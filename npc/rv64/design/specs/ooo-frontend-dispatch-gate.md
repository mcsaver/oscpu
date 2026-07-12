# OoO Frontend Dispatch Gate

> **状态（2026-07-13，FDG-G1 + IFU-LANE1-OWNER CLOSED）**：模块仍在活跃主路径；
> `frontend_dispatch_to_backend_valid_o` 已在唯一 ordinary-admission 方程中排除
> `dispatch0_arch_trap_i`。关闭证据包括旧 RTL 精确 RED、focused GREEN、父级断言负探针、
> 87/87 module、59/59 Difftest-ON AM 与 177/177 official tests；证据索引见
> `.github/task-runs/2026-07-12-rv64-f1-fdg-g1/`。

## 1. 需求

`OooFrontendDispatchGate` 负责收敛 `OooAluFetchCore`（现已重构为 `OooFrontend`
wrapper）中 dispatch 入口的纯组合 gating：

- lane1 direct JAL candidate。
- lane1 direct return candidate。
- lane1 direct branch candidate。
- lane1 barrier / unsupported 判定。
- normal dispatch fire。
- direct JAL0/JAL1、direct ret1 fire。`direct_branch1_fire_o` 是兼容输出，当前固定为 0；
  taken 预测已经前移到 fetch-response，dispatch 拍不再执行 branch1 fast fire。
- 【F2】head0 分支双发资格 `dbranch_dual_go`（预测 not-taken 且 head1 平凡 →
  不 fire 不 flush，原子双发）与 domain-A 分支普通 dispatch fire
  `dbranch_dispatch_fire`（FIFO pop 源）。

本模块只消费父模块已经计算好的 raw predicate 和 ready 信号，不解码指令、不读取 PC/ROB/CSR/RAS/FIFO，也不更新任何状态。

## 2. 协议

### 2.1 端口/owner 合同

| 端口族 | 方向/时序 | owner | 本模块责任 |
| --- | --- | --- | --- |
| `dispatch_valid_i`、`dispatch0_*_i`、`head1_*_i` | input / 纯组合 | 父级 FIFO/head classifier | 只消费整拍稳定的当前 head facts，不缓存 |
| `dispatch*_ready_i` | input / 纯组合 | backend dispatch | 只参与 action fire；不得反馈进 ordinary backend valid |
| `frontend_dispatch_to_backend_valid_o` | output / 纯组合 | 本 gate 产生，BackendDispatchMux 消费 | 表示普通 head0/1 可呈现；不是事务存储，也不是 actual fire |
| `dispatch_fire_o` 与 direct/barrier fire | output / 纯组合 | 本 gate | 按既有 ready 和特殊路径合同生成，本刀不改 owner |

输入：

- `dispatch_valid_i` 表示当前 FIFO/head packet 可以进入 dispatch 组合判断。
- `dispatch0_*_i` 是 slot0 已经归类后的 dispatch predicate。
- `head1_*_raw_i` 是 slot1 原始分类 predicate。
- `head_fetch_fault1_i` 表示 slot1 fetch response fault。
- `head1_return_candidate_i` 与 `lane0_before_ret_safe_i` 已由父模块/RAS safety helper 计算。
- `dispatch*_ready_i` 与 `dispatch*_unsupported_i` 来自后端 decode/dispatch glue。
- 【F2】`head0/head1_branch_pred_taken_i` 是纯 BHT 寄存输出（不含 ready，防组合环）；
  `dispatch*_unsupported_raw_i` 是裸支持性（纯 inst 组合，dual_go 谓词专用）；
  `dispatch0_return_i` 用于区分返回/非返回 JALR（B2 de-pend）。

输出：

- `dispatch1_direct_jal_o`、`dispatch1_return_o`、`direct_branch1_dispatch_valid_o` 描述 lane1 可走的特殊 fast path。
- `dispatch1_barrier_o` 表示 slot1 需要形成 lane1 barrier，而不是普通双发。
- `dispatch1_control_unsupported_o` 与 `dispatch_unsupported_o` 保持旧 unsupported 边界。
- `dispatch_fire_o` 表示普通 slot0/slot1 双发。
- `dispatch1_barrier_fire_o`、`direct_jal0_fire_o`、`direct_jal1_fire_o`、
  `direct_ret1_fire_o` 是父模块后续控制使用的 action fire；
  `direct_branch1_fire_o` 当前固定为 0。
- `dbranch_dual_go_o`、`dbranch_dispatch_fire_o`、`frontend_dispatch_to_backend_valid_o`、`lane1_barrier_dispatch0_valid_o` 供 dispatch mux 与 FIFO pop 消费。

### 2.2 stall、flush/trap 与同拍优先级

- 本模块无 stall 状态；downstream stall 时由父级 FIFO/head owner 保持 payload，本 gate 只重算同一组稳定 facts。
- `frontend_dispatch_to_backend_valid_o` 禁止依赖 `dispatch*_ready_i`，避免 valid↔ready 组合环。
- 本模块不清任何状态，也不拥有 flush/redirect。`dispatch0_arch_trap_i` 只做 ordinary backend-present 排除；pending trap/stop、redirect 与 FIFO 动作仍由既有 owner 负责。

| 同拍事件 | ordinary backend present | lane1 | pending trap/stop | committed store / 已发 AXI / CSR commit |
| --- | --- | --- | --- | --- |
| head0 arch trap | **强制 0（最高排他优先级）** | 既有 lane1-base 阻断 | 保持既有捕获/停止 | 全部保持，不在本模块职责 |
| head0 exit/system | 保持既有排除 | 保持既有阻断 | 保持既有 owner | 全部保持 |
| 普通合法 head0 | 按 branch/jal/jump/barrier 方程呈现 | 按既有双发合同 | 无新增动作 | 全部保持 |

## 3. 状态机

本模块无状态、无寄存器、无 ready/valid side effect。所有输出由输入纯组合决定。

时序模型只有一条组合规则：`head facts -> candidate/barrier/ordinary-valid -> downstream mux`。
reset/flush/kill 不进入本模块；同拍竞争由 §2.2 的排他表静态解决，不存在跨拍状态转移。

## 4. 不变量

- lane1 普通/特殊 dispatch 必须被 slot0 exit/trap/system/JAL/JALR 阻断；slot0
  分支仅在非 `dbranch_dual_go` 时阻断（F2），但 `head_fetch_fault1_i=1` 时必须形成
  barrier，让更老的 branch 先入 ROB、fault 进入 pending owner；slot0 FP 已迁域 A。
- lane1 branch fast path 仍要求 slot1 无 fetch fault。
- lane1 barrier 必须覆盖 slot1 fetch fault、exit/system/trap、不可直接处理的
  branch/JALR；slot1 FP 已迁域 A 走普通双发，非返回 JALR 在
  `OOO_ROB_WALK_MODE=1` 下走 de-pend 双发（`dispatch1_depend_jump`）而非 barrier。
- 旧 `dispatch_unsupported` 语义必须保留：它排除 slot0 branch/JALR，但不额外排除 slot0 JAL；slot0 JAL 自己由 direct JAL path 消费。
- `dispatch1_mem_unsupported_o` 当前固定为 0，表示 lane1 memory 不再作为 unsupported 边界。
- 不改变 direct branch0、仍活的 pending system/trap、commit 或 redirect 时序所有权；
  已删除的 pending branch/jump/mem/fp 四类不再属于本模块职责。
- **CURRENT**：head1 `arch_trap` 形成 barrier，只允许更老的 slot0 走
  `lane1_barrier_dispatch0_valid_o`；trap 槽本身不作为普通 lane1 backend dispatch。
- **FDG-I1 / FDG-G1（CLOSED 2026-07-12）**：
  `dispatch0_arch_trap_i -> !frontend_dispatch_to_backend_valid_o`。主 backend-valid 方程
  已加入该排除项，父级 `OooFrontend` 同时用时钟立即断言守住精确异常边界；断言不重述
  FP decode，因而覆盖 fetch fault、illegal、privileged illegal 等所有 arch-trap 来源。
- **FDG-I2 正对照**：合法 FADD.S/普通 ALU 仍可 ordinary backend present，防止用“全部关断”假修复。
- **FDG-I3 无环**：ordinary backend valid 不依赖 ready；新增排除项只消费 classifier fact。

## 5. 数据通路

1. 计算 lane1 base：`dispatch_valid && !slot0 exit/trap/system/JAL/JALR &&
   (!slot0 branch || dbranch_dual_go || head_fetch_fault1)`（slot0 FP 不参与阻断）。
2. 在 lane1 base 下生成 direct JAL、return、branch candidate。
3. 在 lane1 base 下生成 barrier 与 control unsupported。
4. 普通 `dispatch_fire` 要求 lane1 base、无 barrier、无 unsupported、两个 dispatch ready。
5. direct JAL/return fire 只做 action 组合，不修改状态；branch1 fire 固定为 0。

## 6. 验证与关闭证据（2026-07-12）

- 必须保留合法 FADD.S 的正对照。
- 必须覆盖 unknown OP-FP funct7、reserved FMA fmt、reserved static rm、
  DYN+reserved frm，并检查 `arch_trap && frontend_dispatch_to_backend_valid`。
- 常驻整链 TB 必须把 classifier 与 dispatch gate 串接；旧 RTL 对上述四类反例精确 RED，
  修复后四类均满足 `illegal && arch_trap && !fp_enabled && !backend_valid`，合法 FADD.S 满足
  `fp_enabled && !arch_trap && backend_valid`。
- 父级立即断言必须用故意 force `arch_trap && backend_valid` 的负探针证明会响，再跑正常回归证明恒静默。

实测关闭矩阵：

| 层级 | 结果 | 裁决边界 |
| --- | --- | --- |
| RED | 旧 RTL 四类非法 FP 均只在 `backend_valid` 期望处失败，共 4 errors | 证明缺口可达，不是只读代码推断 |
| focused | classifier→ordinary-admission 4/4 PASS；合法 FADD.S 正对照 PASS | 新整链 TB 止于 gate 输出；下游 mux 的直接 OR sink 由结构审查和既有 mux TB 覆盖 |
| assertion mutation | 强制 `arch_trap && backend_valid` 后出现 `[FDG-CONTRACT FDG-I1]`，runner 非零 | 证明断言非真空；正常 87 项回归静默 |
| full functional | module 87/87；AM Difftest ON 59/59；official 177/177 | 均采信原始子层 rc；不采信错误环境下的旧 binary 结果 |
| structural | lint、`check-rtl-style`、`check-contract` PASS；assert baseline 固定为 35 | baseline 35 需以 `current=35` 复跑锁定 |

本切片只关闭功能合同。尚未据此声称 5 ns 时序改善或 200 MHz 达标；正式重综合与 STA
归入后续架构切片的同模型 A/B。

IFU-LANE1-OWNER 补充矩阵：ordinary+PF/AF、pred-NT actual-NT/actual-taken、predicted-taken
poison、head0 fault/control priority，以及无 provenance 的 pseudo default ACCESS filter 均由
`tb_ooo_ifu_lane1_fault_owner` 常驻覆盖。actual-taken 的 pending fault 被 squash；actual-NT
则只在 older branch 后形成精确 trap。
