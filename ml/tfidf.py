"""FEVER-trained TF-IDF + Logistic Regression implementation of MLClassifier."""
from __future__ import annotations

import time
from pathlib import Path
from typing import Any

import joblib

from .base import MLInferenceError, MLLabel, MLResult, MLUnavailableError


FEVER_TO_ML = {
    "SUPPORTS": MLLabel.REAL,
    "REFUTES": MLLabel.FAKE,
    "NOT ENOUGH INFO": MLLabel.UNCERTAIN,
}
# The training script converts FEVER source labels to these ML labels before
# fitting LogisticRegression, so these are the classes stored in the artifact.
ML_CLASS_TO_LABEL = {label.value: label for label in FEVER_TO_ML.values()}
MODEL_ID = "fever-tfidf-logreg/v1"


class TfidfClassifier:
    """Load a serialized scikit-learn pipeline once and classify claims locally."""

    def __init__(self, model_path: str | Path) -> None:
        self.model_path = Path(model_path)
        if not self.model_path.is_file():
            raise MLUnavailableError(f"ML model artifact not found: {self.model_path}")
        try:
            artifact: Any = joblib.load(self.model_path)
        except Exception as exc:
            raise MLUnavailableError("ML model artifact could not be loaded") from exc

        if not isinstance(artifact, dict) or "pipeline" not in artifact:
            raise MLUnavailableError("ML model artifact has an unsupported format")
        self._pipeline = artifact["pipeline"]
        self.model_id = str(artifact.get("model_id", MODEL_ID))
        try:
            classifier = self._pipeline.named_steps["logisticregression"]
            classes = set(classifier.classes_)
        except (AttributeError, KeyError, TypeError) as exc:
            raise MLUnavailableError("ML model artifact does not contain the expected pipeline") from exc
        if classes != set(ML_CLASS_TO_LABEL):
            raise MLUnavailableError("ML model artifact does not contain all expected TruWave labels")

    def classify(self, claim: str) -> MLResult:
        claim = claim.strip()
        if not claim:
            raise ValueError("claim must not be empty")

        started = time.perf_counter()
        try:
            probabilities = self._pipeline.predict_proba([claim])[0]
            classifier = self._pipeline.named_steps["logisticregression"]
            pairs = [
                (ML_CLASS_TO_LABEL[str(label)], float(score))
                for label, score in zip(classifier.classes_, probabilities, strict=True)
            ]
            best_label, best_score = max(pairs, key=lambda pair: pair[1])
        except Exception as exc:
            raise MLInferenceError("TF-IDF classifier could not process the claim") from exc

        return MLResult(
            label=best_label,
            confidence=best_score,
            model_id=self.model_id,
            scores={label: score for label, score in pairs},
            latency_ms=max(0, int((time.perf_counter() - started) * 1000)),
        )
