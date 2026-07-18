#!/usr/bin/env python3
"""Shared WebSocket helpers that keep a byte buffer across timeouts."""
from __future__ import annotations

import base64
import os
import socket
import struct


class WsClient:
    def __init__(self, sock: socket.socket) -> None:
        self.sock = sock
        self.buf = bytearray()

    def _pull(self) -> bool:
        try:
            chunk = self.sock.recv(4096)
        except socket.timeout:
            return False
        if not chunk:
            raise RuntimeError("socket closed")
        self.buf.extend(chunk)
        return True

    def recv_text(self) -> str:
        while True:
            while len(self.buf) < 2:
                if not self._pull():
                    raise socket.timeout
            first, second = self.buf[0], self.buf[1]
            opcode = first & 0x0F
            length = second & 0x7F
            hdr = 2
            if length == 126:
                while len(self.buf) < 4:
                    if not self._pull():
                        raise socket.timeout
                length = struct.unpack("!H", self.buf[2:4])[0]
                hdr = 4
            elif length == 127:
                while len(self.buf) < 10:
                    if not self._pull():
                        raise socket.timeout
                length = struct.unpack("!Q", self.buf[2:10])[0]
                hdr = 10
            mask_len = 4 if second & 0x80 else 0
            total = hdr + mask_len + length
            while len(self.buf) < total:
                if not self._pull():
                    raise socket.timeout
            frame = bytes(self.buf[:total])
            del self.buf[:total]
            payload = frame[hdr + mask_len :]
            if mask_len:
                mask = frame[hdr : hdr + 4]
                payload = bytes(
                    value ^ mask[index % 4] for index, value in enumerate(payload)
                )
            if opcode == 0x8:
                raise RuntimeError("server closed WebSocket")
            if opcode != 0x1:
                continue
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
    header.extend(value ^ mask[index % 4] for index, value in enumerate(payload))
    sock.sendall(header)


def connect(port: int) -> WsClient:
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
        chunk = sock.recv(1)
        if not chunk:
            raise RuntimeError("socket closed during upgrade")
        response.extend(chunk)
    if not response.startswith(b"HTTP/1.1 101"):
        raise RuntimeError(f"WebSocket upgrade failed: {response!r}")
    sock.settimeout(0.5)
    return WsClient(sock)
