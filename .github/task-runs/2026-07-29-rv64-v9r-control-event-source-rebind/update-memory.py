#!/usr/bin/env python3
"""Publish stable V9R source-rebind facts through the DB-owned memory API."""

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
        "## 2026-07-29 RV64 V9R current-source evidence closure",
        """## 2026-07-29 RV64 V9R current-source evidence closure

- 当前 RV64 design-id 保持 `sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`。`OooIntBackend.v` 与 `OooMemAxiBridge.v` production SHA-256 在 current-source replay 前后不变；V9R SQ-query retry C0 baseline 2/2 PASS，bank0/bank1/bridge 三个 compile-success RTL 负向版本分别由 `@18/@39/@24` raw assertion 拒绝。
- V9O evidence-index 为 167/167 PASS，verification-id 为 `sha256:5e8107e641f459131fc86220a84ef206870ebc773cc6931ecc65921d8b1c4a92`。16 个 CLOSED debt 当前绑定 38 个 artifact 和 32 个 canonical semantic check，failures=0。
- `SERIALIZE-G1` publisher/currentness 已改为 schema-aware exact tuple：candidate、independent contract、review report 的 kind/path/order/fixed SHA-256 必须逐项相等，missing/extra/remapped evidence 均在 ledger hash refresh 前 fail closed。泛化的非 JSON 例外不能绕过该 tuple identity。
- postflight 在开始校验时先发布 `GAP validation_not_completed`，仅在 architecture currentness 48/48、historical backfill 4/4、task-local workflow 20/20、V9O index 与 SERIALIZE verifier 的日志、返回码、测试数和终端 marker 全部通过后重新发布 PASS。v1 reviewer 准确发现旧 48-test rc=1、缺少 task-local receipt 和 bridge TB 合同；修复后的隔离 v2 reviewer 给出 `APPROVED_FOR_CURRENT_SCOPE`。
- A3 原始 published state 仍为 `FAIL rc=1`；其 execution/DUT terminal/binding/raw input/RTL assertion 为 `COMPLETE/COMPLETE/NO_DRIFT/VALID/CLEAN`，旧 dmesg oracle 把 `printk: debug:` 误判。frozen-input checker replay 为 PASS 且正向接受该行、负向拒绝真正 `BUG:`；没有修改 A3 历史状态，也没有触发 production/elaboration/device-model/simulator-semantics/required-input 的完整重跑条件。
- historical backfill 当前 `VD0=0, VD1=0, selected=NONE`，但 full architecture freeze 仍有 33 个 inventory/census/proof-depth blocker；因此 `ARCH_STABLE=GAP`、`PPA=UNQUALIFIED`、promotion=false。当前 PASS 只闭合 source/evidence workflow 子范围。""",
    ),
    Update(
        ".github/memory/modules/npc.md",
        "## RV64 SQ-query retry current-source contract V9R",
        """## RV64 SQ-query retry current-source contract V9R

### C0 transaction 合同

- 在 edge-old full-flush barrier 周期，`OooIntBackend` 两路 SQ-query retry-ready/capture/fire 与 `OooMemAxiBridge.S_SQ_QUERY` handoff 必须被阻断，MIQ/SQ owner 保持；barrier 撤销后才允许精确 handoff。不得用 terminal 去重或弱化断言掩盖重复/提前事件。
- current production SHA-256 为 `OooIntBackend.v=49ec3d7eff22e4146be35bf1a0e56e7c57c7a3418ae4bc6fa0e65d34d83cca5a`、`OooMemAxiBridge.v=2d6f33182e02e516e03864849e6d7299db44163a847b814f88ba8ea8d821a062`。验证源绑定必须同时覆盖 `testbench/Makefile`、`tb_ooo_int_backend.sv` 和 `tb_ooo_mem_axi_bridge.sv`。
- 当前 raw oracle 为 baseline 2/2 PASS；bank0、bank1、bridge 三个 compile-success RTL version 分别在 `@18/@39/@24` 被拒绝，3/3 PASS。V9O index 167/167，closed-debt currentness 为 16/38/32/0。

### A3 与晋级边界

- A3 定义为“系统 transaction 完成、旧 dmesg oracle 误判”，但原始 `FAIL rc=1` 永远保留。冻结 dmesg/console replay 只发布独立 checker PASS，不反写旧状态；checker 必须接受 `printk: debug:` 并拒绝真正 `BUG:`。
- 只有 production core RTL 语义、当前配置下实际 elaborated RTL、device model/simulator execution semantics 发生变化，或 A3 缺少原始输入、terminal chain、post-hash，才要求完整系统重跑。
- historical `VD0/VD1` 已清零并不等于 whole-core freeze；当前仍有 33 个 inventory/census/proof-depth blocker，故 `ARCH_STABLE=GAP`、`PPA=UNQUALIFIED`。""",
    ),
    Update(
        ".github/memory/modules/agent-system.md",
        "## Schema-aware RTL evidence publication and receipt closure",
        """## Schema-aware RTL evidence publication and receipt closure

- CLOSED RV64 debt 的 publisher 必须先验证 evidence identity，再刷新通用 hash。若一个 debt 使用 candidate/contract/review 混合 tuple，应由单一 canonical verifier 导出 exact kind/path/order/fixed SHA-256；missing、extra、remapped、reordered 或 hash-drifted member 都要在写 ledger 前失败。
- “raw log 只做 hash”“JSON 检查 design-id/status”“review Markdown 由 canonical tuple 校验”是三种显式 evidence kind，不得把所有非 JSON 文件放进广义例外。currentness 还必须运行 canonical architecture semantic check，不能只证明文件存在和 hash 当前。
- postflight 不能从若干上游 JSON 直接合成 PASS。开始时应先撤销旧 PASS，随后消费每个定向 suite 的 `.log` 与 `.rc`、唯一测试数、`OK` terminal 和禁止的 `FAILED/Traceback` marker；index/verifier receipt 也要绑定 design-id、artifact count 与精确 PASS marker。
- 独立 reviewer 合同须列全 production RTL、实际 Makefile/filelist、所有参与 oracle 的 testbench 源码和 receipt；漏列一个 TB 时只能 GAP。reviewer 发现的假绿应先保留原报告，再用 versioned contract 复核，不得追认旧候选 PASS。
- Windows→WSL 工程命令继续 single-flight。外层超时中断的 attempt 使用独立 status/log 路径保留，后续 attempt 不覆盖；无残留进程后才重新取得 shell ownership。硬件技术正文使用 module/signal/transaction、cycle/config、TB/EDA marker 与 PASS/GAP 范围，协调状态单独记录。""",
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
            "120",
            "--max-tokens",
            "60000",
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
