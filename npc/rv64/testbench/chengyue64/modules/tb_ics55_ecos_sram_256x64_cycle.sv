`timescale 1ns/1ps
module tb_ics55_ecos_sram_256x64_cycle;
  reg clk=0;
  always #5 clk=~clk;
  reg ceb=1,gweb=1,mare=0;
  reg [3:0] mar=0;
  reg [7:0] address=0;
  reg [63:0] data=0,web=~64'b0;
  wire [63:0] actual,reference;
  ics55_ecos_sram_256x64_m4 dut (
    .CLK(clk),.CEB(ceb),.GWEB(gweb),.WEB(web),.A(address),
    .D(data),.Q(actual),.MARE(mare),.MAR(mar)
  );
  ics55_ecos_sram_256x64_m4_reference oracle (
    .CLK(clk),.CEB(ceb),.GWEB(gweb),.WEB(web),.A(address),
    .D(data),.Q(reference),.MARE(mare),.MAR(mar)
  );
  integer checks=0,i;
  reg [31:0] random_q=32'hacd50321;
  reg [63:0] retained;
  function [31:0] next_random(input [31:0] value);
    reg [31:0] v;
    begin
      v=value^(value<<13);v=v^(v>>17);next_random=v^(v<<5);
    end
  endfunction
  task cycle(input disabled,input read_mode,input [7:0] row,
             input [63:0] value,input [63:0] bit_mask);
    begin
      @(negedge clk);
      ceb=disabled;gweb=read_mode;address=row;data=value;web=bit_mask;
      @(posedge clk);#1;
      if(actual!==reference)
        $fatal(1,"vendor mismatch CEB=%b GWEB=%b WEB=%h A=%h q=%h ref=%h",
               ceb,gweb,web,address,actual,reference);
      checks=checks+1;
    end
  endtask
  initial begin
    for(i=0;i<256;i=i+1) cycle(0,0,8'(i),64'h0123456789000000+64'(i),0);
    for(i=0;i<256;i=i+1) cycle(0,1,8'(i),0,~64'b0);
    // Unwritten Q bits retain the previous output, not the newly selected row.
    cycle(0,1,8'd17,0,0);retained=actual;
    cycle(0,0,8'd231,~64'b0,~64'b1);
    if(actual!==((retained & ~64'b1)|64'b1)) $fatal(1,"masked Q hold semantics");
    cycle(0,0,8'd73,0,~64'b0);
    if(actual!==reference) $fatal(1,"all-masked write Q mismatch");
    for(i=0;i<64;i=i+1) cycle(0,0,8'(i),~64'b0,~(64'b1<<i));
    for(i=0;i<2048;i=i+1) begin
      random_q=next_random(random_q);
      mare=random_q[3];mar=random_q[7:4];
      cycle(random_q[0]&&random_q[1],random_q[2],random_q[15:8],
            {random_q,~random_q},{random_q^32'h926abd08,random_q});
    end
    for(i=0;i<256;i=i+1) cycle(0,1,8'(i),0,0);
    $display("[PASS] tb_ics55_ecos_sram_256x64_cycle checks=%0d",checks);
    $finish;
  end
endmodule
