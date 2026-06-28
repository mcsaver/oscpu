# OooIntBackend 巨石拆分 Spec

## 1. 目标

`execute/OooIntBackend.v`（~2167 行）是双发射整数 OoO 执行后端：issue、操作数旁路、
ALU/CompareUnit/LSU/WBU/MulDiv/CLMUL 实例、分支解析、写回 FSM，外加 23 个 helper
函数。本战线把其中**可干净分离、纯组合**的功能块抽为独立 owner，沿用 RED→GREEN
专属 testbench + 全回归；不触碰深度流水线耦合的旁路/调度/写回 FSM。

## 2. 已抽出的 owner（纯组合，行为等价）

| owner | 文件 | 职责 | 专属 TB |
| --- | --- | --- | --- |
| 整数位操作 | `execute/OooBitmanipGate.v` | Zba/Zbb/Zbc/Zbs 走 bitmanip 路径的指令结果（clz/ctz/popcount/rol/ror/andn/min-max/bset 等，含 dispatcher） | `tb_ooo_bitmanip_gate`（5 op smoke） |
| 原子访存结果 | `execute/OooAmoGate.v` | RV64A AMO（swap/add/xor/and/or/min/max[u]，W/D）的旧值规整与新值计算 | `tb_ooo_amo_gate`（7 op） |

抽取判据：函数仅服务该子路径、不被 issue/bypass 主逻辑共享；trivial 的 `sign_extend_word`
随 owner 复制以保持自包含（父模块仍保留同名共享副本）。bitmanip 两条 issue lane 各
例化一个实例。`OooIntBackend` 由 2167 行降到 1845 行。

## 3. 停止边界（不再拆）

剩余 helper 与逻辑属于以下两类，继续拆为负收益/不可接受风险，故停止：

- **深度流水线耦合**：`select_op1/op2`（操作数旁路选择）、`rob_distance_from_head` /
  `rob_idx_older_than`（ROB 年龄比较）、两个 `always` 块（issue 组合 + 写回时序 FSM）。
  这些是 OoO 调度/旁路核心，拆出会把流水线逻辑碎片化并引入时序相关 bug。
- **过于平凡**：`rv64_word_alu_result`（W 后缀 ALU，~18 行）、`is_clmul_inst` /
  `clmul_op_from_funct3`（CLMUL 译码 helper）、`sign/zero_extend_word`。单独建模块
  反而降低可读性。

## 4. 验证（每刀）

- `make -C npc/rv64 lint` / build PASS；module testbench 全 PASS（含两个新 owner TB）；
  official riscv-tests（含 rv64ua 38 项 AMO、rv64uzb* 70 项 bitmanip）177 项 0 FAIL。

## 5. 边界

只做纯组合 owner 外移，不改 issue/bypass/写回时序、ROB 顺序或分支解析语义。
