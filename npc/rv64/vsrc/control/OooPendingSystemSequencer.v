`include "define.v"

module OooPendingSystemSequencer #(
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W,
  parameter PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W,
  parameter PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W
) (
  input clk,
  input rst,

  input clear_i,
  input clear_dispatched_i,
  input dispatch_fire_i,
  input producer_death_i,
  input [PRODUCER_ID_W-1:0] dispatch_producer_id_i,

  // 【B-FP 簇】drain 完成拍刷新 CSR 读值: capture 拍锁存的 rdata 在"CSR 与
  // 产生 fflags 的 FP 指令同窗口在飞"时是旧值(fsflags 读 0)。drain 完成拍
  // ROB 已空、CSR 状态为架构终值, 重锁一次; fire 拍(至少晚一拍)消费寄存值。
  input refresh_rdata_i,
  input [`XLEN-1:0] refresh_rdata_value_i,
  input capture_irq_i,
  input [`XLEN-1:0] capture_irq_pc_i,
  input [`TRAP_CAUSE_W-1:0] capture_irq_cause_i,

  input capture_head0_i,
  input capture_head0_csr_i,
  input capture_head0_ecall_i,
  input capture_head0_mret_i,
  input capture_head0_wfi_i,
  input capture_head0_sfence_i,
  input capture_head0_fencei_i,
  input [`XLEN-1:0] capture_head0_pc_i,
  input [`INST_W-1:0] capture_head0_inst_i,
  input [`XLEN-1:0] capture_head0_next_pc_i,
  input [`XLEN-1:0] capture_head0_csr_rdata_i,

  input capture_lane1_i,
  input capture_lane1_csr_i,
  input capture_lane1_ecall_i,
  input capture_lane1_mret_i,
  input capture_lane1_wfi_i,
  input capture_lane1_sfence_i,
  input capture_lane1_fencei_i,
  input [`XLEN-1:0] capture_lane1_pc_i,
  input [`INST_W-1:0] capture_lane1_inst_i,
  input [`XLEN-1:0] capture_lane1_next_pc_i,
  input [`XLEN-1:0] capture_lane1_csr_rdata_i,

  output valid_o,
  output dispatched_o,
  output csr_o,
  output ecall_o,
  output mret_o,
  output wfi_o,
  output sfence_o,
  output fencei_o,
  output irq_o,
  output [`XLEN-1:0] pc_o,
  output [`INST_W-1:0] inst_o,
  output [`XLEN-1:0] next_pc_o,
  output [`XLEN-1:0] csr_rdata_o,
  output [`TRAP_CAUSE_W-1:0] irq_cause_o,
  output producer_valid_o,
  output [PRODUCER_ID_W-1:0] producer_id_o
);

  reg valid_q;
  reg dispatched_q;
  reg csr_q;
  reg ecall_q;
  reg mret_q;
  reg wfi_q;
  reg sfence_q;
  reg fencei_q;
  reg irq_q;
  reg [`XLEN-1:0] pc_q;
  reg [`INST_W-1:0] inst_q;
  reg [`XLEN-1:0] next_pc_q;
  reg [`XLEN-1:0] csr_rdata_q;
  reg [`TRAP_CAUSE_W-1:0] irq_cause_q;
  reg producer_valid_q;
  reg [PRODUCER_ID_W-1:0] producer_id_q;

  wire capture_any_w = capture_irq_i || capture_head0_i || capture_lane1_i;
  wire empty_w = !valid_q && !producer_valid_q;
  wire dispatch_birth_w =
      dispatch_fire_i && valid_q && csr_q && !dispatched_q &&
      !producer_valid_q && !clear_i;

  always @(posedge clk) begin
    if (rst) begin
      valid_q <= 1'b0;
      dispatched_q <= 1'b0;
      csr_q <= 1'b0;
      ecall_q <= 1'b0;
      mret_q <= 1'b0;
      wfi_q <= 1'b0;
      sfence_q <= 1'b0;
      fencei_q <= 1'b0;
      irq_q <= 1'b0;
      pc_q <= {`XLEN{1'b0}};
      inst_q <= {`INST_W{1'b0}};
      next_pc_q <= {`XLEN{1'b0}};
      csr_rdata_q <= {`XLEN{1'b0}};
      irq_cause_q <= {`TRAP_CAUSE_W{1'b0}};
      producer_valid_q <= 1'b0;
      producer_id_q <= {PRODUCER_ID_W{1'b0}};
    end else if (producer_valid_q) begin
      // v8k：post-dispatch lease 只能由 exact pending commit 清除。本模块的
      // synchronous reset 已由父层并入 backend-global flush，故 ordinary
      // pending clear / recapture / orphan clear-dispatched 均只能保持并报错，
      // 不能先于 ROB death 丢失 full ProducerId。
      if (producer_death_i) begin
        valid_q <= 1'b0;
        dispatched_q <= 1'b0;
        csr_q <= 1'b0;
        ecall_q <= 1'b0;
        mret_q <= 1'b0;
        wfi_q <= 1'b0;
        sfence_q <= 1'b0;
        fencei_q <= 1'b0;
        irq_q <= 1'b0;
        producer_valid_q <= 1'b0;
        producer_id_q <= {PRODUCER_ID_W{1'b0}};
      end
    end else if (clear_i) begin
      valid_q <= 1'b0;
      dispatched_q <= 1'b0;
      csr_q <= 1'b0;
      ecall_q <= 1'b0;
      mret_q <= 1'b0;
      wfi_q <= 1'b0;
      sfence_q <= 1'b0;
      fencei_q <= 1'b0;
      irq_q <= 1'b0;
      producer_id_q <= {PRODUCER_ID_W{1'b0}};
    end else if (empty_w && capture_irq_i) begin
      valid_q <= 1'b1;
      dispatched_q <= 1'b0;
      csr_q <= 1'b0;
      ecall_q <= 1'b0;
      mret_q <= 1'b0;
      wfi_q <= 1'b0;
      sfence_q <= 1'b0;
      fencei_q <= 1'b0;
      irq_q <= 1'b1;
      pc_q <= capture_irq_pc_i;
      inst_q <= {`INST_W{1'b0}};
      next_pc_q <= capture_irq_pc_i;
      csr_rdata_q <= {`XLEN{1'b0}};
      irq_cause_q <= capture_irq_cause_i;
      producer_id_q <= {PRODUCER_ID_W{1'b0}};
    end else if (empty_w && capture_head0_i) begin
      valid_q <= 1'b1;
      dispatched_q <= 1'b0;
      csr_q <= capture_head0_csr_i;
      ecall_q <= capture_head0_ecall_i;
      mret_q <= capture_head0_mret_i;
      wfi_q <= capture_head0_wfi_i;
      sfence_q <= capture_head0_sfence_i;
      fencei_q <= capture_head0_fencei_i;
      irq_q <= 1'b0;
      pc_q <= capture_head0_pc_i;
      inst_q <= capture_head0_inst_i;
      next_pc_q <= capture_head0_next_pc_i;
      csr_rdata_q <= capture_head0_csr_rdata_i;
      irq_cause_q <= {`TRAP_CAUSE_W{1'b0}};
      producer_id_q <= {PRODUCER_ID_W{1'b0}};
    end else if (empty_w && capture_lane1_i) begin
      valid_q <= 1'b1;
      dispatched_q <= 1'b0;
      csr_q <= capture_lane1_csr_i;
      ecall_q <= capture_lane1_ecall_i;
      mret_q <= capture_lane1_mret_i;
      wfi_q <= capture_lane1_wfi_i;
      sfence_q <= capture_lane1_sfence_i;
      fencei_q <= capture_lane1_fencei_i;
      irq_q <= 1'b0;
      pc_q <= capture_lane1_pc_i;
      inst_q <= capture_lane1_inst_i;
      next_pc_q <= capture_lane1_next_pc_i;
      csr_rdata_q <= capture_lane1_csr_rdata_i;
      irq_cause_q <= {`TRAP_CAUSE_W{1'b0}};
      producer_id_q <= {PRODUCER_ID_W{1'b0}};
    end else if (dispatch_birth_w) begin
      dispatched_q <= 1'b1;
      producer_valid_q <= 1'b1;
      producer_id_q <= dispatch_producer_id_i;
    end else if (clear_dispatched_i) begin
      dispatched_q <= 1'b0;
    end else if (refresh_rdata_i && valid_q && csr_q && !dispatched_q) begin
      csr_rdata_q <= refresh_rdata_value_i;
    end
  end

  assign valid_o = valid_q;
  assign dispatched_o = dispatched_q;
  assign csr_o = csr_q;
  assign ecall_o = ecall_q;
  assign mret_o = mret_q;
  assign wfi_o = wfi_q;
  assign sfence_o = sfence_q;
  assign fencei_o = fencei_q;
  assign irq_o = irq_q;
  assign pc_o = pc_q;
  assign inst_o = inst_q;
  assign next_pc_o = next_pc_q;
  assign csr_rdata_o = csr_rdata_q;
  assign irq_cause_o = irq_cause_q;
  // raw lease 是 birth fence 的承重状态。不要与 metadata 相与；metadata
  // 一致性由下方 assertion 守护，异常时保守阻止复用。
  assign producer_valid_o = producer_valid_q;
  assign producer_id_o = producer_id_q;

`ifdef OOO_ASSERT
  reg producer_valid_prev_q;
  reg [PRODUCER_ID_W-1:0] producer_id_prev_q;
  reg producer_death_prev_q;
  always @(posedge clk) begin
    if (rst) begin
      producer_valid_prev_q <= 1'b0;
      producer_id_prev_q <= {PRODUCER_ID_W{1'b0}};
      producer_death_prev_q <= 1'b0;
    end else begin
      if (producer_valid_q && !(valid_q && csr_q && dispatched_q)) begin
        $error("[V8K-PENDING-CSR-LEASE-SHAPE] raw lease lost pending CSR metadata @%0t", $time);
        $fatal;
      end
      if (dispatch_fire_i && !dispatch_birth_w) begin
        $error("[V8K-PENDING-CSR-DISPATCH-BIRTH] fire without pre-ROB CSR owner valid=%b csr=%b dispatched=%b lease=%b @%0t",
               valid_q, csr_q, dispatched_q, producer_valid_q, $time);
        $fatal;
      end
      if (producer_valid_q &&
          (clear_i || clear_dispatched_i ||
           refresh_rdata_i || dispatch_fire_i) && !producer_death_i) begin
        $error("[V8K-PENDING-CSR-NO-RECAPTURE] live lease collided with non-death update clear=%b cdisp=%b cap=%b refresh=%b fire=%b @%0t",
               clear_i, clear_dispatched_i, capture_any_w,
               refresh_rdata_i, dispatch_fire_i, $time);
        $fatal;
      end
      if (producer_valid_q && capture_any_w) begin
        $error("[V8K-PENDING-CSR-NO-RECAPTURE] live lease recapture attempted even on death edge @%0t",
               $time);
        $fatal;
      end
      if (valid_q && !producer_valid_q && capture_any_w) begin
        $error("[V8K-PENDING-CSR-NO-RECAPTURE] pre-ROB pending payload recapture attempted @%0t", $time);
        $fatal;
      end
      if (producer_valid_prev_q && producer_valid_q &&
          !producer_death_prev_q &&
          (producer_id_q != producer_id_prev_q)) begin
        $error("[V8K-PENDING-CSR-LEASE-STABLE] live ProducerId changed old=%h new=%h @%0t",
               producer_id_prev_q, producer_id_q, $time);
        $fatal;
      end
      producer_valid_prev_q <= producer_valid_q;
      producer_id_prev_q <= producer_id_q;
      producer_death_prev_q <= producer_death_i;
    end
  end
`endif


endmodule
