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
- MRET/SRET current-mode 合法性与 SRET/TSR privileged illegal 分类。
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

### XRET-G1 current-mode 接口合同（2026-07-12，RTL 前冻结）

| 类别 | producer / 输入 | classifier 输出 | consumer 约束 |
| --- | --- | --- | --- |
| MRET current mode | `DecodeUnit.CTRL_MRET_BIT` + `CsrFile.priv_mode_o` | `mret_raw_o && priv_mode_i != PRIV_M` 必须置 `priv_system_illegal_o` 与 `arch_trap_raw_o` | `OooPendingDispatchArbiter` 必须以 arch-trap 胜过 system capture，CsrFile 不得收到该 xRET 请求 |
| SRET current mode | `DecodeUnit.CTRL_SRET_BIT` + `CsrFile.priv_mode_o` | `sret_raw_o && priv_mode_i == PRIV_U` 必须置 `priv_system_illegal_o` 与 `arch_trap_raw_o` | 同上；S/M mode 的 SRET 不因 current-mode gate 变非法 |
| SRET TSR | `CTRL_SRET_BIT` + `priv_mode_i` + `mstatus_i.TSR` | 仅 `SRET && priv==S && TSR` 置 privileged illegal | M-mode SRET 不受 TSR 约束；S-mode TSR=0 合法 |

六类跨模块契约冻结如下：

1. **握手**：模块无 valid/ready 状态；输入到 facts 为同拍纯组合映射，不能持有或撤回事务。
2. **stall**：模块不产生 stall；上游冻结时输入保持即可，classifier 无独立推进动作。
3. **flush/redirect/trap**：模块无状态可清。非法 xRET 同拍同时保留 xRET raw fact 并置
   `arch_trap_raw_o`；下游既有优先级必须是 arch-trap capture 胜过 system/xRET capture。
4. **异常序**：classifier 只形成 illegal-instruction fact；精确 trap 仍由 pending trap/ROB
   边界触发。`CsrFile` 只消费已由此门判定合法的 xRET 请求。
5. **访存序**：不读写 SQ/LSU/AXI，无访存序副作用。
6. **投机恢复/单一真源**：current mode 与 TSR 均只消费 `CsrFile` 导出的架构状态；模块不保存
   镜像。wrong-path facts 仍由父级 FIFO 可见性与 squash 控制。

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
- **XRET-I1（已验证）**：MRET 仅 M-mode 合法；
  `mret_raw_o && priv_mode_i != PRIV_M` 必须进入 privileged illegal。
- **XRET-I2（已验证）**：SRET 在 U-mode 非法，在 S/M-mode 可执行；
  `sret_raw_o && priv_mode_i == PRIV_U` 必须进入 privileged illegal。
- **XRET-I3（冻结，既有合同）**：TSR 只拦截 S-mode SRET；M-mode SRET 即使 TSR=1 也不非法。
- `priv_system_illegal` 必须统一汇总 current-mode xRET、supervisor fence from U、
  S-mode TVM fence、S-mode+TSR SRET 与受 TW 约束的 WFI。
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

### XRET-G1 RTL 级拓扑（RTL 前冻结）

- **边界/协议**：不改端口；`ctrl_i/priv_mode_i/mstatus_i` 输入与
  `priv_system_illegal_o/arch_trap_raw_o/facts_o` 输出均为同拍组合信号。
- **寄存器/FSM/pipeline**：无寄存器、无 FSM、无 pipeline；reset/flush/stall 无本地对象。
- **组合块**：`ctrl_legal_w` 生成 MRET/SRET raw facts；一个 `priv!=M` 比较器形成
  MRET current-mode illegal，一个 `priv==U` 比较器形成 SRET current-mode illegal；既有
  SRET/S/TSR 比较保持；三者与其它 privileged illegal 源经 OR 汇合，再进入 arch-trap/stop。
- **优先级**：本块只形成 facts，不仲裁副作用；下游保持 arch-trap > system/xRET capture。
- **资源/关键路径**：只新增两个 2-bit 特权比较与浅层 OR，无共享时序资源；预计路径为
  `ctrl bit + priv compare -> priv_system_illegal -> arch_trap -> stop/facts`。
- **function 划分**：不新增 function；所有逻辑保持显式 wire/assign。

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
- 跨模块检查 `arch_trap_raw_o && frontend_dispatch_to_backend_valid_o`。`FDG-G1` 已于
  2026-07-12 关闭：四类 head0 FP 代表反例必须满足 `arch_trap && !backend_valid`，合法
  FADD.S 必须继续满足 `fp_enabled && backend_valid`。

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

### 2026-07-12 FDG-G1 关闭

- `tb_ooo_fp_legality_dispatch_path` 已把真实 DecodeUnit、FP legality、classifier 与
  ordinary dispatch admission 串接；旧 RTL 对四类非法编码精确 RED，修复后 4/4 focused PASS。
- `OooFrontend` 的 `FDG-I1` 立即断言已用故意违约负探针证明非真空；正常 module 87/87、
  Difftest-ON AM 59/59、official 177/177 均通过。
- 本节只关闭 classifier→dispatch admission 合同；xRET current-mode 由下一节的独立
  XRET-G1 RED/GREEN 关闭。

### 2026-07-12 XRET-G1 关闭

- 常驻 classifier 矩阵新增 MRET@S/U、SRET@U 三类反例，并保留 MRET@M、
  SRET@S+TSR=0/1；额外覆盖 SRET@M+TSR=1，证明 TSR 不会越权拦截 M-mode。
- 旧 RTL 精确 RED：仅 6 个预期检查失败（3 类反例各自缺
  `priv_system_illegal/arch_trap`），全部正对照继续通过。
- classifier 最小修复后单测 1/1 PASS；DecodeUnit、classifier、head-pair、lane1 capture、
  pending-dispatch focused gate 5/5 PASS。
- `tb_ooo_priv_system` 另以真实 `30200073/10200073` 贯穿 Decode→classifier→pending→CsrFile：
  S-mode lane0 MRET 与 U-mode lane1 SRET 均得到 cause=illegal、正确 `mepc/mtval`，handler
  返回后继续执行，且非法 xRET 没有 synthetic commit；包含该整核场景的 focused 5/5 与
  final module 87/87 均 PASS。
- 未给纯组合 classifier 强加仅供断言使用的时钟端口：仓库要求时序块立即断言，而本模块
  无 `clk`/状态；常驻矩阵直接编码 ISA current-mode 真理，旧 RTL 的精确 RED 已证明其非真空。
  下游 `FDG-I1` 继续独立保证任何 `arch_trap` 不进入普通 backend dispatch。

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
