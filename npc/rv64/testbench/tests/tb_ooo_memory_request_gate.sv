`include "define.v"

module tb_ooo_memory_request_gate;
  `include "tb_common.svh"

  reg core_local_flush;
  reg checkpoint_mem_flush;
  reg pending_system_satp_write_commit;
  reg pending_system_sfence_commit;

  reg stop_pending;
  reg pending_fp;
  reg backend_drained;
  reg pending_fp_mem_pending;
  reg pending_fp_mem_done;
  reg pending_fp_store;
  reg [`XLEN-1:0] pending_fp_mem_aligned_addr;
  reg [`XLEN-1:0] pending_fp_mem_wdata;
  reg [`STRB_W-1:0] pending_fp_mem_wstrb;

  reg core_mem_req_valid;
  reg core_mem_req_write;
  reg [`XLEN-1:0] core_mem_req_addr;
  reg [`XLEN-1:0] core_mem_req_wdata;
  reg [`STRB_W-1:0] core_mem_req_wstrb;
  reg core_mem_rsp_ready;

  reg mem_req_ready;
  reg mem_rsp_valid;

  wire pending_fp_mem_req_valid;
  wire pending_fp_mem_req_fire;
  wire pending_fp_mem_rsp_fire;
  wire mem_req_valid;
  wire mem_req_write;
  wire [`XLEN-1:0] mem_req_addr;
  wire [`XLEN-1:0] mem_req_wdata;
  wire [`STRB_W-1:0] mem_req_wstrb;
  wire mem_rsp_ready;
  wire mem_flush;
  wire mmu_flush;

  OooMemoryRequestGate dut (
    .core_local_flush_i(core_local_flush),
    .checkpoint_mem_flush_i(checkpoint_mem_flush),
    .pending_system_satp_write_commit_i(pending_system_satp_write_commit),
    .pending_system_sfence_commit_i(pending_system_sfence_commit),
    .stop_pending_i(stop_pending),
    .pending_fp_i(pending_fp),
    .backend_drained_i(backend_drained),
    .pending_fp_mem_pending_i(pending_fp_mem_pending),
    .pending_fp_mem_done_i(pending_fp_mem_done),
    .pending_fp_store_i(pending_fp_store),
    .pending_fp_mem_aligned_addr_i(pending_fp_mem_aligned_addr),
    .pending_fp_mem_wdata_i(pending_fp_mem_wdata),
    .pending_fp_mem_wstrb_i(pending_fp_mem_wstrb),
    .core_mem_req_valid_i(core_mem_req_valid),
    .core_mem_req_write_i(core_mem_req_write),
    .core_mem_req_addr_i(core_mem_req_addr),
    .core_mem_req_wdata_i(core_mem_req_wdata),
    .core_mem_req_wstrb_i(core_mem_req_wstrb),
    .core_mem_rsp_ready_i(core_mem_rsp_ready),
    .mem_req_ready_i(mem_req_ready),
    .mem_rsp_valid_i(mem_rsp_valid),
    .pending_fp_mem_req_valid_o(pending_fp_mem_req_valid),
    .pending_fp_mem_req_fire_o(pending_fp_mem_req_fire),
    .pending_fp_mem_rsp_fire_o(pending_fp_mem_rsp_fire),
    .mem_req_valid_o(mem_req_valid),
    .mem_req_write_o(mem_req_write),
    .mem_req_addr_o(mem_req_addr),
    .mem_req_wdata_o(mem_req_wdata),
    .mem_req_wstrb_o(mem_req_wstrb),
    .mem_rsp_ready_o(mem_rsp_ready),
    .mem_flush_o(mem_flush),
    .mmu_flush_o(mmu_flush)
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

  task automatic tb_checkstrb;
    input [1023:0] what;
    input [`STRB_W-1:0] got;
    input [`STRB_W-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%0x expected=0x%0x",
                 what, got, exp);
      end
    end
  endtask

  task automatic clear_inputs;
    begin
      core_local_flush = 1'b0;
      checkpoint_mem_flush = 1'b0;
      pending_system_satp_write_commit = 1'b0;
      pending_system_sfence_commit = 1'b0;
      stop_pending = 1'b0;
      pending_fp = 1'b0;
      backend_drained = 1'b0;
      pending_fp_mem_pending = 1'b0;
      pending_fp_mem_done = 1'b0;
      pending_fp_store = 1'b0;
      pending_fp_mem_aligned_addr = 64'h0000_0000_8000_1000;
      pending_fp_mem_wdata = 64'h1122_3344_5566_7788;
      pending_fp_mem_wstrb = 8'hff;
      core_mem_req_valid = 1'b0;
      core_mem_req_write = 1'b0;
      core_mem_req_addr = 64'h0000_0000_8000_2000;
      core_mem_req_wdata = 64'haaaa_bbbb_cccc_dddd;
      core_mem_req_wstrb = 8'h0f;
      core_mem_rsp_ready = 1'b0;
      mem_req_ready = 1'b0;
      mem_rsp_valid = 1'b0;
    end
  endtask

  task automatic set_pending_fp_ready;
    begin
      stop_pending = 1'b1;
      pending_fp = 1'b1;
      backend_drained = 1'b1;
      pending_fp_mem_pending = 1'b0;
      pending_fp_mem_done = 1'b0;
    end
  endtask

  initial begin
    tb_errors = 0;

    clear_inputs();
    core_mem_req_valid = 1'b1;
    core_mem_req_write = 1'b1;
    core_mem_rsp_ready = 1'b1;
    #1;
    tb_check1("core lane0 valid passthrough", mem_req_valid, 1'b1);
    tb_check1("core lane0 write passthrough", mem_req_write, 1'b1);
    tb_check64("core lane0 addr passthrough", mem_req_addr, core_mem_req_addr);
    tb_check64("core lane0 wdata passthrough", mem_req_wdata, core_mem_req_wdata);
    tb_checkstrb("core lane0 wstrb passthrough", mem_req_wstrb, core_mem_req_wstrb);
    tb_check1("core lane0 rsp ready passthrough", mem_rsp_ready, 1'b1);

    clear_inputs();
    set_pending_fp_ready();
    pending_fp_store = 1'b1;
    mem_req_ready = 1'b1;
    core_mem_req_valid = 1'b1;
    core_mem_req_write = 1'b0;
    #1;
    tb_check1("pending fp req valid", pending_fp_mem_req_valid, 1'b1);
    tb_check1("pending fp req fire", pending_fp_mem_req_fire, 1'b1);
    tb_check1("pending fp overrides valid", mem_req_valid, 1'b1);
    tb_check1("pending fp store write", mem_req_write, 1'b1);
    tb_check64("pending fp addr", mem_req_addr, pending_fp_mem_aligned_addr);
    tb_check64("pending fp wdata", mem_req_wdata, pending_fp_mem_wdata);
    tb_checkstrb("pending fp wstrb", mem_req_wstrb, pending_fp_mem_wstrb);

    clear_inputs();
    set_pending_fp_ready();
    pending_fp_store = 1'b0;
    #1;
    tb_check1("pending fp load write low", mem_req_write, 1'b0);
    tb_check1("pending fp no ready no fire", pending_fp_mem_req_fire, 1'b0);

    clear_inputs();
    set_pending_fp_ready();
    pending_fp_mem_pending = 1'b1;
    mem_rsp_valid = 1'b1;
    core_mem_rsp_ready = 1'b0;
    #1;
    tb_check1("pending fp pending blocks new req", pending_fp_mem_req_valid, 1'b0);
    tb_check1("pending fp rsp ready forced", mem_rsp_ready, 1'b1);
    tb_check1("pending fp rsp fire", pending_fp_mem_rsp_fire, 1'b1);

    clear_inputs();
    set_pending_fp_ready();
    pending_fp_mem_done = 1'b1;
    #1;
    tb_check1("pending fp done blocks req", pending_fp_mem_req_valid, 1'b0);

    clear_inputs();
    stop_pending = 1'b1;
    pending_fp = 1'b1;
    backend_drained = 1'b0;
    #1;
    tb_check1("backend not drained blocks fp req", pending_fp_mem_req_valid, 1'b0);

    clear_inputs();
    core_local_flush = 1'b1;
    #1;
    tb_check1("core local mem flush", mem_flush, 1'b1);
    core_local_flush = 1'b0;
    checkpoint_mem_flush = 1'b1;
    #1;
    tb_check1("checkpoint mem flush", mem_flush, 1'b1);

    clear_inputs();
    pending_system_satp_write_commit = 1'b1;
    #1;
    tb_check1("satp mmu flush", mmu_flush, 1'b1);
    pending_system_satp_write_commit = 1'b0;
    pending_system_sfence_commit = 1'b1;
    #1;
    tb_check1("sfence mmu flush", mmu_flush, 1'b1);

    tb_finish("tb_ooo_memory_request_gate");
  end
endmodule
