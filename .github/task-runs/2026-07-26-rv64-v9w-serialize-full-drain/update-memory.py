#!/usr/bin/env python3
"""Publish stable V9W facts through the DB-owned update-stored API."""

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
        "## 2026-07-26 RV64 V9W pending-system canonical kind",
        """## 2026-07-26 RV64 V9W pending-system canonical kind

- 当前本地 RV64 双发射 OoO RTL design-id 为 `sha256:1252332b723017ab370ee6a49d945ad86dce1f2e5b585aaea4dccb7388a79702`。`OooPendingSystemSequencer` 已用单一 `kind_q` 保存 `CSR/ECALL/XRET/WFI/SFENCE_FAMILY/FENCEI/FENCE/IRQ`，公开类型、普通 FENCE drain 与 SFENCE/SINVAL/FENCE.I redirect 均从 holder 投影。
- 当前设计证据：双 lane 非 IRQ 类型矩阵 14/14、focused 2/2、layered 6/6、compile-success RTL variants 4/4 精确拒绝、module 111/111、official 177/177、AM 59/59、DiffTest mismatch 0、canonical architecture 9/9 GREEN。
- AI 工作流证据：`npc-dev` 5/5、`agent-system` 11/11 PASS；双角色检查以 `实现者`、`审查者`、`双角色复核` 三个语义锚点接受等价专业措辞，并保留缺失复核锚点的负向反例。strict guard 仅因 `rv64-linux` 没有完成态 PASS evidence 保持 FAIL。
- 当前 `rv64-linux` 为 7 PASS / 1 FAIL：同一 design-id 的 simulator SHA-256 为 `4b0be491fbe1305e79bbaf599787f1321c8ac7dcc8ea5236a23a735edda8441d`；rootfs 在 1200 秒内推进到 Linux 0.059199 秒的 EFI 初始化后 `exit=124`，未到 virtio/EXT4/VFS/systemd/Ubuntu/hostname/terminal marker，且没有 RTL assertion-failure marker。该记录是系统时限 GAP，不是 RTL FAIL 或 rootfs PASS。
- 实现者与独立 reviewer 均只给出 canonical kind、CSR ProducerId lease、typed redirect 的局部 PASS。`SERIALIZE-G1` 保持 P1/OPEN；recovery cross-product、真实 memory-owner terminal 与七类 transaction exactly-once 仍为 GAP。
- final arch-stable audit 有 32 blockers；PPA 保持 `UNQUALIFIED`、promotion=false。本轮未增加 terminal-event 去重、未削弱 assertion，也未从局部架构证据外推 synthesis/STA/PPA 结论。""",
    ),
    Update(
        ".github/memory/modules/npc.md",
        "## RV64 pending-system canonical type and typed redirect V9W",
        """## RV64 pending-system canonical type and typed redirect V9W

### 稳定微架构合同

- `OooPendingSystemSequencer.kind_q` 是 serialized SYSTEM/CSR/IRQ 类型的唯一注册真源；`valid_o` 当且仅当 kind 非 NONE，valid holder 的八个公开类型 exact-one。非空 holder 不接受 recapture，kind/payload 保持到授权 clear/death。
- 普通 FENCE 由 holder 输出 `fence_o`，`OooControlPlane` 不得再从 raw instruction 建立第二类型真源。SFENCE.VMA/SINVAL family 与 FENCE.I 的 redirect reason 必须消费 exact holder-derived commit pulse。
- CSR ProducerId lease 只在 CSR dispatch birth，必须由 matching PID+PC commit death 或 backend-global reset 终止；非 CSR serialized transaction 不制造 ProducerId。

### 当前证据与边界

- current design-id 为 `sha256:1252332b723017ab370ee6a49d945ad86dce1f2e5b585aaea4dccb7388a79702`。两 lane × 七类非 IRQ capture/hold/clear 为 14/14；SINVAL 产生 SFENCE reason、FENCE.I 产生 FENCEI reason；四个 compile-success RTL 变体分别验证 onehot、kind-valid 与两条 typed redirect oracle。
- focused 2/2、layered 6/6、module 111/111、architecture 9/9 GREEN。该证据只关闭 canonical type/typed redirect 局部切片。
- 当前 `rv64-linux` 绑定相同 design-id 与 simulator SHA-256 `4b0be491fbe1305e79bbaf599787f1321c8ac7dcc8ea5236a23a735edda8441d`：7 个前置节点 PASS，rootfs 节点在 Linux 0.059199 秒、EFI 初始化后达到 1200 秒 host boundary；未看到 mount/systemd/terminal 或 RTL assertion-failure marker。因此它只增加 forward-progress 边界，不关闭 serialized terminal transaction。
- `SERIALIZE-G1` 仍为 OPEN：尚需七类 × 两 lane × holder phase × recovery source 的交叉反例、`core_mem_idle_w/core_mem_retire_quiet_w` 真实 owner 终态，以及 commit/trap/return、redirect、holder/stop clear、MMU flush、bridge terminal 的 exactly-once 联合观测。禁止用 terminal 去重或 assertion 降级掩盖重复/幽灵事件。
- full-core architecture freeze 保持 GAP/32 blockers，PPA UNQUALIFIED、promotion=false。""",
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
