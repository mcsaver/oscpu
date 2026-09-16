// Single Sv39 walker with a coherent PTE read / compare-and-OR memory service.
// The memory service checks PMP/PMA and serializes compare-and-OR with stores.
// A failed comparison restarts from the captured root; stale PTEs are not used.
// ad_update_i is permission to mutate A/D now. Speculative store probes clear
// it, receive needs_ad_o, and repeat at the authorized store boundary.
module R64PageWalk (
  input clk_i,input rst_i,
  input req_valid_i,output req_ready_o,
  input [63:0] req_vaddr_i,input [43:0] req_root_ppn_i,
  input [1:0] req_access_i,input [1:0] req_priv_i,
  input req_sum_i,input req_mxr_i,input req_ad_update_i,input req_pbmt_enable_i,
  output rsp_valid_o,input rsp_ready_i,
  output [55:0] rsp_paddr_o,output [7:0] rsp_flags_o,
  output [1:0] rsp_pbmt_o,output [1:0] rsp_level_o,
  output rsp_napot_o,output rsp_global_o,output rsp_needs_ad_o,
  output rsp_fault_o,output [4:0] rsp_cause_o,
  output [55:0] rsp_pte_addr_o,output [63:0] rsp_pte_o,
  output mem_valid_o,input mem_ready_i,
  output mem_compare_or_o,output [55:0] mem_addr_o,
  output [63:0] mem_expected_o,output [63:0] mem_or_mask_o,
  input mem_rsp_valid_i,output mem_rsp_ready_o,
  input [63:0] mem_rdata_i,input mem_error_i,input mem_compare_ok_i
);
  localparam [2:0] IDLE=0,READ=1,CHECK=2,UPDATE=3,UPDATED=4,RESULT=5;
  reg [2:0] state_q;
  reg [38:0] va_q;
  reg [63:0] pte_q;
  reg [43:0] root_q;
  reg [1:0] access_q,priv_q,level_q;
  reg sum_q,mxr_q,ad_update_q,global_q,pbmt_enable_q;
  reg [55:0] pte_addr_q,pa_q;
  reg [7:0] flags_q;
  reg [1:0] pbmt_q;
  reg napot_q,needs_ad_q,fault_q;
  reg [4:0] cause_q;

  wire canonical_w=req_vaddr_i[63:39]=={25{req_vaddr_i[38]}};
  wire leaf_w=mem_rdata_i[1]||mem_rdata_i[3];
  wire napot_w=mem_rdata_i[63];
  wire [1:0] pbmt_w=mem_rdata_i[62:61];
  wire [43:0] ppn_w=mem_rdata_i[53:10];
  wire base_bad_w=!mem_rdata_i[0]||(!mem_rdata_i[1]&&mem_rdata_i[2])||
                  (|mem_rdata_i[60:54])||pbmt_w==3||(!pbmt_enable_q&&pbmt_w!=0);
  wire nonleaf_bad_w=level_q==0||napot_w||pbmt_w!=0||
                    mem_rdata_i[4]||mem_rdata_i[6]||mem_rdata_i[7];
  wire alignment_bad_w=(level_q==2&&(|ppn_w[17:0]))||
                       (level_q==1&&(|ppn_w[8:0]))||
                       (napot_w&&(level_q!=0||ppn_w[3:0]!=4'b1000));
  wire user_ok_w=priv_q==0?mem_rdata_i[4]:
                 (!mem_rdata_i[4]||(access_q!=0&&sum_q));
  wire operation_ok_w=access_q==0?mem_rdata_i[3]:
                      (access_q==1?(mem_rdata_i[1]||(mxr_q&&mem_rdata_i[3])):mem_rdata_i[2]);
  wire permission_bad_w=!user_ok_w||!operation_ok_w;
  wire needs_ad_w=!mem_rdata_i[6]||(access_q==2&&!mem_rdata_i[7]);
  wire [4:0] page_cause_w=access_q==0?5'd12:(access_q==1?5'd13:5'd15);
  wire [4:0] access_cause_w=access_q==0?5'd1:(access_q==1?5'd5:5'd7);
  wire [63:0] ad_mask_w=access_q==2?64'hc0:64'h40;
  wire [8:0] next_vpn_w=level_q==2?va_q[29:21]:va_q[20:12];
  wire [55:0] leaf_pa_w=level_q==2?{ppn_w[43:18],va_q[29:0]}:
    (level_q==1?{ppn_w[43:9],va_q[20:0]}:
     (napot_w?{ppn_w[43:4],va_q[15:0]}:{ppn_w,va_q[11:0]}));

  assign req_ready_o=state_q==IDLE&&!rst_i;
  assign rsp_valid_o=state_q==RESULT&&!rst_i;
  assign rsp_paddr_o=pa_q;assign rsp_flags_o=flags_q;assign rsp_pbmt_o=pbmt_q;
  assign rsp_level_o=level_q;assign rsp_napot_o=napot_q;assign rsp_global_o=global_q;
  assign rsp_needs_ad_o=needs_ad_q;assign rsp_fault_o=fault_q;assign rsp_cause_o=cause_q;
  assign rsp_pte_addr_o=pte_addr_q;assign rsp_pte_o=pte_q;
  assign mem_valid_o=(state_q==READ||state_q==UPDATE)&&!rst_i;
  assign mem_compare_or_o=state_q==UPDATE;
  assign mem_addr_o=pte_addr_q;assign mem_expected_o=pte_q;assign mem_or_mask_o=ad_mask_w;
  assign mem_rsp_ready_o=(state_q==CHECK||state_q==UPDATED)&&!rst_i;

  always @(posedge clk_i) begin
    if(rst_i) begin
      state_q<=IDLE;va_q<=0;pte_q<=0;root_q<=0;access_q<=0;priv_q<=0;level_q<=2;
      sum_q<=0;mxr_q<=0;ad_update_q<=0;pbmt_enable_q<=0;global_q<=0;pte_addr_q<=0;pa_q<=0;
      flags_q<=0;pbmt_q<=0;napot_q<=0;needs_ad_q<=0;fault_q<=0;cause_q<=0;
    end else case(state_q)
      IDLE: if(req_valid_i) begin
        va_q<=req_vaddr_i[38:0];root_q<=req_root_ppn_i;
        access_q<=req_access_i;priv_q<=req_priv_i;
        sum_q<=req_sum_i;mxr_q<=req_mxr_i;ad_update_q<=req_ad_update_i;pbmt_enable_q<=req_pbmt_enable_i;
        pte_addr_q<={req_root_ppn_i,req_vaddr_i[38:30],3'b0};
        level_q<=2;global_q<=0;fault_q<=!canonical_w;needs_ad_q<=0;
        cause_q<=req_access_i==0?5'd12:(req_access_i==1?5'd13:5'd15);
        state_q<=canonical_w?READ:RESULT;
      end
      READ: if(mem_ready_i) state_q<=CHECK;
      CHECK: if(mem_rsp_valid_i) begin
        if(mem_error_i) begin fault_q<=1;cause_q<=access_cause_w;state_q<=RESULT;end
        else if(base_bad_w||(leaf_w?(alignment_bad_w||permission_bad_w):nonleaf_bad_w)) begin
          fault_q<=1;cause_q<=page_cause_w;state_q<=RESULT;
        end else if(!leaf_w) begin
          pte_addr_q<={ppn_w,next_vpn_w,3'b0};level_q<=level_q-1'b1;
          global_q<=global_q||mem_rdata_i[5];state_q<=READ;
        end else begin
          pte_q<=mem_rdata_i;pa_q<=leaf_pa_w;flags_q<=mem_rdata_i[7:0];
          pbmt_q<=pbmt_w;napot_q<=napot_w;global_q<=global_q||mem_rdata_i[5];
          needs_ad_q<=needs_ad_w;
          state_q<=(needs_ad_w&&ad_update_q)?UPDATE:RESULT;
        end
      end
      UPDATE: if(mem_ready_i) state_q<=UPDATED;
      UPDATED: if(mem_rsp_valid_i) begin
        if(mem_error_i) begin fault_q<=1;cause_q<=access_cause_w;state_q<=RESULT;end
        else if(!mem_compare_ok_i) begin
          // Re-read every ancestor after a race; permissions/global attributes
          // may have changed along with the leaf itself.
          pte_addr_q<={root_q,va_q[38:30],3'b0};level_q<=2;
          global_q<=0;needs_ad_q<=0;state_q<=READ;
        end else begin
          pte_q<=pte_q|ad_mask_w;flags_q<=flags_q|ad_mask_w[7:0];
          needs_ad_q<=0;state_q<=RESULT;
        end
      end
      RESULT: if(rsp_ready_i) state_q<=IDLE;
      default: state_q<=IDLE;
    endcase
  end
`ifdef R64_ASSERT
  always @(posedge clk_i) if(!rst_i&&req_valid_i&&req_ready_o)
    if(req_access_i==3||req_priv_i>1)
      $fatal(1,"walker must receive a translated U/S access");
`endif
endmodule
