`timescale 10ps/1ps
// Compare settled behavior with the vendor delayed core and an independent
// expected-memory scoreboard. The vendor module is renamed only in build/.
module tb_ics55_ecos_sram_cycle;
  reg CLK = 0;
  always #5 CLK = !CLK;
  reg [7:0] A = 0;
  reg [127:0] D = 0;
  reg CEB = 1;
  reg GWEB = 1;
  reg [3:0] MAR = 0;
  reg MARE = 0;
  wire [127:0] Q;
  wire [127:0] Q_ref;
  reg [127:0] expected [0:255];
  reg [127:0] expected_q;
  reg [127:0] pattern;
  integer checks = 0;
  integer i;
  integer bit_index;

  ics55_ecos_sram_256x128_m4_ww dut (
    .MAR(MAR), .D(D), .Q(Q), .MARE(MARE), .GWEB(GWEB),
    .A(A), .CLK(CLK), .CEB(CEB)
  );
  ics55_ecos_sram_256x128_m4_ww_reference reference (
    .MAR(MAR), .D(D), .Q(Q_ref), .MARE(MARE), .GWEB(GWEB),
    .A(A), .CLK(CLK), .CEB(CEB)
  );

  task automatic transfer(
    input reg disabled,
    input reg read_only,
    input reg [7:0] address,
    input reg [127:0] data
  );
    begin
      @(negedge CLK);
      CEB = disabled;
      GWEB = read_only;
      A = address;
      D = data;
      MAR = address[3:0];
      MARE = address[4];
      #2;
      if (Q !== expected_q || Q_ref !== expected_q)
        $fatal(1, "output changed without rising edge check=%0d", checks);
      @(posedge CLK);
      if (!disabled && !read_only) begin
        expected[address] = data;
        expected_q = data;
      end else if (!disabled && read_only) expected_q = expected[address];
      // Official core uses <= #1. Sample after that delayed update settles.
      #2;
      if (Q !== Q_ref || Q !== expected_q)
        $fatal(1, "macro mismatch check=%0d CEB=%b GWEB=%b A=%0d got=%h vendor=%h expected=%h",
               checks, disabled, read_only, address, Q, Q_ref, expected_q);
      checks = checks + 1;
    end
  endtask

  initial begin
    // No reset: uninitialized Q/storage remain unknown in four-state views.
    transfer(1, 1, 8'd0, 128'd0);
    transfer(0, 1, 8'd255, 128'd0);
    for (i = 0; i < 256; i = i + 1) begin
      pattern = {32'h13579bdf ^ 32'(i), 32'h2468ace0 ^ (32'(i) << 8),
                 32'h89abcdef ^ (32'(i) << 16), 32'hfedcba98 ^ (32'(i) << 24)};
      transfer(0, 0, 8'(i), pattern);
    end
    for (i = 255; i >= 0; i = i - 1)
      transfer(0, 1, 8'(i), 128'd0);
    // Disabled writes must not change Q or corrupt any addressed row.
    for (i = 0; i < 256; i = i + 1) begin
      transfer(1, 0, 8'(i), ~expected[i]);
      transfer(1, 1, 8'(255-i), 128'd0);
      transfer(0, 1, 8'(i), 128'd0);
    end
    for (i = 0; i < 256; i = i + 1) begin
      pattern = ~expected[i];
      transfer(0, 0, 8'(i), pattern);
    end
    for (i = 255; i >= 0; i = i - 1)
      transfer(0, 1, 8'(i), 128'd0);
    // Preserve the official core's four-state conditional control behavior.
    transfer(1'bx, 0, 8'd0, 128'd0);
    transfer(0, 1'bx, 8'd255, 128'd0);
    // Walking one/zero exercises every D/Q bit in both 64-bit halves.
    for (bit_index = 0; bit_index < 128; bit_index = bit_index + 1) begin
      pattern = 128'd1 << bit_index;
      transfer(0, 0, 8'(bit_index), pattern);
      transfer(0, 1, 8'(bit_index), 128'd0);
      transfer(0, 0, 8'(bit_index + 128), ~pattern);
      transfer(0, 1, 8'(bit_index + 128), 128'd0);
    end
    $display("[PASS] tb_ics55_ecos_sram_cycle checks=%0d addresses=256 bits=128 vendor_core=matched ce_hold=checked write_through=checked", checks);
    $finish;
  end
endmodule
