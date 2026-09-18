// A 64-bit architectural counter with byte-local addition. Each boundary
// caches whether its lower bits are one, two or three increments from wrap.
// The cache describes the current value, including software writes; it adds
// no architectural cycle and accepts any increment from zero through three.
module R64Counter(
 input clk_i,input rst_i,input enable_i,input [1:0] increment_i,
 input write_i,input [63:0] write_value_i,output reg [63:0] value_o
);
 wire [1:0] step_w=enable_i ? increment_i:2'b0;
 wire [63:0] next_w;
 wire [20:0] running_near_w,writing_near_w;
 wire [20:0] step_near_w[0:3];
 wire [3:0] step_select_w=4'b1<<step_w;
 genvar choice;
 generate for(choice=0;choice<4;choice=choice+1)begin:g_choice
  R64CounterNear #(.STEP(2'(choice))) summary(.value_i(value_o),.near_o(step_near_w[choice]));
 end endgenerate
 assign running_near_w=({21{step_select_w[0]}}&step_near_w[0])|({21{step_select_w[1]}}&step_near_w[1])|
  ({21{step_select_w[2]}}&step_near_w[2])|({21{step_select_w[3]}}&step_near_w[3]);
 R64CounterNear writing_summary(.value_i(write_value_i),.near_o(writing_near_w));
 assign next_w[7:0]=value_o[7:0]+{6'b0,step_w};
 genvar bank,offset;
 generate for(bank=1;bank<8;bank=bank+1)begin:g_bank
  localparam N=bank*8;
  reg [2:0] near_wrap_q;
  wire carry_w=(step_w!=0&&near_wrap_q[0])||
               (step_w[1]&&near_wrap_q[1])||
               (step_w==3&&near_wrap_q[2]);
  assign next_w[N+:8]=value_o[N+:8]+{7'b0,carry_w};
  for(offset=0;offset<3;offset=offset+1)begin:g_near
   // Adding at most three cannot wrap into the top three values. Only
   // the low three bits change their equality target; higher bits are ones.
   always @(posedge clk_i)begin
    if(rst_i)near_wrap_q[offset]<=0;
    else if(write_i)near_wrap_q[offset]<=writing_near_w[(bank-1)*3+offset];
    else near_wrap_q[offset]<=running_near_w[(bank-1)*3+offset];
   end
  end
 end endgenerate
 always @(posedge clk_i)begin
  if(rst_i)value_o<=0;
  else if(write_i)value_o<=write_value_i;
  else value_o<=next_w;
 end
endmodule
