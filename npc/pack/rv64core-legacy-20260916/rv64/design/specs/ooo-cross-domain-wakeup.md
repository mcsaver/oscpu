# 规范：FP completion → integer IQ 的跨域 sticky wakeup

> 模块：`OooFpBackend`、`OooIntBackend`、`OooIntIssueQueue`。
> 状态：**T3D 已实现；T3H 已扩展为 wake0/1 全 sticky（2026-07-13）**。

## 1. 根因与切点

T3C 切断 FP admission ready/fire 环后，full Verilator 仍暴露历史 SCC 的另一真实分支：

```text
FP completion valid/pdest
 -> integer IQ FP-store source same-cycle wake/select
 -> integer branch issue/redirect/kill
 -> FP arithmetic completion kill mask
 -> FP completion valid/pdest
```

FP store 数据源只要求最终可发射，不要求 producer 完成同拍发射。T3D 先删除
`fp_wake0(execution completion) -> integer IQ resident select` 的同拍前视；T3G fresh STA
随后证明 `fp_wake1(FP load WB)` 快路形成 DCache→IntIQ→ALU/control→FetchPacketCache 的
top1。T3H 因此把 wake0/1 都收紧为上升沿写 sticky ready、N+1 才 select，并同步删除
FP PRF R3 的同拍 write-through。

## 2. 六类接口合同

- **握手**：不新增端口/ready；`fp_wake0/1` 仍是单拍 execution-completion/load-WB 广播。
- **stall/backpressure**：N 拍 wake0/1 都不允许让 FP-store entry 同拍 select；N 沿吸收，
  N+1 可 select。本文落地时曾独立保留整数 EX-only fast select；T3M 已删除，当前所有整数
  completion 同样 N 沿 sticky、N+1 select，见 `ooo-ex-sticky-wakeup-barrier.md`。
- **flush/kill/redirect**：kill 拍仍压 issue；存活前缀必须吸收同拍 FP wake，年轻后缀 squash。
- **异常序**：FP completion/fflags/ROB done owner 不动；只给 FP-store consumer 增加一拍。
- **访存序**：FP store 的 SQ/MIQ/request owner 不变，延迟发生在进入 memory issue 前。
- **恢复/单真源**：`fp_st_ready_q` 是跨域可发射状态唯一真源；不得复制 wake FIFO 或注册 kill。

## 3. 周期与验证

| 周期 | fp_wake0/1 | FP-store select | sticky state |
| --- | --- | --- | --- |
| N | pulse | 不因该 pulse 发射 | N 沿置 ready |
| N+1 | 0 | 可发射 | 保持 ready |

- 旧 RTL RED：resident FP-store 在 N 拍被错误提前 select。
- GREEN：wake0/1 均为 N 不 issue、N+1 issue；dispatch insertion 在 IQ 内显式 OR 两路
  wake，compaction/kill survivor 均不漏 wake。
- full Verilator `--assert` build 不得再报告上述 cross-domain SCC。
- fresh OpenSTA 中 `fp_wake -> IntIssueQueue select -> branch kill -> FpArith` loop family 必须为0。

T3D 实施时未延迟 fp_wake1 或 FpIssueQueue 的整数/FP self wakeup。后续 T3E fresh
网表先给出 integer full-WB→FpIssueQueue→FpConvert 反例，integer→FP 方向由
`ooo-int-to-fp-sticky-wakeup.md` 接管；T3G 又给出 FP-load wake1 的 DCache 首路径。
T3H 最终由 `ooo-fp-sticky-wakeup-barrier.md` 统一接管 wake0/1 的 FP self 与 FP-store
消费边界。
