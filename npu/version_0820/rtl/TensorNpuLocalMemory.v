`timescale 1ns/1ps

// SPDX-License-Identifier: Apache-2.0
// Byte-addressed local memory used by the functional Tensor NPU model.
//
// The array intentionally has no reset: software/testbench must initialize every
// byte that it consumes.  Read ports are combinational.  The write port commits
// all active byte lanes together at the rising clock edge, or commits none when
// any active lane is outside LMEM.
module TensorNpuLocalMemory #(
  parameter LMEM_BYTES = 4096
) (
  input  wire        clk,

  input  wire        rd0_valid_i,
  input  wire [31:0] rd0_addr_i,
  input  wire [3:0]  rd0_bytes_i,
  output reg  [63:0] rd0_data_o,
  output reg         rd0_oob_o,

  input  wire        rd1_valid_i,
  input  wire [31:0] rd1_addr_i,
  input  wire [3:0]  rd1_bytes_i,
  output reg  [63:0] rd1_data_o,
  output reg         rd1_oob_o,

  input  wire        wr_valid_i,
  input  wire [31:0] wr_addr_i,
  input  wire [63:0] wr_data_i,
  input  wire [7:0]  wr_strb_i,
  output reg         wr_oob_o
);

  reg [7:0] mem_q [0:LMEM_BYTES-1];

  // The extra address bit makes the end-exclusive checks immune to 32-bit
  // addition wraparound.
  localparam [32:0] LMEM_BYTES_U = LMEM_BYTES;

  integer rd0_lane;
  always @* begin
    rd0_data_o = 64'b0;
    rd0_oob_o  = 1'b0;

    if (rd0_valid_i) begin
      if ((rd0_bytes_i >= 4'd1) &&
          (rd0_bytes_i <= 4'd8) &&
          (({1'b0, rd0_addr_i} + {{29{1'b0}}, rd0_bytes_i}) <=
           LMEM_BYTES_U)) begin
        for (rd0_lane = 0; rd0_lane < 8; rd0_lane = rd0_lane + 1) begin
          if (rd0_lane < rd0_bytes_i)
            rd0_data_o[(rd0_lane * 8) +: 8] =
                mem_q[rd0_addr_i + rd0_lane];
        end
      end else begin
        rd0_oob_o = 1'b1;
      end
    end
  end

  integer rd1_lane;
  always @* begin
    rd1_data_o = 64'b0;
    rd1_oob_o  = 1'b0;

    if (rd1_valid_i) begin
      if ((rd1_bytes_i >= 4'd1) &&
          (rd1_bytes_i <= 4'd8) &&
          (({1'b0, rd1_addr_i} + {{29{1'b0}}, rd1_bytes_i}) <=
           LMEM_BYTES_U)) begin
        for (rd1_lane = 0; rd1_lane < 8; rd1_lane = rd1_lane + 1) begin
          if (rd1_lane < rd1_bytes_i)
            rd1_data_o[(rd1_lane * 8) +: 8] =
                mem_q[rd1_addr_i + rd1_lane];
        end
      end else begin
        rd1_oob_o = 1'b1;
      end
    end
  end

  // Only active byte lanes participate in write range checking.  Therefore an
  // all-zero strobe is a legal no-op even when wr_addr_i is outside LMEM.
  integer wr_check_lane;
  always @* begin
    wr_oob_o = 1'b0;
    if (wr_valid_i) begin
      for (wr_check_lane = 0;
           wr_check_lane < 8;
           wr_check_lane = wr_check_lane + 1) begin
        if (wr_strb_i[wr_check_lane] &&
            (({1'b0, wr_addr_i} + wr_check_lane) >= LMEM_BYTES_U))
          wr_oob_o = 1'b1;
      end
    end
  end

  integer wr_lane;
  always @(posedge clk) begin
    if (wr_valid_i && !wr_oob_o) begin
      for (wr_lane = 0; wr_lane < 8; wr_lane = wr_lane + 1) begin
        if (wr_strb_i[wr_lane])
          mem_q[wr_addr_i + wr_lane] <= wr_data_i[(wr_lane * 8) +: 8];
      end
    end
  end

`ifdef NPU_ASSERT
  // This checks an internal implication of the range checker.  External OOB
  // requests are legal fail-closed inputs and deliberately do not assert.
  integer assert_lane;
  always @(posedge clk) begin
    if (wr_valid_i && !wr_oob_o) begin
      for (assert_lane = 0; assert_lane < 8; assert_lane = assert_lane + 1) begin
        if (wr_strb_i[assert_lane] &&
            (({1'b0, wr_addr_i} + assert_lane) >= LMEM_BYTES_U)) begin
          $display("[NPU-LMEM][INTERNAL-FAIL] accepted write lane is OOB");
          $finish;
        end
      end
    end
  end
`endif

endmodule
