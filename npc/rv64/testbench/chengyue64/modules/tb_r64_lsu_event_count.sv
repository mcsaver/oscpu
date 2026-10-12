`timescale 1ns/1ps
`include "R64Protocol.vh"
module tb_r64_lsu_event_count;
  reg clk=0;
  // Pure combinational exhaustive slice; dynamic RR fairness is checked by
  // tb_r64_lsu_network, with stimuli driven away from clock edges.
  reg rst=1;
  reg [5:0] occupied=0,live=0,before_mask=0;
  reg [1:0] credit=0;
  reg [53:0] tags=0;
  reg [839:0] packets=0;
  wire [5:0] take;
  wire [1:0] fire, selected_live;
  wire [17:0] selected_tags;
  wire [279:0] selected_packets;
  R64LsuCompletionArbiter dut(
    .clk_i(clk),.rst_i(rst),.source_occupied_i(occupied),.source_live_i(live),
    .source_tag_i(tags),.source_result_i(packets),.source_take_o(take),
    .completion_credit_i(credit),.completion_fire_o(fire),.selected_live_o(selected_live),
    .completion_tag_o(selected_tags),.completion_result_o(selected_packets));
  integer b,v,c,k,i,p,first,second,cases=0;
  reg [5:0] expected_take;
  reg [1:0] expected_fire, expected_selected_live;
  reg [17:0] expected_tags;
  reg [279:0] expected_packets;
  initial begin
    for(i=0;i<6;i=i+1) begin
      tags[i*9+:9]=9'(i+1); packets[i*140+:140]=140'h1234567890+i;
    end
    #1; rst=0;
    force dut.before_q=before_mask;
    for(b=0;b<64;b=b+1)
    for(v=0;v<64;v=v+1)
    for(c=0;c<4;c=c+1) begin
      before_mask=6'(b); occupied=6'(v); credit=2'(c);
      first=-1; second=-1;
      // Independent software order: unvisited sources first, index order
      // within each RR partition. Cancellation never changes this ordering.
      for(p=0;p<2;p=p+1)
      for(i=0;i<6;i=i+1)
        if(occupied[i] && before_mask[i]==p[0]) begin
          if(first<0) first=i; else if(second<0) second=i;
        end
      expected_take=0; expected_tags=0; expected_packets=0;
      if(first>=0) begin
        expected_tags[0+:9]=9'(first+1);
        expected_packets[0+:140]=140'h1234567890+first;
        if(credit[0]) expected_take[first]=1;
      end
      if(second>=0) begin
        expected_tags[9+:9]=9'(second+1);
        expected_packets[140+:140]=140'h1234567890+second;
        if(credit[1]) expected_take[second]=1;
      end
      for(k=0;k<4;k=k+1) begin
        case(k)
          0:live=occupied;
          1:live=0;
          2:live=occupied & 6'b010101;
          3:live=occupied & 6'b101010;
        endcase
        expected_fire=0; expected_selected_live=0;
        if(first>=0) expected_selected_live[0]=live[first];
        if(second>=0) expected_selected_live[1]=live[second];
        if(first>=0) expected_fire[0]=live[first] && credit[0];
        if(second>=0) expected_fire[1]=live[second] && credit[1];
        #1;
        if(take!==expected_take || fire!==expected_fire ||
           selected_live!==expected_selected_live ||
           selected_tags!==expected_tags || selected_packets!==expected_packets)
          $fatal(1,"arbiter occupancy/live isolation before=%h occupied=%h live=%h credit=%h",
                 before_mask,occupied,live,credit);
        cases=cases+1;
      end
    end
    release dut.before_q;
    $display("[PASS] tb_r64_lsu_event_count independent_selector_oracle cases=%0d",cases);
    $finish;
  end
endmodule
