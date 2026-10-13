module ics55_ecos_sram_256x128_m4_ww (
`ifdef POWER_PIN
    VSS,
    VDD,
`endif
    MAR,
    D,
    Q,
    MARE,
    GWEB,
    A,
    CLK,
    CEB
  );


  input [7:0] A;
  input CEB;
  input CLK;
  input [127:0] D;
  input GWEB;
  input [3:0] MAR;
  input MARE;
  output [127:0] Q;
`ifdef POWER_PIN
  inout VSS;
  supply0 VSS;
  inout VDD;
  supply1 VDD;
`endif

reg [127:0] data_reg;
reg [127:0] MEMORY [255:0];

wire    mem_read;
wire    mem_write;

assign mem_read = ~CEB & GWEB;
assign mem_write = ~CEB & ~GWEB;

always @(posedge CLK) begin
  if (mem_write) begin
    MEMORY[A] <= #1 D;
    data_reg  <= #1 D;
  end
  else if (mem_read) begin
    data_reg <= #1 MEMORY[A];
  end
end


assign Q = data_reg;


endmodule

