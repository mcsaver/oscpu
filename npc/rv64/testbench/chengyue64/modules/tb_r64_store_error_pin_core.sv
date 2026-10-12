`timescale 1ns/1ps
`include "R64Dispatch.vh"
// Whole real Core: external AXI memory is the only functional model.
// No internal state is forced; all roots/consumers enter through instruction fetch.
module tb_r64_store_error_pin_core;
  reg          clk_i;
  reg          rst_i;
  reg          run_i;
  reg  [ 63:0] time_i;
  reg          irq_software_i, irq_timer_i, irq_external_i, irq_supervisor_external_i;
  reg          dma_invalidate_i;
  reg          wfi_wait_i;
  wire         arvalid_o;
  reg          arready_i;
  wire [  3:0] arid_o;
  wire [ 63:0] araddr_o;
  wire [  7:0] arlen_o;
  wire [  2:0] arsize_o, arprot_o;
  wire [  1:0] arburst_o;
  reg          rvalid_i;
  wire         rready_o;
  reg  [  3:0] rid_i;
  reg  [ 63:0] rdata_i;
  reg  [  1:0] rresp_i;
  reg          rlast_i;
  wire         awvalid_o;
  reg          awready_i;
  wire [  3:0] awid_o;
  wire [ 63:0] awaddr_o;
  wire [  7:0] awlen_o;
  wire [  2:0] awsize_o, awprot_o;
  wire [  1:0] awburst_o;
  wire         wvalid_o;
  reg          wready_i;
  wire [ 63:0] wdata_o;
  wire [  7:0] wstrb_o;
  wire         wlast_o;
  reg          bvalid_i;
  wire         bready_o;
  reg  [  3:0] bid_i;
  reg  [  1:0] bresp_i;
  wire         tensor_cmd_valid_o;
  reg          tensor_cmd_ready_i;
  wire [  8:0] tensor_cmd_tag_o;
  wire [ 63:0] tensor_cmd_o, tensor_operand_o;
  wire         tensor_pair_o;
  wire [  7:0] tensor_class_o;
  reg          tensor_terminal_valid_i;
  wire         tensor_terminal_ready_o;
  reg  [  8:0] tensor_terminal_tag_i;
  reg          tensor_error_i;
  reg  [  7:0] tensor_error_code_i;
  // Combinational architectural events, accepted on this clock edge. A simulator
  // may register observations outside the hardware core. READY throttles retire.
  reg  [  1:0] trace_ready_i;
  wire [  1:0] trace_valid_o;
  wire [127:0] trace_pc_o, trace_raw_o, trace_npc_o, trace_data_o;
  wire [  7:0] trace_length_o;
  wire [  1:0] trace_rd_write_o, trace_rd_fp_o;
  wire [  9:0] trace_rd_arch_o, trace_fflags_o;
  wire [ 15:0] trace_kind_o;
  wire         trap_valid_o, trap_interrupt_o;
  wire [  5:0] trap_cause_o;
  wire [ 63:0] trap_pc_o, trap_tval_o, trap_raw_o, trap_target_o;
  wire [  3:0] trap_length_o;
  wire [  1:0] privilege_o;
  wire [ 63:0] mstatus_o, satp_o;
  wire [  5:0] rob_count_o;
  wire         protocol_error_o;
  R64CoreTop dut(.*);
  initial clk_i=0;
  always #5 clk_i=~clk_i;

  `define LS dut.memory.unit.lsu
  localparam integer N = 20;
  initial begin
    if ($bits(`LS.alive_q) != N || $bits(`LS.query_front_pin_w) != 2*N)
      $fatal(1,"Core LSQ pin-observer width mismatch");
  end
  reg [7:0] ram[0:8191];
  reg [15:0] busy=0;
  reg [63:0] bus_addr[0:15];
  integer bus_beat[0:15],bus_len[0:15],bus_release[0:15];
  reg awheld=0,wheld=0,bpending=0,rheld=0,release_b=0;
  reg [63:0] wa,wd;
  reg [7:0] ws;
  reg [3:0] wi;
  integer cycles=0,checks=0,commits=0,source_slot=-1,source_tag=-1;
  integer error_edge=-1,external_b=-1,flush_edge=-1,local_flush_edge=-1,trap_edge=-1;
  integer free_pin_edges=0,newreserve_after_error=0,reuse_after_error=0,pin_start=-1;
  integer data_reads=0,writes=0,reservations=0,query_pinned_takes=0,attempts=0;
  reg trap_seen=0;
  integer b_delay=24,blocked_cycle=-1,unused_plusarg;
  reg[63:0] saved_source;
  function [31:0] addi(input integer rd,rs,im);
    addi={12'(im),5'(rs),3'b000,5'(rd),7'h13};
  endfunction
  function [31:0] ld(input integer rd,rs,im);
    ld={12'(im),5'(rs),3'b011,5'(rd),7'h03};
  endfunction
  task put(input integer off,input[31:0] ins);
    for(integer n=0;n<4;n=n+1)ram[off+n]=ins[n*8+:8];
  endtask
  function [63:0] readmem(input[63:0]addr);
    reg[63:0]v;
    begin
      v=64'h0000001300000013;
      if(addr>=64'h80000000&&addr<=64'h80001ff8)
        for(integer k=0;k<8;k=k+1)v[k*8+:8]=ram[int'(addr-64'h80000000)+k];
      readmem=v;
    end
  endfunction
  task check(input bit okay,input[767:0]message);
    begin checks=checks+1;if(!okay)$fatal(1,"%0s cycle=%0d",message,cycles);end
  endtask
  // Observe only real public transactions and internal certificates; no force
  // or internal assignment supplies admission, bindings, owners, or recovery.
  always @(posedge clk_i)if(!rst_i)begin
    cycles=cycles+1;time_i=64'(cycles);
    check(!protocol_error_o,"AXI protocol error");
    if(arvalid_o&&arready_i)begin
      check(!busy[arid_o]&&arid_o<2&&arburst_o==1,"AR owner/order");
      busy[arid_o]=1;bus_addr[arid_o]=araddr_o;
      bus_beat[arid_o]=0;bus_len[arid_o]=int'(arlen_o);
      bus_release[arid_o]=cycles+(arid_o==1?160:1);
      if(arid_o==1)data_reads=data_reads+1;
    end
    rheld=rvalid_i&&!rready_o;
    if(rvalid_i&&rready_o)begin
      if(rlast_i)busy[rid_i]=0;else bus_beat[rid_i]=bus_beat[rid_i]+1;
    end
    if(bvalid_i&&bready_o)begin bpending=0;external_b=cycles;end
    if(awvalid_o&&awready_i)begin
      check(!awheld&&awlen_o==0&&awburst_o==1,"AW owner");awheld=1;wa=awaddr_o;wi=awid_o;
    end
    if(wvalid_o&&wready_i)begin
      check(!wheld&&wlast_o,"W owner");wheld=1;wd=wdata_o;ws=wstrb_o;
    end
    if(awheld&&wheld&&!bpending)begin
      check(wa==64'h80001001&&ws==8'h02&&wd[15:8]==8'h11,"old store external byte identity");
      awheld=0;wheld=0;bpending=1;writes=writes+1;
      // This external transaction will fail, hence memory is not modified.
    end
    for(integer l=0;l<2;l=l+1)begin
      if(dut.backend.birth_w[l]&&dut.backend.decode_uop_w[l*`R64_UOP_W+:64]==64'h80000008)begin
        check(dut.lsu_reserve_fire[l],"source common memory birth");
        source_slot=int'(dut.lsu_reserve_selected[l*5+:5]);
        source_tag=int'(dut.backend.birth_tag_w[l*9+:9]);
      end
      if(dut.lsu_reserve_fire[l])begin
        reservations=reservations+1;
        if(error_edge>=0&&cycles>error_edge)begin
          newreserve_after_error=newreserve_after_error+1;
          if(dut.lsu_reserve_selected[l*5+:5]==5'(source_slot))reuse_after_error=reuse_after_error+1;
        end
      end
      if(trace_valid_o[l])begin
        check(commits<2&&trace_pc_o[l*64+:64]==64'h80000000+64'(commits)*4,
              "faulting store or younger instruction retired");
        check(trace_rd_write_o[l]&&!trace_rd_fp_o[l],"setup destination");
        check(trace_data_o[l*64+:64]==(commits==0?64'h80001000:64'h11),"setup golden value");
        commits=commits+1;
      end
      if(source_slot>=0&&`LS.query_valid_w[l]&&
         `LS.query_front_pin_w[l*N+source_slot])begin
        check(`LS.selected_forward_w[l][15:8]==8'h11,"pinned query source bytes changed");
        if(`LS.query_take_w[l])query_pinned_takes=query_pinned_takes+1;
      end
    end
    if(source_slot>=0&&`LS.query_held_pin_w[source_slot]&&pin_start<0)begin
      pin_start=cycles;saved_source=`LS.store_q[source_slot];
      $display("PIN cycle=%0d slot=%0d tag=%0d state=%0d source=%h queryvalid=%b take=%b physical=%b reserve=%b",
        cycles,source_slot,source_tag,`LS.state_q[source_slot],saved_source,
        `LS.query_valid_w,`LS.query_take_w,`LS.physical_hold_valid_q,dut.lsu_reserve_fire);
    end
    if(`LS.store_response_fire_w)begin
      check(`LS.mem_store_rsp_error_i&&`LS.mem_store_rsp_token_i==5'(source_slot),"actual store B error identity");
      check(`LS.query_held_pin_w[source_slot],"no resident source reference at B error");
      error_edge=cycles;
    end
    if(error_edge>=0&&cycles>=error_edge&&cycles<=error_edge+12)begin
      $display("EDGE cycle=%0d rel=%0d state=%0d alive=%b pin=%b querypin=%b queryvalid=%b querytake=%b source=%h resident_exception=%b stop=%b birth_stop=%b run=%b recoveryfence=%b birth=%b reserve=%b offer=%h credit=%b want=%b store_done=%b/%b event=%b prepare=%b flush=%b localflush=%b irrevocable=%b",
        cycles,cycles-error_edge,`LS.state_q[source_slot],`LS.alive_q[source_slot],
        `LS.source_pin_w[source_slot],`LS.query_held_pin_w[source_slot],
        `LS.query_valid_w,`LS.query_take_w,`LS.store_q[source_slot],
        dut.head_exception_raw,dut.stop_birth,dut.backend.birth_stop_w,run_i,dut.backend.recovery_fence_q,dut.backend.birth_w,dut.lsu_reserve_fire,
        dut.lsu_reserve_slot,dut.lsu_reserve_ready,dut.lsu_reserve_want,`LS.store_done_valid_o,`LS.store_done_ready_i,
        dut.control.commit.event_valid_q,dut.control.commit.trap_prepare_o,dut.full_flush,
        dut.memory.flush_i,dut.lsu_irrevocable);
      if(`LS.state_q[source_slot]==0&&`LS.source_pin_w[source_slot])free_pin_edges=free_pin_edges+1;
      if(cycles>error_edge&&`LS.source_pin_w[source_slot])begin
        check(`LS.store_q[source_slot]===saved_source,"freed pinned source overwritten before cancellation");
        check(run_i,"test stopped run before resident pin drained");
        check(dut.backend.birth_stop_w || dut.memory.flush_i,
              "freed pinned source lacks architectural admission or cancellation fence");
        check(dut.lsu_reserve_fire==0,"new LSQ birth after known head store fault");
        if(|dut.lsu_reserve_want)attempts=attempts+1;
      end
    end
    if(dut.full_flush&&flush_edge<0)flush_edge=cycles;
    if(dut.memory.flush_i&&local_flush_edge<0)local_flush_edge=cycles;
    if(trap_valid_o&&!trap_seen)begin
      check(!trap_interrupt_o&&trap_cause_o==7&&trap_pc_o==64'h80000008&&
            trap_tval_o==64'h80001001,"precise real store fault");
      check(commits==2&&writes==1,"precise architectural prefix and single external store");
      trap_seen=1;trap_edge=cycles;
    end
  end
  always @(negedge clk_i)begin
    arready_i=!rst_i;awready_i=!rst_i&&!awheld;wready_i=!rst_i&&!wheld;
    if(rst_i)rheld=0;
    if(!rheld)begin
      rvalid_i=0;rdata_i=0;rid_i=0;rresp_i=0;rlast_i=0;
      if(!rst_i)
        for(integer id=1;id>=0;id=id-1)if(busy[id]&&cycles>=bus_release[id])begin
          rvalid_i=1;rid_i=4'(id);
          rdata_i=readmem(bus_addr[id]+64'(bus_beat[id])*8);
          rlast_i=bus_beat[id]==bus_len[id];
        end
    end
    // Wait for actual resident blocked query, then return error normally.
    // Recovery is produced exclusively by the real Commit/Inbox chain.
    if(source_slot>=0&&bpending&&`LS.query_held_pin_w[source_slot]&&
       |(`LS.query_valid_w&~`LS.query_take_w))begin
      if(blocked_cycle<0)blocked_cycle=cycles;
      if(cycles>=blocked_cycle+b_delay)release_b=1;
    end
    bvalid_i=!rst_i&&bpending&&release_b;bid_i=wi;bresp_i=2;
    trace_ready_i=3;
  end
  initial begin
    unused_plusarg=$value$plusargs("b_delay=%d",b_delay);
    rst_i=1;run_i=1;time_i=0;irq_software_i=0;irq_timer_i=0;irq_external_i=0;irq_supervisor_external_i=0;
    dma_invalidate_i=0;wfi_wait_i=0;tensor_cmd_ready_i=0;tensor_terminal_valid_i=0;
    tensor_terminal_tag_i=0;tensor_error_i=0;tensor_error_code_i=0;trace_ready_i=3;
    arready_i=0;awready_i=0;wready_i=0;rvalid_i=0;rdata_i=0;rid_i=0;rresp_i=0;rlast_i=0;
    bvalid_i=0;bid_i=0;bresp_i=0;
    for(integer n=0;n<8192;n=n+1)ram[n]=0;
    for(integer n=0;n<8;n=n+1)ram[4096+n]=8'(64'h8877665544332200>>(n*8));
    put(0,32'h00001097);put(4,addi(2,0,17));
    put(8,32'h002080a3); // SB x2,1(x1), a partial source for young LDs.
    for(integer n=0;n<24;n=n+1)put(12+n*4,ld(3+n%20,1,0));
    put(108,32'h00100073);
    repeat(4)@(negedge clk_i);rst_i=0;
    for(integer n=0;n<1200&&!trap_seen;n=n+1)@(negedge clk_i);
    if(!trap_seen)$display("TIMEOUT slot=%0d state=%0d heldpin=%h qvalid=%b qtake=%b holds=%b reservations=%0d busy=%h bpending=%b release=%b",source_slot,`LS.state_q[source_slot],`LS.query_held_pin_w,`LS.query_valid_w,`LS.query_take_w,`LS.physical_hold_valid_q,reservations,busy,bpending,release_b);
    check(trap_seen,"real fault recovery did not progress");
    repeat(2)@(negedge clk_i);
    run_i=0;
    repeat(6)@(negedge clk_i);
    check(error_edge>=0&&pin_start>=0,"missing resident source reference at B error");
    check(local_flush_edge>error_edge&&flush_edge>=error_edge+2,"real recovery latency not observed");
    check(newreserve_after_error==0&&reuse_after_error==0,"source reused before recovery");
    check(`LS.query_held_pin_w==0&&`LS.alive_q==0,"recovery left source references or live owners");
    check(readmem(64'h80001000)==64'h8877665544332200,"error modified external memory");
    $display("[PASS] tb_r64_store_error_pin_core checks=%0d error=%0d external_b=%0d trap=%0d flush=%0d local_flush=%0d free_pin_edges=%0d attempts=%0d newreserve=%0d reuse=%0d reservations=%0d query_takes=%0d",
      checks,error_edge,external_b,trap_edge,flush_edge,local_flush_edge,free_pin_edges,attempts,newreserve_after_error,reuse_after_error,reservations,query_pinned_takes);
    $finish;
  end
  `undef LS
endmodule
