`include "define.v"

// Pending FP owner：只保存 FP 序列化边界的状态/进度，FPR 与提交副作用留在父模块。
module OooPendingFpSequencer (
  input clk,
  input rst,
  input late_clear_i,
  input clear_i,

  input capture_head0_i,
  input capture_head0_load_i,
  input capture_head0_store_i,
  input capture_head0_double_i,
  input capture_head0_gpr_write_i,
  input [`XLEN-1:0] capture_head0_pc_i,
  input [`INST_W-1:0] capture_head0_inst_i,
  input [`XLEN-1:0] capture_head0_next_pc_i,
  input [`REG_ADDR_W-1:0] capture_head0_rd_i,

  input capture_lane1_i,
  input capture_lane1_valid_i,
  input capture_lane1_load_i,
  input capture_lane1_store_i,
  input capture_lane1_double_i,
  input capture_lane1_gpr_write_i,
  input [`XLEN-1:0] capture_lane1_pc_i,
  input [`INST_W-1:0] capture_lane1_inst_i,
  input [`XLEN-1:0] capture_lane1_next_pc_i,
  input [`REG_ADDR_W-1:0] capture_lane1_rd_i,

  input mem_req_fire_i,
  input [`XLEN-1:0] mem_req_addr_i,
  input [`XLEN-1:0] mem_req_wdata_i,
  input [`STRB_W-1:0] mem_req_wstrb_i,
  input mem_rsp_fire_i,

  input long_start_i,
  input long_done_i,
  input [`XLEN-1:0] long_done_result_i,
  input [4:0] long_done_fflags_i,

  input compute_start_i,
  // compute_ready_i:compute 结果是否就绪(流水化 arith 需等其多周期 done,见
  // OooFpPendingExec.compute_ready_o);非 arith compute 恒 1,行为与原单拍一致。
  input compute_ready_i,
  input [`XLEN-1:0] compute_result_i,
  input [4:0] compute_fflags_i,

  output reg valid_o,
  output reg mem_pending_o,
  output reg mem_done_o,
  output reg long_pending_o,
  output reg long_done_o,
  output reg [`XLEN-1:0] long_result_o,
  output reg [4:0] long_fflags_o,
  output reg compute_done_o,
  output reg [`XLEN-1:0] compute_result_o,
  output reg [4:0] compute_fflags_o,
  output reg load_o,
  output reg store_o,
  output reg double_o,
  output reg gpr_write_o,
  output reg [`XLEN-1:0] pc_o,
  output reg [`INST_W-1:0] inst_o,
  output reg [`XLEN-1:0] next_pc_o,
  output reg [`XLEN-1:0] addr_o,
  output reg [`XLEN-1:0] wdata_o,
  output reg [`STRB_W-1:0] wstrb_o,
  output reg [`REG_ADDR_W-1:0] rd_o
);

  always @(posedge clk) begin
    if (rst) begin
      valid_o <= 1'b0;
      mem_pending_o <= 1'b0;
      mem_done_o <= 1'b0;
      long_pending_o <= 1'b0;
      long_done_o <= 1'b0;
      long_result_o <= {`XLEN{1'b0}};
      long_fflags_o <= 5'b00000;
      compute_done_o <= 1'b0;
      compute_result_o <= {`XLEN{1'b0}};
      compute_fflags_o <= 5'b00000;
      load_o <= 1'b0;
      store_o <= 1'b0;
      double_o <= 1'b0;
      gpr_write_o <= 1'b0;
      pc_o <= {`XLEN{1'b0}};
      inst_o <= {`INST_W{1'b0}};
      next_pc_o <= {`XLEN{1'b0}};
      addr_o <= {`XLEN{1'b0}};
      wdata_o <= {`XLEN{1'b0}};
      wstrb_o <= {`STRB_W{1'b0}};
      rd_o <= {`REG_ADDR_W{1'b0}};
    end else begin
      if (mem_req_fire_i) begin
        mem_pending_o <= 1'b1;
        addr_o <= mem_req_addr_i;
        wdata_o <= mem_req_wdata_i;
        wstrb_o <= mem_req_wstrb_i;
      end

      if (mem_rsp_fire_i) begin
        mem_pending_o <= 1'b0;
        mem_done_o <= 1'b1;
      end

      if (long_start_i) begin
        long_pending_o <= 1'b1;
        long_done_o <= 1'b0;
        long_result_o <= {`XLEN{1'b0}};
        long_fflags_o <= 5'b00000;
      end

      if (long_done_i) begin
        long_pending_o <= 1'b0;
        long_done_o <= 1'b1;
        long_result_o <= long_done_result_i;
        long_fflags_o <= long_done_fflags_i;
      end

      // 流水化 arith:compute_start_i 在等待期间持续拉高,但只有 compute_ready_i
      // (= arith 多周期 done)为真时才锁存 compute_done,实现延后 LATENCY 拍。
      if (compute_start_i && compute_ready_i) begin
        compute_done_o <= 1'b1;
        compute_result_o <= compute_result_i;
        compute_fflags_o <= compute_fflags_i;
      end

      if (clear_i) begin
        valid_o <= 1'b0;
        mem_pending_o <= 1'b0;
        mem_done_o <= 1'b0;
        long_pending_o <= 1'b0;
        long_done_o <= 1'b0;
        long_result_o <= {`XLEN{1'b0}};
        long_fflags_o <= 5'b00000;
        compute_done_o <= 1'b0;
        compute_result_o <= {`XLEN{1'b0}};
        compute_fflags_o <= 5'b00000;
        load_o <= 1'b0;
        store_o <= 1'b0;
        gpr_write_o <= 1'b0;
      end

      if (capture_lane1_i) begin
        valid_o <= capture_lane1_valid_i;
        mem_pending_o <= 1'b0;
        mem_done_o <= capture_lane1_valid_i &&
                      !capture_lane1_load_i && !capture_lane1_store_i;
        long_pending_o <= 1'b0;
        long_done_o <= 1'b0;
        long_result_o <= {`XLEN{1'b0}};
        long_fflags_o <= 5'b00000;
        compute_done_o <= 1'b0;
        compute_result_o <= {`XLEN{1'b0}};
        compute_fflags_o <= 5'b00000;
        load_o <= capture_lane1_valid_i && capture_lane1_load_i;
        store_o <= capture_lane1_valid_i && capture_lane1_store_i;
        double_o <= capture_lane1_valid_i && capture_lane1_double_i;
        gpr_write_o <= capture_lane1_valid_i && capture_lane1_gpr_write_i;
        pc_o <= capture_lane1_pc_i;
        inst_o <= capture_lane1_inst_i;
        next_pc_o <= capture_lane1_next_pc_i;
        addr_o <= {`XLEN{1'b0}};
        wdata_o <= {`XLEN{1'b0}};
        wstrb_o <= {`STRB_W{1'b0}};
        rd_o <= capture_lane1_rd_i;
      end

      if (capture_head0_i) begin
        valid_o <= 1'b1;
        mem_pending_o <= 1'b0;
        mem_done_o <= !capture_head0_load_i && !capture_head0_store_i;
        long_pending_o <= 1'b0;
        long_done_o <= 1'b0;
        long_result_o <= {`XLEN{1'b0}};
        long_fflags_o <= 5'b00000;
        compute_done_o <= 1'b0;
        compute_result_o <= {`XLEN{1'b0}};
        compute_fflags_o <= 5'b00000;
        load_o <= capture_head0_load_i;
        store_o <= capture_head0_store_i;
        double_o <= capture_head0_double_i;
        gpr_write_o <= capture_head0_gpr_write_i;
        pc_o <= capture_head0_pc_i;
        inst_o <= capture_head0_inst_i;
        next_pc_o <= capture_head0_next_pc_i;
        addr_o <= {`XLEN{1'b0}};
        wdata_o <= {`XLEN{1'b0}};
        wstrb_o <= {`STRB_W{1'b0}};
        rd_o <= capture_head0_rd_i;
      end

      if (late_clear_i) begin
        valid_o <= 1'b0;
        mem_pending_o <= 1'b0;
        mem_done_o <= 1'b0;
        long_pending_o <= 1'b0;
        long_done_o <= 1'b0;
        long_result_o <= {`XLEN{1'b0}};
        long_fflags_o <= 5'b00000;
        compute_done_o <= 1'b0;
        compute_result_o <= {`XLEN{1'b0}};
        compute_fflags_o <= 5'b00000;
        next_pc_o <= {`XLEN{1'b0}};
      end
    end
  end

endmodule
