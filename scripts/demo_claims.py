"""Run one claim per line through the live Google + TF-IDF verification pipeline."""
from __future__ import annotations

import argparse
import asyncio
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT))

from backend.config import ConfigError, load_settings  # noqa: E402
from backend.main import build_verifier  # noqa: E402
from backend.verifier import VerificationUnavailable  # noqa: E402


def _table(rows: list[tuple[str, str, str, str, str]]) -> str:
    headers = ("Claim", "Model", "DIRECT", "Verdict", "Rule")
    widths = [max(len(headers[i]), *(len(row[i]) for row in rows)) for i in range(len(headers))]

    def line(row: tuple[str, ...]) -> str:
        return " | ".join(value.ljust(widths[i]) for i, value in enumerate(row))

    return "\n".join([line(headers), "-+-".join("-" * width for width in widths), *(line(row) for row in rows)])


async def _run(path: Path) -> int:
    try:
        settings = load_settings()
        if settings.ml_provider != "tfidf":
            raise ConfigError("ML_PROVIDER must be tfidf for this demo")
        if settings.evidence_provider != "google":
            raise ConfigError("EVIDENCE_PROVIDER must be google for this demo")
        claims = [line.strip() for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
    except (OSError, UnicodeError, ConfigError) as exc:
        print(f"Unable to start demo: {exc}", file=sys.stderr)
        return 2

    if not claims:
        print("The claims file contains no non-empty claims.", file=sys.stderr)
        return 2

    try:
        verifier = build_verifier(settings)
        classifier = getattr(verifier, "_ml", None)
        if classifier is None:
            raise ConfigError("The TF-IDF classifier is unavailable")
        classifier.classify("TruWave startup warmup")
    except Exception:
        print("Unable to load or warm the configured verification pipeline.", file=sys.stderr)
        return 1

    rows = []
    for claim in claims:
        try:
            decision = await verifier.verify(claim)
        except VerificationUnavailable:
            print("Live verification is unavailable for at least one claim.", file=sys.stderr)
            return 1
        model = decision.ml
        model_text = f"{model.label.value} {model.confidence:.3f}" if model else "UNAVAILABLE"
        direct_count = sum(item.relevance_tier.value == "DIRECT" for item in decision.evidence.items)
        rows.append((claim, model_text, str(direct_count), decision.verdict.value, decision.rule_id))

    print(_table(rows))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("claims_file", type=Path, help="UTF-8 text file with one claim per line")
    args = parser.parse_args()
    return asyncio.run(_run(args.claims_file))


if __name__ == "__main__":
    raise SystemExit(main())
