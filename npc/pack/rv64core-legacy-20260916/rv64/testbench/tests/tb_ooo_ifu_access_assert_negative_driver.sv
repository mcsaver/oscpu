// Reviewer-only second top: intentionally violates exactly one IFU-ACCESS-G1
// bridge assertion per run. Production RTL and the positive bridge TB are not edited.
module tb_ooo_ifu_access_assert_negative_driver;
  string marker;

  initial begin
    if (!$value$plusargs("ACCESS_ASSERT=%s", marker)) begin
      $display("ACCESS-ASSERT-NEGATIVE-SKIP");
      $finish;
    end

    wait (tb_ooo_fetch_axi_bridge.rst === 1'b0);
    @(negedge tb_ooo_fetch_axi_bridge.clk);

    // Default payload satisfies every IFU-ACCESS response invariant.
    force tb_ooo_fetch_axi_bridge.dut.g2_assert_rsp_stall_q = 1'b0;
    force tb_ooo_fetch_axi_bridge.dut.g2_assert_resp0_bytes_q = 3'd4;
    force tb_ooo_fetch_axi_bridge.dut.fetch_rsp_valid_o = 1'b1;
    force tb_ooo_fetch_axi_bridge.dut.fetch_rsp_resp0_bytes_o = 3'd4;
    force tb_ooo_fetch_axi_bridge.dut.fetch_rsp_resp0_o = 2'b00;
    force tb_ooo_fetch_axi_bridge.dut.fetch_rsp_resp1_o = 2'b00;

    if (marker == "HOLD") begin
      force tb_ooo_fetch_axi_bridge.dut.g2_assert_rsp_stall_q = 1'b1;
      force tb_ooo_fetch_axi_bridge.dut.g2_assert_resp0_bytes_q = 3'd2;
    end else if (marker == "SPLIT-RANGE") begin
      force tb_ooo_fetch_axi_bridge.dut.fetch_rsp_resp0_bytes_o = 3'd1;
      force tb_ooo_fetch_axi_bridge.dut.fetch_rsp_resp1_o = 2'b10;
    end else if (marker == "SUCCESS-SPLIT") begin
      force tb_ooo_fetch_axi_bridge.dut.fetch_rsp_resp0_bytes_o = 3'd2;
    end else if (marker == "FAULT-ABI") begin
      force tb_ooo_fetch_axi_bridge.dut.fetch_rsp_resp0_bytes_o = 3'd2;
      force tb_ooo_fetch_axi_bridge.dut.fetch_rsp_resp0_o = 2'b10;
      force tb_ooo_fetch_axi_bridge.dut.fetch_rsp_resp1_o = 2'b10;
    end else begin
      $display("ACCESS-ASSERT-NEGATIVE-UNKNOWN marker=%s", marker);
      $finish;
    end

    @(posedge tb_ooo_fetch_axi_bridge.clk);
    #1;
    $display("ACCESS-ASSERT-NEGATIVE-DONE marker=%s", marker);
    $finish;
  end
endmodule
