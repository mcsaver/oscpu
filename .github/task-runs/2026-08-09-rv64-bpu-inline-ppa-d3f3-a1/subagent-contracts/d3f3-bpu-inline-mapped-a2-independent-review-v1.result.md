# d3f3 BPU-inline mapped A2 independent review v1

RV64 RTL 结论｜对象=`NpcTop` / `OooBranchDirectionPredictor` / sealed `traceable-d3f3-bpu-inline-a2` evidence｜周期/配置=5.000 ns、d3f3、`mapped-5ns-bpu-inline-v1`｜TB/EDA 观测=raw status/summary/manifests/synth_stat/OpenSTA Top40/traceability/cleanup 只读复核一致｜范围=RETAIN evidence PASS；timing/PPA GAP

独立裁决：`RETAIN`。

- task-run status=`PASS`；`preflight/manifest/synth/opensta/parser/trace/binding/cleanup` rc 全 0；runtime 删除 1,566,158,238 bytes，netlist 未保留。
- summary、binding log、production before/after、source manifest、STA manifest、Top40 SHA-256 分别为 `70a4f5ed...a882`、`30b54f66...a24c`、`b1ec234c...d2f9`/`b1ec234c...d2f9`、`8c7aa3cd...37fd5`、`75b2071c...8a2c`、`24154946...e145`，与运行节点报告一致。
- summary 精确绑定 d3f3 与 `mapped-5ns-bpu-inline-v1`；OpenSTA completion=`macro_lib_count=3`。
- raw `synth_stat.txt` 最终 hierarchy 只有 `OooFpArithGate×1`、`Sram4096x113×2`、`Sram4096x199×1` 为 unknown；`OooBranchDirectionPredictor` 为 87,601 mapped cells。whole-core logic area=2,465,601.32、sequential area=679,275.52。
- raw summary timing 为 WNS=-50.241458893 ns、TNS=-719693.1875 ns、40/40 violated、loops=0、`target_200mhz_met=false`。
- Top40 的 40 startpoints 与 40 endpoints 全部命中 BPU instance；最坏 path 从 `update_taken_i` DFF 经 local-PHT update AOI21 到 `local_pht_q[0][0]` DFF，54.784690857 ns arc 与 -50.241458893 ns slack 均直接来自 raw report。
- traceability=`startpoints=40`、`endpoints=40`、public 40/40、opaque 0/0。
- 相对四宏 A2：known cells +87,601、logic area +283,823.40、sequential area +109,068.96、WNS -38.691271782 ns、TNS -432,228.40625 ns；结论方向与 raw 两份 summary 一致。

边界：

- evidence PASS 只证明本次三宏+BPU-inline synthesis/OpenSTA 证据完整；200 MHz timing/PPA 明确为 GAP。
- local-PHT register-array 展开/集中 update fanout 是被路径形态支持的架构假设，不是本次只读复核证明的唯一 RTL root cause；无网表 fanout report、物理布线、CTS 或多角分析。
- fixed-toggle power、placeholder macro 内部 PPA 与 macro-inclusive total 均不具备 signoff 资格。
- 本复核未运行综合、OpenSTA、parser、trace 或测试，未写 evidence；首次只读查询的局部 shell 变量被 Windows 层展开为空并返回路径不存在，随后以显式路径完成同一批查询，无工程副作用。

`counterexample`：whole-inline 后 Top40 从四宏基线的 memory/control 路径完全切换为 BPU local-PHT internal paths，反驳“整块内联只增加面积而不主导时序”。`scope_extension_request=无`。置信度：sealed evidence/binding/数值高；微架构根因机制中等。
