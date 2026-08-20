# BPU banked-child PPA Pareto architecture decision v1

RV64 RTL 结论｜对象=`OooBranchDirectionPredictor→OooBranchLocalPht→16×OooBranchLocalPhtBank` 与 sealed b279/d3f3 5 ns receipts｜周期/配置=双路 0-cycle lookup、update S1→S2、`mapped-5ns-bpu-local-pht-banked-child-inline-v1`｜TB/EDA 观测=b279 runner/evidence PASS，WNS=-11.550187111 ns、TNS=-308193.40625 ns、logic area=2468670.96，但预冻结面积门失败｜范围=GAP

## 裁决

- b279 的 frozen experiment verdict 保持 `ROLLBACK/GAP`；不得改写成 RETAIN/PASS。
- b279 作为 noncanonical engineering frontier/negative-knowledge archive 保留，`front_accepted=false`、`canonical=false`、`champion=false`。
- 唯一下一动作是实现一次 `write-banked/read-flat-view` 面积变体。
- 该变体任一冻结门失败即停止 BPU 探索并转向 FP；不再进行 bank-count、OOC 或第二面积变体 sweep。

## Architecture IR

```text
OooFrontend fetch PC/static
  -> OooBranchDirectionPredictor
       state owner:
         ghr_q
         bht_valid_q / bht_q[1024]
         local_hist_valid_q / local_hist_q[256]
         parent BHT/local-history S1/S2
       read:
         gshare + local-history index + hybrid select
       -> OooBranchLocalPht                 # wrapper，无 architected state
            bank=index[11:8]=PC[4:1]
            row =index[7:0]=local_history
            -> 16 × OooBranchLocalPhtBank
                 state owner:
                   valid_q[256]
                   counter_q[256][1:0]
                   upd_valid_q/upd_row_q/upd_taken_q/upd_old_ctr_q
                 read:
                   lane0、lane1 各一条 256-row 组合 view
                 update:
                   selected-bank S1 capture -> 下一沿 S2 saturating write

issue-resolve
  -> OooBranchBpuUpdateGate
  -> parent BHT/local-history S1/S2
  -> child one-hot bank S1/S2

mispredict
  -> redirect / ROB squash
  -> resolved actual outcome 仍训练；predictor 不 checkpoint/restore
```

## 三配置 Pareto 事实

| 配置 | WNS / TNS (ns) | 全核 logic / sequential area | known cells / relative power | BPU stdcell | Top40 | 状态 |
|---|---:|---:|---:|---:|---|---|
| d3f3 four-placeholder | -11.550187111 / -287464.78125 | 2181777.92 / 570206.56 | 929250 / 0.136 W | area/timing hidden | 40/40 CSR→memory-owner/control | boundary anchor，GAP |
| d3f3 whole-BPU-inline | -50.241458893 / -719693.1875 | 2465601.32 / 679275.52 | 1016851 / 0.162 W | 87601 cells；283823.40 area；109068.96 seq | 40/40 `update_taken_i→local_pht_q[*]` | diagnostic，GAP |
| b279 16-bank child | -11.550187111 / -308193.40625 | 2468670.96 / 680439.76 | 996124 / 0.160 W | 66874 cells；286893.04 area；110233.20 seq | 40/40 CSR→memory-owner/control；无 BPU Top40 | frozen ROLLBACK/GAP；noncanonical archive |

b279 相对 whole-inline：WNS `+38.691271782 ns`、TNS `+411499.78125 ns`、logic area `+3069.64`、sequential area `+1164.24`、known cells `-20727`、relative power `-0.002 W`、BPU `MUX4 +9136`。

b279 相对 four-placeholder：WNS 相同、TNS `-20728.625 ns`、inline BPU stdcell area `286893.04`、relative power `+0.024 W`。placeholder 隐藏 BPU 内部 arcs/area，不能凭相同 WNS 支配 b279。

三个点均未满足 5 ns timing hard gate，power 均未资格化，且 placeholder 缺真实 BPU area/timing，因此正式 Pareto front 仍为空。whole-inline 与 b279 仅形成 noncanonical engineering trade-off。

## 结构因果与反例

whole-inline 的 40/40 Top40 从 `update_taken_i` DFF/Q 经公共 `counter_train()`/variable write 到不同 `local_pht_q[*]` D。b279 将该写锥收窄到 16 个 bank-local S1/S2，旧路径族退出 Top40，WNS回到非 BPU 路径，支持“公共 local-PHT write cone 是原 Top40 主瓶颈”。这只证明 Top40 排名迁移，不证明 Top40 以下不存在等价 bank/read/write 路径。

| BPU | DFF | ICG | MUX4 | cells |
|---|---:|---:|---:|---:|
| d3f3 whole-inline | 17706 | 5377 | 5460 | 87601 |
| b279 banked | 17895 | 5393 | 14596 | 66874 |
| delta | +189 | +16 | +9136 | -20727 |

`+189 DFF × 6.16 = +1164.24` 精确解释 sequential-area 增量。16 banks 各有 639 MUX4，最可能来自每 bank 独立实现 lane0/lane1 row-select 与 `update_old_ctr` 选择，再由 wrapper 选择 bank；但 netlist 已删除，缺 cone-level attribution，`share=0`、hierarchy 与 library mapping 亦可能参与，故这不是唯一已证 root cause。

## 唯一面积变体

建议配置身份：

`mapped-5ns-bpu-local-pht-write-banked-flat-read-view-inline-v1`

结构边界：

- `OooBranchDirectionPredictor`、预测周期、容量、索引与 hybrid selector 不变。
- `OooBranchLocalPhtBank` 继续独占 `valid_q/counter_q` 及 bank-local update S1/S2；one-hot bank update decode 不变。
- 删除每 bank 的 lane-specific `lookup0_row_i/lookup1_row_i` variable-read selector；新增只读 `valid_view_o[255:0]`、`counter_view_o[511:0]`。
- `OooBranchLocalPht` 拼接 16 份 read-only view，对完整 12-bit `lookup0_idx_i/lookup1_idx_i` 各做一次全局组合选择。
- `update_old_ctr` 保持在选中 bank 内；不得新增公共 `trained_counter` 或 flat 4096-entry variable write。

禁止恢复的物理不变量：

- `update_taken_i` 最多负载 16 个 bank-local `upd_taken_q` S1。
- `counter_train` 和 S2 write data 保持 bank-local。
- 不允许公共 `update_taken_q/trained_counter` 重新驱动 4096-entry D cone。
- read-only flat view 只能从 state Q 端出发，不得成为 write owner。

Focused gate：

- `tb_ooo_branch_local_pht` 保持同/异 bank、同/异 row 双路 0-cycle、S1/S2、read-before-write、RAW no-forward、饱和与 clear pending-S2 全部 PASS。
- `tb_ooo_branch_direction_predictor` 保持 mispredict train/no-restore。
- `run_ooo_branch_local_pht_mutations.py` 现有 11/11 compile-success mutations 精确动态拒绝。

一次同源 5 ns PPA 的单一 RETAIN 门：

```text
focused TB/mutation 全绿
AND 16-bank state/update hierarchy 与内部 arcs 可见
AND full BPU violating/high-fanout inventory 无公共 update_taken→4096-entry write族
AND WNS > -50.241458893 ns
AND TNS > -719693.1875 ns
AND full-chip logic area < 2465601.32
AND inline BPU stdcell area < 283823.40
AND BPU MUX4 < 14596
```

Power 仅记录 relative diagnostic，不作资格门。任一条件失败即回滚该变体并转向 FP。全部通过也只能替换 noncanonical engineering archive，仍保持 `canonical=false/GAP`，随后冻结 BPU 并转 FP。

## Registry 单一入口状态

```yaml
node_id: bpu-local-pht-banked-child-b279
source_design_id: sha256:b279d4bc209013144ea4075aa7102119a28ee2b77f797a98717401bc9272697e
product_role: product_core
source_lifecycle: development
mapped_execution_receipt: PASS
frozen_experiment_verdict: ROLLBACK
physical_status: GAP
archive_class: engineering_proxy_archive
archive_status: RETAIN_NONCANONICAL
front_accepted: false
canonical: false
champion: false
canonical_production_status: BLOCKED_UNCHANGED
next_action: FIX_WRITE_BANKED_FLAT_READ_VIEW_V1
stop_condition: one_variant_misses_any_frozen_gate_then_stop_bpu_to_fp
```

`mapped_execution_receipt=PASS` 只表示 command/identity/parser/binding/cleanup 完整，不是 PPA PASS。原始 marker：

`[TRACEABLE-MAPPED-CURRENT][PASS] run=2026-08-10-rv64-bpu-local-pht-banked-child-ppa-b279-a1 evidence=traceable-b279-bpu-local-pht-banked-child-a1`

## 边界

- Counterexamples：logic/seq area回退3069.64/1164.24；TNS比placeholder差20728.625；40条timing violation仍存在；power未资格化。
- Unknowns：Top40以下完整BPU path、高扇出清单、MUX4逐cone归属、CTS/routing/multicorner、macro-inclusive area、真实activity power。
- Alternative hypotheses：Top40迁移可能部分来自hierarchy/排名；面积回退可能由read mux、S1复制或mapping约束共同造成。
- Scope extension：当前只读裁决无需扩展。实现需新版本合同授权 RTL/TB/mutation/registry 与一次新design-id PPA，并采集完整BPU violating/high-fanout inventory。
- Confidence：sealed数值、身份、cell census、frozen ROLLBACK为高；旧Top40主瓶颈因果为中高；MUX4归因与flat-read收益为中；power因果与正式Pareto资格为低/无。

合同 JSON SHA-256：`de19426e7e44657b646e3a034bff2f7e9fa55920d94dd6f5d49830805988c803`。本节点只读，未运行仿真、综合、STA、parser或test。
