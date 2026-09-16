module tb_false_green;
  initial begin
    $display("FAIL tb_false_green errors=1");
    $finish(1);
  end
endmodule
