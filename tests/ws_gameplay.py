#!/usr/bin/env python3
"""WebSocket gameplay checks for Basalt Relay (assert on @event, not prose)."""
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
    read_until(sock, "@event room.info")
    return sock


def must_contain(label: str, text: str, *needles: str) -> None:
    for needle in needles:
        if needle not in text:
            raise RuntimeError(f"{label}: missing {needle!r} in {text!r}")


def main() -> None:
    port = int(sys.argv[1])
    name = f"AsmPlay{uuid.uuid4().hex[:8]}"
    sock = login(port, name)

    send_text(sock, "wield shiv")
    must_contain(
        "wield",
        read_until(sock, "@event char.equipment"),
        '"weapon":"shiv"',
    )

    send_text(sock, "remove")
    must_contain(
        "remove",
        read_until(sock, "@event char.equipment"),
        '"weapon":null',
    )
    send_text(sock, "wield shiv")
    read_until(sock, '"weapon":"shiv"')

    send_text(sock, "down")
    must_contain(
        "tunnels",
        read_until(sock, '"id":"tunnels"'),
        "luminous rat",
        '"inCombat":false',
    )

    send_text(sock, "attack rat")
    start = read_until(sock, "@event combat.start")
    must_contain(
        "combat start",
        start,
        '"mob":"rat"',
        '"inCombat":true',
    )

    deadline = time.time() + 12
    transcript = start
    saw_round = "@event combat.round" in transcript

    def combat_resolved(text: str) -> bool:
        return (
            "@event combat.end" in text
            and '"result":"killed"' in text
        )

    if combat_resolved(transcript):
        pass
    else:
        while time.time() < deadline:
            try:
                transcript += recv_text(sock)
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

    send_text(sock, "up")
    read_until(sock, '"id":"nexus"')
    send_text(sock, "north")
    read_until(sock, '"id":"market"')
    send_text(sock, "join")
    must_contain(
        "join",
        read_until(sock, '"faction":"front"'),
        '"faction":"front"',
    )

    send_text(sock, "sleep")
    must_contain("sleep", read_until(sock, "@event char.dream"), "char.dream")

    sock.close()
    print("gameplay checks passed")


if __name__ == "__main__":
    main()
