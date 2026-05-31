`include "define.v"

module LSUControl (
  input [`XLEN_BYTE_W-1:0] addr_low_i,
  input [1:0] mem_size_i,
  input mem_unsigned_i,
  output reg [`XLEN_BIT_SHIFT-1:0] byte_shift_o,
  output reg [`STRB_W-1:0] mem_wstrb_o,
  output reg [1:0] load_size_o,
  output reg load_unsigned_o,
  output reg misaligned_o
);

  // 控制面只根据访问粒度和低地址位产生 lane 控制，数据搬移留给 LSUDataPath。
  always @(*) begin
    byte_shift_o = {addr_low_i, 3'b000};
    mem_wstrb_o = {`STRB_W{1'b0}};
    load_size_o = mem_size_i;
    load_unsigned_o = mem_unsigned_i;
    misaligned_o = 1'b0;

    case (mem_size_i)
      `MEM_SIZE_BYTE: begin
        mem_wstrb_o = {{(`STRB_W-1){1'b0}}, 1'b1} << addr_low_i;
      end

      `MEM_SIZE_HALF: begin
        mem_wstrb_o = {{(`STRB_W-2){1'b0}}, 2'b11} << addr_low_i;
        misaligned_o = addr_low_i[0];
      end

      `MEM_SIZE_WORD: begin
        mem_wstrb_o = {{(`STRB_W-4){1'b0}}, 4'b1111} << addr_low_i;
        misaligned_o = |addr_low_i[1:0];
      end

      default: begin
        mem_wstrb_o = {`STRB_W{1'b1}};
        misaligned_o = |addr_low_i;
      end
    endcase
  end

endmodule
