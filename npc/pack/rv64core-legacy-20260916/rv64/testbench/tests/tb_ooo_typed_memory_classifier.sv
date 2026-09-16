`include "define.v"
`include "tb_common.svh"

module tb_ooo_typed_memory_classifier;
  reg clk;
  reg rst;
  reg access_valid;
  reg pma_fault;
  reg pma_attr_valid;
  reg [1:0] pma_class;
  reg pbmt_valid;
  reg pbmte;
  reg [1:0] pbmt;
  wire attr_valid;
  wire [1:0] mem_class;
  wire fault_valid;
  wire page_fault;
  wire access_fault;
  wire pbmt_fault;
  wire cacheable;
  wire serialized;

  integer base_case;
  integer pbmt_case;
  integer enabled_matrix_count;
  integer disabled_leaf_count;

  OooTypedMemoryClassifier dut (
    .clk(clk),
    .rst(rst),
    .access_valid_i(access_valid),
    .pma_fault_i(pma_fault),
    .pma_attr_valid_i(pma_attr_valid),
    .pma_class_i(pma_class),
    .pbmt_valid_i(pbmt_valid),
    .pbmte_i(pbmte),
    .pbmt_i(pbmt),
    .attr_valid_o(attr_valid),
    .class_o(mem_class),
    .fault_valid_o(fault_valid),
    .page_fault_o(page_fault),
    .access_fault_o(access_fault),
    .pbmt_fault_o(pbmt_fault),
    .cacheable_o(cacheable),
    .serialized_o(serialized)
  );

  function automatic base_class_legal;
    input [1:0] value;
    begin
      base_class_legal =
          (value == `OOO_MEM_CLASS_CACHED) ||
          (value == `OOO_MEM_CLASS_NC) ||
          (value == `OOO_MEM_CLASS_IO);
    end
  endfunction

  task automatic check_current;
    input [1023:0] what;
    reg exp_page_fault;
    reg exp_pma_admitted;
    reg exp_access_fault;
    reg exp_attr_valid;
    reg [1:0] exp_class;
    reg exp_cacheable;
    begin
      // 独立 reference：按冻结表先判 PBMT/PTE fault，再判 PMA，最后做类型覆盖。
      exp_page_fault = access_valid && pbmt_valid &&
          ((!pbmte && (pbmt != 2'b00)) ||
           (pbmte && (pbmt == 2'b11)));
      exp_pma_admitted =
          pma_attr_valid && !pma_fault && base_class_legal(pma_class);
      exp_access_fault =
          access_valid && !exp_page_fault && !exp_pma_admitted;
      exp_attr_valid =
          access_valid && !exp_page_fault && exp_pma_admitted;
      exp_class = `OOO_MEM_CLASS_RSVD;
      if (exp_attr_valid) begin
        if (!pbmt_valid || (pbmt == 2'b00))
          exp_class = pma_class;
        else if (pbmt == 2'b01)
          exp_class = `OOO_MEM_CLASS_NC;
        else if (pbmt == 2'b10)
          exp_class = `OOO_MEM_CLASS_IO;
      end
      exp_cacheable =
          exp_attr_valid && (exp_class == `OOO_MEM_CLASS_CACHED);

      #1;
      tb_check1(what, page_fault, exp_page_fault);
      tb_check1(what, access_fault, exp_access_fault);
      tb_check1(what, fault_valid, exp_page_fault || exp_access_fault);
      tb_check1(what, attr_valid, exp_attr_valid);
      tb_check1(what, pbmt_fault, exp_page_fault);
      tb_check1(what, cacheable, exp_cacheable);
      tb_check1(what, serialized, exp_attr_valid && !exp_cacheable);
      if (mem_class !== exp_class) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s class=%02b expected=%02b",
                 what, mem_class, exp_class);
      end

      // 在输入稳定后给立即断言一个采样沿，避免组合过渡被误判。
      #1 clk = 1'b1;
      #1 clk = 1'b0;
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    access_valid = 1'b0;
    pma_fault = 1'b0;
    pma_attr_valid = 1'b1;
    pma_class = `OOO_MEM_CLASS_CACHED;
    pbmt_valid = 1'b0;
    pbmte = 1'b0;
    pbmt = 2'b00;
    #1 clk = 1'b1;
    #1 clk = 1'b0;
    rst = 1'b0;

    access_valid = 1'b0;
    pma_fault = 1'b1;
    pma_attr_valid = 1'b0;
    pma_class = `OOO_MEM_CLASS_RSVD;
    pbmt_valid = 1'b1;
    pbmte = 1'b0;
    pbmt = 2'b11;
    check_current("inactive is fault-free and poisoned");

    // 冻结合同的 PBMTE-enabled 4×4：PMA 包含 CACHED/NC/IO/DENY 四行。
    access_valid = 1'b1;
    pbmt_valid = 1'b1;
    pbmte = 1'b1;
    enabled_matrix_count = 0;
    for (base_case = 0; base_case < 4; base_case = base_case + 1) begin
      if (base_case < 3) begin
        pma_fault = 1'b0;
        pma_attr_valid = 1'b1;
        pma_class = base_case[1:0];
      end else begin
        pma_fault = 1'b1;
        pma_attr_valid = 1'b0;
        pma_class = `OOO_MEM_CLASS_RSVD;
      end
      for (pbmt_case = 0; pbmt_case < 4;
           pbmt_case = pbmt_case + 1) begin
        pbmt = pbmt_case[1:0];
        check_current("PBMTE-enabled PMA x PBMT 4x4 matrix");
        enabled_matrix_count = enabled_matrix_count + 1;
      end
    end

    // PBMTE-disabled 不是 Bare：translated leaf 的 PBMT 字段仍存在。四种 PMA 行中
    // PBMT=00 继承（DENY 为 access fault），01/10/11 均以 reserved-PTE page fault 优先。
    pbmte = 1'b0;
    disabled_leaf_count = 0;
    for (base_case = 0; base_case < 4; base_case = base_case + 1) begin
      if (base_case < 3) begin
        pma_fault = 1'b0;
        pma_attr_valid = 1'b1;
        pma_class = base_case[1:0];
      end else begin
        pma_fault = 1'b1;
        pma_attr_valid = 1'b0;
        pma_class = `OOO_MEM_CLASS_RSVD;
      end
      for (pbmt_case = 0; pbmt_case < 4;
           pbmt_case = pbmt_case + 1) begin
        pbmt = pbmt_case[1:0];
        check_current("PBMTE-disabled translated-leaf cases");
        disabled_leaf_count = disabled_leaf_count + 1;
      end
    end

    // Bare 不存在 leaf PBMT 字段，位值和 PBMTE 都不得改变 PMA 基础类型。
    pbmt_valid = 1'b0;
    pbmte = 1'b0;
    pbmt = 2'b11;
    pma_class = `OOO_MEM_CLASS_NC;
    check_current("Bare ignores absent PBMT bits");

    // 合法 PMA deny + PBMT reserved：PTE page fault 必须先于 target access fault。
    pbmt_valid = 1'b1;
    pbmte = 1'b1;
    pbmt = 2'b11;
    pma_fault = 1'b1;
    pma_attr_valid = 1'b0;
    pma_class = `OOO_MEM_CLASS_RSVD;
    check_current("PBMT page fault has priority over PMA deny");

    pbmt = 2'b00;
    check_current("PMA deny is access fault with no attr");

    // Svpbmt 明确允许基础 IO 被 PBMT-NC 覆盖为 NC，不能私自 clamp 回 IO。
    pma_fault = 1'b0;
    pma_attr_valid = 1'b1;
    pma_class = `OOO_MEM_CLASS_IO;
    pbmt = 2'b01;
    check_current("base IO plus PBMT-NC becomes NC");
    if (!attr_valid || (mem_class != `OOO_MEM_CLASS_NC)) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] explicit IO+PBMT-NC counterexample");
    end

`ifdef TYPED_FAILCLOSED_INPUT_TEST
    // 本组用无 OOO_ASSERT 的第二编译运行验证 consumer 本身仍 fail-closed；
    // assertion-negative runner 另证明 producer 合同违约会响精确 marker。
    pbmt_valid = 1'b0;
    pbmte = 1'b0;
    pbmt = 2'b00;
    pma_fault = 1'b1;
    pma_attr_valid = 1'b1;
    pma_class = `OOO_MEM_CLASS_CACHED;
    check_current("contradictory PMA fault+attr fails closed");

    pma_fault = 1'b0;
    pma_attr_valid = 1'b0;
    pma_class = `OOO_MEM_CLASS_RSVD;
    check_current("missing PMA fault+attr fails closed");

    pma_fault = 1'b0;
    pma_attr_valid = 1'b1;
    pma_class = `OOO_MEM_CLASS_RSVD;
    check_current("routable PMA RSVD input fails closed");
`endif

    $display("[R4-S1.1-TYPED-CLASS] enabled_matrix=%0d disabled_leaf=%0d + Bare/deny/priority/IO-NC PASS",
             enabled_matrix_count, disabled_leaf_count);
    tb_finish("tb_ooo_typed_memory_classifier");
  end
endmodule
