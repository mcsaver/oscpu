# V13F OooIntIssueQueue 局部 PPA 基线

## 结论

冻结源码的 200 MHz 局部映射与 5 ns ideal-clock STA 均完成，结构检查为净。当前 top40 统一指向
`valid_q[0] -> packed-age pop/compaction control -> entry0 wide payload D`，因此下一刀不改 selector
真值表，也不改 payload 所有权；只评估 onehot pop mask 能否缩短 compaction owner 回译。

## 证据

- 源码身份：`evidence/source/source-hashes.sha256`
- coarse：`evidence/ppa/local-baseline/coarse-synth-stat.txt`、`coarse-synth-check.txt`
- mapped：`evidence/ppa/local-baseline/mapped-synth-stat.txt`、`mapped-synth-check.txt`
- STA：`evidence/ppa/local-baseline/opensta-config.tcl`、`opensta-check-setup.txt`、
  `opensta-top40.rpt`、`opensta-console.log`

数值：coarse `4,430 cells / 1,614 $mux / 1,481 $pmux`；mapped
`34,468 cells / 75,205.48 area`；最差 slack `+2.233862638 ns`，top40 均为 entry0 payload D。

## 边界

这是模块级相对诊断，不证明 parent/full-core 200 MHz，也不包含功能回归；本阶段未改 RTL，故不把
未运行的功能、集成、power 或 system 项标为 PASS。
