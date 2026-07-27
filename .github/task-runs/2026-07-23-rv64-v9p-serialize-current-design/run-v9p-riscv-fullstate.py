#!/usr/bin/env python3
"""Run flag-ON RV64 riscv-tests with NPC/NEMU full architectural-state comparison."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re
import subprocess
import sys
from typing import Any


ROOT = pathlib.Path(__file__).resolve().parents[3]
TASK = ROOT / ".github/task-runs/2026-07-23-rv64-v9p-serialize-current-design"
ISA = ROOT / "npc/rv64/testsuites/core-tests/src/riscv-tests/isa"
SIMULATOR = ROOT / "npc/rv64/build-csrqh/NpcSimTop"
REFERENCE = ROOT / "nemu/build/riscv64-nemu-interpreter-so"
EXPECTED_DESIGN_SHA = (
    "9ac1ae14b18635cf25ea80efa7ce4cd85a07bdd6f0e525755658dc8dcd26207a"
)
RISCV_PREFIX = "riscv64-linux-gnu-"
GCC_OPTS = (
    "-static -mcmodel=medany -fvisibility=hidden -fno-pie -no-pie "
    "-nostdlib -nostartfiles "
    "-Wl,--build-id=none"
)
SUITES = (
    "rv64ui",
    "rv64um",
    "rv64ua",
    "rv64uc",
    "rv64uf",
    "rv64ud",
    "rv64uzba",
    "rv64uzbb",
    "rv64uzbc",
    "rv64uzbs",
    "rv64mi",
    "rv64si",
)
SMOKE_TARGETS = (
    "rv64mi-p-csr",
    "rv64si-p-csr",
    "rv64si-p-dirty",
    "rv64ui-v-fence_i",
)
P_ONLY_SUITES = ("rv64mi", "rv64si")


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def current_design_sha() -> str:
    sys.path.insert(0, str(ROOT / "npc/rv64/eval/ppa/tools"))
    import architecture_hard_gates as arch

    return arch.rtl_binding(ROOT)[0]


def write_json(path: pathlib.Path, value: Any) -> None:
    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def run_logged(
    args: list[str], log_path: pathlib.Path, *, cwd: pathlib.Path = ROOT
) -> subprocess.CompletedProcess[str]:
    log_path.parent.mkdir(parents=True, exist_ok=True)
    with log_path.open("w", encoding="utf-8") as handle:
        handle.write("command=" + " ".join(args).replace(str(ROOT), "<REPO>") + "\n")
        handle.flush()
        completed = subprocess.run(
            args,
            cwd=cwd,
            stdout=handle,
            stderr=subprocess.STDOUT,
            check=False,
            text=True,
        )
        handle.write(f"return_code={completed.returncode}\n")
    return completed


def build_targets(scope: str, result_dir: pathlib.Path) -> list[str]:
    common = [
        "make",
        "-C",
        str(ISA),
        "XLEN=64",
        f"RISCV_PREFIX={RISCV_PREFIX}",
        f"RISCV_GCC_OPTS={GCC_OPTS}",
    ]
    if scope == "smoke":
        targets = list(SMOKE_TARGETS)
        completed = run_logged(
            common + [f"{target}.dump" for target in targets],
            result_dir / "build.log",
        )
        if completed.returncode != 0:
            raise RuntimeError("smoke target build failed")
        return targets

    clean = run_logged(common + ["clean"], result_dir / "clean.log")
    if clean.returncode != 0:
        raise RuntimeError("riscv-tests clean failed")
    completed = run_logged(
        common + ["-j2", *SUITES],
        result_dir / "build.log",
    )
    if completed.returncode != 0:
        raise RuntimeError("full p/v target build failed")

    targets: list[str] = []
    for suite in SUITES:
        source_names = sorted(path.stem for path in (ISA / suite).glob("*.S"))
        for source_name in source_names:
            targets.append(f"{suite}-p-{source_name}")
            if suite not in P_ONLY_SUITES:
                targets.append(f"{suite}-v-{source_name}")
    if len(targets) != 330 or len(set(targets)) != 330:
        raise RuntimeError(
            f"full p/v inventory requires 330 unique targets, got {len(targets)}"
        )
    return targets


def tohost_addr(elf: pathlib.Path) -> str:
    completed = subprocess.run(
        [f"{RISCV_PREFIX}nm", str(elf)],
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
        text=True,
    )
    if completed.returncode != 0:
        raise RuntimeError(f"nm failed for {elf.name}: {completed.stderr.strip()}")
    matches = re.findall(r"(?m)^([0-9A-Fa-f]+)\s+\S\s+tohost$", completed.stdout)
    if not matches:
        raise RuntimeError(f"missing tohost symbol: {elf.name}")
    return f"0x{matches[-1]}"


def run_target(target: str, result_dir: pathlib.Path) -> dict[str, Any]:
    elf = ISA / target
    if not elf.is_file():
        raise RuntimeError(f"built ELF is missing: {target}")
    image = result_dir / "images" / f"{target}.bin"
    image.parent.mkdir(parents=True, exist_ok=True)
    objcopy = subprocess.run(
        [f"{RISCV_PREFIX}objcopy", "-O", "binary", str(elf), str(image)],
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
        text=True,
    )
    if objcopy.returncode != 0:
        raise RuntimeError(f"objcopy failed for {target}: {objcopy.stderr.strip()}")

    log_path = result_dir / "logs" / f"{target}.log"
    tohost = tohost_addr(elf)
    args = [
        str(SIMULATOR),
        "-b",
        "--no-progress",
        "--max-cycles=2000000",
        f"--diff={REFERENCE}",
        f"--tohost={tohost}",
        str(image),
    ]
    completed = run_logged(args, log_path)
    text = log_path.read_text(encoding="utf-8", errors="replace")
    terminal_pass = "TOHOST PASS" in text or "HIT GOOD TRAP" in text
    diff_mismatch = re.search(r"(?i)\[npc-diff\].*mismatch", text) is not None
    passed = completed.returncode == 0 and terminal_pass and not diff_mismatch
    return {
        "target": target,
        "variant": target.split("-")[1],
        "return_code": completed.returncode,
        "terminal_pass": terminal_pass,
        "difftest_mismatch": diff_mismatch,
        "passed": passed,
        "tohost": tohost,
        "elf_sha256": sha256_file(elf),
        "image_sha256": sha256_file(image),
        "log": log_path.relative_to(ROOT).as_posix(),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scope", choices=("smoke", "full"), required=True)
    args = parser.parse_args()
    result_dir = TASK / f"riscv-fullstate-{args.scope}"
    result_dir.mkdir(parents=True, exist_ok=True)
    status_path = TASK / f"riscv-fullstate-{args.scope}.status"
    status_path.write_text("RUNNING\n", encoding="utf-8")
    try:
        design_sha_pre = current_design_sha()
        if design_sha_pre != EXPECTED_DESIGN_SHA:
            raise RuntimeError(
                f"RTL design-id mismatch: {design_sha_pre} != {EXPECTED_DESIGN_SHA}"
            )
        if not SIMULATOR.is_file() or not REFERENCE.is_file():
            raise RuntimeError("flag-ON simulator or NEMU reference is missing")
        simulator_sha = sha256_file(SIMULATOR)
        reference_sha = sha256_file(REFERENCE)
        targets = build_targets(args.scope, result_dir)
        records: list[dict[str, Any]] = []
        for index, target in enumerate(targets, start=1):
            print(
                f"[V9P-RISCV-FULLSTATE] {index}/{len(targets)} {target}",
                flush=True,
            )
            record = run_target(target, result_dir)
            records.append(record)
            if not record["passed"]:
                break

        design_sha_post = current_design_sha()
        binding_stable = (
            design_sha_post == design_sha_pre
            and sha256_file(SIMULATOR) == simulator_sha
            and sha256_file(REFERENCE) == reference_sha
        )
        passed = len(records) == len(targets) and all(
            record["passed"] for record in records
        )
        summary = {
            "schema": "ysyx.rv64.serialize-fullstate.v1",
            "scope": args.scope,
            "rtl_design_id": f"sha256:{design_sha_pre}",
            "configuration": "OOO_CSR_QUEUE_HEAD=1",
            "simulator": SIMULATOR.relative_to(ROOT).as_posix(),
            "simulator_sha256": simulator_sha,
            "reference": REFERENCE.relative_to(ROOT).as_posix(),
            "reference_sha256": reference_sha,
            "required": len(targets),
            "attempted": len(records),
            "passed": sum(bool(record["passed"]) for record in records),
            "failed": sum(not bool(record["passed"]) for record in records),
            "variants": {
                "p": sum(record["variant"] == "p" for record in records),
                "v": sum(record["variant"] == "v" for record in records),
            },
            "binding_stable": binding_stable,
            "result": "PASS" if passed and binding_stable else "FAIL",
            "records": records,
        }
        write_json(result_dir / "summary.json", summary)
        status_path.write_text(
            ("PASS" if summary["result"] == "PASS" else "FAIL") + "\n",
            encoding="utf-8",
        )
        print(
            "[V9P-RISCV-FULLSTATE] "
            f"scope={args.scope} passed={summary['passed']}/{summary['required']} "
            f"binding_stable={binding_stable} result={summary['result']}",
            flush=True,
        )
        return 0 if summary["result"] == "PASS" else 1
    except (OSError, RuntimeError, ValueError) as exc:
        status_path.write_text(f"FAIL {exc}\n", encoding="utf-8")
        print(f"[V9P-RISCV-FULLSTATE][FAIL] {exc}", file=sys.stderr, flush=True)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
