# RV64 V13C A3 evidence audit

## 结论

本轮是 `verification`，没有修改 production RTL，也没有启动长系统仿真。

- A3 原始发布状态继续是 `FAIL`；DUT 已完成预期 systemd-strict/poweroff/system-reset
  终端事务，唯一失败来自旧 `dmesg-no-critical` 对 `printk: debug:` 的误判。
- V10F versioned checker replay 保持 PASS；本轮从冻结 A3 console、内嵌 checker 与绑定重新执行，
  得到同一语义结果。
- `c1b531→5f9dd068` 只批准为冻结 generated set 内的有界语义身份：normalized RTL 无差异，
  device-model object 无差异，仅 host `cpu-exec` 诊断观测 object 改变。
- A4 继续是 `FAIL rc=143 ... signal=TERM`，没有被重标，也不是 system PASS。
- 当前 production design-id 是 `29c0afe8…f483`。V13B `OooLoadQueue` 变化已精确传播到
  `NpcTop` coarse，因此 A3 不能绑定当前系统 promotion；当前设计另需 fast-gate rebind 和获授权的
  新 system attempt。

## A3 固定分类

| 字段 | 值 |
| --- | --- |
| `published_gate_state` | `FAIL` |
| `execution_state` | `COMPLETE` |
| `dut_terminal_state` | `COMPLETE` |
| `binding_state` | `NO_DRIFT` |
| `raw_artifact_state` | `VALID` |
| `rtl_assertion_state` | `CLEAN` |
| `oracle_state` | `INVALID` |
| `evidence_replayable` | `YES` |
| `full_system_rerun_required` | `NO` |
| `launch_authorization_state` | `NOT_REQUIRED` |
| `rerun_reason` | `NONE` |
| `next_action` | `VERSIONED_ORACLE_REPLAY` |

该表只覆盖 A3 历史 oracle correction；它不覆盖当前 `29c0afe8…f483` 的 system promotion。

## fresh 验证

- 冻结 A3 source input：9/9 SHA-256 一致。
- V10F canonical asset：9/9 SHA-256 一致。
- fresh replay：legacy matches=2、current matches=0、`printk_debug=ACCEPT`、
  `real_bug=REJECT`、terminal=6/6、cycles=5,071,521,696、commits=1,223,536,213，PASS。
- checker 单测：3/3 方法 PASS；覆盖 4 个 benign boundary fixture、9 个真实 critical fixture，
  并用恢复未定界 `BUG:` 的 source mutation 重现 A3 false red。
- fresh/canonical replay：移除输出位置字段后，其余语义字段字节级相同。
- V12C currentness checker 在当前 V13B design-id 上 fail-closed：queue-head、pending-system、
  functional 三类旧 summary 均报告 design ID drift；这些证据 disposition 为 `REBIND`。

## 实现者 / 审查者

- 实现者：A3 oracle correction 无需完整系统重跑；A3/A4 历史状态未修改，未使用终端事件去重，
  未削弱 RTL assertion。当前 production system promotion 单独保持 GAP。
- 独立审查者：A3 历史事务 `APPROVE`；`c1b531→5f9dd068` 冻结生成集语义身份
  `BOUNDED_APPROVE`；当前 `29c0afe8…f483` 系统绑定 `GAP`。审查合同与完整边界见
  `review-result.md`。

## 证据入口

- 结构化裁决：`a3-oracle-currentness-audit.json`
- 独立审查：`review-result.md`
- fresh bounded 日志：`evidence/`
- 历史 canonical replay：
  `.github/task-runs/2026-07-28-rv64-v10f-a3-checker-replay-v2/`
- A3/A4 原始状态：
  `.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/`

## 未闭合项与下一步

1. A3 历史 oracle 误判子项已闭合；不再重跑 A3，也不恢复 A4。
2. 当前 production system recert 仍未闭合。若将来要启动预计超过 4 小时的新 attempt，必须先刷新
   current fast gates、完成 prelaunch 独立复核并取得用户明确授权。
3. 在未申请长跑时，开发主线可继续处理当前 `OooLoadQueue` 的
   `release_q_ready`→entry-update 组合锥；它仍只能形成 development checkpoint，不能越级 promotion。
