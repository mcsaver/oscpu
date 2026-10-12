`include "R64Protocol.vh"
// Registered permission to finish one precise memory head. Once granted it is
// irrevocable until that exact head presents its terminal completion, including
// a fault. Recovery never revokes an accepted external effect.
module R64MemoryEffectLease #(
  parameter TAG_W = 9,
  parameter SUCCESSOR_STORE_LEASE = 0,
  parameter ORDINARY_SUCCESSOR_STORE_LEASE = 0,
  parameter DUAL_RETIRE_STORE_LEASE = 0
) (
  input clk_i, rst_i,
  input head_present_i,
  input [TAG_W-1:0] head_tag_i,
  input [7:0] head_kind_i,
  input head_complete_i,
  input allow_i,
  input recover_i,
  input flush_i,
  input successor_grant_i,
  input [TAG_W-1:0] successor_tag_i,
  output reg valid_o,
  output reg [TAG_W-1:0] tag_o
);
  wire memory_head = head_kind_i == `R64_K_LOAD ||
                     head_kind_i == `R64_K_STORE ||
                     head_kind_i == `R64_K_AMO;
  wire grant = !valid_o && head_present_i && memory_head &&
               !head_complete_i && allow_i && !recover_i && !flush_i;
  // Control certifies an actual retirement prefix, never just terminal arrival.
  // A previously completed head may have released its lease while Trace held
  // retirement, so the same install also works when the old lease is empty.
  wire successor_predecessor = (SUCCESSOR_STORE_LEASE != 0 && head_kind_i == `R64_K_STORE) ||
      ((ORDINARY_SUCCESSOR_STORE_LEASE != 0 || DUAL_RETIRE_STORE_LEASE != 0) &&
       (head_kind_i == `R64_K_NORMAL ||
       head_kind_i == `R64_K_BRANCH || head_kind_i == `R64_K_LOAD || head_kind_i == `R64_K_STORE));
  wire successor_install = successor_predecessor && successor_grant_i &&
      head_present_i && head_complete_i &&
      allow_i && !recover_i && !flush_i && (!valid_o || tag_o == head_tag_i);
  always @(posedge clk_i) begin
    if (rst_i) begin valid_o <= 0; tag_o <= 0; end
    else if (successor_install) begin
      valid_o <= 1;
      tag_o <= successor_tag_i;
    end else if (valid_o) begin
      if (head_present_i && head_tag_i == tag_o && head_complete_i)
        valid_o <= 0;
    end else if (grant) begin
      valid_o <= 1;
      tag_o <= head_tag_i;
    end
  end
`ifdef R64_ASSERT
  always @(posedge clk_i) if (!rst_i && valid_o) begin
    if (!head_present_i || head_tag_i != tag_o)
      $fatal(1, "Memory effect lease lost its precise ROB head");
    if (flush_i)
      $fatal(1, "Precise flush crossed a memory effect lease");
  end
`endif
endmodule
