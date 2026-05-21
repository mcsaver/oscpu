# Dispatch Log

## 基本信息

- `task_id`: `2026-05-20-npc-axi-bus-crossbar`
- `task_slug`: `npc-axi-bus-crossbar`
- `graph_template`: `custom`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-05-20] `recall` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户确认继续推进 AXI bus/crossbar 设计
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、memory/study 文件、NPC AXI 相关源码
- `action`: 梳理当前 ICache/DCache/NpcCore/NpcSimTop 的 single-beat AXI-like 接口和 DPI 直连边界
- `outputs`: 当前 master/slave 形态、后续抽取位置
- `evidence`: 源码阅读结果见 `task-report.md`
- `handoff_to`: `design`
- `next_step`: 落 RTL 模块
- `notes`: 当前工作区已有多处未提交改动，本任务只追加 bus/crossbar 相关文件并最小改接。

### [2026-05-20] `design` - `completed`

- `owner_agent`: Codex
- `trigger`: RTL 强制工作流
- `depends_on`: `recall`
- `inputs`: 现有 AXI-like 协议、用户高性能多负载可定制诉求
- `action`: 按需求、协议、状态机、不变量、数据通路约束完成推导
- `outputs`: `task-report.md` 的 “RTL 推导摘要”
- `evidence`: `.github/task-runs/2026-05-20-npc-axi-bus-crossbar/task-report.md`
- `handoff_to`: `implement`
- `next_step`: 新增 `AxiLiteXbar`、`NpcAxiBus`、`AxiDpiSlave`
- `notes`: 第一阶段保持一个 DPI slave，后续再拆 PMEM/MMIO/default error。

### [2026-05-20] `implement` - `completed`

- `owner_agent`: Codex
- `trigger`: 根据设计摘要落 RTL
- `depends_on`: `design`
- `inputs`: 当前 `NpcCore` I-side/D-side AXI-like 端口与 `NpcSimTop` DPI PMEM/MMIO 直连逻辑
- `action`: 新增参数化 `AxiLiteXbar`、`NpcAxiBus`、`AxiDpiSlave`、`AxiDefaultSlave`，并把 `NpcSimTop` 改接为 `NpcCore + NpcAxiBus + AxiDpiSlave`
- `outputs`: 总线从仿真顶层抽出，crossbar 负责地址译码、仲裁、owner route、read response buffer 和 AW/W buffering
- `evidence`: `npc/single/vsrc/{AxiLiteXbar.v,NpcAxiBus.v,AxiDpiSlave.sv,AxiDefaultSlave.v,NpcSimTop.sv}`、`npc/single/Makefile`
- `handoff_to`: `verify`
- `next_step`: lint、模块 testbench、AM cpu-tests
- `notes`: 当前仍配置为一个 DPI slave；`AxiDefaultSlave` 已作为后续地址未命中错误 slave 预留。

### [2026-05-20] `debug` - `completed`

- `owner_agent`: Codex
- `trigger`: `cpu-tests add` 在 pc `0x80000098` 处卡住
- `depends_on`: `implement`
- `inputs`: `/tmp/npc-xbar-debug4.vcd`
- `action`: 用 trace 定位 IFU flush 与 AR handshake 同拍时，旧逻辑把已送达 slave 的 AR 当作未发送请求取消，导致 DPI slave 端留下没有 owner 的 R response，进而阻塞 LSU AR
- `outputs`: 修正 read abort/drop 规则：当前拍 AR 已握手时转为 drop-drain；drop 未返回前保持 master busy；abort 有效时不 grant 新读请求
- `evidence`: 修复后 `cpu-tests add` GOOD TRAP，`cycles=1647`、`commits=838`
- `handoff_to`: `verify`
- `next_step`: 运行完整目标验证
- `notes`: no-ID 模式下取消读不能释放同 master 的新 outstanding，必须等被取消 response drain 完成。

### [2026-05-20] `verify` - `completed`

- `owner_agent`: Codex
- `trigger`: 修复完成后回归
- `depends_on`: `debug`
- `inputs`: 改动后 RTL/仿真壳
- `action`: 执行 lint、Verilator build、模块 testbench 和关键 cpu-tests
- `outputs`: 全部目标验证通过
- `evidence`: `make -C npc/single lint` PASS；`make -C npc/single -j4` PASS；`make -C npc/single/testbench RESULT_DIR=/tmp/npc-axi-bus-crossbar-tests run` 21/21 PASS；`cpu-tests add/load-store/fence-i` PASS
- `handoff_to`: `record`
- `next_step`: 更新 memory
- `notes`: 本轮未执行综合/STA，仍受本机缺 oss-cad-suite/yosys 路径的既有环境问题限制。

### [2026-05-20] `record` - `completed`

- `owner_agent`: Codex
- `trigger`: 验证完成
- `depends_on`: `verify`
- `inputs`: 验证日志与最终改动范围
- `action`: 更新 task-report、dispatch-log、project-status、npc module memory
- `outputs`: 收尾记录完成
- `evidence`: `.github/task-runs/2026-05-20-npc-axi-bus-crossbar/`、`.github/memory/project-status.md`、`.github/memory/modules/npc.md`
- `handoff_to`: 无
- `next_step`: 后续可拆 PMEM/MMIO/default error 多 slave 地址表
- `notes`: 工作区已有大量既有未提交改动，本任务未回退无关文件。
