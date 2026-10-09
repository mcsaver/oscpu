`include "R64PlatformMap.vh"
// Native AXI4 fabric with real platform register devices. Four external Lite
// ports retain the PSRAM, SDRAM, legacy-MMIO and virtio device contracts.
module R64AxiPlatform (
  input          clk_i,
  input          rst_i,
  input          arvalid_i,
  output         arready_o,
  input  [  3:0] arid_i,
  input  [ 63:0] araddr_i,
  input  [  7:0] arlen_i,
  input  [  2:0] arsize_i, arprot_i,
  input  [  1:0] arburst_i,
  output         rvalid_o,
  input          rready_i,
  output [  3:0] rid_o,
  output [ 63:0] rdata_o,
  output [  1:0] rresp_o,
  output         rlast_o,
  input          awvalid_i,
  output         awready_o,
  input  [  3:0] awid_i,
  input  [ 63:0] awaddr_i,
  input  [  7:0] awlen_i,
  input  [  2:0] awsize_i,
  input  [  1:0] awburst_i,
  input          wvalid_i,
  output         wready_o,
  input  [ 63:0] wdata_i,
  input  [  7:0] wstrb_i,
  input          wlast_i,
  output         bvalid_o,
  input          bready_i,
  output [  3:0] bid_o,
  output [  1:0] bresp_o,
  output [  3:0] ext_arvalid_o,
  input  [  3:0] ext_arready_i,
  output [255:0] ext_araddr_o,
  output [ 11:0] ext_arsize_o, ext_arprot_o,
  input  [  3:0] ext_rvalid_i,
  output [  3:0] ext_rready_o,
  input  [255:0] ext_rdata_i,
  input  [  7:0] ext_rresp_i,
  output [  3:0] ext_awvalid_o,
  input  [  3:0] ext_awready_i,
  output [255:0] ext_awaddr_o,
  output [ 11:0] ext_awsize_o,
  output [  3:0] ext_wvalid_o,
  input  [  3:0] ext_wready_i,
  output [255:0] ext_wdata_o,
  output [ 31:0] ext_wstrb_o,
  input  [  3:0] ext_bvalid_i,
  output [  3:0] ext_bready_o,
  input  [  7:0] ext_bresp_i,
  input          uart_rx_valid_i,
  input  [  7:0] uart_rx_data_i,
  output         uart_rx_ready_o,
  output         uart_tx_valid_o,
  output [  7:0] uart_tx_data_o,
  input  [ 31:0] external_irq_sources_i,
  output         timer_wait_o,
  output [ 63:0] time_o,
  output         irq_software_o, irq_timer_o, irq_external_o, irq_supervisor_external_o,
  output         syscon_valid_o,
  output [ 31:0] syscon_value_o,
  output         protocol_error_o
);
  // Device reset shares the Fabric's local clearing edge. Fabric suppresses
  // all physical requests/responses during assertion and recovery.
  reg device_reset_q;
  always @(posedge clk_i) device_reset_q <= rst_i;
  wire device_tx_valid, device_syscon_valid, device_rx_ready;
  wire [7:0] device_tx_data;
  reg tx_valid_q;
  reg [7:0] tx_data_q;
  // Clear publishing state on the sampled external reset as well as the
  // distributed reset. Its VALID therefore already implies !device_reset_q.
  // Present a registered byte event at the platform boundary. UART native
  // register decode and FIFO state must not share the external pin budget.
  always @(posedge clk_i) begin
    if (rst_i || device_reset_q) tx_valid_q <= 0;
    else begin
      tx_valid_q <= device_tx_valid;
      if (device_tx_valid) tx_data_q <= device_tx_data;
    end
  end
  assign uart_tx_data_o  = tx_data_q;
  assign uart_tx_valid_o = tx_valid_q && !rst_i;
  assign syscon_valid_o  = device_syscon_valid && !rst_i;
  assign uart_rx_ready_o = device_rx_ready && !device_reset_q;
  wire [15:0] av, ar, rv, rr, aw, awr, wv, wr, bv, br;
  wire [1023:0] aa, rd, wa, wd;
  wire [47:0] az, ap, wz;
  wire [31:0] rp, bp;
  wire [127:0] ws;
  wire uart_irq, rtc_irq;
  wire [31:0] sources = external_irq_sources_i | {27'b0, rtc_irq, 2'b0, uart_irq, 1'b0};
  R64AxiFabric #(
    .READ_MEMORY_MASK(`R64_PLATFORM_READ_MEMORY),
    .BASE(`R64_PLATFORM_BASE),
    .MASK(`R64_PLATFORM_MASK),
    .MEMORY(`R64_PLATFORM_MEMORY),
    .EXECUTABLE(`R64_PLATFORM_EXECUTABLE)
  ) fabric (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .arvalid_i(arvalid_i),
    .arready_o(arready_o),
    .arid_i(arid_i),
    .araddr_i(araddr_i),
    .arlen_i(arlen_i),
    .arsize_i(arsize_i),
    .arprot_i(arprot_i),
    .arburst_i(arburst_i),
    .rvalid_o(rvalid_o),
    .rready_i(rready_i),
    .rid_o(rid_o),
    .rdata_o(rdata_o),
    .rresp_o(rresp_o),
    .rlast_o(rlast_o),
    .awvalid_i(awvalid_i),
    .awready_o(awready_o),
    .awid_i(awid_i),
    .awaddr_i(awaddr_i),
    .awlen_i(awlen_i),
    .awsize_i(awsize_i),
    .awburst_i(awburst_i),
    .wvalid_i(wvalid_i),
    .wready_o(wready_o),
    .wdata_i(wdata_i),
    .wstrb_i(wstrb_i),
    .wlast_i(wlast_i),
    .bvalid_o(bvalid_o),
    .bready_i(bready_i),
    .bid_o(bid_o),
    .bresp_o(bresp_o),
    .s_arvalid_o(av),
    .s_arready_i(ar),
    .s_araddr_o(aa),
    .s_arsize_o(az),
    .s_arprot_o(ap),
    .s_rvalid_i(rv),
    .s_rready_o(rr),
    .s_rdata_i(rd),
    .s_rresp_i(rp),
    .s_awvalid_o(aw),
    .s_awready_i(awr),
    .s_awaddr_o(wa),
    .s_awsize_o(wz),
    .s_wvalid_o(wv),
    .s_wready_i(wr),
    .s_wdata_o(wd),
    .s_wstrb_o(ws),
    .s_bvalid_i(bv),
    .s_bready_o(br),
    .s_bresp_i(bp),
    .protocol_error_o(protocol_error_o)
  );
  AxiClint #(
    .ADDR_W(64),
    .DATA_W(64),
    .STRB_W(8),
    .MTIME_DIVISOR(10)
  ) clint (
    .clk(clk_i),
    .rst(device_reset_q),
    .s_axi_arvalid_i(av[`R64_PORT_CLINT]),
    .s_axi_arready_o(ar[`R64_PORT_CLINT]),
    .s_axi_araddr_i(aa[`R64_PORT_CLINT*64+:64]),
    .s_axi_arsize_i(az[`R64_PORT_CLINT*3+:3]),
    .s_axi_rvalid_o(rv[`R64_PORT_CLINT]),
    .s_axi_rready_i(rr[`R64_PORT_CLINT]),
    .s_axi_rdata_o(rd[`R64_PORT_CLINT*64+:64]),
    .s_axi_rresp_o(rp[`R64_PORT_CLINT*2+:2]),
    .s_axi_awvalid_i(aw[`R64_PORT_CLINT]),
    .s_axi_awready_o(awr[`R64_PORT_CLINT]),
    .s_axi_awaddr_i(wa[`R64_PORT_CLINT*64+:64]),
    .s_axi_awsize_i(wz[`R64_PORT_CLINT*3+:3]),
    .s_axi_wvalid_i(wv[`R64_PORT_CLINT]),
    .s_axi_wready_o(wr[`R64_PORT_CLINT]),
    .s_axi_wdata_i(wd[`R64_PORT_CLINT*64+:64]),
    .s_axi_wstrb_i(ws[`R64_PORT_CLINT*8+:8]),
    .s_axi_bvalid_o(bv[`R64_PORT_CLINT]),
    .s_axi_bready_i(br[`R64_PORT_CLINT]),
    .s_axi_bresp_o(bp[`R64_PORT_CLINT*2+:2]),
    .mtime_o(time_o),
    .msip_irq_o(irq_software_o),
    .mtip_irq_o(irq_timer_o),
    .timer_wait_o(timer_wait_o)
  );
  AxiPlic #(
    .ADDR_W(64),
    .DATA_W(64),
    .STRB_W(8),
    .SOURCE_NUM(32)
  ) plic (
    .clk(clk_i),
    .rst(device_reset_q),
    .s_axi_arvalid_i(av[`R64_PORT_PLIC]),
    .s_axi_arready_o(ar[`R64_PORT_PLIC]),
    .s_axi_araddr_i(aa[`R64_PORT_PLIC*64+:64]),
    .s_axi_arsize_i(az[`R64_PORT_PLIC*3+:3]),
    .s_axi_rvalid_o(rv[`R64_PORT_PLIC]),
    .s_axi_rready_i(rr[`R64_PORT_PLIC]),
    .s_axi_rdata_o(rd[`R64_PORT_PLIC*64+:64]),
    .s_axi_rresp_o(rp[`R64_PORT_PLIC*2+:2]),
    .s_axi_awvalid_i(aw[`R64_PORT_PLIC]),
    .s_axi_awready_o(awr[`R64_PORT_PLIC]),
    .s_axi_awaddr_i(wa[`R64_PORT_PLIC*64+:64]),
    .s_axi_awsize_i(wz[`R64_PORT_PLIC*3+:3]),
    .s_axi_wvalid_i(wv[`R64_PORT_PLIC]),
    .s_axi_wready_o(wr[`R64_PORT_PLIC]),
    .s_axi_wdata_i(wd[`R64_PORT_PLIC*64+:64]),
    .s_axi_wstrb_i(ws[`R64_PORT_PLIC*8+:8]),
    .s_axi_bvalid_o(bv[`R64_PORT_PLIC]),
    .s_axi_bready_i(br[`R64_PORT_PLIC]),
    .s_axi_bresp_o(bp[`R64_PORT_PLIC*2+:2]),
    .source_irq_i(sources),
    .external_irq_o(),
    .machine_irq_o(irq_external_o),
    .supervisor_irq_o(irq_supervisor_external_o)
  );
  AxiResetSyscon #(
    .ADDR_W(64),
    .DATA_W(64),
    .STRB_W(8)
  ) syscon (
    .clk(clk_i),
    .rst(rst_i || device_reset_q),
    .s_axi_arvalid_i(av[`R64_PORT_RESET_SYSCON]),
    .s_axi_arready_o(ar[`R64_PORT_RESET_SYSCON]),
    .s_axi_araddr_i(aa[`R64_PORT_RESET_SYSCON*64+:64]),
    .s_axi_arsize_i(az[`R64_PORT_RESET_SYSCON*3+:3]),
    .s_axi_rvalid_o(rv[`R64_PORT_RESET_SYSCON]),
    .s_axi_rready_i(rr[`R64_PORT_RESET_SYSCON]),
    .s_axi_rdata_o(rd[`R64_PORT_RESET_SYSCON*64+:64]),
    .s_axi_rresp_o(rp[`R64_PORT_RESET_SYSCON*2+:2]),
    .s_axi_awvalid_i(aw[`R64_PORT_RESET_SYSCON]),
    .s_axi_awready_o(awr[`R64_PORT_RESET_SYSCON]),
    .s_axi_awaddr_i(wa[`R64_PORT_RESET_SYSCON*64+:64]),
    .s_axi_awsize_i(wz[`R64_PORT_RESET_SYSCON*3+:3]),
    .s_axi_wvalid_i(wv[`R64_PORT_RESET_SYSCON]),
    .s_axi_wready_o(wr[`R64_PORT_RESET_SYSCON]),
    .s_axi_wdata_i(wd[`R64_PORT_RESET_SYSCON*64+:64]),
    .s_axi_wstrb_i(ws[`R64_PORT_RESET_SYSCON*8+:8]),
    .s_axi_bvalid_o(bv[`R64_PORT_RESET_SYSCON]),
    .s_axi_bready_i(br[`R64_PORT_RESET_SYSCON]),
    .s_axi_bresp_o(bp[`R64_PORT_RESET_SYSCON*2+:2]),
    .syscon_write_valid_o(device_syscon_valid),
    .syscon_write_value_o(syscon_value_o)
  );
  wire unused_uart_access, unused_uart_write;
  wire [11:0] unused_uart_addr;
  wire [63:0] unused_uart_write_data, unused_uart_read_data;
  wire [7:0] unused_uart_strb;
  AxiToUart #(
    .ADDR_W(64),
    .DATA_W(64),
    .STRB_W(8)
  ) uart (
    .clk(clk_i),
    .rst(device_reset_q),
    .s_axi_arvalid_i(av[`R64_PORT_UART]),
    .s_axi_arready_o(ar[`R64_PORT_UART]),
    .s_axi_araddr_i(aa[`R64_PORT_UART*64+:64]),
    .s_axi_arsize_i(az[`R64_PORT_UART*3+:3]),
    .s_axi_rvalid_o(rv[`R64_PORT_UART]),
    .s_axi_rready_i(rr[`R64_PORT_UART]),
    .s_axi_rdata_o(rd[`R64_PORT_UART*64+:64]),
    .s_axi_rresp_o(rp[`R64_PORT_UART*2+:2]),
    .s_axi_awvalid_i(aw[`R64_PORT_UART]),
    .s_axi_awready_o(awr[`R64_PORT_UART]),
    .s_axi_awaddr_i(wa[`R64_PORT_UART*64+:64]),
    .s_axi_awsize_i(wz[`R64_PORT_UART*3+:3]),
    .s_axi_wvalid_i(wv[`R64_PORT_UART]),
    .s_axi_wready_o(wr[`R64_PORT_UART]),
    .s_axi_wdata_i(wd[`R64_PORT_UART*64+:64]),
    .s_axi_wstrb_i(ws[`R64_PORT_UART*8+:8]),
    .s_axi_bvalid_o(bv[`R64_PORT_UART]),
    .s_axi_bready_i(br[`R64_PORT_UART]),
    .s_axi_bresp_o(bp[`R64_PORT_UART*2+:2]),
    .uart_rx_valid_i(uart_rx_valid_i && !rst_i && !device_reset_q),
    .uart_rx_data_i(uart_rx_data_i),
    .uart_rx_ready_o(device_rx_ready),
    .uart_tx_valid_o(device_tx_valid),
    .uart_tx_data_o(device_tx_data),
    .uart_irq_o(uart_irq),
    .uart_access_valid_o(unused_uart_access),
    .uart_access_write_o(unused_uart_write),
    .uart_access_addr_o(unused_uart_addr),
    .uart_access_wdata_o(unused_uart_write_data),
    .uart_access_wstrb_o(unused_uart_strb),
    .uart_access_rdata_o(unused_uart_read_data)
  );
  R64AxiRtc rtc (
    .clk_i(clk_i),
    .rst_i(device_reset_q),
    .arvalid_i(av[`R64_PORT_RTC]),
    .arready_o(ar[`R64_PORT_RTC]),
    .araddr_i(aa[`R64_PORT_RTC*64+:12]),
    .arsize_i(az[`R64_PORT_RTC*3+:3]),
    .rvalid_o(rv[`R64_PORT_RTC]),
    .rready_i(rr[`R64_PORT_RTC]),
    .rdata_o(rd[`R64_PORT_RTC*64+:64]),
    .rresp_o(rp[`R64_PORT_RTC*2+:2]),
    .awvalid_i(aw[`R64_PORT_RTC]),
    .awready_o(awr[`R64_PORT_RTC]),
    .awaddr_i(wa[`R64_PORT_RTC*64+:12]),
    .awsize_i(wz[`R64_PORT_RTC*3+:3]),
    .wvalid_i(wv[`R64_PORT_RTC]),
    .wready_o(wr[`R64_PORT_RTC]),
    .wdata_i(wd[`R64_PORT_RTC*64+:64]),
    .wstrb_i(ws[`R64_PORT_RTC*8+:8]),
    .bvalid_o(bv[`R64_PORT_RTC]),
    .bready_i(br[`R64_PORT_RTC]),
    .bresp_o(bp[`R64_PORT_RTC*2+:2]),
    .irq_o(rtc_irq)
  );
  // Each nibble names the Fabric endpoint for one external AXI-Lite port.
  // Keep the external ABI order explicit; the loop below only repeats wiring.
  localparam [15:0] EXTERNAL_SLAVE_MAP = {
    `R64_PORT_VIRTIO_BLK,  // ext[3]
    `R64_PORT_LEGACY_MMIO, // ext[2]
    `R64_PORT_SDRAM,       // ext[1]
    `R64_PORT_PSRAM        // ext[0]
  };
  localparam [15:0] ERROR_PORTS = `R64_PLATFORM_ERROR_PORTS;
  genvar e;
  generate
    for (e = 0; e < 4; e = e + 1) begin : g_external
      localparam [3:0] FABRIC_PORT = EXTERNAL_SLAVE_MAP[e*4+:4];
      assign ext_arvalid_o[e] = av[FABRIC_PORT];
      assign ar[FABRIC_PORT] = ext_arready_i[e];
      assign ext_araddr_o[e*64+:64] = aa[FABRIC_PORT*64+:64];
      assign ext_arsize_o[e*3+:3] = az[FABRIC_PORT*3+:3];
      assign ext_arprot_o[e*3+:3] = ap[FABRIC_PORT*3+:3];
      assign rv[FABRIC_PORT] = ext_rvalid_i[e];
      assign ext_rready_o[e] = rr[FABRIC_PORT];
      assign rd[FABRIC_PORT*64+:64] = ext_rdata_i[e*64+:64];
      assign rp[FABRIC_PORT*2+:2] = ext_rresp_i[e*2+:2];
      assign ext_awvalid_o[e] = aw[FABRIC_PORT];
      assign awr[FABRIC_PORT] = ext_awready_i[e];
      assign ext_awaddr_o[e*64+:64] = wa[FABRIC_PORT*64+:64];
      assign ext_awsize_o[e*3+:3] = wz[FABRIC_PORT*3+:3];
      assign ext_wvalid_o[e] = wv[FABRIC_PORT];
      assign wr[FABRIC_PORT] = ext_wready_i[e];
      assign ext_wdata_o[e*64+:64] = wd[FABRIC_PORT*64+:64];
      assign ext_wstrb_o[e*8+:8] = ws[FABRIC_PORT*8+:8];
      assign bv[FABRIC_PORT] = ext_bvalid_i[e];
      assign ext_bready_o[e] = br[FABRIC_PORT];
      assign bp[FABRIC_PORT*2+:2] = ext_bresp_i[e*2+:2];
    end
    for (e = 0; e < `R64_PLATFORM_SLAVES; e = e + 1) begin : g_unimplemented
      if (ERROR_PORTS[e]) begin : g_error
        AxiDefaultSlave #(
          .DATA_W(64)
        ) error (
          .clk(clk_i),
          .rst(device_reset_q),
          .s_axi_arvalid_i(av[e]),
          .s_axi_arready_o(ar[e]),
          .s_axi_rvalid_o(rv[e]),
          .s_axi_rready_i(rr[e]),
          .s_axi_rdata_o(rd[e*64+:64]),
          .s_axi_rresp_o(rp[e*2+:2]),
          .s_axi_awvalid_i(aw[e]),
          .s_axi_awready_o(awr[e]),
          .s_axi_wvalid_i(wv[e]),
          .s_axi_wready_o(wr[e]),
          .s_axi_bvalid_o(bv[e]),
          .s_axi_bready_i(br[e]),
          .s_axi_bresp_o(bp[e*2+:2])
        );
      end
    end
  endgenerate
endmodule
