#!/usr/bin/env python3
"""Native R64SystemTop L2/L3 execution with full instruction/state DiffTest.

The existing payloads and their phase definitions stay authoritative. This
runner uses native event evidence and does not mint legacy architecture/PPA
promotion identities or pretend to have run the old simulator.
"""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import re
import signal
import shutil
import tempfile
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[5]


def phases(layer, case):
    name = "mini_system_run" if layer == "l2" else "lightweight_linux_run"
    spec = importlib.util.spec_from_file_location(
        name, ROOT / "npc/rv64/eval/ppa/tools" / (name + ".py"))
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    if case not in module.CASE_SELECTORS:
        raise ValueError(f"unsupported {layer} case: {case}")
    if layer == "l2":
        expected = (*module.COMMON_MARKERS, module.CASE_MARKERS[case],
                    *module.CASE_BODY_MARKERS[case], *module.FINAL_MARKERS)
        known = module.ALL_KNOWN_MARKERS
    else:
        expected = module.phase_markers_for_case(case)
        known = module.ALL_KNOWN_PHASE_MARKERS
    return module.CASE_SELECTORS[case], expected, known


def check_log(text, layer, case, status):
    selector, expected, known = phases(layer, case)
    contract = sys.modules["mini_system_run" if layer == "l2" else "lightweight_linux_run"]
    critical = contract.CRITICAL_PATTERNS if layer == "l3" else ()
    if "HIT BAD TRAP" in text or contract.ASSERTION_RE.search(text) or any(
            pattern.search(text) for pattern in critical):
        raise ValueError("existing layer contract detected an RTL or guest failure")
    if status != 0:
        raise ValueError(f"simulator returned {status}")
    found = [(text.find(marker), marker) for marker in expected]
    for offset, marker in found:
        if offset < 0 or text.count(marker) != 1:
            raise ValueError(f"missing or duplicate guest phase: {marker}")
    if [offset for offset, _ in found] != sorted(offset for offset, _ in found):
        raise ValueError("guest phases out of order")
    if any(marker in text for marker in known - set(expected)):
        raise ValueError("guest executed an unrequested case")
    terminal = re.findall(
        r"\[PASS\] r64_system_poweroff commits=(\d+) cycles=(\d+) traps=(\d+) syscon_events=(\d+)", text)
    if len(terminal) != 1 or terminal[0][3] != "1":
        raise ValueError("missing or duplicate natural syscon completion")
    if text.find("[PASS] r64_system_poweroff") < found[-1][0]:
        raise ValueError("syscon completion precedes final guest phase")
    if re.search(r"\[FAIL\]|__RV64_L[23]_FAIL|Kernel panic|No working init|Assertion failed", text):
        raise ValueError("guest, DiffTest or RTL reported failure")
    expected_rx = [selector]
    if layer == "l3" and case in ("all", "interrupt"):
        expected_rx += [0x41, 0x42]
    rx = [(m.start(), int(m[1], 16)) for m in re.finditer(r"UART_RX cycle=\d+ byte=0x([0-9a-f]{2})", text)]
    if [byte for _, byte in rx] != expected_rx:
        raise ValueError("wrong UART input bytes or cardinality")
    select = f"__RV64_{layer.upper()}_CASE_SELECT__"
    selected = next(marker for marker in expected if marker.startswith(f"__RV64_{layer.upper()}_CASE_") and marker != select)
    if not text.find(select) < rx[0][0] < text.find(selected):
        raise ValueError("case selector not bracketed by guest phases")
    if len(rx) == 3:
        for index in (1, 2):
            arm = f"__RV64_L3_UART_ARM_{index}__"
            result = f"__RV64_L3_UART_RX_{index}=0x{64+index:02x}__"
            if not text.find(arm) < rx[index][0] < text.find(result):
                raise ValueError("UART IRQ transaction out of order")
    if layer == "l3":
        power_down = text.find("reboot: Power down")
        if (text.count("reboot: Power down") != 1 or
                not found[-1][0] < power_down < text.find("[PASS] r64_system_poweroff")):
            raise ValueError("Linux did not perform one ordered natural power down")
    commits, cycles, traps, _ = map(int, terminal[0])
    return dict(status="PASS", layer=layer, case=case,
                complete_layer=case == "all", commits=commits,
                cycles=cycles, traps=traps, syscon_events=1,
                phases=list(expected), uart_rx=expected_rx,
                instruction_reference="full PC/GPR/FPR/CSR",
                hardware="R64SystemTop")


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--layer", choices=("l2", "l3"), required=True)
    ap.add_argument("--case", default="all")
    ap.add_argument("--images", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--sim", type=Path, default=ROOT / "npc/rv64/build/chengyue64/system/obj/VR64SystemTestTop")
    ap.add_argument("--ref", type=Path, default=ROOT / "nemu/build/rv64-rebuild-reference/riscv64-nemu-interpreter-so")
    ap.add_argument("--max-cycles", type=int)
    ap.add_argument("--host-timeout", type=int, default=14400)
    ap.add_argument("--progress", type=int, default=1000000)
    ap.add_argument("--stalls", action="store_true")
    ap.add_argument("--check-log", type=Path,
                    help="validate an existing completed native run instead of executing")
    args = ap.parse_args()
    selector, _, _ = phases(args.layer, args.case)
    args.out.mkdir(parents=True, exist_ok=True)
    if args.check_log:
        text = args.check_log.read_text(errors="replace")
        # Completed logs must contain the runner's explicit exit record. This
        # cannot convert a killed/unfinished simulation into a successful run.
        match = re.findall(r"R64_RUN_EXIT=(-?\d+)", text)
        if len(match) != 1:
            raise ValueError("log requires exactly one explicit process exit record")
        status = int(match[0])
    else:
        image = args.images.resolve()
        payload = "mini-system.bin" if args.layer == "l2" else "Image"
        dtb = "mini-system.dtb" if args.layer == "l2" else "guest.dtb"
        loads = [(0x80400000, payload), (0x82300000, dtb)]
        if args.layer == "l3":
            loads.append((0x84000000, "initramfs.cpio"))
        for file in ("fw_jump.bin", *(name for _, name in loads)):
            if not (image / file).is_file():
                raise ValueError(f"missing system image: {image / file}")
        cycles = args.max_cycles or (100000000 if args.layer == "l2" else 1500000000)
        # A later rebuild must not truncate a shared object mapped by this run.
        model = Path(tempfile.mkdtemp(prefix="model-", dir=args.out)).resolve()
        shutil.copy2(args.sim.resolve(), model / "sim")
        shutil.copy2(args.ref.resolve(), model / "reference.so")
        cmd = [str(model / "sim"), str(image / "fw_jump.bin"), str(model / "reference.so"),
               "--system", "--memory=0x08000000", f"--maxcycles={cycles}",
               f"--progress={args.progress}"]
        cmd += [f"--load=0x{address:x}:{image / file}" for address, file in loads]
        cmd += [f"--uart-input=__RV64_{args.layer.upper()}_CASE_SELECT__:{chr(selector)}"]
        if args.layer == "l3" and args.case in ("all", "interrupt"):
            cmd += ["--uart-input=__RV64_L3_UART_ARM_1__:A",
                    "--uart-input=__RV64_L3_UART_ARM_2__:B"]
        if args.stalls:
            cmd.append("--stalls")
        (args.out / "command.json").write_text(json.dumps(cmd, indent=2) + "\n")
        log = args.out / "console.log"
        with log.open("w") as output:
            proc = subprocess.Popen(cmd, stdout=output, stderr=subprocess.STDOUT,
                                    start_new_session=True)
            try:
                status = proc.wait(timeout=args.host_timeout)
            except (subprocess.TimeoutExpired, KeyboardInterrupt):
                os.killpg(proc.pid, signal.SIGTERM)
                try:
                    proc.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(proc.pid, signal.SIGKILL)
                    proc.wait()
                status = 124
            output.write(f"\nR64_RUN_EXIT={status}\n")
        text = log.read_text(errors="replace")
    try:
        result = check_log(text, args.layer, args.case, status)
    except ValueError as error:
        result = dict(status="FAIL", layer=args.layer, case=args.case, reason=str(error))
    (args.out / "summary.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result))
    return result["status"] != "PASS"


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError) as error:
        print(f"[FAIL] {error}", file=sys.stderr)
        sys.exit(1)
