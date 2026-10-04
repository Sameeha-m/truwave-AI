import asyncio
import json
from pathlib import Path

RECORDINGS = Path(__file__).parent / "evidence" / "recordings"


def run(coro):
    return asyncio.run(coro)


def recording(name: str) -> dict:
    return json.loads((RECORDINGS / name).read_text(encoding="utf-8"))
