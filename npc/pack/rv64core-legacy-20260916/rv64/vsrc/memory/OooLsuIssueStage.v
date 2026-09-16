`include "define.v"

// The post-register-read LSU transaction stage.  capture_i is the already
// authorized IQ pop + owner-token allocation edge.  consume_i is the exact
// request or local-completion handoff; kill/flush retire an unaccepted holder.
// Capture and consume may coincide only for the authorized pair refill.
// No request bypasses this stage, and no downstream ready enters its payload.
module OooLsuIssueStage #(
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W,
  parameter PRODUCER_ID_W = `OOO_PRODUCER_ID_W,
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W,
  parameter ALLOW_SPECIAL = 1
) (
  input clk,
  input rst,
  input flush_i,
  input kill_valid_i,
  input [ROB_INDEX_W-1:0] kill_rob_idx_i,
  input [ROB_INDEX_W-1:0] rob_head_idx_i,
  input capture_i,
  input consume_i,
  input [7:0] command_i,
  input [`INST_W-1:0] inst_i,
  input [PRODUCER_ID_W-1:0] producer_id_i,
  input [PHY_REG_ADDR_W-1:0] pdest_i,
  input fp_pdest_i,
  input fp_store_i,
  input [`XLEN-1:0] base_i,
  input [`XLEN-1:0] offset_i,
  input [`XLEN-1:0] store_data_i,
  input [4:0] owner_token_i,
  input [1:0] epoch_i,
  input translate_active_i,
  output reg valid_o,
  output kill_o,
  output [7:0] command_o,
  output [`INST_W-1:0] inst_o,
  output [PRODUCER_ID_W-1:0] producer_id_o,
  output [PHY_REG_ADDR_W-1:0] pdest_o,
  output fp_pdest_o,
  output fp_store_o,
  output [`XLEN-1:0] address_o,
  output [`XLEN-1:0] store_data_o,
  output [1:0] owner_kind_o,
  output [4:0] owner_token_o,
  output [1:0] epoch_o,
  output reg [`STRB_W-1:0] byte_mask_o,
  output reg misaligned_o,
  output cross_page_o,
  output exception_o
);
  // command = {load, store, amo, lr, sc, size[1:0], unsigned}.
  // Address is the same sum that the old reservation already captured as
  // fault_tval.  Keep this single value for both execution and fault identity,
  // instead of storing base/offset too and recomputing after the boundary.
  localparam PAYLOAD_W = 2*`XLEN + `INST_W + PRODUCER_ID_W +
                         PHY_REG_ADDR_W + 19;
  wire [`XLEN-1:0] capture_address_w = base_i + offset_i;
  wire [1:0] capture_kind_w =
      command_i[5] ? 2'b10 : command_i[6] ? 2'b01 : 2'b00;
  wire [PAYLOAD_W-1:0] capture_payload_w =
      {command_i, inst_i, producer_id_i, pdest_i, fp_pdest_i, fp_store_i,
       capture_address_w, store_data_i, capture_kind_w, owner_token_i, epoch_i};
  reg [PAYLOAD_W-1:0] payload_q;
  assign {command_o, inst_o, producer_id_o, pdest_o, fp_pdest_o, fp_store_o,
          address_o, store_data_o, owner_kind_o, owner_token_o, epoch_o} = payload_q;
  wire [ROB_INDEX_W-1:0] owner_age_w =
      producer_id_o[ROB_INDEX_W-1:0] - rob_head_idx_i;
  wire [ROB_INDEX_W-1:0] boundary_age_w = kill_rob_idx_i - rob_head_idx_i;
  assign kill_o = valid_o && kill_valid_i && (owner_age_w > boundary_age_w);

  always @(posedge clk) begin
    if (rst || flush_i) begin
      valid_o <= 1'b0;
      payload_q <= {PAYLOAD_W{1'b0}};
    end else if (kill_o) begin
      valid_o <= 1'b0;
    end else if (capture_i) begin
      valid_o <= 1'b1;
      payload_q <= capture_payload_w;
    end else if (consume_i) begin
      valid_o <= 1'b0;
    end
  end

  always @(*) begin
    byte_mask_o = {`STRB_W{1'b1}};
    misaligned_o = |address_o[`XLEN_BYTE_W-1:0];
    case (command_o[2:1])
      `MEM_SIZE_BYTE: begin
        byte_mask_o = {{(`STRB_W-1){1'b0}}, 1'b1};
        misaligned_o = 1'b0;
      end
      `MEM_SIZE_HALF: begin
        byte_mask_o = {{(`STRB_W-2){1'b0}}, 2'b11};
        misaligned_o = address_o[0];
      end
      `MEM_SIZE_WORD: begin
        byte_mask_o = {{(`STRB_W-4){1'b0}}, 4'b1111};
        misaligned_o = |address_o[1:0];
      end
      default: begin end
    endcase
  end
  wire [3:0] access_bytes_w = 4'd1 << command_o[2:1];
  assign cross_page_o = ({1'b0, address_o[11:0]} + {9'b0, access_bytes_w}) > 13'h1000;
  assign exception_o = valid_o &&
      ((command_o[5] && misaligned_o) ||
       (translate_active_i && (command_o[7] || command_o[6]) &&
        !command_o[5] && misaligned_o && cross_page_o));

`ifdef OOO_ASSERT
  reg check_valid_q;
  reg check_payload_q;
  reg expected_valid_q;
  reg [PAYLOAD_W-1:0] expected_payload_q;
  always @(posedge clk) begin
    if (rst) begin
      check_valid_q <= 1'b0;
      check_payload_q <= 1'b0;
      expected_valid_q <= 1'b0;
      expected_payload_q <= {PAYLOAD_W{1'b0}};
    end else begin
      if (check_valid_q && (valid_o !== expected_valid_q))
        $error("[LSU-ISSUE-LIFETIME] capture/consume/kill/flush valid transition mismatch @%0t", $time);
      if (check_payload_q && (payload_q !== expected_payload_q))
        $error("[LSU-ISSUE-PAYLOAD] captured or held command changed @%0t", $time);
      if (capture_i && valid_o && !consume_i && !kill_o && !flush_i)
        $error("[LSU-ISSUE-CAPACITY] capture overwrote a live transaction @%0t", $time);
      if (consume_i && !valid_o)
        $error("[LSU-ISSUE-CONSUME] handoff without a resident owner @%0t", $time);
      if (capture_i && !(command_i[7] || command_i[6] || command_i[5]))
        $error("[LSU-ISSUE-CLASS] non-memory command captured @%0t", $time);
      if (capture_i && (!ALLOW_SPECIAL) &&
          (command_i[5] || fp_pdest_i || fp_store_i))
        $error("[LSU-ISSUE-PLAIN-LANE] special command captured in plain-memory lane @%0t", $time);
      if (capture_i && command_i[5] && fp_store_i)
        $error("[LSU-ISSUE-AMO-DATA] atomic and FP-store data owners overlap @%0t", $time);
      check_valid_q <= 1'b1;
      expected_valid_q <= !flush_i && !kill_o &&
                          (capture_i || (valid_o && !consume_i));
      check_payload_q <= !flush_i && !kill_o && (capture_i || valid_o);
      expected_payload_q <= capture_i ? capture_payload_w : payload_q;
    end
  end
`endif
endmodule
