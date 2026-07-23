#!/usr/bin/env python3
"""Prepare DB-owned retained-memory updates for the V9L postflight."""

from __future__ import annotations

import json
import pathlib
import subprocess
from dataclasses import dataclass


ROOT = pathlib.Path(__file__).resolve().parents[3]
RUN_DIR = pathlib.Path(__file__).resolve().parent
STAGING = RUN_DIR / "memory-postflight-staging"
DB_TOOL = ROOT / "scripts/github_index_db.py"


@dataclass(frozen=True)
class Update:
    path: str
    heading: str
    section: str
    insert_after: str | None = None


UPDATES = (
    Update(
        ".github/memory/project-status.md",
        "## 2026-07-22 NEMU reference-smoke target contract",
        """## 2026-07-22 NEMU reference-smoke target contract

- `cpu-tests` 的 `ARCH=riscv*-nemu` reference smoke 必须由 `CONFIG_TARGET_NATIVE_ELF=y` 的宿主 NEMU 执行。旧 e2e 判定把 `CONFIG_TARGET_AM=y` 当作兼容配置；该 target 会把 NEMU 自身构建成 AM 镜像，并由 `platform/nemu.mk` 再次调用同一 NEMU `run` 入口，形成递归 make 链，而不是有效 reference smoke。
- `scripts/e2e/lib/common.sh`、`scripts/e2e/modules/nemu.sh`、`nemu.tsv`、`quick.tsv` 与 NEMU e2e 合同已统一为 host-native RISC-V 语义。新增 `nemu-reference-config-contract` 仅接受 native 加显式 `riscv32`/`riscv64` ISA，并对 AM、SHARE、native 非 RISC-V、native 缺失 ISA、缺失配置全部 fail closed；历史 `AGENT_E2E_FORCE_SMOKE=1` 不能绕过 target/ISA 类型。
- 修正后的真实 RV64 `add` smoke 执行 `844` 条 guest 指令并 `HIT GOOD TRAP`，汇总 `1/1 PASS`。`difftest` profile 的最终 run `2026-07-23-ownership-rv64-memory-functional-aggregate-revtag-v9l-2` 为 completed，8 个节点全 PASS；NEMU 配置前后 SHA-256 均为 `78fc4445c5ed41264d5b9688520b592f3265101d4a8ddd83bc40383ee9fc8a0d`。
- 先前 AM/SoftFloat、unused helper、UART assert 和递归构建失败 run 保留为 root-cause 反例，不作为完成证据；为错误 AM 路径试加的 NEMU 生产源码改动已逐项撤回。长期 RV64 OoO/PPA goal 仍 active，PPA 继续为 `UNQUALIFIED`。""",
    ),
    Update(
        ".github/memory/modules/nemu.md",
        "## NEMU host-native reference smoke contract (2026-07-22)",
        """## NEMU host-native reference smoke contract (2026-07-22)

- `ARCH=riscv64-nemu` / `ARCH=riscv32-nemu` 的 AM program reference run 需要宿主可执行且 ISA 匹配的 NEMU，即 `.config` 中 `CONFIG_TARGET_NATIVE_ELF=y` 且 `CONFIG_ISA` 为 `riscv32` 或 `riscv64`。`CONFIG_TARGET_SHARE=y` 只生成 DiffTest 共享库；`CONFIG_TARGET_AM=y` 把 NEMU 自身交叉编译成 AM 镜像，且 Kconfig 明示 `DON'T CHOOSE`，二者均不能作为该 smoke 的执行 target。
- `e2e_nemu_native_reference_compatible` 只接受 host-native RISC-V target；`nemu-reference-config-contract` 在隔离临时目录中验证 native RISC-V 正例，以及 AM、SHARE、native 非 RISC-V、native 缺失 ISA、missing 反例，并核对 `nemu.tsv`、`quick.tsv` 绑定 `e2e_nemu_native_add_smoke`。旧强制变量不再改变 target/ISA 判定。
- 当前 native RV64 reference 的 `cpu-tests add` 为 `1/1 PASS`、`HIT GOOD TRAP`、844 条 guest 指令；配置保护封装证明运行前后 `.config` SHA-256 都是 `78fc4445c5ed41264d5b9688520b592f3265101d4a8ddd83bc40383ee9fc8a0d`。完整 difftest e2e 完成证据为 `2026-07-23-ownership-rv64-memory-functional-aggregate-revtag-v9l-2`。""",
    ),
    Update(
        ".github/memory/modules/agent-system.md",
        "## Executable target preconditions and wording boundary (2026-07-22)",
        """## Executable target preconditions and wording boundary (2026-07-22)

- e2e 节点的“兼容配置”必须按实际产物类型定义，并有独立正反例合同：可执行 reference、DiffTest shared object、AM image 不能只因同属 NEMU 就互换。配置边界允许业务 smoke SKIP，但配置选择器合同本身必须始终执行并 fail closed，避免错误前提被 SKIP 掩盖。
- 本地 RV64 工作继续使用已固化的 `rv64-hardware-professional` 叙述：明确 CPU 微架构、Verilog/SystemVerilog、spec、testbench、EDA、功能证据与 PPA 范围；真实 RTL 标识符和特权级/异常术语不改写。该层不建立关键词黑名单，不削减 workspace、shell、上下文或推理能力，也不承诺控制不可观测的产品侧内容分类结果。
- 若产品界面中断当前节点，恢复依据是 task-run 状态、唯一配置/RTL 哈希和已发布 evidence，而不是重复派发同一节点。子 agent 仍先消费版本化本地 RTL 任务合同；协调状态留在主 agent/task-run，技术任务只携带本地 RTL/spec/TB/evidence 输入、输出与成功条件。""",
    ),
    Update(
        ".github/memory/known-issues.md",
        "### [123] NEMU reference smoke 把 TARGET_AM 当作可执行 reference 会递归构建（2026-07-22）",
        """### [123] NEMU reference smoke 把 TARGET_AM 当作可执行 reference 会递归构建（2026-07-22）

- **症状**：native NEMU 配置被旧 `nemu-add-smoke` 误判为不兼容并 SKIP；切到 `riscv64-am_defconfig` 后先出现 SoftFloat/unused helper/AM libc link 边界，越过编译后产生 `make[1] ... make[2231]` 递归链，直到节点预算耗尽。
- **根因**：`ARCH=riscv*-nemu` 的 cpu-tests run 需要宿主 NEMU executable；`CONFIG_TARGET_AM=y` 却把 NEMU 本体构建为 AM program，随后 `abstract-machine/scripts/platform/nemu.mk` 为运行该镜像再次进入同一 NEMU `run`，因而递归。旧 helper 名称和判定把 AM program target 错当成 AM guest reference compatibility。
- **修复/门禁**：reference selector 只接受 `CONFIG_TARGET_NATIVE_ELF=y` 且 `CONFIG_ISA` 为 `riscv32`/`riscv64`；新增 `nemu-reference-config-contract` 自动接受 native RISC-V、拒绝 AM/SHARE/native 非 RISC-V/native 缺失 ISA/missing，并证明旧强制变量不能绕过。`nemu.tsv` 与 `quick.tsv` 统一绑定 native RISC-V smoke；错误 AM 路径上的临时 NEMU 源码兼容改动全部撤回。
- **当前状态**：native RV64 `add` reference smoke `1/1 PASS`、`HIT GOOD TRAP`、844 instructions；最终 `difftest` run `2026-07-23-ownership-rv64-memory-functional-aggregate-revtag-v9l-2` completed，配置前后哈希一致。历史 blocked runs 仅保留为反例，不得作为完成证据。""",
        insert_after="## 活跃问题\n<!-- 当前未解决的问题 -->",
    ),
)


def load_document(path: str) -> str:
    if path == ".github/memory/known-issues.md":
        # The stored-document load API is intentionally token-bounded.  Reuse the
        # exact 11232-byte staging file that was the immediately preceding
        # update-stored source, so the oldest retained section is not truncated
        # while appending [123].
        baseline = RUN_DIR / "memory-staging" / "known-issues.md"
        document = baseline.read_text(encoding="utf-8")
        required = (
            "### [122] V8L 汇总直接绑定随机临时编译路径会造成重复运行哈希漂移",
            "### [115] T3H 后 physical 200MHz 仍未闭合",
        )
        if baseline.stat().st_size != 11232 or any(
            heading not in document for heading in required
        ):
            raise RuntimeError("known-issues staging baseline provenance drifted")
        return document
    completed = subprocess.run(
        [
            "python3", str(DB_TOOL), "load", "--source", "stored",
            "--path", path, "--json", "--max-tokens", "50000",
        ],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    chunks = json.loads(completed.stdout)
    if not isinstance(chunks, list) or not chunks:
        raise RuntimeError(f"stored document has no chunks: {path}")
    ordered = sorted(chunks, key=lambda item: item["start_line"])
    texts = [item["text"].strip() for item in ordered]
    if not texts[0].startswith("# "):
        raise RuntimeError(f"stored document has no title: {path}")
    return "\n\n".join(texts).rstrip() + "\n"


def insert_section(document: str, update: Update) -> str:
    if update.heading in document:
        raise RuntimeError(f"section already exists: {update.heading}")
    if update.insert_after is None:
        first_break = document.find("\n\n")
        if first_break < 0:
            raise RuntimeError(f"document has no title separator: {update.path}")
        return (
            document[:first_break]
            + "\n\n"
            + update.section.strip()
            + "\n\n"
            + document[first_break + 2:]
        )
    if document.count(update.insert_after) != 1:
        raise RuntimeError(f"expected one insertion anchor in {update.path}")
    return document.replace(
        update.insert_after,
        update.insert_after + "\n\n" + update.section.strip(),
        1,
    )


def main() -> int:
    STAGING.mkdir(parents=True, exist_ok=True)
    for update in UPDATES:
        document = load_document(update.path)
        if update.heading in document:
            print(f"[V9L-POSTFLIGHT-MEMORY][EXISTS] {update.path}")
            continue
        updated = insert_section(document, update)
        output = STAGING / pathlib.Path(update.path).name
        output.write_text(updated, encoding="utf-8")
        print(f"[V9L-POSTFLIGHT-MEMORY][PASS] {update.path} -> {output.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
