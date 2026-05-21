`include "define.v"

module stage_pipe_test;
  `include "tb_common.svh"

  reg clk;
  reg rst;

  reg fe_flush;
  reg fe_redirect_valid;
  reg [`XLEN-1:0] fe_redirect_pc;
  reg fe_consume;
  reg fe_halt;
  reg fe_fatal;

  wire fe_pipe_ready;
  wire fe_pipe_valid;
  wire [`XLEN-1:0] fe_pipe_pc;
  wire [`INST_W-1:0] fe_pipe_inst;
  wire [`XLEN-1:0] fe_pipe_inst_len;
  wire [`XLEN-1:0] fe_pipe_pred_pc;
  wire [9:0] fe_pipe_bht_idx;
  wire fe_pipe_error;
  wire [`XLEN-1:0] fe_fetch_pc;
  wire fe_fetch_pending;

  wire icache_cpu_req_valid;
  wire icache_cpu_req_ready;
  wire [`XLEN-1:0] icache_cpu_req_addr;
  wire icache_cpu_rsp_valid;
  wire [`XLEN-1:0] icache_cpu_rsp_data;
  wire icache_cpu_rsp_error;
  wire imem_axi_arvalid;
  reg imem_axi_arready;
  wire [`XLEN-1:0] imem_axi_araddr;
  reg imem_axi_rvalid;
  wire imem_axi_rready;
  reg [`XLEN-1:0] imem_axi_rdata;
  reg [1:0] imem_axi_rresp;
  reg imem_rsp_pending_q;
  reg [`XLEN-1:0] imem_rsp_addr_q;

  wire fe_if_id_valid;
  wire [`XLEN-1:0] fe_if_id_pc;
  wire [`INST_W-1:0] fe_if_id_inst;
  wire [`XLEN-1:0] fe_if_id_inst_len;
  wire [`XLEN-1:0] fe_if_id_pred_pc;
  wire fe_if_id_error;

  reg update_en;
  reg clear;
  reg mem_ex_valid;
  reg mem_ex_load;
  reg mem_ex_store;
  reg [1:0] mem_ex_size;
  reg mem_ex_unsigned;
  reg [`XLEN-1:0] mem_ex_addr;
  reg [`XLEN-1:0] mem_ex_store_data;

  wire lsu_req_valid;
  wire lsu_req_ready;
  wire lsu_req_write;
  wire [`XLEN-1:0] lsu_req_addr;
  wire [`XLEN-1:0] lsu_req_wdata;
  wire [3:0] lsu_req_wstrb;
  wire lsu_rsp_valid;
  wire [`XLEN-1:0] lsu_rsp_rdata;
  wire lsu_rsp_error;
  wire [`XLEN-1:0] mem_load_data;
  wire mem_response;
  wire mem_fault;
  wire mem_pending;

  reg dcache_invalidate;
  wire dcache_flush_done;
  wire dmem_axi_arvalid;
  reg dmem_axi_arready;
  wire [`XLEN-1:0] dmem_axi_araddr;
  reg dmem_axi_rvalid;
  wire dmem_axi_rready;
  reg [`XLEN-1:0] dmem_axi_rdata;
  reg [1:0] dmem_axi_rresp;
  wire dmem_axi_awvalid;
  reg dmem_axi_awready;
  wire [`XLEN-1:0] dmem_axi_awaddr;
  wire dmem_axi_wvalid;
  reg dmem_axi_wready;
  wire [`XLEN-1:0] dmem_axi_wdata;
  wire [3:0] dmem_axi_wstrb;
  reg dmem_axi_bvalid;
  wire dmem_axi_bready;
  reg [1:0] dmem_axi_bresp;
  reg dmem_rsp_pending_q;
  reg dmem_rsp_write_q;
  reg [`XLEN-1:0] dmem_rsp_addr_q;

  reg p_if_id_valid;
  reg p_id_ex_valid;
  reg p_id_ex_load;
  reg p_id_ex_ecall;
  reg p_id_ex_ebreak;
  reg p_id_ex_mret;
  reg p_id_ex_branch;
  reg p_id_ex_jal;
  reg p_id_ex_jalr;
  reg [`REG_ADDR_W-1:0] p_id_ex_rd_idx;
  reg [`XLEN-1:0] p_id_ex_pred_pc;
  reg p_dec_uses_rs1;
  reg p_dec_uses_rs2;
  reg [`REG_ADDR_W-1:0] p_dec_rs1_idx;
  reg [`REG_ADDR_W-1:0] p_dec_rs2_idx;
  reg p_ex_mem_valid;
  reg p_ex_mem_is_mem;
  reg p_mem_response;
  reg p_mem_fault;
  reg p_ex_wait;
  reg p_halt;
  reg p_fatal;
  reg p_ex_fetch_fault;
  reg p_ex_illegal;
  reg p_ex_redirect_misaligned;
  reg p_ex_load_store_misaligned;
  reg [`XLEN-1:0] p_ex_control_next_pc;
  reg [`XLEN-1:0] p_ex_redirect_pc;
  reg [`XLEN-1:0] p_trap_target;
  reg [`XLEN-1:0] p_csr_mepc;
  reg p_cache_flush_valid;
  reg [`XLEN-1:0] p_cache_flush_redirect_pc;
  wire p_ex_fire;
  wire p_ex_exception;
  wire p_ex_exception_fatal;
  wire p_ex_mret_redirect;
  wire p_ex_any_flush;
  wire p_id_accept;
  wire p_if_id_consume;
  wire p_if_id_can_refill;
  wire p_ebreak_fire;
  wire p_pipeline_normal_update;
  wire p_if_redirect_valid;
  wire [`XLEN-1:0] p_if_redirect_pc;
  wire p_ex_mem_leave_update;
  wire p_ex_mem_load_update;
  wire p_mem_wb_from_mem;
  wire p_mem_wb_from_ex;
  wire p_mem_wb_load;
  wire p_bpu_update_valid;

  integer report_fd;
  integer frontend_miss_wait_cycles;
  integer frontend_hit_wait_cycles;
  integer frontend_duplicate_bubbles;
  integer mem_miss_wait_cycles;
  integer mem_hit_wait_cycles;
  integer mem_store_wait_cycles;
  integer load_use_bubbles;
  integer removable_frontend_hit_bubbles;
  integer removable_mem_hit_bubbles;
  integer guard_cycles;
  integer expect_frontend_hit_zero;
  string report_path;

  assign fe_pipe_ready = (~fe_if_id_valid) | fe_consume;

  IfStage u_if_stage (
    .clk(clk),
    .rst(rst),
    .flush_i(fe_flush),
    .redirect_valid_i(fe_redirect_valid),
    .redirect_pc_i(fe_redirect_pc),
    .pipe_ready_i(fe_pipe_ready),
    .halt_i(fe_halt),
    .fatal_i(fe_fatal),
    .bpu_update_valid_i(1'b0),
    .bpu_update_pc_i({`XLEN{1'b0}}),
    .bpu_update_inst_i({`INST_W{1'b0}}),
    .bpu_update_seq_pc_i({`XLEN{1'b0}}),
    .bpu_update_next_pc_i({`XLEN{1'b0}}),
    .bpu_update_taken_i(1'b0),
    .bpu_update_bht_idx_i(10'h0),
    .pipe_valid_o(fe_pipe_valid),
    .pipe_pc_o(fe_pipe_pc),
    .pipe_inst_o(fe_pipe_inst),
    .pipe_inst_len_o(fe_pipe_inst_len),
    .pipe_pred_pc_o(fe_pipe_pred_pc),
    .pipe_bht_idx_o(fe_pipe_bht_idx),
    .pipe_error_o(fe_pipe_error),
    .ifu_req_valid_o(icache_cpu_req_valid),
    .ifu_req_ready_i(icache_cpu_req_ready),
    .ifu_req_addr_o(icache_cpu_req_addr),
    .ifu_rsp_valid_i(icache_cpu_rsp_valid),
    .ifu_rsp_data_i(icache_cpu_rsp_data),
    .ifu_rsp_error_i(icache_cpu_rsp_error),
    .fetch_pc_o(fe_fetch_pc),
    .fetch_pending_o(fe_fetch_pending)
  );

  ICache u_icache (
    .clk(clk),
    .rst(rst),
    .abort_i(fe_flush),
    .invalidate_i(1'b0),
    .cpu_req_valid_i(icache_cpu_req_valid),
    .cpu_req_ready_o(icache_cpu_req_ready),
    .cpu_req_addr_i(icache_cpu_req_addr),
    .cpu_rsp_valid_o(icache_cpu_rsp_valid),
    .cpu_rsp_data_o(icache_cpu_rsp_data),
    .cpu_rsp_error_o(icache_cpu_rsp_error),
    .axi_arvalid_o(imem_axi_arvalid),
    .axi_arready_i(imem_axi_arready),
    .axi_araddr_o(imem_axi_araddr),
    .axi_rvalid_i(imem_axi_rvalid),
    .axi_rready_o(imem_axi_rready),
    .axi_rdata_i(imem_axi_rdata),
    .axi_rresp_i(imem_axi_rresp)
  );

  IfIdPipeReg u_if_id_pipe (
    .clk(clk),
    .rst(rst),
    .clear_i(fe_flush),
    .consume_i(fe_consume),
    .load_i(fe_pipe_valid),
    .load_pc_i(fe_pipe_pc),
    .load_inst_i(fe_pipe_inst),
    .load_inst_len_i(fe_pipe_inst_len),
    .load_pred_pc_i(fe_pipe_pred_pc),
    .load_bht_idx_i(fe_pipe_bht_idx),
    .load_error_i(fe_pipe_error),
    .valid_o(fe_if_id_valid),
    .pc_o(fe_if_id_pc),
    .inst_o(fe_if_id_inst),
    .inst_len_o(fe_if_id_inst_len),
    .pred_pc_o(fe_if_id_pred_pc),
    .bht_idx_o(),
    .error_o(fe_if_id_error)
  );

  MemoryStage u_memory_stage (
    .clk(clk),
    .rst(rst),
    .update_en_i(update_en),
    .clear_i(clear),
    .ex_valid_i(mem_ex_valid),
    .ex_load_i(mem_ex_load),
    .ex_store_i(mem_ex_store),
    .ex_mem_size_i(mem_ex_size),
    .ex_mem_unsigned_i(mem_ex_unsigned),
    .ex_mem_addr_i(mem_ex_addr),
    .ex_store_data_i(mem_ex_store_data),
    .lsu_req_valid_o(lsu_req_valid),
    .lsu_req_ready_i(lsu_req_ready),
    .lsu_req_write_o(lsu_req_write),
    .lsu_req_addr_o(lsu_req_addr),
    .lsu_req_wdata_o(lsu_req_wdata),
    .lsu_req_wstrb_o(lsu_req_wstrb),
    .lsu_rsp_valid_i(lsu_rsp_valid),
    .lsu_rsp_rdata_i(lsu_rsp_rdata),
    .lsu_rsp_error_i(lsu_rsp_error),
    .load_data_o(mem_load_data),
    .response_o(mem_response),
    .fault_o(mem_fault),
    .pending_o(mem_pending)
  );

  DCache u_dcache (
    .clk(clk),
    .rst(rst),
    .invalidate_i(dcache_invalidate),
    .flush_i(1'b0),
    .flush_done_o(dcache_flush_done),
    .cpu_req_valid_i(lsu_req_valid),
    .cpu_req_ready_o(lsu_req_ready),
    .cpu_req_write_i(lsu_req_write),
    .cpu_req_addr_i(lsu_req_addr),
    .cpu_req_wdata_i(lsu_req_wdata),
    .cpu_req_wstrb_i(lsu_req_wstrb),
    .cpu_rsp_valid_o(lsu_rsp_valid),
    .cpu_rsp_rdata_o(lsu_rsp_rdata),
    .cpu_rsp_error_o(lsu_rsp_error),
    .axi_arvalid_o(dmem_axi_arvalid),
    .axi_arready_i(dmem_axi_arready),
    .axi_araddr_o(dmem_axi_araddr),
    .axi_rvalid_i(dmem_axi_rvalid),
    .axi_rready_o(dmem_axi_rready),
    .axi_rdata_i(dmem_axi_rdata),
    .axi_rresp_i(dmem_axi_rresp),
    .axi_awvalid_o(dmem_axi_awvalid),
    .axi_awready_i(dmem_axi_awready),
    .axi_awaddr_o(dmem_axi_awaddr),
    .axi_wvalid_o(dmem_axi_wvalid),
    .axi_wready_i(dmem_axi_wready),
    .axi_wdata_o(dmem_axi_wdata),
    .axi_wstrb_o(dmem_axi_wstrb),
    .axi_bvalid_i(dmem_axi_bvalid),
    .axi_bready_o(dmem_axi_bready),
    .axi_bresp_i(dmem_axi_bresp)
  );

  PipelineControl u_pipeline_control (
    .if_id_valid_i(p_if_id_valid),
    .id_ex_valid_i(p_id_ex_valid),
    .id_ex_load_i(p_id_ex_load),
    .id_ex_ecall_i(p_id_ex_ecall),
    .id_ex_ebreak_i(p_id_ex_ebreak),
    .id_ex_mret_i(p_id_ex_mret),
    .id_ex_branch_i(p_id_ex_branch),
    .id_ex_jal_i(p_id_ex_jal),
    .id_ex_jalr_i(p_id_ex_jalr),
    .id_ex_rd_idx_i(p_id_ex_rd_idx),
    .id_ex_pred_pc_i(p_id_ex_pred_pc),
    .dec_uses_rs1_i(p_dec_uses_rs1),
    .dec_uses_rs2_i(p_dec_uses_rs2),
    .dec_rs1_idx_i(p_dec_rs1_idx),
    .dec_rs2_idx_i(p_dec_rs2_idx),
    .ex_mem_valid_i(p_ex_mem_valid),
    .ex_mem_is_mem_i(p_ex_mem_is_mem),
    .mem_response_i(p_mem_response),
    .mem_fault_i(p_mem_fault),
    .ex_wait_i(p_ex_wait),
    .halt_i(p_halt),
    .fatal_i(p_fatal),
    .ex_fetch_fault_i(p_ex_fetch_fault),
    .ex_illegal_i(p_ex_illegal),
    .ex_redirect_misaligned_i(p_ex_redirect_misaligned),
    .ex_load_store_misaligned_i(p_ex_load_store_misaligned),
    .ex_control_next_pc_i(p_ex_control_next_pc),
    .ex_redirect_pc_i(p_ex_redirect_pc),
    .trap_target_i(p_trap_target),
    .csr_mepc_i(p_csr_mepc),
    .cache_flush_valid_i(p_cache_flush_valid),
    .cache_flush_redirect_pc_i(p_cache_flush_redirect_pc),
    .ex_fire_o(p_ex_fire),
    .ex_exception_o(p_ex_exception),
    .ex_exception_fatal_o(p_ex_exception_fatal),
    .ex_mret_redirect_o(p_ex_mret_redirect),
    .ex_any_flush_o(p_ex_any_flush),
    .id_accept_o(p_id_accept),
    .if_id_consume_o(p_if_id_consume),
    .if_id_can_refill_o(p_if_id_can_refill),
    .ebreak_fire_o(p_ebreak_fire),
    .pipeline_normal_update_o(p_pipeline_normal_update),
    .if_redirect_valid_o(p_if_redirect_valid),
    .if_redirect_pc_o(p_if_redirect_pc),
    .ex_mem_leave_update_o(p_ex_mem_leave_update),
    .ex_mem_load_update_o(p_ex_mem_load_update),
    .mem_wb_from_mem_o(p_mem_wb_from_mem),
    .mem_wb_from_ex_o(p_mem_wb_from_ex),
    .mem_wb_load_o(p_mem_wb_load),
    .bpu_update_valid_o(p_bpu_update_valid)
  );

  function [`XLEN-1:0] imemory_word;
    input [`XLEN-1:0] addr;
    begin
      case (addr[5:2])
        4'd0: imemory_word = 32'h0000_0013;
        4'd1: imemory_word = 32'h0010_0093;
        4'd2: imemory_word = 32'h0020_0113;
        default: imemory_word = 32'h0000_0013;
      endcase
    end
  endfunction

  function [`XLEN-1:0] dmemory_word;
    input [`XLEN-1:0] addr;
    reg [`XLEN-1:0] word_index;
    begin
      word_index = (addr - 32'h8000_0000) >> 2;
      dmemory_word = 32'h0000_7000 + word_index;
    end
  endfunction

  task automatic emit_metric;
    input [1023:0] key;
    input integer value;
    begin
      $display("[METRIC] %0s=%0d", key, value);
      if (report_fd != 0) begin
        $fdisplay(report_fd, "%0s=%0d", key, value);
      end
    end
  endtask

  task automatic set_defaults;
    begin
      fe_flush = 1'b0;
      fe_redirect_valid = 1'b0;
      fe_redirect_pc = `RESET_PC;
      fe_consume = 1'b0;
      fe_halt = 1'b0;
      fe_fatal = 1'b0;
      imem_axi_arready = 1'b1;
      imem_axi_rvalid = 1'b0;
      imem_axi_rdata = 32'h0;
      imem_axi_rresp = 2'b00;
      imem_rsp_pending_q = 1'b0;
      imem_rsp_addr_q = 32'h0;

      update_en = 1'b1;
      clear = 1'b0;
      mem_ex_valid = 1'b0;
      mem_ex_load = 1'b0;
      mem_ex_store = 1'b0;
      mem_ex_size = `MEM_SIZE_WORD;
      mem_ex_unsigned = 1'b0;
      mem_ex_addr = 32'h0;
      mem_ex_store_data = 32'h0;
      dcache_invalidate = 1'b0;
      dmem_axi_arready = 1'b1;
      dmem_axi_rvalid = 1'b0;
      dmem_axi_rdata = 32'h0;
      dmem_axi_rresp = 2'b00;
      dmem_axi_awready = 1'b1;
      dmem_axi_wready = 1'b1;
      dmem_axi_bvalid = 1'b0;
      dmem_axi_bresp = 2'b00;
      dmem_rsp_pending_q = 1'b0;
      dmem_rsp_write_q = 1'b0;
      dmem_rsp_addr_q = 32'h0;
    end
  endtask

  task automatic reset_all;
    begin
      rst = 1'b1;
      set_defaults();
      `TB_TICK(clk);
      rst = 1'b0;
      `TB_TICK(clk);
      #1;
    end
  endtask

  task automatic wait_for_frontend_ifid;
    output integer cycles;
    begin
      cycles = 0;
      guard_cycles = 0;
      #1;
      while (!fe_if_id_valid && (guard_cycles < 200)) begin
        `TB_TICK(clk);
        #1;
        cycles = cycles + 1;
        guard_cycles = guard_cycles + 1;
      end
      tb_check1("frontend IF/ID valid reached", fe_if_id_valid, 1'b1);
    end
  endtask

  task automatic measure_frontend_hit_path;
    output integer hit_cycles;
    output integer duplicate_bubbles;
    begin
      wait_for_frontend_ifid(frontend_miss_wait_cycles);
      tb_check32("frontend first pc", fe_if_id_pc, `RESET_PC);
      tb_check32("frontend first inst", fe_if_id_inst, 32'h0000_0013);

      fe_halt = 1'b1;
      fe_consume = 1'b1;
      `TB_TICK(clk);
      fe_consume = 1'b0;
      #1;
      tb_check1("frontend pipe drained", fe_if_id_valid, 1'b0);

      fe_flush = 1'b1;
      fe_redirect_valid = 1'b1;
      fe_redirect_pc = `RESET_PC;
      `TB_TICK(clk);
      fe_flush = 1'b0;
      fe_redirect_valid = 1'b0;
      fe_halt = 1'b0;
      #1;

      // cache hit 必须在请求同拍形成 IF/ID load 脉冲，不能再落入 fetch buffer 等下一拍。
      tb_check1("frontend hit req valid", icache_cpu_req_valid, 1'b1);
      tb_check1("frontend hit rsp valid", icache_cpu_rsp_valid, 1'b1);
      tb_check1("frontend hit direct pipe", fe_pipe_valid, 1'b1);
      tb_check32("frontend hit pipe pc", fe_pipe_pc, `RESET_PC);
      hit_cycles = 0;

      `TB_TICK(clk);
      #1;
      tb_check1("frontend hit loaded ifid", fe_if_id_valid, 1'b1);
      tb_check32("frontend hit ifid inst", fe_if_id_inst, 32'h0000_0013);
      tb_check1("frontend hit not duplicated", fe_pipe_valid, 1'b0);
      duplicate_bubbles = fe_pipe_valid ? 1 : 0;
    end
  endtask

  task automatic wait_for_mem_response;
    output integer cycles;
    begin
      cycles = 0;
      guard_cycles = 0;
      #1;
      while (!mem_response && (guard_cycles < 160)) begin
        `TB_TICK(clk);
        #1;
        cycles = cycles + 1;
        guard_cycles = guard_cycles + 1;
      end
      tb_check1("mem response reached", mem_response, 1'b1);
    end
  endtask

  task automatic finish_mem_instruction;
    begin
      `TB_TICK(clk);
      mem_ex_valid = 1'b0;
      mem_ex_load = 1'b0;
      mem_ex_store = 1'b0;
      #1;
    end
  endtask

  task automatic issue_load;
    input [`XLEN-1:0] addr;
    input [`XLEN-1:0] expected_data;
    output integer cycles;
    begin
      mem_ex_valid = 1'b1;
      mem_ex_load = 1'b1;
      mem_ex_store = 1'b0;
      mem_ex_size = `MEM_SIZE_WORD;
      mem_ex_unsigned = 1'b0;
      mem_ex_addr = addr;
      mem_ex_store_data = 32'h0;
      wait_for_mem_response(cycles);
      tb_check1("load fault", mem_fault, 1'b0);
      tb_check32("load data", mem_load_data, expected_data);
      finish_mem_instruction();
    end
  endtask

  task automatic issue_store;
    input [`XLEN-1:0] addr;
    input [`XLEN-1:0] data;
    output integer cycles;
    begin
      mem_ex_valid = 1'b1;
      mem_ex_load = 1'b0;
      mem_ex_store = 1'b1;
      mem_ex_size = `MEM_SIZE_WORD;
      mem_ex_unsigned = 1'b0;
      mem_ex_addr = addr;
      mem_ex_store_data = data;
      wait_for_mem_response(cycles);
      tb_check1("store fault", mem_fault, 1'b0);
      finish_mem_instruction();
    end
  endtask

  task automatic pipeline_defaults;
    begin
      p_if_id_valid = 1'b1;
      p_id_ex_valid = 1'b1;
      p_id_ex_load = 1'b0;
      p_id_ex_ecall = 1'b0;
      p_id_ex_ebreak = 1'b0;
      p_id_ex_mret = 1'b0;
      p_id_ex_branch = 1'b0;
      p_id_ex_jal = 1'b0;
      p_id_ex_jalr = 1'b0;
      p_id_ex_rd_idx = 5'd5;
      p_id_ex_pred_pc = 32'h8000_0004;
      p_dec_uses_rs1 = 1'b0;
      p_dec_uses_rs2 = 1'b0;
      p_dec_rs1_idx = 5'd0;
      p_dec_rs2_idx = 5'd0;
      p_ex_mem_valid = 1'b0;
      p_ex_mem_is_mem = 1'b0;
      p_mem_response = 1'b0;
      p_mem_fault = 1'b0;
      p_ex_wait = 1'b0;
      p_halt = 1'b0;
      p_fatal = 1'b0;
      p_ex_fetch_fault = 1'b0;
      p_ex_illegal = 1'b0;
      p_ex_redirect_misaligned = 1'b0;
      p_ex_load_store_misaligned = 1'b0;
      p_ex_control_next_pc = 32'h8000_0004;
      p_ex_redirect_pc = 32'h8000_0100;
      p_trap_target = 32'h8000_1000;
      p_csr_mepc = 32'h8000_2000;
      p_cache_flush_valid = 1'b0;
      p_cache_flush_redirect_pc = 32'h8000_3000;
    end
  endtask

  task automatic measure_load_use_bubble;
    output integer bubbles;
    begin
      pipeline_defaults();
      p_id_ex_load = 1'b1;
      p_dec_uses_rs1 = 1'b1;
      p_dec_rs1_idx = 5'd5;
      #1;
      tb_check1("load-use accepts dependent into EX", p_id_accept, 1'b1);
      tb_check1("load-use lets load enter MEM", p_ex_fire, 1'b1);
      bubbles = 0;

      pipeline_defaults();
      p_ex_mem_valid = 1'b1;
      p_ex_mem_is_mem = 1'b1;
      p_mem_response = 1'b0;
      #1;
      tb_check1("dependent waits while load misses", p_ex_fire, 1'b0);
      tb_check1("busy EX keeps IF/ID stable", p_id_accept, 1'b0);

      pipeline_defaults();
      p_id_ex_valid = 1'b0;
      p_ex_mem_valid = 1'b1;
      p_ex_mem_is_mem = 1'b1;
      p_mem_response = 1'b1;
      p_dec_uses_rs1 = 1'b1;
      p_dec_rs1_idx = 5'd5;
      #1;
      tb_check1("load-use releases on MEM response", p_id_accept, 1'b1);
      tb_check1("MEM response can feed WB", p_mem_wb_from_mem, 1'b1);
    end
  endtask

  always @(posedge clk) begin
    if (rst) begin
      imem_axi_rvalid <= 1'b0;
      imem_axi_rdata <= 32'h0;
      imem_axi_rresp <= 2'b00;
      imem_rsp_pending_q <= 1'b0;
      imem_rsp_addr_q <= 32'h0;
    end else begin
      imem_axi_rvalid <= imem_rsp_pending_q;
      imem_axi_rdata <= imemory_word(imem_rsp_addr_q);
      imem_axi_rresp <= 2'b00;
      imem_rsp_pending_q <= imem_axi_arvalid & imem_axi_arready;
      imem_rsp_addr_q <= imem_axi_araddr;
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      dmem_axi_rvalid <= 1'b0;
      dmem_axi_rdata <= 32'h0;
      dmem_axi_rresp <= 2'b00;
      dmem_axi_bvalid <= 1'b0;
      dmem_axi_bresp <= 2'b00;
      dmem_rsp_pending_q <= 1'b0;
      dmem_rsp_write_q <= 1'b0;
      dmem_rsp_addr_q <= 32'h0;
    end else begin
      dmem_axi_rvalid <= dmem_rsp_pending_q & ~dmem_rsp_write_q;
      dmem_axi_rdata <= dmem_rsp_write_q ? 32'h0 : dmemory_word(dmem_rsp_addr_q);
      dmem_axi_rresp <= 2'b00;
      dmem_axi_bvalid <= dmem_rsp_pending_q & dmem_rsp_write_q;
      dmem_axi_bresp <= 2'b00;
      dmem_rsp_pending_q <= (dmem_axi_arvalid & dmem_axi_arready) |
                            (dmem_axi_awvalid & dmem_axi_awready &
                             dmem_axi_wvalid & dmem_axi_wready);
      dmem_rsp_write_q <= dmem_axi_awvalid & dmem_axi_awready &
                          dmem_axi_wvalid & dmem_axi_wready;
      dmem_rsp_addr_q <= (dmem_axi_arvalid & dmem_axi_arready) ?
                         dmem_axi_araddr :
                         dmem_axi_awaddr;
    end
  end

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    report_fd = 0;
    report_path = "stage_pipe_test_bubble_report.txt";
    if ($value$plusargs("REPORT=%s", report_path)) begin
    end
    report_fd = $fopen(report_path, "w");
    if (report_fd == 0) begin
      $display("[WARN] could not open report path: %0s", report_path);
    end else begin
      $fdisplay(report_fd, "# NPC single stage_pipe_test bubble report");
    end
    expect_frontend_hit_zero = $test$plusargs("EXPECT_FRONTEND_HIT_ZERO");

    reset_all();
    measure_frontend_hit_path(frontend_hit_wait_cycles, frontend_duplicate_bubbles);

    reset_all();
    issue_load(32'h8000_0010, dmemory_word(32'h8000_0010), mem_miss_wait_cycles);
    issue_load(32'h8000_0010, dmemory_word(32'h8000_0010), mem_hit_wait_cycles);
    issue_store(32'h8000_0010, 32'h1234_5678, mem_store_wait_cycles);
    measure_load_use_bubble(load_use_bubbles);

    removable_frontend_hit_bubbles = (frontend_hit_wait_cycles > 0) ? frontend_hit_wait_cycles : 0;
    removable_mem_hit_bubbles = ((mem_hit_wait_cycles > 0) ? mem_hit_wait_cycles : 0) +
                                ((mem_store_wait_cycles > 0) ? mem_store_wait_cycles : 0);

    emit_metric("frontend_icache_miss_wait_cycles", frontend_miss_wait_cycles);
    emit_metric("frontend_icache_hit_to_ifid_wait_cycles", frontend_hit_wait_cycles);
    emit_metric("frontend_duplicate_buffer_bubbles", frontend_duplicate_bubbles);
    emit_metric("mem_stage_load_miss_wait_cycles", mem_miss_wait_cycles);
    emit_metric("mem_stage_dcache_load_hit_wait_cycles", mem_hit_wait_cycles);
    emit_metric("mem_stage_dcache_store_hit_wait_cycles", mem_store_wait_cycles);
    emit_metric("id_stage_load_use_bubbles", load_use_bubbles);
    emit_metric("removable_frontend_hit_bubbles", removable_frontend_hit_bubbles);
    emit_metric("removable_mem_hit_bubbles", removable_mem_hit_bubbles);

    if (expect_frontend_hit_zero && (frontend_hit_wait_cycles != 0)) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] optimized frontend hit wait got=%0d expected=0",
               frontend_hit_wait_cycles);
    end

    if (report_fd != 0) begin
      $fclose(report_fd);
    end
    tb_finish("stage_pipe_test");
  end
endmodule
