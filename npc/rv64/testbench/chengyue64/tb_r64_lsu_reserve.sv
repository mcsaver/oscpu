`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_lsu_reserve;
 parameter DEPTH=18;parameter EARLY_STORE=0;localparam IW=$clog2(DEPTH);
  reg clk=0;always #5 clk=~clk;
  reg rst=1,flush=0;reg [31:0] kill=0;
  reg [2:0] trigger_enable=0;reg [63:0] trigger_address=0;
  reg trigger_test=0,no_external=0;reg [8:0] full_tag[0:31];
  reg head_valid=1,effect_allow=1,fp_enable=1;reg [8:0] head_tag=0;
  reg [1:0] commit_fire=0;reg [17:0] commit_tag=0;
  reg [1:0] in_fire=0;wire [1:0] in_ready;
  reg [17:0] in_tag=0;reg [2*`R64_UOP_W-1:0] in_uop=0;reg [383:0] operand=0;
  wire [1:0] out_valid;reg [1:0] out_ready=3;
  wire [17:0] out_tag;wire [2*`R64_RESULT_W-1:0] out_result;
  wire [31:0] reuse;wire irreversible,idle,drained;
  wire [1:0] tv,tr,tad,tresp,trespready;wire [127:0] tva,tpa;
  wire [3:0] ta,tc;wire [1:0] tfault,tneeds;wire [9:0] tcause,townersize;wire [5:0] towneraccess;
  wire [1:0] mv,mr,mcache,mresp,mrespready,merror;wire [2*IW-1:0] mtoken,mresptoken;
  wire [127:0] ma,md,mrd;wire [3:0] mop;wire [5:0] msize;wire [15:0] mstrb;wire [9:0] mamo;
  reg [1:0] rwant=0,rfire=0;wire [1:0] rready;wire [2*IW-1:0] rslot;
  reg [17:0] rtag=0;reg [15:0] rfunc=0;reg [9:0] ramo=0;
  reg [2*IW-1:0] bslot=0;reg [IW-1:0] saved_slot[0:31];
  R64Lsu #(.EARLY_STORE(EARLY_STORE),.ENTRIES(DEPTH),.INDEX_W(IW)) dut(
   .reserve_want_i(rwant),.reserve_fire_i(rfire),.reserve_ready_o(rready),.reserve_slot_o(rslot),
   .reserve_tag_i(rtag),.reserve_func_i(rfunc),.reserve_amo_i(ramo),.in_slot_i(bslot),
   .clk_i(clk),.rst_i(rst),.flush_i(flush),.kill_mask_i(kill),
   .head_valid_i(head_valid),.head_tag_i(head_tag),.effect_allow_i(effect_allow),.trigger_enable_i(trigger_enable),.trigger_address_i(trigger_address),.fp_enable_i(fp_enable),.translate_active_i(1'b0),
   .store_done_valid_o(),.store_done_ready_i(1'b1),.store_done_tag_o(),.store_done_error_o(),.store_done_tval_o(),
   .mem_fast_store_o(),.mem_store_rsp_valid_i(1'b0),.mem_store_rsp_ready_o(),.mem_store_rsp_token_i({IW{1'b0}}),.mem_store_rsp_error_i(1'b0),
   .commit_fire_i(commit_fire),.commit_tag_i(commit_tag),
   .in_fire_i(in_fire),.in_ready_o(in_ready),.in_tag_i(in_tag),.in_uop_i(in_uop),.in_operand_i(operand),
   .out_valid_o(out_valid),.out_ready_i(out_ready),.out_tag_o(out_tag),.out_result_o(out_result),
   .reuse_block_o(reuse),.irrevocable_o(irreversible),.idle_o(idle),.drain_idle_o(drained),
   .tr_valid_o(tv),.tr_ready_i(tr),.tr_vaddr_o(tva),.tr_access_o(ta),.tr_ad_update_o(tad),
   .tr_rsp_valid_i(tresp),.tr_rsp_ready_o(trespready),.tr_paddr_i(tpa),.tr_class_i(tc),
   .tr_fault_i(tfault),.tr_needs_ad_i(tneeds),.tr_cause_i(tcause),
   .tr_owner_access_o(towneraccess),.tr_owner_size_o(townersize),
   .mem_valid_o(mv),.mem_ready_i(mr),.mem_token_o(mtoken),.mem_addr_o(ma),.mem_data_o(md),
   .mem_op_o(mop),.mem_cache_o(mcache),.mem_size_o(msize),.mem_strb_o(mstrb),.mem_amo_o(mamo),
   .mem_rsp_valid_i(mresp),.mem_rsp_ready_o(mrespready),.mem_rsp_token_i(mresptoken),
   .mem_rsp_data_i(mrd),.mem_rsp_error_i(merror),.mem_rsp_offset_i(6'b0));
  reg [63:0] memory[0:1023],expected[0:31];reg [31:0] active=0,killed=0,received=0;
  reg [31:0] expectfault=0;reg [5:0] expectcause[0:31];reg [63:0] expecttval[0:31];
  reg [63:0] tqueue[0:15];reg [1:0] taqueue[0:15];reg adqueue[0:15];
  integer tdue[0:15],th[0:1],tt[0:1],tn[0:1];
  reg [IW-1:0] mqtoken[0:15];reg [63:0] mqdata[0:15];
  reg mqerror[0:15];integer mdue[0:15],mh[0:1],mt[0:1],mn[0:1];
  integer cycles=0,trcount=0,memcount=0,wbcount=0,dual=0,adupdates=0;
  integer tr_delay=2,mem_delay=3;
  reg head_preparation_seen=0;
  reg delay_owner=0;reg [63:0] delayed_addr=0;
  reg tr_hold=0,mem_hold=0,error_write=0,bad_response=0;
  reg [31:0] rng=32'h947312bd;reg random_stall=0;
  genvar g;
  generate for(g=0;g<2;g=g+1)begin:gen_model
    assign tr[g]=tn[g]<7&&!tr_hold&&(!random_stall||rng[g]);
    assign tresp[g]=tn[g]!=0&&tdue[g*8+th[g]]<=cycles&&!tr_hold;
    assign tpa[g*64+:64]=tqueue[g*8+th[g]]&~64'h1000;
    assign tc[g*2+:2]=tqueue[g*8+th[g]][11:8]==4'he ?2'd2:2'd0;
    assign tfault[g]=tqueue[g*8+th[g]][11:8]==4'hf;
    assign tneeds[g]=tqueue[g*8+th[g]][11:8]==4'hd&&taqueue[g*8+th[g]]==2&&!adqueue[g*8+th[g]];
    assign tcause[g*5+:5]=taqueue[g*8+th[g]]==2?5'd15:5'd13;
    assign mr[g]=mn[g]<7&&!mem_hold&&(!random_stall||rng[g+2]);
    assign mresp[g]=(bad_response&&g==0)||(mn[g]!=0&&mdue[g*8+mh[g]]<=cycles&&!mem_hold);
    assign mresptoken[g*IW+:IW]=bad_response?{IW{1'b0}}:mqtoken[g*8+mh[g]];
    assign mrd[g*64+:64]=mqdata[g*8+mh[g]];
    assign merror[g]=mqerror[g*8+mh[g]];
  end endgenerate
  integer a,b,tag,index,j,slot;
  reg [63:0] response_data;
  always @(posedge clk)if(!rst)begin
    if(delay_owner&&dut.prepared_valid_q&&dut.prepared_tag_q==0)head_preparation_seen=1;
    if(no_external&&(tv!=0||mv!=0))$fatal(1,"trigger escaped into translation/physical request");
    cycles=cycles+1;rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
    for(a=0;a<2;a=a+1)begin
      // Queue outputs must remain the accepted owner through the sampling edge.
      tn[a]<=tn[a]+((tv[a]&&tr[a])?1:0)-((tresp[a]&&trespready[a])?1:0);
      if(tresp[a]&&trespready[a])th[a]<=(th[a]+1)%8;
      if(tv[a]&&tr[a])begin
        tqueue[a*8+tt[a]]=tva[a*64+:64];taqueue[a*8+tt[a]]=ta[a*2+:2];adqueue[a*8+tt[a]]=tad[a];
        tdue[a*8+tt[a]]=cycles+((delay_owner&&tva[a*64+:64]==delayed_addr)?80:tr_delay);tt[a]<=(tt[a]+1)%8;trcount=trcount+1;
        if(tad[a]&&ta[a*2+:2]==2)adupdates=adupdates+1;
      end
      mn[a]<=mn[a]+((mv[a]&&mr[a])?1:0)-((mresp[a]&&mrespready[a])?1:0);
      if(mresp[a]&&mrespready[a])mh[a]<=(mh[a]+1)%8;
      if(mv[a]&&mr[a])begin
        index=ma[a*64+:64]>>3;response_data=memory[index];
        if(mop[a*2+:2]==1&&!error_write)for(j=0;j<8;j=j+1)
          if(mstrb[a*8+j])memory[index][j*8+:8]=md[a*64+j*8+:8];
        mqtoken[a*8+mt[a]]=mtoken[a*IW+:IW];mqdata[a*8+mt[a]]=response_data;
        mqerror[a*8+mt[a]]=mop[a*2+:2]!=0&&error_write;
        mdue[a*8+mt[a]]=cycles+mem_delay;mt[a]<=(mt[a]+1)%8;memcount=memcount+1;
      end
      if(out_valid[a]&&out_ready[a])begin
        tag=out_tag[a*9+:5];
        if(trigger_test&&out_tag[a*9+:9]!==full_tag[tag])$fatal(1,"trigger generation mismatch");
        if(!active[tag]||killed[tag]||received[tag])$fatal(1,"invalid completion tag %0d active%h killed%h received%h",tag,active,killed,received);
        if(out_result[a*`R64_RESULT_W+64]!==expectfault[tag]||
          (!expectfault[tag]&&out_result[a*`R64_RESULT_W+:64]!==expected[tag])||
          (expectfault[tag]&&(out_result[a*`R64_RESULT_W+65+:6]!==expectcause[tag]||
            out_result[a*`R64_RESULT_W+71+:64]!==expecttval[tag])))
          $fatal(1,"bad result tag%0d value%h expected%h exception%b",tag,out_result[a*`R64_RESULT_W+:64],expected[tag],out_result[a*`R64_RESULT_W+64]);
        received[tag]=1;wbcount=wbcount+1;
      end
    end
    if(out_valid==3&&out_ready==3)dual=dual+1;
  end
  reg serial_fire=0,serial_ready_result=0,serial_commit=0;
  reg [8:0] serial_tag=256;reg [63:0] serial_raw=0;
  wire [`R64_UOP_W-1:0] serial_uop;
  wire serial_ready,serial_valid;wire [8:0] serial_result_tag;
  wire [`R64_RESULT_W-1:0] serial_result;
  R64Decode serial_decode(.pc_i(64'h80000000),.raw_i(serial_raw),.length_i(4'd4),.pred_npc_i(64'h80000004),
    .fetch_exception_i(1'b0),.fetch_cause_i(6'b0),.fetch_tval_i(64'b0),
    .uop_o(serial_uop),.meta_o(),.class_o(),.rd_write_o(),.rd_fp_o(),.rd_arch_o(),
    .src_arch_o(),.src_fp_o(),.src_used_o(),.serial_o(),.illegal_o());
  R64Serial serial_unit(
    .clk_i(clk),.rst_i(rst),.flush_i(flush),.kill_mask_i(kill),
    .fire_i(serial_fire),.ready_o(serial_ready),.tag_i(serial_tag),.head_tag_i(head_tag),
    .uop_i(serial_uop),.operand_i(192'b0),.memory_idle_i(drained),.wfi_wake_i(1'b1),
    .result_valid_o(serial_valid),.result_ready_i(serial_ready_result),
    .result_tag_o(serial_result_tag),.result_o(serial_result),
    .commit_i(serial_commit),.commit_tag_i(serial_tag),.privilege_i(2'b11),.mstatus_i(64'b0),
    .csr_query_o(),.csr_query_valid_i(1'b1),.return_prepare_o(),
    .csr_address_o(),.csr_select_o(),.csr_operation_o(),.csr_rs1_o(),.csr_operand_o(),
    .csr_commit_o(),.csr_read_i(64'b0),.csr_write_value_i(64'b0),.csr_illegal_i(1'b0),
    .return_supervisor_o(),.return_commit_o(),.return_target_i(64'b0),
    .icache_invalidate_o(),.tlb_invalidate_o(),.tlb_all_vaddr_o(),.tlb_all_asid_o(),
    .tlb_vpn_o(),.tlb_asid_o(),
    .tensor_cmd_valid_o(),.tensor_cmd_ready_i(1'b0),.tensor_cmd_tag_o(),
    .tensor_cmd_o(),.tensor_operand_o(),.tensor_pair_o(),.tensor_class_o(),
    .tensor_terminal_valid_i(1'b0),.tensor_terminal_ready_o(),.tensor_terminal_tag_i(9'b0),
    .tensor_error_i(1'b0),.tensor_error_code_i(8'b0),.irrevocable_o(),.reuse_block_o(),.idle_o());
  task reserve_one;
    input integer lane;input [8:0] tagno;input [7:0] fn;input [4:0] amo;
    begin
      @(negedge clk);rwant=2'b1<<lane;rtag=0;rfunc=0;ramo=0;
      rtag[lane*9+:9]=tagno;rfunc[lane*8+:8]=fn;ramo[lane*5+:5]=amo;
      #1;if(!rready[lane])$fatal(1,"reserve_one no credit");
      saved_slot[tagno[4:0]]=rslot[lane*IW+:IW];rfire=2'b1<<lane;
      @(negedge clk);rfire=0;rwant=0;
    end
  endtask
  task bind_one;
    input integer lane;input [8:0] tagno;input [63:0] addr,data;
    input [7:0] fn;input [4:0] amo;input [63:0] answer;
    begin
      @(negedge clk);in_fire=2'b1<<lane;in_tag=0;in_uop=0;operand=0;bslot=0;
      in_tag[lane*9+:9]=tagno;bslot[lane*IW+:IW]=saved_slot[tagno[4:0]];
      in_uop[lane*`R64_UOP_W+196+:8]=fn;in_uop[lane*`R64_UOP_W+155+:5]=amo;
      operand[lane*192+:64]=addr;operand[lane*192+64+:64]=data;
      full_tag[tagno[4:0]]=tagno;active[tagno[4:0]]=1;received[tagno[4:0]]=0;
      killed[tagno[4:0]]=0;expected[tagno[4:0]]=answer;expectfault[tagno[4:0]]=0;
      expectcause[tagno[4:0]]=0;expecttval[tagno[4:0]]=addr;
      @(negedge clk);in_fire=0;
    end
  endtask
  task wait_result;
    input [4:0] slotno;integer budget;
    begin
      budget=0;while(!received[slotno]&&budget<200)begin @(negedge clk);budget=budget+1;end
      if(!received[slotno])$fatal(1,"missing result %0d reuse%h",slotno,reuse);
    end
  endtask
  task retire;
    input [8:0] tagno;
    begin @(negedge clk);commit_fire=1;commit_tag={9'b0,tagno};
      @(negedge clk);commit_fire=0;active[tagno[4:0]]=0;end
  endtask
  task clear_all;
    begin @(negedge clk);flush=1;active=0;received=0;
      @(negedge clk);flush=0;kill=0;
      repeat(4)@(negedge clk);
      if(!idle)$fatal(1,"nonissued clear retained owner");
    end
  endtask
  integer n,before_mem,before_tr,budget;reg [IW-1:0] oldslot;
  initial begin
    for(n=0;n<1024;n=n+1)memory[n]=64'h1234567880000000+n;
    for(n=0;n<2;n=n+1)begin th[n]=0;tt[n]=0;tn[n]=0;mh[n]=0;mt[n]=0;mn[n]=0;end
    repeat(4)@(negedge clk);rst=0;no_external=1;
    rwant=3;repeat(8)@(negedge clk);
    if(reuse!=0||rready!=3||rslot[0+:IW]==rslot[IW+:IW])$fatal(1,"empty want contract");
    rwant=0;
    for(n=0;n<DEPTH-2;n=n+2)begin
      @(negedge clk);rwant=3;rtag={9'(n+1),9'(n)};rfunc=16'h0303;ramo=0;#1;
      if(rready!=3)$fatal(1,"dual reserve lost capacity");
      saved_slot[n]=rslot[0+:IW];saved_slot[n+1]=rslot[IW+:IW];rfire=3;
      @(negedge clk);rfire=0;rwant=0;
    end
    reserve_one(1,9'(DEPTH-2),8'h03,0);
    rwant=3;#1;if(rready!=1)$fatal(1,"one-free prefix");
    rwant=0;reserve_one(0,9'(DEPTH-1),8'h03,0);
    for(n=0;n<4;n=n+1)begin
      rwant=2'(n);#1;if(rready!==~rwant)$fatal(1,"full queue want mask");
    end
    rwant=0;repeat(10)@(negedge clk);
    if(reuse!=(32'hffffffff>>(32-DEPTH))||dut.bound_q!=0)$fatal(1,"unbound owner not retained");
    clear_all();
    // Actual head-authorized Serial must drain preceding execution while
    // future unbound MEM reservations retain full owner/reuse identity.
    head_tag=256;serial_tag=256;no_external=1;
    reserve_one(0,257,8'h03,0);reserve_one(1,258,8'h23,0);
    if(idle||!drained||reuse[2:1]!=3)$fatal(1,"owner idle and serial drain conflated");
    for(n=0;n<3;n=n+1)begin
      @(negedge clk);
      serial_raw=n==0?64'h0000000f:(n==1?64'h0000100f:64'h12000073);
      if(!serial_ready)$fatal(1,"Serial did not release previous fence");
      serial_fire=1;@(negedge clk);serial_fire=0;budget=0;
      while(!serial_valid&&budget<30)begin @(negedge clk);budget=budget+1;end
      if(!serial_valid||serial_result_tag!=256||serial_result[64])
        $fatal(1,"head fence deadlocked behind younger unbound reservation");
      repeat(4)begin @(negedge clk);if(!serial_valid||idle||!drained)
        $fatal(1,"fence result/drain changed under terminal backpressure");end
      serial_ready_result=1;@(negedge clk);serial_ready_result=0;
      @(negedge clk);serial_commit=1;@(negedge clk);serial_commit=0;
    end
    clear_all();head_tag=0;
    reserve_one(0,0,8'h03,0);oldslot=saved_slot[0];
    @(negedge clk);kill=1;in_fire=1;in_tag=0;bslot={{IW{1'b0}},oldslot};
    in_uop=0;in_uop[196+:8]=8'h03;operand=0;
    @(negedge clk);in_fire=0;kill=0;
    repeat(2)@(negedge clk);if(reuse!=0)$fatal(1,"cancelled unbound retained");
    head_tag=32;reserve_one(1,32,8'h03,0);
    if(saved_slot[0]!=oldslot)$fatal(1,"fixture did not reuse same slot");
    @(negedge clk);in_fire=1;in_tag=0;bslot={{IW{1'b0}},oldslot};
    @(negedge clk);in_fire=0;
    if(dut.bound_q[oldslot]||dut.tag_q[oldslot]!=32)$fatal(1,"old generation bind mutated replacement");
    no_external=0;bind_one(1,32,64'h80,0,8'h03,0,memory[16]);wait_result(0);
    clear_all();
    head_tag=64;head_valid=0;effect_allow=0;
    reserve_one(0,64,8'h23,0);reserve_one(1,65,8'h03,0);
    before_mem=memcount;bind_one(1,65,64'h1080,0,8'h03,0,64'hfeedbeef);
    repeat(35)@(negedge clk);
    if(memcount!=before_mem||received[1])$fatal(1,"young load crossed unbound store");
    bind_one(0,64,64'h80,64'hfeedbeef,8'h23,0,0);
    wait_result(1);
    if(memcount!=before_mem)$fatal(1,"forwarding emitted memory request");
    head_valid=1;effect_allow=1;wait_result(0);retire(64);head_tag=65;
    if(memory[16]!=64'hfeedbeef)$fatal(1,"store visibility lost");
    clear_all();
    head_tag=96;reserve_one(0,96,8'h03,0);reserve_one(0,97,8'h03,0);
    before_mem=memcount;bind_one(0,97,64'h88,0,8'h03,0,memory[17]);
    repeat(35)@(negedge clk);
    if(memcount!=before_mem||received[1])$fatal(1,"translation bypass crossed unknown IO");
    @(negedge clk);kill=1;@(negedge clk);kill=0;head_tag=97;
    wait_result(1);clear_all();
    head_tag=128;reserve_one(0,128,8'h03,0);oldslot=saved_slot[0];
    tr_delay=45;before_mem=memcount;before_tr=trcount;
    bind_one(0,128,64'h90,0,8'h03,0,memory[18]);
    budget=0;while(trcount==before_tr&&budget<30)begin @(negedge clk);budget=budget+1;end
    if(trcount==before_tr)$fatal(1,"no accepted translation");
    @(negedge clk);kill=1;killed[0]=1;
    @(negedge clk);kill=0;head_tag=129;serial_tag=129;
    serial_raw=64'h0000000f;serial_fire=1;
    @(negedge clk);serial_fire=0;
    repeat(12)@(negedge clk);
    if(serial_valid)$fatal(1,"fence ignored accepted cancelled translation");
    if(!reuse[0]||dut.state_q[oldslot]!=2||drained)$fatal(1,"cancelled translation owner released early");
    budget=0;while(!idle&&budget<90)begin @(negedge clk);budget=budget+1;end
    if(!idle||memcount!=before_mem||received[0])$fatal(1,"cancelled translation failed drain");
    budget=0;
    while(!serial_valid&&budget<30)begin @(negedge clk);budget=budget+1;end
    if(!serial_valid||serial_result[64])$fatal(1,"fence did not release after real drain");
    serial_ready_result=1;@(negedge clk);serial_ready_result=0;
    @(negedge clk);serial_commit=1;@(negedge clk);serial_commit=0;
    active=0;killed=0;tr_delay=2;
    // Two existing owners bind together while a third younger dispatch
    // owner is reserved. The younger unknown owner must not block their loads.
    head_tag=224;reserve_one(0,224,8'h03,0);reserve_one(1,225,8'h03,0);
    @(negedge clk);rwant=1;rtag=226;rfunc=16'h0003;ramo=0;#1;
    saved_slot[2]=rslot[0+:IW];rfire=1;in_fire=3;in_tag={9'd225,9'd224};
    bslot={saved_slot[1],saved_slot[0]};in_uop=0;operand=0;
    in_uop[196+:8]=8'h03;in_uop[`R64_UOP_W+196+:8]=8'h03;
    operand[63:0]=64'ha0;operand[192+:64]=64'ha8;
    for(n=0;n<2;n=n+1)begin
      active[n]=1;received[n]=0;killed[n]=0;expectfault[n]=0;
      expected[n]=memory[20+n];full_tag[n]=9'(224+n);
    end
    @(negedge clk);rfire=0;rwant=0;in_fire=0;
    if(!dut.bound_q[saved_slot[0]]||!dut.bound_q[saved_slot[1]]||dut.bound_q[saved_slot[2]])
      $fatal(1,"dual bind and reserve lost distinct owners");
    wait_result(0);wait_result(1);clear_all();
    head_tag=160;trigger_enable=3;trigger_address=64'h100;no_external=1;
    reserve_one(0,160,8'h83,0);repeat(12)@(negedge clk);
    bind_one(0,160,64'h100,1,8'h83,0,0);
    expectfault[0]=1;expectcause[0]=3;expecttval[0]=64'h100;
    wait_result(0);clear_all();trigger_enable=0;no_external=0;
    // A simultaneous old-generation stale bind and new reservation must
    // discard the stale payload without clearing the new dispatch owner.
    head_tag=192;
    @(negedge clk);rwant=1;rtag=192;rfunc=16'h0003;ramo=0;#1;
    oldslot=rslot[0+:IW];saved_slot[0]=oldslot;rfire=1;
    in_fire=1;in_tag=160;bslot={{IW{1'b0}},oldslot};in_uop=0;
    in_uop[196+:8]=8'h03;operand=0;
    @(negedge clk);rfire=0;rwant=0;in_fire=0;
    if(dut.tag_q[oldslot]!=192||dut.bound_q[oldslot])$fatal(1,"stale bind damaged same-edge new reserve");

    if($test$plusargs("bad-class"))begin
      bind_one(0,192,64'h80,0,8'h23,0,0);$fatal(1,"bad class accepted");
    end
    bind_one(0,192,64'h80,0,8'h03,0,memory[16]);
    if($test$plusargs("bad-double-bind"))begin
      bind_one(0,192,64'h80,0,8'h03,0,memory[16]);$fatal(1,"double bind accepted");
    end
    wait_result(0);clear_all();
    $display("[PASS] tb_r64_lsu_reserve matrix reverse-bind alias unknown-IO trigger real-fence kill-drain generation wb=%0d",wbcount);
    $finish;
  end
  initial begin #300000;$fatal(1,"reserve timeout cycles%0d reuse%h received%h",cycles,reuse,received);end
endmodule
