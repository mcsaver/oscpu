# V12C SERIALIZE-G1 当前设计独立审查

RV64 RTL 结论｜对象=`OooRob` queue-head CSR、`OooPendingSystemSequencer` pending-SYSTEM 与 `currentness-decision.json`｜周期/配置=C0/C1/C2，`OOO_CSR_QUEUE_HEAD=1`，design_id=`sha256:882111...`｜TB/EDA 观测=queue-head 2/2+2/2、pending-SYSTEM 3/3+14/14、functional 113/177/61；A3 绑定漂移｜范围=GAP

结论：确认快门禁 PASS，但它只闭合当前设计的局部 split-domain 事务证据；`SERIALIZE-G1` 必须维持 `STALE_EVIDENCE`，`serialize_g1_current_design_bound=false`、architecture freeze=`GAP`、PPA=`UNPROMOTED`。不得把 `currentness-decision.json` 顶层 `status=PASS` 或 checker 返回成功解释成债务 CLOSED。

## 已确认的 RTL/TB 证据

- queue-head CSR assert/release 均观察三类提交事务的 `C0_commit=1 C0_barrier=1 CsrFile_request=1 C1_apply=1 C2_quiet=1`，以及两类错误路径 CSR 的 `selective_kill=1 C0=0 C1=0`。
- 两个 C2 负向版本进入实际 Icarus argv/dependency，编译 rc=0，随后以 repeated/unowned marker 被 testbench 检出并以 `[RESULT] FAIL status=1` 结束。dependency 同时绑定 `OooRob.v` 与 `OooPendingSystemSequencer.v`。
- pending-SYSTEM 三个基线通过；14 个负向 RTL 版本均有实际变体 module dependency、compile rc=0 与 `.vvp` 收据，并被对应 MMU、redirect、FENCE、holder/stop、CSR ProducerId/PC、WFI、decode 或 fetch-cache 消费者拒绝。
- 功能队列绑定相同 `882111...` design-id：module 113/113、official 177/177、AM 61/61、DiffTest mismatch=0；这不是完整 Linux/systemd 重认证。
- queue-head 清理 19 项，pending-SYSTEM 清理 83 项；只读复核未发现残留 `generated/**`、`.vvp`、`.deps`、`.argv` 或 `.compile.rc`。
- A3 原始状态仍是 `FAIL rc=1 ...`；checker replay 保留 `strict=16/17 terminal=6/6 cycles=5071521696 commits=1223536213 PASS`。A3 design-id 为 `c1b531...`，ledger 仍绑定 `04c545...`，均不是当前 `882111...`。

## 假绿与覆盖洞

- `check_serialize_current_evidence.py` 主要信任 summary 中的编译输入/cleanup 布尔字段与计数，没有独立复核保留日志哈希、`artifact-cleanup.json` 和每个已删路径。当前快照经 reviewer 只读核验无误，但判定器应加固。
- queue-head 两个负向版本只覆盖 C2 replay/request，未覆盖 `OooRob` queue-head admission/selection 的编译成功 RTL 变体；不能据此宣称完整 queue-head 架构合同闭合。
- `current_design_system_transaction_present=false` 是当前候选的保守字段，不是全 task-run 搜索结论。
- reviewer 合同未授权 `python3`，因此本节点没有重新执行定向单测；结论基于保存的真实日志、JSON、hash 与物理清理状态。

置信度：维持 `STALE_EVIDENCE` 为高；快门禁证据快照为中高。若要转 CLOSED，必须提供当前 `882111...` 的完整 Verilator/Linux systemd status、binding、transaction/raw console/RTL assertion 证据，或提供 A3 到当前设计的完整 elaborated-RTL 等价证明。

所有合同内 WSL 只读命令均已结束，唯一 shell ownership 已归还主节点。
