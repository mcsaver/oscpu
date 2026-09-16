# 模块/子系统规范模板（SPEC-TEMPLATE）

> 本仓库约定：**动 RTL 前先写/更新 spec**。新规范复制本模板填写。要求专业、图文并茂、
> 状态机优先（用显式 FSM/时序模型表达，而非堆叠多层组合判断）。
> 位置：单模块放 `design/specs/<name>.md`；跨模块/架构级放 `design/arch/<name>.md`。
>
> **契约先行强制**：触碰握手 / stall / flush·redirect·trap / 异常序 / 访存序 / 投机恢复 或跨模块的
> rv64 改动，§2 接口契约 + §3 状态/时序模型（尤其 flush「谁清谁保持」表 + 同拍优先级表）是
> **动 RTL 前必须填满的前置产物**，不是事后补文档。六类契约规范与判据见
> `.github/instructions/interface-contract-first.instructions.md`。填不出 = 未理解上下游 = 禁止写 RTL。

---

## 1. 目的与范围
- 该模块解决什么问题、在数据通路/控制面的位置、不负责什么（明确边界）。

## 2. 接口契约
- 端口表：方向 / 位宽 / 时序（ready-valid? 单拍? 多拍? 组合还是打拍）/ 复位值 / 含义 /
  **决定握手的状态在谁那里**（禁止“甩给 parent”而不指明）。
- 时序图（ASCII 波形）：典型握手、背压、flush 行为。
- **flush/redirect「谁清谁保持」表**（触碰控制路径时**必填**）：逐 flush 源列 [清什么 | 保持什么]，
  并给同拍优先级全序（trap/exit > CSR/xRET > branch mispredict > BPU/RAS > 顺序 PC）；
  三条铁律：committed store 不得清、不得 kill 已发 AXI、CSR 写 commit 拍即架构可见。

## 3. 状态与时序模型（FSM 优先）
- 状态定义 + 状态转移图（ASCII）。
- 每状态：进入条件、动作、退出条件、与外部握手的关系。
- 寄存器清单：复位值、更新条件、优先级（若有同拍竞争，显式列优先级）。

## 4. 不变量（Invariants）
- 必须始终成立的性质（如：精确异常边界、访存顺序、ready/valid 无组合环、
  outstanding 计数上界、forward 正确性）。每条给出"为何成立"。

- **能编码的不变量必须转成立即断言**：`always @(posedge clk) if (违约) $error(...)`（禁 SVA `|->`/`$stable`，
  工具链不支持）；每条断言写完须故意制造一次违约确认会响（防真空通过），且编码独立于 RTL 的真理（防同盲区）。
  断言受 `` `ifdef OOO_ASSERT `` 门控、`make check-contract` gate 统计其计数不回退。

## 5. 关键路径与时序考量
- 组合深度热点；是否需要切流水/寄存器；CPI↔Fmax 权衡说明。

## 6. 验证计划
- 模块 TB 覆盖点；映射到哪些 riscv-tests / AM cpu-tests；预期 CPI 影响。
- 自校验/参考对比方式。

## 7. 风险与回退
- 已知风险、历史踩坑引用（记忆/task-run）、不收敛时的回退点（git checkpoint）。

## 8. 变更记录
- 日期 / 改动 / 验证证据。
