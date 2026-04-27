#!/usr/bin/env python3
"""Local Bluetooth media bridge for Polypod.

Exposes a tiny HTTP API on localhost:
- GET /state
- POST /play
- POST /pause
- POST /next
- POST /previous

This bridge uses playerctl (MPRIS) and prioritizes Bluetooth-backed players
(named with "bluez") when multiple players are present.
"""

import json
import os
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Optional

HOST = os.environ.get("POLYPOD_MEDIA_HOST", "127.0.0.1")
PORT = int(os.environ.get("POLYPOD_MEDIA_PORT", "8765"))
PLAYERCTL = os.environ.get("PLAYERCTL_BIN", "playerctl")


def _run_playerctl(args: list[str]) -> tuple[int, str, str]:
    try:
        completed = subprocess.run(
            [PLAYERCTL, *args],
            capture_output=True,
            text=True,
            timeout=2,
            check=False,
        )
        return completed.returncode, completed.stdout.strip(), completed.stderr.strip()
    except FileNotFoundError:
        return 127, "", "playerctl not found"
    except subprocess.TimeoutExpired:
        return 124, "", "playerctl timed out"


def _list_players() -> list[str]:
    code, stdout, _ = _run_playerctl(["-l"])
    if code != 0 or not stdout:
        return []

    return [line.strip() for line in stdout.splitlines() if line.strip()]


def _choose_player() -> Optional[str]:
    players = _list_players()
    if not players:
        return None

    bluetooth_players = [p for p in players if "bluez" in p.lower()]
    if bluetooth_players:
        return bluetooth_players[0]

    return players[0]


def _build_state() -> dict:
    player = _choose_player()
    if not player:
        return {
            "connected": False,
            "is_playing": False,
            "status": "disconnected",
            "title": "",
            "artist": "",
            "album": "",
            "player": None,
        }

    status_code, status_out, _ = _run_playerctl(["-p", player, "status"])
    meta_code, meta_out, _ = _run_playerctl(
        ["-p", player, "metadata", "--format", "{{title}}\n{{artist}}\n{{album}}"]
    )

    status = status_out if status_code == 0 and status_out else "Unknown"
    is_playing = status.lower() == "playing"

    title = ""
    artist = ""
    album = ""
    if meta_code == 0 and meta_out:
        lines = meta_out.splitlines()
        if len(lines) > 0:
            title = lines[0].strip()
        if len(lines) > 1:
            artist = lines[1].strip()
        if len(lines) > 2:
            album = lines[2].strip()

    return {
        "connected": True,
        "is_playing": is_playing,
        "status": status,
        "title": title,
        "artist": artist,
        "album": album,
        "player": player,
    }


def _run_command(command: str) -> tuple[bool, str]:
    player = _choose_player()
    if not player:
        return False, "No active media player found"

    code, _, stderr = _run_playerctl(["-p", player, command])
    if code != 0:
        message = stderr or f"playerctl command failed: {command}"
        return False, message

    return True, "ok"


class _Handler(BaseHTTPRequestHandler):
    def _send_json(self, status: int, payload: dict) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:  # noqa: N802
        if self.path == "/state":
            self._send_json(200, _build_state())
            return

        self._send_json(404, {"error": "not found"})

    def do_POST(self) -> None:  # noqa: N802
        path_to_command = {
            "/play": "play",
            "/pause": "pause",
            "/next": "next",
            "/previous": "previous",
        }
        command = path_to_command.get(self.path)

        if not command:
            self._send_json(404, {"error": "not found"})
            return

        ok, message = _run_command(command)
        if not ok:
            self._send_json(409, {"ok": False, "error": message})
            return

        self._send_json(200, {"ok": True})

    def log_message(self, format: str, *args) -> None:  # noqa: A003
        return


if __name__ == "__main__":
    server = ThreadingHTTPServer((HOST, PORT), _Handler)
    print(f"Bluetooth media bridge listening on http://{HOST}:{PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
