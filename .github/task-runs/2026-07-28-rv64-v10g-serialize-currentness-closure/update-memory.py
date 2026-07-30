#!/usr/bin/env python3
"""Publish stable V10G RV64 facts through the DB-owned memory API."""

from __future__ import annotations

import json
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
INDEX = ROOT / "scripts/github_index_db.py"


@dataclass(frozen=True)
class Update:
    path: str
    heading: str
    section: str


UPDATES = (
    Update(
        ".github/memory/project-status.md",
        "## 2026-07-28 RV64 V10G queue-head serialization currentness",
        """## 2026-07-28 RV64 V10G queue-head serialization currentness

- 当前 product-default RV64 design-id 为 `sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`，产品配置固定 `OOO_CSR_QUEUE_HEAD=1` 与 holder assertion=1。合法非 FP lane0/head0 CSR 使用 queue-head retirement；lane1/FP CSR、其余 SYSTEM、architectural trap 与 simulation exit 保留 pending/full-drain owner。
- queue-head CSR assertion/release C0/C1/C2 均 PASS；每种配置观察 3 个 committed 与 2 个 killed transaction。两份 compile-success C2 RTL 版本均被动态拒绝。SYSTEM product-default 为 3/3 baseline 与 14/14 compile-success RTL version；current replay 为 26/26、module 113/113、official 177/177、AM 59/59、DiffTest mismatch 0、architecture 9/9 GREEN。
- 隔离 final reviewer v2/v3 均给出 `APPROVED_FOR_CURRENT_SCOPE`；v3 额外核验 historical depth、9/9 checker replay、XRET holder-onehot、4 份 cohort contract、V9O 167/167 与 A3/A4 状态边界，未发现当前范围可复现 false-green。`SERIALIZE-G1` 仅对 Phase1 split-domain CLOSED；Phase2–5、whole-core holder census、正式 freeze-input inventory 与 PPA promotion 均未关闭。
- A3 原始 published state 保持 FAIL；其 execution/DUT terminal/binding/raw artifact/RTL assertion 为 `COMPLETE/COMPLETE/NO_DRIFT/VALID/CLEAN`，旧 dmesg oracle 为 INVALID。A4 保持 TERM/FAIL，不作为 PASS。当前没有 production/elaborated RTL、device model 或 simulator semantics 变化，因此不需要完整系统重跑。
- historical-defect backfill 已成为 freeze gate。当前 5 项中 VD4×2、VD3×1、VD1×2；两个 VD1 会阻止 architecture freeze，选择 `HIST-SER-QH-YOUNGER-STORE-CYCLE` 为下一项。
- checker identity 维护从冻结日志/RTL-version summary 重放 9 个 closed-debt checker，9/9 PASS 且输入前后哈希不变；XRET 8 个 RTL version + 2 个 observer probe 全部编译成功并被拒绝；V9O index 167/167、arch-stable 单测 48/48。当前 audit 仅保留 32 个真实边界 blocker，`ARCH_STABLE=GAP`、`PPA=UNQUALIFIED`、promotion=false。
- AI 环境已增加通用 `rv64-historical-defect-backfill-loop`；非历史 bounded brief 可独立命中蓝图。`npc-dev` 5/5、`agent-system` 11/11 与双 profile strict guard 均 PASS；最初含 `v10g` 的无独立 focus task-run 保持 blocked，不改写为完成。""",
    ),
    Update(
        ".github/memory/modules/npc.md",
        "## RV64 queue-head serialization and historical backfill V10G",
        """## RV64 queue-head serialization and historical backfill V10G

### 稳定微架构合同

- product-default `OOO_CSR_QUEUE_HEAD=1` 只允许合法非 FP lane0/head0 CSR 在 ROB head 直接 C0 retirement；lane1/FP CSR 与其它 SYSTEM/trap/exit 不得借用该入口。
- queue-head CSR 的 typed C0 request、C1 registered apply/CsrFile request 与 C2 no-repeat 必须使用同一 PID/PC/inst transaction。killed CSR 不得产生任何 C0/C1/C2 side effect；不得用 seen-bit 去重掩盖重复 terminal。
- SYSTEM pending holder 继续覆盖 SATP/SFENCE/FENCE.I/FENCE/WFI/ECALL/xRET/IRQ 等 full-drain classes；owner/stop death、MMU/FPC action 与 typed redirect 均保留原断言强度。

### 当前证据

- design-id `sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`。queue-head assertion/release PASS；两份 compile-success C2 RTL version 均被拒绝；SYSTEM 3/3+14/14；layered replay 26/26，module 113/113、official 177/177、AM 59/59、DiffTest 0、architecture 9/9 GREEN。
- `SERIALIZE-G1` 经隔离 reviewer v2/v3 批准为 Phase1 CLOSED；v3 确认 `GAP_MARKER_SCHEMA_ONLY` 只属于旧 marker schema，当前 owner-bound raw scoreboard 会拒绝同一 compile-success RTL version。该状态不能外推到 later serialization phases、whole-core freeze 或 PPA。
- A3 是“系统 transaction 完成、旧 oracle 误判”，但原始 FAIL 不变；A4 是 TERM/FAIL。只有 production core、实际 elaborated RTL、device model/simulator semantics 或 A3 必需原始证据变化才要求完整系统重跑。

### Historical defect gate

- backfill 深度使用 VD0–VD4；VD0/VD1 阻止 architecture freeze。当前选择 `HIST-SER-QH-YOUNGER-STORE-CYCLE`：历史 full-drain head CSR 等待 `mem_idle && sq_empty`，younger SQ store 又只能在 CSR retirement 后清除，构成真实 wait-for cycle。
- 现有 older-store positive case 不是该 younger-store 反例，当前只到 VD1。下一步必须构造 compile-success 历史 RTL version 并由当前 queue-head transaction testbench 动态拒绝；达到至少 VD3 后才能清除此项。
- current arch-stable checker 48/48、V9O index 167/167；最终 audit 的 32 blockers 只来自两个 VD1、incomplete whole-core census 和空 freeze-input inventory。`ARCH_STABLE=GAP`、`PPA=UNQUALIFIED`。
- 该 backfill 图已作为 `.github/agentic-hardware-blueprint.md` 的非历史入口；bounded recall、`npc-dev` 5/5、`agent-system` 11/11 和 strict guard 双 profile 均 PASS。具体活动缺陷仍只由 versioned ledger 维护。""",
    ),
)


def load_stored(path: str) -> str:
    completed = subprocess.run(
        [
            sys.executable,
            str(INDEX),
            "load",
            "--source",
            "stored",
            "--path",
            path,
            "--json",
            "--limit",
            "100",
            "--max-tokens",
            "50000",
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
    texts = [str(item["text"]).strip() for item in ordered]
    if not texts[0].startswith("# "):
        raise RuntimeError(f"stored document has no title: {path}")
    return "\n\n".join(texts).rstrip() + "\n"


def upsert(document: str, update: Update) -> tuple[str, bool]:
    section = update.section.strip()
    if update.heading not in document:
        first_break = document.find("\n\n")
        if first_break < 0:
            raise RuntimeError(f"document has no title separator: {update.path}")
        return (
            document[:first_break]
            + "\n\n"
            + section
            + "\n\n"
            + document[first_break + 2 :],
            True,
        )
    start = document.find(update.heading)
    if start < 0 or document.find(update.heading, start + 1) >= 0:
        raise RuntimeError(f"section heading is not unique: {update.heading}")
    next_heading = document.find("\n## ", start + len(update.heading))
    end = len(document) if next_heading < 0 else next_heading + 1
    current = document[start:end].strip()
    if current == section:
        return document, False
    return document[:start] + section + "\n\n" + document[end:].lstrip(), True


def publish(update: Update) -> None:
    document = load_stored(update.path)
    updated, changed = upsert(document, update)
    if not changed:
        print(f"PASS memory unchanged path={update.path}")
        return
    completed = subprocess.run(
        [sys.executable, str(INDEX), "update-stored", update.path, "--stdin"],
        cwd=ROOT,
        check=True,
        input=updated,
        capture_output=True,
        text=True,
    )
    print(completed.stdout.strip())


def main() -> int:
    for update in UPDATES:
        publish(update)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
