# Task Report

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-host-fast-off-focused
- `profile`: manual NEMU-only focused gate
- `scope`: NEMU full Ubuntu 22.04 PyLong/int focused A/B
- `status`: completed
- `started_at`: 2026-06-16

## 目标

在 `NEMU_VADDR_HOST_FAST=0` 下运行 3 轮 focused PyLong/int preflight，检查关闭 host-fast vaddr path 后是否仍能跑通，并为 [76] 的 fast-path 切分矩阵提供证据。

## 配置

- `NEMU_VADDR_HOST_FAST=0`
- `NEMU_PYTHON_INT_LOOPS=3`
- `NEMU_PYTHON_INT_CHECK_MAX_CYCLES=60000000000`
- `NEMU_PYTHON_INT_POWEROFF=0`
- `runtime.wide_ifetch=1`
- `runtime.decode_cache=1`
- `runtime.vaddr_host_fast=0`
- `runtime.mmu_tlb=1`

## 结果

- full rootfs readiness PASS。
- NEMU performance config PASS。
- Linux kernel config PASS。
- probe bytes `3080`，sha256 `7c8b760d606d3e56671d30b2f502c0b23a1eff6a7d9bed834b3954e4ac9601e8`。
- 3 轮 `__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__:focused:N:0` 全部 PASS。
- `__NEMU_PYTHON_INT_PREFLIGHT_DONE__ rc=0`。
- 外层记录 `boot_seconds=207 total_seconds=297`。

## 边界

本 run 说明关闭 host-fast vaddr path 的 slow path 在 3-loop focused gate 下可用，且没有复现 PyLong/int corruption。但默认同口径 baseline 也 PASS，因此不能把 host-fast 排除为 [76] 根因；后续需要提高 reproducer 触发率或更接近 full hard gate 的触发时序。

