`timescale 1ns/1ps

module tb_r64_protection_registered;
  reg clk=0; always #5 clk=~clk;
  reg rst=1, qvalid=0, qready=0;
  reg [63:0] qpa=64'h80001000;
  reg [64:0] qlast=65'h80001007;
  reg [3:0] qprotection=4'b0111;
  reg [1:0] qpriv=3,qpbmt=0,qclass=0;
  reg qpmafault=0,qfault=0,qad=0;
  reg [4:0] qcause=5;
  reg [15:0] qactive=0;
  reg [895:0] qlo=0,qhi=0;
  reg [63:0] qpermission=0;
  wire qaccept,qrv;
  wire [63:0] qoutpa;
  wire [1:0] qoutclass;
  wire qoutfault,qoutad;
  wire [4:0] qoutcause;
  wire [3:0] qoutprotection;
  wire [76:0] qpayload={qoutpa,qoutclass,qoutfault,qoutad,qoutcause,qoutprotection};
  reg [76:0] saved;
  integer invalid_checks=0;
  R64DataProtection #(.PMA_PREPARED(1),.EMPTY_FLOW(0)) leaf(
    .clk_i(clk),.rst_i(rst),.req_valid_i(qvalid),.req_ready_o(qaccept),
    .req_paddr_i(qpa),.req_last_i(qlast),.req_protection_i(qprotection),
    .req_priv_i(qpriv),.req_pbmt_i(qpbmt),.req_pma_class_i(qclass),
    .req_pma_fault_i(qpmafault),.req_fault_i(qfault),.req_needs_ad_i(qad),.req_cause_i(qcause),
    .pmp_active_i(qactive),.pmp_lower_i(qlo),.pmp_upper_i(qhi),.pmp_permission_i(qpermission),
    .rsp_valid_o(qrv),.rsp_ready_i(qready),.rsp_paddr_o(qoutpa),.rsp_class_o(qoutclass),
    .rsp_fault_o(qoutfault),.rsp_needs_ad_o(qoutad),.rsp_cause_o(qoutcause),.rsp_protection_o(qoutprotection)
  );
  localparam T=9;
  reg run=0;
  reg [1:0] rr=0;
  reg [63:0] permission=3;
  reg [895:0] lower=0,upper=0;
  wire [1:0] v,r,rv,fault,ad;
  wire [2*T-1:0] token,rtoken;
  wire [127:0] va,pa;
  wire [3:0] access_kind,classes;
  wire [7:0] protection;
  wire [9:0] cause;
  wire idle;
  integer sent[0:1],returned[0:1],last_return[0:1];
  integer limit=4,cycle=0,cancelled=0,replacements=0,dual_replacements=0,held=0,ii_checks=0;
  reg [1:0] held_q=0;
  reg [T+72:0] held_payload[0:1];
  genvar lane;
  generate for(lane=0;lane<2;lane=lane+1)begin:g_lane
    wire store_kind=(sent[lane]+lane)%2;
    assign v[lane]=run && sent[lane]<limit;
    assign token[lane*T+:T]=T'(9'h80+lane*64+sent[lane]*3);
    assign va[lane*64+:64]=64'h80002000+lane*1024+sent[lane]*8;
    assign access_kind[lane*2+:2]=store_kind?2'd2:2'd1;
    assign protection[lane*4+:4]={store_kind,!store_kind,2'b11};
  end endgenerate
  R64DataTranslationService #(.TOKEN_W(T)) dut(
    .clk_i(clk),.rst_i(rst),.req_valid_i(v),.req_ready_o(r),.req_token_i(token),.req_vaddr_i(va),
    .req_access_i(access_kind),.req_protection_i(protection),.req_ad_update_i(2'b0),
    .rsp_valid_o(rv),.rsp_ready_i(rr),.rsp_token_o(rtoken),.rsp_paddr_o(pa),.rsp_class_o(classes),
    .rsp_fault_o(fault),.rsp_needs_ad_o(ad),.rsp_cause_o(cause),.idle_o(idle),
    .privilege_i(2'd1),.mstatus_i(64'b0),.satp_i(64'b0),.pbmt_enable_i(1'b1),
    .pmp_active_i(16'b1),.pmp_lower_i(lower),.pmp_upper_i(upper),.pmp_permission_i(permission),
    .tlb_invalidate_i(1'b0),.tlb_all_vaddr_i(1'b1),.tlb_all_asid_i(1'b1),
    .tlb_vpn_i(27'b0),.tlb_asid_i(16'b0),
    .mem_valid_o(),.mem_ready_i(2'b11),.mem_compare_or_o(),.mem_addr_o(),.mem_expected_o(),.mem_or_mask_o(),
    .mem_rsp_valid_i(2'b0),.mem_rsp_ready_o(),.mem_rdata_i(128'b0),
    .mem_error_i(2'b0),.mem_compare_ok_i(2'b0)
  );
  always @(posedge clk)begin
    if(rst)begin
      cycle<=0;held_q<=0;
      for(integer l=0;l<2;l=l+1)begin sent[l]<=0;returned[l]<=0;last_return[l]<=-1;end
    end else begin
      cycle<=cycle+1;
      if (&(rv & rr & dut.raw_valid & dut.raw_ready)) dual_replacements=dual_replacements+1;
      for(integer l=0;l<2;l=l+1)begin
        reg [T+72:0] payload;
        bit is_store,expected_fault;
        payload={rtoken[l*T+:T],pa[l*64+:64],classes[l*2+:2],fault[l],ad[l],cause[l*5+:5]};
        if(held_q[l] && (!rv[l] || payload!==held_payload[l]))
          $fatal(1,"PMP change modified held owner lane=%0d",l);
        held_q[l]<=rv[l]&&!rr[l];held_payload[l]<=payload;
        if(rv[l]&&!rr[l])held=held+1;
        if(v[l]&&r[l])sent[l]<=sent[l]+1;
        if(rv[l]&&rr[l])begin
          is_store=(returned[l]+l)%2;
          expected_fault=returned[l]!=0 && !is_store;
          if(returned[l]>=sent[l] || rtoken[l*T+:T]!==T'(9'h80+l*64+returned[l]*3) ||
             pa[l*64+:64]!==64'h80002000+l*1024+returned[l]*8 ||
             classes[l*2+:2]!==0 || ad[l] || fault[l]!==expected_fault ||
             cause[l*5+:5] !== (is_store?5'd7:5'd5))
            $fatal(1,"old-pop/new-push token/facts mispaired lane=%0d item=%0d token=%h fault=%b cause=%0d",
              l,returned[l],rtoken[l*T+:T],fault[l],cause[l*5+:5]);
          if(returned[l]<4)cancelled=cancelled+1;
          if(returned[l]>=8)begin
            if(cycle!=last_return[l]+1)$fatal(1,"registered protection lost II=1 lane=%0d",l);
            ii_checks=ii_checks+1;
          end
          if(dut.raw_valid[l]&&dut.raw_ready[l])replacements=replacements+1;
          last_return[l]<=cycle;returned[l]<=returned[l]+1;
        end
      end
    end
  end
  initial begin
    lower[0+:56]=56'h80000000;upper[0+:56]=56'h8000ffff;
    repeat(3)@(negedge clk);rst=0;
    // Invalid Q is allowed synchronous prewrite, never a raw combinational path.
    repeat(8)begin
      @(posedge clk);#1;saved=qpayload;
      qpa=qpa+64'h1234;qlast={1'b1,~qpa};qprotection=~qprotection;
      qpriv=~qpriv;qpbmt=qpbmt+1'b1;qclass=qclass+1'b1;
      qpmafault=~qpmafault;qfault=~qfault;qad=~qad;qcause=qcause+1'b1;
      qactive=~qactive;qlo=~qlo;qhi=~qhi;qpermission=~qpermission;
      #1;if(qrv || qpayload!==saved)$fatal(1,"registered invalid payload follows raw/PMP");
      invalid_checks=invalid_checks+1;
    end
    @(negedge clk);run=1;
    while(sent[0]!=4 || sent[1]!=4 || rv!=3)@(negedge clk);
    repeat(4)@(negedge clk);
    // First response was sampled while R/W allowed; all eight leases are now
    // caller-cancelled. They must drain in order while the new PMP denies reads.
    permission=2;
    repeat(6)@(negedge clk);
    if(sent[0]!=4 || sent[1]!=4 || r!=0 || idle)$fatal(1,"held token credit/owner lost");
    rr=3;limit=24;
    while(returned[0]!=24 || returned[1]!=24)@(negedge clk);
    run=0;repeat(2)@(negedge clk);
    if(!idle || cancelled!=8 || replacements<32 || dual_replacements<16 || ii_checks!=32)
      $fatal(1,"missing replacement/cancellation/II coverage");
    $display("[PASS] tb_r64_protection_registered tokens=48 cancelled_drains=%0d held=%0d replacements=%0d dual_replacements=%0d II_checks=%0d invalid_Q_checks=%0d",
      cancelled,held,replacements,dual_replacements,ii_checks,invalid_checks);
    $finish;
  end
  initial begin #20000;$fatal(1,"registered boundary timeout");end
endmodule
