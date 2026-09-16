`timescale 1ns/1ps
`include "define.v"
`ifndef TENSOR_SIDECAR_SHARED_READ_FOCUSED
`include "tensor_npu_defs.vh"
`endif

module tb_ooo_direct_npu_slice;
  logic clk;
  logic rst;
  logic flush;

  logic head_valid;
  logic head_slot1_valid;
  logic [`XLEN-1:0] head_pc0;
  logic [`INST_W-1:0] head_inst0;
  logic [1:0] head_resp0;
  logic [`XLEN-1:0] head_pc1;
  logic [`INST_W-1:0] head_inst1;
  logic [1:0] head_resp1;
  logic [`XLEN-1:0] head_fault_tval;
  logic normal_lane0_fire;
  wire head0_claim;
  wire head1_claim;
  wire head_pop;

  wire residual_valid;
  logic residual_ready;
  wire [`XLEN-1:0] residual_pc;
  wire [`INST_W-1:0] residual_inst;
  wire [1:0] residual_resp;

  wire tensor_valid;
  wire tensor_ready;
  wire [`XLEN-1:0] tensor_pc;
  wire [`XLEN-1:0] tensor_next_pc;
  wire [63:0] tensor_bits;
  wire tensor_is_64;
  wire tensor_required;
  wire [7:0] tensor_opclass;
  wire tensor_cross_packet;
  wire pair_error_valid;
  logic pair_error_ready;
  wire [`XLEN-1:0] pair_error_pc;
  wire [`TRAP_CAUSE_W-1:0] pair_error_cause;
  wire [`XLEN-1:0] pair_error_tval;
  wire [1:0] pair_error_code;
  wire pair_pending;
  wire pair_serialize;

  logic dispatch_enable;
  logic [`OOO_PRODUCER_ID_W-1:0] dispatch_pid;
  logic [`OOO_PHY_REG_ADDR_W-1:0] dispatch_src_preg;
  logic dispatch_src_ready;
  logic [`XLEN-1:0] src_read_value;

  logic direct_alloc_valid;
  logic direct_alloc_launch_open;
  logic [`OOO_PRODUCER_ID_W-1:0] direct_alloc_pid;
  logic [63:0] direct_alloc_cmd_bits;
  logic direct_alloc_is_64;
  logic direct_alloc_required;
  logic [7:0] direct_alloc_opclass;
  wire sidecar_alloc_ready;
  wire sidecar_serialize_active;
`ifdef TENSOR_SIDECAR_SHARED_READ_FOCUSED
  wire sidecar_alloc_valid = direct_alloc_valid;
`else
  wire sidecar_alloc_valid = direct_alloc_valid ||
      (tensor_valid && dispatch_enable);
`endif
  wire [`OOO_PRODUCER_ID_W-1:0] sidecar_alloc_pid =
      direct_alloc_valid ? direct_alloc_pid : dispatch_pid;

  logic wake_valid;
  logic [`OOO_PHY_REG_ADDR_W-1:0] wake_preg;
  logic [`XLEN-1:0] wake_value;
  logic wake1_valid;
  logic [`OOO_PHY_REG_ADDR_W-1:0] wake1_preg;
  logic [`XLEN-1:0] wake1_value;
  wire src_read_valid;
  wire [`OOO_PHY_REG_ADDR_W-1:0] src_read_preg;
  logic src_read_grant_enable;
  wire src_read_ready = src_read_valid && src_read_grant_enable;
  logic kill_valid;
  logic [`OOO_PRODUCER_ID_W-1:0] kill_pid;
  logic sidecar_flush;
  logic rob_head_valid;
  logic [`OOO_PRODUCER_ID_W-1:0] rob_head_pid;
  logic rob_head_launch_open;
  logic mem_idle;
  logic mem_retire_quiet;

  wire npu_cmd_valid;
  logic npu_cmd_ready;
  wire [`OOO_PRODUCER_ID_W-1:0] npu_cmd_pid;
  wire [63:0] npu_cmd_bits;
  wire [`XLEN-1:0] npu_cmd_rs_value;
  wire npu_cmd_is_64;
  wire npu_cmd_required;
  wire [7:0] npu_cmd_opclass;

  logic terminal_valid;
  wire terminal_ready;
  logic [`OOO_PRODUCER_ID_W-1:0] terminal_pid;
  logic [`XLEN-1:0] terminal_data;
  logic terminal_error;
  logic [7:0] terminal_error_code;
  wire completion_valid;
  logic completion_ready;
  logic completion_query_match;
  wire [`OOO_PRODUCER_ID_W-1:0] completion_pid;
  wire [`XLEN-1:0] completion_data;
  wire completion_error;
  wire [7:0] completion_error_code;
  wire owner_valid;
  wire [`OOO_PRODUCER_ID_W-1:0] owner_pid;
  wire [`XLEN-1:0] owner_pc;
  wire [`XLEN-1:0] owner_next_pc;
  wire sent;
  wire cmd_fire;
  wire terminal_match;
  wire completion_fire;
  wire stale_terminal_drop;
  wire stale_completion_drop;
  wire [31:0] issued_count;
  wire [31:0] terminal_count;
  wire [31:0] completion_count;
  wire [31:0] wait_head_cycles;
  wire [31:0] wait_drain_cycles;
  wire [31:0] npu_backpressure_cycles;
  wire [31:0] serialize_cycles;

`ifndef TENSOR_SIDECAR_SHARED_READ_FOCUSED
  wire dec_legal;
  wire [`NPU_OP_W-1:0] dec_op;
  wire [4:0] dec_rs_addr;
  wire [4:0] dec_imm5;
  wire [5:0] dec_dst;
  wire [5:0] dec_src0;
  wire [5:0] dec_src1;
  wire [5:0] dec_src2;
  wire [4:0] dec_flags;
  wire [1:0] dec_sync_engine;
`endif

`ifndef TENSOR_SIDECAR_SHARED_READ_FOCUSED
  assign tensor_ready = dispatch_enable && sidecar_alloc_ready &&
                        !direct_alloc_valid;

  OooTensorPairOwner u_pair (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .head_valid_i(head_valid),
    .head_slot1_valid_i(head_slot1_valid),
    .head_pc0_i(head_pc0),
    .head_inst0_i(head_inst0),
    .head_resp0_i(head_resp0),
    .head_pc1_i(head_pc1),
    .head_inst1_i(head_inst1),
    .head_resp1_i(head_resp1),
    .head_fault_tval_i(head_fault_tval),
    .normal_lane0_fire_i(normal_lane0_fire),
    .head0_claim_o(head0_claim),
    .head1_claim_o(head1_claim),
    .head_pop_o(head_pop),
    .residual_valid_o(residual_valid),
    .residual_ready_i(residual_ready),
    .residual_pc_o(residual_pc),
    .residual_inst_o(residual_inst),
    .residual_resp_o(residual_resp),
    .tensor_valid_o(tensor_valid),
    .tensor_ready_i(tensor_ready),
    .tensor_pc_o(tensor_pc),
    .tensor_next_pc_o(tensor_next_pc),
    .tensor_bits_o(tensor_bits),
    .tensor_is_64_o(tensor_is_64),
    .tensor_required_o(tensor_required),
    .tensor_opclass_o(tensor_opclass),
    .tensor_cross_packet_o(tensor_cross_packet),
    .error_valid_o(pair_error_valid),
    .error_ready_i(pair_error_ready),
    .error_pc_o(pair_error_pc),
    .error_cause_o(pair_error_cause),
    .error_tval_o(pair_error_tval),
    .error_code_o(pair_error_code),
    .pair_pending_o(pair_pending),
    .serialize_o(pair_serialize)
  );
`else
  assign tensor_ready = 1'b0;
`endif

  OooTensorRobSidecar u_sidecar (
    .clk(clk),
    .rst(rst),
    .alloc_valid_i(sidecar_alloc_valid),
    .alloc_ready_o(sidecar_alloc_ready),
    .alloc_launch_open_i(direct_alloc_launch_open),
    .alloc_producer_id_i(sidecar_alloc_pid),
    .alloc_pc_i(direct_alloc_valid ? 64'h4000 : tensor_pc),
    .alloc_next_pc_i(direct_alloc_valid ? 64'h4004 : tensor_next_pc),
    .alloc_cmd_bits_i(direct_alloc_valid ? direct_alloc_cmd_bits : tensor_bits),
    .alloc_cmd_is_64_i(direct_alloc_valid ? direct_alloc_is_64 : tensor_is_64),
    .alloc_required_i(direct_alloc_valid ? direct_alloc_required : tensor_required),
    .alloc_opclass_i(direct_alloc_valid ? direct_alloc_opclass : tensor_opclass),
    .alloc_src_preg_i(dispatch_src_preg),
    .alloc_src_ready_i(dispatch_src_ready),
    .src_read_valid_o(src_read_valid),
    .src_read_preg_o(src_read_preg),
    .src_read_ready_i(src_read_ready),
    .src_read_value_i(src_read_value),
    .wake0_valid_i(wake_valid),
    .wake0_preg_i(wake_preg),
    .wake0_value_i(wake_value),
    .wake1_valid_i(wake1_valid),
    .wake1_preg_i(wake1_preg),
    .wake1_value_i(wake1_value),
    .prelaunch_kill_valid_i(kill_valid),
    .prelaunch_kill_producer_id_i(kill_pid),
    .prelaunch_flush_i(sidecar_flush),
    .rob_head_valid_i(rob_head_valid),
    .rob_head_producer_id_i(rob_head_pid),
    .rob_head_launch_open_i(rob_head_launch_open),
    .mem_idle_i(mem_idle),
    .mem_retire_quiet_i(mem_retire_quiet),
    .cmd_valid_o(npu_cmd_valid),
    .cmd_ready_i(npu_cmd_ready),
    .cmd_producer_id_o(npu_cmd_pid),
    .cmd_bits_o(npu_cmd_bits),
    .cmd_rs_value_o(npu_cmd_rs_value),
    .cmd_is_64_o(npu_cmd_is_64),
    .cmd_required_o(npu_cmd_required),
    .cmd_opclass_o(npu_cmd_opclass),
    .terminal_valid_i(terminal_valid),
    .terminal_ready_o(terminal_ready),
    .terminal_producer_id_i(terminal_pid),
    .terminal_data_i(terminal_data),
    .terminal_error_i(terminal_error),
    .terminal_error_code_i(terminal_error_code),
    .completion_valid_o(completion_valid),
    .completion_ready_i(completion_ready),
    .completion_query_match_i(completion_query_match),
    .completion_producer_id_o(completion_pid),
    .completion_data_o(completion_data),
    .completion_error_o(completion_error),
    .completion_error_code_o(completion_error_code),
    .owner_valid_o(owner_valid),
    .serialize_active_o(sidecar_serialize_active),
    .owner_producer_id_o(owner_pid),
    .owner_pc_o(owner_pc),
    .owner_next_pc_o(owner_next_pc),
    .sent_o(sent),
    .cmd_fire_o(cmd_fire),
    .terminal_match_o(terminal_match),
    .completion_fire_o(completion_fire),
    .stale_terminal_drop_o(stale_terminal_drop),
    .stale_completion_drop_o(stale_completion_drop),
    .issued_count_o(issued_count),
    .terminal_count_o(terminal_count),
    .completion_count_o(completion_count),
    .wait_head_cycles_o(wait_head_cycles),
    .wait_drain_cycles_o(wait_drain_cycles),
    .npu_backpressure_cycles_o(npu_backpressure_cycles),
    .serialize_cycles_o(serialize_cycles)
  );

`ifdef CONFIG_NPC_OOO_STATS
  wire [31:0] attribution_sum =
      u_sidecar.attribution_prelaunch_cancel_cycles_q +
      u_sidecar.attribution_wait_not_exact_head_cycles_q +
      u_sidecar.attribution_wait_launch_gate_cycles_q +
      u_sidecar.attribution_wait_src_dependency_cycles_q +
      u_sidecar.attribution_wait_src_value_cycles_q +
      u_sidecar.attribution_wait_mem_active_cycles_q +
      u_sidecar.attribution_wait_mem_retire_cycles_q +
      u_sidecar.attribution_launch_to_offer_cycles_q +
      u_sidecar.attribution_offer_backpressure_cycles_q +
      u_sidecar.attribution_offer_accept_cycles_q +
      u_sidecar.attribution_sent_terminal_absent_cycles_q +
      u_sidecar.attribution_sent_terminal_stale_cycles_q +
      u_sidecar.attribution_sent_terminal_accept_cycles_q +
      u_sidecar.attribution_complete_wb_backpressure_cycles_q +
      u_sidecar.attribution_complete_stale_drop_cycles_q +
      u_sidecar.attribution_complete_wb_accept_cycles_q +
      u_sidecar.attribution_invalid_state_cycles_q +
      u_sidecar.attribution_sent_terminal_completion_stale_cycles_q +
      u_sidecar.attribution_sent_terminal_wb_accept_cycles_q;
`endif

`ifndef TENSOR_SIDECAR_SHARED_READ_FOCUSED
  // Common elaboration with the real NPU command decoder proves that the
  // paired 64-bit payload is the decoder's actual ABI, not a TB-only format.
  TensorNpuCommandDecoder u_npu_decoder (
    .cmd_is_64_i(tensor_is_64),
    .cmd_bits_i(tensor_bits),
    .legal_o(dec_legal),
    .op_o(dec_op),
    .rs_addr_o(dec_rs_addr),
    .imm5_o(dec_imm5),
    .dst_id_o(dec_dst),
    .src0_id_o(dec_src0),
    .src1_id_o(dec_src1),
    .src2_id_o(dec_src2),
    .flags_o(dec_flags),
    .sync_engine_o(dec_sync_engine)
  );
`endif

  task automatic tick;
    begin
      #5 clk = 1'b1;
      #5 clk = 1'b0;
    end
  endtask

  task automatic check(input logic condition, input string message);
    begin
      if (!condition)
        $fatal(1, "[RV64-DIRECT-NPU][FAIL] %s", message);
    end
  endtask

  function automatic [31:0] make_tiu_lo;
    begin
      make_tiu_lo = 32'b0;
      make_tiu_lo[25] = 1'b1;
      make_tiu_lo[19:15] = 5'd3;
      make_tiu_lo[14:12] = 3'b011;
      make_tiu_lo[11:7] = 5'd2;
      make_tiu_lo[6:0] = 7'b1011011;
    end
  endfunction

  function automatic [31:0] make_tiu_hi;
    begin
      make_tiu_hi = 32'b0;
      make_tiu_hi[31:25] = 7'b0000101;
      make_tiu_hi[24:20] = 5'b00101;
      make_tiu_hi[19:15] = 5'd4;
      make_tiu_hi[14:12] = 3'b011;
      make_tiu_hi[11:7] = 5'd1;
      make_tiu_hi[6:0] = 7'b1011011;
    end
  endfunction

  function automatic [31:0] make_single;
    begin
      make_single = 32'b0;
      make_single[31:25] = 7'b0000101;
      make_single[24:20] = 5'b00000;
      make_single[14:12] = 3'b100;
      make_single[6:0] = 7'b1011011;
    end
  endfunction

`ifdef TENSOR_SIDECAR_SHARED_READ_FOCUSED
  task automatic focused_alloc(
    input logic [`OOO_PRODUCER_ID_W-1:0] producer_id,
    input logic [`OOO_PHY_REG_ADDR_W-1:0] source_preg,
    input logic source_dep_ready,
    input logic command_is_64,
    input logic [63:0] command_bits
  );
    begin
      direct_alloc_pid = producer_id;
      direct_alloc_cmd_bits = command_bits;
      direct_alloc_is_64 = command_is_64;
      dispatch_src_preg = source_preg;
      dispatch_src_ready = source_dep_ready;
      rob_head_pid = producer_id;
      direct_alloc_valid = 1'b1;
      #1;
      check(sidecar_alloc_ready, "focused owner was not empty before allocation");
      check(!npu_cmd_valid && !cmd_fire,
            "allocation edge bypassed resident WAIT launch ownership");
      tick();
      direct_alloc_valid = 1'b0;
      #1;
      check(owner_valid && (owner_pid == producer_id),
            "focused allocation lost its full producer identity");
    end
  endtask

  task automatic focused_reset_owner;
    begin
      rst = 1'b1;
      tick();
      rst = 1'b0;
      #1;
      check(!owner_valid && !npu_cmd_valid && !src_read_valid,
            "focused reset left a resident owner/request/offer");
    end
  endtask

  initial begin : tensor_sidecar_shared_read_focused_test
    logic [63:0] held_bits;
    logic [`XLEN-1:0] held_value;
    logic [`OOO_PRODUCER_ID_W-1:0] held_pid;
    integer hold_cycle;

    clk = 1'b0;
    rst = 1'b1;
    flush = 1'b0;
    dispatch_enable = 1'b0;
    dispatch_pid = '0;
    dispatch_src_preg = '0;
    dispatch_src_ready = 1'b0;
    direct_alloc_valid = 1'b0;
    direct_alloc_launch_open = 1'b0;
    direct_alloc_pid = '0;
    direct_alloc_cmd_bits = 64'b0;
    direct_alloc_is_64 = 1'b0;
    direct_alloc_required = 1'b1;
    direct_alloc_opclass = 8'h5a;
    src_read_grant_enable = 1'b0;
    src_read_value = 64'b0;
    wake_valid = 1'b0;
    wake_preg = '0;
    wake_value = 64'b0;
    wake1_valid = 1'b0;
    wake1_preg = '0;
    wake1_value = 64'b0;
    kill_valid = 1'b0;
    kill_pid = '0;
    sidecar_flush = 1'b0;
    rob_head_valid = 1'b1;
    rob_head_pid = '0;
    rob_head_launch_open = 1'b1;
    mem_idle = 1'b1;
    mem_retire_quiet = 1'b1;
    npu_cmd_ready = 1'b0;
    terminal_valid = 1'b0;
    terminal_pid = '0;
    terminal_data = 64'b0;
    terminal_error = 1'b0;
    terminal_error_code = 8'b0;
    completion_ready = 1'b0;
    completion_query_match = 1'b0;

    tick();
    tick();
    rst = 1'b0;
    #1;

    // Edge-old ROB-empty authority allows the allocation itself to expose a
    // zero-source command.  Registered residency begins directly in SENT.
    direct_alloc_launch_open = 1'b1;
    direct_alloc_pid = 8'h61;
    direct_alloc_cmd_bits = 64'h6100_0000_0000_005b;
    direct_alloc_is_64 = 1'b1;
    direct_alloc_valid = 1'b1;
    npu_cmd_ready = 1'b1;
    #1;
    check(sidecar_alloc_ready && !owner_valid && sidecar_serialize_active &&
          npu_cmd_valid && cmd_fire && (npu_cmd_pid == 8'h61) &&
          (npu_cmd_bits == 64'h6100_0000_0000_005b) &&
          (npu_cmd_rs_value == 64'b0),
          "EMPTY allocation did not directly fire its prospective command");
    tick();
    direct_alloc_valid = 1'b0;
    npu_cmd_ready = 1'b0;
    #1;
    check(owner_valid && sent && (owner_pid == 8'h61) &&
          (issued_count == 32'd1),
          "direct allocation fire did not enter SENT exactly once");
`ifdef CONFIG_NPC_OOO_STATS
    check(u_sidecar.alloc_direct_issue_count_q == 32'd1,
          "direct allocation issue event was not counted exactly once");
`endif
    focused_reset_owner();

    // ready is absent from direct valid.  A denied allocation offer must be
    // captured into the existing stable OFFER skid, then fire only once.
    direct_alloc_pid = 8'h62;
    direct_alloc_cmd_bits = 64'h6200_0000_0000_005b;
    direct_alloc_is_64 = 1'b1;
    direct_alloc_valid = 1'b1;
    #1;
    check(sidecar_serialize_active && npu_cmd_valid && !cmd_fire,
          "direct allocation valid incorrectly depended on command ready");
    held_bits = npu_cmd_bits;
    held_pid = npu_cmd_pid;
    tick();
    direct_alloc_valid = 1'b0;
    #1;
    check(owner_valid && npu_cmd_valid && !cmd_fire &&
          (npu_cmd_bits == held_bits) && (npu_cmd_pid == held_pid),
          "denied allocation offer did not enter a stable OFFER skid");
    npu_cmd_ready = 1'b1;
    tick();
    npu_cmd_ready = 1'b0;
    #1;
    check(sent && (issued_count == 32'd1),
          "allocation OFFER skid did not fire exactly once");
`ifdef CONFIG_NPC_OOO_STATS
    check(u_sidecar.alloc_direct_issue_count_q == 32'd0,
          "backpressured allocation was miscounted as a direct issue");
`endif
    focused_reset_owner();

    // BusyTable-ready alone carries no operand value.  Without zero-source or
    // matching WB data, the allocation must retain the WAIT/shared-read path.
    direct_alloc_pid = 8'h63;
    direct_alloc_cmd_bits = 64'h6300_0000_0a03_c05b;
    direct_alloc_is_64 = 1'b0;
    dispatch_src_preg = 6'd19;
    dispatch_src_ready = 1'b1;
    direct_alloc_valid = 1'b1;
    npu_cmd_ready = 1'b1;
    #1;
    check(!u_sidecar.alloc_launch_eligible_w && !npu_cmd_valid && !cmd_fire,
          "dependency-ready allocation used an edge-old PRF value directly");
    tick();
    direct_alloc_valid = 1'b0;
    npu_cmd_ready = 1'b0;
    #1;
    check(owner_valid && !sent && src_read_valid,
          "non-bypassable allocation did not fall back to resident WAIT/read");
    focused_reset_owner();
    direct_alloc_launch_open = 1'b0;
    dispatch_src_preg = '0;
    dispatch_src_ready = 1'b0;
    direct_alloc_is_64 = 1'b0;

    // Dependency readiness and operand-value validity are separate facts.
    // With the shared port denied, the resident request and preg must remain
    // sticky and command launch must remain closed.
    focused_alloc(8'h71, 6'd7, 1'b1, 1'b0,
                  64'h1111_2222_0a02_c05b);
    repeat (3) begin
      check(src_read_valid && (src_read_preg == 6'd7),
            "denied shared read request/preg was not continuously resident");
      check(!npu_cmd_valid,
            "dependency-ready owner offered before operand read grant");
      tick();
      #1;
    end

    // A grant completes the prospective operand and exposes command valid in
    // WAIT immediately.  With ready low the same edge must capture an OFFER
    // skid whose payload is bit-identical across the state boundary.
    src_read_value = 64'h0123_4567_89ab_cdef;
    src_read_grant_enable = 1'b1;
    #1;
    check(src_read_valid && npu_cmd_valid && !cmd_fire &&
          (npu_cmd_rs_value == 64'h0123_4567_89ab_cdef),
          "ready-low WAIT did not expose the granted prospective payload");
    tick();
    src_read_grant_enable = 1'b0;
    #1;
    check(npu_cmd_valid && !src_read_valid,
          "read grant did not capture a stable OFFER skid");
    check(npu_cmd_rs_value == 64'h0123_4567_89ab_cdef,
          "granted PRF value was not captured into command payload");
    held_bits = npu_cmd_bits;
    held_value = npu_cmd_rs_value;
    held_pid = npu_cmd_pid;
    for (hold_cycle = 0; hold_cycle < 3; hold_cycle = hold_cycle + 1) begin
      tick();
      #1;
      check(npu_cmd_valid && (npu_cmd_bits == held_bits) &&
            (npu_cmd_rs_value == held_value) && (npu_cmd_pid == held_pid) &&
            !npu_cmd_is_64 && npu_cmd_required &&
            (npu_cmd_opclass == 8'h5a),
            "OFFER payload changed under multi-cycle command backpressure");
    end
    $display("[TENSOR-SIDECAR-SHARED-READ] denied-hold/grant/offer-backpressure PASS");
    focused_reset_owner();

    // A value already captured at allocation can fire directly from WAIT
    // without visiting OFFER.  Recovery after that fire cannot cancel SENT.
    wake_valid = 1'b1;
    wake_preg = 6'd8;
    wake_value = 64'h0808_0808_0808_0808;
    focused_alloc(8'h70, 6'd8, 1'b0, 1'b0,
                  64'h2020_3030_0a03_c05b);
    wake_valid = 1'b0;
    npu_cmd_ready = 1'b1;
    #1;
    check(npu_cmd_valid && cmd_fire &&
          (npu_cmd_rs_value == 64'h0808_0808_0808_0808),
          "stored operand did not fire directly from WAIT");
    tick();
    npu_cmd_ready = 1'b0;
    #1;
    check(sent && (issued_count == 32'd1),
          "stored WAIT direct fire did not create SENT exactly once");
    kill_valid = 1'b1;
    kill_pid = 8'h70;
    sidecar_flush = 1'b1;
    tick();
    kill_valid = 1'b0;
    sidecar_flush = 1'b0;
    #1;
    check(sent && owner_valid && (owner_pid == 8'h70) &&
          (issued_count == 32'd1),
          "post-fire kill/flush cancelled an irreversible direct launch");
    $display("[TENSOR-SIDECAR-WAIT-FALLTHROUGH] stored-direct-fire/post-fire-noncancel PASS");
    focused_reset_owner();

    // A matching wake is architecturally newer than the stored PRF sample.
    // Prove both inequalities in the required wake1 > wake0 > read order on
    // the same ready-high WAIT edge, not after an OFFER register bubble.
    focused_alloc(8'h72, 6'd9, 1'b1, 1'b0,
                  64'h2222_3333_0a04_c05b);
    src_read_grant_enable = 1'b1;
    src_read_value = 64'h1111_1111_1111_1111;
    wake_valid = 1'b1;
    wake_preg = 6'd9;
    wake_value = 64'h2222_2222_2222_2222;
    npu_cmd_ready = 1'b1;
    #1;
    check(npu_cmd_valid && cmd_fire &&
          (npu_cmd_rs_value == 64'h2222_2222_2222_2222),
          "wake0 did not override a same-cycle read in direct WAIT fire");
    tick();
    src_read_grant_enable = 1'b0;
    wake_valid = 1'b0;
    npu_cmd_ready = 1'b0;
    #1;
    check(sent && (issued_count == 32'd1),
          "wake0/read direct fire did not enter SENT exactly once");
    focused_reset_owner();

    focused_alloc(8'h73, 6'd11, 1'b1, 1'b0,
                  64'h3333_4444_0a05_c05b);
    src_read_grant_enable = 1'b1;
    src_read_value = 64'haaaa_aaaa_aaaa_aaaa;
    wake_valid = 1'b1;
    wake_preg = 6'd11;
    wake_value = 64'hbbbb_bbbb_bbbb_bbbb;
    wake1_valid = 1'b1;
    wake1_preg = 6'd11;
    wake1_value = 64'hcccc_cccc_cccc_cccc;
    npu_cmd_ready = 1'b1;
    #1;
    check(npu_cmd_valid && cmd_fire &&
          (npu_cmd_rs_value == 64'hcccc_cccc_cccc_cccc),
          "wake1 did not override wake0/read in direct WAIT fire");
    tick();
    src_read_grant_enable = 1'b0;
    wake_valid = 1'b0;
    wake1_valid = 1'b0;
    npu_cmd_ready = 1'b0;
    #1;
    check(sent && (issued_count == 32'd1),
          "wake1/wake0/read direct fire did not enter SENT exactly once");
    $display("[TENSOR-SIDECAR-SHARED-READ] wake1>wake0>read direct-fire PASS");
    focused_reset_owner();

    // Cancellation has priority while the shared port is available.  Whether
    // the combinational request is suppressed or merely loses at the edge,
    // no operand capture/OFFER/resident payload may survive cancellation.
    focused_alloc(8'h74, 6'd13, 1'b1, 1'b0,
                  64'h4444_5555_0a06_c05b);
    src_read_grant_enable = 1'b1;
    src_read_value = 64'hdddd_dddd_dddd_dddd;
    kill_valid = 1'b1;
    kill_pid = 8'h74;
    tick();
    src_read_grant_enable = 1'b0;
    kill_valid = 1'b0;
    #1;
    check(!owner_valid && !npu_cmd_valid && !src_read_valid &&
          !u_sidecar.src_dep_ready_q && !u_sidecar.src_operand_valid_q &&
          (u_sidecar.src_value_q == 64'b0),
          "same-cycle kill with port available left OFFER or operand residue");

    focused_alloc(8'h75, 6'd14, 1'b1, 1'b0,
                  64'h5555_6666_0a07_c05b);
    src_read_grant_enable = 1'b1;
    src_read_value = 64'heeee_eeee_eeee_eeee;
    sidecar_flush = 1'b1;
    tick();
    src_read_grant_enable = 1'b0;
    sidecar_flush = 1'b0;
    #1;
    check(!owner_valid && !npu_cmd_valid && !src_read_valid &&
          !u_sidecar.src_dep_ready_q && !u_sidecar.src_operand_valid_q &&
          (u_sidecar.src_value_q == 64'b0),
          "same-cycle flush with port available left OFFER or operand residue");
    $display("[TENSOR-SIDECAR-SHARED-READ] kill/flush-port-available PASS");

    // Once OFFER exists, cancellation must also gate valid combinationally.
    // This is the dangerous ready=1 cross: an external command fire followed
    // by an internal owner clear would otherwise lose an irreversible launch.
    focused_alloc(8'h78, 6'd16, 1'b1, 1'b0,
                  64'h7777_8888_0a08_c05b);
    src_read_grant_enable = 1'b1;
    src_read_value = 64'h0123_0123_0123_0123;
    tick();
    src_read_grant_enable = 1'b0;
    #1;
    check(npu_cmd_valid, "kill/ready probe did not first reach OFFER");
    npu_cmd_ready = 1'b1;
    kill_valid = 1'b1;
    kill_pid = 8'h78;
    #1;
    check(!npu_cmd_valid && !cmd_fire,
          "same-cycle kill/command-ready escaped as an external fire");
    tick();
    npu_cmd_ready = 1'b0;
    kill_valid = 1'b0;
    #1;
    check(!owner_valid && !npu_cmd_valid && !sent &&
          (issued_count == 0) && !u_sidecar.src_operand_valid_q &&
          (u_sidecar.src_value_q == 64'b0),
          "kill/command-ready left an OFFER, SENT owner, or operand residue");

    focused_alloc(8'h79, 6'd17, 1'b1, 1'b0,
                  64'h8888_9999_0a09_c05b);
    src_read_grant_enable = 1'b1;
    src_read_value = 64'h4567_4567_4567_4567;
    tick();
    src_read_grant_enable = 1'b0;
    #1;
    check(npu_cmd_valid, "flush/ready probe did not first reach OFFER");
    npu_cmd_ready = 1'b1;
    sidecar_flush = 1'b1;
    #1;
    check(!npu_cmd_valid && !cmd_fire,
          "same-cycle flush/command-ready escaped as an external fire");
    tick();
    npu_cmd_ready = 1'b0;
    sidecar_flush = 1'b0;
    #1;
    check(!owner_valid && !npu_cmd_valid && !sent &&
          (issued_count == 0) && !u_sidecar.src_operand_valid_q &&
          (u_sidecar.src_value_q == 64'b0),
          "flush/command-ready left an OFFER, SENT owner, or operand residue");
    $display("[TENSOR-SIDECAR-SHARED-READ] cancel+cmd-ready-no-fire PASS");

    // Exercise the new WAIT fall-through itself at the cancellation cross.
    // The architectural launch predicates remain true, but kill/flush must
    // gate valid before a ready-high consumer can observe a fire.
    focused_alloc(8'h7a, 6'd0, 1'b0, 1'b0,
                  64'h9999_aaaa_0a0a_405b);
    npu_cmd_ready = 1'b1;
    kill_valid = 1'b1;
    kill_pid = 8'h7a;
    #1;
    check(u_sidecar.launch_eligible_now_w && !npu_cmd_valid && !cmd_fire,
          "WAIT kill+ready escaped direct-fire cancellation priority");
    tick();
    npu_cmd_ready = 1'b0;
    kill_valid = 1'b0;
    #1;
    check(!owner_valid && (issued_count == 32'd0),
          "WAIT kill+ready created an irreversible command");

    focused_alloc(8'h7b, 6'd0, 1'b0, 1'b0,
                  64'haaaa_bbbb_0a0b_405b);
    npu_cmd_ready = 1'b1;
    sidecar_flush = 1'b1;
    #1;
    check(u_sidecar.launch_eligible_now_w && !npu_cmd_valid && !cmd_fire,
          "WAIT flush+ready escaped direct-fire cancellation priority");
    tick();
    npu_cmd_ready = 1'b0;
    sidecar_flush = 1'b0;
    #1;
    check(!owner_valid && (issued_count == 32'd0),
          "WAIT flush+ready created an irreversible command");
    $display("[TENSOR-SIDECAR-WAIT-FALLTHROUGH] WAIT-cancel+ready-no-fire PASS");

    // Paired 64-bit commands and architectural x0 have no scalar operand.
    // They must never reserve read8 and must expose an exact zero payload.
    focused_alloc(8'h76, 6'd15, 1'b0, 1'b1,
                  64'h89ab_cdef_0123_4567);
    npu_cmd_ready = 1'b1;
    #1;
    check(!src_read_valid && npu_cmd_valid && cmd_fire &&
          npu_cmd_is_64 && (npu_cmd_rs_value == 64'b0),
          "64-bit command did not directly fire with a zero scalar value");
    tick();
    npu_cmd_ready = 1'b0;
    #1;
    check(sent && (issued_count == 32'd1),
          "64-bit WAIT direct fire did not enter SENT exactly once");
    focused_reset_owner();

    focused_alloc(8'h77, 6'd0, 1'b0, 1'b0,
                  64'h0000_0000_0a00_405b);
    check(!src_read_valid && npu_cmd_valid && !cmd_fire &&
          (npu_cmd_rs_value == 64'b0),
          "x0 Tensor source did not expose the ready-low WAIT skid payload");
    tick();
    #1;
    check(npu_cmd_valid && !npu_cmd_is_64 && !src_read_valid &&
          (npu_cmd_rs_value == 64'b0),
          "x0 Tensor command did not offer with an exact zero value");
    focused_reset_owner();
    $display("[TENSOR-SIDECAR-SHARED-READ] no-read 64-bit/x0 PASS");

    check(issued_count == 0 && terminal_count == 0 &&
          completion_count == 0,
          "prelaunch-only focused test changed irreversible counters");

`ifdef CONFIG_NPC_OOO_STATS
    // Freeze the one-hot, pre-edge attribution contract with a compact
    // deterministic walk.  The first owner proves first-blocker priority and
    // cancellation; the second visits every normal/stale wait boundary; the
    // third completes through the exact WB path.
    focused_alloc(8'h81, 6'd21, 1'b0, 1'b0,
                  64'h8100_0000_0a10_c05b);
    rob_head_valid = 1'b0;
    tick();
    rob_head_valid = 1'b1;
    tick();
    kill_valid = 1'b1;
    kill_pid = 8'h81;
    tick();
    kill_valid = 1'b0;
    #1;
    check(!owner_valid, "attribution dependency owner did not cancel");

    focused_alloc(8'h82, 6'd22, 1'b1, 1'b0,
                  64'h8200_0000_0a11_c05b);
    rob_head_launch_open = 1'b0;
    tick();
    rob_head_launch_open = 1'b1;
    tick();
    src_read_value = 64'h8282_8282_8282_8282;
    src_read_grant_enable = 1'b1;
    mem_idle = 1'b0;
    mem_retire_quiet = 1'b0;
    tick();
    src_read_grant_enable = 1'b0;
    mem_idle = 1'b1;
    tick();
    mem_retire_quiet = 1'b1;
    tick();
    #1;
    check(npu_cmd_valid, "attribution owner did not reach OFFER");
    tick();
    npu_cmd_ready = 1'b1;
    tick();
    npu_cmd_ready = 1'b0;
    #1;
    check(sent, "attribution command accept did not reach SENT");
    tick();
    terminal_valid = 1'b1;
    terminal_pid = 8'h92;
    tick();
    terminal_pid = 8'h82;
    tick();
    terminal_valid = 1'b0;
    #1;
    check(completion_valid,
          "attribution exact terminal did not reach COMPLETE");
    tick();
    completion_ready = 1'b1;
    completion_query_match = 1'b0;
    tick();
    completion_ready = 1'b0;
    #1;
    check(!owner_valid && stale_completion_drop,
          "attribution stale completion did not drain the owner");

    mem_idle = 1'b1;
    mem_retire_quiet = 1'b1;
    focused_alloc(8'h83, 6'd0, 1'b0, 1'b0,
                  64'h8300_0000_0a00_405b);
    npu_cmd_ready = 1'b1;
    terminal_valid = 1'b1;
    terminal_pid = 8'h83;
    #1;
    check(npu_cmd_valid && cmd_fire && !terminal_ready,
          "direct WAIT fire incorrectly accepted a same-edge terminal");
    tick();
    npu_cmd_ready = 1'b0;
    #1;
    completion_ready = 1'b1;
    completion_query_match = 1'b1;
    #1;
    check(sent && terminal_ready && terminal_match && completion_valid &&
          completion_fire,
          "exact terminal did not fall through to a ready WB completion");
    tick();
    terminal_valid = 1'b0;
    completion_ready = 1'b0;
    completion_query_match = 1'b0;
    #1;
    check(!owner_valid && !completion_valid &&
          (terminal_count == 32'd2) && (completion_count == 32'd1),
          "direct terminal/WB fall-through did not complete and clear exactly once");

    // A full-id terminal whose ROB generation is no longer live is also a
    // legal completion handshake (ready is the stale-drain arm), but it must
    // clear without a WB fire or architectural completion count.
    focused_alloc(8'h84, 6'd0, 1'b0, 1'b0,
                  64'h8400_0000_0a00_405b);
    npu_cmd_ready = 1'b1;
    tick();
    npu_cmd_ready = 1'b0;
    terminal_valid = 1'b1;
    terminal_pid = 8'h84;
    terminal_data = 64'h8484_8484_8484_8484;
    completion_ready = 1'b1;
    completion_query_match = 1'b0;
    #1;
    check(sent && terminal_match && completion_valid && !completion_fire,
          "direct stale completion did not expose a non-WB handshake");
    tick();
    terminal_valid = 1'b0;
    completion_ready = 1'b0;
    #1;
    check(!owner_valid && stale_completion_drop &&
          (terminal_count == 32'd3) && (completion_count == 32'd1),
          "direct stale completion did not drop and clear exactly once");

    check(u_sidecar.attribution_prelaunch_cancel_cycles_q == 32'd1,
          "prelaunch-cancel attribution mismatch");
    check(u_sidecar.attribution_wait_not_exact_head_cycles_q == 32'd1,
          "not-exact-head attribution mismatch");
    check(u_sidecar.attribution_wait_launch_gate_cycles_q == 32'd1,
          "launch-gate attribution mismatch");
    check(u_sidecar.attribution_wait_src_dependency_cycles_q == 32'd1,
          "source-dependency attribution mismatch");
    check(u_sidecar.attribution_wait_src_value_cycles_q == 32'd1,
          "source-value attribution mismatch");
    check(u_sidecar.attribution_wait_mem_active_cycles_q == 32'd1,
          "memory-active attribution mismatch");
    check(u_sidecar.attribution_wait_mem_retire_cycles_q == 32'd1,
          "memory-retire attribution mismatch");
    check(u_sidecar.attribution_launch_to_offer_cycles_q == 32'd1,
          "launch-to-offer attribution mismatch");
    check(u_sidecar.attribution_offer_backpressure_cycles_q == 32'd1,
          "offer-backpressure attribution mismatch");
    check(u_sidecar.attribution_offer_accept_cycles_q == 32'd3,
          "offer-accept attribution mismatch");
    check(u_sidecar.attribution_sent_terminal_absent_cycles_q == 32'd1,
          "terminal-absent attribution mismatch");
    check(u_sidecar.attribution_sent_terminal_stale_cycles_q == 32'd1,
          "terminal-stale attribution mismatch");
    check(u_sidecar.attribution_sent_terminal_accept_cycles_q == 32'd1,
          "terminal-fallback attribution mismatch");
    check(u_sidecar.attribution_complete_wb_backpressure_cycles_q == 32'd1,
          "completion-backpressure attribution mismatch");
    check(u_sidecar.attribution_complete_stale_drop_cycles_q == 32'd1,
          "completion-stale attribution mismatch");
    check(u_sidecar.attribution_complete_wb_accept_cycles_q == 32'd0,
          "resident completion-accept attribution mismatch");
    check(u_sidecar.attribution_sent_terminal_completion_stale_cycles_q ==
          32'd1,
          "direct terminal stale-completion attribution mismatch");
    check(u_sidecar.attribution_sent_terminal_wb_accept_cycles_q == 32'd1,
          "direct terminal/WB attribution mismatch");
    check(u_sidecar.attribution_invalid_state_cycles_q == 32'd0,
          "invalid-state attribution was nonzero");
    check(npu_backpressure_cycles ==
          (u_sidecar.attribution_launch_to_offer_cycles_q +
           u_sidecar.attribution_offer_backpressure_cycles_q),
          "legacy command backpressure did not equal WAIT-skid plus OFFER stalls");
    check((attribution_sum == 32'd19) &&
          (attribution_sum == serialize_cycles),
          "one-hot attribution did not conserve serialize cycles");
    check((issued_count == 32'd3) && (terminal_count == 32'd3) &&
          (completion_count == 32'd1),
          "attribution accept counters disagree with lifecycle counters");
    $display("[TENSOR-SIDECAR-ATTRIBUTION] one-hot all-buckets sum=%0d serialize=%0d PASS",
             attribution_sum, serialize_cycles);
`endif
    $display("[TENSOR-SIDECAR-SHARED-READ][PASS]");
    $display("[PASS] tb_ooo_direct_npu_slice_tensor_shared_read");
    $finish;
  end
`else
  initial begin
    logic [63:0] held_cmd_bits;
    logic [`XLEN-1:0] held_rs_value;
    logic [`XLEN-1:0] held_residual_pc;
    logic [`INST_W-1:0] held_residual_inst;

    clk = 1'b0;
    rst = 1'b1;
    flush = 1'b0;
    head_valid = 1'b0;
    head_slot1_valid = 1'b0;
    head_pc0 = 64'b0;
    head_inst0 = 32'b0;
    head_resp0 = 2'b0;
    head_pc1 = 64'b0;
    head_inst1 = 32'b0;
    head_resp1 = 2'b0;
    head_fault_tval = 64'b0;
    normal_lane0_fire = 1'b0;
    residual_ready = 1'b0;
    pair_error_ready = 1'b0;
    dispatch_enable = 1'b0;
    dispatch_pid = 8'h31;
    dispatch_src_preg = 6'd7;
    dispatch_src_ready = 1'b0;
    src_read_grant_enable = 1'b1;
    src_read_value = 64'b0;
    direct_alloc_valid = 1'b0;
    direct_alloc_pid = 8'b0;
    direct_alloc_cmd_bits = 64'h0000_0000_0000_005b;
    direct_alloc_is_64 = 1'b0;
    direct_alloc_required = 1'b0;
    direct_alloc_opclass = 8'b0;
    wake_valid = 1'b0;
    wake_preg = 6'b0;
    wake_value = 64'b0;
    wake1_valid = 1'b0;
    wake1_preg = 6'b0;
    wake1_value = 64'b0;
    kill_valid = 1'b0;
    kill_pid = 8'b0;
    sidecar_flush = 1'b0;
    rob_head_valid = 1'b0;
    rob_head_pid = 8'b0;
    rob_head_launch_open = 1'b0;
    mem_idle = 1'b0;
    mem_retire_quiet = 1'b0;
    npu_cmd_ready = 1'b0;
    terminal_valid = 1'b0;
    terminal_pid = 8'b0;
    terminal_data = 64'b0;
    terminal_error = 1'b0;
    terminal_error_code = 8'b0;
    completion_ready = 1'b0;
    completion_query_match = 1'b0;

    tick();
    tick();
    rst = 1'b0;

    // Same-packet LO/HI becomes one logical command and one FIFO pop.
    head_valid = 1'b1;
    head_slot1_valid = 1'b1;
    head_pc0 = 64'h1000;
    head_pc1 = 64'h1004;
    head_inst0 = make_tiu_lo();
    head_inst1 = make_tiu_hi();
    #1;
    check(head0_claim && head_pop, "same-packet pair was not exclusively claimed");
    tick();
    head_valid = 1'b0;
    check(tensor_valid && tensor_is_64 && tensor_required,
          "same-packet pair did not create required 64-bit command");
    check(tensor_pc == 64'h1000 && tensor_next_pc == 64'h1008,
          "pair PC/next-PC identity is not one logical 8-byte instruction");
    check(tensor_bits == {make_tiu_hi(), make_tiu_lo()},
          "LO/HI command order changed");
    check(dec_legal && (dec_op == `NPU_OP_MM2_NN),
          "real NPU decoder rejected paired MM2 command");

    // Pair owner payload must be sticky before logical dispatch.
    held_cmd_bits = tensor_bits;
    tick();
    tick();
    check(tensor_valid && (tensor_bits == held_cmd_bits),
          "pair payload changed under dispatch backpressure");

    // Logical dispatch allocates exactly one full-PID sidecar.
    dispatch_enable = 1'b1;
    tick();
    dispatch_enable = 1'b0;
    check(!tensor_valid && owner_valid && (owner_pid == 8'h31),
          "logical dispatch did not transfer exactly one owner");
    check(owner_pc == 64'h1000 && owner_next_pc == 64'h1008,
          "sidecar lost logical instruction PC identity");

    // Wrong head cannot launch.  Exact head with undrained memory cannot
    // launch either, while both conditions are attributed by counters.
    tick();
    tick();
    rob_head_valid = 1'b1;
    rob_head_pid = 8'h31;
    rob_head_launch_open = 1'b1;
    tick();
    tick();
    check(!npu_cmd_valid && (issued_count == 0),
          "command launched before source/memory eligibility");

    // Wakeup fills the resident source value; memory drain then creates a
    // sticky OFFER.  NPU backpressure must not change any payload field.
    wake_valid = 1'b1;
    wake_preg = 6'd7;
    wake_value = 64'h0123_4567_89ab_cdef;
    tick();
    wake_valid = 1'b0;
    mem_idle = 1'b1;
    mem_retire_quiet = 1'b1;
    tick();
    check(npu_cmd_valid, "eligible exact-head owner did not enter command offer");
    held_cmd_bits = npu_cmd_bits;
    held_rs_value = npu_cmd_rs_value;
    tick();
    tick();
    check(npu_cmd_valid && (npu_cmd_pid == 8'h31) &&
          (npu_cmd_bits == held_cmd_bits) &&
          (npu_cmd_rs_value == held_rs_value),
          "NPU command payload/PID changed under ready backpressure");

    npu_cmd_ready = 1'b1;
    #1;
    check(cmd_fire, "command fire was not visible at ready-valid intersection");
    tick();
    npu_cmd_ready = 1'b0;
    check(sent && (issued_count == 1),
          "command fire did not create non-cancellable sent owner");

    kill_valid = 1'b1;
    kill_pid = 8'h31;
    tick();
    kill_valid = 1'b0;
    check(sent && owner_valid && (issued_count == 1),
          "post-launch recovery cancelled an irreversible owner");

    // A same-index/different-generation terminal is drained only.  It cannot
    // advance completion or clear the live owner.
    terminal_valid = 1'b1;
    terminal_pid = 8'h21;
    terminal_data = 64'hbad0_bad0_bad0_bad0;
    #1;
    check(terminal_ready, "sent owner did not drain stale terminal");
    tick();
    terminal_valid = 1'b0;
    check(stale_terminal_drop && sent && !completion_valid,
          "stale full-PID terminal escaped exact identity check");
    tick();

    terminal_valid = 1'b1;
    terminal_pid = 8'h31;
    terminal_data = 64'hfeed_face_cafe_beef;
    tick();
    terminal_valid = 1'b0;
    check(completion_valid && (completion_pid == 8'h31) &&
          (completion_data == 64'hfeed_face_cafe_beef) && !completion_error,
          "matching terminal did not create exact completion holder");
    check(completion_error_code == 8'b0,
          "successful terminal created a nonzero NPU error code");

    // Completion payload remains resident under WB backpressure.
    tick();
    tick();
    check(completion_valid && (completion_data == 64'hfeed_face_cafe_beef),
          "completion holder changed under WB backpressure");
    completion_query_match = 1'b1;
    completion_ready = 1'b1;
    #1;
    check(completion_fire, "exact completion was not accepted");
    tick();
    completion_ready = 1'b0;
    completion_query_match = 1'b0;
    check(!owner_valid && (issued_count == 1) &&
          (terminal_count == 1) && (completion_count == 1),
          "completed owner/counters did not retire exactly once");

    // Cross-packet form: ordinary lane0 consumes alone, lane1 LO becomes the
    // only pending pair owner, and next-packet slot1 survives as residual.
    head_valid = 1'b1;
    head_slot1_valid = 1'b1;
    head_pc0 = 64'h2000;
    head_inst0 = 32'h0010_0093;
    head_pc1 = 64'h2004;
    head_inst1 = make_tiu_lo();
    normal_lane0_fire = 1'b1;
    #1;
    check(!head0_claim && head1_claim && head_pop,
          "lane1 LO did not force ordinary lane0-only capture");
    tick();
    normal_lane0_fire = 1'b0;
    check(pair_pending, "cross-packet LO lost pending owner");

    head_pc0 = 64'h2008;
    head_inst0 = make_tiu_hi();
    head_pc1 = 64'h200c;
    head_inst1 = 32'h0020_0113;
    #1;
    check(head0_claim && head_pop, "cross-packet HI was not atomically claimed");
    tick();
    head_valid = 1'b0;
    check(tensor_valid && tensor_cross_packet && residual_valid,
          "cross-packet command/residual were not both retained");
    check(tensor_pc == 64'h2004 && tensor_next_pc == 64'h200c,
          "cross-packet logical PC identity is incorrect");
    check(residual_pc == 64'h200c && residual_inst == 32'h0020_0113,
          "post-HI residual was lost or changed");
    held_residual_pc = residual_pc;
    held_residual_inst = residual_inst;
    tick();
    check(residual_valid && (residual_pc == held_residual_pc) &&
          (residual_inst == held_residual_inst),
          "post-HI residual changed under backpressure");
    residual_ready = 1'b1;
    tick();
    residual_ready = 1'b0;
    flush = 1'b1;
    tick();
    flush = 1'b0;
    check(!tensor_valid && !residual_valid && !pair_pending,
          "flush did not clear pre-dispatch pair ownership");

    // Single-word Tensor control also creates exactly one logical command;
    // the following slot is held as residual rather than becoming a second
    // command or being dropped.
    head_valid = 1'b1;
    head_slot1_valid = 1'b1;
    head_pc0 = 64'h2800;
    head_inst0 = make_single();
    head_resp0 = 2'b00;
    head_pc1 = 64'h2804;
    head_inst1 = 32'h0050_0293;
    head_resp1 = 2'b00;
    #1;
    check(head0_claim && head_pop, "single-word Tensor control was not claimed");
    tick();
    head_valid = 1'b0;
    check(tensor_valid && !tensor_is_64 && !tensor_required && residual_valid,
          "single-word command/residual identity is incorrect");
    check(dec_legal, "real NPU decoder rejected single-word config command");
    flush = 1'b1;
    tick();
    flush = 1'b0;

    // LO mismatch reports the saved LO but does not pop/lose the following
    // packet.  No command or offload counter may change.
    head_valid = 1'b1;
    head_slot1_valid = 1'b0;
    head_pc0 = 64'h3000;
    head_inst0 = make_tiu_lo();
    #1;
    check(head0_claim && head_pop, "tail LO was not captured");
    tick();
    head_slot1_valid = 1'b1;
    head_pc0 = 64'h3004;
    head_inst0 = 32'h0030_0193;
    head_pc1 = 64'h3008;
    head_inst1 = 32'h0040_0213;
    #1;
    check(head0_claim && !head_pop, "mismatch consumed the following packet");
    tick();
    check(pair_error_valid && (pair_error_code == 2'd1) &&
          (pair_error_cause == `EXC_ILLEGAL_INST) &&
          (pair_error_pc == 64'h3000) &&
          (pair_error_tval == {32'b0, make_tiu_lo()}) && !tensor_valid &&
          (issued_count == 1),
          "mismatch did not fail closed on the LO owner");
    check(!head_pop, "mismatch packet was popped while error held");
    pair_error_ready = 1'b1;
    tick();
    pair_error_ready = 1'b0;
    head_valid = 1'b0;

    // Same-packet mismatch owns and pops the packet, but keeps slot1 only as
    // a younger residual shadow.  The typed trap handoff must release both
    // holders atomically; software will refetch slot1 after returning.
    head_valid = 1'b1;
    head_slot1_valid = 1'b1;
    head_pc0 = 64'h3400;
    head_pc1 = 64'h3404;
    head_inst0 = make_tiu_lo();
    head_inst1 = 32'h0060_0313;
    head_resp0 = 2'b00;
    head_resp1 = 2'b00;
    #1;
    check(head0_claim && head_pop,
          "same-packet mismatch was not exclusively consumed");
    tick();
    head_valid = 1'b0;
    check(pair_error_valid && residual_valid &&
          (pair_error_cause == `EXC_ILLEGAL_INST) &&
          (pair_error_pc == 64'h3400) &&
          (pair_error_tval == {32'b0, make_tiu_lo()}),
          "same-packet mismatch lost typed payload or residual shadow");
    held_residual_pc = residual_pc;
    held_residual_inst = residual_inst;
    tick();
    check(pair_error_valid && residual_valid &&
          (residual_pc == held_residual_pc) &&
          (residual_inst == held_residual_inst),
          "same-packet mismatch payload changed before trap handoff");
    pair_error_ready = 1'b1;
    tick();
    pair_error_ready = 1'b0;
    check(!pair_error_valid && !residual_valid,
          "typed pair-trap handoff did not atomically release residual");

    // A same-packet HI access fault carries the precise fetch frontier, not
    // the saved LO instruction bits, and maps to instruction access fault.
    head_valid = 1'b1;
    head_slot1_valid = 1'b1;
    head_pc0 = 64'h3600;
    head_pc1 = 64'h3604;
    head_inst0 = make_tiu_lo();
    head_inst1 = 32'hffff_ffff;
    head_resp0 = 2'b00;
    head_resp1 = 2'b01;
    head_fault_tval = 64'h0000_0000_0000_3606;
    #1;
    check(head0_claim && head_pop,
          "same-packet pair access fault was not owned");
    tick();
    head_valid = 1'b0;
    check(pair_error_valid && (pair_error_code == 2'd2) &&
          (pair_error_cause == `EXC_INST_ACCESS_FAULT) &&
          (pair_error_pc == 64'h3600) &&
          (pair_error_tval == 64'h0000_0000_0000_3606),
          "same-packet pair access fault lost precise typed payload");
    pair_error_ready = 1'b1;
    tick();
    pair_error_ready = 1'b0;
    head_resp1 = 2'b00;
    head_fault_tval = 64'b0;

    // An exact adjacent fetch fault is consumed into the saved LO error owner,
    // never emitted as a partial command.
    head_valid = 1'b1;
    head_slot1_valid = 1'b0;
    head_pc0 = 64'h3800;
    head_inst0 = make_tiu_lo();
    head_resp0 = 2'b00;
    #1;
    check(head_pop, "fault-case LO was not captured");
    tick();
    head_pc0 = 64'h3804;
    head_inst0 = 32'hffff_ffff;
    head_resp0 = 2'b10;
    head_fault_tval = 64'h0000_0000_0000_3806;
    #1;
    check(head0_claim && head_pop, "adjacent pair fetch fault was not owned");
    tick();
    check(pair_error_valid && (pair_error_code == 2'd2) &&
          (pair_error_cause == `EXC_INST_PAGE_FAULT) &&
          (pair_error_pc == 64'h3800) &&
          (pair_error_tval == 64'h0000_0000_0000_3806) && !tensor_valid &&
          (issued_count == 1),
          "pair fetch fault did not fail closed before command issue");
    pair_error_ready = 1'b1;
    tick();
    pair_error_ready = 1'b0;
    head_valid = 1'b0;
    head_resp0 = 2'b00;
    head_fault_tval = 64'b0;

    // Full-id prelaunch kill: same ROB index with wrong generation cannot kill;
    // exact generation can.  No second command is issued.
    direct_alloc_valid = 1'b1;
    direct_alloc_pid = 8'h42;
    dispatch_src_ready = 1'b1;
    src_read_value = 64'h55aa;
    tick();
    direct_alloc_valid = 1'b0;
    check(owner_valid && (owner_pid == 8'h42),
          "direct sidecar setup allocation failed");
    kill_valid = 1'b1;
    kill_pid = 8'h32;
    tick();
    check(owner_valid, "wrong-generation kill cleared live owner");
    kill_pid = 8'h42;
    tick();
    kill_valid = 1'b0;
    check(!owner_valid && (issued_count == 1),
          "exact prelaunch kill did not clear without side effect");

    // The same clear priority holds after a sticky command offer has formed
    // but before cmd_ready creates the irreversible launch fire.
    direct_alloc_valid = 1'b1;
    direct_alloc_pid = 8'h43;
    tick();
    direct_alloc_valid = 1'b0;
    rob_head_valid = 1'b1;
    rob_head_pid = 8'h43;
    rob_head_launch_open = 1'b1;
    mem_idle = 1'b1;
    mem_retire_quiet = 1'b1;
    tick();
    check(npu_cmd_valid && !cmd_fire,
          "second owner did not reach prelaunch backpressured offer");
    kill_valid = 1'b1;
    kill_pid = 8'h43;
    tick();
    kill_valid = 1'b0;
    check(!owner_valid && !npu_cmd_valid && (issued_count == 1),
          "prelaunch kill failed to cancel sticky offer without fire");

    // BusyTable reports a matching same-cycle WB as ready, but the PRF read
    // still contains the pre-edge value.  Allocation must capture the WB
    // payload rather than blessing that stale PRF value as ready.
    direct_alloc_valid = 1'b1;
    direct_alloc_pid = 8'h44;
    dispatch_src_preg = 6'd9;
    dispatch_src_ready = 1'b1;
    src_read_value = 64'hdead_dead_dead_dead;
    wake_valid = 1'b1;
    wake_preg = 6'd9;
    wake_value = 64'h0123_89ab_4567_cdef;
    tick();
    direct_alloc_valid = 1'b0;
    wake_valid = 1'b0;
    rob_head_pid = 8'h44;
    tick();
    check(npu_cmd_valid &&
          (npu_cmd_rs_value == 64'h0123_89ab_4567_cdef),
          "same-cycle allocation/wakeup captured stale PRF source data");
    kill_valid = 1'b1;
    kill_pid = 8'h44;
    tick();
    kill_valid = 1'b0;
    check(!owner_valid && !npu_cmd_valid && (issued_count == 1),
          "same-cycle wakeup probe owner did not cancel before launch");

    check(wait_head_cycles >= 2, "wait-head counter did not observe head blocking");
    check(wait_drain_cycles >= 2, "wait-drain counter did not observe memory blocking");
    check(npu_backpressure_cycles >= 2,
          "NPU backpressure counter did not observe ready stall");
    check(serialize_cycles > 0, "serialization cycle counter remained zero");
`ifdef CONFIG_NPC_OOO_STATS
    check(attribution_sum == serialize_cycles,
          "one-hot attribution sum diverged from serialize cycles");
    check(u_sidecar.attribution_invalid_state_cycles_q == 32'd0,
          "normal direct slice observed invalid-state attribution");
    $display("[RV64-DIRECT-NPU-ATTR] cancel=%0d not_head=%0d launch_gate=%0d src_dep=%0d src_value=%0d mem_active=%0d mem_retire=%0d launch=%0d offer_bp=%0d offer_accept=%0d terminal_absent=%0d terminal_stale=%0d terminal_fallback=%0d wb_bp=%0d wb_stale=%0d wb_accept=%0d direct_stale=%0d direct_wb=%0d invalid=%0d sum=%0d",
             u_sidecar.attribution_prelaunch_cancel_cycles_q,
             u_sidecar.attribution_wait_not_exact_head_cycles_q,
             u_sidecar.attribution_wait_launch_gate_cycles_q,
             u_sidecar.attribution_wait_src_dependency_cycles_q,
             u_sidecar.attribution_wait_src_value_cycles_q,
             u_sidecar.attribution_wait_mem_active_cycles_q,
             u_sidecar.attribution_wait_mem_retire_cycles_q,
             u_sidecar.attribution_launch_to_offer_cycles_q,
             u_sidecar.attribution_offer_backpressure_cycles_q,
             u_sidecar.attribution_offer_accept_cycles_q,
             u_sidecar.attribution_sent_terminal_absent_cycles_q,
             u_sidecar.attribution_sent_terminal_stale_cycles_q,
             u_sidecar.attribution_sent_terminal_accept_cycles_q,
             u_sidecar.attribution_complete_wb_backpressure_cycles_q,
             u_sidecar.attribution_complete_stale_drop_cycles_q,
             u_sidecar.attribution_complete_wb_accept_cycles_q,
             u_sidecar.attribution_sent_terminal_completion_stale_cycles_q,
             u_sidecar.attribution_sent_terminal_wb_accept_cycles_q,
             u_sidecar.attribution_invalid_state_cycles_q,
             attribution_sum);
`endif

    $display("[RV64-DIRECT-NPU][PASS] issued=%0d terminal=%0d completion=%0d wait_head=%0d wait_drain=%0d npu_backpressure=%0d serialize=%0d",
             issued_count, terminal_count, completion_count,
             wait_head_cycles, wait_drain_cycles,
             npu_backpressure_cycles, serialize_cycles);
    $finish;
  end
`endif
endmodule
