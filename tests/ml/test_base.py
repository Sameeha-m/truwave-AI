import math

import pytest

from ml.base import MLLabel, MLResult


@pytest.mark.parametrize("c", [0.0, 0.5, 1.0])
def test_confidence_boundaries_accepted(c):
    assert MLResult(MLLabel.REAL, c, "m").confidence == c


@pytest.mark.parametrize("c", [-0.01, 1.01, math.nan, math.inf])
def test_confidence_out_of_range_rejected(c):
    with pytest.raises(ValueError):
        MLResult(MLLabel.FAKE, c, "m")


def test_label_must_be_enum():
    with pytest.raises(ValueError):
        MLResult("FAKE", 0.5, "m")
