#!/usr/bin/env python3
"""Compile and dynamically reject local-PHT contract mutations.

Every negative variant is an exact source replacement, must compile successfully,
and must reach its directed functional failure marker. Product RTL is hashed before
and after the matrix and is never overwritten.  The production source also passes a
fail-closed topology audit before any variant runs: bank ports are read-only views,
both lookup selectors consume full indices, and the wrapper owns no clocked write.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Sequence


@dataclass(frozen=True)
class Replacement:
    old: str
    new: str


@dataclass(frozen=True)
class Mutation:
    mutation_id: str
    target: str
    rtl_effect: str
    replacements: tuple[Replacement, ...]
    expected_marker: str


MUTATIONS = (
    Mutation(
        "lane1-address-reuse",
        "child",
        "lane1 flat read 错误复用 lane0 完整 12-bit 地址",
        (
            Replacement(
                """\
  assign lookup1_valid_o = flat_valid_view_w[lookup1_idx_i];
  assign lookup1_ctr_o =
      flat_counter_view_w[(lookup1_idx_i * 2) +: 2];
""",
                """\
  assign lookup1_valid_o = flat_valid_view_w[lookup0_idx_i];
  assign lookup1_ctr_o =
      flat_counter_view_w[(lookup0_idx_i * 2) +: 2];
""",
            ),
        ),
        "[BPU-LPHT-A4-SAME-BANK-DUAL-READ] FAIL",
    ),
    Mutation(
        "bank-row-exchange",
        "child",
        "update 把 index 低 4 bit 当 bank、高 8 bit 当 row",
        (
            Replacement(
                """\
  wire [BANK_W-1:0] update_bank_w =
      update_idx_i[`BPU_LOCAL_PHT_INDEX_W-1:ROW_W];
  wire [ROW_W-1:0] update_row_w = update_idx_i[ROW_W-1:0];
""",
                """\
  wire [BANK_W-1:0] update_bank_w = update_idx_i[BANK_W-1:0];
  wire [ROW_W-1:0] update_row_w =
      update_idx_i[`BPU_LOCAL_PHT_INDEX_W-1:BANK_W];
""",
            ),
        ),
        "[BPU-LPHT-A2-BANK-ROW-S1] FAIL",
    ),
    Mutation(
        "lookup-extra-cycle",
        "child",
        "lookup0 输出错误增加一个寄存级",
        (
            Replacement(
                """\
  assign lookup0_valid_o = flat_valid_view_w[lookup0_idx_i];
  assign lookup0_ctr_o =
      flat_counter_view_w[(lookup0_idx_i * 2) +: 2];
""",
                """\
  reg lookup0_valid_q;
  reg [1:0] lookup0_ctr_q;
  always @(posedge clk) begin
    lookup0_valid_q <= flat_valid_view_w[lookup0_idx_i];
    lookup0_ctr_q <= flat_counter_view_w[(lookup0_idx_i * 2) +: 2];
  end
  assign lookup0_valid_o = lookup0_valid_q;
  assign lookup0_ctr_o = lookup0_ctr_q;
""",
            ),
        ),
        "[BPU-LPHT-A3-UPDATE-S1-S2] FAIL",
    ),
    Mutation(
        "public-flat-write-owner",
        "child",
        "wrapper 错误恢复公共 4096-entry valid/counter write owner",
        (
            Replacement(
                """\
  wire [(BANKS*ROWS)-1:0] flat_valid_view_w;
  wire [(2*BANKS*ROWS)-1:0] flat_counter_view_w;
""",
                """\
  wire [(BANKS*ROWS)-1:0] flat_valid_view_w;
  wire [(2*BANKS*ROWS)-1:0] flat_counter_view_w;

  reg [(BANKS*ROWS)-1:0] public_flat_valid_q;
  reg [1:0] public_flat_counter_q [0:(BANKS*ROWS)-1];
  always @(posedge clk) begin
    if (rst || clear_i) begin
      public_flat_valid_q <= {(BANKS*ROWS){1'b0}};
    end else if (update_valid_i) begin
      public_flat_valid_q[update_idx_i] <= 1'b1;
      public_flat_counter_q[update_idx_i] <=
          update_taken_i ? 2'd3 : 2'd1;
    end
  end
""",
            ),
            Replacement(
                """\
  assign lookup0_valid_o = flat_valid_view_w[lookup0_idx_i];
  assign lookup0_ctr_o =
      flat_counter_view_w[(lookup0_idx_i * 2) +: 2];
  assign lookup1_valid_o = flat_valid_view_w[lookup1_idx_i];
  assign lookup1_ctr_o =
      flat_counter_view_w[(lookup1_idx_i * 2) +: 2];
""",
                """\
  assign lookup0_valid_o = public_flat_valid_q[lookup0_idx_i];
  assign lookup0_ctr_o = public_flat_counter_q[lookup0_idx_i];
  assign lookup1_valid_o = public_flat_valid_q[lookup1_idx_i];
  assign lookup1_ctr_o = public_flat_counter_q[lookup1_idx_i];
""",
            ),
        ),
        "[BPU-LPHT-A2-BANK-ROW-S1] FAIL",
    ),
    Mutation(
        "taken-counter-wrap",
        "child",
        "taken 计数器在 3 后错误 wrap 到 0",
        (
            Replacement(
                "        counter_train = (counter == 2'd3) ? 2'd3 : (counter + 2'd1);\n",
                "        counter_train = counter + 2'd1;\n",
            ),
        ),
        "[BPU-LPHT-A5-SATURATING-COUNTER] FAIL",
    ),
    Mutation(
        "update-one-cycle",
        "child",
        "resolve 沿直接写 bank，错误缩短为一拍可见",
        (
            Replacement(
                """\
    end else begin
      // S1：bank select 已在 wrapper 收窄；在本 bank 捕获 taken/row/old ctr。
      upd_valid_q <= update_valid_i;
""",
                """\
    end else begin
      if (update_valid_i) begin
        valid_q[update_row_i] <= 1'b1;
        counter_q[update_row_i] <= counter_train(update_old_ctr_w, update_taken_i);
      end
      // S1：bank select 已在 wrapper 收窄；在本 bank 捕获 taken/row/old ctr。
      upd_valid_q <= update_valid_i;
""",
            ),
        ),
        "[BPU-LPHT-A2-BANK-ROW-S1] FAIL",
    ),
    Mutation(
        "update-three-cycle",
        "child",
        "在 S1/S2 间错误增加第三拍 valid 延迟",
        (
            Replacement(
                """\
  reg upd_valid_q;
  reg [ROW_W-1:0] upd_row_q;
""",
                """\
  reg upd_valid_q;
  reg upd_valid_qq;
  reg [ROW_W-1:0] upd_row_q;
""",
            ),
            Replacement(
                """\
      upd_valid_q <= 1'b0;
    end else begin
""",
                """\
      upd_valid_q <= 1'b0;
      upd_valid_qq <= 1'b0;
    end else begin
""",
            ),
            Replacement(
                """\
      upd_valid_q <= update_valid_i;
      if (update_valid_i) begin
""",
                """\
      upd_valid_q <= update_valid_i;
      upd_valid_qq <= upd_valid_q;
      if (update_valid_i) begin
""",
            ),
            Replacement(
                "      if (upd_valid_q) begin\n",
                "      if (upd_valid_qq) begin\n",
            ),
        ),
        "[BPU-LPHT-A3-UPDATE-S1-S2] FAIL",
    ),
    Mutation(
        "raw-forwarding",
        "child",
        "新 S1 错误旁路同 row pending S2 训练结果",
        (
            Replacement(
                """\
  wire [1:0] update_old_ctr_w = valid_q[update_row_i] ?
      counter_q[update_row_i] : `BPU_COUNTER_INIT;
""",
                """\
  wire update_forward_w = upd_valid_q && (upd_row_q == update_row_i);
  wire [1:0] update_old_ctr_w = update_forward_w ?
      counter_train(upd_old_ctr_q, upd_taken_q) :
      (valid_q[update_row_i] ? counter_q[update_row_i] : `BPU_COUNTER_INIT);
""",
            ),
        ),
        "[BPU-LPHT-A6-RAW-NO-FORWARD] FAIL",
    ),
    Mutation(
        "clear-keeps-pending-s2",
        "child",
        "clear 错误保留 bank-local pending S2",
        (
            Replacement(
                "      upd_valid_q <= 1'b0;\n",
                "      upd_valid_q <= upd_valid_q;\n",
            ),
        ),
        "[BPU-LPHT-A7-CLEAR-PENDING-S2] FAIL",
    ),
    Mutation(
        "same-bank-arbitration",
        "child",
        "同 bank 时错误压掉 lane1 组合读",
        (
            Replacement(
                "  assign lookup1_valid_o = flat_valid_view_w[lookup1_idx_i];\n",
                """\
  assign lookup1_valid_o =
      (lookup1_idx_i[`BPU_LOCAL_PHT_INDEX_W-1:`OOO_BPU_LOCAL_PHT_ROW_W] !=
       lookup0_idx_i[`BPU_LOCAL_PHT_INDEX_W-1:`OOO_BPU_LOCAL_PHT_ROW_W]) &&
      flat_valid_view_w[lookup1_idx_i];
""",
            ),
        ),
        "[BPU-LPHT-A4-SAME-BANK-DUAL-READ] FAIL",
    ),
    Mutation(
        "mispredict-suppresses-train",
        "parent",
        "parent 错误抑制 prediction!=actual 的 local-PHT train",
        (
            Replacement(
                "    .update_valid_i(update_valid_i),\n",
                "    .update_valid_i(update_valid_i && (update_taken_i == lookup0_pred_taken_o)),\n",
            ),
        ),
        "[BPU-L1-STRONG] lookup1 strength mismatch: got=0 exp=1 pc=0000000080001020",
    ),
    Mutation(
        "mispredict-restores-local-pht",
        "parent",
        "parent 错误把 mispredict 当作 child clear/restore",
        (
            Replacement(
                "    .clear_i(clear_i),\n",
                "    .clear_i(clear_i || (update_valid_i && (update_taken_i != lookup0_pred_taken_o))),\n",
            ),
        ),
        "[BPU-L1-STRONG] lookup1 strength mismatch: got=0 exp=1 pc=0000000080001020",
    ),
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def apply_mutation(source: str, mutation: Mutation) -> tuple[str, list[dict[str, object]]]:
    mutated = source
    receipts: list[dict[str, object]] = []
    for replacement in mutation.replacements:
        count = mutated.count(replacement.old)
        if count != 1:
            raise ValueError(
                f"{mutation.mutation_id}: expected one anchor, observed {count}"
            )
        mutated = mutated.replace(replacement.old, replacement.new, 1)
        receipts.append(
            {
                "old_sha256": sha256_bytes(replacement.old.encode("utf-8")),
                "new_sha256": sha256_bytes(replacement.new.encode("utf-8")),
                "anchor_count": count,
            }
        )
    return mutated, receipts


def audit_product_structure(source: str) -> dict[str, object]:
    """Audit the fixed write-banked/read-flat-view ownership boundary."""

    separator = "module OooBranchLocalPhtBank #("
    if source.count(separator) != 1:
        return {
            "status": "FAIL",
            "errors": ["OooBranchLocalPhtBank module boundary is not unique"],
        }
    wrapper, bank = source.split(separator, 1)
    required_wrapper = (
        "wire [(BANKS*ROWS)-1:0] flat_valid_view_w;",
        "wire [(2*BANKS*ROWS)-1:0] flat_counter_view_w;",
        "assign lookup0_valid_o = flat_valid_view_w[lookup0_idx_i];",
        "flat_counter_view_w[(lookup0_idx_i * 2) +: 2];",
        "assign lookup1_valid_o = flat_valid_view_w[lookup1_idx_i];",
        "flat_counter_view_w[(lookup1_idx_i * 2) +: 2];",
        ".valid_view_o(flat_valid_view_w[(ROWS*bank_i)+:ROWS])",
        "flat_counter_view_w[((2*ROWS)*bank_i)+:(2*ROWS)]",
    )
    required_bank = (
        "output [`OOO_BPU_LOCAL_PHT_ROWS-1:0] valid_view_o",
        "output [(2*`OOO_BPU_LOCAL_PHT_ROWS)-1:0] counter_view_o",
        "wire [1:0] update_old_ctr_w = valid_q[update_row_i] ?",
        "counter_q[upd_row_q] <= counter_train(upd_old_ctr_q, upd_taken_q);",
    )
    errors = [
        f"wrapper lacks fixed flat-read anchor: {anchor}"
        for anchor in required_wrapper
        if wrapper.count(anchor) != 1
    ]
    errors.extend(
        f"bank lacks fixed state/update anchor: {anchor}"
        for anchor in required_bank
        if bank.count(anchor) != 1
    )
    if "always @(posedge clk)" in wrapper:
        errors.append("wrapper regained a clocked public write owner")
    if "function [1:0] counter_train" in wrapper:
        errors.append("wrapper regained a public counter_train data cone")
    for lane_anchor in ("lookup0_en_i", "lookup0_row_i", "lookup1_en_i", "lookup1_row_i"):
        if lane_anchor in bank:
            errors.append(f"bank regained lane-specific read selector: {lane_anchor}")
    return {"status": "FAIL" if errors else "PASS", "errors": errors}


def run_one(
    *,
    repo_root: Path,
    testbench_dir: Path,
    result_dir: Path,
    sources: dict[str, Path],
    source_text: dict[str, str],
    mutation: Mutation,
) -> dict[str, object]:
    variant_dir = result_dir / mutation.mutation_id
    rtl_dir = variant_dir / "rtl"
    build_dir = variant_dir / "build"
    run_dir = variant_dir / "run"
    rtl_dir.mkdir(parents=True, exist_ok=True)
    run_dir.mkdir(parents=True, exist_ok=True)

    mutated, replacements = apply_mutation(source_text[mutation.target], mutation)
    source_path = sources[mutation.target]
    mutant_path = rtl_dir / source_path.name
    mutant_path.write_text(mutated, encoding="utf-8")

    test = (
        "tb_ooo_branch_local_pht"
        if mutation.target == "child"
        else "tb_ooo_branch_direction_predictor"
    )
    log_path = run_dir / "logs" / f"{test}.log"
    override = (
        f"RTL_OOO_BRANCH_LOCAL_PHT={mutant_path}"
        if mutation.target == "child"
        else f"RTL_OOO_BRANCH_DIRECTION_PREDICTOR={mutant_path}"
    )
    command = [
        "make",
        "-B",
        f"BUILD_DIR={build_dir}",
        f"RESULT_DIR={run_dir}",
        override,
        str(log_path),
    ]
    completed = subprocess.run(
        command,
        cwd=testbench_dir,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    (variant_dir / "driver.stdout").write_text(completed.stdout, encoding="utf-8")
    (variant_dir / "driver.stderr").write_text(completed.stderr, encoding="utf-8")

    compile_artifact = build_dir / f"{test}.vvp"
    compile_succeeded = (
        compile_artifact.is_file() and compile_artifact.stat().st_size > 0
    )
    log_bytes = log_path.read_bytes() if log_path.is_file() else b""
    log_text = log_bytes.decode("utf-8", errors="replace")
    raw_log_sha256 = sha256_bytes(log_bytes) if log_bytes else None
    raw_log_size_bytes = len(log_bytes)
    raw_log_bound = raw_log_sha256 is not None and raw_log_size_bytes > 0
    expected_marker_count = log_text.count(mutation.expected_marker)
    result_fail_count = log_text.count("[RESULT] FAIL")
    result_pass_count = log_text.count("[RESULT] PASS")
    rejected = (
        compile_succeeded
        and completed.returncode != 0
        and expected_marker_count == 1
        and result_fail_count == 1
        and result_pass_count == 0
        and raw_log_bound
    )
    return {
        "mutation_id": mutation.mutation_id,
        "target": mutation.target,
        "rtl_effect": mutation.rtl_effect,
        "replacement_receipts": replacements,
        "mutant_path": mutant_path.relative_to(repo_root).as_posix(),
        "mutant_sha256": sha256_bytes(mutant_path.read_bytes()),
        "testbench": test,
        "command": command,
        "driver_rc": completed.returncode,
        "compile_succeeded": compile_succeeded,
        "compile_artifact": compile_artifact.relative_to(repo_root).as_posix(),
        "expected_marker": mutation.expected_marker,
        "expected_marker_count": expected_marker_count,
        "result_fail_count": result_fail_count,
        "result_pass_count": result_pass_count,
        "raw_log_sha256": raw_log_sha256,
        "raw_log_size_bytes": raw_log_size_bytes,
        "raw_log_bound": raw_log_bound,
        "rejected": rejected,
        "log_path": log_path.relative_to(repo_root).as_posix(),
    }


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[4],
    )
    parser.add_argument("--result-dir", required=True, type=Path)
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    repo_root = args.repo_root.resolve()
    result_dir = args.result_dir.resolve()
    if result_dir.exists() and any(result_dir.iterdir()):
        print(f"result directory is not empty: {result_dir}", file=sys.stderr)
        return 2
    result_dir.mkdir(parents=True, exist_ok=True)

    testbench_dir = repo_root / "npc/rv64/testbench"
    sources = {
        "child": repo_root / "npc/rv64/vsrc/frontend/OooBranchLocalPht.v",
        "parent": repo_root / "npc/rv64/vsrc/frontend/OooBranchDirectionPredictor.v",
    }
    before = {name: path.read_bytes() for name, path in sources.items()}
    source_text = {name: data.decode("utf-8") for name, data in before.items()}
    structure_audit = audit_product_structure(source_text["child"])
    if structure_audit["status"] != "PASS":
        print(
            "[BPU-LPHT-STRUCTURE] FAIL "
            + "; ".join(str(error) for error in structure_audit["errors"]),
            file=sys.stderr,
        )
        return 2

    try:
        results = [
            run_one(
                repo_root=repo_root,
                testbench_dir=testbench_dir,
                result_dir=result_dir,
                sources=sources,
                source_text=source_text,
                mutation=mutation,
            )
            for mutation in MUTATIONS
        ]
    except (OSError, UnicodeError, ValueError) as error:
        print(f"[BPU-LPHT-MUTATIONS] FAIL setup={error}", file=sys.stderr)
        return 2

    after = {name: path.read_bytes() for name, path in sources.items()}
    source_unchanged = before == after
    compile_count = sum(bool(row["compile_succeeded"]) for row in results)
    unique_marker_count = sum(row["expected_marker_count"] == 1 for row in results)
    raw_log_bound_count = sum(bool(row["raw_log_bound"]) for row in results)
    rejected_count = sum(bool(row["rejected"]) for row in results)
    passed = (
        structure_audit["status"] == "PASS"
        and source_unchanged
        and rejected_count == len(MUTATIONS)
    )
    evidence = {
        "schema": "npc-rv64-bpu-local-pht-mutation-evidence-v3",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "configuration": "iverilog-g2012-OOO_ASSERT",
        "structure_audit": structure_audit,
        "source_sha256_before": {
            name: sha256_bytes(data) for name, data in before.items()
        },
        "source_sha256_after": {
            name: sha256_bytes(data) for name, data in after.items()
        },
        "source_unchanged": source_unchanged,
        "mutations": results,
        "summary": {
            "total": len(MUTATIONS),
            "compile_succeeded": compile_count,
            "unique_expected_marker": unique_marker_count,
            "raw_logs_bound": raw_log_bound_count,
            "rejected": rejected_count,
            "all_rejected": passed,
        },
    }
    evidence_path = result_dir / "mutation-evidence.json"
    evidence_path.write_text(
        json.dumps(evidence, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        "[BPU-LPHT-MUTATIONS] "
        f"total={len(MUTATIONS)} compile_succeeded={compile_count} "
        f"unique_marker={unique_marker_count} raw_logs_bound={raw_log_bound_count} "
        f"rejected={rejected_count} source_unchanged={int(source_unchanged)} "
        f"{'PASS' if passed else 'FAIL'}"
    )
    print("[BPU-LPHT-STRUCTURE] PASS write-banked/read-flat-view")
    print(evidence_path)
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
