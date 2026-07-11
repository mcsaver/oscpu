`timescale 1ns/1ps
`include "define.v"

// Local transition test for the already-decoded bridge state:
// PC ends at page+0xffe, first halfword is a legal compressed instruction,
// and translation/PMP of the second page has already produced PAGE_FAULT.
module tb_fetch_page_end_c_fault;
  reg clk = 1'b0;
  reg rst = 1'b1;
  reg rvalid = 1'b0;
  reg [63:0] rdata = 64'b0;
  reg [1:0] rresp = 2'b00;

  wire rsp_valid;
  wire [31:0] rsp_inst0;
  wire [1:0] rsp_resp0;
  wire [31:0] rsp_inst1;
  wire [1:0] rsp_resp1;

  wire [63:0] dec0_pc;
  wire [63:0] dec0_next_pc;
  wire [31:0] dec0_inst;
  wire [1:0] dec0_resp;
  wire dec0_stop;
  wire [63:0] dec1_pc;
  wire [63:0] dec1_next_pc;
  wire [31:0] dec1_inst;
  wire [1:0] dec1_resp;
  wire dec1_stop;
  wire dec0_branch;
  wire [63:0] dec0_bimm;
  wire dec1_branch;
  wire [63:0] dec1_bimm;
  wire [63:0] packet_next_pc;

  always #5 clk = ~clk;

  OooFetchAxiBridge dut (
    .clk(clk), .rst(rst), .mmu_flush_i(1'b0),
    .invalidate_valid_i(1'b0), .invalidate_addr_i(64'b0),
    .priv_mode_i(`PRIV_S), .satp_i(64'b0), .svpbmt_en_i(1'b0),
    .pmpcfg_i({`PMP_CFG_BUS_W{1'b0}}),
    .pmpaddr_i({`PMP_ADDR_BUS_W{1'b0}}),
    .fetch_req_valid_i(1'b0), .fetch_req_pc_i(64'b0),
    .fetch_rsp_valid_o(rsp_valid), .fetch_rsp_ready_i(1'b0),
    .fetch_rsp_inst0_o(rsp_inst0), .fetch_rsp_resp0_o(rsp_resp0),
    .fetch_rsp_inst1_o(rsp_inst1), .fetch_rsp_resp1_o(rsp_resp1),
    .ifu_axi_arready_i(1'b0), .ifu_axi_rvalid_i(rvalid),
    .ifu_axi_rdata_i(rdata), .ifu_axi_rresp_i(rresp),
    .ifu_axi_awready_i(1'b0), .ifu_axi_wready_i(1'b0),
    .ifu_axi_bvalid_i(1'b0), .ifu_axi_bresp_i(2'b00)
  );

  OooFetchPacketDecode decode (
    .rsp_pc_i(64'h0000_0000_8000_0ffe),
    .rsp_inst0_i(rsp_inst0), .rsp_resp0_i(rsp_resp0),
    .rsp_inst1_i(rsp_inst1), .rsp_resp1_i(rsp_resp1),
    .dec0_pc_o(dec0_pc), .dec0_next_pc_o(dec0_next_pc),
    .dec0_inst_o(dec0_inst), .dec0_resp_o(dec0_resp),
    .dec0_control_stop_o(dec0_stop),
    .dec1_pc_o(dec1_pc), .dec1_next_pc_o(dec1_next_pc),
    .dec1_inst_o(dec1_inst), .dec1_resp_o(dec1_resp),
    .dec1_control_stop_o(dec1_stop),
    .dec0_branch_o(dec0_branch), .dec0_bimm_o(dec0_bimm),
    .dec1_branch_o(dec1_branch), .dec1_bimm_o(dec1_bimm),
    .packet_next_pc_o(packet_next_pc)
  );

  initial begin
    repeat (2) @(posedge clk);
    #1 rst = 1'b0;
    @(negedge clk);

    // Deposit a state reachable after the second-page walk failed and the bridge
    // returned to fetch the two valid bytes remaining in the first page.
    dut.state_q = 4'd4;                 // S_R0
    dut.pc_q = 64'h0000_0000_8000_0ffe;
    dut.packet_cross_page_q = 1'b1;
    dut.packet_first_bytes_q = 3'd2;
    dut.resp0_q = 2'b00;                // first page itself is executable
    dut.resp1_q = 2'b10;                // second-page instruction page fault
    rdata = 64'h0000_0000_0000_0001;   // low halfword 0x0001 = C.NOP
    rresp = 2'b00;
    rvalid = 1'b1;

    @(posedge clk);
    #1 rvalid = 1'b0;

    if (rsp_valid && rsp_inst0[15:0] == 16'h0001 &&
        dec0_next_pc == 64'h0000_0000_8000_1000 && dec0_resp == 2'b10) begin
      $display("BUG_REPRODUCED pc=%h c_half=%h next_pc=%h resp0=%b",
               dec0_pc, rsp_inst0[15:0], dec0_next_pc, dec0_resp);
      $finish_and_return(0);
    end

    $display("BUG_NOT_REPRODUCED valid=%0d inst0=%h next=%h resp0=%b state=%0d",
             rsp_valid, rsp_inst0, dec0_next_pc, dec0_resp, dut.state_q);
    $finish_and_return(1);
  end
endmodule
