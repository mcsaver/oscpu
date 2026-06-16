# Dispatch Log

## 基本信息

- `task_id`: `2026-05-21-npc-dcache-8kb-profile`
- `task_slug`: `npc-dcache-8kb-profile`
- `graph_template`: `custom`
- `log_policy`: `append-only`

---

### [2026-05-21 00:00] `recall` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户要求按 benchmark 分析建议进行优化。
- `depends_on`: none
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、project/memory、NPC study、RTL workflow。
- `action`: 读取上下文，确认当前 DCache 为 4KB direct-mapped，benchmark 暴露 DCache miss/writeback 压力。
- `outputs`: 选择 DCache 容量翻倍 + load/store 统计增强作为第一轮低风险优化。
- `evidence`: 已读文件与截图指标。
- `handoff_to`: `rtl-derive`
- `next_step`: 补 RTL 四段式推导。
- `notes`: JAL/JALR/RAS 已接近满分，不作为第一优先级。

### [2026-05-21 00:00] `rtl-derive` - `completed`

- `owner_agent`: `codex`
- `trigger`: 即将修改 `DCache.v`。
- `depends_on`: `recall`
- `inputs`: DCache 参数、flush 状态机、统计事件接口。
- `action`: 按需求、协议规则、状态机、不变量、数据通路约束推导本轮改动边界。
- `outputs`: RTL 推导摘要。
- `evidence`: `task-report.md` 中“RTL 推导摘要”。
- `handoff_to`: `implement`
- `next_step`: 修改 RTL 与统计接口。
- `notes`: 本轮不改 miss-side 总线协议，不引入 replacement policy。

### [2026-05-21 00:00] `implement` - `completed`

- `owner_agent`: `codex`
- `trigger`: 完成推导后落盘。
- `depends_on`: `rtl-derive`
- `inputs`: `DCache.v`、`NpcSimTop.sv`、`cpu-exec.cpp`
- `action`: `DCache` 扩到 128 lines；flush 步进参数化；DCache DPI 事件新增 `is_store`；host 统计新增 load/store 明细。
- `outputs`: 三个文件已修改。
- `evidence`: 静态搜索确认 `LINE_COUNT=128`、`INDEX_BITS=7`、`npc_dcache_event` 六参一致。
- `handoff_to`: `verify-static`
- `next_step`: 尝试验证。
- `notes`: 工作区原本已有大量未提交改动，本轮只追加上述文件片段。

### [2026-05-21 00:00] `verify-static` - `completed`

- `owner_agent`: `codex`
- `trigger`: 修改后检查。
- `depends_on`: `implement`
- `inputs`: 已改文件。
- `action`: 运行 `git diff --check -- npc/single/vsrc/DCache.v npc/single/vsrc/NpcSimTop.sv npc/single/csrc/cpu/cpu-exec.cpp`。
- `outputs`: 无空白错误或冲突标记。
- `evidence`: 命令仅输出 Windows Git 的 LF/CRLF 提示。
- `handoff_to`: `env-verify`
- `next_step`: 尝试 lint/build。
- `notes`: 该检查不能替代 Verilator lint。

### [2026-05-21 00:00] `env-verify` - `blocked`

- `owner_agent`: `codex`
- `trigger`: 需要真实构建验证。
- `depends_on`: `verify-static`
- `inputs`: 当前 Codex PowerShell 环境。
- `action`: 尝试 `make -C ... lint`、`verilator --version`、`wsl.exe -l -v`。
- `outputs`: `make`/`verilator` 未找到；`wsl.exe` 报未安装或不可见发行版。
- `evidence`: 终端输出记录在本次对话。
- `handoff_to`: user/local WSL
- `next_step`: 在用户 WSL 环境补跑 lint/build/benchmark。
- `notes`: 这属于当前工具环境限制，不是源码验证通过。

### [2026-05-21 00:00] `record` - `completed`

- `owner_agent`: `codex`
- `trigger`: 收尾记录。
- `depends_on`: `env-verify`
- `inputs`: 本轮改动、静态检查、环境阻塞。
- `action`: 更新 project-status、NPC memory 和 task-runs。
- `outputs`: 记录落盘。
- `evidence`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、本目录。
- `handoff_to`: none
- `next_step`: 用户本地复跑 benchmark 后继续决定 2-way/victim cache 或 burst。
- `notes`: 验证缺口已显式记录。
