#!/usr/bin/env python3
"""Persist reviewed S2-Q1/Q2 and AI-workflow closure through DB-first APIs."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


RUN_DIR = Path(__file__).resolve().parent
REPO_ROOT = RUN_DIR.parents[2]
INDEX_CLI = REPO_ROOT / "scripts" / "github_index_db.py"


PROJECT_Q1_ENTRY = (
    "- [2026-07-18] **RV64 PPA 架构恢复 S2-Q1：`OooMmuEpochOwner` source-catalog adoption "
    "无条件 GREEN；live integration 继续 RED**。唯一 canonical runner 的 release/assert 正例 2/2、"
    "完整消息 assertion-negative 4/4、compile-success exact-oracle mutation 7/7、release/assert lint、"
    "style、Yosys、adoption checker 全 PASS；fresh module aggregate 104/104 PASS。首轮 aggregate 暴露"
    "并关闭 `tb_ooo_priv_system` typed-response/owner 悬空 X：TB 复用真实 `OooTypedPmaChecker` 并锁存"
    "request provenance，未关闭断言。`adoption-sources.sha256` 9/9 OK，manifest `b621e47a…f9757f12`；"
    "独立复核的 P0/P1/P2 均关闭。Q1 仍未 live instantiate；precommit/effective classifier、selective "
    "squash、backend/SQ/bridge/IFU full quiet、grant-time apply/invalidate/LR clear、dynamic epoch/wrap、"
    "双 memory、Linux、200MHz 与 PPA 仍 RED/unqualified。"
)

PROJECT_Q2_ENTRY = (
    "- [2026-07-18] **RV64 PPA 架构恢复 S2-Q2：mem0-only contract/checker hardening checkpoint 已归档，live "
    "implementation RED**。状态顺序固定 `CAPTURE→SQUASH→WAIT_QUIET→GRANT`：先按 held ROB age "
    "selective squash younger SQ/IFU，再等 registered backend/SQ/bridge/IFU quiet；full quiet 禁止回灌 "
    "ROB `mem_quiet_i`，任何 potential boundary 禁止 commit1。CsrFile 必须 prepare normalized old→next、"
    "收编 legacy CSR/trap/xRET context writer，并在同一 grant fire 执行 apply/typed invalidate/LR clear/"
    "pending/redirect/epoch+1；capture block 只 gate 新 owner，旧 transport 必须 drain。v7 manifest 还锁定"
    "held-head exact equality、sticky owner/CSR shared abort、registered writer reserve+defer、generation-matched "
    "sticky IFU ack、独立 FENCE.I store+IFU serialization、named DTLB/ITLB/FPC/redirect/PC leaf、typed mask、"
    "active-source、精确 packed range、concrete payload/cause 宏值、registered quiet/memory ack、真实 IFU leaf、"
    "grant 原子 consumer、valid epoch capture、全实例名、全 procedural writer 唯一性与 SQ fill epoch 真实 mux；"
    "release/OOO_ASSERT active/elaborated 双变体、exact FENCE.I/MIQ/true memory-leaf producer、exact payload、"
    "guarded epoch/ROB/irrevocable storage/reset-arm、set-dominant squash completion、internal conditional/"
    "replicated-generate、任意深度 concat 与 imported/package/hierarchical task actual 也已 fail-closed。v7 进一步"
    "锁死 canonical `rst`、精确 `@(posedge clk)`、完整 ancestor guard path、module lexical declaration/source/"
    "reset/next binding；精确组合驱动只接受 module-scope continuous/net assignment，拒绝 initializer 与"
    "procedural continuous assign；任意 generate shadow、nested selector writer、embedded unknown/system task "
    "actual、unknown child/primitive driver、task-local port shadow 与 host/child-driven clk/rst 均 fail-closed；"
    "required ports 进入 critical-symbol audit，runner 锁定 28-path pre/post source snapshot。checker 自测 "
    "162/162；当前 live readiness 双变体各预期 `rc=1`、931 项 RED，聚合 1862 项，digest "
    "`fc5baa96190e9bcac70248f912523f8ae9192045885d6023b6cb940f4675a592`、contract lock "
    "`d830e31698425f431ad92fc907e2748b151399539e9736a0abfc0ee7d9d2d5fa` 与 baseline lock "
    "`abfe4e248f27e50d4f6cafc69f7429dba37e36544b3a5d6ec01248993ed1dc88` "
    "已锁定。该证据只证明下一实现接口缺口可审计，且尚不称 final freeze；不证明 selective squash、full "
    "quiet、abort/FENCE.I、lane1/IFU/stale/wrap 安全、双 memory、Linux 或 PPA。"
)

NPC_Q1_ENTRY = (
    "- 2026-07-18(RV64-PPA-S2-Q1): **standalone MMU epoch owner source-catalog adoption GREEN；live "
    "integration RED**。canonical 正例 2/2、命名负向 4/4、compile-success exact mutation 7/7、lint/"
    "style/Yosys/adoption 与 fresh 104/104 module aggregate 全绿；严格 pre-increment oracle、共享 PASS "
    "marker、唯一 filelist/Makefile/spec 入口均闭合。typed priv TB 的 floating response provenance 已以"
    "真实 PMA + owner/epoch/tval latch 修复。manifest 9/9 OK (`b621e47a…f9757f12`)，review P0/P1/P2 "
    "均关闭。leaf 尚未实例化，不能产生 live MMU、双 memory、Linux、时序/面积/功耗声明。"
)

NPC_Q2_ENTRY = (
    "- 2026-07-18(RV64-PPA-S2-Q2): **machine-mapped mem0 contract/checker hardening checkpoint；live RTL "
    "双变体聚合 1862 structural RED**。协议要求 head0 precommit + CsrFile normalized envelope、lane1 potential boundary "
    "禁退休、held-age memory/IFU squash 双 ack 后才 WAIT_QUIET、legacy context writer 唯一仲裁、registered "
    "quiet/no-ingress、grant-fire 真实 leaf consumers 与 valid-owner dynamic epoch；v7 另锁定 mismatch shared "
    "abort、registered writer reserve/defer、generation-matched IFU ack、FENCE.I retire serialization、trap CSR/LR/"
    "transaction unique-next、active-source、精确宽度/宏值、registered quiet/ack、真实 leaf、valid capture、"
    "全 writer 唯一性与 SQ epoch mux provenance；release/OOO_ASSERT elaboration、exact producer/payload、"
    "guarded epoch/ROB/irrevocable storage/reset-arm、set-dominant squash completion、internal conditional/"
    "replicated-generate、任意深度 concat 与 unknown task actual 也已锁定；并新增 canonical reset/event、"
    "完整 ancestor guard path、module lexical binding、module-scope continuous-driver-only、generate shadow、"
    "nested selector writer、embedded task actual、unknown child/primitive driver、lexical port/clk/rst ownership、"
    "required-port critical audit 与 pre/post source snapshot 约束。checker mutation 162/162，"
    "runner 锁定双变体各 931、聚合 1862 RED，"
    "`fc5baa96190e9bcac70248f912523f8ae9192045885d6023b6cb940f4675a592` digest、"
    "`d830e31698425f431ad92fc907e2748b151399539e9736a0abfc0ee7d9d2d5fa` contract lock 与 "
    "`abfe4e248f27e50d4f6cafc69f7429dba37e36544b3a5d6ec01248993ed1dc88` baseline lock；completion marker "
    "还绑定全部证据哈希，仅在全门通过后生成。"
    "当前 issue1 memory 仍常量关闭；该 checkpoint "
    "只用于下一原子实现和反例设计，不是功能/PPA GREEN。"
)

PROJECT_AI_ENTRY = (
    "- [2026-07-18] **AI 开发环境 v10：task-run 完成证据已闭合为 live-profile-bound bundle + "
    "transactional DB publication**。bounded recall 逐 chunk 绑定 canonical/profile/独立 focus、完整 metadata "
    "与非空正文，CLI/API/runner 默认预算已对齐到 2400，1906 exact/少 1 token 边界保持 fail-closed；"
    "completed bundle 的 node/source/module/owner/function/status/inputs/outputs 现场回绑当前 "
    "profile include closure，首要 evidence 固定为 `evidence/<node_id>.log`，dispatch 锁定两个 startup PASS "
    "及逐节点 `in-progress→PASS` 全序和 11 字段 payload，evidence-index 重算全部普通资产。七 artifact marker "
    "之后只允许 `publish-task-run` 在单 SQLite 事务内提交严格 EOF publication；generic sync 精确同步 "
    "DB/index/backup，但既不能制造也不能撤销已提交 publication，promote/update/migrate/backup/snapshot/rehydrate 同样被"
    "封锁。真实 SQLite 回归 14/14 覆盖 staged 隐身、幂等发布/final_result、post-publish sync 保留、DB-first backup ownership、尾随"
    "publication、marker/staged/DB-open、all-shim prune、rehydrate、direct/nested generic 写入和 contract/"
    "nested-report 反例。独立审查发现的全量一致 tuple 改写、真实但错属 evidence、发布撤销/语义分裂与"
    "通用写入漏洞均已复现后关闭；`2026-07-18-github-index-5` (agent-system 9/9)、"
    "`2026-07-18-agent-system-5` (github-index 1/1) 与 `2026-07-18-rv64-ppa-3` (npc-dev 5/5) "
    "均 completed、publication_valid。该结论只证明 AI "
    "工作流可发现/执行/审计，不替代 RV64 live epoch、双 memory、Linux、200MHz 或 PPA gate。"
)

AGENT_SYSTEM_AI_ENTRY = (
    "- 2026-07-18：**agent/e2e v10 已把自洽证据升级为 live source-bound completion，并关闭 DB 发布"
    "假绿**。`e2e_validate_task_run_bundle` 递归解析当前 profile TSV/include closure，把 node/source/module/"
    "owner/function/status/inputs/outputs 与 manifest/resolve/nodes/report/dispatch 精确同序比较；每节点首要"
    "证据必须是 canonical node-owned log，辅助指针也必须是 actual indexed ordinary asset。dispatch 只"
    "接受两个 startup PASS 后逐节点 `in-progress→PASS`，每事件恰好 11 字段；marker 绑定七 artifact。"
    "DB 采用 staged sync + 专用 `publish-task-run` 两阶段：generic archive 精确 prune DB/index/backup 却"
    "保护 committed publication，generic promote/update/migrate/rehydrate 不得写入任意 task-run 层级的 "
    "`completion-publication.md`，publisher/API/strict guard 对 publication 统一严格 EOF，completed API "
    "还从唯一 canonical 收尾段恢复 `final_result`；audit 只豁免不可恢复的 canonical publication backup，并拒绝反向备份；普通 backup/snapshot 也过滤 publication。"
    "brief 默认 2400 与 CLI/API 对齐，又保留显式覆盖与必需 focus 的 fail-closed。真实 SQLite 回归 14/14；多产物一致 function 改写、"
    "错属真实 evidence、尾随 publication、post-publish sync 与失败 DB 路径均有负例。正式证据 "
    "`.github/task-runs/2026-07-18-github-index-5/`、"
    "`.github/task-runs/2026-07-18-agent-system-5/` 与 `.github/task-runs/2026-07-18-rv64-ppa-3/` "
    "均 completed 且 publication_valid；本项不构成任何 "
    "RV64 功能、Linux、时序或 PPA 声明。"
)


def stored_content(path: str) -> str:
    request = json.dumps(
        {"op": "show", "path": path, "source": "stored", "include_content": True},
        ensure_ascii=False,
    )
    result = subprocess.run(
        [sys.executable, str(INDEX_CLI), "api", "--request", request],
        cwd=REPO_ROOT,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    payload = json.loads(result.stdout)
    content = payload.get("document", {}).get("content")
    if not payload.get("ok") or payload.get("source") != "stored" or not isinstance(content, str):
        raise RuntimeError(f"stored API read failed for {path}: {payload}")
    return content


def upsert_line(content: str, marker: str, tag: str, entry: str) -> str:
    lines = content.splitlines(keepends=True)
    matches = [index for index, line in enumerate(lines) if tag in line]
    if len(matches) > 1:
        raise RuntimeError(f"duplicate memory tag {tag}: {len(matches)}")
    normalized = entry.rstrip("\n") + "\n"
    if matches:
        lines[matches[0]] = normalized
        return "".join(lines)
    if content.count(marker) != 1:
        raise RuntimeError(f"memory marker count for {tag} is {content.count(marker)}, expected 1")
    return content.replace(marker, marker + normalized, 1)


def update_stored(path: str, content: str) -> None:
    subprocess.run(
        [sys.executable, str(INDEX_CLI), "update-stored", path, "--stdin"],
        cwd=REPO_ROOT,
        input=content,
        check=True,
        text=True,
    )


def main() -> int:
    project_path = ".github/memory/project-status.md"
    npc_path = ".github/memory/modules/npc.md"
    agent_system_path = ".github/memory/modules/agent-system.md"
    project_marker = "## 已完成的工作\n<!-- 按时间倒序记录，格式: - [日期] 简要描述 -->\n"
    npc_marker = "## 当前状态\n<!-- 已实现的模块、信号位宽等 -->\n"
    agent_system_marker = "## 当前状态\n\n"

    project = stored_content(project_path)
    project = upsert_line(project, project_marker, "RV64 PPA 架构恢复 S2-Q1", PROJECT_Q1_ENTRY)
    project = upsert_line(project, project_marker, "RV64 PPA 架构恢复 S2-Q2", PROJECT_Q2_ENTRY)
    project = upsert_line(project, project_marker, "AI 开发环境 v10", PROJECT_AI_ENTRY)
    npc = stored_content(npc_path)
    npc = upsert_line(npc, npc_marker, "RV64-PPA-S2-Q1", NPC_Q1_ENTRY)
    npc = upsert_line(npc, npc_marker, "RV64-PPA-S2-Q2", NPC_Q2_ENTRY)
    agent_system = stored_content(agent_system_path)
    agent_system = upsert_line(
        agent_system,
        agent_system_marker,
        "agent/e2e v10",
        AGENT_SYSTEM_AI_ENTRY,
    )

    update_stored(project_path, project)
    update_stored(npc_path, npc)
    update_stored(agent_system_path, agent_system)
    subprocess.run(
        [sys.executable, str(INDEX_CLI), "audit-db-first"],
        cwd=REPO_ROOT,
        check=True,
    )
    print("PASS persisted reviewed S2-Q1 + S2-Q2 + AI v10 memory through update-stored")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
