# 规范：FP dispatch admission credit 与双 lane 原子接收

> 模块：`OooIntBackend`、`OooFpBackend`、`OooDispatchBackend`、
> `OooFreeList`、`OooFpIssueQueue`。
> 状态：**T3C 已实现并验证；admission 真环已清除（2026-07-13）**。

## 1. 根因与目标

当前 FP 入口把 `disp_valid/fpld_alloc_valid` 与 `dispatch*_dbe_ready` 先相与，
而 `FpBackend.ready` 又通过 `FreeList.alloc1_ready` 或 `FpIssueQueue.dispatch1_ready`
依赖实际 `fire`。这使下面的组合 SCC 成为真实协议环：

```text
FP ready -> IntBackend valid gate -> DispatchBackend pair ready/fire
         -> FpBackend alloc/IQ fire -> lane1 ready -> FP ready
```

T3C 用“raw intent -> state-only credit -> joint admission -> actual accept”恢复 ready DAG，
不增加流水级、不建立影子计数器，也不改变 FP 执行/完成时序。

## 2. 接口契约（六类）

### 2.1 握手

- `disp*_valid` 与 `fpld*_alloc_valid` 是上游原始意图，只由 packet valid 与指令类别产生，
  **不得包含任何 ready/accept/fire**。
- ready 只由已寄存 `fp_free_count`、`fp_iq_count`、raw resource need 以及既有
  kill/recover 门控生成；不得读取 FreeList/FpIQ 的组合 ready/fire。
- `accept0/1` 是 `OooDispatchBackend.dispatch*_fire` 对 FP resource uop 的资格化投影；
  FP map、free list、busy 与 FP IQ 只在 accept 时更新。
- accept 必须蕴含同 lane raw intent 与 credit ready；否则触发立即断言。

### 2.2 stall / backpressure

- lane0 local capacity：满足 lane0 自身 0/1 个 FPR credit 与 0/1 个 FP-IQ credit。
- packet capacity：满足两 lane resource need 的精确和（各类 0/1/2）。不预借本拍 issue、
  commit 或 free 产生的槽位，保持现有保守时序。
- mandatory lane1 时 packet capacity 不足必须 `fire0=fire1=0`；optional lane1 可只 fire0。
- raw valid/payload 在 backpressure 期间由上游保持；accept=0 时 FP map/free/busy/IQ 全冻结。

### 2.3 flush / kill / redirect

- same-cycle branch kill 与 recover 继续阻止 FP admission；不得为切环注册 long-op/branch kill。
- trap flush 仍把 FP map 恢复恒等映射、FreeList/IQ 清到初态、物理堆从架构 FPR 恢复。
- ROB-walk 的 map restore/free 与 IQ age squash 语义不变；本刀不新增 replay owner。

### 2.4 异常序

- illegal FP 指令仍在上游形成精确异常，不得消耗 FP credit。
- 已接收 FP uop 的 ROB owner、fflags、FP/GPR destination 与完成 FIFO 顺序不变。
- admission stall 只延迟接收，不允许单边修改 rename 后再等待另一 lane。

### 2.5 访存序

- FP arithmetic 每 lane需要 1 个 FP-IQ credit；仅 FPR 目的时再需要 1 个 FPR credit。
- FP load 不进 FP IQ，但需要 1 个 FPR credit；FP store不需要这两类 credit。
- load/store 的整数 IQ、SQ/MIQ、翻译、请求与响应 owner 全部保持现状；只有 load 的 FPR
  rename allocation 改由 actual accept 驱动。

### 2.6 投机恢复 / 单一真源

- `OooFreeList.count_q` 与 `OooFpIssueQueue.count_q` 是唯一容量真源；禁止增加第二份
  credit counter、reservation bit 或 ingress shadow state。
- raw intent 只描述请求，actual accept 才拥有状态变化；两者不得混为 fire。
- mandatory pair 原子性由可执行断言 `[FP-DISPATCH-PAIR-ATOMIC]` 看护。

## 3. 精确 credit 公式

```text
free_need0 = raw lane0 FPR-destination arithmetic or FP load
free_need1 = raw lane1 FPR-destination arithmetic or FP load
iq_need0   = raw lane0 FP arithmetic
iq_need1   = raw lane1 FP arithmetic

lane0_cap = free_slots >= free_need0 && iq_slots >= iq_need0
packet_cap = free_slots >= free_need0 + free_need1
          && iq_slots   >= iq_need0   + iq_need1
```

- lane0 class ready 使用 `lane0_cap`。
- lane1 class ready 使用 `packet_cap`，因为 lane1 fire 恒与 lane0 packet accept 同拍。
- `OooIntBackend` 在 mandatory lane1 raw valid 时还必须用 `packet_cap` 门控 lane0；
  optional lane1 不反压 lane0。

## 4. 周期模型

| 周期 | raw intent | capacity | DBE fire | FP 状态 |
| --- | --- | --- | --- | --- |
| N（有容量） | 稳定呈现 | state-only ready | mandatory 0/1 同 fire | N 沿按 accept 更新 |
| N（无容量） | 保持不变 | ready=0 | 两 lane均0（optional可仅0） | 完全冻结 |
| N+1（资源恢复） | 同一 payload | ready=1 | 恰好接收一次 | map/free/IQ 各更新一次 |

## 5. RED / GREEN 与非声明

- mandatory pair 在 free/IQ 边界：无容量时不得单边 fire/分配，恢复后各一次。
- 枚举 lane0/lane1 对 free/IQ 的 0/1/2 need 与容量 0/1/2。
- accept=0 多拍：map、free count、IQ count、ROB count 不得漂移。
- optional lane1：资源不足时只允许 lane0；mandatory 时两者都不允许。
- 负探针故意制造 `fire0 ^ fire1`，必须命中 `[FP-DISPATCH-PAIR-ATOMIC]`。
- Verilator full build 必须不再依赖 UNOPTFLAT 围栏；fresh OpenSTA 应验证 FP admission SCC=0。

本刀只修 FP admission DAG，不声明 T3B 的 long-op 环已经由网表证实消失，也不声明达到
physical 200 MHz；后者仍需 full regression、CoreMark 与 fresh 5ns A/B。
