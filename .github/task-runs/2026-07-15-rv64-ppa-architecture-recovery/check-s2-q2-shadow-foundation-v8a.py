#!/usr/bin/env python3
"""Fail-closed structural checker for the behavior-neutral S2-Q2 v8a shadow.

v8a deliberately does not implement the live epoch barrier.  It freezes only a
reversible ABI/precommit/permit/classifier foundation and records the P0 items
that must be solved before any active v8b integration claim.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import importlib.util
import json
import re
import sys
from pathlib import Path
from typing import Any


RUN_DIR = Path(__file__).resolve().parent
REPO_ROOT = RUN_DIR.parents[2]
DEFAULT_MANIFEST = RUN_DIR / "s2-q2-shadow-foundation-interface-v8a.json"
V7_CHECKER = RUN_DIR / "check-s2-q2-live-epoch-readiness.py"
EXPECTED_CONTRACT_LOCK_SHA256 = "92c38c83fbd6cefd51921bc139b65acc965fb2e054c2f554086159c39bd160a3"
EXPECTED_EVIDENCE_BASELINE_SHA256 = "1dc0a5b68d8bfd9cc8e312cabe911236ee2ee2b3ec0b3f215ce132e6fbed98e9"
ACTIVE_VARIANTS = {
    "release": (),
    "ooo_assert": ("OOO_ASSERT",),
}

EXPECTED_SCOPE = {
    "memory_lanes": 1,
    "issue1_memory_enabled": False,
    "behavior_neutral_shadow_only": True,
    "active_context_permit": False,
    "active_fencei_permit": False,
    "q1_owner_instantiated": False,
    "full_identity_safety_claimed": False,
    "full_context_payload_in_scope": False,
    "fencei_transaction_in_scope": False,
    "selective_squash_in_scope": False,
    "dynamic_epoch_in_scope": False,
    "structural_pass_is_sufficient": False,
    "allowed_claim": "v8a shadow interface/checker readiness only",
}

EXPECTED_BLOCKER_IDS = [
    "P0-IFU-ACK-DIRECTION",
    "P0-HEAD-PRESENT-AND-FLUSH",
    "P0-FULL-IDENTITY-PROVENANCE-AND-REUSE",
    "P0-SAME-OWNER-TYPED-CONTEXT-PAYLOAD",
    "P0-FENCEI-OWNER-DOMAIN",
    "P0-FENCEI-GENERATION-AND-CAPTURE-BLOCK",
    "P0-Q1-ABORT-PRIORITY",
    "P1-CHECKER-SUPPORT-MODULE-DIRECTIONS",
]

EXPECTED_SELF_TEST_INVENTORY = [
    "exact-instance-accepted",
    "wrong-instance-map-killed",
    "missing-context-permit-killed",
    "missing-fencei-permit-killed",
    "precommit-commit-ready-bypass-killed",
    "identity-valid-done-alias-killed",
    "tie-high-shadow-accepted",
    "active-shadow-permit-killed",
    "lane1-csr-self-inequality-killed",
    "missing-sfence-class-killed",
    "commit1-shadow-gate-killed",
    "truncated-identity-width-killed",
    "child-output-host-override-killed",
    "q1-live-instance-killed",
    "deferred-blocker-drift-killed",
    "v7-provenance-drift-killed",
    "contract-lock-drift-killed",
]

EXPECTED_V7_PROVENANCE = {
    "schema": "s2-q2-live-epoch-interface-v7",
    "contract_lock_sha256": "d830e31698425f431ad92fc907e2748b151399539e9736a0abfc0ee7d9d2d5fa",
    "evidence_baseline_sha256": "abfe4e248f27e50d4f6cafc69f7429dba37e36544b3a5d6ec01248993ed1dc88",
    "contract_file_sha256": "579b7c50af2a17332c3cd4b923e7c9c259439da40be704c5f626947def249ee5",
    "manifest_file_sha256": "514ccfe4bf6e1c0fef3ecfbd93127495561a447044514d95d502172063719c40",
    "checker_file_sha256": "f14a9e3a8a8c0ca79f1f6b3955d00678eb39ad5903da7c63e81b47e6817f82e8",
    "runner_file_sha256": "8f4804333d678d9431c86c889feb7979f3c36d3da88e8840cbd48e6234cea0f4",
    "source_inventory_file_sha256": "c273e3322b2a61366773a1b849a0991cf110b01a46b6158d32895b59adb1e97e",
    "release_red_count": 931,
    "ooo_assert_red_count": 931,
    "aggregate_red_count": 1862,
    "aggregate_red_sha256": "fc5baa96190e9bcac70248f912523f8ae9192045885d6023b6cb940f4675a592",
}

V7_FILE_HASHES = {
    "contract_file_sha256":
        RUN_DIR / "s2-q2-live-epoch-atomic-slice-contract.md",
    "manifest_file_sha256":
        RUN_DIR / "s2-q2-live-epoch-interface.json",
    "checker_file_sha256":
        RUN_DIR / "check-s2-q2-live-epoch-readiness.py",
    "runner_file_sha256":
        RUN_DIR / "run-s2-q2-live-epoch-readiness.sh",
    "source_inventory_file_sha256":
        RUN_DIR / "evidence/r4-s2-q2-live-epoch-readiness-red/sources.sha256",
}


def load_v7_checker() -> Any:
    spec = importlib.util.spec_from_file_location("q2_v7_checker", V7_CHECKER)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import parser helpers from {V7_CHECKER}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


V7 = load_v7_checker()


def canonical_sha256(value: Any) -> str:
    encoded = json.dumps(
        value, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def contract_lock_sha256(manifest: dict[str, Any]) -> str:
    projection = {
        key: value for key, value in manifest.items()
        if key not in {"contract_lock_sha256", "evidence_baseline"}
    }
    return canonical_sha256(projection)


def evidence_baseline_sha256(manifest: dict[str, Any]) -> str:
    return canonical_sha256(manifest.get("evidence_baseline", {}))


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def v7_provenance_errors(
    manifest: dict[str, Any], *, check_files: bool = True
) -> list[str]:
    errors: list[str] = []
    actual = manifest.get("v7_provenance")
    if actual != EXPECTED_V7_PROVENANCE:
        errors.append("v7 provenance map differs from frozen reviewed values")
        return errors
    if not check_files:
        return errors
    for key, path in V7_FILE_HASHES.items():
        if not path.is_file():
            errors.append(f"missing frozen v7 provenance file: {path.name}")
        elif file_sha256(path) != EXPECTED_V7_PROVENANCE[key]:
            errors.append(f"frozen v7 provenance drift: {path.name}")
    return errors


def validate_contract(
    manifest: dict[str, Any], *, check_files: bool = True,
    enforce_digests: bool = True,
) -> list[str]:
    errors: list[str] = []
    if manifest.get("schema") != "s2-q2-shadow-foundation-interface-v8a":
        errors.append("unexpected v8a interface schema")
    if enforce_digests:
        actual_lock = contract_lock_sha256(manifest)
        if manifest.get("contract_lock_sha256") != EXPECTED_CONTRACT_LOCK_SHA256 \
                or actual_lock != EXPECTED_CONTRACT_LOCK_SHA256:
            errors.append("v8a contract-lock digest differs from frozen checker digest")
        if evidence_baseline_sha256(manifest) != EXPECTED_EVIDENCE_BASELINE_SHA256:
            errors.append("v8a evidence baseline differs from reviewed digest")
    if manifest.get("scope") != EXPECTED_SCOPE:
        errors.append("v8a scope weakened or expanded beyond neutral shadow")
    blockers = manifest.get("deferred_p0_blockers", [])
    if [item.get("id") for item in blockers] != EXPECTED_BLOCKER_IDS:
        errors.append("deferred P0/P1 blocker inventory or order drifted")
    if any(not item.get("exit") or not item.get("disposition") for item in blockers):
        errors.append("a deferred blocker lacks disposition or explicit exit criterion")
    if manifest.get("self_test_inventory") != EXPECTED_SELF_TEST_INVENTORY:
        errors.append("checker self-test inventory/order differs from frozen list")
    baseline = manifest.get("evidence_baseline", {})
    if baseline.get("expected_self_test_mutations") != len(EXPECTED_SELF_TEST_INVENTORY):
        errors.append("self-test mutation baseline does not match frozen inventory")
    errors.extend(v7_provenance_errors(manifest, check_files=check_files))
    return errors


def manifest_critical_symbols(manifest: dict[str, Any]) -> set[tuple[str, str]]:
    symbols: set[tuple[str, str]] = set()
    for item in manifest.get("required_ports", []):
        symbols.add((item["module"], item["port"]))
    wrapper = manifest["wrapper_bundle"]
    for module in wrapper["modules"]:
        for port in wrapper["inputs"] + wrapper["outputs"]:
            symbols.add((module, port))
    for item in manifest.get("required_signal_widths", []):
        symbols.add((item["module"], item["signal"]))
    for item in manifest.get("boolean_requirements", []):
        symbols.add((item["module"], item["target"]))
        for source in item.get("sources", []):
            symbols.add((item["module"], source))
    for collection in ("signal_dependencies", "forbidden_dependencies"):
        for item in manifest.get(collection, []):
            symbols.add((item["module"], item["target"]))
            for source in item.get("sources", []):
                symbols.add((item["module"], source))
    for item in manifest.get("instance_connections", []):
        for signal in item.get("ports", {}).values():
            symbols.add((item["host"], signal))
        for signal in item.get("same_name_ports", []):
            symbols.add((item["host"], signal))
    return symbols


def load_active_modules(
    repo_root: Path, manifest: dict[str, Any], variant: str
) -> tuple[dict[str, str], list[str]]:
    module_code: dict[str, str] = {}
    errors: list[str] = []
    for module, relative in manifest["module_files"].items():
        path = repo_root / relative
        if not path.is_file():
            errors.append(f"missing source for {module}: {relative}")
            module_code[module] = ""
            continue
        preprocessed, detail = V7.preprocess_verilog_path(
            path, repo_root, defines=ACTIVE_VARIANTS[variant]
        )
        if preprocessed is None:
            errors.append(f"{module} active-source preprocessing failed: {detail}")
            module_code[module] = ""
            continue
        body = V7.module_body(V7.code_only(preprocessed), module)
        if body is None:
            errors.append(f"source does not define expected module {module}: {relative}")
            module_code[module] = ""
        else:
            module_code[module] = body
    return module_code, errors


def run_variant(
    repo_root: Path, manifest: dict[str, Any], variant: str
) -> list[str]:
    module_code, errors = load_active_modules(repo_root, manifest, variant)
    macro_path = repo_root / "npc/rv64/vsrc/include/define.v"
    if not macro_path.is_file():
        macro_definitions: dict[str, str] = {}
        errors.append("missing macro source npc/rv64/vsrc/include/define.v")
    else:
        macro_definitions = V7.object_macro_definitions(
            macro_path.read_text(encoding="utf-8")
        )
        for item in manifest["required_macro_definitions"]:
            actual = macro_definitions.get(item["name"])
            if actual != item["exact"]:
                errors.append(
                    f"macro {item['name']} expected {item['exact']}, got "
                    f"{actual if actual is not None else 'missing'}"
                )

    for module, signal in sorted(manifest_critical_symbols(manifest)):
        declaration_errors = V7.module_symbol_declaration_errors(
            module_code.get(module, ""), signal
        )
        if declaration_errors:
            errors.append(
                f"{module}.{signal} declaration scope invalid: "
                + "; ".join(declaration_errors)
            )

    for item in manifest["required_ports"]:
        if not V7.declared_port(
            module_code.get(item["module"], ""), item["direction"], item["port"]
        ):
            errors.append(
                f"{item['module']} lacks {item['direction']} port {item['port']}"
            )

    wrapper = manifest["wrapper_bundle"]
    for module in wrapper["modules"]:
        body = module_code.get(module, "")
        for port in wrapper["inputs"]:
            if not V7.declared_port(body, "input", port):
                errors.append(f"{module} lacks wrapper input port {port}")
        for port in wrapper["outputs"]:
            if not V7.declared_port(body, "output", port):
                errors.append(f"{module} lacks wrapper output port {port}")

    width = V7.expand_object_macros(
        manifest["wrapper_width_bundle"]["width_token"], macro_definitions
    )
    width_port = manifest["wrapper_width_bundle"]["port"]
    for module in wrapper["modules"] + ["OooRob"]:
        if not V7.declared_port_width(module_code.get(module, ""), width_port, width):
            errors.append(
                f"{module}.{width_port} lacks width token "
                f"{manifest['wrapper_width_bundle']['width_token']}"
            )
    for item in manifest["required_signal_widths"]:
        expanded_width = V7.expand_object_macros(
            item["width_token"], macro_definitions
        )
        if not V7.declared_signal_width(
            module_code.get(item["module"], ""), item["signal"], expanded_width
        ):
            errors.append(
                f"{item['module']}.{item['signal']} lacks width token "
                f"{item['width_token']}"
            )

    for item in manifest["instance_connections"]:
        expected = dict(item.get("ports", {}))
        for port in item.get("same_name_ports", []):
            expected[port] = port
        ok, detail = V7.exact_instance_connection(
            module_code.get(item["host"], ""), item["child"], expected,
            item.get("instance"),
        )
        if not ok:
            errors.append(f"{item['host']}->{item['child']}: {detail}")

    for item in manifest["exclusive_instance_outputs"]:
        producer_errors = V7.exclusive_instance_output_errors(
            module_code.get(item["host"], ""), item
        )
        if producer_errors:
            errors.append(
                f"{item['host']}.{item['signal']} producer is not exclusive: "
                + "; ".join(producer_errors)
            )

    graphs = {
        module: V7.assignment_graph(body, include_sequential=False)
        for module, body in module_code.items()
    }
    for requirement in manifest["boolean_requirements"]:
        body = module_code.get(requirement["module"], "")
        expanded = V7.expanded_requirement(requirement, macro_definitions)
        driver_errors = V7.exact_combinational_driver_errors(
            body, requirement["target"], module_code
        )
        shape_errors = V7.boolean_requirement_errors(body, expanded)
        if driver_errors or shape_errors:
            errors.append(
                f"{requirement['module']}.{requirement['target']} shadow equation "
                "invalid: " + "; ".join(driver_errors + shape_errors)
            )
    for item in manifest["signal_dependencies"]:
        graph = graphs.get(item["module"], {})
        missing = [
            source for source in item["sources"]
            if not V7.depends_on(graph, item["target"], source)
        ]
        if missing:
            errors.append(
                f"{item['module']}.{item['target']} missing required dependencies: "
                + ", ".join(missing)
            )
    for item in manifest["forbidden_dependencies"]:
        graph = graphs.get(item["module"], {})
        present = [
            source for source in item["sources"]
            if V7.depends_on(graph, item["target"], source)
        ]
        if present:
            errors.append(
                f"{item['module']}.{item['target']} has forbidden shadow dependencies: "
                + ", ".join(present)
            )
    for item in manifest["forbidden_live_shapes"]:
        if re.search(item["pattern"], module_code.get(item["module"], "")):
            errors.append(f"{item['module']} forbidden live shape: {item['reason']}")
    return errors


def run_self_test(manifest_path: Path) -> int:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    checks: list[tuple[str, bool]] = []

    host_good = V7.code_only("""
      module Host(input head0_context_permit_i,
                  input fencei_retire_permit_i,
                  output head0_retire_candidate_valid_o,
                  output head0_identity_valid_o,
                  output [7:0] head0_identity_o);
        Child u_child (
          .head0_context_permit_i(head0_context_permit_i),
          .fencei_retire_permit_i(fencei_retire_permit_i),
          .head0_retire_candidate_valid_o(head0_retire_candidate_valid_o),
          .head0_identity_valid_o(head0_identity_valid_o),
          .head0_identity_o(head0_identity_o)
        );
      endmodule
    """)
    body = V7.module_body(host_good, "Host") or ""
    expected_map = {
        "head0_context_permit_i": "head0_context_permit_i",
        "fencei_retire_permit_i": "fencei_retire_permit_i",
        "head0_retire_candidate_valid_o": "head0_retire_candidate_valid_o",
        "head0_identity_valid_o": "head0_identity_valid_o",
        "head0_identity_o": "head0_identity_o",
    }
    ok, _ = V7.exact_instance_connection(body, "Child", expected_map, "u_child")
    checks.append(("exact-instance-accepted", ok))
    wrong = body.replace(
        ".head0_identity_o(head0_identity_o)",
        ".head0_identity_o(head0_retire_candidate_valid_o)",
    )
    ok, _ = V7.exact_instance_connection(wrong, "Child", expected_map, "u_child")
    checks.append(("wrong-instance-map-killed", not ok))
    missing_context = body.replace(
        ".head0_context_permit_i(head0_context_permit_i),", ""
    )
    ok, _ = V7.exact_instance_connection(
        missing_context, "Child", expected_map, "u_child"
    )
    checks.append(("missing-context-permit-killed", not ok))
    missing_fencei = body.replace(
        ".fencei_retire_permit_i(fencei_retire_permit_i),", ""
    )
    ok, _ = V7.exact_instance_connection(
        missing_fencei, "Child", expected_map, "u_child"
    )
    checks.append(("missing-fencei-permit-killed", not ok))

    precommit_req = {
        "target": "candidate",
        "sources": ["recovering", "count", "valid", "head", "done"],
        "exact_expression":
            "!recovering && (count != 0) && valid[head] && done",
        "forbid_absorbing_constants": True,
        "forbid_ternary_xor": True,
    }
    precommit_good = V7.code_only(
        "assign candidate = !recovering && (count != 0) && valid[head] && done;"
    )
    precommit_bad = V7.code_only(
        "assign candidate = commit_ready && !recovering && (count != 0) && "
        "valid[head] && done;"
    )
    checks.append((
        "precommit-commit-ready-bypass-killed",
        not V7.boolean_requirement_errors(precommit_good, precommit_req)
        and bool(V7.boolean_requirement_errors(precommit_bad, precommit_req)),
    ))

    identity_valid_req = {
        "target": "identity_valid",
        "sources": ["count", "valid", "head"],
        "exact_expression": "(count != 0) && valid[head]",
        "forbid_absorbing_constants": True,
        "forbid_ternary_xor": True,
    }
    identity_valid_good = V7.code_only(
        "assign identity_valid = (count != 0) && valid[head];"
    )
    identity_valid_bad = V7.code_only(
        "assign identity_valid = (count != 0) && valid[head] && done;"
    )
    checks.append((
        "identity-valid-done-alias-killed",
        not V7.boolean_requirement_errors(identity_valid_good, identity_valid_req)
        and bool(V7.boolean_requirement_errors(identity_valid_bad, identity_valid_req)),
    ))

    tie_req = {
        "target": "permit", "sources": [], "exact_expression": "1'b1",
        "forbid_absorbing_constants": False, "forbid_ternary_xor": True,
    }
    tie_good = V7.code_only("assign permit = 1'b1;")
    tie_bad = V7.code_only("assign permit = live_grant;")
    checks.append((
        "tie-high-shadow-accepted",
        not V7.boolean_requirement_errors(tie_good, tie_req),
    ))
    checks.append((
        "active-shadow-permit-killed",
        bool(V7.boolean_requirement_errors(tie_bad, tie_req)),
    ))

    csr_req = {
        "target": "is_csr", "sources": ["inst", "head"],
        "exact_expression":
            "(inst[head][6:0] == 7'b1110011) && "
            "(inst[head][14:12] != 3'b000)",
        "forbid_absorbing_constants": True, "forbid_ternary_xor": True,
    }
    csr_good = V7.code_only(
        "assign is_csr = (inst[head][6:0] == 7'b1110011) && "
        "(inst[head][14:12] != 3'b000);"
    )
    csr_bad = V7.code_only("assign is_csr = inst[head] != inst[head];")
    checks.append((
        "lane1-csr-self-inequality-killed",
        not V7.boolean_requirement_errors(csr_good, csr_req)
        and bool(V7.boolean_requirement_errors(csr_bad, csr_req)),
    ))

    boundary_req = {
        "target": "boundary", "sources": ["csr", "sfence", "xret", "fencei"],
        "exact_expression": "csr || sfence || xret || fencei",
        "forbid_absorbing_constants": True, "forbid_ternary_xor": True,
    }
    boundary_good = V7.code_only("assign boundary = csr || sfence || xret || fencei;")
    boundary_bad = V7.code_only("assign boundary = csr || xret || fencei;")
    checks.append((
        "missing-sfence-class-killed",
        not V7.boolean_requirement_errors(boundary_good, boundary_req)
        and bool(V7.boolean_requirement_errors(boundary_bad, boundary_req)),
    ))

    neutral_graph = V7.assignment_graph(
        V7.code_only("assign commit1 = ready && valid1; assign shadow = class1;")
    )
    active_graph = V7.assignment_graph(
        V7.code_only("assign commit1 = ready && valid1 && !shadow; assign shadow = class1;")
    )
    checks.append((
        "commit1-shadow-gate-killed",
        not V7.depends_on(neutral_graph, "commit1", "shadow")
        and V7.depends_on(active_graph, "commit1", "shadow"),
    ))

    width_good = V7.code_only("module W(output [8-1:0] identity); endmodule")
    width_bad = V7.code_only("module W(output [4-1:0] identity); endmodule")
    checks.append((
        "truncated-identity-width-killed",
        V7.declared_port_width(V7.module_body(width_good, "W") or "", "identity", "8")
        and not V7.declared_port_width(
            V7.module_body(width_bad, "W") or "", "identity", "8"
        ),
    ))

    producer_req = {
        "child": "Child", "instance": "u_child",
        "port": "head0_identity_o", "signal": "head0_identity_o",
    }
    override = body + "\nassign head0_identity_o = 8'b0;\n"
    checks.append((
        "child-output-host-override-killed",
        not V7.exclusive_instance_output_errors(body, producer_req)
        and bool(V7.exclusive_instance_output_errors(override, producer_req)),
    ))

    q1_pattern = manifest["forbidden_live_shapes"][0]["pattern"]
    checks.append((
        "q1-live-instance-killed",
        re.search(q1_pattern, "OooMmuEpochOwner u_mmu_epoch_owner ();") is not None,
    ))

    blocker_drift = copy.deepcopy(manifest)
    blocker_drift["deferred_p0_blockers"] = blocker_drift["deferred_p0_blockers"][:-1]
    checks.append((
        "deferred-blocker-drift-killed",
        bool(validate_contract(
            blocker_drift, check_files=False, enforce_digests=False
        )),
    ))
    provenance_drift = copy.deepcopy(manifest)
    provenance_drift["v7_provenance"]["aggregate_red_count"] = 0
    checks.append((
        "v7-provenance-drift-killed",
        bool(v7_provenance_errors(provenance_drift, check_files=False)),
    ))
    lock_drift = copy.deepcopy(manifest)
    lock_drift["scope"]["active_context_permit"] = True
    checks.append((
        "contract-lock-drift-killed",
        contract_lock_sha256(lock_drift) != contract_lock_sha256(manifest),
    ))

    actual_inventory = [name for name, _ in checks]
    if actual_inventory != EXPECTED_SELF_TEST_INVENTORY:
        print("[S2-Q2-V8A-SELFTEST][FAIL] internal inventory order drift")
        return 1
    failed = [name for name, passed in checks if not passed]
    for name, passed in checks:
        print(f"[S2-Q2-V8A-SELFTEST][{'PASS' if passed else 'FAIL'}] {name}")
    if failed:
        print(f"[S2-Q2-V8A-SELFTEST][FAIL] mutations={len(checks)} failed={len(failed)}")
        return 1
    print(f"[S2-Q2-V8A-SELFTEST][PASS] mutations={len(checks)}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--repo-root", type=Path, default=REPO_ROOT)
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--print-locks", action="store_true")
    args = parser.parse_args()

    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    if args.print_locks:
        print(f"contract_lock_sha256={contract_lock_sha256(manifest)}")
        print(f"evidence_baseline_sha256={evidence_baseline_sha256(manifest)}")
        return 0
    if args.self_test:
        return run_self_test(args.manifest)

    contract_errors = validate_contract(manifest)
    if contract_errors:
        for error in contract_errors:
            print(f"[S2-Q2-V8A-CONTRACT][RED] {error}")
        print(f"[S2-Q2-V8A-CONTRACT][FAIL] unresolved={len(contract_errors)}")
        return 2

    all_errors: list[tuple[str, str]] = []
    for variant in ACTIVE_VARIANTS:
        for error in run_variant(args.repo_root, manifest, variant):
            all_errors.append((variant, error))
    for variant, error in all_errors:
        print(f"[S2-Q2-V8A-READINESS][RED][{variant}] {error}")
    if all_errors:
        print(f"[S2-Q2-V8A-READINESS][FAIL] unresolved={len(all_errors)}")
        return 1
    print(
        "[S2-Q2-V8A-READINESS][PASS] neutral shadow foundation is structurally "
        "ready; deferred v8b P0 blockers and RTL behavior gates remain"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
