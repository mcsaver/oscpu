`timescale 1ns/1ps
`include "R64Uop.vh"
`include "define.v"
module tb_r64_decode;
  reg [63:0] raw=0,pc=64'h80000000,pred=64'h80000004,tval=0;
  reg [3:0] len=4;
  reg fetch_ex=0;
  reg [5:0] cause=0;
  wire [`R64_UOP_W-1:0] u;
  wire [`R64_META_W-1:0] m;
  wire [2:0] c,sfp,su;
  wire wr,rfp,serial,illegal;
  wire [4:0] rd;
  wire [14:0] sa;
  wire [`CTRL_BUS_W-1:0] ctrl;
  wire fp,fl,fs,fg,movef,moveg,fclass,sgnj,addsub,mul,fma,div,sqrt,minmax,cmp,cvf,cvg,dbl;
  integer oi,f7,f3,rs2,n,code,variants,variant;
  reg [6:0] opcodes[0:23];
  reg expected_legal,expected_write,expected_fp;
  R64Decode dec(.pc_i(pc),.raw_i(raw),.length_i(len),.pred_npc_i(pred),
    .fetch_exception_i(fetch_ex),.fetch_cause_i(cause),.fetch_tval_i(tval),
    .uop_o(u),.meta_o(m),.class_o(c),.rd_write_o(wr),.rd_fp_o(rfp),
    .rd_arch_o(rd),.src_arch_o(sa),.src_fp_o(sfp),.src_used_o(su),
    .serial_o(serial),.illegal_o(illegal));
  DecodeUnit oracle(.inst_i(raw[31:0]),.ctrl_o(ctrl),.rs1_idx_o(),.rs2_idx_o(),.rd_idx_o());
  OooFpDecode fp_oracle(.decode_valid_i(1'b1),.inst_i(raw[31:0]),
    .fp_load_o(fl),.fp_store_o(fs),.fp_move_to_fpr_o(movef),.fp_move_to_gpr_o(moveg),
    .fp_class_o(fclass),.fp_sgnj_o(sgnj),.fp_addsub_o(addsub),.fp_mul_o(mul),
    .fp_fma_o(fma),.fp_div_o(div),.fp_sqrt_o(sqrt),.fp_minmax_o(minmax),
    .fp_compare_o(cmp),.fp_convert_to_fpr_o(cvf),.fp_convert_to_gpr_o(cvg),
    .fp_o(fp),.fp_double_o(dbl),.fp_gpr_write_o(fg));
  task check;input condition;input [511:0] msg;
    begin if(condition!==1'b1)$fatal(1,"%s raw=%h",msg,raw);end
  endtask
  task compare;
    begin
      #1;
      expected_legal=!ctrl[`CTRL_ILLEGAL_BIT]||fp;
      expected_fp=fp&&!fg&&!fs;
      expected_write=expected_legal&&
          ((ctrl[`CTRL_RD_EN_BIT]&&!fp)||fg||expected_fp)&&(expected_fp||raw[11:7]!=0);
      if(illegal!==!expected_legal)
        $fatal(1,"legality mismatch inst=%h native=%b oldctrl=%b fp=%b",
          raw[31:0],illegal,ctrl[`CTRL_ILLEGAL_BIT],fp);
      check(wr==expected_write,"destination write classification");
      if(wr)check(rfp==expected_fp,"destination register namespace");
      if(expected_legal)begin
        if(fp&&!fl&&!fs)begin
          check(c==`R64_C_FP,"FP issue domain");
          check(su==(fma?7:(addsub||mul||div||sgnj||minmax||cmp)?3:1),"FP source count");
          check(sfp[0]==!(movef||(cvf&&raw[31:25]>=7'h68)),"FP source namespace");
        end
        if(fl||fs||ctrl[`CTRL_NEED_MEM_BIT])check(c==`R64_C_MEM,"MEM issue domain");
        if(ctrl[`CTRL_MULDIV_BIT])check(c==`R64_C_MDU,"MDU issue domain");
      end else check(u[`R64_U_EXCEPTION]&&su==0&&!wr,"illegal encoding caused effects");
      n=n+1;
    end
  endtask
  initial begin
    opcodes[0]=7'h37;opcodes[1]=7'h17;opcodes[2]=7'h6f;opcodes[3]=7'h67;
    opcodes[4]=7'h63;opcodes[5]=7'h03;opcodes[6]=7'h23;opcodes[7]=7'h07;
    opcodes[8]=7'h27;opcodes[9]=7'h2f;opcodes[10]=7'h13;opcodes[11]=7'h1b;
    opcodes[12]=7'h33;opcodes[13]=7'h3b;opcodes[14]=7'h43;opcodes[15]=7'h47;
    opcodes[16]=7'h4b;opcodes[17]=7'h4f;opcodes[18]=7'h53;opcodes[19]=7'h73;
    opcodes[20]=7'h0f;n=0;
    for(oi=0;oi<21;oi=oi+1)
      for(f7=0;f7<128;f7=f7+1)
        for(f3=0;f3<8;f3=f3+1)
          for(rs2=0;rs2<32;rs2=rs2+1)begin
            raw={32'b0,7'(f7),5'(rs2),5'd1,3'(f3),5'd1,opcodes[oi]};compare();
          end
    // System fixed operands and every remaining opcode family are checked too.
    for(code=0;code<4096;code=code+1)begin raw={32'b0,12'(code),5'd0,3'd0,5'd0,7'h73};compare();end
    for(code=0;code<128;code=code+1)begin
      raw={57'b0,7'(code)};if(code!=7'h5b)compare();
    end
    // Every FP source namespace includes f0, and FMA source3 is inst[31:27].
    raw=32'h00000043;#1;check(!illegal&&rfp&&wr&&su==7&&sfp==7&&sa==0,"FMA f0 triple source");
    raw=32'h00100393;len=2;raw=64'h0001;#1;
    check(!illegal&&u[`R64_U_CMD]==32'h00000013&&m[`R64_M_RAW]==raw&&m[`R64_M_LEN]==2,"RVC raw/expanded identity");
    raw=0;#1;check(illegal&&u[`R64_U_ARG]==0,"reserved RVC trap");
    len=4;raw=64'h0001405b;#1;check(!illegal&&serial&&su==1&&m[`R64_M_KIND]==`R64_K_TENSOR,"tensor config");
    len=8;raw=64'h0a00305b_0200305b;#1;check(!illegal&&serial&&su==0&&u[`R64_U_FUNC]==1,"tensor TIU pair");
    raw[63:32]=32'h0e00305b;#1;check(!illegal&&u[`R64_U_FUNC]==2,"tensor GDMA pair");
    raw[63:32]=32'h00000013;#1;check(illegal&&u[`R64_U_ARG]==32'h0200305b,"tensor malformed pair tval");
    fetch_ex=1;cause=12;tval=64'h90000fff;#1;
    check(u[`R64_U_EXCEPTION]&&u[`R64_U_CAUSE]==12&&u[`R64_U_ARG]==tval&&!wr&&su==0,"fetch exception precedence");
    $display("[R64-DECODE] encoding comparisons=%0d I/M/B/A/F/D/CSR/Svinval plus RVC/Tensor/exception PASS",n);
    $display("[PASS] tb_r64_decode");$finish;
  end
endmodule
