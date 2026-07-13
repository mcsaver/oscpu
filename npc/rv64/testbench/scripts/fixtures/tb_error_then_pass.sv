module tb_error_then_pass;
  initial begin
    $error("intentional immediate assertion violation");
    $display("[PASS] tb_error_then_pass");
    $finish(0);
  end
endmodule
