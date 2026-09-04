#!/usr/bin/env python3
import argparse
import fcntl
import json
import os
import socket
import stat
import subprocess
import sys
import time


def reserve_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind(("127.0.0.1", 0))
        return sock.getsockname()[1]


def reserve_distinct_ports() -> tuple[int, int]:
    first = reserve_port()
    second = reserve_port()
    while second == first:
        second = reserve_port()
    return first, second


def run_qmp_gdbstub_conflict(args, log):
    qmp_port, gdbstub_port = reserve_distinct_ports()
    cmd = [
        args.nemu,
        f"--qmp={qmp_port}",
        f"--gdbstub={gdbstub_port}",
    ]
    log.write(f"qmp-gdbstub-conflict-command: {' '.join(cmd)}\n")
    try:
        completed = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=args.timeout,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError(
            "NEMU waited for a client instead of rejecting simultaneous QMP/GDB run-control"
        ) from exc
    output = completed.stdout or ""
    log.write(output)
    if completed.returncode == 0:
        raise RuntimeError("NEMU accepted simultaneous --qmp and --gdbstub")
    marker = "--qmp and --gdbstub cannot be enabled together"
    if marker not in output:
        raise RuntimeError(
            f"QMP/GDB conflict failed without the expected diagnostic: rc={completed.returncode}"
        )
    log.write(f"PASS qmp-gdbstub-mutually-exclusive rc={completed.returncode}\n")


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
    raise RuntimeError(f"could not connect to QMP on port {port}: {last_error}")


def recv_json_line(sock_file) -> dict:
    line = sock_file.readline()
    if not line:
        raise RuntimeError("unexpected EOF from QMP")
    return json.loads(line.decode("utf-8"))


def qmp_execute(sock, sock_file, command: str, events: list | None = None, request_id=None) -> dict:
    if request_id is None:
        request_id = f"qmp-smoke:{command}"
    payload = json.dumps(
        {"execute": command, "id": request_id},
        separators=(",", ":"),
    ).encode("utf-8") + b"\r\n"
    sock.sendall(payload)
    while True:
        reply = recv_json_line(sock_file)
        if "event" in reply:
            if events is not None:
                events.append(reply)
            continue
        if reply.get("id") != request_id:
            raise RuntimeError(f"{command} QMP id echo mismatch: expected={request_id!r} reply={reply}")
        return reply


def recv_event_until(sock_file, events: list, event: str, deadline: float) -> dict:
    while time.monotonic() < deadline:
        try:
            reply = recv_json_line(sock_file)
        except socket.timeout:
            continue
        if "event" in reply:
            events.append(reply)
            if reply.get("event") == event:
                return reply
            continue
        raise RuntimeError(f"unexpected QMP reply while waiting for {event}: {reply}")
    raise RuntimeError(f"timed out waiting for QMP event {event}: events={events}")


def require_return(reply: dict, command: str):
    if "return" not in reply:
        raise RuntimeError(f"{command} did not return success: {reply}")
    return reply["return"]


def require_event_count(events: list, event: str, expected: int, label: str, log):
    count = sum(1 for item in events if item.get("event") == event)
    if count != expected:
        raise RuntimeError(
            f"unexpected QMP event multiplicity {event}: "
            f"count={count} expected={expected} events={events}"
        )
    log.write(f"PASS {label} {event} count={count}\n")


def require_oversized_id_rejected(sock, sock_file, events: list, log):
    payload = json.dumps(
        {"execute": "query-status", "id": "x" * 300},
        separators=(",", ":"),
    ).encode("utf-8") + b"\r\n"
    sock.sendall(payload)
    while True:
        reply = recv_json_line(sock_file)
        if "event" in reply:
            events.append(reply)
            continue
        break
    error = reply.get("error")
    if (
        not isinstance(error, dict)
        or error.get("class") != "GenericError"
        or "request id" not in error.get("desc", "")
        or "id" in reply
    ):
        raise RuntimeError(f"oversized QMP id was not safely rejected: {reply}")
    # The malformed request must not poison or close the connection.
    status = require_return(
        qmp_execute(sock, sock_file, "query-status", events,
                    request_id="after-oversized-id"),
        "query-status",
    )
    if status.get("status") != "prelaunch":
        raise RuntimeError(f"QMP did not recover after oversized id: {status}")
    log.write("PASS qmp-oversized-id-rejected-and-connection-recovered\n")


def require_oversized_frame_rejected(sock, sock_file, events: list, log):
    # Put a destructive command before the receive-buffer boundary.  A reader
    # that dispatches its truncated prefix would shut NEMU down instead of
    # rejecting and draining the complete newline-delimited frame.
    payload = (
        b'{"execute":"system_powerdown","padding":"'
        + (b"x" * 8192)
        + b'"}\r\n'
    )
    sock.sendall(payload)
    while True:
        reply = recv_json_line(sock_file)
        if "event" in reply:
            events.append(reply)
            continue
        break
    error = reply.get("error")
    if (
        not isinstance(error, dict)
        or error.get("class") != "GenericError"
        or "oversized QMP request frame" not in error.get("desc", "")
        or "id" in reply
    ):
        raise RuntimeError(f"oversized QMP frame was not safely rejected: {reply}")
    status = require_return(
        qmp_execute(sock, sock_file, "query-status", events,
                    request_id="after-oversized-frame"),
        "query-status",
    )
    if status.get("status") != "prelaunch":
        raise RuntimeError(f"QMP did not recover after oversized frame: {status}")
    if any(event.get("event") == "SHUTDOWN" for event in events):
        raise RuntimeError(
            f"oversized frame dispatched its system_powerdown prefix: {events}"
        )

    # CR is a wire byte too.  A stream of CR bytes must not bypass the frame
    # limit merely because CRLF framing permits one optional trailing CR.
    sock.sendall((b"\r" * 5000) + b"\n")
    cr_reply = recv_json_line(sock_file)
    if (
        cr_reply.get("error", {}).get("desc") != "oversized QMP request frame"
        or "id" in cr_reply
    ):
        raise RuntimeError(f"oversized CR frame was not rejected: {cr_reply}")
    log.write("PASS qmp-oversized-frame-drained-rejected-and-connection-recovered\n")


def require_structural_json_validation(sock, sock_file, events: list, log):
    def send_raw(payload: bytes) -> dict:
        sock.sendall(payload + b"\r\n")
        while True:
            reply = recv_json_line(sock_file)
            if "event" in reply:
                events.append(reply)
                continue
            return reply

    malformed = send_raw(b'{"execute":"system_powerdown"')
    if malformed.get("error", {}).get("desc") != "invalid QMP request" or "id" in malformed:
        raise RuntimeError(f"unterminated JSON frame was not rejected: {malformed}")

    embedded_cr = send_raw(b'{"execute":"system_\rpowerdown"}')
    if (
        embedded_cr.get("error", {}).get("desc") != "invalid QMP request"
        or "id" in embedded_cr
    ):
        raise RuntimeError(f"embedded CR was normalized into a command: {embedded_cr}")

    raw_nul = send_raw(b'{"execute":"system_powerdown"}\x00trailing-garbage')
    if (
        raw_nul.get("error", {}).get("desc") != "invalid QMP request"
        or "id" in raw_nul
    ):
        raise RuntimeError(f"raw NUL terminated and dispatched a prefix: {raw_nul}")

    # C's isspace() accepts VT and FF, but JSON does not.  Keep a destructive
    # command behind each byte so accepting non-JSON whitespace cannot hide as
    # a harmless parser-compatibility difference.
    for label, non_json_ws in (("vertical-tab", b"\x0b"),
                               ("form-feed", b"\x0c")):
        non_json_ws_reply = send_raw(
            b'{"execute"' + non_json_ws + b':' + non_json_ws
            + b'"system_powerdown"}'
        )
        if (
            non_json_ws_reply.get("error", {}).get("desc")
            != "invalid QMP request"
            or "id" in non_json_ws_reply
        ):
            raise RuntimeError(
                f"non-JSON {label} whitespace was accepted: "
                f"{non_json_ws_reply}"
            )

    # RFC 8259 wire JSON is UTF-8.  Exercise every boundary class with the
    # invalid sequence hidden in an otherwise ignored value behind a
    # destructive command: validating only recognized strings would still
    # permit system_powerdown to run.
    invalid_utf8_sequences = (
        ("isolated-continuation", b"\x80"),
        ("overlong", b"\xc0\xaf"),
        ("surrogate", b"\xed\xa0\x80"),
        ("above-unicode-max", b"\xf4\x90\x80\x80"),
        ("truncated", b"\xe2\x82"),
    )
    for label, sequence in invalid_utf8_sequences:
        invalid_utf8_value = send_raw(
            b'{"execute":"system_powerdown","extra":"'
            + sequence
            + b'"}'
        )
        if (
            invalid_utf8_value.get("error", {}).get("desc")
            != "invalid QMP request"
            or "id" in invalid_utf8_value
        ):
            raise RuntimeError(
                f"invalid UTF-8 {label} value was accepted: "
                f"{invalid_utf8_value}"
            )

    invalid_utf8_id = send_raw(
        b'{"execute":"query-status","id":"bad-\xff-id"}'
    )
    if (
        invalid_utf8_id.get("error", {}).get("desc")
        != "invalid QMP request"
        or "id" in invalid_utf8_id
    ):
        raise RuntimeError(
            f"invalid UTF-8 request id was accepted/reflected: {invalid_utf8_id}"
        )

    valid_utf8 = send_raw(
        '{"execute":"query-status","extra":"中文😀",'
        '"id":"utf8-中文😀"}'.encode("utf-8")
    )
    if valid_utf8.get("id") != "utf8-中文😀":
        raise RuntimeError(f"valid UTF-8 request id was not preserved: {valid_utf8}")
    valid_utf8_status = require_return(valid_utf8, "valid UTF-8 query-status")
    if valid_utf8_status.get("status") != "prelaunch":
        raise RuntimeError(f"valid UTF-8 request changed status: {valid_utf8}")

    nested = send_raw(
        b'{"arguments":{"execute":"system_powerdown"},'
        b'"execute":"query-status","id":"top-level-wins"}'
    )
    if nested.get("id") != "top-level-wins":
        raise RuntimeError(f"top-level QMP id was not preserved: {nested}")
    nested_status = require_return(nested, "query-status with nested execute")
    if nested_status.get("status") != "prelaunch":
        raise RuntimeError(f"nested execute key was dispatched: {nested}")

    nested_only = send_raw(
        b'{"arguments":{"execute":"system_powerdown"},"id":"nested-only"}'
    )
    if (
        nested_only.get("error", {}).get("desc") != "invalid QMP request"
        or nested_only.get("id") != "nested-only"
    ):
        raise RuntimeError(f"nested-only execute was accepted: {nested_only}")

    invalid_id = send_raw(b'{"execute":"query-status","id":true}')
    if (
        "request id" not in invalid_id.get("error", {}).get("desc", "")
        or "id" in invalid_id
    ):
        raise RuntimeError(f"non-string/non-number QMP id was accepted: {invalid_id}")

    status = require_return(
        qmp_execute(sock, sock_file, "query-status", events,
                    request_id="after-structural-json-validation"),
        "query-status",
    )
    if status.get("status") != "prelaunch":
        raise RuntimeError(f"QMP did not recover after malformed frames: {status}")
    if any(event.get("event") == "SHUTDOWN" for event in events):
        raise RuntimeError(f"malformed/nested frame dispatched powerdown: {events}")
    log.write(
        "PASS qmp-top-level-json-lexer-utf8-malformed-nested-id-recovery\n"
    )


def require_netdevs(netdevs, label: str, log):
    if len(netdevs) != 1:
        raise RuntimeError(f"unexpected query-netdev entries: {netdevs}")
    entry = netdevs[0]
    if entry.get("id") != "net0" or entry.get("type") != "hostless":
        raise RuntimeError(f"unexpected query-netdev identity: {entry}")
    nemu = entry.get("nemu")
    if not isinstance(nemu, dict):
        raise RuntimeError(f"query-netdev missing nemu object: {entry}")
    for key, value in {
        "backend": "hostless-responder",
        "model": "virtio-net-mmio",
        "mac": "52:54:00:12:34:56",
        "host-ip": "10.0.2.2",
        "guest-ip": "10.0.2.15",
        "mtu": 1500,
        "speed-mbps": 1000,
        "duplex": "full",
        "config-bytes": 17,
        "tap-ifname": "none",
    }.items():
        if nemu.get(key) != value:
            raise RuntimeError(f"query-netdev unexpected {key}: {entry}")
    for key in {"dhcp", "dns", "ntp", "icmp", "tcp-http", "link-up"}:
        if nemu.get(key) is not True:
            raise RuntimeError(f"query-netdev missing enabled {key}: {entry}")
    if nemu.get("ntp-server") != "10.0.2.2":
        raise RuntimeError(f"query-netdev unexpected hostless NTP server: {entry}")
    for key in {
        "host-packet-backend",
        "tap",
        "slirp-nat",
        "host-port-forward",
        "external-network",
        "external-mirror",
    }:
        if nemu.get(key) is not False:
            raise RuntimeError(f"query-netdev boundary ledger should keep {key}=false: {entry}")
    if nemu.get("http-methods") != ["GET", "HEAD"] or nemu.get("http-not-found") is not True:
        raise RuntimeError(f"query-netdev unexpected hostless HTTP surface: {entry}")
    http_large = nemu.get("http-large")
    if (
        not isinstance(http_large, dict)
        or http_large.get("path") != "/nemu-large"
        or http_large.get("bytes") != 4096
        or http_large.get("segment-payload-max") != 1200
    ):
        raise RuntimeError(f"query-netdev unexpected hostless large HTTP surface: {entry}")
    apt_repo = nemu.get("apt-repo")
    if (
        not isinstance(apt_repo, dict)
        or apt_repo.get("base") != "/ubuntu"
        or apt_repo.get("suite") != "jammy"
        or apt_repo.get("component") != "main"
        or apt_repo.get("arch") != "riscv64"
        or apt_repo.get("signed") is not True
        or apt_repo.get("inrelease") != "/ubuntu/dists/jammy/InRelease"
        or apt_repo.get("signed-by") != "/ubuntu/keyrings/nemu-hostless-archive-keyring.gpg"
        or apt_repo.get("key-fingerprint") != "E6742789E6F3AAEAD748589209108C9EAFAA6C14"
        or apt_repo.get("package") != "nemu-hostless-hello"
        or apt_repo.get("version") != "1.0"
        or apt_repo.get("deb-size") != 676
        or apt_repo.get("upgrade-version") != "1.1"
        or apt_repo.get("upgrade-deb-size") != 674
        or apt_repo.get("meta-package") != "nemu-hostless-meta"
        or apt_repo.get("meta-version") != "1.0"
        or apt_repo.get("meta-depends") != "nemu-hostless-hello (= 1.0)"
        or apt_repo.get("meta-deb-size") != 868
        or apt_repo.get("meta-upgrade-version") != "1.1"
        or apt_repo.get("meta-upgrade-depends") != "nemu-hostless-hello (= 1.1)"
        or apt_repo.get("meta-upgrade-deb-size") != 886
    ):
        raise RuntimeError(f"query-netdev unexpected hostless apt repo: {entry}")
    features = nemu.get("features")
    if not isinstance(features, dict):
        raise RuntimeError(f"query-netdev missing features object: {entry}")
    for key in (
        "version-1", "mtu", "mac", "mrg-rxbuf", "status",
        "ctrl-vq", "ctrl-rx", "ctrl-vlan", "ctrl-rx-extra",
        "guest-announce", "ctrl-mac-addr", "speed-duplex",
        "indirect-desc", "event-idx",
    ):
        if features.get(key) is not True:
            raise RuntimeError(f"query-netdev missing feature {key}: {entry}")
    driver_features = nemu.get("driver-features")
    if not isinstance(driver_features, dict):
        raise RuntimeError(f"query-netdev missing driver-features object: {entry}")
    for key in (
        "version-1", "mtu", "mac", "mrg-rxbuf", "status",
        "ctrl-vq", "ctrl-rx", "ctrl-vlan", "ctrl-rx-extra",
        "guest-announce", "ctrl-mac-addr", "speed-duplex",
        "indirect-desc", "event-idx",
    ):
        if driver_features.get(key) is not False:
            raise RuntimeError(f"query-netdev unexpected negotiated feature {key}: {entry}")
    ctrl_rx = nemu.get("ctrl-rx")
    if (
        not isinstance(ctrl_rx, dict)
        or ctrl_rx.get("promisc") is not False
        or ctrl_rx.get("allmulti") is not False
        or ctrl_rx.get("alluni") is not False
        or ctrl_rx.get("nomulti") is not False
        or ctrl_rx.get("nouni") is not False
        or ctrl_rx.get("nobcast") is not False
    ):
        raise RuntimeError(f"query-netdev unexpected ctrl-rx state: {entry}")
    ctrl_mac = nemu.get("ctrl-mac")
    if (
        not isinstance(ctrl_mac, dict)
        or ctrl_mac.get("current") != "52:54:00:12:34:56"
        or ctrl_mac.get("table-set") is not False
        or ctrl_mac.get("addr-set") is not False
        or ctrl_mac.get("unicast") != 0
        or ctrl_mac.get("multicast") != 0
    ):
        raise RuntimeError(f"query-netdev unexpected ctrl-mac state: {entry}")
    ctrl_vlan = nemu.get("ctrl-vlan")
    if (
        not isinstance(ctrl_vlan, dict)
        or ctrl_vlan.get("filter-count") != 0
        or ctrl_vlan.get("last-vid-valid") is not False
        or ctrl_vlan.get("last-vid") != 0
        or ctrl_vlan.get("last-cmd") != 0
    ):
        raise RuntimeError(f"query-netdev unexpected ctrl-vlan state: {entry}")
    ctrl_announce = nemu.get("ctrl-announce")
    if (
        not isinstance(ctrl_announce, dict)
        or ctrl_announce.get("pending") is not False
        or ctrl_announce.get("requested") is not False
    ):
        raise RuntimeError(f"query-netdev unexpected ctrl-announce state: {entry}")
    stats = nemu.get("stats")
    if not isinstance(stats, dict):
        raise RuntimeError(f"query-netdev missing stats object: {entry}")
    for key in (
        "tx-packets", "tx-bytes", "tx-errors",
        "rx-packets", "rx-bytes", "rx-drops",
        "arp-requests", "arp-replies",
        "icmp-echo-requests", "icmp-echo-replies",
        "dhcp-requests", "dhcp-replies",
        "dns-queries", "dns-replies",
        "ntp-requests", "ntp-replies",
        "tcp-segments", "tcp-replies", "tcp-http-requests",
        "tcp-http-head-requests", "tcp-http-not-found",
        "tcp-http-apt-requests", "tcp-http-apt-deb-requests",
        "tcp-http-large-requests", "tcp-http-segmented-responses",
        "tcp-http-response-segments",
        "tap-tx-packets", "tap-tx-bytes", "tap-tx-errors",
        "tap-rx-packets", "tap-rx-bytes", "tap-rx-errors",
        "ctrl-commands", "ctrl-rx-commands", "ctrl-rx-extra-commands",
        "ctrl-mac-table-commands",
        "ctrl-mac-addr-commands", "ctrl-vlan-commands",
        "ctrl-announce-commands", "ctrl-errors",
    ):
        if stats.get(key) != 0:
            raise RuntimeError(f"query-netdev unexpected nonzero stat {key}: {entry}")
    log.write(f"PASS {label} net0\n")
    log.write(f"PASS {label}-host-network-boundary-ledger\n")
    log.write(f"PASS {label}-features\n")
    log.write(f"PASS {label}-driver-features-zero-baseline\n")
    log.write(f"PASS {label}-stats-zero-baseline\n")


def require_rngs(rngs, label: str, log):
    if len(rngs) != 1:
        raise RuntimeError(f"unexpected query-rng entries: {rngs}")
    entry = rngs[0]
    if entry.get("id") != "rng0" or entry.get("type") != "virtio-rng":
        raise RuntimeError(f"unexpected query-rng identity: {entry}")
    if entry.get("model") != "virtio-rng-mmio":
        raise RuntimeError(f"unexpected query-rng model: {entry}")
    if entry.get("backend") not in {"host-urandom", "deterministic-fallback"}:
        raise RuntimeError(f"unexpected query-rng backend: {entry}")
    nemu = entry.get("nemu")
    if not isinstance(nemu, dict):
        raise RuntimeError(f"query-rng missing nemu object: {entry}")
    for key, value in {
        "device-id": 4,
        "version": 2,
        "irq": 3,
        "queue-count": 1,
        "queue-num-max": 8,
    }.items():
        if nemu.get(key) != value:
            raise RuntimeError(f"query-rng unexpected {key}: {entry}")
    features = nemu.get("features")
    if (
        not isinstance(features, dict)
        or features.get("version-1") is not True
        or features.get("indirect-desc") is not True
        or features.get("event-idx") is not True
    ):
        raise RuntimeError(f"query-rng missing virtio feature baseline: {entry}")
    log.write(f"PASS {label} rng0\n")


def require_rtcs(rtcs, label: str, log):
    if len(rtcs) != 1:
        raise RuntimeError(f"unexpected query-rtc entries: {rtcs}")
    entry = rtcs[0]
    if entry.get("id") != "rtc0" or entry.get("type") != "goldfish-rtc":
        raise RuntimeError(f"unexpected query-rtc identity: {entry}")
    if entry.get("model") != "google,goldfish-rtc":
        raise RuntimeError(f"unexpected query-rtc model: {entry}")
    nemu = entry.get("nemu")
    if not isinstance(nemu, dict):
        raise RuntimeError(f"query-rtc missing nemu object: {entry}")
    if nemu.get("irq") != 4 or nemu.get("time-source") != "host-realtime-epoch+clint-mtime":
        raise RuntimeError(f"query-rtc unexpected source/irq: {entry}")
    if nemu.get("time-unit") != "ns" or nemu.get("time-latch") != "low-then-high":
        raise RuntimeError(f"query-rtc unexpected unit/latch: {entry}")
    if nemu.get("virtual-timebase-hz") != 10_000_000:
        raise RuntimeError(f"query-rtc unexpected virtual timebase: {entry}")
    if nemu.get("alarm-supported") is not True:
        raise RuntimeError(f"query-rtc missing alarm support: {entry}")
    for key in ("alarm-enabled", "alarm-running", "irq-enabled", "interrupt-pending", "interrupt-line"):
        if not isinstance(nemu.get(key), bool):
            raise RuntimeError(f"query-rtc missing boolean {key}: {entry}")
    if nemu.get("alarm-enabled") != nemu.get("alarm-running"):
        raise RuntimeError(f"query-rtc alarm alias mismatch: {entry}")
    if nemu.get("interrupt-line") != (nemu.get("interrupt-pending") and nemu.get("irq-enabled")):
        raise RuntimeError(f"query-rtc interrupt line mismatch: {entry}")
    current_ns = nemu.get("current-ns")
    if not isinstance(current_ns, int) or current_ns < 1_500_000_000_000_000_000:
        raise RuntimeError(f"query-rtc implausible current time: {entry}")
    log.write(f"PASS {label} rtc0\n")


def require_serials(serials, label: str, log):
    if len(serials) != 1:
        raise RuntimeError(f"unexpected query-serial entries: {serials}")
    entry = serials[0]
    for key, value in {
        "id": "serial0",
        "type": "uart",
        "model": "ns16550a",
        "backend": "nemu-16550a",
    }.items():
        if entry.get(key) != value:
            raise RuntimeError(f"query-serial unexpected {key}: {entry}")
    if entry.get("frontend-open") is not True or "stderr" not in entry.get("filename", ""):
        raise RuntimeError(f"query-serial unexpected host backend: {entry}")

    nemu = entry.get("nemu")
    if not isinstance(nemu, dict):
        raise RuntimeError(f"query-serial missing nemu object: {entry}")
    for key, value in {
        "mmio": "0x10000000",
        "irq": 1,
        "bus-profile": "8bit",
        "map-size": 0x1000,
    }.items():
        if nemu.get(key) != value:
            raise RuntimeError(f"query-serial unexpected {key}: {entry}")

    registers = nemu.get("registers")
    if not isinstance(registers, dict):
        raise RuntimeError(f"query-serial missing registers: {entry}")
    for key in {"ier", "iir", "fcr", "lcr", "mcr", "lsr", "msr", "scr", "dll", "dlm"}:
        value = registers.get(key)
        if not isinstance(value, str) or not value.startswith("0x"):
            raise RuntimeError(f"query-serial invalid register {key}: {entry}")
    if not isinstance(registers.get("dlab"), bool):
        raise RuntimeError(f"query-serial invalid dlab bit: {entry}")

    rx_fifo = nemu.get("rx-fifo")
    if not isinstance(rx_fifo, dict):
        raise RuntimeError(f"query-serial missing rx-fifo: {entry}")
    if rx_fifo.get("capacity") != 16:
        raise RuntimeError(f"query-serial unexpected rx fifo capacity: {entry}")
    for key in {"visible-capacity", "count", "room", "trigger"}:
        if not isinstance(rx_fifo.get(key), int):
            raise RuntimeError(f"query-serial invalid rx fifo {key}: {entry}")
    if not isinstance(rx_fifo.get("fifo-enabled"), bool):
        raise RuntimeError(f"query-serial invalid fifo-enabled: {entry}")

    host_rx = nemu.get("host-rx")
    if not isinstance(host_rx, dict):
        raise RuntimeError(f"query-serial missing host-rx: {entry}")
    if host_rx.get("staging-capacity") != 1048576:
        raise RuntimeError(f"query-serial unexpected host rx staging capacity: {entry}")
    for key in {"staging-count", "dropped"}:
        if not isinstance(host_rx.get(key), int):
            raise RuntimeError(f"query-serial invalid host-rx {key}: {entry}")

    tx_buffer = nemu.get("tx-buffer")
    if not isinstance(tx_buffer, dict) or tx_buffer.get("capacity") != 4096:
        raise RuntimeError(f"query-serial unexpected tx-buffer: {entry}")
    if not isinstance(tx_buffer.get("count"), int):
        raise RuntimeError(f"query-serial invalid tx-buffer count: {entry}")
    if not isinstance(nemu.get("irq-level"), bool) or not isinstance(nemu.get("thr-irq-pending"), bool):
        raise RuntimeError(f"query-serial invalid irq state: {entry}")
    log.write(f"PASS {label} serial0\n")


def require_interrupts(interrupts, label: str, log):
    if not isinstance(interrupts, dict):
        raise RuntimeError(f"query-interrupts did not return an object: {interrupts}")
    clint = interrupts.get("clint")
    plic = interrupts.get("plic")
    if not isinstance(clint, dict) or not isinstance(plic, dict):
        raise RuntimeError(f"query-interrupts missing clint/plic: {interrupts}")
    for key, value in {
        "model": "riscv,clint0",
        "mmio": "0x02000000",
        "time-source": "host-monotonic",
        "timebase-hz": 10_000_000,
    }.items():
        if clint.get(key) != value:
            raise RuntimeError(f"query-interrupts unexpected clint {key}: {interrupts}")
    if not isinstance(clint.get("mtime"), int) or not isinstance(clint.get("mtimecmp"), int):
        raise RuntimeError(f"query-interrupts clint lacks counters: {interrupts}")

    for key, value in {
        "model": "riscv,plic0",
        "mmio": "0x0c000000",
        "nr-irqs": 32,
        "contexts": 2,
    }.items():
        if plic.get(key) != value:
            raise RuntimeError(f"query-interrupts unexpected plic {key}: {interrupts}")
    sources = plic.get("sources")
    if not isinstance(sources, list):
        raise RuntimeError(f"query-interrupts missing source list: {interrupts}")
    by_irq = {item.get("irq"): item for item in sources if isinstance(item, dict)}
    expected_sources = {
        1: ("serial0", "uart16550"),
        2: ("virtio-blk", "virtio-mmio"),
        3: ("virtio-rng", "virtio-mmio"),
        4: ("goldfish-rtc", "platform-rtc"),
        5: ("virtio-net", "virtio-mmio"),
    }
    for irq, (name, kind) in expected_sources.items():
        entry = by_irq.get(irq)
        if entry is None:
            raise RuntimeError(f"query-interrupts missing irq{irq}: {interrupts}")
        if entry.get("name") != name or entry.get("kind") != kind or entry.get("enabled") is not True:
            raise RuntimeError(f"query-interrupts unexpected irq{irq}: {entry}")
    log.write(f"PASS {label} plic-clint\n")


def require_qmp_schema(schema, expected_commands: set[str], log):
    if not isinstance(schema, list):
        raise RuntimeError(f"query-qmp-schema did not return a list: {schema}")
    by_name = {
        item.get("name"): item
        for item in schema
        if isinstance(item, dict) and item.get("meta-type") == "command"
    }
    for expected in expected_commands:
        entry = by_name.get(expected)
        if entry is None:
            raise RuntimeError(f"query-qmp-schema missing {expected}: {schema}")
        if entry.get("arg-type") != "q_empty" or not isinstance(entry.get("ret-type"), str):
            raise RuntimeError(f"query-qmp-schema malformed {expected}: {entry}")
    if by_name["query-qmp-schema"].get("ret-type") != "SchemaInfoList":
        raise RuntimeError(f"query-qmp-schema self ret-type mismatch: {by_name['query-qmp-schema']}")
    log.write(f"PASS query-qmp-schema commands={len(by_name)}\n")


def kill_and_wait(proc: subprocess.Popen):
    if proc.poll() is None:
        proc.kill()
        proc.wait(timeout=5)


def read_text(path: str) -> str:
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            return f.read()
    except FileNotFoundError:
        return ""


def validate_artifact_paths(args):
    readonly = {
        "smoke-script": __file__,
        "nemu": args.nemu,
        "block-image": args.block_image,
        "firmware": args.firmware,
        "kernel": args.kernel,
        "dtb": args.dtb,
    }
    writable = {
        "log": args.log,
        "nemu-log": args.nemu_log,
        "cont-nemu-log": args.cont_nemu_log,
        "block-nemu-log": args.block_nemu_log,
        "runtime-nemu-log": args.runtime_nemu_log,
        "disconnect-nemu-log": args.disconnect_nemu_log,
        "system-powerdown-nemu-log": args.system_powerdown_nemu_log,
        "guest-shutdown-nemu-log": args.guest_shutdown_nemu_log,
        "disconnect-image": args.disconnect_image,
        "system-powerdown-image": args.system_powerdown_image,
        "guest-shutdown-image": args.guest_shutdown_image,
    }
    for label, overlay in {
        "overlay-image": args.overlay_image,
        "runtime-overlay-image": args.runtime_overlay_image,
    }.items():
        writable[label] = overlay
        writable[f"{label}.meta"] = f"{overlay}.meta"
        writable[f"{label}.meta.tmp"] = f"{overlay}.meta.tmp"
        writable[f"{label}.lock"] = f"{overlay}.lock"

    readonly_real = {}
    for label, path in readonly.items():
        if not path or not os.path.isfile(path):
            raise RuntimeError(f"required {label} is not a regular file: {path}")
        readonly_real[label] = os.path.realpath(path)

    writable_real = {}
    for label, path in writable.items():
        if not path:
            raise RuntimeError(f"writable {label} path is empty")
        resolved = os.path.realpath(os.path.abspath(path))
        if resolved == os.path.sep:
            raise RuntimeError(f"unsafe writable {label} path: {path}")
        if os.path.lexists(path):
            if os.path.islink(path):
                raise RuntimeError(f"writable {label} must not be a symlink: {path}")
            mode = os.lstat(path).st_mode
            if not stat.S_ISREG(mode):
                raise RuntimeError(
                    f"writable {label} has unsafe existing file type: {path}"
                )
        for input_label, input_path in readonly.items():
            aliases = resolved == readonly_real[input_label]
            if os.path.lexists(path):
                try:
                    aliases = aliases or os.path.samefile(path, input_path)
                except FileNotFoundError:
                    pass
            if aliases:
                raise RuntimeError(
                    f"writable {label} aliases required {input_label}: {path}"
                )
        for other_label, other_path in writable.items():
            if other_label == label or other_label not in writable_real:
                continue
            aliases = resolved == writable_real[other_label]
            if os.path.lexists(path) and os.path.lexists(other_path):
                try:
                    aliases = aliases or os.path.samefile(path, other_path)
                except FileNotFoundError:
                    pass
            if aliases:
                raise RuntimeError(
                    f"writable artifacts alias each other: {label}={path} and "
                    f"{other_label}={other_path}"
                )
        writable_real[label] = resolved


def artifact_identity(path: str):
    info = os.lstat(path)
    return info.st_dev, info.st_ino


def unlink_owned_artifact(path: str, identity):
    if identity is None:
        return
    try:
        if artifact_identity(path) == identity:
            os.unlink(path)
    except FileNotFoundError:
        pass


def remove_overlay(path: str, backing: str):
    candidates = (path, f"{path}.meta", f"{path}.meta.tmp")
    lock_path = f"{path}.lock"
    backing_real = os.path.realpath(backing)
    if not path:
        raise RuntimeError("overlay path is empty")
    if not os.path.isfile(backing):
        raise RuntimeError(f"block backing is not a regular file: {backing}")
    os.makedirs(os.path.dirname(os.path.abspath(lock_path)), exist_ok=True)
    lock_flags = os.O_RDWR | os.O_CREAT | os.O_CLOEXEC
    if hasattr(os, "O_NOFOLLOW"):
        lock_flags |= os.O_NOFOLLOW
    lock_fd = os.open(lock_path, lock_flags, 0o600)
    try:
        lock_stat = os.fstat(lock_fd)
        backing_stat = os.stat(backing)
        if not stat.S_ISREG(lock_stat.st_mode):
            raise RuntimeError(f"overlay lock is not a regular file: {lock_path}")
        if (lock_stat.st_dev, lock_stat.st_ino) == (
            backing_stat.st_dev,
            backing_stat.st_ino,
        ):
            raise RuntimeError(f"overlay lock aliases block backing: {lock_path}")
        try:
            fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            raise RuntimeError(f"overlay is already in use: {path}") from exc

        for candidate in (*candidates, lock_path):
            candidate_real = os.path.realpath(candidate)
            if candidate_real == backing_real:
                raise RuntimeError(
                    f"overlay artifact aliases block backing: {candidate} -> {backing_real}"
                )
            if os.path.lexists(candidate):
                candidate_stat = os.lstat(candidate)
                if stat.S_ISDIR(candidate_stat.st_mode):
                    raise RuntimeError(f"overlay artifact is a directory: {candidate}")
                if os.path.samefile(candidate, backing):
                    raise RuntimeError(
                        f"overlay artifact links to block backing: {candidate} -> {backing_real}"
                    )
                if candidate != lock_path and (
                    candidate_stat.st_dev,
                    candidate_stat.st_ino,
                ) == (lock_stat.st_dev, lock_stat.st_ino):
                    raise RuntimeError(
                        f"overlay artifact aliases stable lock: {candidate}"
                    )
        for candidate in candidates:
            try:
                os.unlink(candidate)
            except FileNotFoundError:
                pass
    finally:
        os.close(lock_fd)


def write_guest_poweroff_image(path: str):
    parent = os.path.dirname(path)
    if parent:
        os.makedirs(parent, exist_ok=True)
    words = [
        0x001002B7,  # lui t0, 0x100      ; t0 = 0x00100000
        0x00005337,  # lui t1, 0x5        ; t1 = 0x5000
        0x55530313,  # addi t1, t1, 0x555 ; t1 = 0x5555
        0x0062A023,  # sw t1, 0(t0)       ; syscon poweroff
        0x0000006F,  # j .                ; fallback if MMIO did not stop
    ]
    with open(path, "wb") as f:
        for word in words:
            f.write(word.to_bytes(4, "little"))
    return artifact_identity(path)


def write_guest_spin_image(path: str):
    parent = os.path.dirname(path)
    if parent:
        os.makedirs(parent, exist_ok=True)
    with open(path, "wb") as f:
        f.write((0x0000006F).to_bytes(4, "little"))  # j .
    return artifact_identity(path)


def run_query_quit(args, log):
    port = reserve_port()
    fifo_parent = os.path.dirname(os.path.abspath(args.log))
    qmp_fifo_path = os.path.join(
        fifo_parent,
        f'nemu-qmp-{os.getpid()}-{port}-"\\-\t-串口-🚀.fifo',
    )
    if os.path.lexists(qmp_fifo_path):
        raise RuntimeError(f"QMP serial FIFO fixture already exists: {qmp_fifo_path!r}")
    expected_host_backend = f"stderr,stdin,fifo:{qmp_fifo_path}"
    child_env = os.environ.copy()
    child_env["NEMU_SERIAL_FIFO"] = qmp_fifo_path
    fifo_identity = None
    cmd = [
        args.nemu,
        f"--qmp={port}",
        f"--log={args.nemu_log}",
    ]

    log.write(f"query-quit-command: {' '.join(cmd)}\n")
    log.write(f"query-quit-serial-fifo: {qmp_fifo_path!r}\n")
    proc = subprocess.Popen(
        cmd,
        stdout=log,
        stderr=subprocess.STDOUT,
        env=child_env,
    )
    try:
        with connect_with_retry(port, time.monotonic() + args.timeout) as sock:
            with sock.makefile("rwb", buffering=0) as sock_file:
                fifo_info = os.lstat(qmp_fifo_path)
                if not stat.S_ISFIFO(fifo_info.st_mode) or fifo_info.st_uid != os.getuid():
                    raise RuntimeError(
                        f"NEMU did not create the owned QMP serial FIFO fixture: {qmp_fifo_path!r}"
                    )
                fifo_identity = fifo_info.st_dev, fifo_info.st_ino
                events = []
                greeting = recv_json_line(sock_file)
                if "QMP" not in greeting:
                    raise RuntimeError(f"missing QMP greeting: {greeting}")
                log.write(f"PASS qmp-greeting {greeting['QMP']['version']['package']}\n")

                require_return(
                    qmp_execute(sock, sock_file, "qmp_capabilities", events, request_id="capabilities-echo"),
                    "qmp_capabilities",
                )
                log.write("PASS qmp_capabilities\n")

                status = require_return(qmp_execute(sock, sock_file, "query-status", events), "query-status")
                if status.get("status") != "prelaunch" or status.get("running") is not False:
                    raise RuntimeError(f"unexpected status: {status}")
                log.write(f"PASS query-status {status['status']}\n")

                memory = require_return(
                    qmp_execute(sock, sock_file, "query-memory-size-summary", events),
                    "query-memory-size-summary",
                )
                if memory.get("base-memory") != 0x40000000:
                    raise RuntimeError(f"unexpected memory summary: {memory}")
                log.write(f"PASS query-memory-size-summary {memory['base-memory']}\n")

                machines = require_return(qmp_execute(sock, sock_file, "query-machines", events), "query-machines")
                if not any(item.get("name") == "riscv64-nemu" and item.get("cpu-max") == 1 for item in machines):
                    raise RuntimeError(f"unexpected machines: {machines}")
                log.write("PASS query-machines riscv64-nemu\n")

                cpus = require_return(qmp_execute(sock, sock_file, "query-cpus-fast", events), "query-cpus-fast")
                if len(cpus) != 1 or cpus[0].get("cpu-index") != 0:
                    raise RuntimeError(f"unexpected cpus-fast: {cpus}")
                log.write("PASS query-cpus-fast cpu0\n")

                block = require_return(qmp_execute(sock, sock_file, "query-block", events), "query-block")
                if not isinstance(block, list):
                    raise RuntimeError(f"unexpected query-block: {block}")
                log.write(f"PASS query-block entries={len(block)}\n")

                blockstats = require_return(qmp_execute(sock, sock_file, "query-blockstats", events), "query-blockstats")
                if not isinstance(blockstats, list) or len(blockstats) != 0:
                    raise RuntimeError(f"unexpected detached query-blockstats: {blockstats}")
                log.write(f"PASS query-blockstats entries={len(blockstats)}\n")

                chardevs = require_return(qmp_execute(sock, sock_file, "query-chardev", events), "query-chardev")
                if len(chardevs) != 1 or chardevs[0].get("label") != "serial0":
                    raise RuntimeError(f"unexpected query-chardev: {chardevs}")
                if chardevs[0].get("frontend-open") is not True:
                    raise RuntimeError(f"query-chardev frontend is not open: {chardevs}")
                if chardevs[0].get("filename") != expected_host_backend:
                    raise RuntimeError(
                        f"query-chardev did not preserve escaped host backend: {chardevs}"
                    )
                log.write("PASS query-chardev serial0 escaped-fifo-path\n")

                serials = require_return(qmp_execute(sock, sock_file, "query-serial", events), "query-serial")
                require_serials(serials, "query-serial", log)
                if serials[0].get("filename") != expected_host_backend:
                    raise RuntimeError(
                        f"query-serial did not preserve escaped host backend: {serials}"
                    )
                log.write("PASS query-serial escaped-fifo-path\n")

                netdevs = require_return(qmp_execute(sock, sock_file, "query-netdev", events), "query-netdev")
                require_netdevs(netdevs, "query-netdev", log)

                rngs = require_return(qmp_execute(sock, sock_file, "query-rng", events), "query-rng")
                require_rngs(rngs, "query-rng", log)

                rtcs = require_return(qmp_execute(sock, sock_file, "query-rtc", events), "query-rtc")
                require_rtcs(rtcs, "query-rtc", log)

                interrupts = require_return(
                    qmp_execute(sock, sock_file, "query-interrupts", events),
                    "query-interrupts",
                )
                require_interrupts(interrupts, "query-interrupts", log)

                pci = require_return(qmp_execute(sock, sock_file, "query-pci", events), "query-pci")
                if not isinstance(pci, list) or len(pci) != 0:
                    raise RuntimeError(f"unexpected query-pci baseline: {pci}")
                log.write(f"PASS query-pci entries={len(pci)}\n")

                version = require_return(qmp_execute(sock, sock_file, "query-version", events), "query-version")
                qemu_version = version.get("qemu")
                if not isinstance(qemu_version, dict):
                    raise RuntimeError(f"query-version missing qemu version object: {version}")
                if version.get("package") != "ysyx-nemu" or qemu_version.get("major") != 0:
                    raise RuntimeError(f"unexpected query-version identity: {version}")
                log.write(
                    "PASS query-version "
                    f"{version['package']} {qemu_version.get('major')}.{qemu_version.get('minor')}.{qemu_version.get('micro')}\n"
                )

                kvm = require_return(qmp_execute(sock, sock_file, "query-kvm", events), "query-kvm")
                if kvm.get("enabled") is not False or kvm.get("present") is not False:
                    raise RuntimeError(f"unexpected query-kvm baseline: {kvm}")
                log.write("PASS query-kvm disabled\n")

                expected_commands = {
                    "qmp_capabilities",
                    "query-status",
                    "query-memory-size-summary",
                    "query-machines",
                    "query-cpus-fast",
                    "query-block",
                    "query-blockstats",
                    "query-chardev",
                    "query-serial",
                    "query-netdev",
                    "query-rng",
                    "query-rtc",
                    "query-interrupts",
                    "query-pci",
                    "query-version",
                    "query-kvm",
                    "query-qmp-schema",
                    "query-events",
                    "query-commands",
                    "cont",
                    "stop",
                    "system_reset",
                    "system_powerdown",
                    "quit",
                }

                schema = require_return(
                    qmp_execute(sock, sock_file, "query-qmp-schema", events),
                    "query-qmp-schema",
                )
                require_qmp_schema(schema, expected_commands, log)

                event_infos = require_return(qmp_execute(sock, sock_file, "query-events", events), "query-events")
                event_names = {item.get("name") for item in event_infos}
                for expected in {"RESET", "RESUME", "STOP", "SHUTDOWN"}:
                    if expected not in event_names:
                        raise RuntimeError(f"query-events missing {expected}: {event_infos}")
                log.write(f"PASS query-events events={len(event_infos)}\n")

                commands = require_return(qmp_execute(sock, sock_file, "query-commands", events), "query-commands")
                names = {item.get("name") for item in commands}
                for expected in expected_commands:
                    if expected not in names:
                        raise RuntimeError(f"query-commands missing {expected}: {commands}")
                log.write("PASS query-commands\n")

                error_reply = qmp_execute(sock, sock_file, "x-nemu-unsupported-command", events, request_id=1001)
                error = error_reply.get("error")
                if not isinstance(error, dict) or error.get("class") != "CommandNotFound":
                    raise RuntimeError(f"unsupported command did not return CommandNotFound: {error_reply}")
                log.write("PASS qmp-id-echo return-error\n")

                require_oversized_id_rejected(sock, sock_file, events, log)
                require_oversized_frame_rejected(sock, sock_file, events, log)
                require_structural_json_validation(sock, sock_file, events, log)

                require_return(qmp_execute(sock, sock_file, "quit", events), "quit")
                require_event_count(events, "SHUTDOWN", 1, "qmp-event-shutdown", log)
                log.write("PASS quit OK\n")

        rc = proc.wait(timeout=args.timeout)
        if rc != 0:
            raise RuntimeError(f"NEMU exited with rc={rc}")
        log.write("PASS nemu-exit rc=0\n")
    except Exception:
        kill_and_wait(proc)
        raise
    finally:
        if fifo_identity is None:
            try:
                fifo_info = os.lstat(qmp_fifo_path)
                if stat.S_ISFIFO(fifo_info.st_mode) and fifo_info.st_uid == os.getuid():
                    fifo_identity = fifo_info.st_dev, fifo_info.st_ino
            except FileNotFoundError:
                pass
        unlink_owned_artifact(qmp_fifo_path, fifo_identity)


def run_startup_disconnect(args, log):
    port = reserve_port()
    cmd = [
        args.nemu,
        f"--qmp={port}",
        f"--log={args.nemu_log}",
    ]

    log.write(f"startup-disconnect-command: {' '.join(cmd)}\n")
    proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
    try:
        with connect_with_retry(port, time.monotonic() + args.timeout) as sock:
            with sock.makefile("rwb", buffering=0) as sock_file:
                greeting = recv_json_line(sock_file)
                if "QMP" not in greeting:
                    raise RuntimeError(f"missing QMP greeting for startup disconnect: {greeting}")
                log.write(
                    "PASS startup-disconnect-qmp-greeting "
                    f"{greeting['QMP']['version']['package']}\n"
                )

        try:
            rc = proc.wait(timeout=args.timeout)
        except subprocess.TimeoutExpired as exc:
            raise RuntimeError("NEMU did not fail closed after startup QMP disconnect") from exc
        if rc != 1:
            raise RuntimeError(
                f"NEMU startup QMP disconnect returned rc={rc}, expected fail-closed rc=1"
            )
        log.write(f"PASS startup-qmp-disconnect-fail-closed rc={rc}\n")
    except Exception:
        kill_and_wait(proc)
        raise


def run_query_cont(args, log):
    reset_hartid = 7
    reset_dtb = 0x87F00000
    port = reserve_port()
    cmd = [
        args.nemu,
        f"--qmp={port}",
        f"--log={args.cont_nemu_log}",
        f"--boot-hartid={reset_hartid}",
        f"--boot-dtb={reset_dtb:#x}",
        "--monitor-cmd=info r",
        # cont 的成功回复由 CPU 的真实 RUNNING 确认点发送；si 命令
        # 创建该执行窗口，前一条 info r 保留对启动 ABI 的观察。
        "--monitor-cmd=si 1",
    ]

    log.write(f"query-cont-command: {' '.join(cmd)}\n")
    proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
    try:
        with connect_with_retry(port, time.monotonic() + args.timeout) as sock:
            with sock.makefile("rwb", buffering=0) as sock_file:
                events = []
                greeting = recv_json_line(sock_file)
                if "QMP" not in greeting:
                    raise RuntimeError(f"missing QMP greeting for cont: {greeting}")
                log.write(f"PASS cont-qmp-greeting {greeting['QMP']['version']['package']}\n")

                require_return(qmp_execute(sock, sock_file, "qmp_capabilities", events), "qmp_capabilities")
                status = require_return(qmp_execute(sock, sock_file, "query-status", events), "query-status")
                if status.get("status") != "prelaunch" or status.get("running") is not False:
                    raise RuntimeError(f"unexpected cont prelaunch status: {status}")
                log.write(f"PASS cont-query-status {status['status']}\n")

                commands = require_return(qmp_execute(sock, sock_file, "query-commands", events), "query-commands")
                names = {item.get("name") for item in commands}
                if "cont" not in names:
                    raise RuntimeError(f"query-commands missing cont: {commands}")

                require_return(qmp_execute(sock, sock_file, "system_reset", events), "system_reset")
                require_event_count(events, "RESET", 1, "system-reset-event-reset", log)
                log.write("PASS system-reset-prelaunch OK\n")

                status = require_return(qmp_execute(sock, sock_file, "query-status", events), "query-status")
                if status.get("status") != "prelaunch" or status.get("running") is not False:
                    raise RuntimeError(f"unexpected status after system_reset: {status}")
                log.write(f"PASS system-reset-query-status {status['status']}\n")

                require_return(qmp_execute(sock, sock_file, "cont", events), "cont")
                require_event_count(events, "RESUME", 1, "cont-event-resume", log)
                log.write("PASS cont OK\n")

        rc = proc.wait(timeout=args.timeout)
        if rc != 0:
            raise RuntimeError(f"NEMU exited after cont with rc={rc}")
        log.write("PASS cont-nemu-exit rc=0\n")
        log.flush()
        with open(args.log, "r", encoding="utf-8", errors="replace") as smoke_log:
            content = smoke_log.read()
        if "[monitor-cmd] info r" not in content:
            raise RuntimeError("cont path did not execute monitor-cmd")
        log.write("PASS cont-monitor-cmd\n")
        if "pc  = 0x0000000080000000" not in content:
            raise RuntimeError("cont path did not preserve reset-vector PC")
        log.write("PASS cont-pc-reset-vector\n")
        expected_a0 = f"x10 (  a0) = 0x{reset_hartid:016x}"
        expected_a1 = f"x11 (  a1) = 0x{reset_dtb:016x}"
        if expected_a0 not in content or expected_a1 not in content:
            raise RuntimeError(
                "system_reset did not restore boot ABI registers: "
                f"expected {expected_a0!r} and {expected_a1!r}"
            )
        log.write(
            f"PASS system-reset-boot-abi a0={reset_hartid:#x} a1={reset_dtb:#x}\n"
        )
        content = read_text(args.cont_nemu_log) + "\n" + read_text(args.log)
        if "QMP system_reset requested" not in content:
            raise RuntimeError("system_reset command did not reach NEMU reset handler")
        log.write("PASS system-reset-log-requested\n")
    except Exception:
        kill_and_wait(proc)
        raise


def run_query_block_attached(args, log):
    remove_overlay(args.overlay_image, args.block_image)

    port = reserve_port()
    cmd = [
        args.nemu,
        f"--qmp={port}",
        f"--log={args.block_nemu_log}",
        f"--block={args.block_image}",
        f"--block-overlay={args.overlay_image}",
    ]

    log.write(f"query-block-command: {' '.join(cmd)}\n")
    proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
    try:
        with connect_with_retry(port, time.monotonic() + args.timeout) as sock:
            with sock.makefile("rwb", buffering=0) as sock_file:
                events = []
                greeting = recv_json_line(sock_file)
                if "QMP" not in greeting:
                    raise RuntimeError(f"missing QMP greeting for query-block: {greeting}")
                log.write(f"PASS block-qmp-greeting {greeting['QMP']['version']['package']}\n")

                block = require_return(qmp_execute(sock, sock_file, "query-block", events), "query-block")
                if len(block) != 1:
                    raise RuntimeError(f"query-block expected one attached disk: {block}")
                entry = block[0]
                if entry.get("device") != "virtio0":
                    raise RuntimeError(f"unexpected query-block device: {entry}")
                inserted = entry.get("inserted", {})
                nemu = entry.get("nemu", {})
                if inserted.get("drv") != "raw" or inserted.get("ro") is not False:
                    raise RuntimeError(f"unexpected inserted block info: {inserted}")
                if nemu.get("capacity-bytes") != 0x80000000 or nemu.get("capacity-sectors") != 4194304:
                    raise RuntimeError(f"unexpected qmp block capacity: {nemu}")
                if nemu.get("overlay") != "enabled" or nemu.get("write-target") != "overlay":
                    raise RuntimeError(f"unexpected qmp block overlay state: {nemu}")
                if nemu.get("overlay-state") != "new" or nemu.get("overlay-metadata") != "sidecar-v1-crc64":
                    raise RuntimeError(f"unexpected qmp block overlay metadata: {nemu}")
                if nemu.get("overlay-dirty-sectors") != 0:
                    raise RuntimeError(f"unexpected dirty sectors before guest run: {nemu}")
                if nemu.get("read-mmap") != "enabled" or nemu.get("read-mmap-bytes") != 0x80000000:
                    raise RuntimeError(f"unexpected qmp block mmap state: {nemu}")
                log.write("PASS query-block-attached virtio0\n")
                log.write(f"PASS query-block-capacity {nemu['capacity-bytes']}\n")
                log.write(f"PASS query-block-overlay {nemu['overlay']}\n")
                log.write(f"PASS query-block-read-mmap {nemu['read-mmap']}\n")

                blockstats = require_return(qmp_execute(sock, sock_file, "query-blockstats", events), "query-blockstats")
                if len(blockstats) != 1:
                    raise RuntimeError(f"query-blockstats expected one attached disk: {blockstats}")
                stats_entry = blockstats[0]
                if stats_entry.get("device") != "virtio0":
                    raise RuntimeError(f"unexpected query-blockstats device: {stats_entry}")
                stats = stats_entry.get("stats", {})
                stats_nemu = stats_entry.get("nemu", {})
                for key in ("rd_bytes", "wr_bytes", "rd_operations", "wr_operations", "flush_operations"):
                    if stats.get(key) != 0:
                        raise RuntimeError(f"unexpected nonzero qmp block stat {key}: {stats_entry}")
                for key in ("discard-operations", "write-zeroes-operations", "failed-operations"):
                    if stats_nemu.get(key) != 0:
                        raise RuntimeError(f"unexpected nonzero qmp nemu stat {key}: {stats_entry}")
                if stats_nemu.get("async-submitted") != 0 or stats_nemu.get("async-completed") != 0:
                    raise RuntimeError(f"unexpected qmp async blockstats baseline: {stats_entry}")
                log.write("PASS query-blockstats-attached virtio0\n")
                log.write("PASS query-blockstats-zero-baseline\n")
                log.write("PASS query-blockstats-async-baseline\n")

                require_return(qmp_execute(sock, sock_file, "quit", events), "quit")
                require_event_count(events, "SHUTDOWN", 1, "block-event-shutdown", log)
                log.write("PASS block-quit OK\n")

        rc = proc.wait(timeout=args.timeout)
        if rc != 0:
            raise RuntimeError(f"NEMU query-block exited with rc={rc}")
        log.write("PASS block-nemu-exit rc=0\n")
    except Exception:
        kill_and_wait(proc)
        raise
    finally:
        remove_overlay(args.overlay_image, args.block_image)


def run_query_runtime(args, log):
    remove_overlay(args.runtime_overlay_image, args.block_image)

    port = reserve_port()
    cmd = [
        args.nemu,
        "-b",
        f"--max-insts={args.runtime_max_insts}",
        f"--qmp={port}",
        f"--log={args.runtime_nemu_log}",
        "--boot-hartid=0",
        f"--boot-dtb={args.dtb_addr}",
        "-i",
        args.firmware,
        f"--load={args.next_addr}:{args.kernel}",
        f"--load={args.dtb_addr}:{args.dtb}",
        f"--block={args.block_image}",
        f"--block-overlay={args.runtime_overlay_image}",
    ]

    log.write(f"query-runtime-command: {' '.join(cmd)}\n")
    proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
    try:
        with connect_with_retry(port, time.monotonic() + args.timeout) as sock:
            with sock.makefile("rwb", buffering=0) as sock_file:
                events = []
                greeting = recv_json_line(sock_file)
                if "QMP" not in greeting:
                    raise RuntimeError(f"missing QMP greeting for runtime: {greeting}")
                log.write(f"PASS runtime-qmp-greeting {greeting['QMP']['version']['package']}\n")

                require_return(qmp_execute(sock, sock_file, "qmp_capabilities", events), "qmp_capabilities")
                status = require_return(qmp_execute(sock, sock_file, "query-status", events), "query-status")
                if status.get("status") != "prelaunch" or status.get("running") is not False:
                    raise RuntimeError(f"unexpected runtime prelaunch status: {status}")
                log.write(f"PASS runtime-query-status-prelaunch {status['status']}\n")

                require_return(qmp_execute(sock, sock_file, "cont", events), "cont")
                require_event_count(events, "RESUME", 1, "runtime-event-resume-start", log)
                log.write("PASS runtime-cont OK\n")

                status = require_return(qmp_execute(sock, sock_file, "query-status", events), "query-status")
                if status.get("status") != "running" or status.get("running") is not True:
                    raise RuntimeError(f"unexpected runtime running status: {status}")
                log.write(f"PASS runtime-query-status {status['status']}\n")

                for mutable_command in (
                    "query-block",
                    "query-blockstats",
                    "query-chardev",
                    "query-serial",
                    "query-netdev",
                    "query-rng",
                    "query-rtc",
                    "query-interrupts",
                ):
                    running_reply = qmp_execute(
                        sock, sock_file, mutable_command, events,
                        request_id=f"runtime-{mutable_command}-while-running",
                    )
                    running_error = running_reply.get("error")
                    if (
                        not isinstance(running_error, dict)
                        or running_error.get("class") != "GenericError"
                        or "paused" not in running_error.get("desc", "")
                    ):
                        raise RuntimeError(
                            f"mutable {mutable_command} was not rejected while "
                            f"CPU was running: {running_reply}"
                        )
                log.write("PASS runtime-all-mutable-queries-rejected-while-running\n")

                require_return(qmp_execute(sock, sock_file, "stop", events), "stop")
                require_event_count(events, "STOP", 1, "runtime-event-stop", log)
                log.write("PASS runtime-stop OK\n")

                # STOP reply 本身就是 CPU pause-point 的确认，不再容许先回复、
                # 后暂停的竞态窗口。
                status = require_return(
                    qmp_execute(sock, sock_file, "query-status", events),
                    "query-status",
                )
                if status.get("status") != "paused" or status.get("running") is not False:
                    raise RuntimeError(f"STOP replied before CPU entered paused state: {status}")
                log.write(f"PASS runtime-query-status-paused {status['status']}\n")

                blockstats = require_return(qmp_execute(sock, sock_file, "query-blockstats", events), "query-blockstats")
                if len(blockstats) != 1 or blockstats[0].get("device") != "virtio0":
                    raise RuntimeError(f"unexpected runtime blockstats: {blockstats}")
                if not isinstance(blockstats[0].get("stats"), dict):
                    raise RuntimeError(f"runtime blockstats missing stats object: {blockstats}")
                if not isinstance(blockstats[0].get("nemu"), dict):
                    raise RuntimeError(f"runtime blockstats missing nemu object: {blockstats}")
                log.write("PASS runtime-query-blockstats virtio0\n")

                chardevs = require_return(qmp_execute(sock, sock_file, "query-chardev", events), "query-chardev")
                if len(chardevs) != 1 or chardevs[0].get("label") != "serial0":
                    raise RuntimeError(f"unexpected runtime chardevs: {chardevs}")
                log.write("PASS runtime-query-chardev serial0\n")

                serials = require_return(qmp_execute(sock, sock_file, "query-serial", events), "query-serial")
                require_serials(serials, "runtime-query-serial", log)

                netdevs = require_return(qmp_execute(sock, sock_file, "query-netdev", events), "query-netdev")
                require_netdevs(netdevs, "runtime-query-netdev", log)

                rngs = require_return(qmp_execute(sock, sock_file, "query-rng", events), "query-rng")
                require_rngs(rngs, "runtime-query-rng", log)

                rtcs = require_return(qmp_execute(sock, sock_file, "query-rtc", events), "query-rtc")
                require_rtcs(rtcs, "runtime-query-rtc", log)

                interrupts = require_return(
                    qmp_execute(sock, sock_file, "query-interrupts", events),
                    "query-interrupts",
                )
                require_interrupts(interrupts, "runtime-query-interrupts", log)

                require_return(qmp_execute(sock, sock_file, "cont", events), "cont")
                require_event_count(events, "RESUME", 2, "runtime-event-resume-after-stop", log)
                log.write("PASS runtime-cont-after-stop OK\n")

                # CONT reply 同理确认 CPU 已离开 pause wait。
                status = require_return(
                    qmp_execute(sock, sock_file, "query-status", events),
                    "query-status",
                )
                if status.get("status") != "running" or status.get("running") is not True:
                    raise RuntimeError(f"CONT replied before CPU resumed: {status}")
                log.write(f"PASS runtime-query-status-resumed {status['status']}\n")

                require_return(qmp_execute(sock, sock_file, "quit", events), "quit")
                require_event_count(events, "SHUTDOWN", 1, "runtime-event-shutdown", log)
                log.write("PASS runtime-quit OK\n")

        rc = proc.wait(timeout=args.timeout)
        if rc != 0:
            raise RuntimeError(f"NEMU runtime QMP exited with rc={rc}")
        log.write("PASS runtime-nemu-exit rc=0\n")
    except Exception:
        kill_and_wait(proc)
        raise
    finally:
        remove_overlay(args.runtime_overlay_image, args.block_image)


def run_runtime_stop_disconnect(args, log):
    payload_identity = None
    payload_identity = write_guest_spin_image(args.disconnect_image)

    port = reserve_port()
    cmd = [
        args.nemu,
        "-b",
        "--max-insts=1000000000",
        f"--qmp={port}",
        f"--log={args.disconnect_nemu_log}",
        "-i",
        args.disconnect_image,
    ]

    log.write(f"runtime-disconnect-command: {' '.join(cmd)}\n")
    log.flush()
    case_output_start = os.lseek(log.fileno(), 0, os.SEEK_CUR)
    proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
    try:
        with connect_with_retry(port, time.monotonic() + args.timeout) as sock:
            with sock.makefile("rwb", buffering=0) as sock_file:
                events = []
                greeting = recv_json_line(sock_file)
                if "QMP" not in greeting:
                    raise RuntimeError(
                        f"missing QMP greeting for runtime disconnect: {greeting}"
                    )
                require_return(
                    qmp_execute(sock, sock_file, "qmp_capabilities", events),
                    "qmp_capabilities",
                )
                require_return(qmp_execute(sock, sock_file, "cont", events), "cont")
                require_event_count(
                    events, "RESUME", 1, "disconnect-event-resume", log
                )
                require_return(qmp_execute(sock, sock_file, "stop", events), "stop")
                require_event_count(events, "STOP", 1, "disconnect-event-stop", log)

                status = require_return(
                    qmp_execute(sock, sock_file, "query-status", events),
                    "query-status",
                )
                if status.get("status") != "paused" or status.get("running") is not False:
                    raise RuntimeError(
                        f"STOP replied before disconnect case actually paused: {status}"
                    )
                log.write("PASS runtime-disconnect-actually-paused\n")
                sock.shutdown(socket.SHUT_RDWR)

        try:
            rc = proc.wait(timeout=args.timeout)
        except subprocess.TimeoutExpired as exc:
            raise RuntimeError(
                "NEMU hung after paused runtime QMP client disconnected"
            ) from exc
        if rc != 1:
            raise RuntimeError(f"runtime QMP disconnect returned rc={rc}, expected 1")
        log.flush()
        with open(args.log, "rb") as case_output:
            case_output.seek(case_output_start)
            content = case_output.read().decode("utf-8", errors="replace")
        for marker in (
            "QMP CPU paused",
            "QMP runtime client disconnected unexpectedly; requesting NEMU abort",
            "QMP CPU resumed",
        ):
            if marker not in content:
                raise RuntimeError(f"runtime disconnect path missing log marker: {marker}")
        log.write("PASS runtime-qmp-disconnect-fail-closed rc=1\n")
    except Exception:
        kill_and_wait(proc)
        raise
    finally:
        unlink_owned_artifact(args.disconnect_image, payload_identity)


def run_system_powerdown(args, log):
    payload_identity = None
    payload_identity = write_guest_spin_image(args.system_powerdown_image)

    port = reserve_port()
    cmd = [
        args.nemu,
        "-b",
        "--max-insts=1000000000",
        f"--qmp={port}",
        f"--log={args.system_powerdown_nemu_log}",
        "-i",
        args.system_powerdown_image,
    ]

    log.write(f"system-powerdown-command: {' '.join(cmd)}\n")
    proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
    try:
        with connect_with_retry(port, time.monotonic() + args.timeout) as sock:
            with sock.makefile("rwb", buffering=0) as sock_file:
                events = []
                greeting = recv_json_line(sock_file)
                if "QMP" not in greeting:
                    raise RuntimeError(f"missing QMP greeting for system_powerdown: {greeting}")
                log.write(f"PASS system-powerdown-qmp-greeting {greeting['QMP']['version']['package']}\n")

                require_return(qmp_execute(sock, sock_file, "qmp_capabilities", events), "qmp_capabilities")
                status = require_return(qmp_execute(sock, sock_file, "query-status", events), "query-status")
                if status.get("status") != "prelaunch" or status.get("running") is not False:
                    raise RuntimeError(f"unexpected system_powerdown prelaunch status: {status}")
                log.write(f"PASS system-powerdown-query-status-prelaunch {status['status']}\n")

                require_return(qmp_execute(sock, sock_file, "cont", events), "cont")
                require_event_count(events, "RESUME", 1, "system-powerdown-event-resume", log)
                log.write("PASS system-powerdown-cont OK\n")

                status = require_return(qmp_execute(sock, sock_file, "query-status", events), "query-status")
                if status.get("status") != "running" or status.get("running") is not True:
                    raise RuntimeError(f"unexpected system_powerdown running status: {status}")
                log.write(f"PASS system-powerdown-query-status {status['status']}\n")

                require_return(qmp_execute(sock, sock_file, "system_powerdown", events), "system_powerdown")
                require_event_count(events, "SHUTDOWN", 1, "system-powerdown-event-shutdown", log)
                log.write("PASS system-powerdown OK\n")

        rc = proc.wait(timeout=args.timeout)
        if rc != 0:
            raise RuntimeError(f"NEMU system_powerdown QMP exited with rc={rc}")
        log.write("PASS system-powerdown-nemu-exit rc=0\n")
        content = read_text(args.system_powerdown_nemu_log) + "\n" + read_text(args.log)
        if "QMP system_powerdown requested" not in content:
            raise RuntimeError("system_powerdown command did not reach NEMU powerdown handler")
        log.write("PASS system-powerdown-log-requested\n")
    except Exception:
        kill_and_wait(proc)
        raise
    finally:
        unlink_owned_artifact(args.system_powerdown_image, payload_identity)


def run_guest_shutdown_event(args, log):
    payload_identity = None
    payload_identity = write_guest_poweroff_image(args.guest_shutdown_image)

    port = reserve_port()
    cmd = [
        args.nemu,
        "-b",
        "--max-insts=1000",
        f"--qmp={port}",
        f"--log={args.guest_shutdown_nemu_log}",
        "-i",
        args.guest_shutdown_image,
    ]

    log.write(f"guest-shutdown-command: {' '.join(cmd)}\n")
    proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
    try:
        with connect_with_retry(port, time.monotonic() + args.timeout) as sock:
            with sock.makefile("rwb", buffering=0) as sock_file:
                events = []
                greeting = recv_json_line(sock_file)
                if "QMP" not in greeting:
                    raise RuntimeError(f"missing QMP greeting for guest shutdown: {greeting}")
                log.write(f"PASS guest-shutdown-qmp-greeting {greeting['QMP']['version']['package']}\n")

                require_return(qmp_execute(sock, sock_file, "qmp_capabilities", events), "qmp_capabilities")
                status = require_return(qmp_execute(sock, sock_file, "query-status", events), "query-status")
                if status.get("status") != "prelaunch" or status.get("running") is not False:
                    raise RuntimeError(f"unexpected guest shutdown prelaunch status: {status}")
                log.write(f"PASS guest-shutdown-query-status-prelaunch {status['status']}\n")

                require_return(qmp_execute(sock, sock_file, "cont", events), "cont")
                require_event_count(events, "RESUME", 1, "guest-shutdown-event-resume", log)
                log.write("PASS guest-shutdown-cont OK\n")

                recv_event_until(sock_file, events, "SHUTDOWN", time.monotonic() + args.timeout)
                require_event_count(events, "SHUTDOWN", 1, "guest-shutdown-event-shutdown", log)

        rc = proc.wait(timeout=args.timeout)
        if rc != 0:
            raise RuntimeError(f"NEMU guest shutdown QMP exited with rc={rc}")
        log.write("PASS guest-shutdown-nemu-exit rc=0\n")
        log.flush()
        content = read_text(args.guest_shutdown_nemu_log) + "\n" + read_text(args.log)
        if "syscon-reset: poweroff requested" not in content:
            raise RuntimeError("guest shutdown path did not hit syscon poweroff")
        log.write("PASS guest-shutdown-syscon-poweroff\n")
        if "QMP guest shutdown event emitted" not in content:
            raise RuntimeError("guest shutdown path did not emit QMP shutdown event")
        log.write("PASS guest-shutdown-qmp-emitted\n")
        if "HIT GOOD TRAP" not in content:
            raise RuntimeError("guest shutdown path did not finish with good trap")
        log.write("PASS guest-shutdown-good-trap\n")
    except Exception:
        kill_and_wait(proc)
        raise
    finally:
        unlink_owned_artifact(args.guest_shutdown_image, payload_identity)


def main() -> int:
    parser = argparse.ArgumentParser(description="Smoke-test NEMU's minimal QMP startup socket")
    parser.add_argument("--nemu", required=True)
    parser.add_argument("--log", required=True)
    parser.add_argument("--nemu-log", required=True)
    parser.add_argument("--cont-nemu-log", required=True)
    parser.add_argument("--block-nemu-log", required=True)
    parser.add_argument("--runtime-nemu-log", required=True)
    parser.add_argument("--disconnect-nemu-log", required=True)
    parser.add_argument("--system-powerdown-nemu-log", required=True)
    parser.add_argument("--guest-shutdown-nemu-log", required=True)
    parser.add_argument("--block-image", required=True)
    parser.add_argument("--overlay-image", required=True)
    parser.add_argument("--runtime-overlay-image", required=True)
    parser.add_argument("--disconnect-image", required=True)
    parser.add_argument("--system-powerdown-image", required=True)
    parser.add_argument("--guest-shutdown-image", required=True)
    parser.add_argument("--firmware", required=True)
    parser.add_argument("--kernel", required=True)
    parser.add_argument("--dtb", required=True)
    parser.add_argument("--next-addr", default="0x80200000")
    parser.add_argument("--dtb-addr", default="0x82200000")
    parser.add_argument("--runtime-max-insts", type=int, default=1000000000)
    parser.add_argument("--timeout", type=float, default=10.0)
    args = parser.parse_args()

    validate_artifact_paths(args)
    log_parent = os.path.dirname(args.log)
    if log_parent:
        os.makedirs(log_parent, exist_ok=True)
    with open(args.log, "w", encoding="utf-8") as log:
        run_qmp_gdbstub_conflict(args, log)
        run_startup_disconnect(args, log)
        run_query_quit(args, log)
        run_query_cont(args, log)
        run_query_block_attached(args, log)
        run_query_runtime(args, log)
        run_runtime_stop_disconnect(args, log)
        run_system_powerdown(args, log)
        run_guest_shutdown_event(args, log)
        log.write("__NEMU_QMP_SMOKE__:ok\n")

    return 0


if __name__ == "__main__":
    sys.exit(main())
