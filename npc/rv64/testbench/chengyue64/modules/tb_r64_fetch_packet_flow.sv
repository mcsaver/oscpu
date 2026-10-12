
`timescale 1ns/1ps
module tb_r64_fetch_packet_flow;
  parameter FLOW=1;
  reg clk=0;always #5 clk=~clk;
  reg rst=1,run=0,redirect=0,req_ready=0,rsp_valid=0,packet_ready=0,learn=0;
  reg [63:0] target=64'h80000400;
  wire req_valid,rsp_ready,packet_valid;
  wire [63:0] req_pc,packet_pc;
  reg [127:0] rsp_data=0;
  reg rsp_fault=0;
  reg [4:0] rsp_cause=0;
  reg [7:0] rsp_mask=0;
  wire [127:0] packet_data;
  wire packet_fault,plan_valid,plan_word;
  wire [4:0] packet_cause;
  wire [7:0] packet_mask;
  wire [2:0] plan_offset;
  wire [62:0] plan_target;
  R64FetchStream #(.EARLY_PREDICT(1),.PACKET_EMPTY_FLOW(FLOW)) dut(
    .clk_i(clk),.rst_i(rst),.run_i(run),.redirect_i(redirect),
    .redirect_block_i(target[63:4]),.redirect_offset_i(target[3:1]),
    .invalidate_i(1'b0),.learn_i(learn),.learn_pc_i(64'h80000004),
    .learn_length_i(4'd4),.learn_target_i(64'h80000100),
    .resolve_i(1'b0),.resolve_pc_i(64'd0),.resolve_taken_i(1'b0),
    .resolve_target_i(64'd0),.repair_i(1'b0),.repair_block_i(64'd0),
    .req_valid_o(req_valid),.req_ready_i(req_ready),.req_pc_o(req_pc),
    .rsp_valid_i(rsp_valid),.rsp_ready_o(rsp_ready),.rsp_data_i(rsp_data),
    .rsp_fault_i(rsp_fault),.rsp_cause_i(rsp_cause),.rsp_access_mask_i(rsp_mask),
    .packet_valid_o(packet_valid),.packet_ready_i(packet_ready),.packet_pc_o(packet_pc),
    .packet_data_o(packet_data),.packet_fault_o(packet_fault),.packet_cause_o(packet_cause),
    .packet_access_mask_o(packet_mask),.packet_plan_valid_o(plan_valid),
    .packet_plan_offset_o(plan_offset),.packet_plan_word_o(plan_word),
    .packet_plan_target_o(plan_target));
  reg [63:0] request_pc[0:127],expected_pc[0:127];
  reg request_stale[0:127],request_plan[0:127],expected_plan[0:127];
  reg [141:0] expected_result[0:127];
  integer request_head=0,request_tail=0,packet_head=0,packet_tail=0;
  integer response_edge[0:127],expected_gap[0:127];
  integer accepted=0,responses=0,packets=0,stale_responses=0,direct_measured=0;
  integer held_packets=0,full_seen=0,redirect_response=0,simultaneous=0,old_priority=0;
  reg held_request=0,held_stale=0,held_packet=0;
  reg [63:0] held_pc;
  reg [273:0] held_payload;
  integer i,c;
  always @(posedge clk)if(!rst)begin
    c=int'($time/10);
    if(held_request&&(!req_valid||req_pc!==held_pc))$fatal(1,"held request changed");
    if(held_packet&&!redirect)begin
      if(!packet_valid || {packet_pc,packet_data,packet_fault,packet_cause,packet_mask,
        plan_valid,plan_offset,plan_word,plan_target}!==held_payload)
        $fatal(1,"blocked direct packet changed when captured into Q");
      held_packets=held_packets+1;
    end
    held_packet=packet_valid&&!packet_ready&&!redirect;
    held_payload={packet_pc,packet_data,packet_fault,packet_cause,packet_mask,
        plan_valid,plan_offset,plan_word,plan_target};
    held_request=req_valid&&!req_ready;held_pc=req_pc;
    if(redirect)begin
      packet_head=packet_tail;
      for(i=request_head;i<request_tail;i=i+1)request_stale[i]=1;
      if(req_valid&&!req_ready)held_stale=1;
      if(packet_valid)$fatal(1,"redirect published packet");
      if(rsp_valid&&rsp_ready)redirect_response=redirect_response+1;
    end
    // Response model is ordered; no dependence on internal owner metadata.
    if(rsp_valid&&rsp_ready)begin
      if(request_head==request_tail)$fatal(1,"unowned cache response");
      if(request_stale[request_head]||redirect)stale_responses=stale_responses+1;
      else begin
        expected_pc[packet_tail]=request_pc[request_head];
        expected_plan[packet_tail]=request_plan[request_head];
        expected_result[packet_tail]={rsp_data,rsp_fault,rsp_cause,rsp_mask};
        response_edge[packet_tail]=c;
        expected_gap[packet_tail]=(packet_head==packet_tail&&packet_ready)?(FLOW?0:1):-1;
        packet_tail=packet_tail+1;
      end
      request_head=request_head+1;responses=responses+1;
    end
    if(packet_valid&&packet_ready)begin
      if(packet_head==packet_tail)$fatal(1,"duplicate or stale packet");
      if(packet_pc!==expected_pc[packet_head] ||
          {packet_data,packet_fault,packet_cause,packet_mask}!==expected_result[packet_head] ||
          plan_valid!==expected_plan[packet_head])
        $fatal(1,"packet metadata separated from accepted owner");
      if(plan_valid&&{plan_offset,plan_word,plan_target}!=={3'd2,1'b1,63'h40000080})
        $fatal(1,"predicted plan separated from packet");
      if(expected_gap[packet_head]>=0)begin
        if(c-response_edge[packet_head]!=expected_gap[packet_head])
          $fatal(1,"response-to-packet edge mismatch got%0d expected%0d",
              c-response_edge[packet_head],expected_gap[packet_head]);
        direct_measured=direct_measured+1;
      end
      packet_head=packet_head+1;packets=packets+1;
    end
    if(req_valid&&req_ready)begin
      request_pc[request_tail]=req_pc;
      request_stale[request_tail]=held_stale||redirect;
      request_plan[request_tail]=req_pc==64'h80000000;
      request_tail=request_tail+1;accepted=accepted+1;held_stale=0;
    end
    if(req_valid&&req_ready&&rsp_valid&&rsp_ready)simultaneous=simultaneous+1;
    if(rsp_valid&&rsp_ready&&packet_valid&&packet_ready&&dut.packet_count_q!=0)
      old_priority=old_priority+1;
    if(dut.packet_count_q==4)full_seen=full_seen+1;
    if(request_tail-request_head>4)$fatal(1,"request reservation exceeded four");
  end
  task automatic send_response;
    integer id;
    begin
      @(negedge clk);#1;id=request_head;
      rsp_valid=1;rsp_data={64'h1234000000000000+64'(id),64'habcd000000000000+64'(id)};
      rsp_fault=id[0];rsp_cause=5'(id+1);rsp_mask=8'(id*17);
      @(posedge clk);if(!rsp_ready)$fatal(1,"owned cache response backpressured");
      @(negedge clk);#1;rsp_valid=0;
    end
  endtask
  integer goal,stale_before;
  initial begin
    repeat(3)@(negedge clk);#1;rst=0;learn=1;
    @(negedge clk);#1;learn=0;run=1;req_ready=1;
    wait(accepted==4);@(negedge clk);#1;run=0;req_ready=0;
    repeat(4)send_response();
    repeat(3)@(negedge clk);
    #1;if(dut.packet_count_q!=4||accepted!=4||request_head!=request_tail)
      $fatal(1,"four-credit/full queue setup");
    // Old Q remains first when a new cache response arrives; an accepted
    // request and an older response can exchange independent owner credits.
    packet_ready=1;run=1;req_ready=1;
    wait(accepted==5);@(negedge clk);#1;run=0;
    rsp_valid=1;rsp_data=128'h123456789abcdef0fedcba9876543210;
    rsp_fault=0;rsp_cause=5'd3;rsp_mask=8'ha5;
    @(negedge clk);#1;rsp_valid=0;req_ready=0;
    while(request_head<request_tail)send_response();
    wait(packets==responses);@(negedge clk);#1;packet_ready=0;
    // Two fresh empty responses, including one real fault/access mask.
    run=1;req_ready=1;goal=accepted+2;
    wait(accepted==goal);@(negedge clk);#1;run=0;req_ready=0;packet_ready=1;
    send_response();repeat(2)@(negedge clk);send_response();repeat(3)@(negedge clk);
    // Keep one held request through redirect and consume an old response on
    // the redirect edge. Neither may be reclassified into the new stream.
    run=1;req_ready=1;goal=accepted+2;
    wait(accepted==goal);@(negedge clk);#1;req_ready=0;packet_ready=0;
    wait(req_valid);@(negedge clk);#1;
    redirect=1;rsp_valid=1;rsp_data=128'hdeadbeef;stale_before=stale_responses;
    @(negedge clk);#1;redirect=0;rsp_valid=0;
    req_ready=1;run=0;
    @(negedge clk);#1;req_ready=0;
    while(request_head<request_tail)send_response();
    repeat(3)@(negedge clk);
    #1;if(stale_responses<=stale_before||packet_valid||dut.packet_count_q!=0)
      $fatal(1,"redirect failed to drain old responses");
    // New target must remain usable after the held old request has drained.
    run=1;req_ready=1;goal=accepted+2;
    wait(accepted==goal);@(negedge clk);#1;run=0;req_ready=0;packet_ready=1;
    send_response();send_response();repeat(4)@(negedge clk);
    #1;
    if(direct_measured<4||held_packets<3||full_seen<1||redirect_response<1||
        simultaneous<1||old_priority<1||packet_head!=packet_tail||responses+ (request_tail-request_head)!=accepted)
      $fatal(1,"packet flow coverage measured%0d held%0d full%0d redirect%0d",
          direct_measured,held_packets,full_seen,redirect_response);
    $display("[PASS] tb_r64_fetch_packet_flow flow=%0d accepted=%0d responses=%0d packets=%0d stale=%0d measured=%0d gap=%0d held=%0d full=%0d redirect_response=%0d simultaneous=%0d old_priority=%0d",
        FLOW,accepted,responses,packets,stale_responses,direct_measured,FLOW?0:1,
        held_packets,full_seen,redirect_response,simultaneous,old_priority);
    $finish;
  end
  initial begin #100000;$fatal(1,"packet flow timeout");end
endmodule
