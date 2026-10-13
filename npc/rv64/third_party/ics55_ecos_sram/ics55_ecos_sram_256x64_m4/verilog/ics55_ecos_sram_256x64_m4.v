//macro define notes:
//1. INITIAL_MEMORY:
//   This definition is for initialize memory 
//2. INIT_CODE_FORMAT_BIN
//   This definition is for code format, default is HEX
//3. POWER_PIN
//   if define it, add power pin in top module
//4. NO_MESSAGE
//   if define it, all warning/error message will not appear
//5. MEMFAULTINJ
//   if define it, enable fault injection feature
//6. TX_TIMING_UNIT
//   if define it, use typical corner timing
//7. TX_INITIALIZE_FAULT
//    Initialize the memory fault data in verilog format
//8. ADDRESS_OUTOF_RANGE_STATUS
//   if define this option, address outof range will distory memory data

`timescale 10ps/1ps

`ifdef TX_TIMING_UNIT
`define ACEM 1
`else
`define ACEM 0.1
`endif




module ics55_ecos_sram_256x64_m4 (
`ifdef POWER_PIN
    VDD, VSS,
`endif
    A, D, CEB, CLK, 
    GWEB, 
    WEB, 
    MARE, MAR,
    Q
);

`define    TRUE                 1'b1
`define    FALSE                1'b0

parameter Q_NO_TOG = 1;
parameter MarginW = 4;
parameter Words   = 256;
parameter Bits    = 64;
parameter Mux     = 4;
parameter Bank    = 1;
parameter Addr    = 8;
parameter MuxAddr = 2.0;
parameter Trcqx = `ACEM*(88.1);
parameter Trcqx_8 = `ACEM*(88.1);
parameter Twcqx = `ACEM*(86.5);
parameter Twcqx_8 = `ACEM*(86.5);
parameter leftio = 32;
parameter rightio = 32;

`ifdef POWER_PIN
inout VDD;
inout VSS;
`endif

input [Addr-1:0] A;
input [Bits-1:0] D;
input CLK;
input CEB;
input GWEB;
input [Bits-1:0] WEB;
input MARE;
input [MarginW-1:0] MAR;
output [Bits-1:0] Q;

`protect 

`ifdef TX_INITIALIZE_FAULT
reg [Bits-1:0] mem_fault  [Words-1:0];
reg [Bits-1:0] Pre_Loading2 [Words-1:0];
`endif
reg [Bits-1:0] mem [Words-1:0];
reg [Bits-1:0] Pre_Loading [Words-1:0];

event EVQ;
event EVQWT;

reg [Bits-1:0] BitWriteOutput;
reg [Addr-1:0] Last_A;
reg [Addr-1:0] latch_Last_A;

wire [Addr-1:0]    A_buf;
wire [Bits-1:0]    D_buf;
wire               GWEB_buf;
wire [Bits-1:0]    WEB_buf;
wire               CEB_buf;
wire               MARE_buf;
wire [MarginW-1:0] MAR_buf;
wire [Bits-1:0]    Q_buf;

reg [Bits-1:0]     D_reg;
reg                GWEB_reg;
reg [Bits-1:0]     WEB_reg;
reg                TMCKH_reg;

reg [Bits-1:0]     D_int;
reg [Addr-1:0]     A_int;
reg                CEB_int;
reg                GWEB_int;
reg [Bits-1:0]     WEB_int;

reg [Bits-1:0]     Latch_D;
reg [Addr-1:0]     Latch_A;
reg                Latch_CEB;
reg                Latch_GWEB;
reg [Bits-1:0]     Latch_WEB;
reg              Latch_MARE;
reg  [MarginW-1:0] Latch_MAR;

reg [Bits-1:0]     Q_int;
reg [Bits-1:0]     Q_tmp;
reg                  PRDYB_int;
reg                  PRDYB_tmp;
reg                  PRDYB_reg;

integer i;
reg [Bits-1:0] mem_fault_array_XOR [Words-1:0];
reg [Bits-1:0] mem_fault_array_sa0 [Words-1:0];
reg [Bits-1:0] mem_fault_array_sa1 [Words-1:0];
reg faultinj_en;
reg [Bits-1:0] mem_XOR_data;
initial
begin
    faultinj_en = 1'b0;
    `ifdef MEMFAULTINJ
    faultinj_en = 1'b1;
    `endif
    for(i=0; i<Words; i=i+1)
    begin
        if(faultinj_en == 1'b1)
            mem_fault_array_XOR[i] = {Bits{1'b0}};
        else
        begin
            mem_fault_array_sa0[i] = {Bits{1'b1}};
            mem_fault_array_sa1[i] = {Bits{1'b0}};
        end
    end
    if (faultinj_en == 1'b1)
    begin
        if($test$plusargs("asap_error"))
            mem_fault_array_XOR[1] = 1'b1 << (Bits - 1);
    end
end
                   
//define for timing  flag
wire sdfcond_A;
wire sdfcond_D;
wire sdfcond_GWEB;
wire sdfcond_WEB;
wire sdfcond_CEBR;
wire sdfcond_CEBW;
wire sdfcond_RCLK;
wire sdfcond_WCLK;
wire sdfcond_CLK;
wire sdfcond_RCLK8;
wire sdfcond_WCLK8;
wire sdfcond_MAR;
wire sdfcond_MARE;

assign sdfcond_A    = ~CEB_buf ;
assign sdfcond_D63    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[63] ;
assign sdfcond_D62    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[62] ;
assign sdfcond_D61    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[61] ;
assign sdfcond_D60    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[60] ;
assign sdfcond_D59    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[59] ;
assign sdfcond_D58    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[58] ;
assign sdfcond_D57    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[57] ;
assign sdfcond_D56    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[56] ;
assign sdfcond_D55    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[55] ;
assign sdfcond_D54    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[54] ;
assign sdfcond_D53    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[53] ;
assign sdfcond_D52    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[52] ;
assign sdfcond_D51    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[51] ;
assign sdfcond_D50    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[50] ;
assign sdfcond_D49    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[49] ;
assign sdfcond_D48    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[48] ;
assign sdfcond_D47    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[47] ;
assign sdfcond_D46    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[46] ;
assign sdfcond_D45    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[45] ;
assign sdfcond_D44    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[44] ;
assign sdfcond_D43    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[43] ;
assign sdfcond_D42    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[42] ;
assign sdfcond_D41    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[41] ;
assign sdfcond_D40    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[40] ;
assign sdfcond_D39    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[39] ;
assign sdfcond_D38    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[38] ;
assign sdfcond_D37    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[37] ;
assign sdfcond_D36    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[36] ;
assign sdfcond_D35    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[35] ;
assign sdfcond_D34    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[34] ;
assign sdfcond_D33    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[33] ;
assign sdfcond_D32    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[32] ;
assign sdfcond_D31    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[31] ;
assign sdfcond_D30    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[30] ;
assign sdfcond_D29    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[29] ;
assign sdfcond_D28    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[28] ;
assign sdfcond_D27    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[27] ;
assign sdfcond_D26    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[26] ;
assign sdfcond_D25    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[25] ;
assign sdfcond_D24    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[24] ;
assign sdfcond_D23    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[23] ;
assign sdfcond_D22    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[22] ;
assign sdfcond_D21    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[21] ;
assign sdfcond_D20    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[20] ;
assign sdfcond_D19    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[19] ;
assign sdfcond_D18    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[18] ;
assign sdfcond_D17    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[17] ;
assign sdfcond_D16    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[16] ;
assign sdfcond_D15    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[15] ;
assign sdfcond_D14    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[14] ;
assign sdfcond_D13    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[13] ;
assign sdfcond_D12    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[12] ;
assign sdfcond_D11    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[11] ;
assign sdfcond_D10    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[10] ;
assign sdfcond_D9    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[9] ;
assign sdfcond_D8    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[8] ;
assign sdfcond_D7    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[7] ;
assign sdfcond_D6    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[6] ;
assign sdfcond_D5    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[5] ;
assign sdfcond_D4    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[4] ;
assign sdfcond_D3    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[3] ;
assign sdfcond_D2    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[2] ;
assign sdfcond_D1    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[1] ;
assign sdfcond_D0    = ~CEB_buf & ~GWEB_buf & ~WEB_buf[0] ;
assign sdfcond_GWEB  = ~CEB_buf ;
assign sdfcond_WEB  = ~CEB_buf & ~GWEB_buf ;
assign sdfcond_CEBR = GWEB_buf;
assign sdfcond_CEBW = ~GWEB_buf;
assign sdfcond_MAR  = ~CEB_buf ;
assign sdfcond_MARE  = ~CEB_buf ;

assign sdfcond_RCLK = ~CEB_buf & GWEB_buf  & ~MARE;
assign sdfcond_WCLK = ~CEB_buf & ~GWEB_buf  & ~MARE;
assign sdfcond_RCLK8 = ~CEB_buf & GWEB_buf  & MARE & MAR[3] & !MAR[2] & !MAR[1] & !MAR[0] ;
assign sdfcond_WCLK8 = ~CEB_buf & ~GWEB_buf  & MARE & MAR[3] & !MAR[2] & !MAR[1] & !MAR[0] ;
assign sdfcond_CLK  = ~CEB_buf ;

reg n_flag_A7;
reg n_flag_A6;
reg n_flag_A5;
reg n_flag_A4;
reg n_flag_A3;
reg n_flag_A2;
reg n_flag_A1;
reg n_flag_A0;
reg [Addr-1:0] n_flag_A_bus;
reg n_flag_D63;
reg n_flag_D62;
reg n_flag_D61;
reg n_flag_D60;
reg n_flag_D59;
reg n_flag_D58;
reg n_flag_D57;
reg n_flag_D56;
reg n_flag_D55;
reg n_flag_D54;
reg n_flag_D53;
reg n_flag_D52;
reg n_flag_D51;
reg n_flag_D50;
reg n_flag_D49;
reg n_flag_D48;
reg n_flag_D47;
reg n_flag_D46;
reg n_flag_D45;
reg n_flag_D44;
reg n_flag_D43;
reg n_flag_D42;
reg n_flag_D41;
reg n_flag_D40;
reg n_flag_D39;
reg n_flag_D38;
reg n_flag_D37;
reg n_flag_D36;
reg n_flag_D35;
reg n_flag_D34;
reg n_flag_D33;
reg n_flag_D32;
reg n_flag_D31;
reg n_flag_D30;
reg n_flag_D29;
reg n_flag_D28;
reg n_flag_D27;
reg n_flag_D26;
reg n_flag_D25;
reg n_flag_D24;
reg n_flag_D23;
reg n_flag_D22;
reg n_flag_D21;
reg n_flag_D20;
reg n_flag_D19;
reg n_flag_D18;
reg n_flag_D17;
reg n_flag_D16;
reg n_flag_D15;
reg n_flag_D14;
reg n_flag_D13;
reg n_flag_D12;
reg n_flag_D11;
reg n_flag_D10;
reg n_flag_D9;
reg n_flag_D8;
reg n_flag_D7;
reg n_flag_D6;
reg n_flag_D5;
reg n_flag_D4;
reg n_flag_D3;
reg n_flag_D2;
reg n_flag_D1;
reg n_flag_D0;
reg [Bits-1:0] n_flag_D_bus;
reg n_flag_GWEB;
reg n_flag_WEB63;
reg n_flag_WEB62;
reg n_flag_WEB61;
reg n_flag_WEB60;
reg n_flag_WEB59;
reg n_flag_WEB58;
reg n_flag_WEB57;
reg n_flag_WEB56;
reg n_flag_WEB55;
reg n_flag_WEB54;
reg n_flag_WEB53;
reg n_flag_WEB52;
reg n_flag_WEB51;
reg n_flag_WEB50;
reg n_flag_WEB49;
reg n_flag_WEB48;
reg n_flag_WEB47;
reg n_flag_WEB46;
reg n_flag_WEB45;
reg n_flag_WEB44;
reg n_flag_WEB43;
reg n_flag_WEB42;
reg n_flag_WEB41;
reg n_flag_WEB40;
reg n_flag_WEB39;
reg n_flag_WEB38;
reg n_flag_WEB37;
reg n_flag_WEB36;
reg n_flag_WEB35;
reg n_flag_WEB34;
reg n_flag_WEB33;
reg n_flag_WEB32;
reg n_flag_WEB31;
reg n_flag_WEB30;
reg n_flag_WEB29;
reg n_flag_WEB28;
reg n_flag_WEB27;
reg n_flag_WEB26;
reg n_flag_WEB25;
reg n_flag_WEB24;
reg n_flag_WEB23;
reg n_flag_WEB22;
reg n_flag_WEB21;
reg n_flag_WEB20;
reg n_flag_WEB19;
reg n_flag_WEB18;
reg n_flag_WEB17;
reg n_flag_WEB16;
reg n_flag_WEB15;
reg n_flag_WEB14;
reg n_flag_WEB13;
reg n_flag_WEB12;
reg n_flag_WEB11;
reg n_flag_WEB10;
reg n_flag_WEB9;
reg n_flag_WEB8;
reg n_flag_WEB7;
reg n_flag_WEB6;
reg n_flag_WEB5;
reg n_flag_WEB4;
reg n_flag_WEB3;
reg n_flag_WEB2;
reg n_flag_WEB1;
reg n_flag_WEB0;
reg [Bits-1:0] n_flag_WEB_bus;
reg n_flag_CEB;
reg n_flag_MAR;
reg n_flag_MARE;
reg n_flag_CLK_period ;
reg n_flag_CLK_high_pluse ;
reg n_flag_CLK_low_pluse ;

reg Last_n_flag_A7 ;
reg Last_n_flag_A6 ;
reg Last_n_flag_A5 ;
reg Last_n_flag_A4 ;
reg Last_n_flag_A3 ;
reg Last_n_flag_A2 ;
reg Last_n_flag_A1 ;
reg Last_n_flag_A0 ;
reg [Addr-1:0] Last_n_flag_A_bus;
reg Last_n_flag_D63 ;
reg Last_n_flag_D62 ;
reg Last_n_flag_D61 ;
reg Last_n_flag_D60 ;
reg Last_n_flag_D59 ;
reg Last_n_flag_D58 ;
reg Last_n_flag_D57 ;
reg Last_n_flag_D56 ;
reg Last_n_flag_D55 ;
reg Last_n_flag_D54 ;
reg Last_n_flag_D53 ;
reg Last_n_flag_D52 ;
reg Last_n_flag_D51 ;
reg Last_n_flag_D50 ;
reg Last_n_flag_D49 ;
reg Last_n_flag_D48 ;
reg Last_n_flag_D47 ;
reg Last_n_flag_D46 ;
reg Last_n_flag_D45 ;
reg Last_n_flag_D44 ;
reg Last_n_flag_D43 ;
reg Last_n_flag_D42 ;
reg Last_n_flag_D41 ;
reg Last_n_flag_D40 ;
reg Last_n_flag_D39 ;
reg Last_n_flag_D38 ;
reg Last_n_flag_D37 ;
reg Last_n_flag_D36 ;
reg Last_n_flag_D35 ;
reg Last_n_flag_D34 ;
reg Last_n_flag_D33 ;
reg Last_n_flag_D32 ;
reg Last_n_flag_D31 ;
reg Last_n_flag_D30 ;
reg Last_n_flag_D29 ;
reg Last_n_flag_D28 ;
reg Last_n_flag_D27 ;
reg Last_n_flag_D26 ;
reg Last_n_flag_D25 ;
reg Last_n_flag_D24 ;
reg Last_n_flag_D23 ;
reg Last_n_flag_D22 ;
reg Last_n_flag_D21 ;
reg Last_n_flag_D20 ;
reg Last_n_flag_D19 ;
reg Last_n_flag_D18 ;
reg Last_n_flag_D17 ;
reg Last_n_flag_D16 ;
reg Last_n_flag_D15 ;
reg Last_n_flag_D14 ;
reg Last_n_flag_D13 ;
reg Last_n_flag_D12 ;
reg Last_n_flag_D11 ;
reg Last_n_flag_D10 ;
reg Last_n_flag_D9 ;
reg Last_n_flag_D8 ;
reg Last_n_flag_D7 ;
reg Last_n_flag_D6 ;
reg Last_n_flag_D5 ;
reg Last_n_flag_D4 ;
reg Last_n_flag_D3 ;
reg Last_n_flag_D2 ;
reg Last_n_flag_D1 ;
reg Last_n_flag_D0 ;
reg [Bits-1:0] Last_n_flag_D_bus;
reg Last_n_flag_GWEB;
reg Last_n_flag_WEB63 ;
reg Last_n_flag_WEB62 ;
reg Last_n_flag_WEB61 ;
reg Last_n_flag_WEB60 ;
reg Last_n_flag_WEB59 ;
reg Last_n_flag_WEB58 ;
reg Last_n_flag_WEB57 ;
reg Last_n_flag_WEB56 ;
reg Last_n_flag_WEB55 ;
reg Last_n_flag_WEB54 ;
reg Last_n_flag_WEB53 ;
reg Last_n_flag_WEB52 ;
reg Last_n_flag_WEB51 ;
reg Last_n_flag_WEB50 ;
reg Last_n_flag_WEB49 ;
reg Last_n_flag_WEB48 ;
reg Last_n_flag_WEB47 ;
reg Last_n_flag_WEB46 ;
reg Last_n_flag_WEB45 ;
reg Last_n_flag_WEB44 ;
reg Last_n_flag_WEB43 ;
reg Last_n_flag_WEB42 ;
reg Last_n_flag_WEB41 ;
reg Last_n_flag_WEB40 ;
reg Last_n_flag_WEB39 ;
reg Last_n_flag_WEB38 ;
reg Last_n_flag_WEB37 ;
reg Last_n_flag_WEB36 ;
reg Last_n_flag_WEB35 ;
reg Last_n_flag_WEB34 ;
reg Last_n_flag_WEB33 ;
reg Last_n_flag_WEB32 ;
reg Last_n_flag_WEB31 ;
reg Last_n_flag_WEB30 ;
reg Last_n_flag_WEB29 ;
reg Last_n_flag_WEB28 ;
reg Last_n_flag_WEB27 ;
reg Last_n_flag_WEB26 ;
reg Last_n_flag_WEB25 ;
reg Last_n_flag_WEB24 ;
reg Last_n_flag_WEB23 ;
reg Last_n_flag_WEB22 ;
reg Last_n_flag_WEB21 ;
reg Last_n_flag_WEB20 ;
reg Last_n_flag_WEB19 ;
reg Last_n_flag_WEB18 ;
reg Last_n_flag_WEB17 ;
reg Last_n_flag_WEB16 ;
reg Last_n_flag_WEB15 ;
reg Last_n_flag_WEB14 ;
reg Last_n_flag_WEB13 ;
reg Last_n_flag_WEB12 ;
reg Last_n_flag_WEB11 ;
reg Last_n_flag_WEB10 ;
reg Last_n_flag_WEB9 ;
reg Last_n_flag_WEB8 ;
reg Last_n_flag_WEB7 ;
reg Last_n_flag_WEB6 ;
reg Last_n_flag_WEB5 ;
reg Last_n_flag_WEB4 ;
reg Last_n_flag_WEB3 ;
reg Last_n_flag_WEB2 ;
reg Last_n_flag_WEB1 ;
reg Last_n_flag_WEB0 ;
reg [Bits-1:0] Last_n_flag_WEB_bus;
reg Last_n_flag_CEB ;
reg Last_n_flag_CLK_period ;
reg Last_n_flag_CLK_high_pluse ;
reg Last_n_flag_CLK_low_pluse ;
reg [Bits-1:0] MEM_reg;
reg [Bits-1:0] D_reg_new;
reg [Bits-1:0] WEB_reg_new;
//enddefine for timing flag

buf Abuf7  (A_buf[7], A[7]);
buf Abuf6  (A_buf[6], A[6]);
buf Abuf5  (A_buf[5], A[5]);
buf Abuf4  (A_buf[4], A[4]);
buf Abuf3  (A_buf[3], A[3]);
buf Abuf2  (A_buf[2], A[2]);
buf Abuf1  (A_buf[1], A[1]);
buf Abuf0  (A_buf[0], A[0]);

buf Dbuf63  (D_buf[63], D[63]);
buf Dbuf62  (D_buf[62], D[62]);
buf Dbuf61  (D_buf[61], D[61]);
buf Dbuf60  (D_buf[60], D[60]);
buf Dbuf59  (D_buf[59], D[59]);
buf Dbuf58  (D_buf[58], D[58]);
buf Dbuf57  (D_buf[57], D[57]);
buf Dbuf56  (D_buf[56], D[56]);
buf Dbuf55  (D_buf[55], D[55]);
buf Dbuf54  (D_buf[54], D[54]);
buf Dbuf53  (D_buf[53], D[53]);
buf Dbuf52  (D_buf[52], D[52]);
buf Dbuf51  (D_buf[51], D[51]);
buf Dbuf50  (D_buf[50], D[50]);
buf Dbuf49  (D_buf[49], D[49]);
buf Dbuf48  (D_buf[48], D[48]);
buf Dbuf47  (D_buf[47], D[47]);
buf Dbuf46  (D_buf[46], D[46]);
buf Dbuf45  (D_buf[45], D[45]);
buf Dbuf44  (D_buf[44], D[44]);
buf Dbuf43  (D_buf[43], D[43]);
buf Dbuf42  (D_buf[42], D[42]);
buf Dbuf41  (D_buf[41], D[41]);
buf Dbuf40  (D_buf[40], D[40]);
buf Dbuf39  (D_buf[39], D[39]);
buf Dbuf38  (D_buf[38], D[38]);
buf Dbuf37  (D_buf[37], D[37]);
buf Dbuf36  (D_buf[36], D[36]);
buf Dbuf35  (D_buf[35], D[35]);
buf Dbuf34  (D_buf[34], D[34]);
buf Dbuf33  (D_buf[33], D[33]);
buf Dbuf32  (D_buf[32], D[32]);
buf Dbuf31  (D_buf[31], D[31]);
buf Dbuf30  (D_buf[30], D[30]);
buf Dbuf29  (D_buf[29], D[29]);
buf Dbuf28  (D_buf[28], D[28]);
buf Dbuf27  (D_buf[27], D[27]);
buf Dbuf26  (D_buf[26], D[26]);
buf Dbuf25  (D_buf[25], D[25]);
buf Dbuf24  (D_buf[24], D[24]);
buf Dbuf23  (D_buf[23], D[23]);
buf Dbuf22  (D_buf[22], D[22]);
buf Dbuf21  (D_buf[21], D[21]);
buf Dbuf20  (D_buf[20], D[20]);
buf Dbuf19  (D_buf[19], D[19]);
buf Dbuf18  (D_buf[18], D[18]);
buf Dbuf17  (D_buf[17], D[17]);
buf Dbuf16  (D_buf[16], D[16]);
buf Dbuf15  (D_buf[15], D[15]);
buf Dbuf14  (D_buf[14], D[14]);
buf Dbuf13  (D_buf[13], D[13]);
buf Dbuf12  (D_buf[12], D[12]);
buf Dbuf11  (D_buf[11], D[11]);
buf Dbuf10  (D_buf[10], D[10]);
buf Dbuf9  (D_buf[9], D[9]);
buf Dbuf8  (D_buf[8], D[8]);
buf Dbuf7  (D_buf[7], D[7]);
buf Dbuf6  (D_buf[6], D[6]);
buf Dbuf5  (D_buf[5], D[5]);
buf Dbuf4  (D_buf[4], D[4]);
buf Dbuf3  (D_buf[3], D[3]);
buf Dbuf2  (D_buf[2], D[2]);
buf Dbuf1  (D_buf[1], D[1]);
buf Dbuf0  (D_buf[0], D[0]);

buf GWEBbuf  (GWEB_buf, GWEB);
buf WEBbuf63  (WEB_buf[63], WEB[63]);
buf WEBbuf62  (WEB_buf[62], WEB[62]);
buf WEBbuf61  (WEB_buf[61], WEB[61]);
buf WEBbuf60  (WEB_buf[60], WEB[60]);
buf WEBbuf59  (WEB_buf[59], WEB[59]);
buf WEBbuf58  (WEB_buf[58], WEB[58]);
buf WEBbuf57  (WEB_buf[57], WEB[57]);
buf WEBbuf56  (WEB_buf[56], WEB[56]);
buf WEBbuf55  (WEB_buf[55], WEB[55]);
buf WEBbuf54  (WEB_buf[54], WEB[54]);
buf WEBbuf53  (WEB_buf[53], WEB[53]);
buf WEBbuf52  (WEB_buf[52], WEB[52]);
buf WEBbuf51  (WEB_buf[51], WEB[51]);
buf WEBbuf50  (WEB_buf[50], WEB[50]);
buf WEBbuf49  (WEB_buf[49], WEB[49]);
buf WEBbuf48  (WEB_buf[48], WEB[48]);
buf WEBbuf47  (WEB_buf[47], WEB[47]);
buf WEBbuf46  (WEB_buf[46], WEB[46]);
buf WEBbuf45  (WEB_buf[45], WEB[45]);
buf WEBbuf44  (WEB_buf[44], WEB[44]);
buf WEBbuf43  (WEB_buf[43], WEB[43]);
buf WEBbuf42  (WEB_buf[42], WEB[42]);
buf WEBbuf41  (WEB_buf[41], WEB[41]);
buf WEBbuf40  (WEB_buf[40], WEB[40]);
buf WEBbuf39  (WEB_buf[39], WEB[39]);
buf WEBbuf38  (WEB_buf[38], WEB[38]);
buf WEBbuf37  (WEB_buf[37], WEB[37]);
buf WEBbuf36  (WEB_buf[36], WEB[36]);
buf WEBbuf35  (WEB_buf[35], WEB[35]);
buf WEBbuf34  (WEB_buf[34], WEB[34]);
buf WEBbuf33  (WEB_buf[33], WEB[33]);
buf WEBbuf32  (WEB_buf[32], WEB[32]);
buf WEBbuf31  (WEB_buf[31], WEB[31]);
buf WEBbuf30  (WEB_buf[30], WEB[30]);
buf WEBbuf29  (WEB_buf[29], WEB[29]);
buf WEBbuf28  (WEB_buf[28], WEB[28]);
buf WEBbuf27  (WEB_buf[27], WEB[27]);
buf WEBbuf26  (WEB_buf[26], WEB[26]);
buf WEBbuf25  (WEB_buf[25], WEB[25]);
buf WEBbuf24  (WEB_buf[24], WEB[24]);
buf WEBbuf23  (WEB_buf[23], WEB[23]);
buf WEBbuf22  (WEB_buf[22], WEB[22]);
buf WEBbuf21  (WEB_buf[21], WEB[21]);
buf WEBbuf20  (WEB_buf[20], WEB[20]);
buf WEBbuf19  (WEB_buf[19], WEB[19]);
buf WEBbuf18  (WEB_buf[18], WEB[18]);
buf WEBbuf17  (WEB_buf[17], WEB[17]);
buf WEBbuf16  (WEB_buf[16], WEB[16]);
buf WEBbuf15  (WEB_buf[15], WEB[15]);
buf WEBbuf14  (WEB_buf[14], WEB[14]);
buf WEBbuf13  (WEB_buf[13], WEB[13]);
buf WEBbuf12  (WEB_buf[12], WEB[12]);
buf WEBbuf11  (WEB_buf[11], WEB[11]);
buf WEBbuf10  (WEB_buf[10], WEB[10]);
buf WEBbuf9  (WEB_buf[9], WEB[9]);
buf WEBbuf8  (WEB_buf[8], WEB[8]);
buf WEBbuf7  (WEB_buf[7], WEB[7]);
buf WEBbuf6  (WEB_buf[6], WEB[6]);
buf WEBbuf5  (WEB_buf[5], WEB[5]);
buf WEBbuf4  (WEB_buf[4], WEB[4]);
buf WEBbuf3  (WEB_buf[3], WEB[3]);
buf WEBbuf2  (WEB_buf[2], WEB[2]);
buf WEBbuf1  (WEB_buf[1], WEB[1]);
buf WEBbuf0  (WEB_buf[0], WEB[0]);

buf CEBbuf (CEB_buf, CEB);


buf MAREbuf  (MARE_buf, MARE);
buf MARbuf0  (MAR_buf[0], MAR[0]);
buf MARbuf1  (MAR_buf[1], MAR[1]);
buf MARbuf2  (MAR_buf[2], MAR[2]);
buf MARbuf3  (MAR_buf[3], MAR[3]);



buf Qbuf63  (Q[63], Q_buf[63]);
buf Qbuf62  (Q[62], Q_buf[62]);
buf Qbuf61  (Q[61], Q_buf[61]);
buf Qbuf60  (Q[60], Q_buf[60]);
buf Qbuf59  (Q[59], Q_buf[59]);
buf Qbuf58  (Q[58], Q_buf[58]);
buf Qbuf57  (Q[57], Q_buf[57]);
buf Qbuf56  (Q[56], Q_buf[56]);
buf Qbuf55  (Q[55], Q_buf[55]);
buf Qbuf54  (Q[54], Q_buf[54]);
buf Qbuf53  (Q[53], Q_buf[53]);
buf Qbuf52  (Q[52], Q_buf[52]);
buf Qbuf51  (Q[51], Q_buf[51]);
buf Qbuf50  (Q[50], Q_buf[50]);
buf Qbuf49  (Q[49], Q_buf[49]);
buf Qbuf48  (Q[48], Q_buf[48]);
buf Qbuf47  (Q[47], Q_buf[47]);
buf Qbuf46  (Q[46], Q_buf[46]);
buf Qbuf45  (Q[45], Q_buf[45]);
buf Qbuf44  (Q[44], Q_buf[44]);
buf Qbuf43  (Q[43], Q_buf[43]);
buf Qbuf42  (Q[42], Q_buf[42]);
buf Qbuf41  (Q[41], Q_buf[41]);
buf Qbuf40  (Q[40], Q_buf[40]);
buf Qbuf39  (Q[39], Q_buf[39]);
buf Qbuf38  (Q[38], Q_buf[38]);
buf Qbuf37  (Q[37], Q_buf[37]);
buf Qbuf36  (Q[36], Q_buf[36]);
buf Qbuf35  (Q[35], Q_buf[35]);
buf Qbuf34  (Q[34], Q_buf[34]);
buf Qbuf33  (Q[33], Q_buf[33]);
buf Qbuf32  (Q[32], Q_buf[32]);
buf Qbuf31  (Q[31], Q_buf[31]);
buf Qbuf30  (Q[30], Q_buf[30]);
buf Qbuf29  (Q[29], Q_buf[29]);
buf Qbuf28  (Q[28], Q_buf[28]);
buf Qbuf27  (Q[27], Q_buf[27]);
buf Qbuf26  (Q[26], Q_buf[26]);
buf Qbuf25  (Q[25], Q_buf[25]);
buf Qbuf24  (Q[24], Q_buf[24]);
buf Qbuf23  (Q[23], Q_buf[23]);
buf Qbuf22  (Q[22], Q_buf[22]);
buf Qbuf21  (Q[21], Q_buf[21]);
buf Qbuf20  (Q[20], Q_buf[20]);
buf Qbuf19  (Q[19], Q_buf[19]);
buf Qbuf18  (Q[18], Q_buf[18]);
buf Qbuf17  (Q[17], Q_buf[17]);
buf Qbuf16  (Q[16], Q_buf[16]);
buf Qbuf15  (Q[15], Q_buf[15]);
buf Qbuf14  (Q[14], Q_buf[14]);
buf Qbuf13  (Q[13], Q_buf[13]);
buf Qbuf12  (Q[12], Q_buf[12]);
buf Qbuf11  (Q[11], Q_buf[11]);
buf Qbuf10  (Q[10], Q_buf[10]);
buf Qbuf9  (Q[9], Q_buf[9]);
buf Qbuf8  (Q[8], Q_buf[8]);
buf Qbuf7  (Q[7], Q_buf[7]);
buf Qbuf6  (Q[6], Q_buf[6]);
buf Qbuf5  (Q[5], Q_buf[5]);
buf Qbuf4  (Q[4], Q_buf[4]);
buf Qbuf3  (Q[3], Q_buf[3]);
buf Qbuf2  (Q[2], Q_buf[2]);
buf Qbuf1  (Q[1], Q_buf[1]);
buf Qbuf0  (Q[0], Q_buf[0]);

assign Q_buf = Q_int;


reg CEBxCLK_buf;
wire CEBxCLK;
reg CEBxCLK_latency_buf;
wire CEBxCLK_SDF;
initial
begin
    CEBxCLK_buf = 1'b0;
    CEBxCLK_latency_buf = 1'b0;
end
always@(posedge CLK)
begin 
    CEBxCLK_latency_buf = CEBxCLK_buf;
    CEBxCLK_buf = CEB_buf;
end
buf CEBCLK1 (CEBxCLK, CEBxCLK_buf);
xor CEBCLK2 (CEBxCLK_SDF, CEBxCLK_buf, CEBxCLK_latency_buf);

`ifdef INITIAL_MEMORY
parameter INIT_DELAY = 0.1;
parameter codefile = "ics55_ecos_sram_256x64_m4.init.code";
`endif 

`ifdef INITIAL_MEMORY
initial
begin
    #(INIT_DELAY);
    PreLoadData(codefile);
end
`endif 

`ifdef TX_INITIALIZE_FAULT
parameter codefile2 = "ics55_ecos_sram_256x64_m4.fault.code";
initial
begin
    `ifdef INIT_CODE_FORMAT_BIN
    $readmemb(codefile2, Pre_Loading2, 0, Words-1);
    `else
    $readmemh(codefile2, Pre_Loading2, 0, Words-1);
    `endif
    for(i=0; i < Words; i=i+1) 
    begin
        mem_fault[i] = Pre_Loading2[i];
    end
end
`endif 

// 1. precheck
//   1. power pin check
`ifdef POWER_PIN
always@(VDD) 
begin
    if (VDD !== 1'b1 && $realtime !=0 ) begin
        `ifdef NO_MESSAGE
        `else
        $display("Error_Message: Power down, memory data is destroyed at %t in %m", $time);
        `endif
        MemDataInitial(1'bx);
    end
end
always@(VSS) 
begin
    if (VSS !== 1'b0 && $realtime !=0 ) begin
        `ifdef NO_MESSAGE
        `else
        $display("Error_Message: Ground power don't equal to 0, memory data is destroyed at %t in %m", $time);
        `endif
        MemDataInitial(1'bx);
    end
end
`endif 

//   1. mare, marc deffault value check
always@(posedge CLK)
begin
    if (MARE_buf === 1'bx && CEB_buf === 1'b0)
    begin
        `ifdef NO_MESSAGE
        `else
        $display("Error_Message: MARE is unknown in %m, at %t", $realtime);
        `endif
        MemDataInitial(1'bx);
        Q_int = {Bits{1'bx}};
    end

    if (^MAR_buf === 1'bx && CEB_buf === 1'b0)
    begin
        `ifdef NO_MESSAGE
        `else
        $display("Error_Message: MAR is unknown in %m, at %t", $realtime);
        `endif
        MemDataInitial(1'bx);
        Q_int = {Bits{1'bx}};
    end

    if (MARE_buf === 1'b1 && CEB_buf === 1'b0)
    begin
        if ((MAR_buf === 4'b1000) && $realtime != 0) begin
        end
        else begin
            `ifdef NO_MESSAGE
            `else
            $display("Error_Message: The MAR must be 4'b1000  when MARE=1'b1 at %t", $realtime);
            $display("Error_Message: The MAR value please refer to datasheet, please check it");
            `endif
            MemDataInitial(1'bx);
        end
    end
end


always@(
    A_buf or
    D_buf or
    CEB_buf or
    GWEB_buf or
    WEB_buf or
    MAR_buf or
    MARE_buf
)
begin
    #0.1;
    Latch_A = A_buf;
    Latch_D = D_buf;
    Latch_CEB = CEB_buf;
    Latch_GWEB = GWEB_buf;
    Latch_WEB = WEB_buf;
    Latch_MAR = MAR_buf;
    Latch_MARE = MARE_buf;
end

always@(posedge CLK) //posedge clock 
begin
    if ($realtime != 0)
    begin 
    if (CLK === 1'bx)
        begin
            casez({CEB_int,GWEB_int})
            2'b00:
            begin
                MemDataInitial(1'bx);
            end
            2'b01:
            begin
                Q_int = {Bits{1'bx}};
            end
            2'b0x:
            begin
                MemDataInitial(1'bx);
                Q_int = {Bits{1'bx}};
            end
            2'bx0,
            2'bx1,
            2'bxx:
            begin
                MemDataInitial(1'bx);
                Q_int = {Bits{1'bx}};
            end
            endcase
            `ifdef NO_MESSAGE
            `else
            $display("Error_Message: The clock cycle is unknown in %m at %t", $realtime);
            `endif
        end
        else
        begin
                Last_A = latch_Last_A;
                memory_active;
                latch_Last_A = A_buf;
        end
    end
end

always@(
   n_flag_A7 or
   n_flag_A6 or
   n_flag_A5 or
   n_flag_A4 or
   n_flag_A3 or
   n_flag_A2 or
   n_flag_A1 or
   n_flag_A0 or
   n_flag_D63 or
   n_flag_D62 or
   n_flag_D61 or
   n_flag_D60 or
   n_flag_D59 or
   n_flag_D58 or
   n_flag_D57 or
   n_flag_D56 or
   n_flag_D55 or
   n_flag_D54 or
   n_flag_D53 or
   n_flag_D52 or
   n_flag_D51 or
   n_flag_D50 or
   n_flag_D49 or
   n_flag_D48 or
   n_flag_D47 or
   n_flag_D46 or
   n_flag_D45 or
   n_flag_D44 or
   n_flag_D43 or
   n_flag_D42 or
   n_flag_D41 or
   n_flag_D40 or
   n_flag_D39 or
   n_flag_D38 or
   n_flag_D37 or
   n_flag_D36 or
   n_flag_D35 or
   n_flag_D34 or
   n_flag_D33 or
   n_flag_D32 or
   n_flag_D31 or
   n_flag_D30 or
   n_flag_D29 or
   n_flag_D28 or
   n_flag_D27 or
   n_flag_D26 or
   n_flag_D25 or
   n_flag_D24 or
   n_flag_D23 or
   n_flag_D22 or
   n_flag_D21 or
   n_flag_D20 or
   n_flag_D19 or
   n_flag_D18 or
   n_flag_D17 or
   n_flag_D16 or
   n_flag_D15 or
   n_flag_D14 or
   n_flag_D13 or
   n_flag_D12 or
   n_flag_D11 or
   n_flag_D10 or
   n_flag_D9 or
   n_flag_D8 or
   n_flag_D7 or
   n_flag_D6 or
   n_flag_D5 or
   n_flag_D4 or
   n_flag_D3 or
   n_flag_D2 or
   n_flag_D1 or
   n_flag_D0 or
   n_flag_GWEB or
   n_flag_WEB63 or
   n_flag_WEB62 or
   n_flag_WEB61 or
   n_flag_WEB60 or
   n_flag_WEB59 or
   n_flag_WEB58 or
   n_flag_WEB57 or
   n_flag_WEB56 or
   n_flag_WEB55 or
   n_flag_WEB54 or
   n_flag_WEB53 or
   n_flag_WEB52 or
   n_flag_WEB51 or
   n_flag_WEB50 or
   n_flag_WEB49 or
   n_flag_WEB48 or
   n_flag_WEB47 or
   n_flag_WEB46 or
   n_flag_WEB45 or
   n_flag_WEB44 or
   n_flag_WEB43 or
   n_flag_WEB42 or
   n_flag_WEB41 or
   n_flag_WEB40 or
   n_flag_WEB39 or
   n_flag_WEB38 or
   n_flag_WEB37 or
   n_flag_WEB36 or
   n_flag_WEB35 or
   n_flag_WEB34 or
   n_flag_WEB33 or
   n_flag_WEB32 or
   n_flag_WEB31 or
   n_flag_WEB30 or
   n_flag_WEB29 or
   n_flag_WEB28 or
   n_flag_WEB27 or
   n_flag_WEB26 or
   n_flag_WEB25 or
   n_flag_WEB24 or
   n_flag_WEB23 or
   n_flag_WEB22 or
   n_flag_WEB21 or
   n_flag_WEB20 or
   n_flag_WEB19 or
   n_flag_WEB18 or
   n_flag_WEB17 or
   n_flag_WEB16 or
   n_flag_WEB15 or
   n_flag_WEB14 or
   n_flag_WEB13 or
   n_flag_WEB12 or
   n_flag_WEB11 or
   n_flag_WEB10 or
   n_flag_WEB9 or
   n_flag_WEB8 or
   n_flag_WEB7 or
   n_flag_WEB6 or
   n_flag_WEB5 or
   n_flag_WEB4 or
   n_flag_WEB3 or
   n_flag_WEB2 or
   n_flag_WEB1 or
   n_flag_WEB0 or
   n_flag_CEB or
   n_flag_CLK_period or
   n_flag_CLK_high_pluse or
   n_flag_CLK_low_pluse
) begin
    timing_volation_function; 
end


// 2. timing volation
task timing_volation_function;
integer i;
begin
    if (n_flag_CLK_period !== Last_n_flag_CLK_period || n_flag_CLK_low_pluse !== Last_n_flag_CLK_low_pluse || n_flag_CLK_high_pluse !== Last_n_flag_CLK_high_pluse)
    begin
        if($realtime != 0 )
        begin
	       MemDataInitial(1'bx);
            `ifdef NO_MESSAGE
            `else
            $display("Error_Message: The clock cycle is unconformable in %m at %t", $realtime);
            `endif
            Q_int = {Bits{1'bx}};
        end
    end
    else
    begin
        n_flag_A_bus = {n_flag_A7,n_flag_A6,n_flag_A5,n_flag_A4,n_flag_A3,n_flag_A2,n_flag_A1,n_flag_A0};
        n_flag_D_bus = {n_flag_D63,n_flag_D62,n_flag_D61,n_flag_D60,n_flag_D59,n_flag_D58,n_flag_D57,n_flag_D56,n_flag_D55,n_flag_D54,n_flag_D53,n_flag_D52,n_flag_D51,n_flag_D50,n_flag_D49,n_flag_D48,n_flag_D47,n_flag_D46,n_flag_D45,n_flag_D44,n_flag_D43,n_flag_D42,n_flag_D41,n_flag_D40,n_flag_D39,n_flag_D38,n_flag_D37,n_flag_D36,n_flag_D35,n_flag_D34,n_flag_D33,n_flag_D32,n_flag_D31,n_flag_D30,n_flag_D29,n_flag_D28,n_flag_D27,n_flag_D26,n_flag_D25,n_flag_D24,n_flag_D23,n_flag_D22,n_flag_D21,n_flag_D20,n_flag_D19,n_flag_D18,n_flag_D17,n_flag_D16,n_flag_D15,n_flag_D14,n_flag_D13,n_flag_D12,n_flag_D11,n_flag_D10,n_flag_D9,n_flag_D8,n_flag_D7,n_flag_D6,n_flag_D5,n_flag_D4,n_flag_D3,n_flag_D2,n_flag_D1,n_flag_D0};
        n_flag_WEB_bus = {n_flag_WEB63,n_flag_WEB62,n_flag_WEB61,n_flag_WEB60,n_flag_WEB59,n_flag_WEB58,n_flag_WEB57,n_flag_WEB56,n_flag_WEB55,n_flag_WEB54,n_flag_WEB53,n_flag_WEB52,n_flag_WEB51,n_flag_WEB50,n_flag_WEB49,n_flag_WEB48,n_flag_WEB47,n_flag_WEB46,n_flag_WEB45,n_flag_WEB44,n_flag_WEB43,n_flag_WEB42,n_flag_WEB41,n_flag_WEB40,n_flag_WEB39,n_flag_WEB38,n_flag_WEB37,n_flag_WEB36,n_flag_WEB35,n_flag_WEB34,n_flag_WEB33,n_flag_WEB32,n_flag_WEB31,n_flag_WEB30,n_flag_WEB29,n_flag_WEB28,n_flag_WEB27,n_flag_WEB26,n_flag_WEB25,n_flag_WEB24,n_flag_WEB23,n_flag_WEB22,n_flag_WEB21,n_flag_WEB20,n_flag_WEB19,n_flag_WEB18,n_flag_WEB17,n_flag_WEB16,n_flag_WEB15,n_flag_WEB14,n_flag_WEB13,n_flag_WEB12,n_flag_WEB11,n_flag_WEB10,n_flag_WEB9,n_flag_WEB8,n_flag_WEB7,n_flag_WEB6,n_flag_WEB5,n_flag_WEB4,n_flag_WEB3,n_flag_WEB2,n_flag_WEB1,n_flag_WEB0};
        for (i=0; i< Addr; i=i+1)
        begin
            Latch_A[i] = (n_flag_A_bus[i] !== Last_n_flag_A_bus[i]) ? 1'bx : Latch_A[i];
        end
        for (i=0; i< Bits; i=i+1)
        begin
            Latch_D[i] = (n_flag_D_bus[i] !== Last_n_flag_D_bus[i]) ? 1'bx : Latch_D[i];
            Latch_WEB[i] = (n_flag_WEB_bus[i] !== Last_n_flag_WEB_bus[i]) ? 1'bx : Latch_WEB[i];
        end
            Latch_GWEB = (n_flag_GWEB !== Last_n_flag_GWEB) ? 1'bx : Latch_GWEB;
        Latch_CEB = (n_flag_CEB !== Last_n_flag_CEB) ? 1'bx : Latch_CEB;
        #0.1;
        memory_active;
    end
    Last_n_flag_CLK_period = n_flag_CLK_period;
    Last_n_flag_CLK_low_pluse = n_flag_CLK_low_pluse;
    Last_n_flag_CLK_high_pluse = n_flag_CLK_high_pluse;
    Last_n_flag_A_bus = n_flag_A_bus;
    Last_n_flag_D_bus = n_flag_D_bus;
    Last_n_flag_GWEB = n_flag_GWEB;
    Last_n_flag_WEB_bus = n_flag_WEB_bus;
    Last_n_flag_CEB = n_flag_CEB;
end
endtask

always@(Latch_A  or
       Latch_D or
       Latch_GWEB or
       Latch_WEB or
       Latch_CEB)
begin
    // #0.1;
    A_int = Latch_A;
    D_int = Latch_D;
    CEB_int = Latch_CEB;
    GWEB_int  = Latch_GWEB;
    WEB_int  = Latch_WEB;
end
// 3. memory active 
task memory_active;
begin
    casez({CEB_int, GWEB_int})
    2'b00: begin // write active
        if (CheckWriteAddress(A_int))
        begin
                D_reg = D_int;
                WEB_reg = WEB_int;
                BitWriteFunction(D_reg, mem[A_int], WEB_reg);
                mem[A_int] = BitWriteOutput;
                BitWriteFunction(D_reg, Q_int, WEB_reg);
                Q_tmp = BitWriteOutput;
                    -> EVQWT;
        end
        else // write address out of range
        begin
            `ifdef ADDRESS_OUTOF_RANGE_STATUS
            MemDataInitial(1'bx);
            `endif
            Q_tmp = {Bits{1'bx}};
               -> EVQWT;
            `ifdef NO_MESSAGE
            `else
            $display("Warning_Message: The Address is out of range in %m at %t", $realtime);
            `endif
        end
    end
    2'b01: begin // read active
        if (CheckReadAddress(A_int))
        begin
            if (Q_NO_TOG == `FALSE) begin
                 if (A_int !== Last_A)
                 begin
                     if(faultinj_en == 1'b1)
                     begin
                         mem_XOR_data = mem[A_int] ^ mem_fault_array_XOR[A_int];
                     end
                     else
                     begin
                         mem_XOR_data = mem[A_int] & mem_fault_array_sa0[A_int];
                         mem_XOR_data = mem_XOR_data | mem_fault_array_sa1[A_int];
                     end
                     //Q_tmp = mem[A_int];
                    `ifdef TX_INITIALIZE_FAULT
                    Q_tmp = mem_XOR_data ^ mem_fault[A_int];
                    `else
                    Q_tmp = mem_XOR_data;
                    `endif
                     if (Q_int !== Q_tmp)
                         -> EVQ;
                     else 
                         Q_int = Q_tmp;
                 end
                 else 
                 begin
                     if (Q_int !== Q_tmp)
                     begin
                         if(faultinj_en == 1'b1)
                         begin
                             mem_XOR_data = mem[A_int] ^ mem_fault_array_XOR[A_int];
                         end
                         else
                         begin
                             mem_XOR_data = mem[A_int] & mem_fault_array_sa0[A_int];
                             mem_XOR_data = mem_XOR_data | mem_fault_array_sa1[A_int];
                         end
                         //Q_tmp = mem[A_int];
                         `ifdef TX_INITIALIZE_FAULT
                         Q_tmp = mem_XOR_data ^ mem_fault[A_int];
                         `else
                         Q_tmp = mem_XOR_data;
                         `endif
                         -> EVQ;
                     end
                     else 
                     begin
                         if(faultinj_en == 1'b1)
                         begin
                             mem_XOR_data = mem[A_int] ^ mem_fault_array_XOR[A_int];
                         end
                         else
                         begin
                             mem_XOR_data = mem[A_int] & mem_fault_array_sa0[A_int];
                             mem_XOR_data = mem_XOR_data | mem_fault_array_sa1[A_int];
                         end
                         //Q_tmp = mem[A_int];
                         `ifdef TX_INITIALIZE_FAULT
                         Q_tmp = mem_XOR_data ^ mem_fault[A_int];
                         `else
                         Q_tmp = mem_XOR_data;
                         `endif
                         Q_int = Q_tmp;
                     end
                 end
             end
             else // else if`Q_NO_TOG 
             begin
                 if(faultinj_en == 1'b1)
                 begin
                     mem_XOR_data = mem[A_int] ^ mem_fault_array_XOR[A_int];
                 end
                 else
                 begin
                     mem_XOR_data = mem[A_int] & mem_fault_array_sa0[A_int];
                     mem_XOR_data = mem_XOR_data | mem_fault_array_sa1[A_int];
                 end
                 //Q_tmp = mem[A_int];
                 `ifdef TX_INITIALIZE_FAULT
                 Q_tmp = mem_XOR_data ^ mem_fault[A_int];
                 `else
                 Q_tmp = mem_XOR_data;
                 `endif
                 Q_int = Q_tmp;
                 -> EVQ;
             end
        end
        else // read address out of range
        begin
            `ifdef NO_MESSAGE
            `else
            $display("Warning_Message: The Address is out of range in %m at %t", $realtime);
            `endif
        end
    end
    2'b0x:
    begin
        if (CheckWriteAddress(A_int))
        begin
                D_reg = {Bits{1'bx}};
                WEB_reg = WEB_int;
                BitWriteFunction(D_reg, mem[A_int], WEB_reg);
                mem[A_int] = BitWriteOutput;
                BitWriteFunction(D_reg, Q_int, WEB_reg);
                Q_tmp = BitWriteOutput;
                    -> EVQWT;
        end
        else // write address out of range
        begin
            `ifdef ADDRESS_OUTOF_RANGE_STATUS
            MemDataInitial(1'bx);
            `endif
            Q_tmp = {Bits{1'bx}};
               -> EVQWT;
            `ifdef NO_MESSAGE
            `else
            $display("Warning_Message: The Address is out of range in %m at %t", $realtime);
            `endif
        end
        `ifdef NO_MESSAGE
        `else
        $display("Error_Message: The global write enable is unknown in %m at %t", $realtime);
        `endif
        Q_int = {Bits{1'bx}};
    end
    2'b10,
    2'b11,
    2'b1x:
    begin
    end
    2'bx0,
    2'bx1,
    2'bxx:
    begin
        `ifdef NO_MESSAGE
        `else
        $display("Error_Message: The Chip enable is unknown in %m at %t", $realtime);
        `endif
        Q_int = {Bits{1'bx}};
    end
    endcase

end
endtask




always@(EVQ)
begin:EVQ_ACTIVE
    if (MARE_buf === 1'b0)
    begin
        #Trcqx
        Q_int   =  {Bits{1'bx}};
        Q_int   <= Q_tmp;
    end
    else if (MARE_buf === 1'b1 && MAR_buf[3] === 1'b1&& MAR_buf[2] === 1'b0&& MAR_buf[1] === 1'b0&& MAR_buf[0] === 1'b0) 
    begin
        #Trcqx_8
        Q_int   =  {Bits{1'bx}};
        Q_int   <= Q_tmp;
    end
end

always@(EVQWT)
begin:EVQWT_ACTIVE
    if (MARE_buf === 1'b0)
    begin
        #Twcqx
        Q_int   =  {Bits{1'bx}};
        Q_int   <= Q_tmp;
    end
    else if (MARE_buf === 1'b1 && MAR_buf[3] === 1'b1&& MAR_buf[2] === 1'b0&& MAR_buf[1] === 1'b0&& MAR_buf[0] === 1'b0) 
    begin
        #Twcqx_8
        Q_int   =  {Bits{1'bx}};
        Q_int   <= Q_tmp;
    end
end


task BitWriteFunction;
    input [Bits-1:0] DataIn;
    input [Bits-1:0] MemoryIn;
    input [Bits-1:0] WriteEn;
    
    reg  [Bits-1:0] DataIn;
    reg  [Bits-1:0] MemoryIn;
    reg  [Bits-1:0] WriteEn;
    integer i;
    
    begin
        for(i=0;i<Bits;i=i+1)
        begin
            if (WriteEn[i] === 1'b0)
                BitWriteOutput[i] = DataIn[i];
            else if (WriteEn[i] === 1'b1)
                BitWriteOutput[i] = MemoryIn[i];
            else 
                BitWriteOutput[i] = 1'bx;
        end
    end
endtask

task MemDataInitial;
input memdatainit;
reg   memdatainit;
integer i;
begin
case(memdatainit)
1'b0 : begin
    for(i=0;i<Words;i=i+1)
        mem[i] <= {Bits{1'b0}};
end
1'b1 : begin
    for(i=0;i<Words;i=i+1)
        mem[i] <= {Bits{1'b1}};
end
1'bx : begin
    for(i=0;i<Words;i=i+1)
        mem[i] <= {Bits{1'bx}};
end
endcase
end
endtask




// function for address range check 
function CheckReadAddress;
    input [Addr-1:0] Address;
    reg Addressxor;
    begin
        Addressxor = ^Address;
        if(Addressxor !== 1'bx)
        begin
            if (Address >= Words)
            begin
                `ifdef NO_MESSAGE
                `else
                $display("Error_Message : Read address out of range occured at = (%t) on address = (%m)", $realtime);
                `endif
                CheckReadAddress = 1'b0;
            end
            else
            begin
                CheckReadAddress = 1'b1;
            end
        end 
        else 
        begin
            `ifdef NO_MESSAGE
            `else
            $display("Error_Message : There is X in Read address occured at = (%t) on address = (%m)", $realtime);
            `endif
            CheckReadAddress = 1'b0;
            Q_int = {Bits{1'bx}};
        end
    end
endfunction

function CheckWriteAddress;
    input [Addr-1:0] Address;
    reg Addressxor;
    integer i;
    begin
        Addressxor = ^Address;
        if(Addressxor !== 1'bx)
        begin
            if (Address >= Words)
            begin
                `ifdef NO_MESSAGE
                `else
                $display("Error_Message : Write address out of range occured at = (%t) on address = (%m)", $realtime);
                `endif
                CheckWriteAddress = 1'b0;
            end
            else
            begin
                CheckWriteAddress = 1'b1;
            end
        end 
        else 
        begin
            `ifdef NO_MESSAGE
            `else
            $display("Error_Message : There is X in Write address occured at = (%t) on address = (%m)", $realtime);
            $display("Error_Message : Initial all memory data X at = (%t) on address = (%m)", $realtime);
            `endif
            CheckWriteAddress = 1'b0;
            for(i=0;i<Words;i=i+1)
            begin
                mem[i] = {Bits{1'bx}};
            end
        end
    end
endfunction
   

// PreLoadData for SRAM
`ifdef INITIAL_MEMORY
task PreLoadData;
    input [256*8:1] inputfile; //max is 256 character for file name
    reg [Addr:0] i;
    begin
        $display("Pre-Load data from file %s", inputfile);
        `ifdef INIT_CODE_FORMAT_BIN
        $readmemb(inputfile, Pre_Loading, 0, Words-1);
        `else
        $readmemh(inputfile, Pre_Loading, 0, Words-1);
        `endif
        for(i=0; i < Words; i=i+1) 
        begin
            mem[i] = Pre_Loading[i];
        end
    end
endtask
`endif



specify
    specparam  Trcq     = `ACEM*111.9;
    specparam  Trcq_8     = `ACEM*111.9;
    specparam  Twcq     = `ACEM*110.2;
    specparam  Twcq_8     = `ACEM*110.2;
    specparam  Trc     = `ACEM*144.0;
    specparam  Twc     = `ACEM*141.9;
    specparam  Twc8    = `ACEM*141.9;
    specparam  Trc8    = `ACEM*144.0;
    specparam  Tckl     = `ACEM*45.5;
    specparam  Tckh     = `ACEM*20.4;
    specparam  Trces    = `ACEM*33.7;
    specparam  Twces    = `ACEM*33.7;
    specparam  Trceh    = `ACEM*15.6;
    specparam  Twceh    = `ACEM*16.8;
    specparam  Tas      = `ACEM*17.4;
    specparam  Tah      = `ACEM*16.5;
    specparam  Tds      = `ACEM*1.0;
    specparam  Tdh      = `ACEM*28.3;
    specparam  Twes     = `ACEM*1.3;
    specparam  Tweh     = `ACEM*30.5;
    specparam  Tgwes    = `ACEM*20.0;
    specparam  Tgweh    = `ACEM*18.7;
    specparam  Tmars    = `ACEM*116.7;
    specparam  Tmarh    = `ACEM*116.7;
    specparam  Tmares   = `ACEM*116.7;
    specparam  Tmareh   = `ACEM*116.7;


    $setuphold(posedge CLK &&& sdfcond_A, posedge A[7], Tas, Tah, n_flag_A7);
    $setuphold(posedge CLK &&& sdfcond_A, negedge A[7], Tas, Tah, n_flag_A7);
    $setuphold(posedge CLK &&& sdfcond_A, posedge A[6], Tas, Tah, n_flag_A6);
    $setuphold(posedge CLK &&& sdfcond_A, negedge A[6], Tas, Tah, n_flag_A6);
    $setuphold(posedge CLK &&& sdfcond_A, posedge A[5], Tas, Tah, n_flag_A5);
    $setuphold(posedge CLK &&& sdfcond_A, negedge A[5], Tas, Tah, n_flag_A5);
    $setuphold(posedge CLK &&& sdfcond_A, posedge A[4], Tas, Tah, n_flag_A4);
    $setuphold(posedge CLK &&& sdfcond_A, negedge A[4], Tas, Tah, n_flag_A4);
    $setuphold(posedge CLK &&& sdfcond_A, posedge A[3], Tas, Tah, n_flag_A3);
    $setuphold(posedge CLK &&& sdfcond_A, negedge A[3], Tas, Tah, n_flag_A3);
    $setuphold(posedge CLK &&& sdfcond_A, posedge A[2], Tas, Tah, n_flag_A2);
    $setuphold(posedge CLK &&& sdfcond_A, negedge A[2], Tas, Tah, n_flag_A2);
    $setuphold(posedge CLK &&& sdfcond_A, posedge A[1], Tas, Tah, n_flag_A1);
    $setuphold(posedge CLK &&& sdfcond_A, negedge A[1], Tas, Tah, n_flag_A1);
    $setuphold(posedge CLK &&& sdfcond_A, posedge A[0], Tas, Tah, n_flag_A0);
    $setuphold(posedge CLK &&& sdfcond_A, negedge A[0], Tas, Tah, n_flag_A0);
    $setuphold(posedge CLK &&& sdfcond_D63, posedge D[63], Tds, Tdh, n_flag_D63);
    $setuphold(posedge CLK &&& sdfcond_D63, negedge D[63], Tds, Tdh, n_flag_D63);
    $setuphold(posedge CLK &&& sdfcond_D62, posedge D[62], Tds, Tdh, n_flag_D62);
    $setuphold(posedge CLK &&& sdfcond_D62, negedge D[62], Tds, Tdh, n_flag_D62);
    $setuphold(posedge CLK &&& sdfcond_D61, posedge D[61], Tds, Tdh, n_flag_D61);
    $setuphold(posedge CLK &&& sdfcond_D61, negedge D[61], Tds, Tdh, n_flag_D61);
    $setuphold(posedge CLK &&& sdfcond_D60, posedge D[60], Tds, Tdh, n_flag_D60);
    $setuphold(posedge CLK &&& sdfcond_D60, negedge D[60], Tds, Tdh, n_flag_D60);
    $setuphold(posedge CLK &&& sdfcond_D59, posedge D[59], Tds, Tdh, n_flag_D59);
    $setuphold(posedge CLK &&& sdfcond_D59, negedge D[59], Tds, Tdh, n_flag_D59);
    $setuphold(posedge CLK &&& sdfcond_D58, posedge D[58], Tds, Tdh, n_flag_D58);
    $setuphold(posedge CLK &&& sdfcond_D58, negedge D[58], Tds, Tdh, n_flag_D58);
    $setuphold(posedge CLK &&& sdfcond_D57, posedge D[57], Tds, Tdh, n_flag_D57);
    $setuphold(posedge CLK &&& sdfcond_D57, negedge D[57], Tds, Tdh, n_flag_D57);
    $setuphold(posedge CLK &&& sdfcond_D56, posedge D[56], Tds, Tdh, n_flag_D56);
    $setuphold(posedge CLK &&& sdfcond_D56, negedge D[56], Tds, Tdh, n_flag_D56);
    $setuphold(posedge CLK &&& sdfcond_D55, posedge D[55], Tds, Tdh, n_flag_D55);
    $setuphold(posedge CLK &&& sdfcond_D55, negedge D[55], Tds, Tdh, n_flag_D55);
    $setuphold(posedge CLK &&& sdfcond_D54, posedge D[54], Tds, Tdh, n_flag_D54);
    $setuphold(posedge CLK &&& sdfcond_D54, negedge D[54], Tds, Tdh, n_flag_D54);
    $setuphold(posedge CLK &&& sdfcond_D53, posedge D[53], Tds, Tdh, n_flag_D53);
    $setuphold(posedge CLK &&& sdfcond_D53, negedge D[53], Tds, Tdh, n_flag_D53);
    $setuphold(posedge CLK &&& sdfcond_D52, posedge D[52], Tds, Tdh, n_flag_D52);
    $setuphold(posedge CLK &&& sdfcond_D52, negedge D[52], Tds, Tdh, n_flag_D52);
    $setuphold(posedge CLK &&& sdfcond_D51, posedge D[51], Tds, Tdh, n_flag_D51);
    $setuphold(posedge CLK &&& sdfcond_D51, negedge D[51], Tds, Tdh, n_flag_D51);
    $setuphold(posedge CLK &&& sdfcond_D50, posedge D[50], Tds, Tdh, n_flag_D50);
    $setuphold(posedge CLK &&& sdfcond_D50, negedge D[50], Tds, Tdh, n_flag_D50);
    $setuphold(posedge CLK &&& sdfcond_D49, posedge D[49], Tds, Tdh, n_flag_D49);
    $setuphold(posedge CLK &&& sdfcond_D49, negedge D[49], Tds, Tdh, n_flag_D49);
    $setuphold(posedge CLK &&& sdfcond_D48, posedge D[48], Tds, Tdh, n_flag_D48);
    $setuphold(posedge CLK &&& sdfcond_D48, negedge D[48], Tds, Tdh, n_flag_D48);
    $setuphold(posedge CLK &&& sdfcond_D47, posedge D[47], Tds, Tdh, n_flag_D47);
    $setuphold(posedge CLK &&& sdfcond_D47, negedge D[47], Tds, Tdh, n_flag_D47);
    $setuphold(posedge CLK &&& sdfcond_D46, posedge D[46], Tds, Tdh, n_flag_D46);
    $setuphold(posedge CLK &&& sdfcond_D46, negedge D[46], Tds, Tdh, n_flag_D46);
    $setuphold(posedge CLK &&& sdfcond_D45, posedge D[45], Tds, Tdh, n_flag_D45);
    $setuphold(posedge CLK &&& sdfcond_D45, negedge D[45], Tds, Tdh, n_flag_D45);
    $setuphold(posedge CLK &&& sdfcond_D44, posedge D[44], Tds, Tdh, n_flag_D44);
    $setuphold(posedge CLK &&& sdfcond_D44, negedge D[44], Tds, Tdh, n_flag_D44);
    $setuphold(posedge CLK &&& sdfcond_D43, posedge D[43], Tds, Tdh, n_flag_D43);
    $setuphold(posedge CLK &&& sdfcond_D43, negedge D[43], Tds, Tdh, n_flag_D43);
    $setuphold(posedge CLK &&& sdfcond_D42, posedge D[42], Tds, Tdh, n_flag_D42);
    $setuphold(posedge CLK &&& sdfcond_D42, negedge D[42], Tds, Tdh, n_flag_D42);
    $setuphold(posedge CLK &&& sdfcond_D41, posedge D[41], Tds, Tdh, n_flag_D41);
    $setuphold(posedge CLK &&& sdfcond_D41, negedge D[41], Tds, Tdh, n_flag_D41);
    $setuphold(posedge CLK &&& sdfcond_D40, posedge D[40], Tds, Tdh, n_flag_D40);
    $setuphold(posedge CLK &&& sdfcond_D40, negedge D[40], Tds, Tdh, n_flag_D40);
    $setuphold(posedge CLK &&& sdfcond_D39, posedge D[39], Tds, Tdh, n_flag_D39);
    $setuphold(posedge CLK &&& sdfcond_D39, negedge D[39], Tds, Tdh, n_flag_D39);
    $setuphold(posedge CLK &&& sdfcond_D38, posedge D[38], Tds, Tdh, n_flag_D38);
    $setuphold(posedge CLK &&& sdfcond_D38, negedge D[38], Tds, Tdh, n_flag_D38);
    $setuphold(posedge CLK &&& sdfcond_D37, posedge D[37], Tds, Tdh, n_flag_D37);
    $setuphold(posedge CLK &&& sdfcond_D37, negedge D[37], Tds, Tdh, n_flag_D37);
    $setuphold(posedge CLK &&& sdfcond_D36, posedge D[36], Tds, Tdh, n_flag_D36);
    $setuphold(posedge CLK &&& sdfcond_D36, negedge D[36], Tds, Tdh, n_flag_D36);
    $setuphold(posedge CLK &&& sdfcond_D35, posedge D[35], Tds, Tdh, n_flag_D35);
    $setuphold(posedge CLK &&& sdfcond_D35, negedge D[35], Tds, Tdh, n_flag_D35);
    $setuphold(posedge CLK &&& sdfcond_D34, posedge D[34], Tds, Tdh, n_flag_D34);
    $setuphold(posedge CLK &&& sdfcond_D34, negedge D[34], Tds, Tdh, n_flag_D34);
    $setuphold(posedge CLK &&& sdfcond_D33, posedge D[33], Tds, Tdh, n_flag_D33);
    $setuphold(posedge CLK &&& sdfcond_D33, negedge D[33], Tds, Tdh, n_flag_D33);
    $setuphold(posedge CLK &&& sdfcond_D32, posedge D[32], Tds, Tdh, n_flag_D32);
    $setuphold(posedge CLK &&& sdfcond_D32, negedge D[32], Tds, Tdh, n_flag_D32);
    $setuphold(posedge CLK &&& sdfcond_D31, posedge D[31], Tds, Tdh, n_flag_D31);
    $setuphold(posedge CLK &&& sdfcond_D31, negedge D[31], Tds, Tdh, n_flag_D31);
    $setuphold(posedge CLK &&& sdfcond_D30, posedge D[30], Tds, Tdh, n_flag_D30);
    $setuphold(posedge CLK &&& sdfcond_D30, negedge D[30], Tds, Tdh, n_flag_D30);
    $setuphold(posedge CLK &&& sdfcond_D29, posedge D[29], Tds, Tdh, n_flag_D29);
    $setuphold(posedge CLK &&& sdfcond_D29, negedge D[29], Tds, Tdh, n_flag_D29);
    $setuphold(posedge CLK &&& sdfcond_D28, posedge D[28], Tds, Tdh, n_flag_D28);
    $setuphold(posedge CLK &&& sdfcond_D28, negedge D[28], Tds, Tdh, n_flag_D28);
    $setuphold(posedge CLK &&& sdfcond_D27, posedge D[27], Tds, Tdh, n_flag_D27);
    $setuphold(posedge CLK &&& sdfcond_D27, negedge D[27], Tds, Tdh, n_flag_D27);
    $setuphold(posedge CLK &&& sdfcond_D26, posedge D[26], Tds, Tdh, n_flag_D26);
    $setuphold(posedge CLK &&& sdfcond_D26, negedge D[26], Tds, Tdh, n_flag_D26);
    $setuphold(posedge CLK &&& sdfcond_D25, posedge D[25], Tds, Tdh, n_flag_D25);
    $setuphold(posedge CLK &&& sdfcond_D25, negedge D[25], Tds, Tdh, n_flag_D25);
    $setuphold(posedge CLK &&& sdfcond_D24, posedge D[24], Tds, Tdh, n_flag_D24);
    $setuphold(posedge CLK &&& sdfcond_D24, negedge D[24], Tds, Tdh, n_flag_D24);
    $setuphold(posedge CLK &&& sdfcond_D23, posedge D[23], Tds, Tdh, n_flag_D23);
    $setuphold(posedge CLK &&& sdfcond_D23, negedge D[23], Tds, Tdh, n_flag_D23);
    $setuphold(posedge CLK &&& sdfcond_D22, posedge D[22], Tds, Tdh, n_flag_D22);
    $setuphold(posedge CLK &&& sdfcond_D22, negedge D[22], Tds, Tdh, n_flag_D22);
    $setuphold(posedge CLK &&& sdfcond_D21, posedge D[21], Tds, Tdh, n_flag_D21);
    $setuphold(posedge CLK &&& sdfcond_D21, negedge D[21], Tds, Tdh, n_flag_D21);
    $setuphold(posedge CLK &&& sdfcond_D20, posedge D[20], Tds, Tdh, n_flag_D20);
    $setuphold(posedge CLK &&& sdfcond_D20, negedge D[20], Tds, Tdh, n_flag_D20);
    $setuphold(posedge CLK &&& sdfcond_D19, posedge D[19], Tds, Tdh, n_flag_D19);
    $setuphold(posedge CLK &&& sdfcond_D19, negedge D[19], Tds, Tdh, n_flag_D19);
    $setuphold(posedge CLK &&& sdfcond_D18, posedge D[18], Tds, Tdh, n_flag_D18);
    $setuphold(posedge CLK &&& sdfcond_D18, negedge D[18], Tds, Tdh, n_flag_D18);
    $setuphold(posedge CLK &&& sdfcond_D17, posedge D[17], Tds, Tdh, n_flag_D17);
    $setuphold(posedge CLK &&& sdfcond_D17, negedge D[17], Tds, Tdh, n_flag_D17);
    $setuphold(posedge CLK &&& sdfcond_D16, posedge D[16], Tds, Tdh, n_flag_D16);
    $setuphold(posedge CLK &&& sdfcond_D16, negedge D[16], Tds, Tdh, n_flag_D16);
    $setuphold(posedge CLK &&& sdfcond_D15, posedge D[15], Tds, Tdh, n_flag_D15);
    $setuphold(posedge CLK &&& sdfcond_D15, negedge D[15], Tds, Tdh, n_flag_D15);
    $setuphold(posedge CLK &&& sdfcond_D14, posedge D[14], Tds, Tdh, n_flag_D14);
    $setuphold(posedge CLK &&& sdfcond_D14, negedge D[14], Tds, Tdh, n_flag_D14);
    $setuphold(posedge CLK &&& sdfcond_D13, posedge D[13], Tds, Tdh, n_flag_D13);
    $setuphold(posedge CLK &&& sdfcond_D13, negedge D[13], Tds, Tdh, n_flag_D13);
    $setuphold(posedge CLK &&& sdfcond_D12, posedge D[12], Tds, Tdh, n_flag_D12);
    $setuphold(posedge CLK &&& sdfcond_D12, negedge D[12], Tds, Tdh, n_flag_D12);
    $setuphold(posedge CLK &&& sdfcond_D11, posedge D[11], Tds, Tdh, n_flag_D11);
    $setuphold(posedge CLK &&& sdfcond_D11, negedge D[11], Tds, Tdh, n_flag_D11);
    $setuphold(posedge CLK &&& sdfcond_D10, posedge D[10], Tds, Tdh, n_flag_D10);
    $setuphold(posedge CLK &&& sdfcond_D10, negedge D[10], Tds, Tdh, n_flag_D10);
    $setuphold(posedge CLK &&& sdfcond_D9, posedge D[9], Tds, Tdh, n_flag_D9);
    $setuphold(posedge CLK &&& sdfcond_D9, negedge D[9], Tds, Tdh, n_flag_D9);
    $setuphold(posedge CLK &&& sdfcond_D8, posedge D[8], Tds, Tdh, n_flag_D8);
    $setuphold(posedge CLK &&& sdfcond_D8, negedge D[8], Tds, Tdh, n_flag_D8);
    $setuphold(posedge CLK &&& sdfcond_D7, posedge D[7], Tds, Tdh, n_flag_D7);
    $setuphold(posedge CLK &&& sdfcond_D7, negedge D[7], Tds, Tdh, n_flag_D7);
    $setuphold(posedge CLK &&& sdfcond_D6, posedge D[6], Tds, Tdh, n_flag_D6);
    $setuphold(posedge CLK &&& sdfcond_D6, negedge D[6], Tds, Tdh, n_flag_D6);
    $setuphold(posedge CLK &&& sdfcond_D5, posedge D[5], Tds, Tdh, n_flag_D5);
    $setuphold(posedge CLK &&& sdfcond_D5, negedge D[5], Tds, Tdh, n_flag_D5);
    $setuphold(posedge CLK &&& sdfcond_D4, posedge D[4], Tds, Tdh, n_flag_D4);
    $setuphold(posedge CLK &&& sdfcond_D4, negedge D[4], Tds, Tdh, n_flag_D4);
    $setuphold(posedge CLK &&& sdfcond_D3, posedge D[3], Tds, Tdh, n_flag_D3);
    $setuphold(posedge CLK &&& sdfcond_D3, negedge D[3], Tds, Tdh, n_flag_D3);
    $setuphold(posedge CLK &&& sdfcond_D2, posedge D[2], Tds, Tdh, n_flag_D2);
    $setuphold(posedge CLK &&& sdfcond_D2, negedge D[2], Tds, Tdh, n_flag_D2);
    $setuphold(posedge CLK &&& sdfcond_D1, posedge D[1], Tds, Tdh, n_flag_D1);
    $setuphold(posedge CLK &&& sdfcond_D1, negedge D[1], Tds, Tdh, n_flag_D1);
    $setuphold(posedge CLK &&& sdfcond_D0, posedge D[0], Tds, Tdh, n_flag_D0);
    $setuphold(posedge CLK &&& sdfcond_D0, negedge D[0], Tds, Tdh, n_flag_D0);

    $setuphold(posedge CLK &&& sdfcond_GWEB, posedge GWEB, Tgwes, Tgweh, n_flag_GWEB);
    $setuphold(posedge CLK &&& sdfcond_GWEB, negedge GWEB, Tgwes, Tgweh, n_flag_GWEB);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[63], Twes, Tweh, n_flag_WEB63);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[63], Twes, Tweh, n_flag_WEB63);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[62], Twes, Tweh, n_flag_WEB62);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[62], Twes, Tweh, n_flag_WEB62);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[61], Twes, Tweh, n_flag_WEB61);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[61], Twes, Tweh, n_flag_WEB61);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[60], Twes, Tweh, n_flag_WEB60);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[60], Twes, Tweh, n_flag_WEB60);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[59], Twes, Tweh, n_flag_WEB59);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[59], Twes, Tweh, n_flag_WEB59);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[58], Twes, Tweh, n_flag_WEB58);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[58], Twes, Tweh, n_flag_WEB58);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[57], Twes, Tweh, n_flag_WEB57);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[57], Twes, Tweh, n_flag_WEB57);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[56], Twes, Tweh, n_flag_WEB56);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[56], Twes, Tweh, n_flag_WEB56);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[55], Twes, Tweh, n_flag_WEB55);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[55], Twes, Tweh, n_flag_WEB55);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[54], Twes, Tweh, n_flag_WEB54);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[54], Twes, Tweh, n_flag_WEB54);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[53], Twes, Tweh, n_flag_WEB53);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[53], Twes, Tweh, n_flag_WEB53);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[52], Twes, Tweh, n_flag_WEB52);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[52], Twes, Tweh, n_flag_WEB52);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[51], Twes, Tweh, n_flag_WEB51);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[51], Twes, Tweh, n_flag_WEB51);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[50], Twes, Tweh, n_flag_WEB50);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[50], Twes, Tweh, n_flag_WEB50);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[49], Twes, Tweh, n_flag_WEB49);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[49], Twes, Tweh, n_flag_WEB49);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[48], Twes, Tweh, n_flag_WEB48);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[48], Twes, Tweh, n_flag_WEB48);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[47], Twes, Tweh, n_flag_WEB47);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[47], Twes, Tweh, n_flag_WEB47);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[46], Twes, Tweh, n_flag_WEB46);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[46], Twes, Tweh, n_flag_WEB46);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[45], Twes, Tweh, n_flag_WEB45);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[45], Twes, Tweh, n_flag_WEB45);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[44], Twes, Tweh, n_flag_WEB44);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[44], Twes, Tweh, n_flag_WEB44);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[43], Twes, Tweh, n_flag_WEB43);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[43], Twes, Tweh, n_flag_WEB43);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[42], Twes, Tweh, n_flag_WEB42);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[42], Twes, Tweh, n_flag_WEB42);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[41], Twes, Tweh, n_flag_WEB41);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[41], Twes, Tweh, n_flag_WEB41);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[40], Twes, Tweh, n_flag_WEB40);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[40], Twes, Tweh, n_flag_WEB40);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[39], Twes, Tweh, n_flag_WEB39);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[39], Twes, Tweh, n_flag_WEB39);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[38], Twes, Tweh, n_flag_WEB38);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[38], Twes, Tweh, n_flag_WEB38);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[37], Twes, Tweh, n_flag_WEB37);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[37], Twes, Tweh, n_flag_WEB37);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[36], Twes, Tweh, n_flag_WEB36);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[36], Twes, Tweh, n_flag_WEB36);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[35], Twes, Tweh, n_flag_WEB35);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[35], Twes, Tweh, n_flag_WEB35);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[34], Twes, Tweh, n_flag_WEB34);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[34], Twes, Tweh, n_flag_WEB34);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[33], Twes, Tweh, n_flag_WEB33);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[33], Twes, Tweh, n_flag_WEB33);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[32], Twes, Tweh, n_flag_WEB32);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[32], Twes, Tweh, n_flag_WEB32);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[31], Twes, Tweh, n_flag_WEB31);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[31], Twes, Tweh, n_flag_WEB31);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[30], Twes, Tweh, n_flag_WEB30);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[30], Twes, Tweh, n_flag_WEB30);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[29], Twes, Tweh, n_flag_WEB29);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[29], Twes, Tweh, n_flag_WEB29);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[28], Twes, Tweh, n_flag_WEB28);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[28], Twes, Tweh, n_flag_WEB28);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[27], Twes, Tweh, n_flag_WEB27);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[27], Twes, Tweh, n_flag_WEB27);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[26], Twes, Tweh, n_flag_WEB26);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[26], Twes, Tweh, n_flag_WEB26);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[25], Twes, Tweh, n_flag_WEB25);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[25], Twes, Tweh, n_flag_WEB25);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[24], Twes, Tweh, n_flag_WEB24);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[24], Twes, Tweh, n_flag_WEB24);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[23], Twes, Tweh, n_flag_WEB23);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[23], Twes, Tweh, n_flag_WEB23);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[22], Twes, Tweh, n_flag_WEB22);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[22], Twes, Tweh, n_flag_WEB22);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[21], Twes, Tweh, n_flag_WEB21);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[21], Twes, Tweh, n_flag_WEB21);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[20], Twes, Tweh, n_flag_WEB20);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[20], Twes, Tweh, n_flag_WEB20);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[19], Twes, Tweh, n_flag_WEB19);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[19], Twes, Tweh, n_flag_WEB19);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[18], Twes, Tweh, n_flag_WEB18);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[18], Twes, Tweh, n_flag_WEB18);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[17], Twes, Tweh, n_flag_WEB17);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[17], Twes, Tweh, n_flag_WEB17);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[16], Twes, Tweh, n_flag_WEB16);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[16], Twes, Tweh, n_flag_WEB16);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[15], Twes, Tweh, n_flag_WEB15);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[15], Twes, Tweh, n_flag_WEB15);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[14], Twes, Tweh, n_flag_WEB14);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[14], Twes, Tweh, n_flag_WEB14);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[13], Twes, Tweh, n_flag_WEB13);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[13], Twes, Tweh, n_flag_WEB13);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[12], Twes, Tweh, n_flag_WEB12);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[12], Twes, Tweh, n_flag_WEB12);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[11], Twes, Tweh, n_flag_WEB11);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[11], Twes, Tweh, n_flag_WEB11);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[10], Twes, Tweh, n_flag_WEB10);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[10], Twes, Tweh, n_flag_WEB10);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[9], Twes, Tweh, n_flag_WEB9);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[9], Twes, Tweh, n_flag_WEB9);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[8], Twes, Tweh, n_flag_WEB8);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[8], Twes, Tweh, n_flag_WEB8);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[7], Twes, Tweh, n_flag_WEB7);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[7], Twes, Tweh, n_flag_WEB7);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[6], Twes, Tweh, n_flag_WEB6);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[6], Twes, Tweh, n_flag_WEB6);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[5], Twes, Tweh, n_flag_WEB5);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[5], Twes, Tweh, n_flag_WEB5);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[4], Twes, Tweh, n_flag_WEB4);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[4], Twes, Tweh, n_flag_WEB4);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[3], Twes, Tweh, n_flag_WEB3);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[3], Twes, Tweh, n_flag_WEB3);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[2], Twes, Tweh, n_flag_WEB2);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[2], Twes, Tweh, n_flag_WEB2);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[1], Twes, Tweh, n_flag_WEB1);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[1], Twes, Tweh, n_flag_WEB1);
    $setuphold(posedge CLK &&& sdfcond_WEB, posedge WEB[0], Twes, Tweh, n_flag_WEB0);
    $setuphold(posedge CLK &&& sdfcond_WEB, negedge WEB[0], Twes, Tweh, n_flag_WEB0);
    $setuphold(posedge CLK &&& sdfcond_CEBR, posedge CEB, Trces, Trceh, n_flag_CEB);
    $setuphold(posedge CLK &&& sdfcond_CEBR, negedge CEB, Trces, Trceh, n_flag_CEB);
    $setuphold(posedge CLK &&& sdfcond_CEBW, posedge CEB, Twces, Twceh, n_flag_CEB);
    $setuphold(posedge CLK &&& sdfcond_CEBW, negedge CEB, Twces, Twceh, n_flag_CEB);
    $setuphold(posedge CLK &&& sdfcond_MAR, posedge MAR[3], Tmars, Tmarh, n_flag_MAR);
    $setuphold(posedge CLK &&& sdfcond_MAR, negedge MAR[3], Tmars, Tmarh, n_flag_MAR);
    $setuphold(posedge CLK &&& sdfcond_MAR, posedge MAR[2], Tmars, Tmarh, n_flag_MAR);
    $setuphold(posedge CLK &&& sdfcond_MAR, negedge MAR[2], Tmars, Tmarh, n_flag_MAR);
    $setuphold(posedge CLK &&& sdfcond_MAR, posedge MAR[1], Tmars, Tmarh, n_flag_MAR);
    $setuphold(posedge CLK &&& sdfcond_MAR, negedge MAR[1], Tmars, Tmarh, n_flag_MAR);
    $setuphold(posedge CLK &&& sdfcond_MAR, posedge MAR[0], Tmars, Tmarh, n_flag_MAR);
    $setuphold(posedge CLK &&& sdfcond_MAR, negedge MAR[0], Tmars, Tmarh, n_flag_MAR);
    $setuphold(posedge CLK &&& sdfcond_MARE, posedge MARE, Tmares, Tmareh, n_flag_MARE);
    $setuphold(posedge CLK &&& sdfcond_MARE, negedge MARE, Tmares, Tmareh, n_flag_MARE);
   

    $period ( posedge CLK &&& sdfcond_RCLK, Trc,     n_flag_CLK_period);
    $period ( posedge CLK &&& sdfcond_WCLK, Twc,     n_flag_CLK_period);
    $period ( negedge CLK &&& sdfcond_RCLK, Trc,     n_flag_CLK_period);
    $period ( negedge CLK &&& sdfcond_WCLK, Twc,     n_flag_CLK_period);
    $period ( posedge CLK &&& sdfcond_RCLK8, Trc8,     n_flag_CLK_period);
    $period ( posedge CLK &&& sdfcond_WCLK8, Twc8,     n_flag_CLK_period);
    $period ( negedge CLK &&& sdfcond_RCLK8, Trc8,     n_flag_CLK_period);
    $period ( negedge CLK &&& sdfcond_WCLK8, Twc8,     n_flag_CLK_period);
    $width  ( posedge CLK &&& sdfcond_CLK,  Tckh, 0, n_flag_CLK_high_pluse);
    $width  ( negedge CLK &&& sdfcond_CLK,  Tckl, 0, n_flag_CLK_low_pluse);

    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[63] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[62] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[61] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[60] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[59] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[58] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[57] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[56] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[55] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[54] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[53] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[52] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[51] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[50] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[49] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[48] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[47] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[46] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[45] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[44] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[43] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[42] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[41] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[40] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[39] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[38] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[37] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[36] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[35] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[34] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[33] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[32] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[31] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[30] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[29] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[28] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[27] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[26] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[25] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[24] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[23] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[22] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[21] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[20] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[19] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[18] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[17] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[16] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[15] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[14] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[13] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[12] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[11] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[10] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[9] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[8] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[7] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[6] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[5] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[4] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[3] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[2] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[1] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[0] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[63] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[62] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[61] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[60] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[59] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[58] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[57] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[56] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[55] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[54] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[53] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[52] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[51] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[50] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[49] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[48] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[47] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[46] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[45] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[44] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[43] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[42] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[41] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[40] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[39] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[38] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[37] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[36] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[35] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[34] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[33] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[32] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[31] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[30] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[29] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[28] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[27] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[26] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[25] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[24] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[23] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[22] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[21] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[20] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[19] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[18] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[17] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[16] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[15] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[14] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[13] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[12] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[11] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[10] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[9] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[8] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[7] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[6] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[5] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[4] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[3] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[2] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[1] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[0] : 1'bx)) = Trcq_8;
    if (!CEB && !GWEB && !WEB[63]  && !MARE) (posedge CLK => (Q[63] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[62]  && !MARE) (posedge CLK => (Q[62] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[61]  && !MARE) (posedge CLK => (Q[61] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[60]  && !MARE) (posedge CLK => (Q[60] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[59]  && !MARE) (posedge CLK => (Q[59] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[58]  && !MARE) (posedge CLK => (Q[58] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[57]  && !MARE) (posedge CLK => (Q[57] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[56]  && !MARE) (posedge CLK => (Q[56] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[55]  && !MARE) (posedge CLK => (Q[55] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[54]  && !MARE) (posedge CLK => (Q[54] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[53]  && !MARE) (posedge CLK => (Q[53] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[52]  && !MARE) (posedge CLK => (Q[52] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[51]  && !MARE) (posedge CLK => (Q[51] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[50]  && !MARE) (posedge CLK => (Q[50] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[49]  && !MARE) (posedge CLK => (Q[49] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[48]  && !MARE) (posedge CLK => (Q[48] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[47]  && !MARE) (posedge CLK => (Q[47] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[46]  && !MARE) (posedge CLK => (Q[46] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[45]  && !MARE) (posedge CLK => (Q[45] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[44]  && !MARE) (posedge CLK => (Q[44] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[43]  && !MARE) (posedge CLK => (Q[43] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[42]  && !MARE) (posedge CLK => (Q[42] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[41]  && !MARE) (posedge CLK => (Q[41] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[40]  && !MARE) (posedge CLK => (Q[40] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[39]  && !MARE) (posedge CLK => (Q[39] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[38]  && !MARE) (posedge CLK => (Q[38] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[37]  && !MARE) (posedge CLK => (Q[37] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[36]  && !MARE) (posedge CLK => (Q[36] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[35]  && !MARE) (posedge CLK => (Q[35] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[34]  && !MARE) (posedge CLK => (Q[34] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[33]  && !MARE) (posedge CLK => (Q[33] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[32]  && !MARE) (posedge CLK => (Q[32] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[31]  && !MARE) (posedge CLK => (Q[31] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[30]  && !MARE) (posedge CLK => (Q[30] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[29]  && !MARE) (posedge CLK => (Q[29] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[28]  && !MARE) (posedge CLK => (Q[28] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[27]  && !MARE) (posedge CLK => (Q[27] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[26]  && !MARE) (posedge CLK => (Q[26] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[25]  && !MARE) (posedge CLK => (Q[25] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[24]  && !MARE) (posedge CLK => (Q[24] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[23]  && !MARE) (posedge CLK => (Q[23] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[22]  && !MARE) (posedge CLK => (Q[22] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[21]  && !MARE) (posedge CLK => (Q[21] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[20]  && !MARE) (posedge CLK => (Q[20] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[19]  && !MARE) (posedge CLK => (Q[19] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[18]  && !MARE) (posedge CLK => (Q[18] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[17]  && !MARE) (posedge CLK => (Q[17] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[16]  && !MARE) (posedge CLK => (Q[16] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[15]  && !MARE) (posedge CLK => (Q[15] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[14]  && !MARE) (posedge CLK => (Q[14] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[13]  && !MARE) (posedge CLK => (Q[13] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[12]  && !MARE) (posedge CLK => (Q[12] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[11]  && !MARE) (posedge CLK => (Q[11] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[10]  && !MARE) (posedge CLK => (Q[10] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[9]  && !MARE) (posedge CLK => (Q[9] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[8]  && !MARE) (posedge CLK => (Q[8] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[7]  && !MARE) (posedge CLK => (Q[7] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[6]  && !MARE) (posedge CLK => (Q[6] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[5]  && !MARE) (posedge CLK => (Q[5] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[4]  && !MARE) (posedge CLK => (Q[4] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[3]  && !MARE) (posedge CLK => (Q[3] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[2]  && !MARE) (posedge CLK => (Q[2] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[1]  && !MARE) (posedge CLK => (Q[1] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[0]  && !MARE) (posedge CLK => (Q[0] : 1'bx)) = Twcq;
    if (!CEB && !GWEB && !WEB[63]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[63] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[62]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[62] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[61]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[61] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[60]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[60] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[59]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[59] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[58]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[58] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[57]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[57] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[56]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[56] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[55]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[55] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[54]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[54] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[53]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[53] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[52]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[52] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[51]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[51] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[50]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[50] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[49]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[49] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[48]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[48] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[47]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[47] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[46]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[46] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[45]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[45] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[44]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[44] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[43]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[43] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[42]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[42] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[41]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[41] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[40]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[40] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[39]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[39] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[38]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[38] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[37]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[37] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[36]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[36] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[35]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[35] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[34]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[34] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[33]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[33] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[32]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[32] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[31]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[31] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[30]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[30] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[29]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[29] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[28]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[28] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[27]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[27] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[26]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[26] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[25]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[25] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[24]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[24] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[23]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[23] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[22]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[22] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[21]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[21] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[20]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[20] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[19]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[19] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[18]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[18] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[17]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[17] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[16]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[16] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[15]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[15] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[14]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[14] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[13]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[13] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[12]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[12] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[11]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[11] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[10]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[10] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[9]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[9] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[8]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[8] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[7]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[7] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[6]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[6] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[5]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[5] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[4]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[4] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[3]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[3] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[2]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[2] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[1]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[1] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB && !WEB[0]  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[0] : 1'bx)) = Twcq_8;
endspecify
`endprotect

endmodule

