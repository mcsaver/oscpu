# Decode — 译码分类 + 微 op 裂分

**文件**:`src/core/decode/Decode.hh` · **↔ npc**:`OooDecode`(+ 微 op 裂分)

## 职责
纯组合 `*Gate`:把一条静态指令分类到 dispatch 的各处理类别,并标注是否需分配目的寄存器 / IQ 槽 / 裂微 op。

## 状态
无(纯组合)。

## 接口
- `decode(in) -> Decoded{is_halt,is_store,is_branch,is_jump,is_jal,is_jalr,is_sys,needs_dst,needs_iq}`。
  - `needs_dst`:非 halt/branch/jump 且 `dst>=0`(JAL/JALR 含链接 rd → 触发 free-list backpressure 检查)。
  - `needs_iq`:非 halt/jump/系统 op/JAL(JALR 等 rs;STORE 需 **2** 个 IQ 槽 = STA+STD,由 dispatch 据 `is_store` 处理)。

## 行为(⑥ STA/STD)
- `is_store` 的指令在 dispatch 裂成 **STA**(`FuType::STA`,等 base=src0,算地址)+ **STD**(`FuType::STD`,等 data=src1,取数据)两个 IQ 条目,共享同一 SQ 项 + ROB 项;两微 op 均执行后 store 的 ROB 项才 `done`。

## 不变量 / 行为
- 分类结果与迁移前 dispatch 内联布尔逐一等价(纯搬移,行为不变);STA/STD 裂分是新增行为,内存语义由 difftest 守恒。

## 测试
`make run-sta`(整核 demo/fuzz)覆盖裂分路径;`make run-*` 全套回归确认分类等价(旧版本 bit-exact)。
