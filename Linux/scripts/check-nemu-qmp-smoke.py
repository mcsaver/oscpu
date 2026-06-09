#!/usr/bin/env python3
import argparse
import json
import os
import socket
import subprocess
import sys
import time


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
    raise RuntimeError(f"could not connect to QMP on port {port}: {last_error}")


def recv_json_line(sock_file) -> dict:
    line = sock_file.readline()
    if not line:
        raise RuntimeError("unexpected EOF from QMP")
    return json.loads(line.decode("utf-8"))


def qmp_execute(sock, sock_file, command: str) -> dict:
    payload = json.dumps({"execute": command}, separators=(",", ":")).encode("utf-8") + b"\r\n"
    sock.sendall(payload)
    return recv_json_line(sock_file)


def require_return(reply: dict, command: str):
    if "return" not in reply:
        raise RuntimeError(f"{command} did not return success: {reply}")
    return reply["return"]


def kill_and_wait(proc: subprocess.Popen):
    if proc.poll() is None:
        proc.kill()
        proc.wait(timeout=5)


def run_query_quit(args, log):
    port = reserve_port()
    cmd = [
        args.nemu,
        f"--qmp={port}",
        f"--log={args.nemu_log}",
    ]

    log.write(f"query-quit-command: {' '.join(cmd)}\n")
    proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
    try:
        with connect_with_retry(port, time.monotonic() + args.timeout) as sock:
            with sock.makefile("rwb", buffering=0) as sock_file:
                greeting = recv_json_line(sock_file)
                if "QMP" not in greeting:
                    raise RuntimeError(f"missing QMP greeting: {greeting}")
                log.write(f"PASS qmp-greeting {greeting['QMP']['version']['package']}\n")

                require_return(qmp_execute(sock, sock_file, "qmp_capabilities"), "qmp_capabilities")
                log.write("PASS qmp_capabilities\n")

                status = require_return(qmp_execute(sock, sock_file, "query-status"), "query-status")
                if status.get("status") != "prelaunch" or status.get("running") is not False:
                    raise RuntimeError(f"unexpected status: {status}")
                log.write(f"PASS query-status {status['status']}\n")

                memory = require_return(
                    qmp_execute(sock, sock_file, "query-memory-size-summary"),
                    "query-memory-size-summary",
                )
                if memory.get("base-memory") != 0x40000000:
                    raise RuntimeError(f"unexpected memory summary: {memory}")
                log.write(f"PASS query-memory-size-summary {memory['base-memory']}\n")

                machines = require_return(qmp_execute(sock, sock_file, "query-machines"), "query-machines")
                if not any(item.get("name") == "riscv64-nemu" and item.get("cpu-max") == 1 for item in machines):
                    raise RuntimeError(f"unexpected machines: {machines}")
                log.write("PASS query-machines riscv64-nemu\n")

                cpus = require_return(qmp_execute(sock, sock_file, "query-cpus-fast"), "query-cpus-fast")
                if len(cpus) != 1 or cpus[0].get("cpu-index") != 0:
                    raise RuntimeError(f"unexpected cpus-fast: {cpus}")
                log.write("PASS query-cpus-fast cpu0\n")

                block = require_return(qmp_execute(sock, sock_file, "query-block"), "query-block")
                if not isinstance(block, list):
                    raise RuntimeError(f"unexpected query-block: {block}")
                log.write(f"PASS query-block entries={len(block)}\n")

                blockstats = require_return(qmp_execute(sock, sock_file, "query-blockstats"), "query-blockstats")
                if not isinstance(blockstats, list) or len(blockstats) != 0:
                    raise RuntimeError(f"unexpected detached query-blockstats: {blockstats}")
                log.write(f"PASS query-blockstats entries={len(blockstats)}\n")

                commands = require_return(qmp_execute(sock, sock_file, "query-commands"), "query-commands")
                names = {item.get("name") for item in commands}
                for expected in {
                    "qmp_capabilities",
                    "query-status",
                    "query-cpus-fast",
                    "query-blockstats",
                    "cont",
                    "stop",
                    "quit",
                }:
                    if expected not in names:
                        raise RuntimeError(f"query-commands missing {expected}: {commands}")
                log.write("PASS query-commands\n")

                require_return(qmp_execute(sock, sock_file, "quit"), "quit")
                log.write("PASS quit OK\n")

        rc = proc.wait(timeout=args.timeout)
        if rc != 0:
            raise RuntimeError(f"NEMU exited with rc={rc}")
        log.write("PASS nemu-exit rc=0\n")
    except Exception:
        kill_and_wait(proc)
        raise


def run_query_cont(args, log):
    port = reserve_port()
    cmd = [
        args.nemu,
        f"--qmp={port}",
        f"--log={args.cont_nemu_log}",
        "--monitor-cmd=info r",
    ]

    log.write(f"query-cont-command: {' '.join(cmd)}\n")
    proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
    try:
        with connect_with_retry(port, time.monotonic() + args.timeout) as sock:
            with sock.makefile("rwb", buffering=0) as sock_file:
                greeting = recv_json_line(sock_file)
                if "QMP" not in greeting:
                    raise RuntimeError(f"missing QMP greeting for cont: {greeting}")
                log.write(f"PASS cont-qmp-greeting {greeting['QMP']['version']['package']}\n")

                require_return(qmp_execute(sock, sock_file, "qmp_capabilities"), "qmp_capabilities")
                status = require_return(qmp_execute(sock, sock_file, "query-status"), "query-status")
                if status.get("status") != "prelaunch" or status.get("running") is not False:
                    raise RuntimeError(f"unexpected cont prelaunch status: {status}")
                log.write(f"PASS cont-query-status {status['status']}\n")

                commands = require_return(qmp_execute(sock, sock_file, "query-commands"), "query-commands")
                names = {item.get("name") for item in commands}
                if "cont" not in names:
                    raise RuntimeError(f"query-commands missing cont: {commands}")

                require_return(qmp_execute(sock, sock_file, "cont"), "cont")
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
    except Exception:
        kill_and_wait(proc)
        raise


def run_query_block_attached(args, log):
    if os.path.exists(args.overlay_image):
        os.unlink(args.overlay_image)

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
                greeting = recv_json_line(sock_file)
                if "QMP" not in greeting:
                    raise RuntimeError(f"missing QMP greeting for query-block: {greeting}")
                log.write(f"PASS block-qmp-greeting {greeting['QMP']['version']['package']}\n")

                block = require_return(qmp_execute(sock, sock_file, "query-block"), "query-block")
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
                if nemu.get("overlay-dirty-sectors") != 0:
                    raise RuntimeError(f"unexpected dirty sectors before guest run: {nemu}")
                if nemu.get("read-mmap") != "enabled" or nemu.get("read-mmap-bytes") != 0x80000000:
                    raise RuntimeError(f"unexpected qmp block mmap state: {nemu}")
                log.write("PASS query-block-attached virtio0\n")
                log.write(f"PASS query-block-capacity {nemu['capacity-bytes']}\n")
                log.write(f"PASS query-block-overlay {nemu['overlay']}\n")
                log.write(f"PASS query-block-read-mmap {nemu['read-mmap']}\n")

                blockstats = require_return(qmp_execute(sock, sock_file, "query-blockstats"), "query-blockstats")
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

                require_return(qmp_execute(sock, sock_file, "quit"), "quit")
                log.write("PASS block-quit OK\n")

        rc = proc.wait(timeout=args.timeout)
        if rc != 0:
            raise RuntimeError(f"NEMU query-block exited with rc={rc}")
        log.write("PASS block-nemu-exit rc=0\n")
    except Exception:
        kill_and_wait(proc)
        raise
    finally:
        if os.path.exists(args.overlay_image):
            os.unlink(args.overlay_image)


def run_query_runtime(args, log):
    if os.path.exists(args.runtime_overlay_image):
        os.unlink(args.runtime_overlay_image)

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
                greeting = recv_json_line(sock_file)
                if "QMP" not in greeting:
                    raise RuntimeError(f"missing QMP greeting for runtime: {greeting}")
                log.write(f"PASS runtime-qmp-greeting {greeting['QMP']['version']['package']}\n")

                require_return(qmp_execute(sock, sock_file, "qmp_capabilities"), "qmp_capabilities")
                status = require_return(qmp_execute(sock, sock_file, "query-status"), "query-status")
                if status.get("status") != "prelaunch" or status.get("running") is not False:
                    raise RuntimeError(f"unexpected runtime prelaunch status: {status}")
                log.write(f"PASS runtime-query-status-prelaunch {status['status']}\n")

                require_return(qmp_execute(sock, sock_file, "cont"), "cont")
                log.write("PASS runtime-cont OK\n")

                status = require_return(qmp_execute(sock, sock_file, "query-status"), "query-status")
                if status.get("status") != "running" or status.get("running") is not True:
                    raise RuntimeError(f"unexpected runtime running status: {status}")
                log.write(f"PASS runtime-query-status {status['status']}\n")

                require_return(qmp_execute(sock, sock_file, "stop"), "stop")
                log.write("PASS runtime-stop OK\n")

                deadline = time.monotonic() + args.timeout
                while True:
                    status = require_return(qmp_execute(sock, sock_file, "query-status"), "query-status")
                    if status.get("status") == "paused" and status.get("running") is False:
                        break
                    if time.monotonic() >= deadline:
                        raise RuntimeError(f"runtime did not enter paused status: {status}")
                    time.sleep(0.05)
                log.write(f"PASS runtime-query-status-paused {status['status']}\n")

                blockstats = require_return(qmp_execute(sock, sock_file, "query-blockstats"), "query-blockstats")
                if len(blockstats) != 1 or blockstats[0].get("device") != "virtio0":
                    raise RuntimeError(f"unexpected runtime blockstats: {blockstats}")
                if not isinstance(blockstats[0].get("stats"), dict):
                    raise RuntimeError(f"runtime blockstats missing stats object: {blockstats}")
                if not isinstance(blockstats[0].get("nemu"), dict):
                    raise RuntimeError(f"runtime blockstats missing nemu object: {blockstats}")
                log.write("PASS runtime-query-blockstats virtio0\n")

                require_return(qmp_execute(sock, sock_file, "cont"), "cont")
                log.write("PASS runtime-cont-after-stop OK\n")

                deadline = time.monotonic() + args.timeout
                while True:
                    status = require_return(qmp_execute(sock, sock_file, "query-status"), "query-status")
                    if status.get("status") == "running" and status.get("running") is True:
                        break
                    if time.monotonic() >= deadline:
                        raise RuntimeError(f"runtime did not resume running status: {status}")
                    time.sleep(0.05)
                log.write(f"PASS runtime-query-status-resumed {status['status']}\n")

                require_return(qmp_execute(sock, sock_file, "quit"), "quit")
                log.write("PASS runtime-quit OK\n")

        rc = proc.wait(timeout=args.timeout)
        if rc != 0:
            raise RuntimeError(f"NEMU runtime QMP exited with rc={rc}")
        log.write("PASS runtime-nemu-exit rc=0\n")
    except Exception:
        kill_and_wait(proc)
        raise
    finally:
        if os.path.exists(args.runtime_overlay_image):
            os.unlink(args.runtime_overlay_image)


def main() -> int:
    parser = argparse.ArgumentParser(description="Smoke-test NEMU's minimal QMP startup socket")
    parser.add_argument("--nemu", required=True)
    parser.add_argument("--log", required=True)
    parser.add_argument("--nemu-log", required=True)
    parser.add_argument("--cont-nemu-log", required=True)
    parser.add_argument("--block-nemu-log", required=True)
    parser.add_argument("--runtime-nemu-log", required=True)
    parser.add_argument("--block-image", required=True)
    parser.add_argument("--overlay-image", required=True)
    parser.add_argument("--runtime-overlay-image", required=True)
    parser.add_argument("--firmware", required=True)
    parser.add_argument("--kernel", required=True)
    parser.add_argument("--dtb", required=True)
    parser.add_argument("--next-addr", default="0x80200000")
    parser.add_argument("--dtb-addr", default="0x82200000")
    parser.add_argument("--runtime-max-insts", type=int, default=1000000000)
    parser.add_argument("--timeout", type=float, default=10.0)
    args = parser.parse_args()

    os.makedirs(os.path.dirname(args.log), exist_ok=True)
    with open(args.log, "w", encoding="utf-8") as log:
        run_query_quit(args, log)
        run_query_cont(args, log)
        run_query_block_attached(args, log)
        run_query_runtime(args, log)
        log.write("__NEMU_QMP_SMOKE__:ok\n")

    return 0


if __name__ == "__main__":
    sys.exit(main())
