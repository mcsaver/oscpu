#!/usr/bin/env python3
"""Focused regressions for the workspace agent operating contract.

The suite is intentionally bounded: representative behavior, active-source
anti-pattern scanning, and mutations for regressions that previously produced
wrong engineering workflow conclusions. Domain correctness stays in domain tests.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import tempfile
from pathlib import Path
from typing import Callable


REPO_ROOT = Path(__file__).resolve().parents[2]

SHIMS = (
    "AGENTS.md",
    "CLAUDE.md",
    "GEMINI.md",
    "CONVENTIONS.md",
    ".windsurfrules",
    ".cursor/rules/agents.mdc",
)

GENERAL_POLICY_FILES = (
    ".github/AGENTS.md",
    ".github/instructions/agent-lightweight-workflow.instructions.md",
    ".github/instructions/agent-env-layer-contract.instructions.md",
    ".github/instructions/agent-env-state-machine.instructions.md",
    ".github/instructions/agent-e2e-workflow.instructions.md",
    ".github/instructions/memory-protocol.instructions.md",
    ".github/agents/agent-system.agent.md",
    ".github/agents/software-flow.agent.md",
    ".github/agents/hardware-flow.agent.md",
    ".github/agents/ysyx-coordinator.agent.md",
    "AI_ENVIRONMENT.md",
)

ACTIVE_SOURCE_GLOBS = (
    ".codex/agents/*.toml",
    ".cursor/rules/*.mdc",
    ".github/agents/*.md",
    ".github/instructions/*.instructions.md",
    ".github/skills/**/SKILL.md",
    ".github/e2e/*.md",
    ".github/e2e/modules/*.md",
)

# Each scenario protects a distinct false-PASS class; anchors are intentionally
# semantic and cross-layer instead of checking every sentence in every document.
SCENARIOS: dict[str, dict[str, tuple[str, ...]]] = {
    "ordinary-code-fix": {
        ".github/AGENTS.md": (
            "inspect → act → targeted validation → report",
            "Safe local work is one authorization scope",
        ),
        ".github/instructions/agent-lightweight-workflow.instructions.md": (
            "无需先创建 task-run、DB brief、",
            "preflight、implementation、build、test、collect、inspect 和 analysis",
        ),
        ".github/agents/software-flow.agent.md": (
            "一个清楚的小修复不要求先",
            "不要为每个步骤创建节点",
        ),
    },
    "minimum-sufficient-validation": {
        ".github/AGENTS.md": (
            "它对应哪个明确的 acceptance criterion",
            "哪一种实际 false PASS",
            "固定输入、固定命令、固定 tool/seed/thread 且 oracle 确定时通常执行一次",
        ),
        ".github/instructions/agent-lightweight-workflow.instructions.md": (
            "不同 workload、corner/config、",
            "不算机械复验",
        ),
    },
    "hardware-correctness-preserved": {
        ".github/AGENTS.md": (
            "RTL 协议与时序、DiffTest、断言、综合、STA、PPA",
            "不能被 AI 流程检查替代或削弱",
        ),
        ".github/agents/hardware-flow.agent.md": (
            "compare/DiffTest 需要两侧同一 workload/config 的可比较产物",
            "PPA A/B 必须绑定相同 RTL/filelist/parameter/define/tool/config/corner/workload",
        ),
        ".github/copilot-instructions.md": (
            "仿真 smoke、综合成功、STA 通过和 PPA 改善回答不同问题",
            "不能互相替代",
        ),
    },
    "verifier-anomaly-escalation": {
        ".github/instructions/agent-lightweight-workflow.instructions.md": (
            "异常接受、异常拒绝、输出矛盾",
            "harness 调查作为一个明确的故障分支",
        ),
        ".github/instructions/agent-env-state-machine.instructions.md": (
            "结果矛盾、缺失或 verifier 异常",
            "先隔离 runner/verifier 故障",
        ),
    },
    "destructive-and-external-boundary": {
        ".github/AGENTS.md": (
            "破坏性、难恢复或有外部副作用的动作",
            "需要明确授权并先核对真实目标",
            "保护用户数据、secret、未提交修改和任务外文件",
        ),
        ".github/instructions/agent-env-state-machine.instructions.md": (
            "范围扩大到破坏性、外部副作用、release/security 或用户选择",
            "暂停并取得相应授权",
        ),
    },
    "compaction-recovery": {
        ".github/AGENTS.md": (
            "用户明确的 acceptance criteria；",
            "实际 repository/worktree 状态；",
            "过去 agent 自创的临时 sequencing、permission phase、gate、marker",
        ),
        ".github/instructions/agent-env-state-machine.instructions.md": (
            "旧记录中的临时 plan_graph、authorization",
            "不会自动恢复",
        ),
        ".github/instructions/memory-protocol.instructions.md": (
            "实际 worktree、当前配置和本轮验证优先",
            "过去 memory 中的流程建议、临时 gate、phase、marker 或单 shell 规则不会自动继承",
        ),
    },
    "hash-and-persistence-scope": {
        ".github/AGENTS.md": (
            "不作为普通 task ID、工作流身份或主要人工 review surface",
            "byte identity、cache integrity、release provenance",
        ),
        ".github/instructions/agent-e2e-workflow.instructions.md": (
            "--publish` 才启用 DB recall、",
            "hash 只用于 byte identity、cache integrity、release provenance",
        ),
        "AI_ENVIRONMENT.md": (
            "不是普通任务的固定前置或收尾许可",
            "release、migration、security、forensic、商业交付或 publication",
        ),
    },
    "resource-scoped-concurrency": {
        ".github/AGENTS.md": (
            "仅当多个动作会竞争同一 build 目录、配置文件、数据库、进程、端口或设备",
            "互不冲突的读取、分析和独立构建不受 workspace-wide single-flight 限制",
        ),
        ".github/agents/hardware-flow.agent.md": (
            "同一文件、build/scratch、current artifact、仿真进程、端口、许可证或设备的写入会冲突",
            "无依赖且资源独立的读取、分析、实现和独立 scratch 构建可以并行",
        ),
        ".github/agents/ysyx-coordinator.agent.md": (
            "不存在 workspace-wide unique shell",
            "不要求每次只派发一个 agent",
        ),
    },
    "strict-exceptions-remain-fail-closed": {
        ".github/AGENTS.md": (
            "显式 persistent/published 的长时间仿真、综合、STA 或系统回放",
            "cleanup 都完成才能记录 PASS",
            "HUP/INT/TERM 不等于 PASS",
        ),
        ".github/instructions/agent-e2e-workflow.instructions.md": (
            "non-zero exit、timeout、signal、中断或缺失 terminal evidence 不得写成 PASS",
            "PPA 必须绑定相同 RTL/filelist/config/tool/corner/workload",
        ),
    },
    "high-signal-reporting": {
        ".github/AGENTS.md": (
            "已满足的 criterion、消除的不确定性、真实验证和剩余风险",
            "不汇报 marker/hash 数量、审计配额",
        ),
        ".github/agents/ysyx-coordinator.agent.md": (
            "满足了哪些 acceptance criteria",
            "不要用节点数、hash 数、审计配额或内部协调流水账",
        ),
    },
}

POLICY_EXPECTATIONS: tuple[tuple[tuple[str, ...], object], ...] = (
    (("schema_version",), 1),
    (("operating_contract", "source"), ".github/AGENTS.md"),
    (("operating_contract", "primary_objective_first"), True),
    (("operating_contract", "acceptance_criteria_driven"), True),
    (("operating_contract", "safe_local_operations_are_one_scope"), True),
    (("operating_contract", "self_created_permission_gates_forbidden"), True),
    (("operating_contract", "failure_driven_evidence_escalation"), True),
    (("layers", "database", "active_instruction_source"), False),
    (("layers", "skill", "may_create_permission_boundaries"), False),
    (("layers", "agent", "may_expand_user_authority"), False),
    (("lightweight_workflow", "controller_required_for_ordinary_tasks"), False),
    (("lightweight_workflow", "task_classes_are_descriptive"), True),
    (("lightweight_workflow", "gate_selection"), "explicit-only"),
    (("lightweight_workflow", "changed_paths_create_gates"), False),
    (("lightweight_workflow", "changed_paths_may_suggest_checks"), True),
    (("lightweight_workflow", "default_archive_mode"), "none"),
    (("lightweight_workflow", "task_run_requires_explicit_selection"), True),
    (("lightweight_workflow", "zero_gate_finish_result"), "FINISHED_NO_GATES"),
    (("lightweight_workflow", "zero_gate_finish_is_engineering_pass"), False),
    (("lightweight_workflow", "private_token_reasoning_archived"), False),
    (("validation_budget", "versioned_verifier_default"), "trusted-until-observed-anomaly"),
    (("validation_budget", "deterministic_default_execution_count"), 1),
    (("validation_budget", "file_count_or_path_triggers_assurance"), False),
    (("specialized_assurance", "persistent_longrun", "interrupted_or_incomplete_may_pass"), False),
    (("specialized_assurance", "release", "fail_closed"), True),
    (("specialized_assurance", "hash_and_sha", "ordinary_task_identity"), False),
    (("retention", "ordinary_task_run_default"), "none"),
    (("retention", "memory_update_required"), False),
    (("traceability", "ordinary_task_completion_dependency"), False),
    (("state_machine", "ordinary_tasks_require_traceback"), False),
    (("observability", "ordinary_task_report_required"), False),
    (("observability", "ordinary_trace_id_required"), False),
    (("observability", "ordinary_run_manifest_required"), False),
    (("observability", "ordinary_profile_resolve_required"), False),
    (("observability", "ordinary_evidence_index_required"), False),
    (("task_routing", "cpu_architect", "routing_is_advisory"), True),
    (("delivery", "explicit_boundary"), True),
)

COMPACTION_ORDER = [
    "primary_objective",
    "explicit_acceptance_criteria",
    "repository_state",
    "hard_constraints",
    "current_validation_evidence",
]

HASH_CRITERIA = {
    "byte_identity",
    "cache_integrity",
    "release_provenance",
    "supply_chain_or_security",
    "persistence",
    "reproducibility",
    "forensic",
}

PROCESS_GATE_PATTERNS = tuple(
    re.compile(pattern, re.I)
    for pattern in (
        r"只有.*(?:PASS|通过).*才(?:允许|能|可).*(?:build|test|构建|测试|继续)",
        r"(?:必须|务必)先.*(?:preflight|gate|marker|seal|hash|SHA|brief|task-run|profile).*(?:才|方可|之后)",
        r"(?:workspace-wide|全工作区).*(?:unique shell|唯一 shell).*(?:必须|才|方可)",
        r"(?:每次|每轮).*(?:重新验证|重验).*(?:verifier|runner|classifier|harness)",
        r"\bdo not proceed until\b.*(?:preflight|gate|marker|seal|hash|verifier).*\bpass",
        r"\bonly after\b.*(?:preflight|gate|marker|seal|hash|verifier).*\bpass.*\b(?:build|test|proceed|continue)\b",
    )
)

NEGATIONS = (
    "不得", "不需要", "不是", "不能", "不自动", "禁止", "不再", "无需",
    "不要求", "不要", "不存在", "不会", "不应", "默认 opt-in", "只在", "仅在",
)

REQUIRED_FILES = tuple(
    sorted(
        set(SHIMS)
        | {".github/ai-env/contracts/agent-env-policy.json"}
        | {relative for files in SCENARIOS.values() for relative in files}
    )
)


def nested(payload: object, keys: tuple[str, ...]) -> object:
    value = payload
    for key in keys:
        if not isinstance(value, dict) or key not in value:
            return None
        value = value[key]
    return value


def read(root: Path, relative: str, errors: list[str]) -> str:
    try:
        return (root / relative).read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        errors.append(f"{relative}: unreadable: {exc}")
        return ""


def active_sources(root: Path) -> tuple[str, ...]:
    paths = set(GENERAL_POLICY_FILES) | set(SHIMS) | {
        ".github/agentic-hardware-blueprint.md",
        ".github/copilot-instructions.md",
        ".github/ai-env/README.md",
    }
    for pattern in ACTIVE_SOURCE_GLOBS:
        paths.update(path.relative_to(root).as_posix() for path in root.glob(pattern) if path.is_file())
    return tuple(sorted(relative for relative in paths if (root / relative).is_file()))


def validate_policy(root: Path, errors: list[str]) -> None:
    relative = ".github/ai-env/contracts/agent-env-policy.json"
    try:
        policy = json.loads((root / relative).read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        errors.append(f"{relative}: invalid JSON: {exc}")
        return
    for keys, expected in POLICY_EXPECTATIONS:
        actual = nested(policy, keys)
        if actual != expected:
            errors.append(f"policy {'.'.join(keys)}: expected {expected!r}, got {actual!r}")
    if nested(policy, ("operating_contract", "compaction_recovery_order")) != COMPACTION_ORDER:
        errors.append("policy operating_contract.compaction_recovery_order is invalid")
    questions = nested(policy, ("validation_budget", "new_check_questions"))
    if not isinstance(questions, list) or len(questions) != 3:
        errors.append("policy validation_budget.new_check_questions must contain three questions")
    criteria = nested(policy, ("specialized_assurance", "hash_and_sha", "allowed_criteria"))
    if not isinstance(criteria, list) or not HASH_CRITERIA.issubset(criteria):
        errors.append("policy hash_and_sha.allowed_criteria is incomplete")


def validate_shims(root: Path, errors: list[str]) -> None:
    for relative in SHIMS:
        text = read(root, relative, errors)
        if ".github/AGENTS.md" not in text:
            errors.append(f"{relative}: missing canonical link")
        for anchor in ("acceptance criteria", "inspect/edit/build/test/collect/analyze"):
            if anchor not in text:
                errors.append(f"{relative}: missing fallback {anchor!r}")
        if not any(anchor in text for anchor in ("不自创 gate", "不得自行增加 gate")):
            errors.append(f"{relative}: missing no-self-created-gate fallback")
        if not any(anchor in text for anchor in ("破坏性、难恢复或外部副作用", "破坏性、难恢复或有外部副作用")):
            errors.append(f"{relative}: missing destructive/external fallback")
        for anchor in ("RTL", "DiffTest", "综合", "STA", "PPA", "release", "security"):
            if anchor not in text:
                errors.append(f"{relative}: missing correctness fallback {anchor!r}")
        if len(text.splitlines()) > (30 if relative == "AGENTS.md" else 20):
            errors.append(f"{relative}: compatibility shim is no longer thin")


def validate_scenarios(root: Path, errors: list[str]) -> None:
    for scenario, files in SCENARIOS.items():
        for relative, anchors in files.items():
            text = read(root, relative, errors)
            for anchor in anchors:
                if anchor not in text:
                    errors.append(f"scenario {scenario}: {relative} missing {anchor!r}")


def validate_active_sources(root: Path, errors: list[str]) -> None:
    for relative in active_sources(root):
        negative_section = False
        for line_no, line in enumerate(read(root, relative, errors).splitlines(), start=1):
            if line.lstrip().startswith("#"):
                lower = line.lower()
                negative_section = any(term in lower for term in ("禁止", "反模式", "anti-pattern", "forbidden examples"))
                continue
            if negative_section or any(term in line for term in NEGATIONS):
                continue
            if any(pattern.search(line) for pattern in PROCESS_GATE_PATTERNS):
                errors.append(f"{relative}:{line_no}: unconditional process gate: {line.strip()}")


def validate(root: Path) -> list[str]:
    errors = [f"{relative}: required active source is missing" for relative in REQUIRED_FILES if not (root / relative).is_file()]
    if errors:
        return errors
    validate_policy(root, errors)
    validate_shims(root, errors)
    validate_scenarios(root, errors)
    validate_active_sources(root, errors)
    return errors


def json_mutation(keys: tuple[str, ...], value: object) -> Callable[[Path], None]:
    def mutate(root: Path) -> None:
        path = root / ".github/ai-env/contracts/agent-env-policy.json"
        payload = json.loads(path.read_text(encoding="utf-8"))
        cursor = payload
        for key in keys[:-1]:
            cursor = cursor[key]
        cursor[keys[-1]] = value
        path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return mutate


def text_mutation(relative: str, old: str, new: str) -> Callable[[Path], None]:
    def mutate(root: Path) -> None:
        path = root / relative
        text = path.read_text(encoding="utf-8")
        if text.count(old) != 1:
            raise RuntimeError(f"non-unique mutation anchor in {relative}: {old!r}")
        path.write_text(text.replace(old, new, 1), encoding="utf-8")
    return mutate


def append_mutation(relative: str, line: str) -> Callable[[Path], None]:
    def mutate(root: Path) -> None:
        path = root / relative
        path.write_text(path.read_text(encoding="utf-8") + f"\n{line}\n", encoding="utf-8")
    return mutate


MUTATIONS: tuple[tuple[str, str, Callable[[Path], None]], ...] = (
    (
        "changed-paths-create-gates",
        "changed_paths_create_gates",
        json_mutation(("lightweight_workflow", "changed_paths_create_gates"), True),
    ),
    (
        "zero-gate-empty-set-pass",
        "zero_gate_finish_is_engineering_pass",
        json_mutation(
            ("lightweight_workflow", "zero_gate_finish_is_engineering_pass"), True
        ),
    ),
    (
        "compaction-order-drift",
        "compaction_recovery_order",
        json_mutation(
            ("operating_contract", "compaction_recovery_order"),
            ["historical_agent_gate", *COMPACTION_ORDER[1:]],
        ),
    ),
    (
        "release-not-fail-closed",
        "release.fail_closed",
        json_mutation(("specialized_assurance", "release", "fail_closed"), False),
    ),
    (
        "destructive-boundary-removed",
        "destructive-and-external-boundary",
        text_mutation(
            ".github/AGENTS.md", "破坏性、难恢复或有外部副作用的动作", "普通动作"
        ),
    ),
    (
        "shim-detached",
        "CLAUDE.md: missing canonical link",
        text_mutation(
            "CLAUDE.md",
            "完整规范见 [.github/AGENTS.md](./.github/AGENTS.md)。若无法继续读取链接：",
            "完整规范见旧规则。若无法继续读取链接：",
        ),
    ),
    (
        "self-created-preflight",
        "unconditional process gate",
        append_mutation(
            ".github/instructions/agent-lightweight-workflow.instructions.md",
            "只有 preflight PASS 后才允许 build。",
        ),
    ),
    (
        "global-unique-shell",
        "unconditional process gate",
        append_mutation(
            ".github/agents/ysyx-coordinator.agent.md",
            "全工作区 unique shell 必须由一个 agent 持有才可继续。",
        ),
    ),
    (
        "verifier-anomaly-ignored",
        "verifier-anomaly-escalation",
        text_mutation(
            ".github/instructions/agent-env-state-machine.instructions.md",
            "结果矛盾、缺失或 verifier 异常",
            "结果矛盾或缺失",
        ),
    ),
    (
        "ppa-comparability-weakened",
        "hardware-correctness-preserved",
        text_mutation(
            ".github/agents/hardware-flow.agent.md",
            "PPA A/B 必须绑定相同 RTL/filelist/parameter/define/tool/config/corner/workload",
            "PPA A/B 可以比较任意两个结果",
        ),
    ),
)


def copy_fixture(source: Path, target: Path) -> None:
    for relative in REQUIRED_FILES:
        destination = target / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source / relative, destination)


def test_mutations(source: Path) -> list[str]:
    failures: list[str] = []
    with tempfile.TemporaryDirectory(prefix="agent-contract-test-") as tmp:
        base = Path(tmp)
        pristine = base / "pristine"
        copy_fixture(source, pristine)
        for error in validate(pristine):
            failures.append(f"fixture baseline is invalid: {error}")
        if failures:
            return failures
        for name, expected_error, mutate in MUTATIONS:
            fixture = base / name
            copy_fixture(source, fixture)
            mutate(fixture)
            errors = validate(fixture)
            if not any(expected_error in error for error in errors):
                failures.append(
                    f"mutation {name}: expected {expected_error!r}, got {errors!r}"
                )
    return failures


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=REPO_ROOT)
    parser.add_argument("--positive-only", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    root = args.repo_root.resolve()
    errors = validate(root)
    if not errors and not args.positive_only:
        errors.extend(test_mutations(root))
    payload = {
        "ok": not errors,
        "scenarios": len(SCENARIOS),
        "shims": len(SHIMS),
        "active_sources": len(active_sources(root)),
        "mutations": 0 if args.positive_only else len(MUTATIONS),
        "errors": errors,
    }
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    elif errors:
        for error in errors:
            print(f"[agent-operating-contract-test] FAIL {error}")
    else:
        print(
            "[agent-operating-contract-test] PASS "
            f"scenarios={payload['scenarios']} shims={payload['shims']} "
            f"active_sources={payload['active_sources']} mutations={payload['mutations']}"
        )
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
