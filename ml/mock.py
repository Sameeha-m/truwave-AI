"""Deterministic MOCK classifier for development and pipeline integration only.

This is not a fake-news model and must not be presented as one. Replace it with
the real classifier when that implementation is ready; it satisfies MLClassifier.
"""
from __future__ import annotations

from .base import MLLabel, MLResult


class MockClassifier:
    """Return a fixed, explicit MOCK prediction; evidence still controls verdicts."""

    def __init__(self, label: MLLabel = MLLabel.UNCERTAIN, confidence: float = 0.5) -> None:
        self._label = label
        self._confidence = confidence

    def classify(self, claim: str) -> MLResult:
        if not claim.strip():
            raise ValueError("claim must not be empty")
        return MLResult(self._label, self._confidence, "mock/v1", is_mock=True)
