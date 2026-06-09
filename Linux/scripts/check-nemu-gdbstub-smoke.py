#!/usr/bin/env python3
import argparse
import os
import socket
import subprocess
import sys
import time


def checksum(payload: bytes) -> int:
    return sum(payload) & 0xff


def packet(payload: str) -> bytes:
    body = payload.encode("ascii")
    return b"$" + body + b"#" + f"{checksum(body):02x}".encode("ascii")


def read_exact(sock: socket.socket, count: int) -> bytes:
    chunks = []
    remaining = count
    while remaining:
        chunk = sock.recv(remaining)
        if not chunk:
            raise RuntimeError("unexpected EOF from gdbstub")
        chunks.append(chunk)
        remaining -= len(chunk)
    return b"".join(chunks)


def recv_packet(sock: socket.socket) -> str:
    while True:
        ch = read_exact(sock, 1)
        if ch == b"$":
            break
    body = bytearray()
    while True:
        ch = read_exact(sock, 1)
        if ch == b"#":
            break
        body.extend(ch)
    got = int(read_exact(sock, 2), 16)
    want = checksum(body)
    if got != want:
        sock.sendall(b"-")
        raise RuntimeError(f"bad checksum: got {got:02x}, want {want:02x}")
    sock.sendall(b"+")
    return body.decode("ascii")


def send_packet(sock: socket.socket, payload: str) -> str:
    sock.sendall(packet(payload))
    ack = read_exact(sock, 1)
    if ack != b"+":
        raise RuntimeError(f"gdbstub rejected packet {payload!r}: ack={ack!r}")
    return recv_packet(sock)


def reserve_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind(("127.0.0.1", 0))
        return sock.getsockname()[1]


def connect_with_retry(port: int, deadline: float) -> socket.socket:
    last_error = None
    while time.monotonic() < deadline:
        try:
            sock = socket.create_connection(("127.0.0.1", port), timeout=1.0)
            sock.settimeout(5.0)
            return sock
        except OSError as exc:
            last_error = exc
            time.sleep(0.05)
    raise RuntimeError(f"could not connect to gdbstub on port {port}: {last_error}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Smoke-test NEMU's minimal GDB remote stub")
    parser.add_argument("--nemu", required=True)
    parser.add_argument("--log", required=True)
    parser.add_argument("--nemu-log", required=True)
    parser.add_argument("--monitor-cmd", default="info r")
    parser.add_argument("--timeout", type=float, default=10.0)
    args = parser.parse_args()

    os.makedirs(os.path.dirname(args.log), exist_ok=True)
    port = reserve_port()
    cmd = [
        args.nemu,
        f"--gdbstub={port}",
        f"--monitor-cmd={args.monitor_cmd}",
        f"--log={args.nemu_log}",
    ]

    with open(args.log, "w", encoding="utf-8") as log:
        log.write(f"command: {' '.join(cmd)}\n")
        proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
        try:
            with connect_with_retry(port, time.monotonic() + args.timeout) as sock:
                supported = send_packet(sock, "qSupported")
                if "PacketSize=" not in supported:
                    raise RuntimeError(f"qSupported missing PacketSize: {supported}")
                log.write(f"PASS qSupported {supported}\n")

                stop = send_packet(sock, "?")
                if stop != "S05":
                    raise RuntimeError(f"unexpected stop reply: {stop}")
                log.write(f"PASS stop-reason {stop}\n")

                regs = send_packet(sock, "g")
                if len(regs) < 33 * 16:
                    raise RuntimeError(f"register packet too short: {len(regs)}")
                log.write(f"PASS read-all-regs hex-bytes={len(regs)}\n")

                pc = send_packet(sock, "p20")
                if len(pc) != 16:
                    raise RuntimeError(f"pc register packet has unexpected length: {pc}")
                log.write(f"PASS read-pc {pc}\n")

                mem = send_packet(sock, "m80000000,4")
                if len(mem) != 8:
                    raise RuntimeError(f"memory packet has unexpected length: {mem}")
                log.write(f"PASS read-pmem-reset-vector {mem}\n")

                detach = send_packet(sock, "D")
                if detach != "OK":
                    raise RuntimeError(f"detach failed: {detach}")
                log.write("PASS detach OK\n")

            rc = proc.wait(timeout=args.timeout)
            if rc != 0:
                raise RuntimeError(f"NEMU exited with rc={rc}")
            log.write("PASS nemu-exit rc=0\n")
            log.write("__NEMU_GDBSTUB_SMOKE__:ok\n")
        except Exception:
            proc.kill()
            proc.wait(timeout=5)
            raise

    return 0


if __name__ == "__main__":
    sys.exit(main())
