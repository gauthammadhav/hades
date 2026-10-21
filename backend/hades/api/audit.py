"""Audit record models and store for HADES API."""

from datetime import datetime, timezone
import json
from pathlib import Path
from typing import Dict, List, Optional
from pydantic import BaseModel, Field


class ApiAuditRecord(BaseModel):
    id: int = Field(default=1)
    session_id: str
    event: str
    success: bool = True
    detail: str = ""
    created_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())


class AuditStore:
    """Thread-safe storage for session audit records."""

    def __init__(self, state_file: Optional[Path] = None):
        self._state_file = state_file
        self._records: Dict[str, List[ApiAuditRecord]] = {}
        self._next_id = 1
        if self._state_file and self._state_file.exists():
            self._load()

    def add(self, session_id: str, event: str, success: bool, detail: str) -> ApiAuditRecord:
        record = ApiAuditRecord(
            id=self._next_id,
            session_id=session_id,
            event=event,
            success=success,
            detail=detail,
            created_at=datetime.now(timezone.utc).isoformat(),
        )
        self._next_id += 1
        if session_id not in self._records:
            self._records[session_id] = []
        self._records[session_id].append(record)
        self._save()
        return record

    def get_session_audits(self, session_id: str) -> List[ApiAuditRecord]:
        return list(self._records.get(session_id, []))

    def _save(self) -> None:
        if not self._state_file:
            return
        try:
            self._state_file.parent.mkdir(parents=True, exist_ok=True)
            data = {
                sid: [r.model_dump(mode="json") for r in recs]
                for sid, recs in self._records.items()
            }
            self._state_file.write_text(json.dumps(data, indent=2), encoding="utf-8")
        except OSError:
            pass

    def _load(self) -> None:
        if not self._state_file or not self._state_file.exists():
            return
        try:
            raw = json.loads(self._state_file.read_text(encoding="utf-8"))
            for sid, items in raw.items():
                self._records[sid] = [ApiAuditRecord(**item) for item in items]
                for r in self._records[sid]:
                    if r.id >= self._next_id:
                        self._next_id = r.id + 1
        except Exception:
            pass


_GLOBAL_AUDIT_STORE = AuditStore()


def get_audit_store() -> AuditStore:
    return _GLOBAL_AUDIT_STORE
