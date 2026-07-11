# OooFetchHeadClassifyGate 设计说明

## 目标

`frontend/OooAluFetchCore.v`（后已重构为 `OooFrontend` wrapper；本模块现由
`OooFetchHeadPairGate` 实例化）仍承担 fetch packet head 分类、基础译码非法判定、
FP 子译码、privileged 非法检查、pending/CSR/trap glue 和提交修饰等多类职责。
本轮选择风险最低的一刀：把 head0/head1 重复的“单个 fetch head 分类”纯组合逻辑
收敛到 `frontend/OooFetchHeadClassifyGate.v`。

新模块作为单槽 classifier，内部实例化 `OooFpDecode`，并输出父模块当前已经消费的
`head*_fp_*`、`head*_branch/jal/jalr/mem/system/exit/arch_trap/stop` 等 facts。
父模块仍保留所有时序状态和全局仲裁。

## 范围

本模块只负责：

- `decode_valid` / `fetch_fault` 门控后的基础指令类别 facts。
- OP-FP、FP load/store、FP move/class/sgnj/addsub/mul/fma/div/sqrt/minmax/compare/convert
  等 FP facts。
- CSR、ECALL、EBREAK、MRET/SRET、WFI、SFENCE/SINVAL 事实。
- U-mode supervisor fence illegal、S-mode TVM fence illegal、S-mode TSR SRET illegal
  和 FS-off FP illegal。
- current-mode xRET 检查的当前实现边界；目标合同见下文 `XRET-G1`。
- base decoder illegal 对 FP 合法指令的豁免。
- `exit_raw`、`system_raw`、`arch_trap_raw`、`stop_raw`、`fp_enabled` 等父模块
  下游需要的组合输出。

不在范围内：

- 不新增寄存器或状态机。
- 不产生 ready/valid side effect。
- 不写 CSR/FPR/GPR/ROB。
- 不捕获或清理 pending entry。
- 不更新 fetch FIFO、`next_fetch_pc`、outstanding、discard、redirect 或 flush。
- 不改变 `DecodeUnit`、`OooFpDecode`、RVC 解压或 CSR 文件语义。

## 协议规则

- 本模块无 `clk/rst`，所有输出对输入纯组合返回。
- `decode_valid_i` 由父模块根据 FIFO/head 可见性、前序 fetch fault 和 control-stop
  规则产生；模块不自行判断 head0/head1 是否可见。
- `fetch_fault_i` 表示该槽 fetch response 非正常；fetch fault 必须抑制 decode-derived
  facts，并让该槽成为 architectural trap/stop fact。
- `semihost_peer_inst_i` 由父模块传入：
  - head0 使用 slot1 指令判断 semihost exit pattern。
  - head1 使用 slot0 指令判断 semihost enter pattern。
- `semihost_peer_is_enter_i` 指示 peer pattern 类型，避免模块硬编码 head0/head1。
- 输出 facts 只描述“当前槽是什么”；是否 dispatch/fire/commit 仍由父模块和既有
  gate 决定。

## 状态机

无状态机。该模块是纯组合分类器。

## 不变量

- `fetch_fault_i=1` 时，branch/jump/mem/fp/system/exit facts 必须为 0，
  `arch_trap_raw_o=1`、`stop_raw_o=1`。
- `illegal_raw_o = (decode_illegal && !fp_raw) || fp_dyn_frm_illegal`；合法 FP 指令不能
  被整数 decoder 的 `CTRL_ILLEGAL_BIT` 抢先变成 base illegal trap，DYN 舍入还必须检查
  committed `frm` 是否为保留值。
- FS-off FP illegal 与 base illegal 分离；
  `fp_enabled_o = fp_raw && !fp_disabled && !fp_dyn_frm_illegal`。
- `sfence.vma` 与 `sinval.vma` 受 `mstatus.TVM` 约束；
  `sfence.w.inval` 与 `sfence.inval.ir` 只作为 supervisor 序列化点，不受 TVM 约束。
- U-mode 下所有 supervisor fence 都 illegal。
- **CURRENT**：`priv_system_illegal` 当前包含 supervisor fence from U、
  S-mode TVM fence、S-mode+TSR 的 SRET、以及受 TW 约束的 WFI。
- **KNOWN GAP XRET-G1**：当前缺 `MRET && priv_mode!=M` 与
  `SRET && priv_mode==U`。目标合同是 MRET 仅 M-mode 合法；SRET 在 U-mode 非法，
  S-mode 还受 TSR 约束。`CsrFile` 不复查 current mode，不能依赖下游兜底。
- semihost EBREAK 不产生 `exit_raw_o`，但必须产生 `arch_trap_raw_o`，保持原先
  semihost trap 观测路径。
- 本模块不读取或修改 pending、CSR 文件、FPR、ROB、FIFO、RAS、BPU 或 PC/outstanding
  状态。

## 数据通路骨架

1. `OooFpDecode` 对 `decode_valid_i/inst_i` 产生 FP 子类 facts。
2. 基础控制类 facts 从 `ctrl_i` 派生，并统一受 `decode_valid_i && !decode_illegal`
   门控。
3. privileged illegal facts 使用 `priv_mode_i` 与 `mstatus_i` 组合判断。
4. `system_raw_o` 汇总 ECALL/CSR/xRET/WFI/SFENCE。
5. `arch_trap_raw_o` 汇总 fetch fault、base/DYN-frm illegal、semihost EBREAK、
   FS-off FP、privileged illegal 与 `unsupported_residual`。
6. `stop_raw_o` 汇总 fetch fault/exit/system/arch trap；FP 已迁域 A，
   `fp_raw` 不再属 stop 类（普通 dispatch 进 ROB/FP 簇；FS-off 经 arch trap 仍 stop）。

## 验证计划

新增 `npc/rv64/testbench/tests/tb_ooo_fetch_head_classify_gate.sv`，覆盖：

- 普通 ALU 指令：不 stop、不 trap。
- base illegal：产生 arch trap。
- 合法 FP 在整数 decoder illegal 时不产生 base illegal trap。
- FS-off FP：产生 arch trap。
- CSR/ECALL：产生 system/stop。
- 普通 EBREAK 与 semihost EBREAK 分流。
- MRET/SRET 分类；MRET-from-S/U、SRET-from-U 三类 current-mode 反例。
- SRET under S-mode TSR 正对照。
- SFENCE/SINVAL under U-mode illegal。
- S-mode TVM 只作用于 `sfence.vma/sinval.vma`。
- fetch fault 产生 arch trap/stop，并抑制其它类别 facts。
- 跨模块检查 `arch_trap_raw_o && frontend_dispatch_to_backend_valid_o`；当前 head0 FP
  代表反例应标为 KNOWN GAP，而不是 PASS 条件。

实现后最小回归：

- `make -C npc/rv64/testbench TESTS="tb_ooo_fetch_head_classify_gate tb_ooo_alu_fetch_core tb_decode_unit" RESULT_DIR=../perf/results/20260627-fetch-head-classify/focused run`
- `make -C npc/rv64 lint`
- `make -C npc/rv64 -j2`
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-fetch-head-classify/full-module-testbench run`
- 预算允许时追加 `rv64ui,rv64mi,rv64si` official riscv-tests smoke。

本轮实测结果：

- RED：`tb_ooo_fetch_head_classify_gate` 在模块未实现时因 `Unknown module type:
  OooFetchHeadClassifyGate` 失败，符合预期。
- GREEN：classifier 单测 PASS。
- focused：`tb_ooo_fetch_head_classify_gate tb_ooo_alu_fetch_core tb_decode_unit`
  3/3 PASS。
- full module testbench：101/101 PASS。
- `make -C npc/rv64 lint` PASS。
- `make -C npc/rv64 -j2` PASS。
- official smoke：`rv64ui/rv64mi/rv64si` `overall_rc=0`。

### 2026-07-11 复审边界

- 既有 classifier 单测证明局部分类主路径，不证明 current-mode xRET 完整，也不证明
  `arch_trap` 已在 dispatch gate 关闭 backend valid。
- MRET-from-S/U、SRET-from-U 已在真实 decode/classify 链复现为缺少 illegal；
  SRET-from-S+TSR 正对照正常。

## 实施顺序

1. 增加本 spec 与 task-run 记录。
2. 新增 classifier testbench，先验证模块不存在导致失败。
3. 新增 `frontend/OooFetchHeadClassifyGate.v` 并登记 `vsrc/filelist.mk`、
   `testbench/Makefile`。
4. 用 classifier 替换 head0 内联分类，跑 focused。
5. 用 classifier 替换 head1 内联分类，跑 focused。
6. 跑 lint/build/module 回归。
7. 更新 `vsrc/README.md`、`.github/memory/modules/npc.md`、
   `.github/memory/project-status.md` 和本 task-run。
