"""Central configuration. This is the ONLY module that reads environment variables.

Values come from real environment variables, falling back to a git-ignored
`.env` file in the repository root (see `.env.example`).
"""
from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Mapping

REPO_ROOT = Path(__file__).resolve().parents[1]

ML_PROVIDERS = ("mock", "distilbert")
EVIDENCE_PROVIDERS = ("google", "fixture")


class ConfigError(ValueError):
    """Raised for an invalid configuration value. Never contains secret values."""


@dataclass(frozen=True)
class Settings:
    env: str = "development"
    ml_provider: str = "mock"
    evidence_provider: str = "google"
    # repr=False: the key must never show up in logs, tracebacks or debug prints.
    factcheck_api_key: str = field(default="", repr=False)
    factcheck_language: str = "en"
    factcheck_timeout_s: float = 5.0
    factcheck_page_size: int = 10
    factcheck_max_attempts: int = 2
    evidence_timeout_s: float = 8.0
    evidence_min_relevance: float = 0.5
    ml_timeout_s: float = 5.0
    ml_strong_threshold: float = 0.80
    max_sources: int = 5

    @property
    def factcheck_key_configured(self) -> bool:
        return bool(self.factcheck_api_key)

    @property
    def is_production(self) -> bool:
        return self.env == "production"


def _read_float(env: Mapping[str, str], name: str, default: float, lo: float, hi: float) -> float:
    raw = env.get(name)
    if raw is None or raw.strip() == "":
        return default
    try:
        value = float(raw)
    except ValueError:
        raise ConfigError(f"{name} must be a number") from None
    if not lo <= value <= hi:
        raise ConfigError(f"{name} must be between {lo} and {hi}")
    return value


def _read_int(env: Mapping[str, str], name: str, default: int, lo: int, hi: int) -> int:
    raw = env.get(name)
    if raw is None or raw.strip() == "":
        return default
    try:
        value = int(raw)
    except ValueError:
        raise ConfigError(f"{name} must be a whole number") from None
    if not lo <= value <= hi:
        raise ConfigError(f"{name} must be between {lo} and {hi}")
    return value


def _read_choice(env: Mapping[str, str], name: str, default: str, choices: tuple[str, ...]) -> str:
    value = (env.get(name) or default).strip().lower()
    if value not in choices:
        raise ConfigError(f"{name} must be one of: {', '.join(choices)}")
    return value


def load_settings(
    environ: Mapping[str, str] | None = None,
    *,
    load_env_file: bool = True,
) -> Settings:
    """Build Settings. Pass `environ` (and load_env_file=False) in tests."""
    if environ is None:
        if load_env_file:
            try:
                from dotenv import load_dotenv

                # override=False: real environment variables win over the .env file.
                load_dotenv(REPO_ROOT / ".env", override=False)
            except ImportError:  # python-dotenv not installed; plain env vars still work
                pass
        environ = os.environ

    env_name = _read_choice(environ, "TRUWAVE_ENV", "development", ("development", "production"))
    return Settings(
        env=env_name,
        ml_provider=_read_choice(environ, "ML_PROVIDER", "mock", ML_PROVIDERS),
        evidence_provider=_read_choice(environ, "EVIDENCE_PROVIDER", "google", EVIDENCE_PROVIDERS),
        factcheck_api_key=(environ.get("FACTCHECK_API_KEY") or "").strip(),
        factcheck_language=(environ.get("FACTCHECK_LANGUAGE", "en") or "").strip(),
        factcheck_timeout_s=_read_float(environ, "FACTCHECK_TIMEOUT_S", 5.0, 0.5, 60.0),
        factcheck_page_size=_read_int(environ, "FACTCHECK_PAGE_SIZE", 10, 1, 50),
        factcheck_max_attempts=_read_int(environ, "FACTCHECK_MAX_ATTEMPTS", 2, 1, 4),
        evidence_timeout_s=_read_float(environ, "EVIDENCE_TIMEOUT_S", 8.0, 0.5, 60.0),
        evidence_min_relevance=_read_float(environ, "EVIDENCE_MIN_RELEVANCE", 0.5, 0.0, 1.0),
        ml_timeout_s=_read_float(environ, "ML_TIMEOUT_S", 5.0, 0.5, 60.0),
        ml_strong_threshold=_read_float(environ, "ML_STRONG_THRESHOLD", 0.80, 0.5, 1.0),
        max_sources=_read_int(environ, "MAX_SOURCES", 5, 1, 10),
    )
