`timescale 1ns/1ps
`include "R64Dispatch.vh"
// Standalone execution-domain contract fixture: no ROB, Rename or Backend.
// The mock lifecycle owner publishes certified WB/undo; fast leases are local.
module tb_r64_mem_terminal_current #(parameter MEM_TERMINAL_CURRENT=1,
    parameter ALU_TOKEN_BYPASS=1);
  localparam EXPECT_GAP = ALU_TOKEN_BYPASS ? (MEM_TERMINAL_CURRENT ? 1 : 2) : 2;
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
  R64ExecutionDomain #(.DIRECT_MEM_BIND(1),.ALU_TOKEN_BYPASS(ALU_TOKEN_BYPASS),
    .MEM_TERMINAL_CURRENT(MEM_TERMINAL_CURRENT)) dut (
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
  integer checks=0;
  task check;
    input yes;input [511:0] why;
    begin checks=checks+1;if (yes!==1'b1) $fatal(1,"%0s",why);end
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


  integer cycle=0, exec_cycle[0:511], mem_cycle[0:511], gap_cases=0;
  integer current_mem=0, token_mem=0, head_mem=0, issued_pending=0, held=0, dual_mem=0;
  reg [511:0] mem_seen=0, expected_mem=0;
  reg [63:0] expect_base[0:511], expect_data[0:511];
  reg [7:0] expect_func[0:511];
  always @(posedge clk) begin
    cycle=cycle+1;
    if (!rst) begin
      if(mem_fire==3)dual_mem=dual_mem+1;
      for(integer l=0;l<2;l=l+1) begin
        if(dut.issue_fire_w[l] && |dut.issue_pending_w[l*3+:3])
          issued_pending=issued_pending+1;
        if((dut.read_valid_w[l]||dut.read_local_alu_valid_w[l])&&dut.execute_ready_w[l])begin
          check(exec_cycle[dut.read_tag_w[l*T+:T]]<0,"duplicate real Execute acceptance");
          exec_cycle[dut.read_tag_w[l*T+:T]]=cycle;
        end
        if(dut.read_valid_w[l] && dut.read_class_w[l*3+:3]==`R64_C_MEM &&
           !dut.execute_ready_w[l])held=held+1;
        if(mem_fire[l])begin
          check(!mem_seen[mem_tag[l*T+:T]],"duplicate LSQ bind");
          check(expected_mem[mem_tag[l*T+:T]],"unexpected or cancelled LSQ bind");
          check(mem_slot[l*5+:5]==7,"LSQ slot changed between birth and bind");
          check(mem_command[l*`R64_MEM_CMD_W+0+:64]===
                  expect_base[mem_tag[l*T+:T]],"wrong memory address operand");
          check(mem_command[l*`R64_MEM_CMD_W+128+:64]===
                  expect_data[mem_tag[l*T+:T]],"wrong memory data operand");
          check(mem_command[l*`R64_MEM_CMD_W+192+:8]===
                  expect_func[mem_tag[l*T+:T]],"memory function changed");
          mem_seen[mem_tag[l*T+:T]]=1;mem_cycle[mem_tag[l*T+:T]]=cycle;
          check(exec_cycle[mem_tag[l*T+:T]]==cycle,"direct bind and Execute acceptance diverged");
          if(|dut.registers.late_pending_q[l*2+dut.registers.terminal_select_w[l]])begin
            current_mem=current_mem+1;
            if(|dut.alu_token_valid_w)token_mem=token_mem+1;
            if(|dut.alu_bypass_valid_w)head_mem=head_mem+1;
          end
        end
      end
    end
  end
  task reset_case;
    begin
      rst=1;birth=0;inject=0;recovery=0;mem_ready=0;fp_ready=1;result_ready=31;
      step();step();rst=0;
      mem_seen=0;expected_mem=0;
      for(integer n=0;n<512;n=n+1)begin
        exec_cycle[n]=-1;mem_cycle[n]=-1;expect_base[n]=0;expect_data[n]=0;expect_func[n]=0;
      end
    end
  endtask
  task seed_owner;
    reg [U-1:0] v;
    begin v=0;v[`R64_U_CMD]=64'h12345678;send(0,`R64_C_FP,1,0,32,0,0,0,0,v);end
  endtask
  task alu;
    input integer tagid,dst,src;
    input [63:0] arg;
    reg [U-1:0] v;
    begin v=0;v[`R64_U_FUNC]=`R64_F_ADD;v[`R64_U_OP2_ARG]=1;v[`R64_U_ARG]=arg;
      send(9'(tagid),`R64_C_ALU,1,0,6'(dst),6'(src),0,3'b001,0,v);
    end
  endtask
  task mem;
    input integer tagid,base,data;
    input [7:0] fn;
    input fpdata;
    input [63:0] va,vd;
    reg [U-1:0] v;
    begin
      expected_mem[tagid]=1;expect_base[tagid]=va;expect_data[tagid]=vd;expect_func[tagid]=fn;
      v=0;v[`R64_U_FUNC]=fn;v[`R64_U_ARG]=8;
      send(9'(tagid),`R64_C_MEM,0,0,0,6'(base),6'(data),
           data!=0 ? 3'b011:3'b001,fpdata ? 3'b010:3'b000,v);
    end
  endtask
  task await_bind;
    input integer tagid;
    integer n;
    begin n=0;while(!mem_seen[tagid]&&n<100)begin step();n=n+1;end
      check(mem_seen[tagid],"dependent memory did not bind");
    end
  endtask
  task check_gap;
    input integer producer,consumer;
    begin
      $display("MEM_TERMINAL_GAP enabled=%0d token=%0d producer=%0d consumer=%0d cycles=%0d",
        MEM_TERMINAL_CURRENT,ALU_TOKEN_BYPASS,producer,consumer,mem_cycle[consumer]-exec_cycle[producer]);
      check(mem_cycle[consumer]-exec_cycle[producer]==EXPECT_GAP,"real ALU Execute to MEM bind gap");
      gap_cases=gap_cases+1;
    end
  endtask
  function producer_offer;
    input [8:0] tagid;
    begin
      producer_offer=((dut.read_valid_w[0]||dut.read_local_alu_valid_w[0])&&
        dut.execute_ready_w[0]&&dut.read_tag_w[0+:9]==tagid)||
        ((dut.read_valid_w[1]||dut.read_local_alu_valid_w[1])&&
        dut.execute_ready_w[1]&&dut.read_tag_w[9+:9]==tagid);
    end
  endfunction
  integer mode,waited,current_kill=0;
  reg [U-1:0] first_uop,second_uop;
  initial begin
    // Same public IQ promise chain for load base, store base/data, and all
    // memory classes whose integer operands can be finalized by an ALU.
    for(mode=0;mode<6;mode=mode+1)begin
      reset_case();seed_owner();
      write_value(0,1,64'h2000);write_value(0,2,64'h1122);
      write_value(1,3,64'hdeadbeef);
      alu(1,33,32,8);
      case(mode)
        0:mem(2,33,0,8'h03,0,64'h1008,0);
        1:mem(2,33,2,8'h23,0,64'h1008,64'h1122);
        2:mem(2,1,33,8'h23,0,64'h2000,64'h1008);
        3:mem(2,33,2,8'h83,0,64'h1008,64'h1122);
        4:mem(2,33,0,8'h43,0,64'h1008,0);
        5:mem(2,33,3,8'h63,1,64'h1008,64'hdeadbeef);
      endcase
      repeat(4)step();check(exec_cycle[1]<0&&!mem_seen[2],"operand escaped missing producer");
      mem_ready=3;write_value(0,32,64'h1000);await_bind(2);check_gap(1,2);
    end
    // Two independent ALUs supply the two store operands. Both token lanes
    // and both MEM lanes are real simultaneously accepted owners.
    reset_case();seed_owner();
    first_uop=0;first_uop[`R64_U_FUNC]=`R64_F_ADD;
    first_uop[`R64_U_OP2_ARG]=1;first_uop[`R64_U_ARG]=8;
    second_uop=first_uop;second_uop[`R64_U_ARG]=16;
    birth_tag={9'd2,9'd1};birth_class=0;birth_write=3;birth_fp=0;birth_preg={6'd34,6'd33};
    birth_src={6'b0,6'b0,6'd32,6'b0,6'b0,6'd32};birth_used=6'b001001;
    birth_src_fp=0;birth_uop={second_uop,first_uop};birth_slot=0;
    #1;check(credit==3,"dual producer credit");birth=3;step();birth=0;
    mem(3,33,34,8'h23,0,64'h1008,64'h1010);
    mem(4,34,33,8'h23,0,64'h1010,64'h1008);
    repeat(4)step();mem_ready=3;write_value(0,32,64'h1000);await_bind(3);await_bind(4);
    check(exec_cycle[1]==exec_cycle[2],"dual producer Execute was not simultaneous");
    check_gap(1,3);check_gap(2,4);
    // Current token offered while downstream refuses; after the one-cycle
    // source disappears the local captured value must stay stable and unique.
    reset_case();seed_owner();alu(1,33,32,8);mem(2,33,0,8'h03,0,64'h3008,0);
    repeat(4)step();write_value(0,32,64'h3000);repeat(12)step();
    check(!mem_seen[2]&&exec_cycle[2]<0,"MEM ignored direct-bind downstream stall");
    mem_ready=3;await_bind(2);repeat(4)step();
    // Kill the resident MEM and its completed producer while bind is stalled.
    // The local inbox sees this event before ready rises; no cancelled fire.
    reset_case();seed_owner();alu(1,33,32,8);mem(2,33,0,8'h03,0,64'h4008,0);
    repeat(4)step();write_value(0,32,64'h4000);repeat(8)step();
    expected_mem[2]=0;recovery={65'b0,1'b0,1'b1,32'h6};step();recovery=0;
    mem_ready=3;step();repeat(4)step();check(!mem_seen[2],"current kill leaked LSQ bind");
    // Same ROB slots and destination/source preg are reused with a new tag.
    // Block a new seed and confirm stale PRF/head/token cannot discharge it.
    mem_ready=0;first_uop=0;first_uop[`R64_U_CMD]=64'h12345678;
    send(32,`R64_C_FP,1,0,32,0,0,0,0,first_uop);
    alu(33,33,32,8);mem(34,33,0,8'h03,0,64'h5008,0);
    repeat(4)step();check(exec_cycle[33]<0&&!mem_seen[34],"reused source accepted old value");
    mem_ready=3;write_value(0,32,64'h5000);await_bind(34);check_gap(33,34);
    // Deliver current kill on the first certified token cycle, before its
    // consumer has had a local capture edge. Execute must reject the raw RR
    // candidate although the live producer token is numerically ready.
    if(ALU_TOKEN_BYPASS)begin
      reset_case();seed_owner();alu(1,33,32,8);mem(2,33,0,8'h03,0,64'h5808,0);
      repeat(4)step();write_value(0,32,64'h5800);waited=0;
      while(!producer_offer(1)&&waited<30)begin step();waited=waited+1;end
      check(producer_offer(1),"kill-window producer never offered Execute");
      expected_mem[2]=0;recovery={65'b0,1'b0,1'b1,32'h4};step();recovery=0;mem_ready=3;
      #1;check(dut.alu_token_valid_w!=0&&dut.kill_mask_i==4,
                "kill did not overlap first certified producer token");
      check(mem_fire==0,"current certified token bypassed consumer kill");
      if(MEM_TERMINAL_CURRENT)begin
        check(dut.read_valid_w!=0,"current kill case had no raw RR candidate");
        current_kill=current_kill+1;
      end
      step();repeat(5)step();check(!mem_seen[2],"current-killed MEM resurrected");
    end
    // Full flush at held MEM has the same no-effect boundary.
    reset_case();seed_owner();alu(1,33,32,8);mem(2,33,0,8'h03,0,64'h6008,0);
    repeat(4)step();write_value(0,32,64'h6000);repeat(8)step();
    expected_mem[2]=0;recovery={65'b0,1'b1,1'b1,32'hffffffff};step();recovery=0;
    mem_ready=3;step();repeat(4)step();check(!mem_seen[2],"flush leaked LSQ bind");
    check(held>0&&issued_pending>0,"stall/promise coverage was vacuous");
    if(MEM_TERMINAL_CURRENT)check(current_mem>0,"current-certified MEM not accepted");
    if(MEM_TERMINAL_CURRENT&&ALU_TOKEN_BYPASS)check(token_mem>0,"token not used at actual MEM acceptance");
    if(!MEM_TERMINAL_CURRENT)check(current_mem==0,"disabled option changed original MEM acceptance");
    $display("[PASS] tb_r64_mem_terminal_current enabled=%0d token=%0d checks=%0d gaps=%0d current=%0d token_mem=%0d head_mem=%0d pending=%0d held=%0d dual=%0d current_kill=%0d",
      MEM_TERMINAL_CURRENT,ALU_TOKEN_BYPASS,checks,gap_cases,current_mem,token_mem,head_mem,issued_pending,held,dual_mem,current_kill);
    $finish;
  end
endmodule
