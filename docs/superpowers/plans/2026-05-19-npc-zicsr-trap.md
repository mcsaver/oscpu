# NPC Zicsr Trap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring `npc/single` to the first-stage NEMU-compatible RV32I + Zicsr machine trap loop without introducing a pipeline yet.

**Architecture:** Keep the current one-in-flight multi-cycle `NpcCore` and add a small machine CSR block plus centralized trap/mret control. `ebreak + a0` remains the NPC exit protocol, while `ecall` becomes a real trap to `mtvec`; AM/NPC CTE then uses `ecall -> mtvec -> mret` for yield and kernel context switching.

**Tech Stack:** Verilog/SystemVerilog RTL, Verilator, GNU Make/Kconfig, RISC-V AM bare-metal tests, C/assembly in Abstract Machine.

---

## Scope And File Map

**Create**
- `am-kernels/tests/cpu-tests/tests/zicsr-trap.c`: focused RED/GREEN smoke for CSR read-modify-write, `ecall`, `mtvec`, and `mret`.
- `npc/single/vsrc/CSRFile.v`: machine CSR state and read/write/trap/mret update helper.
- `.github/task-runs/2026-05-19-npc-zicsr-trap/task-report.md`: task evidence and RTL derivation summary.
- `.github/task-runs/2026-05-19-npc-zicsr-trap/dispatch-log.md`: node execution log.

**Modify**
- `npc/single/vsrc/define.v:61-173`: CSR constants, CSR op encoding, new control bus fields.
- `npc/single/vsrc/DecodeUnit.v:337-358`: decode CSR, `mret`, and `wfi`.
- `npc/single/vsrc/WBU.v:1-22`: add CSR old-value writeback source.
- `npc/single/vsrc/NpcCore.v:48-409`: instantiate CSRFile, latch CSR fields, route CSR writeback, replace `ecall` halt with trap redirect, implement `mret`.
- `npc/single/Makefile:95-106`: add `CSRFile.v` to `STA_RTL_FILES`.
- `abstract-machine/am/src/riscv/npc/cte.c:1-50`: classify `EVENT_YIELD`, implement `kcontext`, support `ienabled/iset`.
- `abstract-machine/am/src/riscv/npc/trap.S:34-66`: align `Context` restore with returned context pointer.
- `.github/memory/project-status.md`: record final outcome.
- `.github/memory/modules/npc.md`: record stable CSR/trap implementation facts.
- `.github/memory/modules/abstract-machine.md`: record NPC CTE completion facts.

**Do Not Modify In This Plan**
- `nemu/**`: NEMU is reference input only for this stage.
- RV32M/B/C support: deferred to the next stage.
- Pipeline files: no pipeline conversion in this plan.

## RTL Generation Workflow Checkpoint

**需求:** NPC must execute RV32I + Zicsr machine-mode trap flows in a single-hart, RV32I-only, IALIGN=32 environment. `ecall` raises cause 11 to `mtvec`; `mret` returns to `mepc`; CSR instructions read old CSR value to `rd` and conditionally write a new value. `ebreak` remains the simulator exit path.

**协议规则:** Current IFU/LSU stay one-request/one-response through `NpcSimTop`. CSR operations are internal, single-cycle in `EXEC/WB`, and have no external backpressure. Trap redirect is a precise control redirect from the current instruction to `mtvec.BASE`; `mret` is a redirect to `mepc`. No async interrupt source is generated in this stage.

**状态机:** Existing `RESET -> FETCH_REQ -> FETCH_WAIT -> DECODE -> EXEC -> MEM_REQ/MEM_WAIT -> WB` remains. CSR instructions go `DECODE -> EXEC -> WB`. `ecall` goes `EXEC -> FETCH_REQ` after CSR trap entry updates. `mret` goes `EXEC -> FETCH_REQ` after CSR mret update. `ebreak` goes `EXEC -> HALT`. Fatal access/illegal traps that cannot be handled may still use `CORE_STATE_TRAP` until full exception software support is added.

**不变量:** One instruction in flight; no normal `commit_valid_o` for trap entry; x0 write remains blocked; CSR RMW reads old CSR value before write; `mepc` is current PC for `ecall`; `mret` writes no GPR and fetches from masked `mepc`; `ebreak` does not enter `mtvec`.

**数据通路约束:** CSR old value becomes a new WBU source. CSR address comes from `inst[31:20]`; zimm comes from `inst[19:15]`; CSR write data comes from `rs1_data_q` or zero-extended zimm. `mstatus` trap/mret updates are centralized in `CSRFile`. `pc_q` updates from `csr_trap_vector_w` or `csr_mepc_w` in the same state transition that performs trap/mret action.

---

### Task 1: Add Focused Zicsr Trap Smoke Test

**Files:**
- Create: `am-kernels/tests/cpu-tests/tests/zicsr-trap.c`

- [ ] **Step 1: Write the failing test**

Create `am-kernels/tests/cpu-tests/tests/zicsr-trap.c` with this content:

```c
#include "trap.h"

static volatile int trap_seen = 0;
static void trap_entry(void);

static uintptr_t read_mscratch(void) {
  uintptr_t value;
  asm volatile("csrr %0, mscratch" : "=r"(value));
  return value;
}

int main() {
  uintptr_t old;
  uintptr_t value;

  asm volatile("csrw mtvec, %0" : : "r"(trap_entry));

  asm volatile("csrrw %0, mscratch, %1" : "=r"(old) : "r"(0x12345000));
  value = read_mscratch();
  check(value == 0x12345000);

  asm volatile("csrrs %0, mscratch, %1" : "=r"(old) : "r"(0x0000000f));
  check(old == 0x12345000);
  value = read_mscratch();
  check(value == 0x1234500f);

  asm volatile("csrrc %0, mscratch, %1" : "=r"(old) : "r"(0x00000003));
  check(old == 0x1234500f);
  value = read_mscratch();
  check(value == 0x1234500c);

  asm volatile("li a7, -1; ecall");
  check(trap_seen == 1);

  return 0;
}

__attribute__((naked, aligned(4)))
static void trap_entry(void) {
  asm volatile(
    "addi sp, sp, -16\n"
    "sw t0, 0(sp)\n"
    "sw t1, 4(sp)\n"
    "csrr t0, mcause\n"
    "li t1, 11\n"
    "bne t0, t1, 1f\n"
    "la t0, trap_seen\n"
    "li t1, 1\n"
    "sw t1, 0(t0)\n"
    "csrr t0, mepc\n"
    "addi t0, t0, 4\n"
    "csrw mepc, t0\n"
    "1:\n"
    "lw t1, 4(sp)\n"
    "lw t0, 0(sp)\n"
    "addi sp, sp, 16\n"
    "mret\n"
  );
}
```

- [ ] **Step 2: Verify the reference path passes**

Run:

```bash
make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu ALL=zicsr-trap run
```

Expected: output contains `[   zicsr-trap] PASS`.

- [ ] **Step 3: Verify NPC is RED**

Run:

```bash
make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=zicsr-trap run NPC_RUN_ARGS='--max-cycles 2000000 --no-progress'
```

Expected before RTL changes: output contains `[   zicsr-trap] ***FAIL***`. Acceptable RED causes are illegal instruction on `csrw mtvec` or premature halt/trap caused by unsupported `ecall/mret`.

- [ ] **Step 4: Commit the RED test**

```bash
git add am-kernels/tests/cpu-tests/tests/zicsr-trap.c
git commit -m "test: add npc zicsr trap smoke"
```

### Task 2: Extend Decode Constants And Control Bus

**Files:**
- Modify: `npc/single/vsrc/define.v:61-173`
- Modify: `npc/single/vsrc/DecodeUnit.v:337-358`

- [ ] **Step 1: Add CSR and system constants**

In `npc/single/vsrc/define.v`, after `SYSTEM_FUNCT12_EBREAK`, add:

```verilog
`define SYSTEM_FUNCT12_MRET    12'h302
`define SYSTEM_FUNCT12_WFI     12'h105

`define CSR_ADDR_W             12
`define CSR_MSTATUS            12'h300
`define CSR_MISA               12'h301
`define CSR_MIE                12'h304
`define CSR_MTVEC              12'h305
`define CSR_MSCRATCH           12'h340
`define CSR_MEPC               12'h341
`define CSR_MCAUSE             12'h342
`define CSR_MTVAL              12'h343
`define CSR_MIP                12'h344
`define CSR_MHARTID            12'hf14

`define MSTATUS_MIE_BIT        3
`define MSTATUS_MPIE_BIT       7
`define MSTATUS_MPP_LSB        11
`define MSTATUS_MPP_MSB        12
`define MSTATUS_MPP_M          2'b11

`define CSR_OP_NONE            3'b000
`define CSR_OP_RW              3'b001
`define CSR_OP_RS              3'b010
`define CSR_OP_RC              3'b011
```

- [ ] **Step 2: Add CSR writeback source**

In `npc/single/vsrc/define.v`, after `WB_SEL_IMM`, add:

```verilog
`define WB_SEL_CSR         3'b101  // 写回 CSR 指令读到的旧值
```

- [ ] **Step 3: Append control-bus fields**

Replace the last control field block in `npc/single/vsrc/define.v` from `CTRL_SYSTEM_BIT` through `CTRL_BUS_W` with:

```verilog
`define CTRL_SYSTEM_BIT          36  // 是否属于 system 指令族
`define CTRL_MISC_MEM_BIT        37  // 是否属于 misc-mem 指令族
`define CTRL_CSR_EN_BIT          38  // 是否为 Zicsr 指令
`define CTRL_CSR_OP_LSB          39  // CSR 读改写操作字段低位
`define CTRL_CSR_OP_MSB          41  // CSR 读改写操作字段高位
`define CTRL_CSR_IMM_BIT         42  // CSR 源操作数是否来自 zimm
`define CTRL_MRET_BIT            43  // 是否为 mret
`define CTRL_WFI_BIT             44  // 是否为 wfi；当前实现视为合法 no-op
`define CTRL_BUS_W               45  // 统一控制总线总宽度
```

- [ ] **Step 4: Decode CSR forms**

In `npc/single/vsrc/DecodeUnit.v`, replace the entire `OPCODE_SYSTEM` case at lines 337-358 with:

```verilog
      `OPCODE_SYSTEM: begin
        ctrl_o[`CTRL_SYSTEM_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b1;

        if (funct3_w == `FUNCT3_ADD_SUB) begin
          if ((rs1_idx_o == {`REG_ADDR_W{1'b0}}) &&
              (rd_idx_o == {`REG_ADDR_W{1'b0}})) begin
            case (funct12_w)
              `SYSTEM_FUNCT12_ECALL: begin
                ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
                ctrl_o[`CTRL_ECALL_BIT] = 1'b1;
              end
              `SYSTEM_FUNCT12_EBREAK: begin
                ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
                ctrl_o[`CTRL_EBREAK_BIT] = 1'b1;
              end
              `SYSTEM_FUNCT12_MRET: begin
                ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
                ctrl_o[`CTRL_MRET_BIT] = 1'b1;
              end
              `SYSTEM_FUNCT12_WFI: begin
                ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
                ctrl_o[`CTRL_WFI_BIT] = 1'b1;
              end
              default: begin
                ctrl_o[`CTRL_SYSTEM_BIT] = 1'b0;
                ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b0;
              end
            endcase
          end else begin
            ctrl_o[`CTRL_SYSTEM_BIT] = 1'b0;
            ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b0;
          end
        end else begin
          case (funct3_w)
            3'b001, 3'b010, 3'b011, 3'b101, 3'b110, 3'b111: begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_CSR_EN_BIT] = 1'b1;
              ctrl_o[`CTRL_RD_EN_BIT] = 1'b1;
              ctrl_o[`CTRL_NEED_WB_BIT] = 1'b1;
              ctrl_o[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_CSR;
              ctrl_o[`CTRL_CSR_IMM_BIT] = funct3_w[2];
              case (funct3_w[1:0])
                2'b01: ctrl_o[`CTRL_CSR_OP_MSB:`CTRL_CSR_OP_LSB] = `CSR_OP_RW;
                2'b10: ctrl_o[`CTRL_CSR_OP_MSB:`CTRL_CSR_OP_LSB] = `CSR_OP_RS;
                2'b11: ctrl_o[`CTRL_CSR_OP_MSB:`CTRL_CSR_OP_LSB] = `CSR_OP_RC;
                default: ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b1;
              endcase
              if (!funct3_w[2]) begin
                ctrl_o[`CTRL_RS1_EN_BIT] = 1'b1;
              end
            end
            default: begin
              ctrl_o[`CTRL_SYSTEM_BIT] = 1'b0;
              ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b0;
            end
          endcase
        end
      end
```

- [ ] **Step 5: Run lint**

Run:

```bash
make -C npc/single lint
```

Expected: Verilator lint reaches successful exit. If it reports width warnings caused by the enlarged control bus, fix the exact field width before continuing.

- [ ] **Step 6: Confirm smoke is still RED**

Run:

```bash
make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=zicsr-trap run NPC_RUN_ARGS='--max-cycles 2000000 --no-progress'
```

Expected: still `[   zicsr-trap] ***FAIL***`, now because CSR execution/trap redirect is not implemented, not because decode rejects CSR encodings.

- [ ] **Step 7: Commit decode changes**

```bash
git add npc/single/vsrc/define.v npc/single/vsrc/DecodeUnit.v
git commit -m "feat: decode npc zicsr system ops"
```

### Task 3: Add Machine CSR Block

**Files:**
- Create: `npc/single/vsrc/CSRFile.v`
- Modify: `npc/single/Makefile:95-106`

- [ ] **Step 1: Create `CSRFile.v`**

Create `npc/single/vsrc/CSRFile.v` with this content:

```verilog
`include "define.v"

module CSRFile (
  input clk,
  input rst,

  input [`CSR_ADDR_W-1:0] raddr_i,
  output reg [`XLEN-1:0] rdata_o,
  output reg illegal_read_o,

  input wen_i,
  input [`CSR_ADDR_W-1:0] waddr_i,
  input [`XLEN-1:0] wdata_i,
  output reg illegal_write_o,

  input trap_enter_i,
  input [`XLEN-1:0] trap_pc_i,
  input [`TRAP_CAUSE_W-1:0] trap_cause_i,
  input [`XLEN-1:0] trap_tval_i,
  output [`XLEN-1:0] trap_vector_o,

  input mret_i,
  output [`XLEN-1:0] mepc_o
);

  reg [`XLEN-1:0] mstatus_q;
  reg [`XLEN-1:0] mtvec_q;
  reg [`XLEN-1:0] mscratch_q;
  reg [`XLEN-1:0] mepc_q;
  reg [`XLEN-1:0] mcause_q;
  reg [`XLEN-1:0] mtval_q;
  reg [`XLEN-1:0] mie_q;
  reg [`XLEN-1:0] mip_q;

  wire [`XLEN-1:0] misa_value_w = 32'h4000_0100;
  wire [`XLEN-1:0] mtvec_base_w = {mtvec_q[`XLEN-1:2], 2'b00};
  wire [`XLEN-1:0] mepc_masked_w = {mepc_q[`XLEN-1:2], 2'b00};

  assign trap_vector_o = mtvec_base_w;
  assign mepc_o = mepc_masked_w;

  always @(*) begin
    illegal_read_o = 1'b0;
    case (raddr_i)
      `CSR_MSTATUS:  rdata_o = mstatus_q;
      `CSR_MISA:     rdata_o = misa_value_w;
      `CSR_MIE:      rdata_o = mie_q;
      `CSR_MTVEC:    rdata_o = mtvec_q;
      `CSR_MSCRATCH: rdata_o = mscratch_q;
      `CSR_MEPC:     rdata_o = mepc_masked_w;
      `CSR_MCAUSE:   rdata_o = mcause_q;
      `CSR_MTVAL:    rdata_o = mtval_q;
      `CSR_MIP:      rdata_o = mip_q;
      `CSR_MHARTID:  rdata_o = {`XLEN{1'b0}};
      default: begin
        rdata_o = {`XLEN{1'b0}};
        illegal_read_o = 1'b1;
      end
    endcase
  end

  always @(*) begin
    case (waddr_i)
      `CSR_MSTATUS,
      `CSR_MIE,
      `CSR_MTVEC,
      `CSR_MSCRATCH,
      `CSR_MEPC,
      `CSR_MCAUSE,
      `CSR_MTVAL,
      `CSR_MIP: illegal_write_o = 1'b0;
      default: illegal_write_o = 1'b1;
    endcase
  end

  always @(posedge clk) begin
    if (rst) begin
      mstatus_q <= {`XLEN{1'b0}};
      mtvec_q <= {`XLEN{1'b0}};
      mscratch_q <= {`XLEN{1'b0}};
      mepc_q <= {`XLEN{1'b0}};
      mcause_q <= {`XLEN{1'b0}};
      mtval_q <= {`XLEN{1'b0}};
      mie_q <= {`XLEN{1'b0}};
      mip_q <= {`XLEN{1'b0}};
    end else if (trap_enter_i) begin
      mepc_q <= {trap_pc_i[`XLEN-1:2], 2'b00};
      mcause_q <= {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, trap_cause_i};
      mtval_q <= trap_tval_i;
      mstatus_q[`MSTATUS_MPIE_BIT] <= mstatus_q[`MSTATUS_MIE_BIT];
      mstatus_q[`MSTATUS_MIE_BIT] <= 1'b0;
      mstatus_q[`MSTATUS_MPP_MSB:`MSTATUS_MPP_LSB] <= `MSTATUS_MPP_M;
    end else if (mret_i) begin
      mstatus_q[`MSTATUS_MIE_BIT] <= mstatus_q[`MSTATUS_MPIE_BIT];
      mstatus_q[`MSTATUS_MPIE_BIT] <= 1'b1;
      mstatus_q[`MSTATUS_MPP_MSB:`MSTATUS_MPP_LSB] <= 2'b00;
    end else if (wen_i && !illegal_write_o) begin
      case (waddr_i)
        `CSR_MSTATUS:  mstatus_q <= wdata_i;
        `CSR_MIE:      mie_q <= wdata_i;
        `CSR_MTVEC:    mtvec_q <= wdata_i;
        `CSR_MSCRATCH: mscratch_q <= wdata_i;
        `CSR_MEPC:     mepc_q <= {wdata_i[`XLEN-1:2], 2'b00};
        `CSR_MCAUSE:   mcause_q <= wdata_i;
        `CSR_MTVAL:    mtval_q <= wdata_i;
        `CSR_MIP:      mip_q <= wdata_i;
        default: begin
        end
      endcase
    end
  end

endmodule
```

- [ ] **Step 2: Add CSRFile to STA file list**

In `npc/single/Makefile`, add `$(abspath ./vsrc/CSRFile.v)` to `STA_RTL_FILES` between `CompareUnit.v` and `DecodeUnit.v`:

```make
	$(abspath ./vsrc/CompareUnit.v) \
	$(abspath ./vsrc/CSRFile.v) \
	$(abspath ./vsrc/DecodeUnit.v) \
```

- [ ] **Step 3: Run lint**

Run:

```bash
make -C npc/single lint
```

Expected: lint passes and includes `CSRFile.v` through the automatic `VSRCS` list.

- [ ] **Step 4: Confirm smoke is still RED**

Run:

```bash
make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=zicsr-trap run NPC_RUN_ARGS='--max-cycles 2000000 --no-progress'
```

Expected: still `[   zicsr-trap] ***FAIL***`, because `NpcCore` has not yet connected CSRFile.

- [ ] **Step 5: Commit CSR module**

```bash
git add npc/single/vsrc/CSRFile.v npc/single/Makefile
git commit -m "feat: add npc machine csr file"
```

### Task 4: Connect CSR, Trap Entry, MRET, And WBU

**Files:**
- Modify: `npc/single/vsrc/WBU.v:1-22`
- Modify: `npc/single/vsrc/NpcCore.v:48-409`

- [ ] **Step 1: Add CSR writeback source to WBU**

Replace `npc/single/vsrc/WBU.v` with:

```verilog
`include "define.v"

module WBU (
  input [2:0] wb_sel_i,
  input [`XLEN-1:0] alu_data_i,
  input [`XLEN-1:0] load_data_i,
  input [`XLEN-1:0] pc_plus4_i,
  input [`XLEN-1:0] imm_data_i,
  input [`XLEN-1:0] csr_data_i,
  output reg [`XLEN-1:0] wb_data_o
);

  // 写回源统一在这里收口，CSR 指令写回旧 CSR 值，仍由顶层统一裁决是否提交到 GPR。
  always @(*) begin
    case (wb_sel_i)
      `WB_SEL_ALU:  wb_data_o = alu_data_i;
      `WB_SEL_LOAD: wb_data_o = load_data_i;
      `WB_SEL_PC4:  wb_data_o = pc_plus4_i;
      `WB_SEL_IMM:  wb_data_o = imm_data_i;
      `WB_SEL_CSR:  wb_data_o = csr_data_i;
      default:      wb_data_o = {`XLEN{1'b0}};
    endcase
  end

endmodule
```

- [ ] **Step 2: Add CSR pipeline registers and wires in NpcCore**

In `npc/single/vsrc/NpcCore.v`, after `load_data_q`, add:

```verilog
  reg [`XLEN-1:0] csr_old_data_q;
  reg [`CSR_ADDR_W-1:0] csr_addr_q;
  reg [2:0] csr_op_q;
  reg csr_imm_q;
  reg [`REG_ADDR_W-1:0] csr_zimm_q;
```

After `ctrl_ebreak_w`, add:

```verilog
  wire ctrl_csr_en_w = ctrl_q[`CTRL_CSR_EN_BIT];
  wire ctrl_mret_w = ctrl_q[`CTRL_MRET_BIT];
  wire ctrl_wfi_w = ctrl_q[`CTRL_WFI_BIT];
```

After `ctrl_wb_sel_w`, add:

```verilog
  wire [2:0] ctrl_csr_op_w = ctrl_q[`CTRL_CSR_OP_MSB:`CTRL_CSR_OP_LSB];
  wire ctrl_csr_imm_w = ctrl_q[`CTRL_CSR_IMM_BIT];
```

After `dec_rd_idx_w`, add:

```verilog
  wire [`CSR_ADDR_W-1:0] dec_csr_addr_w = inst_q[31:20];
  wire [`REG_ADDR_W-1:0] dec_csr_zimm_w = inst_q[19:15];
```

- [ ] **Step 3: Add CSR combinational datapath in NpcCore**

Before `DecodeUnit u_decode`, add:

```verilog
  wire [`XLEN-1:0] csr_rdata_w;
  wire csr_illegal_read_w;
  wire csr_illegal_write_w;
  wire [`XLEN-1:0] csr_src_w = csr_imm_q ? {{(`XLEN-`REG_ADDR_W){1'b0}}, csr_zimm_q} : rs1_data_q;
  wire csr_write_need_w = ctrl_csr_en_w &&
                          ((csr_op_q == `CSR_OP_RW) ||
                           ((csr_op_q == `CSR_OP_RS) && (csr_src_w != {`XLEN{1'b0}})) ||
                           ((csr_op_q == `CSR_OP_RC) && (csr_src_w != {`XLEN{1'b0}})));
  reg [`XLEN-1:0] csr_wdata_r;

  always @(*) begin
    case (csr_op_q)
      `CSR_OP_RW: csr_wdata_r = csr_src_w;
      `CSR_OP_RS: csr_wdata_r = csr_rdata_w | csr_src_w;
      `CSR_OP_RC: csr_wdata_r = csr_rdata_w & ~csr_src_w;
      default:    csr_wdata_r = csr_rdata_w;
    endcase
  end

  wire csr_trap_enter_w = (state_q == `CORE_STATE_EXEC) && ctrl_ecall_w;
  wire csr_mret_enter_w = (state_q == `CORE_STATE_EXEC) && ctrl_mret_w;
  wire [`XLEN-1:0] csr_trap_vector_w;
  wire [`XLEN-1:0] csr_mepc_w;
```

- [ ] **Step 4: Instantiate CSRFile**

After the `RegisterFile` instance and before `ALU`, add:

```verilog
  CSRFile u_csrfile (
    .clk(clk),
    .rst(rst),
    .raddr_i((state_q == `CORE_STATE_DECODE) ? dec_csr_addr_w : csr_addr_q),
    .rdata_o(csr_rdata_w),
    .illegal_read_o(csr_illegal_read_w),
    .wen_i((state_q == `CORE_STATE_WB) && csr_write_need_w),
    .waddr_i(csr_addr_q),
    .wdata_i(csr_wdata_r),
    .illegal_write_o(csr_illegal_write_w),
    .trap_enter_i(csr_trap_enter_w),
    .trap_pc_i(pc_q),
    .trap_cause_i(`EXC_ECALL_MMODE),
    .trap_tval_i({`XLEN{1'b0}}),
    .trap_vector_o(csr_trap_vector_w),
    .mret_i(csr_mret_enter_w),
    .mepc_o(csr_mepc_w)
  );
```

- [ ] **Step 5: Pass CSR data into WBU**

Update the `WBU u_wbu` instance by adding:

```verilog
    .csr_data_i(csr_old_data_q),
```

between `.imm_data_i(wb_imm_data_w),` and `.wb_data_o(wb_data_w)`.

- [ ] **Step 6: Reset CSR pipeline registers**

In the reset branch of `NpcCore`, after `load_data_q <= ...`, add:

```verilog
      csr_old_data_q <= {`XLEN{1'b0}};
      csr_addr_q <= {`CSR_ADDR_W{1'b0}};
      csr_op_q <= `CSR_OP_NONE;
      csr_imm_q <= 1'b0;
      csr_zimm_q <= {`REG_ADDR_W{1'b0}};
```

- [ ] **Step 7: Latch CSR metadata in DECODE**

In `CORE_STATE_DECODE`, after `rd_idx_q <= dec_rd_idx_w;`, add:

```verilog
          csr_addr_q <= dec_csr_addr_w;
          csr_op_q <= dec_ctrl_w[`CTRL_CSR_OP_MSB:`CTRL_CSR_OP_LSB];
          csr_imm_q <= dec_ctrl_w[`CTRL_CSR_IMM_BIT];
          csr_zimm_q <= dec_csr_zimm_w;
          csr_old_data_q <= csr_rdata_w;
```

Then extend the illegal decode check:

```verilog
          if (dec_ctrl_w[`CTRL_ILLEGAL_BIT] ||
              (dec_ctrl_w[`CTRL_CSR_EN_BIT] && csr_illegal_read_w)) begin
```

- [ ] **Step 8: Replace ECALL halt with trap redirect**

In `CORE_STATE_EXEC`, replace the `ctrl_ecall_w` branch at lines 316-323 with:

```verilog
          if (ctrl_ecall_w) begin
            // ecall 必须进入 mtvec，让 AM CTE 可以通过 trap.S 保存现场再 mret 返回。
            trap_cause_q <= `EXC_ECALL_MMODE;
            trap_pc_q <= pc_q;
            trap_tval_q <= {`XLEN{1'b0}};
            exit_is_ecall_q <= 1'b0;
            exit_is_ebreak_q <= 1'b0;
            pc_q <= csr_trap_vector_w;
            next_pc_q <= csr_trap_vector_w;
            state_q <= `CORE_STATE_FETCH_REQ;
          end else if (ctrl_mret_w) begin
            pc_q <= csr_mepc_w;
            next_pc_q <= csr_mepc_w;
            state_q <= `CORE_STATE_FETCH_REQ;
          end else if (ctrl_csr_en_w && csr_illegal_write_w && csr_write_need_w) begin
            exit_is_ecall_q <= 1'b0;
            exit_is_ebreak_q <= 1'b0;
            trap_cause_q <= `EXC_ILLEGAL_INST;
            trap_pc_q <= pc_q;
            trap_tval_q <= inst_q;
            state_q <= `CORE_STATE_TRAP;
          end else if (ctrl_ebreak_w) begin
            trap_cause_q <= `EXC_BREAKPOINT;
            trap_pc_q <= pc_q;
            trap_tval_q <= {`XLEN{1'b0}};
            exit_is_ecall_q <= 1'b0;
            exit_is_ebreak_q <= 1'b1;
            exit_code_q <= rf_a0_data_w;
            state_q <= `CORE_STATE_HALT;
```

Remove the old `ctrl_ebreak_w` branch that followed the original `ctrl_ecall_w` branch, because the replacement block above already contains the preserved `ebreak` exit behavior.

- [ ] **Step 9: Keep WFI as no-op**

No dedicated branch is needed for `ctrl_wfi_w`: it falls through to `CORE_STATE_WB`, and `next_pc_q` already holds `pc + 4`.

- [ ] **Step 10: Run lint**

Run:

```bash
make -C npc/single lint
```

Expected: lint passes. If Verilator reports unused `ctrl_wfi_w`, remove the separate wire and rely on the control bit through fallthrough behavior.

- [ ] **Step 11: Build NPC**

Run:

```bash
make -C npc/single
```

Expected: `npc/single/build/NpcSimTop` links successfully.

- [ ] **Step 12: Verify zicsr-trap GREEN**

Run:

```bash
make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=zicsr-trap run NPC_RUN_ARGS='--max-cycles 2000000 --no-progress'
```

Expected: `[   zicsr-trap] PASS`.

- [ ] **Step 13: Regression check RV32I smoke**

Run:

```bash
make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run NPC_RUN_ARGS='--max-cycles 2000000 --no-progress'
```

Expected: `[            add] PASS`.

- [ ] **Step 14: Commit RTL integration**

```bash
git add npc/single/vsrc/WBU.v npc/single/vsrc/NpcCore.v
git commit -m "feat: connect npc zicsr trap flow"
```

### Task 5: Align AM NPC CTE And Trap Restore

**Files:**
- Modify: `abstract-machine/am/src/riscv/npc/cte.c:1-50`
- Modify: `abstract-machine/am/src/riscv/npc/trap.S:34-66`

- [ ] **Step 1: Replace NPC CTE implementation**

Replace `abstract-machine/am/src/riscv/npc/cte.c` with the NEMU-aligned implementation:

```c
#include <am.h>
#include <riscv/riscv.h>
#include <klib.h>
#include <klib-macros.h>

#define IRQ_MASK      ((uintptr_t)1 << (__riscv_xlen - 1))
#define CAUSE_ECALL_M 11
#define CAUSE_MTI     (IRQ_MASK | 7)
#define CAUSE_MEI     (IRQ_MASK | 11)

static Context* (*user_handler)(Event, Context*) = NULL;

Context* __am_irq_handle(Context *c) {
  if (user_handler) {
    Event ev = {0};
    switch (c->mcause) {
      case CAUSE_ECALL_M:
        ev.event = (c->GPR1 == (uintptr_t)-1) ? EVENT_YIELD : EVENT_SYSCALL;
        c->mepc += 4;
        break;
      case CAUSE_MTI:
        ev.event = EVENT_IRQ_TIMER;
        break;
      case CAUSE_MEI:
        ev.event = EVENT_IRQ_IODEV;
        break;
      default:
        ev.event = EVENT_ERROR;
        ev.cause = c->mcause;
        break;
    }

    c = user_handler(ev, c);
    assert(c != NULL);
  }

  return c;
}

extern void __am_asm_trap(void);

static void __am_kcontext_on_return() {
  panic("kernel context returns");
}

bool cte_init(Context*(*handler)(Event, Context*)) {
  asm volatile("csrw mtvec, %0" : : "r"(__am_asm_trap));
  user_handler = handler;
  return true;
}

Context *kcontext(Area kstack, void (*entry)(void *), void *arg) {
  uintptr_t stack_top = (uintptr_t)kstack.end & ~(uintptr_t)0xf;
  Context *c = (Context *)stack_top - 1;
  memset(c, 0, sizeof(Context));

  c->mepc = (uintptr_t)entry;
  c->mstatus = MSTATUS_MPP_M;
  c->gpr[1] = (uintptr_t)__am_kcontext_on_return;
  c->GPR2 = (uintptr_t)arg;
  c->pdir = NULL;
  return c;
}

void yield() {
#ifdef __riscv_e
  asm volatile("li a5, -1; ecall");
#else
  asm volatile("li a7, -1; ecall");
#endif
}

bool ienabled() {
  uintptr_t mstatus;
  asm volatile("csrr %0, mstatus" : "=r"(mstatus));
  return (mstatus & MSTATUS_MIE) != 0;
}

void iset(bool enable) {
  uintptr_t mask = MSTATUS_MIE;
  if (enable) asm volatile("csrs mstatus, %0" : : "r"(mask));
  else        asm volatile("csrc mstatus, %0" : : "r"(mask));
}
```

- [ ] **Step 2: Update trap.S to restore returned context**

In `abstract-machine/am/src/riscv/npc/trap.S`, after `call __am_irq_handle`, add:

```asm
  # 调度器返回要恢复的 Context；切换 sp 后，下面的 POP 才会真正恢复新任务。
  mv sp, a0
```

The block should become:

```asm
  mv a0, sp
  call __am_irq_handle

  # 调度器返回要恢复的 Context；切换 sp 后，下面的 POP 才会真正恢复新任务。
  mv sp, a0

  LOAD t1, OFFSET_STATUS(sp)
  LOAD t2, OFFSET_EPC(sp)
```

- [ ] **Step 3: Build am-tests for NPC**

Run:

```bash
make -C am-kernels/tests/am-tests ARCH=riscv32-npc image mainargs=i
```

Expected: `am-kernels/tests/am-tests/build/amtest-riscv32-npc.bin` is produced without assembler errors for CSR instructions.

- [ ] **Step 4: Verify interrupt/yield smoke**

Run:

```bash
timeout 5s make -C am-kernels/tests/am-tests ARCH=riscv32-npc c mainargs=i NPC_RUN_ARGS='--max-cycles 0 --no-progress'
```

Expected: output contains `Hello, AM World @ riscv32-npc` and at least one `y` before `timeout` terminates the infinite test. The shell exit code may be `124` due to timeout; that is acceptable only if the expected text appears.

- [ ] **Step 5: Verify yield-os context switching**

Run:

```bash
timeout 5s make -C am-kernels/kernels/yield-os ARCH=riscv32-npc c NPC_RUN_ARGS='--max-cycles 0 --no-progress'
```

Expected: output contains alternating `A` and `B` characters before timeout. The shell exit code may be `124` due to timeout; that is acceptable only if both `A` and `B` appear.

- [ ] **Step 6: Commit AM CTE changes**

```bash
git add abstract-machine/am/src/riscv/npc/cte.c abstract-machine/am/src/riscv/npc/trap.S
git commit -m "feat: enable npc cte trap return"
```

### Task 6: Full Verification And Records

**Files:**
- Create: `.github/task-runs/2026-05-19-npc-zicsr-trap/task-report.md`
- Create: `.github/task-runs/2026-05-19-npc-zicsr-trap/dispatch-log.md`
- Modify: `.github/memory/project-status.md`
- Modify: `.github/memory/modules/npc.md`
- Modify: `.github/memory/modules/abstract-machine.md`

- [ ] **Step 1: Run final lint and build**

Run:

```bash
make -C npc/single lint
make -C npc/single
```

Expected: both commands exit 0.

- [ ] **Step 2: Run focused and regression tests**

Run:

```bash
make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=zicsr-trap run NPC_RUN_ARGS='--max-cycles 2000000 --no-progress'
make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run NPC_RUN_ARGS='--max-cycles 2000000 --no-progress'
make -C am-kernels/kernels/hello ARCH=riscv32-npc run NPC_RUN_ARGS='--max-cycles 2000000 --no-progress'
```

Expected: `zicsr-trap` PASS, `add` PASS, hello reaches `HIT GOOD TRAP`.

- [ ] **Step 3: Run CTE long-running smokes**

Run:

```bash
timeout 5s make -C am-kernels/tests/am-tests ARCH=riscv32-npc c mainargs=i NPC_RUN_ARGS='--max-cycles 0 --no-progress'
timeout 5s make -C am-kernels/kernels/yield-os ARCH=riscv32-npc c NPC_RUN_ARGS='--max-cycles 0 --no-progress'
```

Expected: `am-tests mainargs=i` prints at least one `y`; `yield-os` prints both `A` and `B`. Timeout exit code 124 is acceptable for these infinite tests only when expected output is present.

- [ ] **Step 4: Create task report**

Create `.github/task-runs/2026-05-19-npc-zicsr-trap/task-report.md` with:

```markdown
# NPC Zicsr Trap Task Report

## Scope

- Implemented NPC RV32I + Zicsr machine CSR/trap first stage.
- Kept `ebreak + a0` as simulator exit protocol.
- Did not implement RV32M/B/C or pipeline changes.

## RTL Derivation Summary

- Requirements: CSR RMW, `ecall -> mtvec`, `mret -> mepc`, `wfi` no-op, precise trap state.
- Protocol: CSR internal single-cycle path, existing one-request/one-response IFU/LSU unchanged.
- State machine: CSR uses `DECODE -> EXEC -> WB`; `ecall/mret` redirect from `EXEC` to `FETCH_REQ`; `ebreak` remains `HALT`.
- Invariants: one instruction in flight, x0 blocked, trap instructions do not normal-commit, CSR RMW returns old value.
- Datapath: `CSRFile` owns machine CSR state; `WBU` gains `WB_SEL_CSR`; `NpcCore` centralizes trap and mret PC redirection.

## Verification

- `make -C npc/single lint`: PASS
- `make -C npc/single`: PASS
- `zicsr-trap` on NEMU: PASS
- `zicsr-trap` on NPC: PASS
- `add` on NPC: PASS
- `hello` on NPC: PASS
- `am-tests mainargs=i` on NPC: PASS by observed `y` before timeout
- `yield-os` on NPC: PASS by observed `A` and `B` before timeout

## Notes

- Timeout exit code 124 is expected for infinite CTE smoke tests when expected output appears first.
```

- [ ] **Step 5: Create dispatch log**

Create `.github/task-runs/2026-05-19-npc-zicsr-trap/dispatch-log.md` with:

```markdown
# NPC Zicsr Trap Dispatch Log

| Node | Action | Evidence |
| --- | --- | --- |
| recall | Read AGENTS, memory, NPC study notes, NEMU `inst.c` | Spec `docs/superpowers/specs/2026-05-19-npc-zicsr-trap-design.md` |
| red-test | Added `zicsr-trap` smoke and confirmed NPC RED | `zicsr-trap` NEMU PASS, NPC FAIL before RTL |
| decode | Extended control bus and SYSTEM decode | `make -C npc/single lint` PASS |
| csrfile | Added machine CSR block | `make -C npc/single lint` PASS |
| core | Connected CSR/trap/mret path | `zicsr-trap` NPC PASS |
| am-cte | Completed NPC CTE restore path | `am-tests mainargs=i` and `yield-os` smoke output |
| regression | Ran final checks | lint/build/add/hello PASS |
```

- [ ] **Step 6: Update memory files**

Append concise entries:

` .github/memory/project-status.md` under “已完成的工作”:

```markdown
- [2026-05-19] 补齐 NPC 第一阶段 RV32I + Zicsr machine trap 闭环：新增 `CSRFile`，支持 `csrrw/csrrs/csrrc/csrrwi/csrrsi/csrrci`、`ecall -> mtvec`、`mret -> mepc` 和 `wfi` no-op；保留 `ebreak + a0` 作为 AM/NPC 退出协议；AM NPC CTE 现可通过 `yield()` 保存/恢复上下文。验证：`npc/single lint/build` PASS，`zicsr-trap/add/hello` PASS，`am-tests mainargs=i` 输出 `y`，`yield-os` 输出 `A/B` 后按 timeout 结束。
```

` .github/memory/modules/npc.md` under “当前状态”:

```markdown
- 2026-05-19: `npc/single` 已补齐第一阶段 machine CSR/trap 闭环。`CSRFile` 覆盖 `mstatus/mtvec/mscratch/mepc/mcause/mtval/mie/mip/misa/mhartid`，`DecodeUnit` 支持 Zicsr 与 `mret/wfi`，`NpcCore` 将 `ecall` 从直接 halt 改为写 CSR 后跳 `mtvec`，`mret` 从 `mepc` 返回；`ebreak + a0` 仍是仿真退出协议。
```

` .github/memory/modules/abstract-machine.md` under “当前状态”:

```markdown
- 2026-05-19: `riscv32-npc` 的 CTE 路径已对齐 NEMU 基础语义：`cte_init()` 写 `mtvec`，`yield()` 使用 `ecall`，`__am_irq_handle()` 将 M-mode ecall 的 `a7=-1` 识别为 `EVENT_YIELD`，`trap.S` 使用 handler 返回的 `Context *` 恢复现场，`kcontext()` 可创建初始内核上下文。
```

- [ ] **Step 7: Commit records**

```bash
git add .github/task-runs/2026-05-19-npc-zicsr-trap \
        .github/memory/project-status.md \
        .github/memory/modules/npc.md \
        .github/memory/modules/abstract-machine.md
git commit -m "docs: record npc zicsr trap bringup"
```

## Self-Review

**Spec coverage:** This plan covers all confirmed spec goals: CSR block, decode, trap/mret behavior, `ebreak` exit preservation, AM CTE, verification, and memory/task-run records. RV32M and pipeline are intentionally out of this stage and will be separate plans after this stage is green.

**Placeholder scan:** No placeholder markers or incomplete code blocks are used as implementation instructions. The only conditional acceptance is the explicit timeout rule for infinite tests with required observed output.

**Type consistency:** Control names use `CTRL_CSR_*`, `CSR_OP_*`, `WB_SEL_CSR`, and `CSRFile` consistently across `define.v`, `DecodeUnit.v`, `NpcCore.v`, and `WBU.v`.
