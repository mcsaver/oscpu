`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_lsu_misaligned;
 integer split_blocked_hints=0,split_live_hints=0;
 always @(posedge clk)if(!rst)begin
   if(dut.split.out_request_o!==dut.split.out_valid_o)begin
     split_blocked_hints=split_blocked_hints+1;
     if(dut.split.out_valid_o!=0||(dut.sv&dut.sr)!=0)
       $fatal(1,"split hint escaped blocked actual request");
   end else if(|dut.sv)split_live_hints=split_live_hints+1;
 end
 parameter EARLY_STORE=1;parameter DEPTH=18;localparam IW=$clog2(DEPTH);
  reg clk=0;always #5 clk=~clk;
  reg rst=1,flush=0,translation_active=0;reg [31:0] kill=0;
  reg head_valid=1,effect_allow=1,fp_enable=1;reg [8:0] head_tag=0;
  reg [1:0] commit_fire=0;reg [17:0] commit_tag=0;
  reg [1:0] in_fire=0;wire [1:0] in_ready;
  reg [17:0] in_tag=0;reg [2*`R64_UOP_W-1:0] in_uop=0;reg [383:0] operand=0;
  wire store_valid,store_error;reg store_ready=1;wire [8:0] store_tag;wire [63:0] store_tval;integer fast_completions=0;
  wire [1:0] out_valid;reg [1:0] out_ready=3;
  wire [17:0] out_tag;wire [2*`R64_RESULT_W-1:0] out_result;
  wire [31:0] reuse;wire irreversible,idle;
  wire [1:0] tv,tr,tad,tresp,trespready;wire [127:0] tva,tpa;
  wire [3:0] ta,tc;wire [1:0] tfault,tneeds;wire [9:0] tcause,townersize;wire [5:0] towneraccess;
  wire [1:0] mv,mr,mcache,mresp,mrespready,merror;wire [2*IW-1:0] mtoken,mresptoken;
  wire [127:0] ma,md,mrd;wire [3:0] mop;wire [5:0] msize;wire [15:0] mstrb;wire [9:0] mamo;
  // TB-only front-end: previous stimuli reserve in program order, then
  // bind the captured payload one edge later to the real dispatch-owned LSU.
  reg [1:0] bind_fire_q=0;reg [17:0] bind_tag_q=0;
  reg [2*`R64_UOP_W-1:0] bind_uop_q=0;reg [383:0] bind_operand_q=0;
  reg [2*IW-1:0] bind_slot_q=0;wire [2*IW-1:0] reserve_slot_w;
  always @(posedge clk)begin
    if(rst||flush)bind_fire_q<=0;
    else bind_fire_q<=in_fire;
    if(|in_fire)begin
      bind_tag_q<=in_tag;bind_uop_q<=in_uop;bind_operand_q<=operand;bind_slot_q<=reserve_slot_w;
    end
  end
  R64LoadStore #(.EARLY_STORE(EARLY_STORE),.ENTRIES(DEPTH),.INDEX_W(IW),.CACHE_SET_W(2)) dut(
   .clk_i(clk),.rst_i(rst),.flush_i(flush),.invalidate_i(1'b0),.kill_mask_i(kill),
   .head_valid_i(head_valid),.head_tag_i(head_tag),.effect_allow_i(effect_allow),.trigger_enable_i(3'b0),.trigger_address_i(64'b0),.fp_enable_i(fp_enable),.translate_active_i(translation_active),
   .store_done_valid_o(store_valid),.store_done_ready_i(store_ready),.store_done_tag_o(store_tag),.store_done_error_o(store_error),.store_done_tval_o(store_tval),
   .commit_fire_i(commit_fire),.commit_tag_i(commit_tag),
   .reserve_want_i(2'b11),.reserve_fire_i(in_fire),.reserve_ready_o(in_ready),.reserve_slot_o(reserve_slot_w),
   .reserve_tag_i(in_tag),.reserve_func_i({in_uop[`R64_UOP_W+196+:8],in_uop[196+:8]}),
   .reserve_amo_i({in_uop[`R64_UOP_W+155+:5],in_uop[155+:5]}),
   .in_fire_i(bind_fire_q),.in_ready_o(),.in_tag_i(bind_tag_q),.in_slot_i(bind_slot_q),
   .in_uop_i(bind_uop_q),.in_operand_i(bind_operand_q),
   .out_valid_o(out_valid),.out_ready_i(out_ready),.out_tag_o(out_tag),.out_result_o(out_result),
   .reuse_block_o(reuse),.irrevocable_o(irreversible),.idle_o(idle),
   .tr_valid_o(tv),.tr_ready_i(tr),.tr_vaddr_o(tva),.tr_access_o(ta),.tr_ad_update_o(tad),
   .tr_rsp_valid_i(tresp),.tr_rsp_ready_o(trespready),.tr_paddr_i(tpa),.tr_class_i(tc),
   .tr_fault_i(tfault),.tr_needs_ad_i(tneeds),.tr_cause_i(tcause),
   .tr_owner_access_o(towneraccess),.tr_owner_size_o(townersize),
   .aux_valid_i(4'b0),.aux_ready_o(),.aux_addr_i(256'b0),.aux_data_i(256'b0),.aux_expected_i(256'b0),
   .aux_op_i(8'b0),.aux_cache_i(4'b0),.aux_size_i(12'b0),.aux_strb_i(32'b0),
   .aux_rsp_valid_o(),.aux_rsp_ready_i(4'b1111),.aux_rsp_data_o(),.aux_rsp_error_o(),.aux_rsp_compare_o(),
   .read_valid_o(rv),.read_ready_i(rr),.read_addr_o(ra),.read_len_o(rl),.read_size_o(rz),
   .beat_valid_i(bv),.beat_ready_o(br),.beat_data_i(bd),.beat_resp_i((read_fault&&read_request_address==read_fault_address)?2'b10:2'b00),.beat_last_i(left==1),
   .write_valid_o(wv),.write_ready_i(wr),.write_addr_o(wa),.write_size_o(wz),
   .write_data_valid_o(wdv),.write_data_ready_i(wdr),.write_data_o(wd),.write_strb_o(ws),
   .write_rsp_valid_i(bvalid),.write_rsp_ready_o(bready),.write_resp_i(bresp));
  wire rv,rr,bv,br,wv,wr,wdv,wdr,bready;wire [63:0] ra,wa,wd,bd;wire [7:0] rl,ws;wire [2:0] rz,wz;
  reg reading=0,aw=0,ww=0,bvalid=0;
  reg read_fault=0,write_fault=0;reg [63:0] read_fault_address=0,write_fault_address=0;
  reg [63:0] read_request_address=0,write_request_address=0;integer write_txns=0;reg [1:0] bresp=0;
  integer ri=0,left=0,wi=0,read_due=0,read_txns=0;
  reg [63:0] wdata;reg [7:0] wstrb;
  assign rr=!reading;assign bv=reading&&cycles>=read_due;assign bd=memory[ri];
  assign wr=!aw&&!bvalid&&rng[8];assign wdr=!ww&&!bvalid&&rng[9];
  assign mv=dut.mv;assign mr=dut.mr;
  always @(posedge clk)if(!rst)begin
    if(bv&&br)begin ri<=ri+1;left<=left-1;if(left==1)reading<=0;end
    if(rv&&rr)begin reading<=1;read_request_address<=ra;ri<=ra>>3;left<=rl+1;read_due<=cycles+mem_delay;read_txns=read_txns+1;end
    if(wv&&wr)begin aw=1;wi=wa>>3;write_request_address=wa;write_txns=write_txns+1;end
    if(wdv&&wdr)begin ww=1;wdata=wd;wstrb=ws;end
    if(aw&&ww&&!bvalid)begin
      bvalid<=1;bresp<=(write_fault&&write_request_address==write_fault_address)?2:0;
      if(!(write_fault&&write_request_address==write_fault_address))for(integer byte_n=0;byte_n<8;byte_n=byte_n+1)
        if(wstrb[byte_n])memory[wi][8*byte_n+:8]=wdata[8*byte_n+:8];
    end
    if(bvalid&&bready)begin aw=0;ww=0;bvalid<=0;end
  end
  reg [63:0] memory[0:8191],expected[0:31];reg [31:0] active=0,killed=0,received=0;
  reg [31:0] expectfault=0;reg [5:0] expectcause[0:31];reg [63:0] expecttval[0:31];
  reg [63:0] tqueue[0:15];reg [1:0] taqueue[0:15];reg adqueue[0:15];
  integer tdue[0:15],th[0:1],tt[0:1],tn[0:1];
  reg [IW-1:0] mqtoken[0:15];reg [63:0] mqdata[0:15];
  reg mqerror[0:15];integer mdue[0:15],mh[0:1],mt[0:1],mn[0:1];
  integer cycles=0,trcount=0,memcount=0,wbcount=0,dual=0,adupdates=0;
  integer tr_delay=2,mem_delay=3;
  reg tr_hold=0,mem_hold=0,error_write=0;
  reg [31:0] rng=32'h947312bd;reg random_stall=0;
  genvar g;
  generate for(g=0;g<2;g=g+1)begin:gen_model
    assign tr[g]=tn[g]<7&&!tr_hold&&(!random_stall||rng[g]);
    assign tresp[g]=tn[g]!=0&&tdue[g*8+th[g]]<=cycles&&!tr_hold;
    assign tpa[g*64+:64]=translation_active?(tqueue[g*8+th[g]]&~64'h1000):tqueue[g*8+th[g]];
    assign tc[g*2+:2]=tqueue[g*8+th[g]][15:12]==6?2'd2:(tqueue[g*8+th[g]][15:12]==5?2'd1:2'd0);
    assign tfault[g]=0;
    assign tneeds[g]=0;
    assign tcause[g*5+:5]=taqueue[g*8+th[g]]==2?5'd15:5'd13;
  end endgenerate
  integer a,b,tag,index,j,slot;
  reg [63:0] response_data;
  always @(posedge clk)if(!rst)begin
    cycles=cycles+1;rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
    for(a=0;a<2;a=a+1)begin
      // Queue outputs must remain the accepted owner through the sampling edge.
      tn[a]<=tn[a]+((tv[a]&&tr[a])?1:0)-((tresp[a]&&trespready[a])?1:0);
      if(tresp[a]&&trespready[a])th[a]<=(th[a]+1)%8;
      if(tv[a]&&tr[a])begin
        tqueue[a*8+tt[a]]=tva[a*64+:64];taqueue[a*8+tt[a]]=ta[a*2+:2];adqueue[a*8+tt[a]]=tad[a];
        tdue[a*8+tt[a]]=cycles+tr_delay;tt[a]<=(tt[a]+1)%8;trcount=trcount+1;
        if(tad[a]&&ta[a*2+:2]==2)adupdates=adupdates+1;
      end
      if(mv[a]&&mr[a])memcount=memcount+1;
      if(out_valid[a]&&out_ready[a])begin
        tag=out_tag[a*9+:5];
        if(!active[tag]||killed[tag]||received[tag])$fatal(1,"invalid completion tag %0d active%h killed%h received%h",tag,active,killed,received);
        if(out_result[a*`R64_RESULT_W+64]!==expectfault[tag]||
          (!expectfault[tag]&&out_result[a*`R64_RESULT_W+:64]!==expected[tag])||
          (expectfault[tag]&&(out_result[a*`R64_RESULT_W+65+:6]!==expectcause[tag]||
            out_result[a*`R64_RESULT_W+71+:64]!==expecttval[tag])))
          $fatal(1,"bad result tag%0d value%h expected%h exception%b",tag,out_result[a*`R64_RESULT_W+:64],expected[tag],out_result[a*`R64_RESULT_W+64]);
        received[tag]=1;wbcount=wbcount+1;
      end
    end
    if(store_valid&&store_ready)begin
      tag=store_tag[4:0];
      if(!active[tag]||killed[tag]||received[tag]||store_tag!=head_tag)
        $fatal(1,"invalid narrow store completion tag%0d",store_tag);
      if(store_error!==expectfault[tag]||(!store_error&&expected[tag]!=0)||
        (store_error&&(expectcause[tag]!=7||store_tval!==expecttval[tag])))
        $fatal(1,"narrow store completion payload tag%0d",store_tag);
      received[tag]=1;wbcount=wbcount+1;fast_completions=fast_completions+1;
    end
    if(out_valid==3&&out_ready==3)dual=dual+1;
  end
  task enqueue;
    input [8:0] tagno;input [63:0] addr,data;input [7:0] fn;input [4:0] amo;
    input [63:0] answer;input fault;input [5:0] cause;
    begin
      @(negedge clk);while(!in_ready[0])@(negedge clk);
      in_fire=1;in_tag={9'b0,tagno};in_uop=0;operand=0;
      in_uop[196+:8]=fn;in_uop[155+:5]=amo;operand[63:0]=addr;operand[64+:64]=data;
      active[tagno[4:0]]=1;received[tagno[4:0]]=0;killed[tagno[4:0]]=0;
      expected[tagno[4:0]]=answer;expectfault[tagno[4:0]]=fault;
      expectcause[tagno[4:0]]=cause;expecttval[tagno[4:0]]=addr;
      @(negedge clk);in_fire=0;
    end
  endtask
  task wait_result;
    input [4:0] tagno;
    begin while(!received[tagno])@(negedge clk);end
  endtask
  task retire;
    input [8:0] tagno;
    begin @(negedge clk);commit_fire=1;commit_tag={9'b0,tagno};@(negedge clk);commit_fire=0;active[tagno[4:0]]=0;end
  endtask

  reg [7:0] golden[0:65535];
  integer n,serial=0,before_mem,before_tr,before_writes,size,offset,rounds,bytes_count,check_index;
  reg [63:0] address,value,answer,pa;
  function [63:0] physical;
    input [63:0] va;
    begin physical=translation_active?(va&~64'h1000):va;end
  endfunction
  function [63:0] gather;
    input [63:0] addr;input integer bytes;
    integer k;
    begin gather=0;for(k=0;k<bytes;k=k+1)gather[k*8+:8]=golden[addr+k];end
  endfunction
  task check_memory;
    input [63:0] address;
    integer k,start;
    begin
      start=(address/64)*64;
      for(k=start;k<start+128;k=k+1)
        if(memory[k/8][(k%8)*8+:8]!==golden[k])$fatal(1,"memory footprint corruption byte%h actual%h expected%h",k,memory[k/8][(k%8)*8+:8],golden[k]);
    end
  endtask
  task execute;
    input [63:0] addr,data;input [7:0] fn;input [4:0] amo;
    input [63:0] result;input fault;input [5:0] cause;input [63:0] tval;
    integer slot;
    begin
      slot=serial%32;head_tag=serial[8:0];
      enqueue(serial[8:0],addr,data,fn,amo,result,fault,cause);expecttval[slot]=tval;
      wait_result(slot[4:0]);
      if(fault)begin
        @(negedge clk);flush=1;@(negedge clk);flush=0;
      end
      retire(serial[8:0]);serial=serial+1;
    end
  endtask
  initial begin
    for(n=0;n<65536;n=n+1)golden[n]=(n*29+137)%256;
    for(n=0;n<8192;n=n+1)for(j=0;j<8;j=j+1)memory[n][j*8+:8]=golden[n*8+j];
    for(n=0;n<2;n=n+1)begin th[n]=0;tt[n]=0;tn[n]=0;mh[n]=0;mt[n]=0;mn[n]=0;end
    repeat(4)@(negedge clk);rst=0;
    // All offsets for 16/32/64-bit accesses: ordinary cached and NC RAM,
    // including 8B/64B boundaries; independent byte golden checks footprint.
    for(rounds=0;rounds<2;rounds=rounds+1)
      for(size=1;size<=3;size=size+1)for(offset=1;offset<8;offset=offset+1)begin
        address=(rounds==0?64'h38:64'h5038)+offset;bytes_count=1<<size;
        answer=gather(address,bytes_count);
        execute(address,0,size==3?8'h03:(8'h04+size[7:0]),0,answer,0,0,0);
        value=64'hfedcba9876543210^(serial*64'h112233);
        for(n=0;n<bytes_count;n=n+1)golden[address+n]=value[n*8+:8];
        execute(address,value,8'h20+size[7:0],0,0,0,0,0);
        check_memory(address);
        answer=gather(address,bytes_count);
        if(size==1)answer={{48{answer[15]}},answer[15:0]};
        if(size==2)answer={{32{answer[31]}},answer[31:0]};
        execute(address,0,size[7:0],0,answer,0,0,0);
      end
    // FSD/FLD and FSW/FLW preserve payload and NaN-box the 32-bit load.
    address=64'h83f;value=64'hc123456789abcdef;
    for(n=0;n<8;n=n+1)golden[address+n]=value[n*8+:8];
    execute(address,value,8'h63,0,0,0,0,0);execute(address,0,8'h43,0,value,0,0,0);
    address=64'h87f;value=64'h87654321;
    for(n=0;n<4;n=n+1)golden[address+n]=value[n*8+:8];
    execute(address,value,8'h62,0,0,0,0,0);execute(address,0,8'h42,0,64'hffffffff87654321,0,0,0);
    // Bare cross-page is legal after full-range protection; translated is not.
    address=64'hffe;value=64'h1122334455667788;
    for(n=0;n<8;n=n+1)golden[address+n]=value[n*8+:8];
    execute(address,value,8'h23,0,0,0,0,0);execute(address,0,8'h03,0,value,0,0,0);
    translation_active=1;before_tr=trcount;before_mem=memcount;
    execute(address,0,8'h03,0,0,1,4,address);
    execute(address,0,8'h23,0,0,1,6,address);
    if(trcount!=before_tr||memcount!=before_mem)$fatal(1,"translated page-cross escaped early rejection");
    // Same-page translated access uses the one translated contiguous range.
    address=64'h1187;pa=physical(address);answer=gather(pa,8);
    execute(address,0,8'h03,0,answer,0,0,0);translation_active=0;
    // IO and all atomics remain precise non-splitting exceptions.
    before_mem=memcount;execute(64'h6003,0,8'h03,0,0,1,4,64'h6003);
    execute(64'h6003,1,8'h23,0,0,1,6,64'h6003);
    execute(64'h83,0,8'ha3,2,0,1,4,64'h83);
    execute(64'h83,1,8'ha3,0,0,1,6,64'h83);
    if(memcount!=before_mem)$fatal(1,"IO/atomic misalign reached memory");
    // Later byte B error: exact error VA, earlier successful bytes remain,
    // no bytes after the first error may be issued or modified.
    address=64'h53f;value=64'hcafebabedeadbeef;before_writes=write_txns;
    write_fault=1;write_fault_address=address+3;
    for(n=0;n<3;n=n+1)golden[address+n]=value[n*8+:8];
    execute(address,value,8'h23,0,0,1,7,address+3);write_fault=0;
    check_memory(address);
    if(write_txns!=before_writes+4)$fatal(1,"split store continued after B error");
    // NC read error at fragment 5 must report base+5 and stop further bytes.
    address=64'h507d;read_fault=1;read_fault_address=address+5;before_writes=read_txns;
    execute(address,0,8'h03,0,0,1,5,address+5);read_fault=0;
    if(read_txns!=before_writes+6)$fatal(1,"split read continued after error");
    // A split store crossing two words cannot falsely forward its truncated
    // first-word mask into a younger aligned load; the barrier lasts to commit.
    address=64'h8bf;value=64'h123456789abcdef0;before_mem=memcount;head_tag=serial[8:0]-1'b1;
    for(n=0;n<8;n=n+1)golden[address+n]=value[n*8+:8];
    enqueue(serial[8:0],address,value,8'h23,0,0,0,0);
    enqueue(serial[8:0]+1'b1,64'h8c0,0,8'h03,0,gather(64'h8c0,8),0,0);
    repeat(20)@(negedge clk);
    if(memcount!=before_mem)$fatal(1,"split store/read escaped head barrier");
    head_tag=serial[8:0];wait_result(serial%32);
    if(!irreversible)$fatal(1,"split store lost irreversible retirement owner");
    repeat(12)@(negedge clk);
    if(received[(serial+1)%32])$fatal(1,"younger load bypassed split store before commit");
    retire(serial[8:0]);serial=serial+1;head_tag=serial[8:0];
    wait_result(serial%32);retire(serial[8:0]);serial=serial+1;check_memory(address);
    // Accepted killed split load drains all held transactions and never WB.
    address=64'h509f;head_tag=serial[8:0];before_mem=memcount;mem_delay=20;
    enqueue(serial[8:0],address,0,8'h03,0,gather(address,8),0,0);
    wait(memcount>before_mem);@(negedge clk);kill=32'b1<<(serial%32);killed=kill;
    @(negedge clk);kill=0;
    if(!reuse[serial%32])$fatal(1,"split owner freed before drain");
    while(reuse[serial%32])@(negedge clk);
    if(received[serial%32])$fatal(1,"killed split load wrote back");
    active[serial%32]=0;mem_delay=3;
    repeat(3)@(negedge clk);if(!idle)$fatal(1,"split owner leak");
    if(split_blocked_hints==0||split_live_hints==0||dut.service.CPU_REQUEST_HINTS!=1)
      $fatal(1,"split request hint coverage missing");
    $display("SPLIT_REQUEST_HINT blocked=%0d live=%0d",split_blocked_hints,split_live_hints);
    $display("[PASS] tb_r64_lsu_misaligned completed=%0d fragment_writes=%0d read_transactions=%0d",wbcount,write_txns,read_txns);
    $finish;
  end
  initial begin #10000000;$fatal(1,"timeout serial%0d cycles%0d reuse%h",serial,cycles,reuse);end
endmodule
