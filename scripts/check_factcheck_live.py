"""Live check: does my FACTCHECK_API_KEY work against the real Google Fact Check API?

Usage (from the repository root):
    python scripts/check_factcheck_live.py
    python scripts/check_factcheck_live.py "your claim here"
    python scripts/check_factcheck_live.py "your claim here" --save

Makes exactly ONE real API call. Never prints the key. With --save, the raw Google
response body is written to tests/evidence/recordings/live_<claim>.json so it can
become a regression test.
"""
from __future__ import annotations

import argparse
import asyncio
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT))

from backend.config import ConfigError, load_settings  # noqa: E402
from backend.verifier import VerificationUnavailable, decide  # noqa: E402
from evidence.base import ProviderError  # noqa: E402
from evidence.google_factcheck import GoogleFactCheckProvider, parse_claims_payload  # noqa: E402
from evidence.normalize import explain_relevance  # noqa: E402
from evidence.service import EvidenceService  # noqa: E402

DEFAULT_CLAIM = "Drinking bleach cures COVID-19"


def format_relevance_report(claim: str, items: list, min_relevance: float) -> list[str]:
    """One block per parsed review, INCLUDING the ones the relevance gate rejects.

    Shows the same numbers the gate uses (it calls the same explain_relevance), so you can
    see exactly why each fact-check passed or failed. Contains no secrets.
    """
    lines: list[str] = []
    for n, item in enumerate(items, start=1):
        b = explain_relevance(claim, item.reviewed_claim)
        passed = b.score >= min_relevance
        if passed:
            reason = f"PASSED (score {b.score:.2f} >= {min_relevance})"
        elif b.blocked_by_negation:
            reason = (f"FAILED: negation guard. Word overlap alone would be {b.overlap_score:.2f}, "
                      f"but only one side contains a negation, so the score was forced to 0")
        else:
            reason = f"FAILED: word overlap {b.score:.2f} is below {min_relevance}"
        lines += [
            f"[{n}] {item.publisher_name}  |  rating: {item.raw_rating!r}  ->  stance {item.stance.value}",
            f"    reviewed claim : {item.reviewed_claim!r}",
            f"    shared words   : {list(b.shared)}",
            f"    only in yours  : {list(b.only_in_claim)}",
            f"    only in theirs : {list(b.only_in_reviewed)}",
            f"    negation words : yours={list(b.claim_negators)}  theirs={list(b.reviewed_negators)}",
            f"    result         : {reason}",
        ]
    return lines

HINTS = {
    "no_api_key": "FACTCHECK_API_KEY was not found. Create a file named .env in the repo root "
                  "(next to .env.example) containing the line FACTCHECK_API_KEY=your_key, no quotes.",
    "auth_failed": "Google rejected the key. Check that (1) the key was copied completely, "
                   "(2) the 'Fact Check Tools API' is ENABLED in the same Google Cloud project, "
                   "(3) the key has no restriction that blocks this API or server-side use "
                   "(an Android/iOS/HTTP-referrer-restricted key will not work from a backend).",
    "bad_request": "Google rejected the request itself (unexpected). Try a different claim.",
    "rate_limited": "Quota or rate limit reached. Wait a minute and retry; check quotas in Google Cloud Console.",
    "timeout": "The request timed out. Check your internet connection / firewall and retry.",
    "unavailable": "Could not reach Google's service. Check your internet connection, VPN or firewall.",
    "bad_response": "Google answered, but not with the documented JSON shape. Re-run with --save and share the file.",
}


class _ReplayProvider:
    """Feeds the already-fetched payload through the normal EvidenceService pipeline."""

    name = "google_factcheck"

    def __init__(self, payload: dict) -> None:
        self._payload = payload

    async def search(self, claim: str):
        return parse_claims_payload(self._payload, provider=self.name)


async def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("claim", nargs="?", default=DEFAULT_CLAIM)
    parser.add_argument("--save", action="store_true", help="save the raw response as a test recording")
    args = parser.parse_args()

    # Windows consoles often cannot print every character fact-checkers use (curly quotes, other scripts).
    try:
        sys.stdout.reconfigure(errors="replace")
    except AttributeError:
        pass

    try:
        settings = load_settings()
    except ConfigError as exc:
        print(f"FAIL  configuration problem: {exc}")
        return 1

    key = settings.factcheck_api_key
    print(f"Claim: {args.claim!r}")
    if key:
        print(f"Key:   found ({len(key)} characters); the value is never printed")
    else:
        print("Key:   NOT FOUND")

    provider = GoogleFactCheckProvider(
        key,
        language=settings.factcheck_language,
        page_size=settings.factcheck_page_size,
        timeout_s=settings.factcheck_timeout_s,
        max_attempts=settings.factcheck_max_attempts,
    )
    try:
        payload = await provider.fetch(args.claim)
    except ProviderError as exc:
        print(f"\nFAIL  live API call did not succeed: {exc.code}" + (f" ({exc.reason})" if exc.reason else ""))
        print("      " + HINTS.get(exc.code, "See the message above."))
        return 1

    claims = payload.get("claims") or []
    print(f"\nOK    Google API call succeeded (valid JSON, {len(claims)} claim(s) returned)")

    if args.save:
        slug = re.sub(r"[^a-z0-9]+", "_", args.claim.lower()).strip("_")[:50] or "claim"
        out = REPO_ROOT / "tests" / "evidence" / "recordings" / f"live_{slug}.json"
        out.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"      saved raw response -> {out.relative_to(REPO_ROOT)}")

    try:
        raw_items = parse_claims_payload(payload)
    except ProviderError as exc:
        print(f"FAIL  response could not be parsed: {exc.code}. Re-run with --save and share the file.")
        return 1

    service = EvidenceService(
        [_ReplayProvider(payload)],
        min_relevance=settings.evidence_min_relevance,
        provider_timeout_s=settings.evidence_timeout_s,
    )
    result = await service.gather(args.claim)
    report = result.reports[0]
    print(f"\nParsed {len(raw_items)} fact-check review(s); {report.kept_count} passed the relevance gate "
          f"(min relevance {settings.evidence_min_relevance}).")
    for item in result.items:
        print(f"  - [{item.stance.value:8}] {item.publisher_name} ({item.tier.value.lower()}) "
              f"rating={item.raw_rating!r} relevance={item.relevance:.2f}\n      {item.title}\n      {item.url}")
    if raw_items:
        print("\nWhy each review passed or failed the relevance gate:")
        for line in format_relevance_report(args.claim, raw_items, settings.evidence_min_relevance):
            print("  " + line)

    print("\nWhat the verification engine would say with NO ML prediction:")
    try:
        decision = decide(None, result, ml_threshold=settings.ml_strong_threshold, max_sources=settings.max_sources)
        print(f"  verdict={decision.verdict.value}  confidence={decision.confidence:.2f}  rule={decision.rule_id}")
        print(f"  summary: {decision.summary}")
    except VerificationUnavailable:
        print("  (no verdict: evidence unavailable)")
    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
