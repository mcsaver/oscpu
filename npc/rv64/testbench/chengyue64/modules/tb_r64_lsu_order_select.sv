`timescale 1ns/1ps
module tb_r64_lsu_order_select;
 parameter N=18;localparam W=$clog2(N);
 reg [N-1:0] valid=0;reg [N*N-1:0] older=0,younger=0;
 reg [N*8-1:0] byte_data=0;wire byte_valid;wire [7:0] byte_result;wire [N-1:0] byte_winner;
 wire v0,v1;wire [W-1:0] s0,s1;wire [N-1:0] fmask,smask;
 R64LsuOrderSelect #(.N(N),.SLOT_W(W)) dut(
  .valid_i(valid),.older_i(older),.first_mask_o(fmask),.second_mask_o(smask),.first_valid_o(v0),.second_valid_o(v1),
  .first_slot_o(s0),.second_slot_o(s1));
 R64LsuForwardByte #(.N(N),.SLOT_W(W)) byte_dut(
  .valid_i(valid),.younger_i(younger),.data_i(byte_data),.valid_o(byte_valid),
  .data_o(byte_result),.winner_mask_o(byte_winner));
 integer rank[0:N-1];integer i,j,n,k,tmp,b0,b1,youngest;
 reg [31:0] rng=32'h876532ad;
 task randomize_word;
  begin rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};end
 endtask
 task check;
  begin
   for(i=0;i<N;i=i+1)begin
    byte_data[i*8+:8]=8'(rank[i]+31*i);
    for(j=0;j<N;j=j+1)begin
     older[i*N+j]=rank[j]<rank[i];younger[i*N+j]=rank[j]>rank[i];
    end
   end
   youngest=-1;
   for(i=0;i<N;i=i+1)if(valid[i])begin
    if(youngest<0)youngest=i;
    else if(rank[i]>rank[youngest])youngest=i;
   end
   b0=-1;b1=-1;
   for(i=0;i<N;i=i+1)if(valid[i])begin
    if(b0<0)begin b0=i;end
    else if(rank[i]<rank[b0])begin b1=b0;b0=i;end
    else if(b1<0)begin b1=i;end
    else if(rank[i]<rank[b1])b1=i;
   end
   #1;
   if(byte_valid!==(youngest>=0)||byte_winner!==(youngest<0?N'(0):(N'(1)<<youngest))||
      (youngest>=0&&byte_result!==byte_data[youngest*8+:8]))
    $fatal(1,"youngest byte matrix mismatch");
   if(fmask!==(b0<0?{N{1'b0}}:(N'(1)<<b0))||smask!==(b1<0?{N{1'b0}}:(N'(1)<<b1)))
    $fatal(1,"order onehot mismatch");
   if(v0!==(b0>=0)||v1!==(b1>=0)||
     (b0>=0&&s0!==W'(b0))||(b1>=0&&s1!==W'(b1)))
    $fatal(1,"order top2 mismatch valid%h got%0d/%0d wanted%0d/%0d",valid,s0,s1,b0,b1);
  end
 endtask
 initial begin
  for(i=0;i<N;i=i+1)rank[i]=i;
  check();
  for(n=0;n<N;n=n+1)begin valid=1<<n;check();end
  for(n=0;n<4096;n=n+1)begin
   for(k=N-1;k>0;k=k-1)begin
    randomize_word();j=rng%(k+1);tmp=rank[k];rank[k]=rank[j];rank[j]=tmp;
   end
   randomize_word();valid=rng[N-1:0];check();
  end
  $display("[PASS] tb_r64_lsu_order_select N=%0d random permutations/masks=4096",N);
  $finish;
 end
endmodule
