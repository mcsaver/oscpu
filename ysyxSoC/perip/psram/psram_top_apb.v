module psram_top_apb (
  input         clock,
  input         reset,
  input  [31:0] in_paddr,
  input         in_psel,
  input         in_penable,
  input  [2:0]  in_pprot,
  input         in_pwrite,
  input  [31:0] in_pwdata,
  input  [3:0]  in_pstrb,
  output        in_pready,
  output [31:0] in_prdata,
  output        in_pslverr,

  output qspi_sck,
  output qspi_ce_n,
  inout  [3:0] qspi_dio
);

`ifndef SYNTHESIS
  localparam SIM_PSRAM_SIZE = 4 * 1024 * 1024;
  localparam SIM_PSRAM_ADDR_W = 22;

  reg [7:0] sim_mem [0:SIM_PSRAM_SIZE-1];
  integer sim_i;

  wire transfer_w = in_psel && in_penable;
  wire [SIM_PSRAM_ADDR_W-1:0] sim_addr_w = in_paddr[SIM_PSRAM_ADDR_W-1:0];
  wire [SIM_PSRAM_ADDR_W-1:0] sim_addr0_w = sim_addr_w;
  wire [SIM_PSRAM_ADDR_W-1:0] sim_addr1_w = sim_addr_w + {{(SIM_PSRAM_ADDR_W-1){1'b0}}, 1'b1};
  wire [SIM_PSRAM_ADDR_W-1:0] sim_addr2_w = sim_addr_w + {{(SIM_PSRAM_ADDR_W-2){1'b0}}, 2'd2};
  wire [SIM_PSRAM_ADDR_W-1:0] sim_addr3_w = sim_addr_w + {{(SIM_PSRAM_ADDR_W-2){1'b0}}, 2'd3};

  initial begin
    for (sim_i = 0; sim_i < SIM_PSRAM_SIZE; sim_i = sim_i + 1) begin
      sim_mem[sim_i] = 8'h00;
    end
  end

  assign in_pready = transfer_w;
  assign in_prdata = transfer_w && !in_pwrite ? {
    sim_mem[sim_addr3_w],
    sim_mem[sim_addr2_w],
    sim_mem[sim_addr1_w],
    sim_mem[sim_addr0_w]
  } : 32'h0000_0000;
  assign in_pslverr = 1'b0;

  assign qspi_sck = 1'b0;
  assign qspi_ce_n = 1'b1;
  assign qspi_dio = 4'bz;

  always @(posedge clock) begin
    if (!reset && transfer_w && in_pwrite) begin
      if (in_pstrb[0]) sim_mem[sim_addr0_w] <= in_pwdata[7:0];
      if (in_pstrb[1]) sim_mem[sim_addr1_w] <= in_pwdata[15:8];
      if (in_pstrb[2]) sim_mem[sim_addr2_w] <= in_pwdata[23:16];
      if (in_pstrb[3]) sim_mem[sim_addr3_w] <= in_pwdata[31:24];
    end
  end
`else
  wire [3:0] din, dout, douten;
  wire ack;
  EF_PSRAM_CTRL_wb u0 (
    .clk_i(clock),
    .rst_i(reset),
    .adr_i(in_paddr),
    .dat_i(in_pwdata),
    .dat_o(in_prdata),
    .sel_i(in_pstrb),
    .cyc_i(in_psel),
    .stb_i(in_psel),
    .ack_o(ack),
    .we_i(in_pwrite),
  
    .sck(qspi_sck),
    .ce_n(qspi_ce_n),
    .din(din),
    .dout(dout),
    .douten(douten)
  );
  
  assign in_pready = ack && in_psel;
  assign in_pslverr = 1'b0;
  assign qspi_dio[0] = douten[0] ? dout[0] : 1'bz;
  assign qspi_dio[1] = douten[1] ? dout[1] : 1'bz;
  assign qspi_dio[2] = douten[2] ? dout[2] : 1'bz;
  assign qspi_dio[3] = douten[3] ? dout[3] : 1'bz;
  assign din = qspi_dio;
`endif

endmodule
