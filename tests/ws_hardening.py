#!/usr/bin/env python3
"""Regression for #11/#12/#13/#15: title bound, inventory prose, persistence."""
from __future__ import annotations

import json
import os
import socket
import sys
import time
import uuid

from ws_common import connect, send_text


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


def login(port: int, name: str):
    ws = connect(port)
    read_until(ws, "wanderer?")
    send_text(ws.sock, name)
    read_until(ws, "char.create")
    send_text(ws.sock, "1")
    read_until(ws, "@event room.info")
    return ws


def main() -> None:
    port = int(sys.argv[1])
    data_dir = sys.argv[2]
    name = f"AsmHard{uuid.uuid4().hex[:8]}"

    ws = login(port, name)

    send_text(ws.sock, "inventory")
    inv = read_until(ws, "You carry:")
    if "You carry: shiv.\r\n" not in inv and "You carry: shiv.\n" not in inv:
        # Accept either CRLF-only frame or embedded CRLF in a larger frame.
        if "You carry: shiv." not in inv:
            raise RuntimeError(f"inventory missing expected prose: {inv!r}")
    if "You flash credentials" in inv or "Requisition" in inv:
        raise RuntimeError(f"inventory leaked adjacent rodata: {inv!r}")

    # Oversize title must truncate, not segfault the process (#11).
    long_title = "A" * 200
    send_text(ws.sock, f"title {long_title}")
    read_until(ws, "Your title is now:")
    send_text(ws.sock, "equipment")
    eq = read_until(ws, "@event char.equipment")
    if '"weapon"' not in eq:
        raise RuntimeError(f"equipment event broken after long title: {eq!r}")
    # Truncated title is 47 chars; equipment JSON must remain parseable.
    for line in eq.splitlines():
        if line.startswith("@event char.equipment "):
            json.loads(line[len("@event char.equipment ") :])
            break
    else:
        raise RuntimeError(f"no char.equipment line after long title: {eq!r}")

    send_text(ws.sock, "title Courier")
    read_until(ws, "Your title is now: Courier.")
    ws.sock.close()
    time.sleep(0.25)

    # Server must still accept a new connection (no remote crash).
    ws2 = login(port, f"AsmHard{uuid.uuid4().hex[:8]}")
    send_text(ws2.sock, "inventory")
    inv2 = read_until(ws2, "You carry:")
    if "You flash credentials" in inv2:
        raise RuntimeError(f"inventory still leaking: {inv2!r}")
    ws2.sock.close()

    # Resume original character: title persisted, inventory still real (#13).
    resume = connect(port)
    read_until(resume, "wanderer?")
    send_text(resume.sock, name)
    resumed = read_until(resume, "@event room.info")
    if "char.create" in resumed:
        raise RuntimeError("returning character asked to choose a race")
    resume.sock.close()
    time.sleep(0.25)

    path = os.path.join(data_dir, "characters", f"{name.lower()}.json")
    with open(path, encoding="utf-8") as handle:
        record = json.load(handle)
    if record.get("title") != "Courier":
        raise RuntimeError(f"title not persisted: {record!r}")
    if record.get("inventory") != ["shiv"]:
        raise RuntimeError(f"inventory stub/persistence wrong: {record!r}")

    print("WebSocket hardening checks passed")


if __name__ == "__main__":
    main()
