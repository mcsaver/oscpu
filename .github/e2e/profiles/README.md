# E2E Profiles

每个 `.tsv` 文件是一个可执行 profile。格式：

```text
node_id|module|function|owner_agent|inputs|outputs
```

特殊行：

```text
@include|profile-name||||
```

用于复用其它 profile 的节点，例如 `quick` 复用 `discovery`。

改动 profile 后先跑：

```bash
scripts/agent-e2e.sh --validate-all-profiles
```

该命令只检查 profile 展开和 `scripts/e2e/modules/*.sh` 函数绑定，不执行具体 gate。

重型 NEMU Ubuntu 性能采样使用：

```bash
AGENT_E2E_NEMU_PROFILE_GATE=1 scripts/agent-e2e.sh --profile nemu-ubuntu-profile
```

该 profile 继承 NEMU-only focused contract，默认 full rootfs、`NEMU_PROFILE=1`、大指令预算和性能 fast path，guest 功能测试脚本关闭；不要把它加入 NPC-only profile。
summary 会检查 Sv39 TLB 处于启用状态，并要求 `cpu.tb_stop_*` stop reason counters 存在；普通 store 不应再作为保守 TB barrier，真实 MMIO/device write 才作为 TB 边界；taken/not-taken 条件分支、direct jump、JALR、压缩 misc 顺序指令、普通 `fence` 和只读 CSR 应通过 `cpu.tb_continue_*` counters 证明已继续留在 TB 内，`control_fallback`/`fence.i`/AMO/SYSTEM 子桶用于继续定位下一轮瓶颈。profile 默认 `NEMU_INTERPRETER_TB_MAX_INST=32`，可用 `AGENT_E2E_NEMU_PROFILE_TB_MAX_INST`/`NEMU_PROFILE_TB_MAX_INST` 显式做 TB 长度实验；目前 TB=64 是对照项，不作为默认优化。
profile wrapper 默认开启 `NEMU_INTERPRETER_BASIC_BLOCK`、`NEMU_INTERPRETER_WIDE_IFETCH`、`NEMU_INTERPRETER_DECODE_CACHE`、`NEMU_VADDR_HOST_FAST` 和 `NEMU_RISCV_MMU_TLB`，但会尊重调用者显式传入的 `NEMU_*` env；需要做 fast path 关闭诊断时，可直接在 `scripts/agent-e2e.sh --profile nemu-ubuntu-profile` 前加对应 `NEMU_*=0`。2026-06-16 的 disable smoke `.github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-runtime-flag-inline-disable-smoke-fixed/` 证明 wrapper command file 记录 `runtime.wide_ifetch=0`、`runtime.decode_cache=0`、`runtime.vaddr_host_fast=0`、`runtime.mmu_tlb=0`，summary 中 `profile.vaddr.ifetch_wide_disabled=1000000` 且 host-fast read/write 均为 0；默认 smoke `.github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-runtime-flag-inline-default-smoke-fixed/` 仍保持 fast path 全开。
需要看真实 full rootfs 指令类别构成时，设置 `AGENT_E2E_NEMU_PROFILE_OPCODE_MIX=1` 或 `NEMU_PROFILE_OPCODE_MIX=1`；e2e 会要求 `cpu.opcode_mix.enabled=1` 和核心 opcode counters 存在，summary 会输出 `derived.opcode_mix_total` 与 `derived.opcode_*_pct_x100`。该开关是诊断用，默认关闭；当前实现把 runtime flag 做成热路径 inline bool，1B full rootfs profile 中 opcode mix 诊断开销约 1.23%，不要把诊断 run 当作默认性能基线。

需要继续细分 AMO/CSR TB stop 时，设置 `AGENT_E2E_NEMU_PROFILE_STOP_DETAIL=1` 或 `NEMU_PROFILE_STOP_DETAIL=1`；e2e 会要求 `profile.cpu.stop_detail.enabled=1`、AMO 子桶和 SYSTEM CSR 子桶存在，summary 会输出 `derived.tb_stop_amo_*_pct_x100`、`derived.tb_continue_amo_*_pct_x100` 与 `derived.tb_stop_system_csr_*_pct_x100`。该开关同样是诊断用，默认关闭；当前默认 1B profile 为 60.664s/16.48 MIPS，stop-detail 1B profile 为 61.357s/16.30 MIPS。最新 stop-detail 结论是写 CSR 停块主要来自 `sstatus`（约 81.6%），AMO 停块主要来自 `amoadd`（约 50.0%）；AMO 继续留在 TB 内的实验通过 LR/SC/AMO smoke，但 1B 性能下降，已撤回。
`exec_csr()` 的 `sstatus` 专用快路径也已作为负实验撤回：带默认计数版 1B 为 61.841s/16.17 MIPS，移除默认计数后为 61.521s/16.25 MIPS，均慢于 60.664s/16.48 MIPS 基线。后续不要把该方向当作默认优化入口。

需要判断 decode-cache 热点是 miss 多还是命中路径本身贵时，设置 `AGENT_E2E_NEMU_PROFILE_DECODE_CACHE=1` 或 `NEMU_PROFILE_DECODE_CACHE=1`；e2e 会要求 `profile.cpu.decode_cache.lookups` 非零、hit/miss counters 存在，并检查 `derived.decode_cache_hit_rate_x100`。该开关默认关闭，默认 profile command file 仍记录 `decode_cache_detail=0` 且 decode-cache counters 为 0，避免把 per-instruction 诊断计数混入默认基线。2026-06-16 的 1B detail profile `.github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-detail-profile/` 显示 `lookups=999998453`、`hits=913217658`、`misses=86780795`、hit rate 91.32%，命中里的 RVC 占 58.27%，fills 里的 RVC 占 61.21%；同开关 host-perf `.github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-detail-host-perf/` hit rate 91.13%，perf top 仍为 `isa_exec_once`、`vaddr_ifetch_wide`、`rv_decode_cache_exec`、`sv39_translate`、`exec_rv64c`。64K 容量实验已撤回：`CONFIG_INTERPRETER_DECODE_CACHE_ENTRIES=65536` 的 default 1B `.github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-64k-profile/` 为 22.954s/43.57 MIPS；detail 1B `.github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-64k-detail-profile/` hit rate 升到 94.52%，但 MIPS 仍为 43.19，说明容量增加的 footprint 成本盖过了 miss 减少收益。结论：`rv_decode_cache_exec` 热不是单纯 miss-heavy，下一步更应拆 RVC hit 执行/dispatch、wide-ifetch 和 Sv39，而不是重复此前已撤回的 RVC load/store 预译码或单纯扩大 cache 容量实验。

需要继续拆 RVC hit 执行构成时，设置 `AGENT_E2E_NEMU_PROFILE_RVC_DETAIL=1` 或 `NEMU_PROFILE_RVC_DETAIL=1`；e2e 会要求 `profile.cpu.rvc_detail.enabled=1`、`derived.rvc_detail_total` 非零，并检查一组常见 RVC 子类 counters。该开关默认关闭，默认 smoke `.github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-rvc-detail-default-smoke-rerun/` 记录 `rvc_detail=0` 且 RVC counters 为 0。2026-06-16 的 1B RVC detail profile `.github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-rvc-detail-profile/` 显示 `derived.rvc_detail_total=582497849`，高频子类为 `c.sdsp` 75.97M（13.04%）、`c.ldsp` 73.49M（12.61%）、`c.mv` 68.65M（11.78%）、`c.addi` 44.94M（7.71%）、`c.beqz` 38.33M（6.58%）、`c.ld` 37.20M（6.38%）、`c.li` 30.32M（5.20%）、`c.add` 27.87M（4.78%）、`c.bnez` 21.46M（3.68%）、`c.jr` 21.24M（3.64%）。后续若做 RVC 优化，优先看栈相关 load/store、move/add/immediate 和短分支/JR 的 hit path/code layout；低频 floating compressed、`c.ebreak`、`other` 不是当前热路径。窄 fast path 方向已有负实验证据：只提前识别 `c.sdsp/c.ldsp` 的 1B `.github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-rvc-stack-fastpath-profile/` 为 22.566s/44.31 MIPS，低于近场 baseline `.github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-rvc-fastpath-baseline/` 的 21.300s/46.95 MIPS，已撤回；不要重复把同类单指令 fast path 作为默认优化。

需要 host 采样时，设置 `NEMU_PROFILE_HOST_PERF_RECORD=1`；脚本会先试系统 `perf`，WSL Microsoft kernel 不可用时自动在 `Linux/env/platforms/nemu/tools/host-perf/` 建立无 sudo local-cache perf 并输出 `perf.data`/`perf-report.txt`。2026-06-15 的 host perf 证明 `pmp_check_with_priv` 曾占约 27.13%，随后 PMP range/cache dirty path 正收益：默认 1B 从 60.664s/16.48 MIPS 到 44.339s/22.55 MIPS。再把 CLINT host time 同步改成默认每 512 条退休指令同步一次（`NEMU_RISCV_CLINT_HOST_SYNC_INTERVAL=1` 可恢复旧逐指令同步），最终 1B 为 28.402s/35.21 MIPS，`profile.clint.host_time_reads=1987420`。2026-06-16 将 profile counter 与 runtime fast flags 做成热路径 inline 后，默认 1B `.github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-runtime-flag-inline-profile/` 为 23.284s/42.95 MIPS，较 inline-counter 38.55 MIPS 基线约 +11.39%；host-perf 1B `.github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-runtime-flag-inline-host-perf-profile/` 为 25.286s/39.55 MIPS，perf top 不再出现 `runtime_enabled` 或 `nemu_profile_count` 函数热点。继续把 vaddr fault pending 与 paddr device-write pending 空路径改成 header inline guard 后，paddr guard 初跑 1B `.github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-paddr-device-write-guard-profile/` 为 21.189s/47.19 MIPS，正确 host-perf 1B `.github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-paddr-device-write-guard-host-perf-profile-fixed/` 为 21.066s/47.47 MIPS，`paddr_take_device_write` 不再出现在 perf top。后续 RVC load/store decode-cache 预译码实验 1B 降到 21.446s/46.63 MIPS，已撤回；撤回后 host-perf `.github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-after-rvc-mem-decode-cache-revert-host-perf/` 为 21.920s/45.62 MIPS，说明 WSL/host wall-time 有波动，不能只取最高值当稳定收益。当前 top 集中在 `rv_decode_cache_exec`、`vaddr_ifetch_wide`、`isa_exec_once`、`sv39_translate`、`exec_rv64c`，下一刀应继续看取指/译码/Sv39/压缩指令执行热路径；这仍不是完整 Ubuntu login/full hard gate 的完成证据。

需要区分 host perf 中的真实模拟器热点和 guest profile counters 自身开销时，设置 `AGENT_E2E_NEMU_PROFILE_GUEST_COUNTERS=0` 或 `NEMU_PROFILE_GUEST_COUNTERS=0`。该模式仍走 `nemu-ubuntu-profile`、`/usr/bin/time` 和可选 `NEMU_PROFILE_HOST_PERF_RECORD=1`，但运行 NEMU 时设置 `NEMU_PROFILE=0`，summary 会是 `profile.available=0`，command file 会记录 `guest_counters=0`；默认不变，仍为 `guest_counters=1` 并要求 `profile.enabled=1`。2026-06-16 的 host-only 10M smoke `.github/task-runs/2026-06-16-nemu-ubuntu-host-only-profile-smoke/`、默认 guest-counter smoke `.github/task-runs/2026-06-16-nemu-ubuntu-guest-counter-profile-smoke/` 与最终 host-only smoke `.github/task-runs/2026-06-16-nemu-ubuntu-host-only-profile-final-smoke/` 均 PASS。1B host-only host-perf `.github/task-runs/2026-06-16-nemu-ubuntu-host-only-host-perf-profile/` 显示关闭 guest counters 后热点仍为 `rv_decode_cache_exec`、`isa_exec_once`、`sv39_translate`、`vaddr_ifetch_wide`、`exec_rv64c`，因此不要把当前慢速归因于 UART 或 profile counters。`vaddr_ifetch_wide` no-profile/profiler split 是负实验：`.github/task-runs/2026-06-16-nemu-ubuntu-ifetch-split-host-only-host-perf-profile/` 退到 24.12s 且 `vaddr_ifetch_wide` 未下降，已撤回。
