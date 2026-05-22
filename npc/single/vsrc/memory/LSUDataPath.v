`include "define.v"

module LSUDataPath (
  input [`XLEN-1:0] eff_addr_i,
  input [`XLEN-1:0] store_data_i,
  input [4:0] byte_shift_i,
  input [1:0] load_size_i,
  input load_unsigned_i,
  input [`XLEN-1:0] mem_rdata_i,
  output [`XLEN-1:0] mem_addr_o,
  output [`XLEN-1:0] mem_wdata_o,
  output reg [`XLEN-1:0] load_data_o
);

  wire [`XLEN-1:0] shifted_rdata_w = mem_rdata_i >> byte_shift_i;
  wire [7:0] shifted_byte_w = shifted_rdata_w[7:0];
  wire [15:0] shifted_half_w = shifted_rdata_w[15:0];

  // 数据面只做地址对齐、store 数据移位和 load 提取扩展，不再决定访问是否合法。
  assign mem_addr_o = eff_addr_i & {{(`XLEN-2){1'b1}}, 2'b00};
  assign mem_wdata_o = store_data_i << byte_shift_i;

  always @(*) begin
    load_data_o = {`XLEN{1'b0}};

    case (load_size_i)
      `MEM_SIZE_BYTE: begin
        load_data_o = load_unsigned_i ?
                      {{(`XLEN-8){1'b0}}, shifted_byte_w} :
                      {{(`XLEN-8){shifted_byte_w[7]}}, shifted_byte_w};
      end

      `MEM_SIZE_HALF: begin
        load_data_o = load_unsigned_i ?
                      {{(`XLEN-16){1'b0}}, shifted_half_w} :
                      {{(`XLEN-16){shifted_half_w[15]}}, shifted_half_w};
      end

      default: begin
        load_data_o = shifted_rdata_w;
      end
    endcase
  end

endmodule
