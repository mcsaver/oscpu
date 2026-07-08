# 2026-07-08-fp-arith-macro-decision

## 目标

把 `OooFpArithGate` 的 Mul/FMA internal cone probe 结论转成可审查的 module-level macro/OOC
decision placeholder v0，作为后续 Yosys/NpcTop/iEDA STA 前的边界合同。该任务不启动 Ubuntu/rootfs，
也不宣称 FP arithmetic 已经 full stdcell 或 STA-ready。

## 变更

- `npc/rv64/design/specs/ooo-fp-arith-gate.md` 新增 `Macro/OOC Contract v0`：
  固化 5-cycle pending/B-FP latency、`1 op/cycle` launch、kill/flush、value/fflags/meta 对齐、
  OOC coarse PASS/full stdcell open、internal cone evidence 与 remaining tasks。
- `npc/rv64/design/specs/yosys-macro-boundary-contracts.md` 将 `OooFpArithGate` 从 open 转为
  decision placeholder v0，并保留 full-module OOC timing report 或 production child split/top
  constraints 作为未闭合任务。
- `yosys-sta/scripts/check_fp_arith_macro_contract.py` 增加窄检查器，确保 dedicated spec 与四黑盒总表同步。
- `.github/e2e/modules/yosys-sta.md` 与 `npc/rv64/design/specs/README.md` 同步索引该合同。

## 验证

- `python3 yosys-sta/scripts/check_fp_arith_macro_contract.py` PASS：
  `fp-arith-spec facts=18`，`macro-boundary facts=8`。
- `python3 yosys-sta/scripts/check_macro_contracts.py --spec npc/rv64/design/specs/yosys-macro-boundary-contracts.md --netlist npc/rv64/build/sta/NpcTop-100MHz/NpcTop.netlist.v` PASS：
  四个 macro/OOC 边界 RTL 与 netlist instance 均覆盖。
- `python3 -m py_compile yosys-sta/scripts/check_fp_arith_macro_contract.py` PASS。
- `make -C npc/rv64/testbench TESTS=tb_ooo_fp_arith_gate RESULT_DIR=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-08-fp-arith-macro-decision/tb-fp-arith run` PASS。
- `make -C npc/rv64 check-contract` PASS：`$error` 计数当前 12，基线 12。

## 结论

`OooFpArithGate` 的当前生产语义边界保持 5-cycle RTL；module-level blackbox/OOC 只能作为
non-signoff 结构 sanity。internal standalone probes 已转为生产拆分候选证据。下一步仍是产出
full-module OOC timing report，或形成 production child split/top constraints 后再重跑 `NpcTop`
synthesis 与 iEDA STA smoke。

## 风险

- 未接入真实 Liberty/LEF/OOC timing report，顶层 unknown area/timing 仍 open。
- 若后续改 latency、流水级或生产子边界，必须补 focused/random TB，并用 `vsrc/common` facts 与
  `vsrc/debug` checker 审核 RTL 是否符合本 spec 语义。
