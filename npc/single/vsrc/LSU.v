`include "define.v"

module LSU (
  input [`XLEN-1:0] eff_addr_i,
  input [`XLEN-1:0] store_data_i,
  input [1:0] mem_size_i,
  input mem_unsigned_i,
  input [`XLEN-1:0] mem_rdata_i,
  output reg [`XLEN-1:0] mem_addr_o,
  output reg [`XLEN-1:0] mem_wdata_o,
  output reg [3:0] mem_wstrb_o,
  output reg [`XLEN-1:0] load_data_o,
  output reg misaligned_o
);

  wire [4:0] byte_shift_w = {eff_addr_i[1:0], 3'b000};
  wire [`XLEN-1:0] shifted_rdata_w = mem_rdata_i >> byte_shift_w;
  wire [7:0] shifted_byte_w = shifted_rdata_w[7:0];
  wire [15:0] shifted_half_w = shifted_rdata_w[15:0];

  // LSU 统一负责 lane 选择、写掩码和 load 扩展，顶层只处理握手与异常裁决，边界更稳定。
  always @(*) begin
    mem_addr_o = {eff_addr_i[`XLEN-1:2], 2'b00};
    mem_wdata_o = store_data_i << byte_shift_w;
    mem_wstrb_o = 4'b0000;
    load_data_o = {`XLEN{1'b0}};
    misaligned_o = 1'b0;

    case (mem_size_i)
      `MEM_SIZE_BYTE: begin
        mem_wstrb_o = 4'b0001 << eff_addr_i[1:0];
        load_data_o = mem_unsigned_i ?
                      {{(`XLEN-8){1'b0}}, shifted_byte_w} :
                      {{(`XLEN-8){shifted_byte_w[7]}}, shifted_byte_w};
      end

      `MEM_SIZE_HALF: begin
        mem_wstrb_o = 4'b0011 << eff_addr_i[1:0];
        load_data_o = mem_unsigned_i ?
                      {{(`XLEN-16){1'b0}}, shifted_half_w} :
                      {{(`XLEN-16){shifted_half_w[15]}}, shifted_half_w};
        misaligned_o = eff_addr_i[0];
      end

      default: begin
        mem_wstrb_o = 4'b1111;
        load_data_o = shifted_rdata_w;
        misaligned_o = |eff_addr_i[1:0];
      end
    endcase
  end

endmodule
