# v8e ProducerId holder census delta

本文件只记录相对 v8c P0 历史 census 的增量，不改写已经封存的 P0 快照。

| holder | v8c P0 | v8e P1 | active claim |
|---|---|---|---|
| `OooRob` | raw index + zero-extended context shadow | 每槽 4-bit generation；dispatch/head/commit/walk 公开 8-bit allocation shadow | `LOCAL_SOURCE_GREEN`；WB 仍 raw-index authorization，global RED |
| `OooDispatchBackend` | raw ROB index integrator | 连接 7 个 ROB ProducerId 观察口并终止于 unused sink；未向 IQ/EX/WB 传播 | propagation RED |
| Int/FP IQ、EX、长操作、SQ/MIQ、bridge、PRF/Busy/FPR/public completion | raw index/local token | 未改变 | exact authorization RED |
| detached Q1/CSR owners | detached/raw owner | 未改变 | Q1/CSR live owner RED |

状态账本：

```text
PRODUCER_ID_ALLOCATION_SHADOW=LOCAL_GREEN
GLOBAL_NO_LIVE_REUSE=RED
GENERATION_SAFE_FULL_IDENTITY=RED
WRITEBACK_AUTHORIZATION=RED
Q1_CSR_LIVE_OWNER=RED
```

有限位宽的 active 必要条件仍是：

```text
allocation_fire(candidate) -> candidate not-in global_still_live_reference_set
effective_completion = response_valid && target_live &&
                       response_producer_id == target_producer_id
```

v8e 没有新增 global live-set、collision stall 或任何副作用端 exact-ID gate。P0 的 real
branch-recovery + raw-slot reuse + late-old-WB 见证在 v8e runner 中重新执行并复制源清单、见证、
正控和 completion hash，结果继续为 expected RED。

