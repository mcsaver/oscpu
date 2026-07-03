`timescale 1ns/1ps
`include "define.v"
`include "tb_common.svh"

module tb_ooo_frontend_backend_dispatch_mux;
  reg branch_prefetch_dispatch_attempt;
  reg branch_prefetch_dispatch_buffer;
  reg branch_prefetch_dispatch_rsp;
  reg system_csr_dispatch_valid;
  reg frontend_dispatch_to_backend_valid;
  reg direct_branch0_dispatch_valid;
  reg direct_jal0_dispatch_valid;
  reg direct_ret0_dispatch_valid;
  reg lane1_barrier_dispatch0_valid;
  reg jump_dispatch_valid;
  reg mem_dispatch_valid;
  reg return_cont_attempt;
  reg branch_target_append_attempt;
  reg branch_fallthrough_append_attempt;
  reg direct_jal1_fire;
  reg direct_ret1_fire;
  reg dispatch0_ready;

  reg [`XLEN-1:0] branch_prefetch_buf_pc0;
  reg [`XLEN-1:0] branch_prefetch_buf_next_pc0;
  reg [`INST_W-1:0] branch_prefetch_buf_inst0;
  reg [`XLEN-1:0] branch_prefetch_buf_pc1;
  reg [`XLEN-1:0] branch_prefetch_buf_next_pc1;
  reg [`INST_W-1:0] branch_prefetch_buf_inst1;

  reg [`XLEN-1:0] fetch_dec0_pc;
  reg [`XLEN-1:0] fetch_dec0_next_pc;
  reg [`INST_W-1:0] fetch_dec0_inst;
  reg [`XLEN-1:0] fetch_dec1_pc;
  reg [`XLEN-1:0] fetch_dec1_next_pc;
  reg [`INST_W-1:0] fetch_dec1_inst;

  reg [`XLEN-1:0] pending_system_pc;
  reg [`XLEN-1:0] pending_system_next_pc;
  reg [`INST_W-1:0] pending_system_inst;
  reg [`XLEN-1:0] pending_system_csr_rdata;

  reg [`XLEN-1:0] pending_jump_pc;
  reg [`XLEN-1:0] pending_jump_next_pc;
  reg [`INST_W-1:0] pending_jump_inst;

  reg [`XLEN-1:0] pending_mem_pc;
  reg [`XLEN-1:0] pending_mem_next_pc;
  reg [`INST_W-1:0] pending_mem_inst;

  reg [`XLEN-1:0] head_pc0;
  reg [`XLEN-1:0] head_next_pc0;
  reg [`INST_W-1:0] head_inst0;
  reg [`XLEN-1:0] head_pc1;
  reg [`XLEN-1:0] head_next_pc1;
  reg [`INST_W-1:0] head_inst1;

  reg [`XLEN-1:0] return_cont_pc;
  reg [`XLEN-1:0] return_cont_next_pc;
  reg [`INST_W-1:0] return_cont_inst;

  reg [`XLEN-1:0] branch_target_cache_target_pc;
  reg [`XLEN-1:0] branch_target_cache_next_pc;
  reg [`INST_W-1:0] branch_target_cache_inst;
  reg [`XLEN-1:0] direct_ret_target;

  wire core_dispatch0_valid;
  wire core_dispatch1_valid;
  wire core_dispatch0_fire;
  wire jump_dispatch_fire;
  wire mem_dispatch_fire;
  wire [`XLEN-1:0] core_dispatch0_pc;
  wire [`XLEN-1:0] core_dispatch0_next_pc;
  wire [`INST_W-1:0] core_dispatch0_inst;
  wire [`XLEN-1:0] core_dispatch0_csr_rdata;
  wire [`XLEN-1:0] core_dispatch1_pc;
  wire [`XLEN-1:0] core_dispatch1_next_pc;
  wire [`INST_W-1:0] core_dispatch1_inst;

  OooFrontendBackendDispatchMux dut (
    .dispatch1_ready_i(1'b1),
    .dispatch1_squash_i(1'b0),
    .d0_ctrlflow_fired_i(1'b0),
    .d1_ctrlflow_fired_i(1'b0),
    .direct_fire_succ_i({`XLEN{1'b0}}),
    .branch_prefetch_dispatch_attempt_i(branch_prefetch_dispatch_attempt),
    .branch_prefetch_dispatch_buffer_i(branch_prefetch_dispatch_buffer),
    .branch_prefetch_dispatch_rsp_i(branch_prefetch_dispatch_rsp),
    .system_csr_dispatch_valid_i(system_csr_dispatch_valid),
    .frontend_dispatch_to_backend_valid_i(frontend_dispatch_to_backend_valid),
    .direct_branch0_dispatch_valid_i(direct_branch0_dispatch_valid),
    .direct_jal0_dispatch_valid_i(direct_jal0_dispatch_valid),
    .direct_ret0_dispatch_valid_i(direct_ret0_dispatch_valid),
    .lane1_barrier_dispatch0_valid_i(lane1_barrier_dispatch0_valid),
    .jump_dispatch_valid_i(jump_dispatch_valid),
    .mem_dispatch_valid_i(mem_dispatch_valid),
    .return_cont_attempt_i(return_cont_attempt),
    .branch_target_append_attempt_i(branch_target_append_attempt),
    .branch_fallthrough_append_attempt_i(branch_fallthrough_append_attempt),
    .direct_jal1_fire_i(direct_jal1_fire),
    .direct_ret1_fire_i(direct_ret1_fire),
    .dispatch0_ready_i(dispatch0_ready),
    .branch_prefetch_buf_pc0_i(branch_prefetch_buf_pc0),
    .branch_prefetch_buf_next_pc0_i(branch_prefetch_buf_next_pc0),
    .branch_prefetch_buf_inst0_i(branch_prefetch_buf_inst0),
    .branch_prefetch_buf_pc1_i(branch_prefetch_buf_pc1),
    .branch_prefetch_buf_next_pc1_i(branch_prefetch_buf_next_pc1),
    .branch_prefetch_buf_inst1_i(branch_prefetch_buf_inst1),
    .fetch_dec0_pc_i(fetch_dec0_pc),
    .fetch_dec0_next_pc_i(fetch_dec0_next_pc),
    .fetch_dec0_inst_i(fetch_dec0_inst),
    .fetch_dec1_pc_i(fetch_dec1_pc),
    .fetch_dec1_next_pc_i(fetch_dec1_next_pc),
    .fetch_dec1_inst_i(fetch_dec1_inst),
    .pending_system_pc_i(pending_system_pc),
    .pending_system_next_pc_i(pending_system_next_pc),
    .pending_system_inst_i(pending_system_inst),
    .pending_system_csr_rdata_i(pending_system_csr_rdata),
    .pending_jump_pc_i(pending_jump_pc),
    .pending_jump_next_pc_i(pending_jump_next_pc),
    .pending_jump_inst_i(pending_jump_inst),
    .pending_mem_pc_i(pending_mem_pc),
    .pending_mem_next_pc_i(pending_mem_next_pc),
    .pending_mem_inst_i(pending_mem_inst),
    .head_pc0_i(head_pc0),
    .head_next_pc0_i(head_next_pc0),
    .head_inst0_i(head_inst0),
    .head_pc1_i(head_pc1),
    .head_next_pc1_i(head_next_pc1),
    .head_inst1_i(head_inst1),
    .next_fetch_pc_i('0),
    .return_cont_pc_i(return_cont_pc),
    .return_cont_next_pc_i(return_cont_next_pc),
    .return_cont_inst_i(return_cont_inst),
    .branch_target_cache_target_pc_i(branch_target_cache_target_pc),
    .branch_target_cache_next_pc_i(branch_target_cache_next_pc),
    .branch_target_cache_inst_i(branch_target_cache_inst),
    .direct_ret_target_i(direct_ret_target),
    .core_dispatch0_valid_o(core_dispatch0_valid),
    .core_dispatch1_valid_o(core_dispatch1_valid),
    .core_dispatch0_fire_o(core_dispatch0_fire),
    .jump_dispatch_fire_o(jump_dispatch_fire),
    .mem_dispatch_fire_o(mem_dispatch_fire),
    .core_dispatch0_pc_o(core_dispatch0_pc),
    .core_dispatch0_next_pc_o(core_dispatch0_next_pc),
    .core_dispatch0_inst_o(core_dispatch0_inst),
    .core_dispatch0_csr_rdata_o(core_dispatch0_csr_rdata),
    .core_dispatch1_pc_o(core_dispatch1_pc),
    .core_dispatch1_next_pc_o(core_dispatch1_next_pc),
    .core_dispatch1_inst_o(core_dispatch1_inst)
  );

  task automatic tb_check64;
    input [1023:0] what;
    input [`XLEN-1:0] got;
    input [`XLEN-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%016x expected=0x%016x",
                 what, got, exp);
      end
    end
  endtask

  task automatic reset_inputs;
    begin
      branch_prefetch_dispatch_attempt = 1'b0;
      branch_prefetch_dispatch_buffer = 1'b0;
      branch_prefetch_dispatch_rsp = 1'b0;
      system_csr_dispatch_valid = 1'b0;
      frontend_dispatch_to_backend_valid = 1'b0;
      direct_branch0_dispatch_valid = 1'b0;
      direct_jal0_dispatch_valid = 1'b0;
      direct_ret0_dispatch_valid = 1'b0;
      lane1_barrier_dispatch0_valid = 1'b0;
      jump_dispatch_valid = 1'b0;
      mem_dispatch_valid = 1'b0;
      return_cont_attempt = 1'b0;
      branch_target_append_attempt = 1'b0;
      branch_fallthrough_append_attempt = 1'b0;
      direct_jal1_fire = 1'b0;
      direct_ret1_fire = 1'b0;
      dispatch0_ready = 1'b1;

      branch_prefetch_buf_pc0 = 64'h3000_0000;
      branch_prefetch_buf_next_pc0 = 64'h3000_0004;
      branch_prefetch_buf_inst0 = 32'h3000_0000;
      branch_prefetch_buf_pc1 = 64'h3000_0008;
      branch_prefetch_buf_next_pc1 = 64'h3000_000c;
      branch_prefetch_buf_inst1 = 32'h3000_0001;

      fetch_dec0_pc = 64'h2000_0000;
      fetch_dec0_next_pc = 64'h2000_0004;
      fetch_dec0_inst = 32'h2000_0000;
      fetch_dec1_pc = 64'h2000_0008;
      fetch_dec1_next_pc = 64'h2000_000c;
      fetch_dec1_inst = 32'h2000_0001;

      pending_system_pc = 64'h4000_0000;
      pending_system_next_pc = 64'h4000_0004;
      pending_system_inst = 32'h4000_0073;
      pending_system_csr_rdata = 64'h0123_4567_89ab_cdef;

      pending_jump_pc = 64'h5000_0000;
      pending_jump_next_pc = 64'h5000_0100;
      pending_jump_inst = 32'h0000_006f;

      pending_mem_pc = 64'h6000_0000;
      pending_mem_next_pc = 64'h6000_0004;
      pending_mem_inst = 32'h0000_2083;

      head_pc0 = 64'h1000_0000;
      head_next_pc0 = 64'h1000_0004;
      head_inst0 = 32'h0010_0093;
      head_pc1 = 64'h1000_0004;
      head_next_pc1 = 64'h1000_0008;
      head_inst1 = 32'h0020_0113;

      return_cont_pc = 64'h7000_0000;
      return_cont_next_pc = 64'h7000_0004;
      return_cont_inst = 32'h0000_8067;

      branch_target_cache_target_pc = 64'h8000_0000;
      branch_target_cache_next_pc = 64'h8000_0004;
      branch_target_cache_inst = 32'h0030_0193;
      direct_ret_target = 64'h9000_0000;
      #1;
    end
  endtask

  task automatic expect_dispatch0;
    input [1023:0] name;
    input valid;
    input [`XLEN-1:0] pc;
    input [`XLEN-1:0] next_pc;
    input [`INST_W-1:0] inst;
    input [`XLEN-1:0] csr_rdata;
    begin
      tb_check1({name, " d0 valid"}, core_dispatch0_valid, valid);
      tb_check64({name, " d0 pc"}, core_dispatch0_pc, pc);
      tb_check64({name, " d0 next"}, core_dispatch0_next_pc, next_pc);
      tb_check32({name, " d0 inst"}, core_dispatch0_inst, inst);
      tb_check64({name, " d0 csr"}, core_dispatch0_csr_rdata, csr_rdata);
    end
  endtask

  task automatic expect_dispatch1;
    input [1023:0] name;
    input valid;
    input [`XLEN-1:0] pc;
    input [`XLEN-1:0] next_pc;
    input [`INST_W-1:0] inst;
    begin
      tb_check1({name, " d1 valid"}, core_dispatch1_valid, valid);
      tb_check64({name, " d1 pc"}, core_dispatch1_pc, pc);
      tb_check64({name, " d1 next"}, core_dispatch1_next_pc, next_pc);
      tb_check32({name, " d1 inst"}, core_dispatch1_inst, inst);
    end
  endtask

  initial begin
    tb_errors = 0;

    reset_inputs();
    frontend_dispatch_to_backend_valid = 1'b1;
    #1;
    expect_dispatch0("normal", 1'b1, head_pc0, head_next_pc0, head_inst0,
                     {`XLEN{1'b0}});
    expect_dispatch1("normal", 1'b1, head_pc1, head_next_pc1, head_inst1);
    tb_check1("normal fire", core_dispatch0_fire, 1'b1);
    tb_check1("normal no jump fire", jump_dispatch_fire, 1'b0);
    tb_check1("normal no mem fire", mem_dispatch_fire, 1'b0);

    reset_inputs();
    branch_prefetch_dispatch_attempt = 1'b1;
    branch_prefetch_dispatch_buffer = 1'b1;
    branch_prefetch_dispatch_rsp = 1'b1;
    #1;
    expect_dispatch0("prefetch buffer wins", 1'b1, branch_prefetch_buf_pc0,
                     branch_prefetch_buf_next_pc0, branch_prefetch_buf_inst0,
                     {`XLEN{1'b0}});
    expect_dispatch1("prefetch buffer wins", 1'b1, branch_prefetch_buf_pc1,
                     branch_prefetch_buf_next_pc1, branch_prefetch_buf_inst1);

    reset_inputs();
    branch_prefetch_dispatch_attempt = 1'b1;
    branch_prefetch_dispatch_rsp = 1'b1;
    #1;
    expect_dispatch0("prefetch rsp", 1'b1, fetch_dec0_pc,
                     fetch_dec0_next_pc, fetch_dec0_inst, {`XLEN{1'b0}});
    expect_dispatch1("prefetch rsp", 1'b1, fetch_dec1_pc,
                     fetch_dec1_next_pc, fetch_dec1_inst);

    reset_inputs();
    system_csr_dispatch_valid = 1'b1;
    #1;
    expect_dispatch0("system csr", 1'b1, pending_system_pc,
                     pending_system_next_pc, pending_system_inst,
                     pending_system_csr_rdata);
    expect_dispatch1("system csr", 1'b0, head_pc1, head_next_pc1, head_inst1);

    reset_inputs();
    jump_dispatch_valid = 1'b1;
    #1;
    expect_dispatch0("pending jump", 1'b1, pending_jump_pc,
                     pending_jump_next_pc, pending_jump_inst, {`XLEN{1'b0}});
    tb_check1("jump fire", jump_dispatch_fire, 1'b1);
    tb_check1("jump d0 fire", core_dispatch0_fire, 1'b1);

    reset_inputs();
    mem_dispatch_valid = 1'b1;
    #1;
    expect_dispatch0("pending mem", 1'b1, pending_mem_pc,
                     pending_mem_next_pc, pending_mem_inst, {`XLEN{1'b0}});
    tb_check1("mem fire", mem_dispatch_fire, 1'b1);

    reset_inputs();
    direct_ret0_dispatch_valid = 1'b1;
    #1;
    expect_dispatch0("direct ret0", 1'b1, head_pc0, direct_ret_target,
                     head_inst0, {`XLEN{1'b0}});

    reset_inputs();
    return_cont_attempt = 1'b1;
    #1;
    expect_dispatch0("return cont", 1'b0, head_pc0, head_next_pc0,
                     head_inst0, {`XLEN{1'b0}});
    expect_dispatch1("return cont", 1'b1, return_cont_pc,
                     return_cont_next_pc, return_cont_inst);

    reset_inputs();
    branch_target_append_attempt = 1'b1;
    #1;
    expect_dispatch1("branch target append", 1'b1,
                     branch_target_cache_target_pc,
                     branch_target_cache_next_pc,
                     branch_target_cache_inst);

    reset_inputs();
    branch_fallthrough_append_attempt = 1'b1;
    #1;
    expect_dispatch1("fallthrough append", 1'b1, head_pc1, head_next_pc1,
                     head_inst1);

    reset_inputs();
    frontend_dispatch_to_backend_valid = 1'b1;
    direct_ret1_fire = 1'b1;
    #1;
    expect_dispatch1("direct ret1 next", 1'b1, head_pc1, direct_ret_target,
                     head_inst1);

    reset_inputs();
    jump_dispatch_valid = 1'b1;
    dispatch0_ready = 1'b0;
    #1;
    tb_check1("ready blocks d0 fire", core_dispatch0_fire, 1'b0);
    tb_check1("ready blocks jump fire", jump_dispatch_fire, 1'b0);
    expect_dispatch0("ready blocked payload", 1'b1, pending_jump_pc,
                     pending_jump_next_pc, pending_jump_inst, {`XLEN{1'b0}});

    reset_inputs();
    system_csr_dispatch_valid = 1'b1;
    jump_dispatch_valid = 1'b1;
    mem_dispatch_valid = 1'b1;
    #1;
    expect_dispatch0("d0 source priority", 1'b1, pending_system_pc,
                     pending_system_next_pc, pending_system_inst,
                     pending_system_csr_rdata);
    tb_check1("independent jump fire", jump_dispatch_fire, 1'b1);
    tb_check1("independent mem fire", mem_dispatch_fire, 1'b1);

    tb_finish("tb_ooo_frontend_backend_dispatch_mux");
  end
endmodule
