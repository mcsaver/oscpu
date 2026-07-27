#!/usr/bin/env python3
"""Build a deterministic SHA-256 manifest for the V10A evidence bundle."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
RUN_ROOT = Path(__file__).resolve().parent
OUTPUT = RUN_ROOT / "evidence" / "artifact-manifest.json"
DESIGN_ID = "sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951"

EXTERNAL_PATHS = (
    ".github/instructions/agent-e2e-workflow.instructions.md",
    ".github/memory/project-status.md",
    ".github/memory/modules/npc.md",
    "npc/rv64/Makefile",
    "npc/rv64/design/arch/ROADMAP.md",
    "npc/rv64/design/specs/ooo-csr-trap-request-mux.md",
    "npc/rv64/design/specs/ooo-serialize-memory-owner-terminal.md",
    "npc/rv64/eval/ppa/evidence/functional-aggregate-current.json",
    "npc/rv64/eval/ppa/evidence/functional-aggregate-result.json",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/tests/tb_ooo_serialized_owner_exactly_once.sv",
    "npc/rv64/vsrc/control/OooControlPlane.v",
    "npc/rv64/vsrc/control/OooCsrTrapRequestMux.v",
    "npc/rv64/vsrc/frontend/OooFrontendRunGate.v",
    "npc/rv64/vsrc/control/OooPendingDispatchArbiter.v",
    "npc/rv64/vsrc/control/OooPendingDrainResolveGate.v",
    "npc/rv64/vsrc/control/OooPendingLane1CaptureGate.v",
    "npc/rv64/vsrc/control/OooPendingSystemSequencer.v",
    "npc/rv64/vsrc/control/OooPendingTrapExitSequencer.v",
    "npc/rv64/vsrc/control/OooStopPendingSequencer.v",
    "npc/rv64/vsrc/core/CsrFile.v",
)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while chunk := handle.read(1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest()


def task_run_files() -> list[Path]:
    result: list[Path] = []
    for path in RUN_ROOT.rglob("*"):
        if not path.is_file():
            continue
        relative = path.relative_to(RUN_ROOT)
        if relative.parts[0] == "evidence" or relative.name == "evidence-index.md":
            continue
        if "__pycache__" in relative.parts or relative.suffix == ".pyc":
            continue
        result.append(path)
    return result


def build_payload() -> dict[str, object]:
    paths = task_run_files()
    paths.extend(REPO_ROOT / path for path in EXTERNAL_PATHS)
    unique_paths = sorted(
        set(paths), key=lambda path: path.relative_to(REPO_ROOT).as_posix()
    )

    files: list[dict[str, object]] = []
    for path in unique_paths:
        if path.is_symlink():
            raise RuntimeError(f"symlink is not accepted in V10A evidence: {path}")
        if not path.is_file():
            raise FileNotFoundError(path)
        relative = path.relative_to(REPO_ROOT).as_posix()
        files.append(
            {
                "path": relative,
                "size_bytes": path.stat().st_size,
                "sha256": sha256_file(path),
            }
        )

    return {
        "schema": "npc-rv64-v10a-artifact-manifest-v1",
        "design_id": DESIGN_ID,
        "scope": "pending-architectural-trap-clocked-owner-exactly-once",
        "file_count": len(files),
        "total_size_bytes": sum(int(item["size_bytes"]) for item in files),
        "files": files,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check",
        action="store_true",
        help="compare live files with the existing manifest without writing",
    )
    args = parser.parse_args()
    payload = build_payload()
    serialized = json.dumps(payload, indent=2, sort_keys=True) + "\n"

    if args.check:
        if not OUTPUT.is_file() or OUTPUT.read_text(encoding="utf-8") != serialized:
            print(f"FAIL stale V10A artifact manifest path={OUTPUT.relative_to(REPO_ROOT)}")
            return 1
        print(
            "PASS V10A artifact manifest check "
            f"files={payload['file_count']} bytes={payload['total_size_bytes']}"
        )
        return 0

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    temporary = OUTPUT.with_suffix(".json.tmp")
    temporary.write_text(serialized, encoding="utf-8")
    temporary.replace(OUTPUT)
    print(
        "PASS V10A artifact manifest "
        f"files={payload['file_count']} bytes={payload['total_size_bytes']} "
        f"path={OUTPUT.relative_to(REPO_ROOT).as_posix()}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
