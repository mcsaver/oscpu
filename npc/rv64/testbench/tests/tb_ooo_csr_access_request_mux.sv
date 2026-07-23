`include "include/define.v"

module tb_ooo_csr_access_request_mux;
  localparam ROB_INDEX_W = `OOO_ROB_INDEX_W;
  localparam PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W;
  localparam PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W;
  localparam [PRODUCER_ID_W-1:0] PID_A = {PRODUCER_ID_W{1'b0}};
  localparam [PRODUCER_ID_W-1:0] PID_STALE_GEN =
      {1'b1, {(PRODUCER_ID_W-1){1'b0}}};

  reg core_commit0_valid_i;
  reg core_commit0_exception_i;
  reg [`XLEN-1:0] core_commit0_pc_i;
  reg [`INST_W-1:0] core_commit0_inst_i;
  reg [PRODUCER_ID_W-1:0] core_commit0_producer_id_i;
  reg pending_system_i;
  reg pending_system_csr_i;
  reg pending_system_dispatched_i;
  reg pending_system_sfence_i;
  reg [`XLEN-1:0] pending_system_pc_i;
  reg [`INST_W-1:0] pending_system_inst_i;
  reg pending_system_producer_valid_i;
  reg [PRODUCER_ID_W-1:0] pending_system_producer_id_i;
  reg dispatch_valid_i;
  reg dispatch0_system_i;
  reg dispatch1_barrier_i;
  reg head0_csr_raw_i;
  reg head1_csr_raw_i;
  reg [`INST_W-1:0] head_inst0_i;
  reg [`INST_W-1:0] head_inst1_i;
  reg stop_pending_i;
  reg drain_complete_i;
  reg [`XLEN * `REG_NUM - 1:0] debug_gprs_i;

  wire core_commit0_csr_o;
  wire pending_system_csr_commit_o;
  wire head0_csr_commit_o;
  wire head1_csr_probe_o;
  wire csr_access_valid_o;
  wire [`INST_W-1:0] csr_access_inst_o;
  wire [11:0] csr_access_addr_o;
  wire [2:0] csr_access_funct3_o;
  wire [`REG_ADDR_W-1:0] csr_access_rs1_idx_o;
  wire [`XLEN-1:0] csr_access_rs1_data_o;
  wire csr_access_set_clear_noop_o;
  wire csr_access_need_write_o;
  wire csr_probe_valid_o;
  wire [11:0] csr_probe_addr_o;
  wire [2:0] csr_probe_funct3_o;
  wire [`REG_ADDR_W-1:0] csr_probe_rs1_idx_o;
  wire pending_system_satp_write_commit_o;
  wire pending_system_sfence_commit_o;

  OooCsrAccessRequestMux #(
    .ROB_INDEX_W(ROB_INDEX_W),
    .PRODUCER_GEN_W(PRODUCER_GEN_W),
    .PRODUCER_ID_W(PRODUCER_ID_W)
  ) dut (
    .core_commit0_valid_i(core_commit0_valid_i),
    .core_commit0_exception_i(core_commit0_exception_i),
    .core_commit0_pc_i(core_commit0_pc_i),
    .core_commit0_inst_i(core_commit0_inst_i),
    .core_commit0_producer_id_i(core_commit0_producer_id_i),
    .pending_system_i(pending_system_i),
    .pending_system_csr_i(pending_system_csr_i),
    .pending_system_dispatched_i(pending_system_dispatched_i),
    .pending_system_sfence_i(pending_system_sfence_i),
    .pending_system_pc_i(pending_system_pc_i),
    .pending_system_inst_i(pending_system_inst_i),
    .pending_system_producer_valid_i(pending_system_producer_valid_i),
    .pending_system_producer_id_i(pending_system_producer_id_i),
    .dispatch_valid_i(dispatch_valid_i),
    .dispatch0_system_i(dispatch0_system_i),
    .dispatch1_barrier_i(dispatch1_barrier_i),
    .head0_csr_raw_i(head0_csr_raw_i),
    .head1_csr_raw_i(head1_csr_raw_i),
    .head_inst0_i(head_inst0_i),
    .head_inst1_i(head_inst1_i),
    .stop_pending_i(stop_pending_i),
    .drain_complete_i(drain_complete_i),
    .debug_gprs_i(debug_gprs_i),
    .core_commit0_csr_o(core_commit0_csr_o),
    .pending_system_csr_commit_o(pending_system_csr_commit_o),
    .head0_csr_commit_o(head0_csr_commit_o),
    .head1_csr_probe_o(head1_csr_probe_o),
    .csr_access_valid_o(csr_access_valid_o),
    .csr_access_inst_o(csr_access_inst_o),
    .csr_access_addr_o(csr_access_addr_o),
    .csr_access_funct3_o(csr_access_funct3_o),
    .csr_access_rs1_idx_o(csr_access_rs1_idx_o),
    .csr_access_rs1_data_o(csr_access_rs1_data_o),
    .csr_access_set_clear_noop_o(csr_access_set_clear_noop_o),
    .csr_access_need_write_o(csr_access_need_write_o),
    .csr_probe_valid_o(csr_probe_valid_o),
    .csr_probe_addr_o(csr_probe_addr_o),
    .csr_probe_funct3_o(csr_probe_funct3_o),
    .csr_probe_rs1_idx_o(csr_probe_rs1_idx_o),
    .pending_system_satp_write_commit_o(pending_system_satp_write_commit_o),
    .pending_system_sfence_commit_o(pending_system_sfence_commit_o)
  );

  function [`INST_W-1:0] csr_inst;
    input [11:0] csr;
    input [2:0] funct3;
    input [`REG_ADDR_W-1:0] rs1;
    begin
      csr_inst = {csr, rs1, funct3, 5'd1, `OPCODE_SYSTEM};
    end
  endfunction

  task clear_inputs;
    begin
      core_commit0_valid_i = 1'b0;
      core_commit0_exception_i = 1'b0;
      core_commit0_pc_i = 64'h8000_1000;
      core_commit0_inst_i = csr_inst(`CSR_MSTATUS, 3'b010, 5'd5);
      core_commit0_producer_id_i = PID_A;
      pending_system_i = 1'b0;
      pending_system_csr_i = 1'b0;
      pending_system_dispatched_i = 1'b0;
      pending_system_sfence_i = 1'b0;
      pending_system_pc_i = 64'h8000_1000;
      pending_system_inst_i = csr_inst(`CSR_SATP, 3'b001, 5'd6);
      pending_system_producer_valid_i = 1'b0;
      pending_system_producer_id_i = PID_A;
      dispatch_valid_i = 1'b0;
      dispatch0_system_i = 1'b0;
      dispatch1_barrier_i = 1'b0;
      head0_csr_raw_i = 1'b0;
      head1_csr_raw_i = 1'b0;
      head_inst0_i = csr_inst(`CSR_MIE, 3'b010, 5'd7);
      head_inst1_i = csr_inst(`CSR_MTVEC, 3'b010, 5'd8);
      stop_pending_i = 1'b0;
      drain_complete_i = 1'b0;
      pending_system_sfence_i = 1'b0;
      debug_gprs_i = {(`XLEN * `REG_NUM){1'b0}};
      debug_gprs_i[5 * `XLEN +: `XLEN] = 64'h0000_0000_0000_0005;
      debug_gprs_i[6 * `XLEN +: `XLEN] = 64'h0000_0000_0000_0006;
      debug_gprs_i[7 * `XLEN +: `XLEN] = 64'h0000_0000_0000_0007;
      debug_gprs_i[8 * `XLEN +: `XLEN] = 64'h0000_0000_0000_0008;
    end
  endtask

  // probe 只观察 ROB head；即使同拍有 commit/pending access，也不能改写其 payload。
  task expect_probe;
    input exp_valid;
    input [`INST_W-1:0] exp_inst;
    begin
      #1;
      if (csr_probe_valid_o !== exp_valid ||
          (exp_valid &&
           (csr_probe_addr_o !== exp_inst[31:20] ||
            csr_probe_funct3_o !== exp_inst[14:12] ||
            csr_probe_rs1_idx_o !== exp_inst[19:15]))) begin
        $display("FAIL probe valid=%0b addr=%0h funct3=%0h rs1=%0d expected_valid=%0b expected_inst=%0h",
                 csr_probe_valid_o, csr_probe_addr_o, csr_probe_funct3_o,
                 csr_probe_rs1_idx_o, exp_valid, exp_inst);
        $finish;
      end
    end
  endtask

  task expect_access;
    input exp_core_csr;
    input exp_pending_commit;
    input exp_head0_commit;
    input exp_head1_probe;
    input exp_valid;
    input [`INST_W-1:0] exp_inst;
    input exp_need_write;
    input exp_satp_commit;
    input exp_sfence_commit;
    begin
      #1;
      if (core_commit0_csr_o !== exp_core_csr ||
          pending_system_csr_commit_o !== exp_pending_commit ||
          head0_csr_commit_o !== exp_head0_commit ||
          head1_csr_probe_o !== exp_head1_probe ||
          csr_access_valid_o !== exp_valid ||
          csr_access_inst_o !== exp_inst ||
          csr_access_addr_o !== exp_inst[31:20] ||
          csr_access_funct3_o !== exp_inst[14:12] ||
          csr_access_rs1_idx_o !== exp_inst[19:15] ||
          csr_access_rs1_data_o !==
              debug_gprs_i[exp_inst[19:15] * `XLEN +: `XLEN] ||
          csr_access_need_write_o !== exp_need_write ||
          pending_system_satp_write_commit_o !== exp_satp_commit ||
          pending_system_sfence_commit_o !== exp_sfence_commit) begin
        $display("FAIL core=%0b pend=%0b head0=%0b probe=%0b valid=%0b inst=%0h addr=%0h funct3=%0h rs1=%0d data=%0h need=%0b satp=%0b sfence=%0b",
                 core_commit0_csr_o, pending_system_csr_commit_o,
                 head0_csr_commit_o, head1_csr_probe_o,
                 csr_access_valid_o, csr_access_inst_o,
                 csr_access_addr_o, csr_access_funct3_o,
                 csr_access_rs1_idx_o, csr_access_rs1_data_o,
                 csr_access_need_write_o,
                 pending_system_satp_write_commit_o,
                 pending_system_sfence_commit_o);
        $finish;
      end
    end
  endtask

  initial begin
    clear_inputs();
    expect_access(1'b0, 1'b0, 1'b0, 1'b0, 1'b0, head_inst0_i,
                  1'b1, 1'b0, 1'b0);
    expect_probe(1'b0, head_inst0_i);

    clear_inputs();
    head0_csr_raw_i = 1'b1;
    expect_access(1'b0, 1'b0, 1'b0, 1'b0, 1'b1, head_inst0_i,
                  1'b1, 1'b0, 1'b0);
    expect_probe(1'b1, head_inst0_i);

    // 流水线可达正例：lane0 是普通 ADDI，lane1 是 CSR barrier；probe/access 均应取 lane1。
    clear_inputs();
    head_inst0_i = 32'h0010_0093;
    dispatch_valid_i = 1'b1;
    dispatch1_barrier_i = 1'b1;
    head1_csr_raw_i = 1'b1;
    expect_access(1'b0, 1'b0, 1'b0, 1'b1, 1'b1, head_inst1_i,
                  1'b1, 1'b0, 1'b0);
    expect_probe(1'b1, head_inst1_i);

    clear_inputs();
    dispatch_valid_i = 1'b1;
    dispatch0_system_i = 1'b1;
    dispatch1_barrier_i = 1'b1;
    head1_csr_raw_i = 1'b1;
    expect_access(1'b0, 1'b0, 1'b0, 1'b0, 1'b0, head_inst0_i,
                  1'b1, 1'b0, 1'b0);
    expect_probe(1'b0, head_inst0_i);

    // 结构/mutation 隔离：pending 与新 dispatch 通常被上游 stop 门控互斥；这里仅验证
    // 即使直接单元输入被同时拉高，pending main access 也不能污染 head-only probe。
    clear_inputs();
    pending_system_i = 1'b1;
    pending_system_csr_i = 1'b1;
    dispatch_valid_i = 1'b1;
    dispatch1_barrier_i = 1'b1;
    head1_csr_raw_i = 1'b1;
    expect_access(1'b0, 1'b0, 1'b0, 1'b1, 1'b1, pending_system_inst_i,
                  1'b1, 1'b0, 1'b0);
    expect_probe(1'b1, head_inst1_i);

    // 结构/mutation 隔离（非流水线可达声明）：手工同时置 head0/head1 CSR raw、
    // pending 与 commit，验证 access 取 commit0 而 probe 仍只取 lane1 payload。
    clear_inputs();
    core_commit0_valid_i = 1'b1;
    core_commit0_inst_i = csr_inst(`CSR_SATP, 3'b001, 5'd6);
    pending_system_i = 1'b1;
    pending_system_csr_i = 1'b1;
    pending_system_inst_i = csr_inst(`CSR_MSTATUS, 3'b001, 5'd5);
    dispatch_valid_i = 1'b1;
    dispatch1_barrier_i = 1'b1;
    head0_csr_raw_i = 1'b1;
    head1_csr_raw_i = 1'b1;
    expect_access(1'b1, 1'b0, `OOO_CSR_QUEUE_HEAD, 1'b1, 1'b1,
                  core_commit0_inst_i,
                  1'b1, 1'b0, 1'b0);
    expect_probe(1'b1, head_inst1_i);

    clear_inputs();
    pending_system_i = 1'b1;
    pending_system_csr_i = 1'b1;
    pending_system_dispatched_i = 1'b1;
    pending_system_producer_valid_i = 1'b1;
    core_commit0_valid_i = 1'b1;
    core_commit0_inst_i = csr_inst(`CSR_SATP, 3'b001, 5'd6);
    expect_access(1'b1, 1'b1, 1'b0, 1'b0, 1'b1, core_commit0_inst_i,
                  1'b1, 1'b1, 1'b0);
    expect_probe(1'b0, head_inst0_i);

    // Same ROB index with a different generation is a stale ProducerId, not
    // the pending owner.  The raw lease seals the head0 fallback as well.
    clear_inputs();
    pending_system_i = 1'b1;
    pending_system_csr_i = 1'b1;
    pending_system_dispatched_i = 1'b1;
    pending_system_producer_valid_i = 1'b1;
    pending_system_producer_id_i = PID_A;
    core_commit0_valid_i = 1'b1;
    core_commit0_inst_i = csr_inst(`CSR_SATP, 3'b001, 5'd6);
    core_commit0_producer_id_i = PID_STALE_GEN;
    expect_access(1'b1, 1'b0, 1'b0, 1'b0, 1'b1,
                  core_commit0_inst_i, 1'b1, 1'b0, 1'b0);

    // Raw-only and logical-only malformed states both fail closed.  These are
    // combinational unit counterexamples; integration assertions make them
    // fatal if either state is ever reached in the core.
    clear_inputs();
    pending_system_producer_valid_i = 1'b1;
    core_commit0_valid_i = 1'b1;
    core_commit0_inst_i = csr_inst(`CSR_SATP, 3'b001, 5'd6);
    expect_access(1'b1, 1'b0, 1'b0, 1'b0, 1'b1,
                  core_commit0_inst_i, 1'b1, 1'b0, 1'b0);

    clear_inputs();
    pending_system_i = 1'b1;
    pending_system_csr_i = 1'b1;
    pending_system_dispatched_i = 1'b1;
    core_commit0_valid_i = 1'b1;
    core_commit0_inst_i = csr_inst(`CSR_SATP, 3'b001, 5'd6);
    expect_access(1'b1, 1'b0, 1'b0, 1'b0, 1'b1,
                  core_commit0_inst_i, 1'b1, 1'b0, 1'b0);

    clear_inputs();
    pending_system_i = 1'b1;
    pending_system_csr_i = 1'b1;
    pending_system_dispatched_i = 1'b1;
    pending_system_producer_valid_i = 1'b1;
    pending_system_pc_i = 64'h8000_1004;
    core_commit0_valid_i = 1'b1;
    core_commit0_inst_i = csr_inst(`CSR_SATP, 3'b001, 5'd6);
    expect_access(1'b1, 1'b0, 1'b0, 1'b0, 1'b1, core_commit0_inst_i,
                  1'b1, 1'b0, 1'b0);
    expect_probe(1'b0, head_inst0_i);

    clear_inputs();
    pending_system_i = 1'b1;
    pending_system_csr_i = 1'b1;
    pending_system_dispatched_i = 1'b1;
    pending_system_producer_valid_i = 1'b1;
    core_commit0_valid_i = 1'b1;
    core_commit0_inst_i = csr_inst(`CSR_SATP, 3'b010, 5'd0);
    expect_access(1'b1, 1'b1, 1'b0, 1'b0, 1'b1, core_commit0_inst_i,
                  1'b0, 1'b0, 1'b0);
    expect_probe(1'b0, head_inst0_i);
    if (csr_access_set_clear_noop_o !== 1'b1) begin
      $display("FAIL expected set/clear noop");
      $finish;
    end

    clear_inputs();
    pending_system_i = 1'b1;
    pending_system_sfence_i = 1'b1;
    stop_pending_i = 1'b1;
    drain_complete_i = 1'b1;
    expect_access(1'b0, 1'b0, 1'b0, 1'b0, 1'b0, pending_system_inst_i,
                  1'b1, 1'b0, 1'b1);
    expect_probe(1'b0, head_inst0_i);

    clear_inputs();
    pending_system_i = 1'b1;
    pending_system_sfence_i = 1'b1;
    stop_pending_i = 1'b1;
    expect_access(1'b0, 1'b0, 1'b0, 1'b0, 1'b0, pending_system_inst_i,
                  1'b1, 1'b0, 1'b0);
    expect_probe(1'b0, head_inst0_i);

    clear_inputs();
    core_commit0_valid_i = 1'b1;
    core_commit0_exception_i = 1'b1;
    expect_access(1'b0, 1'b0, 1'b0, 1'b0, 1'b0, head_inst0_i,
                  1'b1, 1'b0, 1'b0);
    expect_probe(1'b0, head_inst0_i);

    $display("PASS tb_ooo_csr_access_request_mux");
    $finish;
  end
endmodule
