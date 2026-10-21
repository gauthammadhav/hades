"""WebSocket pub-sub hub for live hardware telemetry and session events."""

import asyncio
import json
from typing import Dict, Set
from fastapi import WebSocket


class WebSocketHub:
    """Manages active WebSocket connections by channel topic."""

    def __init__(self):
        self._connections: Dict[str, Set[WebSocket]] = {}
        self._lock = asyncio.Lock()

    async def connect(self, websocket: WebSocket, topic: str = "*") -> None:
        await websocket.accept()
        async with self._lock:
            if topic not in self._connections:
                self._connections[topic] = set()
            self._connections[topic].add(websocket)

    async def disconnect(self, websocket: WebSocket, topic: str = "*") -> None:
        async with self._lock:
            if topic in self._connections and websocket in self._connections[topic]:
                self._connections[topic].remove(websocket)
                if not self._connections[topic]:
                    del self._connections[topic]

    async def broadcast(self, message: dict, topic: str = "*") -> None:
        """Broadcast JSON message to subscribers of topic and global wildcard ('*')."""
        payload = json.dumps(message)
        dead_connections: list[tuple[str, WebSocket]] = []

        async with self._lock:
            target_topics = {topic, "*"}
            for t in target_topics:
                for ws in self._connections.get(t, set()):
                    try:
                        await ws.send_text(payload)
                    except Exception:
                        dead_connections.append((t, ws))

        # Cleanup disconnected sockets
        for t, ws in dead_connections:
            await self.disconnect(ws, t)


_GLOBAL_HUB = WebSocketHub()


def get_ws_hub() -> WebSocketHub:
    return _GLOBAL_HUB
