# RV32I 结构化学习笔记

## 元信息

- 学习来源：../RV32I.pdf
- 学习日期：2026-04-13
- 适用对象：npc/single 单周期 RV32I CPU
- 关注范围：IFU、IDU、EXU、LSU、WBU 的职责划分与控制信号组织
- 不在本轮范围：CSR 细节、中断异常完整流程、流水线冒险、乘除法扩展

## 总体判断

- 资料核心结论：把单周期 CPU 拆成 IFU -> IDU -> EXU -> LSU -> WBU 五个逻辑块，再由主控 FSM 协调是否取指、执行、访存、写回。
- 资料强调的不是“每条指令怎么编码”本身，而是“译码后要把什么控制信息交给后续模块”。
- 后续实现时，最重要的边界是：IDU 负责解释指令，EXU 负责计算，LSU 负责访存语义，WBU 负责统一提交。

## 模块知识图谱

### IFU

- 输入：当前 PC、next_pc 选择、redirect 请求、总线握手返回。
- 职责：发起取指、维护 outstanding request、缓存返回值、支持 kill 或 discard、做 PC 对齐检查、整理 access fault。
- 设计结论：IFU 不是简单的 PC 加 4，它还承担“请求生命周期管理”和“错误整理”。
- 对当前 NPC 的启发：如果后续要把分支或异常接进来，IFU 需要显式处理 redirect 优先级，不能只靠组合 next_pc。

### IDU

- 输入：pc、inst、en。
- 输出核心：一组结构化译码控制信号，而不是零散的 case 结果。
- 关键控制位：dec_valid、dec_illegal、dec_is_branch、dec_is_jal、dec_is_jalr、dec_is_load、dec_is_store、dec_is_lui、dec_is_auipc、dec_is_system。
- 寄存器接口：rs1_idx、rs2_idx、rd_idx、rs1_en、rs2_en、rd_en。
- 立即数接口：imm、imm_type。
- 执行控制：alu_op、op1_sel、op2_sel、cmp_op。
- 访存控制：mem_req、mem_we、mem_size、mem_unsigned。
- 主控接口：need_exec、need_mem、need_wb。
- 设计结论：IDU 应该在一个地方把“这条指令后面需要什么资源”说清楚，后级尽量不再回头看 opcode。

### EXU

- 子模块：ALU、Compare Unit、Target/Addr Gen、Branch Control、PC+4 加法器。
- 职责：产生算术结果、比较结果、跳转目标、访存地址。
- 设计结论：分支判断至少拆成两层，第一层做比较，第二层根据 br_type 决定是否跳转。
- 对当前 NPC 的启发：现有 alu.v 只覆盖了算术与比较基础，还需要把 branch target、jalr target、load store address 生成独立补齐。

### LSU

- 必须完整支持：LB、LH、LW、LBU、LHU、SB、SH、SW。
- 输入核心：req、we、size、unsigned、addr、wdata。
- 输出核心：done、rdata、exception、exccode。
- 总线侧接口：mem_valid、mem_we、mem_addr、mem_wdata、mem_wstrb、mem_ready、mem_rdata、mem_error。
- 设计结论：LSU 不只是一个读写端口适配层，它还要负责按大小提取字节或半字、做符号扩展或零扩展、上报异常。
- 对当前 NPC 的启发：如果把 load 的字节提取拖到别处做，后续写回和异常路径会越来越乱，应该让 LSU 或 LSU 后的固定单元承担这部分语义。

### WBU

- 输入候选：ALU 结果、Load 结果、PC+4、Imm、CSR 结果、异常状态。
- 输出核心：寄存器写使能、写地址、写数据、指令完成脉冲、异常状态。
- 关键原则：WBU 是提交点，不是计算点。
- 关键原则：先形成统一 wb_req，再在提交点统一做屏蔽。
- 必须屏蔽的场景：写 x0、异常、flush、无效提交。
- 设计结论：不要在 EXU 或 LSU 里直接写寄存器，否则异常屏蔽、trace 集中和后续扩展会很难维护。

## 指令格式速查

### R-type

- 位段：funct7[31:25]、rs2[24:20]、rs1[19:15]、funct3[14:12]、rd[11:7]、opcode[6:0]
- 用途：寄存器到寄存器的算术和逻辑操作

### I-type

- 位段：imm[31:20]、rs1[19:15]、funct3[14:12]、rd[11:7]、opcode[6:0]
- 用途：算术立即数、load、jalr、部分 system
- 特别注意：移位类立即数使用 shamt = inst[24:20]

### S-type

- 位段：imm[11:5] 来自 inst[31:25]，imm[4:0] 来自 inst[11:7]
- 用途：store

### B-type

- 位段重组：inst[31]、inst[7]、inst[30:25]、inst[11:8]、0
- 用途：branch
- 特别注意：最低位固定为 0，目标地址按半字对齐偏移拼接

### U-type

- 位段：inst[31:12] 后接 12 个 0
- 用途：lui、auipc

### J-type

- 位段重组：inst[31]、inst[19:12]、inst[20]、inst[30:21]、0
- 用途：jal
- 特别注意：最低位固定为 0

## 立即数规则

- imm_i = SignExt(inst[31:20])
- imm_s = SignExt({inst[31:25], inst[11:7]})
- imm_b = SignExt({inst[31], inst[7], inst[30:25], inst[11:8], 1'b0})
- imm_u = {inst[31:12], 12'b0}
- imm_j = SignExt({inst[31], inst[19:12], inst[20], inst[30:21], 1'b0})

## 控制信号组织建议

### decode_ctrl_t 应至少覆盖的字段

- valid：当前译码结果是否有效
- illegal：是否非法指令
- rs1_en、rs2_en、rd_en：寄存器端口使用情况
- imm_type：立即数类型
- alu_op：ALU 运算选择
- op1_sel：RS1 或 PC 或 ZERO
- op2_sel：RS2 或 IMM 或 FOUR
- cmp_op：EQ、NE、LT、GE、LTU、GEU
- branch、jal、jalr：控制流类型
- mem_req、mem_we、mem_size、mem_unsigned：访存控制
- wb_en、wb_sel：写回控制
- sys_op：system 指令类型

### 这样组织的收益

- 译码和执行解耦，后级不必重复识别 opcode。
- 主控 FSM 只看“这条指令需要什么阶段”，不需要理解所有指令细节。
- 后续加入 CSR、异常、中断时，可以在控制包上扩展字段而不是打散重写全链路。

## 这份资料反复强调的设计规则

- 规则 1：把译码结果收敛成结构化控制包。
- 原因：减少后级重复译码，方便调试和扩展。

- 规则 2：分支比较和分支决策要分开。
- 原因：比较器只输出关系结果，是否跳转由 branch control 结合 br_type 决定。

- 规则 3：地址生成最好单独存在。
- 原因：branch target、jalr target、load store address 的来源不同，但都属于地址计算问题。

- 规则 4：LSU 负责访存语义，不只是搬运总线数据。
- 原因：load 的符号扩展和字节提取如果散到其他模块，会破坏边界。

- 规则 5：WBU 是统一提交点。
- 原因：异常屏蔽、x0 屏蔽、trace 和后续 CSR 扩展都依赖集中提交。

- 规则 6：result_valid 和 commit_enable 最好分离。
- 原因：未来加入异常、中断、flush 或多周期部件时，不是“有结果”就一定“允许提交”。

## 容易出错的点

- B-type 和 J-type 立即数不是简单连续切片，拼接顺序和最低位补 0 都容易写错。
- JAL 写回的是 PC + 4，不是目标地址。
- JALR 的目标来自 rs1 + imm，而写回仍然是 PC + 4。
- LUI 直接写 imm_u，AUIPC 写 pc + imm_u，两者不要混淆。
- Load unsigned 需要零扩展，Load signed 需要符号扩展。
- x0 必须硬屏蔽写回，即使控制链路误给出写使能也不能真的写。
- 如果在 EXU 或 LSU 直接写寄存器，异常或 flush 时会很难回滚。
- IFU 需要考虑 redirect 优先级和 outstanding request 清理，否则分支后容易取到脏指令。

## 对当前 NPC 的落地启发

- 现有 alu.v 可以继续保留为 EXU 的一个子块，但不要让 ALU 直接承担分支目标和完整写回职责。
- define.v 最适合沉淀 opcode、funct3、funct7 关键宏，以及 op1_sel、op2_sel、cmp_op、wb_sel 等统一编码。
- 如果接下来开始补单周期主通路，优先顺序应是：IDU 控制包 -> EXU 比较和地址生成 -> LSU 访存语义 -> WBU 统一提交 -> IFU 重定向闭环。
- 只要 WBU 还没形成统一提交点，后续加异常、CSR 或 difftest 提交日志都会比较痛苦。

## 待继续学习的空白点

- PDF 里没有展开 CSR 编码和异常返回时序，只留下了 sys 和异常字段接口。
- IFU 的状态图只给了职责，没有细化具体状态编码和握手时序。
- LSU 的地址未对齐异常、总线错误到 exccode 的映射还需要结合具体实现补充。
- 这份资料偏单周期和模块化草图，不涉及流水线冒险和旁路。
