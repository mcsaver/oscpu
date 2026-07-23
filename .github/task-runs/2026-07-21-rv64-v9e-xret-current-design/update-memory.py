#!/usr/bin/env python3
"""Publish stable V9E XRET-G1 facts through the DB-owned memory API."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
INDEX = REPO / "scripts" / "github_index_db.py"

PROJECT_PATH = ".github/memory/project-status.md"
NPC_PATH = ".github/memory/modules/npc.md"
AGENT_SYSTEM_PATH = ".github/memory/modules/agent-system.md"
PROJECT_MARKER = "<!-- 按时间倒序记录，格式: - [日期] 简要描述 -->"
NPC_MARKER = "<!-- 已实现的模块、信号位宽等 -->"
AGENT_SYSTEM_MARKER = "## 当前状态\n\n"
PROJECT_IDENTITY = "RV64 V9E 已把 XRET-G1 绑定到当前同设计证据"
NPC_IDENTITY = "RV64-v9e-xret-current-design"
AGENT_SYSTEM_IDENTITY = "V9E architecture source-binding rebind"

PROJECT_ENTRY = (
    "- [2026-07-21] **RV64 V9E 已把 XRET-G1 绑定到当前同设计证据；长期完整 OoO/PPA 目标继续 "
    "active**。production RTL 未修改；`OooFetchHeadClassifyGate` 是 MRET/SRET current-mode legality "
    "唯一 source，head0/lane1 经 `OooPendingDispatchArbiter`/`OooPendingLane1CaptureGate` 区分精确"
    "架构异常与合法 system-return 请求，`OooPendingTrapExitSequencer → OooCsrTrapRequestMux → CsrFile` "
    "保留并消费最终事务。7 例 matrix 覆盖 MRET@M/S/U 与 SRET@S+TSR0/S+TSR1/U/M+TSR1；4 个"
    "全核程序证明 legal MRET/SRET request/commit/return，以及 illegal head0/lane1 xRET 的 zero request/"
    "commit、精确 cause/PC/tval、handler return 和 older lane0 retirement。当前模块 109/109、"
    "compile-success 本地 RTL 验证变体 8/8、request/commit observation sensitivity 配置 2/2 均动态"
    "拒绝，XRET 单测 10/10；canonical 双跑六项 SHA 全相同，result "
    "`26f29205929a75a9b824f1ab2b3ac938bb453b8e027f041a0f1e02b364d257a1`，绑定 design "
    "`sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`。新增 XRET Makefile "
    "入口触发九条 architecture record 的来源哈希重绑；首轮遗漏 4 个 optional `source_manifest` 被"
    "下游 arch-stable forward test 捕获并保留，修正版同时闭合 `provenance`/`source_manifest`，且逐字节"
    "重建证明 delta 仅为 10 行 XRET target。最终九项 directed architecture GREEN；full-core "
    "`ARCH_STABLE=GAP/blockers=44`、PPA `UNQUALIFIED`、`promotion_eligible=false`。no-tools reviewer "
    "判 PASS、无 P0/P1；不外推形式完备、未列特权序列、全核冻结或 PPA。证据 "
    "`.github/task-runs/2026-07-21-rv64-v9e-xret-current-design/`。"
)

NPC_ENTRY = (
    "- 2026-07-21(RV64-v9e-xret-current-design): **XRET-G1 在当前 design_id 上 CLOSED；production RTL "
    "未改，full-core arch-stable/PPA 未晋级**。legality owner 为 `OooFetchHeadClassifyGate`：MRET 仅 M "
    "mode 合法，SRET 在 U mode 非法、S mode+TSR 非法、M mode 不受 TSR 阻断；不在 `CsrFile` 重复"
    "解码。head0/lane1 exception-versus-system capture 分别由 `OooPendingDispatchArbiter` 与 "
    "`OooPendingLane1CaptureGate` 掌握，精确 metadata 经 `OooPendingTrapExitSequencer/"
    "OooCsrTrapRequestMux` 进入 CSR。focused marker 为 `cases=7 legal=3 illegal=4 raw_preserved=7 "
    "legal_system=3 illegal_arch_trap=4`；四个 full-core marker 分别证明 legal MRET/SRET 各 1 次 request/"
    "commit/return，以及 illegal MRET/SRET 各 1 次 precise exception、0 return request、0 faulting "
    "commit、cause=2、PC/tval/mepc/mtval exact，lane1 case 另有 `older_lane0=1`。八个 current-source "
    "compile-success RTL verification variants 覆盖 mode/TSR legality、false-closed positive control、"
    "head0/lane1 routing、PC/tval，另有 2/2 zero-observer sensitivity 配置；全部动态拒绝且 source "
    "unchanged。模块 109/109、XRET 单测 10/10、永久入口 `make -C npc/rv64 check-xret-current-mode` "
    "双跑 result/raw/variant/module/focused/program SHA 全相同；result "
    "`26f29205929a75a9b824f1ab2b3ac938bb453b8e027f041a0f1e02b364d257a1`，design "
    "`sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`。九项 directed "
    "architecture GREEN；full-core `ARCH_STABLE=GAP/blockers=44`、`ppa=UNQUALIFIED`、"
    "`promotion_eligible=false`，且尚无同设计 full functional aggregate/完整 freeze inputs。"
)

AGENT_SYSTEM_ENTRY = (
    "- 2026-07-21（V9E architecture source-binding rebind）：**共享本地 RTL 验证入口文件变化时，"
    "不能只看 production RTL design_id；必须枚举每条证据的全部 source-binding section，并经更严格"
    "下游消费者 forward test**。新增独立 `check-xret-current-mode` Makefile target 后，九条 architecture "
    "gate 的动态 command/log/metric/status 与 RTL identity 均未变，但 `provenance.files` 哈希正确失配。"
    "首版 task-local repair 只更新九个 `provenance`，要求 pre-gate 仅两个 provenance check RED、每条"
    "唯一 live mismatch 为 Makefile、去除 source-binding 后 semantic projection 相同、candidate 9/9 "
    "GREEN 才原子替换；随后 arch-stable forward test 又捕获四个 optional `source_manifest` 仍绑定旧"
    "哈希。该首轮 coverage gap 原样保留，工具修正为遍历 `provenance` 与 `source_manifest`、复核旧"
    "aggregate、自身文件 live hash 和 post-gate GREEN。另以 byte-level reconstruction 删除唯一 10 行/"
    "598-byte XRET target block，精确重建旧 Makefile SHA，证明允许路径内没有无关字节变化。规则："
    "来源重绑必须同时给出 exact allowed path、actual byte delta、non-source-binding projection、pre/post "
    "consumer 状态和未重跑动态证明的准确声明；不能用手工 JSON 改写或把首轮 GREEN 覆盖掉后续"
    "反例。子 agent 继续用 local RV64 module/signal/transaction/EDA 精确措辞、hash-bound JSON contract "
    "和 self-contained no-tools review；这是减少领域歧义，不改变审查规则或模型推理能力。"
)


def load_stored(path: str) -> str:
    proc = subprocess.run(
        [
            sys.executable,
            str(INDEX),
            "load",
            "--source",
            "stored",
            "--path",
            path,
            "--max-tokens",
            "20000",
            "--json",
        ],
        cwd=REPO,
        check=True,
        capture_output=True,
        text=True,
    )
    chunks = json.loads(proc.stdout)
    if not chunks:
        raise RuntimeError(f"no stored chunks for {path}")
    return "\n".join(str(chunk["text"]) for chunk in chunks).rstrip("\n") + "\n"


def insert_after_marker(content: str, marker: str, identity: str, entry: str) -> tuple[str, bool]:
    if identity in content:
        return content, False
    needle = marker if marker.endswith("\n") else marker + "\n"
    if content.count(needle) != 1:
        raise RuntimeError(f"expected one insertion marker: {marker}")
    return content.replace(needle, needle + entry + "\n", 1), True


def upsert_identity_entry(
    content: str,
    marker: str,
    identity: str,
    entry: str,
) -> tuple[str, bool]:
    lines = content.rstrip("\n").splitlines()
    matches = [index for index, line in enumerate(lines) if identity in line]
    if len(matches) > 1:
        raise RuntimeError(f"duplicate identity lines: {identity}")
    if matches:
        index = matches[0]
        if lines[index] == entry:
            return content, False
        lines[index] = entry
        return "\n".join(lines) + "\n", True
    return insert_after_marker(content, marker, identity, entry)


def collapse_adjacent_duplicate_list_lines(content: str) -> tuple[str, bool]:
    output: list[str] = []
    changed = False
    for line in content.rstrip("\n").splitlines():
        if output and line.startswith("- ") and line == output[-1]:
            changed = True
            continue
        output.append(line)
    return "\n".join(output) + "\n", changed


def update(path: str, marker: str, identity: str, entry: str) -> None:
    current = load_stored(path)
    current, deduplicated = collapse_adjacent_duplicate_list_lines(current)
    updated, changed = upsert_identity_entry(current, marker, identity, entry)
    if not changed and not deduplicated:
        print(f"PASS memory unchanged path={path} identity={identity}")
        return
    proc = subprocess.run(
        [sys.executable, str(INDEX), "update-stored", path, "--stdin"],
        cwd=REPO,
        check=True,
        input=updated,
        text=True,
        capture_output=True,
    )
    print(proc.stdout.strip())


def main() -> int:
    update(PROJECT_PATH, PROJECT_MARKER, PROJECT_IDENTITY, PROJECT_ENTRY)
    update(NPC_PATH, NPC_MARKER, NPC_IDENTITY, NPC_ENTRY)
    update(
        AGENT_SYSTEM_PATH,
        AGENT_SYSTEM_MARKER,
        AGENT_SYSTEM_IDENTITY,
        AGENT_SYSTEM_ENTRY,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
