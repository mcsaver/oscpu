# Task Report

## 基本信息

- `task_id`: `2026-05-20-npc-icache-combo-hit`
- `task_slug`: `npc-icache-combo-hit`
- `graph_template`: `custom`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-05-20`
- `updated_at`: `2026-05-20`

## 任务目标

- `source_request`: 用户要求分析并修改 NPC ICache 命中路径；hit 情况应组合送出，miss/fall 路径应在下一个周期立刻向 RAM 找数据。
- `goal`: 降低前端 ICache hit 与首 miss 的额外等待周期，提升 `make ARCH=riscv32-npc run mainargs=8` 这类长程序的仿真推进速度。
- `scope`: 仅修改 NPC core RTL 前端取指链路，不修改 AM 程序、benchmark、NEMU reference 或外部 DPI 总线协议。

## RTL 推导摘要

- `需求层`: ICache hit 不应经过 `S_LOOKUP -> S_RESP` 打拍；cacheable miss 在请求锁存后的下一拍应直接发起 line fill；uncached fetch 同理下一拍发起直通读。
- `协议层`: ICache CPU-side 仍保持 `req_valid/req_ready/rsp_valid`；允许 `req_fire` 与 `rsp_valid` 同拍出现。IfStage 必须能接住同拍返回，也要继续支持 miss 后 late 返回。
- `状态机层`: `ICache.S_IDLE` 对当前 `cpu_req_addr_i` 直接组合查 tag/data。hit/misaligned 保持 `S_IDLE`；cacheable miss 直接准备 `fill_*` 并进入 `S_FILL_REQ`；fill 完成后保留 `S_LOOKUP` 复查，用于跨 line 取指和补齐后的响应。
- `不变量层`: abort/fence.i invalidate 仍能使在填充的 victim line 保持 invalid；跨 line 取指必须两条 line 都命中才组合返回；misaligned fetch 继续返回 error；同拍 hit response 不得因 `fetch_pending_q` 尚未置位而丢失。
- `数据通路层`: `ICache.v` 新增当前请求的组合 `cur_*` hit/data 网络；`IfStage.v` 新增 `fetch_same_cycle_rsp_w`、`fetch_late_rsp_w` 和 `fetch_rsp_pc_w`，分别处理同拍 hit 与 late response 的 PC、预测和 fetch buffer 写入。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `inspect-icache` | `codex` | `completed` | `ICache.v`、`IfStage.v` | 确认旧 hit 路径多经 `S_LOOKUP/S_RESP`，IfStage 旧门控会丢同拍返回 | 代码静态阅读 |
| `rtl-edit` | `codex` | `completed` | 用户时序要求、现有 ready/valid 协议 | 修改 `ICache.v` 和 `IfStage.v` | `git diff` |
| `verify` | `codex` | `completed` | 修改后 RTL | lint/build/cpu-tests/性能样本 | 下方验证记录 |
| `memory-update` | `codex` | `completed` | 本次修改和验证结果 | 更新 project-status、NPC module memory、本 task-run | `.github/memory/*.md` |

## 关键产物

- `artifacts`: `npc/single/vsrc/ICache.v`、`npc/single/vsrc/IfStage.v`
- `logs_or_traces`: 命令行验证摘要见下方。
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`

## 验证记录

- `make -C npc/single lint`: PASS
- `make -C npc/single -j$(nproc)`: PASS
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run NPC_RUN_ARGS='--diff=default -m 0'`: PASS，`cycles=1790`、`commits=838`、`CPI=2.136`
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=fence-i run NPC_RUN_ARGS='--diff=default -m 0'`: PASS，`cycles=391`、`commits=43`、`CPI=9.093`
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=load-store run NPC_RUN_ARGS='--diff=default -m 0'`: PASS，`cycles=1040`、`commits=370`、`CPI=2.811`
- `timeout 45s make ARCH=riscv32-npc run mainargs=8 CROSS_COMPILE=/home/lyg/riscv-toolchain/riscv/bin/riscv64-unknown-elf- NPC_RUN_ARGS='-m 20000000 --progress=1000000'`: 20M cycles 样本 PASS；改前 `commits=5080118/CPI=3.937/simulation frequency=544373 inst/s`，改后 `commits=6803429/CPI=2.940/simulation frequency=646652 inst/s`。

## 当前阻塞点

- `blockers`: 无。
- `missing_dependencies`: 本机综合/STA 环境仍缺 `/home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/yosys`，本任务未进入综合验证。
- `risk_assessment`: 组合 hit 路径增加了 ICache tag/data 到 IfStage fetch buffer 的组合深度；本轮目标偏向 Verilator 仿真吞吐，后续做 ASIC PPA 时需要 STA 复核该路径。

## 下一步建议

1. 给 ICache/DCache 暴露 access/hit/miss/fill 计数，后续长跑可以直接定位前端 CPI 来源。
2. 恢复 yosys/STA 环境后，检查组合 hit 路径是否成为 IF 前端关键路径。

## 收尾结论

- `final_result`: 已按用户要求把 ICache hit 改为组合返回，并让首 miss/uncached fetch 在下一拍直接进入 RAM/DPI 请求状态。
- `evidence_summary`: lint/build 通过，定向 difftest 通过，`demo mainargs=8` 20M cycles 样本 CPI 从 3.94 降到 2.94。
- `notes`: 当前 build 输出仍带 `-pg -Os`，绝对 inst/s 不作为最终跑分，只用于同构建配置下的相对对比。
