#!/usr/bin/env python3
"""LocalHub soak: federation crash hardening for the in-memory rings.

Floods the node with >200 gridcasts (past GL_MAX_CASTS = 200, the ring the
(gl_next_cast - 1) % MAX fix walks instead of pinning slot 0), then reads back
the full LocalHub surface (saved / witness / ping / gridstats / who) and a
final /health to assert the process survived the wrap and still answers.

The keeper is named to match a per-run ADMINS value so this also exercises the
asm-owned admin gate (hg_is_admin) on gridstats. Runtime is capped: the flood
confirms each cast round-trips by its unique marker, so no fixed sleeps.

Usage: ws_localhub_soak.py /path/to/hollow-grid-asm
"""
import os
import socket
import subprocess
import sys
import tempfile
import urllib.request

from ws_common import connect, send_text

CASTS = 260  # > GL_MAX_CASTS (200) so the ring wraps at least once


def read_until(ws, needle: str, limit: int = 200) -> str:
    transcript = ""
    for _ in range(limit):
        try:
            transcript += ws.recv_text()
        except socket.timeout:
            continue
        if needle in transcript:
            return transcript
    raise RuntimeError(f"did not receive {needle!r}: {transcript[-400:]!r}")


def login(port: int, name: str):
    ws = connect(port)
    read_until(ws, "wanderer?")
    send_text(ws.sock, name)
    first = read_until(ws, "@event")
    if "char.create" in first:
        send_text(ws.sock, "1")
        read_until(ws, "@event room.info")
    return ws


def wait_health(port: int) -> str:
    for _ in range(80):
        try:
            with urllib.request.urlopen(
                f"http://127.0.0.1:{port}/health", timeout=0.2
            ) as response:
                if response.status == 200:
                    return response.read().decode()
        except OSError:
            pass
    raise RuntimeError("soak server did not become healthy")


def main() -> None:
    binary = sys.argv[1]
    port = int(os.environ.get("HG_SOAK_PORT", "18796"))
    keeper = "SoakKeeper"
    with tempfile.TemporaryDirectory() as data:
        env = os.environ.copy()
        # LocalHub mode: no GRID_HUB_URL. Keeper gate is asm-owned; set ADMINS
        # so the keeper name passes hg_is_admin and gridstats is allowed.
        env.pop("GRID_HUB_URL", None)
        env["ADMINS"] = keeper
        server = subprocess.Popen(
            [binary, "--addr", f"127.0.0.1:{port}", "--data", data],
            env=env,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        try:
            wait_health(port)
            ws = login(port, keeper)

            # Non-keeper must be refused gridstats (asm admin gate, negative).
            drifter = login(port, "Drifter")
            send_text(drifter.sock, "gridstats")
            refused = read_until(drifter, "keeper")
            if "@event grid.ledger_stats" in refused:
                raise RuntimeError("non-keeper was allowed to read ledger stats")
            drifter.sock.close()

            # Flood past the cast ring capacity; each cast carries a unique
            # marker we read back to confirm it was processed (no fixed sleep).
            for i in range(CASTS):
                marker = f"soak-{i}"
                send_text(ws.sock, f"gridcast {marker}")
                read_until(ws, marker)

            # Read back the full LocalHub surface after the wrap. Each must
            # still answer -- the process survived the saturated ring.
            send_text(ws.sock, "ping")
            read_until(ws, "@event grid.echo")
            send_text(ws.sock, "witness")
            read_until(ws, "@event grid.fallen")
            send_text(ws.sock, "saved")
            # saved emits an event only when the rescued roll is non-empty;
            # the empty-roll prose still mentions the cages. Either proves the
            # ring read did not crash.
            read_until(ws, "cages")
            send_text(ws.sock, "gridstats")
            read_until(ws, "@event grid.ledger_stats")
            send_text(ws.sock, "who")
            read_until(ws, "@event grid.who")
            ws.sock.close()

            body = wait_health(port)
            if '"ok":true' not in body:
                raise RuntimeError(f"health not ok after soak: {body}")
            if server.poll() is not None:
                raise RuntimeError("server exited during soak")
        finally:
            server.terminate()
            try:
                server.wait(timeout=5)
            except subprocess.TimeoutExpired:
                server.kill()
    print("localhub soak checks passed")


if __name__ == "__main__":
    main()
