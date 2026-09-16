`include "define.v"
`include "tb_common.svh"
`include "rv32_encode.svh"

// Production NpcCoreTop trace for DI-5.  The program is an unrolled stream of
// independent RV64 LD pairs whose effective addresses select different memory
// banks.  The measurement window starts deterministically after eight hot-hit
// completions in each bank and then records exactly 64 consecutive cycles.
module tb_ooo_dual_memory_sustained_issue;
  localparam [`XLEN-1:0] BASE_PC = 64'h0000_0000_8000_0000;
  localparam integer TRACE_CYCLES = 64;
  localparam integer PREHEAT_HITS = 8;
  // The first traversal fills 128 packet-cache entries.  The direct JAL then
  // returns to the load body, leaving more than one 64-cycle trace window
  // before the next control-flow instruction.
  localparam integer LOOP_BYTES = 1024;

  reg clk;
  reg rst;

  wire ifu_axi_arvalid;
  reg ifu_axi_arready;
  wire [`XLEN-1:0] ifu_axi_araddr;
  wire [2:0] ifu_axi_arsize;
  wire [2:0] ifu_axi_arprot;
  reg ifu_axi_rvalid;
  wire ifu_axi_rready;
  reg [`XLEN-1:0] ifu_axi_rdata;
  reg [1:0] ifu_axi_rresp;

  wire lsu_axi_arvalid;
  reg lsu_axi_arready;
  wire [`XLEN-1:0] lsu_axi_araddr;
  wire [2:0] lsu_axi_arsize;
  reg lsu_axi_rvalid;
  wire lsu_axi_rready;
  reg [`XLEN-1:0] lsu_axi_rdata;
  reg [1:0] lsu_axi_rresp;
  wire lsu_axi_awvalid;
  reg lsu_axi_awready;
  wire [`XLEN-1:0] lsu_axi_awaddr;
  wire lsu_axi_wvalid;
  reg lsu_axi_wready;
  wire [`XLEN-1:0] lsu_axi_wdata;
  wire [`STRB_W-1:0] lsu_axi_wstrb;
  reg lsu_axi_bvalid;
  wire lsu_axi_bready;
  reg [1:0] lsu_axi_bresp;

  wire commit0_valid;
  wire [`XLEN-1:0] commit0_pc;
  wire commit1_valid;
  wire [`XLEN-1:0] commit1_pc;
  wire trap_valid;
  wire exit_valid;
  wire halted;

  integer cycle_count;
  integer preheat_hit0;
  integer preheat_hit1;
  integer trace_index;
  integer agu_accepts0;
  integer agu_accepts1;
  integer translation_accepts0;
  integer translation_accepts1;
  integer physical_lsq_queries0;
  integer physical_lsq_queries1;
  integer cache_admissions0;
  integer cache_admissions1;
  integer completions0;
  integer completions1;
  integer dual_issue_cycles;
  reg measure_active;
  reg first_loop_wrap_seen;

  wire agu_fire0 = dut.ooo_mem0_req_valid_w &&
                   dut.ooo_mem0_req_ready_w;
  wire agu_fire1 = dut.ooo_mem1_req_valid_w &&
                   dut.ooo_mem1_req_ready_w;
  wire translation_fire0 =
      dut.u_ooo_dual_mem_bridge.u_bridge0.stage_advance_w;
  wire translation_fire1 =
      dut.u_ooo_dual_mem_bridge.u_bridge1.stage_advance_w;
  wire physical_query0 = dut.ooo_mem0_sq_query_valid_w;
  wire physical_query1 = dut.ooo_mem1_sq_query_valid_w;
  wire cache_admit0 =
      dut.u_ooo_dual_mem_bridge.u_bridge0.dcache_lookup_en_w;
  wire cache_admit1 =
      dut.u_ooo_dual_mem_bridge.u_bridge1.dcache_lookup_en_w;
  wire completion_fire0 = dut.ooo_mem0_rsp_valid_w &&
                          dut.ooo_mem0_rsp_ready_w;
  wire completion_fire1 = dut.ooo_mem1_rsp_valid_w &&
                          dut.ooo_mem1_rsp_ready_w;
  wire hot_hit_fire0 =
      dut.u_ooo_dual_mem_bridge.u_bridge0.lookup_hit_fusion_w &&
      dut.ooo_mem0_rsp_ready_w;
  wire hot_hit_fire1 =
      dut.u_ooo_dual_mem_bridge.u_bridge1.lookup_hit_fusion_w &&
      dut.ooo_mem1_rsp_ready_w;

  NpcCoreTop dut (
    .clk(clk),
    .rst(rst),
    .dcache_dma_invalidate_all_i(1'b0),
    .ifu_axi_arvalid_o(ifu_axi_arvalid),
    .ifu_axi_arready_i(ifu_axi_arready),
    .ifu_axi_araddr_o(ifu_axi_araddr),
    .ifu_axi_arsize_o(ifu_axi_arsize),
    .ifu_axi_arprot_o(ifu_axi_arprot),
    .ifu_axi_rvalid_i(ifu_axi_rvalid),
    .ifu_axi_rready_o(ifu_axi_rready),
    .ifu_axi_rdata_i(ifu_axi_rdata),
    .ifu_axi_rresp_i(ifu_axi_rresp),
    .lsu_axi_arvalid_o(lsu_axi_arvalid),
    .lsu_axi_arready_i(lsu_axi_arready),
    .lsu_axi_araddr_o(lsu_axi_araddr),
    .lsu_axi_arsize_o(lsu_axi_arsize),
    .lsu_axi_rvalid_i(lsu_axi_rvalid),
    .lsu_axi_rready_o(lsu_axi_rready),
    .lsu_axi_rdata_i(lsu_axi_rdata),
    .lsu_axi_rresp_i(lsu_axi_rresp),
    .lsu_axi_awvalid_o(lsu_axi_awvalid),
    .lsu_axi_awready_i(lsu_axi_awready),
    .lsu_axi_awaddr_o(lsu_axi_awaddr),
    .lsu_axi_wvalid_o(lsu_axi_wvalid),
    .lsu_axi_wready_i(lsu_axi_wready),
    .lsu_axi_wdata_o(lsu_axi_wdata),
    .lsu_axi_wstrb_o(lsu_axi_wstrb),
    .lsu_axi_bvalid_i(lsu_axi_bvalid),
    .lsu_axi_bready_o(lsu_axi_bready),
    .lsu_axi_bresp_i(lsu_axi_bresp),
    .irq_software_i(1'b0),
    .irq_timer_i(1'b0),
    .irq_external_i(1'b0),
    .mtime_i(64'd0),
    .commit0_valid_o(commit0_valid),
    .commit0_pc_o(commit0_pc),
    .commit1_valid_o(commit1_valid),
    .commit1_pc_o(commit1_pc),
    .trap_valid_o(trap_valid),
    .exit_valid_o(exit_valid),
    .halted_o(halted)
  );

  function [`INST_W-1:0] inst_addi;
    input [4:0] rd;
    input [4:0] rs1;
    input [11:0] imm;
    begin
      inst_addi = rv32_i(imm, rs1, `FUNCT3_ADD_SUB, rd, `OPCODE_OP_IMM);
    end
  endfunction

  function [`INST_W-1:0] inst_auipc;
    input [4:0] rd;
    input [19:0] imm;
    begin
      inst_auipc = rv32_u(imm, rd, `OPCODE_AUIPC);
    end
  endfunction

  function [`INST_W-1:0] inst_ld;
    input [4:0] rd;
    input [4:0] rs1;
    input [11:0] imm;
    begin
      inst_ld = rv32_i(imm, rs1, `FUNCT3_LD, rd, `OPCODE_LOAD);
    end
  endfunction

  function [`INST_W-1:0] inst_jal;
    input [4:0] rd;
    input [20:0] imm;
    begin
      inst_jal = rv32_j(imm, rd);
    end
  endfunction

  function [`INST_W-1:0] inst_ebreak;
    begin
      inst_ebreak = 32'h0010_0073;
    end
  endfunction

  function [`INST_W-1:0] program_word;
    input [`XLEN-1:0] addr;
    reg [`XLEN-1:0] offset;
    begin
      offset = addr - BASE_PC;
      if (offset == 0)
        program_word = inst_auipc(5'd8, 20'h00000);
      else if (offset == 4)
        program_word = inst_addi(5'd0, 5'd0, 12'h000);
      else if ((addr >= (BASE_PC + 8)) &&
               (addr < (BASE_PC + LOOP_BYTES)))
        program_word = addr[2] ? inst_ld(5'd0, 5'd8, 12'h008) :
                                inst_ld(5'd0, 5'd8, 12'h000);
      else if (addr == (BASE_PC + LOOP_BYTES))
        // target = BASE_PC+8, displacement = 8-1024 = -1016.
        program_word = inst_jal(5'd0, 21'h1f_fc08);
      else if (addr == (BASE_PC + LOOP_BYTES + 4))
        program_word = inst_addi(5'd0, 5'd0, 12'h000);
      else
        program_word = inst_ebreak();
    end
  endfunction

  function [`XLEN-1:0] read64;
    input [`XLEN-1:0] addr;
    begin
      read64 = {program_word(addr + 4), program_word(addr)};
    end
  endfunction

  always @(posedge clk) begin
    if (rst) begin
      ifu_axi_rvalid <= 1'b0;
      ifu_axi_rdata <= {`XLEN{1'b0}};
      ifu_axi_rresp <= 2'b00;
    end else begin
      if (ifu_axi_rvalid && ifu_axi_rready)
        ifu_axi_rvalid <= 1'b0;
      if (ifu_axi_arvalid && ifu_axi_arready) begin
        ifu_axi_rvalid <= 1'b1;
        ifu_axi_rdata <= read64({ifu_axi_araddr[`XLEN-1:3], 3'b000});
        ifu_axi_rresp <= 2'b00;
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      lsu_axi_rvalid <= 1'b0;
      lsu_axi_rdata <= {`XLEN{1'b0}};
      lsu_axi_rresp <= 2'b00;
      lsu_axi_bvalid <= 1'b0;
      lsu_axi_bresp <= 2'b00;
    end else begin
      if (lsu_axi_rvalid && lsu_axi_rready)
        lsu_axi_rvalid <= 1'b0;
      if (lsu_axi_arvalid && lsu_axi_arready) begin
        lsu_axi_rvalid <= 1'b1;
        lsu_axi_rdata <= read64({lsu_axi_araddr[`XLEN-1:3], 3'b000});
        lsu_axi_rresp <= 2'b00;
      end
      if (lsu_axi_bvalid && lsu_axi_bready)
        lsu_axi_bvalid <= 1'b0;
      if ((lsu_axi_awvalid && lsu_axi_awready) ||
          (lsu_axi_wvalid && lsu_axi_wready)) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] load-only stream emitted AXI write");
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      preheat_hit0 <= 0;
      preheat_hit1 <= 0;
      first_loop_wrap_seen <= 1'b0;
    end else begin
      if (!first_loop_wrap_seen &&
          ((commit0_valid && (commit0_pc == (BASE_PC + LOOP_BYTES))) ||
           (commit1_valid && (commit1_pc == (BASE_PC + LOOP_BYTES))))) begin
        first_loop_wrap_seen <= 1'b1;
        preheat_hit0 <= 0;
        preheat_hit1 <= 0;
        $display("[V8U-DI5-I$-PREHEAT] first_loop_wrap_committed cycle=%0d",
                 cycle_count);
      end else if (first_loop_wrap_seen && hot_hit_fire0)
        preheat_hit0 <= preheat_hit0 + 1;
      if (first_loop_wrap_seen && hot_hit_fire1)
        preheat_hit1 <= preheat_hit1 + 1;
      if (trap_valid || exit_valid || halted) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] core terminated during sustained load stream trap=%0b exit=%0b halted=%0b",
                 trap_valid, exit_valid, halted);
      end
      if (measure_active) begin
        if (agu_fire0) agu_accepts0 <= agu_accepts0 + 1;
        if (agu_fire1) agu_accepts1 <= agu_accepts1 + 1;
        if (translation_fire0)
          translation_accepts0 <= translation_accepts0 + 1;
        if (translation_fire1)
          translation_accepts1 <= translation_accepts1 + 1;
        if (physical_query0)
          physical_lsq_queries0 <= physical_lsq_queries0 + 1;
        if (physical_query1)
          physical_lsq_queries1 <= physical_lsq_queries1 + 1;
        if (cache_admit0) cache_admissions0 <= cache_admissions0 + 1;
        if (cache_admit1) cache_admissions1 <= cache_admissions1 + 1;
        if (completion_fire0) completions0 <= completions0 + 1;
        if (completion_fire1) completions1 <= completions1 + 1;
        if (completion_fire0 && completion_fire1)
          dual_issue_cycles <= dual_issue_cycles + 1;
        $display("[V8U-DI5-CYCLE] index=%0d agu=%0b%0b translation=%0b%0b query=%0b%0b cache=%0b%0b completion=%0b%0b",
                 trace_index, agu_fire1, agu_fire0,
                 translation_fire1, translation_fire0,
                 physical_query1, physical_query0,
                 cache_admit1, cache_admit0,
                 completion_fire1, completion_fire0);
        $display("[V8U-DI5-PIPE] index=%0d fetch=%0b/%0b dispatch=%0b%0b/%0b iq=%0b%0b res=%0b%0b capture=%0b%0b consume=%0b%0b turnover=%0b",
                 trace_index,
                 dut.ooo_fetch_req_valid_w, dut.ooo_fetch_rsp_valid_w,
                 dut.u_ooo_core.core_dispatch1_valid_w,
                 dut.u_ooo_core.core_dispatch0_valid_w,
                 dut.u_ooo_core.core_dispatch0_fire_w,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.issue1_valid_w,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.iq_issue0_valid_w,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.mem_issue1_res_valid_q,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.mem_issue_res_valid_q,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.mem_issue1_res_capture_w,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.mem_issue_res_capture_w,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.mem_issue1_res_consume_fire_w,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.mem_issue_res_consume_fire_w,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.mem_issue_pair_turnover_capture_w);
        $display("[V8U-DI5-GRANT] index=%0d candidate=%0b%0b selected=%0b%0b bank=%0b%0b slot=%0b%0b bridge_ready=%0b%0b grant=%0b%0b miq_count=%0d,%0d bridge_load=%0b%0b/%0b%0b",
                 trace_index,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.issue1_dual_transport_candidate_w,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.issue0_dual_transport_candidate_w,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.issue1_dual_selected_w,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.issue0_dual_selected_w,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.issue1_dual_bank1_w,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.issue0_dual_bank1_w,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.issue1_dual_bank_slot_open_w,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.issue0_dual_bank_slot_open_w,
                 dut.ooo_mem1_req_ready_w, dut.ooo_mem0_req_ready_w,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.grant_mem1_issue1_w,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.grant_issue0_w,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.miq_count_w,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.miq1_count_w,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.mem1_bridge_station_load_w,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.mem1_bridge_active_load_w,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.mem_bridge_station_load_w,
                 dut.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.mem_bridge_active_load_w);
        trace_index <= trace_index + 1;
      end
    end
  end

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    ifu_axi_arready = 1'b1;
    lsu_axi_arready = 1'b1;
    lsu_axi_awready = 1'b1;
    lsu_axi_wready = 1'b1;
    measure_active = 1'b0;
    cycle_count = 0;
    trace_index = 0;
    agu_accepts0 = 0;
    agu_accepts1 = 0;
    translation_accepts0 = 0;
    translation_accepts1 = 0;
    physical_lsq_queries0 = 0;
    physical_lsq_queries1 = 0;
    cache_admissions0 = 0;
    cache_admissions1 = 0;
    completions0 = 0;
    completions1 = 0;
    dual_issue_cycles = 0;
    `TB_TICK(clk);
    rst = 1'b0;

    while ((!first_loop_wrap_seen || (preheat_hit0 < PREHEAT_HITS) ||
            (preheat_hit1 < PREHEAT_HITS)) && cycle_count < 2000) begin
      `TB_TICK(clk);
      cycle_count = cycle_count + 1;
    end
    if (cycle_count >= 2000) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] timeout before deterministic I$/D$ preheat wrap=%0b bank0=%0d bank1=%0d",
               first_loop_wrap_seen, preheat_hit0, preheat_hit1);
    end

    $display("[V8U-DI5-WINDOW-BEGIN] policy=first_loop_wrap_then_next_cycle_after_each_bank_eight_hot_hits cycle=%0d bank0_hot_hits=%0d bank1_hot_hits=%0d",
             cycle_count, preheat_hit0, preheat_hit1);
    measure_active = 1'b1;
    repeat (TRACE_CYCLES) begin
      `TB_TICK(clk);
      cycle_count = cycle_count + 1;
    end
    measure_active = 1'b0;

    $display("[V8U-DI5-METRIC] trace_cycles=%0d memory_issue_ipc_milli=%0d dual_issue_cycles=%0d agu_accepts=%0d,%0d translation_accepts=%0d,%0d physical_lsq_queries=%0d,%0d cache_admissions=%0d,%0d completions=%0d,%0d",
             TRACE_CYCLES,
             ((completions0 + completions1) * 1000) / TRACE_CYCLES,
             dual_issue_cycles,
             agu_accepts0, agu_accepts1,
             translation_accepts0, translation_accepts1,
             physical_lsq_queries0, physical_lsq_queries1,
             cache_admissions0, cache_admissions1,
             completions0, completions1);

    if (trace_index != TRACE_CYCLES) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] trace index count got=%0d expected=%0d",
               trace_index, TRACE_CYCLES);
    end
    if ((completions0 + completions1) < 122) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] memory IPC below 1.90 completions=%0d",
               completions0 + completions1);
    end
    if (dual_issue_cycles < 58) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] dual completion cycles got=%0d expected>=58",
               dual_issue_cycles);
    end
    if ((agu_accepts0 < 58) || (agu_accepts1 < 58) ||
        (translation_accepts0 < 58) || (translation_accepts1 < 58) ||
        (physical_lsq_queries0 < 58) || (physical_lsq_queries1 < 58) ||
        (cache_admissions0 < 58) || (cache_admissions1 < 58) ||
        (completions0 < 58) || (completions1 < 58)) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] one or more DI-5 per-bank faces are below 58");
    end
    tb_finish("tb_ooo_dual_memory_sustained_issue");
  end

  wire unused_w = commit0_valid | commit1_valid | ifu_axi_arprot[0] |
      (|ifu_axi_arsize) | (|lsu_axi_arsize) | (|lsu_axi_awaddr) |
      (|lsu_axi_wdata) | (|lsu_axi_wstrb);
endmodule
