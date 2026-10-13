// One ICache way's synchronous full-word data port. The macro Q replaces the
// existing lookup register; no extra pipeline edge or request owner is added.
// Fill writes and LOOKUP reads are exclusive. Q during a write is not an
// instruction response; cache valid/lookup state remains outside this leaf.
module R64ICacheData #(
  parameter ADDR_W = 8,
  parameter WORDS = (1 << ADDR_W)
) (
  input                   clk_i,
  input                   read_i,
  input  [ADDR_W-1:0]      read_addr_i,
  input                   write_i,
  input  [ADDR_W-1:0]      write_addr_i,
  input  [127:0]           write_data_i,
  output [127:0]           read_data_o
);
  generate
    if (ADDR_W == 8 && WORDS == 256) begin : g_ecos
      wire [7:0] address_w = write_i ? write_addr_i : read_addr_i;
      ics55_ecos_sram_256x128_m4_ww macro (
        .CLK(clk_i),
        .CEB(!(read_i || write_i)),
        .GWEB(!write_i),
        .A(address_w),
        .D(write_data_i),
        .Q(read_data_o),
        .MARE(1'b0),
        .MAR(4'b0000)
      );
    end else begin : g_generic
      // Explicit small-geometry fallback for parameterized module tests.
      // Production SET_W=6/SETS=64 always elaborates g_ecos instead.
      reg [127:0] memory_q[0:WORDS-1];
      reg [127:0] output_q;
      always @(posedge clk_i) begin
        if (write_i) begin
          memory_q[write_addr_i] <= write_data_i;
          output_q <= write_data_i;
        end else if (read_i) output_q <= memory_q[read_addr_i];
      end
      assign read_data_o = output_q;
    end
  endgenerate
`ifdef R64_ASSERT
  always @(posedge clk_i)
    if (read_i && write_i)
      $fatal(1, "ICache data single port received simultaneous read/write");
`endif
endmodule
