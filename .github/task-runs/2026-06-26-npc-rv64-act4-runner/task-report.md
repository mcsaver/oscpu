# NPC RV64 ACT4 Runner

## 背景

上一轮已经把 ACT4 final ELF 生成链路接到 `npc/rv64/testsuites/core-tests/`，并用 `I-add-00.elf` 做过单项 NPC smoke。本轮目标是把“手工单项执行”推进为可重复批量 runner，并开始收敛 ACT4 I/M 切片证据。

## 完成内容

- 新增 `npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh`。
- runner 支持：
  - `--build-final` 调用 ACT4 final ELF 生成。
  - `--build-npc` 构建 `npc/rv64` 仿真器。
  - `--list-suites` 列出实际生成的 final ELF suite 目录。
  - `--suites`、`--filter`、`--limit` 控制执行范围。
  - per-ELF `nm` 解析 `tohost`、`objcopy` 转 bin、`NpcSimTop --tohost=ADDR` 执行。
  - 输出 `summary.txt`、`status.txt`、逐项 bin/log 到 `npc/rv64/perf/results/act4-run/<stamp>/`。
- 更新 `npc/rv64/README.md` 与 `npc/rv64/testsuites/README.md`，记录 runner 用法和 `.sig.elf`/final `.elf` 边界。

## 验证

- `bash -n npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh`: PASS。
- `npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --list-suites`: PASS，I workdir 输出 `rv64i/I`。
- `npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --workdir .../act4-npc-final-work-m --list-suites`: PASS，M workdir 输出 `rv64i/M`。
- ACT4 RV64I final ELF runner：`51/51 PASS`。
  - Evidence: `npc/rv64/perf/results/act4-run/20260626-185425-396823/`
- ACT4 RV64M final ELF runner：`13/13 PASS`。
  - Evidence: `npc/rv64/perf/results/act4-run/20260626-185521-398710/`
- 探索 `--extensions A`：当前 ACT4 checkout 未生成普通 A final ELF，实际可见普通 RV64 suite 为 `rv64i/I` 与 `rv64i/M`；该项不记为 RTL failure。

## 结论

`npc/rv64` 已具备可重复 ACT4 final ELF 执行入口，并在当前 ACT4 checkout 的 RV64I/RV64M 普通 suite 上通过 NPC tohost 判定。该证据独立于官方 `riscv-tests`，增强了 core ISA 执行层面的交叉验证。

## 边界

这仍不是完整工业级 CPU signoff。尚未完成 NPC 精确 UDB profile、ACT4 全矩阵、F/D/C/A/Zb/privileged 扩展全覆盖、Linux/full-system gate、长稳、性能、形式验证、PPA/timing/CDC/reset/物理实现签核。
