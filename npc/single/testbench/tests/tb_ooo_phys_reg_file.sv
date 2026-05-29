`include "define.v"

module tb_ooo_phys_reg_file;
  `include "tb_common.svh"

  localparam PHY_REG_ADDR_W = 6;

  reg clk;
  reg rst;
  reg [PHY_REG_ADDR_W-1:0] read0_addr;
  wire [`XLEN-1:0] read0_data;
  reg [PHY_REG_ADDR_W-1:0] read1_addr;
  wire [`XLEN-1:0] read1_data;
  reg [PHY_REG_ADDR_W-1:0] read2_addr;
  wire [`XLEN-1:0] read2_data;
  reg [PHY_REG_ADDR_W-1:0] read3_addr;
  wire [`XLEN-1:0] read3_data;
  reg [PHY_REG_ADDR_W-1:0] read4_addr;
  wire [`XLEN-1:0] read4_data;
  reg [PHY_REG_ADDR_W-1:0] read5_addr;
  wire [`XLEN-1:0] read5_data;
  reg write0_valid;
  reg [PHY_REG_ADDR_W-1:0] write0_addr;
  reg [`XLEN-1:0] write0_data;
  reg write1_valid;
  reg [PHY_REG_ADDR_W-1:0] write1_addr;
  reg [`XLEN-1:0] write1_data;

  OooPhysRegFile dut (
    .clk(clk),
    .rst(rst),
    .read0_addr_i(read0_addr),
    .read0_data_o(read0_data),
    .read1_addr_i(read1_addr),
    .read1_data_o(read1_data),
    .read2_addr_i(read2_addr),
    .read2_data_o(read2_data),
    .read3_addr_i(read3_addr),
    .read3_data_o(read3_data),
    .read4_addr_i(read4_addr),
	    .read4_data_o(read4_data),
	    .read5_addr_i(read5_addr),
	    .read5_data_o(read5_data),
	    .write0_valid_i(write0_valid),
    .write0_addr_i(write0_addr),
    .write0_data_i(write0_data),
    .write1_valid_i(write1_valid),
    .write1_addr_i(write1_addr),
    .write1_data_i(write1_data)
  );

  task automatic clear_inputs;
    begin
      read0_addr = 6'd0;
      read1_addr = 6'd0;
      read2_addr = 6'd0;
      read3_addr = 6'd0;
      read4_addr = 6'd0;
      read5_addr = 6'd0;
      write0_valid = 1'b0;
      write0_addr = 6'd0;
      write0_data = 32'h0;
      write1_valid = 1'b0;
      write1_addr = 6'd0;
      write1_data = 32'h0;
    end
  endtask

  task automatic reset_dut;
    begin
      clk = 1'b0;
      rst = 1'b1;
      clear_inputs();
      `TB_TICK(clk);
      rst = 1'b0;
      #1;
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();

    read0_addr = 6'd1;
    read1_addr = 6'd0;
    #1;
    tb_check32("reset p1 zero", read0_data, 32'h0);
    tb_check32("p0 zero", read1_data, 32'h0);

    write0_valid = 1'b1;
    write0_addr = 6'd1;
    write0_data = 32'h1111_0001;
    write1_valid = 1'b1;
    write1_addr = 6'd2;
    write1_data = 32'h2222_0002;
    read0_addr = 6'd1;
    read1_addr = 6'd2;
    #1;
    tb_check32("write0 bypass", read0_data, 32'h1111_0001);
    tb_check32("write1 bypass", read1_data, 32'h2222_0002);
    `TB_TICK(clk);
    clear_inputs();

    read0_addr = 6'd1;
    read1_addr = 6'd2;
    #1;
    tb_check32("stored p1", read0_data, 32'h1111_0001);
    tb_check32("stored p2", read1_data, 32'h2222_0002);

    write0_valid = 1'b1;
    write0_addr = 6'd3;
    write0_data = 32'haaaa_0003;
    write1_valid = 1'b1;
    write1_addr = 6'd3;
    write1_data = 32'hbbbb_0003;
    read0_addr = 6'd3;
    #1;
    tb_check32("write1 priority bypass", read0_data, 32'hbbbb_0003);
    `TB_TICK(clk);
    clear_inputs();
    read0_addr = 6'd3;
    #1;
    tb_check32("write1 priority stored", read0_data, 32'hbbbb_0003);

    write0_valid = 1'b1;
    write0_addr = 6'd0;
    write0_data = 32'hffff_ffff;
    `TB_TICK(clk);
    clear_inputs();
    read0_addr = 6'd0;
    #1;
    tb_check32("p0 ignores write", read0_data, 32'h0);

    tb_finish("tb_ooo_phys_reg_file");
  end
endmodule
