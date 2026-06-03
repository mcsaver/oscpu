`include "define.v"

module OooFetchPacketCache #(
  parameter INDEX_W = 12,
  parameter ENTRY_COUNT = (1 << INDEX_W)
) (
  input clk,
  input rst,
  input clear_i,

  input lookup_paging_i,
  input [1:0] lookup_priv_i,
  input [`XLEN-1:0] lookup_satp_i,
  input [`XLEN-1:0] lookup_pc_i,
  output lookup_context_hit_o,
  output lookup_hit_o,
  output [`INST_W-1:0] lookup_inst0_o,
  output [1:0] lookup_resp0_o,
  output [`INST_W-1:0] lookup_inst1_o,
  output [1:0] lookup_resp1_o,

  input fill_valid_i,
  input fill_paging_i,
  input [1:0] fill_priv_i,
  input [`XLEN-1:0] fill_satp_i,
  input [`XLEN-1:0] fill_pc_i,
  input [`INST_W-1:0] fill_inst0_i,
  input [1:0] fill_resp0_i,
  input [`INST_W-1:0] fill_inst1_i,
  input [1:0] fill_resp1_i,

  input invalidate_valid_i,
  input [`XLEN-1:0] invalidate_addr_i
);

  reg [ENTRY_COUNT-1:0] valid_q;
  reg paging_q [0:ENTRY_COUNT-1];
  reg [1:0] priv_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] satp_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] pc_q [0:ENTRY_COUNT-1];
  reg [`INST_W-1:0] inst0_q [0:ENTRY_COUNT-1];
  reg [`INST_W-1:0] inst1_q [0:ENTRY_COUNT-1];
  reg [1:0] resp0_q [0:ENTRY_COUNT-1];
  reg [1:0] resp1_q [0:ENTRY_COUNT-1];

  function [INDEX_W-1:0] entry_index;
    input [`XLEN-1:0] pc;
    begin
      entry_index = pc[INDEX_W:1];
    end
  endfunction

  function same_fetch_window;
    input [`XLEN-1:0] fetch_pc;
    input [`XLEN-1:0] store_addr;
    begin
      same_fetch_window =
          ((store_addr & {{(`XLEN-2){1'b1}}, 2'b00}) <= (fetch_pc + 32'd7)) &&
          (((store_addr & {{(`XLEN-2){1'b1}}, 2'b00}) + 32'd3) >= fetch_pc);
    end
  endfunction

  wire [INDEX_W-1:0] lookup_idx_w = entry_index(lookup_pc_i);
  wire [INDEX_W-1:0] fill_idx_w = entry_index(fill_pc_i);
  wire lookup_invalidated_w =
      invalidate_valid_i && same_fetch_window(lookup_pc_i, invalidate_addr_i);
  wire fill_invalidated_w =
      invalidate_valid_i && same_fetch_window(fill_pc_i, invalidate_addr_i);

  assign lookup_context_hit_o =
      valid_q[lookup_idx_w] &&
      (paging_q[lookup_idx_w] == lookup_paging_i) &&
      (!lookup_paging_i ||
       ((priv_q[lookup_idx_w] == lookup_priv_i) &&
        (satp_q[lookup_idx_w] == lookup_satp_i)));
  assign lookup_hit_o =
      lookup_context_hit_o &&
      (pc_q[lookup_idx_w] == lookup_pc_i) &&
      !lookup_invalidated_w;
  assign lookup_inst0_o = inst0_q[lookup_idx_w];
  assign lookup_inst1_o = inst1_q[lookup_idx_w];
  assign lookup_resp0_o = resp0_q[lookup_idx_w];
  assign lookup_resp1_o = resp1_q[lookup_idx_w];

  integer invalidate_idx;

  always @(posedge clk) begin
    if (rst || clear_i) begin
      valid_q <= {ENTRY_COUNT{1'b0}};
    end else begin
      if (invalidate_valid_i) begin
        for (invalidate_idx = 0; invalidate_idx < ENTRY_COUNT;
             invalidate_idx = invalidate_idx + 1) begin
          if (valid_q[invalidate_idx] &&
              same_fetch_window(pc_q[invalidate_idx], invalidate_addr_i)) begin
            valid_q[invalidate_idx] <= 1'b0;
          end
        end
      end

      if (fill_valid_i && !fill_invalidated_w) begin
        valid_q[fill_idx_w] <= 1'b1;
        paging_q[fill_idx_w] <= fill_paging_i;
        priv_q[fill_idx_w] <= fill_priv_i;
        satp_q[fill_idx_w] <= fill_satp_i;
        pc_q[fill_idx_w] <= fill_pc_i;
        inst0_q[fill_idx_w] <= fill_inst0_i;
        inst1_q[fill_idx_w] <= fill_inst1_i;
        resp0_q[fill_idx_w] <= fill_resp0_i;
        resp1_q[fill_idx_w] <= fill_resp1_i;
      end
    end
  end

endmodule
