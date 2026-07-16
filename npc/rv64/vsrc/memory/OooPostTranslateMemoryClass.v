`include "define.v"

// Canonical post-translation memory attributes.
//
// The physical address map remains owned by OooPmaChecker and
// OooDataWordCache.  This module consumes those canonical facts and applies
// the leaf PBMT override exactly once.  In particular, an NC/IO mapping whose
// final PA lies in PMEM must not be admitted to D-cache.
module OooPostTranslateMemoryClass (
  input clk,
  input rst,
  input access_valid_i,
  input pma_fault_i,
  input address_cacheable_i,
  input pbmt_valid_i,
  input [1:0] pbmt_i,
  output pbmt_fault_o,
  output cacheable_o,
  output serialized_o
);

  wire pbmt_default_w = !pbmt_valid_i || (pbmt_i == 2'b00);
  wire pbmt_reserved_w = pbmt_valid_i && (pbmt_i == 2'b11);
  wire admitted_w = access_valid_i && !pma_fault_i && !pbmt_reserved_w;

  assign pbmt_fault_o = access_valid_i && pbmt_reserved_w;
  assign cacheable_o = admitted_w && address_cacheable_i && pbmt_default_w;
  assign serialized_o = admitted_w && !cacheable_o;

`ifdef OOO_ASSERT
  always @(posedge clk) begin
    if (!rst) begin
      if (cacheable_o && (pma_fault_i || pbmt_fault_o || serialized_o))
        $error("[POSTXLATE-CLASS-EXCLUSIVE] cacheable class overlaps fault/serialized @%0t",
               $time);
      if (access_valid_i && pbmt_valid_i &&
          ((pbmt_i == 2'b01) || (pbmt_i == 2'b10)) && cacheable_o)
        $error("[POSTXLATE-CLASS-PBMT] NC/IO PBMT entered D-cache @%0t", $time);
      if ((pma_fault_i || pbmt_fault_o) &&
          (cacheable_o || serialized_o))
        $error("[POSTXLATE-CLASS-FAULT] fault retained an admission class @%0t", $time);
    end
  end
`endif

endmodule
