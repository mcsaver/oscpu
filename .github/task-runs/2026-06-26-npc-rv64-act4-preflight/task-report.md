# NPC RV64 ACT4 Preflight

## 背景

目标是把 `npc/rv64` 从 `riscv-tests` 进一步推进到官方 RISC-V Architecture Tests / ACT4。用户要求当前先完善核本身，不直接跑完整 Linux/rootfs；同时要求测试相关资产放在 `npc` 目录下，不再放到 `.github`。

## 完成内容

- 将外部测试资产从 `.github/runtime-artifacts/npc-rv64-core-tests/` 迁到 `npc/rv64/testsuites/core-tests/`。
- 将测试脚本入口迁到 `npc/rv64/testsuites/scripts/`。
- `make -C npc/rv64 core-regress` 改为调用 `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh`。
- 新增 `npc/rv64/testsuites/README.md`，说明外部 testsuite layout。
- `.gitignore` 忽略 `npc/rv64/testsuites/core-tests/**`，仅保留 `.gitkeep`。
- `npc-rv64-act4-preflight.sh` 支持 `--final-elfs`，用于生成给 DUT/NPC 执行的 `elfs/.../*.elf` final self-checking ELF。
- 明确区分 ACT4 `build/.../*.sig.elf` 和 `elfs/.../*.elf`：前者是 reference signature 中间 ELF，后者才是给 NPC 跑的自检 ELF。

## 验证

- ACT4 runtime assets 已迁移到 `npc/rv64/testsuites/core-tests/`，目录大小约 2.5G。
- `npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh --probe-elfs --extensions I`: PASS，FAST 构建 `204 succeeded`。
- 非 FAST/final ELF 构建：PASS，`255 succeeded`，生成 `npc/rv64/testsuites/core-tests/act4-npc-final-work-script/sail-rv64-max/elfs/rv64i/I/I-add-00.elf`。
- `I-add-00.elf` 的 `tohost` symbol 为 `0x0000000080039300`。
- `I-add-00.elf` 经 objcopy 转 bin 后用 NPC 执行：PASS，日志显示 `TOHOST PASS`，`value=0x0000000000000001`。

## 结论

ACT4 前置链路、GCC15 工具链、Ruby headers gate、RV64I final ELF 生成和一个 NPC DUT smoke 已接通。当前还不能声明 NPC 通过完整 Architecture Tests；下一步需要建立更精确的 NPC UDB config，并把 ACT4 RV64I/基础扩展从单项 smoke 扩展为批量执行与结果汇总。

## 边界

本轮没有运行完整 Linux/rootfs，也没有运行 ACT4 全矩阵。该结果不是完整工业级 CPU signoff。
