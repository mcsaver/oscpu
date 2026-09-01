`timescale 1ns/1ps
`include "define.v"
`include "tb_common.svh"

module tb_ooo_lsu_axi_lane_adapter;
  reg clk;
  reg rst;

  reg u_axi_split_allowed_i;
  reg u_axi_arvalid_i;
  wire u_axi_arready_o;
  reg [`XLEN-1:0] u_axi_araddr_i;
  reg [2:0] u_axi_arsize_i;
  reg [2:0] u_axi_arprot_i;
  wire u_axi_rvalid_o;
  reg u_axi_rready_i;
  wire [`XLEN-1:0] u_axi_rdata_o;
  wire [1:0] u_axi_rresp_o;
  reg u_axi_awvalid_i;
  wire u_axi_awready_o;
  reg [`XLEN-1:0] u_axi_awaddr_i;
  reg [2:0] u_axi_awsize_i;
  reg u_axi_wvalid_i;
  wire u_axi_wready_o;
  reg [`XLEN-1:0] u_axi_wdata_i;
  reg [`STRB_W-1:0] u_axi_wstrb_i;
  wire u_axi_bvalid_o;
  reg u_axi_bready_i;
  wire [1:0] u_axi_bresp_o;

  wire d_axi_arvalid_o;
  reg d_axi_arready_i;
  wire [`XLEN-1:0] d_axi_araddr_o;
  wire [2:0] d_axi_arsize_o;
  wire [2:0] d_axi_arprot_o;
  reg d_axi_rvalid_i;
  wire d_axi_rready_o;
  reg [`XLEN-1:0] d_axi_rdata_i;
  reg [1:0] d_axi_rresp_i;
  wire d_axi_awvalid_o;
  reg d_axi_awready_i;
  wire [`XLEN-1:0] d_axi_awaddr_o;
  wire [2:0] d_axi_awsize_o;
  wire d_axi_wvalid_o;
  reg d_axi_wready_i;
  wire [`XLEN-1:0] d_axi_wdata_o;
  wire [`STRB_W-1:0] d_axi_wstrb_o;
  reg d_axi_bvalid_i;
  wire d_axi_bready_o;
  reg [1:0] d_axi_bresp_i;

  integer errors;
  integer d_ar_fires;
  integer d_aw_fires;
  integer d_w_fires;
  integer input_ft_cases;
  integer input_ft_11;
  integer input_ft_10;
  integer input_ft_01;
  integer input_ft_00;
  integer input_ft_same_cycle;
  integer input_ft_aw_first;
  integer input_ft_w_first;

  OooLsuAxiLaneAdapter dut (
    .clk(clk),
    .rst(rst),
    .u_axi_split_allowed_i(u_axi_split_allowed_i),
    .u_axi_arvalid_i(u_axi_arvalid_i),
    .u_axi_arready_o(u_axi_arready_o),
    .u_axi_araddr_i(u_axi_araddr_i),
    .u_axi_arsize_i(u_axi_arsize_i),
    .u_axi_arprot_i(u_axi_arprot_i),
    .u_axi_rvalid_o(u_axi_rvalid_o),
    .u_axi_rready_i(u_axi_rready_i),
    .u_axi_rdata_o(u_axi_rdata_o),
    .u_axi_rresp_o(u_axi_rresp_o),
    .u_axi_awvalid_i(u_axi_awvalid_i),
    .u_axi_awready_o(u_axi_awready_o),
    .u_axi_awaddr_i(u_axi_awaddr_i),
    .u_axi_awsize_i(u_axi_awsize_i),
    .u_axi_wvalid_i(u_axi_wvalid_i),
    .u_axi_wready_o(u_axi_wready_o),
    .u_axi_wdata_i(u_axi_wdata_i),
    .u_axi_wstrb_i(u_axi_wstrb_i),
    .u_axi_bvalid_o(u_axi_bvalid_o),
    .u_axi_bready_i(u_axi_bready_i),
    .u_axi_bresp_o(u_axi_bresp_o),
    .d_axi_arvalid_o(d_axi_arvalid_o),
    .d_axi_arready_i(d_axi_arready_i),
    .d_axi_araddr_o(d_axi_araddr_o),
    .d_axi_arsize_o(d_axi_arsize_o),
    .d_axi_arprot_o(d_axi_arprot_o),
    .d_axi_rvalid_i(d_axi_rvalid_i),
    .d_axi_rready_o(d_axi_rready_o),
    .d_axi_rdata_i(d_axi_rdata_i),
    .d_axi_rresp_i(d_axi_rresp_i),
    .d_axi_awvalid_o(d_axi_awvalid_o),
    .d_axi_awready_i(d_axi_awready_i),
    .d_axi_awaddr_o(d_axi_awaddr_o),
    .d_axi_awsize_o(d_axi_awsize_o),
    .d_axi_wvalid_o(d_axi_wvalid_o),
    .d_axi_wready_i(d_axi_wready_i),
    .d_axi_wdata_o(d_axi_wdata_o),
    .d_axi_wstrb_o(d_axi_wstrb_o),
    .d_axi_bvalid_i(d_axi_bvalid_i),
    .d_axi_bready_o(d_axi_bready_o),
    .d_axi_bresp_i(d_axi_bresp_i)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  always @(posedge clk) begin
    if (d_axi_arvalid_o && d_axi_arready_i)
      d_ar_fires = d_ar_fires + 1;
    if (d_axi_awvalid_o && d_axi_awready_i)
      d_aw_fires = d_aw_fires + 1;
    if (d_axi_wvalid_o && d_axi_wready_i)
      d_w_fires = d_w_fires + 1;
  end

  function automatic [`XLEN-1:0] data_mask(input [2:0] size);
    begin
      case (size)
        3'd0: data_mask = 64'h0000_0000_0000_00ff;
        3'd1: data_mask = 64'h0000_0000_0000_ffff;
        3'd2: data_mask = 64'h0000_0000_ffff_ffff;
        default: data_mask = 64'hffff_ffff_ffff_ffff;
      endcase
    end
  endfunction

  function automatic [`STRB_W-1:0] low_strobe(input [2:0] size);
    begin
      case (size)
        3'd0: low_strobe = 8'h01;
        3'd1: low_strobe = 8'h03;
        3'd2: low_strobe = 8'h0f;
        default: low_strobe = 8'hff;
      endcase
    end
  endfunction

  function automatic integer byte_count(input [2:0] size);
    begin
      case (size)
        3'd0: byte_count = 1;
        3'd1: byte_count = 2;
        3'd2: byte_count = 4;
        default: byte_count = 8;
      endcase
    end
  endfunction

  task automatic lsa_tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task automatic check1(input string name, input logic got,
                        input logic expected);
    begin
      if (got !== expected) begin
        $display("[CHECK-FAIL] %s got=%b expected=%b", name, got, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic check2(input string name, input logic [1:0] got,
                        input logic [1:0] expected);
    begin
      if (got !== expected) begin
        $display("[CHECK-FAIL] %s got=%b expected=%b", name, got, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic check3(input string name, input logic [2:0] got,
                        input logic [2:0] expected);
    begin
      if (got !== expected) begin
        $display("[CHECK-FAIL] %s got=%b expected=%b", name, got, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic check8(input string name, input logic [7:0] got,
                        input logic [7:0] expected);
    begin
      if (got !== expected) begin
        $display("[CHECK-FAIL] %s got=%02x expected=%02x", name, got, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic check64(input string name, input logic [63:0] got,
                         input logic [63:0] expected);
    begin
      if (got !== expected) begin
        $display("[CHECK-FAIL] %s got=%016x expected=%016x",
                 name, got, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic wait_d_ar;
    integer timeout;
    begin
      timeout = 0;
      while (!d_axi_arvalid_o && timeout < 20) begin
        lsa_tick();
        timeout = timeout + 1;
      end
      check1("downstream AR appears", d_axi_arvalid_o, 1'b1);
    end
  endtask

  task automatic wait_d_aw_w;
    integer timeout;
    begin
      timeout = 0;
      while (!(d_axi_awvalid_o && d_axi_wvalid_o) && timeout < 20) begin
        lsa_tick();
        timeout = timeout + 1;
      end
      check1("downstream AW appears", d_axi_awvalid_o, 1'b1);
      check1("downstream W appears", d_axi_wvalid_o, 1'b1);
    end
  endtask

  task automatic consume_u_r(input logic [63:0] expected_data,
                             input logic [1:0] expected_resp,
                             input logic exercise_stall);
    reg [63:0] held_data;
    reg [1:0] held_resp;
    integer timeout;
    begin
      timeout = 0;
      while (!u_axi_rvalid_o && timeout < 20) begin
        lsa_tick();
        timeout = timeout + 1;
      end
      check1("upstream R appears", u_axi_rvalid_o, 1'b1);
      check64("upstream R data", u_axi_rdata_o, expected_data);
      check2("upstream R response", u_axi_rresp_o, expected_resp);
      if (exercise_stall) begin
        held_data = u_axi_rdata_o;
        held_resp = u_axi_rresp_o;
        u_axi_rready_i = 1'b0;
        lsa_tick();
        check1("upstream R valid held", u_axi_rvalid_o, 1'b1);
        check64("upstream R data held", u_axi_rdata_o, held_data);
        check2("upstream R response held", u_axi_rresp_o, held_resp);
      end
      u_axi_rready_i = 1'b1;
      lsa_tick();
      u_axi_rready_i = 1'b0;
    end
  endtask

  task automatic consume_u_b(input logic [1:0] expected_resp,
                             input logic exercise_stall);
    reg [1:0] held_resp;
    integer timeout;
    begin
      timeout = 0;
      while (!u_axi_bvalid_o && timeout < 20) begin
        lsa_tick();
        timeout = timeout + 1;
      end
      check1("upstream B appears", u_axi_bvalid_o, 1'b1);
      check2("upstream B response", u_axi_bresp_o, expected_resp);
      if (exercise_stall) begin
        held_resp = u_axi_bresp_o;
        u_axi_bready_i = 1'b0;
        lsa_tick();
        check1("upstream B valid held", u_axi_bvalid_o, 1'b1);
        check2("upstream B response held", u_axi_bresp_o, held_resp);
      end
      u_axi_bready_i = 1'b1;
      lsa_tick();
      u_axi_bready_i = 1'b0;
    end
  endtask

  task automatic launch_read(input logic [63:0] addr,
                             input logic [2:0] size,
                             input logic split_allowed);
    begin
      u_axi_split_allowed_i = split_allowed;
      u_axi_araddr_i = addr;
      u_axi_arsize_i = size;
      u_axi_arprot_i = 3'b101;
      u_axi_arvalid_i = 1'b1;
      #1;
      check1("upstream AR accepted", u_axi_arready_o, 1'b1);
      lsa_tick();
      u_axi_arvalid_i = 1'b0;
      #1;
    end
  endtask

  task automatic launch_write(input logic [63:0] addr,
                              input logic [2:0] size,
                              input logic [63:0] data,
                              input logic [7:0] strb,
                              input logic split_allowed,
                              input integer order);
    begin
      u_axi_split_allowed_i = split_allowed;
      u_axi_awaddr_i = addr;
      u_axi_awsize_i = size;
      u_axi_wdata_i = data;
      u_axi_wstrb_i = strb;
      case (order)
        1: begin
          u_axi_awvalid_i = 1'b1;
          #1;
          check1("AW-first AW ready", u_axi_awready_o, 1'b1);
          lsa_tick();
          u_axi_awvalid_i = 1'b0;
          #1;
          check1("partial AW blocks read", u_axi_arready_o, 1'b0);
          u_axi_wvalid_i = 1'b1;
          #1;
          check1("AW-first W ready", u_axi_wready_o, 1'b1);
          lsa_tick();
          u_axi_wvalid_i = 1'b0;
        end
        2: begin
          u_axi_wvalid_i = 1'b1;
          #1;
          check1("W-first W ready", u_axi_wready_o, 1'b1);
          lsa_tick();
          u_axi_wvalid_i = 1'b0;
          #1;
          check1("partial W blocks read", u_axi_arready_o, 1'b0);
          u_axi_awvalid_i = 1'b1;
          #1;
          check1("W-first AW ready", u_axi_awready_o, 1'b1);
          lsa_tick();
          u_axi_awvalid_i = 1'b0;
        end
        default: begin
          u_axi_awvalid_i = 1'b1;
          u_axi_wvalid_i = 1'b1;
          #1;
          check1("same-cycle AW ready", u_axi_awready_o, 1'b1);
          check1("same-cycle W ready", u_axi_wready_o, 1'b1);
          lsa_tick();
          u_axi_awvalid_i = 1'b0;
          u_axi_wvalid_i = 1'b0;
        end
      endcase
      #1;
    end
  endtask

  task automatic aligned_read(input logic [63:0] addr,
                              input logic [2:0] size,
                              input logic exercise_stall);
    reg [63:0] pattern;
    reg [63:0] expected;
    reg [63:0] held_addr;
    reg [2:0] held_size;
    integer lane;
    begin
      pattern = 64'h8877_6655_4433_2211;
      expected = pattern & data_mask(size);
      lane = addr[2:0];
      d_axi_arready_i = 1'b0;
      launch_read(addr, size, 1'b0);
      wait_d_ar();
      check64("aligned AR address", d_axi_araddr_o, addr);
      check3("aligned AR size", d_axi_arsize_o, size);
      check3("aligned ARPROT", d_axi_arprot_o, 3'b101);
      if (exercise_stall) begin
        held_addr = d_axi_araddr_o;
        held_size = d_axi_arsize_o;
        lsa_tick();
        check1("stalled AR valid held", d_axi_arvalid_o, 1'b1);
        check64("stalled AR address held", d_axi_araddr_o, held_addr);
        check3("stalled AR size held", d_axi_arsize_o, held_size);
        check3("stalled ARPROT held", d_axi_arprot_o, 3'b101);
      end
      d_axi_arready_i = 1'b1;
      lsa_tick();
      d_axi_arready_i = 1'b0;
      d_axi_rdata_i = expected << (lane * 8);
      d_axi_rresp_i = 2'b00;
      d_axi_rvalid_i = 1'b1;
      #1;
      check1("aligned downstream R ready", d_axi_rready_o, 1'b1);
      lsa_tick();
      d_axi_rvalid_i = 1'b0;
      consume_u_r(expected, 2'b00, exercise_stall);
    end
  endtask

  task automatic aligned_write(input logic [63:0] addr,
                               input logic [2:0] size,
                               input integer order,
                               input logic exercise_stall);
    reg [63:0] pattern;
    reg [63:0] expected_data;
    reg [7:0] expected_strb;
    reg [63:0] held_awaddr;
    reg [63:0] held_wdata;
    reg [7:0] held_wstrb;
    integer lane;
    begin
      pattern = 64'h8877_6655_4433_2211 & data_mask(size);
      lane = addr[2:0];
      expected_data = pattern << (lane * 8);
      expected_strb = low_strobe(size) << lane;
      d_axi_awready_i = 1'b0;
      d_axi_wready_i = 1'b0;
      launch_write(addr, size, pattern, low_strobe(size), 1'b0, order);
      wait_d_aw_w();
      check64("aligned AW address", d_axi_awaddr_o, addr);
      check3("aligned AW size", d_axi_awsize_o, size);
      check64("aligned W lane data", d_axi_wdata_o, expected_data);
      check8("aligned W lane strobe", d_axi_wstrb_o, expected_strb);
      if (exercise_stall) begin
        held_awaddr = d_axi_awaddr_o;
        held_wdata = d_axi_wdata_o;
        held_wstrb = d_axi_wstrb_o;
        lsa_tick();
        check1("stalled AW valid held", d_axi_awvalid_o, 1'b1);
        check1("stalled W valid held", d_axi_wvalid_o, 1'b1);
        check64("stalled AW address held", d_axi_awaddr_o, held_awaddr);
        check64("stalled W data held", d_axi_wdata_o, held_wdata);
        check8("stalled W strobe held", d_axi_wstrb_o, held_wstrb);
        d_axi_awready_i = 1'b1;
        lsa_tick();
        d_axi_awready_i = 1'b0;
        check1("W remains after AW handshake", d_axi_wvalid_o, 1'b1);
        check64("W data held after AW", d_axi_wdata_o, held_wdata);
        check8("W strobe held after AW", d_axi_wstrb_o, held_wstrb);
        d_axi_wready_i = 1'b1;
        lsa_tick();
        d_axi_wready_i = 1'b0;
      end else begin
        d_axi_awready_i = 1'b1;
        d_axi_wready_i = 1'b1;
        lsa_tick();
        d_axi_awready_i = 1'b0;
        d_axi_wready_i = 1'b0;
      end
      d_axi_bresp_i = 2'b00;
      d_axi_bvalid_i = 1'b1;
      #1;
      check1("aligned downstream B ready", d_axi_bready_o, 1'b1);
      lsa_tick();
      d_axi_bvalid_i = 1'b0;
      consume_u_b(2'b00, exercise_stall);
    end
  endtask

  task automatic split_read(input logic [63:0] addr,
                            input logic [2:0] size);
    reg [63:0] pattern;
    reg [63:0] expected;
    reg [63:0] beat_data;
    integer count;
    integer i;
    integer lane;
    begin
      pattern = 64'h8877_6655_4433_2211;
      expected = pattern & data_mask(size);
      count = byte_count(size);
      d_axi_arready_i = 1'b0;
      launch_read(addr, size, 1'b1);
      for (i = 0; i < count; i = i + 1) begin
        wait_d_ar();
        check64("split AR byte address", d_axi_araddr_o, addr + i);
        check3("split AR byte size", d_axi_arsize_o, 3'd0);
        check3("split ARPROT", d_axi_arprot_o, 3'b101);
        lane = (addr + i) & 7;
        d_axi_arready_i = 1'b1;
        lsa_tick();
        d_axi_arready_i = 1'b0;
        beat_data = ((expected >> (i * 8)) & 64'hff) << (lane * 8);
        d_axi_rdata_i = beat_data;
        d_axi_rresp_i = 2'b00;
        d_axi_rvalid_i = 1'b1;
        #1;
        check1("split downstream R ready", d_axi_rready_o, 1'b1);
        lsa_tick();
        d_axi_rvalid_i = 1'b0;
      end
      consume_u_r(expected, 2'b00, 1'b0);
    end
  endtask

  task automatic split_write(input logic [63:0] addr,
                             input logic [2:0] size,
                             input integer error_beat,
                             input logic [1:0] error_resp);
    reg [63:0] pattern;
    reg [63:0] beat_data;
    reg [1:0] beat_resp;
    integer count;
    integer i;
    integer lane;
    begin
      pattern = 64'h8877_6655_4433_2211 & data_mask(size);
      count = byte_count(size);
      d_axi_awready_i = 1'b0;
      d_axi_wready_i = 1'b0;
      launch_write(addr, size, pattern, low_strobe(size), 1'b1, 0);
      for (i = 0; i < count; i = i + 1) begin
        wait_d_aw_w();
        lane = (addr + i) & 7;
        beat_data = ((pattern >> (i * 8)) & 64'hff) << (lane * 8);
        check64("split AW byte address", d_axi_awaddr_o, addr + i);
        check3("split AW byte size", d_axi_awsize_o, 3'd0);
        check64("split W byte lane", d_axi_wdata_o, beat_data);
        check8("split W byte strobe", d_axi_wstrb_o, 8'h01 << lane);
        d_axi_awready_i = 1'b1;
        d_axi_wready_i = 1'b1;
        lsa_tick();
        d_axi_awready_i = 1'b0;
        d_axi_wready_i = 1'b0;
        beat_resp = (i == error_beat) ? error_resp : 2'b00;
        d_axi_bresp_i = beat_resp;
        d_axi_bvalid_i = 1'b1;
        #1;
        check1("split downstream B ready", d_axi_bready_o, 1'b1);
        if (i + 1 < count) begin
          check1("non-final split B remains internal",
                 u_axi_bvalid_o, 1'b0);
        end else begin
          check1("final split B falls through", u_axi_bvalid_o, 1'b1);
          check2("final split sticky response", u_axi_bresp_o, error_resp);
        end
        lsa_tick();
        d_axi_bvalid_i = 1'b0;
      end
      consume_u_b(error_resp, 1'b0);
    end
  endtask

  task automatic input_write_fallthrough_case(
      input logic [63:0] addr,
      input logic accept_aw_e0,
      input logic accept_w_e0,
      input integer order,
      input logic poison_after_e0,
      input logic [1:0] response);
    reg [63:0] pattern;
    reg [63:0] expected_data;
    reg [7:0] expected_strb;
    integer lane;
    integer before_aw;
    integer before_w;
    begin
      pattern = 64'h0000_0000_8877_6655;
      lane = addr[2:0];
      expected_data = pattern << (lane * 8);
      expected_strb = 8'h0f << lane;
      before_aw = d_aw_fires;
      before_w = d_w_fires;
      input_ft_cases = input_ft_cases + 1;
      case ({accept_aw_e0, accept_w_e0})
        2'b11: input_ft_11 = input_ft_11 + 1;
        2'b10: input_ft_10 = input_ft_10 + 1;
        2'b01: input_ft_01 = input_ft_01 + 1;
        default: input_ft_00 = input_ft_00 + 1;
      endcase
      case (order)
        1: input_ft_aw_first = input_ft_aw_first + 1;
        2: input_ft_w_first = input_ft_w_first + 1;
        default: input_ft_same_cycle = input_ft_same_cycle + 1;
      endcase

      $display("[CASE] input AW/W fall-through ready=%0d%0d order=%0d",
               accept_aw_e0, accept_w_e0, order);
      u_axi_split_allowed_i = 1'b0;
      u_axi_awaddr_i = addr;
      u_axi_awsize_i = 3'd2;
      u_axi_wdata_i = pattern;
      u_axi_wstrb_i = 8'h0f;
      d_axi_awready_i = accept_aw_e0;
      d_axi_wready_i = accept_w_e0;
      u_axi_awvalid_i = 1'b0;
      u_axi_wvalid_i = 1'b0;

      case (order)
        1: begin
          u_axi_awvalid_i = 1'b1;
          #1;
          check1("fall-through AW-first upstream accept",
                 u_axi_awready_o, 1'b1);
          check1("incomplete AW has no downstream AW",
                 d_axi_awvalid_o, 1'b0);
          check1("incomplete AW has no downstream W",
                 d_axi_wvalid_o, 1'b0);
          lsa_tick();
          u_axi_awvalid_i = 1'b0;
          #1;
          check1("held AW blocks read", u_axi_arready_o, 1'b0);
          u_axi_wvalid_i = 1'b1;
        end
        2: begin
          u_axi_wvalid_i = 1'b1;
          #1;
          check1("fall-through W-first upstream accept",
                 u_axi_wready_o, 1'b1);
          check1("incomplete W has no downstream AW",
                 d_axi_awvalid_o, 1'b0);
          check1("incomplete W has no downstream W",
                 d_axi_wvalid_o, 1'b0);
          lsa_tick();
          u_axi_wvalid_i = 1'b0;
          #1;
          check1("held W blocks read", u_axi_arready_o, 1'b0);
          u_axi_awvalid_i = 1'b1;
        end
        default: begin
          u_axi_awvalid_i = 1'b1;
          u_axi_wvalid_i = 1'b1;
        end
      endcase

      #1;
      check1("complete natural write offers direct AW",
             d_axi_awvalid_o, 1'b1);
      check1("complete natural write offers direct W",
             d_axi_wvalid_o, 1'b1);
      check64("direct AW address", d_axi_awaddr_o, addr);
      check3("direct AW size", d_axi_awsize_o, 3'd2);
      check64("direct W lane data", d_axi_wdata_o, expected_data);
      check8("direct W lane strobe", d_axi_wstrb_o, expected_strb);
      check1("complete write keeps read blocked", u_axi_arready_o, 1'b0);

      lsa_tick();
      if (poison_after_e0) begin
        // Once both upstream halves have fired, the producer may immediately
        // change its live payload.  The registered fallback must not observe
        // any of these deliberately incompatible values.
        u_axi_awaddr_i = 64'hdead_c0de_0000_0007;
        u_axi_awsize_i = 3'd7;
        u_axi_wdata_i = 64'hbad0_f00d_cafe_5a5a;
        u_axi_wstrb_i = 8'ha5;
      end
      u_axi_awvalid_i = 1'b0;
      u_axi_wvalid_i = 1'b0;
      #1;
      check1("E0 AW acceptance count",
             d_aw_fires == before_aw + accept_aw_e0, 1'b1);
      check1("E0 W acceptance count",
             d_w_fires == before_w + accept_w_e0, 1'b1);
      check1("accepted AW is not resent",
             d_axi_awvalid_o, !accept_aw_e0);
      check1("accepted W is not resent",
             d_axi_wvalid_o, !accept_w_e0);
      check64("fallback AW address", d_axi_awaddr_o, addr);
      check3("fallback AW size", d_axi_awsize_o, 3'd2);
      check64("fallback W lane data", d_axi_wdata_o, expected_data);
      check8("fallback W lane strobe", d_axi_wstrb_o, expected_strb);

      if (!(accept_aw_e0 && accept_w_e0)) begin
        d_axi_awready_i = 1'b1;
        d_axi_wready_i = 1'b1;
        lsa_tick();
      end
      d_axi_awready_i = 1'b0;
      d_axi_wready_i = 1'b0;
      #1;
      check1("logical write emits exactly one downstream AW",
             d_aw_fires == before_aw + 1, 1'b1);
      check1("logical write emits exactly one downstream W",
             d_w_fires == before_w + 1, 1'b1);
      if (!accept_aw_e0)
        check1("unaccepted AW fallback fires exactly once",
               d_aw_fires == before_aw + 1, 1'b1);
      if (!accept_w_e0)
        check1("unaccepted W fallback fires exactly once",
               d_w_fires == before_w + 1, 1'b1);
      check1("AW is quiet while awaiting B", d_axi_awvalid_o, 1'b0);
      check1("W is quiet while awaiting B", d_axi_wvalid_o, 1'b0);

      u_axi_bready_i = 1'b1;
      d_axi_bresp_i = response;
      d_axi_bvalid_i = 1'b1;
      #1;
      check1("fall-through case downstream B ready",
             d_axi_bready_o, 1'b1);
      check1("fall-through case upstream B visible",
             u_axi_bvalid_o, 1'b1);
      check2("fall-through case B response", u_axi_bresp_o, response);
      lsa_tick();
      d_axi_bvalid_i = 1'b0;
      u_axi_bready_i = 1'b0;
      #1;
      check1("fall-through case B terminates once", u_axi_bvalid_o, 1'b0);
      check1("fall-through case returns idle", u_axi_awready_o, 1'b1);
    end
  endtask

  task automatic reset_blocks_input_write_fallthrough;
    integer before_aw;
    integer before_w;
    begin
      before_aw = d_aw_fires;
      before_w = d_w_fires;
      d_axi_awready_i = 1'b1;
      d_axi_wready_i = 1'b1;
      u_axi_awaddr_i = 64'h0000_0000_0000_8400;
      u_axi_awsize_i = 3'd2;
      u_axi_wdata_i = 64'h0000_0000_4433_2211;
      u_axi_wstrb_i = 8'h0f;
      u_axi_awvalid_i = 1'b1;
      u_axi_wvalid_i = 1'b1;
      rst = 1'b1;
      #1;
      check1("reset masks direct input AW", d_axi_awvalid_o, 1'b0);
      check1("reset masks direct input W", d_axi_wvalid_o, 1'b0);
      lsa_tick();
      u_axi_awvalid_i = 1'b0;
      u_axi_wvalid_i = 1'b0;
      d_axi_awready_i = 1'b0;
      d_axi_wready_i = 1'b0;
      rst = 1'b0;
      lsa_tick();
      check1("reset input test emits no downstream AW",
             d_aw_fires == before_aw, 1'b1);
      check1("reset input test emits no downstream W",
             d_w_fires == before_w, 1'b1);
      check1("reset input test returns idle", u_axi_awready_o, 1'b1);
    end
  endtask

  task automatic final_b_response_case(input logic [1:0] response,
                                       input logic stall_upstream);
    begin
      d_axi_awready_i = 1'b0;
      d_axi_wready_i = 1'b0;
      u_axi_bready_i = 1'b0;
      launch_write(64'h0000_0000_0000_8100 + response,
                   3'd0, 64'h5a, 8'h01, 1'b0, 0);
      wait_d_aw_w();
      d_axi_awready_i = 1'b1;
      d_axi_wready_i = 1'b1;
      lsa_tick();
      d_axi_awready_i = 1'b0;
      d_axi_wready_i = 1'b0;

      u_axi_bready_i = !stall_upstream;
      d_axi_bresp_i = response;
      d_axi_bvalid_i = 1'b1;
      #1;
      check1("final downstream B ready is state-only",
             d_axi_bready_o, 1'b1);
      check1("final B visible without register bubble",
             u_axi_bvalid_o, 1'b1);
      check2("direct final B response", u_axi_bresp_o, response);
      lsa_tick();
      d_axi_bvalid_i = 1'b0;

      if (stall_upstream) begin
        #1;
        check1("stalled final B falls back to held response",
               u_axi_bvalid_o, 1'b1);
        check2("stalled final B response held", u_axi_bresp_o, response);
        lsa_tick();
        check1("stalled final B remains valid", u_axi_bvalid_o, 1'b1);
        check2("stalled final B remains stable", u_axi_bresp_o, response);
        u_axi_bready_i = 1'b1;
        lsa_tick();
        u_axi_bready_i = 1'b0;
      end else begin
        u_axi_bready_i = 1'b0;
      end
      #1;
      check1("final B terminates exactly once", u_axi_bvalid_o, 1'b0);
    end
  endtask

  task automatic reset_blocks_final_b_fallthrough;
    begin
      d_axi_awready_i = 1'b0;
      d_axi_wready_i = 1'b0;
      launch_write(64'h0000_0000_0000_8200,
                   3'd0, 64'ha5, 8'h01, 1'b0, 0);
      wait_d_aw_w();
      d_axi_awready_i = 1'b1;
      d_axi_wready_i = 1'b1;
      lsa_tick();
      d_axi_awready_i = 1'b0;
      d_axi_wready_i = 1'b0;
      d_axi_bresp_i = 2'b10;
      d_axi_bvalid_i = 1'b1;
      u_axi_bready_i = 1'b0;
      #1;
      check1("pre-reset final B is visible", u_axi_bvalid_o, 1'b1);
      rst = 1'b1;
      #1;
      check1("reset masks direct final B", u_axi_bvalid_o, 1'b0);
      lsa_tick();
      d_axi_bvalid_i = 1'b0;
      rst = 1'b0;
      lsa_tick();
      check1("reset leaves no held final B", u_axi_bvalid_o, 1'b0);
      check1("reset returns adapter idle", u_axi_awready_o, 1'b1);
    end
  endtask

  task automatic rejected_read(input logic [63:0] addr,
                               input logic [2:0] size);
    integer before_ar;
    begin
      before_ar = d_ar_fires;
      d_axi_arready_i = 1'b1;
      launch_read(addr, size, 1'b0);
      consume_u_r(64'd0, 2'b11, 1'b0);
      check1("rejected read has no downstream AR",
             d_ar_fires == before_ar, 1'b1);
      d_axi_arready_i = 1'b0;
    end
  endtask

  task automatic rejected_write(input logic [63:0] addr,
                                input logic [2:0] size,
                                input logic [7:0] strb,
                                input logic split_allowed);
    integer before_aw;
    integer before_w;
    begin
      before_aw = d_aw_fires;
      before_w = d_w_fires;
      d_axi_awready_i = 1'b1;
      d_axi_wready_i = 1'b1;
      launch_write(addr, size, 64'h8877_6655_4433_2211,
                   strb, split_allowed, 0);
      consume_u_b(2'b11, 1'b0);
      check1("rejected write has no downstream AW",
             d_aw_fires == before_aw, 1'b1);
      check1("rejected write has no downstream W",
             d_w_fires == before_w, 1'b1);
      d_axi_awready_i = 1'b0;
      d_axi_wready_i = 1'b0;
    end
  endtask

  task automatic oversized_write_fail_closed;
    integer before_aw;
    integer before_w;
    begin
      $display("[CASE] write AWSIZE>3 fail-closed");
      before_aw = d_aw_fires;
      before_w = d_w_fires;
      d_axi_awready_i = 1'b1;
      d_axi_wready_i = 1'b1;
      u_axi_bready_i = 1'b0;

      // WSTRB=0 matches the adapter's invalid-size low-mask result, so the
      // sole rejection reason is the unsupported AWSIZE itself.  Even PMEM's
      // split permission must not turn an over-wide request into side effects.
      launch_write(64'h0000_0000_0001_3000, 3'd4,
                   64'h0123_4567_89ab_cdef, 8'h00, 1'b1, 0);
      check1("oversized write presents no downstream AW",
             d_axi_awvalid_o, 1'b0);
      check1("oversized write presents no downstream W",
             d_axi_wvalid_o, 1'b0);
      check1("oversized write emits no downstream AW",
             d_aw_fires == before_aw, 1'b1);
      check1("oversized write emits no downstream W",
             d_w_fires == before_w, 1'b1);
      check1("oversized write returns upstream B",
             u_axi_bvalid_o, 1'b1);
      check2("oversized write returns DECERR",
             u_axi_bresp_o, 2'b11);

      u_axi_bready_i = 1'b1;
      lsa_tick();
      u_axi_bready_i = 1'b0;
      d_axi_awready_i = 1'b0;
      d_axi_wready_i = 1'b0;
      #1;
      check1("oversized write DECERR terminates once",
             u_axi_bvalid_o, 1'b0);
      check1("oversized write returns adapter idle",
             u_axi_awready_o, 1'b1);
    end
  endtask

  task automatic reset_inputs;
    begin
      u_axi_split_allowed_i = 1'b0;
      u_axi_arvalid_i = 1'b0;
      u_axi_araddr_i = 64'd0;
      u_axi_arsize_i = 3'd0;
      u_axi_arprot_i = 3'd0;
      u_axi_rready_i = 1'b0;
      u_axi_awvalid_i = 1'b0;
      u_axi_awaddr_i = 64'd0;
      u_axi_awsize_i = 3'd0;
      u_axi_wvalid_i = 1'b0;
      u_axi_wdata_i = 64'd0;
      u_axi_wstrb_i = 8'd0;
      u_axi_bready_i = 1'b0;
      d_axi_arready_i = 1'b0;
      d_axi_rvalid_i = 1'b0;
      d_axi_rdata_i = 64'd0;
      d_axi_rresp_i = 2'b00;
      d_axi_awready_i = 1'b0;
      d_axi_wready_i = 1'b0;
      d_axi_bvalid_i = 1'b0;
      d_axi_bresp_i = 2'b00;
    end
  endtask

  integer offset;
  integer order;
  initial begin
    errors = 0;
    d_ar_fires = 0;
    d_aw_fires = 0;
    d_w_fires = 0;
    input_ft_cases = 0;
    input_ft_11 = 0;
    input_ft_10 = 0;
    input_ft_01 = 0;
    input_ft_00 = 0;
    input_ft_same_cycle = 0;
    input_ft_aw_first = 0;
    input_ft_w_first = 0;
    reset_inputs();
    rst = 1'b1;
    repeat (3) lsa_tick();
    rst = 1'b0;
    lsa_tick();

    // 8 byte + 4 half + 2 word + 1 double = all 15 naturally aligned
    // offsets.  The write order rotates through same-cycle/AW-first/W-first.
    order = 0;
    for (offset = 0; offset < 8; offset = offset + 1) begin
      aligned_read(64'h1000 + offset, 3'd0, offset == 0);
      aligned_write(64'h2000 + offset, 3'd0, order, offset == 0);
      order = (order + 1) % 3;
    end
    for (offset = 0; offset < 8; offset = offset + 2) begin
      aligned_read(64'h3000 + offset, 3'd1, 1'b0);
      aligned_write(64'h4000 + offset, 3'd1, order, 1'b0);
      order = (order + 1) % 3;
    end
    for (offset = 0; offset < 8; offset = offset + 4) begin
      aligned_read(64'h5000 + offset, 3'd2, 1'b0);
      aligned_write(64'h6000 + offset, 3'd2, order, 1'b0);
      order = (order + 1) % 3;
    end
    aligned_read(64'h7000, 3'd3, 1'b0);
    aligned_write(64'h8000, 3'd3, order, 1'b0);

    // A complete, legal single-beat write is offered downstream in the same
    // cycle that the second upstream half arrives.  Exercise every independent
    // downstream AW/W acceptance outcome plus same-cycle/AW-first/W-first
    // upstream assembly, and prove that accepted channels are never resent.
    input_write_fallthrough_case(64'h8300, 1'b1, 1'b1, 0, 1'b0, 2'b00);
    input_write_fallthrough_case(64'h8304, 1'b1, 1'b0, 1, 1'b1, 2'b10);
    input_write_fallthrough_case(64'h8308, 1'b0, 1'b1, 2, 1'b0, 2'b11);
    input_write_fallthrough_case(64'h830c, 1'b0, 1'b0, 0, 1'b1, 2'b00);
    check1("input fall-through case count", input_ft_cases == 4, 1'b1);
    check1("input fall-through matrix 11", input_ft_11 == 1, 1'b1);
    check1("input fall-through matrix 10", input_ft_10 == 1, 1'b1);
    check1("input fall-through matrix 01", input_ft_01 == 1, 1'b1);
    check1("input fall-through matrix 00", input_ft_00 == 1, 1'b1);
    check1("input fall-through same-cycle order",
           input_ft_same_cycle == 2, 1'b1);
    check1("input fall-through AW-first order",
           input_ft_aw_first == 1, 1'b1);
    check1("input fall-through W-first order",
           input_ft_w_first == 1, 1'b1);
    $display("[WITNESS] input-aw-w-fallthrough cases=%0d matrix=11:%0d,10:%0d,01:%0d,00:%0d order=same:%0d,aw-first:%0d,w-first:%0d",
             input_ft_cases, input_ft_11, input_ft_10, input_ft_01,
             input_ft_00, input_ft_same_cycle, input_ft_aw_first,
             input_ft_w_first);
    reset_blocks_input_write_fallthrough();

    // A real final B is visible in S_W_RESP.  A ready owner consumes it in the
    // same cycle; a stalled owner gets the exact registered fallback.
    final_b_response_case(2'b00, 1'b0);
    final_b_response_case(2'b10, 1'b0);
    final_b_response_case(2'b11, 1'b1);
    reset_blocks_final_b_fallthrough();

    // PMEM-only split contract: SH@7, SW@6 and SD@1 cross an 8-byte lane.
    split_read(64'h9007, 3'd1);
    split_write(64'ha007, 3'd1, 0, 2'b11);
    split_read(64'hb006, 3'd2);
    split_write(64'hc006, 3'd2, 1, 2'b10);
    split_read(64'hd001, 3'd3);
    split_write(64'he001, 3'd3, 1, 2'b10);

    // MMIO/PTE/AMO mode cannot split: return DECERR without any downstream
    // request.  Sparse masks are rejected even when splitting is allowed.
    rejected_read(64'hf007, 3'd1);
    rejected_write(64'h1_0006, 3'd2, 8'h0f, 1'b0);
    rejected_write(64'h1_1000, 3'd2, 8'h05, 1'b1);
    rejected_write(64'h1_2000, 3'd2, 8'h00, 1'b1);
    oversized_write_fail_closed();

    if (errors == 0) begin
      $display("[PASS] tb_ooo_lsu_axi_lane_adapter");
      $finish;
    end
    $display("[FAIL] tb_ooo_lsu_axi_lane_adapter errors=%0d", errors);
    $fatal(1);
  end
endmodule
