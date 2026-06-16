# RV64 CoreMark CPI Task Report

## 结论

`riscv64-npc` 默认 CoreMark 1000 iterations 已从 `CPI=6.017` 降到 `CPI=0.779`，达到用户要求的 `0.78/0.8` 基线。

## 修改范围

- `npc/rv64/vsrc/include/define.v`
  - 修复 RV64 PMEM cacheable 范围。
  - I/D cache line beat 改为 `8 x 64-bit`。
- `npc/rv64/vsrc/cache/ICache.v`
  - 去除 refill/line-byte path 中的 32-bit beat 假设。
- `npc/rv64/vsrc/ooo/OooIntBackend.v`
  - 补齐 RV64 `*W` sign-extension、RV64M/W 和 RV64B/Zba/Zbb/Zbc/Zbs。
  - memory request strobe 改为 `STRB_W=8`。
- `npc/rv64/vsrc/ooo/OooAluFetchCore.v`
- `npc/rv64/vsrc/ooo/OooAluCoreSlice.v`
- `npc/rv64/vsrc/ooo/OooAluDecodeBackend.v`
  - 透传 8-bit `wstrb`。
- `npc/rv64/vsrc/core/OooMemAxiBridge.v`
  - 8-byte aligned D-cache index、8-bit strobe merge/full-store 判断。
- `npc/rv64/Makefile`
  - 默认启用已验证的 RV64 双发射 OoO 性能后端。

## Root Cause

1. RV64 cache 实际被关闭：cacheable PMEM 范围不覆盖 `0x8000_0000`，所以 CoreMark I/D cache 统计全 0，所有取指/访存都走慢路径。
2. ICache 仍有 32-bit beat 假设：RV64 line fill 与 line 内 byte select 未按 `XLEN=64` 参数化。
3. 顺序核无法达到 sub-1 CPI：恢复 cache 后 CoreMark 仍是 `CPI=1.274`。
4. OoO RV64 路径功能不完整：`*W` 写回、RV64M/W、RV64B 和 8-byte memory lane 不完整，初始 `bitmanip`/`add` 不能作为默认性能后端。

## 验证证据

### Build

- `make -C npc/sim BACKEND=rv64 clean && make -C npc/sim BACKEND=rv64 lint && make -C npc/sim BACKEND=rv64 -j4`
- 结果：PASS。构建命令含 `-DNPC_OOO_ALU_EXPERIMENT`，证明默认路径已切到 RV64 OoO 后端。

### CPU-tests

- 命令：
  - `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv64-npc run NPC_RUN_ARGS="--no-progress --max-cycles 2000000"`
- 结果：
  - `40/40 PASS`
  - 平均 CPI `1.414`
  - 最高 CPI：`dummy cycles=46 commits=12 CPI=3.833`
  - 最低 CPI：`shuixianhua cycles=3429 commits=6077 CPI=0.564`
  - 近平均 CPI：`hello-str cycles=2128 commits=1510 CPI=1.409`

### CoreMark

- 命令：
  - `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/benchmarks/coremark ARCH=riscv64-npc ITERATIONS=1000 run NPC_RUN_ARGS="--no-progress --max-cycles 1000000000"`
- 结果：
  - `CoreMark PASS 8 Marks`
  - `HIT GOOD TRAP`
  - `cycles=247287515`
  - `commits=317356136`
  - `CPI=0.779`
  - `simulation frequency=962507 inst/s`

## 备注

- 当前性能验证日志显示 `Difftest: OFF`；这是当前生成配置状态。该任务目标是 guest-cycle CPI，最终交付以默认 `riscv64-npc` 命令的 `CoreMark PASS` 和 `CPI=0.779` 为准。
