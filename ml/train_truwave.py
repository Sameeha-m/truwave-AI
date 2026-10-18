"""Train and evaluate TruWave's TF-IDF + Logistic Regression model on FEVER.

Example:
    python -m ml.train_truwave --download

The official training and labelled development JSONL files are stored under
ml/data/fever/. Existing files are left untouched by --download.
"""
from __future__ import annotations

import argparse
import json
import urllib.request
from pathlib import Path
from typing import Any

import joblib
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.pipeline import Pipeline
from sklearn import __version__ as sklearn_version

from ml.tfidf import FEVER_TO_ML, MODEL_ID


REPO_ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = REPO_ROOT / "ml" / "data" / "fever"
TRAIN_URL = "https://fever.ai/download/fever/train.jsonl"
DEV_URL = "https://fever.ai/download/fever/shared_task_dev.jsonl"
DEFAULT_MODEL_PATH = REPO_ROOT / "ml" / "artifacts" / "fever_tfidf_logreg.joblib"
LABELS = tuple(label.value for label in FEVER_TO_ML.values())


def _download_if_missing(url: str, destination: Path) -> None:
    if destination.exists():
        print(f"Keeping existing file: {destination}")
        return
    destination.parent.mkdir(parents=True, exist_ok=True)
    request = urllib.request.Request(url, headers={"User-Agent": "TruWave-ML/1.0"})
    temporary = destination.with_suffix(destination.suffix + ".part")
    with urllib.request.urlopen(request, timeout=60) as response, temporary.open("wb") as out:
        while chunk := response.read(1024 * 1024):
            out.write(chunk)
    temporary.replace(destination)
    print(f"Downloaded {destination}")


def _read_split(path: Path) -> tuple[list[str], list[str]]:
    claims: list[str] = []
    labels: list[str] = []
    with path.open("r", encoding="utf-8") as source:
        for line_number, line in enumerate(source, start=1):
            if not line.strip():
                continue
            try:
                row: dict[str, Any] = json.loads(line)
            except json.JSONDecodeError as exc:
                raise ValueError(f"Invalid JSON in {path} at line {line_number}") from exc
            claim = row.get("claim")
            label = row.get("label")
            if not isinstance(claim, str) or not claim.strip():
                raise ValueError(f"Missing claim text in {path} at line {line_number}")
            if label not in FEVER_TO_ML:
                raise ValueError(f"Unknown FEVER label in {path} at line {line_number}: {label!r}")
            claims.append(claim.strip())
            labels.append(FEVER_TO_ML[label].value)
    if not claims:
        raise ValueError(f"No labeled claims found in {path}")
    return claims, labels


def train(train_path: Path, dev_path: Path, model_path: Path) -> None:
    train_claims, train_labels = _read_split(train_path)
    dev_claims, dev_labels = _read_split(dev_path)
    print(f"Loaded {len(train_claims):,} training and {len(dev_claims):,} development claims.")

    pipeline = Pipeline(
        steps=[
            (
                "tfidf",
                TfidfVectorizer(
                    lowercase=True,
                    strip_accents="unicode",
                    ngram_range=(1, 2),
                    min_df=2,
                    max_df=0.98,
                    max_features=200_000,
                    sublinear_tf=True,
                ),
            ),
            (
                "logisticregression",
                LogisticRegression(
                    class_weight="balanced",
                    max_iter=500,
                    random_state=42,
                    solver="lbfgs",
                ),
            ),
        ]
    )
    pipeline.fit(train_claims, train_labels)
    predictions = pipeline.predict(dev_claims)
    print("\nFEVER labelled development results")
    print(classification_report(dev_labels, predictions, labels=LABELS, zero_division=0))
    print("Confusion matrix (rows=actual, columns=predicted; REAL, FAKE, UNCERTAIN):")
    print(confusion_matrix(dev_labels, predictions, labels=LABELS))
    max_scores = pipeline.predict_proba(dev_claims).max(axis=1)
    for threshold in (0.60, 0.70, 0.80):
        coverage = float((max_scores >= threshold).mean())
        print(f"Development claims with max class score >= {threshold:.2f}: {coverage:.1%}")

    model_path.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(
        {"pipeline": pipeline, "model_id": MODEL_ID, "scikit_learn_version": sklearn_version},
        model_path,
        compress=3,
    )
    print(f"Saved model artifact: {model_path}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--download", action="store_true", help="Download official FEVER train/dev files if absent")
    parser.add_argument("--train", type=Path, default=DATA_DIR / "train.jsonl")
    parser.add_argument("--dev", type=Path, default=DATA_DIR / "shared_task_dev.jsonl")
    parser.add_argument("--model-out", type=Path, default=DEFAULT_MODEL_PATH)
    args = parser.parse_args()

    if args.download:
        _download_if_missing(TRAIN_URL, args.train)
        _download_if_missing(DEV_URL, args.dev)
    if not args.train.is_file() or not args.dev.is_file():
        parser.error("FEVER files are missing; pass --download or provide --train and --dev paths")
    train(args.train, args.dev, args.model_out)


if __name__ == "__main__":
    main()
