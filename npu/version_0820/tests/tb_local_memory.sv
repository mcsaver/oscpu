`timescale 1ns/1ps

module tb_local_memory;
  localparam int LMEM_BYTES = 32;

  logic        clk;
  logic        rd0_valid;
  logic [31:0] rd0_addr;
  logic [3:0]  rd0_bytes;
  wire  [63:0] rd0_data;
  wire         rd0_oob;
  logic        rd1_valid;
  logic [31:0] rd1_addr;
  logic [3:0]  rd1_bytes;
  wire  [63:0] rd1_data;
  wire         rd1_oob;
  logic        wr_valid;
  logic [31:0] wr_addr;
  logic [63:0] wr_data;
  logic [7:0]  wr_strb;
  wire         wr_oob;

  TensorNpuLocalMemory #(
    .LMEM_BYTES(LMEM_BYTES)
  ) dut (
    .clk          (clk),
    .rd0_valid_i  (rd0_valid),
    .rd0_addr_i   (rd0_addr),
    .rd0_bytes_i  (rd0_bytes),
    .rd0_data_o   (rd0_data),
    .rd0_oob_o    (rd0_oob),
    .rd1_valid_i  (rd1_valid),
    .rd1_addr_i   (rd1_addr),
    .rd1_bytes_i  (rd1_bytes),
    .rd1_data_o   (rd1_data),
    .rd1_oob_o    (rd1_oob),
    .wr_valid_i   (wr_valid),
    .wr_addr_i    (wr_addr),
    .wr_data_i    (wr_data),
    .wr_strb_i    (wr_strb),
    .wr_oob_o     (wr_oob)
  );

  always #5 clk <= ~clk;

  task automatic fail(input string reason);
    begin
      $display("[NPU-LMEM][FAIL] %s", reason);
      $fatal(1);
    end
  endtask

  task automatic issue_write(
    input logic [31:0] addr,
    input logic [63:0] data,
    input logic [7:0]  strb,
    input logic        expected_oob
  );
    begin
      @(negedge clk);
      wr_valid = 1'b1;
      wr_addr  = addr;
      wr_data  = data;
      wr_strb  = strb;
      #1;
      if (wr_oob !== expected_oob)
        fail($sformatf("write OOB mismatch addr=%0d strb=%02x got=%b expected=%b",
                       addr, strb, wr_oob, expected_oob));
      @(posedge clk);
      #1;
      wr_valid = 1'b0;
      wr_addr  = 32'b0;
      wr_data  = 64'b0;
      wr_strb  = 8'b0;
    end
  endtask

  task automatic check_read0(
    input logic [31:0] addr,
    input logic [3:0]  bytes,
    input logic [63:0] expected_data,
    input logic        expected_oob
  );
    begin
      rd0_valid = 1'b1;
      rd0_addr  = addr;
      rd0_bytes = bytes;
      #1;
      if ((rd0_oob !== expected_oob) || (rd0_data !== expected_data))
        fail($sformatf("read0 mismatch addr=%0d bytes=%0d data=%016x/%016x oob=%b/%b",
                       addr, bytes, rd0_data, expected_data,
                       rd0_oob, expected_oob));
      rd0_valid = 1'b0;
      rd0_addr  = 32'b0;
      rd0_bytes = 4'b0;
      #1;
      if ((rd0_oob !== 1'b0) || (rd0_data !== 64'b0))
        fail("inactive read0 did not return zero/clear OOB");
    end
  endtask

  initial begin
    clk       = 1'b0;
    rd0_valid = 1'b0;
    rd0_addr  = 32'b0;
    rd0_bytes = 4'b0;
    rd1_valid = 1'b0;
    rd1_addr  = 32'b0;
    rd1_bytes = 4'b0;
    wr_valid  = 1'b0;
    wr_addr   = 32'b0;
    wr_data   = 64'b0;
    wr_strb   = 8'b0;

    // Initialize only regions consumed below; the DUT deliberately has no reset.
    issue_write(32'd0,  64'h8877_6655_4433_2211, 8'hff, 1'b0);
    issue_write(32'd8,  64'h0000_0000_0000_0000, 8'hff, 1'b0);
    issue_write(32'd24, 64'h0000_0000_0000_0000, 8'hff, 1'b0);

    // 1/4/8-byte little-endian reads and zero-filled unused lanes.
    check_read0(32'd0, 4'd1, 64'h0000_0000_0000_0011, 1'b0);
    check_read0(32'd0, 4'd4, 64'h0000_0000_4433_2211, 1'b0);
    check_read0(32'd0, 4'd8, 64'h8877_6655_4433_2211, 1'b0);

    // Partial strobes update exactly their selected little-endian lanes.
    issue_write(32'd8, 64'hffee_ddcc_bbaa_9988, 8'h2d, 1'b0);
    check_read0(32'd8, 4'd8, 64'h0000_dd00_bbaa_0088, 1'b0);

    // Both independent combinational read ports operate in the same cycle.
    rd0_valid = 1'b1;
    rd0_addr  = 32'd0;
    rd0_bytes = 4'd4;
    rd1_valid = 1'b1;
    rd1_addr  = 32'd8;
    rd1_bytes = 4'd4;
    #1;
    if (rd0_oob || (rd0_data !== 64'h0000_0000_4433_2211))
      fail("simultaneous read port 0 mismatch");
    if (rd1_oob || (rd1_data !== 64'h0000_0000_bbaa_0088))
      fail("simultaneous read port 1 mismatch");
    rd0_valid = 1'b0;
    rd1_valid = 1'b0;

    // The final byte is a legal one-byte access.
    issue_write(32'd31, 64'h0000_0000_0000_00a5, 8'h01, 1'b0);
    check_read0(32'd31, 4'd1, 64'h0000_0000_0000_00a5, 1'b0);

    // Invalid byte counts fail closed and never expose memory contents.
    rd0_valid = 1'b1;
    rd0_addr  = 32'd0;
    rd0_bytes = 4'd0;
    rd1_valid = 1'b1;
    rd1_addr  = 32'd0;
    rd1_bytes = 4'd9;
    #1;
    if (!rd0_oob || (rd0_data !== 64'b0))
      fail("bytes=0 did not fail closed");
    if (!rd1_oob || (rd1_data !== 64'b0))
      fail("bytes=9 did not fail closed");
    rd0_valid = 1'b0;
    rd1_valid = 1'b0;

    // Seed the last two bytes, then prove an OOB lane cancels the entire write.
    issue_write(32'd30, 64'h0000_0000_0000_beef, 8'h03, 1'b0);
    issue_write(32'd30, 64'h0000_0000_00cc_bbaa, 8'h07, 1'b1);
    check_read0(32'd30, 4'd2, 64'h0000_0000_0000_beef, 1'b0);

    // A zero strobe is a valid no-op, including for an otherwise invalid address.
    issue_write(32'hffff_fff0, 64'hdead_beef_cafe_f00d, 8'h00, 1'b0);
    check_read0(32'd0, 4'd8, 64'h8877_6655_4433_2211, 1'b0);

    $display("[NPU-LMEM][PASS]");
    $finish;
  end

endmodule
