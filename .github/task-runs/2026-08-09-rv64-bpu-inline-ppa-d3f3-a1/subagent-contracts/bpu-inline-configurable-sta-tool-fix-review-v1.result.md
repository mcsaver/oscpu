# BPU-inline configurable STA tool fix independent review v1

RV64 RTL 结论｜对象=`NpcTop` / `OooBranchDirectionPredictor` / configurable mapped-STA 工具链｜周期/配置=5.000 ns、d3f3、`mapped-5ns-bpu-inline-v1`｜TB/EDA 观测=三宏投影静态闭合；留存 unittest 19/19、rc=0；A1 OpenSTA 未进入｜范围=PASS（工具修复；A1 timing/PPA 仍为 GAP）

独立裁决：`RETAIN`。

- registry 精确投影三项 blackbox/Liberty：`Sram4096x199`、`Sram4096x113`、`OooFpArithGate`；`OooBranchDirectionPredictor` 为 `inline_rtl`。四 placeholder 配置仍保持四项投影。
- runner 将同一投影传给 Yosys、Tcl、parser 和 `stamp-mapped-summary`；production manifest 显式绑定新 Tcl、parser、registry、runner。
- Tcl 用 `V15P_STA_EXPECTED_MACRO_LIB_COUNT` 比较实际读取数量；parser 同时核对 completion `macro_lib_count` 与 raw `synth_stat` unknown 集合；registry 末端再核对具体实例计数。
- 静态合同拒绝历史 `$macro_count != 4`、`"macro_lib_count": "4"`、`EXPECTED_UNKNOWN_MACROS`，并覆盖 runner/tool marker mutation。
- A1 raw 末端 unknown census 仅三类；`OooBranchDirectionPredictor` 已映射为 87,601 cells、logic area 283,823.40。原状态仍为 `FAIL rc=1 stage=evidence-complete evidence_complete=0`，没有 WNS/TNS/Top40/power。
- A2 仍只是四宏 evidence baseline：WNS -11.550187111 ns、TNS -287464.78125 ns、40/40 violated，不能转写为 BPU-inline 结果。
- 旧 Tcl/parser SHA-256 与 A1 `sta-inputs.sha256` 完全一致；旧 driver、A1、A2 的 staged/unstaged scoped diff 均为空。

反例与边界：

- 合法三宏被旧四宏常量拒绝，直接支持工具配置根因；不支持 Yosys 不可综合假设。
- 新 Tcl 单独只核对数量；精确 Liberty 身份由 production runner、input manifest 和 registry stamp 合取保证。
- parser 仍绑定当前 d3f3/candidate adapter SHA，因此本裁决不扩展到未来 RTL design-id。
- 留存证据记录 unittest 19 tests、rc=0，并与当前 19 个 test method 对齐；reviewer 按合同未重跑测试、parser、OpenSTA 或综合。

`scope_extension_request=无`。若要关闭 BPU-inline timing/PPA GAP，应另建新 run-id 执行一次同身份综合/OpenSTA。置信度：工具链静态闭合高；实际新 STA 运行与时序结果未测。全部工程命令已结束，WSL shell ownership 已归还。
