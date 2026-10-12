// Non-owning numerical observations. Resident completion notices keep their
// original lane and priority. Newly accepted physical terminal values may fill
// vacant lanes; omission creates no retry/ack because canonical completion lives on.
module R64ValueNoticeMerge #(parameter TAG_W=9, parameter EARLY_VALUE=1) (
  input [1:0] resident_occupied_i, resident_valid_i,
  input [2*TAG_W-1:0] resident_tag_i,
  input [127:0] resident_data_i,
  input [1:0] early_valid_i,
  input [2*TAG_W-1:0] early_tag_i,
  input [127:0] early_data_i,
  output reg [1:0] valid_o,
  output reg [2*TAG_W-1:0] tag_o,
  output reg [127:0] data_o
);
  reg [1:0] unused_early;
  integer lane;
  always @* begin
    valid_o=resident_valid_i;
    tag_o=resident_tag_i;
    data_o=resident_data_i;
    unused_early=early_valid_i & {2{EARLY_VALUE != 0}};
    for(lane=0;lane<2;lane=lane+1)begin
      if(!resident_occupied_i[lane])begin
        if(unused_early[0])begin
          valid_o[lane]=1;
          tag_o[lane*TAG_W+:TAG_W]=early_tag_i[0+:TAG_W];
          data_o[lane*64+:64]=early_data_i[0+:64];
          unused_early[0]=0;
        end else if(unused_early[1])begin
          valid_o[lane]=1;
          tag_o[lane*TAG_W+:TAG_W]=early_tag_i[TAG_W+:TAG_W];
          data_o[lane*64+:64]=early_data_i[64+:64];
          unused_early[1]=0;
        end
      end
    end
  end
endmodule
