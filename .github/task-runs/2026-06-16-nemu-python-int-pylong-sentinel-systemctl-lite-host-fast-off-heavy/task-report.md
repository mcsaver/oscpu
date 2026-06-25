# Task Report

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-pylong-sentinel-systemctl-lite-host-fast-off-heavy
- `trace_id`: manual:nemu-python-int-pylong-sentinel-systemctl-lite-host-fast-off-heavy
- `graph_template`: hardware-aware-software-loop + rv64-ubuntu-probe-loop
- `profile`: NEMU-only direct heavy run
- `status`: completed
- `owner`: nemu + agent-system
- `started_at`: 2026-06-16 16:16 +0800
- `updated_at`: 2026-06-16 16:26 +0800

## 任务目标

- 在已加入 CPython `PyLongObject` sentinel 后，复跑上一轮最有价值的失败条件：`systemctl-lite` + `NEMU_VADDR_HOST_FAST=0`。
- 保持 NEMU-only 路线，不切 NPC、不从备份读取结论；NPC 活跃长跑不清理，只把 wall time 作为受干扰环境参考。

## 配置

- `NEMU_VADDR_HOST_FAST=0`
- `NEMU_PYTHON_INT_STAGE_MODE=systemctl-lite`
- `NEMU_PYTHON_INT_LOOPS=10`
- `NEMU_PYTHON_INT_CHECK_MAX_CYCLES=320000000000`
- `NEMU_PYTHON_INT_CHECK_TIMEOUT=9000`
- `NEMU_PYTHON_INT_BOOT_TIMEOUT=3600`
- `NEMU_PYTHON_INT_POWEROFF=0`
- rootfs: `Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4`
- overlay: `evidence/nemu-python-int-systemctl-lite-host-fast-off-heavy/rootfs-overlay.raw`

## 结果

- `run.rc`: 0
- `python-int-preflight-summary.tsv`: `status	pass`
- stage rc:
  - `before-runtime`: 0
  - `runtime-after-core-tools`: 0
  - `runtime-after-systemd-files`: 0
  - `runtime-after-systemctl-daemon-reload`: 0
  - `runtime-after-systemctl-root-enable`: 0
  - `runtime-after-systemctl-runtime-start`: 0
  - `runtime-after-systemctl`: 0
  - `after-runtime`: 0
- runtime flags: `wide_ifetch=1 decode_cache=1 vaddr_host_fast=0 mmu_tlb=1`
- time: `boot_seconds=197 total_seconds=566`

## PyLong Sentinel 证据

- guest marker 显示 `PYLONG_LAYOUT_AVAILABLE:1`、`PYLONG_LAYOUT_MODE:legacy`，符合 Ubuntu 22.04 guest Python 3.10 的 legacy PyVarObject 布局。
- 各 stage 均可见 `PYLONG_CONST_TWO_OB_SIZE:1`、`PYLONG_CONST_U32_MAX_OB_DIGIT1:3`、`PYLONG_VALUE_2_LAYOUT_OK:1`、`PYLONG_INT_FROM_BYTES_BYTES_LAYOUT_OK:1`。
- 负向扫描未见 `PYLONG_*_MISMATCH`、`PYLONG_*_ERROR`、`Traceback`、`OverflowError`、`ValueError`、`AssertionError`。

## 结论

- PyLongObject sentinel 已在真实 NEMU full rootfs guest 中工作，可提供 legacy CPython int 对象头/digit 级证据。
- 本次同口径 `NEMU_VADDR_HOST_FAST=0` heavy rerun 未复现上一轮 `runtime-after-systemctl` 的 datetime/PyLong transient；这说明 [76] 仍是低概率 transient，不能关闭，也不能把 host-fast-off 写成已排除。
- 下一步应继续重复 `systemctl-lite` host-fast-off/wide-ifetch-off A/B，或增加更贴近失败点的内存/对象 sentinel。

## 证据

- `run-heavy.sh`
- `evidence/nemu-python-int-systemctl-lite-host-fast-off-heavy/run.log`
- `evidence/nemu-python-int-systemctl-lite-host-fast-off-heavy/run.rc`
- `evidence/nemu-python-int-systemctl-lite-host-fast-off-heavy/python-int-preflight-summary.tsv`
- `evidence/nemu-python-int-systemctl-lite-host-fast-off-heavy/console.log`
- `evidence/nemu-python-int-systemctl-lite-host-fast-off-heavy/nemu.log`
