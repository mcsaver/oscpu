# Task Report

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-summary-default-3loop
- `profile`: manual NEMU-only focused gate
- `scope`: NEMU PyLong/int focused gate evidence-summary hook verification
- `status`: completed
- `started_at`: 2026-06-16

## 目标

验证 `check-nemu-python-int-preflight.sh` 新增的 `python-int-preflight-summary.tsv` 会在真实 focused gate 中落盘，记录 runtime flags、loops、probe hash、done line、boot seconds 和 total seconds，避免后续 A/B 只依赖外层 make stdout。

## 配置

- `NEMU_PYTHON_INT_LOOPS=3`
- `NEMU_PYTHON_INT_CHECK_MAX_CYCLES=60000000000`
- `NEMU_PYTHON_INT_POWEROFF=0`
- `runtime.wide_ifetch=1`
- `runtime.decode_cache=1`
- `runtime.vaddr_host_fast=1`
- `runtime.mmu_tlb=1`

## 结果

- full rootfs readiness PASS。
- NEMU performance config PASS。
- Linux kernel config PASS。
- 3 轮 focused PyLong/int preflight 均 rc=0。
- `python-int-preflight-summary.tsv` 真实生成，含 `status	pass`、`done_line	__NEMU_PYTHON_INT_PREFLIGHT_DONE__ rc=0`、`boot_seconds	69`、`total_seconds	101`。

## 边界

这是 focused gate 证据链可观测性增强，不改变 NEMU 执行语义；它不关闭 [76] PyLong transient root cause，也不代表完整 Ubuntu full hard gate 完成。

