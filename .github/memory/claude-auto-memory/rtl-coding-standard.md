---
name: rtl-coding-standard
description: "User's mandatory RTL-writing methodology for this repo — topology-first, hardware-structural, function restrictions"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0353a89c-6ba9-4a48-b7b5-b2e6baab6210
---

用户(数字 IC/RTL 工程背景)对本仓库 RTL 写作的强制要求(2026-06-28/29 多次明确给出):

**写代码前先出拓扑,不要直接写 RTL。** 先输出 RTL 级电路拓扑并自审正确性,再翻译成 RTL。拓扑必含 9 项:① module 边界与接口协议 ② 所有状态寄存器 ③ 所有主要组合逻辑块 ④ FSM 状态与转移 ⑤ pipeline stage 与 valid/ready 流向 ⑥ flush/stall/kill/reset 优先级 ⑦ 资源复制或共享 ⑧ 可能的 critical path ⑨ 哪些逻辑允许 function、哪些必须显式 always 块/module。

**按真实硬件结构写,不按软件函数组织代码:**
- 显式区分时序块与组合块;先说明模块的寄存器/组合逻辑/datapath/control FSM。
- `function` 只能用于**小型纯组合 helper**(lzc/barrel-shift/round/saturate/predicate)。
- **禁止**把状态更新、仲裁、valid/ready、flush/kill、issue/select、ROB/LSQ 更新、divider/任何 FSM 封进 function——必须显式写成 always 块/子 module,使寄存器/控制流/共享资源结构可见。
- 每个 for-loop 注明综合后对应什么硬件;每个共享资源显式给出 mux+enable+控制逻辑;注明关键路径大概位置。

**Why:** 用户要的是硬件可见性与可综合质量,不是软件抽象。大 function 把 datapath/控制藏起来,违背其意图;曾把 ~150 行 FMA 塞进 function 被纠正。

**判据细化(2026-06-29 重构 campaign 实证)**:转 function→always@* 时,只转**大型单次使用、隐藏模块主 datapath 的 function**;**小型 helper(立即数/掩码/字段提取/单表达式,6-17 行)与多站点复用的纯组合 function 保留**——复用 helper(如 enc_i 用 17 次、select_op1 用 6 次、clz/popcount/rotate primitive)本就是 function 的正当用途,转成 always@* 反而重复/更乱。已据此把核执行/解码/CSR 全部大型单次 datapath function 转为 always@*(12 文件:FP arith/classify/sgnj/compare/convert/longop、整数 amo/bitmanip/muldiv、RvcDecompressor、CsrFile decode);loop 应用的逐-entry 控制(PMP entry check、issue-queue select)属设计级,非机械转换。批量转换器 `scratchpad/conv_fp_func.py`(嵌套-begin 法:保留 function 原 begin/end 作内嵌块避免孤儿 end)。

**How to apply:** 任何 RTL 改动先走 [[rtl-generation-workflow]] 的拓扑阶段;遵守 [[verilog-not-systemverilog-for-synth]] 的关键字/文件约束(本仓库 iverilog gate 不吃 always_comb)。完整规范固化在 `.github/instructions/rtl-generation-workflow.instructions.md`。参见 [[fp2-fma-fused-fix]] 作为遵循此规范的范例。
