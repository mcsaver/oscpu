# V14C P0 current-design attribution review v3

RV64 RTL 结论｜对象=`p0-final-2/receipt.json`、`counterexample-inventory-1/inventory.json`、`section13-current-3/section13-current-audit.json`｜周期/配置=current design-id=`sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`｜TB/EDA 观测=九门 9/9 CURRENT_DYNAMIC_PASS；121=118 RTL mutation+3 oracle；114 个唯一变体、4 组别名｜范围=PASS（APPROVED_CURRENT_SCOPE）

## 逐门归属

| P0 gate | 负向观测 | 构成 | summary SHA-256 |
| --- | ---: | --- | --- |
| FDG-G1 | 7 | 6 mutation + 1 oracle | `b2dcdab30d8f00d47f3c13f80a9a6c8b384fddffdf620cb4d217114bccda87f2` |
| XRET-G1 | 10 | 8 mutation + 2 oracle | `54da59093e85f7d12f562c26fe87def5b7b5ccea527344cbbf9641a992f0ce66` |
| MEM-ISSUE-G1 | 8 | 8 mutation | `46666a2e14a05f9e47ea3834759871b107e852255b9d801a07b67b0b5f79bd5b` |
| PTW-PMP-G1 | 28 | 28 mutation | `5faa7a4d50a00133e6f6f90af60a40b63e8fa7c476b04be5ee5999cdef5edfdc` |
| IFU-ACCESS-G1 | 19 | 19 mutation | `1a0e040281671d0a89dc55b1dece47460a6582ed1ea63baeeab3cc891f08524e` |
| IFU-AXI-G1 | 18 | 18 mutation | `dff7e7c74df72eac715ac2bf015462a08353bc6ed51af24ba4463e6764726ae7` |
| IFU-FETCH-G2 | 16 | 16 mutation | `f82c99621a491d3b8e38eb2d8023167b33eb8af2fba5f7dae2516c08b9b26dd9` |
| IFU-TVAL-G1 | 12 | 12 mutation | `32197c0629f035d2bd7dcaa9b22f79621e6e5bd64d289705ecbc6ac8a469cbab` |
| INSTRET-G1 | 3 | 3 mutation | `36aa1868b2eeadbe90b421a7f8816fd5fa5d56f91c1aaeeeeab460b091d64453` |

- 所有 124 行 summary 均为 `compile_success=true`、`dynamic_rejected=true`、`marker_observed=true`、`source_unchanged=true`；P0 精确为 121 行，MIQ-FLUSH-G1 的 3 行位于 `adjacent_non_p0`、分类 P1、`counted_in_p0=false`。
- 118 次 P0 RTL mutation 减去 4 组跨 gate 同变体别名，得到 114 个唯一 `(source, variant_sha256)`：
  1. FDG `trap_ex_pc_corrupted` ↔ XRET `precise_trap_pc_offset`，`OooCsrTrapRequestMux.v`，`be9d7be421f9f8594f6d302f6d3f97b313c98d8847bef8b9ae7f1a81ff5c498d`。
  2. FDG `trap_ex_tval_forced_zero` ↔ XRET `precise_trap_tval_forced_zero`，同文件，`deec2e3c1b88db6a5296ad424314d1536c830a478127139d9d265e19ae1fe46d`。
  3. IFU-ACCESS `pair_ignores_slot1_visibility` ↔ IFU-TVAL `pair_ignores_predicted_taken_lane_visibility`，`OooFetchHeadPairGate.v`，`f9321a1850cec9ec195678651ae6620a575e133649c1db066df2e1396c53093c`。
  4. IFU-ACCESS `decoder_starts_lane1_at_fixed_halfword` ↔ IFU-FETCH `decoder_slot1_starts_at_fixed_halfword`，`OooFetchPacketDecode.v`，`3f752c9744417512dae0572cd8dff1187fa65ceab229c5fa662d9e5b4173a790`。
- 哈希链闭合：inventory=`f8ee837b…7278`，V14B direct=`e6a39a80…757e`，V14C dynamic=`f14d175a…70eb`，IFU replay-elimination=`b007d1c2…c1a`，final receipt=`fcdd3816…a2e5`；均与下游声明一致。合同 SHA-256 匹配 `1731a662…646`。
- IFU-AXI/FETCH 为当前动态执行：34/34 mutation、当前 positive module logs 5/5，`replay_dependency_for_delivery=false`。全局正向收据另闭合 shared module 113/113、V14C dynamic suite 18/18。
- warning 集合闭合为 2368 条 Icarus 诊断；只命中 `AxiCrossbar.v` 已声明行/数组，以及 `PmpChecker.v` 的 `entry_cfg_w`、`entry_addr_w` 和未选中 `entry_addr_w[-1]` generate 分支。负向 mutation 日志中的 `$fatal`/`[CHECK-FAIL]` 是定向检出变体的预期终止；正向审计字段为 `assertion_failure_observed=false`。
- 历史状态保持分层：`current-bind-1.status=PASS` 因 driver 返回码丢失被逻辑作废但未改写；`current-bind-checker-replay-1.status=FAIL` 与 `p0-replay-elimination-1.status=FAIL ... evidence_complete=0` 保留；错误归属的 `p0-final-1.status=PASS` 原样保留并由 final-2 明确 supersede。
- Section13 保持 `architecture_gate_state=RED`、`arch_stable=false`、`ppa_state=BLOCKED_BY_ARCHITECTURE`、`promotion_eligible=false`。

## 反例、未知项与边界

- `p0-final-1.status=PASS` 证明不能仅凭状态字符串接受债务闭合；它把 3 条 MIQ-FLUSH-G1 P1 观测计入 P0，并混淆命名观测数与唯一 RTL 变体数。
- 4 组别名不是少执行 4 次；同一文本 RTL 变体分别接受不同 gate/testbench 契约观测，因此保留 118 次执行、按指纹去重为 114。
- `entry_addr_w[-1]` 目前按 Icarus 未选中 generate 分支解释；其他仿真器或综合器是否给出相同语义未在本节点验证，PPA 保持 BLOCKED。
- 本合同未授权逐行读取 IFU 5 个正向原始 module log 和全部生产 RTL；结论依赖其哈希绑定的 checker receipt，而非重新执行仿真。
- 未执行综合、STA、Power 或跨仿真器复核；这些不属于 `APPROVED_CURRENT_SCOPE`。

`scope_extension_request`：当前收据范围无阻断请求。若要求脱离 checker receipt、逐行独立复核 IFU 正向日志，应新增授权 `p0-replay-elimination-1/results` 与 V14B `module-aggregate/logs`，继续使用只读 `rg/sha256sum`。

`confidence_and_basis`：高。依据合同哈希、五个关键收据及九个 summary 的实算 SHA-256、逐项 schema 真值、明确别名指纹、实际 status 文件和 Section13 fail-closed 字段；置信范围仅覆盖当前 design-id 的九门 P0 task-local current-dynamic 收据，不扩展到 architecture freeze 或 PPA promotion。
