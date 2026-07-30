#!/usr/bin/env python3
"""Fail-closed audit for ``docs/rv64core/study/index.html``.

The audit is deliberately structural. It verifies that the generated single-file
document carries the exact 150-file atlas, a reciprocal elaborated instance
tree, all 38 WaveDrom diagrams, the required transaction pages and no external
runtime resource.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from html.parser import HTMLParser
from pathlib import Path
from typing import Any


SCRIPT = Path(__file__).resolve()
STUDY_ROOT = SCRIPT.parents[1]
REPO_ROOT = SCRIPT.parents[4]
VSRC_ROOT = REPO_ROOT / "npc" / "rv64" / "vsrc"
DEFAULT_HTML = STUDY_ROOT / "index.html"

DATA_RE = re.compile(
    r'<script\s+id="rv64-data"\s+type="application/json">(.*?)</script>',
    re.DOTALL,
)
EXPECTED_STATUS_COUNTS = {
    "Top": 124,
    "Sim": 6,
    "Check": 3,
    "Catalog": 3,
    "Header": 9,
    "Doc/Build": 5,
}
REQUIRED_TRANSACTIONS = {
    "instruction-life",
    "fetch-packet",
    "integer-completion",
    "fp-completion",
    "load",
    "store",
    "branch-recovery",
    "csr-queue-head",
    "precise-trap",
}
REQUIRED_MODULES = {
    "NpcTop",
    "NpcCoreTop",
    "OooCoreTopGlue",
    "OooFrontend",
    "OooFetchAxiBridge",
    "OooExecuteBackend",
    "OooIntBackend",
    "OooFpBackend",
    "OooMemoryAccess",
    "OooDualMemBridgeWrapper",
    "OooStoreQueue",
    "OooLoadQueue",
    "OooRob",
    "OooWriteback",
    "OooControlPlane",
    "CsrFile",
}
REQUIRED_DOM_IDS = {
    "globalSearch",
    "searchResults",
    "menuButton",
    "sidebar",
    "navTabs",
    "sidebarBody",
    "mainContent",
    "toast",
    "liveStatus",
    "rv64-data",
    "thirdPartyLicense",
}
REQUIRED_DATASHEET_LABELS = {
    "GENERAL DESCRIPTION",
    "FEATURES",
    "FUNCTIONAL BLOCK DIAGRAM",
    "THEORY OF OPERATION / TRANSACTION",
    "INTERFACES AND SIGNAL GROUPS",
    "TIMING CHARACTERISTICS",
    "DESIGN INVARIANTS AND CORNER CASES",
    "SOURCE EVIDENCE",
    "REVISION HISTORY",
}


class StructureParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.ids: list[str] = []
        self.external_resources: list[tuple[str, str, str]] = []
        self.javascript_uris: list[tuple[str, str]] = []
        self.script_src_count = 0
        self.stylesheet_link_count = 0

    def handle_starttag(
        self, tag: str, attrs: list[tuple[str, str | None]]
    ) -> None:
        attributes = {key: value or "" for key, value in attrs}
        if attributes.get("id"):
            self.ids.append(attributes["id"])
        for key in ("src", "href"):
            value = attributes.get(key, "")
            if value.startswith(("http://", "https://", "//")):
                self.external_resources.append((tag, key, value))
            if value.lower().startswith("javascript:"):
                self.javascript_uris.append((tag, value))
        if tag == "script" and attributes.get("src"):
            self.script_src_count += 1
        if (
            tag == "link"
            and "stylesheet"
            in {
                item.strip().lower()
                for item in attributes.get("rel", "").split()
                if item.strip()
            }
        ):
            self.stylesheet_link_count += 1


def source_paths() -> set[str]:
    return {
        path.relative_to(REPO_ROOT).as_posix()
        for path in VSRC_ROOT.rglob("*")
        if path.is_file()
    }


def normalize_binary_holds(wave: str) -> str:
    normalized: list[str] = []
    active_level: str | None = None
    for token in wave:
        if token in {"0", "1"}:
            if token == active_level:
                normalized.append(".")
            else:
                normalized.append(token)
                active_level = token
        else:
            normalized.append(token)
            if token != ".":
                active_level = None
    return "".join(normalized)


def load_payload(text: str) -> dict[str, Any]:
    match = DATA_RE.search(text)
    if not match:
        raise ValueError("缺少唯一 rv64-data application/json script")
    if len(DATA_RE.findall(text)) != 1:
        raise ValueError("rv64-data script 必须恰好一个")
    payload = json.loads(match.group(1))
    if not isinstance(payload, dict):
        raise ValueError("rv64-data 顶层必须是 object")
    return payload


def audit_payload(payload: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    meta = payload.get("meta", {})
    files = payload.get("files", [])
    modules = payload.get("modules", {})
    instances = payload.get("instances", [])
    transactions = payload.get("transactions", [])
    timings = payload.get("timings", [])
    product_config = payload.get("productConfig", {})

    if not isinstance(product_config, dict):
        errors.append("productConfig 不是 object")
        product_config = {}
    expected_product_config = {
        "schema": "npc-rv64-product-rtl-config-v1",
        "source": "npc/rv64/configs/product-rtl-defaults.mk",
        "defineFallbackSource": "npc/rv64/vsrc/include/define.v",
        "OOO_CSR_QUEUE_HEAD": "1",
        "OOO_CSR_QUEUE_HEAD_FALLBACK": "1'b1",
        "OOO_TERMINAL_HOLDER_ASSERT": "1",
    }
    for field, expected in expected_product_config.items():
        if product_config.get(field) != expected:
            errors.append(
                f"productConfig.{field}={product_config.get(field)!r} "
                f"expected={expected!r}"
            )
    if "lane1/FP CSR" not in str(product_config.get("activeCsrPath", "")):
        errors.append("productConfig 未说明 queue-head/pending CSR split-domain")

    actual_sources = source_paths()
    embedded_paths = [str(item.get("path", "")) for item in files]
    embedded_counts = Counter(embedded_paths)
    if set(embedded_paths) != actual_sources:
        for path in sorted(actual_sources.difference(embedded_paths)):
            errors.append(f"HTML file atlas 缺失：{path}")
        for path in sorted(set(embedded_paths).difference(actual_sources)):
            errors.append(f"HTML file atlas 多余：{path}")
    for path, count in sorted(embedded_counts.items()):
        if count != 1:
            errors.append(f"HTML file atlas {path} 出现 {count} 次")

    status_counts = Counter(str(item.get("status", "")) for item in files)
    if dict(status_counts) != EXPECTED_STATUS_COUNTS:
        errors.append(
            f"HTML file 身份计数不匹配：{dict(status_counts)} != "
            f"{EXPECTED_STATUS_COUNTS}"
        )
    if len(files) != 150 or meta.get("fileCount") != 150:
        errors.append(
            f"HTML fileCount 不为 150：files={len(files)} "
            f"meta={meta.get('fileCount')}"
        )

    if not REQUIRED_MODULES.issubset(modules):
        errors.append(
            "HTML modules 缺少关键模块："
            + ", ".join(sorted(REQUIRED_MODULES.difference(modules)))
        )
    if meta.get("moduleCount") != len(modules):
        errors.append(
            f"moduleCount meta={meta.get('moduleCount')} actual={len(modules)}"
        )

    instance_ids = [str(item.get("id", "")) for item in instances]
    if len(instance_ids) != len(set(instance_ids)):
        errors.append("实例 id 不唯一")
    by_id = {str(item.get("id", "")): item for item in instances}
    if payload.get("coreRoot") not in by_id:
        errors.append(f"coreRoot 不存在：{payload.get('coreRoot')}")
    if payload.get("socRoot") not in by_id:
        errors.append(f"socRoot 不存在：{payload.get('socRoot')}")
    if by_id.get(str(payload.get("coreRoot")), {}).get("module") != "NpcCoreTop":
        errors.append("coreRoot 不是 NpcCoreTop")
    if by_id.get(str(payload.get("socRoot")), {}).get("module") != "NpcTop":
        errors.append("socRoot 不是 NpcTop")
    if meta.get("instanceCount") != len(instances):
        errors.append(
            f"instanceCount meta={meta.get('instanceCount')} actual={len(instances)}"
        )

    for node in instances:
        node_id = str(node.get("id", ""))
        module = str(node.get("module", ""))
        parent = node.get("parent")
        children = node.get("children", [])
        if module not in modules:
            errors.append(f"{node_id}: module {module} 没有定义数据")
        if parent:
            if parent not in by_id:
                errors.append(f"{node_id}: parent 不存在 {parent}")
            elif node_id not in by_id[parent].get("children", []):
                errors.append(f"{node_id}: parent/child 非 reciprocal")
        for child in children:
            if child not in by_id:
                errors.append(f"{node_id}: child 不存在 {child}")
            elif by_id[child].get("parent") != node_id:
                errors.append(f"{node_id}: child/parent 非 reciprocal {child}")

    for module_name, module_info in modules.items():
        source = str(module_info.get("source", ""))
        if source not in actual_sources:
            errors.append(f"{module_name}: 定义文件不存在 {source}")
        declared_instances = list(module_info.get("instances", []))
        actual_instances = [
            node_id
            for node_id, node in by_id.items()
            if node.get("module") == module_name
        ]
        if sorted(declared_instances) != sorted(actual_instances):
            errors.append(f"{module_name}: module/instance reverse index 不一致")
        ports = module_info.get("ports", [])
        port_names = [str(port.get("name", "")) for port in ports]
        if len(port_names) != len(set(port_names)):
            errors.append(f"{module_name}: ANSI port 名称重复")
        sequential_targets = module_info.get("sequentialTargets")
        if not isinstance(sequential_targets, list):
            errors.append(f"{module_name}: 缺少 Self-check sequentialTargets")
        elif (
            any(not isinstance(target, str) or not target for target in sequential_targets)
            or len(sequential_targets) != len(set(sequential_targets))
        ):
            errors.append(f"{module_name}: sequentialTargets 非字符串或存在重复")
        elif sequential_targets and not module_info.get("posedgeBlocks"):
            errors.append(
                f"{module_name}: 提取到状态左值但 posedgeBlocks=0，"
                "always/always_ff 边沿识别可能漏检"
            )
        if module_info.get("status") == "Top" and not declared_instances:
            errors.append(f"{module_name}: Top 身份但没有 NpcTop instance")

    transaction_ids = {str(item.get("id", "")) for item in transactions}
    if transaction_ids != REQUIRED_TRANSACTIONS:
        errors.append(
            "transaction 集合不匹配："
            f"actual={sorted(transaction_ids)} "
            f"expected={sorted(REQUIRED_TRANSACTIONS)}"
        )
    if meta.get("transactionCount") != len(transactions):
        errors.append("transactionCount meta 与实际不一致")
    timing_ids = {str(item.get("id", "")) for item in timings}
    for transaction in transactions:
        if not transaction.get("phases"):
            errors.append(f"{transaction.get('id')}: 没有 phase")
        if not transaction.get("terminal"):
            errors.append(f"{transaction.get('id')}: 没有 terminal")
        if not transaction.get("backpressure"):
            errors.append(f"{transaction.get('id')}: 没有 backpressure")
        if not transaction.get("flush"):
            errors.append(f"{transaction.get('id')}: 没有 flush rule")
        for phase in transaction.get("phases", []):
            if phase.get("module") not in modules:
                errors.append(
                    f"{transaction.get('id')}: phase module 不存在 "
                    f"{phase.get('module')}"
                )
            for field in ("dataIn", "stateChange", "dataOut", "guard"):
                if not isinstance(phase.get(field), str) or not phase[field].strip():
                    errors.append(
                        f"{transaction.get('id')}: phase "
                        f"{phase.get('module')} 缺少 {field}"
                    )
            side_path = phase.get("sidePath")
            if side_path is not None:
                if not isinstance(side_path, dict):
                    errors.append(
                        f"{transaction.get('id')}: sidePath 不是 object"
                    )
                else:
                    if side_path.get("module") not in modules:
                        errors.append(
                            f"{transaction.get('id')}: sidePath module 不存在 "
                            f"{side_path.get('module')}"
                        )
                    for field in (
                        "label",
                        "dataIn",
                        "stateChange",
                        "dataOut",
                        "guard",
                    ):
                        if (
                            not isinstance(side_path.get(field), str)
                            or not side_path[field].strip()
                        ):
                            errors.append(
                                f"{transaction.get('id')}: sidePath 缺少 {field}"
                            )
        for timing_id in transaction.get("timingIds", []):
            if timing_id not in timing_ids:
                errors.append(
                    f"{transaction.get('id')}: timing 不存在 {timing_id}"
                )
        if not transaction.get("timingIds"):
            errors.append(f"{transaction.get('id')}: 未绑定 WaveDrom")

    store_transaction = next(
        (item for item in transactions if item.get("id") == "store"),
        None,
    )
    if store_transaction:
        store_side_paths = [
            (phase, phase["sidePath"])
            for phase in store_transaction.get("phases", [])
            if isinstance(phase.get("sidePath"), dict)
        ]
        if len(store_side_paths) != 1:
            errors.append(
                "Store 必须恰有一条独立 owner-lifetime sidePath："
                f"actual={len(store_side_paths)}"
            )
        else:
            parent_phase, side_path = store_side_paths[0]
            if parent_phase.get("module") != "OooIntBackend":
                errors.append(
                    "Store owner-lifetime sidePath 必须从 OooIntBackend "
                    "exact response 分叉"
                )
            if side_path.get("module") != "OooMemOwnerTerminalCollector":
                errors.append(
                    "Store sidePath 终点不是 OooMemOwnerTerminalCollector"
                )
            if "只携带 {kind, token, epoch}" not in side_path.get("dataIn", ""):
                errors.append(
                    "Store collector sidePath 未明确限定 tuple-only payload"
                )
        if any(
            phase.get("module") == "OooMemOwnerTerminalCollector"
            for phase in store_transaction.get("phases", [])
        ):
            errors.append(
                "OooMemOwnerTerminalCollector 仍被画在 Store 主完成链上"
            )

    csr_transaction = next(
        (item for item in transactions if item.get("id") == "csr-queue-head"),
        None,
    )
    if csr_transaction:
        csr_modules = [
            phase.get("module") for phase in csr_transaction.get("phases", [])
        ]
        expected_chain = [
            "OooFrontend",
            "OooDispatchBackend",
            "OooIntBackend",
            "OooRob",
            "OooCsrAccessRequestMux",
            "CsrFile",
            "OooControlEventApplySequencer",
        ]
        if csr_modules != expected_chain:
            errors.append(
                "CSR queue-head 主链不匹配："
                f"actual={csr_modules} expected={expected_chain}"
            )
        csr_side_path_parents = [
            (phase.get("module"), phase.get("sidePath"))
            for phase in csr_transaction.get("phases", [])
            if isinstance(phase.get("sidePath"), dict)
        ]
        if len(csr_side_path_parents) != 1:
            errors.append(
                "CSR queue-head 必须恰有一条并行 serial-flush sidePath："
                f"actual={len(csr_side_path_parents)}"
            )
        else:
            csr_side_path_parent, csr_side_path = csr_side_path_parents[0]
            if csr_side_path_parent != "CsrFile":
                errors.append(
                    "CSR queue-head serial-flush sidePath 必须从 CsrFile 的 C0 "
                    f"阶段分出：actual={csr_side_path_parent}"
                )
            if (
                csr_side_path.get("module") != "OooControlCommitSequencer"
                or "serial_flush_q"
                not in csr_side_path.get("stateChange", "")
            ):
                errors.append(
                    "CSR queue-head serial-flush sidePath owner/状态不匹配"
                )
        csr_text = json.dumps(
            csr_transaction, ensure_ascii=False, separators=(",", ":")
        )
        for required_fact in (
            "head0_csr_inflight",
            "只等待 mem_idle",
            "不等待 mem_retire_quiet/SQ empty",
            "C0",
            "C1",
            "C2",
            "lane1/FP CSR",
        ):
            if required_fact not in csr_text:
                errors.append(
                    f"CSR queue-head transaction 缺少事实：{required_fact}"
                )

    if len(timings) != 38 or meta.get("timingCount") != 38:
        errors.append(
            f"WaveDrom 数不为 38：timings={len(timings)} "
            f"meta={meta.get('timingCount')}"
        )
    if len(timing_ids) != len(timings):
        errors.append("WaveDrom id 不唯一")
    for timing in timings:
        wave = timing.get("wave", {})
        if not isinstance(wave, dict) or not isinstance(wave.get("signal"), list):
            errors.append(f"{timing.get('id')}: 非法 WaveJSON")
        if not timing.get("signals"):
            errors.append(f"{timing.get('id')}: 缺少文本替代 signal")
        for signal in timing.get("signals", []):
            signal_wave = signal.get("wave", "")
            if (
                isinstance(signal_wave, str)
                and normalize_binary_holds(signal_wave) != signal_wave
            ):
                errors.append(
                    f"{timing.get('id')} {signal.get('name', '<unnamed>')}: "
                    "HTML payload 含会形成伪毛刺的重复二值电平"
                )

    fingerprint = str(meta.get("sourceFingerprint", ""))
    if not re.fullmatch(r"[0-9a-f]{64}", fingerprint):
        errors.append("sourceFingerprint 不是 sha256")
    if meta.get("waveDromVersion") != "3.6.2":
        errors.append(f"WaveDrom 版本未锁定 3.6.2：{meta.get('waveDromVersion')}")
    elaboration_hash = str(meta.get("elaborationSha256", ""))
    if not re.fullmatch(r"[0-9a-f]{64}", elaboration_hash):
        errors.append("elaborationSha256 不是 sha256")
    if meta.get("revision") != "Rev. C":
        errors.append(f"源码更新版本不是 Rev. C：{meta.get('revision')}")
    return errors


def audit_html_structure(text: str) -> list[str]:
    errors: list[str] = []
    parser = StructureParser()
    parser.feed(text)
    duplicate_ids = [
        item for item, count in Counter(parser.ids).items() if count != 1
    ]
    if duplicate_ids:
        errors.append("静态 DOM id 重复：" + ", ".join(sorted(duplicate_ids)))
    missing_ids = REQUIRED_DOM_IDS.difference(parser.ids)
    if missing_ids:
        errors.append("缺少静态 DOM id：" + ", ".join(sorted(missing_ids)))
    if parser.external_resources:
        errors.append(f"存在外部资源：{parser.external_resources}")
    if parser.javascript_uris:
        errors.append(f"存在 javascript: URI：{parser.javascript_uris}")
    if parser.script_src_count:
        errors.append(f"存在 {parser.script_src_count} 个外部 script src")
    if parser.stylesheet_link_count:
        errors.append(f"存在 {parser.stylesheet_link_count} 个外部 stylesheet")
    if "fetch(" in text or "XMLHttpRequest" in text or "new WebSocket" in text:
        errors.append("HTML 内含网络读取 API，不满足离线单文件合同")
    if "RV64_INTERACTIVE_DATASHEET_BEGIN" not in text:
        errors.append("缺少 RV64_INTERACTIVE_DATASHEET_BEGIN marker")
    if "RV64_INTERACTIVE_DATASHEET_END" not in text:
        errors.append("缺少 RV64_INTERACTIVE_DATASHEET_END marker")
    for label in sorted(REQUIRED_DATASHEET_LABELS):
        if label not in text:
            errors.append(f"缺少 datasheet 固定栏目：{label}")
    required_js_markers = {
        "function renderTreeNode(",
        "function transactionFlow(",
        "function renderModulePage(",
        "function renderTransactionPage(",
        "function renderFilePage(",
        "function selfCheckItems(",
        "function renderSelfCheck(",
        "function runSearch(",
        "window.WaveDrom.RenderWaveForm",
        "window.addEventListener(\"hashchange\"",
        "data-copy-link",
        "TOP-TO-BOTTOM MODULE / DATA FLOW",
        "NO MODULE-SPECIFIC TIMING",
        "flow-step-transfer",
        "flow-data-grid",
        "flow-side-path",
        "PARALLEL OWNER-LIFETIME BRANCH",
        "只携带 {kind, token, epoch}",
        "flow-connector",
        ".flow-data-cell dd {",
        ".lead-grid > * {",
        "word-break: break-word;",
        "self-check-answer",
        "展开参考答案",
        "sequentialTargets",
        "commit0 · DIV older",
        "commit1 · ADD younger",
        "HOW TO READ THIS CASE",
        "grid-template-columns: repeat(auto-fit, minmax(min(100%, 250px), 1fr));",
        "grid-template-columns: repeat(auto-fit, minmax(min(100%, 360px), 1fr));",
        "overflow-wrap: anywhere;",
        "flex-direction: column;",
        "aria-controls=\"sidebarBody\"",
        "role=\"tabpanel\"",
        "pageTitle.focus({ preventScroll: true })",
        "@media print",
    }
    for marker in sorted(required_js_markers):
        if marker not in text:
            errors.append(f"缺少交互/打印 marker：{marker}")
    if "<noscript>" not in text or "NO-JAVASCRIPT OVERVIEW" not in text:
        errors.append("缺少无 JavaScript 降级总览")
    forbidden_markers = {
        "firstInstanceForModule(phase.module": "transaction phase 仍按模块类型猜实例",
        "DATA.timings.slice(0, 1)": "未绑定模块仍回退到无关 WaveDrom",
        "正在装载 <code>": "无 JavaScript 页面残留加载提示",
        "min-width: max-content": "transaction flow 仍强制横向溢出",
        "class=\"flow-arrow\"": "transaction handoff 标签仍使用易覆盖卡片的悬浮箭头",
        "class=\"flow-step-link\"": "transaction 仍使用只能容纳摘要的整卡 button",
        "grid-template-columns: repeat(auto-fit, minmax(min(100%, 220px), 1fr));": "transaction flow 仍是横向自适应卡片网格",
        "columns: 2;": "Features 仍使用会在窄容器中挤压长文本的多栏排版",
        "grid-template-columns: minmax(0, 1.2fr) minmax(280px, 0.8fr);": "lead-grid 仍在窄主内容区强制第二栏最小 280px",
        "function selfTestQuestions(": "Self-check 仍是只有问题、没有答案的旧实现",
        "owner-tagged terminal ingress：kind/token/epoch/ProducerId + response status": "Store owner-lifetime 分支仍错误携带 ProducerId/response status",
    }
    for marker, message in forbidden_markers.items():
        if marker in text:
            errors.append(message)
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("html", nargs="?", type=Path, default=DEFAULT_HTML)
    args = parser.parse_args()
    html_path = args.html.resolve()

    if not html_path.is_file():
        print(f"[interactive-audit] missing={html_path}", file=sys.stderr)
        return 2
    text = html_path.read_text(encoding="utf-8")
    errors: list[str] = []
    try:
        payload = load_payload(text)
    except (ValueError, json.JSONDecodeError) as exc:
        print(f"[interactive-audit][BAD_DATA] {exc}")
        print("[interactive-audit] FAIL")
        return 1

    errors.extend(audit_payload(payload))
    errors.extend(audit_html_structure(text))

    print(f"[interactive-audit] html={html_path.relative_to(REPO_ROOT)}")
    print(f"[interactive-audit] bytes={html_path.stat().st_size}")
    print(f"[interactive-audit] files={len(payload.get('files', []))}")
    print(f"[interactive-audit] modules={len(payload.get('modules', {}))}")
    print(f"[interactive-audit] instances={len(payload.get('instances', []))}")
    print(
        f"[interactive-audit] transactions="
        f"{len(payload.get('transactions', []))}"
    )
    transaction_phase_count = sum(
        len(transaction.get("phases", []))
        for transaction in payload.get("transactions", [])
    )
    transaction_side_path_count = sum(
        1
        for transaction in payload.get("transactions", [])
        for phase in transaction.get("phases", [])
        if phase.get("sidePath")
    )
    print(f"[interactive-audit] transaction_phases={transaction_phase_count}")
    print(
        "[interactive-audit] transaction_side_paths="
        f"{transaction_side_path_count}"
    )
    print(
        "[interactive-audit] transaction_data_fields="
        f"{(transaction_phase_count + transaction_side_path_count) * 4}"
    )
    print(
        "[interactive-audit] self_check_answer_slots="
        f"{len(payload.get('instances', [])) * 5}"
    )
    print(
        "[interactive-audit] sequential_targets="
        f"{sum(len(module.get('sequentialTargets', [])) for module in payload.get('modules', {}).values())}"
    )
    print(f"[interactive-audit] wavedrom={len(payload.get('timings', []))}")
    structure_parser = StructureParser()
    structure_parser.feed(text)
    print(
        "[interactive-audit] external_resources="
        f"{len(structure_parser.external_resources)}"
    )
    for error in errors:
        print(f"[interactive-audit][BAD] {error}")
    if errors:
        print("[interactive-audit] FAIL")
        return 1
    print("[interactive-audit] PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
