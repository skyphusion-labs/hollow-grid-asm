#!/usr/bin/env python3
"""WebSocket gameplay checks for Basalt Relay (assert on @event, not prose)."""
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


def must_contain(label: str, text: str, *needles: str) -> None:
    for needle in needles:
        if needle not in text:
            raise RuntimeError(f"{label}: missing {needle!r} in {text!r}")


def main() -> None:
    port = int(sys.argv[1])
    name = f"AsmPlay{uuid.uuid4().hex[:8]}"
    ws = login(port, name)

    send_text(ws.sock, "wield shiv")
    must_contain(
        "wield",
        read_until(ws, "@event char.equipment"),
        '"weapon":"shiv"',
    )

    send_text(ws.sock, "remove")
    must_contain(
        "remove",
        read_until(ws, "@event char.equipment"),
        '"weapon":null',
    )
    send_text(ws.sock, "wield shiv")
    read_until(ws, '"weapon":"shiv"')

    send_text(ws.sock, "down")
    must_contain(
        "tunnels",
        read_until(ws, '"id":"tunnels"'),
        "glow-rat",
        '"inCombat":false',
    )

    send_text(ws.sock, "attack rat")
    start = read_until(ws, "@event combat.start")
    must_contain(
        "combat start",
        start,
        '"mob":"rat"',
        '"inCombat":true',
    )

    deadline = time.time() + 20
    transcript = start
    saw_round = "@event combat.round" in transcript

    def combat_resolved(text: str) -> bool:
        return "@event combat.end" in text and '"result":"killed"' in text

    if not combat_resolved(transcript):
        while time.time() < deadline:
            try:
                transcript += ws.recv_text()
            except socket.timeout:
                continue
            if "@event combat.round" in transcript:
                saw_round = True
            if combat_resolved(transcript):
                break
        else:
            raise RuntimeError(f"combat did not resolve: {transcript!r}")
    if not saw_round:
        raise RuntimeError(f"missing combat.round: {transcript!r}")
    must_contain("post-kill", transcript, '"inCombat":false')

    send_text(ws.sock, "up")
    read_until(ws, '"id":"nexus"')
    send_text(ws.sock, "north")
    read_until(ws, '"id":"market"')
    send_text(ws.sock, "join")
    must_contain(
        "join",
        read_until(ws, '"faction":"front"'),
        '"faction":"front"',
    )

    send_text(ws.sock, "sleep")
    must_contain("sleep", read_until(ws, "@event char.dream"), "char.dream")

    ws.sock.close()
    print("gameplay checks passed")


if __name__ == "__main__":
    main()
