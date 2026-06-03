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

  function [`XLEN-1:0] merge_wstrb;
    input [`XLEN-1:0] old_data;
    input [`XLEN-1:0] new_data;
    input [`STRB_W-1:0] mask;
    integer byte_idx;
    begin
      merge_wstrb = old_data;
      for (byte_idx = 0; byte_idx < `STRB_W; byte_idx = byte_idx + 1) begin
        if (mask[byte_idx]) begin
          merge_wstrb[byte_idx*8 +: 8] = new_data[byte_idx*8 +: 8];
        end
      end
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
            data_q[store_idx_w] <=
                merge_wstrb(data_q[store_idx_w], store_data_i,
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
