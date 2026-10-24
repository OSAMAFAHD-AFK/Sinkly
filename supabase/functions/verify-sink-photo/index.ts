// verify-sink-photo — the ONE Edge Function of Sinkly.
//
// Phone → { image: <base64 JPEG/PNG/WebP>, customer_id: <RevenueCat app user id> }
//       →  this function  →  Gemini  →  { clean, reason }
//
// Secrets (supabase secrets set …):
//   GEMINI_API_KEY          required. Never leaves the server.
//   GEMINI_MODEL            default "gemini-3.1-flash-lite"
//   DAILY_LIMIT             default 15     checks per phone per rolling 24 h
//   CUSTOMER_DAILY_LIMIT    default = DAILY_LIMIT   checks per subscriber per rolling 24 h, from any
//                           phone/session (needs migration 20261024000000_per_customer_limit.sql)
//   REVENUECAT_SECRET_KEY   RevenueCat secret API key (sk_…). Once set, only customers with an
//                           active "sinkly_premium" entitlement (paid, trial or grace period) get a check.
//                           Not set → everyone is allowed (before the stores are connected).
// (No whole-app ceiling on purpose: a viral video must never lock real users out.
//  Emergency stop: `supabase secrets unset GEMINI_API_KEY` → every check answers 502 at once.)
// SUPABASE_URL and the server key (SUPABASE_SECRET_KEYS, or legacy SUPABASE_SERVICE_ROLE_KEY) are provided by Supabase itself.
//
// Replies (always JSON):
//   200 { clean: boolean, reason: "clean|dishes|dirt|no_sink|not_real_photo|unclear" }
//   400 invalid_image · 401 unauthorized · 402 subscription_required · 413 image_too_large
//   429 limit_reached · 502 verification_unavailable (not counted against the phone)

import { createClient } from "npm:@supabase/supabase-js@2";
import {
  buildGeminiBody,
  decodeBase64,
  detectImageMime,
  extractGeminiText,
  isValidCustomerId,
  MAX_IMAGE_BYTES,
  parseVerdict,
  type Verdict,
} from "./logic.ts";

const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.1-flash-lite";
const DAILY_LIMIT = positiveInt(Deno.env.get("DAILY_LIMIT"), 15);
// Anyone can open new anonymous sessions, so the phone limit alone can be dodged: the paying
// customer has a limit of their own too.
const CUSTOMER_DAILY_LIMIT = positiveInt(Deno.env.get("CUSTOMER_DAILY_LIMIT"), DAILY_LIMIT);
// Up to 3 Gemini calls (retry + thinking fallback) must finish before the app gives up (45 s).
const GEMINI_TIMEOUT_MS = 12_000;

/** Server key: new-style secret key when the project has one, else the legacy service_role key. */
function serverKey(): string | undefined {
  try {
    const secretKeys = JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS") ?? "{}");
    if (typeof secretKeys.default === "string") return secretKeys.default;
  } catch {
    // fall through to the legacy key
  }
  return Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
}

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SERVER_KEY = serverKey();
const admin = SUPABASE_URL && SERVER_KEY
  ? createClient(SUPABASE_URL, SERVER_KEY, { auth: { persistSession: false, autoRefreshToken: false } })
  : null;

function positiveInt(raw: string | undefined, fallback: number): number {
  const value = Number(raw);
  return Number.isInteger(value) && value > 0 ? value : fallback;
}

function reply(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", "cache-control": "no-store" },
  });
}

const REVENUECAT_SECRET_KEY = Deno.env.get("REVENUECAT_SECRET_KEY")?.trim();
const PREMIUM_ENTITLEMENT = "sinkly_premium";

/**
 * Is this RevenueCat customer subscribed right now (paid, free trial or billing grace period)?
 *
 * With the strict paywall every real user is subscribed or on a trial, so this is the lock that
 * keeps strangers from spending the Gemini budget. Before REVENUECAT_SECRET_KEY is set everyone
 * is allowed (the daily limit still applies). If RevenueCat itself can't be reached, the check is
 * allowed rather than blocking paying users; the daily limit still caps it.
 */
async function isSubscriber(customerId: string): Promise<boolean> {
  if (!REVENUECAT_SECRET_KEY) return true;
  if (!isValidCustomerId(customerId)) return false;
  try {
    const response = await fetch(
      `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(customerId)}`,
      { headers: { authorization: `Bearer ${REVENUECAT_SECRET_KEY}` }, signal: AbortSignal.timeout(6_000) },
    );
    if (response.status >= 500 || response.status === 429) {
      console.error("revenuecat: HTTP", response.status);
      return true;
    }
    if (!response.ok) {
      console.error("revenuecat: HTTP", response.status);
      return false;
    }
    const entitlement = (await response.json())?.subscriber?.entitlements?.[PREMIUM_ENTITLEMENT];
    if (!entitlement) return false;
    const until = entitlement.grace_period_expires_date ?? entitlement.expires_date;
    return until == null || Date.parse(until) > Date.now(); // null = never expires
  } catch (error) {
    console.error("revenuecat: request failed", (error as Error).name);
    return true;
  }
}

/** Not reversible: the database only ever sees this hash of the customer id. */
async function hashCustomerId(customerId: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(customerId));
  return Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, "0")).join("");
}

type Reservation = { status: string; attempt_id: string | null };

/**
 * Books one attempt against the phone's AND the customer's daily limits. If the per-customer
 * migration hasn't been applied yet, the per-phone booking (previous behaviour) is used, so
 * checks never stop working because of the deployment order.
 */
async function reserveAttempt(
  client: NonNullable<typeof admin>,
  userId: string,
  customerKey: string | null,
): Promise<Reservation | null> {
  let { data, error } = await client.rpc("reserve_verification", {
    p_device: userId,
    p_device_limit: DAILY_LIMIT,
    p_customer: customerKey,
    p_customer_limit: CUSTOMER_DAILY_LIMIT,
  });
  if (error && (error.code === "PGRST202" || error.code === "42883")) {
    console.error("reserve_verification: per-customer version missing — apply the migration");
    ({ data, error } = await client.rpc("reserve_verification", { p_device: userId, p_device_limit: DAILY_LIMIT }));
  }
  if (error) {
    console.error("reserve_verification failed", error.code);
    return null;
  }
  const row = Array.isArray(data) ? data[0] : data;
  return (row as Reservation | undefined) ?? null;
}

type GeminiOutcome = { verdict: Verdict } | { failed: true };

/** Asks Gemini (at most twice). Network/5xx/429/garbled answers retry once, then fail. */
async function askGemini(base64: string, mime: string, apiKey: string): Promise<GeminiOutcome> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(GEMINI_MODEL)}:generateContent`;
  let withThinking = true;

  for (let attempt = 0; attempt < 2; attempt++) {
    try {
      const response = await fetch(url, {
        method: "POST",
        headers: { "content-type": "application/json", "x-goog-api-key": apiKey },
        body: JSON.stringify(buildGeminiBody(base64, mime, withThinking)),
        signal: AbortSignal.timeout(GEMINI_TIMEOUT_MS),
      });

      if (response.ok) {
        const verdict = parseVerdict(extractGeminiText(await response.json()));
        if (verdict) return { verdict };
        console.error("gemini: unreadable answer");
        continue;
      }

      const detail = await response.text();
      // Some models reject the thinking setting: drop it and try again right away.
      if (response.status === 400 && withThinking && /thinking/i.test(detail)) {
        withThinking = false;
        attempt--;
        continue;
      }
      console.error("gemini: HTTP", response.status);
      if (response.status !== 429 && response.status < 500) return { failed: true }; // our bug: no point retrying
    } catch (error) {
      console.error("gemini: request failed", (error as Error).name);
    }
  }
  return { failed: true };
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response(null, { status: 204 });
  if (request.method !== "POST") return reply(405, { error: "method_not_allowed" });

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey || !admin) {
    console.error(!apiKey ? "GEMINI_API_KEY is not set" : "Supabase server key is missing");
    return reply(502, { error: "verification_unavailable" });
  }

  // 1. Who is calling? A valid (anonymous) Supabase session, checked against the Auth server.
  const token = request.headers.get("authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) return reply(401, { error: "unauthorized" });
  const { data: auth, error: authError } = await admin.auth.getUser(token);
  if (authError || !auth.user) return reply(401, { error: "unauthorized" });
  const userId = auth.user.id;

  let payload: { image?: unknown; customer_id?: unknown } | null;
  try {
    payload = await request.json();
  } catch {
    return reply(400, { error: "invalid_image" });
  }

  // 2. Allowed to use the check at all? RevenueCat confirms the subscription.
  const customerId = typeof payload?.customer_id === "string" ? payload.customer_id : "";
  if (!(await isSubscriber(customerId))) return reply(402, { error: "subscription_required" });

  // 3. A real, small image — rejected before it can cost anything.
  const base64 = payload?.image;
  if (typeof base64 !== "string" || base64.length === 0) return reply(400, { error: "invalid_image" });
  if (base64.length > Math.ceil((MAX_IMAGE_BYTES * 4) / 3) + 8) return reply(413, { error: "image_too_large" });
  const bytes = decodeBase64(base64);
  const mime = bytes ? detectImageMime(bytes) : null;
  if (!bytes || !mime) return reply(400, { error: "invalid_image" });
  if (bytes.length > MAX_IMAGE_BYTES) return reply(413, { error: "image_too_large" });

  // 4. Book one attempt: the phone's and the subscriber's daily limits, checked atomically.
  //    The customer id is a proven one here (right format, active entitlement); without the
  //    RevenueCat secret there is nothing to prove it with, so only the phone limit applies.
  const customerKey = REVENUECAT_SECRET_KEY ? await hashCustomerId(customerId) : null;
  const reservation = await reserveAttempt(admin, userId, customerKey);
  if (!reservation) return reply(502, { error: "verification_unavailable" });
  if (reservation.status === "device_limit" || reservation.status === "customer_limit") {
    return reply(429, { error: "limit_reached" });
  }

  // 5. Ask the model. The photo only ever exists in memory here: it is never stored or logged.
  const outcome = await askGemini(base64, mime, apiKey);
  if ("failed" in outcome) {
    // Our / Google's problem, not the user's: give the attempt back.
    await admin.from("verification_attempts").delete().eq("id", reservation.attempt_id);
    return reply(502, { error: "verification_unavailable" });
  }

  return reply(200, { clean: outcome.verdict.clean, reason: outcome.verdict.reason });
});
