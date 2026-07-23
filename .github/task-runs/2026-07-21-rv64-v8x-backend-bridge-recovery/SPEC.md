# V8X：backend + dual-memory bridge 选择性恢复联合轨迹

## 1. 本地工程作用域

工作对象仅为本地 RV64 Verilog/SystemVerilog 处理器工程。操作范围限于本仓库的
RTL、testbench、Icarus 仿真、证据脚本和生成产物；不涉及网络、远程主机、账号、
凭据、第三方服务或未授权系统。本文的 `kill`、`recovery`、`flush`、`mutation`
分别专指流水线事务失效、分支错误预测恢复、RTL 全局清空信号和 compile-success
RTL 验证变异。

## 2. 要关闭的证据缺口

V8W 已分别证明 bridge active/station 恢复和 backend MIQ exact-drop/pop，但尚缺同一
真实动态仿真中的跨模块事件链：

```text
MIQ bank0 [A, B]
bridge0 active=A, station=B
branch mispredict marks A/B effective-killed
AXI R(A) -> bridge drop(A) -> MIQ pop(A)
station promote(B) -> bridge drop(B) -> MIQ pop(B)
exact terminal count=2, target/WB/commit=0
collector/tracker/MIQ/bridge final state=empty/idle
```

## 3. 接口合同冻结

| 接口面 | producer | consumer | 稳定语义 | 禁止替代 |
| --- | --- | --- | --- | --- |
| request | `OooIntBackend` bank0/1 MIQ launch | wrapper lane0/1 station | `valid/ready` fire 后完整 `{kind,token,epoch,tval}` 进入对应 bridge station | testbench 伪造 ready 或 response |
| active expected | backend MIQ head | bridge active owner check | 当前 head 的 exact tuple、tval 与 `effective_killed` | 仅 token 或 raw kill bit |
| tracker expected | backend owner tracker query | bridge active sticky check | exact `{kind,token,epoch}` live lease | bridge 自推 owner |
| station expected | backend MIQ next-head query | bridge station advance | exact next-head `{kind,token,epoch}` | active head 重用为 station truth |
| SQ order query | bridge final-PA LOAD query | backend shared SQ/LQ ordering | allow/forward/replay 由 exact MIQ owner 和 final PA 决定 | testbench 强制 allow |
| terminal | bridge `drop0/drop1` | backend MIQ pop + terminal collector | only exact killed owner may pop; raw drop still enters tagged collector | response/WB 伪装 terminal |
| AXI | wrapper shared arbiter | local AXI memory model | A 的 AR fire 一次；恢复后只 drain A 的迟到 R；B 不得产生第二个 AR | 全局 flush 或撤回已展示 AR |

## 4. 测试构造

1. 在既有 backend testbench 的 `V8X_BACKEND_BRIDGE_RECOVERY_FOCUSED` 配置中接入
   真实 `OooDualMemBridgeWrapper`，不改默认 leaf-test 模型。
2. 建立一个已解析且尚未退休的 older branch，随后顺序派发同 bank 的普通 LOAD A、B。
3. 等待 `MIQ count=2`、bridge0 `active=A/station=B`，并只接受 A 的一个 AXI AR。
4. 对真实 backend branch-resolve 边界产生一个单拍错误预测恢复事件；检查两项 MIQ
   owner 均已按年龄规则变为 killed，而 wrapper `flush_i` 保持 0。
5. 返回 A 的迟到 AXI R；逐拍检查 `drop(A)->pop(A)->promote(B)->drop(B)->pop(B)`。
6. 检查两个 terminal 的完整身份、严格顺序、无 memory WB、无 A/B commit、无第二个
   downstream AR，最终 MIQ/collector/tracker/ROB/bridge 均空闲。

## 5. 非真空与反例

- 正例必须在 `OOO_ASSERT` 下通过并打印唯一 marker：
  `[V8X-BACKEND-BRIDGE-RECOVERY] ... PASS`。
- 至少一个 compile-success RTL mutation 必须切断联合轨迹中的承重边，并被该 focused
  test 拒绝。首选变异为阻止 station B 在 active A 终止后晋升；它应编译成功，但缺失
  B 的 exact drop/pop/terminal 或最终 idle。
- 相邻 V8W backend/bridge/wrapper/integration 回归必须继续通过。

## 6. 裁决边界

- 本切片只可关闭 V8W v3 指出的“真实 backend+bridge active/station 双 owner 联合轨迹”
  verification gap。
- 若未发现生产 RTL bug，禁止为了产生 diff 修改生产 RTL。
- 即使本切片 GREEN，OOO-4、DI-5、OOO-3、overall architecture 仍按各自未关闭门保持
  RED；PPA 为 `UNQUALIFIED`，`promotion_eligible=false`。

