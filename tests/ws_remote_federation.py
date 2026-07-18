#!/usr/bin/env python3
"""Remote Grid Hub regression checks for canonical identity and federation."""
import json
import os
import socket
import subprocess
import sys
import tempfile
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from ws_common import connect, send_text


CHARACTERS = {
    "RemoteHero": {
        "level": 3,
        "xp": 40,
        "gold": 55,
        "faction": "ally",
        "morality": 25,
        "title": "the Carried",
        "race": "elf",
        "ashsworn": False,
    }
}


class HubHandler(BaseHTTPRequestHandler):
    def log_message(self, _format, *_args):
        return

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        body = json.loads(self.rfile.read(length))
        method = body.get("method")
        params = body.get("params", [])
        result = None
        if method == "tide":
            result = 17
        elif method == "recent":
            result = [
                {
                    "world": "Dustfall",
                    "node": "nexus",
                    "kind": "passage",
                    "text": "A distant relay answers from the dust.",
                    "at": int(time.time() * 1000),
                }
            ]
        elif method == "recentAcross":
            result = []
        elif method == "loadCharacter":
            result = CHARACTERS.setdefault(
                params[0],
                {
                    "level": 1,
                    "xp": 0,
                    "gold": 20,
                    "faction": "none",
                    "morality": 0,
                    "title": "",
                    "race": "",
                    "ashsworn": False,
                },
            )
        elif method == "commitCharacter":
            CHARACTERS[params[0]] = params[1]
            result = params[1]
        elif method == "presence":
            result = [
                {
                    "world": "Dustfall",
                    "name": "DustWalker",
                    "regard": "trusted",
                    "title": "the Far",
                    "at": int(time.time() * 1000),
                }
            ]
        elif method == "listWorlds":
            result = []
        elif method == "castsSince":
            result = []
        elif method == "ledgerStats":
            result = []
        elif method == "pruneLedgerKinds":
            result = {"removed": 0}
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps({"ok": True, "result": result}).encode())


def read_until(ws, needle: str, limit: int = 80) -> str:
    transcript = ""
    for _ in range(limit):
        try:
            transcript += ws.recv_text()
        except socket.timeout:
            continue
        if needle in transcript:
            return transcript
    raise RuntimeError(f"did not receive {needle!r}: {transcript!r}")


def wait_health(port: int) -> None:
    import urllib.request

    for _ in range(80):
        try:
            with urllib.request.urlopen(
                f"http://127.0.0.1:{port}/health", timeout=0.2
            ) as response:
                if response.status == 200:
                    return
        except OSError:
            time.sleep(0.1)
    raise RuntimeError("remote-federation server did not become healthy")


def main() -> None:
    binary = sys.argv[1]
    mud_port = int(os.environ.get("HG_REMOTE_TEST_PORT", "18794"))
    hub_port = int(os.environ.get("HG_REMOTE_HUB_PORT", "18795"))
    hub = ThreadingHTTPServer(("127.0.0.1", hub_port), HubHandler)
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
            wait_health(mud_port)
            ws = connect(mud_port)
            read_until(ws, "wanderer?")
            send_text(ws.sock, "RemoteHero")
            resumed = read_until(ws, "@event room.info")
            if "char.create" in resumed:
                raise RuntimeError("canonical remote character asked for a new race")
            send_text(ws.sock, "whoami")
            identity = read_until(ws, "@event char.identity")
            for expected in ('"faction":"ally"', '"race":"elf"'):
                if expected not in identity:
                    raise RuntimeError(f"remote identity missing {expected}: {identity}")
            send_text(ws.sock, "listen")
            heard = read_until(ws, "@event grid.transmission")
            if '"kind":"echo"' not in heard or "distant relay" not in heard:
                raise RuntimeError(f"remote listen did not read hub trace: {heard}")
            send_text(ws.sock, "who")
            roster = read_until(ws, "@event grid.who")
            if (
                '"world":"Dustfall"' not in roster
                or '"name":"DustWalker"' not in roster
                or '"here":false' not in roster
            ):
                raise RuntimeError(f"remote who omitted federated presence: {roster}")
            ws.sock.close()

            fresh = connect(mud_port)
            read_until(fresh, "wanderer?")
            send_text(fresh.sock, "CommitHero")
            read_until(fresh, "char.create")
            send_text(fresh.sock, "1")
            read_until(fresh, "@event room.info")
            send_text(fresh.sock, "north")
            read_until(fresh, '"id":"market"')
            send_text(fresh.sock, "defend")
            read_until(fresh, '"faction":"ally"')
            fresh.sock.close()
            for _ in range(30):
                if CHARACTERS.get("CommitHero", {}).get("faction") == "ally":
                    break
                time.sleep(0.1)
            else:
                raise RuntimeError(
                    f"canonical commit missing ally state: {CHARACTERS.get('CommitHero')}"
                )
        finally:
            server.terminate()
            server.wait(timeout=5)
            hub.shutdown()
            hub.server_close()
    print("remote federation checks passed")


if __name__ == "__main__":
    main()
