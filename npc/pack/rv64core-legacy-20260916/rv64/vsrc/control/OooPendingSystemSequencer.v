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
  input dispatch_eligible_i,
  input dispatch_cancel_i,
  input head0_csr_inflight_i,
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
  output fence_o,
  output irq_o,
  output [`XLEN-1:0] pc_o,
  output [`INST_W-1:0] inst_o,
  output [`XLEN-1:0] next_pc_o,
  output [`XLEN-1:0] csr_rdata_o,
  output [`TRAP_CAUSE_W-1:0] irq_cause_o,
  output dispatch_permit_o,
  output producer_valid_o,
  output [PRODUCER_ID_W-1:0] producer_id_o
);

  reg valid_q;
  reg dispatched_q;
  localparam SERIAL_KIND_W = 4;
  localparam [SERIAL_KIND_W-1:0] SERIAL_KIND_NONE    = 4'd0;
  localparam [SERIAL_KIND_W-1:0] SERIAL_KIND_CSR     = 4'd1;
  localparam [SERIAL_KIND_W-1:0] SERIAL_KIND_ECALL   = 4'd2;
  localparam [SERIAL_KIND_W-1:0] SERIAL_KIND_XRET    = 4'd3;
  localparam [SERIAL_KIND_W-1:0] SERIAL_KIND_WFI     = 4'd4;
  localparam [SERIAL_KIND_W-1:0] SERIAL_KIND_SFENCE  = 4'd5;
  localparam [SERIAL_KIND_W-1:0] SERIAL_KIND_FENCEI  = 4'd6;
  localparam [SERIAL_KIND_W-1:0] SERIAL_KIND_FENCE   = 4'd7;
  localparam [SERIAL_KIND_W-1:0] SERIAL_KIND_IRQ     = 4'd8;
  reg [SERIAL_KIND_W-1:0] kind_q;
  reg [`XLEN-1:0] pc_q;
  reg [`INST_W-1:0] inst_q;
  reg [`XLEN-1:0] next_pc_q;
  reg [`XLEN-1:0] csr_rdata_q;
  reg [`TRAP_CAUSE_W-1:0] irq_cause_q;
  reg dispatch_permit_q;
  reg producer_valid_q;
  reg [PRODUCER_ID_W-1:0] producer_id_q;

  function [SERIAL_KIND_W-1:0] classify_system_kind;
    input csr_i;
    input ecall_i;
    input xret_i;
    input wfi_i;
    input sfence_i;
    input fencei_i;
    input [`INST_W-1:0] inst_i;
    begin
      if (csr_i)
        classify_system_kind = SERIAL_KIND_CSR;
      else if (ecall_i)
        classify_system_kind = SERIAL_KIND_ECALL;
      else if (xret_i)
        classify_system_kind = SERIAL_KIND_XRET;
      else if (wfi_i)
        classify_system_kind = SERIAL_KIND_WFI;
      else if (sfence_i)
        classify_system_kind = SERIAL_KIND_SFENCE;
      else if (fencei_i)
        classify_system_kind = SERIAL_KIND_FENCEI;
      else if ((inst_i[6:0] == `OPCODE_MISC_MEM) &&
               (inst_i[14:12] == `FUNCT3_FENCE))
        classify_system_kind = SERIAL_KIND_FENCE;
      else
        classify_system_kind = SERIAL_KIND_NONE;
    end
  endfunction

  wire head0_plain_fence_w =
      (capture_head0_inst_i[6:0] == `OPCODE_MISC_MEM) &&
      (capture_head0_inst_i[14:12] == `FUNCT3_FENCE);
  wire lane1_plain_fence_w =
      (capture_lane1_inst_i[6:0] == `OPCODE_MISC_MEM) &&
      (capture_lane1_inst_i[14:12] == `FUNCT3_FENCE);
  wire [SERIAL_KIND_W-1:0] head0_capture_kind_w =
      classify_system_kind(
          capture_head0_csr_i, capture_head0_ecall_i,
          capture_head0_mret_i, capture_head0_wfi_i,
          capture_head0_sfence_i, capture_head0_fencei_i,
          capture_head0_inst_i);
  wire [SERIAL_KIND_W-1:0] lane1_capture_kind_w =
      classify_system_kind(
          capture_lane1_csr_i, capture_lane1_ecall_i,
          capture_lane1_mret_i, capture_lane1_wfi_i,
          capture_lane1_sfence_i, capture_lane1_fencei_i,
          capture_lane1_inst_i);
  wire [3:0] head0_kind_count_w =
      {3'b000, capture_head0_csr_i} +
      {3'b000, capture_head0_ecall_i} +
      {3'b000, capture_head0_mret_i} +
      {3'b000, capture_head0_wfi_i} +
      {3'b000, capture_head0_sfence_i} +
      {3'b000, capture_head0_fencei_i} +
      {3'b000, head0_plain_fence_w};
  wire [3:0] lane1_kind_count_w =
      {3'b000, capture_lane1_csr_i} +
      {3'b000, capture_lane1_ecall_i} +
      {3'b000, capture_lane1_mret_i} +
      {3'b000, capture_lane1_wfi_i} +
      {3'b000, capture_lane1_sfence_i} +
      {3'b000, capture_lane1_fencei_i} +
      {3'b000, lane1_plain_fence_w};
  wire capture_any_w = capture_irq_i || capture_head0_i || capture_lane1_i;
  wire empty_w = !valid_q && !producer_valid_q;
  wire dispatch_permit_arm_w =
      dispatch_eligible_i && !dispatch_cancel_i && !clear_i &&
      !clear_dispatched_i && !head0_csr_inflight_i && valid_q &&
      (kind_q == SERIAL_KIND_CSR) && !dispatched_q && !producer_valid_q;
  wire dispatch_birth_w =
      dispatch_fire_i && dispatch_permit_q && !dispatch_cancel_i &&
      valid_q && (kind_q == SERIAL_KIND_CSR) && !dispatched_q &&
      !producer_valid_q && !clear_i;

  // V15U/V15W: mem-owner terminalization is sampled into a cancellable CSR
  // admission permit.  The permit holds across backend ready stalls, but it
  // never survives a holder clear, orphan recovery, dispatch, exact
  // cancellation witness, or a registered queue-head CSR owner.  The
  // head0-CSR inflight state replaces its long commit cone on the pre-ROB
  // valid path without adding pipeline state or changing either owner death.
  always @(posedge clk) begin
    if (rst) begin
      dispatch_permit_q <= 1'b0;
    end else if (dispatch_cancel_i || clear_i || clear_dispatched_i ||
                 dispatch_fire_i || producer_death_i ||
                 (head0_csr_inflight_i && dispatch_permit_q) ||
                 producer_valid_q || dispatched_q || !valid_q ||
                 (kind_q != SERIAL_KIND_CSR)) begin
      dispatch_permit_q <= 1'b0;
    end else if (dispatch_permit_arm_w) begin
      dispatch_permit_q <= 1'b1;
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      valid_q <= 1'b0;
      dispatched_q <= 1'b0;
      kind_q <= SERIAL_KIND_NONE;
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
        kind_q <= SERIAL_KIND_NONE;
        producer_valid_q <= 1'b0;
        producer_id_q <= {PRODUCER_ID_W{1'b0}};
      end
    end else if (clear_i) begin
      valid_q <= 1'b0;
      dispatched_q <= 1'b0;
      kind_q <= SERIAL_KIND_NONE;
      producer_id_q <= {PRODUCER_ID_W{1'b0}};
    end else if (empty_w && capture_irq_i) begin
      valid_q <= 1'b1;
      dispatched_q <= 1'b0;
      kind_q <= SERIAL_KIND_IRQ;
      pc_q <= capture_irq_pc_i;
      inst_q <= {`INST_W{1'b0}};
      next_pc_q <= capture_irq_pc_i;
      csr_rdata_q <= {`XLEN{1'b0}};
      irq_cause_q <= capture_irq_cause_i;
      producer_id_q <= {PRODUCER_ID_W{1'b0}};
    end else if (empty_w && capture_head0_i) begin
      valid_q <= 1'b1;
      dispatched_q <= 1'b0;
      kind_q <= head0_capture_kind_w;
      pc_q <= capture_head0_pc_i;
      inst_q <= capture_head0_inst_i;
      next_pc_q <= capture_head0_next_pc_i;
      csr_rdata_q <= capture_head0_csr_rdata_i;
      irq_cause_q <= {`TRAP_CAUSE_W{1'b0}};
      producer_id_q <= {PRODUCER_ID_W{1'b0}};
    end else if (empty_w && capture_lane1_i) begin
      valid_q <= 1'b1;
      dispatched_q <= 1'b0;
      kind_q <= lane1_capture_kind_w;
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
    end else if (refresh_rdata_i && valid_q &&
                 (kind_q == SERIAL_KIND_CSR) && !dispatched_q) begin
      csr_rdata_q <= refresh_rdata_value_i;
    end
  end

  assign valid_o = valid_q;
  assign dispatched_o = dispatched_q;
  assign csr_o = kind_q == SERIAL_KIND_CSR;
  assign ecall_o = kind_q == SERIAL_KIND_ECALL;
  assign mret_o = kind_q == SERIAL_KIND_XRET;
  assign wfi_o = kind_q == SERIAL_KIND_WFI;
  assign sfence_o = kind_q == SERIAL_KIND_SFENCE;
  assign fencei_o = kind_q == SERIAL_KIND_FENCEI;
  assign fence_o = kind_q == SERIAL_KIND_FENCE;
  assign irq_o = kind_q == SERIAL_KIND_IRQ;
  assign pc_o = pc_q;
  assign inst_o = inst_q;
  assign next_pc_o = next_pc_q;
  assign csr_rdata_o = csr_rdata_q;
  assign irq_cause_o = irq_cause_q;
  assign dispatch_permit_o = dispatch_permit_q;
  // raw lease 是 birth fence 的承重状态。不要与 metadata 相与；metadata
  // 一致性由下方 assertion 守护，异常时保守阻止复用。
  assign producer_valid_o = producer_valid_q;
  assign producer_id_o = producer_id_q;

`ifdef OOO_ASSERT
  reg producer_valid_prev_q;
  reg [PRODUCER_ID_W-1:0] producer_id_prev_q;
  reg producer_death_prev_q;
  reg head0_csr_inflight_prev_q;
  wire [3:0] held_kind_count_w =
      {3'b000, csr_o} + {3'b000, ecall_o} +
      {3'b000, mret_o} + {3'b000, wfi_o} +
      {3'b000, sfence_o} + {3'b000, fencei_o} +
      {3'b000, fence_o} + {3'b000, irq_o};
  always @(posedge clk) begin
    if (rst) begin
      producer_valid_prev_q <= 1'b0;
      producer_id_prev_q <= {PRODUCER_ID_W{1'b0}};
      producer_death_prev_q <= 1'b0;
      head0_csr_inflight_prev_q <= 1'b0;
    end else begin
      if (valid_q != (kind_q != SERIAL_KIND_NONE)) begin
        $error("[V9W-SERIAL-KIND-VALID] valid/kind mismatch valid=%b kind=%0d @%0t",
               valid_q, kind_q, $time);
        $fatal;
      end
      if (valid_q && (held_kind_count_w != 4'd1)) begin
        $error("[V9W-SERIAL-KIND-ONEHOT] pending kind is not exact-one kind=%0d count=%0d @%0t",
               kind_q, held_kind_count_w, $time);
        $fatal;
      end
      if (capture_head0_i && (head0_kind_count_w != 4'd1)) begin
        $error("[V9W-SERIAL-CAPTURE-HEAD0-TYPE] head0 capture type count=%0d inst=%h @%0t",
               head0_kind_count_w, capture_head0_inst_i, $time);
        $fatal;
      end
      if (capture_lane1_i && (lane1_kind_count_w != 4'd1)) begin
        $error("[V9W-SERIAL-CAPTURE-LANE1-TYPE] lane1 capture type count=%0d inst=%h @%0t",
               lane1_kind_count_w, capture_lane1_inst_i, $time);
        $fatal;
      end
      if (producer_valid_q &&
          !(valid_q && (kind_q == SERIAL_KIND_CSR) && dispatched_q)) begin
        $error("[V8K-PENDING-CSR-LEASE-SHAPE] raw lease lost pending CSR metadata @%0t", $time);
        $fatal;
      end
      if (dispatch_permit_q &&
          !(valid_q && (kind_q == SERIAL_KIND_CSR) && !dispatched_q &&
            !producer_valid_q)) begin
        $error("[V15U-CSR-DISPATCH-PERMIT-SHAPE] permit lost pre-ROB CSR owner valid=%b csr=%b dispatched=%b lease=%b @%0t",
               valid_q, csr_o, dispatched_q, producer_valid_q, $time);
        $fatal;
      end
      if (head0_csr_inflight_prev_q && dispatch_permit_q) begin
        $error("[V15W-HEAD0-CSR-PERMIT-CLEAR] queue-head CSR inflight did not clear pending CSR permit @%0t",
               $time);
        $fatal;
      end
      if (dispatch_fire_i &&
          (!dispatch_permit_q || dispatch_cancel_i)) begin
        $error("[V15U-CSR-DISPATCH-PERMIT-AUTHORITY] fire without live uncancelled permit permit=%b cancel=%b @%0t",
               dispatch_permit_q, dispatch_cancel_i, $time);
        $fatal;
      end
      if (dispatch_fire_i && !dispatch_birth_w) begin
        $error("[V8K-PENDING-CSR-DISPATCH-BIRTH] fire without pre-ROB CSR owner valid=%b csr=%b dispatched=%b lease=%b @%0t",
               valid_q, csr_o, dispatched_q, producer_valid_q, $time);
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
      head0_csr_inflight_prev_q <= head0_csr_inflight_i;
    end
  end
`endif


endmodule
