# OoO branch-resolve ProducerId authorization spec

## 1. 目的与范围

本规范定义 `OooIntBackend → OooDispatchBackend → OooRob` 的 registered branch-resolve
生产者归属与控制副作用授权。它解决 resolve q 只保存 raw ROB index、却能直接触发 redirect、
ROB walk、BPU update 和多 holder selective kill 的 generation-alias 风险。

不改变分支目标计算、预测策略、redirect 优先级、ROB-walk 算法、流水拍或 ready/valid；不处理
pending-system/CSR 和 finite-generation global reuse。

## 2. 接口契约

### 2.1 端口与责任

| 信号 | 方向 | 位宽 | 时序 | 单一责任 |
|---|---|---:|---|---|
| resolve candidate valid/PID | IntBackend→DispatchBackend | 1 / `PRODUCER_ID_W` | branch q 组合输出 | 声明待查询的 full P，不代表已授权 |
| resolve query valid/PID | DispatchBackend→ROB | 同上 | 组合透传 | 不缓存、不修改身份 |
| resolve query match | ROB→IntBackend | 1 | edge-old ROB 组合查询 | exact P、valid、!done、!recover_q 权威 |
| branch resolve outputs | IntBackend→wrappers/frontend | 既有 ABI | 组合 | 只承载 authorized capability/payload |
| raw kill boundary | IntBackend→ROB/IQ/FU/memory | `ROB_INDEX_W` | 组合 | 仅为 authorized P 的低位年龄投影 |

query 不参与 ready/valid 反压：branch q `down_ready=1`，query match 只能门控语义输出，不能门控
q 的物理消费或上游 issue。

### 2.2 典型时序

```text
cycle N    issue0 control-flow fire(P)
edge N     branch_q<=P, ex0_q<=P
cycle N+1  ROB resolve_query(P); compare branch_q.P==raw registered ex0_q.P
           open+coherent -> one authorized resolve pulse
           otherwise     -> silent physical consume
edge N+1   branch_q/ex0_q consume; optional mispredict starts ROB recovery
```

### 2.3 flush/redirect 谁清谁保持

| 事件 | branch q | ROB slot | downstream effect |
|---|---|---|---|
| reset/global flush | 清 | ROB按既有规则清 | 全静默 |
| checkpoint restore | 清 | 按既有恢复 | 全静默 |
| prior `recover_q` | 不应捕获；残留可消费 | walk继续 | query closed，全静默 |
| current P mispredict | 正常消费 | P保留、严格年轻后缀 walk | P 的 authorized redirect/kill允许 |
| slot invalid/done/PID mismatch | 可消费 | 不改 | 全静默 |
| trap redirect squash（上层） | source capability可形成 | 不改 | redirect由既有上层优先级屏蔽；BPU/resolve 语义按现有合同 |

同拍全序：`reset/global flush > checkpoint/prior recovery > exact-open/coherence > branch effect >
ordinary consume`。全核 redirect 全序仍为 `trap/exit > CSR/xRET > branch mispredict > BPU/RAS > 顺序PC`。

## 3. 状态与时序模型

### 3.1 状态

不新增状态。branch q 是 `PipeStageReg` 的单项 `EMPTY/OCCUPIED(P)`；ROB 既有 slot 保存
`valid/done/generation`，`recover_q` 保存 prior recovery 状态。

### 3.2 转移

| 当前 | 条件 | 下一 | 语义输出 |
|---|---|---|---|
| EMPTY | issue control-flow fire(P) | OCCUPIED(P) | 0 |
| OCCUPIED(P) | open(P) && raw `ex0_valid_q` && `ex0_producer_id_q==P` | EMPTY | authorized pulse |
| OCCUPIED(P) | stale/mismatch/cancel/recover | EMPTY | 0 |
| 任意 | reset/flush/checkpoint | EMPTY | 0 |

### 3.3 寄存器清单

| 状态 | 复位 | 更新 | 优先级 |
|---|---|---|---|
| branch `PipeStageReg.valid/payload` | 0 | issue fire / consume | reset > flush/checkpoint > normal |
| ROB `valid/done/generation/recover_q` | 既有 | 既有 allocate/WB/commit/walk | 本切片不改写规则 |

## 4. 不变量

1. authorized ⇒ branch candidate、ROB exact-open(P)、raw registered `ex0_valid_q` 且
   `ex0_producer_id_q==P`。coherence 禁止读取 completion-open、killed-now、WB-valid 或其他
   semantic-valid 派生信号。
2. raw boundary 等于 P 低位；generation 不得在授权前丢失。
3. query 不读 self-generated `kill_valid_i`，也不进入 transport/ready，避免组合反馈。
4. stale/done/invalid/prior-recovery/cancel candidate 的全部语义输出为零。
5. identity mismatch 生产态 fail-closed；assertion 是诊断，不是唯一保护。
6. 当前 `kill_valid_i` 只由本 authorized resolve 产生，且 `flush/checkpoint` 不是 capability 的
   组合后代；未来新增独立同拍 kill source 时必须重新冻结无环仲裁合同。
7. 并行 killed-now helper 必须 `automatic`，并把 `target/head/current-kill/recovery` 全部作为
   显式实参；函数体不得隐式读取这些全局信号，以保证同 PID 下 kill 翻转也重新求值。

## 5. 关键路径与时序考量

新组合锥为 `ROB slot state → exact PID compare → authorized resolve → existing redirect/kill`。不增加
流水拍；当前阶段只做结构与后续 diagnostic STA，不宣称 timing/PPA GREEN。

## 6. 验证计划

- `tb_ooo_int_backend`：live、stale-generation、branch/raw-EX0 full-PID mismatch、done/invalid/recovery、
  reset/flush/checkpoint、自身 mispredict boundary（全部语义输出恰好一拍）。
- `tb_ooo_rob`：resolve query exact/open/death-edge 与同拍 self-kill cycle-free 语义。
- `tb_ooo_rob` 另覆盖 target PID/index 不变时 current kill 置位→撤销，completion query 必须重开。
- 结构依赖审计：coherence 只读 raw EX0 q；query 不读 `kill_valid_i`；flush/checkpoint 不是
  capability 的组合后代。
- compile-success mutation：删 generation/query/raw-EX0 coherence/done/recovery/cancel fence，或把
  coherence 换成 semantic valid / query 换成 killed-now-inclusive，均须命中。
- legacy branch、v8d/v8f/v8g/v8h/v8i focused 与 module aggregate 不回退。

## 7. 风险与回退

- query 增加 redirect critical cone；若 fresh diagnostic timing 证明不可接受，另立保持同语义的
  预计算/寄存架构切片，不能退回 raw-index authorization。
- 本地 GREEN 不外推 pending-system/CSR、global reuse、Linux 或 PPA。

## 8. 变更记录

- 2026-07-19 v8j：reviewer 反例将 coherence 收紧为 raw registered EX0-only，并冻结无反馈结构前提；
  实现 smoke 进一步修复 killed-now helper 的 automatic/显式敏感性根因。
