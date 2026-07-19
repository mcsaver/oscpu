# R4-S0 OpenSTA fail-closed 证据契约

## 证据代际

- `fresh-synth-run1/opensta-exact5ns/` 是 **INVALID_FAIL_OPEN_PREVIEW**：旧 runner 把 synthesis audit
  的 SHA 同时冒充 synthesis binding 与 setup-member manifest，并把 `combinational_loops` 直接写死为
  `0`。该目录只能用于定位历史关键路径，不能进入 baseline、候选晋级或 200MHz gate。
- `fresh-synth-{run1,run2}/opensta-exact5ns-v2/` 才是当前 runner 的唯一可验输出。runner 拒绝覆盖
  已存在的 v2 目录，也不读取或修改旧 preview。

## v2 闭合条件

1. synthesis audit 必须是 `t4q-synthesis-audit-v1`、唯一 `NpcTop` top-stat、`module_count=119`，
   且网表字节数/SHA、八项 freeze PASS、综合 exit=0 与现场输入一致；pre/post binding 必须完全相同。
2. 主 STA 前后各跑一次独立 setup probe；probe 字节与派生的三类精确成员集合必须一致。主 STA
   `check_setup -verbose` 只能依次出现 input-delay、output-delay、unconstrained-endpoint 三类，拒绝
   第四类 warning、loop warning 与任何 trailing diagnostic。
3. 主 STA 输入、参数和 OpenSTA 版本必须 pre/post 不变；completion marker 必须逐项绑定网表、liberty、
   OpenSTA、synthesis audit/freeze/exit/binding、setup manifest 与输入 manifest。
4. top report 必须恰好 40 个 path block，每块恰好一个 Startpoint/Endpoint/Path Group/Path Type 和一个
   九位小数 slack；slack 符号、MET/VIOLATED、唯一 WNS/TNS 与 violation 数必须一致，拒绝 negative zero。
5. console 不得含 Warning/Error、unknown-module blackbox 或 combinational-loop diagnostic。

`target_200mhz_met` 只要求 exact 5ns 的上述 timing gate 闭合；`reserve_met` 独立要求最差路径
slack `>= +0.10ns`。二者不得混写。OpenSTA vectorless power 仅保留为 diagnostic，`power_qualified=false`。
