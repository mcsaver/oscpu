`timescale 1ns/1ps
`include "R64Dispatch.vh"
// Real ResponseIngress -> Completion -> WB transport and execution-domain
// pipeline. The lifecycle fixture independently checks full tags/destinations;
// only canonical WB writes values. No speculative data is injected into RR.
module tb_r64_rr_complete_admit_chain #(parameter RR_COMPLETE_ADMIT=1);
  localparam ENABLE_RESOLVED=1, ENABLE_TOKEN=1;
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
  wire [2*`R64_MEM_CMD_W-1:0] mem_command;
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
  wire [1:0] resolved_valid=response_valid & response_ready & {2{notice_enable && !rst && !flush}} &
      { !kill[response_tag[T+:5]] && !response_data[R+`R64_R_EXCEPTION],
        !kill[response_tag[0+:5]] && !response_data[`R64_R_EXCEPTION] };
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
  R64ExecutionDomain #(.ALU_TOKEN_BYPASS(ENABLE_TOKEN),.LOAD_COMPLETION_PROMISE(1),.LOAD_RESOLVED_VALUE(ENABLE_RESOLVED),
    .RR_COMPLETE_ADMIT(RR_COMPLETE_ADMIT),.MEM_TERMINAL_CURRENT(1),.DIRECT_MEM_BIND(1)) dut(
    .batch_apply_i(1'b0),.batch_greclaim_i(64'b0),.batch_freclaim_i(64'b0),

    .resolved_value_valid_i(resolved_valid), .resolved_value_tag_i(response_tag),
    .resolved_value_data_i({response_data[R+:64],response_data[0+:64]}),
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
    .lsu_slot_o(),.lsu_command_o(mem_command),.fp_ready_i(1'b1),.fp_fire_o(),.fp_tag_o(),
    .fp_command_o(),.fp_operand_o(),.serial_ready_i(1'b1),.serial_fire_o(),.serial_tag_o(),
    .serial_command_o());
  integer directactual=0,directeligible=0,fallback=0;
  integer direct_cycle[0:511];
  reg [63:0] mem_base[0:511],mem_data[0:511];
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
          if(dut.registers.direct_eligible_w[l])directeligible=directeligible+1;
          if(dut.registers.direct_admit_w[l])begin directactual=directactual+1;
            direct_cycle[dut.issue_tag_w[l*T+:T]]=cycle;end
          else fallback=fallback+1;
          issue_cycle[dut.issue_tag_w[l*T+:T]]=cycle;
          if(dut.issue_tag_w[l*T+:T]==3 && resolved_valid!=0)current_issues=current_issues+1;
          pending_at_issue[dut.issue_tag_w[l*T+:T]]=dut.issue_pending_w[l*3+:3];
        end
        if((dut.read_valid_w[l]||dut.read_local_alu_valid_w[l])&&dut.execute_ready_w[l])
          execute_cycle[dut.read_tag_w[l*T+:T]]=cycle;
        if(mem_fire[l])begin
          mem_count[mem_tag[l*T+:T]]=mem_count[mem_tag[l*T+:T]]+1;
          mem_base[mem_tag[l*T+:T]]=mem_command[l*`R64_MEM_CMD_W+:64];
          mem_data[mem_tag[l*T+:T]]=mem_command[l*`R64_MEM_CMD_W+128+:64];
        end
      end
    end
  end
  task tick; begin @(posedge clk);#1;@(negedge clk);end endtask
  task check(input yes,input [511:0] why);
    begin checks=checks+1;if(yes!==1'b1)$fatal(1,"%0s",why);end
  endtask
  task clean;
    begin
      rst=1;birth=0;response_valid=0;recovery=0;mem_ready=3;allow_cq=1;allow_wb=1;notice_enable=1;tick();rst=0;tick();
      for(integer n=0;n<512;n=n+1) begin
        response_cycle[n]=-1;capture_cycle[n]=-1;wb_cycle[n]=-1;direct_cycle[n]=-1;
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
      check(execute_cycle[dependent]-response_cycle[producer]==(RR_COMPLETE_ADMIT?1:2),
            "response-to-dependent Execute latency");
      check(pending_at_issue[dependent]==1,"pending classification");
      $display("LOAD_RETURN_TAIL producer=%0d dependent=%0d response=%0d capture=%0d wb=%0d iq=%0d execute=%0d gap=%0d",
        producer,dependent,response_cycle[producer],capture_cycle[producer],wb_cycle[producer],
        issue_cycle[dependent],execute_cycle[dependent],execute_cycle[dependent]-response_cycle[producer]);
    end
  endtask


  task two_source(input [8:0] tag,input [2:0] cls,input [U-1:0] payload);
    begin
      birth_tag={9'b0,tag};birth_class={3'b0,cls};birth_write={1'b0,cls==`R64_C_ALU};
      birth_fp=0;birth_preg=34;birth_src={18'b0,6'b0,6'd33,6'd32};
      birth_used=6'b011;birth_src_fp=0;birth_uop={{U{1'b0}},payload};
      #1;check(birth_ready[0],"two-source birth credit");birth=1;tick();birth=0;
    end
  endtask
  task await_execute(input integer id);
    integer n;
    begin n=0;while(execute_cycle[id]<0&&n<80)begin tick();n=n+1;end
      check(execute_cycle[id]>=0,"dependent failed actual Execute");end
  endtask
  task gap(input integer id,input integer producer);
    begin
      await_execute(id);
      $display("RR_COMPLETE_GAP enabled=%0d producer=%0d consumer=%0d response=%0d execute=%0d gap=%0d",
        RR_COMPLETE_ADMIT,producer,id,response_cycle[producer],execute_cycle[id],
        execute_cycle[id]-response_cycle[producer]);
      check(execute_cycle[id]-response_cycle[producer]==(RR_COMPLETE_ADMIT?1:2),
            "actual raw accepted value to Execute gap");
    end
  endtask
  reg [U-1:0] u;
  reg [63:0] expected;
  integer mode,before_direct;
  initial begin
    for(mode=0;mode<8;mode=mode+1)begin
      clean();load_owner(1,32,3,0,0);load_owner(2,33,3,0,0);
      u=0;u[`R64_U_FUNC]=`R64_F_ADD;expected=107;
      case(mode)
        0:begin u[`R64_U_OP2_ARG]=1;u[`R64_U_ARG]=7;
          birth_one(3,`R64_C_ALU,1,0,34,32,1,u);end
        1:begin u[`R64_U_FUNC]=`R64_F_SLL;expected=800;two_source(3,`R64_C_ALU,u);end
        2:begin u[`R64_U_FUNC]=`R64_F_SLL;u[`R64_U_OP2_ARG]=1;u[`R64_U_ARG]=2;
          expected=400;birth_one(3,`R64_C_ALU,1,0,34,32,1,u);end
        3:begin u[`R64_U_WORD]=1;u[`R64_U_OP2_ARG]=1;u[`R64_U_ARG]=64'h80000000;
          expected=64'hffffffff80000064;birth_one(3,`R64_C_ALU,1,0,34,32,1,u);end
        4:begin u[`R64_U_OP1_PC]=1;u[`R64_U_PC]=64'h80000100;expected=64'h80000103;
          two_source(3,`R64_C_ALU,u);end
        5:begin u[`R64_U_OP1_ZERO]=1;expected=3;two_source(3,`R64_C_ALU,u);end
        6:begin u[`R64_U_FUNC]=3;birth_one(3,`R64_C_MEM,0,0,0,32,1,u);end
        7:begin u[`R64_U_FUNC]=8'h23;two_source(3,`R64_C_MEM,u);end
      endcase
      repeat(8)tick();check(mem_count[1]==1&&mem_count[2]==1,"load owner did not execute before return");
      offer(3,1,100,2,3,0);gap(3,1);
      if(mode<6)begin await_done(3);check(got[3]==expected,"direct ALU input control/value incorrect");end
      else begin check(mem_count[3]==1&&mem_base[3]==100,"MEM direct address wrong");
        if(mode==7)check(mem_data[3]==3,"MEM direct data wrong");end
      await_done(1);
      check(capture_cycle[1]-response_cycle[1]==2&&wb_cycle[1]-response_cycle[1]==3,
            "direct RR changed canonical transport or WB");
    end
    // Native no-register LUI/AUIPC packets still need current input control;
    // the previous ingress control is unrelated and may be stale after reset.
    for(mode=0;mode<2;mode=mode+1)begin
      clean();u=0;u[`R64_U_FUNC]=`R64_F_ADD;u[`R64_U_OP2_ARG]=1;
      if(mode==0)begin u[`R64_U_OP1_ZERO]=1;u[`R64_U_ARG]=64'hffffffff98765000;
        expected=64'hffffffff98765000;end
      else begin u[`R64_U_OP1_PC]=1;u[`R64_U_PC]=64'h80001000;u[`R64_U_ARG]=64'h1234;
        expected=64'h80002234;end
      birth_one(1,`R64_C_ALU,1,0,32,0,0,u);await_done(1);
      check(got[1]==expected,"LUI/AUIPC direct input control wrong");
      check(execute_cycle[1]-issue_cycle[1]==(RR_COMPLETE_ADMIT?1:2),"zero-source complete packet latency");
    end

    clean();load_owner(1,32,3,0,0);load_owner(2,33,3,0,0);
    consumer(3,34,32);consumer(4,35,33);repeat(8)tick();
    offer(3,1,1000,2,2000,0);gap(3,1);gap(4,2);await_done(3);await_done(4);
    check(got[3]==1001&&got[4]==2001&&execute_cycle[3]==execute_cycle[4],
          "dual complete packets changed values or lost dual Execute");
    // Notice disabled: the real canonical WB must provide the packet on its
    // accepted edge. No guessed promise or PRF-ready value can replace it.
    clean();load_owner(1,32,3,0,0);consumer(3,34,32);repeat(8)tick();
    notice_enable=0;offer(1,1,3000,0,0,0);await_done(3);
    check(got[3]==3001&&wb_cycle[1]-response_cycle[1]==3,"canonical WB packet correctness");
    check(execute_cycle[3]-wb_cycle[1]==(RR_COMPLETE_ADMIT?1:2),
          "real WB to dependent Execute latency");
    if(RR_COMPLETE_ADMIT)check(direct_cycle[3]==wb_cycle[1],"WB direct owner was not admitted at actual WB");
    $display("RR_COMPLETE_WB enabled=%0d response_to_Execute=%0d WB_to_Execute=%0d",
      RR_COMPLETE_ADMIT,execute_cycle[3]-response_cycle[1],execute_cycle[3]-wb_cycle[1]);
    // PRF-ready alone is not a current numerical certificate.
    clean();load_owner(1,32,3,0,0);load_owner(2,33,3,0,0);repeat(8)tick();
    offer(1,1,50,0,0,0);await_done(1);repeat(2)tick();
    u=0;u[`R64_U_FUNC]=`R64_F_ADD;two_source(3,`R64_C_ALU,u);
    repeat(5)tick();before_direct=directactual;
    offer(2,0,0,2,60,0);await_done(3);
    check(got[3]==110&&directactual==before_direct,"PRF-ready was treated as complete current value");
    check(execute_cycle[3]-response_cycle[2]==2,"partial values changed fallback latency");
    // Real accepted response does not steal the blocked canonical CQ owner.
    clean();load_owner(1,32,3,0,0);consumer(3,34,32);repeat(8)tick();
    allow_cq=0;offer(1,1,400,0,0,0);gap(3,1);repeat(5)tick();
    check(got[3]==401&&wb_cycle[1]<0&&source_take==0,"direct route stole canonical completion");
    allow_cq=1;await_done(1);check(done_count[1]==1,"blocked producer failed to drain");
    // Downstream hold, then kill/flush, before any actual MEM acceptance.
    for(mode=0;mode<3;mode=mode+1)begin
      clean();load_owner(1,32,3,0,0);repeat(8)tick();
      u=0;u[`R64_U_FUNC]=8'h23;birth_one(3,`R64_C_MEM,0,0,0,32,1,u);
      repeat(4)tick();mem_ready=0;offer(1,1,500,0,0,0);repeat(5)tick();
      check(execute_cycle[3]<0,"direct MEM ignored downstream stall");
      if(mode!=0)begin recovery={65'b0,mode==2,1'b1,32'h8};tick();recovery=0;tick();end
      mem_ready=3;
      if(mode==0)begin await_execute(3);check(mem_count[3]==1&&mem_base[3]==500,"held direct MEM payload");end
      else begin repeat(6)tick();check(execute_cycle[3]<0&&mem_count[3]==0,"cancelled direct MEM escaped");end
    end
    // Old fulltag response cannot satisfy a reused physical destination.
    clean();load_owner(1,32,3,0,0);consumer(3,34,32);repeat(8)tick();
    recovery={65'b0,1'b1,1'b1,32'hffffffff};tick();recovery=0;repeat(3)tick();
    load_owner(33,32,3,0,0);consumer(35,34,32);repeat(8)tick();before_direct=directactual;
    offer(1,1,999,0,0,0);repeat(6)tick();
    check(execute_cycle[35]<0&&directactual==before_direct,"stale generation became complete packet");
    offer(1,33,700,0,0,0);gap(35,33);await_done(35);check(got[35]==701,"new generation data wrong");
    if(RR_COMPLETE_ADMIT)check(directactual>10,"direct route coverage absent");
    else check(directactual==0,"disabled direct route accepted");
    check(fallback>0&&directeligible>0,"eligibility/fallback coverage absent");
    $display("[PASS] tb_r64_rr_complete_admit_chain enabled=%0d checks=%0d eligible=%0d actual=%0d fallback=%0d raw_Ingress_CQ_WB_Execute=1",
      RR_COMPLETE_ADMIT,checks,directeligible,directactual,fallback);$finish;
  end
  initial begin #200000;$fatal(1,"complete admit chain timeout");end
endmodule
