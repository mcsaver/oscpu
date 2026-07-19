`include "define.v"

module tb_r4_s1p1_typed_negative;
  reg clk = 1'b0;
  reg rst = 1'b1;
  reg access_valid = 1'b0;
  reg pma_fault = 1'b0;
  reg pma_attr_valid = 1'b1;
  reg [1:0] pma_class = `OOO_MEM_CLASS_CACHED;
  reg pbmt_valid = 1'b0;
  reg pbmte = 1'b0;
  reg [1:0] pbmt = 2'b00;
  wire attr_valid;
  wire [1:0] mem_class;
  wire fault_valid;
  wire page_fault;
  wire access_fault;
  wire pbmt_fault;
  wire cacheable;
  wire serialized;
  string case_name;

  OooTypedMemoryClassifier dut (
    .clk(clk), .rst(rst), .access_valid_i(access_valid),
    .pma_fault_i(pma_fault), .pma_attr_valid_i(pma_attr_valid),
    .pma_class_i(pma_class), .pbmt_valid_i(pbmt_valid),
    .pbmte_i(pbmte), .pbmt_i(pbmt), .attr_valid_o(attr_valid),
    .class_o(mem_class), .fault_valid_o(fault_valid),
    .page_fault_o(page_fault), .access_fault_o(access_fault),
    .pbmt_fault_o(pbmt_fault), .cacheable_o(cacheable),
    .serialized_o(serialized)
  );

  initial begin
    if (!$value$plusargs("CASE=%s", case_name))
      $fatal(1, "missing +CASE");
    #1 clk = 1'b1;
    #1 clk = 1'b0;
    rst = 1'b0;
    access_valid = 1'b1;

    if (case_name == "pma_inconsistent") begin
      pma_fault = 1'b1;
      pma_attr_valid = 1'b1;
    end else if (case_name == "pma_rsvd") begin
      pma_fault = 1'b0;
      pma_attr_valid = 1'b1;
      pma_class = `OOO_MEM_CLASS_RSVD;
    end else if (case_name == "class_poison") begin
      pma_fault = 1'b1;
      pma_attr_valid = 1'b0;
      pma_class = `OOO_MEM_CLASS_RSVD;
      force dut.class_o = `OOO_MEM_CLASS_CACHED;
    end else begin
      $fatal(1, "unknown CASE=%0s", case_name);
    end

    #1 clk = 1'b1;
    #1 clk = 1'b0;
    $display("[R4-S1.1-NEGATIVE-SENTINEL] case=%0s", case_name);
    $finish;
  end
endmodule
