# V9O 类型化控制事件合同

## 本地工程范围

工作对象是本地 RV64 Verilog/SystemVerilog 双发射 OoO 核；操作范围限于工作区内的
RTL、testbench、仿真、综合/STA 辅助检查和生成证据。本切片处理控制事件如何在正确流水
周期驱动：

1. 前端取指 PC 重定向与前端清空；
2. 分支误预测边界之后的更年轻 ROB/IQ/执行/访存/FP 事务回收；
3. 精确陷阱或队头 CSR 退休后的全后端清空；
4. pending-system CSR 精确 owner 提交时对同拍更年轻分支的优先级；
5. `reason`、`kill_younger_than`、`flush_fetch` 与 `backend_action` 的同源身份。

`mmu_flush`、cache policy 与 PPA 拓扑保持正交，不并入控制事件仲裁。AXI 已登记事务的
驻留与终结合同也不参与 PC 赢家选择，但作为 C0 屏障的必须保持边界在本合同中验证。

## 架构需求

- canonical winner：`OooRedirectArbiter` 按 `rob_idx - rob_head` 年龄律选择唯一前端类型化
  事件；同年龄保持 `trap > branch > direct`。该输出是规范参考视图和前端消费真源。
- cycle-free production projection：最终前端赢家不得直接反馈到 backend ready/commit
  组合锥。ROB 从 edge-old Q 状态、commit 许可和精确 pending CSR ProducerId 产生
  `head0_control_event_pregrant`；后端分支事件只在
  `branch_request && !head0_control_event_pregrant` 时成立。双向立即断言必须证明该投影
  与最终前端 `SELECTIVE_NOW/FULL_NEXT` 赢家一致。
- branch apply phase：被授权的 branch/JALR 事件在解析拍执行严格年轻选择性恢复，并携带
  同源 `kill_younger_than`；不能延迟到下一拍。
- full apply phase：精确陷阱与 queue-head CSR 的全后端清空保持“C0 提交并建立屏障、
  C1 寄存类型化事件施加清空”，不能让 C0 屏障抑制队头退休或 CSR 架构写。
- single C0 request source：`OooControlEventApplySequencer.request_valid_i` 只能直接读取
  ROB edge-old `head0_full_flush_pregrant`。实际 trap commit 与 queue-head CSR commit
  是同一 C0 记录的架构后果，必须分别与 `TRAP/CSR_COMMIT` pregrant 做双向等价断言；
  禁止把这些提交脉冲重新 OR 回 request，避免出现没有 C0 younger-work barrier 的晚到
  C1 请求表示。
- pending CSR phase：若队头 CSR 的
  `{slot_generation, rob_idx}` 精确匹配 pending-system owner ProducerId，则该提交事件为
  `CSR_COMMIT/NONE`。它关闭同拍新 dispatch 和更年轻 branch 事件，但不产生
  `FULL_NEXT`、completion cut 或 C1 全清空。
- direct phase：dispatch 期 direct 控制流只清前端，不清后端。
- transaction boundary：已登记的 STORE/AMO/AXI 事务继续由各自 owner 与 terminal
  合同完成；C0 只停止新 station/pre-owner 准入，不能撤回 registered AXI VALID。

## 接口合同

统一事件至少携带：

```text
valid, pc, reason, kill_younger_than, flush_fetch, backend_action
```

其中 `backend_action` 必须区分 `NONE`、当拍选择性恢复与下一拍全后端清空，不能由单个
`flush_backend` 布尔量隐式混合。若保留 `flush_backend` 作为 ABI 观察字段，则必须严格由
`backend_action != NONE` 派生。

后端局部接口进一步区分：

```text
head0_control_event_pregrant
  = head0_full_flush_pregrant || exact_pending_csr_commit_pregrant

head0_full_flush_pregrant
  = head0_commit_pregrant && (head_exception || queue_head_csr_without_pending_owner)
```

`head0_commit_pregrant` 使用独立的 `commit_pregrant_ready`：LQ 只允许 registered
`completed_q` 进入该许可，不能把 current formal-WB completion bypass 接回 C0
completion cut。实际 commit 路径仍使用普通 `commit_ready`，保留既有 leaf 行为。

只有 `head0_full_flush_pregrant` 建立 C0 full barrier、strict-younger completion cut 和
C1 sequencer request；两类 pregrant 都关闭新 dispatch 并压住同拍更年轻 branch。

full C0 completion cut 必须覆盖当前全部 8 类 completion query。定向验证至少构造
`head=15/younger=0` 的 ROB 环绕布局，让同一个真实 head exception pregrant 同拍切断
8 类严格年轻 completion，并证明 pregrant 前这些 query 均非空。

双 memory lane 的 AXI 保持验证必须先让两个 child bridge 都进入 registered
`S_READ_ADDR`，再保持多拍 full barrier；两份 lane-local AR VALID/payload 和共享 arbiter
owner 必须保持到各自 address/response terminal，两个精确 owner token 各交付一次。

## 声明边界

本切片关闭目标是 `CONTROL-EVENT-G1` 的字段同源、无组合环赢家投影、阶段语义和生产 RTL
消费点，不外推为 `SERIALIZE-G1`、完整架构冻结或 PPA promotion。全核 blocker 与 PPA
资格仍由 canonical hard gate 独立裁决。
