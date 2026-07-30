# V11D 独立终审

## 结论

`APPROVE`，严格限于 `tracker-next-token-cursor`；blocker=0。

终审合同 SHA-256：
`e783df2547e64f7674300370658b51819888e120a2ef1ee8c5d79e7e4afab001`。

## 已核证据

- production tracker SHA-256：
  `fd7e0a1bcdd1fd12f35b07bb655db67a512c9a30c3ca0aae6bd5a41903f889c8`；
- design-id：
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`；
- 146-file RTL pre/post、12-file focused manifest pre/post 与当前文件逐项一致；
- canonical summary SHA-256：
  `21a209961c55f4036af32c716701ed52803caf2dd61889a9dfe662c1105d3a50`；
- 4/32-token、assert/release baseline 4/4 PASS；
- 9 个 32-token、`OOO_ASSERT` 关闭配置的 compile-success RTL
  variants 均只含声明的单项变化，且 9/9 被定向拒绝；
- expected token/ready/fire/live/PID/cursor 只由 stimulus 与沿前 model
  状态推导，DUT token 与 `dut.next_token_q` 不反喂 expected model；
- attempt-2 把 token 比较限定到对应 valid；两个 lane1 变体的首个拒绝点
  均不再依赖 invalid-lane token 输出；
- ledger 相对 V11C 唯一晋级 cursor：5 PASS / 39 GAP 变为
  6 PASS / 38 GAP。

## 范围与措辞边界

`check_registered_state` 会直接比较 `dut.next_token_q` 并在不一致时
`$fatal`，因此它是第二个 oracle，不是“仅作补充诊断”。这不形成循环自证，
但不得宣称 9 个变体都由纯黑盒 token 序列首先检出。

`lane1-does-not-exclude-lane0` 在 attempt-2 的首个失败周期为
`valid=1, ready=0`，符合当前 valid-qualified token 合同。如果接口合同未来
改成仅在 fire 时定义 token，需要新增 fire-qualified profile。

ARCH_STABLE 当前观测为 51/53，且两项失败在 V11C 已存在；V11D 没有新增
失败。终审时 V11D 目录尚未保存本轮原始 unittest 日志；终审后已用
`run-arch-stable-observation.sh` 重放并保存
`evidence/arch-stable-unittest.log`，精确核对 53 项、两项既有失败及
`v11d_new_failures=0`。该日志只把 51/53 变为可审计 GAP，仍不构成
ARCH_STABLE PASS。

其余 38 个 holder、global no-live-reuse、whole-core/system、综合、STA、
功耗与 PPA 均保持 GAP。
