// One native Sdtrig 1.0 address trigger. Software enumerates tselect=0;
// type 6 is the current encoding, type 2 supports existing native debuggers.
// All accesses match their lowest virtual byte, at every supported size.
// Unsupported action/select/match/chain/size/dmode/hit fields read as zero.
module R64Trigger(
 input clk_i,input rst_i,input write_control_i,input write_address_i,
 input [63:0] write_value_i,input [1:0] privilege_i,
 input machine_ie_i,input supervisor_ie_i,input breakpoint_delegated_i,
 output [63:0] control_o,output [63:0] address_o,output [2:0] enable_o
);
 reg [3:0] type_q;
 reg [2:0] modes_q,access_q;
 reg [63:0] address_q;
 assign control_o={type_q,53'b0,modes_q[2],1'b0,modes_q[1:0],access_q};
 assign address_o=address_q;
 // Sdtrig native reentrancy option 1 preserves ordinary exception delegation.
 // MPRV affects translation, never the privilege in which a trigger executes.
 wire privilege_enabled_w=privilege_i==3 ? modes_q[2]&&machine_ie_i:
     (privilege_i==1 ? modes_q[1]&&(!breakpoint_delegated_i||supervisor_ie_i):
      privilege_i==0&&modes_q[0]);
 assign enable_o={3{(type_q==2||type_q==6)&&privilege_enabled_w}}&access_q;
 always @(posedge clk_i)begin
  if(rst_i)begin type_q<=15;modes_q<=0;access_q<=0;address_q<=0;end
  else begin
   if(write_address_i)address_q<=write_value_i;
   if(write_control_i)begin
    if(write_value_i[63:60]==2||write_value_i[63:60]==6)begin
     type_q<=write_value_i[63:60];
     modes_q<={write_value_i[6],write_value_i[4:3]};
     access_q<=write_value_i[2:0];
    end else begin type_q<=15;modes_q<=0;access_q<=0;end
   end
  end
 end
endmodule
