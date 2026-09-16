`include "define.v"

// R4-S1 final-PA typed memory classifier。
// PMA 基础类型与 translated-leaf PBMT 只在此合并一次；模块纯组合、无 owner/FSM。
// 任何 pre-target fault 都撤销 attr，并把 class poison 为 RSVD，防止 consumer 误路由。
module OooTypedMemoryClassifier (
  input clk,
  input rst,
  input access_valid_i,
  input pma_fault_i,
  input pma_attr_valid_i,
  input [1:0] pma_class_i,
  // pbmt_valid_i 表示 translated leaf 的 PBMT 字段存在；Bare 必须为 0。
  input pbmt_valid_i,
  input pbmte_i,
  input [1:0] pbmt_i,
  output attr_valid_o,
  output [1:0] class_o,
  output fault_valid_o,
  output page_fault_o,
  output access_fault_o,
  // S1 迁移期兼容视图；只从 typed 结果/typed fault 单向派生。
  output pbmt_fault_o,
  output cacheable_o,
  output serialized_o
);

  wire pma_class_legal_w =
      (pma_class_i == `OOO_MEM_CLASS_CACHED) ||
      (pma_class_i == `OOO_MEM_CLASS_NC) ||
      (pma_class_i == `OOO_MEM_CLASS_IO);
  wire pma_admitted_w =
      pma_attr_valid_i && !pma_fault_i && pma_class_legal_w;

  // PBMTE 关闭不等价于 PBMT 字段不存在：translated leaf 的非零位必须 page fault。
  wire pbmt_disabled_nonzero_w =
      pbmt_valid_i && !pbmte_i && (pbmt_i != 2'b00);
  wire pbmt_enabled_reserved_w =
      pbmt_valid_i && pbmte_i && (pbmt_i == 2'b11);
  wire pbmt_page_fault_w =
      access_valid_i && (pbmt_disabled_nonzero_w || pbmt_enabled_reserved_w);

  wire pma_access_fault_w =
      access_valid_i && !pbmt_page_fault_w && !pma_admitted_w;
  wire final_admitted_w =
      access_valid_i && !pbmt_page_fault_w && pma_admitted_w;

  reg [1:0] class_r;
  always @(*) begin
    class_r = `OOO_MEM_CLASS_RSVD;
    if (final_admitted_w) begin
      if (!pbmt_valid_i || (pbmt_i == 2'b00)) begin
        class_r = pma_class_i;
      end else if (pbmte_i && (pbmt_i == 2'b01)) begin
        class_r = `OOO_MEM_CLASS_NC;
      end else if (pbmte_i && (pbmt_i == 2'b10)) begin
        class_r = `OOO_MEM_CLASS_IO;
      end
    end
  end

  assign page_fault_o = pbmt_page_fault_w;
  assign access_fault_o = pma_access_fault_w;
  assign fault_valid_o = page_fault_o || access_fault_o;
  assign attr_valid_o = final_admitted_w;
  // 不合法属性统一输出 poison；fault 资格与 class 编码保持正交。
  assign class_o = attr_valid_o ? class_r : `OOO_MEM_CLASS_RSVD;

  assign pbmt_fault_o = page_fault_o;
  assign cacheable_o = attr_valid_o && (class_o == `OOO_MEM_CLASS_CACHED);
  assign serialized_o = attr_valid_o && !cacheable_o;

`ifdef OOO_ASSERT
  always @(posedge clk) begin
    if (!rst) begin
      if ((access_valid_i === 1'b1) &&
          (pma_fault_i === pma_attr_valid_i))
        $error("[TYPED-PMA-ATTR-INCONSISTENT] active PMA fault/attr qualification disagrees @%0t",
               $time);
      if ((access_valid_i === 1'b1) &&
          (pma_attr_valid_i === 1'b1) &&
          (pma_class_i == `OOO_MEM_CLASS_RSVD))
        $error("[TYPED-PMA-RSVD-INPUT] PMA admitted RSVD class @%0t", $time);
      if (attr_valid_o && (class_o == `OOO_MEM_CLASS_RSVD))
        $error("[TYPED-CLASS-RSVD-VALID] RSVD class became routable @%0t", $time);
      if (!attr_valid_o && (class_o != `OOO_MEM_CLASS_RSVD))
        $error("[TYPED-CLASS-POISON] invalid attr did not poison class @%0t", $time);
      if (fault_valid_o && attr_valid_o)
        $error("[TYPED-CLASS-FAULT-ATTR] pre-target fault retained attr @%0t", $time);
      if (page_fault_o && access_fault_o)
        $error("[TYPED-CLASS-FAULT-PRIORITY] page/access faults overlap @%0t", $time);
      if ((cacheable_o !=
           (attr_valid_o && (class_o == `OOO_MEM_CLASS_CACHED))) ||
          (serialized_o != (attr_valid_o && !cacheable_o)))
        $error("[TYPED-CLASS-COMPAT] Boolean view diverged from typed result @%0t",
               $time);
      if ((access_valid_i === 1'b1) && pma_admitted_w &&
          pbmt_valid_i && pbmte_i && (pbmt_i == 2'b01) &&
          (!attr_valid_o || (class_o != `OOO_MEM_CLASS_NC)))
        $error("[TYPED-CLASS-PBMT-NC] PBMT-NC override was not preserved @%0t",
               $time);
    end
  end
`endif

endmodule
