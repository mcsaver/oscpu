`timescale 1ns/1ps
`include "R64Dispatch.vh"
// Real ResponseIngress -> Completion -> WB transport and execution-domain
// pipeline. The lifecycle fixture independently checks full tags/destinations;
// only canonical WB writes values. No speculative data is injected into RR.
module tb_r64_rr_complete_branch_admit #(parameter BRANCH_ADMIT=1, GPR_READ=1);
  localparam RR_COMPLETE_ADMIT=1;
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
  wire resolve_valid,redirect_valid;
  wire [8:0] resolve_tag;
  wire [63:0] resolve_npc,resolve_pc;
  wire resolve_conditional,resolve_indirect,resolve_taken;
  R64ExecutionDomain #(.ALU_TOKEN_BYPASS(ENABLE_TOKEN),.LOAD_COMPLETION_PROMISE(1),.LOAD_RESOLVED_VALUE(ENABLE_RESOLVED),
    .RR_COMPLETE_ADMIT(RR_COMPLETE_ADMIT),.RR_COMPLETE_BRANCH_ADMIT(BRANCH_ADMIT),
    .RR_ADMIT_GPR_READ(GPR_READ),.MEM_TERMINAL_CURRENT(1),.DIRECT_MEM_BIND(1)) dut(
    .batch_apply_i(1'b0),.batch_greclaim_i(64'b0),.batch_freclaim_i(64'b0),

    .resolve_valid_o(resolve_valid),.redirect_valid_o(redirect_valid),.resolve_tag_o(resolve_tag),
    .resolve_npc_o(resolve_npc),.resolve_pc_o(resolve_pc),
    .resolve_conditional_o(resolve_conditional),.resolve_indirect_o(resolve_indirect),
    .resolve_taken_o(resolve_taken),
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
  integer resolve_cycle[0:511],resolve_count[0:511],execute_lane[0:511];
  reg [63:0] resolved_npc[0:511],resolved_pc[0:511];
  reg taken_seen[0:511],conditional_seen[0:511],indirect_seen[0:511];
  reg [U-1:0] expected_uop[0:511];
  reg [511:0] branch_expected=0;
  integer branches=0,latency_checks=0,prf_cases=0,ordered_pairs=0;
  always @(posedge clk)if(!rst&&!flush&&resolve_valid)begin
    resolve_cycle[resolve_tag]=cycle;resolve_count[resolve_tag]+=1;
    resolved_npc[resolve_tag]=resolve_npc;resolved_pc[resolve_tag]=resolve_pc;
    taken_seen[resolve_tag]=resolve_taken;conditional_seen[resolve_tag]=resolve_conditional;
    indirect_seen[resolve_tag]=resolve_indirect;
    if(resolve_count[resolve_tag]!=1)$fatal(1,"duplicate branch resolution");
  end
  integer directactual=0,directeligible=0,fallback=0,branch_direct=0,branch_fallback=0;
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
          if(dut.issue_class_w[l*3+:3]==`R64_C_BRANCH)begin
            if(dut.registers.direct_admit_w[l])branch_direct+=1;else branch_fallback+=1;
          end
          if(dut.registers.direct_eligible_w[l])directeligible=directeligible+1;
          if(dut.registers.direct_admit_w[l])begin directactual=directactual+1;
            direct_cycle[dut.issue_tag_w[l*T+:T]]=cycle;end
          else fallback=fallback+1;
          issue_cycle[dut.issue_tag_w[l*T+:T]]=cycle;
          if(dut.issue_tag_w[l*T+:T]==3 && resolved_valid!=0)current_issues=current_issues+1;
          pending_at_issue[dut.issue_tag_w[l*T+:T]]=dut.issue_pending_w[l*3+:3];
        end
        if((dut.read_valid_w[l]||dut.read_local_alu_valid_w[l])&&dut.execute_ready_w[l])begin
          execute_cycle[dut.read_tag_w[l*T+:T]]=cycle;
          execute_lane[dut.read_tag_w[l*T+:T]]=l;
          if(branch_expected[dut.read_tag_w[l*T+:T]] &&
            dut.read_uop_w[l*U+:U]!==expected_uop[dut.read_tag_w[l*T+:T]])
            $fatal(1,"branch terminal changed raw/PC/length/prediction");
        end
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
      branch_expected=0;
      rst=1;birth=0;response_valid=0;recovery=0;mem_ready=3;allow_cq=1;allow_wb=1;notice_enable=1;tick();rst=0;tick();
      for(integer n=0;n<512;n=n+1) begin
        response_cycle[n]=-1;capture_cycle[n]=-1;wb_cycle[n]=-1;direct_cycle[n]=-1;
        resolve_cycle[n]=-1;resolve_count[n]=0;execute_lane[n]=-1;
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
  task offer(input [1:0] mask,input [8:0] t0,input [63:0] d0,
             input [8:0] t1,input [63:0] d1,input fault);
    begin
      repeat(8)tick();
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
  function [31:0] b_inst(input [2:0] f,input integer offset);
    reg [12:0] imm;
    begin imm=13'(offset);b_inst={imm[12],imm[10:5],5'd2,5'd1,f,imm[4:1],imm[11],7'h63};end
  endfunction
  function [31:0] j_inst(input integer offset,input [4:0] rd);
    reg [20:0] imm;
    begin imm=21'(offset);j_inst={imm[20],imm[10:1],imm[11],imm[19:12],rd,7'h6f};end
  endfunction
  function [31:0] i_inst(input integer offset,input [4:0] rd);
    begin i_inst={12'(offset),5'd1,3'b0,rd,7'h67};end
  endfunction
  function cond(input [2:0] f,input [63:0] a,b);
    case(f)
      0:cond=a==b;1:cond=a!=b;4:cond=$signed(a)<$signed(b);
      5:cond=$signed(a)>=$signed(b);6:cond=a<b;7:cond=a>=b;
      default:cond=0;
    endcase
  endfunction
  function [U-1:0] branch_uop(input [31:0] inst,input [63:0] pc,input [3:0] len);
    reg [U-1:0] v;
    begin v=0;v[`R64_U_PC]=pc;v[`R64_U_CMD]={32'hcafe1234,inst};v[`R64_U_LEN]=len;
      v[`R64_U_ARG]=pc+64'(len);
      // Deliberately non-add ALU function/flags: branch control must be
      // independently derived from the accepted instruction.
      v[`R64_U_FUNC]=`R64_F_XOR;v[`R64_U_FLAGS]=8'h0f;
      branch_uop=v;
    end
  endfunction
  task branch_birth(input integer id,input [31:0] inst,input [63:0] pc,input integer len,
                    input integer dst,input [2:0] used);
    reg [U-1:0] v;
    begin
      v=branch_uop(inst,pc,4'(len));expected_uop[id]=v;branch_expected[id]=1;
      birth_tag=18'(id);birth_class={3'b0,`R64_C_BRANCH};birth_write={1'b0,dst!=0};birth_fp=0;
      birth_preg=12'(dst);birth_src={18'b0,6'b0,6'd33,6'd32};
      birth_used={3'b0,used};birth_src_fp=0;birth_uop={{U{1'b0}},v};
      #1;check(birth_ready[0],"branch birth credit");birth=1;tick();birth=0;
    end
  endtask
  task await_resolve(input integer id);
    integer n;
    begin n=0;while(resolve_count[id]==0&&n<80)begin tick();n+=1;end
      check(resolve_count[id]==1,"branch failed real resolution");end
  endtask
  task verify_branch(input integer id,input [63:0] npc,input taken,input conditional,
                     input indirect,input integer dst);
    begin
      await_resolve(id);branches+=1;
      check(resolved_npc[id]===npc,"branch target/fallthrough wrong");
      check(resolved_pc[id]===expected_uop[id][`R64_U_PC],"branch PC wrong");
      check(taken_seen[id]===taken&&conditional_seen[id]===conditional&&indirect_seen[id]===indirect,
        "branch condition/type wrong");
      if(dst!=0)begin
        await_done(9'(id));
        check(got[id]===expected_uop[id][`R64_U_PC]+64'(expected_uop[id][`R64_U_LEN]),
          "JAL/JALR link differs from PC plus original instruction length");
      end
    end
  endtask
  task branch_gap(input integer id,input integer producer);
    begin
      await_resolve(id);latency_checks+=1;
      if(latency_checks<=6)$display("BRANCH_GAP enabled=%0d response=%0d issue=%0d execute=%0d resolve=%0d gap=%0d",
        BRANCH_ADMIT,response_cycle[producer],issue_cycle[id],execute_cycle[id],resolve_cycle[id],
        execute_cycle[id]-response_cycle[producer]);
      check(execute_cycle[id]-response_cycle[producer]==(BRANCH_ADMIT?1:2),
        "actual load value to branch Execute gap");
      check(resolve_cycle[id]-response_cycle[producer]==(BRANCH_ADMIT?3:4),
        "actual load value to branch resolution gap");
      check(capture_cycle[producer]-response_cycle[producer]==2&&wb_cycle[producer]-response_cycle[producer]==3,
        "branch admission changed canonical producer completion timing");
    end
  endtask
  reg [63:0] av[0:7],bv[0:7];
  reg [2:0] condition[0:5];
  reg [31:0] inst;
  reg [63:0] pc,npc;
  reg tk;
  integer c,v,off,len,dst,mode;
  initial begin
    av[0]=0;bv[0]=0;av[1]=0;bv[1]=1;av[2]=1;bv[2]=0;
    av[3]=64'h8000000000000000;bv[3]=64'h7fffffffffffffff;
    av[4]=64'h7fffffffffffffff;bv[4]=64'h8000000000000000;
    av[5]=64'hffffffffffffffff;bv[5]=0;
    av[6]=0;bv[6]=64'hffffffffffffffff;
    av[7]=64'hffffffffffffffff;bv[7]=64'hffffffffffffffff;
    condition[0]=0;condition[1]=1;condition[2]=4;condition[3]=5;condition[4]=6;condition[5]=7;
    for(c=0;c<6;c+=1)for(v=0;v<8;v+=1)begin
      clean();load_owner(1,32,3,0,0);load_owner(2,33,3,0,0);
      off=(v&1)?-4096:4094;len=(v&2)?2:4;pc=64'h80002000;
      inst=b_inst(condition[c],off);tk=cond(condition[c],av[v],bv[v]);
      branch_birth(3,inst,pc,len,0,3'b011);
      offer(3,1,av[v],2,bv[v],0);
      npc=tk ? pc+64'(off) : pc+64'(len);
      verify_branch(3,npc,tk,1,0,0);branch_gap(3,1);
    end
    // Positive/negative J/I offsets, rd=x0/nonzero, rs1=rd old physical source,
    // compressed canonical instruction with original two-byte link length.
    for(mode=0;mode<8;mode+=1)begin
      clean();load_owner(1,32,3,0,0);pc=64'h80003000;len=(mode&1)?2:4;dst=(mode&2)?34:0;
      off=(mode&1)?-2048:2047;
      if(mode<4)begin
        inst=i_inst(off,dst?5'd1:5'd0);branch_birth(3,inst,pc,len,dst,1);
        offer(1,1,64'h90000802,0,0,0);npc=(64'h90000802+64'(off))&~64'd1;
        verify_branch(3,npc,1,0,1,dst);branch_gap(3,1);
      end else begin
        off=(mode&1)?-1048576:1048574;inst=j_inst(off,dst?5'd1:5'd0);
        branch_birth(3,inst,pc,len,dst,0);npc=pc+64'(off);
        verify_branch(3,npc,1,0,0,dst);
        check(execute_cycle[3]-issue_cycle[3]==(BRANCH_ADMIT?1:2),"source-free JAL direct gap");
      end
    end
    clean();load_owner(1,32,3,0,0);load_owner(2,33,3,0,0);
    offer(3,1,64'hffffffffffffffff,2,0,0);await_done(1);await_done(2);repeat(3)tick();
    branch_birth(3,b_inst(4,-2),64'h80004000,4,0,3);
    verify_branch(3,64'h80003ffe,1,1,0,0);prf_cases+=1;
    check(execute_cycle[3]-issue_cycle[3]==((BRANCH_ADMIT&&GPR_READ)?1:2),"ready PRF branch latency");

    // Canonical birth order supplies two simultaneous branch candidates.
    clean();load_owner(1,32,3,0,0);
    birth=0;birth_tag={9'd8,9'd3};birth_class={`R64_C_BRANCH,`R64_C_BRANCH};birth_write=0;
    birth_used={3'b001,3'b001};birth_src={6'b0,6'b0,6'd32,6'b0,6'b0,6'd32};birth_src_fp=0;
    expected_uop[8]=branch_uop(i_inst(4,0),64'h80005000,4);
    expected_uop[3]=branch_uop(i_inst(-4,0),64'h80005010,2);branch_expected[8]=1;branch_expected[3]=1;
    birth_uop={expected_uop[8],expected_uop[3]};#1;check(birth_ready==3,"dual branch birth");birth=3;tick();birth=0;
    offer(1,1,64'h80001001,0,0,0);
    verify_branch(3,64'h80000ffc,1,0,1,0);verify_branch(8,64'h80001004,1,0,1,0);
    check(execute_cycle[3]<execute_cycle[8],"younger branch bypassed older lane");
    $display("BRANCH_PAIR older_lane=%0d younger_lane=%0d older_execute=%0d younger_execute=%0d",
      execute_lane[3],execute_lane[8],execute_cycle[3],execute_cycle[8]);
    ordered_pairs+=1;


    clean();load_owner(1,32,3,0,0);repeat(8)tick();
    check(mem_count[1]==1,"producer load bound before response");mem_ready=0;
    branch_birth(3,i_inst(4,0),64'h80006000,4,0,1);
    begin
      reg [U-1:0] mu;
      mu=0;mu[`R64_U_FUNC]=8'h23;
      birth_one(4,`R64_C_MEM,0,0,0,32,1,mu);
    end
    offer(1,1,64'h80001001,0,0,0);
    verify_branch(3,64'h80001004,1,0,1,0);
    check(mem_count[4]==0&&issue_cycle[4]>=0,"younger MEM was not held before branch recovery");
    recovery[32]=1;recovery[4]=1;tick();recovery=0;
    mem_ready=3;repeat(5)tick();
    check(mem_count[4]==0&&execute_cycle[4]<0,"older branch recovery leaked younger MEM acceptance");

    // Reclaim producer/consumer slots, then return the old full tag before
    // the new generation's real value. Only the new owner may qualify RR.
    clean();load_owner(1,32,3,0,0);branch_birth(3,i_inst(8,0),64'h80007000,4,0,1);
    repeat(4)tick();recovery[32]=1;recovery[1]=1;recovery[3]=1;tick();recovery=0;repeat(3)tick();
    load_owner(33,32,3,0,0);branch_birth(35,i_inst(-8,0),64'h80008000,2,0,1);
    offer(1,1,64'hdeadbeef,0,0,0);repeat(4)tick();
    check(execute_cycle[3]<0&&execute_cycle[35]<0&&resolve_count[35]==0,"stale producer full tag qualified branch");
    offer(1,33,64'h80009001,0,0,0);
    verify_branch(35,64'h80008ff8,1,0,1,0);branch_gap(35,33);

    $display("[PASS] tb_r64_rr_complete_branch_admit enabled=%0d gpr=%0d checks=%0d branches=%0d load_gaps=%0d prf=%0d ordered_pairs=%0d direct=%0d fallback=%0d branch_direct=%0d branch_fallback=%0d",
      BRANCH_ADMIT,GPR_READ,checks,branches,latency_checks,prf_cases,ordered_pairs,directactual,fallback,branch_direct,branch_fallback);
    $finish;
  end
endmodule
