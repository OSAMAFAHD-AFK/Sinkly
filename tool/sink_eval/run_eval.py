"""Compare vision models on the clean-sink check.

Put photos in tool/sink_eval/images/<label>/ where <label> is the ground truth:
  clean/    sink empty and clean            -> expected clean = true
  dirty/    dishes, food or grime present   -> expected clean = false
  invalid/  no sink, screenshot, dark, ...  -> expected clean = false

Keys come from environment variables only (never from files):
  ANTHROPIC_API_KEY, GEMINI_API_KEY

  python tool/sink_eval/run_eval.py                    # both default models
  python tool/sink_eval/run_eval.py --limit 5          # quick smoke test
  python tool/sink_eval/run_eval.py --models haiku     # one model

Writes tool/sink_eval/results/results.csv and summary.md (both git-ignored).
"""

import argparse
import base64
import csv
import io
import json
import os
import re
import statistics
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image, ImageOps

HERE = Path(__file__).parent
IMAGES = HERE / "images"
RESULTS = HERE / "results"
PROMPT = (HERE / "prompt.txt").read_text(encoding="utf-8").strip()
MAX_SIDE = 1024  # what the app will send; also what the cost numbers assume

# USD per 1M tokens (input, output) — official pages, 2026-10-15. Re-check before budgeting.
MODELS = {
    "haiku": {"id": "claude-haiku-5-5", "provider": "anthropic", "price": (0.10, 0.50)},
    "flashlite": {"id": "gemini-3.1-flash-lite", "provider": "gemini", "price": (0.25, 1.50)},
    # Optional extras: --models haiku,flashlite,flashlite35,sonnet
    "flashlite35": {"id": "gemini-3.5-flash-lite", "provider": "gemini", "price": (0.30, 2.50)},
    "sonnet": {"id": "claude-sonnet-5-5", "provider": "anthropic", "price": (2.00, 10.00)},
}
DEFAULT_MODELS = ["haiku", "flashlite"]
REASONS = ["clean", "dishes", "dirt", "no_sink", "not_real_photo", "unclear"]


def load_image(path: Path) -> bytes:
    """Resize like the app will (long side 1024, JPEG q80, EXIF rotation applied)."""
    with Image.open(path) as img:
        img = ImageOps.exif_transpose(img).convert("RGB")
        img.thumbnail((MAX_SIDE, MAX_SIDE))
        buffer = io.BytesIO()
        img.save(buffer, "JPEG", quality=80)
        return buffer.getvalue()


def post(url: str, headers: dict, body: dict, retries: int = 3):
    data = json.dumps(body).encode()
    for attempt in range(retries + 1):
        request = urllib.request.Request(url, data=data, headers={"content-type": "application/json", **headers})
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return json.loads(response.read())
        except urllib.error.HTTPError as error:
            detail = error.read().decode("utf-8", "replace")
            if error.code in (429, 500, 502, 503, 529) and attempt < retries:
                time.sleep(2 * (attempt + 1))
                continue
            raise RuntimeError(f"HTTP {error.code}: {detail[:300]}") from None
        except urllib.error.URLError as error:
            if attempt < retries:
                time.sleep(2 * (attempt + 1))
                continue
            raise RuntimeError(f"network: {error}") from None


def call_anthropic(model_id: str, jpeg: bytes):
    reply = post(
        "https://api.anthropic.com/v1/messages",
        {"x-api-key": os.environ["ANTHROPIC_API_KEY"], "anthropic-version": "2023-06-01"},
        {
            "model": model_id,
            "max_tokens": 100,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {"type": "base64", "media_type": "image/jpeg", "data": base64.b64encode(jpeg).decode()},
                        },
                        {"type": "text", "text": PROMPT},
                    ],
                }
            ],
        },
    )
    text = "".join(block.get("text", "") for block in reply.get("content", []))
    usage = reply.get("usage", {})
    return text, usage.get("input_tokens", 0), usage.get("output_tokens", 0)


def call_gemini(model_id: str, jpeg: bytes):
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_id}:generateContent"
    headers = {"x-goog-api-key": os.environ["GEMINI_API_KEY"]}
    config = {
        "temperature": 0,
        "maxOutputTokens": 200,
        "responseMimeType": "application/json",
        "responseSchema": {
            "type": "OBJECT",
            "properties": {"clean": {"type": "BOOLEAN"}, "reason": {"type": "STRING", "enum": REASONS}},
            "required": ["clean", "reason"],
        },
    }
    body = {
        "contents": [
            {"parts": [{"inline_data": {"mime_type": "image/jpeg", "data": base64.b64encode(jpeg).decode()}}, {"text": PROMPT}]}
        ],
        "generationConfig": {**config, "thinkingConfig": {"thinkingLevel": "minimal"}},
    }
    try:
        reply = post(url, headers, body)
    except RuntimeError as error:
        # Some models reject the thinking setting: retry once without it.
        if "thinking" not in str(error).lower():
            raise
        body["generationConfig"] = config
        reply = post(url, headers, body)
    parts = reply.get("candidates", [{}])[0].get("content", {}).get("parts", [])
    text = "".join(part.get("text", "") for part in parts if not part.get("thought"))
    usage = reply.get("usageMetadata", {})
    output = usage.get("candidatesTokenCount", 0) + usage.get("thoughtsTokenCount", 0)  # thinking is billed as output
    return text, usage.get("promptTokenCount", 0), output


def parse(text: str):
    """Returns (clean, reason) or (None, None) when the answer is not valid."""
    match = re.search(r"\{.*?\}", text, re.S)
    if not match:
        return None, None
    try:
        obj = json.loads(match.group(0))
        clean, reason = obj.get("clean"), obj.get("reason")
    except (json.JSONDecodeError, AttributeError):
        return None, None
    if not isinstance(clean, bool) or reason not in REASONS:
        return None, None
    # A "clean: true" with a rejecting reason contradicts itself -> treat as not clean.
    return (clean and reason == "clean"), reason


def run_one(job):
    key, path, expected = job
    spec = MODELS[key]
    row = {"model": key, "image": f"{path.parent.name}/{path.name}", "expected_clean": expected}
    started = time.time()
    try:
        jpeg = load_image(path)
        caller = call_anthropic if spec["provider"] == "anthropic" else call_gemini
        text, tokens_in, tokens_out = caller(spec["id"], jpeg)
        clean, reason = parse(text)
        price_in, price_out = spec["price"]
        row.update(
            predicted_clean=clean,
            reason=reason,
            valid=clean is not None,
            tokens_in=tokens_in,
            tokens_out=tokens_out,
            cost_usd=(tokens_in * price_in + tokens_out * price_out) / 1e6,
            raw="" if clean is not None else text[:200],
        )
    except Exception as error:  # keep going: one bad photo must not stop the run
        row.update(predicted_clean=None, reason=None, valid=False, tokens_in=0, tokens_out=0, cost_usd=0, raw=str(error)[:200])
    row["latency_s"] = round(time.time() - started, 2)
    return row


def summarize(rows, keys):
    lines = [
        "| Model | Images | Accuracy | False accept (unlocked while dirty) | False reject (clean refused) | Invalid replies | Median s | p95 s | $ / check | $ / 1,080 checks |",
        "|---|---|---|---|---|---|---|---|---|---|",
    ]
    for key in keys:
        mine = [r for r in rows if r["model"] == key]
        valid = [r for r in mine if r["valid"]]
        positives = [r for r in valid if r["expected_clean"]]
        negatives = [r for r in valid if not r["expected_clean"]]
        correct = sum(r["predicted_clean"] == r["expected_clean"] for r in valid)
        false_accept = sum(r["predicted_clean"] for r in negatives)
        false_reject = sum(not r["predicted_clean"] for r in positives)
        times = sorted(r["latency_s"] for r in mine) or [0]
        cost = statistics.mean(r["cost_usd"] for r in valid) if valid else 0
        pct = lambda a, b: f"{a}/{b} ({100 * a / b:.1f}%)" if b else "-"
        lines.append(
            f"| {MODELS[key]['id']} | {len(mine)} | {pct(correct, len(valid))} | {pct(false_accept, len(negatives))} | "
            f"{pct(false_reject, len(positives))} | {len(mine) - len(valid)} | {statistics.median(times):.2f} | "
            f"{times[int(0.95 * (len(times) - 1))]:.2f} | {cost:.5f} | {cost * 1080:.2f} |"
        )
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--models", default=",".join(DEFAULT_MODELS))
    parser.add_argument("--limit", type=int, default=0, help="max images per label folder (smoke test)")
    parser.add_argument("--workers", type=int, default=4)
    args = parser.parse_args()
    keys = [k.strip() for k in args.models.split(",")]

    needed = {"anthropic": "ANTHROPIC_API_KEY", "gemini": "GEMINI_API_KEY"}
    for key in keys:
        env = needed[MODELS[key]["provider"]]
        if not os.environ.get(env):
            raise SystemExit(f"Set {env} in your environment first (never paste keys into files or chat).")

    jobs = []
    for label in ("clean", "dirty", "invalid"):
        files = sorted(p for p in (IMAGES / label).glob("*") if p.suffix.lower() in {".jpg", ".jpeg", ".png", ".webp", ".heic"})
        for path in files[: args.limit or None]:
            jobs += [(key, path, label == "clean") for key in keys]
    if not jobs:
        raise SystemExit(f"No images found in {IMAGES}/clean|dirty|invalid")

    print(f"{len(jobs)} calls ({len(jobs) // len(keys)} images x {len(keys)} models)...")
    with ThreadPoolExecutor(args.workers) as pool:
        rows = list(pool.map(run_one, jobs))

    RESULTS.mkdir(exist_ok=True)
    with open(RESULTS / "results.csv", "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)

    table = summarize(rows, keys)
    wrong = [r for r in rows if r["valid"] and r["predicted_clean"] != r["expected_clean"]]
    detail = "\n".join(f"- {r['model']}: {r['image']} -> predicted {r['predicted_clean']} ({r['reason']})" for r in wrong)
    (RESULTS / "summary.md").write_text(f"{table}\n\n### Mistakes\n{detail or 'none'}\n", encoding="utf-8")
    print(table)
    print(f"\nMistakes: {len(wrong)}  ->  see {RESULTS / 'summary.md'}")


if __name__ == "__main__":
    main()
