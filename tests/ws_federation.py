#!/usr/bin/env python3
"""WebSocket federation checks for Basalt Relay (LocalHub path, no
GRID_HUB_URL). Exercises listen/ping/worlds/whoami/travel and the rat-kill
hub record, asserting on @event lines rather than prose where possible."""
import base64
import os
import socket
import struct
import sys
import time
import uuid


def recv_exact(sock: socket.socket, length: int) -> bytes:
    chunks = bytearray()
    while len(chunks) < length:
        chunk = sock.recv(length - len(chunks))
        if not chunk:
            raise RuntimeError("socket closed before frame completed")
        chunks.extend(chunk)
    return bytes(chunks)


def recv_text(sock: socket.socket) -> str:
    first, second = recv_exact(sock, 2)
    opcode = first & 0x0F
    length = second & 0x7F
    if length == 126:
        length = struct.unpack("!H", recv_exact(sock, 2))[0]
    elif length == 127:
        length = struct.unpack("!Q", recv_exact(sock, 8))[0]
    if second & 0x80:
        mask = recv_exact(sock, 4)
        payload = bytes(
            value ^ mask[index % 4]
            for index, value in enumerate(recv_exact(sock, length))
        )
    else:
        payload = recv_exact(sock, length)
    if opcode == 0x8:
        raise RuntimeError("server closed WebSocket")
    if opcode != 0x1:
        return ""
    return payload.decode("utf-8")


def send_text(sock: socket.socket, text: str) -> None:
    payload = text.encode("utf-8")
    mask = os.urandom(4)
    header = bytearray([0x81])
    if len(payload) < 126:
        header.append(0x80 | len(payload))
    elif len(payload) < 65536:
        header.append(0x80 | 126)
        header.extend(struct.pack("!H", len(payload)))
    else:
        header.append(0x80 | 127)
        header.extend(struct.pack("!Q", len(payload)))
    header.extend(mask)
    header.extend(
        value ^ mask[index % 4] for index, value in enumerate(payload)
    )
    sock.sendall(header)


def connect(port: int) -> socket.socket:
    sock = socket.create_connection(("127.0.0.1", port), timeout=5)
    key = base64.b64encode(os.urandom(16)).decode("ascii")
    request = (
        "GET /ws HTTP/1.1\r\n"
        f"Host: 127.0.0.1:{port}\r\n"
        "Upgrade: websocket\r\n"
        "Connection: Upgrade\r\n"
        f"Sec-WebSocket-Key: {key}\r\n"
        "Sec-WebSocket-Version: 13\r\n\r\n"
    )
    sock.sendall(request.encode("ascii"))
    response = bytearray()
    while b"\r\n\r\n" not in response:
        response.extend(recv_exact(sock, 1))
    if not response.startswith(b"HTTP/1.1 101"):
        raise RuntimeError(f"WebSocket upgrade failed: {response!r}")
    sock.settimeout(8)
    return sock


def read_until(sock: socket.socket, needle: str, limit: int = 40) -> str:
    transcript = ""
    for _ in range(limit):
        transcript += recv_text(sock)
        if needle in transcript:
            return transcript
    raise RuntimeError(f"did not receive {needle!r}: {transcript!r}")


def login(port: int, name: str) -> socket.socket:
    sock = connect(port)
    read_until(sock, "wanderer?")
    send_text(sock, name)
    read_until(sock, "char.create")
    send_text(sock, "1")
    read_until(sock, "secret phrase")
    send_text(sock, "ci-test-passphrase")
    read_until(sock, "@event room.info")
    return sock


def must_contain(label: str, text: str, *needles: str) -> None:
    for needle in needles:
        if needle not in text:
            raise RuntimeError(f"{label}: missing {needle!r} in {text!r}")


def main() -> None:
    port = int(sys.argv[1])
    name = f"AsmGrid{uuid.uuid4().hex[:8]}"
    sock = login(port, name)

    # worlds: listWorlds seeds Saltreach + Dustfall + self in LocalHub mode.
    send_text(sock, "worlds")
    worlds = read_until(sock, "@event grid.worlds")
    must_contain(
        "worlds",
        worlds,
        "@event grid.worlds",
        '"id":"Dustfall"',
        '"id":"Saltreach"',
        "Basalt Relay",
    )

    # Travel with no target and gate both fall back to the worlds listing.
    send_text(sock, "gate")
    read_until(sock, "@event grid.worlds")

    # listen: LocalHub is seeded with cross-world traces, so this must not be
    # the "empty" branch.
    send_text(sock, "listen")
    heard = read_until(sock, "@event grid.transmission")
    must_contain("listen", heard, '"kind":"echo"')

    # ping (room-scoped local echo): starts out with nothing recorded here.
    send_text(sock, "ping")
    ping_empty = read_until(sock, "@event grid.echo")
    must_contain("ping empty", ping_empty, '"traces":[]')

    # ping all: recentAcross the seeded federation traces.
    send_text(sock, "ping all")
    ping_all = read_until(sock, "@event grid.federation")
    must_contain(
        "ping all",
        ping_all,
        "@event grid.federation",
        '"world":"Dustfall"',
    )

    # whoami: char sheet, LocalHub mode never calls loadCharacter.
    send_text(sock, "whoami")
    who = read_until(sock, "@event char.identity")
    must_contain(
        "whoami",
        who,
        "@event char.identity",
        f'"name":"{name}"',
        '"level":1',
    )
    send_text(sock, "identity")
    read_until(sock, "@event char.identity")

    # Kill the rat, then ping this room: the kill should now show up as a
    # room-local echo (hg_grid_on_kill + local echo, wired in combat.asm).
    # foundation.sh runs this after ws_gameplay.py against the SAME server
    # process, which already killed the rat once; wait out its ~20s respawn
    # timer (hg_heartbeat) rather than assume it's alive.
    send_text(sock, "down")
    read_until(sock, '"id":"tunnels"')

    def combat_resolved(text: str) -> bool:
        return "@event combat.end" in text and '"result":"killed"' in text

    attack_deadline = time.time() + 25
    transcript = ""
    sock.settimeout(2)
    while True:
        send_text(sock, "attack rat")
        chunk = ""
        try:
            while "@event combat.start" not in chunk and (
                "nothing like that here to attack" not in chunk
            ):
                chunk += recv_text(sock)
        except socket.timeout:
            # Timeout is expected while waiting for combat.start or rat
            # respawn; the outer loop retries until the deadline.
            pass
        transcript = chunk
        if "@event combat.start" in transcript:
            break
        if time.time() >= attack_deadline:
            raise RuntimeError("rat never respawned in time")
        time.sleep(1)
    sock.settimeout(8)

    deadline = time.time() + 12
    if not combat_resolved(transcript):
        while time.time() < deadline:
            try:
                transcript += recv_text(sock)
            except socket.timeout:
                continue
            if combat_resolved(transcript):
                break
        else:
            raise RuntimeError(f"combat did not resolve: {transcript!r}")

    send_text(sock, "ping")
    room_echo = read_until(sock, "@event grid.echo")
    must_contain(
        "ping after kill",
        room_echo,
        '"kind":"slain"',
        "slew a glow-rat",
    )

    # A successful handoff is terminal: emit the destination, then close so a
    # client can reconnect there immediately.
    send_text(sock, "travel Dustfall")
    travel = read_until(sock, "@event grid.travel")
    must_contain(
        "travel",
        travel,
        '"to":"Dustfall"',
        "dustfall.skyphusion.org",
    )
    for _ in range(20):
        try:
            recv_text(sock)
        except socket.timeout:
            continue
        except RuntimeError:
            break
    else:
        raise RuntimeError("travel did not close the WebSocket")

    sock.close()
    print("federation checks passed")


if __name__ == "__main__":
    main()
