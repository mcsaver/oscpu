---
name: rtl-coding-standard
description: "复杂 RTL 设计采用 topology-first 并保持硬件结构可见；局部改动按影响面理解调用链"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0353a89c-6ba9-4a48-b7b5-b2e6baab6210
---

用户（数字 IC/RTL 工程背景）对本仓库 RTL 写作强调硬件结构可见。以下 topology-first 清单适用于新模块、
跨模块协议、状态机、流水/仲裁或 PPA 架构改造；已定位的局部 bug 和小型组合修复只需理解直接相关
调用链、状态与时序，不要求先输出固定九项摘要。

**写代码前先出拓扑,不要直接写 RTL。** 先输出 RTL 级电路拓扑并自审正确性,再翻译成 RTL。拓扑必含 9 项:① module 边界与接口协议 ② 所有状态寄存器 ③ 所有主要组合逻辑块 ④ FSM 状态与转移 ⑤ pipeline stage 与 valid/ready 流向 ⑥ flush/stall/kill/reset 优先级 ⑦ 资源复制或共享 ⑧ 可能的 critical path ⑨ 哪些逻辑允许 function、哪些必须显式 always 块/module。

**按真实硬件结构写,不按软件函数组织代码:**
- 显式区分时序块与组合块;先说明模块的寄存器/组合逻辑/datapath/control FSM。
- `function` 只能用于**小型纯组合 helper**(lzc/barrel-shift/round/saturate/predicate)。
- **禁止**把状态更新、仲裁、valid/ready、flush/kill、issue/select、ROB/LSQ 更新、divider/任何 FSM 封进 function——必须显式写成 always 块/子 module,使寄存器/控制流/共享资源结构可见。
- 每个 for-loop 注明综合后对应什么硬件;每个共享资源显式给出 mux+enable+控制逻辑;注明关键路径大概位置。

**Why:** 用户要的是硬件可见性与可综合质量,不是软件抽象。大 function 把 datapath/控制藏起来,违背其意图;曾把 ~150 行 FMA 塞进 function 被纠正。

**判据细化(2026-06-29 重构 campaign 实证)**:转 function→always@* 时,只转**大型单次使用、隐藏模块主 datapath 的 function**;**小型 helper(立即数/掩码/字段提取/单表达式,6-17 行)与多站点复用的纯组合 function 保留**——复用 helper(如 enc_i 用 17 次、select_op1 用 6 次、clz/popcount/rotate primitive)本就是 function 的正当用途,转成 always@* 反而重复/更乱。已据此把核执行/解码/CSR 全部大型单次 datapath function 转为 always@*(12 文件:FP arith/classify/sgnj/compare/convert/longop、整数 amo/bitmanip/muldiv、RvcDecompressor、CsrFile decode);loop 应用的逐-entry 控制(PMP entry check、issue-queue select)属设计级,非机械转换。批量转换器 `scratchpad/conv_fp_func.py`(嵌套-begin 法:保留 function 原 begin/end 作内嵌块避免孤儿 end)。

**How to apply:** 根据影响面按需使用 [[rtl-generation-workflow]]；复杂设计先明确拓扑和接口控制契约，
局部修复直接核对相关数据流和寄存器更新。仍须遵守 [[verilog-not-systemverilog-for-synth]] 中与实际工具链
相关的语法/文件边界，但历史 gate 名称或固定回归组合不自动成为每个任务的收尾许可。参见
[[fp2-fma-fused-fix]] 的结构化实现范例。
