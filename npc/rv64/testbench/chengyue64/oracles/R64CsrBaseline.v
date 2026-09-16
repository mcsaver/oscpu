// Architectural privilege state has a single commit boundary. CSR reads are
// combinational; the serial owner retains the request until commit_i. Traps
// arrive as one ROB-selected record, eliminating per-stage trap state copies.
// The serial owner snapshots read_o/write_value_o together. commit_value_i
// applies that snapshot even if a live counter changes before retirement.
module R64CsrBaseline(
 input clk_i,input rst_i,input count_enable_i,input [63:0] time_i,input [1:0] retired_i,
 input [11:0] address_i,input [2:0] operation_i,input [4:0] rs1_i,input [63:0] operand_i,
 input commit_i,output reg [63:0] read_o,output illegal_o,
 input fp_dirty_i,input [4:0] fp_flags_i,
 input trap_i,input trap_interrupt_i,input [5:0] trap_cause_i,
 input [63:0] trap_pc_i,trap_tval_i,
 input [1:0] return_i,output [63:0] return_target_o,
 input irq_software_i,input irq_timer_i,input irq_external_i,input irq_supervisor_external_i,
 output wfi_wake_o,output irq_pending_o,output [5:0] irq_cause_o,output [63:0] trap_target_o,
 output [1:0] privilege_o,output [63:0] mstatus_o,satp_o,
 output [2:0] frm_o,output pbmt_enable_o,
 output [127:0] pmp_config_o,output [863:0] pmp_address_o,
 output [63:0] write_value_o,input [63:0] commit_value_i,input return_supervisor_i,input [63:0] select_i,
 output [2:0] trigger_enable_o,output [63:0] trigger_address_o
);
 localparam [22:0] STATUS_MASK=23'h7e7faa;
 localparam [22:0] SSTATUS_MASK=23'h0c6722;
 localparam [63:0] XLEN_FIELDS=64'h0000000a00000000;
 localparam [63:0] SSTATUS_VIEW=64'h80000003000c6722;
 localparam [63:0] MISA=64'h800000000014112f;
 reg [1:0] privilege_q;
 reg [22:0] status_q;
 reg [15:0] exception_delegation_q;
 reg [2:0] interrupt_delegation_q,software_pending_q;
 reg [11:0] enable_q;
 reg [63:0] mtvec_q,stvec_q,mscratch_q,sscratch_q;
 reg [62:0] mepc_q,sepc_q;
 reg [63:0] mcause_q,scause_q,mtval_q,stval_q,satp_q;
 wire [63:0] cycle_q,retired_q;
 reg [2:0] mcounter_q,scounter_q;
 reg [1:0] inhibit_q;
 reg pbmt_q;
 reg [4:0] flags_q;
 reg [2:0] rounding_q;
 reg [127:0] pmp_config_q;
 reg [53:0] pmp_address_q[0:15];
 wire [11:0] delegation_w={2'b0,interrupt_delegation_q[2],3'b0,
                          interrupt_delegation_q[1],3'b0,interrupt_delegation_q[0],1'b0};
 wire [11:0] pending_software_w={2'b0,software_pending_q[2],3'b0,
                          software_pending_q[1],3'b0,software_pending_q[0],1'b0};
 // PLIC contexts and software-pending supervisor bits are independent of
 // delegation. Delegation selects trap privilege; it never manufactures a source.
 wire [11:0] pending_hardware_w={irq_external_i,1'b0,irq_supervisor_external_i,1'b0,
                           irq_timer_i,3'b0,irq_software_i,3'b0};
 wire [11:0] pending_w=pending_hardware_w|pending_software_w;
 wire [11:0] machine_pending_w=pending_w&enable_q&~delegation_w;
 wire [11:0] supervisor_pending_w=pending_w&enable_q&delegation_w;
 wire machine_irq_w=(privilege_q!=3||status_q[3])&&(|machine_pending_w);
 wire supervisor_irq_w=(privilege_q==0||(privilege_q==1&&status_q[1]))&&
                         (|supervisor_pending_w);
 wire [4:0] selected_irq_w=machine_irq_w?
   {machine_pending_w[11],machine_pending_w[3],machine_pending_w[7],machine_pending_w[9],machine_pending_w[1]}:
   {supervisor_pending_w[11],supervisor_pending_w[3],supervisor_pending_w[7],supervisor_pending_w[9],supervisor_pending_w[1]};
 assign wfi_wake_o=|(pending_w&enable_q);
 assign irq_pending_o=machine_irq_w||supervisor_irq_w;
 assign irq_cause_o=selected_irq_w[4]?6'd11:(selected_irq_w[3]?6'd3:
     (selected_irq_w[2]?6'd7:(selected_irq_w[1]?6'd9:(selected_irq_w[0]?6'd1:6'd5))));

 wire sd_w=status_q[14:13]==3||status_q[10:9]==3;
 assign mstatus_o=XLEN_FIELDS|{41'b0,status_q}|{sd_w,63'b0};
 assign satp_o=satp_q;assign frm_o=rounding_q;assign pbmt_enable_o=pbmt_q;
 assign privilege_o=privilege_q;assign pmp_config_o=pmp_config_q;
 genvar g;
 generate for(g=0;g<16;g=g+1)begin:g_pmp_out
  assign pmp_address_o[g*54+:54]=pmp_address_q[g];
 end endgenerate
 wire pmp_cfg_w=address_i==12'h3a0||address_i==12'h3a2;
 wire pmp_addr_w=address_i[11:4]==8'h3b;
 wire fp_csr_w=address_i==1||address_i==2||address_i==3;
 wire counter_w=address_i==12'hc00||address_i==12'hc01||address_i==12'hc02;
 wire [1:0] counter_index_w=address_i[1:0];
 wire write_intent_w=operation_i[1:0]==1||rs1_i!=0;
 wire [63:0] trigger_control_w;
 wire known_w=|select_i;
 wire readonly_w=|(select_i&64'h0000000fe0000000);
 always @*begin
  read_o=0;
  read_o=read_o|({64{select_i[0]}}&({59'b0,flags_q})); // 001
  read_o=read_o|({64{select_i[1]}}&({61'b0,rounding_q})); // 002
  read_o=read_o|({64{select_i[2]}}&({56'b0,rounding_q,flags_q})); // 003
  read_o=read_o|({64{select_i[3]}}&(mstatus_o&SSTATUS_VIEW)); // 100
  read_o=read_o|({64{select_i[4]}}&({52'b0,enable_q&delegation_w})); // 104
  read_o=read_o|({64{select_i[5]}}&(stvec_q)); // 105
  read_o=read_o|({64{select_i[6]}}&({61'b0,scounter_q})); // 106
  read_o=read_o|({64{select_i[7]}}&(sscratch_q)); // 140
  read_o=read_o|({64{select_i[8]}}&({sepc_q,1'b0})); // 141
  read_o=read_o|({64{select_i[9]}}&(scause_q)); // 142
  read_o=read_o|({64{select_i[10]}}&(stval_q)); // 143
  read_o=read_o|({64{select_i[11]}}&({52'b0,pending_w&delegation_w})); // 144
  read_o=read_o|({64{select_i[12]}}&(satp_q)); // 180
  read_o=read_o|({64{select_i[13]}}&(mstatus_o)); // 300
  read_o=read_o|({64{select_i[14]}}&(MISA)); // 301
  read_o=read_o|({64{select_i[15]}}&({48'b0,exception_delegation_q})); // 302
  read_o=read_o|({64{select_i[16]}}&({52'b0,delegation_w})); // 303
  read_o=read_o|({64{select_i[17]}}&({52'b0,enable_q})); // 304
  read_o=read_o|({64{select_i[18]}}&(mtvec_q)); // 305
  read_o=read_o|({64{select_i[19]}}&({61'b0,mcounter_q})); // 306
  read_o=read_o|({64{select_i[20]}}&({1'b0,pbmt_q,62'b0})); // 30a
  read_o=read_o|({64{select_i[21]}}&({61'b0,inhibit_q[1],1'b0,inhibit_q[0]})); // 320
  read_o=read_o|({64{select_i[22]}}&(mscratch_q)); // 340
  read_o=read_o|({64{select_i[23]}}&({mepc_q,1'b0})); // 341
  read_o=read_o|({64{select_i[24]}}&(mcause_q)); // 342
  read_o=read_o|({64{select_i[25]}}&(mtval_q)); // 343
  read_o=read_o|({64{select_i[26]}}&({52'b0,pending_w})); // 344
  read_o=read_o|({64{select_i[27]}}&(cycle_q)); // b00
  read_o=read_o|({64{select_i[28]}}&(retired_q)); // b02
  read_o=read_o|({64{select_i[29]}}&(cycle_q)); // c00
  read_o=read_o|({64{select_i[30]}}&(time_i)); // c01
  read_o=read_o|({64{select_i[31]}}&(retired_q)); // c02
  read_o=read_o|({64{select_i[32]}}&(64'h79737978)); // f11
  read_o=read_o|({64{select_i[33]}}&(64'd26010035)); // f12
  read_o=read_o|({64{select_i[34]}}&(64'b0)); // f13
  read_o=read_o|({64{select_i[35]}}&(64'b0)); // f14
  read_o=read_o|({64{select_i[36]}}&(pmp_config_q[63:0])); // 3a0
  read_o=read_o|({64{select_i[37]}}&(pmp_config_q[127:64])); // 3a2
  read_o=read_o|({64{select_i[38]}}&({10'b0,pmp_address_q[0]})); // 3b0
  read_o=read_o|({64{select_i[39]}}&({10'b0,pmp_address_q[1]})); // 3b1
  read_o=read_o|({64{select_i[40]}}&({10'b0,pmp_address_q[2]})); // 3b2
  read_o=read_o|({64{select_i[41]}}&({10'b0,pmp_address_q[3]})); // 3b3
  read_o=read_o|({64{select_i[42]}}&({10'b0,pmp_address_q[4]})); // 3b4
  read_o=read_o|({64{select_i[43]}}&({10'b0,pmp_address_q[5]})); // 3b5
  read_o=read_o|({64{select_i[44]}}&({10'b0,pmp_address_q[6]})); // 3b6
  read_o=read_o|({64{select_i[45]}}&({10'b0,pmp_address_q[7]})); // 3b7
  read_o=read_o|({64{select_i[46]}}&({10'b0,pmp_address_q[8]})); // 3b8
  read_o=read_o|({64{select_i[47]}}&({10'b0,pmp_address_q[9]})); // 3b9
  read_o=read_o|({64{select_i[48]}}&({10'b0,pmp_address_q[10]})); // 3ba
  read_o=read_o|({64{select_i[49]}}&({10'b0,pmp_address_q[11]})); // 3bb
  read_o=read_o|({64{select_i[50]}}&({10'b0,pmp_address_q[12]})); // 3bc
  read_o=read_o|({64{select_i[51]}}&({10'b0,pmp_address_q[13]})); // 3bd
  read_o=read_o|({64{select_i[52]}}&({10'b0,pmp_address_q[14]})); // 3be
  read_o=read_o|({64{select_i[53]}}&({10'b0,pmp_address_q[15]})); // 3bf
  read_o=read_o|({64{select_i[55]}}&trigger_control_w);
  read_o=read_o|({64{select_i[56]}}&trigger_address_o);
  read_o=read_o|({64{select_i[57]}}&64'h0000000001008044);
 end
 assign illegal_o=!known_w||operation_i[1:0]==0||privilege_q<address_i[9:8]||
   (write_intent_w&&readonly_w)||(fp_csr_w&&status_q[14:13]==0)||
   (address_i==12'h180&&privilege_q==1&&status_q[20])||
   (counter_w&&privilege_q!=3&&(!mcounter_q[counter_index_w]||
         (privilege_q==0&&!scounter_q[counter_index_w])));
 wire write_w=commit_i&&!illegal_o&&write_intent_w;
 wire [63:0] source_w=operation_i[2]?{59'b0,rs1_i}:operand_i;
 // MIP/SIP read the OR of software and hardware pending bits. Their RMW write
 // base excludes hardware, so CSRRS/CSRRC cannot latch an external IRQ in software.
 wire [63:0] write_base_w=select_i[26] ? {52'b0,pending_software_w}:
    (select_i[11] ? {52'b0,pending_software_w&delegation_w}:read_o);
 assign write_value_o=operation_i[1:0]==1?source_w:
                  (operation_i[1:0]==2?write_base_w|source_w:write_base_w&~source_w);
 wire [63:0] new_w=commit_value_i;
 R64Trigger trigger(
  .clk_i(clk_i),.rst_i(rst_i),
  .write_control_i(write_w&&!trap_i&&return_i==0&&select_i[55]),
  .write_address_i(write_w&&!trap_i&&return_i==0&&select_i[56]),
  .write_value_i(new_w),.privilege_i(privilege_q),.machine_ie_i(status_q[3]),
  .supervisor_ie_i(status_q[1]),.breakpoint_delegated_i(exception_delegation_q[3]),
  .control_o(trigger_control_w),.address_o(trigger_address_o),.enable_o(trigger_enable_o));
 // b00/b02 are known writable machine CSRs. Qualify them locally so the
 // counter boundary does not traverse unrelated FP, SATP and PMP legality.
 wire counter_commit_w=commit_i&&operation_i[1:0]!=0&&write_intent_w&&
     privilege_q==3&&!trap_i&&return_i==0;
 R64Counter cycles(.clk_i(clk_i),.rst_i(rst_i),
  .enable_i(count_enable_i&&!inhibit_q[0]),.increment_i(2'd1),
  .write_i(counter_commit_w&&address_i==12'hb00),.write_value_i(new_w),.value_o(cycle_q));
 R64Counter retired(.clk_i(clk_i),.rst_i(rst_i),
  .enable_i(count_enable_i&&!inhibit_q[1]),.increment_i(retired_i),
  .write_i(counter_commit_w&&address_i==12'hb02),.write_value_i(new_w),.value_o(retired_q));
 wire trap_supervisor_w=privilege_q!=3&&(trap_interrupt_i?
   (trap_cause_i<12&&delegation_w[trap_cause_i[3:0]]):
   (trap_cause_i<16&&exception_delegation_q[trap_cause_i[3:0]]));
 wire [63:0] machine_vector_w,supervisor_vector_w;
 R64TrapVector machine_vector(.vector_i(mtvec_q),.interrupt_i(trap_interrupt_i),
  .cause_i(trap_cause_i),.target_o(machine_vector_w));
 R64TrapVector supervisor_vector(.vector_i(stvec_q),.interrupt_i(trap_interrupt_i),
  .cause_i(trap_cause_i),.target_o(supervisor_vector_w));
 assign trap_target_o=trap_supervisor_w ? supervisor_vector_w:machine_vector_w;
 assign return_target_o=return_supervisor_i?{sepc_q,1'b0}:{mepc_q,1'b0};
 wire [1:0] mpp_w=status_q[12:11]==2?2'b0:status_q[12:11];
 wire cfg_locked_w=pmp_config_q[address_i[3:0]*8+7];
 wire [3:0] next_pmp_w=address_i[3:0]+4'd1;
 wire cfg_next_locked_w=pmp_config_q[next_pmp_w*8+7];
 wire [1:0] cfg_next_mode_w=pmp_config_q[next_pmp_w*8+3+:2];
 wire pmp_address_locked_w=cfg_locked_w||
      (address_i[3:0]!=15&&cfg_next_locked_w&&cfg_next_mode_w==1);
 wire [22:0] clean_status_w=(new_w[22:0]&STATUS_MASK)&
      ~(new_w[12:11]==2?23'h001800:23'b0);
 integer i;
 wire [63:0] cfg_write_w;
 generate for(g=0;g<8;g=g+1)begin:g_pmp_sanitize
  wire [7:0] c_w=new_w[g*8+:8];
  assign cfg_write_w[g*8+:8]={c_w[7],2'b0,c_w[4:3],(c_w[1]&&!c_w[0])?3'b0:c_w[2:0]};
  wire unused_reserved_w=|c_w[6:5];
 end endgenerate
 wire unused_epc_lsb_w=trap_pc_i[0];
 always @(posedge clk_i)begin
  if(rst_i)begin
   privilege_q<=3;status_q<=0;exception_delegation_q<=0;
   interrupt_delegation_q<=0;software_pending_q<=0;enable_q<=0;
   mtvec_q<=0;stvec_q<=0;mscratch_q<=0;sscratch_q<=0;mepc_q<=0;sepc_q<=0;
   mcause_q<=0;scause_q<=0;mtval_q<=0;stval_q<=0;satp_q<=0;
   mcounter_q<=0;scounter_q<=0;inhibit_q<=0;
   pbmt_q<=0;flags_q<=0;rounding_q<=0;pmp_config_q<=0;
   for(i=0;i<16;i=i+1)pmp_address_q[i]<=0;
  end else begin
   if(fp_dirty_i)begin flags_q<=flags_q|fp_flags_i;status_q[14:13]<=3;end
   if(trap_i)begin
    if(trap_supervisor_w)begin
     sepc_q<=trap_pc_i[63:1];scause_q<={trap_interrupt_i,57'b0,trap_cause_i};stval_q<=trap_tval_i;
     status_q[5]<=status_q[1];status_q[1]<=0;status_q[8]<=privilege_q==1;privilege_q<=1;
    end else begin
     mepc_q<=trap_pc_i[63:1];mcause_q<={trap_interrupt_i,57'b0,trap_cause_i};mtval_q<=trap_tval_i;
     status_q[7]<=status_q[3];status_q[3]<=0;status_q[12:11]<=privilege_q;privilege_q<=3;
    end
   end else if(return_i!=0)begin
    if(return_i==1)begin
     privilege_q<=mpp_w;status_q[3]<=status_q[7];status_q[7]<=1;status_q[12:11]<=0;
     if(mpp_w!=3)status_q[17]<=0;
    end else begin
     privilege_q<=status_q[8]?2'd1:2'd0;status_q[1]<=status_q[5];status_q[5]<=1;
     status_q[8]<=0;status_q[17]<=0;
    end
   end else if(write_w)begin
    if(pmp_cfg_w)begin
     for(i=0;i<8;i=i+1)begin
      if(!pmp_config_q[(address_i[1]?64:0)+i*8+7])
       pmp_config_q[(address_i[1]?64:0)+i*8+:8]<=cfg_write_w[i*8+:8];
     end
    end else if(pmp_addr_w)begin
     if(!pmp_address_locked_w)pmp_address_q[address_i[3:0]]<=new_w[53:0];
    end else case(address_i)
     12'h001:begin flags_q<=new_w[4:0];status_q[14:13]<=3;end
     12'h002:begin rounding_q<=new_w[2:0];status_q[14:13]<=3;end
     12'h003:begin flags_q<=new_w[4:0];rounding_q<=new_w[7:5];status_q[14:13]<=3;end
     12'h100:status_q<=(status_q&~SSTATUS_MASK)|(new_w[22:0]&SSTATUS_MASK);
     12'h104:enable_q<=(enable_q&~delegation_w)|(new_w[11:0]&delegation_w);
     12'h105:stvec_q<={new_w[63:2],1'b0,new_w[1:0]==1};
     12'h106:scounter_q<=new_w[2:0];
     12'h140:sscratch_q<=new_w;
     12'h141:sepc_q<=new_w[63:1];
     12'h142:scause_q<=new_w;
     12'h143:stval_q<=new_w;
     12'h144:software_pending_q[0]<=interrupt_delegation_q[0]?new_w[1]:software_pending_q[0];
     12'h180:if(new_w[63:60]==0||new_w[63:60]==8)satp_q<=new_w;
     12'h300:status_q<=clean_status_w;
     12'h302:exception_delegation_q<=new_w[15:0]&16'hb3ff;
     12'h303:interrupt_delegation_q<={new_w[9],new_w[5],new_w[1]};
     12'h304:enable_q<=new_w[11:0]&12'haaa;
     12'h305:mtvec_q<={new_w[63:2],1'b0,new_w[1:0]==1};
     12'h306:mcounter_q<=new_w[2:0];
     12'h30a:pbmt_q<=new_w[62];
     12'h320:inhibit_q<={new_w[2],new_w[0]};
     12'h340:mscratch_q<=new_w;
     12'h341:mepc_q<=new_w[63:1];
     12'h342:mcause_q<=new_w;
     12'h343:mtval_q<=new_w;
     12'h344:software_pending_q<={new_w[9],new_w[5],new_w[1]};
     default:begin end
    endcase
   end
  end
 end
`ifdef R64_ASSERT
 wire [63:0] checked_select_w;
 R64CsrDecode check_select(.address_i(address_i),.select_o(checked_select_w));
 always @(posedge clk_i)if(!rst_i&&select_i!==checked_select_w)
  $fatal(1,"CSR selector disagrees with serial command owner");
 always @(posedge clk_i)if(!rst_i)begin
  if(return_i==3||(trap_i&&return_i!=0))$fatal(1,"CSR simultaneous privilege transfers");
  if(commit_i&&illegal_o)$fatal(1,"illegal CSR reached architectural commit");
  if(write_w&&fp_dirty_i)$fatal(1,"serial CSR overlapped younger FP retirement");
 end
`endif
endmodule
