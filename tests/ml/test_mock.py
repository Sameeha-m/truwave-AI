from ml.base import MLLabel, MLResult
from ml.mock import MockClassifier


def test_mock_classifier_is_deterministic_and_marked_mock():
    classifier = MockClassifier(MLLabel.FAKE, 0.75)
    first = classifier.classify("claim one")
    second = classifier.classify("claim two")
    assert first == second
    assert first == MLResult(MLLabel.FAKE, 0.75, "mock/v1", is_mock=True)
