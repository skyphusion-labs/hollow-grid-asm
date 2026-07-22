#!/usr/bin/env python3
"""Regression for #11/#12/#13/#15/#16: bounds, prose, persistence, WS input."""
from __future__ import annotations

import json
import os
import socket
import struct
import sys
import time
import uuid

from ws_common import ADMIN_TOKEN, TEST_PASSPHRASE, complete_login, connect, send_text


def send_fragmented(sock: socket.socket, first: str, second: str) -> None:
    """Send one text message split into two WebSocket fragments (#16b)."""
    for opcode, fin, chunk in ((0x1, 0x00, first), (0x0, 0x80, second)):
        payload = chunk.encode("utf-8")
        mask = os.urandom(4)
        header = bytearray([fin | opcode])
        if len(payload) < 126:
            header.append(0x80 | len(payload))
        else:
            header.append(0x80 | 126)
            header.extend(struct.pack("!H", len(payload)))
        header.extend(mask)
        header.extend(v ^ mask[i % 4] for i, v in enumerate(payload))
        sock.sendall(header)


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
    complete_login(ws, name)
    return ws


def wait_record(path: str, title: str, timeout: float = 5.0) -> dict:
    deadline = time.monotonic() + timeout
    last_error: Exception | None = None
    while time.monotonic() < deadline:
        try:
            with open(path, encoding="utf-8") as handle:
                record = json.load(handle)
            if record.get("title") == title:
                return record
        except (FileNotFoundError, json.JSONDecodeError) as error:
            last_error = error
        time.sleep(0.05)
    raise RuntimeError(f"record did not persist title {title!r}: {path}") from last_error


def main() -> None:
    port = int(sys.argv[1])
    data_dir = sys.argv[2]
    name = f"AsmHard{uuid.uuid4().hex[:8]}"
    path = os.path.join(data_dir, "characters", f"{name.lower()}.json")

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

    # Fragmented command must reassemble into one command, not two (#16b).
    send_fragmented(ws.sock, "inven", "tory")
    frag = read_until(ws, "You carry:")
    if "You carry: shiv." not in frag:
        raise RuntimeError(f"fragmented command mis-parsed: {frag!r}")

    # Oversize input must be answered, never silently truncated (#16b).
    send_text(ws.sock, "say " + "B" * 300)
    read_until(ws, "Input too long")

    send_text(ws.sock, "title Courier")
    read_until(ws, "Your title is now: Courier.")
    ws.sock.close()
    record = wait_record(path, "Courier")

    # Server must still accept a new connection (no remote crash).
    ws2 = login(port, f"AsmHard{uuid.uuid4().hex[:8]}")
    send_text(ws2.sock, "inventory")
    inv2 = read_until(ws2, "You carry:")
    if "You flash credentials" in inv2:
        raise RuntimeError(f"inventory still leaking: {inv2!r}")
    ws2.sock.close()

    # Resume original character: title persisted, inventory still real (#13).
    resume = connect(port)
    complete_login(resume, name)
    resume.sock.close()

    if record.get("title") != "Courier":
        raise RuntimeError(f"title not persisted: {record!r}")
    if record.get("inventory") != ["shiv"]:
        raise RuntimeError(f"inventory stub/persistence wrong: {record!r}")

    print("WebSocket hardening checks passed")


if __name__ == "__main__":
    main()
