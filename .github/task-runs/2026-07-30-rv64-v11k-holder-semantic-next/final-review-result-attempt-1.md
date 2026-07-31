# V11K 独立终审 attempt 1

## 结论

`OooMemInflightQueue` 功能队列更新方程未发现反例，两态 Yosys
elaboration 恒等成立；但 `miq-owner-tokens` 暂不能局部关闭，终审结论为
GAP。

合同：
`.github/task-runs/2026-07-30-rv64-v11k-holder-semantic-next/subagent-contracts/v11k-miq-holder-semantic-final-review.json`

合同 SHA-256：
`559c2a312b6f17cf09979a837505a9f120fd492f5eb7bc7b9d919023c5c89c06`

## Blocker 1：push/pop tuple 断言没有独立敏感性证据

- 新增 marker 共四条：
  `[V11K-MIQ-PUSH-TUPLE-KNOWN]`、
  `[V11K-MIQ-POP-TUPLE-KNOWN]`、
  `[V11K-MIQ-OWNER-TUPLE-KNOWN]`、
  `[V11K-MIQ-OWNER-TUPLE-STABLE]`。
- attempt-2 中 push/pop 两个 marker 在全部 26 个 profile 中均为 0。
- 六个 X/Z capture 变体改变驻留 `owner_*_q[tail_q]`，只证明
  `[V11K-MIQ-OWNER-TUPLE-KNOWN]` 会响应，没有直接向 accepted push 或
  valid-head response port 注入 X/Z。
- 需要增加 push 与 pop 端口的 X/Z 定向 profile；assertion 配置必须命中
  对应 marker，release 配置必须由独立 oracle fail-closed。pop 负向还要
  证明 head/count/occupancy 不变。

## Blocker 2：普通回归缺少执行输入哈希绑定

- `tb_ooo_int_backend.sv` 当前 SHA-256 为
  `be96c5f29472a1c2dd92c67f88ac50bdf37e4bdcb6f23362967e0f3ff55d3cec`，
  但 attempt-2 没有为普通回归记录 compile-source manifest。
- regression record 只有日志路径/哈希，没有保存编译时 source-set、
  `.vvp` 产物哈希与 post-hash。
- 需要让三个普通回归各自保存完整 compile source manifest、编译产物
  哈希和 source post-hash，并由 semantic checker fail-closed 校验。

## 已确认范围

- 12 个原负向变体在 assertion/release 中均 compile rc=0，24 次仿真均
  被预期机制拒绝。
- 两个 baseline 与三个普通回归日志均显示 PASS。
- current instance graph 精确包含两个 MIQ 产品路径。
- V11J/V11K 完整 Yosys JSON 均为 130 modules、176087 cells，canonical
  logic SHA-256 均为
  `c49ad65d6aad707f525fe37fabaa2c7187ade0c1c5880ad22b05e5d164d15e5b`。
- 当前证据支持“V11K assertion-only 增量不新增系统重跑触发”，但不替代
  其它轮次尚缺的系统重跑。
- architecture 保持 RED，PPA 保持 UNPROMOTED。

`scope_extension_request`：补齐上述 profile 与回归 binding，重建
semantic ledger 后使用 versioned 合同复审。

WSL single-flight ownership 已归还。
