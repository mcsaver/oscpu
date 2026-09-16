`timescale 1ns/1ps
module tb_r64_dcache;
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
  R64Dcache #(.SET_W(2)) dut(
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
  reg reading=0,readerror=0;
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
        bv=reading&&(!random_stall||rng[7]);
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
        live[t]=0;returns=returns+1;
      end
      if(req_valid[k]&&req_ready[k])begin
        t=req_token[k*6+:6];if(live[t])$fatal(1,"token reused");
        live[t]=1;accepts=accepts+1;
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
  initial begin
    for(n=0;n<2048;n=n+1)memory[n]=64'h1234000000000000+n;
    repeat(4)@(negedge clk);rst=0;
    // Concurrent cold misses into the same line share the installed fill.
    @(negedge clk);req_valid=3;req_addr={64'd8,64'd0};req_token={6'd1,6'd0};
    expected[0]=memory[0];expected[1]=memory[1];
    @(posedge clk);admitted=req_ready;if(admitted!=3)$fatal(1,"cold bank admission");
    @(negedge clk);req_valid=0;while(live!=0)@(negedge clk);
    if(readcmds!=1)$fatal(1,"same-line cold misses did not share the fill");
    // Both banks are warm after the single 64-byte refill.
    random_stall=0;
    for(n=0;n<200;n=n+1)begin
      @(negedge clk);
      req_valid=3;req_op=0;req_cache=3;req_size={3'd3,3'd3};
      req_addr={64'd8,64'd0};req_token={6'd1,6'd0};
      expected[0]=memory[0];expected[1]=memory[1];expect_error=0;expect_compare=0;
      @(posedge clk);
      if(req_ready!=3)$fatal(1,"warm different-bank load throughput bubble");
      // Token IDs must cover the two pipeline stages.
      @(negedge clk);
      req_token={6'd3,6'd2};
      expected[2]=memory[0];expected[3]=memory[1];
      @(posedge clk);if(req_ready!=3)$fatal(1,"warm hit II violation");
    end
    @(negedge clk);req_valid=0;while(live!=0)@(negedge clk);
    if(readcmds!=1)$fatal(1,"unexpected hot-load miss");
    // Same-bank requests arbitrate, preserving the blocked lane payload.
    @(negedge clk);req_valid=3;req_addr={64'd16,64'd0};req_token={6'd4,6'd0};
    expected[0]=memory[0];expected[4]=memory[2];
    @(posedge clk);admitted=req_ready;
    if(admitted!=1)$fatal(1,"same bank collision did not backpressure lane one");
    @(negedge clk);req_valid=req_valid&~admitted;
    do @(posedge clk);while(!req_ready[1]);
    @(negedge clk);req_valid=0;while(live!=0)@(negedge clk);
    random_stall=1;
    command(0,1,1,64'h99,0,0,255,0,3,0,0);
    command(0,0,1,0,0,64'h99,255,0,3,0,0);
    // Non-cacheable PA alias must update the resident cache too.
    command(0,1,0,64'h101,0,0,255,0,3,0,0);
    command(0,0,1,0,0,64'h101,255,0,3,0,0);
    force_write_error=1;
    command(0,1,1,64'hdead,0,0,255,0,3,1,0);
    force_write_error=0;
    command(0,0,1,0,0,64'h101,255,0,3,0,0);
    command(0,2,1,64'h40,64'h999,64'h101,255,0,3,0,0);
    command(0,2,1,64'h40,64'h101,64'h101,255,0,3,0,1);
    command(0,0,1,0,0,64'h141,255,0,3,0,0);
    command(0,3,1,64'd15,0,64'h141,255,0,3,0,0);
    command(0,0,1,0,0,64'h150,255,0,3,0,0);
    // AMO.W upper half and byte-masked resident store.
    command(4,3,1,64'h8000000100000000,0,64'h150,8'hf0,1,2,0,0);
    command(0,0,1,0,0,64'h8000000100000150,255,0,3,0,0);
    command(2,1,1,64'h0000000000550000,0,0,8'h04,0,0,0,0);
    command(0,0,1,0,0,64'h8000000100550150,255,0,3,0,0);
    // LR/SC is checked at the shared mutation owner, including intervening CAS.
    command(0,3,1,0,0,memory[0],255,2,3,0,0);
    command(0,3,1,64'h7788,0,0,255,3,3,0,0);
    command(0,3,1,64'h9999,0,1,255,3,3,0,0);
    command(0,3,1,0,0,64'h7788,255,2,3,0,0);
    command(0,2,1,64'h10000,64'h7788,64'h7788,255,0,3,0,1);
    command(0,3,1,64'h9999,0,1,255,3,3,0,0);
    command(0,3,1,0,0,memory[0],255,2,3,0,0);
    @(negedge clk);reservation_clear=1;@(negedge clk);reservation_clear=0;
    command(0,3,1,64'h7777,0,1,255,3,3,0,0);
    atomic_op[0]=0;atomic_op[1]=1;atomic_op[2]=4;atomic_op[3]=8;atomic_op[4]=12;
    atomic_op[5]=16;atomic_op[6]=20;atomic_op[7]=24;atomic_op[8]=28;
    atomic_answer[0]=64'hfffffffffffffff8;atomic_answer[1]=64'h7ffffffffffffff3;
    atomic_answer[2]=64'hfffffffffffffff6;atomic_answer[3]=64'hfffffffffffffff7;
    atomic_answer[4]=1;atomic_answer[5]=64'h8000000000000005;atomic_answer[6]=64'h7ffffffffffffff3;
    atomic_answer[7]=64'h7ffffffffffffff3;atomic_answer[8]=64'h8000000000000005;
    word_answer[0]=32'hfffffff4;word_answer[1]=32'h7ffffff3;word_answer[2]=32'hfffffff2;
    word_answer[3]=32'hfffffff3;word_answer[4]=1;word_answer[5]=32'h80000001;
    word_answer[6]=32'h7ffffff3;word_answer[7]=32'h7ffffff3;word_answer[8]=32'h80000001;
    for(operation=0;operation<9;operation=operation+1)begin
      command(0,1,1,64'h8000000000000005,0,0,255,0,3,0,0);
      command(0,3,1,64'h7ffffffffffffff3,0,64'h8000000000000005,255,atomic_op[operation],3,0,0);
      command(0,0,1,0,0,atomic_answer[operation],255,0,3,0,0);
      command(0,1,1,64'h8000000112345678,0,0,255,0,3,0,0);
      command(4,3,1,64'h7ffffff300000000,0,64'h8000000112345678,8'hf0,atomic_op[operation],2,0,0);
      command(0,0,1,0,0,{word_answer[operation],32'h12345678},255,0,3,0,0);
    end
    // Failed replacement cannot leave the old tag naming overwritten data.
    command(256,0,1,0,0,memory[32],255,0,3,0,0);
    force_read_error=1;
    command(512,0,1,0,0,0,255,0,3,1,0);force_read_error=0;
    command(0,0,1,0,0,memory[0],255,0,3,0,0);
    // Invalidation during refill drains the response but forbids resurrection.
    fork
      command(1024,0,1,0,0,memory[128],255,0,3,0,0);
      begin wait(rv&&rr);repeat(2)@(negedge clk);invalidate=1;@(negedge clk);invalidate=0;end
    join
    before_reads=readcmds;
    command(1024,0,1,0,0,memory[128],255,0,3,0,0);
    if(readcmds!=before_reads+1)$fatal(1,"invalidated refill resurrected line");
    command(1032,0,0,0,0,memory[129],255,0,3,0,0);
    if(live!=0||accepts!=returns||writecmds!=45)$fatal(1,"transaction accounting %0d/%0d writes%0d",accepts,returns,writecmds);
    $display("[PASS] tb_r64_dcache accepted=%0d responses=%0d dual=%0d read_txn=%0d write_txn=%0d stalls=%0d warm_cycles=400",accepts,returns,dual,readcmds,writecmds,stalls);
    $finish;
  end
  initial begin #500000;$fatal(1,"timeout");end
endmodule
