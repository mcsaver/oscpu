#!/usr/bin/env python3
"""Run current-design RTL counterexamples for architecture-delta rebinding.

The generated RTL variants and compiled simulator images live only below a
``/tmp`` directory.  The durable output contains normalized simulator logs
and one JSON receipt.  This keeps task-runs as result/log storage while the
executable wheel remains in the stable testbench tree.
"""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import importlib.util
import json
import pathlib
import subprocess
import sys
import tempfile
from typing import Any, Sequence


SCHEMA = "npc-rv64-architecture-delta-mutations-v1"
TRANSIENT_TOKEN = "<ARCHITECTURE_DELTA_TRANSIENT>"
BACKEND = "npc/rv64/vsrc/execute/OooIntBackend.v"
STORE_QUEUE = "npc/rv64/vsrc/memory/OooStoreQueue.v"
CONTROL_TOOL = "npc/rv64/eval/ppa/tools/control_event_sq_retry_evidence.py"
ARCH_TOOL = "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"


@dataclasses.dataclass(frozen=True)
class Variant:
    name: str
    debt_id: str
    source: str
    make_variable: str
    test_name: str
    old: str
    new: str
    expected_markers: tuple[str, ...]
    purpose: str
    replaces_historical_items: tuple[str, ...]
    ivflags: str = ""


LOCAL_VARIANTS = (
    Variant(
        name="sq-clear-owner-valid-on-authorized-request-fire",
        debt_id="STORE-BRESP-G1",
        source=STORE_QUEUE,
        make_variable="RTL_OOO_STORE_QUEUE",
        test_name="tb_v9n_sq_owner_residency",
        old=(
            "      if (req_fire_i && req_fire_authorized_w)\n"
            "        request_sent_q[head_q] <= 1'b1;"
        ),
        new=(
            "      if (req_fire_i && req_fire_authorized_w) begin\n"
            "        request_sent_q[head_q] <= 1'b1;\n"
            "        owner_valid_q[head_q] <= 1'b0;\n"
            "      end"
        ),
        expected_markers=(
            "[CHECK-FAIL] V9N STORE owner residency lost before exact terminal",
        ),
        purpose=(
            "Current-contract replacement for the legacy req_fire mutation: "
            "drop the exact SQ owner tuple on an authorized physical request "
            "while retaining request_sent residency."
        ),
        replaces_historical_items=(
            "STORE-BRESP-G1:RTL_MUTATION:sq_clear_owner_valid_on_request_fire",
        ),
    ),
    Variant(
        name="amo-clear-kind-on-write-fire",
        debt_id="STORE-BRESP-G1",
        source=BACKEND,
        make_variable="RTL_OOO_INT_BACKEND",
        test_name="tb_v9n_amo_owner_residency",
        old=(
            "      if (push_amo_write_w) begin\n"
            "        mem_amo_write_sent_q <= 1'b1;\n"
            "        reservation_valid_q <= 1'b0;\n"
            "        reservation_addr_q <= {`XLEN{1'b0}};\n"
            "        reservation_size_q <= 2'b00;\n"
            "      end"
        ),
        new=(
            "      if (push_amo_write_w) begin\n"
            "        mem_amo_write_sent_q <= 1'b1;\n"
            "        mem_amo_q <= 1'b0;\n"
            "        reservation_valid_q <= 1'b0;\n"
            "        reservation_addr_q <= {`XLEN{1'b0}};\n"
            "        reservation_size_q <= 2'b00;\n"
            "      end"
        ),
        expected_markers=(
            "[CHECK-FAIL] V9N AMO owner residency lost before exact terminal",
        ),
        purpose="Drop the AMO holder kind on accepted write launch.",
        replaces_historical_items=(
            "STORE-BRESP-G1:RTL_MUTATION:amo_clear_kind_on_write_fire",
        ),
    ),
    Variant(
        name="sq-launch-admission-substitution",
        debt_id="F0-G1",
        source=STORE_QUEUE,
        make_variable="RTL_OOO_STORE_QUEUE",
        test_name="tb_ooo_store_queue",
        old="            ((!rob_head_valid_i) || (!rob_head_owner_open_i) ||\n",
        new="            ((!rob_head_valid_i) || (!rob_head_launch_open_i) ||\n",
        expected_markers=("[V9L-SQ-POST-LAUNCH-OWNER]",),
        purpose=(
            "Replace resident owner authorization with first-launch admission "
            "after the physical store request."
        ),
        replaces_historical_items=(
            "F0-G1:RTL_MUTATION:sq-launch-admission-substitution",
        ),
    ),
    Variant(
        name="retry-distinct-residency-broad-assertion",
        debt_id="F0-G1",
        source=BACKEND,
        make_variable="RTL_OOO_INT_BACKEND",
        test_name="tb_ooo_int_backend",
        old=(
            "      if ((mem_retry0_valid_q &&\n"
            "           ((mem_bridge_active_load_w &&\n"
            "             (mem_owner_query_token_i == mem_retry0_owner_token_q)) ||\n"
            "            (mem_bridge_station_load_w &&\n"
            "             (mem_station_query_token_i == mem_retry0_owner_token_q)))) ||\n"
            "          (mem_retry1_valid_q &&\n"
            "           ((mem1_bridge_active_load_w &&\n"
            "             (mem1_owner_query_token_i == mem_retry1_owner_token_q)) ||\n"
            "            (mem1_bridge_station_load_w &&\n"
            "             (mem1_station_query_token_i == mem_retry1_owner_token_q))))) begin\n"
        ),
        new=(
            "      if ((mem_retry0_valid_q &&\n"
            "           (mem_bridge_active_load_w || mem_bridge_station_load_w)) ||\n"
            "          (mem_retry1_valid_q &&\n"
            "           (mem1_bridge_active_load_w || mem1_bridge_station_load_w))) begin\n"
        ),
        expected_markers=("[V9L-RETRY-OWNER-DISJOINT]",),
        purpose=(
            "Broaden retry-holder exclusion from exact owner-token equality "
            "to any resident load."
        ),
        replaces_historical_items=(
            "F0-G1:RTL_MUTATION:retry-distinct-residency-broad-assertion",
        ),
        ivflags="-DV8S_DUAL_MEMORY_FOCUSED",
    ),
)


class DeltaMutationError(RuntimeError):
    """A current RTL mutation or its testbench observation is incomplete."""


def sha_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha_file(path: pathlib.Path) -> str:
    return sha_bytes(path.read_bytes())


def load_module(path: pathlib.Path, name: str) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise DeltaMutationError(f"cannot import helper: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def repo_output(root: pathlib.Path, value: pathlib.Path) -> pathlib.Path:
    result = value if value.is_absolute() else root / value
    result = result.resolve()
    try:
        result.relative_to(root.resolve())
    except ValueError as exc:
        raise DeltaMutationError(f"output escapes repository: {result}") from exc
    return result


def control_variants(root: pathlib.Path) -> tuple[Variant, ...]:
    helper = load_module(root / CONTROL_TOOL, "architecture_delta_control_specs")
    result: list[Variant] = []
    for name, spec in helper.VARIANTS.items():
        result.append(Variant(
            name=name,
            debt_id="CONTROL-EVENT-G1",
            source=spec["production_source"],
            make_variable=(
                "RTL_OOO_MEM_AXI_BRIDGE"
                if spec["production_source"].endswith("OooMemAxiBridge.v")
                else "RTL_OOO_INT_BACKEND"
            ),
            test_name=spec["test_name"],
            old=spec["old"],
            new=spec["new"],
            expected_markers=(spec["assertion_marker"],),
            purpose="Reopen the V9R request/transfer path across a C0 barrier.",
            replaces_historical_items=(
                f"CONTROL-EVENT-G1:RTL_MUTATION:{name}",
            ),
        ))
    return tuple(result)


def variants(root: pathlib.Path) -> tuple[Variant, ...]:
    return LOCAL_VARIANTS + control_variants(root)


def reconstruct(root: pathlib.Path, variant: Variant) -> tuple[bytes, bytes]:
    source = (root / variant.source).resolve(strict=True)
    try:
        source.relative_to(root.resolve())
    except ValueError as exc:
        raise DeltaMutationError(f"source escapes repository: {variant.source}") from exc
    if source.is_symlink() or not source.is_file():
        raise DeltaMutationError(f"source is not a regular RTL file: {variant.source}")
    original = source.read_text(encoding="utf-8")
    if original.count(variant.old) != 1 or variant.old == variant.new:
        raise DeltaMutationError(
            f"{variant.name}: exact non-noop RTL anchor drifted"
        )
    mutated = original.replace(variant.old, variant.new, 1)
    if mutated == original or mutated.count(variant.new) != 1:
        raise DeltaMutationError(f"{variant.name}: mutation postcondition failed")
    return original.encode(), mutated.encode()


def normalized(text: str, transient: pathlib.Path) -> str:
    exact = str(transient.resolve())
    if TRANSIENT_TOKEN in text:
        raise DeltaMutationError("raw simulator log already contains transient token")
    if exact not in text:
        raise DeltaMutationError("simulator log does not bind transient build path")
    result = text.replace(exact, TRANSIENT_TOKEN)
    if exact in result:
        raise DeltaMutationError("transient build path remains after normalization")
    return result


def evaluate_log(
    log_text: str,
    returncode: int,
    compiled_image_exists: bool,
    markers: tuple[str, ...],
) -> tuple[bool, bool, dict[str, int]]:
    counts = {marker: log_text.count(marker) for marker in markers}
    compile_success = (
        compiled_image_exists
        and "[COMPILE]" in log_text
        and "compile returned nonzero status" not in log_text
        and "compilation returned nonzero status" not in log_text
        and "syntax error" not in log_text.lower()
    )
    rejected = (
        compile_success
        and returncode != 0
        and all(count == 1 for count in counts.values())
        and "[RESULT] FAIL" in log_text
        and "[RESULT] PASS" not in log_text
        and "[TIMEOUT]" not in log_text
    )
    return compile_success, rejected, counts


def run_one(
    root: pathlib.Path,
    log_dir: pathlib.Path,
    variant: Variant,
) -> dict[str, Any]:
    original, mutated = reconstruct(root, variant)
    source_path = root / variant.source
    source_sha_before = sha_file(source_path)
    log_path = log_dir / f"{variant.name}.log"
    with tempfile.TemporaryDirectory(
        prefix=f"rv64-arch-delta-{variant.name}.", dir="/tmp"
    ) as temp_name:
        transient = pathlib.Path(temp_name)
        mutated_path = transient / source_path.name
        mutated_path.write_bytes(mutated)
        result_dir = transient / "result"
        build_dir = transient / "build"
        target = result_dir / "logs" / f"{variant.test_name}.log"
        command = [
            "make", "-B", "-C", str(root / "npc/rv64/testbench"),
            f"RESULT_DIR={result_dir}", f"BUILD_DIR={build_dir}",
            f"{variant.make_variable}={mutated_path}",
        ]
        if variant.ivflags:
            command.append(
                f"TB_IVFLAGS_{variant.test_name}={variant.ivflags}"
            )
        command.append(str(target))
        completed = subprocess.run(
            command,
            cwd=root,
            check=False,
            capture_output=True,
            text=True,
            timeout=180,
        )
        test_log = target.read_text(encoding="utf-8") if target.is_file() else ""
        driver = completed.stdout + completed.stderr
        combined = test_log
        if driver:
            combined += "\n[ARCHITECTURE-DELTA-DRIVER]\n" + driver
        log_path.write_text(normalized(combined, transient), encoding="utf-8")
        image = build_dir / f"{variant.test_name}.vvp"
        compile_success, rejected, marker_counts = evaluate_log(
            test_log,
            completed.returncode,
            image.is_file(),
            variant.expected_markers,
        )
        transient_image_observed = image.is_file()
    source_sha_after = sha_file(source_path)
    return {
        "name": variant.name,
        "debt_id": variant.debt_id,
        "purpose": variant.purpose,
        "source": variant.source,
        "source_sha256": source_sha_before,
        "source_unchanged": source_sha_before == source_sha_after,
        "variant_sha256": sha_bytes(mutated),
        "anchor_sha256": sha_bytes(variant.old.encode()),
        "replacement_sha256": sha_bytes(variant.new.encode()),
        "make_variable": variant.make_variable,
        "test_name": variant.test_name,
        "ivflags": variant.ivflags,
        "expected_markers": list(variant.expected_markers),
        "marker_counts": marker_counts,
        "compile_success": compile_success,
        "dynamic_rejected": rejected,
        "make_returncode": completed.returncode,
        "transient_compiled_image_observed": transient_image_observed,
        "transient_compiled_image_retained": False,
        "replaces_historical_items": list(variant.replaces_historical_items),
        "log": {
            "path": log_path.relative_to(root).as_posix(),
            "sha256": sha_file(log_path),
            "size_bytes": log_path.stat().st_size,
        },
    }


def build_summary(
    root: pathlib.Path,
    output: pathlib.Path,
    selected: Sequence[str],
) -> dict[str, Any]:
    all_variants = {item.name: item for item in variants(root)}
    unknown = sorted(set(selected) - set(all_variants))
    if unknown:
        raise DeltaMutationError(f"unknown variants: {', '.join(unknown)}")
    chosen = [all_variants[name] for name in selected]
    if not chosen:
        raise DeltaMutationError("variant selection is empty")
    output.parent.mkdir(parents=True, exist_ok=True)
    log_dir = output.parent / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    sources = sorted({item.source for item in chosen})
    before = {path: sha_file(root / path) for path in sources}
    rows = [run_one(root, log_dir, item) for item in chosen]
    after = {path: sha_file(root / path) for path in sources}
    architecture = load_module(root / ARCH_TOOL, "architecture_delta_rtl_binding")
    rtl_sha, rtl_files = architecture.rtl_binding(root)
    passed = sum(
        bool(row["compile_success"])
        and bool(row["dynamic_rejected"])
        and bool(row["source_unchanged"])
        for row in rows
    )
    payload = {
        "schema": SCHEMA,
        "status": "PASS" if passed == len(rows) and before == after else "FAIL",
        "design_id": f"sha256:{rtl_sha}",
        "rtl_file_count": len(rtl_files),
        "source_unchanged": before == after,
        "source_sha256_before": before,
        "source_sha256_after": after,
        "counts": {
            "required": len(rows),
            "compile_success": sum(bool(row["compile_success"]) for row in rows),
            "dynamic_rejected": sum(bool(row["dynamic_rejected"]) for row in rows),
            "passed": passed,
            "transient_compiled_images_retained": 0,
        },
        "inputs": {
            "runner": {
                "path": pathlib.Path(__file__).resolve().relative_to(root).as_posix(),
                "sha256": sha_file(pathlib.Path(__file__).resolve()),
            },
            "control_variant_definitions": {
                "path": CONTROL_TOOL,
                "sha256": sha_file(root / CONTROL_TOOL),
            },
            "architecture_binding": {
                "path": ARCH_TOOL,
                "sha256": sha_file(root / ARCH_TOOL),
            },
        },
        "results": rows,
    }
    output.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return payload


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("--root", type=pathlib.Path, required=True)
    result.add_argument("--output", type=pathlib.Path, required=True)
    result.add_argument(
        "--select",
        action="append",
        default=[],
        help="run only the named variant; repeat for multiple variants",
    )
    return result


def main(argv: Sequence[str] | None = None) -> int:
    args = parser().parse_args(argv)
    root = args.root.resolve(strict=True)
    output = repo_output(root, args.output)
    if output.exists():
        print(
            f"[ARCHITECTURE-DELTA-MUTATIONS][FAIL] output exists: {output}",
            file=sys.stderr,
        )
        return 2
    try:
        available = variants(root)
        selected = args.select or [item.name for item in available]
        payload = build_summary(root, output, selected)
    except (DeltaMutationError, OSError, subprocess.TimeoutExpired) as exc:
        print(f"[ARCHITECTURE-DELTA-MUTATIONS][FAIL] {exc}", file=sys.stderr)
        return 1
    counts = payload["counts"]
    print(
        "[ARCHITECTURE-DELTA-MUTATIONS] "
        f"status={payload['status']} design_id={payload['design_id']} "
        f"compile_success={counts['compile_success']}/{counts['required']} "
        f"dynamic_rejected={counts['dynamic_rejected']}/{counts['required']} "
        "retained_images=0"
    )
    return 0 if payload["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
