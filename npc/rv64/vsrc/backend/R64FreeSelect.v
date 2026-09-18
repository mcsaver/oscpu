// First two free physical slots from a single saturated prefix network.
// Each prefix summarizes zero, one, or at least two bits. No first winner
// is removed and fed through a second complete priority encoder.
module R64FreeSelect #(parameter N=64)(
 input [N-1:0] free_i,output [N-1:0] first_o,second_o,
 output any_o,two_o
);
 localparam LEVELS=$clog2(N);
 genvar level;
 generate for(level=0;level<=LEVELS;level=level+1)begin:g_prefix
  wire [N-1:0] any_w,two_w;
  if(level==0)begin
   assign any_w=free_i;assign two_w=0;
  end else begin
   localparam DISTANCE=1<<(level-1);
   assign any_w=g_prefix[level-1].any_w|(g_prefix[level-1].any_w<<DISTANCE);
   assign two_w=g_prefix[level-1].two_w|(g_prefix[level-1].two_w<<DISTANCE)|
       (g_prefix[level-1].any_w&(g_prefix[level-1].any_w<<DISTANCE));
  end
 end endgenerate
 wire [N-1:0] previous_any_w=g_prefix[LEVELS].any_w<<1;
 wire [N-1:0] previous_two_w=g_prefix[LEVELS].two_w<<1;
 assign first_o=free_i&~previous_any_w;
 assign second_o=free_i&previous_any_w&~previous_two_w;
 assign any_o=g_prefix[LEVELS].any_w[N-1];
 assign two_o=g_prefix[LEVELS].two_w[N-1];
endmodule
