"""Run labeled claims through the live Google + TF-IDF verification pipeline."""
from __future__ import annotations

import argparse
import asyncio
import csv
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT))

from backend.config import ConfigError, load_settings  # noqa: E402
from backend.main import build_verifier  # noqa: E402
from backend.verifier import VerificationUnavailable  # noqa: E402

LABELS = {"REAL", "FAKE", "UNCERTAIN"}
API_DELAY_SECONDS = 1.0
CSV_PATH = REPO_ROOT / "demo" / "claims_results.csv"

CSV_FIELDS = (
    "number",
    "claim",
    "expected",
    "model_label",
    "model_score",
    "direct_evidence_count",
    "verdict",
    "rule",
    "match",
)


def _read_claims(path: Path) -> list[tuple[str, str]]:
    claims = []
    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8-sig").splitlines(), 1):
        if not raw_line.strip():
            continue
        parts = raw_line.split("\t")
        if len(parts) != 2:
            raise ValueError(f"line {line_number} must contain claim<TAB>expected_label")
        claim, expected = parts[0].strip(), parts[1].strip().upper()
        if not claim:
            raise ValueError(f"line {line_number} has an empty claim")
        if expected not in LABELS:
            raise ValueError(f"line {line_number} has an invalid expected label")
        claims.append((claim, expected))
    return claims


def _table(rows: list[dict[str, str]]) -> str:
    headers = (
        "Number", "Claim (first 60 characters)", "Expected", "Model label / score",
        "DIRECT", "Final verdict", "Rule", "Result",
    )
    displayed = [
        (
            row["number"], row["claim"][:60], row["expected"],
            f"{row['model_label']} {row['model_score']}" if row["model_score"] else row["model_label"],
            row["direct_evidence_count"], row["verdict"], row["rule"], row["match"],
        )
        for row in rows
    ]
    widths = [max(len(headers[i]), *(len(row[i]) for row in displayed)) for i in range(len(headers))]

    def line(values: tuple[str, ...]) -> str:
        return " | ".join(value.ljust(widths[i]) for i, value in enumerate(values))

    return "\n".join([
        line(headers),
        "-+-".join("-" * width for width in widths),
        *(line(row) for row in displayed),
    ])


def _write_csv(rows: list[dict[str, str]], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8-sig", newline="") as output:
        writer = csv.DictWriter(output, fieldnames=CSV_FIELDS)
        writer.writeheader()
        writer.writerows(rows)


async def _run(input_path: Path, output_path: Path) -> int:
    try:
        settings = load_settings()
        if settings.ml_provider != "tfidf":
            raise ConfigError("ML_PROVIDER must be tfidf for this demo")
        if settings.evidence_provider != "google":
            raise ConfigError("EVIDENCE_PROVIDER must be google for this demo")
        claims = _read_claims(input_path)
    except (OSError, UnicodeError, ValueError, ConfigError) as exc:
        print(f"Unable to start demo: {exc}", file=sys.stderr)
        return 2

    if not claims:
        print("The claims file contains no claims.", file=sys.stderr)
        return 2

    try:
        verifier = build_verifier(settings)
        classifier = getattr(verifier, "_ml", None)
        if classifier is None:
            raise ConfigError("The TF-IDF classifier is unavailable")
        await asyncio.to_thread(classifier.classify, "TruWave startup warmup")
    except Exception:
        print("Unable to load or warm the configured verification pipeline.", file=sys.stderr)
        return 1

    rows: list[dict[str, str]] = []
    for index, (claim, expected) in enumerate(claims, 1):
        try:
            decision = await verifier.verify(claim)
        except VerificationUnavailable:
            print(f"Live verification is unavailable for claim {index}.", file=sys.stderr)
            return 1

        model = decision.ml
        direct_count = sum(
            item.relevance_tier.value == "DIRECT"
            for item in decision.evidence.items
        )
        model_label = model.label.value if model else "UNAVAILABLE"
        model_score = f"{model.confidence:.3f}" if model else ""
        verdict = decision.verdict.value
        rows.append({
            "number": str(index),
            "claim": claim,
            "expected": expected,
            "model_label": model_label,
            "model_score": model_score,
            "direct_evidence_count": str(direct_count),
            "verdict": verdict,
            "rule": decision.rule_id,
            "match": "MATCH" if verdict == expected else "MISMATCH",
        })
        if index < len(claims):
            await asyncio.sleep(API_DELAY_SECONDS)

    _write_csv(rows, output_path)
    print(_table(rows))
    matched = sum(row["match"] == "MATCH" for row in rows)
    uncertain = sum(row["verdict"] == "UNCERTAIN" for row in rows)
    mismatched = sum(row["match"] == "MISMATCH" for row in rows)
    print(f"\nSummary: {matched}/{len(rows)} matched; {uncertain} UNCERTAIN; {mismatched} mismatched.")
    print(f"Full results written to {output_path.relative_to(REPO_ROOT) if output_path.is_relative_to(REPO_ROOT) else output_path}")
    return 0


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "input_file", nargs="?", type=Path,
        default=REPO_ROOT / "demo" / "claims_input.tsv",
        help="TSV file with one claim<TAB>expected_label per line",
    )
    parser.add_argument(
        "--output", type=Path, default=CSV_PATH,
        help="CSV output path (default: demo/claims_results.csv)",
    )
    args = parser.parse_args()
    return asyncio.run(_run(args.input_file, args.output))


if __name__ == "__main__":
    raise SystemExit(main())
