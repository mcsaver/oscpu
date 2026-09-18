// AXI4 transaction owners feeding the NPC platform's real single-beat endpoints.
// Four read / two write transactions share address launch and response buffers.
// IDs live until the upstream final R/B handshake; each Lite response accounts
// for exactly one beat. MMIO bursts and malformed descriptors have no side effect.
// Every external output depends only on registers (plus synchronous reset).
module R64AxiFabric #(
  parameter integer SLAVES=16,
  parameter integer SLAVE_W=4,
  parameter integer READ_CONTINUE=1,
  parameter integer EARLY_RETURN=1,
  parameter [SLAVES-1:0] READ_MEMORY_MASK=0,
  parameter [SLAVES*64-1:0] BASE=0,
  parameter [SLAVES*64-1:0] MASK=0,
  parameter [SLAVES-1:0] MEMORY=0,
  parameter [SLAVES-1:0] EXECUTABLE=0
)(
  input clk_i,input rst_i,
  input arvalid_i,output arready_o,input [3:0] arid_i,
  input [63:0] araddr_i,input [7:0] arlen_i,
  input [2:0] arsize_i,input [2:0] arprot_i,input [1:0] arburst_i,
  output rvalid_o,input rready_i,output [3:0] rid_o,
  output [63:0] rdata_o,output [1:0] rresp_o,output rlast_o,
  input awvalid_i,output awready_o,input [3:0] awid_i,
  input [63:0] awaddr_i,input [7:0] awlen_i,
  input [2:0] awsize_i,input [1:0] awburst_i,
  input wvalid_i,output wready_o,input [63:0] wdata_i,
  input [7:0] wstrb_i,input wlast_i,
  output bvalid_o,input bready_i,output [3:0] bid_o,output [1:0] bresp_o,
  output reg [SLAVES-1:0] s_arvalid_o,input [SLAVES-1:0] s_arready_i,
  output reg [SLAVES*64-1:0] s_araddr_o,
  output reg [SLAVES*3-1:0] s_arsize_o,output reg [SLAVES*3-1:0] s_arprot_o,
  input [SLAVES-1:0] s_rvalid_i,output reg [SLAVES-1:0] s_rready_o,
  input [SLAVES*64-1:0] s_rdata_i,input [SLAVES*2-1:0] s_rresp_i,
  output reg [SLAVES-1:0] s_awvalid_o,input [SLAVES-1:0] s_awready_i,
  output reg [SLAVES*64-1:0] s_awaddr_o,output reg [SLAVES*3-1:0] s_awsize_o,
  output reg [SLAVES-1:0] s_wvalid_o,input [SLAVES-1:0] s_wready_i,
  output reg [SLAVES*64-1:0] s_wdata_o,output reg [SLAVES*8-1:0] s_wstrb_o,
  input [SLAVES-1:0] s_bvalid_i,output reg [SLAVES-1:0] s_bready_o,
  input [SLAVES*2-1:0] s_bresp_i,
  output reg protocol_error_o
);
  // Distribute synchronous reset from a local register. External handshakes
  // VALID closes immediately on assertion; READY may be high during reset
  // but closes through the local clearing edge before accepting new work.
  // This removes input-reset arrival from every internal owner update cone.
  reg reset_q;
  always @(posedge clk_i) reset_q<=rst_i;
  wire active_w=!rst_i&&!reset_q;

  // One descriptor skid register per independently accepted address channel.
  reg ari_q,awi_q;
  reg [63:0] aria_q,awia_q;
  reg [3:0] arii_q,awii_q;
  reg [7:0] aril_q,awil_q;
  reg [2:0] aris_q,awis_q,arip_q;
  reg [1:0] arib_q,awib_q;
  assign arready_o=!ari_q&&!reset_q;
  assign awready_o=!awi_q&&!reset_q;

  reg [3:0] rlive_q,rwaiting_q,rterminal_q,rbad_q,rfixed_q;
  reg [63:0] ra_q[0:3];
  reg [3:0] ri_q[0:3];
  reg [7:0] rn_q[0:3];
  reg [2:0] rs_q[0:3],rp_q[0:3];
  reg [SLAVE_W-1:0] rt_q[0:3];
  // Shared four-owner table, independent memory/MMIO launch and return
  // services, and one two-entry output FIFO. The registered merge grant
  // limits physical return consumption to the FIFO's real single write port.
  reg merge_q;
  wire radmit_w,rpush_w;
  reg [1:0] rc_q;
  wire [1:0] group_ar_fire,group_return_occupied,group_return_valid;
  wire [SLAVES-1:0] group_ar_mask[0:1],group_return_mask[0:1],group_busy[0:1];
  wire [63:0] group_ar_addr[0:1],group_return_data[0:1];
  wire [2:0] group_ar_size[0:1],group_ar_prot[0:1];
  wire [1:0] group_ar_id[0:1],group_return_id[0:1],group_return_resp[0:1];
  wire [SLAVES-1:0] launch_mask_q=group_ar_mask[0]|group_ar_mask[1];
  wire [SLAVES-1:0] return_mask_q=group_return_mask[merge_q];
  wire [1:0] return_id_q=group_return_id[merge_q];
  wire [SLAVES-1:0] rbusy_q=group_busy[0]|group_busy[1];
  wire [255:0] owner_addr;
  wire [31:0] owner_len;wire [11:0] owner_size,owner_prot;
  wire [4*SLAVE_W-1:0] owner_target;
  reg [SLAVES-1:0] aw_owner0_q,aw_pending_q,w_pending_q;
  genvar descriptor,service;
  generate
    for(descriptor=0;descriptor<4;descriptor=descriptor+1)begin:gen_read_descriptor
      assign owner_addr[descriptor*64+:64]=ra_q[descriptor];
      assign owner_len[descriptor*8+:8]=rn_q[descriptor];
      assign owner_size[descriptor*3+:3]=rs_q[descriptor];
      assign owner_prot[descriptor*3+:3]=rp_q[descriptor];
      assign owner_target[descriptor*SLAVE_W+:SLAVE_W]=rt_q[descriptor];
    end
    for(service=0;service<2;service=service+1)begin:gen_read_service
      R64AxiReadService #(.SLAVES(SLAVES),.SLAVE_W(SLAVE_W),
        .GROUP_MASK(service==0?~READ_MEMORY_MASK:READ_MEMORY_MASK),.ACCEPT_BAD(service==0?1:0),
        .READ_CONTINUE(READ_CONTINUE),.EARLY_RETURN(EARLY_RETURN)) group(
        .clk_i(clk_i),.rst_i(rst_i),.reset_i(reset_q),
        .live_i(rlive_q),.waiting_i(rwaiting_q),.terminal_i(rterminal_q),.bad_i(rbad_q),.fixed_i(rfixed_q),
        .addr_i(owner_addr),.len_i(owner_len),.size_i(owner_size),.prot_i(owner_prot),.target_i(owner_target),
        .admit_i(radmit_w),.consume_i(rpush_w&&merge_q==service),.continue_credit_i(rc_q==0),
        .arready_i(s_arready_i),.rvalid_i(s_rvalid_i),.rdata_i(s_rdata_i),.rresp_i(s_rresp_i),
        .arvalid_o(group_ar_mask[service]),.return_mask_o(group_return_mask[service]),.busy_o(group_busy[service]),
        .araddr_o(group_ar_addr[service]),.arsize_o(group_ar_size[service]),.arprot_o(group_ar_prot[service]),
        .arfire_o(group_ar_fire[service]),.arid_o(group_ar_id[service]),
        .return_occupied_o(group_return_occupied[service]),.return_valid_o(group_return_valid[service]),
        .return_id_o(group_return_id[service]),.return_data_o(group_return_data[service]),
        .return_resp_o(group_return_resp[service]));
    end
  endgenerate

  reg [1:0] wlive_q,wbad_q,wfixed_q,wwait_q,waw_q,ww_q,wterminal_q;
  reg [63:0] wa_q[0:1];
  reg [3:0] wi_q[0:1];
  reg [7:0] wn_q[0:1];
  reg [2:0] ws_q[0:1];
  reg [SLAVE_W-1:0] wt_q[0:1];
  reg [1:0] we_q[0:1];
  reg [SLAVES-1:0] wbusy_q;
  reg [SLAVES-1:0] b_enable_q[0:1];
  reg [SLAVES-1:0] b_enable_next_r[0:1];
  // W has no ID: this two-entry queue is the accepted AW order.
  reg [1:0] order_q;
  reg oh_q,ot_q;
  reg [1:0] oc_q;
  wire wh_w=order_q[oh_q];
  reg [63:0] wd_q[0:1];
  reg [7:0] st_q[0:1];
  reg [1:0] wl_q;
  reg dh_q,dt_q;reg [1:0] dc_q;
  assign wready_o=dc_q<2&&!reset_q;
  wire data_push_w=wvalid_i&&wready_o;

  // Shared two-entry R queue; the original owner slot accompanies its data.
  reg [63:0] rd_q[0:1];
  reg [1:0] re_q[0:1],ro_q[0:1];
  reg [1:0] rl_q;
  reg rh_q,rrt_q;
  assign rvalid_o=rc_q!=0&&!rst_i;
  assign rdata_o=rd_q[rh_q];assign rid_o=ri_q[ro_q[rh_q]];
  assign rresp_o=re_q[rh_q];assign rlast_o=rl_q[rh_q];
  wire rpop_w=rc_q!=0&&rready_i;
  assign rpush_w=group_return_valid[merge_q]&&rc_q<2;

  // Terminal write results stay in their owner; arbitration/output is registered.
  reg bout_q,bowner_q;
  assign bvalid_o=bout_q&&!rst_i;
  assign bid_o=wi_q[bowner_q];assign bresp_o=we_q[bowner_q];
  wire bpop_w=bout_q&&bready_i;

  // A legal aligned beat fits inside its 4 KiB page. For INCR, page
  // overflow is the carry from the eight length bits AND the untouched
  // high offset bits. All four transfer widths are evaluated in parallel.
  function automatic page_cross(input [11:0] offset,input [7:0] len,
      input [2:0] size,input [1:0] burst);
    reg [8:0] c0,c1,c2,c3;
    reg over;
    begin
      c0={1'b0,offset[7:0]}+{1'b0,len};
      c1={1'b0,offset[8:1]}+{1'b0,len};
      c2={1'b0,offset[9:2]}+{1'b0,len};
      c3={1'b0,offset[10:3]}+{1'b0,len};
      case(size)
        0:over=(&offset[11:8])&&c0[8];
        1:over=(&offset[11:9])&&c1[8];
        2:over=(&offset[11:10])&&c2[8];
        3:over=offset[11]&&c3[8];
        default:over=1;
      endcase
      page_cross=(burst!=0)&&over;
    end
  endfunction
  function automatic misaligned(input [2:0] low,input [2:0] size);
    begin
      case(size)
        0:misaligned=0;
        1:misaligned=low[0];
        2:misaligned=|low[1:0];
        3:misaligned=|low;
        default:misaligned=1;
      endcase
    end
  endfunction
  // Once the page check passes, all high address bits are unchanged.
  // Page-aligned apertures need no second address comparator. Non-page
  // masks retain the exact last-beat low-address check.
  wire [11:0] arlast_low_w=aria_q[11:0]+((arib_q==0?12'd0:{4'd0,aril_q})<<aris_q);
  wire [11:0] awlast_low_w=awia_q[11:0]+((awib_q==0?12'd0:{4'd0,awil_q})<<awis_q);
  wire [SLAVES-1:0] ar_boundary_w,aw_boundary_w;
  genvar boundary;
  generate for(boundary=0;boundary<SLAVES;boundary=boundary+1)begin:gen_boundary
    if(MASK[boundary*64+:12]==0)begin
      assign ar_boundary_w[boundary]=0;
      assign aw_boundary_w[boundary]=0;
    end else begin
      assign ar_boundary_w[boundary]=
        ((arlast_low_w&MASK[boundary*64+:12])!=BASE[boundary*64+:12]);
      assign aw_boundary_w[boundary]=
        ((awlast_low_w&MASK[boundary*64+:12])!=BASE[boundary*64+:12]);
    end
  end endgenerate

  // Decode only captured descriptors, with first matching nonzero mask winning.
  integer j;
  reg arfound_r,awfound_r;
  reg [SLAVE_W-1:0] art_r,awt_r;
  reg arbad_r,awbad_r;
  always @(*) begin
    arfound_r=0;awfound_r=0;art_r=0;awt_r=0;
    for(j=0;j<SLAVES;j=j+1) begin
      if(!arfound_r&&MASK[j*64+:64]!=0&&
          (aria_q&MASK[j*64+:64])==BASE[j*64+:64]) begin
        arfound_r=1;art_r=j[SLAVE_W-1:0];
      end
      if(!awfound_r&&MASK[j*64+:64]!=0&&
          (awia_q&MASK[j*64+:64])==BASE[j*64+:64]) begin
        awfound_r=1;awt_r=j[SLAVE_W-1:0];
      end
    end
    arbad_r=!arfound_r||aris_q>3||arib_q>1||
        page_cross(aria_q[11:0],aril_q,aris_q,arib_q)||
        misaligned(aria_q[2:0],aris_q)||
        (arip_q[2]&&!EXECUTABLE[art_r])||
        (aril_q!=0&&!MEMORY[art_r])||
        (arib_q==0&&aril_q>15)||ar_boundary_w[art_r];
    awbad_r=!awfound_r||awis_q>3||awib_q>1||
        page_cross(awia_q[11:0],awil_q,awis_q,awib_q)||
        misaligned(awia_q[2:0],awis_q)||
        (awil_q!=0&&!MEMORY[awt_r])||
        (awib_q==0&&awil_q>15)||aw_boundary_w[awt_r];
  end

  integer k;
  reg rfree_r,rduplicate_r;reg [1:0] rslot_r;
  reg wfree_r,wduplicate_r,wslot_r;
  always @(*) begin
    rfree_r=0;rduplicate_r=0;rslot_r=0;
    wfree_r=0;wduplicate_r=0;wslot_r=0;
    for(k=0;k<4;k=k+1) begin
      if(!rfree_r&&!rlive_q[k]) begin rfree_r=1;rslot_r=k[1:0];end
      if(rlive_q[k]&&ri_q[k]==arii_q) rduplicate_r=1;
    end
    for(k=0;k<2;k=k+1) begin
      if(!wfree_r&&!wlive_q[k]) begin wfree_r=1;wslot_r=k[0];end
      if(wlive_q[k]&&wi_q[k]==awii_q) wduplicate_r=1;
    end
  end
  assign radmit_w=ari_q&&rfree_r&&!rduplicate_r;
  wire wadmit_w=awi_q&&wfree_r&&!wduplicate_r&&oc_q<2;
  // Captured-AW decode already ends at owner registers. If no older W owner
  // exists, admission can reserve the idle target at that same edge.
  wire wadmit_active_w=wadmit_w&&oc_q==0&&!awbad_r&&!wbusy_q[awt_r];
  // Prepare continuation payload while the current beat waits. A physical
  // response only qualifies the narrow install; it does not feed an address
  // increment followed by normal owner arbitration and the plan queue.
  wire [63:0] read_next_addr_w[0:3];
  wire [7:0] read_next_len_w[0:3];
  genvar continuation;
  generate for(continuation=0;continuation<4;continuation=continuation+1)begin:gen_continuation
    assign read_next_addr_w[continuation]={ra_q[continuation][63:12],
      ra_q[continuation][11:0]+(rfixed_q[continuation]?12'd0:(12'd1<<rs_q[continuation]))};
    assign read_next_len_w[continuation]=rn_q[continuation]-1'b1;
  end endgenerate
  wire wlaunch_w=oc_q!=0&&!wwait_q[wh_w]&&!wbad_q[wh_w]&&
      !wbusy_q[wt_q[wh_w]];
  // The registered offer is the exact externally visible W owner.
  // Consume its one-hot handshake directly; WREADY does not select an
  // encoded owner/target before it can release queue capacity.
  wire wbeat_w=(oc_q!=0&&dc_q!=0&&wbad_q[wh_w])||
      (|(w_pending_q&s_wready_i));
  wire order_pop_w=wbeat_w&&wn_q[wh_w]==0;

  // A real final Lite B (or the final drained bad-descriptor W) can select
  // the empty registered AXI B output at the same edge that records terminal.
  wire [1:0] wreturn_w,wterminal_now_w;
  genvar wb;
  generate for(wb=0;wb<2;wb=wb+1) begin:gen_write_return
    assign wreturn_w[wb]=|(b_enable_q[wb]&s_bvalid_i);
    assign wterminal_now_w[wb]=(wreturn_w[wb]&&wn_q[wb]==0)||
      (wbeat_w&&wbad_q[wb]&&wh_w==wb&&wn_q[wb]==0);
  end endgenerate

  // Capture the exact set of endpoints eligible to return B at the same
  // edge that accepts the last missing AW/W channel. The external BVALID
  // arrival then crosses one masked reduction, not owner decode plus a
  // wide completion/next-beat control tree. No transaction cycle is added.
  integer bc;
  always @(*) begin
    for(bc=0;bc<2;bc=bc+1) begin
      b_enable_next_r[bc]=0;
      if(wwait_q[bc]&&!wreturn_w[bc]&&
         (waw_q[bc]||s_awready_i[wt_q[bc]])&&
         (ww_q[bc]||(wbeat_w&&wh_w==bc[0])))
        b_enable_next_r[bc][wt_q[bc]]=1;
    end
  end

  // Internal events are sampled only by the reset-prioritized clock block.
  // Repeating a combinational reset qualification inside each event would
  // carry reset through credit prediction and route selection unnecessarily.
  // Project the next W owner into a one-hot output register. Computing this
  // alongside owner updates keeps current-cycle queue-count/head decoding
  // away from the external WVALID pin, without adding a transaction cycle.
  // W consumption arrives from the external slave. Prepare both possible
  // queue projections from current owners, then select only their narrow
  // endpoint mask with that late handshake. No queue accepts twice.
  wire [SLAVES-1:0] w_offer_w[0:1];
  genvar take;
  generate for(take=0;take<2;take=take+1) begin:gen_write_projection
    localparam TAKE=(take==1);
    reg [1:0] wwait_next_r,ww_next_r,oc_next_r,dc_next_r;
    reg whead_next_r;
    reg [SLAVE_W-1:0] wt_next_r[0:1];
    reg [SLAVES-1:0] w_pending_next_r;
    wire pop_order=TAKE&&wn_q[wh_w]==0;
    integer wn,endpoint;
    always @* begin

    wwait_next_r=wwait_q;ww_next_r=ww_q;
    wt_next_r[0]=wt_q[0];wt_next_r[1]=wt_q[1];
    oc_next_r=oc_q;dc_next_r=dc_q;whead_next_r=wh_w;
    case({wadmit_w,pop_order})
      2'b10:oc_next_r=oc_q+1'b1;
      2'b01:oc_next_r=oc_q-1'b1;
      default:begin end
    endcase
    case({data_push_w,TAKE})
      2'b10:dc_next_r=dc_q+1'b1;
      2'b01:dc_next_r=dc_q-1'b1;
      default:begin end
    endcase
    if(pop_order) whead_next_r=order_q[~oh_q];
    if(wadmit_w&&(oc_q==0||(pop_order&&oc_q==1))) whead_next_r=wslot_r;
    if(wadmit_w) begin
      wwait_next_r[wslot_r]=wadmit_active_w;ww_next_r[wslot_r]=0;
      wt_next_r[wslot_r]=awt_r;
    end
    if(wlaunch_w) begin wwait_next_r[wh_w]=1;ww_next_r[wh_w]=0;end
    if(TAKE&&!wbad_q[wh_w]) ww_next_r[wh_w]=1;
    w_pending_next_r=0;
    for(endpoint=0;endpoint<SLAVES;endpoint=endpoint+1)
      w_pending_next_r[endpoint]=oc_next_r!=0&&dc_next_r!=0&&
        ((!whead_next_r&&wwait_next_r[0]&&!ww_next_r[0]&&
          wt_next_r[0]==endpoint[SLAVE_W-1:0])||
         (whead_next_r&&wwait_next_r[1]&&!ww_next_r[1]&&
          wt_next_r[1]==endpoint[SLAVE_W-1:0]));
    // A nonfinal B restarts the same burst owner, which still owns the
    // W-order head. Its registered endpoint mask updates WVALID locally;
    // late BVALID need not traverse head selection and target encoding.
    for(wn=0;wn<2;wn=wn+1)
      for(endpoint=0;endpoint<SLAVES;endpoint=endpoint+1)
        if(oc_q!=0&&wh_w==wn[0]&&wn_q[wn]!=0&&
           (dc_q!=0||data_push_w)&&b_enable_q[wn][endpoint]&&s_bvalid_i[endpoint])
          w_pending_next_r[endpoint]=1;
    end
    assign w_offer_w[take]=w_pending_next_r;
  end endgenerate
  wire [SLAVES-1:0] w_pending_next_r=wbeat_w?w_offer_w[1]:w_offer_w[0];

  integer s;
  always @(*) begin
    s_arvalid_o=0;s_rready_o=0;s_awvalid_o=0;s_wvalid_o=0;s_bready_o=0;
    s_araddr_o=0;s_arsize_o=0;s_arprot_o=0;
    s_awaddr_o=0;s_awsize_o=0;s_wdata_o=0;s_wstrb_o=0;
    // Payload comes from its held owner. VALID alone authorizes a slave;
    // inactive payload need not be zero. Keeping reset/admission off these
    // wide buses avoids duplicating their control cone for every address bit.
    for(s=0;s<SLAVES;s=s+1) begin
      s_araddr_o[s*64+:64]=group_ar_addr[READ_MEMORY_MASK[s]];
      s_arsize_o[s*3+:3]=group_ar_size[READ_MEMORY_MASK[s]];
      s_arprot_o[s*3+:3]=group_ar_prot[READ_MEMORY_MASK[s]];
      s_wdata_o[s*64+:64]=wd_q[dh_q];
      s_wstrb_o[s*8+:8]=st_q[dh_q];
      if(aw_owner0_q[s]) begin
        s_awaddr_o[s*64+:64]=wa_q[0];s_awsize_o[s*3+:3]=ws_q[0];
      end else begin
        s_awaddr_o[s*64+:64]=wa_q[1];s_awsize_o[s*3+:3]=ws_q[1];
      end
    end
    s_arvalid_o=launch_mask_q&{SLAVES{!rst_i}};
    s_awvalid_o=aw_pending_q&{SLAVES{!rst_i}};
    // AXI reset requires VALID low. READY may remain asserted; the reset
    // branch clears every owner and suppresses internal receive events.
    s_rready_o=return_mask_q&{SLAVES{rc_q<2}};
    s_bready_o=b_enable_q[0]|b_enable_q[1];
    s_wvalid_o=w_pending_q&{SLAVES{!rst_i}};
    if(reset_q) begin
      s_rready_o=0;s_bready_o=0;
    end
  end

  integer n;
  always @(posedge clk_i) begin
    if(reset_q) begin
      ari_q<=0;awi_q<=0;rlive_q<=0;rwaiting_q<=0;rterminal_q<=0;
      rbad_q<=0;rfixed_q<=0;merge_q<=0;
      aw_pending_q<=0;w_pending_q<=0;aw_owner0_q<=0;
      wlive_q<=0;wbad_q<=0;wfixed_q<=0;wwait_q<=0;waw_q<=0;ww_q<=0;
      wterminal_q<=0;wbusy_q<=0;oc_q<=0;oh_q<=0;ot_q<=0;
      dc_q<=0;dh_q<=0;dt_q<=0;rc_q<=0;rh_q<=0;rrt_q<=0;
      bout_q<=0;bowner_q<=0;protocol_error_o<=0;
      b_enable_q[0]<=0;b_enable_q[1]<=0;
    end else begin
      w_pending_q<=w_pending_next_r;
      b_enable_q[0]<=b_enable_next_r[0];b_enable_q[1]<=b_enable_next_r[1];
      if(arvalid_i&&arready_o) begin
        ari_q<=1;aria_q<=araddr_i;arii_q<=arid_i;aril_q<=arlen_i;
        aris_q<=arsize_i;arip_q<=arprot_i;arib_q<=arburst_i;
      end
      if(awvalid_i&&awready_o) begin
        awi_q<=1;awia_q<=awaddr_i;awii_q<=awid_i;awil_q<=awlen_i;
        awis_q<=awsize_i;awib_q<=awburst_i;
      end
      if(radmit_w) begin
        ari_q<=0;rlive_q[rslot_r]<=1;rwaiting_q[rslot_r]<=0;
        rterminal_q[rslot_r]<=0;rbad_q[rslot_r]<=arbad_r;
        ra_q[rslot_r]<=aria_q;ri_q[rslot_r]<=arii_q;rn_q[rslot_r]<=aril_q;
        rs_q[rslot_r]<=aris_q;rp_q[rslot_r]<=arip_q;rt_q[rslot_r]<=art_r;
        rfixed_q[rslot_r]<=arib_q==0;
      end
      for(n=0;n<2;n=n+1)
        if(group_ar_fire[n])rwaiting_q[group_ar_id[n]]<=1;
      // RREADY uses this registered group grant and registered queue credit.
      // A silent endpoint cannot hold the other group's ready mask forever.
      if(READ_MEMORY_MASK!=0&&(rpush_w||!group_return_valid[merge_q])&&
        (group_return_occupied[~merge_q]||group_ar_fire[~merge_q]))
        merge_q<=~merge_q;
      if(rpush_w) begin
        rd_q[rrt_q]<=group_return_data[merge_q];
        re_q[rrt_q]<=group_return_resp[merge_q];
        rl_q[rrt_q]<=rn_q[return_id_q]==0;ro_q[rrt_q]<=return_id_q;
        rrt_q<=~rrt_q;rwaiting_q[return_id_q]<=0;
        if(rn_q[return_id_q]==0) rterminal_q[return_id_q]<=1;
        else begin
          rn_q[return_id_q]<=read_next_len_w[return_id_q];
          // Admission rejects every burst crossing a 4 KiB boundary.
          // Its page number is immutable; only the within-page offset advances.
          if(!rbad_q[return_id_q]&&!rfixed_q[return_id_q])
            ra_q[return_id_q]<=read_next_addr_w[return_id_q];
        end
      end
      if(rpop_w) begin
        rh_q<=~rh_q;
        if(rl_q[rh_q]) rlive_q[ro_q[rh_q]]<=0;
      end
      case({rpush_w,rpop_w})
        2'b10:rc_q<=rc_q+1'b1;
        2'b01:rc_q<=rc_q-1'b1;
        default:begin end
      endcase

      if(wadmit_w) begin
        awi_q<=0;wlive_q[wslot_r]<=1;wbad_q[wslot_r]<=awbad_r;
        wfixed_q[wslot_r]<=awib_q==0;wwait_q[wslot_r]<=wadmit_active_w;
        if(wadmit_active_w) begin
          wbusy_q[awt_r]<=1;aw_pending_q[awt_r]<=1;
          aw_owner0_q[awt_r]<=!wslot_r;
        end
        waw_q[wslot_r]<=0;ww_q[wslot_r]<=0;wterminal_q[wslot_r]<=0;
        wa_q[wslot_r]<=awia_q;wi_q[wslot_r]<=awii_q;wn_q[wslot_r]<=awil_q;
        ws_q[wslot_r]<=awis_q;wt_q[wslot_r]<=awt_r;
        we_q[wslot_r]<=awbad_r?2'b11:2'b00;
        order_q[ot_q]<=wslot_r;ot_q<=~ot_q;
      end
      if(data_push_w) begin
        wd_q[dt_q]<=wdata_i;st_q[dt_q]<=wstrb_i;wl_q[dt_q]<=wlast_i;dt_q<=~dt_q;
      end
      if(wlaunch_w) begin
        wwait_q[wh_w]<=1;waw_q[wh_w]<=0;ww_q[wh_w]<=0;
        wbusy_q[wt_q[wh_w]]<=1;aw_pending_q[wt_q[wh_w]]<=1;
        aw_owner0_q[wt_q[wh_w]]<=!wh_w;
      end
      if(wbeat_w) begin
        dh_q<=~dh_q;
        if(wl_q[dh_q]!=(wn_q[wh_w]==0)) begin
          protocol_error_o<=1;we_q[wh_w]<=2'b10;
        end
        if(wbad_q[wh_w]) begin
          if(wn_q[wh_w]==0) wterminal_q[wh_w]<=1;
          else wn_q[wh_w]<=wn_q[wh_w]-1'b1;
        end else ww_q[wh_w]<=1;
      end
      if(order_pop_w) begin oh_q<=~oh_q;end
      case({wadmit_w,order_pop_w})
        2'b10:oc_q<=oc_q+1'b1;
        2'b01:oc_q<=oc_q-1'b1;
        default:begin end
      endcase
      case({data_push_w,wbeat_w})
        2'b10:dc_q<=dc_q+1'b1;
        2'b01:dc_q<=dc_q-1'b1;
        default:begin end
      endcase
      for(n=0;n<2;n=n+1) begin
        if(wwait_q[n]) begin
          if(!waw_q[n]&&s_awready_i[wt_q[n]]) begin
            waw_q[n]<=1;aw_pending_q[wt_q[n]]<=0;
          end
          if(wreturn_w[n]) begin
            if(s_bresp_i[wt_q[n]*2+:2]!=0) we_q[n]<=we_q[n]|s_bresp_i[wt_q[n]*2+:2];
            if(wn_q[n]==0) begin
              wwait_q[n]<=0;wbusy_q[wt_q[n]]<=0;wterminal_q[n]<=1;
            end else begin
              // The same burst owner retains the slave. The next beat starts
              // only after this real B; AW/W remain independent registered outputs.
              waw_q[n]<=0;ww_q[n]<=0;aw_pending_q[wt_q[n]]<=1;
              wn_q[n]<=wn_q[n]-1'b1;
              if(!wfixed_q[n]) wa_q[n][11:0]<=wa_q[n][11:0]+(12'd1<<ws_q[n]);
            end
          end
        end
      end
      if(bpop_w) begin
        bout_q<=0;wlive_q[bowner_q]<=0;wterminal_q[bowner_q]<=0;
      end
      if(!bout_q) begin
        if(wterminal_q[0]||wterminal_now_w[0]) begin bout_q<=1;bowner_q<=0;end
        else if(wterminal_q[1]||wterminal_now_w[1]) begin bout_q<=1;bowner_q<=1;end
      end
    end
    // Clear only the external VALID owners on the original reset edge.
    // Bulk owner state still uses local reset. During recovery these small
    // records stay empty, so the pin clamp needs only the current reset.
    if(rst_i) begin
      aw_pending_q<=0;w_pending_q<=0;rc_q<=0;bout_q<=0;
    end
  end
`ifdef R64_ASSERT
  always @(posedge clk_i) if(reset_q&&!rst_i) begin
    if((|launch_mask_q)||(|aw_pending_q)||(|w_pending_q)||rc_q!=0||bout_q)
      $fatal(1,"fabric VALID owner survived external reset edge");
  end
  always @(posedge clk_i) if(active_w) begin
    if(b_enable_q[0]!==((wwait_q[0]&&waw_q[0]&&ww_q[0]) ? ({{(SLAVES-1){1'b0}},1'b1}<<wt_q[0]):{SLAVES{1'b0}}) ||
       b_enable_q[1]!==((wwait_q[1]&&waw_q[1]&&ww_q[1]) ? ({{(SLAVES-1){1'b0}},1'b1}<<wt_q[1]):{SLAVES{1'b0}}))
      $fatal(1,"fabric B eligibility disagrees with physical AW/W owners");
    if(aw_pending_q !==
       ((wwait_q[0]&&!waw_q[0] ? ({{(SLAVES-1){1'b0}},1'b1}<<wt_q[0]) : {SLAVES{1'b0}}) |
        (wwait_q[1]&&!waw_q[1] ? ({{(SLAVES-1){1'b0}},1'b1}<<wt_q[1]) : {SLAVES{1'b0}})))
      $fatal(1,"Fabric registered AW route disagrees with owner");
    if(w_pending_q !==
       ((oc_q!=0&&dc_q!=0&&wwait_q[wh_w]&&!ww_q[wh_w]) ?
        ({{(SLAVES-1){1'b0}},1'b1}<<wt_q[wh_w]) : {SLAVES{1'b0}}))
      $fatal(1,"Fabric registered W route disagrees with owner");
    if((|(group_busy[0]&group_busy[1]))||(|(group_ar_mask[0]&group_ar_mask[1])))
      $fatal(1,"fabric service groups share an endpoint owner");
    if(group_ar_fire==3&&group_ar_id[0]==group_ar_id[1])
      $fatal(1,"fabric service groups launched one descriptor twice");
    if(rc_q>2||dc_q>2||oc_q>2)$fatal(1,"fabric queue capacity exceeded");
    if(wbeat_w&&wl_q[dh_q]!=(wn_q[wh_w]==0))
      $fatal(1,"fabric WLAST disagrees with accepted AWLEN");
  end
  // Check the offer against the canonical owner and queue, including
  // simultaneous last-W, new-AW, and newly available data.
  wire wbeat_contract_w=oc_q!=0&&dc_q!=0&&
      (wbad_q[wh_w]||(wwait_q[wh_w]&&!ww_q[wh_w]&&s_wready_i[wt_q[wh_w]]));
  always @(posedge clk_i)
    if(!rst_i&&!reset_q&&wbeat_w!==wbeat_contract_w)
      $fatal(1,"W offer disagrees with canonical owner");
`endif
endmodule
