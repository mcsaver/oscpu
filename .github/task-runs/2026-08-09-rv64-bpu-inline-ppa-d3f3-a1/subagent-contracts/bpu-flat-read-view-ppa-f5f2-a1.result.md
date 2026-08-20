# BPU flat-read-view f5f2 PPA A1

RV64 RTL 结论｜对象=`OooBranchDirectionPredictor→OooBranchLocalPht→16×OooBranchLocalPhtBank` / `2026-08-10-rv64-bpu-flat-read-view-ppa-f5f2-a1`｜周期/配置=5.0ns / `mapped-5ns-bpu-local-pht-write-banked-flat-read-view-inline-v1` / f5f2｜TB/EDA 观测=唯一 runner rc=1，synthesis rc0、OpenSTA fanout inventory rc1、evidence_complete=0｜范围=GAP

## 裁决

`ROLLBACK/GAP`。停止 BPU 探索并转向 FP；未修改输入，未重跑。

## 失败链

- status：`FAIL rc=1 stage=evidence-complete evidence_complete=0 cleanup_rc=0`
- command status：`preflight=0, manifest=0, synth=0, opensta=1, parser=1, trace=1, binding=2, cleanup=0`
- OpenSTA marker：`V15P_OPENSTA_STAGE_FAIL: BPU local-PHT update_taken_i source inventory is empty`
- `opensta-bpu-update-fanout.tsv` 未生成；wrapper source 查询结果为0，endpoint/max/forbidden endpoint均不可裁决。
- `opensta-complete.txt`、power、`summary.json`、traceability、after-manifest 均缺失；binding 因缺 summary 失败。
- cleanup 成功；`runtime_bytes_deleted=0` 不是正常 evidence cleanup PASS marker。

## 未获 parser/binding 的 raw 诊断

- synthesis source=129。
- placeholder：`Sram4096x199×1`、`Sram4096x113×2`、`OooFpArithGate×1`。
- 10项 keep hierarchy；1 predictor、1 child、16 banks；每 bank 2210 cells、9226.56 area。
- 全核：WNS `-11.550187111ns`、TNS `-308182.6875ns`、40 violations、0 loops、logic area `2467662.96`、sequential area `680439.76`、known cells `998410`、total cells `998414`。
- BPU：DFF `17895`、ICG `5393`、MUX4 `13352`、cells `69160`、area `285885.04`、sequential area `110233.20`。
- Top40：35条 CSR mtvec→`OooMemOwnerTerminalCollector`，5条→control-plane；BPU token=0。
- raw negative inventory：matched `318262`、numeric `276466`、negative `45574`、worst `-10.270211ns`，但未获 parser 绑定。
- relative power不可用，OpenSTA在 `report_power` 前失败。

## 精确 delta

| 基线 | WNS | TNS | logic/BPU area | known cells | BPU MUX4 |
|---|---:|---:|---:|---:|---:|
| b279 banked child | `0` | `+10.71875` | `-1008.00` | `+2286` | `-1244` |
| whole-inline | `+38.691271782` | `+411510.5` | `+2061.64` | `-18441` | `+7892` |
| four-placeholder | `0` | `-20717.90625` | `+285885.04` | `+69160` | N/A |

冻结门：focused功能、WNS、TNS、MUX4通过；full-chip area和inline BPU area均比严格上限高`2061.64`，失败；public update fanout、parser/binding、power与after-manifest缺失或失败。正式PPA亦失败：WNS未达`+0.10ns`、TNS非零、40 violations、无macro-inclusive area/qualified power。

底层 fanout collector 失败可能来自 flat STA export 消除 wrapper `update_taken_i` boundary pin，也可能是glob与mapped命名不兼容；不能唯一归因。Top40无BPU只能作弱诊断，不能证明公共4096-entry write cone消失。本轮 exactly-once 授权已消费，任何 collector 修订或新测量必须作为新任务，但BPU停止条件已触发，不再重测。

合同 JSON SHA-256：`86cf7bcffe82e7dcbca52f8873db52f90a95f41357f86257c772caa9441dfb40`。
