#!/usr/bin/env python3
import base64
import json
import os
import socket
import struct
import sys
import time


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
    return sock


def read_until(sock: socket.socket, needle: str, limit: int = 12) -> str:
    transcript = ""
    for _ in range(limit):
        transcript += recv_text(sock)
        if needle in transcript:
            return transcript
    raise RuntimeError(f"did not receive {needle!r}: {transcript!r}")


def wait_record(path: str, room_index: int, timeout: float = 5.0) -> dict:
    deadline = time.monotonic() + timeout
    last_error: Exception | None = None
    while time.monotonic() < deadline:
        try:
            with open(path, encoding="utf-8") as handle:
                record = json.load(handle)
            if record.get("roomIndex") == room_index:
                return record
        except (FileNotFoundError, json.JSONDecodeError) as error:
            last_error = error
        time.sleep(0.05)
    raise RuntimeError(
        f"record did not reach roomIndex {room_index}: {path}"
    ) from last_error


def complete_new_character(sock: socket.socket, race: str, phrase: str) -> None:
    read_until(sock, "char.create")
    send_text(sock, race)
    read_until(sock, "secret phrase")
    send_text(sock, phrase)


def complete_resume(sock: socket.socket, phrase: str) -> None:
    read_until(sock, "secret phrase")
    send_text(sock, phrase)


def main() -> None:
    port = int(sys.argv[1])
    data_dir = sys.argv[2]
    name = "PersistAsm"
    phrase = "persist-test-phrase"
    path = os.path.join(data_dir, "characters", "persistasm.json")

    first = connect(port)
    read_until(first, "wanderer?")
    send_text(first, name)
    complete_new_character(first, "Human", phrase)
    read_until(first, '"id":"nexus"')
    send_text(first, "down")
    read_until(first, '"id":"tunnels"')
    first.close()
    wait_record(path, 6)

    second = connect(port)
    read_until(second, "wanderer?")
    send_text(second, name)
    complete_resume(second, phrase)
    resumed = read_until(second, '"id":"tunnels"')
    if "char.create" in resumed:
        raise RuntimeError("returning character was asked to choose a race")
    for command, room_id in (
        ("up", "nexus"),
        ("east", "workshop"),
        ("up", "roof"),
        ("east", "relay-cut"),
    ):
        send_text(second, command)
        read_until(second, f'"id":"{room_id}"')
    second.close()
    record = wait_record(path, 24)

    assert record["name"] == name
    assert record["race"] == "human"
    assert record["roomIndex"] == 24
    assert record["hp"] == 30
    assert record["inventory"] == ["shiv"]
    assert record.get("secretHash")
    print("WebSocket persistence checks passed")


if __name__ == "__main__":
    main()

