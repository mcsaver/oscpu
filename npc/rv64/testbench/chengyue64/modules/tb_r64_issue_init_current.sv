
`timescale 1ns/1ps
// Real scoreboard Q queries, with an independent input-birth/value ledger.
module tb_r64_issue_init_current #(parameter INIT=1, PREPARED=1);
  reg clk=0; always #5 clk=~clk;
  reg rst=1,flush=0; reg [31:0] kill=0;
  reg [4:0] head=0;
  reg [31:0] serial_active=0,serial_release=0;
  reg serial_allow=1;
  reg [1:0] birth=0; wire [1:0] credit;
  reg [17:0] tags=0; reg [9:0] slots=0;
  reg [511:0] payload=0;
  reg [5:0] classes=0,used=0,fp=0; reg [35:0] src=0;
  reg [11:0] dst=0;
  reg [1:0] bw=0,bfp=0;reg [11:0] bp=0;
  reg [1:0] wb=0,wfp=0;reg [11:0] wp=0;
  reg [1:0] early=0,lp=0,rv=0;reg [11:0] ep=0,lpp=0,rp=0;
  reg [5:0] fu=63;reg [1:0] rr=3;
  wire [35:0] qp;wire [5:0] qf,qr;
  wire [1:0] fire;wire [17:0] ot;wire [9:0] os;
  wire [511:0] op;wire [5:0] oc,of,ou,pending;
  wire [11:0] od;wire [35:0] osp;wire [51:0] plan;wire [3:0] count;
  R64Scoreboard scoreboard(
    .batch_apply_i(1'b0),.batch_greclaim_i('0),.batch_freclaim_i('0),
.clk(clk),.rst(rst),.flush_i(flush),
    .birth_write_i(bw),.birth_fp_i(bfp),.birth_preg_i(bp),
    .wb_write_i(wb),.wb_fp_i(wfp),.wb_preg_i(wp),
    .reclaim_write_i(2'b0),.reclaim_fp_i(2'b0),.reclaim_preg_i(12'b0),
    .query_preg_i(qp),.query_fp_i(qf),.query_ready_o(qr));
  R64Issue #(.N(8),.SLOT_W(3),.PAYLOAD_W(256),.DEFER_READY(1),
    .INIT_CURRENT_READY(INIT),.PREPARED_CANCEL(PREPARED),
    .ALU_ISSUE_PROMISE(1),.LOAD_COMPLETION_PROMISE(1),.LOAD_RESOLVED_VALUE(1),
    .MDU_RESOURCE_PAIR(1)) dut(
    .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),
    .cancel_candidates_i(kill),.cancel_active_i(|kill),.rob_head_i(head),
    .barrier_valid_i(1'b0),.barrier_slot_i(5'b0),
    .serial_active_i(serial_active),.serial_release_i(serial_release),
    .enq_valid_i(birth),.enq_ready_o(credit),.enq_tag_i(tags),.enq_mem_slot_i(slots),
    .enq_payload_i(payload),.enq_class_i(classes),.enq_gpr_dst_i(dst),
    .enq_src_preg_i(src),.enq_src_fp_i(fp),.enq_src_used_i(used),.enq_src_ready_i(6'b0),
    .ready_query_preg_o(qp),.ready_query_fp_o(qf),.ready_query_ready_i(qr),
    .wake_valid_i(wb),.wake_fp_i(wfp),.wake_preg_i(wp),
    .early_valid_i(early),.early_preg_i(ep),
    .resolved_value_valid_i(rv),.resolved_value_preg_i(rp),
    .load_promise_i(lp),.load_preg_i(lpp),
    .fu_allow_i(fu),.serial_allow_i(serial_allow),.issue_ready_i(rr),
    .issue_fire_o(fire),.issue_tag_o(ot),.issue_mem_slot_o(os),
    .issue_payload_o(op),.issue_class_o(oc),.issue_gpr_dst_o(od),
    .issue_src_preg_o(osp),.issue_src_fp_o(of),.issue_src_used_o(ou),
    .issue_src_pending_o(pending),.issue_fp_plan_o(plan),.count_o(count));
  integer cycle=0,checks=0,issued=0,init_issued=0;
  reg [63:0] busy_g=0,busy_f=0;
  reg [511:0] born=0,done=0;reg [17:0] source_record[0:511];
  reg [2:0] fp_record[0:511],used_record[0:511],promise_record[0:511];
  integer born_cycle[0:511],fire_cycle[0:511];
  task check(input yes,input [511:0] why);
    begin checks=checks+1;if(yes!==1'b1)$fatal(1,"%0s cycle=%0d",why,cycle);end
  endtask
  function value_event(input [5:0] preg);
    value_event=(rv[0]&&rp[0+:6]==preg)||(rv[1]&&rp[6+:6]==preg);
  endfunction
  function promise_event(input [5:0] preg);
    promise_event=(lp[0]&&lpp[0+:6]==preg)||(lp[1]&&lpp[6+:6]==preg)||value_event(preg)||
       (fire[0]&&oc[0+:3]==0&&od[0+:6]!=0&&od[0+:6]==preg)||
       (fire[1]&&oc[3+:3]==0&&od[6+:6]!=0&&od[6+:6]==preg);
  endfunction
  integer tag,preg;
  always @(posedge clk) begin
    cycle=cycle+1;
    if(rst||flush) begin
      busy_g=0;busy_f=0;born=0;done=0;
      for(integer n=0;n<512;n=n+1)begin
        promise_record[n]=0;born_cycle[n]=-1;fire_cycle[n]=-1;
      end
    end else begin
      for(integer l=0;l<2;l=l+1) if(fire[l])begin
        tag=int'(ot[l*9+:9]);
        check(born[tag]&&!done[tag],"issue must have one accepted birth");
        check(!kill[tag%32],"cancelled initializing row issued");
        check({osp[l*18+:18],of[l*3+:3],ou[l*3+:3]}===
              {source_record[tag],fp_record[tag],used_record[tag]},"issue full source identity");
        for(integer j=0;j<3;j=j+1)if(used_record[tag][j])begin
          preg=int'(source_record[tag][j*6+:6]);
          if(pending[l*3+j])
            check(!fp_record[tag][j] && preg!=0 &&
                  (promise_record[tag][j]||value_event(6'(preg))),
                  "pending issue needs recorded real promise/current notice");
          else check(!(fp_record[tag][j]?busy_f[preg]:busy_g[preg]),
                     "nonpending issue used busy scoreboard source");
        end
        if(cycle-born_cycle[tag]==1)init_issued=init_issued+1;
        fire_cycle[tag]=cycle;done[tag]=1;issued=issued+1;
      end
      // Accepted event ledger uses full birth source, never DUT row or query mux.
      for(integer n=0;n<512;n=n+1)if(born[n])
        for(integer j=0;j<2;j=j+1)
          if(used_record[n][j]&&!fp_record[n][j]&&source_record[n][j*6+:6]!=0&&
             promise_event(source_record[n][j*6+:6]))promise_record[n][j]=1;
      for(integer l=0;l<2;l=l+1)if(birth[l]&&credit[l])begin
        tag=int'(tags[l*9+:9]);born[tag]=1;done[tag]=0;born_cycle[tag]=cycle;
        source_record[tag]=src[l*18+:18];fp_record[tag]=fp[l*3+:3];used_record[tag]=used[l*3+:3];
        promise_record[tag]=0;
        for(integer j=0;j<2;j=j+1)
          if(used[l*3+j]&&!fp[l*3+j]&&src[(l*3+j)*6+:6]!=0&&
             promise_event(src[(l*3+j)*6+:6]))promise_record[tag][j]=1;
      end
      // Model scoreboard priority independently: WB then newer birth.
      for(integer l=0;l<2;l=l+1)if(wb[l])begin
        if(wfp[l])busy_f[wp[l*6+:6]]=0;
        else if(wp[l*6+:6]!=0)busy_g[wp[l*6+:6]]=0;
      end
      for(integer l=0;l<2;l=l+1)if(bw[l])begin
        if(bfp[l])busy_f[bp[l*6+:6]]=1;
        else if(bp[l*6+:6]!=0)busy_g[bp[l*6+:6]]=1;
      end
    end
  end
  task step;begin @(posedge clk);#1;@(negedge clk);end endtask
  task defaults;
    begin birth=0;bw=0;wb=0;early=0;rv=0;lp=0;kill=0;flush=0;
      rr=3;fu=63;classes=0;dst=0;tags=0;src=0;used=0;fp=0;payload=0;
      serial_active=0;serial_release=0;serial_allow=1;head=0;bfp=0;end
  endtask
  task reset_case;begin defaults();rst=1;step();rst=0;end endtask
  task birth_one(input [8:0] t,input [5:0] p,input [2:0] c,input [2:0] f,input [2:0] u);
    begin tags={9'b0,t};src={18'b0,6'd3,6'd2,p};classes={3'b0,c};fp={3'b0,f};used={3'b0,u};
      birth=1;step();birth=0;end
  endtask
  task drain(input [8:0] t);
    integer n;begin n=0;while(!done[t]&&n<15)begin step();n=n+1;end
      check(done[t],"expected instruction did not issue");end
  endtask
  initial begin
    step();rst=0;
    birth_one(1,0,0,0,1);
    if($test$plusargs("bad-init-ledger"))begin
      force dut.reference_birth_tag_q=18'd9;
      step();$fatal(1,"birth-ledger mismatch was not rejected");
    end
    drain(1);
    check(fire_cycle[1]-born_cycle[1]==2-INIT,"ready single birth E0 to IQ E1/E2");
    $display("INIT_READY_IQ init=%0d latency=%0d",INIT,fire_cycle[1]-born_cycle[1]);
    // Independent accepted lanes must each use their own query triple.
    reset_case();birth=3;tags={9'd2,9'd1};
    src={6'd6,6'd5,6'd2,6'd3,6'd2,6'd1};used=6'b001001;
    step();birth=0;drain(2);
    check(done[1]&&fire_cycle[1]==fire_cycle[2]&&fire_cycle[2]-born_cycle[2]==2-INIT,
          "dual init query lane identity");
    // Both rows use the new producer p10: lane1 cannot treat prebirth p10 as ready.
    reset_case();birth=3;tags={9'd2,9'd1};src={6'b0,6'b0,6'd10,18'b0};used=6'b001000;
    bw=1;bp=12'd10;dst=0;step();birth=0;bw=0;
    repeat(4)step();check(done[1]&&!done[2],"dual birth producer hazard");
    wb=1;wp=12'd10;step();wb=0;drain(2);
    // WB of an old generation and new birth of the same preg: birth wins.
    reset_case();wb=1;wp=12'd11;bw=1;bp=12'd11;
    birth_one(1,11,4,0,1);wb=0;bw=0;
    repeat(4)step();check(!done[1],"same edge WB/birth must remain busy");
    wb=1;step();wb=0;drain(1);
    // Busy query may conservatively wait the current WB edge.
    reset_case();bw=1;bp=12'd12;step();bw=0;birth_one(1,12,4,0,1);
    wb=1;wp=12'd12;#1;check(fire==0,"query must not pretend same-cycle WB is already Q");
    step();wb=0;drain(1);
    // Same-birth promise remains pending; current notice can qualify init row.
    reset_case();bw=1;bp=12'd13;step();bw=0;lp=1;lpp=12'd13;
    birth_one(1,13,4,0,1);lp=0;drain(1);
    check(fire_cycle[1]-born_cycle[1]==2-INIT,"same-birth promise initialization");
    reset_case();bw=1;bp=12'd14;step();bw=0;birth_one(1,14,4,0,1);
    rv=1;rp=12'd14;step();rv=0;drain(1);
    check(fire_cycle[1]-born_cycle[1]==2-INIT,"current final value initializing row");
    reset_case();bw=1;bp=12'd16;step();bw=0;rv=1;rp=12'd16;
    birth_one(1,16,4,0,1);rv=0;drain(1);
    check(fire_cycle[1]-born_cycle[1]==2-INIT,"same birth current notice retained as promise");
    // A next birth changes query addresses; stalled initialized old row keeps ready Q.
    reset_case();rr=0;birth_one(1,1,0,0,1);
    bw=1;bp=12'd15;step();bw=0;birth_one(2,15,4,0,1);
    rr=3;repeat(4)step();check(done[1]&&!done[2],"next query polluted older row readiness");
    wb=1;wp=12'd15;step();wb=0;drain(2);
    // Full initialization cancel and flush discard their owner before any fire.
    reset_case();birth_one(1,0,0,0,1);kill=32'h2;step();kill=0;
    repeat(3)step();check(!done[1]&&count==0,"init kill");
    reset_case();birth_one(1,0,0,0,1);flush=1;step();flush=0;
    repeat(3)step();check(count==0&&issued>0,"init flush");
    // Third FP source is queried with the FP namespace.
    reset_case();bw=1;bfp=1;bp=12'd3;step();bw=0;
    birth_one(1,1,3,7,7);repeat(4)step();check(!done[1],"third FPR source was ignored");
    wb=1;wfp=1;wp=12'd3;step();wb=0;wfp=0;drain(1);
    // Three FPR ports and identical long resources still limit init pairing.
    reset_case();birth=3;tags={9'd2,9'd1};classes={3'd4,3'd3};
    src={6'd6,6'd5,6'd4,6'd3,6'd2,6'd1};fp=6'b011111;used=6'b011111;
    step();birth=0;drain(2);
    check(fire_cycle[1]!=fire_cycle[2],"FP pair exceeded shared three ports");
    reset_case();birth=3;tags={9'd2,9'd1};classes={3'd2,3'd2};step();birth=0;
    drain(2);check(fire_cycle[1]!=fire_cycle[2],"same MDU resource double issue");
    // Function resources and serial dependency remain orthogonal to readiness.
    reset_case();fu=6'b111110;birth_one(1,0,0,0,1);
    repeat(3)step();check(!done[1],"init bypass ignored FU admission");fu=63;drain(1);
    reset_case();head=1;serial_active=2;serial_allow=0;birth=3;
    tags={9'd2,9'd1};classes={3'd0,3'd5};step();birth=0;
    repeat(3)step();check(!done[1]&&!done[2],"serial pair authorization");
    // The head's own active bit must not predate its birth in production.
    serial_release=2;step();serial_active=0;serial_release=0;serial_allow=1;
    drain(1);drain(2);check(fire_cycle[2]>=fire_cycle[1],"serial successor before head");
    check((INIT==0&&init_issued==0)||(INIT!=0&&init_issued>=9),"initialization path not exercised");
    $display("[PASS] tb_r64_issue_init_current init=%0d prepared=%0d checks=%0d issued=%0d init_issued=%0d",
      INIT,PREPARED,checks,issued,init_issued);$finish;
  end
endmodule
