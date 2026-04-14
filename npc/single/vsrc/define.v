`ifndef __NPC_SINGLE_DEFINE_V__
`define __NPC_SINGLE_DEFINE_V__

// 用统一宏收口 ISA 编码、控制枚举和状态编码，后续补 CSR/异常时不用到处找 magic number。
`define XLEN               32
`define INST_W             32
`define PC_W               32
`define REG_NUM            32
`define REG_ADDR_W         5
`define SHIFT_AMT_W        5
`define TRAP_CAUSE_W       5
`define CORE_STATE_W       4

`define RESET_PC           32'h8000_0000
`define PC_STEP            32'd4

`define OPCODE_LOAD        7'b0000011
`define OPCODE_MISC_MEM    7'b0001111
`define OPCODE_OP_IMM      7'b0010011
`define OPCODE_AUIPC       7'b0010111
`define OPCODE_STORE       7'b0100011
`define OPCODE_OP          7'b0110011
`define OPCODE_LUI         7'b0110111
`define OPCODE_BRANCH      7'b1100011
`define OPCODE_JALR        7'b1100111
`define OPCODE_JAL         7'b1101111
`define OPCODE_SYSTEM      7'b1110011

`define FUNCT3_ADD_SUB     3'b000
`define FUNCT3_SLL         3'b001
`define FUNCT3_SLT         3'b010
`define FUNCT3_SLTU        3'b011
`define FUNCT3_XOR         3'b100
`define FUNCT3_SRL_SRA     3'b101
`define FUNCT3_OR          3'b110
`define FUNCT3_AND         3'b111

`define FUNCT3_BEQ         3'b000
`define FUNCT3_BNE         3'b001
`define FUNCT3_BLT         3'b100
`define FUNCT3_BGE         3'b101
`define FUNCT3_BLTU        3'b110
`define FUNCT3_BGEU        3'b111

`define FUNCT3_LB          3'b000
`define FUNCT3_LH          3'b001
`define FUNCT3_LW          3'b010
`define FUNCT3_LBU         3'b100
`define FUNCT3_LHU         3'b101

`define FUNCT3_SB          3'b000
`define FUNCT3_SH          3'b001
`define FUNCT3_SW          3'b010

`define FUNCT3_FENCE       3'b000
`define FUNCT3_FENCE_I     3'b001

`define FUNCT7_STD         7'b0000000
`define FUNCT7_ALT         7'b0100000

`define SYSTEM_FUNCT12_ECALL   12'h000
`define SYSTEM_FUNCT12_EBREAK  12'h001

`define IMM_TYPE_X         3'b000
`define IMM_TYPE_I         3'b001
`define IMM_TYPE_S         3'b010
`define IMM_TYPE_B         3'b011
`define IMM_TYPE_U         3'b100
`define IMM_TYPE_J         3'b101

`define OP1_SEL_RS1        2'b00
`define OP1_SEL_PC         2'b01
`define OP1_SEL_ZERO       2'b10

`define OP2_SEL_RS2        2'b00
`define OP2_SEL_IMM        2'b01
`define OP2_SEL_FOUR       2'b10

`define ALU_OP_ADD         4'h0
`define ALU_OP_SLL         4'h1
`define ALU_OP_SLT         4'h2
`define ALU_OP_SLTU        4'h3
`define ALU_OP_XOR         4'h4
`define ALU_OP_SRL         4'h5
`define ALU_OP_OR          4'h6
`define ALU_OP_AND         4'h7
`define ALU_OP_SUB         4'h8
`define ALU_OP_SRA         4'hd
`define ALU_OP_COPY_B      4'he
`define ALU_OP_COPY_A      4'hf

`define CMP_OP_NONE        3'b000
`define CMP_OP_EQ          3'b001
`define CMP_OP_NE          3'b010
`define CMP_OP_LT          3'b011
`define CMP_OP_GE          3'b100
`define CMP_OP_LTU         3'b101
`define CMP_OP_GEU         3'b110

`define MEM_SIZE_BYTE      2'b00
`define MEM_SIZE_HALF      2'b01
`define MEM_SIZE_WORD      2'b10

`define WB_SEL_NONE        3'b000
`define WB_SEL_ALU         3'b001
`define WB_SEL_LOAD        3'b010
`define WB_SEL_PC4         3'b011
`define WB_SEL_IMM         3'b100

`define EXC_INST_ADDR_MISALIGN   5'd0
`define EXC_INST_ACCESS_FAULT    5'd1
`define EXC_ILLEGAL_INST         5'd2
`define EXC_BREAKPOINT           5'd3
`define EXC_LOAD_ADDR_MISALIGN   5'd4
`define EXC_LOAD_ACCESS_FAULT    5'd5
`define EXC_STORE_ADDR_MISALIGN  5'd6
`define EXC_STORE_ACCESS_FAULT   5'd7
`define EXC_ECALL_MMODE          5'd11

`define CORE_STATE_RESET      4'd0
`define CORE_STATE_FETCH_REQ  4'd1
`define CORE_STATE_FETCH_WAIT 4'd2
`define CORE_STATE_DECODE     4'd3
`define CORE_STATE_EXEC       4'd4
`define CORE_STATE_MEM_REQ    4'd5
`define CORE_STATE_MEM_WAIT   4'd6
`define CORE_STATE_WB         4'd7
`define CORE_STATE_HALT       4'd8
`define CORE_STATE_TRAP       4'd9

`define CTRL_VALID_BIT           0
`define CTRL_ILLEGAL_BIT         1
`define CTRL_RS1_EN_BIT          2
`define CTRL_RS2_EN_BIT          3
`define CTRL_RD_EN_BIT           4
`define CTRL_BRANCH_BIT          5
`define CTRL_JAL_BIT             6
`define CTRL_JALR_BIT            7
`define CTRL_LOAD_BIT            8
`define CTRL_STORE_BIT           9
`define CTRL_ECALL_BIT           10
`define CTRL_EBREAK_BIT          11
`define CTRL_FENCE_BIT           12
`define CTRL_IMM_TYPE_LSB        13
`define CTRL_IMM_TYPE_MSB        15
`define CTRL_OP1_SEL_LSB         16
`define CTRL_OP1_SEL_MSB         17
`define CTRL_OP2_SEL_LSB         18
`define CTRL_OP2_SEL_MSB         19
`define CTRL_ALU_OP_LSB          20
`define CTRL_ALU_OP_MSB          23
`define CTRL_CMP_OP_LSB          24
`define CTRL_CMP_OP_MSB          26
`define CTRL_MEM_SIZE_LSB        27
`define CTRL_MEM_SIZE_MSB        28
`define CTRL_MEM_UNSIGNED_BIT    29
`define CTRL_WB_SEL_LSB          30
`define CTRL_WB_SEL_MSB          32
`define CTRL_NEED_EXEC_BIT       33
`define CTRL_NEED_MEM_BIT        34
`define CTRL_NEED_WB_BIT         35
`define CTRL_SYSTEM_BIT          36
`define CTRL_MISC_MEM_BIT        37
`define CTRL_BUS_W               38

`endif
