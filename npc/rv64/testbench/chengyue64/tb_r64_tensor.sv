`timescale 1ns/1ps
module tb_r64_tensor;
 reg clk_i=0;always #5 clk_i=~clk_i;
 reg rst_i=1,cmd_valid_i=0;wire cmd_ready_o;
 reg [8:0] cmd_tag_i=0;reg [63:0] cmd_i=0,operand_i=0;
 reg pair_i=0;reg [7:0] class_i=0;
 wire terminal_valid_o;reg terminal_ready_i=0;wire [8:0] terminal_tag_o;
 wire error_o;wire [7:0] error_code_o;wire dma_invalidate_o,busy_o,protocol_error_o;
 wire req_valid_o;reg req_ready_i=0;wire req_write_o;
 wire [63:0] req_addr_o,req_wdata_o;wire [7:0] req_wstrb_o;wire [8:0] req_tag_o;
 reg rsp_valid_i=0;wire rsp_ready_o;reg [63:0] rsp_rdata_i=0;reg rsp_error_i=0;reg [8:0] rsp_tag_i=0;
 wire npu_error_o;wire [7:0] npu_error_code_o;
 wire [63:0] command_count_o,completion_count_o,macro_command_count_o;
 wire descriptor_resident_o;wire [5:0] descriptor_expected_o;
 R64TensorLink #(.LMEM_BYTES(512)) dut(.*);
 reg [7:0] memory[0:65535];
 reg [63:0] desc[0:29];
 reg [31:0] random_q=32'h79bb3103;
 reg pending=0,pwrite=0,fail_write=0,inject_bad_tag=0;
 reg [63:0] paddr,pdata;reg [7:0] pstrb;reg [8:0] ptag;
 integer delay_q=0,cycles=0,commands=0,reads=0,writes=0,invalidates=0;
 integer k,i,j,wait_cycles,inv_before;
 reg hold_req=0;reg [145:0] held_req;
 reg hold_terminal=0;reg [17:0] held_terminal;
 function [63:0] config_bits(input integer idx);
  config_bits={32'b0,7'd5,5'(idx),5'd1,3'd4,5'd31,7'h5b};
 endfunction
 task send(input [63:0] bits,input [63:0] value,input bit pair,
           input [8:0] tag,input bit expected_error,input [7:0] code);
  begin
   @(negedge clk_i);cmd_valid_i=1;cmd_i=bits;operand_i=value;pair_i=pair;
   class_i=pair?8'd1:8'd0;cmd_tag_i=tag;
   @(posedge clk_i);while(!cmd_ready_o)@(posedge clk_i);
   @(negedge clk_i);cmd_valid_i=0;
   wait_cycles=0;
   while(!terminal_valid_o)begin @(negedge clk_i);wait_cycles+=1;if(wait_cycles>20000)$fatal(1,"terminal timeout");end
   if(error_o!==expected_error||error_code_o!==code||terminal_tag_o!==tag)
    $fatal(1,"terminal mismatch cmd=%h tag=%h/%h error=%b/%b code=%h/%h",
       bits,terminal_tag_o,tag,error_o,expected_error,error_code_o,code);
   repeat(5)@(negedge clk_i);
   terminal_ready_i=1;@(posedge clk_i);@(negedge clk_i);terminal_ready_i=0;commands+=1;
  end
 endtask
 task descriptor(input bit valid_kernel);
  begin
   for(i=0;i<30;i=i+1)desc[i]=0;
   desc[0]={32'h11,(valid_kernel?32'h514e0010:32'hdeadbeef)};desc[1]={32'd1,32'h43414e01};
   desc[2]=64'h100000003;desc[3]=64'h8877665544332211;
   desc[4]=64'hfa091823bada0765;desc[5]={32'd1,32'd1};
   desc[6]=64'h1122334455667788;desc[7]=64'h99aabbccddeeff00;
   desc[9]={32'd1,32'd0};desc[10]=64'h1000;desc[11]=64'h4000;
   desc[13]=64'h8000;desc[15]=16;desc[16]=1;
   desc[19]=64;desc[20]=64;desc[22]=64;
   desc[23]=64'h1000;desc[24]=64;desc[25]=64'h97;
   desc[26]=64'h4000;desc[27]=64;desc[28]=64'h8000;desc[29]=64;
   for(i=0;i<30;i=i+1)send(config_bits(i),desc[i],0,9'h100+9'(i),0,0);
   if(!descriptor_resident_o||descriptor_expected_o!=30)$fatal(1,"descriptor did not become resident");
  end
 endtask
 always @(negedge clk_i)if(!rst_i)begin
  random_q={random_q[30:0],random_q[31]^random_q[21]^random_q[1]^random_q[0]};
  req_ready_i=!pending&&!rsp_valid_i&&random_q[2];
 end
 always @(posedge clk_i)if(!rst_i)begin
  cycles+=1;
  if(hold_req&&(!req_valid_o||{req_tag_o,req_write_o,req_addr_o,req_wdata_o,req_wstrb_o}!==held_req))
   $fatal(1,"GMEM request unstable");
  hold_req=req_valid_o&&!req_ready_i;held_req={req_tag_o,req_write_o,req_addr_o,req_wdata_o,req_wstrb_o};
  if(hold_terminal&&(!terminal_valid_o||{terminal_tag_o,error_o,error_code_o}!==held_terminal))
   $fatal(1,"CPU terminal unstable");
  hold_terminal=terminal_valid_o&&!terminal_ready_i;held_terminal={terminal_tag_o,error_o,error_code_o};
  if(dma_invalidate_o)begin
   if(pending||rsp_valid_i||terminal_valid_o)$fatal(1,"invalidate ordering violated");
   invalidates+=1;
  end
  if(rsp_valid_i&&rsp_ready_o)begin
   rsp_valid_i<=0;pending<=0;
   if(pwrite)begin
    writes+=1;
    // An error response can follow a partial device effect. Invalidation must
    // still precede the CPU terminal; the checker never rolls this memory back.
    for(k=0;k<8;k=k+1)if(pstrb[k]&&(!rsp_error_i||k==0))memory[int'(paddr)+k]<=pdata[k*8+:8];
   end else reads+=1;
  end
  if(req_valid_o&&req_ready_i)begin
   if(req_addr_o>65528)$fatal(1,"GMEM out of bounds");
   pending<=1;delay_q<=int'(random_q[6:4])+1;pwrite<=req_write_o;
   paddr<=req_addr_o;pdata<=req_wdata_o;pstrb<=req_wstrb_o;ptag<=req_tag_o;
  end
  if(pending&&!rsp_valid_i)begin
   if(delay_q!=0)delay_q<=delay_q-1;
   else begin
    rsp_valid_i<=1;rsp_tag_i<=inject_bad_tag?(ptag^9'h100):ptag;
    rsp_error_i<=pwrite&&fail_write;
    for(k=0;k<8;k=k+1)rsp_rdata_i[k*8+:8]<=memory[int'(paddr)+k];
   end
  end
  if(protocol_error_o&&!inject_bad_tag)$fatal(1,"link protocol error");
  if(cycles>100000)$fatal(1,"simulation timeout");
 end
 initial begin
  inject_bad_tag=$test$plusargs("bad-tag");
  for(j=0;j<65536;j=j+1)memory[j]=0;
  for(j=0;j<16;j=j+1)begin
   {memory['h1003+4*j],memory['h1002+4*j],memory['h1001+4*j],memory['h1000+4*j]}=32'h3f800000;
   {memory['h4003+4*j],memory['h4002+4*j],memory['h4001+4*j],memory['h4000+4*j]}=32'h40000000;
  end
  repeat(4)@(negedge clk_i);rst_i=0;
  // Real scalar NPU config_bits, including CPU producer generation bit eight.
  send(64'h0a10405b,64'habcdef0123456789,0,9'h1a5,0,0);
  if(command_count_o!=1||completion_count_o!=1)$fatal(1,"scalar command bypassed NPU");
  send(config_bits(1),0,0,9'h025,1,18);
  send(config_bits(30),0,0,9'h125,0,0);
  descriptor(0);
  send(64'h0bf0305b0220305b,0,1,9'h1cf,1,14);
  if(!npu_error_o||reads!=0||writes!=0||invalidates!=0)$fatal(1,"static error leaked DMA");
  send(config_bits(0),0,0,9'h0cf,1,14);
  send(config_bits(30),0,0,9'h1cf,0,0);
  if(npu_error_o)$fatal(1,"recoverable error not cleared");
  descriptor(1);inv_before=invalidates;
  send(64'h0bf0305b0220305b,0,1,9'h1f5,0,0);
  if(invalidates!=inv_before+1||reads==0||writes==0)$fatal(1,"real DMA/invalidate missing");
  for(j=0;j<16;j=j+1)
   if({memory['h8003+4*j],memory['h8002+4*j],memory['h8001+4*j],memory['h8000+4*j]}!==32'h40400000)
    $fatal(1,"real RTL F32 add wrong lane=%0d",j);
  descriptor(1);fail_write=1;inv_before=invalidates;
  send(64'h0bf0305b0220305b,0,1,9'h095,1,8'h8a);
  if(invalidates!=inv_before+1)$fatal(1,"failed DMA write did not invalidate");
  send(config_bits(30),0,0,9'h195,1,8'h8a);
  if(!npu_error_o)$fatal(1,"fatal NPU state cleared");
  if(macro_command_count_o!=3)$fatal(1,"macro bypassed actual NPU");
  $display("[PASS] tb_r64_tensor");
  $display("commands=%0d real_npu_commands=%0d real_npu_completions=%0d macros=%0d raw_reads=%0d raw_writes=%0d invalidate=%0d cycles=%0d",
   commands,command_count_o,completion_count_o,macro_command_count_o,reads,writes,invalidates,cycles);
  $finish;
 end
endmodule
