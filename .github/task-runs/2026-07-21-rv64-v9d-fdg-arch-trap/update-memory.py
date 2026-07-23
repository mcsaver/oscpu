#!/usr/bin/env python3
"""Publish stable V9D FDG-G1 facts through the DB-owned memory API."""

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
PROJECT_IDENTITY = "RV64 V9D 已把 FDG-G1 重新绑定到当前同设计证据"
NPC_IDENTITY = "RV64-v9d-fdg-current-design-rebind"
AGENT_SYSTEM_IDENTITY = "V9D discriminating RTL variant reconciliation"

PROJECT_ENTRY = (
    "- [2026-07-21] **RV64 V9D 已把 FDG-G1 重新绑定到当前同设计证据；长期完整 OoO/PPA 目标继续 "
    "active**。production RTL 未修改；真实 owner/dataflow 校正为 `OooFetchHeadClassifyGate/"
    "OooFetchHeadPairGate → OooFrontendDispatchGate → OooFrontendBackendDispatchMux → OooCoreTopGlue`，"
    "精确 trap 独立经 pending arbiter/sequencer 进入 CSR owner。focused 精确覆盖 4 类非法 FP 均形成 "
    "arch-trap 且 backend 0 呈现，并以 1 个合法 FADD.S 保持正路径；全核程序观察 1 次精确非法指令 "
    "trap、capture PC/tval 与 CSR `mepc/mtval` 各 1/1、handler/MRET 完成；同一 commit observation "
    "interface 命中 1 条已知 ADDI 且非法 FP 0 提交。当前模块 109/109、compile-success 本地 RTL 验证"
    "变体 6/6、commit-observer 非空性探针 1/1 动态拒绝、FDG 语义单测 12/12；永久入口 "
    "`make -C npc/rv64 check-fdg-arch-trap` 连续双跑得到相同 result/raw/variant/module/program SHA，"
    "FDG result 为 `6238dbef481273da7d6acc00156a9bf1a23c90ebfb610498053377b66df88fb0`，绑定 design "
    "`sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`。九项定向架构 "
    "gate 仍为 GREEN；full-core `ARCH_STABLE=GAP` 的 blocker 从 45 降为 44，PPA 保持 "
    "`UNQUALIFIED`、`promotion_eligible=false`。no-tools v1 reviewer 的 commit-observer 非空性与 PC/tval "
    "值敏感性两项 P1 促成上述加固；v2 reviewer 判 PASS、无 P0/P1，并保留逐 commit lane 动态切片、"
    "连续 trap metadata 配对和 early-classifier completeness 三项 P2；v3 reviewer 又确认仅归一化精确"
    "临时编译根不削弱诊断敏感性、无 P0/P1，并保留 token 理论碰撞与 helper 不可脱离精确 inventory "
    "单独作完整性证明两项 P2。证据 "
    "`.github/task-runs/2026-07-21-rv64-v9d-fdg-arch-trap/`。"
)

NPC_ENTRY = (
    "- 2026-07-21(RV64-v9d-fdg-current-design-rebind): **FDG-G1 在当前 design_id 上 CLOSED；production "
    "RTL 未改，full-core arch-stable/PPA 未晋级**。分类/admission/final sink 为 "
    "`OooFetchHeadClassifyGate/OooFetchHeadPairGate → OooFrontendDispatchGate → "
    "OooFrontendBackendDispatchMux → OooCoreTopGlue`；`NpcCoreTop.v` 不是该谓词 owner。precise-trap "
    "owner 独立经 `OooPendingDispatchArbiter → OooPendingTrapExitSequencer → "
    "OooCsrTrapRequestMux/CsrFile`。focused marker 精确为 `illegal_fp_cases=4 illegal_classified=4 "
    "arch_trap=4 fp_disabled=4 backend_blocked=4 legal_fp_cases=1 legal_backend_present=1`；全核 marker 为 "
    "`arch_trap_capture=1 capture_pc_match=1 capture_tval_match=1 ordinary_backend_present=0 "
    "core_backend_present=0 commit_oracle_hits=1 illegal_fp_commit=0 handler=1 mret=1 cause=2 "
    "csr_mepc_match=1 csr_mtval_match=1`。六个 current-source compile-success RTL 验证变体分别覆盖 "
    "ordinary/lane1 exclusion、合法正路径、final sink、trap PC 与 trap tval，另有 1/1 commit-observer "
    "非空性探针；全部被定向 oracle 拒绝且 production source unchanged。模块 109/109、FDG 单测 "
    "12/12。永久入口 `make -C npc/rv64 check-fdg-arch-trap` 连续双跑 result/raw/variant/module/"
    "program SHA 全相同；result `6238dbef481273da7d6acc00156a9bf1a23c90ebfb610498053377b66df88fb0`，design "
    "`sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`；"
    "九项 directed architecture GREEN，但 full-core `ARCH_STABLE=GAP/blockers=44`、"
    "`ppa=UNQUALIFIED`、`promotion_eligible=false`，且尚无当前 official/AM/DiffTest 同源 aggregate。"
    "v2/v3 no-tools reviewer 均判 PASS、无 P0/P1；不外推逐 lane commit sensitivity、连续 trap/flush "
    "metadata 配对、early-classifier 变体 completeness、任意日志 token 无碰撞或全核晋级。"
)

AGENT_SYSTEM_ENTRY = (
    "- 2026-07-21（V9D discriminating RTL variant reconciliation）：**任务合同中计划的 RTL 验证变体"
    "必须与最终能被定向 oracle 动态区分的变体一致，并作为证据 source binding 重新生成**。FDG 首个"
    "classifier-to-gate 绑定切片虽然可编译，但全核 precise-trap owner 在 ordinary dispatch-valid 前正确"
    "截获，所选 oracle 因而不能拒绝；该候选不计入覆盖，替换为 lane1 dual-dispatch exclusion 切片。"
    "随后同步 `contract.md`/`rtl-derivation.md`，重跑 canonical builder，再更新 ledger hash；禁止让旧计划"
    "文字与实际 aggregate 分离。v1 reviewer 又以 commit-observer 非空性和 PC/tval 值敏感性两项 P1 "
    "推动证据升级为 6/6 RTL source variants + 1/1 observer probe，v2 才判 PASS；第一轮 FAIL 与被丢弃"
    "候选都保留，不能由后续 PASS 覆盖。最终 canonical replay 又发现随机 `/tmp` 编译根使同一语义日志"
    "哈希漂移；修复只把当前 `TemporaryDirectory` 精确路径替换为 `<FDG_TRANSIENT_TMP>`，保留仓库路径、"
    "编译参数、诊断、oracle marker、return code 与结果文本，并以 109 module + 7 variant/probe live-log "
    "检查和两次完全相同 SHA 重放证明；v3 reviewer 判 PASS、无 P0/P1。聚合 parser 可同时接受仓库既有"
    "的精确 `PASS <test>` 与 `[PASS] "
    "<test>` 成功格式，但仍须拒绝任一 FAIL/ERROR marker、非零返回码、缺失/重复测试和 membership 漂移；"
    "这是兼容已冻结 testbench 输出格式，不是降低判定强度。DB-owned memory updater 必须以条目中真实"
    "存在的稳定 identity 作 exact-line upsert，并为分块回读提供足够 token budget；本轮首次幂等复跑因"
    "identity 漂移和截断回读失败；修正 exact-line/20k-token 回读并去除一个相邻字节级重复项后，"
    "下一轮三份文档全部 unchanged。所有自然语言继续显式绑定 local RV64 "
    "module/signal/path/cycle/EDA 语义，不改变真实工程动作。"
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


def collapse_exact_duplicate_entry(content: str, entry: str) -> tuple[str, bool]:
    """Keep the first exact task entry and remove only identical repeats."""
    needle = entry + "\n"
    count = content.count(needle)
    if count <= 1:
        return content, False
    first = content.find(needle)
    prefix = content[: first + len(needle)]
    suffix = content[first + len(needle) :].replace(needle, "")
    return prefix + suffix, True


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
    """Remove only byte-identical adjacent Markdown list entries."""
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
    current, deduplicated = collapse_exact_duplicate_entry(current, entry)
    current, adjacent_deduplicated = collapse_adjacent_duplicate_list_lines(
        current)
    updated, changed = upsert_identity_entry(
        current, marker, identity, entry)
    if not changed and not deduplicated and not adjacent_deduplicated:
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
