#!/usr/bin/env python3
"""Exhaustively compare the T3K raw legality helper with an independent model.

The proof enumerates every 12-bit CSR address, all funct3 values, zero/nonzero
rs1, and eleven privilege/policy states.  A second phase exercises the public
main/probe routing and deliberately drives different tuples on the two ports.
"""

from __future__ import annotations

import argparse
import importlib.util
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

from t3k_csr_contract import ContractError, T3KSource, require, source_paths


MARKER = "[T3K-LEGALITY-DOMAIN-PROOF]"
RTL_MARKER = "[T3K-RTL-LEGALITY-DOMAIN]"
STATE_COUNT = 11
RAW_CASES = STATE_COUNT * 4096 * 8 * 2
ROUTING_CASES = STATE_COUNT * 4096
ISOLATION_CASES = STATE_COUNT * 4096


def load_source_validator():
    checker = Path(__file__).resolve().with_name("check-t3k-source-contract.py")
    spec = importlib.util.spec_from_file_location("t3k_source_contract_checker", checker)
    require(spec is not None and spec.loader is not None, "E_CHECKER_IMPORT", f"cannot load {checker}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.validate


validate = load_source_validator()


TESTBENCH = r'''`include "define.v"

module tb_t3k_legality_domain;
  reg csr_valid;
  reg [11:0] csr_addr;
  reg [2:0] csr_funct3;
  reg [`REG_ADDR_W-1:0] csr_rs1_idx;
  reg csr_probe_valid;
  reg [11:0] csr_probe_addr;
  reg [2:0] csr_probe_funct3;
  reg [`REG_ADDR_W-1:0] csr_probe_rs1_idx;
  wire csr_illegal;
  wire [`XLEN-1:0] csr_rdata;
  wire irq_pending;
  wire [`TRAP_CAUSE_W-1:0] irq_cause;
  wire [`XLEN-1:0] trap_target;
  wire [`XLEN-1:0] mepc;
  wire [`XLEN-1:0] ret_target;
  wire [1:0] priv_mode;
  wire [`TRAP_CAUSE_W-1:0] ecall_cause;
  wire [`XLEN-1:0] mstatus;
  wire [`XLEN-1:0] satp;
  wire svpbmt_en;
  wire [2:0] frm;
  wire [`PMP_CFG_BUS_W-1:0] pmpcfg;
  wire [`PMP_ADDR_BUS_W-1:0] pmpaddr;

  CsrFile dut (
    .clk(1'b0),
    .rst(1'b0),
    .cycle_count_enable_i(1'b0),
    .time_i({`XLEN{1'b0}}),
    .instret_inc_i(2'b00),
    .csr_valid_i(csr_valid),
    .csr_addr_i(csr_addr),
    .csr_funct3_i(csr_funct3),
    .csr_rs1_idx_i(csr_rs1_idx),
    .csr_rs1_data_i({`XLEN{1'b0}}),
    .csr_zimm_i(csr_rs1_idx),
    .csr_commit_i(1'b0),
    .csr_probe_valid_i(csr_probe_valid),
    .csr_probe_addr_i(csr_probe_addr),
    .csr_probe_funct3_i(csr_probe_funct3),
    .csr_probe_rs1_idx_i(csr_probe_rs1_idx),
    .csr_rdata_o(csr_rdata),
    .csr_illegal_o(csr_illegal),
    .fp_fflags_valid_i(1'b0),
    .fp_fflags_i(5'b00000),
    .fp_dirty_i(1'b0),
    .trap_mem_valid_i(1'b0),
    .trap_mem_pc_i({`XLEN{1'b0}}),
    .trap_mem_cause_i({`TRAP_CAUSE_W{1'b0}}),
    .trap_mem_tval_i({`XLEN{1'b0}}),
    .trap_ex_valid_i(1'b0),
    .trap_ex_pc_i({`XLEN{1'b0}}),
    .trap_ex_cause_i({`TRAP_CAUSE_W{1'b0}}),
    .trap_ex_tval_i({`XLEN{1'b0}}),
    .irq_software_i(1'b0),
    .irq_timer_i(1'b0),
    .irq_external_i(1'b0),
    .irq_pending_o(irq_pending),
    .irq_cause_o(irq_cause),
    .trap_irq_valid_i(1'b0),
    .trap_irq_pc_i({`XLEN{1'b0}}),
    .trap_irq_cause_i({`TRAP_CAUSE_W{1'b0}}),
    .mret_valid_i(1'b0),
    .sret_valid_i(1'b0),
    .trap_target_o(trap_target),
    .mepc_o(mepc),
    .ret_target_o(ret_target),
    .priv_mode_o(priv_mode),
    .ecall_cause_o(ecall_cause),
    .mstatus_o(mstatus),
    .satp_o(satp),
    .svpbmt_en_o(svpbmt_en),
    .frm_o(frm),
    .pmpcfg_o(pmpcfg),
    .pmpaddr_o(pmpaddr)
  );

  function ref_pmpcfg_known;
    input [11:0] addr;
    begin
      ref_pmpcfg_known = (addr == `CSR_PMPCFG0) || (addr == `CSR_PMPCFG2);
    end
  endfunction

  function ref_pmpaddr_known;
    input [11:0] addr;
    begin
      ref_pmpaddr_known = (addr >= `CSR_PMPADDR0) && (addr <= `CSR_PMPADDR15);
    end
  endfunction

  function ref_known;
    input [11:0] addr;
    begin
      case (addr)
        `CSR_FFLAGS, `CSR_FRM, `CSR_FCSR,
        `CSR_MVENDORID, `CSR_MARCHID, `CSR_MIMPID,
        `CSR_SSTATUS, `CSR_SIE, `CSR_STVEC, `CSR_SSCRATCH,
        `CSR_SEPC, `CSR_SCAUSE, `CSR_STVAL, `CSR_SIP,
        `CSR_SCOUNTEREN, `CSR_SATP,
        `CSR_MSTATUS, `CSR_MISA, `CSR_MEDELEG, `CSR_MIDELEG,
        `CSR_MIE, `CSR_MTVEC, `CSR_MCOUNTEREN, `CSR_MCOUNTINHIBIT,
        `CSR_MENVCFG, `CSR_PMPCFG0, `CSR_MSCRATCH, `CSR_MEPC,
        `CSR_MCAUSE, `CSR_MTVAL, `CSR_MIP, `CSR_PMPADDR0,
        `CSR_MCYCLE, `CSR_MINSTRET,
        `CSR_TSELECT, `CSR_TDATA1, `CSR_TDATA2, `CSR_TCONTROL,
        `CSR_CYCLE, `CSR_TIME, `CSR_INSTRET, `CSR_MHARTID:
          ref_known = 1'b1;
        default:
          ref_known = ref_pmpcfg_known(addr) || ref_pmpaddr_known(addr);
      endcase
    end
  endfunction

  function ref_writable;
    input [11:0] addr;
    begin
      case (addr)
        `CSR_FFLAGS, `CSR_FRM, `CSR_FCSR,
        `CSR_SSTATUS, `CSR_SIE, `CSR_STVEC, `CSR_SSCRATCH,
        `CSR_SEPC, `CSR_SCAUSE, `CSR_STVAL, `CSR_SIP,
        `CSR_SCOUNTEREN, `CSR_SATP,
        `CSR_MSTATUS, `CSR_MISA, `CSR_MEDELEG, `CSR_MIDELEG,
        `CSR_MIE, `CSR_MTVEC, `CSR_MCOUNTEREN, `CSR_MCOUNTINHIBIT,
        `CSR_MENVCFG, `CSR_PMPCFG0, `CSR_MSCRATCH, `CSR_MEPC,
        `CSR_MCAUSE, `CSR_MTVAL, `CSR_MIP, `CSR_PMPADDR0,
        `CSR_MCYCLE, `CSR_MINSTRET,
        `CSR_TSELECT, `CSR_TDATA1, `CSR_TDATA2, `CSR_TCONTROL:
          ref_writable = 1'b1;
        default:
          ref_writable = ref_pmpcfg_known(addr) || ref_pmpaddr_known(addr);
      endcase
    end
  endfunction

  function ref_counter;
    input [11:0] addr;
    begin
      case (addr)
        `CSR_CYCLE, `CSR_TIME, `CSR_INSTRET,
        `CSR_CYCLEH, `CSR_TIMEH, `CSR_INSTRETH:
          ref_counter = 1'b1;
        default:
          ref_counter = 1'b0;
      endcase
    end
  endfunction

  function [`XLEN-1:0] ref_counter_bit;
    input [11:0] addr;
    begin
      case (addr)
        `CSR_CYCLE, `CSR_CYCLEH: ref_counter_bit = `COUNTEREN_CY;
        `CSR_TIME, `CSR_TIMEH: ref_counter_bit = `COUNTEREN_TM;
        `CSR_INSTRET, `CSR_INSTRETH: ref_counter_bit = `COUNTEREN_IR;
        default: ref_counter_bit = {`XLEN{1'b0}};
      endcase
    end
  endfunction

  function ref_write_intent;
    input [2:0] funct3;
    input [`REG_ADDR_W-1:0] rs1_idx;
    reg set_clear_noop;
    begin
      set_clear_noop =
          ((funct3 == 3'b010) || (funct3 == 3'b011) ||
           (funct3 == 3'b110) || (funct3 == 3'b111)) &&
          (rs1_idx == {`REG_ADDR_W{1'b0}});
      ref_write_intent =
          (funct3 == 3'b001) || (funct3 == 3'b101) || !set_clear_noop;
    end
  endfunction

  function ref_illegal;
    input [11:0] addr;
    input [2:0] funct3;
    input [`REG_ADDR_W-1:0] rs1_idx;
    input [1:0] current_priv;
    input [`XLEN-1:0] current_mstatus;
    input [`XLEN-1:0] current_mcounteren;
    input [`XLEN-1:0] current_scounteren;
    reg counter_m_allowed;
    reg counter_s_allowed;
    reg counter_allowed;
    reg satp_tvm_illegal;
    begin
      counter_m_allowed =
          (current_mcounteren & ref_counter_bit(addr)) != {`XLEN{1'b0}};
      counter_s_allowed =
          (current_scounteren & ref_counter_bit(addr)) != {`XLEN{1'b0}};
      counter_allowed =
          !ref_counter(addr) ||
          (current_priv == `PRIV_M) ||
          ((current_priv == `PRIV_S) && counter_m_allowed) ||
          ((current_priv == `PRIV_U) && counter_m_allowed && counter_s_allowed);
      satp_tvm_illegal =
          (addr == `CSR_SATP) && (current_priv == `PRIV_S) &&
          ((current_mstatus & `MSTATUS_TVM) != {`XLEN{1'b0}});
      ref_illegal =
          !ref_known(addr) ||
          !(current_priv >= addr[9:8]) ||
          satp_tvm_illegal ||
          !counter_allowed ||
          (ref_write_intent(funct3, rs1_idx) && !ref_writable(addr));
    end
  endfunction

  reg [1:0] state_priv [0:10];
  reg [`XLEN-1:0] state_mstatus [0:10];
  reg [`XLEN-1:0] state_mcounteren [0:10];
  reg [`XLEN-1:0] state_scounteren [0:10];
  integer state_idx;
  integer addr_idx;
  integer funct3_idx;
  integer rs1_case;
  integer raw_cases;
  integer routing_cases;
  integer isolation_cases;
  reg expected_raw;
  reg expected_probe;
  reg expected_access;
  reg got_raw;

  initial begin
    csr_valid = 1'b0;
    csr_addr = 12'h000;
    csr_funct3 = 3'b000;
    csr_rs1_idx = {`REG_ADDR_W{1'b0}};
    csr_probe_valid = 1'b0;
    csr_probe_addr = 12'h000;
    csr_probe_funct3 = 3'b000;
    csr_probe_rs1_idx = {`REG_ADDR_W{1'b0}};
    raw_cases = 0;
    routing_cases = 0;
    isolation_cases = 0;

    state_priv[0] = `PRIV_M; state_mstatus[0] = 0; state_mcounteren[0] = 0; state_scounteren[0] = 0;
    state_priv[1] = `PRIV_M; state_mstatus[1] = `MSTATUS_TVM; state_mcounteren[1] = 0; state_scounteren[1] = 0;
    state_priv[2] = `PRIV_S; state_mstatus[2] = 0; state_mcounteren[2] = 0; state_scounteren[2] = 0;
    state_priv[3] = `PRIV_S; state_mstatus[3] = 0; state_mcounteren[3] = 7; state_scounteren[3] = 0;
    state_priv[4] = `PRIV_S; state_mstatus[4] = `MSTATUS_TVM; state_mcounteren[4] = 7; state_scounteren[4] = 7;
    state_priv[5] = `PRIV_U; state_mstatus[5] = 0; state_mcounteren[5] = 0; state_scounteren[5] = 0;
    state_priv[6] = `PRIV_U; state_mstatus[6] = 0; state_mcounteren[6] = 7; state_scounteren[6] = 0;
    state_priv[7] = `PRIV_U; state_mstatus[7] = 0; state_mcounteren[7] = 7; state_scounteren[7] = 7;
    state_priv[8] = `PRIV_U; state_mstatus[8] = 0; state_mcounteren[8] = 1; state_scounteren[8] = 1;
    state_priv[9] = `PRIV_U; state_mstatus[9] = 0; state_mcounteren[9] = 2; state_scounteren[9] = 2;
    state_priv[10] = `PRIV_U; state_mstatus[10] = 0; state_mcounteren[10] = 4; state_scounteren[10] = 4;

    // Exhaust the raw helper independently of either caller's valid/payload wiring.
    for (state_idx = 0; state_idx < 11; state_idx = state_idx + 1) begin
      for (addr_idx = 0; addr_idx < 4096; addr_idx = addr_idx + 1) begin
        for (funct3_idx = 0; funct3_idx < 8; funct3_idx = funct3_idx + 1) begin
          for (rs1_case = 0; rs1_case < 2; rs1_case = rs1_case + 1) begin
            expected_raw = ref_illegal(
                addr_idx[11:0], funct3_idx[2:0], rs1_case ? 5'd31 : 5'd0,
                state_priv[state_idx], state_mstatus[state_idx],
                state_mcounteren[state_idx], state_scounteren[state_idx]);
            got_raw = dut.csr_access_illegal_raw(
                addr_idx[11:0], funct3_idx[2:0], rs1_case ? 5'd31 : 5'd0,
                state_priv[state_idx], state_mstatus[state_idx],
                state_mcounteren[state_idx], state_scounteren[state_idx]);
            raw_cases = raw_cases + 1;
            if (got_raw !== expected_raw) begin
              $display("[T3K-RAW-REFERENCE-MISMATCH] state=%0d addr=%03h funct3=%0d rs1=%0d got=%b exp=%b",
                       state_idx, addr_idx[11:0], funct3_idx, rs1_case ? 31 : 0,
                       got_raw, expected_raw);
              $finish(1);
            end
          end
        end
      end
    end

    // Exercise both public call sites.  The second sample deliberately gives
    // main access and probe different tuples, proving no accidental cross-wire.
    csr_valid = 1'b1;
    csr_probe_valid = 1'b1;
    for (state_idx = 0; state_idx < 11; state_idx = state_idx + 1) begin
      force dut.priv_mode_q = state_priv[state_idx];
      force dut.csr_mstatus_q = state_mstatus[state_idx];
      force dut.csr_mcounteren_q = state_mcounteren[state_idx];
      force dut.csr_scounteren_q = state_scounteren[state_idx];
      for (addr_idx = 0; addr_idx < 4096; addr_idx = addr_idx + 1) begin
        csr_addr = addr_idx[11:0];
        csr_funct3 = addr_idx[2:0];
        csr_rs1_idx = addr_idx[3] ? 5'd31 : 5'd0;
        csr_probe_addr = csr_addr;
        csr_probe_funct3 = csr_funct3;
        csr_probe_rs1_idx = csr_rs1_idx;
        #1;
        expected_raw = ref_illegal(
            csr_addr, csr_funct3, csr_rs1_idx,
            state_priv[state_idx], state_mstatus[state_idx],
            state_mcounteren[state_idx], state_scounteren[state_idx]);
        routing_cases = routing_cases + 1;
        if ((dut.csr_access_illegal_w !== expected_raw) ||
            (csr_illegal !== expected_raw)) begin
          $display("[T3K-CALLER-EQUIV-MISMATCH] state=%0d addr=%03h main=%b probe=%b exp=%b",
                   state_idx, csr_addr, dut.csr_access_illegal_w,
                   csr_illegal, expected_raw);
          $finish(1);
        end

        csr_addr = addr_idx[11:0] ^ 12'hfff;
        csr_funct3 = ~addr_idx[2:0];
        csr_rs1_idx = addr_idx[3] ? 5'd0 : 5'd31;
        #1;
        expected_access = ref_illegal(
            csr_addr, csr_funct3, csr_rs1_idx,
            state_priv[state_idx], state_mstatus[state_idx],
            state_mcounteren[state_idx], state_scounteren[state_idx]);
        expected_probe = ref_illegal(
            csr_probe_addr, csr_probe_funct3, csr_probe_rs1_idx,
            state_priv[state_idx], state_mstatus[state_idx],
            state_mcounteren[state_idx], state_scounteren[state_idx]);
        isolation_cases = isolation_cases + 1;
        if ((dut.csr_access_illegal_w !== expected_access) ||
            (csr_illegal !== expected_probe)) begin
          $display("[T3K-CALLER-ISOLATION-MISMATCH] state=%0d access_addr=%03h probe_addr=%03h main=%b/%b probe=%b/%b",
                   state_idx, csr_addr, csr_probe_addr,
                   dut.csr_access_illegal_w, expected_access,
                   csr_illegal, expected_probe);
          $finish(1);
        end
      end
      release dut.priv_mode_q;
      release dut.csr_mstatus_q;
      release dut.csr_mcounteren_q;
      release dut.csr_scounteren_q;
    end

    csr_valid = 1'b0;
    csr_probe_valid = 1'b0;
    #1;
    if ((dut.csr_access_illegal_w !== 1'b0) || (csr_illegal !== 1'b0)) begin
      $display("[T3K-VALID-GATE-MISMATCH] main=%b probe=%b",
               dut.csr_access_illegal_w, csr_illegal);
      $finish(1);
    end

    $display("[T3K-RTL-LEGALITY-DOMAIN] PASS raw_cases=%0d routing_cases=%0d isolation_cases=%0d valid_gate_cases=2",
             raw_cases, routing_cases, isolation_cases);
    $finish;
  end
endmodule
'''


def parse_args() -> argparse.Namespace:
    default_root = Path(__file__).resolve().parents[3]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo_root", nargs="?", type=Path, default=default_root)
    parser.add_argument("--mux", type=Path)
    parser.add_argument("--control", type=Path)
    parser.add_argument("--glue", type=Path)
    parser.add_argument("--top", type=Path)
    parser.add_argument("--csr", type=Path)
    parser.add_argument("--iverilog", type=Path)
    parser.add_argument("--vvp", type=Path)
    return parser.parse_args()


def tool_path(override: Path | None, name: str) -> str:
    if override is not None:
        require(override.is_file(), "E_TOOL", f"{name} override is not a regular file: {override}")
        return str(override.resolve())
    resolved = shutil.which(name)
    require(resolved is not None, "E_TOOL", f"required tool not found on PATH: {name}")
    return resolved


def run_proof(root: Path, paths: tuple[Path, ...], iverilog: str, vvp: str) -> str:
    validate(T3KSource.load(*paths))
    csr = paths[4]
    with tempfile.TemporaryDirectory(prefix="t3k-legality-domain-") as temporary:
        temp = Path(temporary)
        testbench = temp / "tb_t3k_legality_domain.sv"
        binary = temp / "proof.vvp"
        testbench.write_text(TESTBENCH, encoding="utf-8")
        compile_result = subprocess.run(
            [
                iverilog,
                "-g2012",
                "-Wall",
                "-s",
                "tb_t3k_legality_domain",
                "-I",
                str(root / "npc/rv64/vsrc"),
                "-I",
                str(root / "npc/rv64/vsrc/include"),
                "-o",
                str(binary),
                str(csr),
                str(testbench),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        require(
            compile_result.returncode == 0,
            "E_PROOF_COMPILE",
            f"iverilog failed rc={compile_result.returncode}:\n{compile_result.stdout}",
        )
        run_result = subprocess.run(
            [vvp, str(binary)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        require(
            run_result.returncode == 0,
            "E_PROOF_RUNTIME",
            f"vvp failed rc={run_result.returncode}:\n{run_result.stdout}",
        )
        fail_markers = re.findall(r"\[T3K-[^]]*(?:FAIL|MISMATCH)[^]]*\]", run_result.stdout)
        require(not fail_markers, "E_PROOF_FAIL_MARKER", f"runtime emitted fail markers: {fail_markers}")
        matches = re.findall(
            rf"^{re.escape(RTL_MARKER)} PASS raw_cases=(\d+) routing_cases=(\d+) "
            r"isolation_cases=(\d+) valid_gate_cases=(\d+)$",
            run_result.stdout,
            flags=re.MULTILINE,
        )
        require(len(matches) == 1, "E_PROOF_PASS_MARKER", f"expected one exact RTL PASS marker:\n{run_result.stdout}")
        counts = tuple(int(value) for value in matches[0])
        require(
            counts == (RAW_CASES, ROUTING_CASES, ISOLATION_CASES, 2),
            "E_PROOF_CASE_COUNT",
            f"proof case counts differ: actual={counts} expected={(RAW_CASES, ROUTING_CASES, ISOLATION_CASES, 2)}",
        )
        return run_result.stdout.strip()


def main() -> None:
    args = parse_args()
    root = args.repo_root.resolve()
    defaults = source_paths(root)
    paths = tuple(
        (override or default).resolve()
        for override, default in zip(
            (args.mux, args.control, args.glue, args.top, args.csr),
            defaults,
        )
    )
    try:
        output = run_proof(root, paths, tool_path(args.iverilog, "iverilog"), tool_path(args.vvp, "vvp"))
    except (ContractError, OSError, UnicodeError) as error:
        code = error.code if isinstance(error, ContractError) else "E_IO"
        print(f"{MARKER} FAIL {code}: {error}", file=sys.stderr)
        raise SystemExit(1)
    print(output)
    print(
        f"{MARKER} PASS raw_cases={RAW_CASES} routing_cases={ROUTING_CASES} "
        f"isolation_cases={ISOLATION_CASES} valid_gate_cases=2"
    )


if __name__ == "__main__":
    main()
