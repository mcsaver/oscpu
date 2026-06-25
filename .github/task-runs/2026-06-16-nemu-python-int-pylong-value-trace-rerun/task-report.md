# Task Report: NEMU PyLong paddr snapshot/value trace

- **日期**: 2026-06-16
- **场景**: NEMU-only full Ubuntu 22.04 PyLong/int blocker [76]
- **profile/入口**: `nemu-dev` 静态合同 + direct `check-nemu-python-int-preflight`
- **结论**: 本切片没有修复 NEMU 功能根因，但修复了诊断链两个关键缺口，并把问题从“Python 读错或对象头坏”推进到“坏 PyLong `ob_size` 在 marker arm 时已经存在于 PMEM”。

## 变更摘要

- NEMU paddr trace 增加 arm/disarm 快照：`paddr-write-trace snapshot ... bytes=...`，直接从 PMEM 读取目标物理地址，区分真实内存损坏与 guest load/read 错误。
- NEMU 增加默认关闭的 value trace：由 serial preparse marker 动态 arm，记录匹配 `value/mask` 的 PMEM/DMA 写入，后续用于抓未知地址对象创建阶段的坏值写源。
- Python PyLong probe 将 stdout 设置为 line-buffer/write-through，避免 traceback 走 stderr 先于关键 serial marker 到达，修复 marker arm 晚于危险操作的诊断 bug。
- Python PyLong probe 在 `argparse.parse_args()` 前先输出小整数 `10` 的 paddr marker，并记录 `ARGS_LOOPS_PREPARSE_ID_MATCH`，用于判断 `args.loops` 是否来自同一个 CPython 小整数对象。
- `scripts/e2e/modules/nemu.sh` 已加入 paddr snapshot、value trace、preparse marker 和 stdout write-through 静态合同。

## 关键证据

- `.github/task-runs/2026-06-16-nemu-python-int-pylong-paddr-trace-no-prewarm/`：关闭 prewarm 后仍 FAIL，`runtime-after-identity` 复现 `ob_size=-9223372036854775807`，说明不是 stdlib prewarm 噪声。
- `.github/task-runs/2026-06-16-nemu-python-int-pylong-paddr-trace-snapshot-rerun/`：失败 stage 的 paddr snapshot 在 arm 时即为 `bytes=0100000000000080`，正常 stage 为 `0100000000000000`；同 stage vaddr/paddr 写 trace count 为 0，说明坏值早于当前 marker。
- `.github/task-runs/2026-06-16-nemu-python-int-pylong-preparse-flush-paddr-trace-rerun-2/`：stdout flush 后仍 FAIL；preparse 小整数 `10` 正常，但失败 stage `ARGS_LOOPS_PREPARSE_ID_MATCH=0`，`argparse` 返回另一个坏 `int` 对象，snapshot 为 `0x8000000000000001`。
- `.github/task-runs/2026-06-16-nemu-python-int-pylong-value-trace-rerun/`：full-word `0x8000000000000001` value trace 在失败 stage count=0，但坏对象 snapshot 仍为 `0100000000000080`；说明不是普通 8-byte 坏值 store，或写入早于 value trace arm。
- `.github/task-runs/2026-06-16-nemu-python-int-pylong-value-byte-trace-rerun/`：byte `0x80` value trace PASS 样本，trace arm/disarm 可用且 count=0。

## 验证

- `python3 -m py_compile Linux/tools/nemu-python-int-preflight.py` PASS
- `bash -n scripts/e2e/modules/nemu.sh scripts/agent-e2e.sh Linux/scripts/check-nemu-python-int-preflight.sh` PASS
- `make -C nemu NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu -j2` PASS
- `scripts/agent-e2e.sh --profile nemu-dev --task-slug 2026-06-16-nemu-pylong-value-trace-contract --stop-on-fail` PASS
- 关键 heavy evidence 已 `index-evidence --write-index --yes` 并生成 stored `evidence-index.md`

## 下一步

- 继续追 `int('10')`/PyLong 创建路径：当前证据显示失败时 `args.loops` 不是 preparse 小整数，而是一个新坏对象。
- 若继续用 value trace，优先让 trace 在 `argparse`/`int()` 转换之前动态开启，并尝试更细的字节/半字/高地址偏移匹配；也可构造不用 argparse 的 `int("10")` focused stage，缩短对象创建窗口。
- 完整 Ubuntu 22.04 hard gate 与 [76] 根因仍未关闭。
