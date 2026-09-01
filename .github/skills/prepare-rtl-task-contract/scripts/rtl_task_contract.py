#!/usr/bin/env python3
"""生成、校验并渲染本地 RV64 RTL 子任务契约。"""

from __future__ import annotations

import argparse
import copy
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys
import tempfile
from typing import Any, Iterable


SOURCE_CONTRACT = ".github/ai-env/contracts/agent-env-rtl-task-contract.json"
CURRENT_CONTRACT_SCHEMA_VERSION = 2
LEGACY_CONTRACT_SCHEMA_VERSION = 1
CANONICAL_SCOPE_FIELDS = {
    "workspace_root",
    "allowed_paths",
    "write_paths",
    "allowed_commands",
}
TASK_ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]{1,127}$")
FIXED_FINDING_CAP_RE = re.compile(
    r"(?:"
    r"(?:最多|至多|不超过)\s*(?:报告|列出|返回|给出|保留)?\s*"
    r"(?:[0-9]+|[一二三四五六七八九十百]+)\s*(?:个|项|条)\s*"
    r"(?:P[0-3](?:/P[0-3])?\s*)?(?:反例|问题|阻断项|发现)"
    r"|"
    r"(?:at\s+most|no\s+more\s+than|limit(?:ed)?\s+to|top)\s+\d+\s+"
    r"(?:P[0-3](?:/P[0-3])?\s+)?(?:counterexamples?|blockers?|findings?|issues?)"
    r")",
    re.IGNORECASE,
)
LEGACY_LANGUAGE_POLICY = {
    "preserve_rtl_identifiers": True,
    "domain_accurate_wording": True,
    "local_rv64_rtl_scope_only": True,
}
CANONICAL_PURPOSE_CATALOG: dict[str, dict[str, str]] = {
    "rg": {
        "mode": "read-only",
        "purpose": "search-allowed-paths",
        "label_zh": "只读检索允许路径",
    },
    "sed": {
        "mode": "read-only",
        "purpose": "view-selected-lines",
        "label_zh": "只读查看指定文本行",
    },
    "git status": {
        "mode": "read-only",
        "purpose": "inspect-worktree-status",
        "label_zh": "只读查看工作树状态",
    },
    "git diff": {
        "mode": "read-only",
        "purpose": "inspect-scoped-diff",
        "label_zh": "只读查看限定差异",
    },
    "git show": {
        "mode": "read-only",
        "purpose": "inspect-versioned-content",
        "label_zh": "只读查看版本化内容",
    },
    "sha256sum": {
        "mode": "read-only",
        "purpose": "hash-declared-artifact",
        "label_zh": "计算已声明产物哈希",
    },
    "apply_patch": {
        "mode": "write-within-scope",
        "purpose": "edit-declared-write-paths",
        "label_zh": "修改已声明写路径",
    },
    "python3": {
        "mode": "write-within-scope",
        "purpose": "run-declared-workspace-script",
        "label_zh": "运行已声明工作区脚本",
    },
    "bash": {
        "mode": "write-within-scope",
        "purpose": "run-declared-workspace-script",
        "label_zh": "运行已声明工作区脚本",
    },
    "make": {
        "mode": "write-within-scope",
        "purpose": "run-declared-build",
        "label_zh": "运行已声明构建",
    },
    "cmake": {
        "mode": "write-within-scope",
        "purpose": "configure-declared-build",
        "label_zh": "配置已声明构建",
    },
    "ninja": {
        "mode": "write-within-scope",
        "purpose": "run-declared-build",
        "label_zh": "运行已声明构建",
    },
    "pytest": {
        "mode": "write-within-scope",
        "purpose": "run-declared-tests",
        "label_zh": "运行已声明测试",
    },
    "iverilog": {
        "mode": "write-within-scope",
        "purpose": "run-declared-rtl-verification",
        "label_zh": "运行已声明 RTL 验证",
    },
    "verilator": {
        "mode": "write-within-scope",
        "purpose": "run-declared-rtl-verification",
        "label_zh": "运行已声明 RTL 验证",
    },
    "yosys": {
        "mode": "write-within-scope",
        "purpose": "run-declared-synthesis",
        "label_zh": "运行已声明综合",
    },
    "openroad": {
        "mode": "write-within-scope",
        "purpose": "run-declared-ppa-flow",
        "label_zh": "运行已声明 PPA 流程",
    },
}


def repo_root_from_script() -> Path:
    return Path(__file__).resolve().parents[4]


def load_json(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError(f"JSON 顶层必须是 object: {path}")
    return data


def load_config(repo_root: Path) -> dict[str, Any]:
    return load_json(repo_root / SOURCE_CONTRACT)


def unique(items: Iterable[str]) -> list[str]:
    result: list[str] = []
    seen: set[str] = set()
    for raw in items:
        item = raw.strip()
        if item and item not in seen:
            result.append(item)
            seen.add(item)
    return result


def repo_relative_path(value: str) -> tuple[str, str | None]:
    if not isinstance(value, str) or not value.strip():
        return "", "path must be a non-empty string"
    raw = value.strip()
    if "\\" in raw:
        return raw, "path must use repository-relative POSIX separators"
    path = PurePosixPath(raw)
    if path.is_absolute() or raw.startswith("/"):
        return raw, "path must be repository-relative"
    if any(part in {"", ".", ".."} for part in path.parts):
        return raw, "path must not contain empty, '.' or '..' components"
    normalized = path.as_posix()
    if normalized in {"", "."}:
        return raw, "path must identify a file or directory below the repository root"
    return normalized, None


def path_is_within(child: str, parent: str) -> bool:
    return child == parent or child.startswith(parent.rstrip("/") + "/")


def string_list(
    value: Any,
    field: str,
    errors: list[str],
    *,
    allow_empty: bool = False,
    single_line: bool = False,
) -> list[str]:
    if not isinstance(value, list) or (not value and not allow_empty):
        qualifier = "a list" if allow_empty else "a non-empty list"
        errors.append(f"{field} must be {qualifier}")
        return []
    result: list[str] = []
    for index, item in enumerate(value):
        if not isinstance(item, str) or not item.strip():
            errors.append(f"{field}[{index}] must be a non-empty string")
            continue
        if "\x00" in item:
            errors.append(f"{field}[{index}] must not contain NUL")
            continue
        normalized = item.strip()
        if single_line and ("\n" in normalized or "\r" in normalized):
            errors.append(f"{field}[{index}] must be a single line")
            continue
        if normalized in result:
            errors.append(f"{field}[{index}] duplicates an earlier value")
            continue
        result.append(normalized)
    return result


def command_list(
    value: Any,
    field: str,
    errors: list[str],
    config: dict[str, Any],
    *,
    allow_empty: bool = False,
) -> list[dict[str, str]]:
    if not isinstance(value, list) or (not value and not allow_empty):
        qualifier = "a list" if allow_empty else "a non-empty list"
        errors.append(f"{field} must be {qualifier}")
        return []
    policy = config.get("command_policy", {})
    expected_fields = set(policy.get("entry_fields", []))
    modes = set(policy.get("modes", []))
    catalog = policy.get("purpose_catalog", {})
    result: list[dict[str, str]] = []
    seen: set[tuple[str, str]] = set()
    for index, item in enumerate(value):
        if not isinstance(item, dict):
            errors.append(f"{field}[{index}] must be an object")
            continue
        if set(item) != expected_fields:
            errors.append(f"{field}[{index}] fields must be command, mode and purpose")
            continue
        command = item.get("command")
        mode = item.get("mode")
        purpose = item.get("purpose")
        if not isinstance(command, str) or not command.strip():
            errors.append(f"{field}[{index}].command must be a non-empty string")
            continue
        if not isinstance(mode, str) or mode not in modes:
            errors.append(f"{field}[{index}].mode is not canonical")
            continue
        if not isinstance(purpose, str) or not purpose.strip():
            errors.append(f"{field}[{index}].purpose must be a non-empty string")
            continue
        if any(character in command or character in purpose for character in ("\x00", "\n", "\r")):
            errors.append(f"{field}[{index}] command and purpose must be single-line text")
            continue
        command = command.strip()
        purpose = purpose.strip()
        canonical = catalog.get(command) if isinstance(catalog, dict) else None
        if not isinstance(canonical, dict):
            errors.append(f"{field}[{index}].command is not in the canonical purpose catalog")
        else:
            if mode != canonical.get("mode"):
                errors.append(f"{field}[{index}].mode must match the canonical command mode")
            if purpose != canonical.get("purpose"):
                errors.append(f"{field}[{index}].purpose must match the canonical command purpose")
        identity = (command, mode)
        if identity in seen:
            errors.append(f"{field}[{index}] duplicates an earlier command/mode pair")
            continue
        seen.add(identity)
        result.append({"command": command, "mode": mode, "purpose": purpose})
    return result


def resolve_inside_repo(repo_root: Path, value: str | Path, label: str) -> Path:
    root = repo_root.resolve()
    candidate = Path(value)
    if not candidate.is_absolute():
        candidate = root / candidate
    resolved = candidate.resolve()
    try:
        resolved.relative_to(root)
    except ValueError as exc:
        raise ValueError(f"{label} must stay inside the repository") from exc
    return resolved


def validate_config(config: dict[str, Any], repo_root: Path | None = None) -> list[str]:
    errors: list[str] = []
    if config.get("schema_version") != CURRENT_CONTRACT_SCHEMA_VERSION:
        errors.append(
            f"config schema_version must be {CURRENT_CONTRACT_SCHEMA_VERSION}"
        )
    if config.get("contract_name") != "local-rtl-task-contract":
        errors.append("config contract_name must be local-rtl-task-contract")
    if config.get("engineering_domain") != "local-rv64-rtl":
        errors.append("config engineering_domain must be local-rv64-rtl")

    expected_paths = {
        "instruction": ".github/instructions/rtl-agent-task-contract.instructions.md",
        "skill": ".github/skills/prepare-rtl-task-contract/SKILL.md",
        "generator": ".github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py",
    }
    for key, expected in expected_paths.items():
        if config.get(key) != expected:
            errors.append(f"config {key} must be {expected}")
        if repo_root is not None and not (repo_root / expected).is_file():
            errors.append(f"config {key} path missing: {expected}")

    required_fields = config.get("required_fields")
    expected_fields = {
        "schema_version",
        "contract_type",
        "task_id",
        "engineering_domain",
        "task_kind",
        "goal",
        "scope",
        "context",
        "deliverables",
        "success_criteria",
        "status_policy",
        "language_policy",
        "source_contract",
    }
    if not isinstance(required_fields, list) or set(required_fields) != expected_fields:
        errors.append("config required_fields must match the canonical task contract fields")

    task_kinds = config.get("task_kinds")
    expected_kinds = {"read-only-review", "implementation", "verification", "ppa-analysis"}
    if not isinstance(task_kinds, list) or set(task_kinds) != expected_kinds:
        errors.append("config task_kinds must contain the four canonical task kinds")

    expected_wording_profile = {
        "profile": "rv64-hardware-professional",
        "reference": ".github/agentic-hardware-blueprint.md#rv64-hardware-professional-task-wording",
        "domain_reference": "npc/rv64/design/arch/rv64-hardware-wording-profile.md",
        "preserve_backticked_identifiers": True,
        "hardware_context_prefix_required": False,
        "preserve_technical_vocabulary": True,
        "keyword_blacklist_forbidden": True,
        "does_not_change_capabilities": True,
        "positive_local_scope_preamble_required": False,
        "rendered_prompt_style": "editable-compact-rv64-hardware-draft",
        "technical_narrative_subject": "local-rv64-rtl-object-or-evidence",
        "coordination_metadata_in_rendered_prompt": False,
        "final_response_evidence_order": [
            "rtl-object-or-local-artifact",
            "cycle-or-configuration",
            "testbench-or-eda-observation",
            "pass-gap-boundary",
        ],
        "ambiguity_context_dimensions": [
            "object", "level", "scope", "engineering-purpose"
        ],
    }
    if config.get("wording_profile") != expected_wording_profile:
        errors.append("config wording_profile must preserve the hardware-only prompt profile")
    elif repo_root is not None and not (
        repo_root / expected_wording_profile["reference"].split("#", 1)[0]
    ).is_file():
        errors.append("config wording_profile reference path is missing")
    elif repo_root is not None and not (
        repo_root / expected_wording_profile["domain_reference"]
    ).is_file():
        errors.append("config wording_profile domain reference path is missing")

    context_policy = config.get("context_policy")
    expected_context_policy = {
        "fields": ["required_files", "material_mode", "supplied_material"],
        "material_modes": ["workspace-files", "prompt-supplied-self-contained"],
        "default_mode": "workspace-files",
        "no_tools_mode": "prompt-supplied-self-contained",
        "no_tools_usage": "exceptional-bounded-evidence-review",
        "no_tools_task_kinds": ["read-only-review"],
    }
    if context_policy != expected_context_policy:
        errors.append("config context_policy does not match the canonical material modes")

    expected_reasoning_policy = {
        "recommended_outlets": [
            "unknowns",
            "assumptions",
            "counterexamples",
            "alternative_hypotheses",
            "scope_adjustment",
            "confidence_and_basis",
        ],
        "inconclusive_allowed": True,
        "forced_pass_forbidden": True,
        "fixed_finding_cap_forbidden": True,
        "scope_adjustment_handling": (
            "supplement-handoff-and-coordinate-write-ownership"
        ),
        "no_tools_claim_scope": "bounded-supplied-material-only",
    }
    if config.get("reasoning_policy") != expected_reasoning_policy:
        errors.append("config reasoning_policy must preserve the RTL correctness boundary")

    expected_tool_semantics = {
        "independent_operations": ["create", "validate", "render"],
        "operation_order_required": False,
        "render_output": "editable-prompt-draft",
        "subagent_context_mode": "caller-selected-relevant-context",
        "validation_failure_effect": "format-error-only",
        "scope_adjustment_action": (
            "supplement-handoff-and-coordinate-write-ownership"
        ),
        "automatic_hashing": False,
        "platform_interruption_effect": "no-technical-status-effect",
    }
    if config.get("legacy_tool_semantics") != expected_tool_semantics:
        errors.append("config legacy_tool_semantics must keep handoff operations optional")

    command_policy = config.get("command_policy")
    expected_read_only = ["rg", "sed", "git status", "git diff", "git show", "sha256sum"]
    expected_write_scoped = [
        "apply_patch",
        "python3",
        "bash",
        "make",
        "cmake",
        "ninja",
        "pytest",
        "iverilog",
        "verilator",
        "yosys",
        "openroad",
    ]
    if not isinstance(command_policy, dict):
        errors.append("config command_policy must be an object")
    else:
        expected_policy_fields = {
            "entry_fields",
            "modes",
            "read_only_commands",
            "write_scoped_commands",
            "purpose_catalog",
        }
        if set(command_policy) != expected_policy_fields:
            errors.append("config command_policy fields do not match the canonical policy schema")
        if command_policy.get("entry_fields") != ["command", "mode", "purpose"]:
            errors.append("config command_policy.entry_fields must be command/mode/purpose")
        if command_policy.get("modes") != ["read-only", "write-within-scope"]:
            errors.append("config command_policy.modes are not canonical")
        if command_policy.get("read_only_commands") != expected_read_only:
            errors.append("config command_policy.read_only_commands are not canonical")
        if command_policy.get("write_scoped_commands") != expected_write_scoped:
            errors.append("config command_policy.write_scoped_commands are not canonical")
        catalog = command_policy.get("purpose_catalog")
        expected_commands = set(expected_read_only) | set(expected_write_scoped)
        if not isinstance(catalog, dict) or set(catalog) != expected_commands:
            errors.append("config command_policy.purpose_catalog must cover every canonical command")
        else:
            if catalog != CANONICAL_PURPOSE_CATALOG:
                errors.append("config command_policy.purpose_catalog differs from the fixed catalog")
            for command, entry in catalog.items():
                if not isinstance(entry, dict) or set(entry) != {"mode", "purpose", "label_zh"}:
                    errors.append(f"config purpose_catalog.{command} fields are not canonical")
                    continue
                expected_mode = "read-only" if command in expected_read_only else "write-within-scope"
                if entry.get("mode") != expected_mode:
                    errors.append(f"config purpose_catalog.{command}.mode must be {expected_mode}")
                purpose = entry.get("purpose")
                if not isinstance(purpose, str) or not re.fullmatch(r"[a-z0-9][a-z0-9-]{2,63}", purpose):
                    errors.append(f"config purpose_catalog.{command}.purpose must be a canonical code")
                label = entry.get("label_zh")
                if not isinstance(label, str) or not label.strip() or any(
                    character in label for character in ("\x00", "\n", "\r")
                ):
                    errors.append(f"config purpose_catalog.{command}.label_zh must be one line")

    defaults = config.get("scope_defaults")
    if not isinstance(defaults, dict):
        errors.append("config scope_defaults must be an object")
    else:
        if defaults != {"workspace_root": "."}:
            errors.append("config scope_defaults must contain only workspace_root='.'")

    status = config.get("status_policy")
    if not isinstance(status, dict):
        errors.append("config status_policy must be an object")
    else:
        expected_status = {
            "review_state": "not_requested",
            "parent_goal_state": "unchanged",
            "isolate_review_to_subtask": False,
            "preserve_original_request": True,
            "semantic_distortion_retry_forbidden": True,
            "official_feedback_recommended": False,
        }
        if status != expected_status:
            errors.append("config status_policy does not match the optional-handoff policy")

    language = config.get("language_policy")
    expected_language = {
        "preserve_rtl_identifiers": True,
        "domain_accurate_wording": True,
        "wording_preserves_task_semantics": True,
    }
    if language != expected_language:
        errors.append("config language_policy does not match the canonical wording policy")
    return errors


def validate_contract(data: dict[str, Any], config: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    required = config.get("required_fields", [])
    for field in required:
        if field not in data:
            errors.append(f"missing required field: {field}")
    unexpected_fields = set(data) - set(required)
    if unexpected_fields:
        errors.append(f"unexpected top-level fields: {sorted(unexpected_fields)}")

    schema_version = data.get("schema_version")
    if schema_version not in {
        LEGACY_CONTRACT_SCHEMA_VERSION,
        CURRENT_CONTRACT_SCHEMA_VERSION,
    }:
        errors.append(
            "schema_version must be "
            f"{LEGACY_CONTRACT_SCHEMA_VERSION} or {CURRENT_CONTRACT_SCHEMA_VERSION}"
        )
    if data.get("contract_type") != "local-rtl-task":
        errors.append("contract_type must be local-rtl-task")
    task_id = data.get("task_id")
    if not isinstance(task_id, str) or not TASK_ID_RE.fullmatch(task_id):
        errors.append("task_id must use 2-128 lower-case letters, digits, '.', '_' or '-'")
    if data.get("engineering_domain") != config.get("engineering_domain"):
        errors.append("engineering_domain must be local-rv64-rtl")
    task_kind = data.get("task_kind")
    if task_kind not in config.get("task_kinds", []):
        errors.append("task_kind is not allowed by the canonical contract")
    goal = data.get("goal")
    if not isinstance(goal, str) or not goal.strip():
        errors.append("goal must be a non-empty string")
    elif "\x00" in goal:
        errors.append("goal must not contain NUL")

    context_policy = config.get("context_policy", {})
    workspace_material_mode = context_policy.get("default_mode", "workspace-files")
    no_tools_material_mode = context_policy.get(
        "no_tools_mode", "prompt-supplied-self-contained"
    )
    raw_context = data.get("context")
    material_mode = workspace_material_mode
    if isinstance(raw_context, dict):
        material_mode = raw_context.get("material_mode", workspace_material_mode)
    scope = data.get("scope")
    allowed_paths: list[str] = []
    write_paths: list[str] = []
    allowed_commands: list[dict[str, str]] = []
    if not isinstance(scope, dict):
        errors.append("scope must be an object")
    else:
        scope_fields = set(scope)
        if schema_version == CURRENT_CONTRACT_SCHEMA_VERSION:
            if scope_fields != CANONICAL_SCOPE_FIELDS:
                errors.append("scope fields must match the canonical v2 scope schema")
        elif schema_version == LEGACY_CONTRACT_SCHEMA_VERSION:
            if not CANONICAL_SCOPE_FIELDS.issubset(scope_fields):
                errors.append("legacy scope is missing canonical path/command fields")
            legacy_scope_flags = scope_fields - CANONICAL_SCOPE_FIELDS
            if any(scope.get(key) is not False for key in legacy_scope_flags):
                errors.append("legacy scope extension flags must be false")
        allowed_paths = string_list(scope.get("allowed_paths"), "scope.allowed_paths", errors)
        write_paths = string_list(
            scope.get("write_paths"), "scope.write_paths", errors, allow_empty=True
        )
        allowed_commands = command_list(
            scope.get("allowed_commands"),
            "scope.allowed_commands",
            errors,
            config,
            allow_empty=True,
        )
        if scope.get("workspace_root") != ".":
            errors.append("scope.workspace_root must be '.'")

    normalized_allowed: list[str] = []
    for index, raw in enumerate(allowed_paths):
        normalized, error = repo_relative_path(raw)
        if error:
            errors.append(f"scope.allowed_paths[{index}] {error}")
        elif normalized != raw:
            errors.append(f"scope.allowed_paths[{index}] must already be normalized")
        else:
            normalized_allowed.append(normalized)
    for index, raw in enumerate(write_paths):
        normalized, error = repo_relative_path(raw)
        if error:
            errors.append(f"scope.write_paths[{index}] {error}")
            continue
        if normalized != raw:
            errors.append(f"scope.write_paths[{index}] must already be normalized")
        if not any(path_is_within(normalized, parent) for parent in normalized_allowed):
            errors.append(f"scope.write_paths[{index}] must be inside scope.allowed_paths")

    if task_kind == "read-only-review" and write_paths:
        errors.append("read-only-review must not declare write_paths")
    if task_kind == "read-only-review" and any(
        entry["mode"] != "read-only" for entry in allowed_commands
    ):
        errors.append("read-only-review commands must all use read-only mode")
    if task_kind == "implementation" and not write_paths:
        errors.append("implementation must declare at least one write_path")
    if task_kind == "implementation" and not any(
        entry["mode"] == "write-within-scope" for entry in allowed_commands
    ):
        errors.append("implementation must declare at least one write-within-scope command")
    if any(entry["mode"] == "write-within-scope" for entry in allowed_commands) and not write_paths:
        errors.append("write-within-scope commands require at least one write_path")

    context = data.get("context")
    required_context: list[str] = []
    supplied_material: list[str] = []
    canonical_context = False
    if not isinstance(context, dict):
        errors.append("context must be an object")
    else:
        context_fields = set(context)
        legacy_context_fields = {"required_files"}
        canonical_context_fields = set(context_policy.get("fields", []))
        if context_fields == legacy_context_fields:
            material_mode = workspace_material_mode
        elif context_fields != canonical_context_fields:
            errors.append(
                "context fields must be legacy required_files or canonical "
                "required_files/material_mode/supplied_material"
            )
        required_context = string_list(context.get("required_files"), "context.required_files", errors)
        if context_fields == canonical_context_fields:
            canonical_context = True
            material_mode = context.get("material_mode")
            if material_mode not in context_policy.get("material_modes", []):
                errors.append("context.material_mode is not canonical")
            supplied_material = string_list(
                context.get("supplied_material"),
                "context.supplied_material",
                errors,
                allow_empty=True,
                single_line=True,
            )
        for index, raw in enumerate(required_context):
            normalized, error = repo_relative_path(raw)
            if error:
                errors.append(f"context.required_files[{index}] {error}")
            elif normalized != raw:
                errors.append(f"context.required_files[{index}] must already be normalized")
    for required_path in config.get("required_context", []):
        if required_path not in required_context:
            errors.append(f"context.required_files missing canonical context: {required_path}")
    if task_kind == "implementation" and config.get("implementation_context") not in required_context:
        errors.append("implementation context must include rtl-generation-workflow.instructions.md")
    for index, context_path in enumerate(required_context):
        normalized, error = repo_relative_path(context_path)
        if error is None and not any(path_is_within(normalized, parent) for parent in normalized_allowed):
            errors.append(f"context.required_files[{index}] must be inside scope.allowed_paths")

    if material_mode == no_tools_material_mode:
        if task_kind not in context_policy.get("no_tools_task_kinds", []):
            errors.append("self-contained no-tools mode is allowed only for read-only-review")
        if allowed_commands:
            errors.append("self-contained no-tools mode must not declare allowed_commands")
        if write_paths:
            errors.append("self-contained no-tools mode must not declare write_paths")
        if not supplied_material:
            errors.append("self-contained no-tools mode requires non-empty supplied_material")
    elif material_mode == workspace_material_mode:
        if supplied_material:
            errors.append("workspace-files mode must not declare supplied_material")

    deliverables = string_list(data.get("deliverables"), "deliverables", errors)
    success_criteria = string_list(
        data.get("success_criteria"), "success_criteria", errors
    )
    technical_narrative = [goal] if isinstance(goal, str) else []
    technical_narrative.extend(deliverables)
    technical_narrative.extend(success_criteria)
    technical_narrative.extend(supplied_material)
    if canonical_context and config.get("reasoning_policy", {}).get(
        "fixed_finding_cap_forbidden"
    ):
        if any(FIXED_FINDING_CAP_RE.search(item) for item in technical_narrative):
            errors.append(
                "fixed finding count caps are forbidden; rank findings without truncation"
            )
    if data.get("status_policy") != config.get("status_policy"):
        errors.append("status_policy must match the canonical optional-handoff policy")
    language_policy = data.get("language_policy")
    legacy_language_policy_valid = (
        isinstance(language_policy, dict)
        and len(language_policy) == 3
        and language_policy.get("preserve_rtl_identifiers") is True
        and language_policy.get("domain_accurate_wording") is True
        and all(value is True for value in language_policy.values())
    )
    if schema_version == CURRENT_CONTRACT_SCHEMA_VERSION:
        language_policy_valid = language_policy == config.get("language_policy")
    else:
        language_policy_valid = (
            language_policy == config.get("language_policy")
            or legacy_language_policy_valid
        )
    if not language_policy_valid:
        errors.append("language_policy must match the canonical wording policy")
    if data.get("source_contract") != SOURCE_CONTRACT:
        errors.append(f"source_contract must be {SOURCE_CONTRACT}")
    return errors


def build_contract(
    args: argparse.Namespace,
    config: dict[str, Any],
) -> dict[str, Any]:
    required_context = unique([*config["required_context"], *(args.required_context or [])])
    if args.task_kind == "implementation":
        required_context = unique([*required_context, config["implementation_context"]])
    allowed_paths = unique([*args.allow_path, *required_context])
    defaults = config["scope_defaults"]
    context_policy = config["context_policy"]
    material_mode = (
        context_policy["no_tools_mode"]
        if args.self_contained_no_tools
        else context_policy["default_mode"]
    )
    purpose_catalog = config["command_policy"]["purpose_catalog"]
    allowed_commands = [
        {
            "command": command.strip(),
            "mode": "read-only",
            "purpose": purpose_catalog.get(command.strip(), {}).get("purpose", ""),
        }
        for command in (args.allow_read_command or [])
    ]
    allowed_commands.extend(
        {
            "command": command.strip(),
            "mode": "write-within-scope",
            "purpose": purpose_catalog.get(command.strip(), {}).get("purpose", ""),
        }
        for command in (args.allow_write_command or [])
    )
    return {
        "schema_version": CURRENT_CONTRACT_SCHEMA_VERSION,
        "contract_type": "local-rtl-task",
        "task_id": args.task_id,
        "engineering_domain": config["engineering_domain"],
        "task_kind": args.task_kind,
        "goal": args.goal.strip(),
        "scope": {
            "workspace_root": defaults["workspace_root"],
            "allowed_paths": allowed_paths,
            "write_paths": unique(args.write_path or []),
            "allowed_commands": allowed_commands,
        },
        "context": {
            "required_files": required_context,
            "material_mode": material_mode,
            "supplied_material": unique(args.supplied_material or []),
        },
        "deliverables": unique(args.deliverable),
        "success_criteria": unique(args.success_criterion),
        "status_policy": copy.deepcopy(config["status_policy"]),
        "language_policy": copy.deepcopy(config["language_policy"]),
        "source_contract": SOURCE_CONTRACT,
    }


def atomic_write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            json.dump(data, handle, ensure_ascii=False, indent=2)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    except BaseException:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise


def bullet_lines(items: list[str]) -> str:
    return "\n".join(f"- {item}" for item in items)


def labeled_bullet_lines(items: list[str], label: str) -> str:
    """让自由文本始终以本地 RV64 工程对象为主语，不改写原始技术内容。"""
    return "\n".join(f"- {label}：{item}" for item in items)


def command_scope_lines(items: list[dict[str, str]]) -> str:
    if not items:
        return "- 无（未提供建议命令）"
    return "\n".join(
        f"- command={item['command']}; mode={item['mode']}"
        for item in items
    )


def command_purpose_lines(items: list[dict[str, str]], config: dict[str, Any]) -> str:
    if not items:
        return "- 无（未提供建议命令用途）"
    catalog = config["command_policy"]["purpose_catalog"]
    return "\n".join(
        f"- {item['command']}: purpose={item['purpose']}; label={catalog[item['command']]['label_zh']}"
        for item in items
    )


def render_contract(
    data: dict[str, Any],
    config: dict[str, Any],
) -> str:
    scope = data["scope"]
    context = data["context"]
    writes = scope["write_paths"] or ["无（只读）"]
    material_mode = context.get(
        "material_mode", config["context_policy"]["default_mode"]
    )
    no_tools = material_mode == config["context_policy"]["no_tools_mode"]
    if no_tools:
        execution_mode = "`self-contained-no-tools`（冻结材料 RTL 复核；不执行命令或仓库读取）"
    elif scope["write_paths"]:
        execution_mode = "`workspace-files`（声明关注范围与写入 ownership；可检查必要调用链）"
    else:
        execution_mode = "`workspace-files`（声明关注范围；默认不修改源码）"
    path_heading = (
        "材料来源路径（仅作 provenance；本节点不读取这些仓库文件）："
        if no_tools
        else "RTL/spec/TB/evidence 输入路径："
    )
    supplied_material = context.get("supplied_material", [])
    supplied_section = (
        "## 冻结 RTL 材料\n\n" + bullet_lines(supplied_material) + "\n\n"
        if no_tools
        else ""
    )
    execution_note = (
        "冻结材料复核不执行工程命令，也不读取上列材料之外的文件；结论只覆盖这些本地 RV64 RTL 材料。"
        if no_tools
        else "只有任务竞争同一 build/scratch、配置、数据库、仿真进程、许可证、端口或设备时才协调串行；独立资源上的安全本地动作可以并行。"
    )
    return f"""# 可编辑的本地 RV64 CPU RTL/验证提示草稿 `{data['task_id']}`

> 这是 `render` 根据兼容 JSON 产生的可编辑 prompt draft。可以结合当前相关上下文修改；
> 不要求逐字派发，JSON 格式校验也不赋予权限或判定 RTL correctness。

- RV64 RTL/证据对象：{data['goal']}
- 流水线配置：任务类型 `{data['task_kind']}`；执行模式 {execution_mode}
- 可选结论摘要格式：`RV64 RTL 结论｜对象=<module/signal/本地证据路径>｜周期/配置=<cycle/config>｜TB/EDA 观测=<testbench/仿真/综合/STA 结果>｜范围=<PASS/GAP/inconclusive>`

## 本地 RTL 输入、动作与产物

{path_heading}
{bullet_lines(scope['allowed_paths'])}

RTL/证据输出路径：
{bullet_lines(writes)}

建议工程命令：
{command_scope_lines(scope['allowed_commands'])}

建议命令用途（兼容枚举）：
{command_purpose_lines(scope['allowed_commands'], config)}

上列路径是 focus 与协作 ownership，上列命令是建议入口，不是平台权限白名单。可以读取理解目标所必需的
本地调用者、被调用者和配置，也可以选择等价的安全本地命令；写入其它 owner 的文件前先协调冲突。

## RV64 RTL 必读材料

{bullet_lines(context['required_files'])}

{supplied_section}## RV64 微架构复核边界

- 报告 `unknowns`、显式假设、RTL/TB 反例、替代微架构解释、置信度及其本地证据基础。
- 信息不足时允许给出 `inconclusive`，不得为了满足预期而强制给出 PASS。
- 不设置固定发现数量上限；不得截断仍影响 RTL 结论的 blocker、反例或覆盖洞。
- 缺少必要上下游 RTL/spec/TB 时列出所需材料及原因；安全只读扩展可直接进行并在结果中说明，写入扩展
  若与其他 agent ownership 冲突则先协调。
- 可以提出合同未预设的微架构解释或设计方案；只有真正超出用户目标、破坏性、难恢复或外部副作用的
  动作才需要新的用户授权。

## RV64 RTL 交付

{labeled_bullet_lines(data['deliverables'], "本地 RV64 RTL 交付")}

## RV64 RTL 判定条件

{labeled_bullet_lines(data['success_criteria'], "本地 RV64 RTL 判定")}

## 最终技术回复

- 推荐尽早按“对象｜周期/配置｜TB/EDA 观测｜范围”给出结论，不要求固定首行。
- 若本地 RV64 RTL 证据 JSON 的字段在定向 Python 单测中得到非预期返回结果，写明 CPU 证据对象、具体 schema 字段、工作区相对路径、测试名和返回码。
- 该叙述顺序不删除反例、未知项、替代假设、原始日志 marker 或真实文件名。
- 需要调整范围时补充 handoff 上下文；新写路径若与其他 agent ownership 重叠，先协调冲突。
- 保留真实 RTL 文件、module、signal、TB、日志 marker 与 schema 字段名称。
- {execution_note}
"""


def audit_wiring(repo_root: Path, config: dict[str, Any]) -> list[str]:
    errors = validate_config(config, repo_root)
    checks = {
        ".github/AGENTS.md": "可用 rtl-agent-task-contract instruction",
        "AI_ENVIRONMENT.md": "prepare-rtl-task-contract",
        ".github/agents/ysyx-coordinator.agent.md": "局部且清楚的 RV64 任务可以直接派发",
        ".github/instructions/rtl-agent-task-contract.instructions.md": "不是 permission gate",
        ".github/skills/prepare-rtl-task-contract/SKILL.md": "Optional legacy JSON",
        ".github/e2e/profiles/agent-system.tsv": "rtl-task-contract|agent-system|e2e_agent_system_rtl_task_contract|agent-system|",
        "scripts/e2e/modules/agent_system.sh": "e2e_agent_system_rtl_task_contract()",
        "scripts/package-ai-dev-env.sh": "agent-env-rtl-task-contract.json",
    }
    for relative, marker in checks.items():
        path = repo_root / relative
        if not path.is_file():
            errors.append(f"wiring path missing: {relative}")
            continue
        if marker not in path.read_text(encoding="utf-8"):
            errors.append(f"wiring marker missing in {relative}: {marker}")

    policy_path = repo_root / ".github/ai-env/contracts/agent-env-policy.json"
    try:
        policy = load_json(policy_path)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        errors.append(f"cannot read policy contract: {exc}")
    else:
        delegation = policy.get("task_delegation")
        if not isinstance(delegation, dict):
            errors.append("policy task_delegation must be an object")
        elif delegation:
            errors.append("policy task_delegation must not make the optional handoff an ordinary-task gate")

    operating_scope = config.get("operating_scope")
    if not isinstance(operating_scope, dict):
        errors.append("operating_scope must describe the legacy optional boundary")
    elif (
        operating_scope.get("ordinary_task_required") is not False
        or operating_scope.get("permission_or_authorization_boundary") is not False
        or operating_scope.get("correctness_gate") is not False
    ):
        errors.append("operating_scope must keep legacy JSON out of ordinary authorization and correctness")
    return errors


def self_test(config: dict[str, Any]) -> tuple[int, list[str]]:
    base = {
        "schema_version": CURRENT_CONTRACT_SCHEMA_VERSION,
        "contract_type": "local-rtl-task",
        "task_id": "self-test-review",
        "engineering_domain": "local-rv64-rtl",
        "task_kind": "read-only-review",
        "goal": "只读复核一个本地 RTL 接口不变量",
        "scope": {
            "workspace_root": ".",
            "allowed_paths": [
                "npc/rv64/vsrc/writeback/OooRob.v",
                *config["required_context"],
            ],
            "write_paths": [],
            "allowed_commands": [
                {"command": "rg", "mode": "read-only", "purpose": "search-allowed-paths"},
                {"command": "sed", "mode": "read-only", "purpose": "view-selected-lines"},
            ],
        },
        "context": {
            "required_files": list(config["required_context"]),
            "material_mode": config["context_policy"]["default_mode"],
            "supplied_material": [],
        },
        "deliverables": ["列出反例、证据位置和剩余风险"],
        "success_criteria": ["每条结论引用目标 RTL 或 spec 的可复核位置"],
        "status_policy": copy.deepcopy(config["status_policy"]),
        "language_policy": copy.deepcopy(config["language_policy"]),
        "source_contract": SOURCE_CONTRACT,
    }
    messages: list[str] = []
    if validate_contract(base, config):
        return 1, ["FAIL positive read-only contract was rejected"]
    rendered = render_contract(base, config)
    for marker in (
        "# 可编辑的本地 RV64 CPU RTL/验证提示草稿",
        "可编辑 prompt draft",
        "不要求逐字派发",
        "JSON 格式校验也不赋予权限或判定 RTL correctness",
        "RV64 RTL/证据对象：",
        "流水线配置：任务类型",
        "RV64 RTL 结论｜对象=<module/signal/本地证据路径>",
        "## 本地 RTL 输入、动作与产物",
        "不是平台权限白名单",
        "默认不修改源码",
        "## RV64 RTL 必读材料",
        "## RV64 微架构复核边界",
        "报告 `unknowns`",
        "允许给出 `inconclusive`",
        "不设置固定发现数量上限",
        "需要调整范围时补充 handoff 上下文",
        "其他 agent ownership 重叠",
        "## RV64 RTL 交付",
        "本地 RV64 RTL 交付：列出反例、证据位置和剩余风险",
        "## RV64 RTL 判定条件",
        "本地 RV64 RTL 判定：每条结论引用目标 RTL 或 spec 的可复核位置",
        "## 最终技术回复",
        "CPU 证据对象、具体 schema 字段、工作区相对路径、测试名和返回码",
        "不删除反例、未知项、替代假设、原始日志 marker 或真实文件名",
        "独立资源上的安全本地动作可以并行",
    ):
        if marker not in rendered:
            return 1, [f"FAIL rendered prompt missing marker: {marker}"]
    for forbidden in (
        "`rv64-hardware-professional`",
        "## 派发资格",
        "`create → validate → render`",
        "`candidate-only`",
        "SHA-256",
        "new-versioned-contract",
        "rendered-contract-only",
        "verbatim",
        "fork_turns",
        "父任务完整对话历史",
        "review_pending",
        "父目标保持 `active`",
        "language_policy",
        "dispatch_policy",
        "legacy_tool_semantics",
        "scope_defaults",
        "legacy_scope_flag_",
        "platform_interruption_effect",
        "subagent_context_mode",
    ):
        if forbidden in rendered:
            return 1, [f"FAIL rendered hardware prompt leaked coordinator-only wording: {forbidden}"]
    messages.append("PASS positive read-only contract and rendered boundary")

    hardware_vocabulary = copy.deepcopy(base)
    hardware_vocabulary["task_id"] = "self-test-hardware-vocabulary"
    hardware_vocabulary["goal"] = (
        "复核 `OooControlPlane` 的 RISC-V 特权级、PMP 权限检查、access fault 与 memory protection RTL 时序"
    )
    hardware_vocabulary["deliverables"] = [
        "核对 `kill_valid_i` 的 execute-stage 流水取消语义、store probe 事务、checkpoint recovery、load replay、testbench 接口异常激励和 compile-success RTL mutation 的 directed oracle"
    ]
    if validate_contract(hardware_vocabulary, config):
        return 1, ["FAIL legitimate CPU architecture vocabulary was rejected"]
    messages.append("PASS legitimate CPU architecture and RTL identifiers remain available")

    noc_vocabulary = copy.deepcopy(base)
    noc_vocabulary["task_id"] = "self-test-noc-vocabulary"
    noc_vocabulary["goal"] = (
        "复核本地 RV64 核的片上互连网络 NoC ready/valid 时序与 AXI 事务归属"
    )
    if validate_contract(noc_vocabulary, config):
        return 1, ["FAIL legitimate on-chip-network wording was rejected"]
    messages.append("PASS legitimate processor NoC terminology remains available")

    context_qualified_vocabulary = copy.deepcopy(base)
    context_qualified_vocabulary["task_id"] = "self-test-context-qualified-vocabulary"
    context_qualified_vocabulary["goal"] = (
        "复核本地 RV64 NoC 扫描链、`kill_valid_i` 流水取消和 PMP 权限判定的 RTL 周期合同"
    )
    if validate_contract(context_qualified_vocabulary, config):
        return 1, ["FAIL context-qualified hardware vocabulary was rejected"]
    messages.append("PASS context-qualified hardware vocabulary is not filtered lexically")

    legacy_language = copy.deepcopy(base)
    legacy_language["task_id"] = "self-test-legacy-language-policy"
    legacy_language["schema_version"] = LEGACY_CONTRACT_SCHEMA_VERSION
    legacy_language["language_policy"] = copy.deepcopy(LEGACY_LANGUAGE_POLICY)
    if validate_contract(legacy_language, config):
        return 1, ["FAIL historical language policy compatibility was rejected"]
    messages.append("PASS historical language policy remains validate-compatible")

    no_tools = copy.deepcopy(base)
    no_tools["task_id"] = "self-test-no-tools-review"
    no_tools["scope"]["allowed_commands"] = []
    no_tools["context"] = {
        "required_files": list(config["required_context"]),
        "material_mode": config["context_policy"]["no_tools_mode"],
        "supplied_material": [
            "冻结事实：valid_q 是 edge-old pending CSR owner；只复核 full ProducerId birth/death 反例。"
        ],
    }
    if validate_contract(no_tools, config):
        return 1, ["FAIL positive self-contained no-tools contract was rejected"]
    no_tools_rendered = render_contract(no_tools, config)
    for marker in (
        "`self-contained-no-tools`",
        "冻结材料 RTL 复核；不执行命令或仓库读取",
        "无（未提供建议命令）",
        "## 冻结 RTL 材料",
        "冻结事实：valid_q",
        "本节点不读取这些仓库文件",
        "结论只覆盖这些本地 RV64 RTL 材料",
    ):
        if marker not in no_tools_rendered:
            return 1, [f"FAIL no-tools rendered prompt missing marker: {marker}"]
    messages.append("PASS positive self-contained no-tools contract and rendered material")

    implementation = copy.deepcopy(base)
    implementation["task_id"] = "self-test-implementation"
    implementation["task_kind"] = "implementation"
    implementation["goal"] = "在声明模块内实现一个本地 RTL 接口不变量"
    implementation["context"]["required_files"].append(
        config["implementation_context"]
    )
    implementation["scope"]["allowed_paths"].append(
        config["implementation_context"]
    )
    implementation["scope"]["write_paths"] = [
        "npc/rv64/vsrc/writeback/OooRob.v"
    ]
    implementation["scope"]["allowed_commands"].append(
        {
            "command": "apply_patch",
            "mode": "write-within-scope",
            "purpose": "edit-declared-write-paths",
        }
    )
    if validate_contract(implementation, config):
        return 1, ["FAIL positive implementation contract was rejected"]
    implementation_rendered = render_contract(implementation, config)
    if "声明关注范围与写入 ownership" not in implementation_rendered:
        return 1, ["FAIL implementation render hid declared write ownership"]
    messages.append("PASS positive implementation contract preserves write ownership context")

    verification = copy.deepcopy(base)
    verification["task_id"] = "self-test-verification"
    verification["task_kind"] = "verification"
    verification["goal"] = "在隔离构建目录运行声明的本地 RTL 验证"
    verification_build = "npc/rv64/testbench/build-contract-self-test"
    verification["scope"]["allowed_paths"].append(verification_build)
    verification["scope"]["write_paths"] = [verification_build]
    verification["scope"]["allowed_commands"].append(
        {
            "command": "make",
            "mode": "write-within-scope",
            "purpose": "run-declared-build",
        }
    )
    if validate_contract(verification, config):
        return 1, ["FAIL positive verification contract was rejected"]
    messages.append("PASS positive verification contract preserves scoped execution capability")

    legacy_context = copy.deepcopy(base)
    legacy_context["task_id"] = "self-test-legacy-context"
    legacy_context["schema_version"] = LEGACY_CONTRACT_SCHEMA_VERSION
    legacy_context["scope"].update(
        {
            "legacy_scope_flag_1": False,
            "legacy_scope_flag_2": False,
            "legacy_scope_flag_3": False,
            "legacy_scope_flag_4": False,
        }
    )
    legacy_context["context"] = {
        "required_files": list(config["required_context"])
    }
    legacy_context["goal"] = "兼容读取历史只读合同，并最多报告三个 P0/P1 反例"
    if validate_contract(legacy_context, config):
        return 1, ["FAIL legacy context compatibility was rejected"]
    messages.append("PASS legacy context remains readable but is not a new-dispatch template")

    mutations: list[tuple[str, Any, str]] = []
    unexpected_scope_field = copy.deepcopy(base)
    unexpected_scope_field["scope"]["unbound_rtl_path_set"] = False
    mutations.append(
        (
            "unexpected-v2-scope-field",
            unexpected_scope_field,
            "scope fields must match the canonical v2 scope schema",
        )
    )
    legacy_nonfalse_flag = copy.deepcopy(legacy_context)
    legacy_nonfalse_flag["scope"]["legacy_scope_flag_1"] = True
    mutations.append(
        (
            "legacy-nonfalse-scope-flag",
            legacy_nonfalse_flag,
            "legacy scope extension flags must be false",
        )
    )
    readonly_write = copy.deepcopy(base)
    readonly_write["scope"]["write_paths"] = ["npc/rv64/vsrc/writeback/OooRob.v"]
    mutations.append(("read-only-write", readonly_write, "read-only-review must not declare write_paths"))
    traversal = copy.deepcopy(base)
    traversal["scope"]["allowed_paths"] = ["../outside.v"]
    mutations.append(("path-traversal", traversal, "must not contain empty, '.' or '..' components"))
    outside_write = copy.deepcopy(base)
    outside_write["task_kind"] = "implementation"
    outside_write["context"]["required_files"].append(config["implementation_context"])
    outside_write["scope"]["write_paths"] = ["npc/rv64/testbench/out.log"]
    mutations.append(("write-outside-allowlist", outside_write, "must be inside scope.allowed_paths"))
    parent_blocked = copy.deepcopy(base)
    parent_blocked["status_policy"]["parent_goal_state"] = "blocked"
    mutations.append(("parent-goal-propagation", parent_blocked, "status_policy must match"))
    no_deliverable = copy.deepcopy(base)
    no_deliverable["deliverables"] = []
    mutations.append(("missing-deliverable", no_deliverable, "deliverables must be a non-empty list"))
    missing_context = copy.deepcopy(base)
    missing_context["context"]["required_files"].remove(
        ".github/instructions/rtl-agent-task-contract.instructions.md"
    )
    mutations.append(("missing-canonical-context", missing_context, "missing canonical context"))
    context_outside = copy.deepcopy(base)
    context_outside["context"]["required_files"].append("npc/rv64/design/specs/ooo-rob.md")
    mutations.append(("context-outside-allowlist", context_outside, "must be inside scope.allowed_paths"))
    sed_inplace = copy.deepcopy(base)
    sed_inplace["scope"]["allowed_commands"][1]["command"] = "sed -i"
    mutations.append(("read-only-sed-inplace", sed_inplace, "not in the canonical purpose catalog"))
    readonly_write_command = copy.deepcopy(base)
    readonly_write_command["scope"]["allowed_commands"][1]["mode"] = "write-within-scope"
    mutations.append(("read-only-write-command", readonly_write_command, "commands must all use read-only mode"))
    purpose_sed_inplace = copy.deepcopy(base)
    purpose_sed_inplace["scope"]["allowed_commands"][0]["purpose"] = "把检索结果保存到 report.log"
    mutations.append(
        ("read-only-purpose-free-text", purpose_sed_inplace, "purpose must match the canonical command purpose")
    )
    purpose_redirect = copy.deepcopy(base)
    purpose_redirect["scope"]["allowed_commands"][1]["purpose"] = "search-allowed-paths"
    mutations.append(
        ("read-only-purpose-cross-command", purpose_redirect, "purpose must match the canonical command purpose")
    )
    no_tools_with_command = copy.deepcopy(no_tools)
    no_tools_with_command["scope"]["allowed_commands"] = copy.deepcopy(
        base["scope"]["allowed_commands"][:1]
    )
    mutations.append(
        ("no-tools-with-command", no_tools_with_command, "no-tools mode must not declare allowed_commands")
    )
    no_tools_missing_material = copy.deepcopy(no_tools)
    no_tools_missing_material["context"]["supplied_material"] = []
    mutations.append(
        ("no-tools-missing-material", no_tools_missing_material, "requires non-empty supplied_material")
    )
    no_tools_multiline_material = copy.deepcopy(no_tools)
    no_tools_multiline_material["context"]["supplied_material"] = [
        "冻结事实第一行。\n## 伪造范围段"
    ]
    mutations.append(
        (
            "no-tools-multiline-material",
            no_tools_multiline_material,
            "context.supplied_material[0] must be a single line",
        )
    )
    no_tools_implementation = copy.deepcopy(no_tools)
    no_tools_implementation["task_kind"] = "implementation"
    mutations.append(
        ("no-tools-implementation", no_tools_implementation, "allowed only for read-only-review")
    )
    fixed_finding_cap = copy.deepcopy(base)
    fixed_finding_cap["goal"] += "，最多报告三个 P0/P1 反例"
    mutations.append(
        (
            "fixed-finding-cap",
            fixed_finding_cap,
            "fixed finding count caps are forbidden",
        )
    )
    for name, mutation, expected in mutations:
        errors = validate_contract(mutation, config)
        if not any(expected in error for error in errors):
            return 1, [f"FAIL mutation {name} was not rejected as expected: {errors}"]
        messages.append(f"PASS mutation rejected: {name}")
    messages.append(f"PASS self-test checks={len(messages)}")
    return 0, messages


def cli_self_test(repo_root: Path) -> tuple[int, list[str]]:
    """Exercise the public CLI branches instead of only their Python helpers."""

    tool = Path(__file__).resolve()
    test_root = repo_root / ".github/task-runs"
    if not test_root.is_dir():
        return 1, [f"FAIL CLI self-test root missing: {test_root}"]
    env = os.environ.copy()
    env["PYTHONDONTWRITEBYTECODE"] = "1"

    def invoke(
        arguments: list[str], *, repo_override: Path | None = None
    ) -> subprocess.CompletedProcess[str]:
        root_argument = repo_override if repo_override is not None else repo_root
        return subprocess.run(
            [sys.executable, str(tool), "--repo-root", str(root_argument), *arguments],
            cwd=repo_root,
            env=env,
            check=False,
            capture_output=True,
            text=True,
        )

    def failed(name: str, result: subprocess.CompletedProcess[str]) -> tuple[int, list[str]]:
        detail = (result.stdout + result.stderr).strip()
        return 1, [f"FAIL CLI {name} rc={result.returncode}: {detail}"]

    messages: list[str] = []
    with tempfile.TemporaryDirectory(prefix=".rtl-task-contract-cli-", dir=test_root) as temporary:
        temp_dir = Path(temporary)
        contract = temp_dir / "positive.json"
        relative_contract = contract.relative_to(repo_root).as_posix()
        create = invoke(
            [
                "create",
                "--task-id",
                "cli-self-test-review",
                "--task-kind",
                "read-only-review",
                "--goal",
                "只读核对本地 RTL 合同 CLI",
                "--allow-path",
                "npc/rv64/vsrc/writeback/OooRob.v",
                "--allow-read-command",
                "rg",
                "--deliverable",
                "返回带路径的只读结论",
                "--success-criterion",
                "仅在声明路径内读取 RTL/spec 且不落盘",
                "--out",
                relative_contract,
            ]
        )
        if create.returncode != 0 or not contract.is_file():
            return failed("create positive", create)
        positive = load_json(contract)
        if (
            positive.get("schema_version") != CURRENT_CONTRACT_SCHEMA_VERSION
            or set(positive.get("scope", {})) != CANONICAL_SCOPE_FIELDS
        ):
            return failed("create canonical v2 scope", create)
        if relative_contract in positive["scope"]["allowed_paths"]:
            return failed("create leaked JSON path into engineering focus", create)
        if "sha" in create.stdout.lower():
            return failed("create displayed an automatic hash", create)
        messages.append("PASS CLI create positive")
        messages.append("PASS CLI create emitted canonical v2 path/command scope")
        messages.append("PASS CLI create kept JSON identity out of engineering focus")
        messages.append("PASS CLI create did not compute or display a hash")

        validate = invoke(["validate", relative_contract])
        if (
            validate.returncode != 0
            or "PASS contract=" not in validate.stdout
            or "format=valid" not in validate.stdout
            or "sha" in validate.stdout.lower()
        ):
            return failed("validate positive", validate)
        messages.append("PASS CLI validate reported format only and no hash")

        render = invoke(["render", relative_contract])
        if (
            render.returncode != 0
            or "command=rg; mode=read-only" not in render.stdout
            or "默认不修改源码" not in render.stdout
            or "# 可编辑的本地 RV64 CPU RTL/验证提示草稿" not in render.stdout
            or "可编辑 prompt draft" not in render.stdout
            or "不要求逐字派发" not in render.stdout
            or "JSON 格式校验也不赋予权限或判定 RTL correctness" not in render.stdout
            or "RV64 RTL/证据对象：" not in render.stdout
            or "RV64 RTL 结论｜对象=<module/signal/本地证据路径>" not in render.stdout
            or "不是平台权限白名单" not in render.stdout
            or "允许给出 `inconclusive`" not in render.stdout
            or "需要调整范围时补充 handoff 上下文" not in render.stdout
            or "其他 agent ownership 重叠" not in render.stdout
            or "## RV64 RTL 交付" not in render.stdout
            or "## RV64 RTL 判定条件" not in render.stdout
            or "## 最终技术回复" not in render.stdout
            or "CPU 证据对象、具体 schema 字段、工作区相对路径、测试名和返回码" not in render.stdout
            or "独立资源上的安全本地动作可以并行" not in render.stdout
        ):
            return failed("render positive", render)
        if any(
            forbidden in render.stdout
            for forbidden in (
                "`rv64-hardware-professional`",
                "## 派发资格",
                "`create → validate → render`",
                "`candidate-only`",
                "SHA-256",
                "new-versioned-contract",
                "rendered-contract-only",
                "verbatim",
                "fork_turns",
                "父任务完整对话历史",
                "review_pending",
                "language_policy",
                "dispatch_policy",
                "legacy_tool_semantics",
                "scope_defaults",
                "legacy_scope_flag_",
                "platform_interruption_effect",
                "subagent_context_mode",
            )
        ):
            return failed("render leaked coordinator-only wording", render)
        messages.append("PASS CLI render emitted an editable, non-hashed prompt draft")

        no_tools_contract = temp_dir / "self-contained-no-tools.json"
        no_tools_relative = no_tools_contract.relative_to(repo_root).as_posix()
        no_tools_create = invoke(
            [
                "create",
                "--task-id",
                "cli-self-test-no-tools-review",
                "--task-kind",
                "read-only-review",
                "--goal",
                "只根据冻结材料复核本地 RTL ProducerId 生命周期",
                "--allow-path",
                "npc/rv64/vsrc/writeback/OooRob.v",
                "--self-contained-no-tools",
                "--supplied-material",
                "冻结材料：birth 只在真实 ROB enqueue 沿锁存 full ProducerId。",
                "--deliverable",
                "只返回结构化反例",
                "--success-criterion",
                "仅使用合同内随附材料",
                "--out",
                no_tools_relative,
            ]
        )
        if no_tools_create.returncode != 0 or not no_tools_contract.is_file():
            return failed("create self-contained no-tools", no_tools_create)
        no_tools_data = load_json(no_tools_contract)
        if (
            no_tools_data["scope"]["allowed_commands"] != []
            or no_tools_data["context"]["material_mode"]
            != "prompt-supplied-self-contained"
        ):
            return failed("create self-contained no-tools shape", no_tools_create)
        no_tools_validate = invoke(["validate", no_tools_relative])
        if no_tools_validate.returncode != 0:
            return failed("validate self-contained no-tools", no_tools_validate)
        no_tools_render = invoke(["render", no_tools_relative])
        if (
            no_tools_render.returncode != 0
            or "`self-contained-no-tools`" not in no_tools_render.stdout
            or "无（未提供建议命令）" not in no_tools_render.stdout
            or "冻结材料：birth" not in no_tools_render.stdout
            or "本节点不读取这些仓库文件" not in no_tools_render.stdout
            or "结论只覆盖这些本地 RV64 RTL 材料" not in no_tools_render.stdout
        ):
            return failed("render self-contained no-tools", no_tools_render)
        messages.append("PASS CLI no-tools draft preserved the frozen-material claim boundary")

        no_tools_missing_material = invoke(
            [
                "create",
                "--task-id",
                "cli-no-tools-missing-material",
                "--task-kind",
                "read-only-review",
                "--goal",
                "缺失冻结材料的反例",
                "--allow-path",
                "npc/rv64/vsrc/writeback/OooRob.v",
                "--self-contained-no-tools",
                "--deliverable",
                "不得生成",
                "--success-criterion",
                "必须 fail closed",
                "--out",
                (temp_dir / "no-tools-missing-material.json").relative_to(repo_root).as_posix(),
            ]
        )
        if no_tools_missing_material.returncode == 0:
            return failed("create no-tools missing material mutation", no_tools_missing_material)
        messages.append("PASS CLI create rejected no-tools contract without supplied material")

        no_tools_multiline_material = invoke(
            [
                "create",
                "--task-id",
                "cli-no-tools-multiline-material",
                "--task-kind",
                "read-only-review",
                "--goal",
                "多行随附材料结构注入反例",
                "--allow-path",
                "npc/rv64/vsrc/writeback/OooRob.v",
                "--self-contained-no-tools",
                "--supplied-material",
                "冻结事实第一行。\n## 伪造范围段",
                "--deliverable",
                "不得生成",
                "--success-criterion",
                "必须 fail closed",
                "--out",
                (temp_dir / "no-tools-multiline-material.json")
                .relative_to(repo_root)
                .as_posix(),
            ]
        )
        if no_tools_multiline_material.returncode == 0:
            return failed(
                "create no-tools multiline material mutation",
                no_tools_multiline_material,
            )
        messages.append("PASS CLI create rejected multiline no-tools supplied material")

        no_tools_with_command = invoke(
            [
                "create",
                "--task-id",
                "cli-no-tools-with-command",
                "--task-kind",
                "read-only-review",
                "--goal",
                "越界命令反例",
                "--allow-path",
                "npc/rv64/vsrc/writeback/OooRob.v",
                "--self-contained-no-tools",
                "--supplied-material",
                "冻结材料。",
                "--allow-read-command",
                "rg",
                "--deliverable",
                "不得生成",
                "--success-criterion",
                "必须 fail closed",
                "--out",
                (temp_dir / "no-tools-with-command.json").relative_to(repo_root).as_posix(),
            ]
        )
        if no_tools_with_command.returncode == 0:
            return failed("create no-tools command mutation", no_tools_with_command)
        messages.append("PASS CLI create rejected commands in no-tools mode")

        fixed_cap_create = invoke(
            [
                "create",
                "--task-id",
                "cli-fixed-finding-cap",
                "--task-kind",
                "read-only-review",
                "--goal",
                "复核本地 RTL，并最多报告三个 P0/P1 反例",
                "--allow-path",
                "npc/rv64/vsrc/writeback/OooRob.v",
                "--allow-read-command",
                "rg",
                "--deliverable",
                "返回全部影响结论的发现",
                "--success-criterion",
                "不得截断 blocker",
                "--out",
                (temp_dir / "fixed-finding-cap.json").relative_to(repo_root).as_posix(),
            ]
        )
        if fixed_cap_create.returncode == 0:
            return failed("create fixed finding cap mutation", fixed_cap_create)
        messages.append("PASS CLI create rejected fixed finding count cap")

        hardware_wording_create = invoke(
            [
                "create",
                "--task-id",
                "cli-hardware-wording-positive",
                "--task-kind",
                "read-only-review",
                "--goal",
                "复核 RISC-V 特权级、PMP 权限检查和 access fault 的 RTL 时序",
                "--allow-path",
                "npc/rv64/vsrc/writeback/OooRob.v",
                "--deliverable",
                "核对 `kill_valid_i` 的流水取消语义和 store probe 事务",
                "--success-criterion",
                "结论引用 RTL 或 spec 的可复核位置",
                "--out",
                (temp_dir / "hardware-wording-positive.json").relative_to(repo_root).as_posix(),
            ]
        )
        if hardware_wording_create.returncode != 0:
            return failed("create legitimate hardware wording", hardware_wording_create)
        messages.append(
            "PASS CLI create preserved RTL vocabulary without requiring command suggestions"
        )

        legacy = copy.deepcopy(positive)
        legacy["schema_version"] = LEGACY_CONTRACT_SCHEMA_VERSION
        legacy["scope"].update(
            {
                "legacy_scope_flag_1": False,
                "legacy_scope_flag_2": False,
                "legacy_scope_flag_3": False,
                "legacy_scope_flag_4": False,
            }
        )
        legacy_contract = temp_dir / "legacy-no-self-path.json"
        atomic_write_json(legacy_contract, legacy)
        legacy_relative = legacy_contract.relative_to(repo_root).as_posix()
        # Render is independently usable; a separate create/validate pre-step is not required.
        legacy_render = invoke(["render", legacy_relative])
        if (
            legacy_render.returncode != 0
            or "可编辑 prompt draft" not in legacy_render.stdout
            or "SHA-256" in legacy_render.stdout
        ):
            return failed("render legacy contract directly", legacy_render)
        legacy_validate = invoke(["validate", legacy_relative])
        if legacy_validate.returncode != 0:
            return failed("validate legacy contract", legacy_validate)
        messages.append("PASS CLI validate kept legacy JSON compatibility")
        messages.append("PASS CLI render worked independently without automatic hash identity")

        unexpected_scope_field = copy.deepcopy(positive)
        unexpected_scope_field["scope"]["unbound_rtl_path_set"] = False
        unexpected_scope_contract = temp_dir / "unexpected-v2-scope-field.json"
        atomic_write_json(unexpected_scope_contract, unexpected_scope_field)
        unexpected_scope_result = invoke(
            ["validate", unexpected_scope_contract.relative_to(repo_root).as_posix()]
        )
        if (
            unexpected_scope_result.returncode == 0
            or "FAIL format:" not in unexpected_scope_result.stderr
            or "candidate-only" in unexpected_scope_result.stderr
            or "result status" in unexpected_scope_result.stderr
        ):
            return failed(
                "validate unexpected v2 scope field mutation",
                unexpected_scope_result,
            )
        messages.append("PASS CLI validation failure reported a format error only")

        sed_inplace = copy.deepcopy(positive)
        sed_inplace["scope"]["allowed_commands"][0]["command"] = "sed -i"
        sed_contract = temp_dir / "sed-inplace.json"
        atomic_write_json(sed_contract, sed_inplace)
        sed_result = invoke(["validate", sed_contract.relative_to(repo_root).as_posix()])
        if sed_result.returncode == 0:
            return failed("validate sed-inplace mutation", sed_result)
        messages.append("PASS CLI validate rejected read-only write-command mutation")

        purpose_sed = copy.deepcopy(positive)
        purpose_sed["scope"]["allowed_commands"][0]["purpose"] = "把检索结果保存到 report.log"
        purpose_sed_contract = temp_dir / "purpose-free-text.json"
        atomic_write_json(purpose_sed_contract, purpose_sed)
        purpose_sed_result = invoke(
            ["validate", purpose_sed_contract.relative_to(repo_root).as_posix()]
        )
        if purpose_sed_result.returncode == 0:
            return failed("validate free-text purpose mutation", purpose_sed_result)
        messages.append("PASS CLI validate rejected free-text purpose mutation")

        purpose_redirect = copy.deepcopy(positive)
        purpose_redirect["scope"]["allowed_commands"][0]["purpose"] = "view-selected-lines"
        purpose_redirect_contract = temp_dir / "purpose-cross-command.json"
        atomic_write_json(purpose_redirect_contract, purpose_redirect)
        purpose_redirect_result = invoke(
            ["validate", purpose_redirect_contract.relative_to(repo_root).as_posix()]
        )
        if purpose_redirect_result.returncode == 0:
            return failed("validate cross-command purpose mutation", purpose_redirect_result)
        messages.append("PASS CLI validate rejected cross-command purpose mutation")

        with tempfile.TemporaryDirectory(prefix="rtl-task-contract-outside-") as outside:
            outside_contract = Path(outside) / "outside.json"
            atomic_write_json(outside_contract, positive)
            outside_result = invoke(["validate", str(outside_contract)])
            if outside_result.returncode == 0 or "inside the repository" not in outside_result.stderr:
                return failed("validate outside-repository input", outside_result)
            outside_root = Path(outside)
            for command in ("validate", "render"):
                rebound = invoke(
                    [command, str(outside_contract)], repo_override=outside_root
                )
                if rebound.returncode == 0 or "must equal the script workspace root" not in rebound.stderr:
                    return failed(f"{command} rebound repository root", rebound)
        messages.append("PASS CLI validate rejected outside-repository input")
        messages.append("PASS CLI validate rejected rebound repository root")
        messages.append("PASS CLI render rejected rebound repository root")

    messages.append(f"PASS CLI self-test checks={len(messages)}")
    return 0, messages


def create_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        default=None,
        help="optional explicit root; its realpath must equal the script workspace root",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    create = subparsers.add_parser(
        "create", help="create an optional legacy JSON handoff"
    )
    create.add_argument("--task-id", required=True)
    create.add_argument(
        "--task-kind",
        required=True,
        choices=["read-only-review", "implementation", "verification", "ppa-analysis"],
    )
    create.add_argument("--goal", required=True)
    create.add_argument("--allow-path", action="append", required=True)
    create.add_argument("--write-path", action="append")
    create.add_argument(
        "--allow-read-command",
        action="append",
        metavar="COMMAND",
        help="suggest a read-only command; purpose is filled from the canonical catalog",
    )
    create.add_argument(
        "--allow-write-command",
        action="append",
        metavar="COMMAND",
        help="suggest a write command; purpose is filled from the canonical catalog",
    )
    create.add_argument(
        "--self-contained-no-tools",
        action="store_true",
        help="exceptional bounded-evidence review consumes only supplied material and declares no tools, shell or file access",
    )
    create.add_argument(
        "--supplied-material",
        action="append",
        help="self-contained engineering fact or excerpt embedded into the rendered prompt",
    )
    create.add_argument("--required-context", action="append")
    create.add_argument("--deliverable", action="append", required=True)
    create.add_argument("--success-criterion", action="append", required=True)
    create.add_argument("--out", required=True)

    validate = subparsers.add_parser(
        "validate", help="validate legacy JSON structure only"
    )
    validate.add_argument("contract")
    render = subparsers.add_parser(
        "render", help="validate structure and render an editable prompt draft"
    )
    render.add_argument("contract")
    subparsers.add_parser("audit", help="audit canonical config and repository wiring")
    subparsers.add_parser("self-test", help="run positive and mutation-negative contract tests")
    subparsers.add_parser(
        "cli-self-test", help="exercise observable legacy handoff CLI semantics"
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = create_parser()
    args = parser.parse_args(argv)
    repo_root = repo_root_from_script()
    if args.repo_root is not None:
        requested_root = Path(args.repo_root).resolve()
        if requested_root != repo_root:
            print("FAIL --repo-root must equal the script workspace root", file=sys.stderr)
            return 1
    try:
        config = load_config(repo_root)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"FAIL cannot load {SOURCE_CONTRACT}: {exc}", file=sys.stderr)
        return 2
    config_errors = validate_config(config, repo_root)
    if config_errors:
        for error in config_errors:
            print(f"FAIL {error}", file=sys.stderr)
        return 2

    if args.command == "create":
        try:
            output = resolve_inside_repo(repo_root, args.out, "--out")
        except ValueError as exc:
            print(f"FAIL {exc}", file=sys.stderr)
            return 1
        output_relative = output.relative_to(repo_root).as_posix()
        data = build_contract(args, config)
        errors = validate_contract(data, config)
        if errors:
            for error in errors:
                print(f"FAIL format: {error}", file=sys.stderr)
            return 1
        atomic_write_json(output, data)
        print(f"PASS created={output_relative}")
        return 0

    if args.command in {"validate", "render"}:
        try:
            contract_path = resolve_inside_repo(repo_root, args.contract, "contract input")
        except ValueError as exc:
            print(f"FAIL {exc}", file=sys.stderr)
            return 1
        try:
            data = load_json(contract_path)
        except (OSError, ValueError, json.JSONDecodeError) as exc:
            print(f"FAIL format: cannot load contract: {exc}", file=sys.stderr)
            return 2
        errors = validate_contract(data, config)
        if errors:
            for error in errors:
                print(f"FAIL format: {error}", file=sys.stderr)
            return 1
        if args.command == "validate":
            print(f"PASS contract={contract_path.relative_to(repo_root).as_posix()} format=valid")
        else:
            print(render_contract(data, config), end="")
        return 0

    if args.command == "audit":
        errors = audit_wiring(repo_root, config)
        if errors:
            for error in errors:
                print(f"FAIL {error}", file=sys.stderr)
            return 1
        print("PASS RTL task contract config, policy, discovery, profile and packaging wiring")
        return 0

    if args.command == "self-test":
        rc, messages = self_test(config)
        for message in messages:
            print(message)
        return rc
    if args.command == "cli-self-test":
        rc, messages = cli_self_test(repo_root)
        for message in messages:
            print(message)
        return rc
    parser.error(f"unknown command: {args.command}")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
