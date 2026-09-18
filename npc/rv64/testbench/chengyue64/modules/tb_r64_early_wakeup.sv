`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_early_wakeup #(parameter EARLY_ACCEPT=0);
 localparam U=`R64_UOP_W,R=`R64_RESULT_W;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,flush=0;reg [31:0] km=0;
 reg [1:0] fire=0;wire [1:0] credit,rv,rr,early,av;
 reg [17:0] tag=0;reg [2*U-1:0] uop=0;reg [5:0] cls=0;
 reg [11:0] dst=0;reg [35:0] src=0;reg [5:0] used=0;
 wire [9:0] memslot;wire [17:0] rt;wire [2*U-1:0] ru;wire [5:0] rc;wire [11:0] rd,ep,ap;wire [383:0] operand;
 wire [11:0] shiftamount;wire [9:0] addsource;wire [41:0] branchimm;wire [9:0] branchcontrol;
 wire [1:0] rawearly,rawav;
 wire [73:0] alucontrol;wire [17:0] earlytag;
 wire [127:0] ad;wire [4:0] resultv;reg [4:0] resultr=0;wire [44:0] resulttag;wire [5*R-1:0] resultdata;
 reg init=0;reg [5:0] initpreg=5;reg [63:0] initdata=10;
 reg [1:0] wvalid=0;reg [11:0] wpreg=0;reg [127:0] wdata=0;reg [17:0] wtag=0;
 wire [1:0] livewb={wvalid[1]&&!km[wtag[9+:5]],wvalid[0]&&!km[wtag[0+:5]]}&{2{!flush}};
 wire [1:0] ww=init ? 2'b01:livewb;
 wire [11:0] wp=init ? {6'b0,initpreg}:wpreg;
 wire [127:0] wd=init ? {64'b0,initdata}:wdata;
 R64RegRead #(.PAYLOAD_W(U)) registers(.in_mem_slot_i(10'b0),.out_mem_slot_o(memslot),
 .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(km),.in_fire_i(fire),.in_ready_o(credit),
 .in_tag_i(tag),.in_payload_i(uop),.in_class_i(cls),.in_gpr_dst_i(dst),
 .in_src_preg_i(src),.in_src_fp_i(6'b0),.in_src_used_i(used),
 .wb_write_i(ww),.wb_fp_i(2'b0),.wb_preg_i(wp),.wb_data_i(wd),
 .alu_bypass_valid_i(av),.alu_bypass_preg_i(ap),.alu_bypass_data_i(ad),
 .out_alu_control_o(alucontrol),.out_add_source_o(addsource),.out_shift_amount_o(shiftamount),.out_branch_imm_o(branchimm),.out_branch_control_o(branchcontrol),.out_valid_o(rv),.out_ready_i(rr),.out_tag_o(rt),.out_payload_o(ru),.out_class_o(rc),
 .out_operand_o(operand),.out_gpr_dst_o(rd));
 R64Execute #(.EARLY_ALU_WAKE(EARLY_ACCEPT)) execute(.clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(km),.rob_head_i(5'b0),
 .in_mem_slot_i(memslot),.lsu_slot_o(),.in_alu_control_i(alucontrol),.in_add_source_i(addsource),.in_shift_amount_i(shiftamount),.in_branch_imm_i(branchimm),.in_branch_control_i(branchcontrol),.in_valid_i(rv),.in_ready_o(rr),.in_tag_i(rt),.in_uop_i(ru),.in_class_i(rc),.in_operand_i(operand),.in_gpr_dst_i(rd),
 .early_tag_o(earlytag),.early_valid_o(rawearly),.early_preg_o(ep),.alu_bypass_valid_o(rawav),.alu_bypass_preg_o(ap),.alu_bypass_data_o(ad),
 .result_valid_o(resultv),.result_ready_i(resultr),.result_tag_o(resulttag),.result_o(resultdata),
 .recovery_preview_valid_o(),.recovery_preview_tag_o(),.resolve_valid_o(),.resolve_tag_o(),.resolve_npc_o(),.redirect_valid_o(),.resolve_pc_o(),
 .resolve_conditional_o(),.resolve_indirect_o(),.resolve_taken_o(),
 .lsu_ready_i(2'b0),.lsu_fire_o(),.lsu_tag_o(),.lsu_uop_o(),.lsu_operand_o(),
 .fp_ready_i(1'b0),.fp_fire_o(),.fp_tag_o(),.fp_uop_o(),.fp_operand_o(),
 .serial_ready_i(1'b0),.serial_fire_o(),.serial_tag_o(),.serial_uop_o(),.serial_operand_o());
 // This direct RR/FU fixture models the Backend's current-owner kill/flush
 // guard; full ROB generation/pnew validation is exercised by WB-lanes/Backend.
 assign early=rawearly&{!km[earlytag[9+:5]],!km[earlytag[0+:5]]}&{2{!rst&&!flush}};
 assign av=rawav&{!km[resulttag[9+:5]],!km[resulttag[0+:5]]}&{2{!rst&&!flush}};
 // Controlled WB arbitration with a real one-cycle result holder. This may
 // deny an ALU for arbitrarily long, then moves its owner/data atomically.
 integer l;
 always @(posedge clk)begin
   if(rst||flush)wvalid<=0;
   else begin
     wvalid<=resultv[1:0]&resultr[1:0];
     for(l=0;l<2;l=l+1)if(resultv[l]&&resultr[l])begin
       wpreg[l*6+:6]<=ap[l*6+:6];wtag[l*9+:9]<=resulttag[l*9+:9];
       wdata[l*64+:64]<=resultdata[l*R+:64];
     end
   end
 end
 task tick;begin @(posedge clk);#1;end endtask
 task check;input condition;input [511:0] msg;
   begin if(condition!==1'b1)$fatal(1,"%0s",msg);end
 endtask
 task inject;
   input integer lane,id,sp,dp,imm,kind;input fault;
   begin
     fire=2'(1<<lane);tag[lane*9+:9]=9'(id);cls[lane*3+:3]=3'(kind);dst[lane*6+:6]=6'(dp);
     src[lane*18+:18]={12'b0,6'(sp)};used[lane*3+:3]=3'b001;uop[lane*U+:U]=0;
     uop[lane*U+64+:64]=64'(imm);uop[lane*U+192+:4]=4;
     uop[lane*U+207]=kind==0;uop[lane*U+208]=fault;
     #1;check(credit[lane],"injection overwrote a held packet");tick();fire=0;tick();
   end
 endtask
 initial begin
   tick();rst=0;init=1;tick();init=0;
   inject(0,0,5,6,1,0,0);
   check(early[0]==(EARLY_ACCEPT!=0)&&rr[0],"ALU accept wake disagrees with guaranteed-empty mode");tick();
   check(early==1&&ep[5:0]==6&&earlytag[8:0]==0,"finished ALU did not wake its full owner");tick();
   check(av==1&&ad[63:0]==11,"early result holder");
   inject(0,1,6,7,1,0,0);
   check(operand[63:0]==11&&!early[0],"held-ALU bypass or speculative blocked wake");
   tick();tick();check(execute.gen_alu[0].lane.count_q==2,"blocked completed ALU owner was lost");
   repeat(8)begin tick();check(!early[0]&&ad[63:0]==11&&execute.gen_alu[0].lane.count_q==2,
     "WB backpressure changed owner/result or woke a queued value");end
   // A multiply can progress on the other lane while the ALU result is held.
   inject(1,2,5,0,0,2,0);tick();
   // Numeric pipeline depth is an implementation choice. Bound real completion,
   // and check the blocked ALU owner throughout the wait.
   begin:wait_multiply
     integer wait_cycles;
     wait_cycles=0;
     while(!resultv[2]&&wait_cycles<24)begin
       tick();wait_cycles=wait_cycles+1;
       check(!early[0]&&ad[63:0]==11&&execute.gen_alu[0].lane.count_q==2,
         "long-unit progress disturbed blocked ALU owner");
     end
   end
   check(resultv[2]&&!early[0],"mixed long result holder");
   resultr=5'b00101;#1;check(!early[0],"queued value woke before its bypass head existed");
   tick();resultr=0;
   check(av[0]&&ad[63:0]==12&&livewb[0]&&wd[63:0]==11&&early[0]&&ep[5:0]==7,"ALU-to-WB holder continuity");
   inject(1,3,6,8,1,0,0);
   check(operand[192+:64]==11,"WB holder/PRF continuity");tick();tick();
   check(av[1]&&ad[127:64]==12,"WB-bypassed consumer numeric result");
   resultr=3;tick();tick();resultr=0;
   inject(1,4,6,9,2,0,0);
   check(operand[192+:64]==11,"PRF continuity after WB holder drained");tick();tick();
   check(ad[127:64]==13,"PRF consumer numeric result");
   flush=1;#1;check(av==0&&early==0,"flush leaked bypass/wakeup");tick();flush=0;

   inject(0,5,5,10,9,0,0);tick();tick();check(ad[63:0]==19,"kill fixture producer");
   inject(0,6,10,11,1,0,0);
   km=32'h60;#1;check(rawav[0]&&av==0&&early==0,"canonical guard did not reject raw canceled ALU owner");
   tick();check(rv==0,"register-read owner survived cancellation edge");km=0;
   // Reusing the same physical destination after cancellation cannot forward
   // the old generation, even though its dead payload bits remain in flops.
   inject(0,37,5,10,91,0,0);tick();tick();check(ad[63:0]==101,"physical-register reuse");
   inject(1,38,10,12,1,0,0);
   check(operand[192+:64]==101,"old cancelled physical value resurrected");tick();tick();
   check(ad[127:64]==102,"reused destination consumer result");
   flush=1;tick();flush=0;
   inject(0,7,5,13,1,0,1);
   check(early==0,"exception advertised a physical result before trap");tick();tick();
   check(av==0&&resultv[0]&&resultdata[64],"exception result holder lost fault or leaked bypass");
   flush=1;tick();flush=0;
   inject(0,8,5,0,1,0,0);
   check(early==0,"x0 advertised an early physical destination");tick();tick();
   check(av==0,"x0 ALU holder became a data bypass source");
   $display("[PASS] tb_r64_early_wakeup heldALU/WB/PRF long-result backpressure kill/flush preg-reuse");
   $finish;
 end
endmodule
