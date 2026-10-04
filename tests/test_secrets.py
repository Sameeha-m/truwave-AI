"""Guards against committing secrets."""
import re
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
GOOGLE_KEY = re.compile(r"AIza[0-9A-Za-z_\-]{35}")


def test_gitignore_protects_env_but_not_the_example():
    lines = {l.strip() for l in (ROOT / ".gitignore").read_text().splitlines()}
    assert ".env" in lines
    assert "!.env.example" in lines


def test_env_example_has_the_variable_and_no_value():
    text = (ROOT / ".env.example").read_text()
    assert re.search(r"^FACTCHECK_API_KEY=\s*$", text, re.M)
    assert not GOOGLE_KEY.search(text)


def _candidate_files():
    try:
        out = subprocess.run(["git", "ls-files", "-co", "--exclude-standard"], cwd=ROOT,
                             capture_output=True, text=True, check=True).stdout
    except (OSError, subprocess.CalledProcessError):
        pytest.skip("not a git checkout")
    return [ROOT / p for p in out.splitlines()]


def test_no_google_api_key_in_any_committable_file():
    offenders = []
    for path in _candidate_files():
        if path.suffix in {".png", ".jpg", ".jpeg", ".webp", ".ttf", ".otf", ".jar", ".pyc", ".ico", ".gif"} or not path.is_file():
            continue
        try:
            if GOOGLE_KEY.search(path.read_text(encoding="utf-8", errors="ignore")):
                offenders.append(str(path.relative_to(ROOT)))
        except OSError:
            continue
    assert offenders == [], f"possible API key found in: {offenders}"
