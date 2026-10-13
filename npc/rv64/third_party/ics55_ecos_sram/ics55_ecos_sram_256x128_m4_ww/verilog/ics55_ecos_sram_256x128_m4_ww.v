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




module ics55_ecos_sram_256x128_m4_ww (
`ifdef POWER_PIN
    VDD, VSS,
`endif
    A, D, CEB, CLK, 
    GWEB, 
    MARE, MAR,
    Q
);

`define    TRUE                 1'b1
`define    FALSE                1'b0

parameter Q_NO_TOG = 1;
parameter MarginW = 4;
parameter Words   = 256;
parameter Bits    = 128;
parameter Mux     = 4;
parameter Bank    = 1;
parameter Addr    = 8;
parameter MuxAddr = 2.0;
parameter Trcqx = `ACEM*(99.0);
parameter Trcqx_8 = `ACEM*(99.0);
parameter Twcqx = `ACEM*(97.3);
parameter Twcqx_8 = `ACEM*(97.3);
parameter leftio = 64;
parameter rightio = 64;

`ifdef POWER_PIN
inout VDD;
inout VSS;
`endif

input [Addr-1:0] A;
input [Bits-1:0] D;
input CLK;
input CEB;
input GWEB;
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
wire               CEB_buf;
wire               MARE_buf;
wire [MarginW-1:0] MAR_buf;
wire [Bits-1:0]    Q_buf;

reg [Bits-1:0]     D_reg;
reg                GWEB_reg;

reg [Bits-1:0]     D_int;
reg [Addr-1:0]     A_int;
reg                CEB_int;
reg                GWEB_int;

reg [Bits-1:0]     Latch_D;
reg [Addr-1:0]     Latch_A;
reg                Latch_CEB;
reg                Latch_GWEB;
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
assign sdfcond_D    = ~CEB_buf & ~GWEB_buf ;
assign sdfcond_GWEB  = ~CEB_buf ;
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
reg n_flag_D127;
reg n_flag_D126;
reg n_flag_D125;
reg n_flag_D124;
reg n_flag_D123;
reg n_flag_D122;
reg n_flag_D121;
reg n_flag_D120;
reg n_flag_D119;
reg n_flag_D118;
reg n_flag_D117;
reg n_flag_D116;
reg n_flag_D115;
reg n_flag_D114;
reg n_flag_D113;
reg n_flag_D112;
reg n_flag_D111;
reg n_flag_D110;
reg n_flag_D109;
reg n_flag_D108;
reg n_flag_D107;
reg n_flag_D106;
reg n_flag_D105;
reg n_flag_D104;
reg n_flag_D103;
reg n_flag_D102;
reg n_flag_D101;
reg n_flag_D100;
reg n_flag_D99;
reg n_flag_D98;
reg n_flag_D97;
reg n_flag_D96;
reg n_flag_D95;
reg n_flag_D94;
reg n_flag_D93;
reg n_flag_D92;
reg n_flag_D91;
reg n_flag_D90;
reg n_flag_D89;
reg n_flag_D88;
reg n_flag_D87;
reg n_flag_D86;
reg n_flag_D85;
reg n_flag_D84;
reg n_flag_D83;
reg n_flag_D82;
reg n_flag_D81;
reg n_flag_D80;
reg n_flag_D79;
reg n_flag_D78;
reg n_flag_D77;
reg n_flag_D76;
reg n_flag_D75;
reg n_flag_D74;
reg n_flag_D73;
reg n_flag_D72;
reg n_flag_D71;
reg n_flag_D70;
reg n_flag_D69;
reg n_flag_D68;
reg n_flag_D67;
reg n_flag_D66;
reg n_flag_D65;
reg n_flag_D64;
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
reg Last_n_flag_D127 ;
reg Last_n_flag_D126 ;
reg Last_n_flag_D125 ;
reg Last_n_flag_D124 ;
reg Last_n_flag_D123 ;
reg Last_n_flag_D122 ;
reg Last_n_flag_D121 ;
reg Last_n_flag_D120 ;
reg Last_n_flag_D119 ;
reg Last_n_flag_D118 ;
reg Last_n_flag_D117 ;
reg Last_n_flag_D116 ;
reg Last_n_flag_D115 ;
reg Last_n_flag_D114 ;
reg Last_n_flag_D113 ;
reg Last_n_flag_D112 ;
reg Last_n_flag_D111 ;
reg Last_n_flag_D110 ;
reg Last_n_flag_D109 ;
reg Last_n_flag_D108 ;
reg Last_n_flag_D107 ;
reg Last_n_flag_D106 ;
reg Last_n_flag_D105 ;
reg Last_n_flag_D104 ;
reg Last_n_flag_D103 ;
reg Last_n_flag_D102 ;
reg Last_n_flag_D101 ;
reg Last_n_flag_D100 ;
reg Last_n_flag_D99 ;
reg Last_n_flag_D98 ;
reg Last_n_flag_D97 ;
reg Last_n_flag_D96 ;
reg Last_n_flag_D95 ;
reg Last_n_flag_D94 ;
reg Last_n_flag_D93 ;
reg Last_n_flag_D92 ;
reg Last_n_flag_D91 ;
reg Last_n_flag_D90 ;
reg Last_n_flag_D89 ;
reg Last_n_flag_D88 ;
reg Last_n_flag_D87 ;
reg Last_n_flag_D86 ;
reg Last_n_flag_D85 ;
reg Last_n_flag_D84 ;
reg Last_n_flag_D83 ;
reg Last_n_flag_D82 ;
reg Last_n_flag_D81 ;
reg Last_n_flag_D80 ;
reg Last_n_flag_D79 ;
reg Last_n_flag_D78 ;
reg Last_n_flag_D77 ;
reg Last_n_flag_D76 ;
reg Last_n_flag_D75 ;
reg Last_n_flag_D74 ;
reg Last_n_flag_D73 ;
reg Last_n_flag_D72 ;
reg Last_n_flag_D71 ;
reg Last_n_flag_D70 ;
reg Last_n_flag_D69 ;
reg Last_n_flag_D68 ;
reg Last_n_flag_D67 ;
reg Last_n_flag_D66 ;
reg Last_n_flag_D65 ;
reg Last_n_flag_D64 ;
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
reg Last_n_flag_GWEB ;
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

buf Dbuf127  (D_buf[127], D[127]);
buf Dbuf126  (D_buf[126], D[126]);
buf Dbuf125  (D_buf[125], D[125]);
buf Dbuf124  (D_buf[124], D[124]);
buf Dbuf123  (D_buf[123], D[123]);
buf Dbuf122  (D_buf[122], D[122]);
buf Dbuf121  (D_buf[121], D[121]);
buf Dbuf120  (D_buf[120], D[120]);
buf Dbuf119  (D_buf[119], D[119]);
buf Dbuf118  (D_buf[118], D[118]);
buf Dbuf117  (D_buf[117], D[117]);
buf Dbuf116  (D_buf[116], D[116]);
buf Dbuf115  (D_buf[115], D[115]);
buf Dbuf114  (D_buf[114], D[114]);
buf Dbuf113  (D_buf[113], D[113]);
buf Dbuf112  (D_buf[112], D[112]);
buf Dbuf111  (D_buf[111], D[111]);
buf Dbuf110  (D_buf[110], D[110]);
buf Dbuf109  (D_buf[109], D[109]);
buf Dbuf108  (D_buf[108], D[108]);
buf Dbuf107  (D_buf[107], D[107]);
buf Dbuf106  (D_buf[106], D[106]);
buf Dbuf105  (D_buf[105], D[105]);
buf Dbuf104  (D_buf[104], D[104]);
buf Dbuf103  (D_buf[103], D[103]);
buf Dbuf102  (D_buf[102], D[102]);
buf Dbuf101  (D_buf[101], D[101]);
buf Dbuf100  (D_buf[100], D[100]);
buf Dbuf99  (D_buf[99], D[99]);
buf Dbuf98  (D_buf[98], D[98]);
buf Dbuf97  (D_buf[97], D[97]);
buf Dbuf96  (D_buf[96], D[96]);
buf Dbuf95  (D_buf[95], D[95]);
buf Dbuf94  (D_buf[94], D[94]);
buf Dbuf93  (D_buf[93], D[93]);
buf Dbuf92  (D_buf[92], D[92]);
buf Dbuf91  (D_buf[91], D[91]);
buf Dbuf90  (D_buf[90], D[90]);
buf Dbuf89  (D_buf[89], D[89]);
buf Dbuf88  (D_buf[88], D[88]);
buf Dbuf87  (D_buf[87], D[87]);
buf Dbuf86  (D_buf[86], D[86]);
buf Dbuf85  (D_buf[85], D[85]);
buf Dbuf84  (D_buf[84], D[84]);
buf Dbuf83  (D_buf[83], D[83]);
buf Dbuf82  (D_buf[82], D[82]);
buf Dbuf81  (D_buf[81], D[81]);
buf Dbuf80  (D_buf[80], D[80]);
buf Dbuf79  (D_buf[79], D[79]);
buf Dbuf78  (D_buf[78], D[78]);
buf Dbuf77  (D_buf[77], D[77]);
buf Dbuf76  (D_buf[76], D[76]);
buf Dbuf75  (D_buf[75], D[75]);
buf Dbuf74  (D_buf[74], D[74]);
buf Dbuf73  (D_buf[73], D[73]);
buf Dbuf72  (D_buf[72], D[72]);
buf Dbuf71  (D_buf[71], D[71]);
buf Dbuf70  (D_buf[70], D[70]);
buf Dbuf69  (D_buf[69], D[69]);
buf Dbuf68  (D_buf[68], D[68]);
buf Dbuf67  (D_buf[67], D[67]);
buf Dbuf66  (D_buf[66], D[66]);
buf Dbuf65  (D_buf[65], D[65]);
buf Dbuf64  (D_buf[64], D[64]);
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

buf GWEBbuf (GWEB_buf, GWEB);

buf CEBbuf (CEB_buf, CEB);


buf MAREbuf  (MARE_buf, MARE);
buf MARbuf0  (MAR_buf[0], MAR[0]);
buf MARbuf1  (MAR_buf[1], MAR[1]);
buf MARbuf2  (MAR_buf[2], MAR[2]);
buf MARbuf3  (MAR_buf[3], MAR[3]);



buf Qbuf127  (Q[127], Q_buf[127]);
buf Qbuf126  (Q[126], Q_buf[126]);
buf Qbuf125  (Q[125], Q_buf[125]);
buf Qbuf124  (Q[124], Q_buf[124]);
buf Qbuf123  (Q[123], Q_buf[123]);
buf Qbuf122  (Q[122], Q_buf[122]);
buf Qbuf121  (Q[121], Q_buf[121]);
buf Qbuf120  (Q[120], Q_buf[120]);
buf Qbuf119  (Q[119], Q_buf[119]);
buf Qbuf118  (Q[118], Q_buf[118]);
buf Qbuf117  (Q[117], Q_buf[117]);
buf Qbuf116  (Q[116], Q_buf[116]);
buf Qbuf115  (Q[115], Q_buf[115]);
buf Qbuf114  (Q[114], Q_buf[114]);
buf Qbuf113  (Q[113], Q_buf[113]);
buf Qbuf112  (Q[112], Q_buf[112]);
buf Qbuf111  (Q[111], Q_buf[111]);
buf Qbuf110  (Q[110], Q_buf[110]);
buf Qbuf109  (Q[109], Q_buf[109]);
buf Qbuf108  (Q[108], Q_buf[108]);
buf Qbuf107  (Q[107], Q_buf[107]);
buf Qbuf106  (Q[106], Q_buf[106]);
buf Qbuf105  (Q[105], Q_buf[105]);
buf Qbuf104  (Q[104], Q_buf[104]);
buf Qbuf103  (Q[103], Q_buf[103]);
buf Qbuf102  (Q[102], Q_buf[102]);
buf Qbuf101  (Q[101], Q_buf[101]);
buf Qbuf100  (Q[100], Q_buf[100]);
buf Qbuf99  (Q[99], Q_buf[99]);
buf Qbuf98  (Q[98], Q_buf[98]);
buf Qbuf97  (Q[97], Q_buf[97]);
buf Qbuf96  (Q[96], Q_buf[96]);
buf Qbuf95  (Q[95], Q_buf[95]);
buf Qbuf94  (Q[94], Q_buf[94]);
buf Qbuf93  (Q[93], Q_buf[93]);
buf Qbuf92  (Q[92], Q_buf[92]);
buf Qbuf91  (Q[91], Q_buf[91]);
buf Qbuf90  (Q[90], Q_buf[90]);
buf Qbuf89  (Q[89], Q_buf[89]);
buf Qbuf88  (Q[88], Q_buf[88]);
buf Qbuf87  (Q[87], Q_buf[87]);
buf Qbuf86  (Q[86], Q_buf[86]);
buf Qbuf85  (Q[85], Q_buf[85]);
buf Qbuf84  (Q[84], Q_buf[84]);
buf Qbuf83  (Q[83], Q_buf[83]);
buf Qbuf82  (Q[82], Q_buf[82]);
buf Qbuf81  (Q[81], Q_buf[81]);
buf Qbuf80  (Q[80], Q_buf[80]);
buf Qbuf79  (Q[79], Q_buf[79]);
buf Qbuf78  (Q[78], Q_buf[78]);
buf Qbuf77  (Q[77], Q_buf[77]);
buf Qbuf76  (Q[76], Q_buf[76]);
buf Qbuf75  (Q[75], Q_buf[75]);
buf Qbuf74  (Q[74], Q_buf[74]);
buf Qbuf73  (Q[73], Q_buf[73]);
buf Qbuf72  (Q[72], Q_buf[72]);
buf Qbuf71  (Q[71], Q_buf[71]);
buf Qbuf70  (Q[70], Q_buf[70]);
buf Qbuf69  (Q[69], Q_buf[69]);
buf Qbuf68  (Q[68], Q_buf[68]);
buf Qbuf67  (Q[67], Q_buf[67]);
buf Qbuf66  (Q[66], Q_buf[66]);
buf Qbuf65  (Q[65], Q_buf[65]);
buf Qbuf64  (Q[64], Q_buf[64]);
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
parameter codefile = "ics55_ecos_sram_256x128_m4_ww.init.code";
`endif 

`ifdef INITIAL_MEMORY
initial
begin
    #(INIT_DELAY);
    PreLoadData(codefile);
end
`endif 

`ifdef TX_INITIALIZE_FAULT
parameter codefile2 = "ics55_ecos_sram_256x128_m4_ww.fault.code";
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
    MAR_buf or
    MARE_buf
)
begin
    #0.1;
    Latch_A = A_buf;
    Latch_D = D_buf;
    Latch_CEB = CEB_buf;
    Latch_GWEB = GWEB_buf;
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
   n_flag_D127 or
   n_flag_D126 or
   n_flag_D125 or
   n_flag_D124 or
   n_flag_D123 or
   n_flag_D122 or
   n_flag_D121 or
   n_flag_D120 or
   n_flag_D119 or
   n_flag_D118 or
   n_flag_D117 or
   n_flag_D116 or
   n_flag_D115 or
   n_flag_D114 or
   n_flag_D113 or
   n_flag_D112 or
   n_flag_D111 or
   n_flag_D110 or
   n_flag_D109 or
   n_flag_D108 or
   n_flag_D107 or
   n_flag_D106 or
   n_flag_D105 or
   n_flag_D104 or
   n_flag_D103 or
   n_flag_D102 or
   n_flag_D101 or
   n_flag_D100 or
   n_flag_D99 or
   n_flag_D98 or
   n_flag_D97 or
   n_flag_D96 or
   n_flag_D95 or
   n_flag_D94 or
   n_flag_D93 or
   n_flag_D92 or
   n_flag_D91 or
   n_flag_D90 or
   n_flag_D89 or
   n_flag_D88 or
   n_flag_D87 or
   n_flag_D86 or
   n_flag_D85 or
   n_flag_D84 or
   n_flag_D83 or
   n_flag_D82 or
   n_flag_D81 or
   n_flag_D80 or
   n_flag_D79 or
   n_flag_D78 or
   n_flag_D77 or
   n_flag_D76 or
   n_flag_D75 or
   n_flag_D74 or
   n_flag_D73 or
   n_flag_D72 or
   n_flag_D71 or
   n_flag_D70 or
   n_flag_D69 or
   n_flag_D68 or
   n_flag_D67 or
   n_flag_D66 or
   n_flag_D65 or
   n_flag_D64 or
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
        n_flag_D_bus = {n_flag_D127,n_flag_D126,n_flag_D125,n_flag_D124,n_flag_D123,n_flag_D122,n_flag_D121,n_flag_D120,n_flag_D119,n_flag_D118,n_flag_D117,n_flag_D116,n_flag_D115,n_flag_D114,n_flag_D113,n_flag_D112,n_flag_D111,n_flag_D110,n_flag_D109,n_flag_D108,n_flag_D107,n_flag_D106,n_flag_D105,n_flag_D104,n_flag_D103,n_flag_D102,n_flag_D101,n_flag_D100,n_flag_D99,n_flag_D98,n_flag_D97,n_flag_D96,n_flag_D95,n_flag_D94,n_flag_D93,n_flag_D92,n_flag_D91,n_flag_D90,n_flag_D89,n_flag_D88,n_flag_D87,n_flag_D86,n_flag_D85,n_flag_D84,n_flag_D83,n_flag_D82,n_flag_D81,n_flag_D80,n_flag_D79,n_flag_D78,n_flag_D77,n_flag_D76,n_flag_D75,n_flag_D74,n_flag_D73,n_flag_D72,n_flag_D71,n_flag_D70,n_flag_D69,n_flag_D68,n_flag_D67,n_flag_D66,n_flag_D65,n_flag_D64,n_flag_D63,n_flag_D62,n_flag_D61,n_flag_D60,n_flag_D59,n_flag_D58,n_flag_D57,n_flag_D56,n_flag_D55,n_flag_D54,n_flag_D53,n_flag_D52,n_flag_D51,n_flag_D50,n_flag_D49,n_flag_D48,n_flag_D47,n_flag_D46,n_flag_D45,n_flag_D44,n_flag_D43,n_flag_D42,n_flag_D41,n_flag_D40,n_flag_D39,n_flag_D38,n_flag_D37,n_flag_D36,n_flag_D35,n_flag_D34,n_flag_D33,n_flag_D32,n_flag_D31,n_flag_D30,n_flag_D29,n_flag_D28,n_flag_D27,n_flag_D26,n_flag_D25,n_flag_D24,n_flag_D23,n_flag_D22,n_flag_D21,n_flag_D20,n_flag_D19,n_flag_D18,n_flag_D17,n_flag_D16,n_flag_D15,n_flag_D14,n_flag_D13,n_flag_D12,n_flag_D11,n_flag_D10,n_flag_D9,n_flag_D8,n_flag_D7,n_flag_D6,n_flag_D5,n_flag_D4,n_flag_D3,n_flag_D2,n_flag_D1,n_flag_D0};
        for (i=0; i< Addr; i=i+1)
        begin
            Latch_A[i] = (n_flag_A_bus[i] !== Last_n_flag_A_bus[i]) ? 1'bx : Latch_A[i];
        end
        for (i=0; i< Bits; i=i+1)
        begin
            Latch_D[i] = (n_flag_D_bus[i] !== Last_n_flag_D_bus[i]) ? 1'bx : Latch_D[i];
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
    Last_n_flag_CEB = n_flag_CEB;
end
endtask

always@(Latch_A  or
       Latch_D or
       Latch_GWEB or
       Latch_CEB)
begin
    // #0.1;
    A_int = Latch_A;
    D_int = Latch_D;
    CEB_int = Latch_CEB;
    GWEB_int = Latch_GWEB;
end
// 3. memory active 
task memory_active;
begin
    casez({CEB_int,GWEB_int})
    2'b00: begin // write active
        if (CheckWriteAddress(A_int))
        begin
                D_reg = D_int;
                mem[A_int] = D_reg;
                Q_tmp = D_buf;
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
            $display("Error_Message: The Address is out of range or there is X in address in %m at %t", $realtime);
            `endif
        end
    end
    2'b01: begin // read function
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
             else // elseif`Q_NO_TOG 
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
        end
        else  // read address out of range
        begin
            Q_int = {Bits{1'bx}};
            disable EVQ_ACTIVE;
            disable EVQWT_ACTIVE;
        end
    end
    2'b0x: begin
        if (CheckWriteAddress(A_int))
        begin
            D_reg = {Bits{1'bx}};
            mem[A_int] = D_reg;
            //if (Q_int !== Q_tmp )
            //begin
                Q_tmp = {Bits{1'bx}};
            //    -> EVQ;
            //end
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
            $display("Error_Message: Address out of range in %m at %t", $realtime);
            `endif
        end
    end
    2'b10,
    2'b11,
    2'b1x: begin
    end
    2'bx0,
    2'bx1,
    2'bxx: begin
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
    specparam  Trcq     = `ACEM*126.7;
    specparam  Trcq_8     = `ACEM*126.7;
    specparam  Twcq     = `ACEM*124.7;
    specparam  Twcq_8     = `ACEM*124.7;
    specparam  Trc     = `ACEM*159.2;
    specparam  Twc     = `ACEM*157.1;
    specparam  Twc8    = `ACEM*157.1;
    specparam  Trc8    = `ACEM*159.2;
    specparam  Tckl     = `ACEM*45.4;
    specparam  Tckh     = `ACEM*20.4;
    specparam  Trces    = `ACEM*33.6;
    specparam  Twces    = `ACEM*33.6;
    specparam  Trceh    = `ACEM*15.6;
    specparam  Twceh    = `ACEM*17.6;
    specparam  Tas      = `ACEM*17.3;
    specparam  Tah      = `ACEM*16.5;
    specparam  Tds      = `ACEM*1.0;
    specparam  Tdh      = `ACEM*35.2;
    specparam  Tgwes    = `ACEM*28.2;
    specparam  Tgweh    = `ACEM*19.7;
    specparam  Tmars    = `ACEM*130.3;
    specparam  Tmarh    = `ACEM*130.3;
    specparam  Tmares   = `ACEM*130.3;
    specparam  Tmareh   = `ACEM*130.3;


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
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[127], Tds, Tdh, n_flag_D127);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[127], Tds, Tdh, n_flag_D127);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[126], Tds, Tdh, n_flag_D126);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[126], Tds, Tdh, n_flag_D126);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[125], Tds, Tdh, n_flag_D125);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[125], Tds, Tdh, n_flag_D125);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[124], Tds, Tdh, n_flag_D124);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[124], Tds, Tdh, n_flag_D124);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[123], Tds, Tdh, n_flag_D123);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[123], Tds, Tdh, n_flag_D123);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[122], Tds, Tdh, n_flag_D122);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[122], Tds, Tdh, n_flag_D122);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[121], Tds, Tdh, n_flag_D121);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[121], Tds, Tdh, n_flag_D121);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[120], Tds, Tdh, n_flag_D120);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[120], Tds, Tdh, n_flag_D120);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[119], Tds, Tdh, n_flag_D119);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[119], Tds, Tdh, n_flag_D119);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[118], Tds, Tdh, n_flag_D118);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[118], Tds, Tdh, n_flag_D118);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[117], Tds, Tdh, n_flag_D117);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[117], Tds, Tdh, n_flag_D117);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[116], Tds, Tdh, n_flag_D116);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[116], Tds, Tdh, n_flag_D116);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[115], Tds, Tdh, n_flag_D115);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[115], Tds, Tdh, n_flag_D115);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[114], Tds, Tdh, n_flag_D114);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[114], Tds, Tdh, n_flag_D114);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[113], Tds, Tdh, n_flag_D113);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[113], Tds, Tdh, n_flag_D113);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[112], Tds, Tdh, n_flag_D112);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[112], Tds, Tdh, n_flag_D112);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[111], Tds, Tdh, n_flag_D111);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[111], Tds, Tdh, n_flag_D111);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[110], Tds, Tdh, n_flag_D110);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[110], Tds, Tdh, n_flag_D110);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[109], Tds, Tdh, n_flag_D109);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[109], Tds, Tdh, n_flag_D109);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[108], Tds, Tdh, n_flag_D108);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[108], Tds, Tdh, n_flag_D108);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[107], Tds, Tdh, n_flag_D107);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[107], Tds, Tdh, n_flag_D107);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[106], Tds, Tdh, n_flag_D106);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[106], Tds, Tdh, n_flag_D106);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[105], Tds, Tdh, n_flag_D105);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[105], Tds, Tdh, n_flag_D105);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[104], Tds, Tdh, n_flag_D104);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[104], Tds, Tdh, n_flag_D104);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[103], Tds, Tdh, n_flag_D103);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[103], Tds, Tdh, n_flag_D103);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[102], Tds, Tdh, n_flag_D102);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[102], Tds, Tdh, n_flag_D102);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[101], Tds, Tdh, n_flag_D101);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[101], Tds, Tdh, n_flag_D101);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[100], Tds, Tdh, n_flag_D100);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[100], Tds, Tdh, n_flag_D100);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[99], Tds, Tdh, n_flag_D99);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[99], Tds, Tdh, n_flag_D99);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[98], Tds, Tdh, n_flag_D98);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[98], Tds, Tdh, n_flag_D98);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[97], Tds, Tdh, n_flag_D97);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[97], Tds, Tdh, n_flag_D97);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[96], Tds, Tdh, n_flag_D96);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[96], Tds, Tdh, n_flag_D96);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[95], Tds, Tdh, n_flag_D95);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[95], Tds, Tdh, n_flag_D95);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[94], Tds, Tdh, n_flag_D94);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[94], Tds, Tdh, n_flag_D94);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[93], Tds, Tdh, n_flag_D93);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[93], Tds, Tdh, n_flag_D93);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[92], Tds, Tdh, n_flag_D92);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[92], Tds, Tdh, n_flag_D92);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[91], Tds, Tdh, n_flag_D91);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[91], Tds, Tdh, n_flag_D91);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[90], Tds, Tdh, n_flag_D90);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[90], Tds, Tdh, n_flag_D90);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[89], Tds, Tdh, n_flag_D89);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[89], Tds, Tdh, n_flag_D89);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[88], Tds, Tdh, n_flag_D88);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[88], Tds, Tdh, n_flag_D88);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[87], Tds, Tdh, n_flag_D87);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[87], Tds, Tdh, n_flag_D87);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[86], Tds, Tdh, n_flag_D86);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[86], Tds, Tdh, n_flag_D86);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[85], Tds, Tdh, n_flag_D85);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[85], Tds, Tdh, n_flag_D85);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[84], Tds, Tdh, n_flag_D84);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[84], Tds, Tdh, n_flag_D84);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[83], Tds, Tdh, n_flag_D83);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[83], Tds, Tdh, n_flag_D83);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[82], Tds, Tdh, n_flag_D82);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[82], Tds, Tdh, n_flag_D82);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[81], Tds, Tdh, n_flag_D81);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[81], Tds, Tdh, n_flag_D81);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[80], Tds, Tdh, n_flag_D80);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[80], Tds, Tdh, n_flag_D80);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[79], Tds, Tdh, n_flag_D79);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[79], Tds, Tdh, n_flag_D79);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[78], Tds, Tdh, n_flag_D78);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[78], Tds, Tdh, n_flag_D78);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[77], Tds, Tdh, n_flag_D77);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[77], Tds, Tdh, n_flag_D77);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[76], Tds, Tdh, n_flag_D76);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[76], Tds, Tdh, n_flag_D76);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[75], Tds, Tdh, n_flag_D75);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[75], Tds, Tdh, n_flag_D75);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[74], Tds, Tdh, n_flag_D74);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[74], Tds, Tdh, n_flag_D74);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[73], Tds, Tdh, n_flag_D73);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[73], Tds, Tdh, n_flag_D73);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[72], Tds, Tdh, n_flag_D72);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[72], Tds, Tdh, n_flag_D72);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[71], Tds, Tdh, n_flag_D71);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[71], Tds, Tdh, n_flag_D71);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[70], Tds, Tdh, n_flag_D70);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[70], Tds, Tdh, n_flag_D70);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[69], Tds, Tdh, n_flag_D69);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[69], Tds, Tdh, n_flag_D69);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[68], Tds, Tdh, n_flag_D68);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[68], Tds, Tdh, n_flag_D68);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[67], Tds, Tdh, n_flag_D67);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[67], Tds, Tdh, n_flag_D67);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[66], Tds, Tdh, n_flag_D66);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[66], Tds, Tdh, n_flag_D66);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[65], Tds, Tdh, n_flag_D65);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[65], Tds, Tdh, n_flag_D65);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[64], Tds, Tdh, n_flag_D64);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[64], Tds, Tdh, n_flag_D64);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[63], Tds, Tdh, n_flag_D63);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[63], Tds, Tdh, n_flag_D63);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[62], Tds, Tdh, n_flag_D62);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[62], Tds, Tdh, n_flag_D62);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[61], Tds, Tdh, n_flag_D61);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[61], Tds, Tdh, n_flag_D61);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[60], Tds, Tdh, n_flag_D60);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[60], Tds, Tdh, n_flag_D60);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[59], Tds, Tdh, n_flag_D59);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[59], Tds, Tdh, n_flag_D59);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[58], Tds, Tdh, n_flag_D58);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[58], Tds, Tdh, n_flag_D58);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[57], Tds, Tdh, n_flag_D57);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[57], Tds, Tdh, n_flag_D57);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[56], Tds, Tdh, n_flag_D56);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[56], Tds, Tdh, n_flag_D56);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[55], Tds, Tdh, n_flag_D55);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[55], Tds, Tdh, n_flag_D55);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[54], Tds, Tdh, n_flag_D54);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[54], Tds, Tdh, n_flag_D54);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[53], Tds, Tdh, n_flag_D53);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[53], Tds, Tdh, n_flag_D53);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[52], Tds, Tdh, n_flag_D52);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[52], Tds, Tdh, n_flag_D52);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[51], Tds, Tdh, n_flag_D51);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[51], Tds, Tdh, n_flag_D51);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[50], Tds, Tdh, n_flag_D50);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[50], Tds, Tdh, n_flag_D50);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[49], Tds, Tdh, n_flag_D49);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[49], Tds, Tdh, n_flag_D49);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[48], Tds, Tdh, n_flag_D48);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[48], Tds, Tdh, n_flag_D48);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[47], Tds, Tdh, n_flag_D47);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[47], Tds, Tdh, n_flag_D47);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[46], Tds, Tdh, n_flag_D46);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[46], Tds, Tdh, n_flag_D46);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[45], Tds, Tdh, n_flag_D45);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[45], Tds, Tdh, n_flag_D45);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[44], Tds, Tdh, n_flag_D44);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[44], Tds, Tdh, n_flag_D44);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[43], Tds, Tdh, n_flag_D43);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[43], Tds, Tdh, n_flag_D43);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[42], Tds, Tdh, n_flag_D42);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[42], Tds, Tdh, n_flag_D42);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[41], Tds, Tdh, n_flag_D41);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[41], Tds, Tdh, n_flag_D41);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[40], Tds, Tdh, n_flag_D40);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[40], Tds, Tdh, n_flag_D40);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[39], Tds, Tdh, n_flag_D39);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[39], Tds, Tdh, n_flag_D39);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[38], Tds, Tdh, n_flag_D38);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[38], Tds, Tdh, n_flag_D38);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[37], Tds, Tdh, n_flag_D37);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[37], Tds, Tdh, n_flag_D37);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[36], Tds, Tdh, n_flag_D36);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[36], Tds, Tdh, n_flag_D36);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[35], Tds, Tdh, n_flag_D35);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[35], Tds, Tdh, n_flag_D35);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[34], Tds, Tdh, n_flag_D34);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[34], Tds, Tdh, n_flag_D34);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[33], Tds, Tdh, n_flag_D33);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[33], Tds, Tdh, n_flag_D33);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[32], Tds, Tdh, n_flag_D32);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[32], Tds, Tdh, n_flag_D32);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[31], Tds, Tdh, n_flag_D31);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[31], Tds, Tdh, n_flag_D31);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[30], Tds, Tdh, n_flag_D30);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[30], Tds, Tdh, n_flag_D30);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[29], Tds, Tdh, n_flag_D29);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[29], Tds, Tdh, n_flag_D29);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[28], Tds, Tdh, n_flag_D28);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[28], Tds, Tdh, n_flag_D28);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[27], Tds, Tdh, n_flag_D27);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[27], Tds, Tdh, n_flag_D27);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[26], Tds, Tdh, n_flag_D26);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[26], Tds, Tdh, n_flag_D26);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[25], Tds, Tdh, n_flag_D25);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[25], Tds, Tdh, n_flag_D25);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[24], Tds, Tdh, n_flag_D24);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[24], Tds, Tdh, n_flag_D24);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[23], Tds, Tdh, n_flag_D23);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[23], Tds, Tdh, n_flag_D23);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[22], Tds, Tdh, n_flag_D22);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[22], Tds, Tdh, n_flag_D22);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[21], Tds, Tdh, n_flag_D21);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[21], Tds, Tdh, n_flag_D21);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[20], Tds, Tdh, n_flag_D20);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[20], Tds, Tdh, n_flag_D20);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[19], Tds, Tdh, n_flag_D19);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[19], Tds, Tdh, n_flag_D19);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[18], Tds, Tdh, n_flag_D18);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[18], Tds, Tdh, n_flag_D18);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[17], Tds, Tdh, n_flag_D17);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[17], Tds, Tdh, n_flag_D17);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[16], Tds, Tdh, n_flag_D16);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[16], Tds, Tdh, n_flag_D16);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[15], Tds, Tdh, n_flag_D15);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[15], Tds, Tdh, n_flag_D15);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[14], Tds, Tdh, n_flag_D14);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[14], Tds, Tdh, n_flag_D14);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[13], Tds, Tdh, n_flag_D13);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[13], Tds, Tdh, n_flag_D13);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[12], Tds, Tdh, n_flag_D12);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[12], Tds, Tdh, n_flag_D12);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[11], Tds, Tdh, n_flag_D11);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[11], Tds, Tdh, n_flag_D11);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[10], Tds, Tdh, n_flag_D10);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[10], Tds, Tdh, n_flag_D10);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[9], Tds, Tdh, n_flag_D9);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[9], Tds, Tdh, n_flag_D9);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[8], Tds, Tdh, n_flag_D8);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[8], Tds, Tdh, n_flag_D8);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[7], Tds, Tdh, n_flag_D7);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[7], Tds, Tdh, n_flag_D7);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[6], Tds, Tdh, n_flag_D6);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[6], Tds, Tdh, n_flag_D6);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[5], Tds, Tdh, n_flag_D5);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[5], Tds, Tdh, n_flag_D5);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[4], Tds, Tdh, n_flag_D4);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[4], Tds, Tdh, n_flag_D4);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[3], Tds, Tdh, n_flag_D3);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[3], Tds, Tdh, n_flag_D3);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[2], Tds, Tdh, n_flag_D2);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[2], Tds, Tdh, n_flag_D2);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[1], Tds, Tdh, n_flag_D1);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[1], Tds, Tdh, n_flag_D1);
    $setuphold(posedge CLK &&& sdfcond_D, posedge D[0], Tds, Tdh, n_flag_D0);
    $setuphold(posedge CLK &&& sdfcond_D, negedge D[0], Tds, Tdh, n_flag_D0);

    $setuphold(posedge CLK &&& sdfcond_GWEB, posedge GWEB, Tgwes, Tgweh, n_flag_GWEB);
    $setuphold(posedge CLK &&& sdfcond_GWEB, negedge GWEB, Tgwes, Tgweh, n_flag_GWEB);
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

    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[127] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[126] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[125] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[124] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[123] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[122] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[121] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[120] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[119] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[118] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[117] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[116] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[115] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[114] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[113] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[112] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[111] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[110] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[109] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[108] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[107] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[106] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[105] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[104] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[103] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[102] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[101] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[100] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[99] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[98] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[97] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[96] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[95] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[94] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[93] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[92] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[91] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[90] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[89] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[88] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[87] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[86] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[85] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[84] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[83] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[82] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[81] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[80] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[79] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[78] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[77] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[76] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[75] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[74] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[73] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[72] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[71] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[70] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[69] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[68] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[67] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[66] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[65] : 1'bx)) = Trcq;
    if (!CEB && GWEB  && !MARE) (posedge CLK => (Q[64] : 1'bx)) = Trcq;
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
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[127] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[126] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[125] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[124] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[123] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[122] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[121] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[120] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[119] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[118] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[117] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[116] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[115] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[114] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[113] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[112] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[111] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[110] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[109] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[108] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[107] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[106] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[105] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[104] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[103] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[102] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[101] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[100] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[99] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[98] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[97] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[96] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[95] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[94] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[93] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[92] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[91] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[90] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[89] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[88] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[87] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[86] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[85] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[84] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[83] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[82] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[81] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[80] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[79] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[78] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[77] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[76] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[75] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[74] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[73] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[72] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[71] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[70] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[69] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[68] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[67] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[66] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[65] : 1'bx)) = Trcq_8;
    if (!CEB && GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[64] : 1'bx)) = Trcq_8;
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
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[127] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[126] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[125] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[124] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[123] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[122] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[121] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[120] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[119] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[118] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[117] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[116] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[115] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[114] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[113] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[112] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[111] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[110] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[109] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[108] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[107] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[106] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[105] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[104] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[103] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[102] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[101] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[100] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[99] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[98] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[97] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[96] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[95] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[94] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[93] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[92] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[91] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[90] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[89] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[88] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[87] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[86] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[85] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[84] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[83] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[82] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[81] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[80] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[79] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[78] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[77] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[76] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[75] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[74] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[73] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[72] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[71] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[70] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[69] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[68] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[67] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[66] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[65] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[64] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[63] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[62] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[61] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[60] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[59] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[58] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[57] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[56] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[55] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[54] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[53] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[52] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[51] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[50] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[49] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[48] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[47] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[46] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[45] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[44] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[43] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[42] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[41] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[40] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[39] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[38] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[37] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[36] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[35] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[34] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[33] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[32] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[31] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[30] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[29] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[28] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[27] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[26] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[25] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[24] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[23] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[22] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[21] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[20] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[19] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[18] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[17] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[16] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[15] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[14] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[13] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[12] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[11] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[10] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[9] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[8] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[7] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[6] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[5] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[4] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[3] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[2] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[1] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && !MARE) (posedge CLK => (Q[0] : 1'bx)) = Twcq;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[127] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[126] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[125] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[124] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[123] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[122] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[121] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[120] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[119] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[118] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[117] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[116] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[115] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[114] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[113] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[112] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[111] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[110] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[109] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[108] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[107] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[106] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[105] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[104] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[103] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[102] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[101] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[100] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[99] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[98] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[97] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[96] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[95] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[94] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[93] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[92] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[91] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[90] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[89] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[88] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[87] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[86] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[85] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[84] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[83] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[82] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[81] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[80] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[79] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[78] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[77] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[76] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[75] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[74] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[73] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[72] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[71] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[70] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[69] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[68] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[67] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[66] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[65] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[64] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[63] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[62] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[61] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[60] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[59] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[58] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[57] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[56] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[55] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[54] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[53] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[52] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[51] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[50] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[49] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[48] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[47] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[46] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[45] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[44] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[43] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[42] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[41] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[40] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[39] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[38] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[37] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[36] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[35] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[34] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[33] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[32] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[31] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[30] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[29] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[28] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[27] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[26] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[25] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[24] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[23] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[22] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[21] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[20] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[19] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[18] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[17] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[16] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[15] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[14] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[13] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[12] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[11] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[10] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[9] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[8] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[7] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[6] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[5] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[4] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[3] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[2] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[1] : 1'bx)) = Twcq_8;
    if (!CEB && !GWEB  && MARE && MAR[3] && !MAR[2] && !MAR[1] && !MAR[0] ) (posedge CLK => (Q[0] : 1'bx)) = Twcq_8;
endspecify
`endprotect

endmodule

