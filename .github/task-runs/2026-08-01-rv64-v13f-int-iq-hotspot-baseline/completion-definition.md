# V13F completion definition — OooIntIssueQueue mapped hotspot baseline

- Parent design-id：`sha256:29c0afe820a5ce58a1299da1faaefabce6f9038156f628e9f0f3ff3b6e23f483`
- `OooIntIssueQueue.v`：`d8eb68b9…218b`
- `OooIntIssueSelect8.v`：`845d5dc4…4879`
- 状态：`PASS_DIAGNOSTIC_BASELINE`；已建立 current-source PPA 诊断基线并选择下一条单机制，未修改 RTL。

## 硬件对象

1. 8-entry packed-age IQ 的 resident `valid/src-ready/capability` 投影。
2. `OooIntIssueSelect8` 的 first-ready、second-ready、first-ready-ALU 三层前缀树与 capability swap。
3. onehot→index、issue0 PRF-address onehot tree、其余 payload dynamic mux、issue fire、双 pop compaction、
   wake/dispatch/kill survivor next-state。
4. 端口、N+1 sticky-wakeup、Universal reservation owner、memory pair、ROB-walk suffix kill 与 full
   ProducerId holder 合同全部冻结。

## 完成条件与停止条件

1. 用冻结两份 RTL 运行 `OooIntIssueQueue` 200 MHz、flatten=1、share=0 的 Yosys coarse/mapped，
   `synth_check` 必须 0 problems。
2. 对 mapped netlist运行 5 ns ideal-clock、zero-I/O OpenSTA，记录 top-40 的 startpoint、endpoint、
   path family、worst slack、TNS/WNS 与 mapped cell/area；该结果仅为模块级诊断。
3. 按 cell mix 与真实路径选择一个可证伪机制。不得仅凭源代码行数或 generic `$mux` 数修改 selector；
   不恢复 completion→select、dispatch bypass，不增加 pipeline stage，不削弱 assertion。
4. 本 baseline 不运行功能回归、整核综合、power 或 system；选中 RTL 候选后再按功能→local PPA→parent
   的信息增益顺序推进。
5. 提取 statistic/check/STA/config 与压缩 console 后删除精确 runtime netlist；task-run 只保留结果和
   少量日志。

## 已完成结果

- coarse：`4,530 wires / 68,764 wire bits / 4,430 cells`，其中 `$mux=1,614`、`$pmux=1,481`、
  `$sdffe=176`；`synth_check=0 problems`。
- mapped：`34,468 cells / 75,205.48 area / 19,293.12 sequential area`；
  `synth_check=0 problems`。
- OpenSTA：5 ns ideal clock 下最差 slack `+2.233862638 ns`，TNS/WNS 为 `0/0`；该值仅用于
  `OooIntIssueQueue` 局部相对筛选。
- top40 全部从 `valid_q[0]` 出发，落到 entry0 的宽 payload D：`imm=5`、`next_pc=12`、
  `pc=12`、`pred_npc=11`。代表路径经过 eligibility/dynamic steering、`issue1_fire_w` 与
  packed compaction 控制后进入 `imm_q[0]`，不是单纯的 issue payload 输出路径。
- 下一候选只替换 compaction 的 pop-owner 表示：直接用既有 `issue*_onehot_w & fire` 形成
  8-bit remove mask，删除 onehot→binary index→逐项比较的回译；`write_i`、packed-age、双 pop、
  dispatch append、wake/kill 与所有断言保持不变。候选必须由功能矩阵与同配置 mapped/STA 证伪。
