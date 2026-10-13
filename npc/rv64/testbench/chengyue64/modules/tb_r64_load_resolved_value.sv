`timescale 1ns/1ps
`include "R64Dispatch.vh"
// Real ResponseIngress -> Completion -> WB transport and execution-domain
// pipeline. The lifecycle fixture independently checks full tags/destinations;
// only canonical WB writes values. No speculative data is injected into RR.
module tb_r64_load_resolved_value #(parameter ENABLE_RESOLVED=1, parameter ENABLE_TOKEN=0, parameter NOTICE_Q=0,
  parameter TEST_NAME="tb_r64_load_resolved_value");
  localparam U=`R64_UOP_W, R=`R64_RESULT_W, T=9, S=7;
  reg clk=0; always #5 clk=~clk;
  reg rst=1;
  reg [`R64_RECOVERY_W(32)-1:0] recovery=0;
  wire flush=recovery[33];
  wire [31:0] kill=recovery[31:0]&{32{recovery[32]}};
  reg [1:0] birth=0,birth_write=0,birth_fp=0;
  reg [17:0] birth_tag=0;
  reg [2*U-1:0] birth_uop=0;
  reg [5:0] birth_class=0,birth_used=0,birth_src_fp=0;
  reg [11:0] birth_preg=0;
  reg [35:0] birth_src=0;
  wire [1:0] birth_ready;
  reg [1:0] mem_ready=3;
  wire [1:0] mem_fire;
  wire [17:0] mem_tag;
  wire [4:0] local_valid,local_ready;
  wire [5*T-1:0] local_tag;
  wire [5*R-1:0] local_data;
  reg [1:0] response_valid=0;
  reg [17:0] response_tag=0;
  reg [2*R-1:0] response_data=0;
  reg allow_cq=1,allow_wb=1,notice_enable=1;
  wire [1:0] response_ready,ingress_valid,ingress_ready,ingress_occupied;
  wire [1:0] cq_valid,cq_request,cq_ready,cq_credit,cq_bus_ready,selected_live;
  wire [5:0] source_take;
  wire [17:0] selected_tag;
  wire [2*R-1:0] selected_data;
  wire [1:0] resolved_valid=selected_live & {2{notice_enable}} &
      { !selected_data[R+`R64_R_EXCEPTION], !selected_data[`R64_R_EXCEPTION] };
  wire [17:0] ingress_tag,cq_tag;
  wire [2*R-1:0] ingress_data,cq_data;
  R64LsuResponseIngress #(.DATA_W(R)) ingress(
    .clk_i(clk),.rst_i(rst),.flush_i(flush),.kill_mask_i(kill),
    .in_valid_i(response_valid),.in_ready_o(response_ready),.in_live_i(2'b11),
    .in_tag_i(response_tag),.in_data_i(response_data),
    .out_occupied_o(ingress_occupied),.out_valid_o(ingress_valid),.out_ready_i(ingress_ready),
    .out_tag_o(ingress_tag),.out_data_o(ingress_data),.reuse_block_o(),.idle_o());
  wire [1:0] cq_fire;
  assign ingress_ready=source_take[1:0];
  R64LsuCompletionArbiter arbiter(
    .clk_i(clk),.rst_i(rst),.source_occupied_i({4'b0,ingress_occupied}),
    .source_live_i({4'b0,ingress_valid}),.source_tag_i({{4*T{1'b0}},ingress_tag}),
    .source_result_i({{4*R{1'b0}},ingress_data}),.source_take_o(source_take),
    .completion_credit_i(cq_credit & {2{allow_cq}}),.completion_fire_o(cq_fire),
    .selected_live_o(selected_live),.completion_tag_o(selected_tag),.completion_result_o(selected_data));
  R64LsuCompletion completion(
    .clk_i(clk),.rst_i(rst),.flush_i(flush),.kill_mask_i(kill),
    .in_fire_i(cq_fire),.in_ready_o(cq_credit),.in_tag_i(selected_tag),
    .in_result_i(selected_data),.out_valid_o(cq_valid),.out_request_o(cq_request),
    .out_ready_i(cq_ready),.out_tag_o(cq_tag),.out_result_o(cq_data),
    .reuse_block_o(),.idle_o());
  wire [S-1:0] source_capture;
  wire [1:0] raw_wb_valid;
  wire [17:0] raw_wb_tag;
  wire [2*R-1:0] raw_wb_data;
  assign cq_ready=cq_bus_ready & {2{allow_wb}};
  R64Writeback #(.SOURCES(S),.SOURCE_W(3),.DEFER_REQUEST(0),.REQUEST_HINTS(1)) wb(
    .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),
    .source_valid_i({cq_valid & {2{allow_wb}},local_valid}),.source_request_i({cq_request,5'b0}),
    .source_ready_o({cq_bus_ready,local_ready}),.source_capture_o(source_capture),
    .source_tag_i({cq_tag,local_tag}),.source_result_i({cq_data,local_data}),
    .owner_query_tag_o(),.owner_query_cert_i(72'b0),.wb_owner_cert_o(),
    .wb_valid_o(raw_wb_valid),.wb_tag_o(raw_wb_tag),.wb_result_o(raw_wb_data));
  wire [1:0] load_capture={source_capture[6]&&!cq_data[R+`R64_R_EXCEPTION],
                          source_capture[5]&&!cq_data[`R64_R_EXCEPTION]};
  reg [31:0] owner_live=0;
  reg [T-1:0] owner_tag[0:31];
  reg [5:0] owner_preg[0:31];
  reg owner_write[0:31],owner_fp[0:31];
  reg [1:0] wb_accept,wb_write,wb_fp;
  reg [11:0] wb_preg;
  reg [127:0] wb_data;
  always @* begin
    wb_accept=0;wb_write=0;wb_fp=0;wb_preg=0;wb_data=0;
    for(integer l=0;l<2;l=l+1) begin
      if(raw_wb_valid[l] && !rst && !flush && !kill[raw_wb_tag[l*T+:5]] &&
         owner_live[raw_wb_tag[l*T+:5]] &&
         owner_tag[raw_wb_tag[l*T+:5]]==raw_wb_tag[l*T+:T]) begin
        wb_accept[l]=1;
        wb_write[l]=owner_write[raw_wb_tag[l*T+:5]] && !raw_wb_data[l*R+`R64_R_EXCEPTION];
        wb_fp[l]=owner_fp[raw_wb_tag[l*T+:5]];
        wb_preg[l*6+:6]=owner_preg[raw_wb_tag[l*T+:5]];
        wb_data[l*64+:64]=raw_wb_data[l*R+:64];
      end
    end
  end
  // Replay an independently transported successful producer value exactly on
  // its canonical WB edge to exercise a notice that becomes stale after Q.
  reg [1:0] aligned_notice=0;
  wire [1:0] wb_notice_valid={
    wb_write[1] && raw_wb_tag[T+:T]==9'd1,
    wb_write[0] && raw_wb_tag[0+:T]==9'd1};
  wire aligned_wb=(aligned_notice!=0) && (wb_notice_valid!=0);
  wire [1:0] notice_valid=aligned_wb ? wb_notice_valid :
      (aligned_notice==1 ? 2'b0 : resolved_valid);
  wire [17:0] notice_tag=aligned_wb ? raw_wb_tag : selected_tag;
  wire [127:0] notice_data=aligned_wb ? wb_data : {selected_data[R+:64],selected_data[0+:64]};
  integer expired_q_crossings=0;
  integer crossing_window=-1;
  reg [1:0] crossing_valid;
  reg [17:0] crossing_tag;
  reg [127:0] crossing_data;
  always @(posedge clk) begin
    if(NOTICE_Q && aligned_wb && !rst) begin
      crossing_valid=wb_notice_valid;crossing_tag=raw_wb_tag;crossing_data=wb_data;
      if(crossing_window==0)
        check((dut.issue_fire_w[0] && dut.issue_tag_w[0+:T]==3) ||
              (dut.issue_fire_w[1] && dut.issue_tag_w[T+:T]==3),"WB edge lacks actual RR admission");
      if(crossing_window==1)check(birth[0] && birth_tag[0+:T]==3,"WB edge lacks consumer birth");
      if(crossing_window==2)
        check((dut.registers.read_select_w[0] && dut.registers.ingress_tag_q[0]==3) ||
              (dut.registers.read_select_w[1] && dut.registers.ingress_tag_q[1]==3),"WB edge lacks first RR read");
      #1;
      check(dut.load_notice_valid_w==crossing_valid &&
            dut.load_notice_tag_w==crossing_tag &&
            dut.load_notice_data_w==crossing_data,"WB-aligned notice packet missing from Q");
      check(dut.resolved_valid_w==0,"completed lease accepted delayed notice");
      expired_q_crossings=expired_q_crossings+1;
    end
  end
  R64ExecutionDomain #(.ALU_TOKEN_BYPASS(ENABLE_TOKEN),.LOAD_COMPLETION_PROMISE(1),.LOAD_RESOLVED_VALUE(ENABLE_RESOLVED),.LOAD_VALUE_NOTICE_Q(NOTICE_Q)) dut(
    .batch_apply_i(1'b0),.batch_greclaim_i(64'b0),.batch_freclaim_i(64'b0),

    .resolved_value_valid_i(notice_valid), .resolved_value_tag_i(notice_tag),
    .resolved_value_data_i(notice_data),
    .clk(clk),.rst(rst),.recovery_i(recovery),.serial_allow_i(1'b1),
    .head_slot_i(5'b0),.head_tag_i(9'b0),.barrier_slot_i(5'b0),.barrier_valid_i(1'b0),
    .serial_active_i(32'b0),.serial_release_i(32'b0),
    .birth_i(birth),.birth_ready_o(birth_ready),.birth_rd_write_i(birth_write),
    .birth_rd_fp_i(birth_fp),.birth_tag_i(birth_tag),.birth_mem_slot_i(10'b0),
    .birth_uop_i(birth_uop),.birth_class_i(birth_class),.birth_preg_i(birth_preg),
    .birth_src_preg_i(birth_src),.birth_src_fp_i(birth_src_fp),.birth_src_used_i(birth_used),
    .load_capture_i(load_capture),.load_capture_tag_i(cq_tag),
    .wb_accept_i(wb_accept),.wb_tag_i(raw_wb_tag),.wb_write_i(wb_write),.wb_fp_i(wb_fp),
    .wb_preg_i(wb_preg),.wb_data_i(wb_data),
    .reclaim_write_i(2'b0),.reclaim_fp_i(2'b0),.reclaim_preg_i(12'b0),
    .result_valid_o(local_valid),.result_ready_i(local_ready),.result_tag_o(local_tag),
    .result_o(local_data),.lsu_ready_i(mem_ready),.lsu_fire_o(mem_fire),.lsu_tag_o(mem_tag),
    .lsu_slot_o(),.lsu_command_o(),.fp_ready_i(1'b1),.fp_fire_o(),.fp_tag_o(),
    .fp_command_o(),.fp_operand_o(),.serial_ready_i(1'b1),.serial_fire_o(),.serial_tag_o(),
    .serial_command_o());
  integer cycle=0,checks=0,notices=0,transport=0,canonical=0,resolved_notices=0,current_issues=0;
  integer response_cycle[0:511],capture_cycle[0:511],wb_cycle[0:511];
  integer issue_cycle[0:511],execute_cycle[0:511],mem_count[0:511],done_count[0:511];
  reg [63:0] got[0:511];
  reg [2:0] pending_at_issue[0:511];
  always @(posedge clk) begin
    cycle=cycle+1;
    if(rst) owner_live<=0;
    else begin
      owner_live<=flush ? 0 : owner_live & ~kill;
      for(integer l=0;l<2;l=l+1) begin
        if(birth[l]) begin
          owner_live[birth_tag[l*T+:5]]<=birth_write[l];
          owner_tag[birth_tag[l*T+:5]]<=birth_tag[l*T+:T];
          owner_write[birth_tag[l*T+:5]]<=birth_write[l];
          owner_fp[birth_tag[l*T+:5]]<=birth_fp[l];
          owner_preg[birth_tag[l*T+:5]]<=birth_preg[l*6+:6];
        end
        if(wb_accept[l]) begin
          owner_live[raw_wb_tag[l*T+:5]]<=0;
          wb_cycle[raw_wb_tag[l*T+:T]]=cycle;
          done_count[raw_wb_tag[l*T+:T]]=done_count[raw_wb_tag[l*T+:T]]+1;
          got[raw_wb_tag[l*T+:T]]=wb_data[l*64+:64];
          canonical=canonical+1;
          if(done_count[raw_wb_tag[l*T+:T]]!=1)$fatal(1,"duplicate canonical completion");
        end
        if(response_valid[l]&&response_ready[l]) response_cycle[response_tag[l*T+:T]]=cycle;
        if(source_capture[5+l]) begin capture_cycle[cq_tag[l*T+:T]]=cycle;transport=transport+1;end
        if(dut.load_promise_w[l]) notices=notices+1;
        if(dut.resolved_valid_w[l]) resolved_notices=resolved_notices+1;
        if(dut.issue_fire_w[l]) begin
          issue_cycle[dut.issue_tag_w[l*T+:T]]=cycle;
          if(dut.issue_tag_w[l*T+:T]==3 && dut.resolved_valid_w!=0)current_issues=current_issues+1;
          pending_at_issue[dut.issue_tag_w[l*T+:T]]=dut.issue_pending_w[l*3+:3];
        end
        if((dut.read_valid_w[l]||dut.read_local_alu_valid_w[l])&&dut.execute_ready_w[l])
          execute_cycle[dut.read_tag_w[l*T+:T]]=cycle;
        if(mem_fire[l])mem_count[mem_tag[l*T+:T]]=mem_count[mem_tag[l*T+:T]]+1;
      end
    end
  end
  task tick; begin @(posedge clk);#1;@(negedge clk);end endtask
  task check(input yes,input [511:0] why);
    begin checks=checks+1;if(yes!==1'b1)$fatal(1,"%0s",why);end
  endtask
  task clean;
    begin
      rst=1;birth=0;response_valid=0;recovery=0;aligned_notice=0;mem_ready=3;allow_cq=1;allow_wb=1;notice_enable=1;tick();rst=0;tick();
      for(integer n=0;n<512;n=n+1) begin
        response_cycle[n]=-1;capture_cycle[n]=-1;wb_cycle[n]=-1;
        issue_cycle[n]=-1;execute_cycle[n]=-1;mem_count[n]=0;done_count[n]=0;
        pending_at_issue[n]=0;got[n]=0;
      end
    end
  endtask
  task birth_one(input [8:0] tag,input [2:0] cls,input wr,input fp,
                 input [5:0] dst,input [5:0] src,input [2:0] used,input [U-1:0] uop);
    begin
      birth_tag={9'b0,tag};birth_class={3'b0,cls};birth_write={1'b0,wr};birth_fp={1'b0,fp};
      birth_preg={6'b0,dst};birth_src={30'b0,src};birth_used={3'b0,used};birth_src_fp=0;
      birth_uop={{U{1'b0}},uop};#1;check(birth_ready[0],"birth no credit");
      birth=1;tick();birth=0;
    end
  endtask
  task load_owner(input [8:0] tag,input [5:0] preg,input [7:0] func,input fp,input fault);
    reg [U-1:0] u;
    begin u=0;u[`R64_U_FUNC]=func;u[`R64_U_EXCEPTION]=fault;
      birth_one(tag,`R64_C_MEM,(preg!=0)||fp,fp,preg,0,0,u);end
  endtask
  task consumer(input [8:0] tag,input [5:0] dst,input [5:0] src);
    reg [U-1:0] u;
    begin u=0;u[`R64_U_FUNC]=`R64_F_ADD;u[`R64_U_OP2_ARG]=1;u[`R64_U_ARG]=1;
      birth_one(tag,`R64_C_ALU,1,0,dst,src,1,u);end
  endtask
  task offer(input [1:0] mask,input [8:0] t0,input [63:0] d0,
             input [8:0] t1,input [63:0] d1,input fault);
    begin
      check((response_ready&mask)==mask,"response credit");
      response_valid=mask;response_tag={t1,t0};response_data=0;
      response_data[0+:64]=d0;response_data[R+:64]=d1;
      response_data[`R64_R_EXCEPTION]=fault;response_data[R+`R64_R_EXCEPTION]=fault;
      tick();response_valid=0;
    end
  endtask
  task await_done(input [8:0] tag);
    integer n;
    begin n=0;while(done_count[tag]==0&&n<80)begin tick();n=n+1;end
      check(done_count[tag]==1,"consumer failed to complete");end
  endtask
  task tail_check(input [8:0] producer,input [8:0] dependent,input [63:0] value);
    begin
      await_done(dependent);
      check(got[dependent]==value,"dependent consumed wrong returned value");
      check(wb_cycle[producer]-response_cycle[producer]==3,"canonical WB edge changed");
      check(capture_cycle[producer]-response_cycle[producer]==2,"transport capture edge changed");
      check(execute_cycle[dependent]-response_cycle[producer]==(ENABLE_RESOLVED?(3+NOTICE_Q):5),
            "response-to-dependent Execute latency");
      check(pending_at_issue[dependent]==1,"pending classification");
      $display("LOAD_RETURN_TAIL producer=%0d dependent=%0d response=%0d capture=%0d wb=%0d iq=%0d execute=%0d gap=%0d",
        producer,dependent,response_cycle[producer],capture_cycle[producer],wb_cycle[producer],
        issue_cycle[dependent],execute_cycle[dependent],execute_cycle[dependent]-response_cycle[producer]);
    end
  endtask

  integer before_notice,n,held;
  reg [U-1:0] u;
  initial begin
    clean();
    for(integer lane=0;lane<3;lane=lane+1)begin
      clean();load_owner(1,32,3,0,0);load_owner(2,33,3,0,0);
      consumer(3,34,32);consumer(4,35,33);repeat(8)tick();
      check(mem_count[1]==1&&mem_count[2]==1,"real MEM accepted before response");
      if(lane==0)begin offer(1,1,100,0,0,0);tail_check(1,3,101);end
      else if(lane==1)begin offer(2,0,0,2,200,0);tail_check(2,4,201);end
      else begin offer(3,1,100,2,200,0);tail_check(1,3,101);tail_check(2,4,201);end
    end
    // Same-edge notice/birth and deferred init do not turn the notice into a
    // sticky numerical-ready bit. The normal WB remains the missed-pulse fallback.
    for(integer offset=0;offset<3;offset=offset+1)begin
      clean();load_owner(1,32,3,0,0);repeat(8)tick();offer(1,1,300,0,0,0);
      repeat(offset)tick();consumer(3,34,32);await_done(3);
      check(got[3]==301,"late birth lost notice/WB value");
    end
    // CQ denial does not own or consume the notice. Value-based execution can
    // finish while canonical completion still has not entered CQ or WB.
    clean();load_owner(1,32,3,0,0);consumer(3,34,32);repeat(8)tick();
    allow_cq=0;offer(1,1,400,0,0,0);
    repeat(8)begin tick();check(source_take==0&&cq_fire==0,"notice consumed blocked completion");end
    if(ENABLE_RESOLVED)begin
      check(execute_cycle[3]>=0&&got[3]==401,"CQ pressure blocked genuine value execution");
      check(execute_cycle[3]-response_cycle[1]==(3+NOTICE_Q),"CQ-independent execution latency");
    end else check(execute_cycle[3]<0,"disabled notice bypassed canonical capture");
    check(wb_cycle[1]<0,"notice changed canonical completion edge");
    allow_cq=1;await_done(1);await_done(3);check(got[3]==401,"CQ drain changed value");
    // A new owner is born at the last notice edge, so it records a scheduling
    // promise but cannot yet issue. Hold canonical WB after the one-shot notice
    // disappears: it must wait numerically, then recover on the real WB pulse.
    clean();load_owner(1,32,3,0,0);repeat(8)tick();allow_wb=0;
    offer(1,1,500,0,0,0);consumer(3,34,32);repeat(10)tick();
    check(wb_cycle[1]<0&&execute_cycle[3]<0,"missed notice consumed stale PRF");
    if(ENABLE_RESOLVED)check(issue_cycle[3]>=0,"same-birth promise not retained");
    allow_wb=1;await_done(3);check(got[3]==501,"WB fallback did not discharge missed notice");
    // Full terminal queues: one ingress saves its admission history exactly
    // once while the selected source and its canonical WB pulse disappear.
    clean();load_owner(1,32,3,0,0);repeat(8)tick();mem_ready=0;
    for(integer k=2;k<7;k=k+1)begin u=0;u[`R64_U_FUNC]=8'h23;
      birth_one(9'(k),`R64_C_MEM,0,0,0,0,0,u);end
    repeat(8)tick();consumer(7,34,32);repeat(4)tick();offer(1,1,600,0,0,0);
    repeat(8)tick();check(execute_cycle[7]<0,"terminal pressure ignored");
    held=0;for(integer l=0;l<2;l=l+1)
      if(dut.registers.ingress_valid_q[l]&&dut.registers.ingress_tag_q[l]==7)held=held+1;
    check(held==1,"consumer did not retain ingress owner");
    mem_ready=3;await_done(7);check(got[7]==601,"held history lost value");
    // Notice/cancellation edge and source pop/refill are full-tag local events.
    clean();load_owner(1,32,3,0,0);consumer(3,34,32);repeat(8)tick();
    offer(1,1,700,0,0,0);
    recovery={65'b0,1'b0,1'b1,32'h0000000a};tick();recovery=0;repeat(8)tick();
    check(execute_cycle[3]<0&&done_count[3]==0,"cancelled notice escaped");
    load_owner(33,32,3,0,0);consumer(35,34,32);repeat(8)tick();
    before_notice=resolved_notices;offer(1,1,999,0,0,0);repeat(7)tick();
    check(resolved_notices==before_notice&&issue_cycle[35]<0,"stale notice woke reused preg");
    offer(1,33,800,0,0,0);tail_check(33,35,801);
    // Producer completion types remain an independent filter.
    for(integer kind=0;kind<6;kind=kind+1)begin
      clean();load_owner(1,kind==4?0:32,kind==1?8'h43:kind==2?8'h83:kind==3?8'h23:8'h03,
                        kind==1,kind==5);repeat(8)tick();before_notice=resolved_notices;
      offer(1,1,900,0,0,kind==0);repeat(8)tick();
      check(resolved_notices==before_notice,"ineligible result became resolved integer load");
    end
    if(NOTICE_Q)begin
      for(integer window=0;window<4;window=window+1)begin
        clean();crossing_window=window;load_owner(1,32,3,0,0);repeat(8)tick();
        // mode 1 retains only the WB-edge announcement; mode 2 also lets a
        // prior resident notice place the consumer at its first RR read.
        aligned_notice=(window==2)?2:1;
        if(window==3)begin
          mem_ready=0;
          for(integer k=2;k<7;k=k+1)begin
            u=0;u[`R64_U_FUNC]=8'h23;
            birth_one(9'(k),`R64_C_MEM,0,0,0,0,0,u);
          end
          repeat(8)tick();consumer(7,34,32);repeat(4)tick();
        end else if(window!=1)begin consumer(3,34,32);repeat(4)tick();end
        offer(1,1,64'd1100+64'(window),0,0,0);
        if(window==1)begin
          n=0;while(wb_notice_valid==0 && n<20)begin tick();n=n+1;end
          check(wb_notice_valid!=0,"birth/WB crossing not reached");
          consumer(3,34,32);
        end
        if(window==3)begin
          repeat(8)tick();check(execute_cycle[7]<0,"blocked RR escaped");
          held=0;for(integer l=0;l<2;l=l+1)
            if(dut.registers.ingress_valid_q[l] && dut.registers.ingress_tag_q[l]==7)begin
              held=held+1;
              check(!dut.registers.ingress_late_pending_q[l][0] &&
                    dut.registers.ingress_late_resolved_q[l][0] &&
                    dut.registers.ingress_late_data_q[l][0+:64]==1103,
                    "blocked ingress failed to save one-shot WB history");
            end
          check(held==1 && pending_at_issue[7]==1,"pending/history consumer missing from ingress");
          mem_ready=3;await_done(7);check(got[7]==1104,"blocked history canonical fallback wrong");
        end else begin
          await_done(3);check(got[3]==(64'd1101+64'(window)),"expired Q canonical fallback wrong");
          if(window==0)check(issue_cycle[3]==wb_cycle[1] && pending_at_issue[3]==1,"pending WB/admission crossing not reached");
          if(window==2)check(issue_cycle[3]+1==wb_cycle[1] && pending_at_issue[3]==1,"pending WB/first-read crossing not reached");
        end
        check(done_count[1]==1,"expired notice duplicated canonical producer completion");
      end
      check(expired_q_crossings==4,"expired Q/WB coverage missing");
      $display("NOTICE_Q_CANONICAL_FALLBACK crossings=%0d old_IQ_admission_birth_first_read_blocked=1",expired_q_crossings);
    end
    if(ENABLE_RESOLVED)check(current_issues>=3&&resolved_notices>=10,"current-hit coverage");
    else check(resolved_notices==0,"feature-off owner query leaked");
    $display("[PASS] %0s enable=%0d notice_q=%0d checks=%0d resolved=%0d current_issues=%0d",
             TEST_NAME,ENABLE_RESOLVED,NOTICE_Q,checks,resolved_notices,current_issues);$finish;
  end
  initial begin #200000;$fatal(1,"load resolved value timeout");end
endmodule
