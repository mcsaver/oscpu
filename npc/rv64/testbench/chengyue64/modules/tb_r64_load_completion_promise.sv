`timescale 1ns/1ps
`include "R64Dispatch.vh"
// Real ResponseIngress -> Completion -> WB transport and execution-domain
// pipeline. The lifecycle fixture independently checks full tags/destinations;
// only canonical WB writes values. No speculative data is injected into RR.
module tb_r64_load_completion_promise #(parameter ENABLE_PROMISE=1);
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
  wire [1:0] response_ready,ingress_valid,ingress_ready,cq_valid,cq_request,cq_ready;
  wire [17:0] ingress_tag,cq_tag;
  wire [2*R-1:0] ingress_data,cq_data;
  R64LsuResponseIngress #(.DATA_W(R)) ingress(
    .clk_i(clk),.rst_i(rst),.flush_i(flush),.kill_mask_i(kill),
    .in_valid_i(response_valid),.in_ready_o(response_ready),.in_live_i(2'b11),
    .in_tag_i(response_tag),.in_data_i(response_data),
    .out_occupied_o(),.out_valid_o(ingress_valid),.out_ready_i(ingress_ready),
    .out_tag_o(ingress_tag),.out_data_o(ingress_data),.reuse_block_o(),.idle_o());
  wire [1:0] cq_fire=ingress_valid & ingress_ready;
  R64LsuCompletion completion(
    .clk_i(clk),.rst_i(rst),.flush_i(flush),.kill_mask_i(kill),
    .in_fire_i(cq_fire),.in_ready_o(ingress_ready),.in_tag_i(ingress_tag),
    .in_result_i(ingress_data),.out_valid_o(cq_valid),.out_request_o(cq_request),
    .out_ready_i(cq_ready),.out_tag_o(cq_tag),.out_result_o(cq_data),
    .reuse_block_o(),.idle_o());
  wire [S-1:0] source_capture;
  wire [1:0] raw_wb_valid;
  wire [17:0] raw_wb_tag;
  wire [2*R-1:0] raw_wb_data;
  R64Writeback #(.SOURCES(S),.SOURCE_W(3),.DEFER_REQUEST(0),.REQUEST_HINTS(1)) wb(
    .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),
    .source_valid_i({cq_valid,local_valid}),.source_request_i({cq_request,5'b0}),
    .source_ready_o({cq_ready,local_ready}),.source_capture_o(source_capture),
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
  R64ExecutionDomain #(.LOAD_COMPLETION_PROMISE(ENABLE_PROMISE)) dut(
    .batch_apply_i(1'b0),.batch_greclaim_i(64'b0),.batch_freclaim_i(64'b0),

    .resolved_value_valid_i(2'b0), .resolved_value_tag_i(18'b0), .resolved_value_data_i(128'b0),
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
  integer cycle=0,checks=0,notices=0,transport=0,canonical=0;
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
        if(dut.issue_fire_w[l]) begin
          issue_cycle[dut.issue_tag_w[l*T+:T]]=cycle;
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
      rst=1;birth=0;response_valid=0;recovery=0;mem_ready=3;tick();rst=0;tick();
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
      check(execute_cycle[dependent]-response_cycle[producer]==(ENABLE_PROMISE?5:6),
            "response-to-dependent Execute latency");
      check(pending_at_issue[dependent]==(ENABLE_PROMISE?1:0),"pending classification");
      $display("LOAD_RETURN_TAIL producer=%0d dependent=%0d response=%0d capture=%0d wb=%0d iq=%0d execute=%0d gap=%0d",
        producer,dependent,response_cycle[producer],capture_cycle[producer],wb_cycle[producer],
        issue_cycle[dependent],execute_cycle[dependent],execute_cycle[dependent]-response_cycle[producer]);
    end
  endtask
  integer before_notice,n,held,base_notice;
  reg [U-1:0] u;
  initial begin
    clean();
    // Resident consumers, either physical CQ/WB lane, and paired completion.
    for(integer lane=0;lane<3;lane=lane+1) begin
      clean();load_owner(1,32,3,0,0);load_owner(2,33,3,0,0);
      consumer(3,34,32);consumer(4,35,33);repeat(8)tick();
      check(mem_count[1]==1&&mem_count[2]==1,"real MEM Execute before response");
      if(lane==0)begin offer(1,1,100,0,0,0);tail_check(1,3,101);end
      else if(lane==1)begin offer(2,0,0,2,200,0);tail_check(2,4,201);end
      else begin offer(3,1,100,2,200,0);tail_check(1,3,101);tail_check(2,4,201);end
    end
    // Birth E1 (deferred init at capture), E2 (same capture), E3 (WB).
    for(integer offset=0;offset<3;offset=offset+1)begin
      clean();load_owner(1,32,3,0,0);repeat(8)tick();offer(1,1,300,0,0,0);
      repeat(offset)tick();consumer(3,34,32);await_done(3);
      check(got[3]==301,"birth/init overlap lost WB value or promise");
      if(offset==0)check(execute_cycle[3]-response_cycle[1]==(ENABLE_PROMISE?5:6),
                        "deferred init/capture overlap");
      if(offset==1&&ENABLE_PROMISE)check(issue_cycle[3]-response_cycle[1]==4,
                                        "same-capture birth fallback");
    end
    // Two simultaneous load captures and two ALU issue promises have four
    // independent destinations. Consumer init at that same edge must retain
    // both sources rather than arbitrate away one producer family.
    clean();load_owner(1,32,3,0,0);load_owner(2,33,3,0,0);repeat(8)tick();
    u=0;u[`R64_U_FUNC]=`R64_F_ADD;u[`R64_U_OP2_ARG]=1;u[`R64_U_ARG]=10;
    birth_tag={9'd4,9'd3};birth_class=0;birth_write=3;birth_fp=0;
    birth_preg={6'd35,6'd34};birth_src=0;birth_used=0;birth_src_fp=0;
    birth_uop={u,u};birth=3;
    response_valid=3;response_tag={9'd2,9'd1};response_data=0;
    response_data[0+:64]=100;response_data[R+:64]=200;
    tick();birth=0;response_valid=0;
    u=0;u[`R64_U_FUNC]=`R64_F_ADD;
    birth_tag={9'd6,9'd5};birth_preg={6'd37,6'd36};
    birth_src={6'b0,6'd35,6'd33,6'b0,6'd34,6'd32};birth_used=6'b011011;
    birth_uop={u,u};birth=3;tick();birth=0;#1;
    check(dut.issue.promise_valid_w==3&&load_capture==3,"four producer announcements did not coincide");
    tick();await_done(5);await_done(6);
    check(got[5]==110&&got[6]==210,"load plus ALU promise lost a value");
    if(ENABLE_PROMISE)check(pending_at_issue[5]==3&&pending_at_issue[6]==3,
                            "four promise sources were arbitrated or reclassified");
    // Full RR terminals, one free ingress. The pulse is captured on admission and
    // saved into this owner while terminal backpressure outlasts WB.
    clean();load_owner(1,32,3,0,0);repeat(8)tick();mem_ready=0;
    for(integer k=2;k<7;k=k+1)begin u=0;u[`R64_U_FUNC]=8'h23;
      birth_one(9'(k),`R64_C_MEM,0,0,0,0,0,u);end
    repeat(8)tick();consumer(7,34,32);repeat(4)tick();offer(1,1,400,0,0,0);
    repeat(8)tick();check(execute_cycle[7]<0,"terminal pressure ignored");
    if(ENABLE_PROMISE)begin
      held=0;for(integer l=0;l<2;l=l+1)
        if(dut.registers.ingress_valid_q[l] && dut.registers.ingress_tag_q[l]==7)held=held+1;
      check(held==1,"promised consumer did not retain ingress owner");
    end
    mem_ready=3;await_done(7);check(got[7]==401,"held ingress lost one-shot WB history");
    // Captured transport followed by global cancellation suppresses canonical
    // WB. The promise cannot supply data and local Recovery kills its RR owner.
    clean();load_owner(1,32,3,0,0);consumer(3,34,32);repeat(8)tick();
    offer(1,1,500,0,0,0);tick();tick();
    check(capture_cycle[1]>=0,"capture-before-cancel coverage");
    recovery={65'b0,1'b0,1'b1,32'h0000000a};tick();recovery=0;repeat(8)tick();
    check(wb_cycle[1]<0&&execute_cycle[3]<0&&done_count[3]==0,"cancelled promise produced value");
    // Slot/preg reuse plus an old full tag. Stale CQ still drains, but the new
    // owner cannot be scheduled until its own complete result is captured.
    load_owner(33,32,3,0,0);consumer(35,34,32);repeat(8)tick();
    before_notice=notices;offer(1,1,999,0,0,0);repeat(7)tick();
    check(notices==before_notice&&issue_cycle[35]<0,"old generation woke reused slot/preg");
    offer(1,33,600,0,0,0);tail_check(33,35,601);
    // Current kill at WB capture, and full flush at capture, are not captures.
    for(integer full=0;full<2;full=full+1)begin
      clean();load_owner(1,32,3,0,0);consumer(3,34,32);repeat(8)tick();
      offer(1,1,700,0,0,0);tick();
      check(cq_valid[0]&&cq_ready[0],"WB-granted cancellation coverage");
      recovery={65'b0,1'(full),1'b1,32'h0000000a};#1;
      check(source_capture[5]==0,"kill/flush grant falsely announced capture");
      tick();recovery=0;repeat(8)tick();check(execute_cycle[3]<0,"cancelled capture escaped");
    end
    // Identity/type exclusions. Returning an exception never grants readiness;
    // FP, AMO, store, x0 and decoded-fault births are not integer-load leases.
    for(integer kind=0;kind<6;kind=kind+1)begin
      clean();load_owner(1,kind==4?0:32,kind==1?8'h43:kind==2?8'h83:kind==3?8'h23:8'h03,
                        kind==1,kind==5);repeat(8)tick();before_notice=notices;
      offer(1,1,800,0,0,kind==0);repeat(8)tick();
      check(notices==before_notice,"ineligible load completion published promise");
    end
    // Demand/READY is not ownership: reservation hints without held CQ valid
    // have no capture event, and reset suppresses the previous registered grant.
    clean();repeat(4)tick();check(source_capture==0,"empty grant became capture");
    check(ENABLE_PROMISE==0||notices>=8,"completion promise coverage");
    $display("[PASS] tb_r64_load_completion_promise enable=%0d checks=%0d notices=%0d transport=%0d canonical=%0d",
             ENABLE_PROMISE,checks,notices,transport,canonical);
    $finish;
  end
  initial begin #200000;$fatal(1,"load completion promise timeout");end
endmodule
