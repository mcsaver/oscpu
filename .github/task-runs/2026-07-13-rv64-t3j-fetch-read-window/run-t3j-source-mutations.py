#!/usr/bin/env python3
"""Mutation ratchet for the T3J source contract and finite-domain proof."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
import subprocess
import sys
import tempfile

from t3j_verilog_contract import (
    ContractError,
    T3JSource,
    parse_expr,
    replace_located,
    require,
    source_paths,
)


MARKER = "[T3J-SOURCE-MUTATIONS]"
TASK_DIR = Path(__file__).resolve().parent
CHECKER = TASK_DIR / "check-t3j-source-contract.py"
PROOF = TASK_DIR / "prove-t3j-window-domain.py"


BRIDGE_FIXTURE = r'''
module OooFetchAxiBridge;
  localparam [3:0] S_IDLE = 4'd0;
  localparam [3:0] S_R0 = 4'd4;
  localparam [3:0] S_RESP = 4'd7;
  localparam [3:0] S_LOOKUP = 4'd9;
  reg [3:0] state_q;
  wire fetch_req_fire_w = fetch_req_valid_i && fetch_req_ready_o;
  wire lookup_hit_resp_w = (state_q == S_LOOKUP) && cache_hit_fusion_w;
  assign fetch_req_ready_o = !mmu_flush_i &&
      ((state_q == S_IDLE) ||
       ((state_q == S_RESP) && fetch_rsp_ready_i) ||
       (lookup_hit_resp_w && fetch_rsp_ready_i));
  wire fetch_cache_fill_complete_w =
      (state_q == S_R0) && ifu_axi_rvalid_i &&
      (ifu_axi_rresp_i == RESP_OK) &&
      !fetch_more_after_r_w && !packet_cross_page_q;
  wire fetch_cache_fill_valid_w = fetch_cache_fill_complete_w;
  wire fetch_cache_read_window_w =
      (state_q == S_IDLE) || (state_q == S_RESP) ||
      (state_q == S_LOOKUP);
  OooFetchPacketCache u_fetch_packet_cache (
    .lookup_read_en_i(fetch_cache_read_window_w),
    .lookup_en_i(fetch_req_fire_w),
    .fill_valid_i(fetch_cache_fill_valid_w)
  );
endmodule
'''


CACHE_FIXTURE = r'''
module OooFetchPacketCache (
  input clk,
  input rst,
  input lookup_read_en_i,
  input lookup_en_i,
  input fill_valid_i
);
  reg dec_en_q;
  reg lkp_paging_q;
  reg [1:0] lkp_priv_q;
  reg [63:0] lkp_satp_q;
  reg [63:0] lkp_pc_q;
  reg [11:0] lkp_idx_q;
  wire [11:0] lookup_idx_w = entry_index(lookup_pc_i[INDEX_W:1]);
  wire [11:0] fill_idx_w = entry_index(fill_pc_i[INDEX_W:1]);
  wire sram_we_w = fill_valid_i && !fill_invalidated_w;
  wire sram_en_w = lookup_read_en_i || sram_we_w;
  wire [11:0] sram_addr_w =
      {SRAM_ADDR_W{1'b0}} | (sram_we_w ? fill_idx_w : lookup_idx_w);
  Sram4096x199 u_payload_sram (
    .en_i(sram_en_w),
    .we_i(sram_we_w),
    .addr_i(sram_addr_w)
  );
  always @(posedge clk) begin
    if (rst) begin
      dec_en_q <= 1'b0;
    end else begin
      dec_en_q <= lookup_en_i;
    end
    if (lookup_en_i) begin
      lkp_paging_q <= lookup_paging_i;
      lkp_priv_q <= lookup_priv_i;
      lkp_satp_q <= lookup_satp_i;
      lkp_pc_q <= lookup_pc_i;
      lkp_idx_q <= lookup_idx_w;
    end
  end
  always @(posedge clk) begin
    if (lookup_en_i && !lookup_read_en_i)
      $error("[FPC-ACCEPT-REQUIRES-READ]");
    if (lookup_read_en_i && sram_we_w)
      $error("[CONTRACT-FPC-1RW]");
  end
endmodule
'''


@dataclass(frozen=True)
class GateResult:
    returncode: int
    output: str


def run_gate(script: Path, bridge: Path, cache: Path) -> GateResult:
    result = subprocess.run(
        [sys.executable, str(script), "--bridge", str(bridge), "--cache", str(cache)],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    return GateResult(result.returncode, result.stdout)


def require_baseline(bridge: Path, cache: Path) -> None:
    for script, label in ((CHECKER, "structure"), (PROOF, "proof")):
        result = run_gate(script, bridge, cache)
        require(
            result.returncode == 0,
            "E_MUTATION_BASELINE",
            f"{label} baseline must pass before mutations; rc={result.returncode}\n{result.output}",
        )
        print(result.output.rstrip())


def expected_rejection(
    name: str,
    bridge_source: str,
    cache_source: str,
    work_dir: Path,
    expectations: tuple[tuple[Path, str], ...],
    expected_passes: tuple[Path, ...] = (),
) -> None:
    case_dir = work_dir / name
    case_dir.mkdir()
    bridge = case_dir / "OooFetchAxiBridge.v"
    cache = case_dir / "OooFetchPacketCache.v"
    bridge.write_text(bridge_source, encoding="utf-8")
    cache.write_text(cache_source, encoding="utf-8")
    for script, expected_code in expectations:
        result = run_gate(script, bridge, cache)
        count = result.output.count(expected_code)
        require(
            result.returncode != 0 and count == 1,
            "E_MUTATION_NOT_REJECTED",
            f"{name}: {script.name} expected one {expected_code}; rc={result.returncode} count={count}\n{result.output}",
        )
    for script in expected_passes:
        result = run_gate(script, bridge, cache)
        require(
            result.returncode == 0,
            "E_MUTATION_UNEXPECTED_LOGIC_RED",
            f"{name}: {script.name} was expected to stay green; rc={result.returncode}\n{result.output}",
        )
    print(
        f"[T3J-MUTATION-{name.upper().replace('-', '_')}] PASS "
        f"expected_failures={len(expectations)} expected_passes={len(expected_passes)}"
    )


def execute_mutations(bridge: Path, cache: Path, work_dir: Path) -> int:
    base = T3JSource.load(bridge, cache)
    bridge_source = base.bridge.source
    cache_source = base.cache.source
    _window, window_location = base.resolved_bridge_port("lookup_read_en_i")

    missing_lookup = replace_located(
        bridge_source,
        window_location,
        "(state_q == S_IDLE) || (state_q == S_RESP)",
    )
    expected_rejection(
        "missing-lookup",
        missing_lookup,
        cache_source,
        work_dir,
        (
            (CHECKER, "E_BRIDGE_READ_WINDOW_EXACT"),
            (PROOF, "E_FIRE_REQUIRES_WINDOW"),
        ),
    )

    missing_resp = replace_located(
        bridge_source,
        window_location,
        "(state_q == S_IDLE) || (state_q == S_LOOKUP)",
    )
    expected_rejection(
        "missing-resp",
        missing_resp,
        cache_source,
        work_dir,
        (
            (CHECKER, "E_BRIDGE_READ_WINDOW_EXACT"),
            (PROOF, "E_FIRE_REQUIRES_WINDOW"),
        ),
    )

    # 这是纯时序回退：read_window=fire 仍满足 fire=>read 及 1RW 互斥，功能证明可绿；
    # 但重新把 SRAM en 接回长 fire 锥，exact 三态 source gate 必须独立报红。
    read_window_is_fire = replace_located(
        bridge_source,
        window_location,
        "fetch_req_fire_w",
    )
    expected_rejection(
        "read-window-is-fire",
        read_window_is_fire,
        cache_source,
        work_dir,
        ((CHECKER, "E_BRIDGE_READ_WINDOW_EXACT"),),
        (PROOF,),
    )

    read_connection = base.bridge_port("lookup_read_en_i")
    semantic_connection = base.bridge_port("lookup_en_i")
    semantic_uses_window = replace_located(
        bridge_source,
        semantic_connection,
        read_connection.text.strip(),
    )
    expected_rejection(
        "semantic-accept-uses-window",
        semantic_uses_window,
        cache_source,
        work_dir,
        (
            (CHECKER, "E_BRIDGE_SEMANTIC_LOOKUP"),
            (PROOF, "E_SEMANTIC_LOOKUP_EQ_FIRE"),
        ),
    )

    includes_fill = replace_located(
        bridge_source,
        window_location,
        "(state_q == S_IDLE) || (state_q == S_RESP) || "
        "(state_q == S_LOOKUP) || (state_q == S_R0)",
    )
    expected_rejection(
        "read-window-includes-fill",
        includes_fill,
        cache_source,
        work_dir,
        (
            (CHECKER, "E_BRIDGE_READ_WINDOW_EXACT"),
            (PROOF, "E_READ_WRITE_MUTEX"),
        ),
    )

    sram_enable_location = base.cache_assignment("sram_en_w")
    sram_enable_and = replace_located(
        cache_source,
        sram_enable_location,
        "lookup_read_en_i && sram_we_w",
    )
    expected_rejection(
        "sram-enable-and",
        bridge_source,
        sram_enable_and,
        work_dir,
        ((CHECKER, "E_CACHE_SRAM_ENABLE_EXACT"),),
    )

    dec_semantic_assignment = next(
        located
        for _position, located in base.cache.nonblocking_assignments("dec_en_q")
        if parse_expr(located.text).op == "id"
        and parse_expr(located.text).args[0] == "lookup_en_i"
    )
    dec_uses_read_window = replace_located(
        cache_source,
        dec_semantic_assignment,
        "lookup_read_en_i",
    )
    expected_rejection(
        "decision-enable-uses-read-window",
        bridge_source,
        dec_uses_read_window,
        work_dir,
        ((CHECKER, "E_CACHE_DECISION_ENABLE"),),
    )

    lookup_index_location = base.cache_assignment("lookup_idx_w")
    lookup_index_from_latched_pc = replace_located(
        cache_source,
        lookup_index_location,
        "entry_index(lkp_pc_q[INDEX_W:1])",
    )
    expected_rejection(
        "lookup-index-from-latched-pc",
        bridge_source,
        lookup_index_from_latched_pc,
        work_dir,
        ((CHECKER, "E_CACHE_LOOKUP_INDEX_SOURCE"),),
    )

    sram_address_location = base.cache_assignment("sram_addr_w")
    swapped_address_arms = replace_located(
        cache_source,
        sram_address_location,
        "{SRAM_ADDR_W{1'b0}} | "
        "(sram_we_w ? lookup_idx_w : fill_idx_w)",
    )
    expected_rejection(
        "swapped-address-arms",
        bridge_source,
        swapped_address_arms,
        work_dir,
        ((CHECKER, "E_CACHE_SRAM_ADDRESS_SOURCE"),),
    )
    return 9


def parse_args() -> argparse.Namespace:
    default_root = Path(__file__).resolve().parents[3]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo_root", nargs="?", type=Path, default=default_root)
    parser.add_argument("--bridge", type=Path)
    parser.add_argument("--cache", type=Path)
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="run against an embedded known-good minimal source fixture",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    root = args.repo_root.resolve()
    try:
        with tempfile.TemporaryDirectory(prefix=".t3j-source-mutation-", dir=TASK_DIR) as temporary:
            work_dir = Path(temporary)
            if args.self_test:
                base_dir = work_dir / "base"
                base_dir.mkdir()
                bridge = base_dir / "OooFetchAxiBridge.v"
                cache = base_dir / "OooFetchPacketCache.v"
                bridge.write_text(BRIDGE_FIXTURE, encoding="utf-8")
                cache.write_text(CACHE_FIXTURE, encoding="utf-8")
            else:
                default_bridge, default_cache = source_paths(root)
                bridge = (args.bridge or default_bridge).resolve()
                cache = (args.cache or default_cache).resolve()
            require_baseline(bridge, cache)
            count = execute_mutations(bridge, cache, work_dir)
    except (ContractError, OSError) as error:
        code = error.code if isinstance(error, ContractError) else "E_IO"
        print(f"{MARKER} FAIL {code}: {error}", file=sys.stderr)
        raise SystemExit(1)
    print(f"{MARKER} PASS mutations={count} mode={'self-test' if args.self_test else 'rtl'}")


if __name__ == "__main__":
    main()
