#!/usr/bin/env python3
"""Publish stable V9N facts through the DB-owned update-stored API."""

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
        "## 2026-07-23 RV64 V9N STORE/AMO owner next-edge residency",
        """## 2026-07-23 RV64 V9N STORE/AMO owner next-edge residency

- 当前 RV64 双发射 OoO 生产 RTL design-id 保持 `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`；本轮未修改生产 `.v` RTL，新增的是 verification wrapper、可编译 RTL 源码变体、证据生成/校验和组合回放规则。
- `STORE-BRESP-G1` 新增独立 next-edge owner residency 证据：STORE/AMO focused 2/2、compile-success source variants 2/2 动态拒绝、evidence 单测 8/8。result/raw SHA-256 分别为 `34090add201aece110bc3423fec7460e33cecb35ce2da1ac73ca788a7cb0d709` 与 `379d16ebbe790b80315943d2420581c9446c8690ffcd076ab1aba44b592e1746`。
- 最终 canonical 9 门架构链全 GREEN，模块聚合 109/109，受共享验证文件影响的 10 个局部架构债务 target 全部重放；arch-stable 135/135 单测 PASS，当前仍为诚实 `GAP`、38 blockers、PPA `UNQUALIFIED`、promotion=false。
- V2 独立 reviewer 未发现 STORE/AMO 局部 RTL 反例，但发现其 dispatch 记录在旧 owner evidence 之后追加且属于 provenance，因而旧证据必须判 freshness GAP。冻结终审记录后已从 9 门顶层完整 canonical 回放并重跑 arch-stable；稳定规则是 provenance 内协调记录必须先冻结，发生后置字节变化时重放叶证据及上层聚合，禁止仅更新 ledger hash。
- 长期 RV64 OoO/PPA goal 保持 active；本切片不外推为全核 freeze 或 PPA promotion。""",
    ),
    Update(
        ".github/memory/modules/npc.md",
        "## RV64 STORE/AMO next-edge owner residency V9N",
        """## RV64 STORE/AMO next-edge owner residency V9N

### 稳定微架构合同

- `OooStoreQueue` 的 plain STORE 在 physical request fire 后、exact SQ terminal 接受前，下一拍必须保留 `valid/owner_valid/request_sent/!terminal`、full ProducerId、owner token 与 MMU epoch；SQ release、ROB early-done、checkpoint recovery 或无 terminal 的 holder 清除都不能结束该期待。
- `OooIntBackend` 的 AMO singleton 在 write fire 后、exact final response 前，下一拍必须保留 `mem_pending_q/mem_amo_q/mem_amo_write_sent_q` 与完整 owner tuple。canonical `NpcCoreTop.u_ooo_core.flush_i=1'b0` 静态排除 leaf global-flush 清除路径；该事实不得外推到其它装配。
- checker 必须在每个时钟沿先比较上一拍 shadow，再捕获本拍 launch，从而跨过 NBA 更新观察 Q；既有 holder-qualified same-edge assertion 不能替代该 next-edge 不变量。

### 当前证据与边界

- current design-id 为 `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`。focused STORE/AMO 2/2；`sq_clear_owner_valid_on_request_fire` 与 `amo_clear_kind_on_write_fire` 两份 compile-success RTL 源码变体均只由 V9N checker 精确拒绝，旧 V9L 同沿 assertion 保持 quiet；证据单测 8/8。
- result/raw SHA-256 分别为 `34090add201aece110bc3423fec7460e33cecb35ce2da1ac73ca788a7cb0d709` 与 `379d16ebbe790b80315943d2420581c9446c8690ffcd076ab1aba44b592e1746`。`arch_stable_freeze.py` 从 live RTL 重构两份变体并独立校验唯一失败 oracle、source/artifact/provenance hash 与 top binding。
- canonical 9 门 architecture aggregate 为 GREEN，arch-stable 135/135 单测通过；full-core 仍为 GAP/38 blockers，PPA UNQUALIFIED、promotion=false。该动态证据不等价于全状态空间形式化证明，也不产生面积、频率或功耗改善结论。""",
    ),
    Update(
        ".github/memory/modules/agent-system.md",
        "## 2026-07-23 RTL review provenance finalization",
        """## 2026-07-23 RTL review provenance finalization

- V9N 终审证明：若 `dispatch-log.md`、review contract 或其它协调记录列入 evidence `SOURCE_PATHS`，必须在最终 canonical 证据生成前冻结。reviewer 结果若在证据之后追加，即使 RTL、focused log 与变体语义均正确，live provenance 也必须判 GAP；修复动作是重放叶证据及受影响的上层 architecture aggregate，再由下游 validator 重构验证，不能只改 ledger SHA。
- canonical 子 agent 流程保持 `create → validate → render`，V2 合同 SHA 为 `de35267426484ede9e84b382cb29c107656f02fb069baaf8593965289a515315`。WSL single-flight ownership 必须用协调消息明确交接与归还；技术 prompt 原样保持本地 RV64 module/signal/transaction/cycle、RTL/spec/TB/evidence 输入和 `rg`/`sed` 只读能力，不把协调状态混写为硬件目标。
- 本轮 V2 reviewer 正是通过上述独立检查发现 freshness GAP；主 agent 冻结记录后完成 9 门 canonical 回放与 135 项 arch-stable 单测。该规则提高证据时间序完整性，不建立关键词黑名单，不改写真实 RTL 标识符，也不削减 workspace exploration、负向 RTL 源码变体、unknowns、反例、scope extension 或 PPA 分析能力。""",
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


def upsert_section(document: str, update: Update) -> tuple[str, bool]:
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
    updated, changed = upsert_section(document, update)
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
