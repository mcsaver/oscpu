`include "define.v"

module OooFetchAxiBridge (
  input clk,
  input rst,

  input invalidate_valid_i,
  input [`XLEN-1:0] invalidate_addr_i,

  input fetch_req_valid_i,
  output fetch_req_ready_o,
  input [`XLEN-1:0] fetch_req_pc_i,
  output fetch_rsp_valid_o,
  input fetch_rsp_ready_i,
  output [`INST_W-1:0] fetch_rsp_inst0_o,
  output [1:0] fetch_rsp_resp0_o,
  output [`INST_W-1:0] fetch_rsp_inst1_o,
  output [1:0] fetch_rsp_resp1_o,

  output ifu_axi_arvalid_o,
  input ifu_axi_arready_i,
  output [`XLEN-1:0] ifu_axi_araddr_o,
  input ifu_axi_rvalid_i,
  output ifu_axi_rready_o,
  input [`XLEN-1:0] ifu_axi_rdata_i,
  input [1:0] ifu_axi_rresp_i
);

  localparam [2:0] S_IDLE = 3'd0;
  localparam [2:0] S_AR0 = 3'd1;
  localparam [2:0] S_R0 = 3'd2;
  localparam [2:0] S_AR1 = 3'd3;
  localparam [2:0] S_R1 = 3'd4;
  localparam [2:0] S_RESP = 3'd5;
  localparam CACHE_INDEX_W = 10;
  localparam CACHE_ENTRIES = (1 << CACHE_INDEX_W);

  reg [2:0] state_q;
  reg [`XLEN-1:0] pc_q;
  reg [`INST_W-1:0] inst0_q;
  reg [`INST_W-1:0] inst1_q;
  reg [1:0] resp0_q;
  reg [1:0] resp1_q;

  reg [CACHE_ENTRIES-1:0] cache_valid_q;
  reg [`XLEN-1:0] cache_pc_q [0:CACHE_ENTRIES-1];
  reg [`INST_W-1:0] cache_inst0_q [0:CACHE_ENTRIES-1];
  reg [`INST_W-1:0] cache_inst1_q [0:CACHE_ENTRIES-1];
  reg [1:0] cache_resp0_q [0:CACHE_ENTRIES-1];
  reg [1:0] cache_resp1_q [0:CACHE_ENTRIES-1];

  /* verilator lint_off UNUSEDSIGNAL */
  function [CACHE_INDEX_W-1:0] cache_index;
    input [`XLEN-1:0] pc;
    begin
      cache_index = pc[CACHE_INDEX_W:1];
    end
  endfunction

  function cache_overlap;
    input [`XLEN-1:0] fetch_pc;
    input [`XLEN-1:0] store_addr;
    begin
      cache_overlap =
          ((store_addr & {{(`XLEN-2){1'b1}}, 2'b00}) <= (fetch_pc + 32'd7)) &&
          (((store_addr & {{(`XLEN-2){1'b1}}, 2'b00}) + 32'd3) >= fetch_pc);
    end
  endfunction
  /* verilator lint_on UNUSEDSIGNAL */

  wire [CACHE_INDEX_W-1:0] req_cache_idx_w = cache_index(fetch_req_pc_i);
  wire [CACHE_INDEX_W-1:0] fill_cache_idx_w = cache_index(pc_q);
  wire req_cache_invalidated_w =
      invalidate_valid_i && cache_overlap(fetch_req_pc_i, invalidate_addr_i);
  wire fill_cache_invalidated_w =
      invalidate_valid_i && cache_overlap(pc_q, invalidate_addr_i);
  wire cache_hit_w =
      cache_valid_q[req_cache_idx_w] &&
      (cache_pc_q[req_cache_idx_w] == fetch_req_pc_i) &&
      !req_cache_invalidated_w;
  wire fetch_req_fire_w = fetch_req_valid_i && fetch_req_ready_o;
  wire fetch_req_miss_fire_w = fetch_req_fire_w && !cache_hit_w;

  // hit 响应一拍后返回；S_RESP 同拍可接下一次 request，保持命中吞吐。
  assign fetch_req_ready_o = (state_q == S_IDLE) ||
                             ((state_q == S_RESP) && fetch_rsp_ready_i);
  assign fetch_rsp_valid_o = (state_q == S_RESP);
  assign fetch_rsp_inst0_o = inst0_q;
  assign fetch_rsp_inst1_o = inst1_q;
  assign fetch_rsp_resp0_o = resp0_q;
  assign fetch_rsp_resp1_o = resp1_q;

  assign ifu_axi_arvalid_o = (state_q == S_AR0) || (state_q == S_AR1) ||
                             fetch_req_miss_fire_w;
  assign ifu_axi_araddr_o =
      fetch_req_miss_fire_w ? fetch_req_pc_i :
      ((state_q == S_AR1) ? (pc_q + 32'd4) : pc_q);
  assign ifu_axi_rready_o = (state_q == S_R0) || (state_q == S_R1);

  integer cache_idx;

  always @(posedge clk) begin
    if (rst) begin
      state_q <= S_IDLE;
      pc_q <= {`XLEN{1'b0}};
      inst0_q <= {`INST_W{1'b0}};
      inst1_q <= {`INST_W{1'b0}};
      resp0_q <= 2'b00;
      resp1_q <= 2'b00;
      cache_valid_q <= {CACHE_ENTRIES{1'b0}};
    end else begin
      if (invalidate_valid_i) begin
        for (cache_idx = 0; cache_idx < CACHE_ENTRIES; cache_idx = cache_idx + 1) begin
          if (cache_valid_q[cache_idx] &&
              cache_overlap(cache_pc_q[cache_idx], invalidate_addr_i)) begin
            cache_valid_q[cache_idx] <= 1'b0;
          end
        end
      end

      case (state_q)
        S_IDLE: begin
          if (fetch_req_fire_w) begin
            pc_q <= fetch_req_pc_i;
            if (cache_hit_w) begin
              inst0_q <= cache_inst0_q[req_cache_idx_w];
              inst1_q <= cache_inst1_q[req_cache_idx_w];
              resp0_q <= cache_resp0_q[req_cache_idx_w];
              resp1_q <= cache_resp1_q[req_cache_idx_w];
              state_q <= S_RESP;
            end else begin
              state_q <= ifu_axi_arready_i ? S_R0 : S_AR0;
            end
          end
        end

        S_AR0: begin
          if (ifu_axi_arready_i) begin
            state_q <= S_R0;
          end
        end

        S_R0: begin
          if (ifu_axi_rvalid_i) begin
            inst0_q <= ifu_axi_rdata_i[`INST_W-1:0];
            resp0_q <= ifu_axi_rresp_i;
            state_q <= S_AR1;
          end
        end

        S_AR1: begin
          if (ifu_axi_arready_i) begin
            state_q <= S_R1;
          end
        end

        S_R1: begin
          if (ifu_axi_rvalid_i) begin
            inst1_q <= ifu_axi_rdata_i[`INST_W-1:0];
            resp1_q <= ifu_axi_rresp_i;
            if ((resp0_q == 2'b00) && (ifu_axi_rresp_i == 2'b00) &&
                !fill_cache_invalidated_w) begin
              // 只缓存完整无错误 packet；store 命中覆盖范围时立即失效，保证 fence-i 类用例不读旧代码。
              cache_valid_q[fill_cache_idx_w] <= 1'b1;
              cache_pc_q[fill_cache_idx_w] <= pc_q;
              cache_inst0_q[fill_cache_idx_w] <= inst0_q;
              cache_inst1_q[fill_cache_idx_w] <= ifu_axi_rdata_i[`INST_W-1:0];
              cache_resp0_q[fill_cache_idx_w] <= resp0_q;
              cache_resp1_q[fill_cache_idx_w] <= ifu_axi_rresp_i;
            end
            state_q <= S_RESP;
          end
        end

        S_RESP: begin
          if (fetch_rsp_ready_i) begin
            if (fetch_req_valid_i) begin
              pc_q <= fetch_req_pc_i;
              if (cache_hit_w) begin
                inst0_q <= cache_inst0_q[req_cache_idx_w];
                inst1_q <= cache_inst1_q[req_cache_idx_w];
                resp0_q <= cache_resp0_q[req_cache_idx_w];
                resp1_q <= cache_resp1_q[req_cache_idx_w];
                state_q <= S_RESP;
              end else begin
                state_q <= ifu_axi_arready_i ? S_R0 : S_AR0;
              end
            end else begin
              state_q <= S_IDLE;
            end
          end
        end

        default: begin
          state_q <= S_IDLE;
        end
      endcase
    end
  end

endmodule
