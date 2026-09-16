// Two independent 32-bit add domains and unsigned comparison facts.
// A 32-bit prefix generates both high carry-in alternatives without a
// low32 -> high32 carry chain. No state or handshake belongs to this helper.
module R64DcacheAmoParts(input [63:0] a_i,b_i,output [99:0] parts_o);
 genvar half,level,bitno;
 generate for(half=0;half<2;half=half+1)begin:gen_half
   wire [31:0] bit_p=a_i[half*32+:32]^b_i[half*32+:32];
   wire [31:0] bit_g=a_i[half*32+:32]&b_i[half*32+:32];
   for(level=0;level<=5;level=level+1)begin:gen_prefix
     wire [31:0] p,g;
     if(level==0)begin:gen_leaf
       assign p=bit_p;assign g=bit_g;
     end else begin:gen_level
       for(bitno=0;bitno<32;bitno=bitno+1)begin:gen_bit
         if(bitno>=(1<<(level-1)))begin:gen_merge
           assign p[bitno]=gen_prefix[level-1].p[bitno]&gen_prefix[level-1].p[bitno-(1<<(level-1))];
           assign g[bitno]=gen_prefix[level-1].g[bitno]|
             (gen_prefix[level-1].p[bitno]&gen_prefix[level-1].g[bitno-(1<<(level-1))]);
         end else begin:gen_copy
           assign p[bitno]=gen_prefix[level-1].p[bitno];
           assign g[bitno]=gen_prefix[level-1].g[bitno];
         end
       end
     end
   end
   if(half==0)begin:gen_low
     assign parts_o[31:0]=bit_p^{gen_prefix[5].g[30:0],1'b0};
     assign parts_o[32]=gen_prefix[5].g[31];
   end else begin:gen_high
     assign parts_o[64:33]=bit_p^{gen_prefix[5].g[30:0],1'b0};
     assign parts_o[96:65]=bit_p^{gen_prefix[5].g[30:0]|gen_prefix[5].p[30:0],1'b1};
   end
 end endgenerate
 assign parts_o[97]=a_i[31:0]<b_i[31:0];
 assign parts_o[98]=a_i[63:32]<b_i[63:32];
 assign parts_o[99]=a_i[63:32]==b_i[63:32];
endmodule
