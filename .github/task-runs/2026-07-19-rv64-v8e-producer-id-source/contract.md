# RV64 v8e ProducerId allocation source 合同

## 设计状态与完成定义

- `design_state`: `intermediate_checkpoint`
- `scope`: canonical `OooRob` 内建立 allocation-issued ProducerId shadow 真源，并把 ROB 自有的
  dispatch/head/commit/walk 观察口绑定到同一每槽 generation 状态。
- `parent`: 当前 v8d shared worktree；runner 运行时以 source inventory SHA-256 绑定具体版本。
- `complete_when`: 参数化 4+4 编码、accepted-allocation-only generation、flush/recovery/commit 保持、
  双 lane/自然环回、真实 branch-walk 后被流水取消的同槽新旧 ID 区分、有限宽回绕 current-RED
  均有可重放证据；功能拍的 legacy count/commit/WB/recovery 行为不变，reset/flush 拍 ready
  显式 fail-closed，禁止接口宣告一次实际未落状态的伪接受。
- `rollback`: 删除新增 generation 阵列和纯观察端口即可回到 parent，不改变既有 payload/控制位段。

本切片不是 complete design point，不进入 Pareto、baseline、architecture seed 或 PPA promotion。

## 编码与单一真源

```text
ProducerId = {slot_generation[3:0], rob_idx[3:0]}
candidate(slot) = {slot_generation_q[slot] + 1 mod 16, slot}
```

- `OOO_PRODUCER_GEN_W=4` 与 `OOO_PRODUCER_ID_W=OOO_PRODUCER_GEN_W+OOO_ROB_INDEX_W`
  独立定义；不能把 context/MMU epoch 当作 producer incarnation。
- `slot_generation_q[slot]` 保存该槽最近一次 accepted allocation 的 generation。硬复位初始化为
  全 1，使首次 accepted allocation 发出 generation 0。
- 只有对应 lane 的 `dispatch_valid && dispatch_ready` 才能把 candidate 写回该槽 generation；
  leaf 与 parent 的 ready 在 `rst || flush_i` 时都必须为 0，使该握手与状态更新优先级一致；
  `dispatch_valid` 未 fire、WB、commit、kill、walk、recovery 和普通 `flush_i` 均不得推进、回滚或清零。
- `dispatch0/1_producer_id_o` 只在各自 allocation fire 时有事务语义；`head0`、`commit0/1`、
  `walk0/1` ID 分别由已有 valid/fire 限定。
- raw `rob_idx` 继续负责数组寻址与环形年龄；ProducerId 只表达 incarnation equality，不参与排序。

## 六类接口契约冻结

| 类别 | 本切片合同 |
|---|---|
| 握手 | lane ID 与同 lane allocation candidate 同拍；`rst/flush` 时 parent/leaf ready 均为 0；无 reset/flush/recovery 事件的 stall 期间 tail 与 generation 不变，因此 candidate 稳定。 |
| 反压 | P1 不新增 identity collision backpressure；除修正 reset/flush 伪接受外，不改变功能拍 ready/fire。future collision guard 必须读 registered global-live scoreboard，并进入 `OooDispatchBackend` parent ready，不能只改 child ROB ready。 |
| flush/recovery | `rst` 可初始化 generation，前提是整个 reset domain 同步清除全部 holder；普通 flush、selective recovery、commit 只结束 ROB 本地引用，generation 保持。 |
| 异常序 | commit/exception/fire 公式逐位不变；新增 commit ID 只是已退休 entry 的观察 payload。 |
| 访存序 | 不改变 SQ/MIQ/bridge、AXI 或 memory token；这些 holder 尚未携带 ProducerId。 |
| 投机恢复/单一真源 | ROB 每槽 generation 是 allocation 编码唯一真源；walk/survivor ID 从同一阵列读取，squash 不回滚已消费 generation。 |

## 有限宽回绕与未来 active 条件

令 `L(t)` 为所有未来仍可能产生副作用的 ProducerId 引用集合。任何有限宽 generation 的 active
必要条件都是：

```text
allocation_fire(candidate) -> candidate not-in L(t)
authorized_completion = response_valid && target_live &&
                        response_producer_id == target_producer_id
```

全局 last-reference/collision scoreboard、全 AUTH carrier 传播及所有副作用前 exact-ID gate 尚未实现。
因此本刀必须同时证明小位宽会回绕且当前分配不会阻塞，状态账本固定为：

```text
PRODUCER_ID_ALLOCATION_SHADOW=LOCAL_GREEN
GLOBAL_NO_LIVE_REUSE=RED
GENERATION_SAFE_FULL_IDENTITY=RED
WRITEBACK_AUTHORIZATION=RED
Q1_CSR_LIVE_OWNER=RED
```

## 机器验证合同

focused runner 必须 fail closed 地完成：

1. release 与 `OOO_ASSERT` 两构建各出现一次精确 PASS marker；
2. 首次双分配、lane/idx 字段、head/commit/walk 观察、stall 不推进、flush 保持、真实 branch-walk
   后同 raw idx 新旧 ID 不同；
3. `PRODUCER_GEN_W=1` 回绕用例精确观察旧 ID 再现且 allocation 未阻塞，作为 current-RED 非声明；
4. 13 个 compile-success semantic mutations 定向检出 generation 不推进、valid-not-fire 推进、
   lane1 复制 lane0、flush/commit/recovery 清 generation、reset/flush ready 漏门控、public ID 丢
   generation、字段顺序错误、commit/walk carrier 串 lane及 parent ready 漏门控；
5. 既有 raw-index late-WB current-RED 与正常 new-WB 正控继续成立，证明 P1 没有伪装成 active 修复；
6. runner 对所有编译依赖、复用的 raw-index witness 源与复制后的 witness/正控证据做 pre/post SHA
   和 completion manifest 绑定；current module aggregate、style、contract 与 full lint 状态分层记录。

## 明确非声明

本合同不声明全局 generation-safe identity、no-live-reuse、WB/PRF/Busy/IQ/FPR/public completion
授权、全 carrier 传播、reset-domain late response 安全、Q1/CSR、双 memory、Linux、综合/STA/power
或 PPA 改善。
