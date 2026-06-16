# Task Report

## 基本信息

- `task_id`: `2026-05-19-riscv-nemu-imbc`
- `task_slug`: `riscv-nemu-imbc`
- `graph_template`: `rv32-reference-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-19 13:05 +0800`
- `updated_at`: `2026-05-19 14:34 +0800`

## 任务目标

- `source_request`: “帮我的 nemu 实现 imbc 拓展，并且添加真正的可编译选项，当我在 kconfig 中配置各种拓展的时候，nemu 中实现，编译器也同步实现控制”
- `goal`: 让 NEMU RV32 的 M/B/C 扩展由 Kconfig 控制，并让 AM guest 编译器同步使用同一组扩展配置。
- `scope`: NEMU RISC-V Kconfig/译码/取指/CSR 可见性，AM `riscv32{e}-nemu` 编译参数，Spike difftest ISA 字符串和验证记录。

## 选图说明

- `selected_template`: `rv32-reference-loop`
- `why_this_graph`: 本任务主闭环仍是 `am-kernels -> abstract-machine -> NEMU(reference)`，需要验证 guest 编译产物能在 NEMU 中运行。
- `dynamic_nodes_added`: `config-compiler-bridge`、`b-c-smoke`
- `why_dynamic_nodes_were_needed`: 原模板没有覆盖“Kconfig 变更必须触发 guest 重编”和“裸 B/C 指令 smoke”这两个配置链路风险。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `recall` | Codex | completed | `.github/AGENTS.md`、memory、NEMU/AM 构建文件 | 约束和调用链摘要 | 已读取相关 memory 与 Kconfig/Makefile/inst.c |
| `config-compiler-bridge` | Codex | completed | NEMU `auto.conf`、AM Makefile | `riscv-nemu-ext.mk`、`EXTRA_DEPS` | `readelf -A` 显示 `rv32i_m_zicsr`、`rv32i_zicsr`、`rv32i_m_c_zicsr_zba_zbb_zbc_zbs` |
| `nemu-imbc-impl` | Codex | completed | `RISCV_EXT_M/B/C` | RV32M/B/C 条件译码、C 可变长度取指 | `make -C nemu -j4` 通过 |
| `default-regression` | Codex | completed | 恢复后的默认本地配置 | `cpu-tests add` PASS | `HIT GOOD TRAP`，840 instructions |
| `m-disabled-smoke` | Codex | completed | 临时关闭 `RISCV_EXT_M` | `mul-longlong` 软件乘法 PASS | ELF 属性 `rv32i2p1_zicsr2p0`，`mul-longlong PASS` |
| `b-c-smoke` | Codex | completed | 临时开启 M+B+C，临时关闭 difftest 跑裸镜像 | 压缩取指 + Zba/Zbb/Zbc/Zbs smoke PASS | 裸镜像 137 instructions，`HIT GOOD TRAP` |
| `difftest-root-cause` | Codex | completed | 用户反馈“difftest 跑不过” | 定位 C 分支立即数错误和 Spike REF 构建缺 B 指令 | `leap-year/string` 复现为 C branch PC mismatch；`shuixianhua/bit` 复现为 REF illegal trap 到 PC 0 |
| `spike-ref-fix` | Codex | completed | `spike-diff` Makefile 与 PA Spike `riscv.mk` | 配置依赖、B 指令列表和并发重链修复 | `insn_list.h` 包含 `sh2add/bext/...`，`make -C spike-diff GUEST_ISA=riscv32` 不再重复重链 |
| `full-difftest-regression` | Codex | completed | M+B+C+DIFFTEST 配置 | cpu-tests 全量 PASS | `timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu run`，35/35 PASS |
| `record` | Codex | completed | 验证结果 | memory 与本报告 | memory 已追加 |

## 关键产物

- `artifacts`: `nemu/src/isa/riscv32/inst.c`、`nemu/src/isa/riscv32/Kconfig`、`abstract-machine/scripts/isa/riscv-nemu-ext.mk`
- `logs_or_traces`: 终端验证输出；`am-kernels/tests/cpu-tests/build/nemu-log.txt`
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/{nemu,abstract-machine,am-kernels}.md`

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 无
- `risk_assessment`: B 扩展按 GCC 13 ratified 子扩展名 `Zba/Zbb/Zbc/Zbs` 实现；裸 `-march=rv32imb` 在本机 GCC 会报“cannot find default versions”，因此没有使用裸 `b`。Spike REF 侧现已把 PA 默认排除的 B 指令列表加回构建，后续若清理 `repo/build`，Makefile 会重新打补丁并重建。

## 下一步建议

1. 后续若要把 `RISCV_EXT_B` 拆成单独的 `Zba/Zbb/Zbc/Zbs` 细粒度 Kconfig，可在当前表项上继续拆分。
2. 若长期启用 difftest 跑裸镜像，需要补一条原始镜像的 REF PC 初始化路径；本轮 AM 程序 difftest 已可正常运行。

## 模板升级候选

- `repeated_dynamic_subgraph`: Kconfig -> guest compiler flags -> AM rebuild dependency
- `should_promote_to_static_template`: `false`
- `reason`: 当前是一次性扩展配置桥接，不足以形成独立静态模板。

## 收尾结论

- `final_result`: 已完成 NEMU RV32 M/B/C 可配置实现与 AM guest 编译器同步控制；后续用户反馈的 M+B+C Spike difftest 失败也已修复。
- `evidence_summary`: 默认配置 NEMU 构建与 `add` PASS；M 关闭 `mul-longlong` PASS；M+B+C 开启 `add` PASS 且 ELF 属性正确；B/C 裸 smoke `HIT GOOD TRAP`；difftest 修复后 `leap-year/string/shuixianhua/bit/mul-longlong` PASS，`M+B+C+DIFFTEST` 下 cpu-tests 35/35 PASS。
- `notes`: 裸 smoke 仍适合在关闭 difftest 时验证 NEMU 本体；AM 程序的 Spike difftest 路径已在全量 cpu-tests 中通过。
