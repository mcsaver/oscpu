`include "define.v"
`include "common/OooBranchDirectionPredictorFacts.vh"

module tb_ooo_branch_local_pht;
  `include "tb_common.svh"

  reg clk;
  reg rst;
  reg clear;
  reg [`BPU_LOCAL_PHT_INDEX_W-1:0] lookup0_idx;
  wire lookup0_valid;
  wire [1:0] lookup0_ctr;
  reg [`BPU_LOCAL_PHT_INDEX_W-1:0] lookup1_idx;
  wire lookup1_valid;
  wire [1:0] lookup1_ctr;
  reg update_valid;
  reg [`BPU_LOCAL_PHT_INDEX_W-1:0] update_idx;
  reg update_taken;

  integer case_errors;

  OooBranchLocalPht dut (
    .clk(clk),
    .rst(rst),
    .clear_i(clear),
    .lookup0_idx_i(lookup0_idx),
    .lookup0_valid_o(lookup0_valid),
    .lookup0_ctr_o(lookup0_ctr),
    .lookup1_idx_i(lookup1_idx),
    .lookup1_valid_o(lookup1_valid),
    .lookup1_ctr_o(lookup1_ctr),
    .update_valid_i(update_valid),
    .update_idx_i(update_idx),
    .update_taken_i(update_taken)
  );

  task automatic tick;
    begin
      `TB_TICK(clk)
    end
  endtask

  task automatic settle;
    begin
      #1;
    end
  endtask

  task automatic check2;
    input [1023:0] what;
    input [1:0] got;
    input [1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=%0d expected=%0d", what, got, exp);
      end
    end
  endtask

  task automatic check8;
    input [1023:0] what;
    input [7:0] got;
    input [7:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%02x expected=0x%02x",
                 what, got, exp);
      end
    end
  endtask

  task automatic case_begin;
    begin
      case_errors = tb_errors;
    end
  endtask

  task automatic case_end;
    input [1023:0] marker;
    begin
      if (tb_errors == case_errors)
        $display("%0s PASS", marker);
      else
        $display("%0s FAIL", marker);
    end
  endtask

  task automatic pulse_clear;
    begin
      update_valid = 1'b0;
      clear = 1'b1;
      tick();
      clear = 1'b0;
      settle();
    end
  endtask

  task automatic train_complete;
    input [`BPU_LOCAL_PHT_INDEX_W-1:0] idx;
    input taken;
    begin
      update_idx = idx;
      update_taken = taken;
      update_valid = 1'b1;
      tick();
      update_valid = 1'b0;
      tick();
      settle();
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    clear = 1'b0;
    lookup0_idx = 12'h123;
    lookup1_idx = 12'h456;
    update_valid = 1'b0;
    update_idx = 12'h000;
    update_taken = 1'b0;
    tick();
    tick();
    rst = 1'b0;
    settle();

    // A1: 两个地址在同一拍内任意改变；输出不依赖 clock/仲裁。
    case_begin();
    tb_check1("zero-cycle lane0 reset invalid", lookup0_valid, 1'b0);
    tb_check1("zero-cycle lane1 reset invalid", lookup1_valid, 1'b0);
    lookup0_idx = 12'hA12;
    lookup1_idx = 12'hA34;
    settle();
    tb_check1("zero-cycle same-bank lane0 invalid", lookup0_valid, 1'b0);
    tb_check1("zero-cycle same-bank lane1 invalid", lookup1_valid, 1'b0);
    tb_check1("bank read-only valid view resets invalid",
              dut.g_bank[10].u_bank.valid_view_o[8'h12], 1'b0);
    tb_check1("wrapper flat valid view resets invalid",
              dut.flat_valid_view_w[12'hA12], 1'b0);
    case_end("[BPU-LPHT-A1-DUAL-ZERO-CYCLE]");

    // A2: index[11:8] 必须只选 bank，index[7:0] 必须成为 bank-local row；
    // resolve edge 只进入 S1，下一沿 S2 才可见。
    pulse_clear();
    lookup0_idx = 12'hA12;
    update_idx = 12'hA12;
    update_taken = 1'b1;
    update_valid = 1'b1;
    tick();
    update_valid = 1'b0;
    settle();
    case_begin();
    tb_check1("S1 must not make update visible", lookup0_valid, 1'b0);
    tb_check1("bank A owns pending S1",
              dut.g_bank[10].u_bank.upd_valid_q, 1'b1);
    tb_check1("unselected bank has no pending S1",
              dut.g_bank[2].u_bank.upd_valid_q, 1'b0);
    check8("bank-local S1 row", dut.g_bank[10].u_bank.upd_row_q, 8'h12);
    tb_check1("bank-local S1 taken", dut.g_bank[10].u_bank.upd_taken_q, 1'b1);
    case_end("[BPU-LPHT-A2-BANK-ROW-S1]");
    tick();
    settle();
    case_begin();
    tb_check1("S2 makes trained entry valid", lookup0_valid, 1'b1);
    check2("S2 taken from init2 saturates to3", lookup0_ctr, 2'd3);
    case_end("[BPU-LPHT-A3-UPDATE-S1-S2]");

    // A3B: bank 只导出 Q 端 read-only view；wrapper 的 bank-major 拼接必须
    // 与完整 12-bit index 数值同序，不能把 bank/row 再分层做 lane selector。
    case_begin();
    tb_check1("bank Q valid view exposes trained row",
              dut.g_bank[10].u_bank.valid_view_o[8'h12], 1'b1);
    check2("bank Q counter view exposes trained row",
           dut.g_bank[10].u_bank.counter_view_o[(2*8'h12)+:2], 2'd3);
    tb_check1("flat valid view preserves full-index order",
              dut.flat_valid_view_w[12'hA12], 1'b1);
    check2("flat counter view preserves full-index order",
           dut.flat_counter_view_w[(2*12'hA12)+:2], 2'd3);
    case_end("[BPU-LPHT-A3B-BANK-Q-FLAT-READ-VIEW]");

    // A4: 同 bank/different row 与同 bank/same row 都必须有两个独立组合 view。
    pulse_clear();
    train_complete(12'hA12, 1'b0);
    train_complete(12'hA34, 1'b1);
    lookup0_idx = 12'hA12;
    lookup1_idx = 12'hA34;
    settle();
    case_begin();
    tb_check1("same-bank different-row lane0 valid", lookup0_valid, 1'b1);
    check2("same-bank different-row lane0 counter", lookup0_ctr, 2'd1);
    tb_check1("same-bank different-row lane1 valid", lookup1_valid, 1'b1);
    check2("same-bank different-row lane1 counter", lookup1_ctr, 2'd3);
    lookup1_idx = 12'hA12;
    settle();
    tb_check1("same-bank same-row lane1 valid", lookup1_valid, 1'b1);
    check2("same-bank same-row lane1 counter", lookup1_ctr, 2'd1);
    case_end("[BPU-LPHT-A4-SAME-BANK-DUAL-READ]");

    // A4B: 已训练的不同 bank/different counter 必须在同一拍双路可见。
    // 从地址切换到检查之间不允许 tick，直接约束 0-cycle 组合读路径。
    pulse_clear();
    train_complete(12'hA12, 1'b0);
    train_complete(12'hB55, 1'b1);
    lookup0_idx = 12'hA12;
    lookup1_idx = 12'hB55;
    settle();
    case_begin();
    tb_check1("different-bank lane0 valid without tick", lookup0_valid, 1'b1);
    check2("different-bank lane0 counter without tick", lookup0_ctr, 2'd1);
    tb_check1("different-bank lane1 valid without tick", lookup1_valid, 1'b1);
    check2("different-bank lane1 counter without tick", lookup1_ctr, 2'd3);
    case_end("[BPU-LPHT-A4B-DIFFERENT-BANK-DUAL-ZERO-CYCLE]");

    // A5: 两端均为真正饱和，不允许 2-bit wrap。
    pulse_clear();
    train_complete(12'hB55, 1'b1);
    train_complete(12'hB55, 1'b1);
    lookup0_idx = 12'hB55;
    settle();
    case_begin();
    check2("taken counter saturates at3", lookup0_ctr, 2'd3);
    train_complete(12'hB55, 1'b0);
    train_complete(12'hB55, 1'b0);
    train_complete(12'hB55, 1'b0);
    train_complete(12'hB55, 1'b0);
    check2("not-taken counter saturates at0", lookup0_ctr, 2'd0);
    case_end("[BPU-LPHT-A5-SATURATING-COUNTER]");

    // A6: 连续同 entry 更新无 forwarding。第二个 S1 读到同沿 S2 写回前的
    // invalid/init2，因此两个 NT 最终仍是 1（既有可容忍丢增量行为）。
    pulse_clear();
    lookup0_idx = 12'hC66;
    update_idx = 12'hC66;
    update_taken = 1'b0;
    update_valid = 1'b1;
    tick();
    tick();
    update_valid = 1'b0;
    tick();
    settle();
    case_begin();
    tb_check1("back-to-back entry valid", lookup0_valid, 1'b1);
    check2("back-to-back no-forwarding lost increment", lookup0_ctr, 2'd1);
    case_end("[BPU-LPHT-A6-RAW-NO-FORWARD]");

    // A7: clear 必须清除 bank-local pending S2；clear 后的空拍不得复活写回。
    pulse_clear();
    lookup0_idx = 12'hD77;
    update_idx = 12'hD77;
    update_taken = 1'b1;
    update_valid = 1'b1;
    tick();
    update_valid = 1'b0;
    clear = 1'b1;
    tick();
    clear = 1'b0;
    tick();
    settle();
    case_begin();
    tb_check1("clear drops pending S2", lookup0_valid, 1'b0);
    case_end("[BPU-LPHT-A7-CLEAR-PENDING-S2]");

    // A8: lookup 在 S2 写沿之前看 old payload，写沿之后才看新 payload。
    pulse_clear();
    train_complete(12'hE80, 1'b0);
    lookup0_idx = 12'hE80;
    update_idx = 12'hE80;
    update_taken = 1'b1;
    update_valid = 1'b1;
    tick();
    update_valid = 1'b0;
    settle();
    case_begin();
    check2("lookup before S2 sees old counter", lookup0_ctr, 2'd1);
    tick();
    settle();
    check2("lookup after S2 sees new counter", lookup0_ctr, 2'd2);
    case_end("[BPU-LPHT-A8-LOOKUP-S2-READ-BEFORE-WRITE]");

    tb_finish("tb_ooo_branch_local_pht");
  end

endmodule
