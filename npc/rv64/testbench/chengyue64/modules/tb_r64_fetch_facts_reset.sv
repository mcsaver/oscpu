`timescale 1ns/1ps
module tb_r64_fetch_facts_reset;
reg clk=0;always #5 clk=!clk;
reg rst=1,valid=0,ready=0;
reg [129:0] facts=0;reg [7:0] mask=0;
wire [1:0] reqready,rspvalid,fault,cmdvalid,beatready;
wire [127:0] data[0:1];wire [4:0] cause[0:1];wire [7:0] outmask[0:1],len[0:1];
wire [63:0] addr[0:1];wire [2:0] size[0:1];
R64ICache #(.PREPARED_PROTECTION(1)) dut(
.clk_i(clk),.rst_i(rst),.invalidate_i(1'b0),.req_valid_i(valid),.req_ready_o(reqready[0]),
.req_paddr_i(64'h80000000),.req_uncached_i(1'b0),.req_fault_i(1'b1),.req_cause_i(5'd12),
.req_access_mask_i(mask),.req_protection_facts_i(facts),
.rsp_valid_o(rspvalid[0]),.rsp_ready_i(ready),.rsp_data_o(data[0]),.rsp_fault_o(fault[0]),
.rsp_cause_o(cause[0]),.rsp_access_mask_o(outmask[0]),.cmd_valid_o(cmdvalid[0]),.cmd_ready_i(1'b0),
.cmd_addr_o(addr[0]),.cmd_len_o(len[0]),.cmd_size_o(size[0]),
.beat_valid_i(1'b0),.beat_ready_o(beatready[0]),.beat_data_i(64'b0),.beat_resp_i(2'b0),.beat_last_i(1'b0));
R64ICacheReference refdut(
.clk_i(clk),.rst_i(rst),.invalidate_i(1'b0),.req_valid_i(valid),.req_ready_o(reqready[1]),
.req_paddr_i(64'h80000000),.req_uncached_i(1'b0),.req_fault_i(1'b1),.req_cause_i(5'd12),
.req_access_mask_i(mask),.rsp_valid_o(rspvalid[1]),.rsp_ready_i(ready),.rsp_data_o(data[1]),
.rsp_fault_o(fault[1]),.rsp_cause_o(cause[1]),.rsp_access_mask_o(outmask[1]),
.cmd_valid_o(cmdvalid[1]),.cmd_ready_i(1'b0),.cmd_addr_o(addr[1]),.cmd_len_o(len[1]),.cmd_size_o(size[1]),
.beat_valid_i(1'b0),.beat_ready_o(beatready[1]),.beat_data_i(64'b0),.beat_resp_i(2'b0),.beat_last_i(1'b0));
integer phase,k,full_checks=0,reset_checks=0,post_responses=0;
task step;input v;input integer which;input reset;input drain;
begin
 @(negedge clk);valid=v;rst=reset;ready=drain;facts=0;mask=0;
 case(which)
  1:begin facts[0]=1;facts[16]=1;mask=8'h03;end
  2:begin facts[0]=1;facts[16]=1;facts[32]=1;facts[48]=1;mask=8'h0f;end
  3:begin facts[129]=1;mask=8'hff;end
 endcase
 @(posedge clk);#1;
 if(reqready[0]!==reqready[1]||rspvalid[0]!==rspvalid[1]||
    {data[0],fault[0],cause[0],outmask[0]}!=={data[1],fault[1],cause[1],outmask[1]}||
    cmdvalid!=0||beatready!=0)$fatal(1,"facts reset changed parent observable");
 if(reset)begin
  if(dut.g_protection_finish.lookup_index_q!==0||dut.g_protection_finish.tail_q!==0||
     dut.effective_mask_w!==0||dut.lookup_valid_q||dut.overflow_valid_q)
   $fatal(1,"facts reset visible owner state");
  reset_checks=reset_checks+1;
 end else if(rspvalid[0]&&ready)post_responses=post_responses+1;
end endtask
initial begin
 for(phase=0;phase<4;phase=phase+1)begin
  step(0,3,1,0);step(0,3,0,0);
  step(1,1,0,0);step(1,2,0,0);step(1,3,0,0);
  if(!dut.lookup_valid_q||!dut.overflow_valid_q||!rspvalid[0])
   $fatal(1,"did not fill lookup + overflow with held response");
  full_checks=full_checks+1;
  step(0,2,1,0);step(0,3,0,1);
  for(k=0;k<6;k=k+1)step(1,1+(k%3),0,1);
  step(0,0,0,1);step(0,0,0,1);
 end
 if(full_checks!=4||reset_checks!=8||post_responses!=24)$fatal(1,"facts reset coverage");
 $display("[PASS] tb_r64_fetch_facts_reset full_owners=%0d reset=%0d post_response=%0d",full_checks,reset_checks,post_responses);
 $finish;
end
endmodule
