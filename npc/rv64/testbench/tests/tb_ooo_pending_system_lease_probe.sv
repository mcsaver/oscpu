`timescale 1ns/1ps
`include "define.v"

// Focused v8k mutation/assertion probe.  It is intentionally not part of the
// default TESTS list because some modes manufacture malformed internal state
// and are expected to fail under OOO_ASSERT.
module tb_ooo_pending_system_lease_probe;
  localparam ROB_INDEX_W = `OOO_ROB_INDEX_W;
  localparam PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W;
  localparam PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W;
  localparam [PRODUCER_ID_W-1:0] PID =
      {1'b1, {(PRODUCER_ID_W-1){1'b0}}};

  reg clk;
  reg rst;
  reg clear;
  reg clear_dispatched;
  reg dispatch_fire;
  reg producer_death;
  reg capture_head0;
  wire valid;
  wire dispatched;
  wire csr;
  wire producer_valid;
  wire [PRODUCER_ID_W-1:0] producer_id;

  OooPendingSystemSequencer #(
    .ROB_INDEX_W(ROB_INDEX_W),
    .PRODUCER_GEN_W(PRODUCER_GEN_W),
    .PRODUCER_ID_W(PRODUCER_ID_W)
  ) dut (
    .clk(clk),
    .rst(rst),
    .clear_i(clear),
    .clear_dispatched_i(clear_dispatched),
    .dispatch_fire_i(dispatch_fire),
    .producer_death_i(producer_death),
    .dispatch_producer_id_i(PID),
    .refresh_rdata_i(1'b0),
    .refresh_rdata_value_i({`XLEN{1'b0}}),
    .capture_irq_i(1'b0),
    .capture_irq_pc_i({`XLEN{1'b0}}),
    .capture_irq_cause_i({`TRAP_CAUSE_W{1'b0}}),
    .capture_head0_i(capture_head0),
    .capture_head0_csr_i(1'b1),
    .capture_head0_ecall_i(1'b0),
    .capture_head0_mret_i(1'b0),
    .capture_head0_wfi_i(1'b0),
    .capture_head0_sfence_i(1'b0),
    .capture_head0_fencei_i(1'b0),
    .capture_head0_pc_i(64'h0000_0000_8000_1000),
    .capture_head0_inst_i(32'h3050_9073),
    .capture_head0_next_pc_i(64'h0000_0000_8000_1004),
    .capture_head0_csr_rdata_i({`XLEN{1'b0}}),
    .capture_lane1_i(1'b0),
    .capture_lane1_csr_i(1'b0),
    .capture_lane1_ecall_i(1'b0),
    .capture_lane1_mret_i(1'b0),
    .capture_lane1_wfi_i(1'b0),
    .capture_lane1_sfence_i(1'b0),
    .capture_lane1_fencei_i(1'b0),
    .capture_lane1_pc_i({`XLEN{1'b0}}),
    .capture_lane1_inst_i({`INST_W{1'b0}}),
    .capture_lane1_next_pc_i({`XLEN{1'b0}}),
    .capture_lane1_csr_rdata_i({`XLEN{1'b0}}),
    .valid_o(valid),
    .dispatched_o(dispatched),
    .csr_o(csr),
    .ecall_o(),
    .mret_o(),
    .wfi_o(),
    .sfence_o(),
    .fencei_o(),
    .irq_o(),
    .pc_o(),
    .inst_o(),
    .next_pc_o(),
    .csr_rdata_o(),
    .irq_cause_o(),
    .producer_valid_o(producer_valid),
    .producer_id_o(producer_id)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task automatic establish_live_lease;
    begin
      rst = 1'b1;
      clear = 1'b0;
      clear_dispatched = 1'b0;
      dispatch_fire = 1'b0;
      producer_death = 1'b0;
      capture_head0 = 1'b0;
      repeat (2) tick();
      rst = 1'b0;
      capture_head0 = 1'b1;
      tick();
      capture_head0 = 1'b0;
      dispatch_fire = 1'b1;
      tick();
      dispatch_fire = 1'b0;
      if (!valid || !dispatched || !csr || !producer_valid ||
          (producer_id != PID)) begin
        $fatal(1, "[V8K-PROBE-SETUP] failed to establish live PID=%h", PID);
      end
    end
  endtask

  initial begin
    establish_live_lease();
`ifdef V8K_PROBE_PARTIAL_METADATA
    force dut.valid_q = 1'b0;
    #1;
    if (!producer_valid || (producer_id != PID))
      $fatal(1, "[V8K-PROBE-PARTIAL-METADATA] raw lease output was metadata-gated");
    $display("PASS tb_ooo_pending_system_lease_probe");
    $finish;
`elsif V8K_PROBE_LIVE_CLEAR
    clear = 1'b1;
    tick();
    if (!producer_valid || (producer_id != PID))
      $fatal(1, "[V8K-PROBE-LIVE-CLEAR] ordinary clear killed live lease");
    $display("PASS tb_ooo_pending_system_lease_probe");
    $finish;
`elsif V8K_PROBE_LIVE_CLEAR_DISPATCHED
    clear_dispatched = 1'b1;
    tick();
    if (!producer_valid || !dispatched || (producer_id != PID))
      $fatal(1, "[V8K-PROBE-LIVE-CDISP] clear-dispatched killed live lease");
    $display("PASS tb_ooo_pending_system_lease_probe");
    $finish;
`elsif V8K_ASSERT_PARTIAL_METADATA
    force dut.valid_q = 1'b0;
    tick();
    $fatal(1, "[V8K-ASSERT-PARTIAL-METADATA] expected assertion did not fire");
`elsif V8K_ASSERT_LIVE_CLEAR
    clear = 1'b1;
    tick();
    $fatal(1, "[V8K-ASSERT-LIVE-CLEAR] expected assertion did not fire");
`else
    $fatal(1, "[V8K-PROBE] select one focused probe macro");
`endif
  end
endmodule
