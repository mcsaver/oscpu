`include "define.v"

module OooPendingSystemSequencer (
  input clk,
  input rst,

  input clear_i,
  input clear_dispatched_i,
  input dispatch_fire_i,

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
  output irq_o,
  output [`XLEN-1:0] pc_o,
  output [`INST_W-1:0] inst_o,
  output [`XLEN-1:0] next_pc_o,
  output [`XLEN-1:0] csr_rdata_o,
  output [`TRAP_CAUSE_W-1:0] irq_cause_o
);

  reg valid_q;
  reg dispatched_q;
  reg csr_q;
  reg ecall_q;
  reg mret_q;
  reg wfi_q;
  reg sfence_q;
  reg irq_q;
  reg [`XLEN-1:0] pc_q;
  reg [`INST_W-1:0] inst_q;
  reg [`XLEN-1:0] next_pc_q;
  reg [`XLEN-1:0] csr_rdata_q;
  reg [`TRAP_CAUSE_W-1:0] irq_cause_q;

  always @(posedge clk) begin
    if (rst) begin
      valid_q <= 1'b0;
      dispatched_q <= 1'b0;
      csr_q <= 1'b0;
      ecall_q <= 1'b0;
      mret_q <= 1'b0;
      wfi_q <= 1'b0;
      sfence_q <= 1'b0;
      irq_q <= 1'b0;
      pc_q <= {`XLEN{1'b0}};
      inst_q <= {`INST_W{1'b0}};
      next_pc_q <= {`XLEN{1'b0}};
      csr_rdata_q <= {`XLEN{1'b0}};
      irq_cause_q <= {`TRAP_CAUSE_W{1'b0}};
    end else if (clear_i) begin
      valid_q <= 1'b0;
      dispatched_q <= 1'b0;
      csr_q <= 1'b0;
      ecall_q <= 1'b0;
      mret_q <= 1'b0;
      wfi_q <= 1'b0;
      sfence_q <= 1'b0;
      irq_q <= 1'b0;
    end else if (capture_irq_i) begin
      valid_q <= 1'b1;
      dispatched_q <= 1'b0;
      csr_q <= 1'b0;
      ecall_q <= 1'b0;
      mret_q <= 1'b0;
      wfi_q <= 1'b0;
      sfence_q <= 1'b0;
      irq_q <= 1'b1;
      pc_q <= capture_irq_pc_i;
      inst_q <= {`INST_W{1'b0}};
      next_pc_q <= capture_irq_pc_i;
      csr_rdata_q <= {`XLEN{1'b0}};
      irq_cause_q <= capture_irq_cause_i;
    end else if (capture_head0_i) begin
      valid_q <= 1'b1;
      dispatched_q <= 1'b0;
      csr_q <= capture_head0_csr_i;
      ecall_q <= capture_head0_ecall_i;
      mret_q <= capture_head0_mret_i;
      wfi_q <= capture_head0_wfi_i;
      sfence_q <= capture_head0_sfence_i;
      irq_q <= 1'b0;
      pc_q <= capture_head0_pc_i;
      inst_q <= capture_head0_inst_i;
      next_pc_q <= capture_head0_next_pc_i;
      csr_rdata_q <= capture_head0_csr_rdata_i;
      irq_cause_q <= {`TRAP_CAUSE_W{1'b0}};
    end else if (capture_lane1_i) begin
      valid_q <= 1'b1;
      dispatched_q <= 1'b0;
      csr_q <= capture_lane1_csr_i;
      ecall_q <= capture_lane1_ecall_i;
      mret_q <= capture_lane1_mret_i;
      wfi_q <= capture_lane1_wfi_i;
      sfence_q <= capture_lane1_sfence_i;
      irq_q <= 1'b0;
      pc_q <= capture_lane1_pc_i;
      inst_q <= capture_lane1_inst_i;
      next_pc_q <= capture_lane1_next_pc_i;
      csr_rdata_q <= capture_lane1_csr_rdata_i;
      irq_cause_q <= {`TRAP_CAUSE_W{1'b0}};
    end else if (dispatch_fire_i) begin
      dispatched_q <= 1'b1;
    end else if (clear_dispatched_i) begin
      dispatched_q <= 1'b0;
    end else if (refresh_rdata_i) begin
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
  assign irq_o = irq_q;
  assign pc_o = pc_q;
  assign inst_o = inst_q;
  assign next_pc_o = next_pc_q;
  assign csr_rdata_o = csr_rdata_q;
  assign irq_cause_o = irq_cause_q;


endmodule
