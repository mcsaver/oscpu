// Tile partial-product generation and compression share one mapping boundary.
// Keeping padding constant here avoids synthesizing impossible full-width rows.
module R64ProductTree #(parameter WIDTH=64,parameter BWIDTH=WIDTH)(
  input [WIDTH-1:0] a_i,input [BWIDTH-1:0] b_i,
  output [WIDTH+BWIDTH-1:0] sum_o,carry_o
);
  localparam FULL=WIDTH+BWIDTH,ROWS=BWIDTH;
  function integer count;
    input integer level;
    integer n,k;
    begin n=ROWS;for(k=0;k<level;k=k+1)n=2*(n/3)+(n%3);count=n;end
  endfunction
  function integer depth;
    input integer n;
    integer k;
    begin k=0;while(n>2)begin n=2*(n/3)+(n%3);k=k+1;end depth=k;end
  endfunction
  localparam LEVELS=depth(ROWS);
  genvar s,j;
  generate for(s=0;s<=LEVELS;s=s+1)begin:level
    localparam N=count(s);
    wire [FULL-1:0] row[0:N-1];
    if(s==0)begin:initial_rows
      for(j=0;j<ROWS;j=j+1)begin:source
        assign row[j]=({{BWIDTH{1'b0}},(a_i&{WIDTH{b_i[j]}})}<<j);
      end
    end else begin:compress
      localparam PREV=count(s-1),GROUPS=PREV/3;
      for(j=0;j<GROUPS;j=j+1)begin:triple
        wire [FULL-1:0] a=level[s-1].row[3*j];
        wire [FULL-1:0] b=level[s-1].row[3*j+1];
        wire [FULL-1:0] c=level[s-1].row[3*j+2];
        assign row[2*j]=a^b^c;
        assign row[2*j+1]=((a&b)|(a&c)|(b&c))<<1;
      end
      for(j=0;j<PREV%3;j=j+1)begin:remainder_rows
        assign row[2*GROUPS+j]=level[s-1].row[3*GROUPS+j];
      end
    end
  end endgenerate
  assign sum_o=level[LEVELS].row[0];
  generate if(ROWS==1)assign carry_o=0;
  else assign carry_o=level[LEVELS].row[1];endgenerate
endmodule

// Balanced 3:2 reductions preserve the complete unsigned sum modulo 2^WIDTH.
module R64CsaReduce #(parameter WIDTH=128,parameter ROWS=8,parameter STRIPE=0,parameter ACTIVE=WIDTH)(
  input [ROWS*WIDTH-1:0] rows_i,
  output [WIDTH-1:0] sum_o,carry_o
);
  function integer count;
    input integer level;
    integer n,k;
    begin n=ROWS;for(k=0;k<level;k=k+1)n=2*(n/3)+(n%3);count=n;end
  endfunction
  function integer depth;
    input integer n;
    integer k;
    begin k=0;while(n>2)begin n=2*(n/3)+(n%3);k=k+1;end depth=k;end
  endfunction
  localparam LEVELS=depth(ROWS);
  genvar s,j;
  generate for(s=0;s<=LEVELS;s=s+1)begin:level
    localparam N=count(s);
    wire [WIDTH-1:0] row[0:N-1];
    if(s==0)begin:initial_rows
      for(j=0;j<ROWS;j=j+1)begin:source
        // Tile pair j/2 occupies ACTIVE bits starting at STRIPE*(j/2).
        // The caller drives padding zero too; this mask preserves that fact
        // when this pure combinational module is mapped independently.
        localparam [WIDTH-1:0] MASK=({WIDTH{1'b1}}>>(WIDTH-ACTIVE))<<((j/2)*STRIPE);
        assign row[j]=rows_i[j*WIDTH+:WIDTH]&MASK;
      end
    end else begin:compress
      localparam PREV=count(s-1),GROUPS=PREV/3;
      for(j=0;j<GROUPS;j=j+1)begin:triple
        wire [WIDTH-1:0] a=level[s-1].row[3*j];
        wire [WIDTH-1:0] b=level[s-1].row[3*j+1];
        wire [WIDTH-1:0] c=level[s-1].row[3*j+2];
        assign row[2*j]=a^b^c;
        assign row[2*j+1]=((a&b)|(a&c)|(b&c))<<1;
      end
      for(j=0;j<PREV%3;j=j+1)begin:remainder_rows
        assign row[2*GROUPS+j]=level[s-1].row[3*GROUPS+j];
      end
    end
  end endgenerate
  assign sum_o=level[LEVELS].row[0];
  generate if(ROWS==1)assign carry_o=0;
  else assign carry_o=level[LEVELS].row[1];endgenerate
endmodule
