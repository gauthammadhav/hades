"""Small persistent registry for sandbox sessions."""

import json
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any
from uuid import uuid4


STATE_PATH = Path.home() / ".local" / "state" / "hades" / "sessions.json"


@dataclass
class SandboxSession:
    session_id: str
    workspace: str
    target: str
    isolation: str
    hardware: list[str]
    runtime_id: str | None = None


def load_sessions(state_path: Path | None = None) -> dict[str, SandboxSession]:
    path = state_path or STATE_PATH
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"Unable to read sandbox state at {path}: {exc}") from exc
    if not isinstance(data, dict):
        return {}
    return {key: SandboxSession(**value) for key, value in data.items()}


def save_sessions(sessions: dict[str, SandboxSession], state_path: Path | None = None) -> None:
    path = state_path or STATE_PATH
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            json.dumps({key: asdict(value) for key, value in sessions.items()}, indent=2),
            encoding="utf-8",
        )
    except OSError as exc:
        raise RuntimeError(f"Unable to write sandbox state at {path}: {exc}") from exc


def new_session(**kwargs: Any) -> SandboxSession:
    return SandboxSession(session_id=uuid4().hex[:12], **kwargs)
