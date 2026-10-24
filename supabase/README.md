# Sinkly × Supabase

Supabase does only two things; everything else runs on the phone.

| Piece | File | Job |
|---|---|---|
| `feedback` table | `migrations/20261015000000_init_sinkly_backend.sql` | Ideas from the app. Insert-only for phones, max 5 per phone per 24 h (trigger). |
| `verification_attempts` table | first migration | Counter only (phone id, hashed subscriber id, time): 15 photo checks per phone AND per subscriber per rolling 24 h. |
| `reserve_verification()` | `…20261024000000_per_customer_limit.sql` | Atomically checks the phone's and the subscriber's limits and books one attempt. No whole-app ceiling. (The older 2-argument version stays as a fallback.) |
| `verify-sink-photo` | `functions/verify-sink-photo/` | Photo → Gemini → `{clean, reason}`. The photo is never stored. |

Identity = anonymous sign-in (no screen, no email). The Gemini key exists only as a Supabase secret.

## One-time setup (run from `D:\Sinkly`)

```bash
supabase login
supabase link --project-ref <your-project-ref>
supabase db push
supabase secrets set GEMINI_API_KEY=<your-gemini-key>
supabase functions deploy verify-sink-photo
```

Then in the dashboard: **Authentication → Sign In / Providers → Allow anonymous sign-ins = ON**
(`config.toml` only affects the local dev stack).

Optional secrets (defaults in brackets): `GEMINI_MODEL` [gemini-3.1-flash-lite], `DAILY_LIMIT` [15],
`CUSTOMER_DAILY_LIMIT` [= DAILY_LIMIT, per subscriber from any phone/session],
`REVENUECAT_SECRET_KEY` [not set = every caller allowed] — see "Subscribers only" below.
Changing one = `supabase secrets set …`, no app update.

**Emergency stop** (abuse or runaway cost): `supabase secrets unset GEMINI_API_KEY` — every check answers 502 immediately
(attempts are refunded, nothing is charged to users). Set the key again to resume.

## Function replies

| HTTP | body | App shows |
|---|---|---|
| 200 | `{clean: true, reason: "clean"}` | Unlock |
| 200 | `{clean: false, reason: "dishes" \| "dirt" \| "no_sink" \| "not_real_photo" \| "unclear"}` | `verify_error_<reason>` |
| 429 | `limit_reached` | `verify_error_limit_reached` |
| 502 | `verification_unavailable` (attempt refunded) | `verify_error_unavailable` |
| 400 / 413 | `invalid_image` / `image_too_large` | `verify_error_unreadable` |
| 401 | `unauthorized` | `verify_error_unavailable` |
| 402 | `subscription_required` | `verify_error_subscription` |

## Subscribers only (RevenueCat)

The app sends its RevenueCat customer id (`customer_id`) with every photo. Once the secret is set,
`isSubscriber()` asks RevenueCat's server whether that customer's `sinkly_premium` entitlement is active
(paid, free trial or billing grace period); anyone else gets `402` before Gemini is called.

```
supabase secrets set REVENUECAT_SECRET_KEY=sk_...
```

Not set → everyone is allowed (the daily limit still applies). If RevenueCat itself is down the
check is allowed rather than blocking paying users.

`customer_id` must look like RevenueCat's anonymous id (`$RCAnonymousID:` + 32 hex, the same rule
RevenueCat's SDK uses); anything else gets `402` without RevenueCat being asked.

**Why a per-subscriber limit:** anyone can open new anonymous sessions, so the per-phone limit alone
let one subscription (even a free trial) spend unlimited Gemini checks. The subscriber limit counts a
SHA-256 hash of the customer id (the id itself is never stored).

### Deploying a change to the limits
1. `npx supabase db push` (or paste the migration into Dashboard → SQL Editor; it is safe to run twice)
2. `npx supabase functions deploy verify-sink-photo`

The function falls back to the per-phone booking if step 1 hasn't run yet, so the order never breaks checks.
