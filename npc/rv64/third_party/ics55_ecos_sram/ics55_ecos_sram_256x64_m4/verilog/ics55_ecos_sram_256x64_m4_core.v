module ics55_ecos_sram_256x64_m4 (
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
    WEB,
    CLK,
    CEB
  );


  input [7:0] A;
  input CEB;
  input CLK;
  input [63:0] D;
  input GWEB;
  input [3:0] MAR;
  input MARE;
  input [63:0] WEB;
  output [63:0] Q;
`ifdef POWER_PIN
  inout VSS;
  supply0 VSS;
  inout VDD;
  supply1 VDD;
`endif

reg [63:0] data_reg;
reg [63:0] MEMORY [255:0];

wire    mem_read;
wire    mem_write;

assign mem_write0 = ~CEB & ~GWEB & ~WEB[0];
assign mem_read0 = ~CEB & GWEB ;
assign mem_write1 = ~CEB & ~GWEB & ~WEB[1];
assign mem_read1 = ~CEB & GWEB ;
assign mem_write2 = ~CEB & ~GWEB & ~WEB[2];
assign mem_read2 = ~CEB & GWEB ;
assign mem_write3 = ~CEB & ~GWEB & ~WEB[3];
assign mem_read3 = ~CEB & GWEB ;
assign mem_write4 = ~CEB & ~GWEB & ~WEB[4];
assign mem_read4 = ~CEB & GWEB ;
assign mem_write5 = ~CEB & ~GWEB & ~WEB[5];
assign mem_read5 = ~CEB & GWEB ;
assign mem_write6 = ~CEB & ~GWEB & ~WEB[6];
assign mem_read6 = ~CEB & GWEB ;
assign mem_write7 = ~CEB & ~GWEB & ~WEB[7];
assign mem_read7 = ~CEB & GWEB ;
assign mem_write8 = ~CEB & ~GWEB & ~WEB[8];
assign mem_read8 = ~CEB & GWEB ;
assign mem_write9 = ~CEB & ~GWEB & ~WEB[9];
assign mem_read9 = ~CEB & GWEB ;
assign mem_write10 = ~CEB & ~GWEB & ~WEB[10];
assign mem_read10 = ~CEB & GWEB ;
assign mem_write11 = ~CEB & ~GWEB & ~WEB[11];
assign mem_read11 = ~CEB & GWEB ;
assign mem_write12 = ~CEB & ~GWEB & ~WEB[12];
assign mem_read12 = ~CEB & GWEB ;
assign mem_write13 = ~CEB & ~GWEB & ~WEB[13];
assign mem_read13 = ~CEB & GWEB ;
assign mem_write14 = ~CEB & ~GWEB & ~WEB[14];
assign mem_read14 = ~CEB & GWEB ;
assign mem_write15 = ~CEB & ~GWEB & ~WEB[15];
assign mem_read15 = ~CEB & GWEB ;
assign mem_write16 = ~CEB & ~GWEB & ~WEB[16];
assign mem_read16 = ~CEB & GWEB ;
assign mem_write17 = ~CEB & ~GWEB & ~WEB[17];
assign mem_read17 = ~CEB & GWEB ;
assign mem_write18 = ~CEB & ~GWEB & ~WEB[18];
assign mem_read18 = ~CEB & GWEB ;
assign mem_write19 = ~CEB & ~GWEB & ~WEB[19];
assign mem_read19 = ~CEB & GWEB ;
assign mem_write20 = ~CEB & ~GWEB & ~WEB[20];
assign mem_read20 = ~CEB & GWEB ;
assign mem_write21 = ~CEB & ~GWEB & ~WEB[21];
assign mem_read21 = ~CEB & GWEB ;
assign mem_write22 = ~CEB & ~GWEB & ~WEB[22];
assign mem_read22 = ~CEB & GWEB ;
assign mem_write23 = ~CEB & ~GWEB & ~WEB[23];
assign mem_read23 = ~CEB & GWEB ;
assign mem_write24 = ~CEB & ~GWEB & ~WEB[24];
assign mem_read24 = ~CEB & GWEB ;
assign mem_write25 = ~CEB & ~GWEB & ~WEB[25];
assign mem_read25 = ~CEB & GWEB ;
assign mem_write26 = ~CEB & ~GWEB & ~WEB[26];
assign mem_read26 = ~CEB & GWEB ;
assign mem_write27 = ~CEB & ~GWEB & ~WEB[27];
assign mem_read27 = ~CEB & GWEB ;
assign mem_write28 = ~CEB & ~GWEB & ~WEB[28];
assign mem_read28 = ~CEB & GWEB ;
assign mem_write29 = ~CEB & ~GWEB & ~WEB[29];
assign mem_read29 = ~CEB & GWEB ;
assign mem_write30 = ~CEB & ~GWEB & ~WEB[30];
assign mem_read30 = ~CEB & GWEB ;
assign mem_write31 = ~CEB & ~GWEB & ~WEB[31];
assign mem_read31 = ~CEB & GWEB ;
assign mem_write32 = ~CEB & ~GWEB & ~WEB[32];
assign mem_read32 = ~CEB & GWEB ;
assign mem_write33 = ~CEB & ~GWEB & ~WEB[33];
assign mem_read33 = ~CEB & GWEB ;
assign mem_write34 = ~CEB & ~GWEB & ~WEB[34];
assign mem_read34 = ~CEB & GWEB ;
assign mem_write35 = ~CEB & ~GWEB & ~WEB[35];
assign mem_read35 = ~CEB & GWEB ;
assign mem_write36 = ~CEB & ~GWEB & ~WEB[36];
assign mem_read36 = ~CEB & GWEB ;
assign mem_write37 = ~CEB & ~GWEB & ~WEB[37];
assign mem_read37 = ~CEB & GWEB ;
assign mem_write38 = ~CEB & ~GWEB & ~WEB[38];
assign mem_read38 = ~CEB & GWEB ;
assign mem_write39 = ~CEB & ~GWEB & ~WEB[39];
assign mem_read39 = ~CEB & GWEB ;
assign mem_write40 = ~CEB & ~GWEB & ~WEB[40];
assign mem_read40 = ~CEB & GWEB ;
assign mem_write41 = ~CEB & ~GWEB & ~WEB[41];
assign mem_read41 = ~CEB & GWEB ;
assign mem_write42 = ~CEB & ~GWEB & ~WEB[42];
assign mem_read42 = ~CEB & GWEB ;
assign mem_write43 = ~CEB & ~GWEB & ~WEB[43];
assign mem_read43 = ~CEB & GWEB ;
assign mem_write44 = ~CEB & ~GWEB & ~WEB[44];
assign mem_read44 = ~CEB & GWEB ;
assign mem_write45 = ~CEB & ~GWEB & ~WEB[45];
assign mem_read45 = ~CEB & GWEB ;
assign mem_write46 = ~CEB & ~GWEB & ~WEB[46];
assign mem_read46 = ~CEB & GWEB ;
assign mem_write47 = ~CEB & ~GWEB & ~WEB[47];
assign mem_read47 = ~CEB & GWEB ;
assign mem_write48 = ~CEB & ~GWEB & ~WEB[48];
assign mem_read48 = ~CEB & GWEB ;
assign mem_write49 = ~CEB & ~GWEB & ~WEB[49];
assign mem_read49 = ~CEB & GWEB ;
assign mem_write50 = ~CEB & ~GWEB & ~WEB[50];
assign mem_read50 = ~CEB & GWEB ;
assign mem_write51 = ~CEB & ~GWEB & ~WEB[51];
assign mem_read51 = ~CEB & GWEB ;
assign mem_write52 = ~CEB & ~GWEB & ~WEB[52];
assign mem_read52 = ~CEB & GWEB ;
assign mem_write53 = ~CEB & ~GWEB & ~WEB[53];
assign mem_read53 = ~CEB & GWEB ;
assign mem_write54 = ~CEB & ~GWEB & ~WEB[54];
assign mem_read54 = ~CEB & GWEB ;
assign mem_write55 = ~CEB & ~GWEB & ~WEB[55];
assign mem_read55 = ~CEB & GWEB ;
assign mem_write56 = ~CEB & ~GWEB & ~WEB[56];
assign mem_read56 = ~CEB & GWEB ;
assign mem_write57 = ~CEB & ~GWEB & ~WEB[57];
assign mem_read57 = ~CEB & GWEB ;
assign mem_write58 = ~CEB & ~GWEB & ~WEB[58];
assign mem_read58 = ~CEB & GWEB ;
assign mem_write59 = ~CEB & ~GWEB & ~WEB[59];
assign mem_read59 = ~CEB & GWEB ;
assign mem_write60 = ~CEB & ~GWEB & ~WEB[60];
assign mem_read60 = ~CEB & GWEB ;
assign mem_write61 = ~CEB & ~GWEB & ~WEB[61];
assign mem_read61 = ~CEB & GWEB ;
assign mem_write62 = ~CEB & ~GWEB & ~WEB[62];
assign mem_read62 = ~CEB & GWEB ;
assign mem_write63 = ~CEB & ~GWEB & ~WEB[63];
assign mem_read63 = ~CEB & GWEB ;

always @(posedge CLK) begin
  if (mem_write0) begin
    MEMORY[A][0] <= #1 D[0];
    data_reg[0]  <= #1 D[0];
  end
  else if (mem_read0) begin
    data_reg[0] <= #1 MEMORY[A][0];
  end
  if (mem_write1) begin
    MEMORY[A][1] <= #1 D[1];
    data_reg[1]  <= #1 D[1];
  end
  else if (mem_read1) begin
    data_reg[1] <= #1 MEMORY[A][1];
  end
  if (mem_write2) begin
    MEMORY[A][2] <= #1 D[2];
    data_reg[2]  <= #1 D[2];
  end
  else if (mem_read2) begin
    data_reg[2] <= #1 MEMORY[A][2];
  end
  if (mem_write3) begin
    MEMORY[A][3] <= #1 D[3];
    data_reg[3]  <= #1 D[3];
  end
  else if (mem_read3) begin
    data_reg[3] <= #1 MEMORY[A][3];
  end
  if (mem_write4) begin
    MEMORY[A][4] <= #1 D[4];
    data_reg[4]  <= #1 D[4];
  end
  else if (mem_read4) begin
    data_reg[4] <= #1 MEMORY[A][4];
  end
  if (mem_write5) begin
    MEMORY[A][5] <= #1 D[5];
    data_reg[5]  <= #1 D[5];
  end
  else if (mem_read5) begin
    data_reg[5] <= #1 MEMORY[A][5];
  end
  if (mem_write6) begin
    MEMORY[A][6] <= #1 D[6];
    data_reg[6]  <= #1 D[6];
  end
  else if (mem_read6) begin
    data_reg[6] <= #1 MEMORY[A][6];
  end
  if (mem_write7) begin
    MEMORY[A][7] <= #1 D[7];
    data_reg[7]  <= #1 D[7];
  end
  else if (mem_read7) begin
    data_reg[7] <= #1 MEMORY[A][7];
  end
  if (mem_write8) begin
    MEMORY[A][8] <= #1 D[8];
    data_reg[8]  <= #1 D[8];
  end
  else if (mem_read8) begin
    data_reg[8] <= #1 MEMORY[A][8];
  end
  if (mem_write9) begin
    MEMORY[A][9] <= #1 D[9];
    data_reg[9]  <= #1 D[9];
  end
  else if (mem_read9) begin
    data_reg[9] <= #1 MEMORY[A][9];
  end
  if (mem_write10) begin
    MEMORY[A][10] <= #1 D[10];
    data_reg[10]  <= #1 D[10];
  end
  else if (mem_read10) begin
    data_reg[10] <= #1 MEMORY[A][10];
  end
  if (mem_write11) begin
    MEMORY[A][11] <= #1 D[11];
    data_reg[11]  <= #1 D[11];
  end
  else if (mem_read11) begin
    data_reg[11] <= #1 MEMORY[A][11];
  end
  if (mem_write12) begin
    MEMORY[A][12] <= #1 D[12];
    data_reg[12]  <= #1 D[12];
  end
  else if (mem_read12) begin
    data_reg[12] <= #1 MEMORY[A][12];
  end
  if (mem_write13) begin
    MEMORY[A][13] <= #1 D[13];
    data_reg[13]  <= #1 D[13];
  end
  else if (mem_read13) begin
    data_reg[13] <= #1 MEMORY[A][13];
  end
  if (mem_write14) begin
    MEMORY[A][14] <= #1 D[14];
    data_reg[14]  <= #1 D[14];
  end
  else if (mem_read14) begin
    data_reg[14] <= #1 MEMORY[A][14];
  end
  if (mem_write15) begin
    MEMORY[A][15] <= #1 D[15];
    data_reg[15]  <= #1 D[15];
  end
  else if (mem_read15) begin
    data_reg[15] <= #1 MEMORY[A][15];
  end
  if (mem_write16) begin
    MEMORY[A][16] <= #1 D[16];
    data_reg[16]  <= #1 D[16];
  end
  else if (mem_read16) begin
    data_reg[16] <= #1 MEMORY[A][16];
  end
  if (mem_write17) begin
    MEMORY[A][17] <= #1 D[17];
    data_reg[17]  <= #1 D[17];
  end
  else if (mem_read17) begin
    data_reg[17] <= #1 MEMORY[A][17];
  end
  if (mem_write18) begin
    MEMORY[A][18] <= #1 D[18];
    data_reg[18]  <= #1 D[18];
  end
  else if (mem_read18) begin
    data_reg[18] <= #1 MEMORY[A][18];
  end
  if (mem_write19) begin
    MEMORY[A][19] <= #1 D[19];
    data_reg[19]  <= #1 D[19];
  end
  else if (mem_read19) begin
    data_reg[19] <= #1 MEMORY[A][19];
  end
  if (mem_write20) begin
    MEMORY[A][20] <= #1 D[20];
    data_reg[20]  <= #1 D[20];
  end
  else if (mem_read20) begin
    data_reg[20] <= #1 MEMORY[A][20];
  end
  if (mem_write21) begin
    MEMORY[A][21] <= #1 D[21];
    data_reg[21]  <= #1 D[21];
  end
  else if (mem_read21) begin
    data_reg[21] <= #1 MEMORY[A][21];
  end
  if (mem_write22) begin
    MEMORY[A][22] <= #1 D[22];
    data_reg[22]  <= #1 D[22];
  end
  else if (mem_read22) begin
    data_reg[22] <= #1 MEMORY[A][22];
  end
  if (mem_write23) begin
    MEMORY[A][23] <= #1 D[23];
    data_reg[23]  <= #1 D[23];
  end
  else if (mem_read23) begin
    data_reg[23] <= #1 MEMORY[A][23];
  end
  if (mem_write24) begin
    MEMORY[A][24] <= #1 D[24];
    data_reg[24]  <= #1 D[24];
  end
  else if (mem_read24) begin
    data_reg[24] <= #1 MEMORY[A][24];
  end
  if (mem_write25) begin
    MEMORY[A][25] <= #1 D[25];
    data_reg[25]  <= #1 D[25];
  end
  else if (mem_read25) begin
    data_reg[25] <= #1 MEMORY[A][25];
  end
  if (mem_write26) begin
    MEMORY[A][26] <= #1 D[26];
    data_reg[26]  <= #1 D[26];
  end
  else if (mem_read26) begin
    data_reg[26] <= #1 MEMORY[A][26];
  end
  if (mem_write27) begin
    MEMORY[A][27] <= #1 D[27];
    data_reg[27]  <= #1 D[27];
  end
  else if (mem_read27) begin
    data_reg[27] <= #1 MEMORY[A][27];
  end
  if (mem_write28) begin
    MEMORY[A][28] <= #1 D[28];
    data_reg[28]  <= #1 D[28];
  end
  else if (mem_read28) begin
    data_reg[28] <= #1 MEMORY[A][28];
  end
  if (mem_write29) begin
    MEMORY[A][29] <= #1 D[29];
    data_reg[29]  <= #1 D[29];
  end
  else if (mem_read29) begin
    data_reg[29] <= #1 MEMORY[A][29];
  end
  if (mem_write30) begin
    MEMORY[A][30] <= #1 D[30];
    data_reg[30]  <= #1 D[30];
  end
  else if (mem_read30) begin
    data_reg[30] <= #1 MEMORY[A][30];
  end
  if (mem_write31) begin
    MEMORY[A][31] <= #1 D[31];
    data_reg[31]  <= #1 D[31];
  end
  else if (mem_read31) begin
    data_reg[31] <= #1 MEMORY[A][31];
  end
  if (mem_write32) begin
    MEMORY[A][32] <= #1 D[32];
    data_reg[32]  <= #1 D[32];
  end
  else if (mem_read32) begin
    data_reg[32] <= #1 MEMORY[A][32];
  end
  if (mem_write33) begin
    MEMORY[A][33] <= #1 D[33];
    data_reg[33]  <= #1 D[33];
  end
  else if (mem_read33) begin
    data_reg[33] <= #1 MEMORY[A][33];
  end
  if (mem_write34) begin
    MEMORY[A][34] <= #1 D[34];
    data_reg[34]  <= #1 D[34];
  end
  else if (mem_read34) begin
    data_reg[34] <= #1 MEMORY[A][34];
  end
  if (mem_write35) begin
    MEMORY[A][35] <= #1 D[35];
    data_reg[35]  <= #1 D[35];
  end
  else if (mem_read35) begin
    data_reg[35] <= #1 MEMORY[A][35];
  end
  if (mem_write36) begin
    MEMORY[A][36] <= #1 D[36];
    data_reg[36]  <= #1 D[36];
  end
  else if (mem_read36) begin
    data_reg[36] <= #1 MEMORY[A][36];
  end
  if (mem_write37) begin
    MEMORY[A][37] <= #1 D[37];
    data_reg[37]  <= #1 D[37];
  end
  else if (mem_read37) begin
    data_reg[37] <= #1 MEMORY[A][37];
  end
  if (mem_write38) begin
    MEMORY[A][38] <= #1 D[38];
    data_reg[38]  <= #1 D[38];
  end
  else if (mem_read38) begin
    data_reg[38] <= #1 MEMORY[A][38];
  end
  if (mem_write39) begin
    MEMORY[A][39] <= #1 D[39];
    data_reg[39]  <= #1 D[39];
  end
  else if (mem_read39) begin
    data_reg[39] <= #1 MEMORY[A][39];
  end
  if (mem_write40) begin
    MEMORY[A][40] <= #1 D[40];
    data_reg[40]  <= #1 D[40];
  end
  else if (mem_read40) begin
    data_reg[40] <= #1 MEMORY[A][40];
  end
  if (mem_write41) begin
    MEMORY[A][41] <= #1 D[41];
    data_reg[41]  <= #1 D[41];
  end
  else if (mem_read41) begin
    data_reg[41] <= #1 MEMORY[A][41];
  end
  if (mem_write42) begin
    MEMORY[A][42] <= #1 D[42];
    data_reg[42]  <= #1 D[42];
  end
  else if (mem_read42) begin
    data_reg[42] <= #1 MEMORY[A][42];
  end
  if (mem_write43) begin
    MEMORY[A][43] <= #1 D[43];
    data_reg[43]  <= #1 D[43];
  end
  else if (mem_read43) begin
    data_reg[43] <= #1 MEMORY[A][43];
  end
  if (mem_write44) begin
    MEMORY[A][44] <= #1 D[44];
    data_reg[44]  <= #1 D[44];
  end
  else if (mem_read44) begin
    data_reg[44] <= #1 MEMORY[A][44];
  end
  if (mem_write45) begin
    MEMORY[A][45] <= #1 D[45];
    data_reg[45]  <= #1 D[45];
  end
  else if (mem_read45) begin
    data_reg[45] <= #1 MEMORY[A][45];
  end
  if (mem_write46) begin
    MEMORY[A][46] <= #1 D[46];
    data_reg[46]  <= #1 D[46];
  end
  else if (mem_read46) begin
    data_reg[46] <= #1 MEMORY[A][46];
  end
  if (mem_write47) begin
    MEMORY[A][47] <= #1 D[47];
    data_reg[47]  <= #1 D[47];
  end
  else if (mem_read47) begin
    data_reg[47] <= #1 MEMORY[A][47];
  end
  if (mem_write48) begin
    MEMORY[A][48] <= #1 D[48];
    data_reg[48]  <= #1 D[48];
  end
  else if (mem_read48) begin
    data_reg[48] <= #1 MEMORY[A][48];
  end
  if (mem_write49) begin
    MEMORY[A][49] <= #1 D[49];
    data_reg[49]  <= #1 D[49];
  end
  else if (mem_read49) begin
    data_reg[49] <= #1 MEMORY[A][49];
  end
  if (mem_write50) begin
    MEMORY[A][50] <= #1 D[50];
    data_reg[50]  <= #1 D[50];
  end
  else if (mem_read50) begin
    data_reg[50] <= #1 MEMORY[A][50];
  end
  if (mem_write51) begin
    MEMORY[A][51] <= #1 D[51];
    data_reg[51]  <= #1 D[51];
  end
  else if (mem_read51) begin
    data_reg[51] <= #1 MEMORY[A][51];
  end
  if (mem_write52) begin
    MEMORY[A][52] <= #1 D[52];
    data_reg[52]  <= #1 D[52];
  end
  else if (mem_read52) begin
    data_reg[52] <= #1 MEMORY[A][52];
  end
  if (mem_write53) begin
    MEMORY[A][53] <= #1 D[53];
    data_reg[53]  <= #1 D[53];
  end
  else if (mem_read53) begin
    data_reg[53] <= #1 MEMORY[A][53];
  end
  if (mem_write54) begin
    MEMORY[A][54] <= #1 D[54];
    data_reg[54]  <= #1 D[54];
  end
  else if (mem_read54) begin
    data_reg[54] <= #1 MEMORY[A][54];
  end
  if (mem_write55) begin
    MEMORY[A][55] <= #1 D[55];
    data_reg[55]  <= #1 D[55];
  end
  else if (mem_read55) begin
    data_reg[55] <= #1 MEMORY[A][55];
  end
  if (mem_write56) begin
    MEMORY[A][56] <= #1 D[56];
    data_reg[56]  <= #1 D[56];
  end
  else if (mem_read56) begin
    data_reg[56] <= #1 MEMORY[A][56];
  end
  if (mem_write57) begin
    MEMORY[A][57] <= #1 D[57];
    data_reg[57]  <= #1 D[57];
  end
  else if (mem_read57) begin
    data_reg[57] <= #1 MEMORY[A][57];
  end
  if (mem_write58) begin
    MEMORY[A][58] <= #1 D[58];
    data_reg[58]  <= #1 D[58];
  end
  else if (mem_read58) begin
    data_reg[58] <= #1 MEMORY[A][58];
  end
  if (mem_write59) begin
    MEMORY[A][59] <= #1 D[59];
    data_reg[59]  <= #1 D[59];
  end
  else if (mem_read59) begin
    data_reg[59] <= #1 MEMORY[A][59];
  end
  if (mem_write60) begin
    MEMORY[A][60] <= #1 D[60];
    data_reg[60]  <= #1 D[60];
  end
  else if (mem_read60) begin
    data_reg[60] <= #1 MEMORY[A][60];
  end
  if (mem_write61) begin
    MEMORY[A][61] <= #1 D[61];
    data_reg[61]  <= #1 D[61];
  end
  else if (mem_read61) begin
    data_reg[61] <= #1 MEMORY[A][61];
  end
  if (mem_write62) begin
    MEMORY[A][62] <= #1 D[62];
    data_reg[62]  <= #1 D[62];
  end
  else if (mem_read62) begin
    data_reg[62] <= #1 MEMORY[A][62];
  end
  if (mem_write63) begin
    MEMORY[A][63] <= #1 D[63];
    data_reg[63]  <= #1 D[63];
  end
  else if (mem_read63) begin
    data_reg[63] <= #1 MEMORY[A][63];
  end
end


assign Q = data_reg;


endmodule

