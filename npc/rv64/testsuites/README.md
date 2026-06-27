# NPC RV64 Testsuites

这个目录专门放 `npc/rv64` 核级外部测试套件、测试工具链和可重复脚本，避免把 CPU 测试资产混到 `.github` 或 RTL 目录里。

## Layout

- `scripts/`: NPC RV64 核级测试脚本入口。
- `core-tests/`: 本地外部测试资产与生成物，包含 `riscv-tests`、ACT4/riscv-arch-test、Sail reference model、xPack GCC、ACT4 workdir 等。该目录默认被 Git 忽略，只保留 `.gitkeep`。

## 常用命令

```bash
npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --riscv-tests --quick
npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh
npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh --probe-elfs --extensions I
npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh --final-elfs --extensions I
npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh --final-elfs --extensions M \
  --workdir npc/rv64/testsuites/core-tests/act4-npc-final-work-script
npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh --final-elfs --extensions Sv \
  --workdir npc/rv64/testsuites/core-tests/act4-npc-final-work-script
npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --list-suites
npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --filter 'I-(add|addi|sub)-00' --limit 3
npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --suites rv64i/I,rv64i/M
npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --suites priv/Sv --limit 5
```

ACT4 的 `build/.../*.sig.elf` 是参考模型生成 signature 用的中间 ELF；给 NPC 执行时应使用 `elfs/.../*.elf` final self-checking ELF。
当前 ACT4 checkout 的 RV64 final ELF suite 目录按实际生成路径选择，例如 `rv64i/I`、`rv64i/M`；不确定时先用 `--list-suites` 查看。
`npc-rv64-act4-preflight.sh --workdir` 支持绝对路径或相对仓库根目录的路径；测试资产仍统一落在 `npc/rv64/testsuites/core-tests/`，不要放到 `.github`。
当前本地 ACT4 checkout 的 unprivileged final ELF 目录只有 `rv64i/I` 和 `rv64i/M`；`C`/`A` extension 生成命令可能返回 0 但不产出可执行 suite，记录时应区分“测试资产未覆盖”和“RTL 执行失败”。
`Sv` privileged suite 当前可生成 `priv/Sv` final ELF；已有 smoke 3/5 PASS，但 canonical S/U timeout 未闭合，不能把 `priv/Sv` 当作完整通过。
