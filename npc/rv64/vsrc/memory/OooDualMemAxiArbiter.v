`include "define.v"

// Two single-outstanding, single-beat memory AXI subsets share one downstream
// AXI subset.  Selection is registered: IDLE never falls through to a READY or
// VALID, and the transport owner remains locked until the exact R/B terminal.
//
// This is an F0 leaf component.  It is intentionally not instantiated by the
// canonical core until the dual-memory integration contracts are implemented.
module OooDualMemAxiArbiter (
  input clk,
  input rst,

  input lane0_axi_arvalid_i,
  output reg lane0_axi_arready_o,
  input [`XLEN-1:0] lane0_axi_araddr_i,
  input [3:0] lane0_axi_arid_i,
  input [7:0] lane0_axi_arlen_i,
  input [2:0] lane0_axi_arsize_i,
  input [1:0] lane0_axi_arburst_i,
  input [2:0] lane0_axi_arprot_i,
  output reg lane0_axi_rvalid_o,
  input lane0_axi_rready_i,
  output reg [`XLEN-1:0] lane0_axi_rdata_o,
  output reg [1:0] lane0_axi_rresp_o,

  input lane0_axi_awvalid_i,
  output reg lane0_axi_awready_o,
  input [`XLEN-1:0] lane0_axi_awaddr_i,
  input [3:0] lane0_axi_awid_i,
  input [7:0] lane0_axi_awlen_i,
  input [2:0] lane0_axi_awsize_i,
  input [1:0] lane0_axi_awburst_i,
  input lane0_axi_wvalid_i,
  output reg lane0_axi_wready_o,
  input [`XLEN-1:0] lane0_axi_wdata_i,
  input [`STRB_W-1:0] lane0_axi_wstrb_i,
  input lane0_axi_wlast_i,
  output reg lane0_axi_bvalid_o,
  input lane0_axi_bready_i,
  output reg [1:0] lane0_axi_bresp_o,

  input lane1_axi_arvalid_i,
  output reg lane1_axi_arready_o,
  input [`XLEN-1:0] lane1_axi_araddr_i,
  input [3:0] lane1_axi_arid_i,
  input [7:0] lane1_axi_arlen_i,
  input [2:0] lane1_axi_arsize_i,
  input [1:0] lane1_axi_arburst_i,
  input [2:0] lane1_axi_arprot_i,
  output reg lane1_axi_rvalid_o,
  input lane1_axi_rready_i,
  output reg [`XLEN-1:0] lane1_axi_rdata_o,
  output reg [1:0] lane1_axi_rresp_o,

  input lane1_axi_awvalid_i,
  output reg lane1_axi_awready_o,
  input [`XLEN-1:0] lane1_axi_awaddr_i,
  input [3:0] lane1_axi_awid_i,
  input [7:0] lane1_axi_awlen_i,
  input [2:0] lane1_axi_awsize_i,
  input [1:0] lane1_axi_awburst_i,
  input lane1_axi_wvalid_i,
  output reg lane1_axi_wready_o,
  input [`XLEN-1:0] lane1_axi_wdata_i,
  input [`STRB_W-1:0] lane1_axi_wstrb_i,
  input lane1_axi_wlast_i,
  output reg lane1_axi_bvalid_o,
  input lane1_axi_bready_i,
  output reg [1:0] lane1_axi_bresp_o,

  output reg d_axi_arvalid_o,
  input d_axi_arready_i,
  output reg [`XLEN-1:0] d_axi_araddr_o,
  output reg [3:0] d_axi_arid_o,
  output reg [7:0] d_axi_arlen_o,
  output reg [2:0] d_axi_arsize_o,
  output reg [1:0] d_axi_arburst_o,
  output reg [2:0] d_axi_arprot_o,
  input d_axi_rvalid_i,
  output reg d_axi_rready_o,
  input [`XLEN-1:0] d_axi_rdata_i,
  input [1:0] d_axi_rresp_i,

  output reg d_axi_awvalid_o,
  input d_axi_awready_i,
  output reg [`XLEN-1:0] d_axi_awaddr_o,
  output reg [3:0] d_axi_awid_o,
  output reg [7:0] d_axi_awlen_o,
  output reg [2:0] d_axi_awsize_o,
  output reg [1:0] d_axi_awburst_o,
  output reg d_axi_wvalid_o,
  input d_axi_wready_i,
  output reg [`XLEN-1:0] d_axi_wdata_o,
  output reg [`STRB_W-1:0] d_axi_wstrb_o,
  output reg d_axi_wlast_o,
  input d_axi_bvalid_i,
  output reg d_axi_bready_o,
  input [1:0] d_axi_bresp_i
);

  localparam [2:0] S_IDLE       = 3'd0;
  localparam [2:0] S_READ_ADDR  = 3'd1;
  localparam [2:0] S_READ_RESP  = 3'd2;
  localparam [2:0] S_WRITE_DATA = 3'd3;
  localparam [2:0] S_WRITE_RESP = 3'd4;

  reg [2:0] state_q;
  reg owner_q;
  reg is_write_q;
  reg rr_q;
  reg aw_seen_q;
  reg w_seen_q;

  wire lane0_read_present_w = lane0_axi_arvalid_i;
  wire lane1_read_present_w = lane1_axi_arvalid_i;
  wire lane0_write_present_w = lane0_axi_awvalid_i || lane0_axi_wvalid_i;
  wire lane1_write_present_w = lane1_axi_awvalid_i || lane1_axi_wvalid_i;
  wire lane0_illegal_w = lane0_read_present_w && lane0_write_present_w;
  wire lane1_illegal_w = lane1_read_present_w && lane1_write_present_w;
  wire request_illegal_w = lane0_illegal_w || lane1_illegal_w;
  wire lane0_request_w = lane0_read_present_w ^ lane0_write_present_w;
  wire lane1_request_w = lane1_read_present_w ^ lane1_write_present_w;
  wire capture_valid_w = !request_illegal_w &&
                         (lane0_request_w || lane1_request_w);
  wire capture_owner_w = lane0_request_w && lane1_request_w ? rr_q :
                         lane1_request_w;
  wire capture_write_w = capture_owner_w ? lane1_write_present_w :
                                           lane0_write_present_w;

  wire ar_fire_w = d_axi_arvalid_o && d_axi_arready_i;
  wire aw_fire_w = d_axi_awvalid_o && d_axi_awready_i;
  wire w_fire_w = d_axi_wvalid_o && d_axi_wready_i;
  wire r_fire_w = d_axi_rvalid_i && d_axi_rready_o;
  wire b_fire_w = d_axi_bvalid_i && d_axi_bready_o;
  wire aw_seen_next_w = aw_seen_q || aw_fire_w;
  wire w_seen_next_w = w_seen_q || w_fire_w;

  // All outputs are explicitly reset-quiet.  In IDLE the default values also
  // enforce registered selection and globally fail closed on a dual-type lane.
  always @(*) begin
    lane0_axi_arready_o = 1'b0;
    lane0_axi_rvalid_o = 1'b0;
    lane0_axi_rdata_o = {`XLEN{1'b0}};
    lane0_axi_rresp_o = 2'b00;
    lane0_axi_awready_o = 1'b0;
    lane0_axi_wready_o = 1'b0;
    lane0_axi_bvalid_o = 1'b0;
    lane0_axi_bresp_o = 2'b00;

    lane1_axi_arready_o = 1'b0;
    lane1_axi_rvalid_o = 1'b0;
    lane1_axi_rdata_o = {`XLEN{1'b0}};
    lane1_axi_rresp_o = 2'b00;
    lane1_axi_awready_o = 1'b0;
    lane1_axi_wready_o = 1'b0;
    lane1_axi_bvalid_o = 1'b0;
    lane1_axi_bresp_o = 2'b00;

    d_axi_arvalid_o = 1'b0;
    d_axi_araddr_o = {`XLEN{1'b0}};
    d_axi_arid_o = 4'b0000;
    d_axi_arlen_o = 8'b0000_0000;
    d_axi_arsize_o = 3'b000;
    d_axi_arburst_o = 2'b00;
    d_axi_arprot_o = 3'b000;
    d_axi_rready_o = 1'b0;

    d_axi_awvalid_o = 1'b0;
    d_axi_awaddr_o = {`XLEN{1'b0}};
    d_axi_awid_o = 4'b0000;
    d_axi_awlen_o = 8'b0000_0000;
    d_axi_awsize_o = 3'b000;
    d_axi_awburst_o = 2'b00;
    d_axi_wvalid_o = 1'b0;
    d_axi_wdata_o = {`XLEN{1'b0}};
    d_axi_wstrb_o = {`STRB_W{1'b0}};
    d_axi_wlast_o = 1'b0;
    d_axi_bready_o = 1'b0;

    if (!rst) begin
      case (state_q)
        S_READ_ADDR: begin
          if (!owner_q) begin
            d_axi_arvalid_o = lane0_axi_arvalid_i;
            d_axi_araddr_o = lane0_axi_araddr_i;
            d_axi_arid_o = lane0_axi_arid_i;
            d_axi_arlen_o = lane0_axi_arlen_i;
            d_axi_arsize_o = lane0_axi_arsize_i;
            d_axi_arburst_o = lane0_axi_arburst_i;
            d_axi_arprot_o = lane0_axi_arprot_i;
            lane0_axi_arready_o = d_axi_arready_i;
          end else begin
            d_axi_arvalid_o = lane1_axi_arvalid_i;
            d_axi_araddr_o = lane1_axi_araddr_i;
            d_axi_arid_o = lane1_axi_arid_i;
            d_axi_arlen_o = lane1_axi_arlen_i;
            d_axi_arsize_o = lane1_axi_arsize_i;
            d_axi_arburst_o = lane1_axi_arburst_i;
            d_axi_arprot_o = lane1_axi_arprot_i;
            lane1_axi_arready_o = d_axi_arready_i;
          end
        end

        S_READ_RESP: begin
          d_axi_rready_o = owner_q ? lane1_axi_rready_i :
                                         lane0_axi_rready_i;
          if (!owner_q) begin
            lane0_axi_rvalid_o = d_axi_rvalid_i;
            lane0_axi_rdata_o = d_axi_rdata_i;
            lane0_axi_rresp_o = d_axi_rresp_i;
          end else begin
            lane1_axi_rvalid_o = d_axi_rvalid_i;
            lane1_axi_rdata_o = d_axi_rdata_i;
            lane1_axi_rresp_o = d_axi_rresp_i;
          end
        end

        S_WRITE_DATA: begin
          if (!owner_q) begin
            d_axi_awvalid_o = !aw_seen_q && lane0_axi_awvalid_i;
            d_axi_awaddr_o = lane0_axi_awaddr_i;
            d_axi_awid_o = lane0_axi_awid_i;
            d_axi_awlen_o = lane0_axi_awlen_i;
            d_axi_awsize_o = lane0_axi_awsize_i;
            d_axi_awburst_o = lane0_axi_awburst_i;
            lane0_axi_awready_o = !aw_seen_q && d_axi_awready_i;
            d_axi_wvalid_o = !w_seen_q && lane0_axi_wvalid_i;
            d_axi_wdata_o = lane0_axi_wdata_i;
            d_axi_wstrb_o = lane0_axi_wstrb_i;
            d_axi_wlast_o = lane0_axi_wlast_i;
            lane0_axi_wready_o = !w_seen_q && d_axi_wready_i;
          end else begin
            d_axi_awvalid_o = !aw_seen_q && lane1_axi_awvalid_i;
            d_axi_awaddr_o = lane1_axi_awaddr_i;
            d_axi_awid_o = lane1_axi_awid_i;
            d_axi_awlen_o = lane1_axi_awlen_i;
            d_axi_awsize_o = lane1_axi_awsize_i;
            d_axi_awburst_o = lane1_axi_awburst_i;
            lane1_axi_awready_o = !aw_seen_q && d_axi_awready_i;
            d_axi_wvalid_o = !w_seen_q && lane1_axi_wvalid_i;
            d_axi_wdata_o = lane1_axi_wdata_i;
            d_axi_wstrb_o = lane1_axi_wstrb_i;
            d_axi_wlast_o = lane1_axi_wlast_i;
            lane1_axi_wready_o = !w_seen_q && d_axi_wready_i;
          end
        end

        S_WRITE_RESP: begin
          d_axi_bready_o = owner_q ? lane1_axi_bready_i :
                                         lane0_axi_bready_i;
          if (!owner_q) begin
            lane0_axi_bvalid_o = d_axi_bvalid_i;
            lane0_axi_bresp_o = d_axi_bresp_i;
          end else begin
            lane1_axi_bvalid_o = d_axi_bvalid_i;
            lane1_axi_bresp_o = d_axi_bresp_i;
          end
        end

        default: begin
          // S_IDLE and illegal encodings are externally quiet.
        end
      endcase
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      state_q <= S_IDLE;
      owner_q <= 1'b0;
      is_write_q <= 1'b0;
      rr_q <= 1'b0;
      aw_seen_q <= 1'b0;
      w_seen_q <= 1'b0;
    end else begin
      case (state_q)
        S_IDLE: begin
          // On an illegal dual-type request every state bit retains its value.
          if (capture_valid_w) begin
            owner_q <= capture_owner_w;
            is_write_q <= capture_write_w;
            aw_seen_q <= 1'b0;
            w_seen_q <= 1'b0;
            state_q <= capture_write_w ? S_WRITE_DATA : S_READ_ADDR;
          end
        end

        S_READ_ADDR: begin
          if (ar_fire_w)
            state_q <= S_READ_RESP;
        end

        S_READ_RESP: begin
          if (r_fire_w) begin
            state_q <= S_IDLE;
            rr_q <= ~owner_q;
            aw_seen_q <= 1'b0;
            w_seen_q <= 1'b0;
          end
        end

        S_WRITE_DATA: begin
          if (aw_fire_w)
            aw_seen_q <= 1'b1;
          if (w_fire_w)
            w_seen_q <= 1'b1;
          if (aw_seen_next_w && w_seen_next_w)
            state_q <= S_WRITE_RESP;
        end

        S_WRITE_RESP: begin
          if (b_fire_w) begin
            state_q <= S_IDLE;
            rr_q <= ~owner_q;
            aw_seen_q <= 1'b0;
            w_seen_q <= 1'b0;
          end
        end

        default: begin
          state_q <= S_IDLE;
          owner_q <= 1'b0;
          is_write_q <= 1'b0;
          aw_seen_q <= 1'b0;
          w_seen_q <= 1'b0;
        end
      endcase
    end
  end

`ifdef OOO_ASSERT
  reg [2:0] assert_state_prev_q;
  reg assert_owner_prev_q;
  reg assert_is_write_prev_q;
  reg assert_terminal_prev_q;
  reg assert_prev_valid_q;
  reg ar_stall_q;
  reg aw_stall_q;
  reg w_stall_q;
  reg r_stall_q;
  reg b_stall_q;
  reg [`XLEN-1:0] araddr_stall_q;
  reg [3:0] arid_stall_q;
  reg [7:0] arlen_stall_q;
  reg [2:0] arsize_stall_q;
  reg [1:0] arburst_stall_q;
  reg [2:0] arprot_stall_q;
  reg [`XLEN-1:0] awaddr_stall_q;
  reg [3:0] awid_stall_q;
  reg [7:0] awlen_stall_q;
  reg [2:0] awsize_stall_q;
  reg [1:0] awburst_stall_q;
  reg [`XLEN-1:0] wdata_stall_q;
  reg [`STRB_W-1:0] wstrb_stall_q;
  reg wlast_stall_q;
  reg [`XLEN-1:0] rdata_stall_q;
  reg [1:0] rresp_stall_q;
  reg [1:0] bresp_stall_q;

  always @(posedge clk) begin
    if (rst) begin
      assert_state_prev_q <= S_IDLE;
      assert_owner_prev_q <= 1'b0;
      assert_is_write_prev_q <= 1'b0;
      assert_terminal_prev_q <= 1'b0;
      assert_prev_valid_q <= 1'b0;
      ar_stall_q <= 1'b0;
      aw_stall_q <= 1'b0;
      w_stall_q <= 1'b0;
      r_stall_q <= 1'b0;
      b_stall_q <= 1'b0;
      if (lane0_axi_arready_o || lane0_axi_awready_o ||
          lane0_axi_wready_o || lane0_axi_rvalid_o || lane0_axi_bvalid_o ||
          lane1_axi_arready_o || lane1_axi_awready_o ||
          lane1_axi_wready_o || lane1_axi_rvalid_o || lane1_axi_bvalid_o ||
          d_axi_arvalid_o || d_axi_rready_o || d_axi_awvalid_o ||
          d_axi_wvalid_o || d_axi_bready_o) begin
        $error("[ARB-RESET-QUIET] AXI handshake output active during reset @%0t", $time);
        $fatal;
      end
    end else begin
      if (lane0_illegal_w || lane1_illegal_w) begin
        $error("[ARB-REQ-CLASS-ONEHOT] lane presents read and write together @%0t", $time);
        $fatal;
      end
      if (assert_prev_valid_q && (assert_state_prev_q != S_IDLE) &&
          !assert_terminal_prev_q &&
          ((owner_q !== assert_owner_prev_q) ||
           (is_write_q !== assert_is_write_prev_q))) begin
        $error("[ARB-OWNER-HOLD] transport owner changed before terminal @%0t", $time);
        $fatal;
      end
      if ((!owner_q &&
           (lane1_axi_arready_o || lane1_axi_awready_o ||
            lane1_axi_wready_o || lane1_axi_rvalid_o || lane1_axi_bvalid_o)) ||
          (owner_q &&
           (lane0_axi_arready_o || lane0_axi_awready_o ||
            lane0_axi_wready_o || lane0_axi_rvalid_o || lane0_axi_bvalid_o))) begin
        $error("[ARB-NONOWNER-ISOLATION] non-owner observed READY/VALID @%0t", $time);
        $fatal;
      end
      if (aw_seen_q && (d_axi_awvalid_o || aw_fire_w)) begin
        $error("[ARB-AW-ONCE] AW repeated after terminal handshake @%0t", $time);
        $fatal;
      end
      if (w_seen_q && (d_axi_wvalid_o || w_fire_w)) begin
        $error("[ARB-W-ONCE] W repeated after terminal handshake @%0t", $time);
        $fatal;
      end
      if ((state_q != S_WRITE_RESP) &&
          (lane0_axi_bvalid_o || lane1_axi_bvalid_o || d_axi_bready_o)) begin
        $error("[ARB-WRITE-TERMINAL] B visible before AW and W completion @%0t", $time);
        $fatal;
      end
      if ((state_q != S_READ_RESP) &&
          (lane0_axi_rvalid_o || lane1_axi_rvalid_o || d_axi_rready_o)) begin
        $error("[ARB-READ-TERMINAL] R visible before AR completion @%0t", $time);
        $fatal;
      end
      if ((lane0_axi_rvalid_o && lane1_axi_rvalid_o) ||
          (lane0_axi_bvalid_o && lane1_axi_bvalid_o)) begin
        $error("[ARB-RSP-ONEHOT] response broadcast to both lanes @%0t", $time);
        $fatal;
      end
      if ((state_q == S_IDLE) &&
          (lane0_axi_arready_o || lane0_axi_awready_o ||
           lane0_axi_wready_o || lane0_axi_rvalid_o || lane0_axi_bvalid_o ||
           lane1_axi_arready_o || lane1_axi_awready_o ||
           lane1_axi_wready_o || lane1_axi_rvalid_o || lane1_axi_bvalid_o ||
           d_axi_arvalid_o || d_axi_rready_o || d_axi_awvalid_o ||
           d_axi_wvalid_o || d_axi_bready_o)) begin
        $error("[ARB-IDLE-QUIET] IDLE exposed a handshake @%0t", $time);
        $fatal;
      end
      if (((state_q == S_READ_ADDR) || (state_q == S_READ_RESP)) &&
          is_write_q) begin
        $error("[ARB-TYPE-STATE] read state carries write type @%0t", $time);
        $fatal;
      end
      if (((state_q == S_WRITE_DATA) || (state_q == S_WRITE_RESP)) &&
          !is_write_q) begin
        $error("[ARB-TYPE-STATE] write state carries read type @%0t", $time);
        $fatal;
      end
      if (ar_stall_q &&
          (!d_axi_arvalid_o || d_axi_araddr_o !== araddr_stall_q ||
           d_axi_arid_o !== arid_stall_q || d_axi_arlen_o !== arlen_stall_q ||
           d_axi_arsize_o !== arsize_stall_q ||
           d_axi_arburst_o !== arburst_stall_q ||
           d_axi_arprot_o !== arprot_stall_q)) begin
        $error("[ARB-AR-HOLD] downstream AR payload changed while stalled @%0t", $time);
        $fatal;
      end
      if (aw_stall_q &&
          (!d_axi_awvalid_o || d_axi_awaddr_o !== awaddr_stall_q ||
           d_axi_awid_o !== awid_stall_q || d_axi_awlen_o !== awlen_stall_q ||
           d_axi_awsize_o !== awsize_stall_q ||
           d_axi_awburst_o !== awburst_stall_q)) begin
        $error("[ARB-AW-HOLD] downstream AW payload changed while stalled @%0t", $time);
        $fatal;
      end
      if (w_stall_q &&
          (!d_axi_wvalid_o || d_axi_wdata_o !== wdata_stall_q ||
           d_axi_wstrb_o !== wstrb_stall_q || d_axi_wlast_o !== wlast_stall_q)) begin
        $error("[ARB-W-HOLD] downstream W payload changed while stalled @%0t", $time);
        $fatal;
      end
      if (r_stall_q &&
          (!(lane0_axi_rvalid_o || lane1_axi_rvalid_o) ||
           ((owner_q ? lane1_axi_rdata_o : lane0_axi_rdata_o) !==
            rdata_stall_q) ||
           ((owner_q ? lane1_axi_rresp_o : lane0_axi_rresp_o) !==
            rresp_stall_q))) begin
        $error("[ARB-R-HOLD] upstream R payload changed while stalled @%0t", $time);
        $fatal;
      end
      if (b_stall_q &&
          (!(lane0_axi_bvalid_o || lane1_axi_bvalid_o) ||
           ((owner_q ? lane1_axi_bresp_o : lane0_axi_bresp_o) !==
            bresp_stall_q))) begin
        $error("[ARB-B-HOLD] upstream B payload changed while stalled @%0t", $time);
        $fatal;
      end

      assert_state_prev_q <= state_q;
      assert_owner_prev_q <= owner_q;
      assert_is_write_prev_q <= is_write_q;
      assert_terminal_prev_q <= r_fire_w || b_fire_w;
      assert_prev_valid_q <= 1'b1;
      ar_stall_q <= d_axi_arvalid_o && !d_axi_arready_i;
      aw_stall_q <= d_axi_awvalid_o && !d_axi_awready_i;
      w_stall_q <= d_axi_wvalid_o && !d_axi_wready_i;
      r_stall_q <= (lane0_axi_rvalid_o && !lane0_axi_rready_i) ||
                   (lane1_axi_rvalid_o && !lane1_axi_rready_i);
      b_stall_q <= (lane0_axi_bvalid_o && !lane0_axi_bready_i) ||
                   (lane1_axi_bvalid_o && !lane1_axi_bready_i);
      araddr_stall_q <= d_axi_araddr_o;
      arid_stall_q <= d_axi_arid_o;
      arlen_stall_q <= d_axi_arlen_o;
      arsize_stall_q <= d_axi_arsize_o;
      arburst_stall_q <= d_axi_arburst_o;
      arprot_stall_q <= d_axi_arprot_o;
      awaddr_stall_q <= d_axi_awaddr_o;
      awid_stall_q <= d_axi_awid_o;
      awlen_stall_q <= d_axi_awlen_o;
      awsize_stall_q <= d_axi_awsize_o;
      awburst_stall_q <= d_axi_awburst_o;
      wdata_stall_q <= d_axi_wdata_o;
      wstrb_stall_q <= d_axi_wstrb_o;
      wlast_stall_q <= d_axi_wlast_o;
      rdata_stall_q <= owner_q ? lane1_axi_rdata_o : lane0_axi_rdata_o;
      rresp_stall_q <= owner_q ? lane1_axi_rresp_o : lane0_axi_rresp_o;
      bresp_stall_q <= owner_q ? lane1_axi_bresp_o : lane0_axi_bresp_o;
    end
  end
`endif

endmodule
