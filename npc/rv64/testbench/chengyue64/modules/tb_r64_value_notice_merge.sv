`timescale 1ns/1ps
module tb_r64_value_notice_merge;
  parameter EARLY_VALUE=1;
  reg [1:0] occupied=0,resident=0,early=0;
  wire [1:0] valid;
  wire [17:0] tags;
  wire [127:0] values;
  integer checks=0;
  R64ValueNoticeMerge #(.EARLY_VALUE(EARLY_VALUE)) dut(
    .resident_occupied_i(occupied),.resident_valid_i(resident),
    .resident_tag_i({9'd11,9'd10}),.resident_data_i({64'd111,64'd110}),
    .early_valid_i(early),.early_tag_i({9'd21,9'd20}),.early_data_i({64'd211,64'd210}),
    .valid_o(valid),.tag_o(tags),.data_o(values));
  reg [1:0] available;
  integer expected_tag,expected_value;
  initial begin
    for(integer o=0;o<4;o=o+1)for(integer r=0;r<4;r=r+1)for(integer e=0;e<4;e=e+1)begin
      occupied=2'(o);resident=2'(r)&occupied;early=2'(e);#1;
      available=EARLY_VALUE?early:0;
      for(integer l=0;l<2;l=l+1)begin
        expected_tag=10+l;expected_value=110+l;
        if(occupied[l])begin
          if(valid[l]!==resident[l])$fatal(1,"resident cancel/fault altered candidate");
        end else if(available!=0)begin
          if(available[0])begin expected_tag=20;expected_value=210;available[0]=0;end
          else begin expected_tag=21;expected_value=211;available[1]=0;end
          if(!valid[l])$fatal(1,"vacant lane lost accepted value");
        end else if(valid[l])$fatal(1,"invented notice without source");
        if(tags[l*9+:9]!==9'(expected_tag)||values[l*64+:64]!==64'(expected_value))
          $fatal(1,"notice priority or payload changed");
        checks=checks+1;
      end
    end
    $display("[PASS] tb_r64_value_notice_merge enable=%0d checks=%0d",EARLY_VALUE,checks);$finish;
  end
endmodule
