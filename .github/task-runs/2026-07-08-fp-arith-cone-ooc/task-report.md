# 任务报告

## 目标

继续推进 `[112] RV64 Yosys full stdcell synthesis` 中的 `OooFpArithGate` 长尾拆账。上一轮已证明全模块 OOC coarse PASS、full stdcell 卡在 ABC gate netlist extraction；本轮在不启动 Ubuntu/rootfs、不改生产 RTL 的边界下，用 task-run 内临时 probe 拆出 addsub/mul/fma 三条输出锥。

## 实现者人格

本轮完成了 `OooFpArithGate` 子路径 OOC probe：

1. 新增 task-run 内临时 wrapper：`evidence/probes/OooFpArithGateConeProbes.v`。
2. 新增复现实验脚本：`run_cone_ooc.sh`，使用 `STA_SYNTH_FLATTEN=1`、`make -B` 和 100MHz 约束。
3. 分别运行 addsub/mul/fma 三个 output cone 的 coarse 与 full stdcell OOC。
4. 压缩 raw log，并用 `github_index_db.py index-evidence --write-index --yes` 登记 evidence asset。

关键结论：

- AddSub cone：coarse PASS，full stdcell PASS，area `15782.760000`，Yosys 用时 `15.60s`。
- Mul cone：coarse PASS，但 full stdcell 在 `600s` 内终止于 ABC `Extracting gate netlist of module \OooFpArithGateMulConeProbe`。
- FMA cone：coarse PASS，但 full stdcell 在 `600s` 内终止于 ABC `Extracting gate netlist of module \OooFpArithGateFmaConeProbe`。
- 因此“拆 addsub/mul/fma”这一步已经给出第一层答案：AddSub 不是当前 full stdcell 长尾；Mul/FMA 仍需继续拆乘法器、normalize、shift-jam、LZC、round/pack 或考虑 macro/iterative 边界。

## 关键证据

- `OooFpArithGateAddSubConeProbe` coarse：`704 wires / 9939 wire bits / 628 cells`，含 `36 $alu`、`250 $mux`、`50 $sdff`、`2 $shl`，`synth_check` 0 problems。
- `OooFpArithGateMulConeProbe` coarse：`582 wires / 9362 wire bits / 533 cells`，含 `31 $alu`、`4 $macc_v2`、`176 $mux`、`34 $sdff`、`2 $shl`，`synth_check` 0 problems。
- `OooFpArithGateFmaConeProbe` coarse：`1127 wires / 35734 wire bits / 1087 cells`，含 `45 $alu`、`14 $macc_v2`、`407 $mux`、`78 $sdff`、`6 $shl`，`synth_check` 0 problems。
- AddSub full stdcell：`Chip area for module '\OooFpArithGateAddSubConeProbe': 15782.760000`，sequential area `3745.280000 (23.73%)`。
- Mul/FMA full stdcell：均进入 ABC pass 后在 gate netlist extraction 阶段 timeout/terminated。
- `git diff --check` PASS，日志 `evidence/git-diff-check.log`。
- `scripts/agent-e2e.sh --profile yosys-sta --task-slug fp-arith-cone-ooc --stop-on-fail` PASS，证据 `.github/task-runs/2026-07-08-fp-arith-cone-ooc-2/`。
- `scripts/agent-e2e.sh --profile npc-dev --task-slug fp-arith-cone-ooc --stop-on-fail` PASS，证据 `.github/task-runs/2026-07-08-fp-arith-cone-ooc-3/`。
- `scripts/agent-e2e.sh --guard --guard-mode strict` PASS，日志 `evidence/agent-e2e-guard-strict.log`。

## 方法边界

- `OooFpArithGateConeProbes.v` 是 task-run evidence 内的临时 probe，不在生产 RTL filelist 中。
- probe 通过实例化完整 `OooFpArithGate` 并只暴露某一类输出锥，让 flatten 后的 unused logic 被裁掉；它适合定位 synthesis 长尾，不等同于已经完成正式模块拆分，也不证明未来真实模块抽取天然等价。
- 本轮没有修改功能 RTL，因此没有新增功能 TB；正确性语义仍以此前 focused TB、`OOO_ASSERT`、riscv-tests/full-state difftest 层级证据为边界。
- `npc/rv64/vsrc/debug` 与 `npc/rv64/vsrc/common` 仍作为 RTL 是否符合 spec 语义的审核层之一；后续若把 Mul/FMA 拆成正式模块并触碰 B-FP meta、kill age、redirect 或 facts 语义，应先查/补 common facts 与 debug checker，再宣称优化有效。

## 审查者人格

未闭合项与风险：

- Mul/FMA cone full stdcell 尚未闭合，不能据 AddSub PASS 宣称 `OooFpArithGate` 或全顶 STA-ready。
- 该 probe 是输出锥近似，不是 production module boundary；正式拆模块仍要补等价/回归证据。
- `OooFetchPacketCache` 的 SRAM/memory macro 边界仍是另一个 active blocker，本轮未处理。
- 本轮 `index-evidence` 对 `.gz` 的自动摘要包含二进制尾部噪声，所以人读结论以本报告和手工抽取 marker 为准。
- strict guard 因工作树内前序脏文件同时要求 `agent-system` 与 `rv64-linux` 证据；本轮未触碰 Ubuntu/rootfs，guard 使用既有有效证据通过，当前新跑的是 `yosys-sta` 与 `npc-dev`。

## 下一步

1. 优先拆 `OooFpArithGateMulConeProbe` 内部的 double/single multiplier、normalize 与 round/pack 子锥，判断 4 个 `macc_v2` 是否需要 macro/iterative/更细流水边界。
2. 对 `OooFpArithGateFmaConeProbe` 继续拆 product、128-bit align/shift-jam、wide add/sub、LZC、normalize、round/pack。
3. 若采用 macro/blackbox，只能作为“未知面积/未实现 stdcell”的定位边界，报告中必须保留限制。
4. 在 Mul/FMA 结构策略明确后，再回到 `NpcTop + OooFetchPacketCache blackbox` 的 full stdcell 探针；仍不要提前启动 Ubuntu/rootfs。
