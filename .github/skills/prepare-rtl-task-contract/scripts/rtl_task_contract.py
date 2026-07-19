#!/usr/bin/env python3
"""生成、校验并渲染本地 RV64 RTL 子任务契约。"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys
import tempfile
from typing import Any, Iterable


SOURCE_CONTRACT = ".github/ai-env/contracts/agent-env-rtl-task-contract.json"
TASK_ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]{1,127}$")
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
) -> list[dict[str, str]]:
    if not isinstance(value, list) or not value:
        errors.append(f"{field} must be a non-empty list")
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
    if config.get("schema_version") != 1:
        errors.append("config schema_version must be 1")
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

    defaults = config.get("access_defaults")
    if not isinstance(defaults, dict):
        errors.append("config access_defaults must be an object")
    else:
        if defaults.get("workspace_root") != ".":
            errors.append("config access_defaults.workspace_root must be '.'")
        for key in ("network", "accounts", "credentials", "external_services"):
            if defaults.get(key) is not False:
                errors.append(f"config access_defaults.{key} must be false")

    status = config.get("status_policy")
    if not isinstance(status, dict):
        errors.append("config status_policy must be an object")
    else:
        expected_status = {
            "review_state": "review_pending",
            "parent_goal_state": "active",
            "isolate_review_to_subtask": True,
            "preserve_original_request": True,
            "semantic_distortion_retry_forbidden": True,
            "official_feedback_recommended": True,
        }
        if status != expected_status:
            errors.append("config status_policy does not match the fail-contained review policy")

    language = config.get("language_policy")
    expected_language = {
        "preserve_rtl_identifiers": True,
        "domain_accurate_wording": True,
        "platform_check_bypass_is_not_an_objective": True,
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

    if data.get("schema_version") != 1:
        errors.append("schema_version must be 1")
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

    scope = data.get("scope")
    allowed_paths: list[str] = []
    write_paths: list[str] = []
    allowed_commands: list[dict[str, str]] = []
    if not isinstance(scope, dict):
        errors.append("scope must be an object")
    else:
        expected_scope_fields = {
            "workspace_root",
            "allowed_paths",
            "write_paths",
            "allowed_commands",
            "network",
            "accounts",
            "credentials",
            "external_services",
        }
        if set(scope) != expected_scope_fields:
            errors.append("scope fields must match the canonical scope schema")
        allowed_paths = string_list(scope.get("allowed_paths"), "scope.allowed_paths", errors)
        write_paths = string_list(
            scope.get("write_paths"), "scope.write_paths", errors, allow_empty=True
        )
        allowed_commands = command_list(
            scope.get("allowed_commands"), "scope.allowed_commands", errors, config
        )
        if scope.get("workspace_root") != ".":
            errors.append("scope.workspace_root must be '.'")
        for key in ("network", "accounts", "credentials", "external_services"):
            if scope.get(key) is not False:
                errors.append(f"scope.{key} must be false")

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
    if not isinstance(context, dict):
        errors.append("context must be an object")
    else:
        if set(context) != {"required_files"}:
            errors.append("context fields must contain only required_files")
        required_context = string_list(context.get("required_files"), "context.required_files", errors)
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

    string_list(data.get("deliverables"), "deliverables", errors)
    string_list(data.get("success_criteria"), "success_criteria", errors)
    if data.get("status_policy") != config.get("status_policy"):
        errors.append("status_policy must match the canonical fail-contained review policy")
    if data.get("language_policy") != config.get("language_policy"):
        errors.append("language_policy must match the canonical wording policy")
    if data.get("source_contract") != SOURCE_CONTRACT:
        errors.append(f"source_contract must be {SOURCE_CONTRACT}")
    return errors


def build_contract(args: argparse.Namespace, config: dict[str, Any]) -> dict[str, Any]:
    required_context = unique([*config["required_context"], *(args.required_context or [])])
    if args.task_kind == "implementation":
        required_context = unique([*required_context, config["implementation_context"]])
    allowed_paths = unique([*args.allow_path, *required_context])
    defaults = config["access_defaults"]
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
        "schema_version": 1,
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
            "network": defaults["network"],
            "accounts": defaults["accounts"],
            "credentials": defaults["credentials"],
            "external_services": defaults["external_services"],
        },
        "context": {"required_files": required_context},
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


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def bullet_lines(items: list[str]) -> str:
    return "\n".join(f"- {item}" for item in items)


def command_permission_lines(items: list[dict[str, str]]) -> str:
    return "\n".join(
        f"- command={item['command']}; mode={item['mode']}"
        for item in items
    )


def command_purpose_lines(items: list[dict[str, str]], config: dict[str, Any]) -> str:
    catalog = config["command_policy"]["purpose_catalog"]
    return "\n".join(
        f"- {item['command']}: purpose={item['purpose']}; label={catalog[item['command']]['label_zh']}"
        for item in items
    )


def render_contract(data: dict[str, Any], config: dict[str, Any]) -> str:
    scope = data["scope"]
    context = data["context"]
    writes = scope["write_paths"] or ["无（只读）"]
    return f"""# 本地 RTL 子任务契约 `{data['task_id']}`

- 工程领域：本地 RV64 Verilog/SystemVerilog 数字电路设计、验证或 PPA
- 任务类型：`{data['task_kind']}`
- 目标：{data['goal']}

## 路径与权限

允许读取/处理：
{bullet_lines(scope['allowed_paths'])}

允许写入：
{bullet_lines(writes)}

允许命令：
{command_permission_lines(scope['allowed_commands'])}

Canonical 审计用途（固定枚举，不接受任务自定义文本，不授予参数、选项或额外能力）：
{command_purpose_lines(scope['allowed_commands'], config)}

`read-only` 只授权无落盘副作用的调用；禁止 `sed -i`、重定向和其它写型选项。

外部访问边界：不联网，不访问账号、凭据或外部服务；不处理工作区外路径。

## 最小上下文

{bullet_lines(context['required_files'])}

## 交付物

{bullet_lines(data['deliverables'])}

## 成功条件

{bullet_lines(data['success_criteria'])}

## 协作约束

- 保留真实 RTL 标识符和信号语义；正文使用流水取消、分支恢复、完成资格、生产者归属、事务标签、定向变异和独立反例复核等准确硬件语义。
- 不得扩大路径、写权限、命令或外部访问范围；需要扩展时先返回主 agent 生成新版契约。
- 平台暂不处理本任务时，仅把当前子任务记为 `review_pending`，保留原始请求与契约证据，父目标保持 `active`；不得通过改变 RTL 语义来重试。
"""


def audit_wiring(repo_root: Path, config: dict[str, Any]) -> list[str]:
    errors = validate_config(config, repo_root)
    checks = {
        ".github/AGENTS.md": "rtl-agent-task-contract.instructions.md",
        "AI_ENVIRONMENT.md": "prepare-rtl-task-contract",
        ".github/agents/ysyx-coordinator.agent.md": "prepare-rtl-task-contract",
        ".github/agents/npc.agent.md": "rtl-agent-task-contract.instructions.md",
        ".github/e2e/profiles/agent-system.tsv": "rtl-task-contract|agent-system|e2e_agent_system_rtl_task_contract|agent-system|",
        "scripts/e2e/modules/agent_system.sh": "e2e_agent_system_rtl_task_contract()",
        "scripts/agent-maintain.sh": "RTL task contract CLI self-test",
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
        else:
            expected = {
                "contract": SOURCE_CONTRACT,
                "instruction": config.get("instruction"),
                "skill": config.get("skill"),
                "generator": config.get("generator"),
                "profile_node": config.get("profile_node"),
                "local_rtl_external_access_forbidden": True,
                "contract_before_dispatch_required": True,
            }
            if delegation != expected:
                errors.append("policy task_delegation does not match the canonical RTL task contract")
    return errors


def self_test(config: dict[str, Any]) -> tuple[int, list[str]]:
    base = {
        "schema_version": 1,
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
            "network": False,
            "accounts": False,
            "credentials": False,
            "external_services": False,
        },
        "context": {"required_files": list(config["required_context"])},
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
    for marker in ("本地 RV64 Verilog/SystemVerilog", "不联网", "review_pending", "父目标保持 `active`"):
        if marker not in rendered:
            return 1, [f"FAIL rendered prompt missing marker: {marker}"]
    messages.append("PASS positive read-only contract and rendered boundary")

    mutations: list[tuple[str, Any, str]] = []
    network = copy.deepcopy(base)
    network["scope"]["network"] = True
    mutations.append(("network-enabled", network, "scope.network must be false"))
    credentials = copy.deepcopy(base)
    credentials["scope"]["credentials"] = True
    mutations.append(("credentials-enabled", credentials, "scope.credentials must be false"))
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

    for name, mutation, expected in mutations:
        errors = validate_contract(mutation, config)
        if not any(expected in error for error in errors):
            return 1, [f"FAIL mutation {name} was not rejected as expected: {errors}"]
        messages.append(f"PASS mutation rejected: {name}")
    messages.append(f"PASS self-test cases={1 + len(mutations)}")
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
                "不写文件且不访问外部服务",
                "--out",
                relative_contract,
            ]
        )
        if create.returncode != 0 or not contract.is_file():
            return failed("create positive", create)
        messages.append("PASS CLI create positive")

        validate = invoke(["validate", relative_contract])
        if validate.returncode != 0 or "PASS contract=" not in validate.stdout:
            return failed("validate positive", validate)
        messages.append("PASS CLI validate positive")

        render = invoke(["render", relative_contract])
        if render.returncode != 0 or "command=rg; mode=read-only" not in render.stdout:
            return failed("render positive", render)
        messages.append("PASS CLI render positive")

        positive = load_json(contract)
        network = copy.deepcopy(positive)
        network["scope"]["network"] = True
        network_contract = temp_dir / "network-enabled.json"
        atomic_write_json(network_contract, network)
        network_result = invoke(["validate", network_contract.relative_to(repo_root).as_posix()])
        if network_result.returncode == 0:
            return failed("validate network mutation", network_result)
        messages.append("PASS CLI validate rejected network mutation")

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

    messages.append("PASS CLI self-test cases=10")
    return 0, messages


def create_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        default=None,
        help="optional explicit root; its realpath must equal the script workspace root",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    create = subparsers.add_parser("create", help="create an atomic JSON task contract")
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
        help="declare an approved read-only command; purpose is filled from the canonical catalog",
    )
    create.add_argument(
        "--allow-write-command",
        action="append",
        metavar="COMMAND",
        help="declare an approved write-within-scope command; purpose is canonical",
    )
    create.add_argument("--required-context", action="append")
    create.add_argument("--deliverable", action="append", required=True)
    create.add_argument("--success-criterion", action="append", required=True)
    create.add_argument("--out", required=True)

    validate = subparsers.add_parser("validate", help="validate a JSON task contract")
    validate.add_argument("contract")
    render = subparsers.add_parser("render", help="validate and render a subagent prompt")
    render.add_argument("contract")
    subparsers.add_parser("audit", help="audit canonical config and repository wiring")
    subparsers.add_parser("self-test", help="run positive and mutation-negative contract tests")
    subparsers.add_parser("cli-self-test", help="exercise create, validate and render as subprocesses")
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
        data = build_contract(args, config)
        errors = validate_contract(data, config)
        if errors:
            for error in errors:
                print(f"FAIL {error}", file=sys.stderr)
            return 1
        try:
            output = resolve_inside_repo(repo_root, args.out, "--out")
        except ValueError as exc:
            print(f"FAIL {exc}", file=sys.stderr)
            return 1
        atomic_write_json(output, data)
        print(f"PASS created={output.relative_to(repo_root).as_posix()} sha256={sha256_file(output)}")
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
            print(f"FAIL cannot load contract: {exc}", file=sys.stderr)
            return 2
        errors = validate_contract(data, config)
        if errors:
            for error in errors:
                print(f"FAIL {error}", file=sys.stderr)
            return 1
        if args.command == "validate":
            print(
                f"PASS contract={contract_path.relative_to(repo_root).as_posix()} "
                f"sha256={sha256_file(contract_path)}"
            )
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
