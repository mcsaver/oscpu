# NEMU Python Int ASLR Target Range Trace

## 结论

本轮关闭了 NEMU full Ubuntu 22.04 PyLong/int transient blocker [76] 的根因：NEMU 维护了 `mstatus.FS=Dirty`，但 CSR 读 `mstatus/sstatus` 时没有暴露只读派生位 `SD`。Linux RISC-V FPU 切换路径用 `regs->status & SR_SD` 判断是否需要保存浮点状态，因此用户态在 libm `log(10)` 首次访问 `.rodata` 常量触发 page fault 后，FPR 没被保存/恢复，`fa0/ft3` 被清零或污染，最终让 CPython `PyLong_FromString` 写入坏的转换常量并生成 `ob_size=0x8000000000000001`。

已修复为：`mstatus/sstatus` 读值按 `FS=Dirty` 派生 `SD`，但不把 `SD` 写回可写 CSR 状态。

## 关键证据

- `evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-libm-log-1/console.log`：修复前同一 `log(10)` 路径中，`fcvt.d.w ft3,a1` 后 `c.fld fa2,0(a3)` 触发首次常量页 fault，返回用户态后 `ft3/fa0` 被清零，`log(10)` 返回错误值。
- `evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpcalc-1/console.log`：CPython `PyLong_FromString` 中 `log@plt` 返回 `-inf` 后，`fsd fa5,0(s2)` 把 `0xfff0000000000000` 写到转换表，后续 `fcvt.l.d` 得到 `INT64_MIN`，导致坏 `ob_size`。
- 本地 Linux 源码 `Linux/env/src/linux/arch/riscv/include/asm/switch_to.h` 使用 `regs->status & SR_SD` 决定 FPU 保存；`csr.h` 中 RV64 `SR_SD=0x8000000000000000`。

## 本轮改动

- `nemu/src/isa/riscv64/include/isa-def.h` 新增 `MSTATUS_SD`。
- `nemu/src/isa/riscv64/inst/csr.c` 新增 `csr_status_sd_bit()`、`csr_mstatus_read_value()`、`csr_sstatus_read_value()`，让 `mstatus/sstatus` 读值包含派生 `SD`。
- 保留并扩展默认关闭的诊断设施：FP load trace、vaddr/paddr value trace、pc-gpr FPR 字段、trace env summary，以及 `nemu-dev` e2e 静态合同。

## 验证

- `bash -n Linux/scripts/check-nemu-python-int-preflight.sh scripts/e2e/modules/nemu.sh .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/run-target-range-trace-dual.sh` PASS。
- `make -C nemu NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu -j2` PASS。
- `scripts/agent-e2e.sh --profile nemu-dev --task-slug 2026-06-21-nemu-status-sd-csr-contract --stop-on-fail` PASS。
- 重型根因复跑 `evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-libm-log-sd-fix-1/` PASS：`python-int-preflight-summary.tsv` 为 `status=pass`，6 个 stage rc 均为 0；`pc=0x3ff7f8dd06` 后 `ft3=0x1.8p+1` 保持，`pc=0x3ff7f8dd5e` 后 `fa0=0x1.26bb1bbb55516p+1`。
- 默认重型复跑 `evidence/aslr-off-full-lite-int10-create-target-range-dual-sd-fix-default-1/` PASS：summary `status=pass`，6 个 stage rc 均为 0；负向检索没有 `ERROR_STATE`、`OverflowError`、`ValueError` 或坏 `ob_size=0x8000000000000001`。

## 边界

这次关闭的是 [76] PyLong/int transient 根因，不等于完整 Ubuntu 22.04 总目标已经完成。后续仍需在完整 full gate 上继续推进更广的 Ubuntu 2204 完整性、性能与 agent/e2e/DB 联动。
