`timescale 1ns/1ps
module tb_r64_dcache_overlap;
  reg clk=0;always #5 clk=~clk;
  reg rst=1,invalidate=0,reservation_clear=0;
  reg [1:0] req_valid=0;wire [1:0] req_ready;
  reg [11:0] req_token=0;reg [127:0] req_addr=0,req_data=0,req_expected=0;
  reg [3:0] req_op=0;reg [1:0] req_cache=3;reg [5:0] req_size={3'd3,3'd3};
  reg [15:0] req_strb=16'hffff;reg [9:0] req_amo=0;
  wire [1:0] rsp_valid,rsp_error,rsp_compare;reg [1:0] rsp_ready=3;
  wire [11:0] rsp_token;wire [127:0] rsp_data;
  wire rv,rr,br;wire [63:0] ra;wire [7:0] rl;wire [2:0] rs;
  reg bv=0;reg [63:0] bd=0;reg [1:0] be=0;reg bl=0;
  wire wv,wdv,wr,wdready,bready;wire [63:0] wa,wd;wire [7:0] ws;wire [2:0] wz;
  reg bvalid=0;reg [1:0] bresp=0;
  wire idle,mutation;wire [60:0] mutationword;
  R64Dcache #(.SET_W(6)) dut(
    .clk_i(clk),.rst_i(rst),.invalidate_i(invalidate),.reservation_clear_i(reservation_clear),
    .req_fast_store_i(2'b0),.store_rsp_valid_o(),.store_rsp_ready_i(1'b1),.store_rsp_token_o(),.store_rsp_error_o(),
    .req_valid_i(req_valid),.req_ready_o(req_ready),.req_token_i(req_token),.req_addr_i(req_addr),
    .req_op_i(req_op),.req_cache_i(req_cache),.req_size_i(req_size),.req_data_i(req_data),
    .req_expected_i(req_expected),.req_strb_i(req_strb),.req_amo_i(req_amo),
    .rsp_valid_o(rsp_valid),.rsp_ready_i(rsp_ready),.rsp_token_o(rsp_token),.rsp_data_o(rsp_data),
    .rsp_error_o(rsp_error),.rsp_compare_o(rsp_compare),
    .read_valid_o(rv),.read_ready_i(rr),.read_addr_o(ra),.read_len_o(rl),.read_size_o(rs),
    .beat_valid_i(bv),.beat_ready_o(br),.beat_data_i(bd),.beat_resp_i(be),.beat_last_i(bl),
    .write_valid_o(wv),.write_ready_i(wr),.write_addr_o(wa),.write_size_o(wz),
    .write_data_valid_o(wdv),.write_data_ready_i(wdready),.write_data_o(wd),.write_strb_o(ws),
    .write_rsp_valid_i(bvalid),.write_rsp_ready_o(bready),.write_resp_i(bresp),
    .idle_o(idle),.mutation_o(mutation),.mutation_word_o(mutationword));
  reg [63:0] memory[0:2047];
  reg [63:0] expected[0:63];reg [63:0] live=0,expect_error=0,expect_compare=0;
  reg force_read_error=0,force_write_error=0,random_stall=1;
  reg [31:0] rng=32'h39b4e921;
  reg reading=0,readerror=0; reg read_pause=0;reg [63:0] done=0;
  integer readindex=0,readleft=0,readbeat=0;
  reg awseen=0,wseen=0,writeerror=0;
  integer writeindex=0,bdelay=0;
  reg [63:0] writedata;reg [7:0] writestrb;
  integer accepts=0,returns=0,readcmds=0,writecmds=0,dual=0,cycles=0,stalls=0;
  integer k,t,n,j,before_reads,operation;
  reg [4:0] atomic_op[0:8];reg [63:0] atomic_answer[0:8];reg [31:0] word_answer[0:8];
  reg [1:0] admitted;
  assign rr=!reading&&(!random_stall||rng[0]);
  assign wr=!awseen&&!bvalid&&(!random_stall||rng[1]);
  assign wdready=!wseen&&!bvalid&&(!random_stall||rng[2]);
  always @(negedge clk)begin
    if(!rst)begin
      rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
      rsp_ready=random_stall?{rng[3]|rng[4],rng[5]|rng[6]}:3;
      if(!bv||br)begin
        bv=reading&&!read_pause&&(!random_stall||rng[7]);
        bd=memory[readindex];be=readerror&&readbeat==1?2'b10:0;
        // Single beat errors must also be observable.
        if(readerror&&readleft==1)be=2;
        bl=readleft==1;
      end
    end
  end
  always @(posedge clk)if(!rst)begin
    cycles=cycles+1;
    if(rv&&rr)begin reading=1;readindex=ra>>3;readleft=rl+1;readbeat=0;readerror=force_read_error;readcmds=readcmds+1;end
    if(bv&&br)begin readindex=readindex+1;readleft=readleft-1;readbeat=readbeat+1;if(readleft==0)reading=0;end
    if(wv&&wr)begin awseen=1;writeindex=wa>>3;writeerror=force_write_error;writecmds=writecmds+1;end
    if(wdv&&wdready)begin wseen=1;writedata=wd;writestrb=ws;end
    if(awseen&&wseen&&!bvalid)begin
      bdelay=bdelay+1;
      if(bdelay==4)begin
        bvalid<=1;bresp<=writeerror?2:0;
        if(!writeerror)for(j=0;j<8;j=j+1)if(writestrb[j])memory[writeindex][8*j+:8]=writedata[8*j+:8];
      end
    end
    if(bvalid&&bready)begin bvalid<=0;awseen=0;wseen=0;bdelay=0;end
    if((req_valid&req_ready)==3)dual=dual+1;
    if((req_valid&~req_ready)!=0)stalls=stalls+1;
    for(k=0;k<2;k=k+1)begin
      if(rsp_valid[k]&&rsp_ready[k])begin
        t=rsp_token[k*6+:6];
        if(!live[t])$fatal(1,"response without token");
        if(rsp_error[k]!==expect_error[t]||rsp_compare[k]!==expect_compare[t]||
          (!rsp_error[k]&&rsp_data[k*64+:64]!==expected[t]))
          $fatal(1,"response token %0d data %h expected %h error %b/%b compare %b/%b",
           t,rsp_data[k*64+:64],expected[t],rsp_error[k],expect_error[t],rsp_compare[k],expect_compare[t]);
        live[t]=0;done[t]=1;returns=returns+1;
      end
      if(req_valid[k]&&req_ready[k])begin
        t=req_token[k*6+:6];if(live[t])$fatal(1,"token reused");
        live[t]=1;done[t]=0;accepts=accepts+1;
      end
    end
  end
  task command;
    input [63:0] addr;input [1:0] op;input cache;input [63:0] data,cmp,answer;
    input [7:0] strb;input [4:0] amo;input [2:0] size;input error,compare;
    begin
      @(negedge clk);req_valid=1;req_addr={64'b0,addr};req_op={2'b0,op};req_cache={1'b1,cache};
      req_data={64'b0,data};req_expected={64'b0,cmp};req_strb={8'hff,strb};req_amo={5'b0,amo};
      req_size={3'd3,size};req_token=0;expected[0]=answer;expect_error[0]=error;expect_compare[0]=compare;
      do @(posedge clk);while(!req_ready[0]);
      @(negedge clk);req_valid=0;
      while(live!=0)@(negedge clk);
    end
  endtask

  integer mode,waited,accepted_early,returned_early,cmd_before;
  reg baseline=0;reg [63:0] cold_addr,other_addr;
  initial begin
    baseline=$test$plusargs("baseline");random_stall=0;
    for(n=0;n<2048;n=n+1)memory[n]=64'h1234000000000000+n;
    repeat(4)@(negedge clk);rst=0;
    for(mode=0;mode<5;mode=mode+1)begin
      command(72,0,1,0,0,memory[9],255,0,3,0,0);
      cold_addr=mode==1?64'h1040:64'h800+64'(mode*128);
      other_addr=mode==2?64'h388:64'd72;
      @(negedge clk);read_pause=1;done=0;cmd_before=readcmds;
      req_valid=1;req_addr={64'b0,cold_addr};req_token=10;req_op=0;req_cache=3;
      expected[10]=memory[cold_addr>>3];expect_error=0;expect_compare=0;
      do @(posedge clk);while(!req_ready[0]);
      @(negedge clk);req_valid=0;
      while(dut.state_q!=2)@(negedge clk);
      if(mode==3)begin invalidate=1;@(negedge clk);invalidate=0;end
      @(negedge clk);req_valid=1;req_addr={64'b0,other_addr};req_token=11;
      expected[11]=memory[other_addr>>3];accepted_early=0;
      if(mode==4)begin
        // Invalidate after the synchronous lookup has captured the old word,
        // before the hit may publish. A later refill must see the new memory.
        @(posedge clk);
        accepted_early=req_ready[0];
        @(negedge clk);
        if(!baseline&&!accepted_early)$fatal(1,"accepted overlap invalidate fixture missing");
        if(accepted_early)req_valid=0;
        invalidate=1;memory[other_addr>>3]=64'hcafe112233445566;
        expected[11]=memory[other_addr>>3];
        @(negedge clk);invalidate=0;
      end
      repeat(20)begin
        @(posedge clk);if(req_valid[0]&&req_ready[0])accepted_early=1;
        @(negedge clk);if(accepted_early)req_valid=0;
      end
      returned_early=done[11];
      $display("DCACHE_OVERLAP mode=%0d accepted_before_refill=%0d returned_before_refill=%0d",
        mode,accepted_early,returned_early);
      if(!baseline&&mode==0&&(!accepted_early||!returned_early))
        $fatal(1,"independent hit did not pass blocked refill");
      if((mode==1||mode==3)&&accepted_early)$fatal(1,"set/invalidate exclusion violated");
      if((mode==2||mode==4)&&returned_early)$fatal(1,"second miss falsely completed as hit");
      if(readcmds!=cmd_before+1)$fatal(1,"second slow owner issued concurrently");
      read_pause=0;
      if(!accepted_early)begin
        do @(posedge clk);while(!req_ready[0]);
        @(negedge clk);req_valid=0;
      end
      waited=0;while(live!=0&&waited<200)begin @(negedge clk);waited=waited+1;end
      if(live!=0||!done[10]||!done[11])$fatal(1,"overlap response owner did not drain");
    end

    // Lane0 may be present in the same bank but fail the overlap eligibility.
    // The accepted lane1 must then supply every field of the bank owner.
    for(mode=5;mode<8;mode=mode+1)begin
      command(72,0,1,0,0,memory[9],255,0,3,0,0);
      cold_addr=64'hc00+64'((mode-5)*128);
      @(negedge clk);read_pause=1;done=0;
      req_valid=1;req_addr={64'b0,cold_addr};req_token=10;req_op=0;req_cache=3;
      expected[10]=memory[cold_addr>>3];expect_error=0;expect_compare=0;
      do @(posedge clk);while(!req_ready[0]);
      @(negedge clk);req_valid=0;while(dut.state_q!=2)@(negedge clk);
      @(negedge clk);
      other_addr=mode==6?cold_addr+8:64'd88;
      req_valid=3;req_addr={64'd72,other_addr};req_token={6'd11,6'd12};
      req_cache=mode==5?2'b10:2'b11;req_op=mode==7?4'b0001:4'b0000;
      req_data={64'b0,64'habcdef0102030405};expected[11]=memory[9];
      expected[12]=mode==7?64'b0:memory[other_addr>>3];
      accepted_early=0;
      repeat(20)begin
        @(posedge clk);admitted=req_valid&req_ready;
        if(admitted[0])$fatal(1,"ineligible lane0 accepted during read overlap");
        if(admitted[1])accepted_early=1;
        @(negedge clk);req_valid=req_valid&~admitted;
      end
      $display("DCACHE_OVERLAP mode=%0d lane1_accepted=%0d lane1_returned=%0d lane0_held=%0d",
        mode,accepted_early,done[11],req_valid[0]);
      if(!baseline&&(!accepted_early||!done[11]))$fatal(1,"eligible lane1 lost to blocked lane0");
      read_pause=0;
      while(req_valid!=0)begin
        @(posedge clk);admitted=req_valid&req_ready;
        @(negedge clk);req_valid=req_valid&~admitted;
      end
      while(live!=0)@(negedge clk);
      if(!done[10]||!done[11]||!done[12])$fatal(1,"mixed eligibility owner missing");
    end
    $display("[PASS] tb_r64_dcache_overlap full-size hit-under-miss, same-set, second-miss, invalidate before/after accepted lookup");$finish;
  end
  initial begin #100000;$fatal(1,"Dcache overlap timeout");end
endmodule
