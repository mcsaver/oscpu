# V9N irrevocable-write owner residency

## 状态

`IN_PROGRESS`。长期 RV64 OoO/PPA goal 保持 active。

## RECALL

- DB brief 对四个 STORE/AMO owner 关键词组合均返回
  `no independent primary focus match`；直接按规范入口读取 ledger、stored memory、
  STORE/AMO spec 与 RTL/TB 驱动链。
- 当前稳定记忆指出：既有 post-launch owner-open 断言可能无法捕获 holder 在同一沿
  被清除、导致下一拍 guard 同时消失的情况。

## 当前假设

- SQ 生产逻辑通过 `request_sent` 强制进入 `survive_r`，并通过 terminal-gated
  `release_ready_o` 防止无 terminal release；功能路径看起来正确，但缺少独立下一拍
  驻留 checker 及针对该盲区的 current-source RTL variant。
- AMO singleton 在 `flush_i` 分支会清空；架构依赖不可撤回 write lease 阻止该输入组合。
  现有 same-edge assertion 只检查 edge-old owner-open，尚需独立下一拍 checker 证明该
  依赖不会静默失效。

## 声明边界

当前尚未给出 PASS；等待独立 reviewer 与可执行反例。
