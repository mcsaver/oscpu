# Task Report

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-default-3loop-focused
- `profile`: manual NEMU-only focused gate
- `scope`: NEMU full Ubuntu 22.04 PyLong/int focused baseline
- `status`: completed
- `started_at`: 2026-06-16

## 目标

用新接入的 `check-nemu-python-int-preflight` 在默认 fast path 全开配置下跑 3 轮 PyLong/int preflight，作为后续 wide-ifetch/host-fast A/B 的同口径 baseline。

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
- probe bytes `3080`，sha256 `7c8b760d606d3e56671d30b2f502c0b23a1eff6a7d9bed834b3954e4ac9601e8`。
- 3 轮 `__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__:focused:N:0` 全部 PASS。
- `__NEMU_PYTHON_INT_PREFLIGHT_DONE__ rc=0`。
- 外层记录 `boot_seconds=69 total_seconds=101`。

## 边界

本 run 只证明默认 focused gate 在 3-loop 压力下未复现 PyLong/int corruption。由于 [76] 是 transient blocker，本 run 不能单独证明默认 fast path 无问题，也不能声明完整 Ubuntu full gate 或 PyLong 根因已闭合。

