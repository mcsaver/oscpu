// Projection of a frozen whole-UOP interface to its externally consumed fields.
  function [2*`R64_MEM_CMD_W-1:0] reference_mem_command;
    input [2*`R64_UOP_W-1:0] uops;
    input [383:0] operands;
    integer lane;
    reg [`R64_UOP_W-1:0] uop;
    reg [191:0] operand;
    begin
      for (lane=0; lane<2; lane=lane+1) begin
        uop=uops[lane*`R64_UOP_W+:`R64_UOP_W];
        operand=operands[lane*192+:192];
        reference_mem_command[lane*`R64_MEM_CMD_W+:`R64_MEM_CMD_W]=
            {uop[155+:5],uop[`R64_U_FUNC],operand[127:64],uop[`R64_U_ARG],operand[63:0]};
      end
    end
  endfunction
  function [`R64_SERIAL_CMD_W-1:0] reference_serial_command;
    input [`R64_UOP_W-1:0] uop;
    input [191:0] operands;
    begin
      reference_serial_command={(uop[`R64_U_LEN] == 8),uop[`R64_U_FUNC],
          operands[79:64],operands[63:0],uop[`R64_U_CMD],uop[`R64_U_PC]};
    end
  endfunction
