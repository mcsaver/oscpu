// CSR address predecode is captured with the serial instruction owner.
// Select bits are independent; a missing address produces an all-zero mask.
module R64CsrDecode (
  input  [11:0] address_i,
  output [63:0] select_o
);
  assign select_o[0] = address_i == 12'h001;
  assign select_o[1] = address_i == 12'h002;
  assign select_o[2] = address_i == 12'h003;
  assign select_o[3] = address_i == 12'h100;
  assign select_o[4] = address_i == 12'h104;
  assign select_o[5] = address_i == 12'h105;
  assign select_o[6] = address_i == 12'h106;
  assign select_o[7] = address_i == 12'h140;
  assign select_o[8] = address_i == 12'h141;
  assign select_o[9] = address_i == 12'h142;
  assign select_o[10] = address_i == 12'h143;
  assign select_o[11] = address_i == 12'h144;
  assign select_o[12] = address_i == 12'h180;
  assign select_o[13] = address_i == 12'h300;
  assign select_o[14] = address_i == 12'h301;
  assign select_o[15] = address_i == 12'h302;
  assign select_o[16] = address_i == 12'h303;
  assign select_o[17] = address_i == 12'h304;
  assign select_o[18] = address_i == 12'h305;
  assign select_o[19] = address_i == 12'h306;
  assign select_o[20] = address_i == 12'h30a;
  assign select_o[21] = address_i == 12'h320;
  assign select_o[22] = address_i == 12'h340;
  assign select_o[23] = address_i == 12'h341;
  assign select_o[24] = address_i == 12'h342;
  assign select_o[25] = address_i == 12'h343;
  assign select_o[26] = address_i == 12'h344;
  assign select_o[27] = address_i == 12'hb00;
  assign select_o[28] = address_i == 12'hb02;
  assign select_o[29] = address_i == 12'hc00;
  assign select_o[30] = address_i == 12'hc01;
  assign select_o[31] = address_i == 12'hc02;
  assign select_o[32] = address_i == 12'hf11;
  assign select_o[33] = address_i == 12'hf12;
  assign select_o[34] = address_i == 12'hf13;
  assign select_o[35] = address_i == 12'hf14;
  assign select_o[36] = address_i == 12'h3a0;
  assign select_o[37] = address_i == 12'h3a2;
  // select[38..53] maps in order to pmpaddr0..15 at CSR addresses 0x3b0..0x3bf.
  genvar pmp_entry;
  generate
    for (pmp_entry = 0; pmp_entry < 16; pmp_entry = pmp_entry + 1) begin : g_pmp_address
      assign select_o[38+pmp_entry] = address_i == {8'h3b, pmp_entry[3:0]};
    end
  endgenerate
  assign select_o[54] = address_i == 12'h7a0;
  assign select_o[55] = address_i == 12'h7a1;
  assign select_o[56] = address_i == 12'h7a2;
  assign select_o[57] = address_i == 12'h7a4;
  assign select_o[63:58] = 0;
endmodule
