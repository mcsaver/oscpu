integer tb_errors;

task automatic tb_check1;
  input [1023:0] what;
  input got;
  input exp;
  begin
    if (got !== exp) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] %0s got=%0b expected=%0b", what, got, exp);
    end
  end
endtask

task automatic tb_check32;
  input [1023:0] what;
  input [31:0] got;
  input [31:0] exp;
  begin
    if (got !== exp) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] %0s got=0x%08x expected=0x%08x", what, got, exp);
    end
  end
endtask

task automatic tb_finish;
  input [1023:0] name;
  begin
    if (tb_errors == 0) begin
      $display("[PASS] %0s", name);
      $finish;
    end else begin
      $display("[FAIL] %0s errors=%0d", name, tb_errors);
      $fatal(1);
    end
  end
endtask

`define TB_TICK(clk) \
  begin \
    #1 clk = 1'b1; \
    #1 clk = 1'b0; \
  end
