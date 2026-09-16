# RV32I 实现检查清单

## 使用方式

- 写一个模块前先看对应章节。
- 完成后再做“自测要点”和“联调要点”。
- 这份清单默认服务于 npc/single 的单周期 RV32I 主通路实现。

## 第一层：指令译码必须稳定

- [ ] 能正确切出 opcode、rd、funct3、rs1、rs2、funct7
- [ ] 能按 I、S、B、U、J 生成立即数
- [ ] 能区分 R-type、I-type、Load、Store、Branch、JAL、JALR、LUI、AUIPC、System
- [ ] 能输出统一 decode_ctrl_t 或等价控制包
- [ ] dec_illegal 只在未命中合法模式时拉高
- [ ] rs1_en、rs2_en、rd_en 与指令语义一致

## 第二层：执行单元必须分职责

- [ ] ALU 至少覆盖 ADD、SUB、SLL、SLT、SLTU、XOR、SRL、SRA、OR、AND
- [ ] Compare unit 能输出 EQ、NE、LT、GE、LTU、GEU 所需关系
- [ ] Branch control 只消费比较结果和 branch 类型，不直接重复比较
- [ ] Target 或 Addr Gen 能分别给出 branch target、jalr target、ls_addr
- [ ] JAL 和 JALR 写回源固定为 PC + 4
- [ ] LUI 写回 imm_u，AUIPC 写回 pc + imm_u

## 第三层：访存单元必须闭环

- [ ] Load 支持 LB、LH、LW、LBU、LHU
- [ ] Store 支持 SB、SH、SW
- [ ] 能根据地址低位和 size 生成 wstrb
- [ ] 能从返回字中提取 byte、half、word
- [ ] Signed load 做符号扩展，unsigned load 做零扩展
- [ ] 预留 misaligned 或 bus error 上报路径

## 第四层：写回单元必须成为唯一提交点

- [ ] 所有结果先变成统一 wb_req 或等价结构
- [ ] wb_sel 能在 ALU、LOAD、PC+4、IMM 等来源间选择
- [ ] 最终写回会屏蔽 x0
- [ ] 异常、flush、无效指令不会错误写回
- [ ] result_valid 与 commit_enable 没有强耦合

## 第五层：取指和主控必须能闭环

- [ ] IFU 支持 PC + 4 正常取指
- [ ] IFU 支持 redirect 优先于顺序取指
- [ ] IFU 能处理 outstanding request 或等价的请求返回生命周期
- [ ] 至少有 PC 对齐检查
- [ ] 主控能判断 need_exec、need_mem、need_wb
- [ ] 分支或跳转后不会继续提交旧路径结果

## 逐类指令自测要点

### 算术和逻辑

- [ ] ADDI 与 ADD 的基础结果一致性正常
- [ ] SUB 和比较类对有符号、无符号边界值都正确
- [ ] SLL、SRL、SRA 只使用低 5 位移位量

### Load 和 Store

- [ ] 字节写不会污染同一字内其它字节
- [ ] 半字写能正确覆盖相邻 2 个字节
- [ ] LB 与 LBU、LH 与 LHU 的扩展行为不同
- [ ] 基址加偏移计算结果正确

### Branch 和 Jump

- [ ] BEQ 和 BNE 使用相等比较
- [ ] BLT 和 BGE 与 BLTU 和 BGEU 的比较语义不同
- [ ] branch target 使用 imm_b
- [ ] jal target 使用 imm_j
- [ ] jalr target 使用 rs1 + imm_i
- [ ] branch 和 jump 都不会把目标地址误写回 rd

### U-type

- [ ] LUI 直接写 imm_u
- [ ] AUIPC 使用当前 pc + imm_u

## 当前 NPC 最值得先做的事情

- [ ] 在 define.v 统一补齐 opcode、funct3、op1_sel、op2_sel、cmp_op、wb_sel 的编码约定
- [ ] 在 IDU 先形成完整控制包，再考虑具体模块连接
- [ ] 在 EXU 除 alu.v 之外补 compare unit 和 target 或 address generator
- [ ] 在 LSU 和 WBU 之间明确“load 数据提取”和“提交写回”的边界
- [ ] 在顶层先画清楚 pc、inst、imm、alu_result、lsu_rdata、wb_data 的数据流

## 联调时优先观察的信号

- [ ] pc
- [ ] inst
- [ ] dec_valid
- [ ] dec_illegal
- [ ] imm
- [ ] alu_op
- [ ] op1_sel
- [ ] op2_sel
- [ ] cmp_op
- [ ] mem_req
- [ ] mem_we
- [ ] mem_size
- [ ] mem_unsigned
- [ ] wb_sel
- [ ] rd_en
- [ ] rd_idx
- [ ] wb_data
- [ ] branch_taken
- [ ] next_pc

## 一眼排查规则

- [ ] 如果 branch 老是跳错，先查 imm_b 拼接和 cmp_op
- [ ] 如果 jal 或 jalr 返回地址错，先查 PC + 4 写回链路
- [ ] 如果 lb 或 lh 结果错，先查提取位段和符号扩展
- [ ] 如果 x0 被写坏，先查 WBU 最终屏蔽而不是前级控制
- [ ] 如果跳转后偶现脏指令，先查 IFU redirect 和旧请求清理
