// Onehot parallel metadata read; balanced OR avoids encoded select fanout
// through several independent wide mux trees. No storage or hidden read ports.
module R64LsuMetaRead #(parameter N=18,parameter DATA_W=162)(
 input [N-1:0] select_i,input [N*DATA_W-1:0] data_i,output [DATA_W-1:0] data_o
);
 function integer clog2;
 input integer value;integer v;
 begin v=value-1;clog2=0;while(v>0)begin v=v>>1;clog2=clog2+1;end end
 endfunction
 localparam LEAVES=1<<clog2(N);
 genvar n;
 generate for(n=1;n<2*LEAVES;n=n+1)begin:gen_tree
   wire [DATA_W-1:0] value_w;
   if(n>=LEAVES)begin:gen_leaf
     if(n-LEAVES<N)begin:gen_present
       assign value_w={DATA_W{select_i[n-LEAVES]}}&data_i[(n-LEAVES)*DATA_W+:DATA_W];
     end else begin:gen_unused
       assign value_w=0;
     end
   end else begin:gen_node
     assign value_w=gen_tree[2*n].value_w|gen_tree[2*n+1].value_w;
   end
 end endgenerate
 assign data_o=gen_tree[1].value_w;
endmodule
