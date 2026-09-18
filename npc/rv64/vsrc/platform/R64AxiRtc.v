// Goldfish RTC register semantics, with an independent nanosecond clock.
// CLINT mtime writes cannot move this clock backwards. TIME writes explicitly
// set wall time; TIME_LOW snapshots HIGH, and ALARM_LOW arms the deadline.
module R64AxiRtc #(parameter [63:0] CLOCK_NS=64'd2)(
 input clk_i,input rst_i,
 input arvalid_i,output arready_o,input [11:0] araddr_i,input [2:0] arsize_i,
 output rvalid_o,input rready_i,output [63:0] rdata_o,output [1:0] rresp_o,
 input awvalid_i,output awready_o,input [11:0] awaddr_i,input [2:0] awsize_i,
 input wvalid_i,output wready_o,input [63:0] wdata_i,input [7:0] wstrb_i,
 output bvalid_o,input bready_i,output [1:0] bresp_o,output irq_o
);
 reg [63:0] time_q,alarm_q;reg [31:0] high_snapshot_q;
 reg armed_q,enabled_q,pending_q;
 wire rd,wr;wire [11:0] ra,wa;wire [2:0] rz,wz;wire [63:0] wd;wire [7:0] ws;
 wire read_error=rz!=2||ra[1:0]!=0||ra>24||(ra==16||ra==20);
 wire write_error=wz!=2||wa[1:0]!=0||wa>28||wa==24||
                  ws!=(wa[2]?8'hf0:8'h0f);
 reg [31:0] read_word;
 wire [31:0] write_word=wa[2]?wd[63:32]:wd[31:0];
 wire [63:0] read_value=ra[2]?{read_word,32'b0}:{32'b0,read_word};
 wire write_fire=wr&&!write_error;
 wire [64:0] next_time={1'b0,time_q}+{1'b0,CLOCK_NS};
 always @*begin
  read_word=0;
  case(ra)
   0:read_word=time_q[31:0];
   4:read_word=high_snapshot_q;
   8:read_word=alarm_q[31:0];
   12:read_word=alarm_q[63:32];
   24:read_word={31'b0,armed_q};
   default:begin end
  endcase
 end
 assign irq_o=enabled_q&&pending_q;
 R64AxiRegisterPort port(
  .clk_i(clk_i),.rst_i(rst_i),.arvalid_i(arvalid_i),.arready_o(arready_o),.araddr_i(araddr_i),.arsize_i(arsize_i),
  .rvalid_o(rvalid_o),.rready_i(rready_i),.rdata_o(rdata_o),.rresp_o(rresp_o),
  .awvalid_i(awvalid_i),.awready_o(awready_o),.awaddr_i(awaddr_i),.awsize_i(awsize_i),
  .wvalid_i(wvalid_i),.wready_o(wready_o),.wdata_i(wdata_i),.wstrb_i(wstrb_i),
  .bvalid_o(bvalid_o),.bready_i(bready_i),.bresp_o(bresp_o),
  .read_o(rd),.read_addr_o(ra),.read_size_o(rz),.read_data_i(read_value),.read_error_i(read_error),
  .write_o(wr),.write_addr_o(wa),.write_size_o(wz),.write_data_o(wd),.write_strb_o(ws),.write_error_i(write_error));
 always @(posedge clk_i)begin
  if(rst_i)begin time_q<=0;alarm_q<=0;high_snapshot_q<=0;armed_q<=0;enabled_q<=0;pending_q<=0;end
  else begin
   time_q<=next_time[64]?64'hffffffffffffffff:next_time[63:0];
   if(rd&&!read_error&&ra==0)high_snapshot_q<=time_q[63:32];
   if(armed_q&&time_q>=alarm_q)begin armed_q<=0;pending_q<=1;end
   if(write_fire)case(wa)
    0:time_q<={time_q[63:32],write_word};
    4:time_q<={write_word,time_q[31:0]};
    8:begin
     alarm_q[31:0]<=write_word;
     armed_q<=time_q<{alarm_q[63:32],write_word};
     if(time_q>={alarm_q[63:32],write_word})pending_q<=1;
    end
    12:alarm_q[63:32]<=write_word;
    16:enabled_q<=write_word[0];
    20:armed_q<=0;
    28:pending_q<=0;
    default:begin end
   endcase
  end
 end
endmodule
