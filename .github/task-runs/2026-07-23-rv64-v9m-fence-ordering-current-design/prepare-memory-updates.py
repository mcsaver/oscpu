#!/usr/bin/env python3
"""Prepare DB-first memory payloads from the current stored documents."""

from __future__ import annotations

import json
import pathlib
import subprocess
import sys


ROOT = pathlib.Path(__file__).resolve().parents[3]
CLI = ROOT / "scripts/github_index_db.py"

UPDATES = {
    ".github/memory/project-status.md": """## 2026-07-23 RV64 FENCE-G1 current-design V9M

- 当前 RV64 双发射 OoO 生产 RTL design-id 保持 `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`；本轮未修改生产 `.v` RTL，修改集中在 full-core testbench、证据生成/校验与工作流规则。
- `FENCE-G1` 已关闭：普通 `FENCE` 的 pending-system drain 同时等待 backend/SQ quiet 与完整 `mem_idle_o`；full-core 程序覆盖 older store、lane1 FENCE、younger device read，并在等待周期运行时核对 CoreGlue→ControlPlane `mem_idle` 端口值。
- canonical `make -C npc/rv64 check-fence-ordering` 为 focused 2/2、module 109/109、两份 compile-success negative RTL variant 2/2、fail-closed validator unittest 12/12；所有正向日志绑定当前 `[RTL-DESIGN-ID]`。result/raw SHA-256 分别为 `792b8c2c9454d01eb5143019136d6b3add734019ff20cd66cd36efef961e2ec0` 与 `3481db6a72c52a786139231107d5ef6e8ba93f19a1018bbe33061ffb875e83c1`。
- 共享 Makefile/TB/freeze validator 的 provenance 变化通过 9 个既有 canonical target 与九门 architecture aggregate 实际重放恢复；最终 ARCH_STABLE audit/verify 和 134 项单测 PASS，当前仍为诚实 `GAP`、38 blockers、PPA `UNQUALIFIED`、promotion false。长期 goal 保持 active。
- 主/子 agent 的用户进度、终审和派发统一使用 `rv64-hardware-professional`：首句写明本地 module/signal/transaction、仿真/综合/STA 与证据产物，协调状态单独进入 task-run；该分层不使用关键词黑名单，也不减少源码探索、命令、负向 RTL 版本、断言、覆盖、独立复核或 PPA 能力。""",
    ".github/memory/modules/npc.md": """## RV64 ordinary FENCE current-design V9M

### 稳定合同

- 普通 `OPCODE_MISC_MEM + FUNCT3_FENCE` 进入 pending-system drain；其完成条件除 backend/SQ quiet 外必须包含 `mem_idle_i`。非 FENCE pending-system 事件不额外依赖该条件。
- `OooIntBackend.mem_idle_o` 覆盖双 MIQ、pending/buffer、双 retry holder、双 memory issue reservation、owner-live 与 terminal-pending count，经 DecodeBackend→CoreSlice→ExecuteBackend→CoreGlue→ControlPlane 原值传到 `OooPendingDrainResolveGate`。
- full-core testbench 在 pending ordinary FENCE 且 `core_mem_idle_w=0` 周期直接要求 `u_control_plane.mem_idle_i === core_mem_idle_w`；older store 必须先 probe/drain，FENCE 才退休，younger device read 只能在两者之后观察。

### 当前证据与边界

- canonical `make -C npc/rv64 check-fence-ordering`：focused 2/2、module aggregate 109/109、compile-success negative RTL variants 2/2、validator unittest 12/12，design-id 为 `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`。
- 两份 negative RTL variant 分别常量化 drain gate 的 FENCE memory-idle 条件与 CoreGlue→ControlPlane `mem_idle` 连接；日志必须精确只有目标 `[CHECK-FAIL]`、`errors=1` 与 `status=1`，不能用前缀/子串或 JSON 自报字段替代。
- `FENCE-G1=CLOSED` 只对当前 design-id 与 result `792b8c2c9454d01eb5143019136d6b3add734019ff20cd66cd36efef961e2ec0` 成立。九门 architecture aggregate 为 GREEN，但 full-core freeze 仍为 GAP/38 blockers，PPA UNQUALIFIED。
- STORE/AMO outstanding owner 的同沿清除仍需独立 `next(entry resident || terminal accepted)` 生命周期守恒证据，不由 FENCE closure 外推。""",
    ".github/memory/modules/agent-system.md": """## 2026-07-23 RV64 hardware-domain user-visible wording

- `rv64-hardware-professional` 现同时约束主 agent 用户进度、终审摘要与子 agent render：首句落到本地 RV64 module/signal/transaction、流水级/时钟周期、仿真/综合/STA 动作和生成证据。
- 协调层状态单独写入合同 JSON、dispatch log 或 task-run，不反复复制进 RTL 技术目标；真实 module/signal/TB/log/schema 标识符以及 PMP、特权级、访问异常、内存保护等处理器术语保持原样。
- 该规则是领域语义完整性层，不建立关键词黑名单，不重命名 RTL 标识符，也不改变 `workspace-files`、shell、命令、路径、上下文、负向 RTL 版本、断言、覆盖矩阵、unknowns、反例或 PPA 分析能力。
- 根 `AGENTS.md`、`.github/AGENTS.md`、`.github/copilot-instructions.md` 与 `AI_ENVIRONMENT.md` 均提供可自动发现入口；RTL 子 agent 仍使用 versioned task contract 与 Windows→WSL single-flight。""",
}


def stored_text(path: str) -> str:
    completed = subprocess.run(
        [
            sys.executable,
            str(CLI),
            "load",
            "--source",
            "stored",
            "--path",
            path,
            "--max-tokens",
            "50000",
            "--json",
        ],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    chunks = json.loads(completed.stdout)
    if not isinstance(chunks, list) or not chunks:
        raise RuntimeError(f"stored memory is missing: {path}")
    ordered = sorted(chunks, key=lambda item: int(item["start_line"]))
    return "\n\n".join(str(item["text"]).strip() for item in ordered)


def main() -> int:
    output_root = ROOT / ".github/cache/rv64-v9m-memory-staging"
    output_root.mkdir(parents=True, exist_ok=True)
    for path, section in UPDATES.items():
        current = stored_text(path)
        title, separator, remainder = current.partition("\n\n")
        if not separator or not title.startswith("# "):
            raise RuntimeError(f"unexpected stored memory shape: {path}")
        updated = f"{title}\n\n{section.strip()}\n\n{remainder.strip()}\n"
        output = output_root / pathlib.Path(path).name
        if path.endswith("modules/npc.md"):
            output = output_root / "module-npc.md"
        elif path.endswith("modules/agent-system.md"):
            output = output_root / "module-agent-system.md"
        output.write_text(updated, encoding="utf-8")
        print(f"{path}\t{output}\tbytes={len(updated.encode('utf-8'))}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
