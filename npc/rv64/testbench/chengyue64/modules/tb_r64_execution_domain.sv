`timescale 1ns/1ps
`include "R64Dispatch.vh"
// Standalone execution-domain contract fixture: no ROB, Rename or Backend.
// The mock lifecycle owner publishes certified WB/undo; fast leases are local.
module tb_r64_execution_domain;
  localparam U=`R64_UOP_W, R=`R64_RESULT_W, T=9;
  reg clk=0;
  always #5 clk=~clk;
  reg rst=1;
  reg [`R64_RECOVERY_W(32)-1:0] recovery=0;
  reg [1:0] birth=0, birth_write=0, birth_fp=0;
  wire [1:0] credit;
  reg [17:0] birth_tag=0;
  reg [9:0] birth_slot=0;
  reg [2*U-1:0] birth_uop=0;
  reg [5:0] birth_class=0;
  reg [11:0] birth_preg=0;
  reg [35:0] birth_src=0;
  reg [5:0] birth_src_fp=0, birth_used=0;
  reg [1:0] reclaim=0, reclaim_fp=0;
  reg [11:0] reclaim_preg=0;
  reg serial_allow=1;
  reg [8:0] head_tag=0;
  reg [31:0] serial_active=0;
  reg [1:0] mem_ready=0;
  reg fp_ready=0, serial_ready=0;
  wire [1:0] mem_fire;
  wire fp_fire, serial_fire;
  wire [17:0] mem_tag;
  wire [9:0] mem_slot;
  wire [2*`R64_MEM_CMD_W-1:0] mem_command;
  wire [8:0] fp_tag, serial_tag;
  wire [31:0] fp_command;
  wire [191:0] fp_operand;
  wire [`R64_SERIAL_CMD_W-1:0] serial_command;
  wire [4:0] result_valid;
  wire [44:0] result_tag;
  wire [5*R-1:0] result;
  reg [31:0] owner_live=0;
  reg [8:0] owner_tag[0:31];
  reg [5:0] owner_preg[0:31];
  reg owner_fp[0:31];
  reg owner_write[0:31];
  reg inject=0, inject_fp=0;
  reg [5:0] inject_preg=0;
  reg [63:0] inject_data=0;
  reg [1:0] wb_accept, wb_write, wb_fp;
  reg [17:0] wb_tag;
  reg [11:0] wb_preg;
  reg [127:0] wb_data;
  wire [31:0] kill_mask=recovery[31:0]&{32{recovery[32]}};
  integer wcount;
  always @(*) begin
    wb_accept=0;wb_tag=0;wb_write=0;wb_fp=0;wb_preg=0;wb_data=0;wcount=0;
    if (inject) begin
      wb_write=1;wb_fp[0]=inject_fp;wb_preg[0+:6]=inject_preg;wb_data[0+:64]=inject_data;
      for (integer s=0;s<32;s=s+1)
        if(owner_live[s] && owner_write[s] && owner_fp[s]==inject_fp &&
            owner_preg[s]==inject_preg) begin wb_accept=1;wb_tag[0+:T]=owner_tag[s];end
    end else for (integer s=0;s<5;s=s+1)
      if (result_valid[s] && wcount<2 && owner_write[result_tag[s*T+:5]] &&
          owner_live[result_tag[s*T+:5]] && !recovery[33] &&
          owner_tag[result_tag[s*T+:5]]==result_tag[s*T+:T] && !kill_mask[result_tag[s*T+:5]]) begin
        wb_accept[wcount]=1;wb_tag[wcount*T+:T]=result_tag[s*T+:T];
        wb_write[wcount]=1;
        wb_fp[wcount]=owner_fp[result_tag[s*T+:5]];
        wb_preg[wcount*6+:6]=owner_preg[result_tag[s*T+:5]];
        wb_data[wcount*64+:64]=result[s*R+:64];
        wcount=wcount+1;
      end
  end
  integer completed=0, mem_count=0, fp_count=0, serial_count=0, early_count=0;
  reg [63:0] last_result;
  reg [`R64_MEM_CMD_W-1:0] last_mem;
  reg [`R64_SERIAL_CMD_W-1:0] last_serial;
  always @(posedge clk) begin
    if (rst) owner_live<=0;
    else begin
      owner_live<=recovery[33] ? 0 : owner_live & ~kill_mask;
      for(integer l=0;l<2;l=l+1) if(wb_accept[l]) owner_live[wb_tag[l*T+:5]]<=0;
      for (integer l=0;l<2;l=l+1)
        if (birth[l]) begin
          owner_live[birth_tag[l*T+:5]]<=1;
          owner_tag[birth_tag[l*T+:5]]<=birth_tag[l*T+:T];
          owner_preg[birth_tag[l*T+:5]]<=birth_preg[l*6+:6];
          owner_fp[birth_tag[l*T+:5]]<=birth_fp[l];
          owner_write[birth_tag[l*T+:5]]<=birth_write[l];
        end
      // A source may drain its last cancelled result while its local event
      // inbox catches up. Only the independent full-tag lifecycle owner can
      // accept it; cancelled/stale results must never count as completion.
      for (integer l=0;l<2;l=l+1) if (wb_accept[l] && !inject) begin
        completed=completed+1;last_result=wb_data[l*64+:64];
      end
      for (integer l=0;l<2;l=l+1) if (mem_fire[l]) begin
        if (mem_tag[l*T+:T] != owner_tag[mem_tag[l*T+:5]])
          $fatal(1,"memory command lost its owner");
        mem_count=mem_count+1;
        last_mem=mem_command[l*`R64_MEM_CMD_W+:`R64_MEM_CMD_W];
      end
      if (fp_fire) begin
        fp_count=fp_count+1;
        if (fp_command!=32'h12345678) $fatal(1,"FP native command projection");
      end
      if (serial_fire) begin serial_count=serial_count+1;last_serial=serial_command;end
      if (|dut.early_valid_w) early_count=early_count+1;
    end
  end
  R64ExecutionDomain #(.DIRECT_MEM_BIND(1)) dut (
    .batch_apply_i(1'b0),.batch_greclaim_i(64'b0),.batch_freclaim_i(64'b0),

    .resolved_value_valid_i(2'b0), .resolved_value_tag_i(18'b0), .resolved_value_data_i(128'b0),
    .clk(clk),.rst(rst),.recovery_i(recovery),.serial_allow_i(serial_allow),
    .head_slot_i(head_tag[4:0]),.head_tag_i(head_tag),
    .barrier_slot_i(head_tag[4:0]),.barrier_valid_i(1'b0),
    .serial_active_i(serial_active),.serial_release_i(32'b0),
    .birth_i(birth),.birth_rd_write_i(birth_write),.birth_rd_fp_i(birth_fp),
    .birth_ready_o(credit),.birth_tag_i(birth_tag),.birth_mem_slot_i(birth_slot),
    .birth_uop_i(birth_uop),.birth_class_i(birth_class),.birth_preg_i(birth_preg),
    .birth_src_preg_i(birth_src),.birth_src_fp_i(birth_src_fp),.birth_src_used_i(birth_used),
    .load_capture_i(2'b0),.load_capture_tag_i(18'b0),
    .wb_accept_i(wb_accept),.wb_tag_i(wb_tag),
    .wb_write_i(wb_write),.wb_fp_i(wb_fp),.wb_preg_i(wb_preg),.wb_data_i(wb_data),
    .reclaim_write_i(reclaim),.reclaim_fp_i(reclaim_fp),.reclaim_preg_i(reclaim_preg),
    .result_valid_o(result_valid),.result_ready_i(5'b11111),
    .result_tag_o(result_tag),.result_o(result),
    .lsu_ready_i(mem_ready),.lsu_fire_o(mem_fire),.lsu_tag_o(mem_tag),
    .lsu_slot_o(mem_slot),.lsu_command_o(mem_command),
    .fp_ready_i(fp_ready),.fp_fire_o(fp_fire),.fp_tag_o(fp_tag),
    .fp_command_o(fp_command),.fp_operand_o(fp_operand),
    .serial_ready_i(serial_ready),.serial_fire_o(serial_fire),.serial_tag_o(serial_tag),
    .serial_command_o(serial_command)
  );
  task step;
    begin @(posedge clk);#1;@(negedge clk);end
  endtask
  task check;
    input yes;input [511:0] why;
    begin if (yes!==1'b1) $fatal(1,"%0s",why);end
  endtask
  task write_value;
    input fp;input [5:0] preg;input [63:0] value;
    begin inject=1;inject_fp=fp;inject_preg=preg;inject_data=value;step();inject=0;end
  endtask
  task send;
    input [8:0] tag;
    input [2:0] cls;
    input wr, fp;
    input [5:0] preg, src0, src1;
    input [2:0] used, source_fp;
    input [U-1:0] uop;
    integer waited;
    begin
      birth_tag={9'b0,tag};birth_class={3'b0,cls};birth_write={1'b0,wr};
      birth_fp={1'b0,fp};birth_preg={6'b0,preg};
      birth_src={18'b0,6'b0,src1,src0};birth_used={3'b0,used};birth_src_fp={3'b0,source_fp};
      birth_uop={{U{1'b0}},uop};birth_slot=10'd7;waited=0;
      #1;
      while (!credit[0] && waited<20) begin step();waited=waited+1;end
      check(credit[0],"execution domain did not return birth credit");
      birth=1;step();birth=0;
    end
  endtask
  task await_mem;
    input integer expected;
    integer waited;
    begin
      waited=0;
      while (mem_count<expected && waited<40) begin step();waited=waited+1;end
      check(mem_count==expected,"native memory command did not progress");
    end
  endtask
  reg [U-1:0] uop;
  integer waited;
  initial begin
    step();rst=0;
    write_value(0,1,64'h1000);
    write_value(0,2,64'habcd);
    write_value(1,0,64'hfedcba9876543210);
    // External FP destination makes a dependent ALU wait for authorized WB.
    uop=0;uop[`R64_U_CMD]=64'h12345678;
    send(0,`R64_C_FP,1,0,32,0,0,0,0,uop);
    uop=0;uop[`R64_U_FUNC]=`R64_F_ADD;
    send(1,`R64_C_ALU,1,0,33,32,1,3'b011,0,uop);
    repeat(10) step();
    check(completed==0 && fp_count==0,"busy operand or external backpressure was bypassed");
    fp_ready=1;waited=0;
    while(fp_count<1 && waited<30) begin step();waited=waited+1;end
    check(fp_count==1 && completed==0,"FP acceptance was mistaken for value readiness");
    write_value(0,32,64'd42);
    waited=0;
    while(completed<1 && waited<40) begin step();waited=waited+1;end
    check(completed==1 && last_result==64'h102a,"authorized WB failed to wake and supply ALU");
    check(early_count!=0,"fast-value authorization was not exercised");
    // A native FP-store command preserves GPR base and FPR f0 data.
    uop=0;uop[`R64_U_ARG]=-64'd8;uop[`R64_U_FUNC]=8'h63;uop[155+:5]=5'h15;
    send(2,`R64_C_MEM,0,0,0,1,0,3'b011,3'b010,uop);
    repeat(8) step();check(mem_count==0,"memory ignored command credit");
    mem_ready=3;await_mem(1);
    check(last_mem[`R64_MEM_BASE]==64'h1000 && last_mem[`R64_MEM_OFFSET]==-64'd8 &&
          last_mem[`R64_MEM_DATA]==64'hfedcba9876543210 &&
          last_mem[`R64_MEM_FUNC]==8'h63 && last_mem[`R64_MEM_AMO]==5'h15,
          "native memory record lost a consumed field");
    // Serial service receives only its PC/command/operand/ASID/kind/pair ABI.
    head_tag=3;serial_ready=1;uop=0;
    uop[`R64_U_PC]=64'h80010000;uop[`R64_U_CMD]=64'h123456789abcdef0;
    uop[`R64_U_LEN]=8;uop[`R64_U_FUNC]=`R64_K_TENSOR;
    send(3,`R64_C_SERIAL,0,0,0,1,2,3'b011,0,uop);
    waited=0;while(serial_count<1 && waited<40) begin step();waited=waited+1;end
    check(serial_count==1 && last_serial[`R64_SERIAL_PC]==64'h80010000 &&
          last_serial[`R64_SERIAL_INST]==64'h123456789abcdef0 &&
          last_serial[`R64_SERIAL_OPERAND]==64'h1000 &&
          last_serial[`R64_SERIAL_ASID]==16'habcd &&
          last_serial[`R64_SERIAL_KIND]==`R64_K_TENSOR && last_serial[`R64_SERIAL_PAIR],
          "native Serial record lost a consumed field");
    // Kill cancels a held producer; undo reclaims readiness independently of maps.
    head_tag=0;fp_ready=0;uop=0;uop[`R64_U_CMD]=64'h12345678;
    send(4,`R64_C_FP,1,1,0,0,0,0,0,uop);
    repeat(8) step();recovery={65'b0,1'b0,1'b1,32'h10};#1;
    check(!dut.recovery_pending_w && dut.owners.live_q[4],
          "source event bypassed the registered Execution boundary");
    reclaim=1;reclaim_fp=1;reclaim_preg=0;step();recovery=0;reclaim=0;
    check(dut.recovery_pending_w && dut.owners.live_q[4],
          "Execution failed to retain event until local consumption edge");
    fp_ready=1;repeat(4) step();check(!dut.owners.live_q[4],
          "local recovery failed to cancel its value lease");check(fp_count==1,"cancelled FP owner fired after kill");
    uop=0;uop[`R64_U_FUNC]=8'h63;
    send(5,`R64_C_MEM,0,0,0,1,0,3'b011,3'b010,uop);
    await_mem(2);
    check(last_mem[`R64_MEM_DATA]==64'hfedcba9876543210,
          "reclaim did not release FPR zero readiness");
    // Full flush releases execution readiness and every cancellable owner.
    fp_ready=0;uop=0;uop[`R64_U_CMD]=64'h12345678;
    send(6,`R64_C_FP,1,1,0,0,0,0,0,uop);
    repeat(5) step();recovery={65'b0,1'b1,1'b1,owner_live};step();recovery=0;step();
    fp_ready=1;uop=0;uop[`R64_U_FUNC]=8'h63;
    send(7,`R64_C_MEM,0,0,0,1,0,3'b011,3'b010,uop);
    await_mem(3);
    check(fp_count==1 && last_mem[`R64_MEM_DATA]==64'hfedcba9876543210,
          "flush retained a stale producer or busy FPR zero");
    $display("[PASS] tb_r64_execution_domain isolated birth/WB/reclaim/kill/flush native MEM/FP/Serial fast-value");
    $finish;
  end
endmodule
