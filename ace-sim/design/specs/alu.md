# Alu — 整数 ALU + 分支比较

**文件**:`src/core/execute/Alu.hh` · **↔ npc**:`ALU` + `CompareUnit`

## 职责
整数加法与分支条件比较;持 ALU 功能单元(latency/II/width)。分支借用本 FU 做比较。

## 状态
- `fu_`:`FunctionalUnit`(见 `hw/resource.hh`):latency/II/width 三合一资源模型。

## 接口
- FU 资源端口:`can_issue(c)` / `reserve(c)` / `next_free()` / `latency()`。
- 组合计算:`compute(a,b,imm) = a+b+imm`;`taken(cond,a,b)`(cond 0=EQ,1=NE)。

## 不变量 / 行为
- `FunctionalUnit`:同周期受 width 限制、跨周期受 II 限制(两者正交;`width` 在 II≥1 时不得失效
  —— V1 审查缺陷 #7 的对应保证)。
- 结构冒险(`!can_issue`)由 `CpuTop` 记录 `next_free()` 并调度 `CpuWake` 兜底(睡眠安全律)。
- 分支的实际方向 = `taken(cond,a,b)`,发射拍算出,随 FuComplete 事件(payload1=0/1)在完成拍解析。

## 测试
`tb_modules::test_execute`:compute/taken(EQ/NE) 正确。
