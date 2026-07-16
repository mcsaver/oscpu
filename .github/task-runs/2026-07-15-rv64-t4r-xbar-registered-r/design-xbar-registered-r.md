# T4R：AxiXbar 非穿透 R response slice

## 红线证据

- T4Q 冻结 RTL、fresh synthesis、exact 5.0 ns global STA：WNS
  `-0.131193727 ns`、TNS `-17.255960464 ns`，40/40 最差路径同族。
- 起点为 `AxiXbar.rd_active_q[0]`，经过 16 路 slave RDATA fall-through
  mux，再串入 `OooFetchAxiBridge` 的 leaf PA/PMP 与 response payload D。
- 旧网表定量拆分：到 xbar `m_rdata_o[17]` 约 `2.322576 ns`；桥内
  leaf PA/PMP/response mux 约 `2.764562 ns`。

## Root cause

`AxiXbar` 已有 per-master `rd_resp_{valid,data,resp,id}_q`，但只在 master
反压时使用；master ready 时 slave R 组合穿透到 master。这不是约束缺口：同一
结构也服务可执行 memory slave，不能用 false path 或 multicycle 掩盖。

## 架构契约

1. `m_rvalid/data/resp/id` 只能由 per-master response q 驱动；禁止
   slave-to-master fall-through bypass。
2. slave R fire 时，无论 master ready 与否，都原子捕获 data/resp/id 并置
   `rd_resp_valid_q`，同时释放 slave owner。
3. `rd_master_busy_q` 只能在后续 buffered master R fire 时释放；响应被消费前
   同 master 不得接受新 AR。
4. buffer 空时仍无条件接收 slave R，保留“先释放 slave、避免另一 master
   被阻塞”的反死锁性质。
5. 代价为所有 IFU/LSU/PTW/MMIO read response 固定增加一拍；cache hit 不经过
   xbar，因此不受影响。

## 验证要求

- xbar TB 显式证明 capture 拍 master RVALID=0、下一拍注册响应出现、反压 payload
  稳定、同 master busy 不提前释放、另一 master 可继续取得已释放 slave。
- fetch bridge、fetch+xbar、mem bridge 定向 TB 与完整 module suite 全绿。
- 新鲜综合后必须重跑 exact 5.0 ns global STA；T4Q 失败证据不得覆盖。

