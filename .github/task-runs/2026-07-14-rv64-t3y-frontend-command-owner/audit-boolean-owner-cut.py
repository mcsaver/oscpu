#!/usr/bin/env python3

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
FRONTEND = ROOT / "npc/rv64/vsrc/frontend/OooFrontend.v"
ARBITER = ROOT / "npc/rv64/vsrc/control/OooPendingDispatchArbiter.v"
CONTROL = ROOT / "npc/rv64/vsrc/control/OooControlPlane.v"


def statement(text: str, anchor: str) -> str:
    start = text.index(anchor)
    end = text.index(";", start) + 1
    return text[start:end]


def audit(frontend: str, arbiter: str, control: str) -> list[str]:
    errors: list[str] = []
    e5 = statement(frontend, "wire commit_e5_valid_w")
    e6 = statement(frontend, "wire commit_e6_base_w")
    capture = statement(arbiter, "wire capture_base_w")

    if "direct_frontend_flush_w" in e5:
        errors.append("E5 still depends on the late direct mask")
    if "direct_frontend_flush_w" in e6:
        errors.append("E6 still depends on the late direct mask")
    if "direct_frontend_flush_i" in capture:
        errors.append("capture_base still depends on the late direct mask")

    required_frontend = [
        "[T3Y-DIRECT-COMMIT-DISJOINT]",
        "commit_e5_valid_w || commit_e6_valid_w",
    ]
    required_control = [
        "[T3Y-DIRECT-CAPTURE-DISJOINT]",
        "pending_system_capture_irq_w",
        "pending_system_capture_head0_w",
        "pending_system_capture_lane1_w",
        "pending_trap_exit_capture_exit_w",
        "pending_trap_exit_capture_arch_w",
    ]
    for token in required_frontend:
        if token not in frontend:
            errors.append(f"missing frontend guard token: {token}")
    for token in required_control:
        if token not in control:
            errors.append(f"missing control guard token: {token}")

    # Only the redundant set/capture mask moves.  These true direct consumers
    # must remain present so a timing cut cannot silently become a squash cut.
    true_consumers = [
        "assign pending_system_clear_o",
        "assign pending_trap_exit_clear_arch_o",
        "assign pending_trap_exit_clear_arch_squash_o",
    ]
    for anchor in true_consumers:
        body = statement(arbiter, anchor)
        if "direct_frontend_flush_i" not in body:
            errors.append(f"true direct consumer lost: {anchor}")

    return errors


def main() -> int:
    frontend = FRONTEND.read_text(encoding="utf-8")
    arbiter = ARBITER.read_text(encoding="utf-8")
    control = CONTROL.read_text(encoding="utf-8")
    errors = audit(frontend, arbiter, control)

    mutations = {
        "restore_e5_late_mask": (
            frontend.replace(
                "wire commit_e5_valid_w =\n      pending_system_csr_commit_w",
                "wire commit_e5_valid_w = !direct_frontend_flush_w &&\n      pending_system_csr_commit_w",
                1,
            ),
            arbiter,
            control,
        ),
        "restore_capture_late_mask": (
            frontend,
            arbiter.replace(
                "!csr_trap_mem_valid_i && can_run_i",
                "!csr_trap_mem_valid_i && !direct_frontend_flush_i && can_run_i",
                1,
            ),
            control,
        ),
        "delete_commit_guard": (
            frontend.replace("[T3Y-DIRECT-COMMIT-DISJOINT]", "[MUTATED]", 1),
            arbiter,
            control,
        ),
        "delete_capture_guard": (
            frontend,
            arbiter,
            control.replace("[T3Y-DIRECT-CAPTURE-DISJOINT]", "[MUTATED]", 1),
        ),
    }
    mutation_results = {}
    for name, sources in mutations.items():
        mutation_errors = audit(*sources)
        mutation_results[name] = {
            "rejected": bool(mutation_errors),
            "errors": mutation_errors,
        }
        if not mutation_errors:
            errors.append(f"negative mutation escaped audit: {name}")

    result = {
        "status": "PASS" if not errors else "FAIL",
        "production_errors": errors,
        "negative_mutations": mutation_results,
        "files": [str(FRONTEND), str(ARBITER), str(CONTROL)],
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
