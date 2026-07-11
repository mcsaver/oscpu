# NPC RV64 使用说明

`npc/rv64` 是从 `npc/single` 派生的 RV64 基础核心后端，用于通过 `npc/sim BACKEND=rv64` 运行 `ARCH=riscv64-npc` 的 Abstract Machine 镜像。

## 当前定位

- ISA 目标：当前活动 OoO 核已实现 RV64IMAFDC + `Zba/Zbb/Zbc/Zbs` + Zicsr，
  M/S/U 三特权级 + Sv39 虚存（硬件 PTW + I/D TLB）+ PMP×16；更细的实现边界
  （能力、限制与开放合同）以 `design/arch/rtl-ground-truth-2026-07-11.md`
  （CURRENT snapshot）、`design/arch/ooo-core-architecture.md` 和 `vsrc/README.md` 为准。
- 数据宽度：`XLEN=64`，PC/GPR/CSR/AXI data/DPI payload 均按 64 位处理。
- 访存宽度：LSU 使用 8-byte bus word 和 `WSTRB[7:0]`，支持 byte/half/word/dword load/store。
- 运行入口：外部请优先使用 `npc/sim` 或 AM 的 `ARCH=riscv64-npc`，不要直接把上层脚本绑到 `npc/rv64` 私有路径。
- Linux/Ubuntu 启动入口：OpenSBI、Linux kernel、DTB、initramfs/rootfs、QEMU reference、focused bring-up tools 和日志套件统一在仓库根目录 `Linux/` 下维护；`npc/rv64` 只保留 core RTL、testbench、Kconfig 和 Verilator 仿真本体。

## 快速命令

```bash
make -C npc/sim rv64_defconfig
make -C npc/sim BACKEND=rv64 lint
make -C npc/sim BACKEND=rv64 -j4
```

核级轻量回归入口：

```bash
make -C npc/rv64 core-regress
```

该入口会依次运行 `npc/rv64/testbench` 模块测试、Verilator lint、NPC
仿真器构建、AM cpu-tests，以及官方 `riscv-tests` 的 RV64 p-mode
用例。外部 `riscv-tests` 源码默认放在
`npc/rv64/testsuites/core-tests/src/riscv-tests/`，这是 ignored testsuite
artifact，不随仓库提交；缺失时可用脚本的 `--fetch-riscv-tests` 拉取。
外部 riscv-tests 收敛在 `npc/rv64/testsuites/`;ACT4(riscv-arch-test 源/工具链/ELF 基线)已整体迁至 `am-kernels/arch-test/`(2026-07-02,详见其 README)。
脚本也支持 `--riscv-privileged` 追加 `rv64mi/rv64si`，以及
`--riscv-filter REGEX` 对单项失败做快速复现。

> **当前结果判读（2026-07-11，F0 收口后）**：module runner 与 AM 聚合器已上传真实
> 子层退出码，并拒绝 failure marker、缺项、重复项或外层 PASS 冒充测试成功。新鲜证据为
> module 86/86、AM 59/59（`fp-difftest-probe` 明确 Difftest ON）和 official
> riscv-tests 177/177；core-regress 的 module/lint/build/AM 子层与 `overall_rc=0` 一致。
> 证据入口：`.github/task-runs/2026-07-11-rv64-f0-truthful-regression/`。

RISC-V Architecture Tests / ACT4(已迁至 am-kernels/arch-test，2026-07-02)：

```bash
# 生成/环境准备(原 npc-rv64-act4-preflight.sh)
am-kernels/arch-test/scripts/act4-preflight.sh --final-elfs --extensions I
# 跑 NPC 目标(原 npc-rv64-act4-run.sh; 统一 runner 见 make -C am-kernels/arch-test help)
am-kernels/arch-test/scripts/act4-npc-run.sh --suites rv64i/I,rv64i/M
make -C am-kernels/arch-test run-npc ACT4_SUITES="rv64i/I,rv64i/M,priv/Sv"
```

要点(详见 am-kernels/arch-test/README.md)：NPC 执行用 `elfs/.../*.elf` final
self-checking ELF(不是 `build/.../*.sig.elf` 参考模型中间 ELF)；privileged Sv
应使用与实现边界匹配的 `sail-RVA22S64` 配置(当前核未实现 V/VS，不用 `sail-rv64-max`)；
`C`/`A` extension 生成会返回成功但不产出可执行 suite。NPC 结果仍写
`npc/rv64/perf/results/act4-run/`。

AM/cpu-tests 回归：

```bash
export AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine
export NPC_HOME=/home/lyg/PA/ysyx-workbench/npc
make -C am-kernels/tests/cpu-tests ARCH=riscv64-npc run \
  NPC_RUN_ARGS="--no-progress --max-cycles 20000000"
```

当前核级验证裁决（2026-07-11，F0 收口后）：official `riscv-tests` 默认+特权组合
177/177、AM 59/59、module 86/86 均为真实退出码通过；三个 sequencer TB 已按 current
接口刷新，FP GPR-destination completion 已从 FPR busy/bypass/wakeup/write 域隔离。
完整范围与仍开放的 F1-F3 合同见 `design/arch/rtl-ground-truth-2026-07-11.md` §5/§6 和
`design/arch/rv64-200mhz-completion-design.md`。

以下为历史验证记录。ACT4 目前已完成 framework
生成 smoke、xPack GCC 15.2.0-1 compiler gate、testsuite artifact 内 Ruby
headers gate、RV64I/RV64M final self-checking ELF 生成与 NPC 执行；ACT4
`rv64i/I` suite `51/51 PASS`，`rv64i/M` suite `13/13 PASS`。2026-06-27
在 `stop_pending` 拆分后复跑 final ELF：`rv64i/I` 51/51 PASS，证据
`npc/rv64/perf/results/20260627-act4-final-rv64i/20260627-074515-1515239/`；
`rv64i/M` 13/13 PASS，证据
`npc/rv64/perf/results/20260627-act4-final-rv64m/20260627-074811-1517820/`；
combined `rv64i/I,rv64i/M` 64/64 PASS，证据
`npc/rv64/perf/results/20260627-act4-final-rv64im/20260627-075540-1520228/`。
ACT4 privileged `Sv` final ELF 生成 485 项成功；smoke `priv/Sv --limit 5`
为 3/5 PASS，证据
`npc/rv64/perf/results/20260627-act4-final-priv-sv-smoke/20260627-075821-1523834/`；
`sv39_canonical_Smode` 放大到 300s/200M cycles 仍 host timeout，但日志显示
持续推进且无 `TOHOST FAIL`/BAD TRAP，证据
`npc/rv64/perf/results/20260627-act4-final-priv-sv-canonical-smode/20260627-080043-1524561/`。
后续确认 timeout 根因是 `sail-rv64-max` 的 V/VS profile mismatch；切换到
`sail-RVA22S64` 并修复 PTE reserved/non-leaf D/A/U、`mstatus/sstatus.SD`
派生、`menvcfg.PBMTE`/Svpbmt PTE policy 和 Svinval supervisor fence 特权/TVM
decode 后，ACT4 `priv/Sv` 33/33 PASS，`priv/Svpbmt` 4/4 PASS，
`priv/Svinval` 2/2 PASS，当前已生成的 Sv 族 combined
`priv/ExceptionsSv,priv/Sv,priv/Svade,priv/Svbare,priv/Svpbmt,priv/Svinval`
为 48/48 PASS，
证据分别在
`npc/rv64/perf/results/20260627-act4-rva22s64-priv-sv-full-after-sd/20260627-085153-1553580/`、
`npc/rv64/perf/results/20260627-act4-rva22s64-priv-svpbmt-after-fix/20260627-091809-1584945/`、
`npc/rv64/perf/results/20260627-act4-rva22s64-priv-svinval-after-fix/20260627-093545-1614756/` 和
`npc/rv64/perf/results/20260627-act4-rva22s64-priv-sv-combined-after-svinval/20260627-093604-1614913/`。
同轮验证还包括 focused PTE set 5/5 PASS、`sv_mstatus_tvm_test` PASS、
`make -C npc/rv64 -j2` PASS、`make -C npc/rv64 lint` PASS、focused module TB
和 Svinval focused TB PASS，以及 official default+FP+A+privileged `riscv-tests` test-only sweep
177/177 PASS，证据分别在
`npc/rv64/perf/results/20260627-act4-rva22s64-priv-sv-pte-reserved-fix2/20260627-084640-1550329/`、
`npc/rv64/perf/results/20260627-act4-rva22s64-priv-sv-tvm-sd-fix/20260627-085144-1553449/`、
`npc/rv64/perf/results/20260627-act4-rva22s64-svpbmt/module-focused-after-whitebox/`、
`npc/rv64/perf/results/20260627-act4-rva22s64-svinval/module-focused/` 和
`npc/rv64/perf/results/20260627-act4-rva22s64-svinval/core-regress-official/20260627-093617-1616308/`。
边界：当前闭合 ACT4 I/M final ELF 和 `sail-RVA22S64` Sv39/Svpbmt/Svinval 核级 gate；
这仍不是 ACT4 全配置、精确 NPC UDB 全覆盖、Linux/full-system、formal/PPA/timing/CDC/reset/物理签核或工业 CPU signoff。

## Difftest 状态

difftest 以本仓库 NEMU 为参考模型（`nemu/src/isa/riscv64` 已完整可用），
`make -C npc/rv64 difftest-ref` 构建参考 `.so`（NEMU
`riscv64-npc_defconfig` + `SHARE=1`）；该目标会切换 NEMU 配置，调用者若要保持自定义
NEMU `.config`，须在 wrapper 中显式备份/恢复。
`configs/default_defconfig` 默认打开 `CONFIG_NPC_DIFFTEST=y`；Kconfig 裸默认与
`rv64_perf_defconfig` 为 n（perf 构建编译期剔除 difftest 运行时）。当前实现可比较
PC/GPR、FPR、确定性 CSR、privilege、fflags/frm，并对异常/中断/counter 做现有同步或
掩码处理；MMIO load 在 commit 拍按指令解码 EA 判定 skip。当前工作区 `.config` 仍未开启
Difftest，因此常规 current-config core-regress 不能冒充逐退休全状态对拍；F0 另用
`default_defconfig` 构建并取得 `Difftest: ON` 的 AM 59/59 证据，随后按哈希恢复配置。详见
`design/arch/rtl-ground-truth-2026-07-11.md` §6.3。

## 生成物

以下路径为生成物，已在仓库 `.gitignore` 中忽略：

- `npc/rv64/.config`
- `npc/rv64/build/`
- `npc/rv64/include/config/`
- `npc/rv64/include/generated/`
- `npc/rv64/testbench/build/`
