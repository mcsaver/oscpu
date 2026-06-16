# Task Report

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-focused-gate
- `trace_id`: manual:nemu-python-int-focused-gate
- `task_slug`: nemu-python-int-focused-gate
- `graph_template`: hardware-aware-software-loop + modular-agent-e2e
- `profile`: NEMU-only focused gate
- `status`: PASS
- `owner`: nemu + agent-system
- `started_at`: 2026-06-16
- `updated_at`: 2026-06-16

## 任务目标

- 为 NEMU full Ubuntu 22.04 的 PyLong/int transient blocker 增加更短的 focused gate。
- 该 gate 使用 full rootfs、NEMU performance config、独立 overlay 和小型 guest Python probe，只验证 PyLong/int preflight，不替代 `nemu-dev-full-gate`。

## 改动摘要

- 新增 `Linux/tools/nemu-python-int-preflight.py`，保留历史 PyLong marker，并支持 `--tag focused --loops N`。
- 新增 `Linux/scripts/check-nemu-python-int-preflight.sh`，从 full rootfs 启动到 root shell 后上传小 probe、校验 SHA/bytes、执行 preflight 并输出 `__NEMU_PYTHON_INT_PREFLIGHT_DONE__ rc=0`。
- 新增 `make -C Linux ARCH=riscv64-nemu check-nemu-python-int-preflight`，默认 full rootfs + 独立 overlay，runtime fast-path env 仍可透传。
- `scripts/e2e/modules/nemu.sh` 已把新脚本、probe、Make target 和关键 marker 纳入 NEMU Ubuntu static/slice contract。

## 验证

- `bash -n Linux/scripts/check-nemu-python-int-preflight.sh scripts/e2e/modules/nemu.sh` PASS。
- `python3 -m py_compile Linux/tools/nemu-python-int-preflight.py` PASS。
- `make -C Linux ARCH=riscv64-nemu check-nemu-python-int-preflight -n` PASS，展开为 full rootfs、新 focused 脚本和独立 overlay。
- 真实 focused run PASS：
  - `NEMU_PYTHON_INT_CHECK_LOG_DIR=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-nemu-python-int-focused-gate/evidence/nemu-python-int-preflight`
  - `NEMU_PYTHON_INT_LOOPS=1`
  - `NEMU_PYTHON_INT_POWEROFF=0`
  - `NEMU_PYTHON_INT_CHECK_MAX_CYCLES=20000000000`
  - `make -C Linux ARCH=riscv64-nemu check-nemu-python-int-preflight`
- 真实 run 结果：boot_seconds=73，total_seconds=103，probe bytes=3080，SHA256 命中，`__NEMU_CHECK_PASS__:python-int-preflight-focused-loop`，`__NEMU_PYTHON_INT_PREFLIGHT_DONE__ rc=0`。
- `scripts/agent-e2e.sh --profile nemu-ubuntu-profile --task-slug 2026-06-16-nemu-python-int-focused-contract-rerun --stop-on-fail` PASS，证明 agent/e2e 合同识别新 focused gate。

## 边界

- 本切片没有定位 PyLong transient 的根因，也没有关闭 known issue [76]。
- 本切片没有证明完整 Ubuntu login/full hard gate 完成。
- 下一步应使用该 focused gate 对 `NEMU_INTERPRETER_WIDE_IFETCH=0`、`NEMU_VADDR_HOST_FAST=0`、`NEMU_RISCV_MMU_TLB=0` 等慢速/fast-path 切分做更低成本 A/B。
