# Task Report

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-probe-loops-byte-trace-rerun
- `profile`: NEMU-only focused heavy diagnostics
- `scope`: NEMU full Ubuntu 22.04 PyLong/int blocker [76]
- `status`: fail-diagnostic + instrumentation advanced
- `updated_at`: 2026-06-21

## 任务目标

继续定位 NEMU full Ubuntu 22.04 中 guest CPython `PyLongObject.ob_size`
偶发损坏来源，避免把 DB doctor 的历史 manual log/旧 shim 噪声误当成本轮 blocker。

## 实现改动

- `Linux/tools/nemu-python-int-preflight.py`
  - 新增 `validate_loop_count()`，在进入 `range()` 之前输出 loop-count 对象的
    `repr/bit_length/plus_one`、PyLong layout 和 paddr marker。
  - `int10-create` 模式新增 `PROBE_LOOPS_*` marker，避免 `range(1, loops + 1)`
    直接抛 `OverflowError` 而丢掉对象头证据。
  - 新增 literal `20` 的 `PYLONG_PROBE_LOOPS_PREPARSE_*` canary，用来区分
    small-int 单例已坏，还是 `int("20")` 返回的新对象坏。
- `nemu/src/memory/vaddr.c`、`nemu/include/memory/vaddr.h`、`nemu/src/device/serial.c`
  - 新增默认关闭的 `vaddr-write-value-trace`，由 serial value marker 同时 arm/disarm。
  - 该 trace 覆盖 host-fast CPU store，弥补 paddr value trace 看不到
    `vaddr_paddr_write_fast()->host_write()` 的盲点。
  - value trace 按 `user_only` 过滤，避免 S-mode kernel 栈写入淹没 CPython 证据。
- `Linux/scripts/check-nemu-python-int-preflight.sh`
  - summary 增加 `runtime.vaddr_write_value_trace`。
- `Linux/tools/nemu-python-int-trace-correlate.py`
  - 新增 console 关联工具，把失败对象的 `PYLONG_*_OB_SIZE_{VADDR,PADDR}`
    marker 与 `vaddr-write-value-trace` 命中自动对齐。
  - parser 支持 marker 被旧日志 interleave 污染的历史样本，并在 corrupt
    `ob_size` 出现时立即抓取当前 stage 的 marker 快照，避免被后续 stage 覆盖。
- `nemu/src/device/serial.c`
  - 修复 serial marker 处理顺序：先完整写出 guest 串口文本，再处理 marker
    和 NEMU Log，避免 trace 日志插入 Python marker 行导致 parser/evidence 失真。
- `scripts/e2e/modules/nemu.sh`
  - 固化 `PROBE_LOOPS`、preparse canary、vaddr value trace、trace correlate
    和 serial-marker hygiene 合同。

## 关键证据

- `evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-loops-byte-trace-rerun/`
  - FAIL，`runtime-after-core-tools` stage rc=1。
  - `PROBE_LOOPS_TYPE=int`，`ob_digit0=20`，但
    `PYLONG_PROBE_LOOPS_ERROR_STATE_OB_SIZE=-9223372036854775807`。
  - paddr arm snapshot 显示失败对象 `bytes=0100000000000080`。
- `evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-loops-preparse-byte-trace-rerun/`
  - FAIL，`before-runtime` 与 `runtime-after-identity` stage rc=1。
  - preparse literal `20` 的 paddr snapshot 正常：`bytes=0100000000000000`。
  - 失败 stage `PROBE_LOOPS_PREPARSE_ID_MATCH=0`，说明坏对象不是 literal small-int
    `20` 本体，而是随后 `int("20")` 返回/创建的另一个 PyLong 对象。
- `evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-loops-vaddr-value-trace-rerun/`
  - PASS，验证 vaddr value trace 接线可运行；初版未过滤 S-mode，噪声过大。
- `evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-loops-vaddr-value-user-trace-rerun/`
  - PASS，验证 user-only value trace 可运行，summary 含
    `runtime.vaddr_write_value_trace=1`。
- `evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-loops-vaddr-value-exact-trace-rerun/`
  - PASS，精确 `0x8000000000000001` trace 可运行。
  - 本 PASS 样本有 20 条用户态 exact store 命中，但没有 PyLong failure；
    后续需要失败样本对比这些 store 是否命中失败对象地址。
- `evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-loops-vaddr-value-exact-trace-rerun-2/`
  - PASS，6 个 stage rc=0，`runtime.vaddr_write_value_trace=1`，boot 144s、
    total 277s。
  - `trace-correlate.log` 显示 `TARGETS=0`、`VALUE_HITS=2`、`TARGET_HITS=0`，
    说明 exact trace 接线可用但该样本未复现。
- `evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-loops-vaddr-value-byte-trace-rerun-2/`
  - FAIL，`runtime-after-identity` stage rc=1，`PROBE_LOOPS` 再次复现
    `ob_size=-9223372036854775807`。
  - 修正后的 `trace-correlate.log` 显示失败对象
    `id=0x3f89dfc4d0`、`ob_size vaddr=0x3f89dfc4e0`、
    `paddr=0x857e84e0`，`VALUE_HITS=12217`，但 `TARGET_HITS=0`。
  - 这说明从 preparse marker 到失败点，用户态含 `0x80` 的 value trace
    没有覆盖失败对象 `ob_size` 字段；当前更偏向“对象复用/初始化留下旧高位”
    或等价窄写/未全宽初始化，而不是显式 `0x80` store 打到该字段。

## 结论

本轮没有关闭 [76]，但把失败对象进一步收窄到：

- preparse literal small-int `20` 可正常；
- 失败来自 `int("20")` 返回/创建的 PyLong 对象；
- 该对象 `type/refcount/digit0` 正常，`ob_size` 高字节坏成
  `0x8000000000000001`；
- 旧 paddr value trace 存在 host-fast 盲点，已通过 vaddr value trace 修复。
- byte value trace 的失败样本没有命中失败对象地址，因此当前不应把 root cause
  简化成“某条用户态 store 显式写入 0x80 到 ob_size”；下一步应追对象分配前
  旧字节来源、`PyLong_FromString/int("20")` 初始化宽度，或用 ASLR 固定地址提前
  arm 目标 range。
- 旧 serial marker 顺序会把 NEMU trace 日志插入 Python marker 行，已修为先输出
  guest 文本再处理 marker；后续新证据应不再出现 marker 行 interleave。

下一步建议使用 `NEMU_PYTHON_INT_DISABLE_ASLR=1` 校准失败对象地址稳定性；
若地址可复用，则在对象创建前用 `NEMU_VADDR_WRITE_TRACE_START/END` 提前 arm
该 `ob_size` range，直接观察初始化写宽度和旧字节来源。
