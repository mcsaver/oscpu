`timescale 1ns/1ps
module tb_r64_regread_pipeline;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,flush=0;reg [31:0] km=0;
 reg [1:0] fire=0,orr=0,wv=0,wfp=0;
 reg [17:0] it=0;reg [63:0] ip=0;reg [5:0] ic=0,fp=0,used=0;
 reg [35:0] src=0;reg [11:0] wp=0;reg [127:0] wd=0;
 wire [1:0] ir,ov;wire [17:0] ot;wire [63:0] op;wire [383:0] operands;
 wire [9:0] out_slots;
 integer reserved;
 always @(*)begin
  reserved=0;
  for(integer lane=0;lane<2;lane=lane+1)begin
   if(dut.ingress_valid_q[lane]&&dut.ingress_class_q[lane]==4)reserved=reserved+1;
   for(integer n=0;n<2;n=n+1)
    if(n<dut.terminal_count_q[lane]&&dut.class_q[lane*2+((integer'(dut.terminal_head_q[lane])+n)%2)]==4)
     reserved=reserved+1;
  end
 end
 R64RegRead #(.PAYLOAD_W(32)) dut(
  .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(km),
  .in_fire_i(fire),.in_ready_o(ir),.in_tag_i(it),.in_payload_i(ip),.in_class_i(ic),
  .in_gpr_dst_i(12'b0),.in_src_preg_i(src),.in_src_fp_i(fp),.in_src_used_i(used),
  .wb_write_i(wv),.wb_fp_i(wfp),.wb_preg_i(wp),.wb_data_i(wd),
  .alu_bypass_valid_i(2'b0),.alu_bypass_preg_i(12'b0),.alu_bypass_data_i(128'b0),
  .out_valid_o(ov),.out_ready_i(orr),.out_tag_o(ot),.out_payload_o(op),.out_class_o(),
  .out_operand_o(operands),.out_gpr_dst_o(),.in_mem_slot_i({it[9+:5],it[0+:5]}),.out_mem_slot_o(out_slots));
 task tick;begin @(posedge clk);#1;end endtask
 task check;input good;input [511:0] msg;begin if(good!==1'b1)$fatal(1,"%0s",msg);end endtask
 task quiet;begin fire=0;wv=0;flush=1;tick();flush=0;km=0;orr=0;used=0;fp=0;end endtask
 task one;
  input integer lane,tag,cls;
  begin it[lane*9+:9]=9'(tag);ip[lane*32+:32]=32'(tag+100);
   ic[lane*3+:3]=3'(cls);fire=2'(1<<lane);#1;
   check(ir[lane],"ingress admission without credit");tick();fire=0;
  end
 endtask
 integer n;
 initial begin
  tick();rst=0;
  wv=3;wp={6'd2,6'd1};wd={64'd22,64'd11};tick();
  wfp=3;wd={64'd222,64'd111};tick();
  wv=1;wp=3;wd=333;tick();wv=0;wfp=0;
  fire=3;it={9'd1,9'd0};ip=0;ic=0;tick();fire=0;tick();
  check(ov==3,"initial independently held outputs");
  // Fill the second terminal entry; the next owner must finish its physical
  // read in ingress while both owned terminal packets stay blocked.
  fire=3;it={9'd5,9'd4};tick();fire=0;tick();
  fire=3;it={9'd3,9'd2};ic=0;used=6'b011111;fp=6'b000111;
  src={6'd0,6'd2,6'd1,6'd3,6'd2,6'd1};tick();fire=0;
  check(dut.fp_ports==3,"registered input bundle FP read budget");
  tick();check(dut.operand_ready_q==3,"blocked outputs did not finish local reads");
  wv=1;wfp=1;wp=1;wd=999;tick();wv=0;
  repeat(8)begin tick();check(dut.fp_ports==0&&dut.operand_ready_q==3,
      "completed blocked owner kept claiming FP ports");end
  orr=3;tick();
  check(ov==3&&ot=={9'd5,9'd4},"second terminal owner lost under pressure");
  tick();
  check(ov==3&&ot=={9'd3,9'd2}&&operands[63:0]==111&&operands[127:64]==222&&
      operands[191:128]==333&&operands[255:192]==11&&operands[319:256]==22,
      "held ingress data/owner changed after PRF update");
  quiet();
  // Dispatch reserved both memory owners. Independent bind must drain lane1
  // even while the older memory packet is behind a stalled integer in lane0.
  one(0,0,0);tick();one(0,2,4);one(1,3,4);tick();
  check(ov==3&&reserved==2&&ot[9+:9]==3&&out_slots[5+:5]==3,"visible independent MEM owner");
  orr=2;tick();
  repeat(8)begin check(ov==1&&reserved==1,
      "independent MEM bind lost or duplicated hidden owner");tick();end
  orr=3;tick();check(ov==1&&ot[0+:9]==2&&out_slots[0+:5]==2&&reserved==1,"hidden older MEM owner");
  tick();check(reserved==0,"actual MEM bind did not release real RR owner");
  quiet();
  // Kill a lane1 owner and reuse the same ROB slot with a new generation.
  // The new LSQ sideband remains independent of the stalled other lane.
  one(0,0,0);tick();one(0,2,4);one(1,3,4);tick();
  km=8;tick();km=0;one(1,35,4);tick();
  check(reserved==2&&ov==3&&ot[9+:9]==35&&out_slots[5+:5]==3,
      "old killed slot poisoned or exposed wrong new generation");
  orr=2;tick();check(reserved==1&&ov==1,"new generation independent bind");
  orr=3;tick();check(ov[0]&&ot[0+:9]==2&&!ov[1],"hidden old MEM identity");
  tick();check(reserved==0,"generation/hidden owner conservation");
  quiet();
  // Six MEM owners fit across both lane terminals and ingress. Credits are
  // registered-state only: downstream READY cannot change them this cycle.
  ic={3'd4,3'd4};fire=3;
  for(n=0;n<3;n=n+1)begin
    check(ir==3,"six-owner MEM reservation admission");
    it={9'(2*n+1),9'(2*n)};tick();
  end
  fire=0;tick();
  check(reserved==6&&ir==0&&ov==3&&ot=={9'd1,9'd0},"six-owner full reservation");
  orr=3;#1;check(ir==0,"READY crossed the Q-only credit boundary");
  tick();check(reserved==4&&ir==3&&ot=={9'd3,9'd2},"first dual MEM release");
  tick();check(reserved==2&&ot=={9'd5,9'd4},"second dual MEM release");
  tick();check(reserved==0&&ov==0,"six-owner MEM FIFO conservation");
  quiet();
  $display("[PASS] tb_r64_regread_pipeline held-read FP3/GPR4 hidden-MEM independent-bind cancel-generation");
  $finish;
 end
endmodule
