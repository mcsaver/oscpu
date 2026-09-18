`include "R64Uop.vh"
// One ROB-head serial owner. Query/complete and architectural commit are
// distinct events: CSR read and RMW write values are captured together, while
// privilege/TLB/cache effects wait for the tagged ROB commit. Tensor commands
// retain their external owner through terminal return and architectural retire.
module R64Serial(
 input clk_i,input rst_i,input flush_i,input [31:0] kill_mask_i,
 input fire_i,output ready_o,input [8:0] tag_i,input [8:0] head_tag_i,
 input [`R64_UOP_W-1:0] uop_i,input [191:0] operand_i,
 input memory_idle_i,input wfi_wake_i,
 output result_valid_o,input result_ready_i,output [8:0] result_tag_o,
 output [`R64_RESULT_W-1:0] result_o,
 input commit_i,input [8:0] commit_tag_i,
 input [1:0] privilege_i,input [63:0] mstatus_i,
 output [11:0] csr_address_o,output [63:0] csr_select_o,output [2:0] csr_operation_o,
 output [4:0] csr_rs1_o,output [63:0] csr_operand_o,output csr_commit_o,
 input [63:0] csr_read_i,csr_write_value_i,input csr_illegal_i,
 output return_supervisor_o,output [1:0] return_commit_o,input [63:0] return_target_i,
 output icache_invalidate_o,output tlb_invalidate_o,
 output tlb_all_vaddr_o,output tlb_all_asid_o,
 output [26:0] tlb_vpn_o,output [15:0] tlb_asid_o,
 output tensor_cmd_valid_o,input tensor_cmd_ready_i,
 output [8:0] tensor_cmd_tag_o,output [63:0] tensor_cmd_o,tensor_operand_o,
 output tensor_pair_o,output [7:0] tensor_class_o,
 input tensor_terminal_valid_i,output tensor_terminal_ready_o,
 input [8:0] tensor_terminal_tag_i,input tensor_error_i,input [7:0] tensor_error_code_i,
 output irrevocable_o,output [31:0] reuse_block_o,output idle_o,
 output csr_query_o,input csr_query_valid_i,output return_prepare_o
);
 localparam [2:0] IDLE=0,EVALUATE=1,SEND=2,WAIT_TERMINAL=3,RESULT=4,RETIRE=5,CSR_WAIT=6;
 reg [2:0] state_q;
 reg [8:0] tag_q;
 reg [63:0] command_q,operand_q;
 reg [63:0] csr_select_q;
 wire [63:0] incoming_command_w=uop_i[`R64_U_CMD];
 wire [63:0] incoming_select_w;
 R64CsrDecode decode_csr(.address_i(incoming_command_w[31:20]),.select_o(incoming_select_w));
 assign csr_select_o=csr_select_q;
 reg [15:0] asid_q;
 reg [7:0] kind_q;
 reg pair_q,dead_q;
 // Authorized side effects belong to the accepted completion. This vector
 // is zero outside RETIRE and is consumed only by a matching tagged commit.
 // The existing RESULT->RETIRE edge performs classification once, avoiding
 // late commit tag comparison followed by repeated kind/exception decoding.
 reg [4:0] retire_effect_q;
 reg [`R64_RESULT_W-1:0] result_q;
 wire tensor_w=command_q[6:0]==7'h5b;
 wire kill_w=flush_i||kill_mask_i[tag_q[4:0]];
 wire commit_owner_w=commit_i&&commit_tag_i==tag_q;
 wire trap_ecall_w=kind_q==`R64_K_ECALL;
 wire trap_ebreak_w=kind_q==`R64_K_EBREAK;
 wire mret_w=kind_q==`R64_K_MRET,sret_w=kind_q==`R64_K_SRET;
 wire sfence_w=kind_q==`R64_K_SFENCE;
 wire csr_w=kind_q==`R64_K_CSR;
 wire dynamic_illegal_w=(csr_w&&csr_illegal_i)||(mret_w&&privilege_i!=3)||
     (sret_w&&(privilege_i==0||(privilege_i==1&&mstatus_i[22])))||
     (sfence_w&&(privilege_i==0||(privilege_i==1&&mstatus_i[20])))||
     (kind_q==`R64_K_WFI&&(privilege_i==0||(privilege_i!=3&&mstatus_i[21])));
 wire external_pending_w=state_q==SEND||state_q==WAIT_TERMINAL;
 assign ready_o=state_q==IDLE&&!rst_i&&!flush_i;
 assign idle_o=state_q==IDLE;
 // Raw terminal ownership is registered. The common WB rejects current
 // flush/kill at capture, while this owner is destroyed on that same edge.
 assign result_valid_o=state_q==RESULT&&!dead_q;
 assign result_tag_o=tag_q;assign result_o=result_q;
 assign csr_address_o=command_q[31:20];assign csr_operation_o=command_q[14:12];
 assign csr_rs1_o=command_q[19:15];assign csr_operand_o=operand_q;
 assign csr_commit_o=commit_owner_w&&retire_effect_q[0];
 // The target lookup uses the same admission edge as this serial owner.
 assign return_prepare_o=fire_i&&(uop_i[`R64_U_FUNC]==`R64_K_MRET||uop_i[`R64_U_FUNC]==`R64_K_SRET);
 assign return_supervisor_o=uop_i[`R64_U_FUNC]==`R64_K_SRET;
 assign return_commit_o={2{commit_owner_w}}&retire_effect_q[2:1];
 assign icache_invalidate_o=commit_owner_w&&retire_effect_q[3];
 assign tlb_invalidate_o=commit_owner_w&&retire_effect_q[4];
 assign tlb_all_vaddr_o=command_q[31:25]==7'h0c||command_q[19:15]==0;
 assign tlb_all_asid_o=command_q[31:25]==7'h0c||command_q[24:20]==0;
 assign tlb_vpn_o=operand_q[38:12];assign tlb_asid_o=asid_q;
 assign tensor_cmd_valid_o=state_q==SEND&&!rst_i;
 assign tensor_cmd_tag_o=tag_q;assign tensor_cmd_o=command_q;assign tensor_operand_o=operand_q;
 assign tensor_pair_o=pair_q;assign tensor_class_o=kind_q;
 // Stale terminal notifications are consumed without completing a newer owner.
 assign tensor_terminal_ready_o=!rst_i;
 wire terminal_w=tensor_terminal_valid_i&&tensor_terminal_ready_o&&
                 tensor_terminal_tag_i==tag_q&&state_q==WAIT_TERMINAL;
 assign irrevocable_o=tensor_w&&(external_pending_w||((state_q==RESULT||state_q==RETIRE)&&!result_q[`R64_R_EXCEPTION]))&&!dead_q;
 assign reuse_block_o=external_pending_w?(32'b1<<tag_q[4:0]):32'b0;
 wire wait_for_memory_w=tensor_w||sfence_w||kind_q==`R64_K_FENCE||kind_q==`R64_K_FENCEI;
 // A WFI owner waits without issuing younger instructions or holding an
 // external transaction. Raw locally-enabled wake is independent of xIE.
 // A query only snapshots data; it never mutates architectural CSR state.
 // Cancellation may leave an orphan query response, ignored outside CSR_WAIT.
 // Keeping this pulse independent of late kill removes the recovery fanout
 // from the request path. Actual writes still require tagged ROB retirement.
 assign csr_query_o=state_q==EVALUATE&&csr_w&&!tensor_w;
 wire evaluate_w=state_q==EVALUATE&&(!wait_for_memory_w||memory_idle_i)&&
     (tensor_w||dynamic_illegal_w||kind_q!=`R64_K_WFI||wfi_wake_i);
 reg [`R64_RESULT_W-1:0] evaluated_r;
 always @(*)begin
  evaluated_r=0;
  if(dynamic_illegal_w&&!tensor_w)begin
   evaluated_r[`R64_R_EXCEPTION]=1;evaluated_r[`R64_R_CAUSE]=2;
   evaluated_r[`R64_R_TVAL]={32'b0,command_q[31:0]};
  end else if(trap_ecall_w||trap_ebreak_w)begin
   evaluated_r[`R64_R_EXCEPTION]=1;
   evaluated_r[`R64_R_CAUSE]=trap_ebreak_w?6'd3:(privilege_i==3?6'd11:(privilege_i==1?6'd9:6'd8));
   evaluated_r[`R64_R_TVAL]=64'b0;
  end else if(csr_w)evaluated_r[`R64_R_DATA]=csr_read_i;
  else if(mret_w||sret_w)evaluated_r[`R64_R_DATA]=return_target_i;
 end
 always @(posedge clk_i)begin
  if(rst_i)begin
   state_q<=IDLE;tag_q<=0;command_q<=0;operand_q<=0;asid_q<=0;csr_select_q<=0;
   kind_q<=0;pair_q<=0;dead_q<=0;result_q<=0;retire_effect_q<=0;
  end else begin
   if(fire_i)begin
    state_q<=EVALUATE;retire_effect_q<=0;tag_q<=tag_i;command_q<=uop_i[`R64_U_CMD];csr_select_q<=incoming_select_w;
    operand_q<=operand_i[63:0];asid_q<=operand_i[79:64];
    kind_q<=uop_i[`R64_U_FUNC];pair_q<=uop_i[`R64_U_LEN]==8;dead_q<=0;
    result_q<=0;result_q[`R64_R_TVAL]<=uop_i[`R64_U_PC];
   end
   if(evaluate_w)begin
    if(tensor_w)state_q<=SEND;
    else if(csr_w)state_q<=CSR_WAIT;
    else begin
     result_q<=evaluated_r;state_q<=RESULT;
     if(csr_w)operand_q<=csr_write_value_i;
    end
   end
   if(state_q==CSR_WAIT&&csr_query_valid_i)begin
    result_q<=evaluated_r;state_q<=RESULT;operand_q<=csr_write_value_i;
   end
   if(state_q==SEND&&tensor_cmd_ready_i)state_q<=WAIT_TERMINAL;
   if(terminal_w)begin
    state_q<=dead_q?IDLE:RESULT;result_q<=0;
    if(tensor_error_i)begin
     result_q[`R64_R_EXCEPTION]<=1;result_q[`R64_R_CAUSE]<=24;
     result_q[`R64_R_TVAL]<={tensor_error_code_i,tag_q[7:0],kind_q,pair_q,pair_q,6'd1,command_q[31:0]};
    end
   end
   if(result_valid_o&&result_ready_i)begin
    state_q<=RETIRE;
    retire_effect_q<= {5{!tensor_w&&!result_q[`R64_R_EXCEPTION]}}&
       {sfence_w,kind_q==`R64_K_FENCEI,sret_w,mret_w,csr_w};
   end
   if(commit_i&&commit_tag_i==tag_q&&state_q==RETIRE)begin
    state_q<=IDLE;retire_effect_q<=0;
   end
   if(state_q!=IDLE&&kill_w)begin
    retire_effect_q<=0;
    if(external_pending_w&&!terminal_w)dead_q<=1;
    else state_q<=IDLE;
   end
  end
 end
 wire unused_uop_w=|{uop_i[217:204],uop_i[127:64]};
 wire unused_operands_w=|operand_i[191:80];
 wire unused_mstatus_w=|{mstatus_i[63:23],mstatus_i[19:0]};
`ifdef R64_ASSERT
 always @(posedge clk_i)if(!rst_i)begin
  if((|retire_effect_q)&&(state_q!=RETIRE||tensor_w||result_q[`R64_R_EXCEPTION]))
   $fatal(1,"serial effect authorization escaped accepted legal completion");
  if(fire_i&&(!ready_o||tag_i!=head_tag_i))$fatal(1,"serial admission is not free ROB head");
  if(irrevocable_o&&kill_w)$fatal(1,"cancelled irrevocable serial transaction");
  if(commit_i&&commit_tag_i==tag_q&&state_q!=IDLE&&state_q!=RETIRE)
   $fatal(1,"serial commit preceded accepted completion");
 end
`endif
endmodule
