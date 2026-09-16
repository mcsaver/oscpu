module tb_r64_rtc;
 reg clk_i=0;always #5 clk_i=~clk_i;reg rst_i=1;
 reg arvalid_i=0,awvalid_i=0,wvalid_i=0,rready_i=0,bready_i=0;
 reg [11:0] araddr_i=0,awaddr_i=0;reg [2:0] arsize_i=2,awsize_i=2;
 reg [63:0] wdata_i=0;reg [7:0] wstrb_i=0;
 wire arready_o,awready_o,wready_o,rvalid_o,bvalid_o,irq_o;
 wire [63:0] rdata_o;wire [1:0] rresp_o,bresp_o;
 R64AxiRtc dut(.*);
 integer writes=0,reads=0;
 task tick;begin @(posedge clk_i);#1;@(negedge clk_i);end endtask
 task write_word(input [11:0] address,input [31:0] value,input bit wfirst,input bit error);
 begin
 awaddr_i=address;wdata_i=address[2]?{value,32'b0}:{32'b0,value};
 wstrb_i=address[2]?8'hf0:8'h0f;
 if(wfirst)begin wvalid_i=1;while(!wready_o)tick();tick();wvalid_i=0;repeat(2)tick();awvalid_i=1;end
 else begin awvalid_i=1;while(!awready_o)tick();tick();awvalid_i=0;repeat(2)tick();wvalid_i=1;end
 if(wfirst)begin while(!awready_o)tick();tick();awvalid_i=0;end
 else begin while(!wready_o)tick();tick();wvalid_i=0;end
 while(!bvalid_o)tick();
 repeat(3)begin if(!bvalid_o||(bresp_o!=0)!=error)$fatal(1,"RTC held B error");tick();end
 bready_i=1;tick();bready_i=0;writes=writes+1;
 end endtask
 task read_word(input [11:0] address,output [31:0] value,input bit error);
 reg [63:0] held;
 begin
 araddr_i=address;arvalid_i=1;while(!arready_o)tick();tick();arvalid_i=0;
 while(!rvalid_o)tick();held=rdata_o;
 repeat(4)begin if(!rvalid_o||rdata_o!==held||(rresp_o!=0)!=error)$fatal(1,"RTC held R changed");tick();end
 value=address[2]?held[63:32]:held[31:0];rready_i=1;tick();rready_i=0;reads=reads+1;
 end endtask
 reg [31:0] value;
 initial begin
 repeat(3)tick();rst_i=0;#1;
 write_word(4,32'h12345678,0,0);write_word(0,32'h20000000,1,0);
 read_word(0,value,0);write_word(4,32'h87654321,1,0);read_word(4,value,0);
 if(value!=32'h12345678)$fatal(1,"RTC low-read high latch broken");
 write_word(12,32'hffffffff,0,0);write_word(8,32'hffffffff,1,0);
 write_word(16,1,0,0);read_word(24,value,0);
 if(value!=1||irq_o)$fatal(1,"future RTC alarm state");
 write_word(20,1,1,0);read_word(24,value,0);if(value!=0)$fatal(1,"RTC alarm cancel");
 write_word(12,0,1,0);write_word(8,0,0,0);read_word(24,value,0);
 if(value!=0||!irq_o)$fatal(1,"expired RTC alarm IRQ");
 write_word(28,1,0,0);if(irq_o)$fatal(1,"RTC IRQ clear");
 read_word(16,value,1);write_word(24,1,0,1);
 awsize_i=3;write_word(0,0,1,1);awsize_i=2;
 read_word(0,value,0);read_word(4,value,0);
 if(value!=32'h87654321)$fatal(1,"invalid RTC write had side effect");
 $display("RTC requests writes=%0d reads=%0d both AW/W orders and held responses PASS",writes,reads);
 $display("[PASS] tb_r64_rtc");$finish;
 end
 initial begin #100000;$fatal(1,"RTC test timeout");end
endmodule
