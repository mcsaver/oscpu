
`timescale 1ns/1ps
`include "tb_r64_frontend.sv"
// Reuse the independent architectural instruction oracle and real
// FetchAccess/translation/I-cache/AXI fixture without replacing any stage.
module tb_r64_frontend_packet_flow;
  parameter FLOW=1;
  tb_r64_frontend #(.PACKET_EMPTY_FLOW(FLOW)) scenario();
  reg [63:0] expected_pc[0:8191];
  reg [141:0] expected_result[0:8191];
  reg [67:0] expected_plan[0:8191];
  integer born[0:8191],expected_gap[0:8191];
  integer head=0,tail=0,cycles,measured=0,min_gap=100,max_gap=-1;
  integer cache_responses=0,align_packets=0,stale=0,blocked_empty=0,full=0,plans=0;
  integer delta;
  always @(posedge scenario.clk)if(!scenario.rst)begin
    cycles=int'($time/10);
    if(scenario.dut.stream_redirect_w)head=tail;
    if(scenario.dut.cache_v_w&&scenario.dut.cache_r_w)begin
      cache_responses=cache_responses+1;
      if(scenario.dut.u_stream.stale_w)stale=stale+1;
      else begin
        expected_pc[tail]=scenario.dut.u_stream.owner_pc_q[scenario.dut.u_stream.owner_head_q];
        expected_plan[tail]=scenario.dut.u_stream.owner_plan_q[scenario.dut.u_stream.owner_head_q];
        expected_result[tail]={scenario.dut.cache_data_w,scenario.dut.cache_fault_w,
            scenario.dut.cache_cause_w,scenario.dut.cache_mask_w};
        born[tail]=cycles;
        expected_gap[tail]=(scenario.dut.u_stream.packet_count_q==0&&scenario.dut.packet_r_w)?
            (FLOW?0:1):-1;
        if(scenario.dut.u_stream.packet_count_q==0&&!scenario.dut.packet_r_w)
          blocked_empty=blocked_empty+1;
        tail=tail+1;
      end
    end
    if(scenario.dut.packet_v_w&&scenario.dut.packet_r_w)begin
      if(head==tail)$fatal(1,"real Frontend emitted duplicate/stale packet");
      if(scenario.dut.packet_pc_w!==expected_pc[head]||
          {scenario.dut.packet_data_w,scenario.dut.packet_fault_w,
            scenario.dut.packet_cause_w,scenario.dut.packet_mask_w}!==expected_result[head])
        $fatal(1,"real I-cache packet lost response or PC owner");
      if(scenario.dut.packet_plan_v_w!==expected_plan[head][67])
        $fatal(1,"real Frontend packet plan valid mismatch");
      if(scenario.dut.packet_plan_v_w)begin
        if({scenario.dut.packet_plan_offset_w,scenario.dut.packet_plan_word_w,
          scenario.dut.packet_plan_target_w}!==expected_plan[head][66:0])
          $fatal(1,"real Frontend packet plan metadata mismatch");
        plans=plans+1;
      end
      if(expected_gap[head]>=0)begin
        delta=cycles-born[head];
        if(delta!=expected_gap[head])
          $fatal(1,"real cache response -> Align edge gap%0d expected%0d",delta,expected_gap[head]);
        if(delta<min_gap)min_gap=delta;
        if(delta>max_gap)max_gap=delta;
        measured=measured+1;
      end
      align_packets=align_packets+1;head=head+1;
    end
    if(scenario.dut.u_stream.packet_count_q==4)full=full+1;
  end
  final begin
    if(measured<20||stale==0||plans==0)
      $fatal(1,"real Frontend packet flow coverage measured%0d stale%0d plans%0d",
          measured,stale,plans);
    $display("[PASS] tb_r64_frontend_packet_flow flow=%0d real_responses=%0d Align_packets=%0d measured=%0d gap=%0d..%0d plans=%0d stale=%0d blocked_empty=%0d full=%0d",
        FLOW,cache_responses,align_packets,measured,min_gap,max_gap,plans,stale,blocked_empty,full);
  end
endmodule
