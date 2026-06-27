# NPC RV64 使用说明

`npc/rv64` 是从 `npc/single` 派生的 RV64 基础核心后端，用于通过 `npc/sim BACKEND=rv64` 运行 `ARCH=riscv64-npc` 的 Abstract Machine 镜像。

## 当前定位

- ISA 目标：当前活动 OoO 核按 RV64GC 基线推进，并已覆盖 `Zba/Zbb/Zbc/Zbs`
  子集；更细的实现边界以 `vsrc/README.md`、core-regress 结果和 memory
  记录为准。
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
外部测试套件、工具链和 ACT4 workdir 统一收敛在 `npc/rv64/testsuites/`。
脚本也支持 `--riscv-privileged` 追加 `rv64mi/rv64si`，以及
`--riscv-filter REGEX` 对单项失败做快速复现。

RISC-V Architecture Tests / ACT4 前置检查：

```bash
npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh --prepare
npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh --install-xpack-gcc
npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh --probe-tests --extensions I
npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh --probe-elfs --extensions I
npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh --final-elfs --extensions I
npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh --final-elfs --extensions M \
  --workdir npc/rv64/testsuites/core-tests/act4-npc-final-work-script
npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh --final-elfs --extensions Sv \
  --config-name sail-RVA22S64 \
  --workdir npc/rv64/testsuites/core-tests/act4-npc-rva22s64-work
npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --list-suites
npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --config-name sail-RVA22S64 \
  --workdir npc/rv64/testsuites/core-tests/act4-npc-rva22s64-work --list-suites
npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --filter 'I-(add|addi|sub)-00' --limit 3
npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --suites rv64i/I,rv64i/M
npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --config-name sail-RVA22S64 \
  --workdir npc/rv64/testsuites/core-tests/act4-npc-rva22s64-work --suites priv/Sv
```

该入口把 `riscv/riscv-arch-test`、ACT4 Python venv、Bundler 和 Sail
reference model 放在 `npc/rv64/testsuites/core-tests/`，不随仓库提交，
也不运行完整 Linux/rootfs。`--probe-tests` 只验证 ACT4 assembly 生成链路；
`--probe-elfs` 默认 `FAST=True`，主要验证 ELF 生成前置链路；`--final-elfs`
会生成 `elfs/.../*.elf` final self-checking ELF，给 NPC 执行时应使用这个
final ELF，而不是 `build/.../*.sig.elf` 参考模型中间 ELF。当前 ACT4 要求
GCC 15+ 或 LLVM/Clang 21+，可用 `--install-xpack-gcc` 在 testsuite
artifact 中安装 xPack GCC 15.2.0-1。`--workdir` 支持绝对路径或相对仓库根目录
的路径，避免 ACT4 在源码 checkout 内生成嵌套测试产物。`--config-name` 可选择
ACT4/Sail 配置目录，`--config-src` 可显式指定配置源；当前核未实现 V/VS，因此
privileged Sv 默认不应使用会期望 `sstatus.VS` 的 `sail-rv64-max`，而应使用
和当前实现边界匹配的 `sail-RVA22S64`。`npc-rv64-act4-run.sh`
会对 final ELF 逐项解析 `tohost`、objcopy 成 bin，并用 NPC `--tohost=ADDR`
判定 PASS/FAIL，结果写入 `npc/rv64/perf/results/act4-run/`；不确定 suite 名时
先用 `--list-suites` 查看实际生成目录。当前本地 ACT4 checkout 的 unprivileged
final ELF 目录只有 `rv64i/I` 和 `rv64i/M`；尝试生成 `C` 或 `A` extension 会返回
成功但不产出可执行 suite，因此不能把它解释为 RTL 的 C/A 执行结果。
`Sv` privileged suite 当前可在 `sail-RVA22S64` 配置下生成并通过 NPC 执行。

AM/cpu-tests 回归：

```bash
export AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine
export NPC_HOME=/home/lyg/PA/ysyx-workbench/npc
make -C am-kernels/tests/cpu-tests ARCH=riscv64-npc run \
  NPC_RUN_ARGS="--no-progress --max-cycles 20000000"
```

当前核级验证结果：AM `ARCH=riscv64-npc` cpu-tests `56/56 PASS`；官方
`riscv-tests` 默认 core-regress 套件 `111` 个 p-mode 用例通过，覆盖
`rv64ui/rv64um/rv64uc/rv64uzba/rv64uzbb/rv64uzbc/rv64uzbs`；追加
`--riscv-privileged` 后组合套件 `135` 个用例通过，额外覆盖
`rv64mi/rv64si`；2026-06-26 的扩展组合
`rv64ui/rv64um/rv64ua/rv64uf/rv64ud/rv64uc/rv64uzba/rv64uzbb/rv64uzbc/rv64uzbs`
为 `153 tests attempted` 全 PASS。官方 `riscv-tests` 通过 NPC 的
`--tohost=ADDR` watcher 判定 PASS/FAIL。ACT4 目前已完成 framework
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

当前默认关闭 `CONFIG_NPC_DIFFTEST`。原因是本仓库 NEMU 的 RV64 reference 仍不完整：`src/isa/riscv64` 不存在，现有执行器也缺 RV64 load/store、OP-32 和 RV64M 等语义。后续若要打开 RV64 difftest，需要先补齐 NEMU RV64 reference。

## 生成物

以下路径为生成物，已在仓库 `.gitignore` 中忽略：

- `npc/rv64/.config`
- `npc/rv64/build/`
- `npc/rv64/include/config/`
- `npc/rv64/include/generated/`
- `npc/rv64/testbench/build/`
