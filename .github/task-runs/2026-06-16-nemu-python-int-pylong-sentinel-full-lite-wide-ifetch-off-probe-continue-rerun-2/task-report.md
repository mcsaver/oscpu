# Task Report

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-probe-continue-rerun-2
- `trace_id`: manual:nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-probe-continue-rerun-2
- `profile`: nemu-dev / manual heavy focused reproducer
- `status`: completed-fail-diagnostic
- `owner`: nemu + agent-system

## 任务目标

- 继续用 `full-lite + NEMU_INTERPRETER_WIDE_IFETCH=0` 重型 focused reproducer 采样 [76]。
- 验证 runner 在 prewarm 之后能把 probe rc 和 PyLong error-state 证据稳定带回 console。
- 不从旧备份取答案，直接以当前 NEMU/Ubuntu 运行现场定位 root cause。

## 配置

- full Ubuntu 22.04 rootfs，独立 overlay: `evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-continue-rerun-2/rootfs-overlay.raw`
- `NEMU_INTERPRETER_WIDE_IFETCH=0`
- `NEMU_PYTHON_INT_STAGE_MODE=full-lite`
- `NEMU_PYTHON_INT_LOOPS=10`
- `NEMU_PYTHON_INT_CHECK_MAX_CYCLES=320000000000`
- `NEMU_PYTHON_INT_CHECK_TIMEOUT=9000`
- `NEMU_PYTHON_INT_BOOT_TIMEOUT=3600`
- `NEMU_PYTHON_INT_POWEROFF=0`

## 结果

- `run.rc`: 2
- summary: `status=fail`
- done marker: `__NEMU_PYTHON_INT_PREFLIGHT_DONE__ rc=1`
- runtime flags: `wide_ifetch=0 decode_cache=1 vaddr_host_fast=1 mmu_tlb=1`
- stage results:
  - `before-runtime`: 0
  - `runtime-after-core-tools`: 0
  - `runtime-after-identity`: 0
  - `runtime-after-systemd-files`: 0
  - `runtime-after-journal`: 1
  - `after-runtime`: 1
- timing: boot 136s, total 352s

## 关键证据

- 前四个 stage 中 `args.loops` 正常：`TYPE=int`、`REPR=10`、`BIT_LENGTH=4`、`PLUS_ONE=11`。
- `runtime-after-journal` 开始，`args.loops` 进入异常状态：
  - `__PYTHON_INT_PREFLIGHT_ARGS_LOOPS_REPR_ERROR__`: `ValueError: Exceeds the limit (4300) for integer string conversion`
  - `__PYTHON_INT_PREFLIGHT_ARGS_LOOPS_BIT_LENGTH__`: `276701161105643274181`
  - `__PYTHON_INT_PREFLIGHT_ARGS_LOOPS_PLUS_ONE_ERROR__`: `OverflowError: too many digits in integer`
  - `__PYTHON_INT_PREFLIGHT_ARGS_LOOPS_MAX_REASONABLE_BIT_LENGTH__`: `63`
- PyLongObject error-state 指向对象头部异常，而不是 Python 脚本或命令行参数字符串本身异常：
  - `TYPE=int`
  - `REFCOUNT=5`
  - `TYPE_PTR` 等于 `INT_TYPE_PTR`
  - `TYPE_MATCH=1`
  - `OB_SIZE=-9223372036854775807`
  - `OB_DIGIT0=10`
  - `OB_DIGIT1=3`
  - `OB_DIGIT2=1`
  - `OB_DIGIT3=0`
- `after-runtime` 复现同样形态：`OB_SIZE=-9223372036854775807`，`OB_DIGIT0=10`，`TYPE_PTR == INT_TYPE_PTR`。
- `__NEMU_PYTHON_INT_STAGE_PROBE_RC__` 已在 console 可见：
  - `runtime-after-journal:1`
  - `after-runtime:1`

## 解释

- 这次证据把 [76] 从“Python int 转换偶发报错”收窄为 `PyLongObject` 头部字段损坏。
- `args.loops` 的 `ob_digit[0]` 仍保留原始值 `10`，类型指针仍匹配 `int`，refcount 也为正；异常集中在 `ob_size` 变成极端负数，进而让 CPython 把一个小整数当成超大负数处理。
- `__PYTHON_INT_PREFLIGHT_PYLONG_ARGS_LOOPS_ERROR_STATE_OK__:1` 不能解释为对象完全正常；该 error-state 路径没有传入 expected size，只表示布局可读且 type/refcount 检查通过。

## 后续方向

- 下一步应追踪 guest 内该 PyLongObject 地址附近的写入来源，尤其是 `ob_size` 所在字节。
- 优先考虑在 NEMU 侧加轻量定向 watch/trace：记录 guest store 写入 PyLongObject header 页或对象地址范围时的 PC、指令、权限状态和地址翻译结果。
- 不再重复泛泛 A/B；现有证据已把排查方向推进到对象头写坏或等价的访存/执行正确性问题。
