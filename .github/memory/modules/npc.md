# NPC (RTL CPU) 模块笔记

## 当前状态
<!-- 已实现的模块、信号位宽等 -->
- 2026-04-13: 已通读 `npc/single/design/RV32I.pdf`，并把单周期 RV32I 的模块划分、立即数规则、控制包字段、WBU 提交原则整理到 `npc/single/design/study/README.md`、`npc/single/design/study/RV32I-ai-notes.md`、`npc/single/design/study/RV32I-implementation-checklist.md`，后续补 NPC 主通路前可先读这三份笔记对齐术语和边界。
- 2026-04-07: `alu.v` 已重建为面向 RV32I 单周期执行路径的组合 ALU，当前支持 `ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND/LUI(src2 直通)`，并额外输出 `zero`、`less_than`、`less_than_u` 供分支判断直接复用。
- 2026-04-07: `IFU/bh_bt.v` 已补成最小 BHT 闭环，当前支持 `pc_lookup` 组合查表输出 `pre_state`/`jump_if`，以及 `pc_wb_bt + state_wb_bh` 的同步写回；表项格式为 `{tag, 2-bit state}`，表深为 `2^BHT_ADDR_WIDTH`。
- 2026-03-22: 新增 alu.v 的基础实现，当前支持 10 种运算: add、sub、and、or、xor、sll、srl、sra、slt、sltu。

## 设计笔记
<!-- 模块设计思路、接口约定 -->
- 2026-04-13: `RV32I.pdf` 对 NPC 当前阶段最有价值的结论是“先把译码压成统一控制包，再把 EXU、LSU、WBU 的边界切清楚”；尤其 WBU 被明确定位为提交点而不是计算点，这会直接影响后续顶层数据通路和异常屏蔽的组织方式。
- 2026-04-07: `alu.v` 当前改为纯组合实现，不再依赖时序寄存；这样更贴合 single 单周期数据通路，执行结果在同一拍内即可被写回、访存地址生成或分支判定复用。
- `alu.v` 的 `select_mod` 对 `OP/OP-IMM` 采用 `{funct7[5], funct3}` 编码：`0000 add`、`1000 sub`、`0001 sll`、`0010 slt`、`0011 sltu`、`0100 xor`、`0101 srl`、`1101 sra`、`0110 or`、`0111 and`；额外用 `1110` 表示 `LUI/src2 直通`，`1111` 预留为 `src1` 直通。
- `alu.v` 里 `zero`、`less_than`、`less_than_u` 统一由减法结果派生，后续 `BEQ/BNE/BLT/BGE/BLTU/BGEU` 可以直接复用，不必再单独复制一套比较器。
- 2026-04-07: `bh_bt.v` 当前按用户要求回到“直接用宏表达式定义位宽”的写法：`tag/index/entry` 的位宽和切片直接基于 `DATA_WIDTH_pc`、`BHT_ADDR_WIDTH` 展开，不再额外包一层 32 位 localparam。这样更贴近当前工程风格，但文件级检查会继续报定宽宏参与算术的位宽告警。
- `bh_bt.v` 当前把 PC 的低 2 位仅用于对齐检查，不参与索引；索引来自 `pc[2 + BHT_ADDR_WIDTH - 1:2]`，其余高位作为 tag，查表命中后用 2-bit 饱和计数器状态的高位作为 `jump_if`。
- `bh_bt.v` 中凡是拿 `DATA_WIDTH_pc`、`BHT_ADDR_WIDTH` 做减法、移位和 part-select 边界计算，都要先做 32 位零扩展；否则 `define.v` 里的 4 位/6 位定宽宏会触发位宽不匹配告警。
- `alu.v` 当前接口为 `rst` `en` `select_mod` `src1` `src2` `zero` `less_than` `less_than_u` `result`；移位类运算使用 `src2` 的低 5 位作为移位量。

## 踩坑记录
<!-- 本模块特有的问题和经验 -->
- 初始版本只有运算模式参数，没有操作数输入和结果寄存器，无法形成可综合可用的 ALU。
