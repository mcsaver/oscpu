// OooFetchPacketCache 外部观测 checker。
// 只用于仿真/测试的 debug 层：读真实端口，投影 common facts，并审核 cache-visible spec 语义。
`include "define.v"
`include "common/OooFetchPacketCacheFacts.vh"

module OooFetchPacketCacheChecker (
  input wire clk,
  input wire rst,
  input wire clear_i,

  input wire lookup_paging_i,
  input wire [1:0] lookup_priv_i,
  input wire [`XLEN-1:0] lookup_satp_i,
  input wire [`XLEN-1:0] lookup_pc_i,
  input wire lookup_context_hit_i,
  input wire lookup_hit_i,

  input wire fill_valid_i,
  input wire fill_paging_i,
  input wire [1:0] fill_priv_i,
  input wire [`XLEN-1:0] fill_satp_i,
  input wire [`XLEN-1:0] fill_pc_i,

  input wire invalidate_valid_i,
  input wire [`XLEN-1:0] invalidate_addr_i
);

  function same_fetch_window;
    input [`XLEN-1:0] fetch_pc;
    input [`XLEN-1:0] store_addr;
    begin
      same_fetch_window =
          ((store_addr & {{(`XLEN-2){1'b1}}, 2'b00}) <=
           (fetch_pc + {{(`XLEN-3){1'b0}}, 3'd7})) &&
          (((store_addr & {{(`XLEN-2){1'b1}}, 2'b00}) +
            {{(`XLEN-3){1'b0}}, 3'd7}) >= fetch_pc);
    end
  endfunction

  wire lookup_invalidated_w =
      invalidate_valid_i && same_fetch_window(lookup_pc_i, invalidate_addr_i);
  wire fill_blocked_by_store_w =
      fill_valid_i && invalidate_valid_i &&
      same_fetch_window(fill_pc_i, invalidate_addr_i);

  wire [`OOO_FPC_FACTS_W-1:0] facts_w;
  assign facts_w[`OOO_FPC_LOOKUP_CONTEXT_HIT] = lookup_context_hit_i;
  assign facts_w[`OOO_FPC_LOOKUP_HIT] = lookup_hit_i;
  assign facts_w[`OOO_FPC_LOOKUP_INVALIDATED] = lookup_invalidated_w;
  assign facts_w[`OOO_FPC_FILL] = fill_valid_i;
  assign facts_w[`OOO_FPC_FILL_BLOCKED_BY_STORE] = fill_blocked_by_store_w;
  assign facts_w[`OOO_FPC_INVALIDATE] = invalidate_valid_i;
  assign facts_w[`OOO_FPC_CLEAR] = clear_i;
  assign facts_w[`OOO_FPC_PAGED_LOOKUP] = lookup_paging_i;
  assign facts_w[`OOO_FPC_BARE_LOOKUP] = !lookup_paging_i;

  wire _unused_facts_w =
      |facts_w | (|lookup_priv_i) | (|lookup_satp_i) |
      (|fill_priv_i) | (|fill_satp_i) | fill_paging_i;

`ifdef OOO_ASSERT
  always @(posedge clk) begin
    if (!rst && lookup_hit_i && !lookup_context_hit_i) begin
      $error("[FPC-HIT-GATE] lookup_hit requires lookup_context_hit: pc=%h @%0t",
             lookup_pc_i, $time);
      $fatal;
    end
  end

  always @(posedge clk) begin
    if (!rst && lookup_hit_i && lookup_invalidated_w) begin
      $error("[FPC-LOOKUP-INVALIDATED] same-cycle store footprint must block hit: pc=%h store=%h @%0t",
             lookup_pc_i, invalidate_addr_i, $time);
      $fatal;
    end
  end
`endif

endmodule
