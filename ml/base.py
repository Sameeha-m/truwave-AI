"""ML layer contract. Implementations (MockClassifier, DistilBERTClassifier) come in Phase 3.

An MLResult is an internal PREDICTION. It is not TruWave's verdict: the verification
engine decides whether, and how much, a prediction may contribute to the final result.
"""
from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import Protocol


class MLLabel(str, Enum):
    REAL = "REAL"
    FAKE = "FAKE"
    UNCERTAIN = "UNCERTAIN"


@dataclass(frozen=True)
class MLResult:
    label: MLLabel
    confidence: float          # classifier's own score for `label`, 0..1. Internal; uncalibrated.
    model_id: str              # e.g. "mock/v1" or "distilbert-liar/2026-xx"
    is_mock: bool = False
    scores: dict[MLLabel, float] | None = None   # per-label scores, internal only
    latency_ms: int = 0

    def __post_init__(self) -> None:
        if not isinstance(self.label, MLLabel):
            raise ValueError("label must be an MLLabel")
        if not (0.0 <= self.confidence <= 1.0):  # also rejects NaN
            raise ValueError("confidence must be between 0 and 1")


class MLError(Exception):
    """Base class for classifier failures."""


class MLUnavailableError(MLError):
    """The model is not loaded / not reachable."""


class MLInferenceError(MLError):
    """The model failed on this particular claim."""


class MLClassifier(Protocol):
    def classify(self, claim: str) -> MLResult:
        """Synchronous and CPU-bound; callers run it in a worker thread."""
        ...
