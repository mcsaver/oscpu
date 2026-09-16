`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_backend_fp;
  localparam U=`R64_UOP_W,M=`R64_META_W,R=`R64_RESULT_W,T=9;
  reg clk=0;always #5 clk=~clk;
  reg rst=1,flush=0,stop=0;
  reg [1:0] fv=0,cr=3;
  wire [1:0] fr,cv,cwr,cfp,cx;
  reg [127:0] fpc=0,raw=0,pred=0;
  reg [7:0] lengths=8'h44;
  wire [2*T-1:0] ct;
  wire [2*M-1:0] cm;
  wire [127:0] cd,ctval;
  wire [9:0] ca,cflags;
  wire [11:0] cc;
  wire redir,resolve,conditional,indirect,taken,recover;
  wire [63:0] target,rpc,rnpc;
  wire [T-1:0] rtag,htag;
  wire [31:0] km;
  wire [5:0] rob_count;
  wire [1:0] lf;
  wire [2*T-1:0] lt;
  wire [2*U-1:0] lu;
  wire [383:0] lop;
  wire ff,sf;
  wire [T-1:0] ft,st;
  wire [U-1:0] fu,su;
  wire [191:0] fop,sop;
  reg [3:0] ev=0;
  wire [3:0] er;
  reg [4*T-1:0] et=0;
  reg [4*R-1:0] ed=0;
  reg [31:0] program_mem[0:255];
  reg [63:0] regs[0:31];
  reg [63:0] memory_value=0,csr_value=0;
  reg [31:0] sq_valid=0;
  reg [T-1:0] sq_tag[0:31];
  reg [63:0] sq_addr[0:31],sq_data[0:31];
  integer sq_seq[0:31],sq_sequence=0;
  integer ml,ms,latest;
  reg [63:0] addr,value;
  // Test-only LSQ owner model: capacity is reserved at real dispatch;
  // operand bind order does not define memory order.
  wire [1:0] rwant,rfire;wire [17:0] rtag_pair;wire [15:0] rfunc;wire [9:0] ramo,bslot;
  reg [1:0] rready;reg [9:0] rslot;
  reg [17:0] reserved=0,bound=0,responded=0;
  reg [8:0] owner_tag[0:17];reg [7:0] owner_func[0:17];
  reg [63:0] owner_addr[0:17];integer free0,free1,qslot,zslot,choice,best_age,current_age;
  reg blocked;integer reserves=0,binds=0,reverse_binds=0;
  always @(*)begin
    free0=-1;free1=-1;
    for(integer f=0;f<18;f=f+1)if(!reserved[f])begin
      if(free0<0)free0=f;else if(free1<0)free1=f;
    end
    rready=3;rslot=0;
    if(rwant[0])begin rready[0]=free0>=0;rslot[0+:5]=5'(free0);end
    if(rwant[1])begin
      rready[1]=rwant[0]?free1>=0:free0>=0;
      rslot[5+:5]=rwant[0]?5'(free1):5'(free0);
    end
  end
  R64Backend backend(.store_done_valid_i(1'b0),.store_done_ready_o(),.store_done_tag_i(9'b0),.store_done_error_i(1'b0),.store_done_tval_i(64'b0),.lsu_reserve_want_o(rwant),.lsu_reserve_fire_o(rfire),.lsu_reserve_tag_o(rtag_pair),
    .lsu_reserve_func_o(rfunc),.lsu_reserve_amo_o(ramo),.lsu_reserve_ready_i(rready),.lsu_reserve_slot_i(rslot),
    .lsu_slot_o(bslot),.fetch_canonical_i(66'b0),.clk(clk),.rst(rst),.flush_i(flush),.stop_i(stop),.serial_allow_i(1'b1),
    .reuse_block_i(32'b0),.fetch_valid_i(fv),.fetch_ready_o(fr),.fetch_pc_i(fpc),.fetch_raw_i(raw),
    .fetch_pred_npc_i(pred),.fetch_length_i(lengths),.fetch_exception_i(2'b0),.fetch_cause_i(12'b0),.fetch_tval_i(128'b0),
    .commit_ready_i(cr),.commit1_allow_i(1'b1),.commit_valid_o(cv),.commit_tag_o(ct),.commit_meta_o(cm),
    .commit_data_o(cd),.commit_exception_o(cx),.commit_cause_o(cc),.commit_tval_o(ctval),.commit_fflags_o(cflags),
    .commit_rd_write_o(cwr),.commit_rd_fp_o(cfp),.commit_rd_arch_o(ca),
    .redirect_valid_o(redir),.redirect_pc_o(target),.resolve_valid_o(resolve),.resolve_tag_o(rtag),
    .resolve_pc_o(rpc),.resolve_npc_o(rnpc),.resolve_conditional_o(conditional),.resolve_indirect_o(indirect),.resolve_taken_o(taken),
    .kill_mask_o(km),.head_tag_o(htag),.rob_count_o(rob_count),.recover_o(recover),
    .lsu_ready_i(~ev[1:0]),.lsu_fire_o(lf),.lsu_tag_o(lt),.lsu_uop_o(lu),.lsu_operand_o(lop),
    .fp_ready_i(fp_credit),.fp_fire_o(ff),.fp_tag_o(ft),.fp_uop_o(fu),.fp_operand_o(fop),
    .serial_ready_i(!ev[3]),.serial_fire_o(sf),.serial_tag_o(st),.serial_uop_o(su),.serial_operand_o(sop),
    .external_valid_i({ev[3],fp_valid,ev[1:0]}),.external_ready_o(er),
    .external_tag_i({et[3*T+:T],fp_result_tag,et[0+:2*T]}),
    .external_result_i({ed[3*R+:R],fp_result,ed[0+:2*R]}));
  wire fp_credit,fp_valid;
  wire [T-1:0] fp_result_tag;
  wire [R-1:0] fp_result;
  R64FpExecute fp(.clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(km),
    .in_fire_i(ff),.in_ready_o(fp_credit),.in_tag_i(ft),.in_uop_i(fu),.in_operand_i(fop),
    .fp_enabled_i(1'b1),.frm_i(3'b0),.out_valid_o(fp_valid),.out_ready_i(er[2]),
    .out_tag_o(fp_result_tag),.out_result_o(fp_result));
  // Minimal LSU/CSR owner models test command/terminal boundaries, not cache
  // implementation. Stores remain speculative until architectural commit;
  // loads forward the most recent admitted older store, including a same-pair store.
  always @(posedge clk)begin
    if(rst||flush)begin ev<=0;sq_valid=0;sq_sequence=0;reserved=0;bound=0;responded=0;end
    else begin
      for(ml=0;ml<4;ml=ml+1)
        if((ev[ml]&&er[ml])||km[et[ml*T+:5]])ev[ml]<=0;
      for(ms=0;ms<32;ms=ms+1)if(km[ms])sq_valid[ms]=0;
      for(qslot=0;qslot<18;qslot=qslot+1)if(reserved[qslot])begin
        if(km[owner_tag[qslot][4:0]])begin reserved[qslot]=0;bound[qslot]=0;end
        for(ml=0;ml<2;ml=ml+1)
          if(cv[ml]&&cr[ml]&&ct[ml*T+:T]==owner_tag[qslot])reserved[qslot]=0;
      end
      for(ml=0;ml<2;ml=ml+1)if(lf[ml])begin
        qslot=bslot[ml*5+:5];
        if(qslot>=18||!reserved[qslot]||bound[qslot]||owner_tag[qslot]!=lt[ml*T+:T])
          $fatal(1,"dispatch LSQ slot/fulltag bound without unique reserve");
        if(owner_func[qslot]!=lu[ml*U+196+:8])$fatal(1,"reserve/bind function mismatch");
        for(zslot=0;zslot<18;zslot=zslot+1)
          if(reserved[zslot]&&!bound[zslot]&&zslot!=qslot&&
              ((owner_tag[zslot][4:0]-htag[4:0])&31)<((owner_tag[qslot][4:0]-htag[4:0])&31))
            reverse_binds=reverse_binds+1;
        bound[qslot]=1;binds=binds+1;
        addr=lop[ml*192+:64]+lu[ml*U+64+:64];owner_addr[qslot]=addr;
        if(lu[ml*U+201])begin
          ms=lt[ml*T+:5];sq_valid[ms]=1;sq_tag[ms]=lt[ml*T+:T];
          sq_addr[ms]=addr;sq_data[ms]=lop[ml*192+64+:64];
        end
      end
      for(ml=0;ml<2;ml=ml+1)if(!ev[ml])begin
        choice=-1;best_age=32;
        for(qslot=0;qslot<18;qslot=qslot+1)if(reserved[qslot]&&bound[qslot]&&!responded[qslot])begin
          blocked=0;current_age=(owner_tag[qslot][4:0]-htag[4:0])&31;
          for(zslot=0;zslot<18;zslot=zslot+1)
            if(reserved[zslot]&&owner_func[zslot][5]&&!bound[zslot]&&
                ((owner_tag[zslot][4:0]-htag[4:0])&31)<current_age)blocked=1;
          if(!blocked&&current_age<best_age)begin choice=qslot;best_age=current_age;end
        end
        if(choice>=0)begin
          responded[choice]=1;ev[ml]<=1;et[ml*T+:T]<=owner_tag[choice];ed[ml*R+:R]<=0;
          if(!owner_func[choice][5])begin
            value=memory_value;latest=-1;
            for(ms=0;ms<32;ms=ms+1)
              if(sq_valid[ms]&&sq_addr[ms]==owner_addr[choice]&&
                  ((sq_tag[ms][4:0]-htag[4:0])&31)<best_age&&
                  (latest<0||((sq_tag[ms][4:0]-htag[4:0])&31)>latest))begin
                value=sq_data[ms];latest=(sq_tag[ms][4:0]-htag[4:0])&31;
              end
            ed[ml*R+:64]<=value;
          end
        end
      end
      for(ml=0;ml<2;ml=ml+1)if(rfire[ml])begin
        qslot=rslot[ml*5+:5];
        if(qslot>=18||reserved[qslot]||!rready[ml])$fatal(1,"LSQ reserve overbooked");
        reserved[qslot]=1;bound[qslot]=0;responded[qslot]=0;
        owner_tag[qslot]=rtag_pair[ml*T+:T];owner_func[qslot]=rfunc[ml*8+:8];reserves=reserves+1;
      end
      if(sf)begin
        if(st!=htag)$fatal(1,"serial command issued before ROB head");
        ev[3]<=1;et[3*T+:T]<=st;ed[3*R+:R]<=0;ed[3*R+:64]<=csr_value;
        csr_value=sop[63:0];
      end
    end
  end
  task tick;begin @(posedge clk);#1;end endtask
  task check;input condition;input [511:0] msg;
    begin if(condition!==1'b1)$fatal(1,"%0s",msg);end
  endtask
  function [31:0] addi;input integer rd,rs,imm;addi={12'(imm),5'(rs),3'b0,5'(rd),7'h13};endfunction
  function [31:0] op;input integer f7,rs2,rs1,f3,rd;op={7'(f7),5'(rs2),5'(rs1),3'(f3),5'(rd),7'h33};endfunction
  function [31:0] branch;input integer rs2,rs1,f3,imm;
    reg[12:0] off;begin off=13'(imm);branch={off[12],off[10:5],5'(rs2),5'(rs1),3'(f3),off[4:1],off[11],7'h63};end
  endfunction
  function [31:0] jal;input integer rd,imm;
    reg[20:0] off;begin off=21'(imm);jal={off[20],off[10:1],off[11],off[19:12],5'(rd),7'h6f};end
  endfunction
  reg [63:0] fp_expected[0:20];
  reg [4:0] fp_flags[0:20];
  function [31:0] fpinst;input integer f7,rs2,rs1,f3,rd;
    fpinst={7'(f7),5'(rs2),5'(rs1),3'(f3),5'(rd),7'h53};
  endfunction
  integer sent,committed,cycles,pairs,lane,idx,redirects,resolves,mem_commands,fp_commands,serial_commands;
  reg [63:0] fetch_pc,expected_pc;
  reg [M-1:0] meta;
  reg [31:0] inst;
  reg [63:0] expect_data,next_pc,imm,srca,srcb;
  reg expect_write,expect_fp,halted;
  reg [4:0] rdidx;
  task inspect_commit;
    begin
      for(lane=0;lane<2;lane=lane+1)if(cv[lane]&&cr[lane])begin
        meta=cm[lane*M+:M];inst=meta[95:64];rdidx=inst[11:7];
        check(meta[`R64_M_PC]==expected_pc,"retired wrong-path or out-of-order PC");
        srca=regs[inst[19:15]];srcb=regs[inst[24:20]];
        expect_data=0;expect_write=0;expect_fp=0;next_pc=expected_pc+4;
        case(inst[6:0])
          7'h13:begin expect_data=srca+{{52{inst[31]}},inst[31:20]};expect_write=rdidx!=0;end
          7'h33:begin
            expect_write=rdidx!=0;
            if(inst[31:25]==1&&inst[14:12]==0)expect_data=srca*srcb;
            else if(inst[31:25]==1&&inst[14:12]==4)expect_data=$signed(srca)/$signed(srcb);
            else expect_data=srca+srcb;
          end
          7'h63:begin
            imm={{51{inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'b0};
            if((inst[14:12]==0&&srca==srcb)||(inst[14:12]==1&&srca!=srcb))next_pc=expected_pc+imm;
          end
          7'h6f:begin
            imm={{43{inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'b0};
            expect_data=expected_pc+4;expect_write=rdidx!=0;next_pc=expected_pc+imm;
          end
          7'h67:begin expect_data=expected_pc+4;expect_write=rdidx!=0;next_pc=(srca+{{52{inst[31]}},inst[31:20]})&-64'd2;end
          7'h23:begin memory_value=srcb;sq_valid[ct[lane*T+:5]]=0;end
          7'h03:begin expect_data=memory_value;expect_write=rdidx!=0;end
          7'h73:begin expect_data=0;expect_write=rdidx!=0;end
          7'h53:begin expect_data=0;expect_write=1;expect_fp=inst[31:25]!=7'h71;end
          default:begin
            check(cx[lane]&&cc[lane*6+:6]==2&&!cwr[lane],"illegal instruction did not retire precise fault");
            halted=1;
          end
        endcase
        if(!halted)begin
          check(!cx[lane],"unexpected exception");
          check(cwr[lane]==expect_write&&(!expect_write||cfp[lane]==expect_fp),"commit destination metadata");
          if(expect_write)begin
            if(cd[lane*64+:64]!==expect_data)
              $fatal(1,"result PC=%h inst=%h actual=%h expected=%h",expected_pc,inst,cd[lane*64+:64],expect_data);
            if(!expect_fp)regs[rdidx]=expect_data;
          end
          check(meta[`R64_M_NPC]==next_pc,"actual branch/retire NPC mismatch");
          expected_pc=next_pc;
        end
        committed=committed+1;
      end
    end
  endtask
  initial begin
    tick();rst=0;sent=0;committed=0;pairs=0;cycles=0;
    // End-to-end steady CPI target, with real decode/rename/PRF/IQ/ALU/WB/ROB.
    while(committed<200&&cycles<160)begin
      fv=sent<200 ? 3:0;
      fpc={64'(4*sent+4),64'(4*sent)};pred={64'(4*sent+8),64'(4*sent+4)};
      raw={32'b0,addi((sent+1)%31+1,0,sent+1),32'b0,addi(sent%31+1,0,sent)};
      #1;
      if(cv==3)pairs=pairs+1;
      for(lane=0;lane<2;lane=lane+1)if(cv[lane])begin
        meta=cm[lane*M+:M];
        check(meta[`R64_M_PC]==4*committed,"steady commit PC order");
        check(cwr[lane]&&!cfp[lane]&&!cx[lane]&&cd[lane*64+:64]==committed,"steady ALU result");
        committed=committed+1;
      end
      if(fv[0]&&fr[0])sent=sent+1;
      if(fv[1]&&fr[1])sent=sent+1;
      tick();cycles=cycles+1;
    end
    check(committed==200&&sent==200&&pairs==100,"end-to-end dual IPC target");
    $display("[R64-BACKEND-IDEAL] committed=200 dual_commit_cycles=100 steady_cpi=0.5 elapsed_with_fill=%0d",cycles);
    fv=0;rst=1;tick();rst=0;
    for(idx=0;idx<32;idx=idx+1)regs[idx]=0;
    memory_value=0;csr_value=0;
    for(idx=0;idx<256;idx=idx+1)program_mem[idx]=0;
    program_mem[0]=addi(1,0,3);program_mem[1]=addi(2,0,7);
    program_mem[2]=op(1,2,1,0,3);program_mem[3]=addi(4,0,100);
    program_mem[4]=op(1,3,4,4,5);program_mem[5]=branch(0,5,0,12);
    program_mem[6]=op(0,3,5,0,6);program_mem[7]=jal(7,12);
    program_mem[8]=addi(8,0,99);program_mem[9]=32'h00803023;
    program_mem[10]=addi(8,0,5);program_mem[11]=32'h00603023;
    program_mem[12]=32'h00003483;program_mem[13]=32'h34049573;
    program_mem[14]=32'h020000d3;program_mem[15]=32'he20085d3;
    program_mem[16]=addi(12,0,2);program_mem[17]=addi(12,12,-1);
    program_mem[18]=branch(0,12,1,-4);program_mem[19]=addi(13,0,84);
    program_mem[20]=32'h00068767;program_mem[21]=addi(15,0,1);
    program_mem[22]=0;program_mem[23]=32'h00803023;
    fetch_pc=0;expected_pc=0;committed=0;cycles=0;redirects=0;resolves=0;halted=0;
    mem_commands=0;fp_commands=0;serial_commands=0;
    while(!halted&&cycles<2000)begin
      if(redir)begin fetch_pc=target;redirects=redirects+1;end
      if(resolve)begin
        resolves=resolves+1;
        if(rpc==28)check(!conditional&&!indirect&&taken&&rnpc==40,"JAL training tuple");
        if(rpc==80)check(!conditional&&indirect&&taken&&rnpc==84,"JALR training tuple");
      end
      fv=fetch_pc<100 ? 3:0;
      fpc={fetch_pc+64'd4,fetch_pc};pred={fetch_pc+64'd8,fetch_pc+64'd4};
      raw={32'b0,program_mem[(fetch_pc>>2)+1],32'b0,program_mem[fetch_pc>>2]};
      #1;inspect_commit();
      if(lf[0])mem_commands=mem_commands+1;if(lf[1])mem_commands=mem_commands+1;
      if(ff)fp_commands=fp_commands+1;if(sf)serial_commands=serial_commands+1;
      if(fv[0]&&fr[0])fetch_pc=fetch_pc+4;if(fv[1]&&fr[1])fetch_pc=fetch_pc+4;
      tick();cycles=cycles+1;
    end
    check(halted&&cycles<2000,"mixed backend program made no progress");
    check(regs[3]==21&&regs[5]==4&&regs[6]==25&&regs[8]==5&&regs[9]==25&&regs[12]==0&&regs[15]==1,"mixed architectural state");
    check(memory_value==25&&csr_value==25&&serial_commands==1&&fp_commands==2,"external owner command/commit conservation");
    check(redirects>=2&&resolves>=4,"branch paths were not exercised");
    fv=0;flush=1;tick();flush=0;#1;check(rob_count==0&&!recover,"post-trap flush");
    $display("[R64-BACKEND-MIXED] commits=%0d redirects=%0d resolves=%0d memory=%0d fp=%0d serial=%0d cycles=%0d PASS",
      committed,redirects,resolves,mem_commands,fp_commands,serial_commands,cycles);

    rst=1;tick();rst=0;flush=0;fv=0;
    for(idx=0;idx<256;idx=idx+1)program_mem[idx]=0;
    program_mem[0]=addi(1,0,3);program_mem[1]=addi(2,0,7);
    program_mem[2]=fpinst(7'h69,0,1,0,1);program_mem[3]=fpinst(7'h69,0,2,0,2);
    program_mem[4]={5'd1,2'b01,5'd2,5'd1,3'b0,5'd3,7'h43};
    program_mem[5]=fpinst(7'h2d,0,3,0,4);
    program_mem[6]=fpinst(7'h0d,1,3,0,5);
    program_mem[7]=fpinst(7'h01,2,5,0,6);
    program_mem[8]=fpinst(7'h61,0,6,0,3);
    program_mem[9]=fpinst(7'h51,6,6,2,4);
    program_mem[10]=fpinst(7'h71,0,3,0,5);
    program_mem[11]=fpinst(7'h11,1,1,1,7);
    program_mem[12]=fpinst(7'h15,1,7,0,8);
    program_mem[13]=fpinst(7'h20,1,6,0,9);
    program_mem[14]=fpinst(7'h21,0,9,0,10);
    program_mem[15]={5'd9,2'b00,5'd9,5'd9,3'b0,5'd11,7'h43};
    program_mem[16]=fpinst(7'h71,0,7,1,6);
    program_mem[17]=fpinst(7'h61,3,7,0,7);
    program_mem[18]=fpinst(7'h0d,0,1,0,12);
    program_mem[19]=fpinst(7'h00,9,1,0,13);
    for(idx=0;idx<21;idx=idx+1)begin fp_expected[idx]=0;fp_flags[idx]=0;end
    fp_expected[0]=3;fp_expected[1]=7;fp_expected[2]=64'h4008000000000000;
    fp_expected[3]=64'h401c000000000000;fp_expected[4]=64'h4038000000000000;
    fp_expected[5]=64'h4013988e1409212e;fp_flags[5]=1;
    fp_expected[6]=64'h4020000000000000;fp_expected[7]=64'h402e000000000000;
    fp_expected[8]=15;fp_expected[9]=1;fp_expected[10]=64'h4038000000000000;
    fp_expected[11]=64'hc008000000000000;fp_expected[12]=64'hc008000000000000;
    fp_expected[13]=64'hffffffff41700000;fp_expected[14]=64'h402e000000000000;
    fp_expected[15]=64'hffffffff43700000;fp_expected[16]=2;
    fp_expected[17]=0;fp_flags[17]=16;fp_expected[18]=64'h7ff0000000000000;fp_flags[18]=8;
    fp_expected[19]=64'hffffffff7fc00000;
    sent=0;committed=0;cycles=0;
    while(committed<21&&cycles<1000)begin
      fv=sent<20 ? 3:sent==20 ? 1:0;
      fpc={64'(sent*4+4),64'(sent*4)};pred={64'(sent*4+8),64'(sent*4+4)};
      raw={32'b0,program_mem[sent+1],32'b0,program_mem[sent]};
      #1;
      for(lane=0;lane<2;lane=lane+1)if(cv[lane])begin
        meta=cm[lane*M+:M];
        check(meta[`R64_M_PC]==4*committed,"native FP retirement PC");
        if(committed==20)check(cx[lane]&&cc[lane*6+:6]==2&&!cwr[lane],"native FP program final precise trap");
        else if(cx[lane]||cd[lane*64+:64]!==fp_expected[committed]||cflags[lane*5+:5]!==fp_flags[committed])
          $fatal(1,"native FP backend index=%0d data=%h flags=%h expected=%h/%h",
            committed,cd[lane*64+:64],cflags[lane*5+:5],fp_expected[committed],fp_flags[committed]);
        committed=committed+1;
      end
      if(fv[0]&&fr[0])sent=sent+1;if(fv[1]&&fr[1])sent=sent+1;
      tick();cycles=cycles+1;
    end
    check(committed==21,"native FP dependency program progress");
    $display("[R64-BACKEND-FP] commits=%0d cycles=%0d FP3/FMA/DIV/SQRT/convert/boxing/flags PASS",committed,cycles);
    $display("[PASS] tb_r64_backend_fp");$finish;
  end
endmodule
