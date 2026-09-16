`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_arithmetic;
  localparam MUL_LATENCY=7;
  reg clk=0;always #5 clk=~clk;
  reg rst=1,flush=0;
  reg [31:0] km=0;
  reg [63:0] a=0,b=0;
  reg [7:0] fun=0;
  reg word=0;
  wire [63:0] alu;
  reg mv=0,mr=1,dv=0,dr=1,cv=0,cr=1;
  reg [8:0] tag=0;
  wire mi,mo,di,dout,ci,co;
  wire [8:0] mt,dt,ct;
  wire [63:0] md,dd,cd;
  integer f,w,k,n,j,i,latency,alu_count,mul_count,div_count,cl_count;
  integer div_cycles=0,div_min=999,div_max=0;
  reg [63:0] expected,result,aa,bb;
  reg [127:0] product;
  reg [63:0] queue_data[0:1023];
  reg [8:0] queue_tag[0:1023];
  integer qread=0,qwrite=0;
  reg [63:0] hold_data;
  reg [8:0] hold_tag;
  reg was_held=0;
  R64Alu ualu(.a_i(a),.b_i(b),.function_i(fun),.word_i(word),.result_o(alu));
  R64Multiply mul(.clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(km),
    .in_valid_i(mv),.in_ready_o(mi),.in_tag_i(tag),.a_i(a),.b_i(b),.function_i(fun[2:0]),.word_i(word),
    .out_valid_o(mo),.out_ready_i(mr),.out_tag_o(mt),.out_data_o(md));
  R64Divide div(.clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(km),
    .in_valid_i(dv),.in_ready_o(di),.in_tag_i(tag),.a_i(a),.b_i(b),.function_i(fun[2:0]),.word_i(word),
    .out_valid_o(dout),.out_ready_i(dr),.out_tag_o(dt),.out_data_o(dd));
  R64Clmul cl(.clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(km),
    .in_valid_i(cv),.in_ready_o(ci),.in_tag_i(tag),.a_i(a),.b_i(b),.function_i(fun[1:0]),
    .out_valid_o(co),.out_ready_i(cr),.out_tag_o(ct),.out_data_o(cd));
  task tick;begin @(posedge clk);#1;end endtask
  task check;input condition;input [511:0] msg;
    begin if(condition!==1'b1)$fatal(1,"%0s fun=%0d word=%0d a=%h b=%h got=%h expected=%h",msg,fun,word,a,b,alu,expected);end
  endtask
  function [63:0] sext;input[31:0] x;sext={{32{x[31]}},x};endfunction
  function [63:0] reference_alu;
    input [63:0] a,b;input[7:0] fn;input wd;
    reg [63:0] x,r;integer sh,j,ct;reg found;
    begin
      x=wd ? {32'b0,a[31:0]}:a;sh=wd ? b[4:0]:b[5:0];r=0;ct=0;found=0;
      case(fn)
        0:r=a+b;1:r=x<<sh;2:r=$signed(a)<$signed(b);3:r=a<b;
        4:r=a^b;5:r=x>>sh;6:r=a|b;7:r=a&b;8:r=a-b;
        13:r=wd ? ($signed(sext(a[31:0]))>>>sh):($signed(a)>>>sh);
        14:r=b;
        16:r=(a<<1)+b;17:r=(a<<2)+b;18:r=(a<<3)+b;
        19:r=a&~b;20:r=a|~b;21:r=~(a^b);
        22:r=(x<<sh)|(x>>((wd ? 32:64)-sh));
        23:r=(x>>sh)|(x<<((wd ? 32:64)-sh));
        24:r=$signed(a)<$signed(b) ? a:b;25:r=$signed(a)>$signed(b) ? a:b;
        26:r=a<b ? a:b;27:r=a>b ? a:b;
        31:r=a|(64'd1<<sh);32:r=a&~(64'd1<<sh);33:r=(a>>sh)&1;34:r=a^(64'd1<<sh);
        35:begin
          ct=wd ? 32:64;
          for(j=0;j<(wd ? 32:64);j=j+1)if(x[j])ct=(wd ? 31:63)-j;
          r=ct;
        end
        36:begin
          ct=wd ? 32:64;
          for(j=(wd ? 31:63);j>=0;j=j-1)if(x[j])ct=j;
          r=ct;
        end
        37:begin for(j=0;j<64;j=j+1)ct=ct+x[j];r=ct;end
        38:r={{56{a[7]}},a[7:0]};39:r={{48{a[15]}},a[15:0]};40:r={48'b0,a[15:0]};
        41:for(j=0;j<8;j=j+1)r[j*8+:8]=a[(7-j)*8+:8];
        42:for(j=0;j<8;j=j+1)r[j*8+:8]=a[j*8+:8]!=0 ? 255:0;
        43:r={32'b0,a[31:0]}+b;
        44:r=({32'b0,a[31:0]}<<1)+b;
        45:r=({32'b0,a[31:0]}<<2)+b;
        46:r=({32'b0,a[31:0]}<<3)+b;
        47:r={32'b0,a[31:0]}<<b[5:0];
        default:r=0;
      endcase
      reference_alu=wd ? sext(r[31:0]):r;
    end
  endfunction
  function [63:0] reference_mul;
    input[63:0] a,b;input[2:0] fn;input wd;
    reg signed[127:0] sa,sb,p;
    begin
      sa={{64{(fn==1||fn==2)&&a[63]}},a};
      sb={{64{fn==1&&b[63]}},b};p=sa*sb;
      reference_mul=wd ? sext(p[31:0]):fn==0 ? p[63:0]:p[127:64];
    end
  endfunction
  initial begin
    tick();rst=0;alu_count=0;mul_count=0;div_count=0;cl_count=0;
    for(f=0;f<48;f=f+1)if(f<=8||f==13||f==14||(f>=16&&f<=27)||f>=31)
      for(w=0;w<2;w=w+1)if(w==0||f==0||f==1||f==5||f==8||f==13||f==22||f==23||f==35||f==36||f==37)
        for(k=0;k<64;k=k+1)
          for(n=0;n<8;n=n+1)begin
            case(n)
              0:a=0;1:a=-1;2:a=64'h8000000000000000;3:a=64'h7fffffff80000000;
              4:a=64'h0102030405060708;default:a={$random,$random};
            endcase
            b=n<5 ? 64'(k):{$random,$random};fun=8'(f);word=w;
            expected=reference_alu(a,b,fun,word);#1;
            check(alu===expected,"ALU numeric oracle");alu_count=alu_count+1;
          end
    // Elastic multiplier random input gaps and output stalls; queue scoreboard
    // observes only accepted input/output events, independently of pipeline state.
    for(i=0;i<500;i=i+1)begin
      if(!mv||mi)begin
        mv=($random&3)!=0;a={$random,$random};b={$random,$random};
        fun=8'($random&3);word=($random&3)==0;if(word)fun=0;tag=9'(i);
      end
      mr=($random&3)!=0;#1;
      if(was_held)check(mo&&md==hold_data&&mt==hold_tag,"multiplier held output changed");
      if(mo&&mr)begin check(qread<qwrite&&md==queue_data[qread]&&mt==queue_tag[qread],"multiplier scoreboard");qread=qread+1;mul_count=mul_count+1;end
      if(mv&&mi)begin queue_data[qwrite]=reference_mul(a,b,fun[2:0],word);queue_tag[qwrite]=tag;qwrite=qwrite+1;end
      was_held=mo&&!mr;hold_data=md;hold_tag=mt;tick();
    end
    mv=0;mr=1;
    for(i=0;i<MUL_LATENCY+2;i=i+1)begin
      #1;if(mo)begin check(md==queue_data[qread]&&mt==queue_tag[qread],"mul drain");qread=qread+1;mul_count=mul_count+1;end
      tick();
    end
    check(qread==qwrite,"multiply conservation");
    // Multiply cancellation includes a full backpressured output stage.
    mv=1;mr=0;tag=5;fun=0;word=0;a=7;b=9;tick();mv=0;repeat(MUL_LATENCY-1)tick();
    #1;check(mo&&md==63,"multiply kill setup");km=32'h20;#1;check(!mo||mt==5,"multiply cancel owner changed");tick();check(!mo,"multiply registered kill leaked");km=0;mr=1;

    // Every product tile uses the same owner: cancel and flush at each
    // physical pipeline boundary must suppress both current and later output.
    for(j=0;j<MUL_LATENCY;j=j+1)begin
      flush=1;tick();flush=0;tick();check(mi,"multiply reset credit");mv=1;mr=0;tag=9'd12;a=-1;b=-1;fun=1;word=0;
      tick();mv=0;repeat(j)tick();km=32'h1000;#1;check(!mo||mt==12,"multiply cancel changed owner");
      tick();check(!mo,"multiply registered early kill");km=0;mr=1;repeat(MUL_LATENCY+2)begin tick();check(!mo,"multiply killed tile revived");end
      mv=1;mr=0;tag=9'd44;tick();mv=0;repeat(j)tick();flush=1;tick();flush=0;mr=1;
      repeat(MUL_LATENCY+2)begin tick();check(!mo,"multiply flushed tile revived");end
    end
    // Uninterrupted II=1 for all legal multiply variants, including MULW.
    mr=1;mv=1;
    for(i=0;i<200;i=i+1)begin
      a={$random,$random};b={$random,$random};fun=8'(i%4);word=(i%5)==0;if(word)fun=0;tag=9'(i+100);
      #1;check(mi,"multiplier II1 input credit");
      if(i>=MUL_LATENCY)check(mo,"multiplier II1 output bubble");
      if(mo)begin check(md==queue_data[qread]&&mt==queue_tag[qread],"multiplier II1 value/owner");qread=qread+1;mul_count=mul_count+1;end
      queue_data[qwrite]=reference_mul(a,b,fun[2:0],word);queue_tag[qwrite]=tag;qwrite=qwrite+1;tick();
    end
    mv=0;
    repeat(MUL_LATENCY+1)begin
      #1;if(mo)begin check(md==queue_data[qread]&&mt==queue_tag[qread],"multiplier II1 drain");qread=qread+1;mul_count=mul_count+1;end
      tick();
    end
    check(qread==qwrite,"multiplier II1 conservation");
    for(w=0;w<2;w=w+1)for(f=4;f<8;f=f+1)for(n=0;n<45;n=n+1)begin
      word=w;fun=8'(f);tag=9'(n);
      case(n)
        0:begin a=0;b=0;end
        1:begin a=64'h8000000000000000;b=-1;end
        2:begin a=64'hffffffff80000000;b=-1;end
        3:begin a=-1;b=0;end
        4:begin a=7;b=19;end
        5:begin a=-19;b=7;end
        6:begin a=19;b=-7;end
        default:begin a={$random,$random};b={$random,$random};end
      endcase
      aa=word ? (fun[0] ? {32'b0,a[31:0]}:sext(a[31:0])):a;
      bb=word ? (fun[0] ? {32'b0,b[31:0]}:sext(b[31:0])):b;
      if(bb==0)expected=fun[1] ? aa:64'hffffffffffffffff;
      else if(!fun[0]&&aa==64'h8000000000000000&&bb==-64'd1)expected=fun[1] ? 0:aa;
      else if(fun[0])expected=fun[1] ? aa%bb:aa/bb;
      else expected=fun[1] ? $signed(aa)%$signed(bb):$signed(aa)/$signed(bb);
      if(word)expected=sext(expected[31:0]);
      #1;check(di,"divider idle credit");dv=1;dr=0;tick();dv=0;latency=0;
      while(!dout&&latency<80)begin tick();latency=latency+1;end
      check(dout&&dd==expected&&dt==tag,"divider numeric/tag oracle");
      div_cycles=div_cycles+latency;if(latency<div_min)div_min=latency;if(latency>div_max)div_max=latency;
      repeat(3)begin tick();check(dout&&dd==expected&&dt==tag,"divider held output changed");end
      dr=1;tick();div_count=div_count+1;
    end
    dv=1;tag=6;word=0;fun=4;a=-1;b=3;tick();dv=0;tick();km=64;#1;check(!dout,"divider kill leaked");tick();km=0;#1;check(di,"divider kill failed credit");

    // Includes ABS, NORMALIZE, ALIGN, radix-4 and held RESPONSE owners.
    for(j=0;j<80;j=j+1)begin
      flush=1;tick();flush=0;dv=1;dr=0;tag=9'd14;word=0;fun=5;a=-1;b=3;
      tick();dv=0;repeat(j)tick();km=32'h4000;#1;check(!dout||dt==14,"divider canceled owner changed");
      tick();check(!dout,"divider registered cancellation");km=0;dr=1;repeat(3)begin tick();check(!dout,"divider killed state revived");end
      check(di,"divider canceled owner credit");
    end
    for(f=1;f<=3;f=f+1)for(n=0;n<90;n=n+1)begin
      fun=8'(f);tag=9'(n);a={$random,$random};b={$random,$random};
      if(n==0)a=0;if(n==1)b=0;if(n==2)begin a=-1;b=-1;end
      product=0;for(j=0;j<64;j=j+1)if(b[j])product=product^({64'b0,a}<<j);
      expected=f==1 ? product[63:0]:f==2 ? product[126:63]:product[127:64];
      #1;check(ci,"clmul idle credit");cv=1;cr=0;tick();cv=0;latency=0;
      while(!co&&latency<18)begin tick();latency=latency+1;end
      check(co&&cd==expected&&ct==tag,"carryless four-bit oracle");
      repeat(2)begin tick();check(co&&cd==expected,"clmul held output changed");end
      cr=1;tick();cl_count=cl_count+1;
    end
    cv=1;tag=7;a=-1;b=-1;fun=1;tick();cv=0;km=128;tick();km=0;#1;check(ci&&!co,"clmul kill failed");
    $display("[R64-DIV-LATENCY] operations=%0d total=%0d min=%0d max=%0d",div_count,div_cycles,div_min,div_max);
    $display("[R64-ARITHMETIC] alu=%0d multiply=%0d divide=%0d clmul=%0d numeric/hold/kill PASS",alu_count,mul_count,div_count,cl_count);
    $display("[PASS] tb_r64_arithmetic");$finish;
  end
endmodule
