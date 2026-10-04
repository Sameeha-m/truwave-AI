import pytest

from backend.config import ConfigError, load_settings


def settings(**env):
    return load_settings(env, load_env_file=False)


def test_defaults():
    s = settings()
    assert (s.env, s.ml_provider, s.evidence_provider) == ("development", "mock", "google")
    assert not s.factcheck_key_configured
    assert s.ml_strong_threshold == 0.80 and s.max_sources == 5


def test_reads_expected_variable_names():
    s = settings(FACTCHECK_API_KEY="  abc123  ", ML_PROVIDER="DistilBERT", EVIDENCE_PROVIDER="fixture",
                 EVIDENCE_MIN_RELEVANCE="0.6", MAX_SOURCES="3")
    assert s.factcheck_api_key == "abc123" and s.factcheck_key_configured
    assert (s.ml_provider, s.evidence_provider) == ("distilbert", "fixture")
    assert s.evidence_min_relevance == 0.6 and s.max_sources == 3


def test_key_is_hidden_from_repr():
    s = settings(FACTCHECK_API_KEY="SUPERSECRETKEY")
    assert "SUPERSECRETKEY" not in repr(s) and "SUPERSECRETKEY" not in str(s)


@pytest.mark.parametrize("env", [
    {"ML_PROVIDER": "gpt"}, {"EVIDENCE_PROVIDER": "bing"}, {"TRUWAVE_ENV": "staging"},
    {"FACTCHECK_TIMEOUT_S": "abc"}, {"FACTCHECK_TIMEOUT_S": "0"}, {"EVIDENCE_MIN_RELEVANCE": "2"},
    {"MAX_SOURCES": "0"}, {"MAX_SOURCES": "1.5"},
])
def test_invalid_values_are_rejected_with_a_clear_message(env):
    with pytest.raises(ConfigError):
        settings(**env)


def test_blank_values_fall_back_to_defaults():
    assert settings(ML_PROVIDER="", FACTCHECK_TIMEOUT_S="").ml_provider == "mock"


def test_config_error_never_contains_the_key():
    with pytest.raises(ConfigError) as info:
        settings(FACTCHECK_API_KEY="SUPERSECRETKEY", ML_PROVIDER="nope")
    assert "SUPERSECRETKEY" not in str(info.value)
