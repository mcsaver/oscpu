`timescale 1ns/1ps
module tb_r64_lsu_select;
 parameter N=18;localparam SW=5;
 reg [N-1:0] valid=0;reg [N*5-1:0] age=0;reg [N*8-1:0] data=0;
 wire v0,v1,yv;wire [4:0] s0,s1,a0,a1,ya;wire [7:0] yd;
 R64LsuSelect #(.N(N),.SLOT_W(SW)) select(.valid_i(valid),.age_i(age),
 .first_valid_o(v0),.second_valid_o(v1),.first_slot_o(s0),.second_slot_o(s1),.first_age_o(a0),.second_age_o(a1));
 R64LsuYoungestByte #(.N(N),.SLOT_W(SW)) youngest(.valid_i(valid),.age_i(age),.data_i(data),.valid_o(yv),.data_o(yd),.age_o(ya));
 reg [31:0] rng=32'h94639bad;integer t,i,e0,e1,ey;
 task check;
 begin
  #1;e0=-1;e1=-1;ey=-1;
  for(i=0;i<N;i=i+1)if(valid[i])begin
   if(e0<0||age[i*5+:5]<age[e0*5+:5])begin e1=e0;e0=i;end
   else if(e1<0||age[i*5+:5]<age[e1*5+:5])e1=i;
   if(ey<0||age[i*5+:5]>age[ey*5+:5])ey=i;
  end
  if(v0!==(e0>=0)||v1!==(e1>=0)||yv!==(ey>=0))$fatal(1,"tree validity");
  if(e0>=0&&(s0!==e0[4:0]||a0!==age[e0*5+:5]))$fatal(1,"first winner");
  if(e1>=0&&(s1!==e1[4:0]||a1!==age[e1*5+:5]))$fatal(1,"second winner");
  if(ey>=0&&(yd!==data[ey*8+:8]||ya!==age[ey*5+:5]))$fatal(1,"youngest byte");
  if(e0<0&&(s0!=0||s1!=0||yd!=0))$fatal(1,"invalid padded leaf escaped");
 end
 endtask
 initial begin
  check();
  for(t=0;t<N;t=t+1)begin valid=0;valid[t]=1;check();end
  for(t=0;t<4096;t=t+1)begin
   for(i=0;i<N;i=i+1)begin
    rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
    valid[i]=rng[8];age[i*5+:5]=rng[4:0];data[i*8+:8]=rng[23:16];
   end
   check();
  end
  $display("[PASS] tb_r64_lsu_select N=%0d 4096 masks/ages plus empty and all onehot",N);$finish;
 end
endmodule
