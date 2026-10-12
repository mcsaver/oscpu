`timescale 1ns/1ps
`include "R64Dispatch.vh"
// Standalone execution-domain contract fixture: no ROB, Rename or Backend.
// The mock lifecycle owner publishes certified WB/undo; fast leases are local.
module tb_r64_alu_token_bypass #(parameter ALU_TOKEN_BYPASS=1,
    parameter EXPECT_GAP=ALU_TOKEN_BYPASS ? 1 : 2);
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
  reg [4:0] result_ready=31;
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
      if (result_valid[s] && result_ready[s] && wcount<2 && owner_write[result_tag[s*T+:5]] &&
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
  R64ExecutionDomain #(.DIRECT_MEM_BIND(1),.ALU_TOKEN_BYPASS(ALU_TOKEN_BYPASS)) dut (
    .batch_apply_i(1'b0),.batch_greclaim_i(64'b0),.batch_freclaim_i(64'b0),

    .resolved_value_valid_i(2'b0),.resolved_value_tag_i(18'b0),.resolved_value_data_i(128'b0),
    .load_capture_i(2'b0),.load_capture_tag_i(18'b0),
    .clk(clk),.rst(rst),.recovery_i(recovery),.serial_allow_i(serial_allow),
    .head_slot_i(head_tag[4:0]),.head_tag_i(head_tag),
    .barrier_slot_i(head_tag[4:0]),.barrier_valid_i(1'b0),
    .serial_active_i(serial_active),.serial_release_i(32'b0),
    .birth_i(birth),.birth_rd_write_i(birth_write),.birth_rd_fp_i(birth_fp),
    .birth_ready_o(credit),.birth_tag_i(birth_tag),.birth_mem_slot_i(birth_slot),
    .birth_uop_i(birth_uop),.birth_class_i(birth_class),.birth_preg_i(birth_preg),
    .birth_src_preg_i(birth_src),.birth_src_fp_i(birth_src_fp),.birth_src_used_i(birth_used),
    .wb_accept_i(wb_accept),.wb_tag_i(wb_tag),
    .wb_write_i(wb_write),.wb_fp_i(wb_fp),.wb_preg_i(wb_preg),.wb_data_i(wb_data),
    .reclaim_write_i(reclaim),.reclaim_fp_i(reclaim_fp),.reclaim_preg_i(reclaim_preg),
    .result_valid_o(result_valid),.result_ready_i(result_ready),
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

  task send_pair;
    input [8:0] first_tag;
    input [5:0] dst0, dst1, src0, src1;
    input [U-1:0] uop0, uop1;
    integer pair_wait;
    begin
      birth_tag={first_tag+9'd1,first_tag};birth_class=0;
      birth_write=3;birth_fp=0;birth_preg={dst1,dst0};
      birth_src={6'b0,6'b0,src1,6'b0,6'b0,src0};birth_used=6'b001001;
      birth_src_fp=0;birth_uop={uop1,uop0};birth_slot=0;pair_wait=0;
      #1;
      while(credit!=3 && pair_wait<40)begin step();pair_wait=pair_wait+1;end
      check(credit==3,"dual-chain birth credit absent");
      birth=3;step();birth=0;
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
  reg [U-1:0] uop, uop_second;
  integer waited, dual_chain_gaps=0;

  wire [5:0] observed_pending;
  wire [1:0] observed_promise;
  generate
    if(EXPECT_GAP<=2) begin
      assign observed_pending=dut.issue_pending_w;
      assign observed_promise=dut.issue.promise_valid_w;
    end else begin
      assign observed_pending=0;
      assign observed_promise=0;
    end
  endgenerate
  integer cycle=0, gap_count=0, promise_count=0, accepted_lane0=0, accepted_lane1=0;
  integer token_accepts=0, head_token_overlap=0, certified_tokens=0;
  always @(posedge clk) if (!rst) begin
    for (integer l=0;l<2;l=l+1) begin
      if (dut.alu_token_valid_w[l]) begin
        certified_tokens=certified_tokens+1;
        if (dut.alu_token_tag_w[l*9+:9]==19 || dut.alu_token_tag_w[l*9+:9]==20)
          $fatal(1,"x0/fault token acquired a value certificate");
      end
      if (dut.raw_alu_token_resident_w[l] && dut.raw_alu_bypass_valid_w[l] &&
          dut.alu_token_tag_w[l*9+:9]!=result_tag[l*9+:9])
        head_token_overlap=head_token_overlap+1;
      if ((dut.read_valid_w[l] || dut.read_local_alu_valid_w[l]) &&
          dut.execute_ready_w[l])
        for (integer s=0;s<2;s=s+1)
          if (dut.registers.late_pending_q[l*2+dut.registers.terminal_select_w[l]][s] &&
              dut.alu_token_valid_w!=0)
            token_accepts=token_accepts+1;
    end
  end
  integer exec_cycle[0:511], iq_cycle[0:511], birth_cycle[0:511];
  integer late_birth_count=0, token_init_count=0, held_birth_count=0, late_issue_count=0;
  wire [1:0] token_wake = {dut.execute.gen_alu[1].lane.early_token_w,
                           dut.execute.gen_alu[0].lane.early_token_w};
  function execute_offer(input [8:0] tag);
    execute_offer=((dut.read_valid_w[0] || dut.read_local_alu_valid_w[0])&&dut.execute_ready_w[0]&&dut.read_tag_w[0+:9]==tag)||
                  ((dut.read_valid_w[1] || dut.read_local_alu_valid_w[1])&&dut.execute_ready_w[1]&&dut.read_tag_w[9+:9]==tag);
  endfunction
  function held_value(input [8:0] tag);
    held_value=(dut.alu_bypass_valid_w[0]&&result_tag[0+:9]==tag)||
               (dut.alu_bypass_valid_w[1]&&result_tag[9+:9]==tag);
  endfunction
  function early_owner(input [8:0] tag);
    early_owner=(dut.early_valid_w[0]&&dut.early_tag_w[0+:9]==tag)||
                (dut.early_valid_w[1]&&dut.early_tag_w[9+:9]==tag);
  endfunction
  reg [511:0] done=0;
  reg [63:0] expected[0:511];
  always @(posedge clk) begin
    cycle=cycle+1;
    if (!rst) begin
      for (integer l=0;l<2;l=l+1) begin
        if (birth[l]) begin
          birth_cycle[birth_tag[l*9+:9]]=cycle;
          if(birth_tag[l*9+:9]==23 || birth_tag[l*9+:9]==25) begin
            check(iq_cycle[birth_tag[l*9+:9]-1]>=0 &&
                  iq_cycle[birth_tag[l*9+:9]-1]<cycle,"late consumer did not miss issue promise");
            late_birth_count=late_birth_count+1;
          end
          if(birth_tag[l*9+:9]==25) begin
            check(held_value(24)&&!early_owner(24),"late held-head birth did not miss wake pulse");
            held_birth_count=held_birth_count+1;
          end
        end
        if(dut.issue_fire_w[l]) begin
          iq_cycle[dut.issue_tag_w[l*9+:9]]=cycle;
          if(dut.issue_tag_w[l*9+:9]==23 || dut.issue_tag_w[l*9+:9]==25) begin
            check(observed_pending[l*3+:3]==0,"late consumer unexpectedly captured issue promise");
            late_issue_count=late_issue_count+1;
          end
        end
        if (dut.issue_fire_w[l] && |observed_pending[l*3+:3]) promise_count=promise_count+1;
        if (dut.issue_fire_w[l] && (dut.issue_tag_w[l*9+:9]==19 || dut.issue_tag_w[l*9+:9]==20) &&
            observed_promise[l]) $fatal(1,"x0/fault advertised an issue promise");
        if ((dut.read_valid_w[l] || dut.read_local_alu_valid_w[l]) && dut.execute_ready_w[l]) begin
          exec_cycle[dut.read_tag_w[l*9+:9]]=cycle;
          if (l==0) accepted_lane0=accepted_lane0+1; else accepted_lane1=accepted_lane1+1;
        end
        if (wb_accept[l] && !inject) begin
          if (done[wb_tag[l*9+:9]]) $fatal(1,"duplicate ALU completion");
          if (wb_data[l*64+:64] !== expected[wb_tag[l*9+:9]])
            $fatal(1,"bad ALU result tag=%d got=%h expected=%h",wb_tag[l*9+:9],
                wb_data[l*64+:64],expected[wb_tag[l*9+:9]]);
          done[wb_tag[l*9+:9]]=1;
        end
      end
      for(integer n=0;n<16;n=n+1)
        if(dut.issue.valid_q[n] && dut.issue.tag_q[n]==23 &&
           (dut.issue.init0_w[n]||dut.issue.init1_w[n])) begin
          check((token_wake[0]&&dut.early_valid_w[0]&&dut.early_tag_w[0+:9]==22)||
                (token_wake[1]&&dut.early_valid_w[1]&&dut.early_tag_w[9+:9]==22),
                "DEFER_READY initialization did not overlap authorized token wake");
          token_init_count=token_init_count+1;
        end
    end
  end
  task chain;
    input integer first, length, source_preg, first_dest;
    begin
      for (integer n=0;n<length;n=n+1) begin
        uop=0;uop[`R64_U_FUNC]=`R64_F_ADD;uop[`R64_U_OP2_ARG]=1;uop[`R64_U_ARG]=1;
        expected[first+n]=64'(11+n);
        send(9'(first+n),`R64_C_ALU,1,0,6'(first_dest+n),
             6'(n==0 ? source_preg : first_dest+n-1),0,3'b001,0,uop);
      end
    end
  endtask
  initial begin
    for(integer n=0;n<512;n=n+1) begin
      exec_cycle[n]=-1;iq_cycle[n]=-1;birth_cycle[n]=-1;expected[n]=0;
    end
    step();rst=0;
    // All dependent instructions are born before the root external value.
    // This exercises actual IQ promise publication and six real RR holders.
    uop=0;uop[`R64_U_CMD]=64'h12345678;
    send(0,`R64_C_FP,1,0,32,0,0,0,0,uop);
    chain(1,8,32,33);
    repeat(5) step();
    check(completed==0,"dependent ALU escaped without seed value");
    fp_ready=1;repeat(4) step();
    write_value(0,32,10);
    waited=0;
    while(!done[8] && waited<150) begin step();waited=waited+1;end
    check(done[8],"promise dependency chain deadlocked");
    for(integer n=2;n<=8;n=n+1) begin
      $display("ALU_RAW_INTERVAL predecessor=%0d consumer=%0d cycles=%0d",n-1,n,
               exec_cycle[n]-exec_cycle[n-1]);
      check(exec_cycle[n]-exec_cycle[n-1]==EXPECT_GAP,"RAW execution interval");
      gap_count=gap_count+1;
    end
    if(EXPECT_GAP<=2) check(promise_count>=7,"new promise path not exercised");

    // WB denied: a completed producer behind another ALU head cannot
    // advertise its value; promised dependents wait locally without consuming FU.
    result_ready=0;
    uop=0;uop[`R64_U_FUNC]=`R64_F_ADD;uop[`R64_U_OP2_ARG]=1;uop[`R64_U_ARG]=10;
    expected[10]=10;send(10,`R64_C_ALU,1,0,45,0,0,3'b001,0,uop);
    expected[11]=11;uop[`R64_U_ARG]=1;send(11,`R64_C_ALU,1,0,46,45,0,3'b001,0,uop);
    expected[12]=12;send(12,`R64_C_ALU,1,0,47,46,0,3'b001,0,uop);
    repeat(25) step();
    check(!done[10]&&!done[11]&&!done[12],"WB credit ignored");
    result_ready=31;waited=0;
    while(!done[12] && waited<100) begin step();waited=waited+1;end
    check(done[12],"congested ALU head created circular wait");

    // Register shift B is a late ALU source, so predecoded shift amount must
    // follow the same final operand rather than the old PRF snapshot.
    uop=0;uop[`R64_U_CMD]=64'h12345678;
    send(13,`R64_C_FP,1,0,48,0,0,0,0,uop);fp_ready=0;
    uop=0;uop[`R64_U_FUNC]=`R64_F_ADD;uop[`R64_U_OP2_ARG]=1;uop[`R64_U_ARG]=1;
    expected[14]=4;send(14,`R64_C_ALU,1,0,49,48,0,3'b001,0,uop);
    write_value(0,1,5);
    uop=0;uop[`R64_U_FUNC]=`R64_F_SLL;
    expected[15]=80;send(15,`R64_C_ALU,1,0,50,1,49,3'b011,0,uop);
    fp_ready=1;repeat(4) step();write_value(0,48,3);
    waited=0;
    while(!done[15] && waited<100) begin step();waited=waited+1;end
    check(done[15],"late shift amount failed");

    // Flush promised consumers while their true data is still queued.
    result_ready=0;
    uop=0;uop[`R64_U_FUNC]=`R64_F_ADD;uop[`R64_U_OP2_ARG]=1;uop[`R64_U_ARG]=20;
    expected[16]=20;send(16,`R64_C_ALU,1,0,51,0,0,3'b001,0,uop);
    uop[`R64_U_ARG]=1;expected[17]=21;send(17,`R64_C_ALU,1,0,52,51,0,3'b001,0,uop);
    expected[18]=22;send(18,`R64_C_ALU,1,0,53,52,0,3'b001,0,uop);
    repeat(12) step();
    recovery={65'b0,1'b1,1'b1,owner_live};step();recovery=0;step();step();
    result_ready=31;repeat(6) step();
    check(!done[16]&&!done[17]&&!done[18],"flush leaked promised generation");
    // Reuse the same physical numbers and ROB slots with a new generation.
    uop=0;uop[`R64_U_FUNC]=`R64_F_ADD;uop[`R64_U_OP2_ARG]=1;uop[`R64_U_ARG]=100;
    expected[48]=100;send(48,`R64_C_ALU,1,0,51,0,0,3'b001,0,uop);
    uop[`R64_U_ARG]=1;expected[49]=101;send(49,`R64_C_ALU,1,0,52,51,0,3'b001,0,uop);
    expected[50]=102;send(50,`R64_C_ALU,1,0,53,52,0,3'b001,0,uop);
    waited=0;
    while(!done[50] && waited<100) begin step();waited=waited+1;end
    check(done[50],"new generation used old physical value");
    // x0 and faulting ALUs are never speculative value producers.
    result_ready=0;
    uop=0;uop[`R64_U_FUNC]=`R64_F_ADD;uop[`R64_U_OP2_ARG]=1;uop[`R64_U_ARG]=7;
    send(19,`R64_C_ALU,0,0,0,0,0,3'b001,0,uop);
    uop[`R64_U_EXCEPTION]=1;
    send(20,`R64_C_ALU,1,0,54,0,0,3'b001,0,uop);
    uop[`R64_U_EXCEPTION]=0;uop[`R64_U_ARG]=1;
    send(21,`R64_C_ALU,1,0,55,54,0,3'b001,0,uop);
    repeat(15) step();
    check(exec_cycle[19]>=0&&exec_cycle[20]>=0&&exec_cycle[21]<0,
          "x0/fault producer exclusion not exercised");
    recovery={65'b0,1'b1,1'b1,owner_live};step();recovery=0;step();step();
    // Miss the producer's IQ promise deliberately. Consumer birth occurs on
    // the naturally offered Execute handshake; its deferred readiness query
    // must observe the next registered token wake while WB remains blocked.
    result_ready=0;
    uop=0;uop[`R64_U_FUNC]=`R64_F_ADD;uop[`R64_U_OP2_ARG]=1;uop[`R64_U_ARG]=30;
    expected[22]=30;send(22,`R64_C_ALU,1,0,56,0,0,3'b001,0,uop);
    waited=0;
    while(!execute_offer(22)&&waited<40)begin step();waited=waited+1;end
    check(execute_offer(22),"late-birth producer never offered Execute handshake");
    uop[`R64_U_ARG]=1;expected[23]=31;
    send(23,`R64_C_ALU,1,0,57,56,0,3'b001,0,uop);
    check(exec_cycle[22]==birth_cycle[23],"late birth missed producer acceptance boundary");
    waited=0;
    while(exec_cycle[23]<0&&waited<40)begin step();waited=waited+1;end
    check(exec_cycle[23]>=0&&token_init_count==1&&!done[22]&&!done[23],
          "token/init late consumer stalled or bypassed blocked WB");
    result_ready=31;waited=0;
    while(!done[23]&&waited<40)begin step();waited=waited+1;end
    check(done[22]&&done[23],"late token/init pair failed to complete");

    // Birth after both the issue promise and token/head wake pulse have passed.
    // The live authorized result head, held under WB denial, is still a value.
    result_ready=0;uop[`R64_U_ARG]=40;expected[24]=40;
    send(24,`R64_C_ALU,1,0,58,0,0,3'b001,0,uop);
    waited=0;
    while(!held_value(24)&&waited<40)begin step();waited=waited+1;end
    check(held_value(24),"held-head late-birth producer failed to finish");
    repeat(3)step();
    check(held_value(24)&&!early_owner(24)&&!done[24],"held-head wake pulse did not expire");
    uop[`R64_U_ARG]=1;expected[25]=41;
    send(25,`R64_C_ALU,1,0,59,58,0,3'b001,0,uop);
    waited=0;
    while(exec_cycle[25]<0&&waited<40)begin step();waited=waited+1;end
    check(exec_cycle[25]>=0&&!done[24]&&!done[25],"held-head late consumer waited for canonical WB");
    result_ready=31;waited=0;
    while(!done[25]&&waited<40)begin step();waited=waited+1;end
    check(done[24]&&done[25]&&late_birth_count==2&&held_birth_count==1&&late_issue_count==2,
          "late-birth coverage or exactly-once progress");

    // Two independently valued dependent chains are all born before the seed.
    // Both IQ/Execute lanes must sustain the measured dependency interval.
    uop=0;uop[`R64_U_CMD]=64'h12345678;
    send(64,`R64_C_FP,1,0,32,0,0,0,0,uop);
    for(integer n=0;n<8;n=n+1)begin
      uop=0;uop[`R64_U_FUNC]=`R64_F_ADD;
      uop[`R64_U_OP2_ARG]=1;uop[`R64_U_ARG]=1;
      uop_second=uop;uop_second[`R64_U_ARG]=2;
      expected[65+2*n]=64'(51+n);expected[66+2*n]=64'(52+2*n);
      send_pair(9'(65+2*n),6'(33+2*n),6'(34+2*n),
                6'(n==0 ? 32 : 31+2*n),6'(n==0 ? 32 : 32+2*n),uop,uop_second);
    end
    repeat(4)step();
    check(exec_cycle[65]<0 && exec_cycle[66]<0,"dual chains escaped seed wait");
    write_value(0,32,50);waited=0;
    while((!done[79] || !done[80]) && waited<120)begin step();waited=waited+1;end
    check(done[79]&&done[80],"dual dependent chains deadlocked");
    for(integer n=67;n<=80;n=n+1)begin
      check(exec_cycle[n]-exec_cycle[n-2]==EXPECT_GAP,"dual chain real Execute interval");
      dual_chain_gaps=dual_chain_gaps+1;
    end
    check(accepted_lane0>0 && accepted_lane1>0,"dual Execute lane coverage absent");
    $display("ALU_TOKEN_DUAL_CHAIN intervals=%0d gap=%0d lanes=%0d/%0d",
             dual_chain_gaps,EXPECT_GAP,accepted_lane0,accepted_lane1);
    // A MEM consumer has the same IQ scheduling promise, but shared acceptance
    // still follows registered local numeric readiness, one edge after fast ALU.
    uop=0;uop[`R64_U_CMD]=64'h12345678;
    send(96,`R64_C_FP,1,0,39,0,0,0,0,uop);
    uop=0;uop[`R64_U_FUNC]=`R64_F_ADD;
    uop[`R64_U_OP2_ARG]=1;uop[`R64_U_ARG]=1;
    expected[97]=64'h9001;
    send(97,`R64_C_ALU,1,0,40,39,0,3'b001,0,uop);
    uop=0;uop[`R64_U_FUNC]=8'h03;
    send(98,`R64_C_MEM,0,0,0,40,0,3'b001,0,uop);
    mem_ready=3;repeat(4)step();write_value(0,39,64'h9000);
    await_mem(1);
    check(exec_cycle[98]-exec_cycle[97]==EXPECT_GAP+1,
          "shared MEM acceptance bypassed registered operand readiness");
    check(last_mem[`R64_MEM_BASE]==64'h9001,
          "shared MEM consumed the wrong token value");
    $display("ALU_TOKEN_SHARED_MEM gap=%0d",exec_cycle[98]-exec_cycle[97]);
    check(head_token_overlap>0,"old head/new token overlap case was vacuous");
    if(ALU_TOKEN_BYPASS) check(token_accepts>0 && certified_tokens>0,
                             "real token-dependent Execute acceptance absent");
    $display("ALU_TOKEN_EXECUTE enabled=%0d token_accepts=%0d certified=%0d head_token_overlap=%0d",
             ALU_TOKEN_BYPASS,token_accepts,certified_tokens,head_token_overlap);
    $display("ALU_LATE_BIRTH missed_promise=%0d token_init_overlap=%0d held_head_birth=%0d no_promise_issues=%0d",
             late_birth_count,token_init_count,held_birth_count,late_issue_count);
    $display("[PASS] tb_r64_alu_token_bypass gap=%0d intervals=%0d promises=%0d lanes=%0d/%0d late_birth=%0d",
             EXPECT_GAP,gap_count,promise_count,accepted_lane0,accepted_lane1,late_birth_count);
    $finish;
  end
endmodule
