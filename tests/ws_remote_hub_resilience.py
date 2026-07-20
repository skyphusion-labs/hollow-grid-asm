#!/usr/bin/env python3
"""Remote-hub resilience: fail-open must hold under a hostile hub.

Boots the node in remote mode against a hub that (phase 1) answers every RPC
with malformed JSON and (phase 2) drops the connection mid-suite. Federation is
best-effort: a broken hub must never take the world down. After each phase we
assert /health stays 200, the process is still running, and player commands
still return a local answer (whoami reads back the local self, travel/listen/
who/gridcast do not crash).

Usage: ws_remote_hub_resilience.py /path/to/hollow-grid-asm
"""
import os
import socket
import subprocess
import sys
import tempfile
import threading
import time
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from ws_common import connect, send_text

# Shared, flipped by main between phases.
MODE = {"v": "malformed"}


class HostileHub(BaseHTTPRequestHandler):
    def log_message(self, _format, *_args):
        return

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        try:
            self.rfile.read(length)
        except OSError:
            return
        mode = MODE["v"]
        if mode == "drop":
            # Abrupt close: curl sees a reset, rpc_call must fail open.
            try:
                self.connection.close()
            except OSError:
                pass
            return
        if mode == "http_error":
            self.send_response(503)
            self.end_headers()
            return
        # malformed: 200 OK but a body cJSON cannot parse.
        body = b'{"ok":true,"result": this is not <<< json'
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        try:
            self.wfile.write(body)
        except OSError:
            pass


def read_until(ws, needle: str, limit: int = 120) -> str:
    transcript = ""
    for _ in range(limit):
        try:
            transcript += ws.recv_text()
        except socket.timeout:
            continue
        if needle in transcript:
            return transcript
    raise RuntimeError(f"did not receive {needle!r}: {transcript[-400:]!r}")


def wait_health(port: int, server: subprocess.Popen | None = None) -> str:
    for _ in range(80):
        if server is not None and server.poll() is not None:
            raise RuntimeError(
                f"resilience server exited during boot (code {server.returncode})"
            )
        try:
            with urllib.request.urlopen(
                f"http://127.0.0.1:{port}/health", timeout=0.3
            ) as response:
                if response.status == 200:
                    return response.read().decode()
        except OSError:
            pass
        time.sleep(0.1)
    raise RuntimeError("resilience server did not become healthy")


def login(port: int, name: str):
    ws = connect(port)
    read_until(ws, "wanderer?")
    send_text(ws.sock, name)
    first = read_until(ws, "@event")
    if "char.create" in first:
        send_text(ws.sock, "1")
        read_until(ws, "@event room.info")
    return ws


def drain(ws, rounds: int = 6) -> None:
    """Best-effort: pull whatever the command produced without asserting a
    specific event. Hub-dependent commands legitimately emit only fail-open
    prose (no @event) when the hub is broken; the point is they must answer
    without hanging or crashing the process."""
    for _ in range(rounds):
        try:
            ws.recv_text()
        except socket.timeout:
            return


def exercise(port: int, name: str) -> None:
    """Run the fail-open player surface; nothing here may hang or crash."""
    ws = login(port, name)
    # whoami must fail open to the local self even with the hub broken.
    send_text(ws.sock, "whoami")
    who = read_until(ws, "@event char.identity")
    if f'"name":"{name}"' not in who:
        raise RuntimeError(f"whoami did not fail open to local self: {who[-200:]}")
    # who is local-first (presence merge is best-effort), so it still emits.
    send_text(ws.sock, "who")
    read_until(ws, "@event grid.who")
    # Hub-dependent commands: assert only that they answer (no hang/crash).
    for command in ("listen", "worlds", "ping all", "gridcast still standing"):
        send_text(ws.sock, command)
        drain(ws)
    ws.sock.close()


def main() -> None:
    binary = sys.argv[1]
    mud_port = int(os.environ.get("HG_RESIL_PORT", "18797"))
    hub_port = int(os.environ.get("HG_RESIL_HUB_PORT", "18798"))
    hub = ThreadingHTTPServer(("127.0.0.1", hub_port), HostileHub)
    hub_thread = threading.Thread(target=hub.serve_forever, daemon=True)
    hub_thread.start()
    with tempfile.TemporaryDirectory() as data:
        env = os.environ.copy()
        env.update(
            {
                "GRID_HUB_URL": f"http://127.0.0.1:{hub_port}",
                "GRID_HUB_TOKEN": "test-token",
                "WORLD_URL": f"ws://127.0.0.1:{mud_port}/ws",
            }
        )
        server = subprocess.Popen(
            [binary, "--addr", f"127.0.0.1:{mud_port}", "--data", data],
            env=env,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        try:
            wait_health(mud_port, server)

            MODE["v"] = "malformed"
            exercise(mud_port, "MalformHero")
            if server.poll() is not None:
                raise RuntimeError("server exited under malformed hub JSON")
            wait_health(mud_port, server)

            MODE["v"] = "http_error"
            exercise(mud_port, "ErrorHero")
            wait_health(mud_port, server)

            MODE["v"] = "drop"
            exercise(mud_port, "DropHero")
            if server.poll() is not None:
                raise RuntimeError("server exited when the hub dropped connections")
            body = wait_health(mud_port, server)
            if '"ok":true' not in body:
                raise RuntimeError(f"health not ok after hostile hub: {body}")
        finally:
            server.terminate()
            try:
                server.wait(timeout=5)
            except subprocess.TimeoutExpired:
                server.kill()
            hub.shutdown()
            hub.server_close()
    print("remote hub resilience checks passed")


if __name__ == "__main__":
    main()
