#!/usr/bin/env python3
"""Prepare retained-memory documents for DB-owned update-stored publication."""

from __future__ import annotations

import json
import pathlib
import subprocess
from dataclasses import dataclass


ROOT = pathlib.Path(__file__).resolve().parents[3]
RUN_DIR = pathlib.Path(__file__).resolve().parent
STAGING = RUN_DIR / "memory-staging"
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
        "## 2026-07-22 RV64 V9L functional aggregate and memory ownership",
        """## 2026-07-22 RV64 V9L functional aggregate and memory ownership

- 当前 RV64 双发射 OoO 生产 RTL design_id 为 `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`。本轮生产 RTL 修正了三项同一内存所有权合同：ROB head 的“可发射”与“发射后仍持有精确 owner”分离；SQ 的 AMO post-launch 检查在 recovery 期间继续要求 exact head/full ProducerId owner；AXI bridge 的 station lookup 只在当前 response credit 可前进时允许，并把 retry residency 限定为同一 exact token，而不是禁止同 bank 的不同 token 同时驻留。
- `F0-G1` 已在当前 design-id 关闭：模块测试 `109/109`、official `177/177`、AM cpu-tests `59/59` 且 DiffTest mismatch `0`、CoreMark `ITERATIONS=10`/CRC `0xfcaf`/GOOD TRAP、Dhrystone `mainargs=10000`/GOOD TRAP；功能证据变体 `11/11` 编译并被拒绝。functional result/aggregate SHA-256 分别为 `3e632a4a8f00ab8d69fc880c8a1e3e8fbf0cbedf240b25a400a8a06f0c25f296` 与 `c09c03742fc26dd99ff638baaf2848496328ee264340f8c9f05f08a5df202793`。
- V9L current-source RTL 验证变体 `4/4` 编译成功并被对应断言拒绝；V8L holder 生命周期 `8/8` 正向基线和 `9/9` 编译成功 RTL 变体通过。V8L 汇总只规范化 runner 自有 `/tmp/v8l-global-lease.*` 路径，两次从零重放的 lifecycle/mutation 产物字节一致，SHA-256 分别为 `82143f9e166465572fc58cdf42c3d07b4a3e9d1d3a78224edb2b9748c6b43a97` 与 `494048b7248b2b1d3c76c3c034c91003fb102b1677ab4e0b0919cb8bc773b707`。
- 九个 directed architecture gates 已按当前清单重放并全 GREEN；`architecture-current.json` 与 hard-gate result SHA-256 分别为 `a364e78b6e7fbc92619cb8c09ee33e3732ad7186f84597db6f4c24d8c357c6b1`、`2e501a4cb367d02b77cecdfbb14f439ba8e02cf2707fab24aa2f721226e0ba70`。arch-stable 审计 `134/134` 单测通过，当前结果仍为诚实 `GAP`、`39` blockers、PPA `UNQUALIFIED`、`promotion_eligible=false`；其 SHA-256 为 `784b4953c1db766e4e8efa5a4189d770a6b88d886e86eecdd09e51a741966b00`。
- 12 个已关闭架构债务均已重绑当前 design-id；仍开放的是明确记录的架构语义/范围决策、完整 census、cohort inventory 与 freeze inputs。长期 goal 保持 active，不能把 F0 或 9 个定向门外推为 `ARCH_STABLE` 或 PPA 晋级。""",
    ),
    Update(
        ".github/memory/modules/npc.md",
        "## RV64 V9L memory ownership and current functional aggregate",
        """## RV64 V9L memory ownership and current functional aggregate

### 稳定微架构合同

- `rob_head_launch_open_o` 只授权新的 AMO/SQ request launch，包含 flush/recovery quiet 条件；`rob_head_owner_open_o` 表示当前 exact ROB head 仍 valid 且 unfinished，供已经 launch 的事务在 recovery 期间保持 owner。两者不能互换，post-launch owner 检查必须使用后者并同时比较 ROB index 与 full ProducerId。
- `OooMemAxiBridge` 的 station allow 与 lookup 必须由同一 `rsp_ready_w` response credit 决定；没有 response credit 时不得发起 lookup。retry bank 与 station 可以保存不同 token，禁止项仅是同一 exact retry token 同时出现在 retry Q 与 active/station owner 中。
- 对应生产断言为 `[V9L-SQ-POST-LAUNCH-OWNER]`、`[V9L-SQ-LOOKAHEAD-CREDIT]` 与 `[V9L-RETRY-OWNER-DISJOINT]`；V9L 四个 current-source 编译成功 RTL 变体分别切断这些合同并全部被动态拒绝。

### 当前证据与边界

- current design-id 为 `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`。canonical functional aggregate 为模块 `109/109`、official `177/177`、AM `59/59`、DiffTest mismatch `0`、CoreMark 10/CRC `0xfcaf`、Dhrystone 10000，F0 evidence mutations `11/11`。
- `npc/sim/Makefile` 的递归 backend 调用显式传递 `NPC_HOME=$(BACKEND_DIR)`；外层 AM/NPC 环境中的 platform-root `NPC_HOME` 不再污染 rv64 backend 子 make。该修正属于构建入口绑定，不改变处理器 RTL。
- V8L holder evidence 在 assert/release 共 `8/8` 基线及 `9/9` 编译成功 RTL 变体上通过；汇总产物只替换 runner 自有随机临时目录，并经连续两轮 SHA 文件 `cmp` 验证确定性。producer-holder census 仍保留 `instance_graph_complete=false`、`semantic_complete=false` 和非 GREEN 状态，局部动态证据不提升整核 census。
- 九个 directed architecture gates 为当前 design-id 全 GREEN，arch-stable 审计 `134/134` 单测通过；完整冻结仍为 `GAP`、39 blockers，PPA `UNQUALIFIED`。长期 goal 继续 active。""",
    ),
    Update(
        ".github/memory/modules/am-kernels.md",
        "## 2026-07-22 RV64 current-design aggregate",
        """## 2026-07-22 RV64 current-design aggregate

- 同一 RV64 OoO design-id `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2` 下，AM cpu-tests `59/59` 全部 GOOD TRAP，DiffTest mismatch 为 `0`；CoreMark `ITERATIONS=10` 的 CRC 为 `0xfcaf` 且 GOOD TRAP，Dhrystone `mainargs=10000` GOOD TRAP。这些结果属于 F0 功能聚合，不是性能或 PPA 晋级证据。
- `npc/sim/Makefile` 递归进入 RV64 backend 时显式传递 `NPC_HOME=$(BACKEND_DIR)`，避免调用方继承的 AM platform-root `NPC_HOME` 使 backend make 解析到错误目录。功能聚合器同时绑定 simulator/config、每个 AM/official image、唯一原始日志和 NEMU reference binary，并用 11 个证据变体验证缺失、重复、替换、旧哈希与清单漂移均 fail closed。""",
    ),
    Update(
        ".github/memory/known-issues.md",
        "### [122] V8L 汇总直接绑定随机临时编译路径会造成重复运行哈希漂移（2026-07-22）",
        """### [122] V8L 汇总直接绑定随机临时编译路径会造成重复运行哈希漂移（2026-07-22）

- **症状**：`check-global-producer-no-live-reuse` 连续两次 `8/8` baseline、`9/9` compile-success RTL variant 均通过，但 holder lifecycle 汇总 SHA-256 不同；mutation 结构化摘要本身稳定。
- **根因**：baseline 与 mutation 的编译命令记录 runner 创建的 `/tmp/v8l-global-lease.<random>` build root。直接把原始日志 SHA 写入冻结汇总，会把非语义随机目录当成设计证据的一部分；第二轮从零运行因此使 manifest 中的 artifact hash 过期。
- **稳定门禁**：先完整检查原始日志的 PASS/FAIL marker、变体编译产物和独立失败后果，再仅把 runner 自有 `/tmp/v8l-global-lease.[A-Za-z0-9]+` 规范化为 `<V8L_TEMP>` 后生成被哈希绑定的日志。不得删除 assertion、RTL 路径、周期值、错误文本或其它未知字段；规范化后的 lifecycle/mutation 产物必须再做至少两次 canonical run 的字节级 `cmp`。
- **当前状态**：V8L 两次从零重放产物完全一致，lifecycle/mutation SHA-256 分别为 `82143f9e166465572fc58cdf42c3d07b4a3e9d1d3a78224edb2b9748c6b43a97`、`494048b7248b2b1d3c76c3c034c91003fb102b1677ab4e0b0919cb8bc773b707`；arch-stable 的 `census.dynamic_lifecycle_evidence` 为 PASS。本条是所有含 runner-owned 随机路径的 RTL 证据聚合通用风险，不表示仿真语义不确定。""",
        insert_after="## 活跃问题\n<!-- 当前未解决的问题 -->",
    ),
)


def load_document(path: str) -> str:
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
    anchor = update.insert_after
    if anchor is None:
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
    if document.count(anchor) != 1:
        raise RuntimeError(f"expected one insertion anchor in {update.path}")
    return document.replace(
        anchor,
        anchor + "\n\n" + update.section.strip(),
        1,
    )


def main() -> int:
    STAGING.mkdir(parents=True, exist_ok=True)
    for update in UPDATES:
        document = load_document(update.path)
        updated = insert_section(document, update)
        output = STAGING / pathlib.Path(update.path).name
        if output.exists():
            output = STAGING / (pathlib.Path(update.path).parent.name
                                + "-" + pathlib.Path(update.path).name)
        output.write_text(updated, encoding="utf-8")
        print(f"[V9L-MEMORY-STAGING][PASS] {update.path} -> {output.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
