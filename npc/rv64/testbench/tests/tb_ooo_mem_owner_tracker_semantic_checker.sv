`timescale 1ns/1ps

// Verification-only checker for the public OooMemOwnerTracker contract.
//
// This module is intentionally outside the production RTL.  It makes the
// four-state simulation contract explicit without changing the synthesized
// owner tracker or its two-state allocation/death datapath.
module OooMemOwnerTrackerSemanticChecker #(
  parameter TOKEN_COUNT = 4,
  parameter TOKEN_W = 2,
  parameter KIND_W = 2,
  parameter EPOCH_W = 2,
  parameter COUNT_W = 3,
  parameter PRODUCER_ID_W = 4,
  parameter PRODUCER_COUNT = (1 << PRODUCER_ID_W)
) (
  input clk,
  input rst,

  input alloc0_valid_i,
  input [KIND_W-1:0] alloc0_kind_i,
  input [EPOCH_W-1:0] alloc0_epoch_i,
  input [PRODUCER_ID_W-1:0] alloc0_producer_id_i,
  input alloc1_valid_i,
  input [KIND_W-1:0] alloc1_kind_i,
  input [EPOCH_W-1:0] alloc1_epoch_i,
  input [PRODUCER_ID_W-1:0] alloc1_producer_id_i,

  input free0_valid_i,
  input [KIND_W-1:0] free0_kind_i,
  input [TOKEN_W-1:0] free0_token_i,
  input [EPOCH_W-1:0] free0_epoch_i,
  input free1_valid_i,
  input [KIND_W-1:0] free1_kind_i,
  input [TOKEN_W-1:0] free1_token_i,
  input [EPOCH_W-1:0] free1_epoch_i,
  input [TOKEN_COUNT-1:0] release_mask_i,

  input [TOKEN_COUNT-1:0] live_mask_i,
  input [TOKEN_COUNT*KIND_W-1:0] kind_table_i,
  input [TOKEN_COUNT*EPOCH_W-1:0] epoch_table_i,
  input [TOKEN_COUNT*PRODUCER_ID_W-1:0] producer_id_table_i,
  input [PRODUCER_COUNT-1:0] producer_live_mask_i,
  input [COUNT_W-1:0] live_count_i
);

  integer token_i;

  always @(posedge clk) begin
    if (!rst) begin
      if (alloc0_valid_i &&
          ((^alloc0_kind_i === 1'bx) ||
           (^alloc0_epoch_i === 1'bx) ||
           (^alloc0_producer_id_i === 1'bx))) begin
        $display("[V11C-TRACKER-ALLOC0-TUPLE-KNOWN] valid allocation tuple contains X");
        $fatal(1);
      end
      if (alloc1_valid_i &&
          ((^alloc1_kind_i === 1'bx) ||
           (^alloc1_epoch_i === 1'bx) ||
           (^alloc1_producer_id_i === 1'bx))) begin
        $display("[V11C-TRACKER-ALLOC1-TUPLE-KNOWN] valid allocation tuple contains X");
        $fatal(1);
      end
      if (free0_valid_i &&
          ((^free0_kind_i === 1'bx) ||
           (^free0_token_i === 1'bx) ||
           (^free0_epoch_i === 1'bx))) begin
        $display("[V11C-TRACKER-FREE0-TUPLE-KNOWN] valid terminal tuple contains X");
        $fatal(1);
      end
      if (free1_valid_i &&
          ((^free1_kind_i === 1'bx) ||
           (^free1_token_i === 1'bx) ||
           (^free1_epoch_i === 1'bx))) begin
        $display("[V11C-TRACKER-FREE1-TUPLE-KNOWN] valid terminal tuple contains X");
        $fatal(1);
      end
      if (^release_mask_i === 1'bx) begin
        $display("[V11C-TRACKER-RELEASE-MASK-KNOWN] release mask contains X");
        $fatal(1);
      end
      if (^live_mask_i === 1'bx) begin
        $display("[V11C-TRACKER-LIVE-MASK-KNOWN] registered live mask contains X");
        $fatal(1);
      end
      if ((^producer_live_mask_i === 1'bx) ||
          (^live_count_i === 1'bx)) begin
        $display("[V11C-TRACKER-LIVE-SUMMARY-KNOWN] registered lease summary contains X");
        $fatal(1);
      end

      for (token_i = 0; token_i < TOKEN_COUNT; token_i = token_i + 1) begin
        if (live_mask_i[token_i] &&
            ((^kind_table_i[token_i*KIND_W +: KIND_W] === 1'bx) ||
             (^epoch_table_i[token_i*EPOCH_W +: EPOCH_W] === 1'bx) ||
             (^producer_id_table_i[
                 token_i*PRODUCER_ID_W +: PRODUCER_ID_W] === 1'bx))) begin
          $display("[V11C-TRACKER-LIVE-TUPLE-KNOWN] live token=%0d has X metadata",
                   token_i);
          $fatal(1);
        end
        if (live_mask_i[token_i] &&
            !producer_live_mask_i[
              producer_id_table_i[
                token_i*PRODUCER_ID_W +: PRODUCER_ID_W]]) begin
          $display("[V11C-TRACKER-LIVE-MAP-MEMBER] live token=%0d lacks ProducerId membership",
                   token_i);
          $fatal(1);
        end
      end
    end
  end

endmodule
