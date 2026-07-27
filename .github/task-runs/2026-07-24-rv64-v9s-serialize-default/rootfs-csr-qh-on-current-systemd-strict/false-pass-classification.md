# V9S strict systemd run false-PASS classification

## 结论

- classification: `runner_status_false_green`
- rootfs system gate: `FAIL`
- RTL promotion eligibility: `false`
- 默认配置切换资格: `false`

本次结果没有完成 strict guest check 和自然关机。原始状态文件曾为 `PASS`，但该文本与
`driver.log`、`guest/console.log` 和存活进程证据冲突，已 fail-closed 更正为：

```text
FAIL rc=1 stage=systemd-strict-guest evidence_complete=0 cleanup_rc=0 observed_child_signal=HUP
```

原始五字节状态保存在 `status.before-fail-closed-correction.txt`。

## 绑定与运行观测

- RTL design id:
  `sha256:c358ce6d3ef0fe1cb4cd8337bd4dd4f35c44d713b54d047c2ea9a51d38c07e8d`
- simulator SHA-256:
  `ddde549a08c8f912d48a90bb74a742f33a5d2d07d828eaacd7c2bab2127b541f`
- rootfs SHA-256:
  `d4cda519bef51088b320c3a50486f24c678313eadce0b3905a9c439d91d71b06`
- config:
  `OOO_CSR_QUEUE_HEAD=1`,
  `OOO_TERMINAL_HOLDER_ASSERT=1`,
  `NPC_SYSTEMD_GUEST_COMMAND_MODE=systemd-strict`,
  `uart_rx_bytes=0`
- 最后退休 checkpoint:
  `320000000 insts`, `pc=0x0000003f8eeca18a`
- `driver.log:440-441`:
  子 `make` 与外层 `make` 均以 `Hangup` 结束。
- 原 runner 与 simulator PID 已不存在。

## 未满足的成功条件

`guest/console.log` 中没有实际出现以下运行期 marker：

- `__NPC_SYSTEMD_AUTOCHECK_DONE__ rc=0`
- `__NPC_SYSTEMD_UART_CHECK_DONE__ rc=0`
- `__NPC_SYSTEMD_POWEROFF_BEGIN__`
- `HIT GOOD TRAP`

`driver.log:96` 仅打印了 runner 配置中的预期 done-marker 字符串，不是 guest 已产生该 marker
的运行期证据。日志也没有
`[npc-systemd-check] PASS strict guest + natural poweroff (mode=systemd-strict)`。

## 原因

原脚本的 `EXIT` trap 只按 trap 入口的 `$?` 决定 `PASS/FAIL`。子系统回放被 `HUP`
终止后，脚本没有独立的“全部证据检查已执行到末端”状态，因而把未完成路径错误写成了
`PASS`。日志只能证明子 `make` 收到 `HUP`，不能从现有证据确定信号的宿主来源。

## 修复与反例

- `scripts/task-run-status.sh`：只有显式 evidence-complete、command rc=0、
  cleanup rc=0 且无 signal 时才写 `PASS`。
- 当前 v9s strict/full runner 记录 stage，并对 `HUP/INT/TERM` fail-closed。
- `scripts/tests/test-task-run-status.sh` 覆盖：
  正常完成、clean early-exit、命令失败、cleanup 失败、`HUP`。
- 重跑使用新的 result label 和 detached single-flight launcher，旧现场不覆盖。

## 内容哈希

- 原始 `PASS\n` status:
  `c26de83abdc9496cd1301470918ec39ecca1cf389ef0ae1c6504da1800d1c431`
- `driver.log`:
  `8b2869ba7ce1ebd8cf6c77e053c04d729545fb460618ac9011ce82fcc9cd9db3`
- `guest/console.log`:
  `664fa968b1f7acd96bf6f8359a0c4073fc16b5bbb105681c8a859146e9c9d26e`
- `binding.txt`:
  `c3f682b92264c224128f5a61063b8ec249af75968f044a43f8d1c935d3a31165`
- `config-restore.log`:
  `2fe15adf766b2f8913d2553e17d4b118b4098e926ddb2a4df03760ca274422a5`
