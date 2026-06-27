`include "define.v"
`include "tb_common.svh"

module tb_ooo_fetch_packet_seed_mux;
  reg csr_trap;
  reg direct_flush;
  reg fallthrough_capture;
  reg branch_spec_restore;
  reg pending_branch_commit_resolve;
  reg pending_branch_match;
  reg pending_branch_misaligned;
  reg branch_prefetch_hit;
  reg branch_resolve_untracked;
  reg pending_jump_resolve;
  reg pending_jump_misaligned;
  reg pending_jump_redirect;
  reg pending_mem_resolve;
  reg system_csr_dispatch;
  reg pending_system_csr_commit;
  reg drain_complete;
  reg drain_pending_arch_trap;
  reg drain_pending_system;
  reg drain_pending_branch_undispatched;
  reg drain_pending_jump;
  reg drain_pending_mem;
  reg drain_pending_fp;
  reg jalr_prefetch_hit;

  reg [`XLEN-1:0] fallthrough_pc0;
  reg [`XLEN-1:0] fallthrough_pc1;
  reg [`XLEN-1:0] fallthrough_next_pc0;
  reg [`XLEN-1:0] fallthrough_next_pc1;
  reg [`XLEN-1:0] fallthrough_packet_next_pc;
  reg [`INST_W-1:0] fallthrough_inst0;
  reg [`INST_W-1:0] fallthrough_inst1;
  reg [1:0] fallthrough_resp0;
  reg [1:0] fallthrough_resp1;

  reg [`XLEN-1:0] branch_pc0;
  reg [`XLEN-1:0] branch_pc1;
  reg [`XLEN-1:0] branch_next_pc0;
  reg [`XLEN-1:0] branch_next_pc1;
  reg [`XLEN-1:0] branch_packet_next_pc;
  reg [`INST_W-1:0] branch_inst0;
  reg [`INST_W-1:0] branch_inst1;
  reg [1:0] branch_resp0;
  reg [1:0] branch_resp1;

  reg [`XLEN-1:0] jalr_pc0;
  reg [`XLEN-1:0] jalr_pc1;
  reg [`XLEN-1:0] jalr_next_pc0;
  reg [`XLEN-1:0] jalr_next_pc1;
  reg [`XLEN-1:0] jalr_packet_next_pc;
  reg [`INST_W-1:0] jalr_inst0;
  reg [`INST_W-1:0] jalr_inst1;
  reg [1:0] jalr_resp0;
  reg [1:0] jalr_resp1;

  wire clear;
  wire seed_valid;
  wire [`XLEN-1:0] seed_pc0;
  wire [`XLEN-1:0] seed_pc1;
  wire [`XLEN-1:0] seed_next_pc0;
  wire [`XLEN-1:0] seed_next_pc1;
  wire [`XLEN-1:0] seed_packet_next_pc;
  wire [`INST_W-1:0] seed_inst0;
  wire [`INST_W-1:0] seed_inst1;
  wire [1:0] seed_resp0;
  wire [1:0] seed_resp1;

  OooFetchPacketSeedMux dut (
    .csr_trap_i(csr_trap),
    .direct_flush_i(direct_flush),
    .fallthrough_capture_i(fallthrough_capture),
    .branch_spec_restore_i(branch_spec_restore),
    .pending_branch_commit_resolve_i(pending_branch_commit_resolve),
    .pending_branch_match_i(pending_branch_match),
    .pending_branch_misaligned_i(pending_branch_misaligned),
    .branch_prefetch_hit_i(branch_prefetch_hit),
    .branch_resolve_untracked_i(branch_resolve_untracked),
    .pending_jump_resolve_i(pending_jump_resolve),
    .pending_jump_misaligned_i(pending_jump_misaligned),
    .pending_jump_redirect_i(pending_jump_redirect),
    .pending_mem_resolve_i(pending_mem_resolve),
    .system_csr_dispatch_i(system_csr_dispatch),
    .pending_system_csr_commit_i(pending_system_csr_commit),
    .drain_complete_i(drain_complete),
    .drain_pending_arch_trap_i(drain_pending_arch_trap),
    .drain_pending_system_i(drain_pending_system),
    .drain_pending_branch_undispatched_i(drain_pending_branch_undispatched),
    .drain_pending_jump_i(drain_pending_jump),
    .drain_pending_mem_i(drain_pending_mem),
    .drain_pending_fp_i(drain_pending_fp),
    .jalr_prefetch_hit_i(jalr_prefetch_hit),
    .fallthrough_pc0_i(fallthrough_pc0),
    .fallthrough_pc1_i(fallthrough_pc1),
    .fallthrough_next_pc0_i(fallthrough_next_pc0),
    .fallthrough_next_pc1_i(fallthrough_next_pc1),
    .fallthrough_packet_next_pc_i(fallthrough_packet_next_pc),
    .fallthrough_inst0_i(fallthrough_inst0),
    .fallthrough_inst1_i(fallthrough_inst1),
    .fallthrough_resp0_i(fallthrough_resp0),
    .fallthrough_resp1_i(fallthrough_resp1),
    .branch_pc0_i(branch_pc0),
    .branch_pc1_i(branch_pc1),
    .branch_next_pc0_i(branch_next_pc0),
    .branch_next_pc1_i(branch_next_pc1),
    .branch_packet_next_pc_i(branch_packet_next_pc),
    .branch_inst0_i(branch_inst0),
    .branch_inst1_i(branch_inst1),
    .branch_resp0_i(branch_resp0),
    .branch_resp1_i(branch_resp1),
    .jalr_pc0_i(jalr_pc0),
    .jalr_pc1_i(jalr_pc1),
    .jalr_next_pc0_i(jalr_next_pc0),
    .jalr_next_pc1_i(jalr_next_pc1),
    .jalr_packet_next_pc_i(jalr_packet_next_pc),
    .jalr_inst0_i(jalr_inst0),
    .jalr_inst1_i(jalr_inst1),
    .jalr_resp0_i(jalr_resp0),
    .jalr_resp1_i(jalr_resp1),
    .clear_o(clear),
    .seed_valid_o(seed_valid),
    .seed_pc0_o(seed_pc0),
    .seed_pc1_o(seed_pc1),
    .seed_next_pc0_o(seed_next_pc0),
    .seed_next_pc1_o(seed_next_pc1),
    .seed_packet_next_pc_o(seed_packet_next_pc),
    .seed_inst0_o(seed_inst0),
    .seed_inst1_o(seed_inst1),
    .seed_resp0_o(seed_resp0),
    .seed_resp1_o(seed_resp1)
  );

  task automatic check_xlen;
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

  task automatic check_seed_packet;
    input [1023:0] tag;
    input [`XLEN-1:0] exp_pc0;
    input [`XLEN-1:0] exp_pc1;
    input [`XLEN-1:0] exp_next_pc0;
    input [`XLEN-1:0] exp_next_pc1;
    input [`XLEN-1:0] exp_packet_next_pc;
    input [`INST_W-1:0] exp_inst0;
    input [`INST_W-1:0] exp_inst1;
    input [1:0] exp_resp0;
    input [1:0] exp_resp1;
    begin
      tb_check1({tag, " clear"}, clear, 1'b0);
      tb_check1({tag, " seed valid"}, seed_valid, 1'b1);
      check_xlen({tag, " pc0"}, seed_pc0, exp_pc0);
      check_xlen({tag, " pc1"}, seed_pc1, exp_pc1);
      check_xlen({tag, " next0"}, seed_next_pc0, exp_next_pc0);
      check_xlen({tag, " next1"}, seed_next_pc1, exp_next_pc1);
      check_xlen({tag, " packet next"}, seed_packet_next_pc,
                 exp_packet_next_pc);
      tb_check32({tag, " inst0"}, seed_inst0, exp_inst0);
      tb_check32({tag, " inst1"}, seed_inst1, exp_inst1);
      tb_check32({tag, " resp0"}, {30'b0, seed_resp0}, {30'b0, exp_resp0});
      tb_check32({tag, " resp1"}, {30'b0, seed_resp1}, {30'b0, exp_resp1});
    end
  endtask

  task automatic check_clear;
    input [1023:0] tag;
    begin
      tb_check1({tag, " clear"}, clear, 1'b1);
      tb_check1({tag, " seed invalid"}, seed_valid, 1'b0);
    end
  endtask

  task automatic check_noop;
    input [1023:0] tag;
    begin
      tb_check1({tag, " no clear"}, clear, 1'b0);
      tb_check1({tag, " no seed"}, seed_valid, 1'b0);
    end
  endtask

  task automatic reset_inputs;
    begin
      csr_trap = 1'b0;
      direct_flush = 1'b0;
      fallthrough_capture = 1'b0;
      branch_spec_restore = 1'b0;
      pending_branch_commit_resolve = 1'b0;
      pending_branch_match = 1'b0;
      pending_branch_misaligned = 1'b0;
      branch_prefetch_hit = 1'b0;
      branch_resolve_untracked = 1'b0;
      pending_jump_resolve = 1'b0;
      pending_jump_misaligned = 1'b0;
      pending_jump_redirect = 1'b0;
      pending_mem_resolve = 1'b0;
      system_csr_dispatch = 1'b0;
      pending_system_csr_commit = 1'b0;
      drain_complete = 1'b0;
      drain_pending_arch_trap = 1'b0;
      drain_pending_system = 1'b0;
      drain_pending_branch_undispatched = 1'b0;
      drain_pending_jump = 1'b0;
      drain_pending_mem = 1'b0;
      drain_pending_fp = 1'b0;
      jalr_prefetch_hit = 1'b0;

      fallthrough_pc0 = 64'h0000_0000_0000_1000;
      fallthrough_pc1 = 64'h0000_0000_0000_1004;
      fallthrough_next_pc0 = 64'h0000_0000_0000_1004;
      fallthrough_next_pc1 = 64'h0000_0000_0000_1008;
      fallthrough_packet_next_pc = 64'h0000_0000_0000_1008;
      fallthrough_inst0 = 32'h0000_0013;
      fallthrough_inst1 = 32'h0010_0093;
      fallthrough_resp0 = 2'b00;
      fallthrough_resp1 = 2'b01;

      branch_pc0 = 64'h0000_0000_0000_2000;
      branch_pc1 = 64'h0000_0000_0000_2002;
      branch_next_pc0 = 64'h0000_0000_0000_2002;
      branch_next_pc1 = 64'h0000_0000_0000_2004;
      branch_packet_next_pc = 64'h0000_0000_0000_2004;
      branch_inst0 = 32'h0020_0113;
      branch_inst1 = 32'h0030_0193;
      branch_resp0 = 2'b10;
      branch_resp1 = 2'b11;

      jalr_pc0 = 64'h0000_0000_0000_3000;
      jalr_pc1 = 64'h0000_0000_0000_3004;
      jalr_next_pc0 = 64'h0000_0000_0000_3004;
      jalr_next_pc1 = 64'h0000_0000_0000_3008;
      jalr_packet_next_pc = 64'h0000_0000_0000_3008;
      jalr_inst0 = 32'h0040_0213;
      jalr_inst1 = 32'h0050_0293;
      jalr_resp0 = 2'b01;
      jalr_resp1 = 2'b00;
      #1;
    end
  endtask

  initial begin
    tb_errors = 0;

    reset_inputs();
    check_noop("default");

    reset_inputs();
    direct_flush = 1'b1;
    fallthrough_capture = 1'b1;
    #1;
    check_seed_packet("direct flush fallthrough seed",
                      fallthrough_pc0, fallthrough_pc1,
                      fallthrough_next_pc0, fallthrough_next_pc1,
                      fallthrough_packet_next_pc, fallthrough_inst0,
                      fallthrough_inst1, fallthrough_resp0, fallthrough_resp1);

    reset_inputs();
    csr_trap = 1'b1;
    direct_flush = 1'b1;
    fallthrough_capture = 1'b1;
    pending_branch_match = 1'b1;
    branch_prefetch_hit = 1'b1;
    #1;
    check_clear("csr trap final override");

    reset_inputs();
    branch_spec_restore = 1'b1;
    #1;
    check_clear("branch spec restore");

    reset_inputs();
    pending_branch_match = 1'b1;
    branch_prefetch_hit = 1'b1;
    #1;
    check_seed_packet("pending branch prefetch seed",
                      branch_pc0, branch_pc1, branch_next_pc0,
                      branch_next_pc1, branch_packet_next_pc, branch_inst0,
                      branch_inst1, branch_resp0, branch_resp1);

    reset_inputs();
    pending_branch_commit_resolve = 1'b1;
    pending_branch_match = 1'b1;
    branch_prefetch_hit = 1'b1;
    #1;
    check_clear("branch commit overrides branch seed");

    reset_inputs();
    pending_branch_match = 1'b1;
    pending_branch_misaligned = 1'b1;
    branch_prefetch_hit = 1'b1;
    #1;
    check_clear("branch misaligned clears");

    reset_inputs();
    branch_resolve_untracked = 1'b1;
    #1;
    check_clear("untracked branch clears");

    reset_inputs();
    pending_jump_resolve = 1'b1;
    pending_jump_redirect = 1'b1;
    jalr_prefetch_hit = 1'b1;
    #1;
    check_seed_packet("pending jump jalr seed",
                      jalr_pc0, jalr_pc1, jalr_next_pc0, jalr_next_pc1,
                      jalr_packet_next_pc, jalr_inst0, jalr_inst1,
                      jalr_resp0, jalr_resp1);

    reset_inputs();
    pending_jump_resolve = 1'b1;
    pending_jump_redirect = 1'b1;
    jalr_prefetch_hit = 1'b0;
    #1;
    check_clear("pending jump redirect no hit clears");

    reset_inputs();
    pending_jump_resolve = 1'b1;
    pending_jump_redirect = 1'b0;
    #1;
    check_noop("pending jump resolve without redirect");

    reset_inputs();
    pending_mem_resolve = 1'b1;
    drain_complete = 1'b1;
    drain_pending_mem = 1'b1;
    #1;
    check_noop("pending mem resolve blocks drain clear");

    reset_inputs();
    system_csr_dispatch = 1'b1;
    pending_system_csr_commit = 1'b1;
    #1;
    check_noop("csr dispatch blocks csr commit clear");

    reset_inputs();
    pending_system_csr_commit = 1'b1;
    #1;
    check_clear("csr commit clears");

    reset_inputs();
    drain_complete = 1'b1;
    drain_pending_jump = 1'b1;
    jalr_prefetch_hit = 1'b1;
    #1;
    check_seed_packet("drain jump jalr seed",
                      jalr_pc0, jalr_pc1, jalr_next_pc0, jalr_next_pc1,
                      jalr_packet_next_pc, jalr_inst0, jalr_inst1,
                      jalr_resp0, jalr_resp1);

    reset_inputs();
    drain_complete = 1'b1;
    drain_pending_arch_trap = 1'b1;
    #1;
    check_clear("drain arch trap clears");

    reset_inputs();
    drain_complete = 1'b1;
    drain_pending_fp = 1'b1;
    #1;
    check_clear("drain fp clears");

    tb_finish("tb_ooo_fetch_packet_seed_mux");
  end

endmodule

