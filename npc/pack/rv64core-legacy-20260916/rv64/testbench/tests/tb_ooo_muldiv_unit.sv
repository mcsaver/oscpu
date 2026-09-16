`include "define.v"

module tb_ooo_muldiv_unit;
  `include "tb_common.svh"
  localparam PW=6;
  localparam RW=4;
  localparam GW=`OOO_PRODUCER_GEN_W;
  localparam IW=RW+GW;
  localparam IDS=1<<IW;
  reg clk=0, rst=1, flush=0, kill_valid=0;
  reg [RW-1:0] kill_idx=0, head_idx=0;
  reg req_valid=0, word_op=0, resp_ready=1;
  reg [IW-1:0] req_pid=0;
  reg [PW-1:0] req_dest=0;
  reg [31:0] inst=0;
  reg [63:0] lhs=0, rhs=0;
  wire req_ready, resp_valid, owner_valid;
  wire [IW-1:0] resp_pid, owner_pid;
  wire [RW-1:0] resp_rob;
  wire [PW-1:0] resp_dest;
  wire [63:0] result;
  wire [IDS-1:0] live_mask;
  reg [IDS-1:0] expected_valid;
  reg [63:0] expected_data [0:IDS-1];
  reg [PW-1:0] expected_dest [0:IDS-1];
  integer accepted=0, completed=0, cycles=0;
  integer i,j,k,n,wait_cycles;
  reg [63:0] random_state=64'h13b6_8355_10ac_7991;
  reg [63:0] values [0:9];
  reg [63:0] held_data;
  reg [IW-1:0] held_pid;
  reg [RW-1:0] check_age, cut_age;
  reg [IW-1:0] next_id;

  OooMulDivUnit #(.PHY_REG_ADDR_W(PW),.ROB_INDEX_W(RW),
      .PRODUCER_GEN_W(GW),.PRODUCER_ID_W(IW)) dut (
    .clk(clk),.rst(rst),.flush_i(flush),.kill_valid_i(kill_valid),
    .kill_rob_idx_i(kill_idx),.rob_head_idx_i(head_idx),
    .req_valid_i(req_valid),.req_ready_o(req_ready),.req_producer_id_i(req_pid),
    .req_pdest_i(req_dest),.req_inst_i(inst),.req_src1_i(lhs),.req_src2_i(rhs),
    .req_word_i(word_op),.resp_valid_o(resp_valid),.resp_ready_i(resp_ready),
    .resp_rob_idx_o(resp_rob),.resp_producer_id_o(resp_pid),.resp_pdest_o(resp_dest),
    .resp_data_o(result),.owner_valid_o(owner_valid),.owner_producer_id_o(owner_pid),
    .owner_live_mask_o(live_mask)
  );

  function [63:0] reference;
    input [2:0] op;
    input word_mode;
    input [63:0] a,b;
    reg [63:0] aa,bb,raw;
    reg signed [64:0] sa,sb;
    reg signed [129:0] product;
    reg signed [63:0] signed_a,signed_b;
    begin
      aa=word_mode ? {{32{!op[0] && a[31]}},a[31:0]} : a;
      bb=word_mode ? {{32{!op[0] && b[31]}},b[31:0]} : b;
      if (!op[2]) begin
        aa=word_mode ? {{32{a[31]}},a[31:0]} : a;
        bb=word_mode ? {{32{b[31]}},b[31:0]} : b;
        sa=$signed({((op==1 || op==2) && aa[63]),aa});
        sb=$signed({((op==1) && bb[63]),bb});
        product=sa*sb;
        raw=(op==0) ? product[63:0] : product[127:64];
      end else begin
        signed_a=$signed(aa); signed_b=$signed(bb);
        if (bb==0) raw=op[1] ? aa : 64'hffff_ffff_ffff_ffff;
        else if (!op[0] && aa==64'h8000_0000_0000_0000 && bb==64'hffff_ffff_ffff_ffff)
          raw=op[1] ? 64'd0 : aa;
        else if (!op[0]) raw=op[1] ? signed_a%signed_b : signed_a/signed_b;
        else raw=op[1] ? aa%bb : aa/bb;
      end
      reference=word_mode ? {{32{raw[31]}},raw[31:0]} : raw;
    end
  endfunction

  task tick;
    integer idx;
    begin
      #1;
      if (rst || flush) expected_valid={IDS{1'b0}};
      else begin
        if (kill_valid) begin
          cut_age=kill_idx-head_idx;
          for (idx=0; idx<IDS; idx=idx+1) begin
            check_age=idx[RW-1:0]-head_idx;
            if (check_age>cut_age) expected_valid[idx]=0;
          end
        end
        if (resp_valid && resp_ready) begin
          if (!expected_valid[resp_pid] || result !== expected_data[resp_pid] ||
              resp_dest !== expected_dest[resp_pid] || resp_rob !== resp_pid[RW-1:0])
            $fatal(1,"MulDiv completion mismatch cycle=%0d pid=%h result=%h expected=%h",
                cycles,resp_pid,result,expected_data[resp_pid]);
          expected_valid[resp_pid]=0;
          completed=completed+1;
        end
        if (req_valid && req_ready) begin
          if (expected_valid[req_pid] || live_mask[req_pid])
            $fatal(1,"test attempted live ProducerId reuse");
          expected_valid[req_pid]=1;
          expected_data[req_pid]=reference(inst[14:12],word_op,lhs,rhs);
          expected_dest[req_pid]=req_dest;
          accepted=accepted+1;
        end
      end
      clk=1; #1; clk=0; #1;
      if ((expected_valid & ~live_mask) != 0)
        $fatal(1,"MulDiv lost a live producer");
      cycles=cycles+1;
    end
  endtask

  task send;
    input [2:0] op;
    input w;
    input [63:0] a,b;
    input [IW-1:0] id;
    integer timeout;
    begin
      req_valid=1; inst={7'b0000001,5'd2,5'd1,op,5'd3,7'h33};
      lhs=a; rhs=b; word_op=w; req_pid=id; req_dest=id[PW-1:0];
      timeout=0; #1;
      while (!req_ready && timeout<120) begin tick(); timeout=timeout+1; end
      if (!req_ready) $fatal(1,"MulDiv request timed out");
      tick(); req_valid=0;
    end
  endtask

  task drain;
    integer timeout;
    begin
      req_valid=0; resp_ready=1; timeout=0;
      while ((owner_valid || expected_valid!=0) && timeout<150) begin
        tick(); timeout=timeout+1;
      end
      if (owner_valid || expected_valid!=0) $fatal(1,"MulDiv failed to drain");
    end
  endtask

  initial begin
    tb_errors=0; expected_valid=0; next_id=0;
    tick(); rst=0; tick();
    values[0]=0; values[1]=1; values[2]=2; values[3]=64'hffff_ffff_ffff_ffff;
    values[4]=64'h8000_0000_0000_0000; values[5]=64'h7fff_ffff_ffff_ffff;
    values[6]=64'h0000_0000_8000_0000; values[7]=64'hffff_ffff_8000_0000;
    values[8]=64'h1234_5678_9abc_def0; values[9]=64'hfedc_ba98_7654_3210;
    for (k=0;k<2;k=k+1)
      for (n=0;n<8;n=n+1)
        for (i=0;i<10;i=i+1)
          for (j=0;j<10;j=j+1) begin
            send(n[2:0],k[0],values[i],values[j],next_id);
            drain(); next_id=next_id+1'b1;
          end

    // 持续乘法：每一拍输入都必须实际握手，验证 II=1，结果逐项 scoreboard。
    for (i=0;i<96;i=i+1) begin
      req_valid=1; inst={7'b0000001,5'd2,5'd1,i[1:0],1'b0,5'd3,7'h33};
      inst[14:12]={1'b0,i[1:0]};
      lhs=64'hfd12_89ba_30dc_1291+i; rhs=64'h85ab_090d_4815_cd21-i;
      req_pid=next_id; req_dest=next_id[PW-1:0]; word_op=0; #1;
      if (!req_ready) $fatal(1,"pipelined multiplier inserted launch bubble at %0d",i);
      tick(); next_id=next_id+1'b1;
    end
    req_valid=0; drain();

    // divider busy 不得阻挡独立 MUL。选大商保留足够长的重叠窗口。
    send(3'b101,0,64'hffff_ffff_ffff_ffff,64'd3,next_id); next_id=next_id+1'b1;
    for (i=0;i<12;i=i+1) begin
      send(3'b000,0,64'd17+i,64'd91,next_id); next_id=next_id+1'b1;
    end
    drain();

    // 结果反压后分母零的 DIV 先完成，不能覆盖已经呈现的 MUL response。
    resp_ready=0;
    send(3'b000,0,64'd123,64'd456,next_id); next_id=next_id+1'b1;
    repeat(5) tick();
    if (!resp_valid) $fatal(1,"missing buffered multiply result");
    held_data=result; held_pid=resp_pid;
    send(3'b100,0,64'd99,64'd0,next_id); next_id=next_id+1'b1;
    repeat(8) begin
      tick();
      if (!resp_valid || result!==held_data || resp_pid!==held_pid)
        $fatal(1,"response arbitration changed a stalled payload");
    end
    drain();

    // ROB wrap 的 selective kill：保留较老项，清除年轻在途 MUL/DIV/结果。
    head_idx=4'he; kill_idx=4'h1;
    resp_ready=0;
    send(3'b000,0,64'd5,64'd7,{{GW{1'b1}},4'hf});
    send(3'b101,0,64'hffff_ffff_ffff_ffff,64'd3,{{GW{1'b1}},4'h3});
    send(3'b010,0,64'hffff_ffff_ffff_fffe,64'd9,{{GW{1'b1}},4'h4});
    kill_valid=1; tick(); kill_valid=0; drain();
    head_idx=0;

    for (i=0;i<500;i=i+1) begin
      random_state=random_state^(random_state<<13);
      random_state=random_state^(random_state>>7);
      random_state=random_state^(random_state<<17);
      send(i[2:0],i[3],random_state,random_state^64'hdb24_516f_908a_3711,next_id);
      next_id=next_id+1'b1; drain();
    end
    resp_ready=0;
    send(3'b000,0,64'd91,64'd82,next_id);
    flush=1; tick(); flush=0;
    repeat(8) tick();
    if (resp_valid || owner_valid || live_mask!=0) $fatal(1,"flush retained MulDiv work");
    $display("[COVERAGE] accepted=%0d completed=%0d cycles=%0d mul_ii=1",accepted,completed,cycles);
    tb_finish("tb_ooo_muldiv_unit");
  end
endmodule
