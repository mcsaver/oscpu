`include "define.v"

module OooDataWordCache #(
  parameter INDEX_W = 10,
  parameter ENTRY_COUNT = (1 << INDEX_W)
) (
  input clk,
  input rst,

  input [`XLEN-1:0] req_lookup_addr_i,
  output req_cacheable_o,
  output req_hit_o,
  output [`XLEN-1:0] req_data_o,

  input [`XLEN-1:0] walk_lookup_addr_i,
  output walk_cacheable_o,
  output walk_hit_o,
  output [`XLEN-1:0] walk_data_o,

  input fill_valid_i,
  input [`XLEN-1:0] fill_addr_i,
  input [`XLEN-1:0] fill_data_i,

  input store_commit_i,
  input store_invalidate_all_i,
  input [`XLEN-1:0] store_addr_i,
  input [`XLEN-1:0] store_data_i,
  input [`STRB_W-1:0] store_wstrb_i
);

  reg [ENTRY_COUNT-1:0] valid_q;
  reg [`XLEN-1:0] addr_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] data_q [0:ENTRY_COUNT-1];

  function [INDEX_W-1:0] cache_index;
    input [`XLEN-1:0] addr;
    begin
      cache_index = addr[INDEX_W+`XLEN_BYTE_W-1:`XLEN_BYTE_W];
    end
  endfunction

  function cacheable_addr;
    input [`XLEN-1:0] addr;
    begin
      cacheable_addr = ((addr & `NPC_AXI_PMEM_MASK) == `NPC_AXI_PMEM_BASE);
    end
  endfunction

  function [`XLEN-1:0] merge_wstrb64;
    input [`XLEN-1:0] old_data;
    input [`XLEN-1:0] new_data;
    input [`STRB_W-1:0] mask;
    begin
      // RV64 数据 cache 只在 64-bit word 粒度存储；显式 8-lane mux
      // 比按 strobe 循环改写更容易审查综合后的 byte-enable 数据通路。
      merge_wstrb64 = {
          mask[7] ? new_data[63:56] : old_data[63:56],
          mask[6] ? new_data[55:48] : old_data[55:48],
          mask[5] ? new_data[47:40] : old_data[47:40],
          mask[4] ? new_data[39:32] : old_data[39:32],
          mask[3] ? new_data[31:24] : old_data[31:24],
          mask[2] ? new_data[23:16] : old_data[23:16],
          mask[1] ? new_data[15:8]  : old_data[15:8],
          mask[0] ? new_data[7:0]   : old_data[7:0]
      };
    end
  endfunction

  wire [INDEX_W-1:0] req_idx_w = cache_index(req_lookup_addr_i);
  wire [INDEX_W-1:0] walk_idx_w = cache_index(walk_lookup_addr_i);
  wire [INDEX_W-1:0] fill_idx_w = cache_index(fill_addr_i);
  wire [INDEX_W-1:0] store_idx_w = cache_index(store_addr_i);
  wire store_cacheable_w = cacheable_addr(store_addr_i);
  wire store_hit_w =
      store_cacheable_w && valid_q[store_idx_w] &&
      (addr_q[store_idx_w] == store_addr_i);

  assign req_cacheable_o = cacheable_addr(req_lookup_addr_i);
  assign req_hit_o =
      req_cacheable_o && valid_q[req_idx_w] &&
      (addr_q[req_idx_w] == req_lookup_addr_i);
  assign req_data_o = data_q[req_idx_w];

  assign walk_cacheable_o = cacheable_addr(walk_lookup_addr_i);
  assign walk_hit_o =
      walk_cacheable_o && valid_q[walk_idx_w] &&
      (addr_q[walk_idx_w] == walk_lookup_addr_i);
  assign walk_data_o = data_q[walk_idx_w];

  always @(posedge clk) begin
    if (rst) begin
      valid_q <= {ENTRY_COUNT{1'b0}};
    end else begin
      if (fill_valid_i && cacheable_addr(fill_addr_i)) begin
        valid_q[fill_idx_w] <= 1'b1;
        addr_q[fill_idx_w] <= fill_addr_i;
        data_q[fill_idx_w] <= fill_data_i;
      end

      if (store_commit_i) begin
        if (store_invalidate_all_i) begin
          valid_q <= {ENTRY_COUNT{1'b0}};
        end

        if (store_cacheable_w) begin
          if (store_hit_w) begin
            valid_q[store_idx_w] <= 1'b1;
            addr_q[store_idx_w] <= store_addr_i;
            data_q[store_idx_w] <=
                merge_wstrb64(data_q[store_idx_w], store_data_i,
                              store_wstrb_i);
          end else if (store_wstrb_i == {`STRB_W{1'b1}}) begin
            valid_q[store_idx_w] <= 1'b1;
            addr_q[store_idx_w] <= store_addr_i;
            data_q[store_idx_w] <= store_data_i;
          end
        end
      end
    end
  end

endmodule
