#!/usr/bin/env python3
"""Run compile-success structural mutations against the focused OOO-3 LQ TB."""

from __future__ import annotations

import hashlib
import json
import subprocess
import tempfile
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path


@dataclass(frozen=True)
class Mutation:
    name: str
    old: str
    new: str
    oracle: str
    contract: str


RUN_DIR = Path(__file__).resolve().parent
REPO_ROOT = RUN_DIR.parents[2]
SOURCE = REPO_ROOT / "npc/rv64/vsrc/memory/OooLoadQueue.v"
TB_DIR = REPO_ROOT / "npc/rv64/testbench"

MUTATIONS = (
    Mutation(
        "pid_index_only",
        "(producer_id_q[g] == issue0_producer_id_i);",
        "(producer_id_q[g][ROB_INDEX_W-1:0] ==\n"
        "           issue0_producer_id_i[ROB_INDEX_W-1:0]);",
        "same ROB index with stale generation is issue-closed",
        "Every LQ ownership lookup uses the complete ProducerId.",
    ),
    Mutation(
        "issue_killed_bypass",
        "if (issue0_hit_w[lookup_i] && !killed_q[lookup_i] &&\n"
        "          !completed_q[lookup_i])",
        "if (issue0_hit_w[lookup_i] && !completed_q[lookup_i])",
        "launched younger load remains issue-closed tombstone",
        "A selectively killed launched load cannot issue again.",
    ),
    Mutation(
        "query_metadata_bypass",
        "if (query1_hit_w[lookup_i] && launched_q[lookup_i] &&\n"
        "          !killed_q[lookup_i] && !completed_q[lookup_i] &&\n"
        "          query1_meta_match_w[lookup_i] && !query_pair_same_pid_w)",
        "if (query1_hit_w[lookup_i] && launched_q[lookup_i] &&\n"
        "          !killed_q[lookup_i] && !completed_q[lookup_i] &&\n"
        "          !query_pair_same_pid_w)",
        "retry with changed final PA fails closed",
        "A repeated physical query preserves PA, class, attribute and mask.",
    ),
    Mutation(
        "response_order_bypass",
        "(ordered_q[lookup_i] || response1_fault_i))",
        "(1'b1 || response1_fault_i))",
        "allow opens response while replay stays ordered-closed",
        "A successful load response requires an allow/forward disposition.",
    ),
    Mutation(
        "terminal_releases_normal",
        "((terminal0_hit_w[i] || terminal1_hit_w[i]) && killed_q[i]))",
        "(terminal0_hit_w[i] || terminal1_hit_w[i]))",
        "normal transport terminal retains retire-resident entries",
        "A normal transport terminal does not end retire residency.",
    ),
    Mutation(
        "flush_drops_launched",
        "if (((launched_q[i] || launch0_hit_w[i] || launch1_hit_w[i]) &&\n"
        "               !completed_q[i] && !completion0_hit_w[i] &&\n"
        "               !completion1_hit_w[i]) &&",
        "if (((1'b0 || launch0_hit_w[i] || launch1_hit_w[i]) &&\n"
        "               !completed_q[i] && !completion0_hit_w[i] &&\n"
        "               !completion1_hit_w[i]) &&",
        "selective recovery clears unlaunched younger load only",
        "Recovery retains a launched incomplete load as a killed tombstone.",
    ),
    Mutation(
        "release_before_completion",
        "if (release0_match_w[lookup_i] &&\n"
        "          (completed_q[lookup_i] || completion0_hit_w[lookup_i] ||\n"
        "           completion1_hit_w[lookup_i]))",
        "if (release0_match_w[lookup_i])",
        "retirement before formal completion is backpressured",
        "ROB release requires prior or same-cycle formal completion.",
    ),
    Mutation(
        "dual_alloc_same_slot",
        "alloc1_idx_r = alloc_i[ENTRY_INDEX_W-1:0];",
        "alloc1_idx_r = alloc0_idx_r;",
        "dual dispatch must create two LQ residents",
        "Dual dispatch allocation selects two distinct edge-old free entries.",
    ),
    Mutation(
        "dual_query_same_pid_bypass",
        "wire query_pair_same_pid_w = query0_valid_i && query1_valid_i &&\n"
        "      (query0_producer_id_i == query1_producer_id_i);",
        "wire query_pair_same_pid_w = 1'b0;",
        "same-PID dual query fails closed on both ports",
        "Two final-PA query lanes cannot update one ProducerId in the same cycle.",
    ),
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    source_bytes = SOURCE.read_bytes()
    source_text = source_bytes.decode("utf-8")
    scratch = Path(tempfile.mkdtemp(prefix="codex-v8v-lq-mutations-"))
    results: list[dict[str, object]] = []

    for mutation in MUTATIONS:
        occurrences = source_text.count(mutation.old)
        if occurrences != 1:
            raise RuntimeError(
                f"mutation {mutation.name}: expected one anchor, found {occurrences}"
            )
        mutant_text = source_text.replace(mutation.old, mutation.new, 1)
        mutant_dir = scratch / mutation.name
        mutant_dir.mkdir(parents=True)
        mutant_path = mutant_dir / "OooLoadQueue.v"
        mutant_path.write_text(mutant_text, encoding="utf-8")
        build_dir = mutant_dir / "build"
        result_dir = mutant_dir / "result"
        log_path = result_dir / "logs/tb_ooo_load_queue.log"
        command = [
            "make",
            "-B",
            "-C",
            str(TB_DIR),
            f"BUILD_DIR={build_dir}",
            f"RESULT_DIR={result_dir}",
            f"RTL_OOO_LOAD_QUEUE={mutant_path}",
            str(log_path),
        ]
        completed = subprocess.run(
            command,
            cwd=REPO_ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        log_text = log_path.read_text(encoding="utf-8", errors="replace") \
            if log_path.exists() else completed.stdout
        vvp_path = build_dir / "tb_ooo_load_queue.vvp"
        compile_success = vvp_path.is_file()
        oracle_seen = mutation.oracle in log_text
        dynamic_rejected = completed.returncode != 0 and "[RESULT] FAIL" in log_text
        passed = compile_success and oracle_seen and dynamic_rejected
        results.append(
            {
                "name": mutation.name,
                "contract": mutation.contract,
                "oracle": mutation.oracle,
                "compile_success": compile_success,
                "oracle_seen": oracle_seen,
                "dynamic_rejected": dynamic_rejected,
                "passed": passed,
                "make_returncode": completed.returncode,
                "mutant_sha256": sha256_bytes(mutant_text.encode("utf-8")),
                "diagnostic_lines": [
                    line
                    for line in log_text.splitlines()
                    if mutation.oracle in line or "[RESULT]" in line
                ],
            }
        )

    payload = {
        "schema_version": "rv64-lq-mutation-evidence-v1",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "source": str(SOURCE.relative_to(REPO_ROOT)),
        "source_sha256": sha256_bytes(source_bytes),
        "testbench": "npc/rv64/testbench/tests/tb_ooo_load_queue.sv",
        "mutation_count": len(results),
        "compile_success_count": sum(bool(r["compile_success"]) for r in results),
        "dynamic_rejected_count": sum(bool(r["dynamic_rejected"]) for r in results),
        "passed_count": sum(bool(r["passed"]) for r in results),
        "all_passed": all(bool(r["passed"]) for r in results),
        "results": results,
    }
    json_path = RUN_DIR / "mutation-results.json"
    json_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

    rows = [
        "# OOO-3 LQ compile-success mutation results",
        "",
        f"- source SHA-256: `{payload['source_sha256']}`",
        f"- mutations: `{payload['passed_count']}/{payload['mutation_count']}` rejected by dynamic hardware oracles",
        f"- all passed: `{str(payload['all_passed']).lower()}`",
        "",
        "| Mutation | Compile | Dynamic reject | Exact oracle | Result |",
        "| --- | --- | --- | --- | --- |",
    ]
    for result in results:
        rows.append(
            "| {name} | {compile} | {reject} | `{oracle}` | {passed} |".format(
                name=result["name"],
                compile="PASS" if result["compile_success"] else "FAIL",
                reject="PASS" if result["dynamic_rejected"] else "FAIL",
                oracle=result["oracle"],
                passed="PASS" if result["passed"] else "FAIL",
            )
        )
    (RUN_DIR / "mutation-results.md").write_text(
        "\n".join(rows) + "\n", encoding="utf-8"
    )

    print(json.dumps({
        "scratch": str(scratch),
        "all_passed": payload["all_passed"],
        "passed": payload["passed_count"],
        "total": payload["mutation_count"],
        "evidence": str(json_path),
    }))
    return 0 if payload["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
