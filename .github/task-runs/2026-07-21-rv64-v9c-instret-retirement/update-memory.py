#!/usr/bin/env python3
"""Publish the stable V9C INSTRET conclusion through the DB-owned memory API."""

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
PROJECT_IDENTITY = "RV64 V9C INSTRET retirement closure"
NPC_IDENTITY = "RV64-v9c-instret-retirement"
AGENT_SYSTEM_IDENTITY = "V9C task-specific e2e DB-first focus ordering"

PROJECT_ENTRY = (
    "- [2026-07-21] **RV64 V9C INSTRET retirement closure 已在当前同设计证据上关闭 INSTRET-G1；"
    "长期完整 OoO/PPA 目标继续 active**。production RTL 未修改；"
    "`OooCommitOutputMux` 以最终可见双提交 lane 的 `valid && !exception` population count 作为唯一"
    "`retire_count_o`，`NpcCoreTop` 只把该计数接入 `CsrFile.instret_inc_i`。Sv39 程序精确观察"
    "2 个异常 lane 各增量 0、MRET 1 次/SRET 6 次/SFENCE.VMA 1 次各增量 1、1052 个 CSR prior-edge"
    "检查；模块聚合 109/109、focused 3/3、compile-success 本地 RTL 验证变异 3/3 动态拒绝、"
    "相关 Python 单测 46/46。永久入口 `make -C npc/rv64 check-instret-retirement` 绑定 design "
    "`sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`；九项定向架构 gate "
    "GREEN，但 full-core `ARCH_STABLE=GAP` 且仍有 45 个 blocker，`ppa=UNQUALIFIED`、"
    "`promotion_eligible=false`。hash-bound no-tools reviewer 判 PASS、无 P0/P1，并保留 program-level "
    "lane-1 异常非空性、prior-edge 说明和本地证据 provenance 边界三项 P2。证据 "
    "`.github/task-runs/2026-07-21-rv64-v9c-instret-retirement/`。"
)

NPC_ENTRY = (
    "- 2026-07-21(RV64-v9c-instret-retirement): **INSTRET-G1 在最终同设计上 CLOSED；production RTL 未改，"
    "full-core arch-stable/PPA 仍未晋级**。owner/source-of-truth 是 `OooCommitOutputMux` 最终可见 lane："
    "`retire_count_o=popcount(commit_valid && !commit_exception)`，随后唯一连接到"
    "`NpcCoreTop.CsrFile.instret_inc_i`；core-local 预 mux 计数不得进入 CSR。Sv39 full-core 程序给出精确"
    "event inventory：`exception_lanes=2 exception_zero_delta=2 mret=1 sret=6 sfence_vma=1 "
    "control_exact=8 control_total=8 csr_delta_checks=1052`，并由最终 `minstret` 聚合等式关闭尾拍。"
    "109/109 动态派生模块测试、3/3 focused 和 3 个 compile-success 当前源码 RTL 变异均通过预期判定；"
    "evidence builder/arch-stable validator 现场复算全部 RTL identity、source/log SHA、程序事件、模块"
    "membership 与变异源码。永久入口 `make -C npc/rv64 check-instret-retirement`，design "
    "`sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`；"
    "`INSTRET-G1=CLOSED` 只覆盖 reset 退出、`mcountinhibit.IR=0`、无软件写 `minstret` 的当前合同，"
    "不外推 WFI、程序级 FENCE.I、inhibit 切换、软件写/overflow 或 full-core promotion。当前九项定向"
    "architecture GREEN，`ARCH_STABLE=GAP/blockers=45`、`ppa=UNQUALIFIED`、"
    "`promotion_eligible=false`。证据 `.github/task-runs/2026-07-21-rv64-v9c-instret-retirement/`。"
)

AGENT_SYSTEM_ENTRY = (
    "- 2026-07-21（V9C task-specific e2e DB-first focus ordering）：**task slug 的领域词必须先有当前"
    "non-history 独立 focus，不能由同一旧 task-run 自证**。反例 "
    "`.github/task-runs/2026-07-21-rv64-instret-retirement-closure-revtag-v9c/` 在五个 NPC 合同节点"
    "5/5 PASS 时仍因 `no independent primary focus match` 正确保持 blocked；根因是当时 INSTRET 稳定"
    "结论尚未通过 `update-stored` 进入 module memory，且多出的 `closure` 不存在于独立 focus。"
    "`project-status` 属于 core chunk，不能单独替代独立 focus。先用官方 `update-stored` 发布"
    "`.github/memory/modules/npc.md`，再把 slug 收敛到确实存在的 `rv64 instret retirement` 后，"
    "bounded brief 命中该 module chunk 并 complete；随后 `npc-dev` 5/5、`agent-system` 10/10、"
    "`github-index` 1/1 均完成原子 publication。稳定顺序是：业务证据闭合 → DB-owned module memory "
    "发布 → 同领域词 task-specific e2e → strict guard。该规则保留 non-history fail-closed、历史隔离和"
    "全部节点验证强度，只消除收尾顺序歧义；blocked 反例保留审计但不计为完成证据。"
)


def load_stored(path: str) -> str:
    proc = subprocess.run(
        [sys.executable, str(INDEX), "load", "--source", "stored", "--path", path, "--json"],
        cwd=REPO,
        check=True,
        capture_output=True,
        text=True,
    )
    chunks = json.loads(proc.stdout)
    if not chunks:
        raise RuntimeError(f"no stored chunks for {path}")
    content = "\n".join(str(chunk["text"]) for chunk in chunks)
    return content.rstrip("\n") + "\n"


def insert_after_marker(content: str, marker: str, identity: str, entry: str) -> tuple[str, bool]:
    if identity in content:
        return content, False
    needle = marker if marker.endswith("\n") else marker + "\n"
    if content.count(needle) != 1:
        raise RuntimeError(f"expected one insertion marker: {marker}")
    return content.replace(needle, needle + entry + "\n", 1), True


def update(path: str, marker: str, identity: str, entry: str) -> None:
    current = load_stored(path)
    if path == PROJECT_PATH:
        current = current.replace(
            "本地 honest-producer 信任边界",
            "本地证据 provenance 边界",
        )
    updated, changed = insert_after_marker(current, marker, identity, entry)
    persisted = load_stored(path)
    if not changed and current == persisted:
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
