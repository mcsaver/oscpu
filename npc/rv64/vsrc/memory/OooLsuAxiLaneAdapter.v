`include "define.v"

// Owned logical-window -> standard AXI byte-lane adapter.  Transactions use
// registered state except for the narrow legal aligned-write admission offer
// documented below; backpressure always falls back to the same registers.
//
// Upstream contract:
//   * address is the exact first-byte address;
//   * data and WSTRB are packed from lane 0;
//   * AxSIZE is authoritative and only 1/2/4/8-byte accesses are legal.
// Downstream contract:
//   * AxADDR/AxSIZE obey natural alignment for every beat;
//   * WDATA/WSTRB and RDATA use the standard address-selected byte lanes.
//
// Misaligned requests are split into byte beats only when split_allowed_i is
// true.  The core drives it only for ordinary PMEM after whole-access
// translation/PMP/PMA qualification.  MMIO/PTE accesses therefore never gain
// extra read/write side effects through this adapter.
module OooLsuAxiLaneAdapter #(
  parameter XLEN = `XLEN,
  parameter STRB_W = `STRB_W
) (
  input clk,
  input rst,

  input u_axi_split_allowed_i,

  input u_axi_arvalid_i,
  output u_axi_arready_o,
  input [XLEN-1:0] u_axi_araddr_i,
  input [2:0] u_axi_arsize_i,
  input [2:0] u_axi_arprot_i,
  output u_axi_rvalid_o,
  input u_axi_rready_i,
  output [XLEN-1:0] u_axi_rdata_o,
  output [1:0] u_axi_rresp_o,

  input u_axi_awvalid_i,
  output u_axi_awready_o,
  input [XLEN-1:0] u_axi_awaddr_i,
  input [2:0] u_axi_awsize_i,
  input u_axi_wvalid_i,
  output u_axi_wready_o,
  input [XLEN-1:0] u_axi_wdata_i,
  input [STRB_W-1:0] u_axi_wstrb_i,
  output u_axi_bvalid_o,
  input u_axi_bready_i,
  output [1:0] u_axi_bresp_o,

  output d_axi_arvalid_o,
  input d_axi_arready_i,
  output [XLEN-1:0] d_axi_araddr_o,
  output [2:0] d_axi_arsize_o,
  output [2:0] d_axi_arprot_o,
  input d_axi_rvalid_i,
  output d_axi_rready_o,
  input [XLEN-1:0] d_axi_rdata_i,
  input [1:0] d_axi_rresp_i,

  output d_axi_awvalid_o,
  input d_axi_awready_i,
  output [XLEN-1:0] d_axi_awaddr_o,
  output [2:0] d_axi_awsize_o,
  output d_axi_wvalid_o,
  input d_axi_wready_i,
  output [XLEN-1:0] d_axi_wdata_o,
  output [STRB_W-1:0] d_axi_wstrb_o,
  input d_axi_bvalid_i,
  output d_axi_bready_o,
  input [1:0] d_axi_bresp_i
);

  localparam integer LANE_BITS = $clog2(STRB_W);

  localparam [2:0] S_IDLE    = 3'd0;
  localparam [2:0] S_R_ADDR  = 3'd1;
  localparam [2:0] S_R_DATA  = 3'd2;
  localparam [2:0] S_R_RESP  = 3'd3;
  localparam [2:0] S_W_SEND  = 3'd4;
  localparam [2:0] S_W_RESP  = 3'd5;
  localparam [2:0] S_B_RESP  = 3'd6;

  function [3:0] bytes_from_size;
    input [2:0] size;
    begin
      case (size)
        3'd0: bytes_from_size = 4'd1;
        3'd1: bytes_from_size = 4'd2;
        3'd2: bytes_from_size = 4'd4;
        3'd3: bytes_from_size = 4'd8;
        default: bytes_from_size = 4'd0;
      endcase
    end
  endfunction

  function [STRB_W-1:0] low_mask_from_size;
    input [2:0] size;
    begin
      case (size)
        3'd0: low_mask_from_size = 8'h01;
        3'd1: low_mask_from_size = 8'h03;
        3'd2: low_mask_from_size = 8'h0f;
        3'd3: low_mask_from_size = 8'hff;
        default: low_mask_from_size = {STRB_W{1'b0}};
      endcase
    end
  endfunction

  function naturally_aligned;
    input [XLEN-1:0] addr;
    input [2:0] size;
    begin
      case (size)
        3'd0: naturally_aligned = 1'b1;
        3'd1: naturally_aligned = !addr[0];
        3'd2: naturally_aligned = !(|addr[1:0]);
        3'd3: naturally_aligned = !(|addr[2:0]);
        default: naturally_aligned = 1'b0;
      endcase
    end
  endfunction

  function [XLEN-1:0] data_mask_from_size;
    input [2:0] size;
    begin
      case (size)
        3'd0: data_mask_from_size = {{(XLEN-8){1'b0}}, 8'hff};
        3'd1: data_mask_from_size = {{(XLEN-16){1'b0}}, 16'hffff};
        3'd2: data_mask_from_size = {{(XLEN-32){1'b0}}, 32'hffff_ffff};
        3'd3: data_mask_from_size = {XLEN{1'b1}};
        default: data_mask_from_size = {XLEN{1'b0}};
      endcase
    end
  endfunction

  function [1:0] sticky_resp;
    input [1:0] old_resp;
    input [1:0] new_resp;
    begin
      sticky_resp = (old_resp != 2'b00) ? old_resp : new_resp;
    end
  endfunction

  reg [2:0] state_q;

  // Independent upstream AW/W capture.  Either half blocks reads, and neither
  // is cleared until a complete logical command has been formed.
  reg aw_hold_q;
  reg [XLEN-1:0] awaddr_q;
  reg [2:0] awsize_q;
  reg aw_split_allowed_q;
  reg w_hold_q;
  reg [XLEN-1:0] wdata_q;
  reg [STRB_W-1:0] wstrb_q;

  reg [XLEN-1:0] cmd_addr_q;
  reg [2:0] cmd_size_q;
  reg [3:0] cmd_nbytes_q;
  reg cmd_split_q;
  reg [XLEN-1:0] cmd_wdata_q;
  reg [3:0] beat_idx_q;
  reg [1:0] resp_accum_q;
  reg [XLEN-1:0] read_accum_q;

  reg [XLEN-1:0] d_araddr_q;
  reg [2:0] d_arsize_q;
  reg [2:0] d_arprot_q;
  reg [XLEN-1:0] d_awaddr_q;
  reg [2:0] d_awsize_q;
  reg [XLEN-1:0] d_wdata_q;
  reg [STRB_W-1:0] d_wstrb_q;
  reg d_aw_sent_q;
  reg d_w_sent_q;

  reg [XLEN-1:0] u_rdata_q;
  reg [1:0] u_rresp_q;
  reg [1:0] u_bresp_q;

  wire idle_w = (state_q == S_IDLE);
  assign u_axi_awready_o = idle_w && !aw_hold_q;
  assign u_axi_wready_o = idle_w && !w_hold_q;
  // Write priority is explicit for a same-cycle read/write request.  This
  // closes the window in which a miss could overtake a selected store drain.
  assign u_axi_arready_o = idle_w && !aw_hold_q && !w_hold_q &&
                           !u_axi_awvalid_i && !u_axi_wvalid_i;

  wire u_ar_fire_w = u_axi_arvalid_i && u_axi_arready_o;
  wire u_aw_fire_w = u_axi_awvalid_i && u_axi_awready_o;
  wire u_w_fire_w = u_axi_wvalid_i && u_axi_wready_o;

  wire eff_aw_valid_w = aw_hold_q || u_aw_fire_w;
  wire [XLEN-1:0] eff_awaddr_w = aw_hold_q ? awaddr_q : u_axi_awaddr_i;
  wire [2:0] eff_awsize_w = aw_hold_q ? awsize_q : u_axi_awsize_i;
  wire eff_aw_split_allowed_w = aw_hold_q ? aw_split_allowed_q :
                                           u_axi_split_allowed_i;
  wire eff_w_valid_w = w_hold_q || u_w_fire_w;
  wire [XLEN-1:0] eff_wdata_w = w_hold_q ? wdata_q : u_axi_wdata_i;
  wire [STRB_W-1:0] eff_wstrb_w = w_hold_q ? wstrb_q : u_axi_wstrb_i;
  wire [3:0] eff_write_nbytes_w = bytes_from_size(eff_awsize_w);
  wire eff_write_size_ok_w = (eff_write_nbytes_w != 4'd0) &&
                             (eff_write_nbytes_w <= STRB_W);
  wire eff_write_natural_w = naturally_aligned(eff_awaddr_w, eff_awsize_w);
  wire eff_write_mask_ok_w =
      (eff_wstrb_w == low_mask_from_size(eff_awsize_w));
  wire [LANE_BITS-1:0] write_lane_w =
      eff_awaddr_w[LANE_BITS-1:0];

  // A complete, legal naturally aligned write may use the admission cycle as
  // its first downstream send cycle.  This remains a VALID-only forward path:
  // upstream READY above is derived exclusively from local state/holders and
  // never from either downstream READY.  Partial/invalid/split commands retain
  // the registered path so no externally visible beat can precede validation.
  wire direct_write_offer_w = !rst && idle_w &&
                              eff_aw_valid_w && eff_w_valid_w &&
                              eff_write_size_ok_w && eff_write_mask_ok_w &&
                              eff_write_natural_w;
  wire [XLEN-1:0] direct_wdata_w =
      eff_wdata_w << (write_lane_w * 8);
  wire [STRB_W-1:0] direct_wstrb_w =
      eff_wstrb_w << write_lane_w;

  assign u_axi_rvalid_o = (state_q == S_R_RESP);
  assign u_axi_rdata_o = u_rdata_q;
  assign u_axi_rresp_o = u_rresp_q;

  assign d_axi_arvalid_o = (state_q == S_R_ADDR);
  assign d_axi_araddr_o = d_araddr_q;
  assign d_axi_arsize_o = d_arsize_q;
  assign d_axi_arprot_o = d_arprot_q;
  assign d_axi_rready_o = (state_q == S_R_DATA);
  assign d_axi_awvalid_o = direct_write_offer_w ||
                           ((state_q == S_W_SEND) && !d_aw_sent_q);
  assign d_axi_awaddr_o = direct_write_offer_w ? eff_awaddr_w : d_awaddr_q;
  assign d_axi_awsize_o = direct_write_offer_w ? eff_awsize_w : d_awsize_q;
  assign d_axi_wvalid_o = direct_write_offer_w ||
                          ((state_q == S_W_SEND) && !d_w_sent_q);
  assign d_axi_wdata_o = direct_write_offer_w ? direct_wdata_w : d_wdata_q;
  assign d_axi_wstrb_o = direct_write_offer_w ? direct_wstrb_w : d_wstrb_q;
  assign d_axi_bready_o = (state_q == S_W_RESP);

  wire d_ar_fire_w = d_axi_arvalid_o && d_axi_arready_i;
  wire d_aw_fire_w = d_axi_awvalid_o && d_axi_awready_i;
  wire d_w_fire_w = d_axi_wvalid_o && d_axi_wready_i;
  wire [1:0] resp_with_r_w = sticky_resp(resp_accum_q, d_axi_rresp_i);
  wire [1:0] resp_with_b_w = sticky_resp(resp_accum_q, d_axi_bresp_i);
  wire [LANE_BITS-1:0] current_read_lane_w =
      d_araddr_q[LANE_BITS-1:0];
  wire [LANE_BITS-1:0] natural_read_lane_w =
      cmd_addr_q[LANE_BITS-1:0];
  wire [7:0] current_read_byte_w =
      d_axi_rdata_i >> (current_read_lane_w * 8);
  wire [XLEN-1:0] read_accum_with_byte_w =
      read_accum_q |
      ({{(XLEN-8){1'b0}}, current_read_byte_w} <<
       {beat_idx_q[2:0], 3'b000});
  wire [XLEN-1:0] natural_read_window_w =
      (d_axi_rdata_i >> (natural_read_lane_w * 8)) &
      data_mask_from_size(cmd_size_q);
  wire [3:0] next_beat_idx_w = beat_idx_q + 4'd1;
  wire split_write_more_beats_w =
      cmd_split_q && (next_beat_idx_w < cmd_nbytes_q);
  // The target B is already a registered terminal.  Let only the final
  // logical-write beat fall through to the upstream owner; a stalled owner is
  // captured by the existing S_B_RESP register on the same edge.  Keeping
  // downstream BREADY state-only avoids a READY loop through the crossbar.
  wire final_b_fallthrough_w = !rst && (state_q == S_W_RESP) &&
                               d_axi_bvalid_i &&
                               !split_write_more_beats_w;
  assign u_axi_bvalid_o = (state_q == S_B_RESP) ||
                          final_b_fallthrough_w;
  assign u_axi_bresp_o = final_b_fallthrough_w ? resp_with_b_w :
                                                    u_bresp_q;
  wire [XLEN-1:0] next_write_addr_w = d_awaddr_q + {{(XLEN-1){1'b0}}, 1'b1};
  wire [LANE_BITS-1:0] next_write_lane_w =
      next_write_addr_w[LANE_BITS-1:0];
  wire [7:0] next_write_byte_w =
      cmd_wdata_q >> {next_beat_idx_w[2:0], 3'b000};

  always @(posedge clk) begin
    if (rst) begin
      state_q <= S_IDLE;
      aw_hold_q <= 1'b0;
      awaddr_q <= {XLEN{1'b0}};
      awsize_q <= 3'd0;
      aw_split_allowed_q <= 1'b0;
      w_hold_q <= 1'b0;
      wdata_q <= {XLEN{1'b0}};
      wstrb_q <= {STRB_W{1'b0}};
      cmd_addr_q <= {XLEN{1'b0}};
      cmd_size_q <= 3'd0;
      cmd_nbytes_q <= 4'd0;
      cmd_split_q <= 1'b0;
      cmd_wdata_q <= {XLEN{1'b0}};
      beat_idx_q <= 4'd0;
      resp_accum_q <= 2'b00;
      read_accum_q <= {XLEN{1'b0}};
      d_araddr_q <= {XLEN{1'b0}};
      d_arsize_q <= 3'd0;
      d_arprot_q <= 3'd0;
      d_awaddr_q <= {XLEN{1'b0}};
      d_awsize_q <= 3'd0;
      d_wdata_q <= {XLEN{1'b0}};
      d_wstrb_q <= {STRB_W{1'b0}};
      d_aw_sent_q <= 1'b0;
      d_w_sent_q <= 1'b0;
      u_rdata_q <= {XLEN{1'b0}};
      u_rresp_q <= 2'b00;
      u_bresp_q <= 2'b00;
    end else begin
      case (state_q)
        S_IDLE: begin
          d_aw_sent_q <= 1'b0;
          d_w_sent_q <= 1'b0;

          if (u_aw_fire_w) begin
            aw_hold_q <= 1'b1;
            awaddr_q <= u_axi_awaddr_i;
            awsize_q <= u_axi_awsize_i;
            aw_split_allowed_q <= u_axi_split_allowed_i;
          end
          if (u_w_fire_w) begin
            w_hold_q <= 1'b1;
            wdata_q <= u_axi_wdata_i;
            wstrb_q <= u_axi_wstrb_i;
          end

          if (eff_aw_valid_w && eff_w_valid_w) begin
            aw_hold_q <= 1'b0;
            w_hold_q <= 1'b0;
            cmd_addr_q <= eff_awaddr_w;
            cmd_size_q <= eff_awsize_w;
            cmd_nbytes_q <= eff_write_nbytes_w;
            cmd_wdata_q <= eff_wdata_w;
            beat_idx_q <= 4'd0;
            resp_accum_q <= 2'b00;
            d_aw_sent_q <= 1'b0;
            d_w_sent_q <= 1'b0;
            if (!eff_write_size_ok_w || !eff_write_mask_ok_w ||
                (!eff_write_natural_w && !eff_aw_split_allowed_w)) begin
              // Invalid/sparse or side-effectful misaligned write: fail before
              // presenting either downstream channel.
              u_bresp_q <= 2'b11;
              state_q <= S_B_RESP;
            end else if (eff_write_natural_w) begin
              cmd_split_q <= 1'b0;
              d_awaddr_q <= eff_awaddr_w;
              d_awsize_q <= eff_awsize_w;
              d_wdata_q <= direct_wdata_w;
              d_wstrb_q <= direct_wstrb_w;
              // E0 acceptance is independent per AXI channel.  A channel that
              // fires here is recorded as sent; S_W_SEND therefore retries
              // only the unaccepted channel.  Dual acceptance proceeds
              // directly to the registered downstream-B owner.
              d_aw_sent_q <= d_aw_fire_w;
              d_w_sent_q <= d_w_fire_w;
              state_q <= (d_aw_fire_w && d_w_fire_w) ? S_W_RESP : S_W_SEND;
            end else begin
              cmd_split_q <= 1'b1;
              d_awaddr_q <= eff_awaddr_w;
              d_awsize_q <= 3'd0;
              d_wdata_q <=
                  ({{(XLEN-8){1'b0}}, eff_wdata_w[7:0]} <<
                   (write_lane_w * 8));
              d_wstrb_q <= {{(STRB_W-1){1'b0}}, 1'b1} <<
                           write_lane_w;
              state_q <= S_W_SEND;
            end
          end else if (u_ar_fire_w) begin
            cmd_addr_q <= u_axi_araddr_i;
            cmd_size_q <= u_axi_arsize_i;
            cmd_nbytes_q <= bytes_from_size(u_axi_arsize_i);
            beat_idx_q <= 4'd0;
            resp_accum_q <= 2'b00;
            read_accum_q <= {XLEN{1'b0}};
            d_arprot_q <= u_axi_arprot_i;
            if ((bytes_from_size(u_axi_arsize_i) == 4'd0) ||
                (bytes_from_size(u_axi_arsize_i) > STRB_W)) begin
              u_rdata_q <= {XLEN{1'b0}};
              u_rresp_q <= 2'b11;
              state_q <= S_R_RESP;
            end else if (naturally_aligned(u_axi_araddr_i,
                                           u_axi_arsize_i)) begin
              cmd_split_q <= 1'b0;
              d_araddr_q <= u_axi_araddr_i;
              d_arsize_q <= u_axi_arsize_i;
              state_q <= S_R_ADDR;
            end else if (u_axi_split_allowed_i) begin
              cmd_split_q <= 1'b1;
              d_araddr_q <= u_axi_araddr_i;
              d_arsize_q <= 3'd0;
              state_q <= S_R_ADDR;
            end else begin
              u_rdata_q <= {XLEN{1'b0}};
              u_rresp_q <= 2'b11;
              state_q <= S_R_RESP;
            end
          end
        end

        S_R_ADDR: begin
          if (d_ar_fire_w)
            state_q <= S_R_DATA;
        end

        S_R_DATA: begin
          if (d_axi_rvalid_i) begin
            if (cmd_split_q && (next_beat_idx_w < cmd_nbytes_q)) begin
              read_accum_q <= read_accum_with_byte_w;
              resp_accum_q <= resp_with_r_w;
              beat_idx_q <= next_beat_idx_w;
              d_araddr_q <= d_araddr_q + {{(XLEN-1){1'b0}}, 1'b1};
              d_arsize_q <= 3'd0;
              state_q <= S_R_ADDR;
            end else begin
              u_rdata_q <= cmd_split_q ? read_accum_with_byte_w :
                                         natural_read_window_w;
              u_rresp_q <= resp_with_r_w;
              state_q <= S_R_RESP;
            end
          end
        end

        S_R_RESP: begin
          if (u_axi_rready_i)
            state_q <= S_IDLE;
        end

        S_W_SEND: begin
          if (d_aw_fire_w)
            d_aw_sent_q <= 1'b1;
          if (d_w_fire_w)
            d_w_sent_q <= 1'b1;
          if ((d_aw_sent_q || d_aw_fire_w) &&
              (d_w_sent_q || d_w_fire_w)) begin
            d_aw_sent_q <= 1'b0;
            d_w_sent_q <= 1'b0;
            state_q <= S_W_RESP;
          end
        end

        S_W_RESP: begin
          if (d_axi_bvalid_i) begin
            if (split_write_more_beats_w) begin
              resp_accum_q <= resp_with_b_w;
              beat_idx_q <= next_beat_idx_w;
              d_awaddr_q <= next_write_addr_w;
              d_awsize_q <= 3'd0;
              d_wdata_q <=
                  ({{(XLEN-8){1'b0}}, next_write_byte_w} <<
                   (next_write_lane_w * 8));
              d_wstrb_q <= {{(STRB_W-1){1'b0}}, 1'b1} <<
                           next_write_lane_w;
              d_aw_sent_q <= 1'b0;
              d_w_sent_q <= 1'b0;
              state_q <= S_W_SEND;
            end else begin
              u_bresp_q <= resp_with_b_w;
              state_q <= u_axi_bready_i ? S_IDLE : S_B_RESP;
            end
          end
        end

        S_B_RESP: begin
          if (u_axi_bready_i)
            state_q <= S_IDLE;
        end

        default: state_q <= S_IDLE;
      endcase
    end
  end

`ifdef OOO_ASSERT
  reg ar_stall_q;
  reg aw_stall_q;
  reg w_stall_q;
  reg u_b_stall_q;
  reg [XLEN-1:0] araddr_stall_q;
  reg [2:0] arsize_stall_q;
  reg [2:0] arprot_stall_q;
  reg [XLEN-1:0] awaddr_stall_q;
  reg [2:0] awsize_stall_q;
  reg [XLEN-1:0] wdata_stall_q;
  reg [STRB_W-1:0] wstrb_stall_q;
  reg [1:0] u_bresp_stall_q;
  always @(posedge clk) begin
    if (rst) begin
      ar_stall_q <= 1'b0;
      aw_stall_q <= 1'b0;
      w_stall_q <= 1'b0;
      u_b_stall_q <= 1'b0;
    end else begin
      if (ar_stall_q &&
          (!d_axi_arvalid_o || d_axi_araddr_o !== araddr_stall_q ||
           d_axi_arsize_o !== arsize_stall_q ||
           d_axi_arprot_o !== arprot_stall_q)) begin
        $error("[LANE-AR-HOLD] downstream AR changed while stalled @%0t", $time);
        $fatal;
      end
      if (aw_stall_q &&
          (!d_axi_awvalid_o || d_axi_awaddr_o !== awaddr_stall_q ||
           d_axi_awsize_o !== awsize_stall_q)) begin
        $error("[LANE-AW-HOLD] downstream AW changed while stalled @%0t", $time);
        $fatal;
      end
      if (w_stall_q &&
          (!d_axi_wvalid_o || d_axi_wdata_o !== wdata_stall_q ||
           d_axi_wstrb_o !== wstrb_stall_q)) begin
        $error("[LANE-W-HOLD] downstream W changed while stalled @%0t", $time);
        $fatal;
      end
      if (u_b_stall_q &&
          (!u_axi_bvalid_o || u_axi_bresp_o !== u_bresp_stall_q)) begin
        $error("[LANE-B-HOLD] upstream B changed while stalled @%0t", $time);
        $fatal;
      end
      if ((state_q == S_W_RESP) && d_axi_bvalid_i &&
          split_write_more_beats_w && u_axi_bvalid_o) begin
        $error("[LANE-B-SPLIT] non-final split B escaped upstream @%0t", $time);
        $fatal;
      end
      if (final_b_fallthrough_w &&
          (!u_axi_bvalid_o || u_axi_bresp_o !== resp_with_b_w)) begin
        $error("[LANE-B-FALLTHROUGH] final B response mismatch @%0t", $time);
        $fatal;
      end
      if ((state_q == S_IDLE) &&
          (d_axi_awvalid_o || d_axi_wvalid_o) &&
          (!direct_write_offer_w || !d_axi_awvalid_o || !d_axi_wvalid_o ||
           !eff_write_size_ok_w || !eff_write_mask_ok_w ||
           !eff_write_natural_w ||
           d_axi_awaddr_o !== eff_awaddr_w ||
           d_axi_awsize_o !== eff_awsize_w ||
           d_axi_wdata_o !== direct_wdata_w ||
           d_axi_wstrb_o !== direct_wstrb_w)) begin
        $error("[LANE-W-DIRECT-LEGAL] illegal/incomplete direct write offer @%0t", $time);
        $fatal;
      end
      if ((state_q == S_W_SEND) &&
          ((d_aw_sent_q && d_axi_awvalid_o) ||
           (d_w_sent_q && d_axi_wvalid_o))) begin
        $error("[LANE-W-NO-RESEND] accepted downstream write channel reissued @%0t", $time);
        $fatal;
      end
      if (d_axi_arvalid_o &&
          !naturally_aligned(d_axi_araddr_o, d_axi_arsize_o)) begin
        $error("[LANE-AR-ALIGN] non-standard downstream read beat @%0t", $time);
        $fatal;
      end
      if (d_axi_awvalid_o &&
          !naturally_aligned(d_axi_awaddr_o, d_axi_awsize_o)) begin
        $error("[LANE-AW-ALIGN] non-standard downstream write beat @%0t", $time);
        $fatal;
      end
      if (d_axi_wvalid_o &&
          (d_axi_wstrb_o !==
           (low_mask_from_size(d_axi_awsize_o) <<
            d_axi_awaddr_o[LANE_BITS-1:0]))) begin
        $error("[LANE-WSTRB] downstream byte lanes do not match AW owner @%0t", $time);
        $fatal;
      end
      ar_stall_q <= d_axi_arvalid_o && !d_axi_arready_i;
      aw_stall_q <= d_axi_awvalid_o && !d_axi_awready_i;
      w_stall_q <= d_axi_wvalid_o && !d_axi_wready_i;
      u_b_stall_q <= u_axi_bvalid_o && !u_axi_bready_i;
      araddr_stall_q <= d_axi_araddr_o;
      arsize_stall_q <= d_axi_arsize_o;
      arprot_stall_q <= d_axi_arprot_o;
      awaddr_stall_q <= d_axi_awaddr_o;
      awsize_stall_q <= d_axi_awsize_o;
      wdata_stall_q <= d_axi_wdata_o;
      wstrb_stall_q <= d_axi_wstrb_o;
      u_bresp_stall_q <= u_axi_bresp_o;
    end
  end
`endif

endmodule
