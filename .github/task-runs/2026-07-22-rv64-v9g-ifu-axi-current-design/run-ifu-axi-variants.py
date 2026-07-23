#!/usr/bin/env python3
"""Compile and dynamically reject local RV64 IFU AXI lifecycle RTL variants."""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import json
import pathlib
import subprocess
import tempfile
from typing import Sequence


SCHEMA = "npc-rv64-ifu-axi-flush-drain-rtl-variants-v1"
SUITE_RUN_ID = "2026-07-22-rv64-v9g-ifu-axi-current-design"
TRANSIENT_DIR_TOKEN = "<IFU_AXI_V9G_TRANSIENT_TMP>"


@dataclasses.dataclass(frozen=True)
class VariantSpec:
    name: str
    purpose: str
    source_rel: str
    make_variable: str
    test_name: str
    old: str
    new: str
    expected_marker: str


BRIDGE = "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v"
XBAR = "npc/rv64/vsrc/bus/AxiXbar.v"

VARIANTS = (
    VariantSpec(
        name="flush_releases_write_owner",
        purpose=(
            "Treat frontend mmu_flush_i as transaction reset while the "
            "instruction-fetch PTE A-update write owner is active."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge",
        old=(
            "    end else if (mmu_flush_i && "
            "(state_q != S_AD_UPDATE)) begin"
        ),
        new="    end else if (mmu_flush_i) begin",
        expected_marker="flush keeps A-update write owner got=0 expected=1",
    ),
    VariantSpec(
        name="awvalid_withdraws_on_flush",
        purpose=(
            "Withdraw a pending instruction-fetch PTE AW channel while "
            "mmu_flush_i is asserted."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge",
        old=(
            "  assign ifu_axi_awvalid_o = "
            "(state_q == S_AD_UPDATE) && !aw_done_q;"
        ),
        new=(
            "  assign ifu_axi_awvalid_o = "
            "(state_q == S_AD_UPDATE) && !aw_done_q && !mmu_flush_i;"
        ),
        expected_marker="flush+last AW records fire got=0 expected=1",
    ),
    VariantSpec(
        name="wvalid_withdraws_on_flush",
        purpose=(
            "Withdraw a pending instruction-fetch PTE W channel while "
            "mmu_flush_i is asserted."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge",
        old=(
            "  assign ifu_axi_wvalid_o = "
            "(state_q == S_AD_UPDATE) && !w_done_q;"
        ),
        new=(
            "  assign ifu_axi_wvalid_o = "
            "(state_q == S_AD_UPDATE) && !w_done_q && !mmu_flush_i;"
        ),
        expected_marker="repeated flush keeps W valid got=0 expected=1",
    ),
    VariantSpec(
        name="bready_withdraws_on_flush",
        purpose=(
            "Withdraw BREADY from the active instruction-fetch PTE write "
            "owner while mmu_flush_i is asserted."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge",
        old="  assign ifu_axi_bready_o = (state_q == S_AD_UPDATE);",
        new=(
            "  assign ifu_axi_bready_o = "
            "(state_q == S_AD_UPDATE) && !mmu_flush_i;"
        ),
        expected_marker="repeated flush keeps BREADY got=0 expected=1",
    ),
    VariantSpec(
        name="last_aw_fire_not_counted",
        purpose=(
            "Ignore the current-cycle final AW handshake in the PTE write "
            "completion predicate."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge",
        old=(
            "  wire ifu_ad_aw_accepted_next_w = "
            "aw_done_q || ifu_ad_aw_fire_w;"
        ),
        new="  wire ifu_ad_aw_accepted_next_w = aw_done_q;",
        expected_marker="flush+last-AW+B completes to IDLE got=0 expected=1",
    ),
    VariantSpec(
        name="last_w_fire_not_counted",
        purpose=(
            "Ignore the current-cycle final W handshake in the PTE write "
            "completion predicate."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge",
        old=(
            "  wire ifu_ad_w_accepted_next_w = "
            "w_done_q || ifu_ad_w_fire_w;"
        ),
        new="  wire ifu_ad_w_accepted_next_w = w_done_q;",
        expected_marker="flush+last-W+B completes to IDLE got=0 expected=1",
    ),
    VariantSpec(
        name="flush_aw_fire_not_recorded",
        purpose=(
            "Discard an AW handshake that occurs in the same cycle as "
            "mmu_flush_i instead of recording the channel acceptance."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge",
        old="          if (ifu_ad_aw_fire_w) aw_done_q <= 1'b1;",
        new=(
            "          if (ifu_ad_aw_fire_w && !mmu_flush_i) "
            "aw_done_q <= 1'b1;"
        ),
        expected_marker="flush+first AW records fire got=0 expected=1",
    ),
    VariantSpec(
        name="flush_w_fire_not_recorded",
        purpose=(
            "Discard a W handshake that occurs in the same cycle as "
            "mmu_flush_i instead of recording the channel acceptance."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge",
        old="          if (ifu_ad_w_fire_w) w_done_q <= 1'b1;",
        new=(
            "          if (ifu_ad_w_fire_w && !mmu_flush_i) "
            "w_done_q <= 1'b1;"
        ),
        expected_marker="flush+first W records fire got=0 expected=1",
    ),
    VariantSpec(
        name="completion_requires_old_done_bits",
        purpose=(
            "Require both registered channel-done bits before B completion, "
            "ignoring simultaneous AW and W handshakes."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge",
        old=(
            "  wire ifu_ad_write_complete_w = "
            "ifu_ad_aw_accepted_next_w &&\n"
            "                                 "
            "ifu_ad_w_accepted_next_w && ifu_ad_b_fire_w;"
        ),
        new=(
            "  wire ifu_ad_write_complete_w = aw_done_q &&\n"
            "                                 "
            "w_done_q && ifu_ad_b_fire_w;"
        ),
        expected_marker="flush+AW+W+B completes to IDLE got=0 expected=1",
    ),
    VariantSpec(
        name="same_cycle_flush_not_effective_drop",
        purpose=(
            "Ignore current-cycle mmu_flush_i when AW/W/B complete in the "
            "same cycle, allowing an obsolete fetch transaction to re-walk."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge",
        old="            if (ad_drop_q || mmu_flush_i) begin",
        new="            if (ad_drop_q) begin",
        expected_marker="flush+last-AW+B completes to IDLE got=0 expected=1",
    ),
    VariantSpec(
        name="flush_drop_not_sticky",
        purpose=(
            "Fail to retain the semantic drop bit from mmu_flush_i until a "
            "later PTE write B completion."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge",
        old="          if (mmu_flush_i) ad_drop_q <= 1'b1;",
        new="          if (mmu_flush_i) ad_drop_q <= 1'b0;",
        expected_marker="AW-first flush drains to IDLE got=0 expected=1",
    ),
    VariantSpec(
        name="bresp_error_precedes_drop",
        purpose=(
            "Allow a B response error to override sticky or current-cycle "
            "semantic drop at instruction-fetch PTE write completion."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge",
        old="            if (ad_drop_q || mmu_flush_i) begin",
        new=(
            "            if ((ad_drop_q || mmu_flush_i) && "
            "(ifu_axi_bresp_i == RESP_OK)) begin"
        ),
        expected_marker="both-done flush+B-error drains to IDLE got=0 expected=1",
    ),
    VariantSpec(
        name="awaddr_uses_live_candidate_during_flush",
        purpose=(
            "Replace the frozen PTE AW address with the live candidate PC "
            "while the write channel is backpressured under mmu_flush_i."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge",
        old="  assign ifu_axi_awaddr_o = walk_pte_addr_q;",
        new=(
            "  assign ifu_axi_awaddr_o = mmu_flush_i ? "
            "fetch_ctx_candidate_pc_q : walk_pte_addr_q;"
        ),
        expected_marker="repeated flush keeps AWADDR",
    ),
    VariantSpec(
        name="wdata_uses_live_candidate_during_flush",
        purpose=(
            "Replace the frozen A-updated PTE data with the live candidate "
            "PC while W is backpressured under mmu_flush_i."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge",
        old="  assign ifu_axi_wdata_o = ad_pte_q;",
        new=(
            "  assign ifu_axi_wdata_o = mmu_flush_i ? "
            "fetch_ctx_candidate_pc_q : ad_pte_q;"
        ),
        expected_marker="repeated flush keeps WDATA",
    ),
    VariantSpec(
        name="xbar_b_fire_does_not_release_owner",
        purpose=(
            "Prevent the exact slave B handshake from releasing the AxiXbar "
            "write owner and its master-busy state."
        ),
        source_rel=XBAR,
        make_variable="RTL_AXI_XBAR",
        test_name="tb_ooo_fetch_axi_bridge_xbar",
        old=(
            "        if (wr_active_q[s] && wr_aw_sent_q[s] && "
            "wr_w_sent_q[s] &&\n"
            "            s_bvalid_i[s] && s_bready_r[s]) begin"
        ),
        new=(
            "        if (1'b0 && wr_active_q[s] && wr_aw_sent_q[s] && "
            "wr_w_sent_q[s] &&\n"
            "            s_bvalid_i[s] && s_bready_r[s]) begin"
        ),
        expected_marker="xbar releases IFU write owner got=1 expected=0",
    ),
    VariantSpec(
        name="xbar_releases_owner_on_bvalid",
        purpose=(
            "Release the AxiXbar write owner on slave BVALID without the "
            "master BREADY handshake."
        ),
        source_rel=XBAR,
        make_variable="RTL_AXI_XBAR",
        test_name="tb_axi_xbar",
        old=(
            "        if (wr_active_q[s] && wr_aw_sent_q[s] && "
            "wr_w_sent_q[s] &&\n"
            "            s_bvalid_i[s] && s_bready_r[s]) begin"
        ),
        new=(
            "        if (wr_active_q[s] && wr_aw_sent_q[s] && "
            "wr_w_sent_q[s] &&\n"
            "            s_bvalid_i[s]) begin"
        ),
        expected_marker=(
            "split write owner remains active under B backpressure "
            "got=0 expected=1"
        ),
    ),
    VariantSpec(
        name="xbar_aw_capture_requires_same_cycle_wvalid",
        purpose=(
            "Require WVALID in the same cycle as an accepted AW channel, "
            "breaking legal AW-first master presentation."
        ),
        source_rel=XBAR,
        make_variable="RTL_AXI_XBAR",
        test_name="tb_axi_xbar",
        old="        if (m_awvalid_i[m] && m_awready_r[m]) begin",
        new=(
            "        if (m_awvalid_i[m] && m_awready_r[m] && "
            "m_wvalid_i[m]) begin"
        ),
        expected_marker="split write slave awvalid got=0 expected=1",
    ),
    VariantSpec(
        name="xbar_w_capture_requires_same_cycle_awvalid",
        purpose=(
            "Require AWVALID in the same cycle as an accepted W channel, "
            "breaking legal W-first master presentation."
        ),
        source_rel=XBAR,
        make_variable="RTL_AXI_XBAR",
        test_name="tb_axi_xbar",
        old="        if (m_wvalid_i[m] && m_wready_r[m]) begin",
        new=(
            "        if (m_wvalid_i[m] && m_wready_r[m] && "
            "m_awvalid_i[m]) begin"
        ),
        expected_marker="w-first write slave awvalid got=0 expected=1",
    ),
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: pathlib.Path) -> str:
    return sha256_bytes(path.read_bytes())


def repository_path(root: pathlib.Path, value: pathlib.Path) -> pathlib.Path:
    resolved = value.resolve()
    if not resolved.is_relative_to(root):
        raise ValueError(f"output escapes repository: {resolved}")
    return resolved


def normalize_transient_paths(text: str, transient: pathlib.Path) -> str:
    if TRANSIENT_DIR_TOKEN in text:
        raise ValueError("raw log already contains the normalization token")
    exact = str(transient.resolve(strict=True))
    if exact not in text:
        raise ValueError("raw log does not bind the current transient directory")
    return text.replace(exact, TRANSIENT_DIR_TOKEN)


def normalize_log_directory(
    root: pathlib.Path,
    log_dir: pathlib.Path,
    transient_dir: pathlib.Path,
) -> tuple[int, int]:
    resolved_log_dir = repository_path(root, log_dir)
    if not resolved_log_dir.is_dir():
        raise ValueError(f"log directory is missing: {resolved_log_dir}")
    transient = transient_dir.resolve(strict=True)
    if transient.is_relative_to(root):
        raise ValueError("transient compile directory must be outside repository")
    if transient.parent != pathlib.Path("/tmp") or not transient.name.startswith(
        "rv64-ifu-axi-v9g."
    ):
        raise ValueError(f"unexpected transient compile directory: {transient}")
    logs = sorted(resolved_log_dir.glob("*.log"))
    if not logs:
        raise ValueError("log inventory is empty")
    replacements = 0
    for log_path in logs:
        resolved_log = log_path.resolve(strict=True)
        if log_path.is_symlink() or resolved_log.parent != resolved_log_dir:
            raise ValueError(f"log is not an exact regular file: {log_path}")
        text = resolved_log.read_text(encoding="utf-8")
        replacements += text.count(str(transient))
        resolved_log.write_text(
            normalize_transient_paths(text, transient), encoding="utf-8")
    return len(logs), replacements


def reconstruct_variant(
    root: pathlib.Path,
    spec: VariantSpec,
) -> tuple[str, str]:
    source = (root / spec.source_rel).resolve(strict=True)
    if not source.is_relative_to(root):
        raise ValueError(f"{spec.name}: source escapes repository")
    text = source.read_text(encoding="utf-8")
    if text.count(spec.old) != 1 or spec.old == spec.new:
        raise ValueError(f"{spec.name}: live RTL variant anchor is not unique")
    return text, text.replace(spec.old, spec.new, 1)


def run_one(
    root: pathlib.Path,
    output_dir: pathlib.Path,
    spec: VariantSpec,
) -> dict[str, object]:
    original_text, variant_text = reconstruct_variant(root, spec)
    original_path = root / spec.source_rel
    log_path = output_dir / f"{spec.name}.log"
    with tempfile.TemporaryDirectory(
        prefix=f"rv64-v9g-{spec.name}.", dir="/tmp",
    ) as temp_name:
        temp = pathlib.Path(temp_name)
        variant_path = temp / original_path.name
        variant_path.write_text(variant_text, encoding="utf-8")
        result_dir = temp / "result"
        build_dir = temp / "build"
        target = result_dir / "logs" / f"{spec.test_name}.log"
        command = [
            "make", "-B", "-C", str(root / "npc/rv64/testbench"),
            f"RESULT_DIR={result_dir}", f"BUILD_DIR={build_dir}",
            f"{spec.make_variable}={variant_path}",
            str(target),
        ]
        completed = subprocess.run(
            command, cwd=root, check=False, capture_output=True, text=True,
            timeout=180)
        test_log = target.read_text(encoding="utf-8") if target.is_file() else ""
        driver = completed.stdout + completed.stderr
        combined = test_log + (
            "\n[RTL-VERIFICATION-VARIANT-DRIVER]\n" + driver
            if driver else "")
        log_path.write_text(
            normalize_transient_paths(combined, temp), encoding="utf-8")
        compiled_image = build_dir / f"{spec.test_name}.vvp"
        compile_success = (
            compiled_image.is_file() and "[COMPILE]" in test_log
            and "compile returned nonzero status" not in test_log)
        marker_observed = spec.expected_marker in test_log
        dynamic_rejected = (
            compile_success and completed.returncode != 0 and marker_observed
            and "[RESULT] FAIL status=" in test_log
            and "[RESULT] PASS" not in test_log)
    return {
        "name": spec.name,
        "debt_id": "IFU-AXI-G1",
        "purpose": spec.purpose,
        "source": spec.source_rel,
        "make_variable": spec.make_variable,
        "test_name": spec.test_name,
        "original_sha256": sha256_bytes(original_text.encode("utf-8")),
        "variant_sha256": sha256_bytes(variant_text.encode("utf-8")),
        "expected_marker": spec.expected_marker,
        "marker_observed": marker_observed,
        "compile_success": compile_success,
        "dynamic_rejected": dynamic_rejected,
        "make_returncode": completed.returncode,
        "log": {
            "path": log_path.relative_to(root).as_posix(),
            "sha256": sha256_file(log_path),
        },
    }


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=pathlib.Path, required=True)
    parser.add_argument("--output", type=pathlib.Path)
    parser.add_argument("--normalize-log-dir", type=pathlib.Path)
    parser.add_argument("--transient-dir", type=pathlib.Path)
    args = parser.parse_args(argv)
    root = args.root.resolve(strict=True)

    if args.normalize_log_dir is not None or args.transient_dir is not None:
        if (args.normalize_log_dir is None or args.transient_dir is None
                or args.output is not None):
            parser.error(
                "log normalization requires --normalize-log-dir and "
                "--transient-dir without --output")
        count, replacements = normalize_log_directory(
            root, args.normalize_log_dir, args.transient_dir)
        print(
            f"[IFU-AXI-LOG-NORMALIZATION] logs={count} "
            f"replacements={replacements} token={TRANSIENT_DIR_TOKEN}")
        return 0

    if args.output is None:
        parser.error("RTL verification-variant mode requires --output")
    output = repository_path(root, args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    log_dir = output.parent / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)

    source_paths = sorted({spec.source_rel for spec in VARIANTS})
    before = {name: sha256_file(root / name) for name in source_paths}
    results = [run_one(root, log_dir, spec) for spec in VARIANTS]
    after = {name: sha256_file(root / name) for name in source_paths}
    compile_success = sum(bool(row["compile_success"]) for row in results)
    dynamic_rejected = sum(bool(row["dynamic_rejected"]) for row in results)
    payload = {
        "schema": SCHEMA,
        "suite_run_id": SUITE_RUN_ID,
        "required": len(VARIANTS),
        "compile_success": compile_success,
        "dynamic_rejected": dynamic_rejected,
        "source_unchanged": before == after,
        "source_sha256_before": before,
        "source_sha256_after": after,
        "results": results,
    }
    output.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8")
    print(
        f"[IFU-AXI-RTL-VARIANTS] required={len(VARIANTS)} "
        f"compile_success={compile_success} dynamic_rejected={dynamic_rejected} "
        f"source_unchanged={str(before == after).lower()}")
    return 0 if (
        compile_success == len(VARIANTS)
        and dynamic_rejected == len(VARIANTS)
        and before == after
    ) else 1


if __name__ == "__main__":
    raise SystemExit(main())
