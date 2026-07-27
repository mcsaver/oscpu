# V9W dispatch log

## v9w-serialize-full-drain-review-v1

- RTL 对象：默认 full-drain 配置下的
  `OooPendingSystemSequencer/OooStopPendingSequencer/
  OooPendingDrainResolveGate/OooRob/NpcCoreTop` serialized transaction。
- contract JSON：
  `.github/task-runs/2026-07-26-rv64-v9w-serialize-full-drain/subagent-contracts/v9w-serialize-full-drain-review-v1.json`。
- contract SHA-256：
  `5f5830c721b2530c45174ab25d118fa6022c56a31124e93124e289618cd4add0`。
- pipeline：canonical `create → validate → render` PASS；write paths 为空。
- reviewer：`/root/serialize_review`；只读静态复核后归还 WSL shell
  ownership。
- pre-implementation 结论：`GAP`。发现并行 type bits、普通 FENCE 的第二
  raw decode、SINVAL typed reason 漂移、recovery cross-product 与非 FENCE
  memory terminal 证据缺口。
- 主节点处理：本轮仅修复 canonical type、holder projection 与 typed
  redirect，并明确不关闭其它 GAP。

## v9w-serialize-full-drain-review-v2

- RTL 对象：
  `kind_q → holder projection → typed commit pulse → redirect reason`，
  以及 current-design 正负向证据。
- contract JSON：
  `.github/task-runs/2026-07-26-rv64-v9w-serialize-full-drain/subagent-contracts/v9w-serialize-full-drain-review-v2.json`。
- contract SHA-256：
  `b930dea8044b43ca30157daab98077e9305007fb7daf0dfd069ee7044e1a219d`。
- pipeline：canonical `create → validate → render` PASS；初始提示为未经改写的
  render 输出；write paths 为空。
- WSL single-flight：主节点显式交付唯一工程 shell；reviewer 只运行合同列明
  的 `rg`、`sed`、`git diff`、`git status`，未运行仿真/综合/STA，结束后
  明确归还。
- reviewer 局部结论：当前 design-id 上 canonical kind、CSR lease 与 typed
  redirect 为最小 `PASS`；14 个双 lane 类型案例、focused 2/2、layered
  6/6、module 111/111 与四个 compile-success RTL 变体相互一致。
- reviewer 总体结论：`SERIALIZE-G1=OPEN/GAP`。剩余 blocker 是 recovery
  cross-product、真实 memory-owner 终态，以及七类 terminal transaction
  exactly-once/无 ghost side effect 证据。
- status：`REVIEW_COMPLETE_LOCAL_PASS_GLOBAL_GAP`。
