# Sinkly × Supabase

Supabase does only two things; everything else runs on the phone.

| Piece | File | Job |
|---|---|---|
| `feedback` table | `migrations/20261015000000_init_sinkly_backend.sql` | Ideas from the app. Insert-only for phones, max 5 per phone per 24 h (trigger). |
| `verification_attempts` table | first migration | Counter only (phone id + time): 15 photo checks per phone per rolling 24 h. |
| `reserve_verification()` | `…010000_remove_global_limit.sql` | Atomically checks the phone's limit and books one attempt. No whole-app ceiling. |
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

Optional secrets (defaults in brackets): `GEMINI_MODEL` [gemini-3.1-flash-lite], `DAILY_LIMIT` [15].
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

## Later: subscribers only

`isSubscriber()` in `functions/verify-sink-photo/index.ts` returns `true` for now.
When Adapty / RevenueCat is wired, it asks their server API whether the `premium` access level is active.
