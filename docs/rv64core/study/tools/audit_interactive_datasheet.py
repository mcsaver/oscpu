#!/usr/bin/env python3
"""Fail-closed audit for ``docs/rv64core/study/index.html``.

The audit is deliberately structural. It verifies that the generated single-file
document carries the exact 150-file atlas, a reciprocal elaborated instance
tree, all 38 WaveDrom diagrams, the required transaction pages and no external
runtime resource.
"""

from __future__ import annotations

import argparse
import hashlib
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
DEFAULT_XML = Path("/tmp/rv64-study-npctop.xml")
CSS_PATH = STUDY_ROOT / "tools" / "interactive_datasheet.css"
JS_PATH = STUDY_ROOT / "tools" / "interactive_datasheet.js"
BUILD_SCRIPT_PATH = STUDY_ROOT / "tools" / "build_interactive_datasheet.py"
ELABORATION_SCRIPT_PATH = STUDY_ROOT / "tools" / "generate_elaboration_xml.sh"
ATLAS_PATH = STUDY_ROOT / "11-逐文件源码地图.md"
NPC_MAKEFILE_PATH = REPO_ROOT / "npc" / "rv64" / "Makefile"
PRODUCT_DEFAULTS_PATH = (
    REPO_ROOT / "npc" / "rv64" / "configs" / "product-rtl-defaults.mk"
)

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
EXPECTED_TRANSACTION_TIMING_TITLES = {
    "instruction-life": [
        "程序序 DIV(older) → ADD(younger)：ADD 可先 formal-WB，但只能等 DIV 后以 commit1 同拍退休",
        "普通整数 ALU：dispatch 后至少跨三个后续上升沿才更新架构 GPR",
        "head1 早完成也不能越过 head0；head0 ready 后可双退休",
    ],
    "fetch-packet": [
        "fetch miss：outstanding owner 覆盖 TLB/PTW/AXI 全寿命",
        "redirect 后旧响应可到达总线，但必须被 discard，不能入 FIFO",
        "response 在沿上写 FIFO，registered head 后续才派发",
        "RVC packet：16-bit slot0 + 32-bit slot1，共消耗 6B",
    ],
    "integer-completion": [
        "EX stage 遇 completion 反压时保持同一个 producer",
        "普通整数 ALU：dispatch 后至少跨三个后续上升沿才更新架构 GPR",
        "valid 等待 ready 时，tag、结果与异常元数据必须稳定",
        "completion 广播清 busy/唤醒，dependent 使用 PRF 或 bypass",
    ],
    "fp-completion": [
        "FMA producer 的身份与 fflags 必须穿过全部流水级",
        "FP long-op 单 owner：busy 期间禁止覆盖，done 后再取得 completion 资格",
        "FP 结果先物理可见，再进入 done FIFO，最后 formal-WB 与按序 commit",
        "valid 等待 ready 时，tag、结果与异常元数据必须稳定",
    ],
    "load": [
        "SQ 完整覆盖时 load 从最近的老 store 前递，不访问 cache",
        "不同 addr[3] 的双 memory uop 可同拍进入两个 bank",
        "PTW 发现叶 PTE A/D 未置位：先更新 PTE，再重试原访存",
        "AXI AR 反压期间地址、尺寸、属性和 owner 全部保持",
    ],
    "store": [
        "ready 场景：aggregate B 同拍形成 mem_rsp；反压时才进入 S_RESP 保持",
        "AW 与 W 可以在不同周期握手，内部状态必须分别记账",
        "双 bank 同时 miss：共享 raw AXI 按 owner 串行服务",
    ],
    "branch-recovery": [
        "branch resolve 后统一 redirect，并取消所有 younger transaction",
        "redirect 后旧响应可到达总线，但必须被 discard，不能入 FIFO",
    ],
    "csr-queue-head": [
        "产品默认 head0 CSR：inflight 持有 stop，只等 mem_idle；C0 提交，C1 apply，C2 静默",
        "serialized owner：capture -> drain -> exact terminal -> 单次 apply -> clear",
        "控制命令要跨越多个周期保存身份和参数",
    ],
    "precise-trap": [
        "精确异常：老 I0 退休，fault I1 不正常退休，年轻 I2 即使完成也被取消",
        "精确异常：较老者可先退休，异常者本身不产生普通提交",
        "older trap 压制 pending exit：raw 与 sticky 两层都不能双 terminal",
        "设备中断可异步 pending，但只在 Core 精确边界形成 trap",
    ],
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
    "AxiCrossbar",
}
REQUIRED_DOM_IDS = {
    "globalSearch",
    "searchResults",
    "menuButton",
    "fontScaleButton",
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


def current_source_fingerprint(xml_path: Path = DEFAULT_XML) -> str:
    """复算 builder 的完整源码绑定，防止 HTML 在原地悄悄过期。"""

    paths = [
        ATLAS_PATH,
        xml_path,
        NPC_MAKEFILE_PATH,
        PRODUCT_DEFAULTS_PATH,
        BUILD_SCRIPT_PATH,
        CSS_PATH,
        JS_PATH,
        ELABORATION_SCRIPT_PATH,
        *sorted(STUDY_ROOT.glob("[0-9][0-9]-*.md")),
        *sorted(path for path in VSRC_ROOT.rglob("*") if path.is_file()),
    ]
    digest = hashlib.sha256()
    for path in paths:
        digest.update(path.as_posix().encode("utf-8"))
        digest.update(path.read_bytes())
    return digest.hexdigest()


def audit_source_freshness(meta: dict[str, Any]) -> list[str]:
    """Bind the delivered payload to the current XML and every source input."""

    errors: list[str] = []
    if not DEFAULT_XML.is_file():
        return [f"缺少当前 elaboration XML：{DEFAULT_XML}"]
    actual_elaboration = hashlib.sha256(DEFAULT_XML.read_bytes()).hexdigest()
    if meta.get("elaborationSha256") != actual_elaboration:
        errors.append(
            "HTML elaborationSha256 与当前 NpcTop XML 不一致："
            f"html={meta.get('elaborationSha256')} current={actual_elaboration}"
        )
    actual_fingerprint = current_source_fingerprint(DEFAULT_XML)
    if meta.get("sourceFingerprint") != actual_fingerprint:
        errors.append(
            "HTML sourceFingerprint 与当前 RTL/讲义/工具不一致："
            f"html={meta.get('sourceFingerprint')} current={actual_fingerprint}"
        )
    return errors


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


def audit_transaction_timing_bindings(
    transactions: list[dict[str, Any]],
    timings: list[dict[str, Any]],
) -> list[str]:
    """Require an exact semantic transaction-to-WaveDrom binding."""

    errors: list[str] = []
    timing_titles_by_id = {
        str(timing.get("id", "")): str(timing.get("title", ""))
        for timing in timings
    }
    transactions_by_id = {
        str(transaction.get("id", "")): transaction
        for transaction in transactions
    }
    for transaction_id, expected_titles in (
        EXPECTED_TRANSACTION_TIMING_TITLES.items()
    ):
        transaction = transactions_by_id.get(transaction_id)
        if transaction is None:
            continue
        timing_ids = transaction.get("timingIds", [])
        actual_titles = [
            timing_titles_by_id.get(str(timing_id), f"<missing:{timing_id}>")
            for timing_id in timing_ids
        ]
        if actual_titles != expected_titles:
            errors.append(
                f"{transaction_id}: WaveDrom 语义绑定不匹配："
                f"actual={actual_titles} expected={expected_titles}"
            )
    return errors


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

    errors.extend(audit_transaction_timing_bindings(transactions, timings))

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
    if meta.get("revision") != "Rev. E":
        errors.append(f"当前源码同步版本不是 Rev. E：{meta.get('revision')}")
    errors.extend(audit_source_freshness(meta))
    return errors


def audit_css_readability(css_text: str) -> list[str]:
    """Audit the minimum local readability contract without touching files."""

    errors: list[str] = []
    css_definitions = set(
        re.findall(r"(?m)^\s*(--[a-z0-9-]+)\s*:", css_text)
    )
    css_references = set(re.findall(r"var\(\s*(--[a-z0-9-]+)", css_text))
    missing_variables = sorted(css_references.difference(css_definitions))
    if missing_variables:
        errors.append(
            "CSS 引用了未定义变量：" + ", ".join(missing_variables)
        )

    tiny_font_sizes = [
        match.group(0)
        for match in re.finditer(
            r"font-size\s*:\s*(?:[0-9](?:\.[0-9]+)?|10(?:\.0+)?)px",
            css_text,
        )
    ]
    if tiny_font_sizes:
        errors.append(
            "CSS 仍含小于 11px 的显式字号："
            + ", ".join(tiny_font_sizes[:8])
        )
    if re.search(
        r"\.font-scale-button\s*\{[^}]*\bdisplay\s*:\s*none\b",
        css_text,
        re.DOTALL,
    ):
        errors.append("CSS 在窄屏隐藏了唯一字号切换按钮")

    readability_markers = {
        "--text-body: 16px;",
        "--text-caption: 12px;",
        "body[data-font-scale=\"xlarge\"]",
        ".flow-data-cell dd {",
        "font-size: var(--text-body);",
        ".wave-host svg text {",
        ".source-description {",
        ".license-text {",
    }
    for marker in sorted(readability_markers):
        if marker not in css_text:
            errors.append(f"CSS 缺少可读性合同 marker：{marker}")
    return errors


def audit_readability_self_test() -> list[str]:
    """Prove that readability and source-freshness regressions fail closed."""

    errors: list[str] = []
    css_text = CSS_PATH.read_text(encoding="utf-8")
    baseline_errors = audit_css_readability(css_text)
    if baseline_errors:
        errors.append(
            "当前 CSS 未通过 readability baseline："
            + "；".join(baseline_errors)
        )

    injected_errors = audit_css_readability(
        css_text
        + "\n.audit-negative {"
        + "font-size: 9px;"
        + "color: var(--missing-reader-token);"
        + "}\n"
        + ".font-scale-button {display: none;}\n"
    )
    if not any("小于 11px" in item for item in injected_errors):
        errors.append("负向样例中的 9px 字号未被审计拦截")
    if not any("--missing-reader-token" in item for item in injected_errors):
        errors.append("负向样例中的未定义 CSS 变量未被审计拦截")
    if not any("隐藏了唯一字号" in item for item in injected_errors):
        errors.append("负向样例中的移动端隐藏字号按钮未被审计拦截")

    if not DEFAULT_HTML.is_file():
        errors.append(f"缺少 self-test baseline HTML：{DEFAULT_HTML}")
        return errors
    try:
        payload = load_payload(DEFAULT_HTML.read_text(encoding="utf-8"))
    except (ValueError, json.JSONDecodeError) as exc:
        errors.append(f"无法读取 self-test baseline payload：{exc}")
        return errors
    meta = payload.get("meta", {})
    transactions = payload.get("transactions", [])
    timings = payload.get("timings", [])
    binding_errors = audit_transaction_timing_bindings(transactions, timings)
    if binding_errors:
        errors.append(
            "当前 HTML 未通过 transaction timing baseline："
            + "；".join(binding_errors)
        )
    mutated_transactions = json.loads(json.dumps(transactions, ensure_ascii=False))
    bpu_timing = next(
        (
            timing
            for timing in timings
            if str(timing.get("title", "")).startswith("BPU：")
        ),
        None,
    )
    mutated_store = next(
        (
            transaction
            for transaction in mutated_transactions
            if transaction.get("id") == "store"
        ),
        None,
    )
    if bpu_timing is None or mutated_store is None:
        errors.append("无法构造 transaction timing 负向样例")
    else:
        mutated_store["timingIds"] = [bpu_timing["id"]]
        if not any(
            "store: WaveDrom 语义绑定不匹配" in item
            for item in audit_transaction_timing_bindings(
                mutated_transactions, timings
            )
        ):
            errors.append("负向样例中的 Store/BPU timing 误绑未被审计拦截")
    freshness_errors = audit_source_freshness(meta)
    if freshness_errors:
        errors.append(
            "当前 HTML 未通过 source-freshness baseline："
            + "；".join(freshness_errors)
        )
    stale_source_meta = dict(meta)
    stale_source_meta["sourceFingerprint"] = "0" * 64
    if not any(
        "sourceFingerprint" in item
        for item in audit_source_freshness(stale_source_meta)
    ):
        errors.append("负向样例中的 stale source fingerprint 未被审计拦截")
    stale_xml_meta = dict(meta)
    stale_xml_meta["elaborationSha256"] = "0" * 64
    if not any(
        "elaborationSha256" in item
        for item in audit_source_freshness(stale_xml_meta)
    ):
        errors.append("负向样例中的 stale elaboration hash 未被审计拦截")
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
        "function applyFontScale(",
        "function cycleFontScale(",
        "window.WaveDrom.RenderWaveForm",
        "window.addEventListener(\"hashchange\"",
        "data-copy-link",
        "data-font-scale-control",
        "data-font-scale=\"large\"",
        "AxiCrossbar",
        "aggregate B 同拍形成 mem_rsp",
        "terminal_seen_q",
        "static survivor map",
        "FS=Off",
        "TOP-TO-BOTTOM MODULE / DATA FLOW",
        "NO MODULE-SPECIFIC TIMING",
        "flow-step-transfer",
        "flow-data-grid",
        "flow-side-path",
        "flow-reading-key",
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
        "AxiXbar": "讲义仍引用已重命名的旧 AXI 互连",
        "S_WRITE_RESP → S_RESP → rsp fire": "Store transaction 仍把 S_RESP 误写成 aggregate B 的必经级",
    }
    for marker, message in forbidden_markers.items():
        if marker in text:
            errors.append(message)

    css_text = CSS_PATH.read_text(encoding="utf-8")
    js_text = JS_PATH.read_text(encoding="utf-8")
    if css_text not in text:
        errors.append("index.html 内嵌 CSS 与工具源不一致")
    if js_text not in text:
        errors.append("index.html 内嵌 JavaScript 与工具源不一致")

    errors.extend(audit_css_readability(css_text))
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("html", nargs="?", type=Path, default=DEFAULT_HTML)
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="运行不落盘的可读性与源码新鲜度正/负向自检",
    )
    args = parser.parse_args()
    if args.self_test:
        self_test_errors = audit_readability_self_test()
        for error in self_test_errors:
            print(f"[interactive-audit-self-test][BAD] {error}")
        if self_test_errors:
            print("[interactive-audit-self-test] FAIL")
            return 1
        print(
            "[interactive-audit-self-test] "
            "baseline=PASS negative-9px=REJECTED "
            "negative-undefined-variable=REJECTED "
            "negative-hidden-control=REJECTED "
            "negative-transaction-timing=REJECTED "
            "negative-stale-source=REJECTED "
            "negative-stale-elaboration=REJECTED"
        )
        print("[interactive-audit-self-test] PASS")
        return 0
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
    css_text = CSS_PATH.read_text(encoding="utf-8")
    css_definitions = set(
        re.findall(r"(?m)^\s*(--[a-z0-9-]+)\s*:", css_text)
    )
    css_references = set(re.findall(r"var\(\s*(--[a-z0-9-]+)", css_text))
    print(
        "[interactive-audit] typography="
        "default-large/body-16px/caption-12px/scales-3"
    )
    print(
        "[interactive-audit] undefined_css_variables="
        f"{len(css_references.difference(css_definitions))}"
    )
    current_meta = payload.get("meta", {})
    current_xml_hash = (
        hashlib.sha256(DEFAULT_XML.read_bytes()).hexdigest()
        if DEFAULT_XML.is_file()
        else "missing"
    )
    print(
        "[interactive-audit] current_elaboration_bound="
        f"{int(current_meta.get('elaborationSha256') == current_xml_hash)}"
    )
    current_fingerprint = (
        current_source_fingerprint(DEFAULT_XML)
        if DEFAULT_XML.is_file()
        else "missing"
    )
    print(
        "[interactive-audit] current_source_bound="
        f"{int(current_meta.get('sourceFingerprint') == current_fingerprint)}"
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
