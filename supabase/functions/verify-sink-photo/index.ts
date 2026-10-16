// verify-sink-photo — the ONE Edge Function of Sinkly.
//
// Phone → { image: <base64 JPEG/PNG/WebP> }  →  this function  →  Gemini  →  { clean, reason }
//
// Secrets (supabase secrets set …):
//   GEMINI_API_KEY        required. Never leaves the server.
//   GEMINI_MODEL          default "gemini-3.1-flash-lite"
//   DAILY_LIMIT           default 15     checks per phone per rolling 24 h
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
  MAX_IMAGE_BYTES,
  parseVerdict,
  type Verdict,
} from "./logic.ts";

const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.1-flash-lite";
const DAILY_LIMIT = positiveInt(Deno.env.get("DAILY_LIMIT"), 15);
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

/**
 * Is this person a paying subscriber?
 *
 * TODO(adapty|revenuecat): once subscriptions are wired, send the store profile id from the app,
 * ask Adapty / RevenueCat's server API whether the 'premium' access level is active, and return
 * false when it is not. With the strict paywall every real user is subscribed or on a trial,
 * so this is the lock that keeps strangers from spending your Gemini budget.
 * Until then everyone is allowed; the daily limits still apply.
 */
// deno-lint-ignore require-await
async function isSubscriber(_userId: string): Promise<boolean> {
  return true;
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

  // 2. Allowed to use the check at all? (placeholder until Adapty / RevenueCat)
  if (!(await isSubscriber(userId))) return reply(402, { error: "subscription_required" });

  // 3. A real, small image — rejected before it can cost anything.
  let base64: unknown;
  try {
    base64 = (await request.json())?.image;
  } catch {
    return reply(400, { error: "invalid_image" });
  }
  if (typeof base64 !== "string" || base64.length === 0) return reply(400, { error: "invalid_image" });
  if (base64.length > Math.ceil((MAX_IMAGE_BYTES * 4) / 3) + 8) return reply(413, { error: "image_too_large" });
  const bytes = decodeBase64(base64);
  const mime = bytes ? detectImageMime(bytes) : null;
  if (!bytes || !mime) return reply(400, { error: "invalid_image" });
  if (bytes.length > MAX_IMAGE_BYTES) return reply(413, { error: "image_too_large" });

  // 4. Book one attempt (the phone's daily limit, checked atomically).
  const { data: booking, error: bookingError } = await admin.rpc("reserve_verification", {
    p_device: userId,
    p_device_limit: DAILY_LIMIT,
  });
  const reservation = Array.isArray(booking) ? booking[0] : booking;
  if (bookingError || !reservation) {
    console.error("reserve_verification failed", bookingError?.code);
    return reply(502, { error: "verification_unavailable" });
  }
  if (reservation.status === "device_limit") return reply(429, { error: "limit_reached" });

  // 5. Ask the model. The photo only ever exists in memory here: it is never stored or logged.
  const outcome = await askGemini(base64, mime, apiKey);
  if ("failed" in outcome) {
    // Our / Google's problem, not the user's: give the attempt back.
    await admin.from("verification_attempts").delete().eq("id", reservation.attempt_id);
    return reply(502, { error: "verification_unavailable" });
  }

  return reply(200, { clean: outcome.verdict.clean, reason: outcome.verdict.reason });
});
