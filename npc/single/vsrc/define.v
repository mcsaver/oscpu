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

// 立即数类型编码：DecodeUnit 给出类型，ImmGen 按类型完成拼接与符号扩展。
`define IMM_TYPE_X         3'b000  // 不使用立即数
`define IMM_TYPE_I         3'b001  // I-type: 算术立即数 / load / jalr
`define IMM_TYPE_S         3'b010  // S-type: store 偏移
`define IMM_TYPE_B         3'b011  // B-type: branch 偏移
`define IMM_TYPE_U         3'b100  // U-type: lui / auipc 高 20 位立即数
`define IMM_TYPE_J         3'b101  // J-type: jal 跳转偏移

// EXU 第一个操作数来源选择。
`define OP1_SEL_RS1        2'b00   // 来自寄存器 rs1
`define OP1_SEL_PC         2'b01   // 来自当前 pc
`define OP1_SEL_ZERO       2'b10   // 常数 0，用于 lui 等场景

// EXU 第二个操作数来源选择。
`define OP2_SEL_RS2        2'b00   // 来自寄存器 rs2
`define OP2_SEL_IMM        2'b01   // 来自立即数 imm
`define OP2_SEL_FOUR       2'b10   // 常数 4，主要服务 PC+4 类计算

// ALU 运算编码：DecodeUnit 只描述“做什么”，ALU 负责真正计算。
`define ALU_OP_ADD         4'h0    // 加法：地址生成 / auipc / addi / add
`define ALU_OP_SLL         4'h1    // 逻辑左移
`define ALU_OP_SLT         4'h2    // 有符号小于比较，结果写成 0/1
`define ALU_OP_SLTU        4'h3    // 无符号小于比较，结果写成 0/1
`define ALU_OP_XOR         4'h4    // 按位异或
`define ALU_OP_SRL         4'h5    // 逻辑右移
`define ALU_OP_OR          4'h6    // 按位或
`define ALU_OP_AND         4'h7    // 按位与
`define ALU_OP_SUB         4'h8    // 减法：sub 等场景
`define ALU_OP_SRA         4'hd    // 算术右移
`define ALU_OP_COPY_B      4'he    // 直通第二操作数，常用于 lui
`define ALU_OP_COPY_A      4'hf    // 直通第一操作数，当前预留

// CompareUnit 关系比较编码：只产出真假，不直接决定是否跳转。
`define CMP_OP_NONE        3'b000  // 当前指令不需要比较
`define CMP_OP_EQ          3'b001  // 相等
`define CMP_OP_NE          3'b010  // 不相等
`define CMP_OP_LT          3'b011  // 有符号小于
`define CMP_OP_GE          3'b100  // 有符号大于等于
`define CMP_OP_LTU         3'b101  // 无符号小于
`define CMP_OP_GEU         3'b110  // 无符号大于等于

// 访存粒度编码：LSU 依据它生成 wstrb 并完成 load 扩展。
`define MEM_SIZE_BYTE      2'b00   // 8-bit
`define MEM_SIZE_HALF      2'b01   // 16-bit
`define MEM_SIZE_WORD      2'b10   // 32-bit

// 写回源选择：WBU 在这里统一做多路选择，避免前级直接写寄存器堆。
`define WB_SEL_NONE        3'b000  // 不写回
`define WB_SEL_ALU         3'b001  // 写回 ALU 结果
`define WB_SEL_LOAD        3'b010  // 写回 load 返回值
`define WB_SEL_PC4         3'b011  // 写回 pc + 4，jal/jalr 使用
`define WB_SEL_IMM         3'b100  // 写回立即数，lui 使用

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

// 统一控制总线字段定义：DecodeUnit 产出 ctrl_o，NpcCore 在 DECODE 阶段锁存后供各后级模块消费。
// 单 bit 标记优先描述“这条指令是什么/需要什么”，多 bit 字段则描述“后级该怎么做”。
`define CTRL_VALID_BIT           0   // 译码结果有效；当前实现默认对取到的 inst 都置 1
`define CTRL_ILLEGAL_BIT         1   // 该编码是否非法；若为 1，顶层会直接进入 illegal trap
`define CTRL_RS1_EN_BIT          2   // 是否需要读取 rs1
`define CTRL_RS2_EN_BIT          3   // 是否需要读取 rs2
`define CTRL_RD_EN_BIT           4   // 是否存在 rd 写回目标
`define CTRL_BRANCH_BIT          5   // 是否属于条件分支类指令
`define CTRL_JAL_BIT             6   // 是否属于 jal
`define CTRL_JALR_BIT            7   // 是否属于 jalr
`define CTRL_LOAD_BIT            8   // 是否属于 load
`define CTRL_STORE_BIT           9   // 是否属于 store
`define CTRL_ECALL_BIT           10  // 是否为 ecall
`define CTRL_EBREAK_BIT          11  // 是否为 ebreak
`define CTRL_FENCE_BIT           12  // 是否为 fence/fence.i；当前实现视为合法 no-op
`define CTRL_IMM_TYPE_LSB        13  // 立即数字段低位：交给 ImmGen 选择拼接规则
`define CTRL_IMM_TYPE_MSB        15  // 立即数字段高位
`define CTRL_OP1_SEL_LSB         16  // EXU 第一个操作数来源字段低位
`define CTRL_OP1_SEL_MSB         17  // EXU 第一个操作数来源字段高位
`define CTRL_OP2_SEL_LSB         18  // EXU 第二个操作数来源字段低位
`define CTRL_OP2_SEL_MSB         19  // EXU 第二个操作数来源字段高位
`define CTRL_ALU_OP_LSB          20  // ALU 运算编码字段低位
`define CTRL_ALU_OP_MSB          23  // ALU 运算编码字段高位
`define CTRL_CMP_OP_LSB          24  // CompareUnit 比较关系字段低位
`define CTRL_CMP_OP_MSB          26  // CompareUnit 比较关系字段高位
`define CTRL_MEM_SIZE_LSB        27  // LSU 访存粒度字段低位
`define CTRL_MEM_SIZE_MSB        28  // LSU 访存粒度字段高位
`define CTRL_MEM_UNSIGNED_BIT    29  // load 是否按无符号扩展处理
`define CTRL_WB_SEL_LSB          30  // WBU 写回源选择字段低位
`define CTRL_WB_SEL_MSB          32  // WBU 写回源选择字段高位
`define CTRL_NEED_EXEC_BIT       33  // 指令是否需要经过 EXEC 阶段
`define CTRL_NEED_MEM_BIT        34  // 指令是否需要经过 MEM 阶段
`define CTRL_NEED_WB_BIT         35  // 指令是否需要在 WB 阶段提交写回
`define CTRL_SYSTEM_BIT          36  // 是否属于 system 指令族（当前只接 ecall/ebreak）
`define CTRL_MISC_MEM_BIT        37  // 是否属于 misc-mem 指令族（当前只接 fence/fence.i）
`define CTRL_BUS_W               38  // 统一控制总线总宽度

`endif
