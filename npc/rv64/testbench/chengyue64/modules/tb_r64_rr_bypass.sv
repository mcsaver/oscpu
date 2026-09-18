`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_rr_bypass #(parameter BYPASS=1);
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
 reg fpready=0;reg [5:0] credit_mask=6'b111111;
 wire [5:0] fu_credit;wire fp_fire;wire [8:0] fp_tag;wire [191:0] fp_operands;
 reg init=0;reg [5:0] initpreg=5;reg [63:0] initdata=10;
 reg [1:0] wvalid=0;reg [11:0] wpreg=0;reg [127:0] wdata=0;reg [17:0] wtag=0;
 wire [1:0] livewb={wvalid[1]&&!km[wtag[9+:5]],wvalid[0]&&!km[wtag[0+:5]]}&{2{!flush}};
 wire [1:0] ww=init ? 2'b01:livewb;
 wire [11:0] wp=init ? {6'b0,initpreg}:wpreg;
 wire [127:0] wd=init ? {64'b0,initdata}:wdata;
 R64RegRead #(.PAYLOAD_W(U),.Q_ONLY_TERMINAL(1),.ALU_TERMINAL_BYPASS(BYPASS)) registers(.in_mem_slot_i(10'b0),.out_mem_slot_o(memslot),
 .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(km),.in_fire_i(fire),.in_ready_o(credit),
 .fu_credit_i(fu_credit&credit_mask),.in_tag_i(tag),.in_payload_i(uop),.in_class_i(cls),.in_gpr_dst_i(dst),
 .in_src_preg_i(src),.in_src_fp_i(6'b0),.in_src_used_i(used),
 .wb_write_i(ww),.wb_fp_i(2'b0),.wb_preg_i(wp),.wb_data_i(wd),
 .alu_bypass_valid_i(av),.alu_bypass_preg_i(ap),.alu_bypass_data_i(ad),
 .out_alu_control_o(alucontrol),.out_add_source_o(addsource),.out_shift_amount_o(shiftamount),.out_branch_imm_o(branchimm),.out_branch_control_o(branchcontrol),.out_valid_o(rv),.out_ready_i(rr),.out_tag_o(rt),.out_payload_o(ru),.out_class_o(rc),
 .out_operand_o(operand),.out_gpr_dst_o(rd));
 R64Execute #(.EARLY_ALU_WAKE(1)) execute(.clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(km),.rob_head_i(5'b0),
 .in_mem_slot_i(memslot),.lsu_slot_o(),.in_alu_control_i(alucontrol),.in_add_source_i(addsource),.in_shift_amount_i(shiftamount),.in_branch_imm_i(branchimm),.in_branch_control_i(branchcontrol),.in_valid_i(rv),.in_ready_o(rr),.in_tag_i(rt),.in_uop_i(ru),.in_class_i(rc),.in_operand_i(operand),.in_gpr_dst_i(rd),
 .rr_fu_credit_o(fu_credit),.early_tag_o(earlytag),.early_valid_o(rawearly),.early_preg_o(ep),.alu_bypass_valid_o(rawav),.alu_bypass_preg_o(ap),.alu_bypass_data_o(ad),
 .result_valid_o(resultv),.result_ready_i(resultr),.result_tag_o(resulttag),.result_o(resultdata),
 .recovery_preview_valid_o(),.recovery_preview_tag_o(),.resolve_valid_o(),.resolve_tag_o(),.resolve_npc_o(),.redirect_valid_o(),.resolve_pc_o(),
 .resolve_conditional_o(),.resolve_indirect_o(),.resolve_taken_o(),
 .lsu_ready_i(2'b0),.lsu_fire_o(),.lsu_tag_o(),.lsu_uop_o(),.lsu_operand_o(),
 .fp_ready_i(fpready),.fp_fire_o(fp_fire),.fp_tag_o(fp_tag),.fp_uop_o(),.fp_operand_o(fp_operands),
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
     src[lane*18+:18]=kind==2 ? {6'b0,6'd6,6'(sp)}:{12'b0,6'(sp)};
     used[lane*3+:3]=kind==2 ? 3'b011:3'b001;uop[lane*U+:U]=0;
     if(kind==2)uop[lane*U+196+:8]=8'd4;
     uop[lane*U+64+:64]=64'(imm);uop[lane*U+192+:4]=4;
     uop[lane*U+207]=kind==0;uop[lane*U+208]=fault;
     #1;check(credit[lane],"injection overwrote a held packet");tick();fire=0;tick();
   end
 endtask

 reg [511:0] seen=0,fp_seen=0;
 integer k,wait_cycles;
 reg [63:0] expected[0:511];
 always @(posedge clk)if(!rst&&!flush)begin
   for(integer port=0;port<5;port=port+1)
     if(resultv[port]&&resultr[port]&&!km[resulttag[port*9+:5]])begin
       if(seen[resulttag[port*9+:9]]||resultdata[port*R+:64]!==expected[resulttag[port*9+:9]])
         $fatal(1,"RR bypass lost/duplicated operand owner tag=%0d got=%h expected=%h",
           resulttag[port*9+:9],resultdata[port*R+:64],expected[resulttag[port*9+:9]]);
       seen[resulttag[port*9+:9]]=1;
     end
   if(fp_fire)begin
     if(fp_seen[fp_tag])$fatal(1,"RR FP owner accepted twice");
     fp_seen[fp_tag]=1;
   end
 end
 initial begin
   for(k=0;k<512;k=k+1)expected[k]=0;
   tick();rst=0;init=1;initpreg=5;initdata=10;tick();
   initpreg=6;initdata=7;tick();init=0;resultr=3;
   expected[1]=1;expected[2]=1;expected[3]=15;
   inject(0,1,5,0,0,2,0);repeat(3)tick();
   inject(0,2,5,0,0,2,0);
   inject(0,3,5,7,5,0,0);
   // The ALU reads 10 before this PRF rewrite, then must keep its own snapshot.
   init=1;initpreg=5;initdata=999;tick();init=0;repeat(8)tick();
   check(seen[3]&&!seen[1]&&!seen[2],"ALU did not bypass a blocked DIV head");
   resultr=5'b01011;wait_cycles=0;
   while((!seen[1]||!seen[2])&&wait_cycles<160)begin tick();wait_cycles=wait_cycles+1;end
   check(seen[1]&&seen[2],"DIV owners failed to drain after ALU bypass");
   repeat(4)tick();
   init=1;initpreg=5;initdata=20;tick();init=0;
   expected[5]=22;expected[10]=23;
   inject(0,4,5,0,0,3,0);tick();
   inject(0,5,5,8,2,0,0);repeat(8)tick();
   check(seen[5]&&!fp_seen[4],"ALU did not bypass a blocked FP head");
   inject(0,10,5,9,3,0,0);repeat(8)tick();
   check(seen[10]&&!fp_seen[4],"bypassed slot did not return to the free tail");
   fpready=1;repeat(5)tick();check(fp_seen[4],"older FP owner was lost by tail bypass");
   fpready=0;credit_mask[0]=0;
   inject(0,6,5,0,0,3,0);tick();
   inject(0,7,5,10,1,0,0);
   km=32'h80;credit_mask[0]=1;tick();tick();km=0;repeat(3)tick();
   check(!seen[7]&&!fp_seen[6],"cancelled ALU escaped or blocked FP was accepted");
   fpready=1;repeat(5)tick();check(fp_seen[6],"tail cancellation removed its older FP owner");
   fpready=0;credit_mask[1]=0;
   inject(1,8,5,0,0,3,0);tick();
   inject(1,9,5,11,1,0,0);
   flush=1;tick();flush=0;fpready=1;credit_mask=63;resultr=31;repeat(10)tick();
   check(!seen[9]&&!fp_seen[8]&&rv==0&&registers.ingress_valid_q==0,
       "flush resurrected a resident bypass owner");
   expected[12]=24;fpready=0;
   inject(1,11,5,0,0,3,0);tick();
   inject(1,12,5,12,4,0,0);repeat(8)tick();
   check(seen[12]&&!fp_seen[11],"lane1-only ALU failed to bypass");
   fpready=1;repeat(6)tick();check(fp_seen[11]&&rv==0,"lane1 final drain failed");
   $display("[PASS] tb_r64_rr_bypass DIV/FP blocked-head snapshot/tail-reuse kill/flush lane1");
   $finish;
 end
endmodule
