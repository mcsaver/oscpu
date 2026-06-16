# Dispatch Log

## 基本信息

- `task_id`: `2026-05-29-ooo-core-top-split`
- `task_slug`: `ooo-core-top-split`
- `graph_template`: `npc-sim-regression`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-05-29 13:30] `read-boundary` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户要求新增 core top，将仿真顶层和核心管理分离。
- `depends_on`: `.github/AGENTS.md`、NPC memory/instructions 读取完成。
- `inputs`: `NpcSimTop.sv`, `NpcCore.v`, `OooAluFetchCore.v`, `NpcAxiBus.v`, `AxiDpiSlave.sv`
- `action`: 梳理顺序核外部 IFU/LSU 总线、OoO 私有 fetch/mem 端口、仿真 DPI 总线位置。
- `outputs`: 确认旧 `NpcSimTop` 在 `NPC_OOO_ALU_EXPERIMENT=1` 下直接实例化 OoO 并用 DPI 一拍双端口建模内存。
- `evidence`: 源码检查。
- `handoff_to`: `add-core-top`
- `next_step`: 新增 core 管理顶层。
- `notes`: 优先保持现有外部 IFU/LSU 总线 ABI。

### [2026-05-29 13:45] `add-core-top` - `completed`

- `owner_agent`: Codex
- `trigger`: core/sim 边界设计完成。
- `depends_on`: `read-boundary`
- `inputs`: `NpcCore` ABI、`OooAluFetchCore` ABI
- `action`: 新增 `NpcCoreTop.v`，默认封装顺序核，实验宏下封装 OoO 核；增加 fetch packet 到 IFU 读桥、双 mem 端口到 LSU 仲裁桥。
- `outputs`: `npc/single/vsrc/core/NpcCoreTop.v`
- `evidence`: `make -C npc/single NPC_OOO_ALU_EXPERIMENT=1 -B -j4` 初次构建 PASS。
- `handoff_to`: `refactor-sim-top`
- `next_step`: 改造 `NpcSimTop`。
- `notes`: 桥接实现保守串行，目标是先恢复正确性。

### [2026-05-29 13:50] `refactor-sim-top` - `completed`

- `owner_agent`: Codex
- `trigger`: core top 可编译。
- `depends_on`: `add-core-top`
- `inputs`: `NpcSimTop.sv`, `filelist.mk`, `Makefile`
- `action`: `NpcSimTop` 统一实例化 `NpcCoreTop`，移除 OoO 私有 DPI fetch/mem block；`filelist.mk` 加入 `NpcCoreTop.v`；`RTL_CORE_TOP` 默认改为 `NpcCoreTop`。
- `outputs`: 仿真顶层只保留总线/设备/DPI 事件。
- `evidence`: OoO 构建 PASS。
- `handoff_to`: `regression`
- `next_step`: 代表测试。
- `notes`: 顺序核 cache/BPU 统计仍通过仿真层次化观察 `u_core.u_inorder`，不参与 core 功能 ABI。

### [2026-05-29 13:52] `ooo-fetch-latency-fix` - `completed`

- `owner_agent`: Codex
- `trigger`: 代表测试全部在 `pc=0x80000000` 跑到 max-cycles。
- `depends_on`: `refactor-sim-top`
- `inputs`: `/tmp/coretop.vcd`, `OooAluFetchCore.v`
- `action`: 定位 fetch response dispatch-bypass 后没有更新 `next_fetch_pc_q`；改为 response enqueue 或 bypass-consumed 且本拍无新 request 时都推进 packet next PC。
- `outputs`: `OooAluFetchCore.v` 修复。
- `evidence`: 修复后 `add/bitmanip/recursion/fence-i` PASS。
- `handoff_to`: `ooo-buffer-address-fix`
- `next_step`: 继续处理访存类 BAD TRAP。
- `notes`: 这是旧一拍直连 fetch ready 隐藏的非零延迟协议问题。

### [2026-05-29 13:58] `ooo-buffer-address-fix` - `completed`

- `owner_agent`: Codex
- `trigger`: `mem-test/string` BAD TRAP。
- `depends_on`: `ooo-fetch-latency-fix`
- `inputs`: `/tmp/memtest.vcd`, `OooIntBackend.v`
- `action`: 定位 memory buffer 路径把 effective address 原样发到总线，非对齐 byte load/store 读错；改为 buffer request 发 word-aligned 地址。
- `outputs`: `OooIntBackend.v` 修复。
- `evidence`: 代表 `mem-test/string` 修复后 PASS。
- `handoff_to`: `regression`
- `next_step`: CPU-test 全量。
- `notes`: effective address 仍保留用于 response LSU 的 load 数据移位。

### [2026-05-29 14:00] `regression` - `completed`

- `owner_agent`: Codex
- `trigger`: 代表测试全过。
- `depends_on`: `ooo-fetch-latency-fix`, `ooo-buffer-address-fix`
- `inputs`: `npc/single/build/NpcSimTop`, `am-kernels/tests/cpu-tests/build/*-riscv32-npc.bin`
- `action`: 执行 CPU-test 全量并收集 CPI；补跑默认非 OoO build + `add` 冒烟；最终重新构建 OoO 实验模式。
- `outputs`: `/tmp/ysyx-ooo-full-cputests-coretop.tsv`
- `evidence`: `40/40 PASS`, weighted CPI `4.690321`; default `add` PASS `CPI=1.801`; final OoO build PASS。
- `handoff_to`: `memory-update`
- `next_step`: 更新 memory 与 task report。
- `notes`: CPI 高是保守总线桥代价，不代表优化目标完成。
