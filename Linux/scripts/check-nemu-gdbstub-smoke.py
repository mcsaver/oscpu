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


def recv_packet(sock: socket.socket, send_ack: bool = True) -> str:
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
        if send_ack:
            sock.sendall(b"-")
        raise RuntimeError(f"bad checksum: got {got:02x}, want {want:02x}")
    if send_ack:
        sock.sendall(b"+")
    return body.decode("ascii")


def send_packet(
    sock: socket.socket,
    payload: str,
    expect_ack: bool = True,
    ack_reply: bool = True,
) -> str:
    sock.sendall(packet(payload))
    if expect_ack:
        ack = read_exact(sock, 1)
        if ack != b"+":
            raise RuntimeError(f"gdbstub rejected packet {payload!r}: ack={ack!r}")
    return recv_packet(sock, send_ack=ack_reply)


def send_packet_no_reply(sock: socket.socket, payload: str, expect_ack: bool = True) -> None:
    sock.sendall(packet(payload))
    if expect_ack:
        ack = read_exact(sock, 1)
        if ack != b"+":
            raise RuntimeError(f"gdbstub rejected packet {payload!r}: ack={ack!r}")


def word_le_hex(value: int) -> str:
    return value.to_bytes(8, byteorder="little", signed=False).hex()


def word_from_le_hex(value: str) -> int:
    return int.from_bytes(bytes.fromhex(value), byteorder="little", signed=False)


def ascii_from_hex(value: str) -> str:
    return bytes.fromhex(value).decode("ascii")


def words32_le_hex(words: list[int]) -> str:
    return b"".join(word.to_bytes(4, byteorder="little", signed=False) for word in words).hex()


def guest_poweroff_program_hex() -> str:
    return words32_le_hex([
        0x001002B7,  # lui t0, 0x100      ; t0 = 0x00100000
        0x00005337,  # lui t1, 0x5        ; t1 = 0x5000
        0x55530313,  # addi t1, t1, 0x555 ; t1 = 0x5555
        0x0062A023,  # sw t1, 0(t0)       ; syscon poweroff
        0x0000006F,  # j .                ; fallback if MMIO did not stop
    ])


def guest_spin_program_hex() -> str:
    return words32_le_hex([
        0x0000006F,  # j .                ; stay running until GDB sends raw Ctrl-C
    ])


def guest_write_watch_program_hex() -> str:
    return words32_le_hex([
        0x00000297,  # auipc t0, 0        ; t0 = current PC = 0x80000000
        0x10028293,  # addi t0, t0, 0x100 ; t0 = 0x80000100
        0x02A00313,  # addi t1, zero, 42
        0x0062A023,  # sw t1, 0(t0)       ; trigger Z2/Z4 watchpoint
        0x001002B7,  # lui t0, 0x100      ; t0 = 0x00100000
        0x00005337,  # lui t1, 0x5        ; t1 = 0x5000
        0x55530313,  # addi t1, t1, 0x555 ; t1 = 0x5555
        0x0062A023,  # sw t1, 0(t0)       ; syscon poweroff
        0x0000006F,  # j .                ; fallback if MMIO did not stop
    ])


def guest_read_watch_program_hex() -> str:
    return words32_le_hex([
        0x00000297,  # auipc t0, 0        ; t0 = current PC = 0x80000000
        0x10028293,  # addi t0, t0, 0x100 ; t0 = 0x80000100
        0x0002A303,  # lw t1, 0(t0)       ; trigger Z3 watchpoint
        0x001002B7,  # lui t0, 0x100      ; t0 = 0x00100000
        0x00005337,  # lui t1, 0x5        ; t1 = 0x5000
        0x55530313,  # addi t1, t1, 0x555 ; t1 = 0x5555
        0x0062A023,  # sw t1, 0(t0)       ; syscon poweroff
        0x0000006F,  # j .                ; fallback if MMIO did not stop
    ])


def read_text(path: str) -> str:
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            return f.read()
    except FileNotFoundError:
        return ""


def read_qxfer(sock: socket.socket, obj: str, annex: str, chunk_size: int = 0x80) -> str:
    offset = 0
    chunks = []
    while True:
        reply = send_packet(sock, f"qXfer:{obj}:read:{annex}:{offset:x},{chunk_size:x}")
        if not reply:
            raise RuntimeError(f"qXfer:{obj}:read returned an empty reply")
        marker = reply[0]
        if marker not in ("m", "l"):
            raise RuntimeError(f"qXfer:{obj}:read returned unexpected marker: {reply[:32]!r}")
        data = reply[1:]
        chunks.append(data)
        offset += len(data.encode("ascii"))
        if marker == "l":
            return "".join(chunks)


def read_target_xml(sock: socket.socket, chunk_size: int = 0x80) -> str:
    return read_qxfer(sock, "features", "target.xml", chunk_size)


def read_memory_map(sock: socket.socket, chunk_size: int = 0x40) -> str:
    return read_qxfer(sock, "memory-map", "", chunk_size)


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


def run_continue_exit(args, log) -> None:
    port = reserve_port()
    continue_nemu_log = args.nemu_log + ".continue"
    cmd = [
        args.nemu,
        f"--gdbstub={port}",
        f"--monitor-cmd={args.monitor_cmd}",
        f"--log={continue_nemu_log}",
    ]
    program_hex = guest_poweroff_program_hex()
    program_len = len(program_hex) // 2

    log.write(f"continue-command: {' '.join(cmd)}\n")
    proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
    try:
        with connect_with_retry(port, time.monotonic() + args.timeout) as sock:
            supported = send_packet(sock, "qSupported")
            if "PacketSize=" not in supported:
                raise RuntimeError(f"continue qSupported missing PacketSize: {supported}")
            log.write(f"PASS continue-qSupported {supported}\n")

            write_program = send_packet(sock, f"M80000000,{program_len:x}:{program_hex}")
            if write_program != "OK":
                raise RuntimeError(f"continue program write failed: {write_program}")
            set_pc = send_packet(sock, f"P20={word_le_hex(0x80000000)}")
            if set_pc != "OK":
                raise RuntimeError(f"continue pc setup failed: {set_pc}")
            cont = send_packet(sock, "c")
            if cont != "W00":
                raise RuntimeError(f"continue returned unexpected reply: {cont}")
            log.write("PASS continue-exit W00\n")

        rc = proc.wait(timeout=args.timeout)
        if rc != 0:
            raise RuntimeError(f"NEMU continue exited with rc={rc}")
        log.write("PASS continue-nemu-exit rc=0\n")
        log.flush()

        content = read_text(continue_nemu_log) + "\n" + read_text(args.log)
        if "syscon-reset: poweroff requested" not in content:
            raise RuntimeError("continue path did not hit syscon poweroff")
        log.write("PASS continue-syscon-poweroff\n")
        if "HIT GOOD TRAP" not in content:
            raise RuntimeError("continue path did not finish with good trap")
        log.write("PASS continue-good-trap\n")
    except Exception:
        proc.kill()
        proc.wait(timeout=5)
        raise


def run_swbreak_continue(args, log) -> None:
    port = reserve_port()
    swbreak_nemu_log = args.nemu_log + ".swbreak"
    cmd = [
        args.nemu,
        f"--gdbstub={port}",
        f"--monitor-cmd={args.monitor_cmd}",
        f"--log={swbreak_nemu_log}",
    ]
    program_hex = guest_poweroff_program_hex()
    program_len = len(program_hex) // 2
    break_pc = 0x80000008

    log.write(f"swbreak-command: {' '.join(cmd)}\n")
    proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
    try:
        with connect_with_retry(port, time.monotonic() + args.timeout) as sock:
            supported = send_packet(sock, "qSupported")
            if "PacketSize=" not in supported:
                raise RuntimeError(f"swbreak qSupported missing PacketSize: {supported}")
            if "swbreak+" not in supported:
                raise RuntimeError(f"qSupported missing software breakpoint feature: {supported}")
            if "vContSupported+" not in supported:
                raise RuntimeError(f"qSupported missing vCont feature: {supported}")
            log.write(f"PASS swbreak-qSupported {supported}\n")

            write_program = send_packet(sock, f"M80000000,{program_len:x}:{program_hex}")
            if write_program != "OK":
                raise RuntimeError(f"swbreak program write failed: {write_program}")
            set_pc = send_packet(sock, f"P20={word_le_hex(0x80000000)}")
            if set_pc != "OK":
                raise RuntimeError(f"swbreak pc setup failed: {set_pc}")

            insert = send_packet(sock, f"Z0,{break_pc:x},4")
            if insert != "OK":
                raise RuntimeError(f"software breakpoint insert failed: {insert}")
            log.write("PASS swbreak-insert OK\n")

            hit = send_packet(sock, "vCont;c")
            if hit != "S05":
                raise RuntimeError(f"software breakpoint did not stop with S05: {hit}")
            log.write("PASS swbreak-hit S05\n")
            log.write("PASS swbreak-vcont-hit S05\n")

            pc_after_hit = send_packet(sock, "p20")
            expected_pc = word_le_hex(break_pc)
            if pc_after_hit != expected_pc:
                raise RuntimeError(f"software breakpoint pc mismatch: {pc_after_hit}, want {expected_pc}")
            log.write(f"PASS swbreak-pc {pc_after_hit}\n")

            remove = send_packet(sock, f"z0,{break_pc:x},4")
            if remove != "OK":
                raise RuntimeError(f"software breakpoint remove failed: {remove}")
            log.write("PASS swbreak-remove OK\n")

            cont = send_packet(sock, "vCont;c")
            if cont != "W00":
                raise RuntimeError(f"continue after software breakpoint returned unexpected reply: {cont}")
            log.write("PASS swbreak-continue-exit W00\n")
            log.write("PASS swbreak-vcont-continue-exit W00\n")

        rc = proc.wait(timeout=args.timeout)
        if rc != 0:
            raise RuntimeError(f"NEMU swbreak exited with rc={rc}")
        log.write("PASS swbreak-nemu-exit rc=0\n")
        log.flush()

        content = read_text(swbreak_nemu_log) + "\n" + read_text(args.log)
        if "syscon-reset: poweroff requested" not in content:
            raise RuntimeError("swbreak path did not hit syscon poweroff")
        log.write("PASS swbreak-syscon-poweroff\n")
        if "HIT GOOD TRAP" not in content:
            raise RuntimeError("swbreak path did not finish with good trap")
        log.write("PASS swbreak-good-trap\n")
    except Exception:
        proc.kill()
        proc.wait(timeout=5)
        raise


def run_hbreak_continue(args, log) -> None:
    port = reserve_port()
    hbreak_nemu_log = args.nemu_log + ".hbreak"
    cmd = [
        args.nemu,
        f"--gdbstub={port}",
        f"--monitor-cmd={args.monitor_cmd}",
        f"--log={hbreak_nemu_log}",
    ]
    program_hex = guest_poweroff_program_hex()
    program_len = len(program_hex) // 2
    break_pc = 0x80000008

    log.write(f"hbreak-command: {' '.join(cmd)}\n")
    proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
    try:
        with connect_with_retry(port, time.monotonic() + args.timeout) as sock:
            supported = send_packet(sock, "qSupported")
            if "PacketSize=" not in supported:
                raise RuntimeError(f"hbreak qSupported missing PacketSize: {supported}")
            if "hwbreak+" not in supported:
                raise RuntimeError(f"qSupported missing hardware breakpoint feature: {supported}")
            if "vContSupported+" not in supported:
                raise RuntimeError(f"qSupported missing vCont feature: {supported}")
            log.write(f"PASS hbreak-qSupported {supported}\n")

            write_program = send_packet(sock, f"M80000000,{program_len:x}:{program_hex}")
            if write_program != "OK":
                raise RuntimeError(f"hbreak program write failed: {write_program}")
            set_pc = send_packet(sock, f"P20={word_le_hex(0x80000000)}")
            if set_pc != "OK":
                raise RuntimeError(f"hbreak pc setup failed: {set_pc}")

            insert = send_packet(sock, f"Z1,{break_pc:x},4")
            if insert != "OK":
                raise RuntimeError(f"hardware breakpoint insert failed: {insert}")
            log.write("PASS hbreak-insert OK\n")

            hit = send_packet(sock, "vCont;c")
            if hit != "S05":
                raise RuntimeError(f"hardware breakpoint did not stop with S05: {hit}")
            log.write("PASS hbreak-hit S05\n")
            log.write("PASS hbreak-vcont-hit S05\n")

            pc_after_hit = send_packet(sock, "p20")
            expected_pc = word_le_hex(break_pc)
            if pc_after_hit != expected_pc:
                raise RuntimeError(f"hardware breakpoint pc mismatch: {pc_after_hit}, want {expected_pc}")
            log.write(f"PASS hbreak-pc {pc_after_hit}\n")

            remove = send_packet(sock, f"z1,{break_pc:x},4")
            if remove != "OK":
                raise RuntimeError(f"hardware breakpoint remove failed: {remove}")
            log.write("PASS hbreak-remove OK\n")

            cont = send_packet(sock, "vCont;c")
            if cont != "W00":
                raise RuntimeError(f"continue after hardware breakpoint returned unexpected reply: {cont}")
            log.write("PASS hbreak-continue-exit W00\n")
            log.write("PASS hbreak-vcont-continue-exit W00\n")

        rc = proc.wait(timeout=args.timeout)
        if rc != 0:
            raise RuntimeError(f"NEMU hbreak exited with rc={rc}")
        log.write("PASS hbreak-nemu-exit rc=0\n")
        log.flush()

        content = read_text(hbreak_nemu_log) + "\n" + read_text(args.log)
        if "syscon-reset: poweroff requested" not in content:
            raise RuntimeError("hbreak path did not hit syscon poweroff")
        log.write("PASS hbreak-syscon-poweroff\n")
        if "HIT GOOD TRAP" not in content:
            raise RuntimeError("hbreak path did not finish with good trap")
        log.write("PASS hbreak-good-trap\n")
    except Exception:
        proc.kill()
        proc.wait(timeout=5)
        raise


def run_watchpoint_case(args, log, rsp_type: int, name: str, program_hex: str, expected_pc: int) -> None:
    port = reserve_port()
    watch_nemu_log = f"{args.nemu_log}.{name}"
    cmd = [
        args.nemu,
        f"--gdbstub={port}",
        f"--monitor-cmd={args.monitor_cmd}",
        f"--log={watch_nemu_log}",
    ]
    program_len = len(program_hex) // 2
    watched_addr = 0x80000100

    log.write(f"{name}-command: {' '.join(cmd)}\n")
    proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
    try:
        with connect_with_retry(port, time.monotonic() + args.timeout) as sock:
            supported = send_packet(sock, "qSupported")
            if "PacketSize=" not in supported:
                raise RuntimeError(f"{name} qSupported missing PacketSize: {supported}")
            if "watchpoint+" not in supported:
                raise RuntimeError(f"qSupported missing watchpoint feature: {supported}")
            if "vContSupported+" not in supported:
                raise RuntimeError(f"qSupported missing vCont feature: {supported}")
            log.write(f"PASS {name}-qSupported {supported}\n")

            init_data = send_packet(sock, "M80000100,4:78563412")
            if init_data != "OK":
                raise RuntimeError(f"{name} data setup failed: {init_data}")
            write_program = send_packet(sock, f"M80000000,{program_len:x}:{program_hex}")
            if write_program != "OK":
                raise RuntimeError(f"{name} program write failed: {write_program}")
            set_pc = send_packet(sock, f"P20={word_le_hex(0x80000000)}")
            if set_pc != "OK":
                raise RuntimeError(f"{name} pc setup failed: {set_pc}")

            insert = send_packet(sock, f"Z{rsp_type},{watched_addr:x},4")
            if insert != "OK":
                raise RuntimeError(f"{name} watchpoint insert failed: {insert}")
            log.write(f"PASS {name}-insert Z{rsp_type} OK\n")

            hit = send_packet(sock, "vCont;c")
            if hit != "S05":
                raise RuntimeError(f"{name} did not stop with S05: {hit}")
            log.write(f"PASS {name}-hit S05\n")

            pc_after_hit = send_packet(sock, "p20")
            expected_pc_hex = word_le_hex(expected_pc)
            if pc_after_hit != expected_pc_hex:
                raise RuntimeError(f"{name} pc mismatch: {pc_after_hit}, want {expected_pc_hex}")
            log.write(f"PASS {name}-pc {pc_after_hit}\n")

            remove = send_packet(sock, f"z{rsp_type},{watched_addr:x},4")
            if remove != "OK":
                raise RuntimeError(f"{name} watchpoint remove failed: {remove}")
            log.write(f"PASS {name}-remove OK\n")

            cont = send_packet(sock, "vCont;c")
            if cont != "W00":
                raise RuntimeError(f"continue after {name} returned unexpected reply: {cont}")
            log.write(f"PASS {name}-continue-exit W00\n")

        rc = proc.wait(timeout=args.timeout)
        if rc != 0:
            raise RuntimeError(f"NEMU {name} exited with rc={rc}")
        log.write(f"PASS {name}-nemu-exit rc=0\n")
        log.flush()

        content = read_text(watch_nemu_log) + "\n" + read_text(args.log)
        watch_log_name = {
            2: "write watchpoint",
            3: "read watchpoint",
            4: "access watchpoint",
        }[rsp_type]
        if f"GDB stub {watch_log_name} hit" not in content:
            raise RuntimeError(f"{name} path did not log watchpoint hit")
        log.write(f"PASS {name}-hit-log\n")
        if "syscon-reset: poweroff requested" not in content:
            raise RuntimeError(f"{name} path did not hit syscon poweroff")
        log.write(f"PASS {name}-syscon-poweroff\n")
        if "HIT GOOD TRAP" not in content:
            raise RuntimeError(f"{name} path did not finish with good trap")
        log.write(f"PASS {name}-good-trap\n")
    except Exception:
        proc.kill()
        proc.wait(timeout=5)
        raise


def run_watchpoints(args, log) -> None:
    run_watchpoint_case(args, log, 2, "watch-write", guest_write_watch_program_hex(), 0x80000010)
    run_watchpoint_case(args, log, 3, "watch-read", guest_read_watch_program_hex(), 0x8000000C)
    run_watchpoint_case(args, log, 4, "watch-access", guest_write_watch_program_hex(), 0x80000010)


def run_async_halt(args, log) -> None:
    port = reserve_port()
    async_nemu_log = args.nemu_log + ".async"
    cmd = [
        args.nemu,
        f"--gdbstub={port}",
        f"--monitor-cmd={args.monitor_cmd}",
        f"--log={async_nemu_log}",
    ]
    spin_hex = guest_spin_program_hex()
    spin_len = len(spin_hex) // 2
    poweroff_hex = guest_poweroff_program_hex()
    poweroff_len = len(poweroff_hex) // 2

    log.write(f"async-halt-command: {' '.join(cmd)}\n")
    proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
    try:
        with connect_with_retry(port, time.monotonic() + args.timeout) as sock:
            supported = send_packet(sock, "qSupported")
            if "PacketSize=" not in supported:
                raise RuntimeError(f"async halt qSupported missing PacketSize: {supported}")
            if "async-stop+" not in supported:
                raise RuntimeError(f"qSupported missing async stop feature: {supported}")
            log.write(f"PASS async-halt-qSupported {supported}\n")

            write_spin = send_packet(sock, f"M80000000,{spin_len:x}:{spin_hex}")
            if write_spin != "OK":
                raise RuntimeError(f"async halt spin program write failed: {write_spin}")
            set_pc = send_packet(sock, f"P20={word_le_hex(0x80000000)}")
            if set_pc != "OK":
                raise RuntimeError(f"async halt pc setup failed: {set_pc}")

            send_packet_no_reply(sock, "c")
            time.sleep(0.05)
            sock.sendall(b"\x03")
            halted = recv_packet(sock)
            if halted != "S05":
                raise RuntimeError(f"async halt returned unexpected reply: {halted}")
            log.write("PASS async-halt S05\n")

            pc_after_halt = send_packet(sock, "p20")
            if pc_after_halt != word_le_hex(0x80000000):
                raise RuntimeError(f"async halt pc mismatch: {pc_after_halt}")
            log.write(f"PASS async-halt-pc {pc_after_halt}\n")

            write_poweroff = send_packet(sock, f"M80000000,{poweroff_len:x}:{poweroff_hex}")
            if write_poweroff != "OK":
                raise RuntimeError(f"async halt poweroff program write failed: {write_poweroff}")
            reset_pc = send_packet(sock, f"P20={word_le_hex(0x80000000)}")
            if reset_pc != "OK":
                raise RuntimeError(f"async halt pc reset failed: {reset_pc}")
            cont = send_packet(sock, "c")
            if cont != "W00":
                raise RuntimeError(f"continue after async halt returned unexpected reply: {cont}")
            log.write("PASS async-halt-continue-exit W00\n")

        rc = proc.wait(timeout=args.timeout)
        if rc != 0:
            raise RuntimeError(f"NEMU async halt exited with rc={rc}")
        log.write("PASS async-halt-nemu-exit rc=0\n")
        log.flush()

        content = read_text(async_nemu_log) + "\n" + read_text(args.log)
        if "GDB stub async interrupt requested" not in content:
            raise RuntimeError("async halt path did not log the Ctrl-C interrupt")
        log.write("PASS async-halt-ctrl-c-log\n")
        if "syscon-reset: poweroff requested" not in content:
            raise RuntimeError("async halt path did not hit syscon poweroff")
        log.write("PASS async-halt-syscon-poweroff\n")
        if "HIT GOOD TRAP" not in content:
            raise RuntimeError("async halt path did not finish with good trap")
        log.write("PASS async-halt-good-trap\n")
    except Exception:
        proc.kill()
        proc.wait(timeout=5)
        raise


def run_no_ack_mode(args, log) -> None:
    port = reserve_port()
    noack_nemu_log = args.nemu_log + ".noack"
    cmd = [
        args.nemu,
        f"--gdbstub={port}",
        f"--monitor-cmd={args.monitor_cmd}",
        f"--log={noack_nemu_log}",
    ]

    log.write(f"noack-command: {' '.join(cmd)}\n")
    proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
    try:
        with connect_with_retry(port, time.monotonic() + args.timeout) as sock:
            supported = send_packet(sock, "qSupported")
            if "PacketSize=" not in supported:
                raise RuntimeError(f"noack qSupported missing PacketSize: {supported}")
            if "QStartNoAckMode+" not in supported:
                raise RuntimeError(f"qSupported missing no-ack feature: {supported}")
            log.write(f"PASS noack-qSupported {supported}\n")

            start = send_packet(sock, "QStartNoAckMode")
            if start != "OK":
                raise RuntimeError(f"QStartNoAckMode failed: {start}")
            log.write("PASS noack-start OK\n")

            stop = send_packet(sock, "?", expect_ack=False, ack_reply=False)
            if stop != "S05":
                raise RuntimeError(f"noack stop reply mismatch: {stop}")
            log.write("PASS noack-stop-reason S05\n")

            pc = send_packet(sock, "p20", expect_ack=False, ack_reply=False)
            if len(pc) != 16:
                raise RuntimeError(f"noack pc packet has unexpected length: {pc}")
            log.write(f"PASS noack-read-pc {pc}\n")

            vcont = send_packet(sock, "vCont?", expect_ack=False, ack_reply=False)
            if vcont != "vCont;c;s":
                raise RuntimeError(f"noack vCont query reply mismatch: {vcont}")
            log.write("PASS noack-vCont-query vCont;c;s\n")

            detach = send_packet(sock, "D", expect_ack=False, ack_reply=False)
            if detach != "OK":
                raise RuntimeError(f"noack detach failed: {detach}")
            log.write("PASS noack-detach OK\n")

        rc = proc.wait(timeout=args.timeout)
        if rc != 0:
            raise RuntimeError(f"NEMU noack exited with rc={rc}")
        log.write("PASS noack-nemu-exit rc=0\n")
        log.flush()

        content = read_text(noack_nemu_log) + "\n" + read_text(args.log)
        if "GDB stub no-ack mode enabled" not in content:
            raise RuntimeError("noack path did not log no-ack enable")
        log.write("PASS noack-log-enabled\n")
    except Exception:
        proc.kill()
        proc.wait(timeout=5)
        raise


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
                if "qXfer:features:read+" not in supported:
                    raise RuntimeError(f"qSupported missing target XML feature: {supported}")
                if "qXfer:memory-map:read+" not in supported:
                    raise RuntimeError(f"qSupported missing memory-map feature: {supported}")
                if "swbreak+" not in supported:
                    raise RuntimeError(f"qSupported missing software breakpoint feature: {supported}")
                if "hwbreak+" not in supported:
                    raise RuntimeError(f"qSupported missing hardware breakpoint feature: {supported}")
                if "watchpoint+" not in supported:
                    raise RuntimeError(f"qSupported missing watchpoint feature: {supported}")
                if "vContSupported+" not in supported:
                    raise RuntimeError(f"qSupported missing vCont feature: {supported}")
                if "async-stop+" not in supported:
                    raise RuntimeError(f"qSupported missing async stop feature: {supported}")
                if "QStartNoAckMode+" not in supported:
                    raise RuntimeError(f"qSupported missing no-ack feature: {supported}")
                log.write(f"PASS qSupported {supported}\n")

                vcont_query = send_packet(sock, "vCont?")
                if vcont_query != "vCont;c;s":
                    raise RuntimeError(f"unexpected vCont query reply: {vcont_query}")
                log.write("PASS vCont-query vCont;c;s\n")

                qf_threads = send_packet(sock, "qfThreadInfo")
                qs_threads = send_packet(sock, "qsThreadInfo")
                thread_alive = send_packet(sock, "T1")
                if qf_threads != "m1" or qs_threads != "l" or thread_alive != "OK":
                    raise RuntimeError(
                        f"unexpected single-thread replies: qf={qf_threads} qs={qs_threads} T1={thread_alive}"
                    )
                log.write("PASS thread-info qf=m1 qs=l T1=OK\n")

                thread_extra = ascii_from_hex(send_packet(sock, "qThreadExtraInfo,1"))
                if thread_extra != "NEMU single hart":
                    raise RuntimeError(f"unexpected thread extra info: {thread_extra!r}")
                log.write(f"PASS thread-extra {thread_extra}\n")

                target_xml = read_target_xml(sock)
                required_xml = [
                    "<architecture>riscv:rv64</architecture>",
                    '<feature name="org.gnu.gdb.riscv.cpu">',
                    '<reg name="zero" bitsize="64" type="int" regnum="0"/>',
                    '<reg name="pc" bitsize="64" type="code_ptr" regnum="32"/>',
                ]
                for marker in required_xml:
                    if marker not in target_xml:
                        raise RuntimeError(f"target.xml missing marker: {marker}")
                reg_count = target_xml.count("<reg name=")
                if reg_count != 33:
                    raise RuntimeError(f"target.xml register count mismatch: {reg_count}")
                log.write(f"PASS target-xml riscv64 regs={reg_count} bytes={len(target_xml)}\n")

                memory_map = read_memory_map(sock)
                required_memory_map = [
                    "<memory-map>",
                    '<memory type="ram" start="0x80000000" length="0x40000000"/>',
                ]
                for marker in required_memory_map:
                    if marker not in memory_map:
                        raise RuntimeError(f"memory-map missing marker: {marker}")
                log.write(
                    f"PASS memory-map ram start=0x80000000 length=0x40000000 bytes={len(memory_map)}\n"
                )

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

                write_x0 = send_packet(sock, f"P0={word_le_hex(0x1122334455667788)}")
                if write_x0 != "OK":
                    raise RuntimeError(f"write x0 failed: {write_x0}")
                x0 = send_packet(sock, "p0")
                if x0 != word_le_hex(0):
                    raise RuntimeError(f"x0 changed after write: {x0}")
                log.write("PASS write-x0-ignored OK\n")

                alt_pc = word_le_hex(0x80000004)
                write_pc = send_packet(sock, f"P20={alt_pc}")
                if write_pc != "OK":
                    raise RuntimeError(f"write pc failed: {write_pc}")
                pc_after_write = send_packet(sock, "p20")
                if pc_after_write != alt_pc:
                    raise RuntimeError(f"pc write did not stick: {pc_after_write}")
                restore_pc = send_packet(sock, f"P20={pc}")
                if restore_pc != "OK" or send_packet(sock, "p20") != pc:
                    raise RuntimeError("pc restore failed")
                log.write(f"PASS write-pc {pc}->{alt_pc}->restore\n")

                mem = send_packet(sock, "m80000000,4")
                if len(mem) != 8:
                    raise RuntimeError(f"memory packet has unexpected length: {mem}")
                log.write(f"PASS read-pmem-reset-vector {mem}\n")

                patch_mem = "13000000"
                write_mem = send_packet(sock, f"M80000000,4:{patch_mem}")
                if write_mem != "OK":
                    raise RuntimeError(f"write PMEM failed: {write_mem}")
                mem_after_write = send_packet(sock, "m80000000,4")
                if mem_after_write != patch_mem:
                    raise RuntimeError(f"PMEM write did not stick: {mem_after_write}")
                restore_mem = send_packet(sock, f"M80000000,4:{mem}")
                if restore_mem != "OK" or send_packet(sock, "m80000000,4") != mem:
                    raise RuntimeError("PMEM restore failed")
                log.write(f"PASS write-pmem-reset-vector {mem}->{patch_mem}->restore\n")

                step_pc = send_packet(sock, f"P20={pc}")
                if step_pc != "OK" or send_packet(sock, "p20") != pc:
                    raise RuntimeError("pc reset before single-step failed")
                write_step_mem = send_packet(sock, f"M80000000,4:{patch_mem}")
                if write_step_mem != "OK" or send_packet(sock, "m80000000,4") != patch_mem:
                    raise RuntimeError("single-step NOP patch failed")
                step_reply = send_packet(sock, "s")
                if step_reply != "S05":
                    raise RuntimeError(f"single-step returned unexpected stop reply: {step_reply}")
                stepped_pc = send_packet(sock, "p20")
                expected_step_pc = word_le_hex((word_from_le_hex(pc) + 4) & ((1 << 64) - 1))
                if stepped_pc != expected_step_pc:
                    raise RuntimeError(f"single-step pc mismatch: {stepped_pc}, want {expected_step_pc}")
                restore_step_mem = send_packet(sock, f"M80000000,4:{mem}")
                restore_step_pc = send_packet(sock, f"P20={pc}")
                if (restore_step_mem != "OK" or restore_step_pc != "OK" or
                        send_packet(sock, "m80000000,4") != mem or send_packet(sock, "p20") != pc):
                    raise RuntimeError("single-step restore failed")
                log.write(f"PASS single-step {step_reply} pc={pc}->{stepped_pc}->restore\n")

                vcont_pc = send_packet(sock, f"P20={pc}")
                if vcont_pc != "OK" or send_packet(sock, "p20") != pc:
                    raise RuntimeError("pc reset before vCont step failed")
                write_vcont_mem = send_packet(sock, f"M80000000,4:{patch_mem}")
                if write_vcont_mem != "OK" or send_packet(sock, "m80000000,4") != patch_mem:
                    raise RuntimeError("vCont step NOP patch failed")
                vcont_step_reply = send_packet(sock, "vCont;s")
                if vcont_step_reply != "S05":
                    raise RuntimeError(f"vCont step returned unexpected stop reply: {vcont_step_reply}")
                vcont_stepped_pc = send_packet(sock, "p20")
                if vcont_stepped_pc != expected_step_pc:
                    raise RuntimeError(f"vCont step pc mismatch: {vcont_stepped_pc}, want {expected_step_pc}")
                restore_vcont_mem = send_packet(sock, f"M80000000,4:{mem}")
                restore_vcont_pc = send_packet(sock, f"P20={pc}")
                if (restore_vcont_mem != "OK" or restore_vcont_pc != "OK" or
                        send_packet(sock, "m80000000,4") != mem or send_packet(sock, "p20") != pc):
                    raise RuntimeError("vCont step restore failed")
                log.write(f"PASS vcont-step {vcont_step_reply} pc={pc}->{vcont_stepped_pc}->restore\n")

                detach = send_packet(sock, "D")
                if detach != "OK":
                    raise RuntimeError(f"detach failed: {detach}")
                log.write("PASS detach OK\n")

            rc = proc.wait(timeout=args.timeout)
            if rc != 0:
                raise RuntimeError(f"NEMU exited with rc={rc}")
            log.write("PASS nemu-exit rc=0\n")
            run_continue_exit(args, log)
            run_swbreak_continue(args, log)
            run_hbreak_continue(args, log)
            run_watchpoints(args, log)
            run_async_halt(args, log)
            run_no_ack_mode(args, log)
            log.write("__NEMU_GDBSTUB_SMOKE__:ok\n")
        except Exception:
            proc.kill()
            proc.wait(timeout=5)
            raise

    return 0


if __name__ == "__main__":
    sys.exit(main())
