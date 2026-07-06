# tool/ — 工作区级通用工具

存放贯穿多个子工程（`npc/*`、`nemu`、`Linux` … 不限这三个）复用的通用工具，
**不隶属任何单一工程**（避免"通用工具寄生在某个 consumer 里、别人反向依赖它"的耦合）。

## 当前工具
- `kconfig/` — Linux 风格 Kconfig 配置系统（`conf`/`mconf`）。原在 `nemu/tools/kconfig`，
  2026-07-06 迁出通用化（6+ 工程共用它）。
- `fixdep/` — Kconfig 配套依赖处理工具（自动生成/修正依赖文件）。

## 定位约定（YSYX_HOME）
各工程用工作区根变量 `YSYX_HOME` 定位本目录：`$(YSYX_HOME)/tool/<工具>`。
`YSYX_HOME` 由各工程按自身位置 `?=` default（如 `npc/rv64` = `$(abspath ../..)`、
`Linux` = `$(REPO_ROOT)`），**独立于 `NEMU_HOME`**——不使用 nemu 的工程只需设 `YSYX_HOME`
即可复用这些工具，不必借道 nemu。可被 env 或上层 make 覆盖。

⚠ Makefile 变量赋值**勿用行内注释**（`VAR ?= val   # ...`）——`#` 前的空格会并入变量值、污染路径；
注释另起一行。
