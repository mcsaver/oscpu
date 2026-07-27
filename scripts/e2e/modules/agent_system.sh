#!/usr/bin/env bash

e2e_agent_system_discovery() {
  echo "[agent-system] discovery files"
  local rc=0
  e2e_print_required_files \
    AGENTS.md \
    AI_ENVIRONMENT.md \
    .github/AGENTS.md \
    .github/copilot-instructions.md \
    .github/ai-env/README.md \
    .github/ai-env/contracts/agent-env-policy.json \
    .github/ai-env/contracts/agent-env-rebuild-matrix.json \
    .github/ai-env/contracts/agent-env-schema-contract.json \
    .github/ai-env/contracts/agent-env-observability.json \
    .github/ai-env/contracts/agent-env-state-traceability.json \
    .github/ai-env/contracts/agent-env-runtime-artifacts.json \
    .github/ai-env/contracts/agent-env-review-routing.json \
    .github/ai-env/contracts/agent-env-branch-health.json \
    .github/ai-env/contracts/agent-env-delivery.json \
    .github/agentic-hardware-blueprint.md \
    .github/instructions/agent-env-layer-contract.instructions.md \
    .github/instructions/agent-env-state-machine.instructions.md \
    .github/instructions/memory-protocol.instructions.md \
    .github/instructions/agent-e2e-workflow.instructions.md \
    .github/instructions/rtl-agent-task-contract.instructions.md \
    .github/ai-env/contracts/agent-env-rtl-task-contract.json \
    .github/skills/agent-env-maintenance/SKILL.md \
    .github/skills/prepare-rtl-task-contract/SKILL.md \
    .github/skills/prepare-rtl-task-contract/agents/openai.yaml \
    .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py \
    .github/agents/AGENT_INDEX.md \
    .github/workflows/agent-maintain.yml \
    .github/e2e/README.md \
    .github/e2e/profiles/discovery.tsv \
    .github/e2e/profiles/nemu-dev.tsv \
    .github/e2e/profiles/nemu-dev-gate.tsv \
    .github/e2e/profiles/nemu-dev-full-gate.tsv \
    .github/e2e/profiles/nemu-dev-full-soak.tsv \
    .github/e2e/profiles/npc-dev.tsv \
    .github/e2e/profiles/nemu-ubuntu-focused.tsv \
    .github/e2e/profiles/nemu-ubuntu-gate.tsv \
    .github/e2e/profiles/nemu-ubuntu-full-gate.tsv \
    .github/e2e/profiles/nemu-ubuntu-full-soak.tsv \
    .github/e2e/modules/agent-system.md \
    .github/e2e/modules/toolchain.md \
    .github/memory/project-status.md \
    .github/memory/known-issues.md \
    .github/memory/modules/agent-system.md \
    .github/task-runs/templates/task-report.template.md \
    .github/task-runs/templates/dispatch-log.template.md \
    deliverables/ai-dev-env-commercial-v1/README.md \
    deliverables/ai-dev-env-commercial-v1/PACKAGING_MANIFEST.md \
    deliverables/ai-dev-env-commercial-v1/COMMERCIAL_READINESS.md \
    scripts/package-ai-dev-env.sh \
    scripts/README.md \
    scripts/agent-env.sh \
    scripts/agent-run.sh \
    scripts/agent-maintain.sh \
    scripts/agent-e2e.sh \
    scripts/task-run-status.sh \
    scripts/tests/test-task-run-status.sh \
    scripts/e2e/lib/common.sh \
    scripts/e2e/lib/report.sh || rc=1

  echo "[agent-system] non-interactive soft environment hook"
  local runner_sh="$E2E_ROOT_DIR/scripts/agent-e2e.sh"
  local agent_env_sh="$E2E_ROOT_DIR/scripts/agent-env.sh"
  local agent_run_sh="$E2E_ROOT_DIR/scripts/agent-run.sh"
  if grep -Fq 'source "$E2E_ROOT_DIR/scripts/agent-env.sh"' "$runner_sh"; then
    printf 'PASS agent-e2e sources scripts/agent-env.sh\n'
  else
    printf 'FAIL agent-e2e sources scripts/agent-env.sh\n'
    rc=1
  fi
  if grep -Fq 'YSYX_AGENT_ENV_SOURCED=1' "$agent_env_sh"; then
    printf 'PASS agent-env exports sourced marker\n'
  else
    printf 'FAIL agent-env exports sourced marker\n'
    rc=1
  fi
  if grep -Fq 'source "$REPO_ROOT/scripts/agent-env.sh"' "$agent_run_sh" &&
     grep -Fq 'exec "$@"' "$agent_run_sh"; then
    printf 'PASS agent-run sources scripts/agent-env.sh before exec\n'
  else
    printf 'FAIL agent-run sources scripts/agent-env.sh before exec\n'
    rc=1
  fi
  if grep -Fq '看似 source、实际为空' "$agent_env_sh" &&
     grep -Fq 'unset YSYX_AGENT_ENV_SOURCED YSYX_AGENT_ENV_SOURCE' "$agent_env_sh" &&
     grep -Fq 'unset YSYX_HOME NEMU_HOME AM_HOME NPC_HOME NVBOARD_HOME YOSYSSTA_HOME' "$agent_env_sh"; then
    printf 'PASS agent-env repairs incomplete inherited marker\n'
  else
    printf 'FAIL agent-env repairs incomplete inherited marker\n'
    rc=1
  fi

  echo "[agent-system] outer command-control hygiene"
  local workflow_doc=".github/instructions/agent-e2e-workflow.instructions.md"
  local e2e_readme=".github/e2e/README.md"
  local agent_contract=".github/e2e/modules/agent-system.md"
  local control_hygiene_ok=1
  for doc in "$workflow_doc" "$e2e_readme" "$agent_contract"; do
    if e2e_file_contains "$doc" '外层工具控制符' &&
       e2e_file_contains "$doc" 'rg -e'; then
      printf 'PASS command-control hygiene documented in %s\n' "$doc"
    else
      printf 'FAIL command-control hygiene documented in %s\n' "$doc"
      control_hygiene_ok=0
    fi
  done
  if [[ $control_hygiene_ok -ne 1 ]]; then
    rc=1
  fi

  echo "[agent-system] WSL single-flight hygiene"
  local wsl_hygiene_ok=1
  for doc in "$workflow_doc" "$e2e_readme" "$agent_contract"; do
    if e2e_file_contains "$doc" '并发启动多个 `wsl.exe`' &&
       e2e_file_contains "$doc" 'Wsl/Service/E_UNEXPECTED' &&
       e2e_file_contains "$doc" 'scripts/agent-run.sh'; then
      printf 'PASS WSL single-flight hygiene documented in %s\n' "$doc"
    else
      printf 'FAIL WSL single-flight hygiene documented in %s\n' "$doc"
      wsl_hygiene_ok=0
    fi
  done
  if [[ $wsl_hygiene_ok -ne 1 ]]; then
    rc=1
  fi

  echo "[agent-system] e2e evidence guard"
  local evidence_guard_ok=1
  local E2E_GUARD_REQUIRE_DB_ARCHIVE=0
  export E2E_GUARD_REQUIRE_DB_ARCHIVE
  if grep -Fq 'E2E_GUARD_MODE=strict' "$runner_sh" &&
     grep -Fq 'e2e_guard_profiles_for_path' "$runner_sh" &&
     grep -Fq 'e2e_guard_evidence_has_db_recall' "$runner_sh" &&
     grep -Fq 'e2e_guard_evidence_has_db_archive' "$runner_sh" &&
     grep -Fq 'e2e_guard_evidence_updated_epoch' "$runner_sh" &&
     grep -Fq 'e2e_validate_task_run_bundle' "$runner_sh" &&
     grep -Fq 'missing_evidence profile=' "$runner_sh" &&
     grep -Fq -- '--guard-mode strict' "$E2E_ROOT_DIR/.github/AGENTS.md" &&
     grep -Fq -- '--guard-mode strict' "$E2E_ROOT_DIR/.github/instructions/agent-e2e-workflow.instructions.md" &&
     grep -Fq -- '--guard-mode strict' "$E2E_ROOT_DIR/.github/e2e/README.md" &&
     grep -Fq -- '--guard-mode strict' "$E2E_ROOT_DIR/scripts/README.md" &&
     grep -Fq -- 'context-brief.md' "$E2E_ROOT_DIR/.github/instructions/agent-e2e-workflow.instructions.md" &&
     grep -Fq -- 'evidence-index.md' "$E2E_ROOT_DIR/.github/e2e/README.md" &&
     grep -Fq -- '`nodes.tsv`' "$E2E_ROOT_DIR/.github/e2e/README.md"; then
    printf 'PASS e2e evidence guard is wired into runner and docs\n'
  else
    printf 'FAIL e2e evidence guard runner or docs missing\n'
    evidence_guard_ok=0
  fi
  if (
    git() { return 42; }
    E2E_GUARD_PATHS_FILE=
    E2E_GUARD_PATH_ARGS=()
    e2e_guard_collect_paths
  ) >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard treated Git enumeration failure as no changes\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard propagates Git enumeration failure\n'
  fi
  if (
    find() { return 42; }
    list_profiles >/dev/null
  ) || (
    find() { return 42; }
    validate_all_profiles >/dev/null
  ) || (
    list_profiles() { return 0; }
    validate_all_profiles >/dev/null
  ); then
    printf 'FAIL profile catalog accepted find failure or empty catalog\n'
    evidence_guard_ok=0
  else
    printf 'PASS profile catalog propagates find failure and rejects empty catalog\n'
  fi

  local guard_tmp guard_token guard_run_prefix guard_paths guard_evidence guard_report_only guard_missing_node
  local guard_context_injected guard_context_profile_mismatch guard_context_indented_heading guard_context_truncated
  local guard_resolve_injected guard_resolve_profile_mismatch guard_resolve_indented_heading guard_resolve_truncated
  local guard_context_empty_chunks guard_context_history_primary guard_resolve_duplicate_nodes guard_manifest_skip
  local guard_identity_mismatch guard_time_mismatch
  local guard_resolve_tuple_mismatch guard_dispatch_orphan guard_dispatch_field_mismatch
  local guard_dispatch_order_mismatch guard_manifest_summary_mismatch guard_evidence_pointer_dangling
  local guard_profile_tuple_rewrite guard_evidence_pointer_misbound
  local guard_symlink_root
  local guard_change_epoch guard_fresh_updated_at guard_newest_updated_at guard_run_id
  local guard_stale_semantic guard_fresh_semantic guard_profile_mismatch
  local guard_older_candidate guard_newest_candidate guard_select_out
  local guard_manifest_status guard_manifest_missing guard_manifest_naive
  local guard_manifest_invalid guard_manifest_nonobject guard_invalid_out
  local guard_manifest_nonfinite guard_manifest_duplicate guard_manifest_dangling
  local guard_manifest_future guard_report_injected
  local guard_index_truncated guard_index_wrong_profile guard_index_missing_asset guard_index_hash_mismatch
  local guard_marker_missing guard_marker_stale
  local guard_legacy_prefix guard_legacy_duplicate
  local guard_fraction_early guard_fraction_late guard_fraction_before_trigger
  local guard_fraction_out guard_fraction_base guard_before_trigger_timestamp
  guard_tmp=$(mktemp -d) || return 1
  guard_token=$(basename "$guard_tmp")
  guard_run_prefix="$E2E_ROOT_DIR/.github/task-runs/.agent-system-guard-${guard_token}"
  guard_paths="$guard_tmp/paths.txt"
  guard_evidence="${guard_run_prefix}-evidence-pass"
  guard_run_id=$(basename "$guard_evidence")
  guard_report_only="${guard_run_prefix}-evidence-report-only"
  guard_context_injected="${guard_run_prefix}-evidence-context-injected"
  guard_context_profile_mismatch="${guard_run_prefix}-evidence-context-profile-mismatch"
  guard_context_indented_heading="${guard_run_prefix}-evidence-context-indented-heading"
  guard_context_truncated="${guard_run_prefix}-evidence-context-truncated"
  guard_context_empty_chunks="${guard_run_prefix}-evidence-context-empty-chunks"
  guard_resolve_injected="${guard_run_prefix}-evidence-resolve-injected"
  guard_resolve_profile_mismatch="${guard_run_prefix}-evidence-resolve-profile-mismatch"
  guard_resolve_indented_heading="${guard_run_prefix}-evidence-resolve-indented-heading"
  guard_resolve_truncated="${guard_run_prefix}-evidence-resolve-truncated"
  guard_resolve_duplicate_nodes="${guard_run_prefix}-evidence-resolve-duplicate-nodes"
  guard_manifest_skip="${guard_run_prefix}-evidence-manifest-skip"
  guard_identity_mismatch="${guard_run_prefix}-evidence-identity-mismatch"
  guard_time_mismatch="${guard_run_prefix}-evidence-time-mismatch"
  guard_resolve_tuple_mismatch="${guard_run_prefix}-evidence-resolve-tuple-mismatch"
  guard_dispatch_orphan="${guard_run_prefix}-evidence-dispatch-orphan"
  guard_dispatch_field_mismatch="${guard_run_prefix}-evidence-dispatch-field-mismatch"
  guard_dispatch_order_mismatch="${guard_run_prefix}-evidence-dispatch-order-mismatch"
  guard_manifest_summary_mismatch="${guard_run_prefix}-evidence-manifest-summary-mismatch"
  guard_evidence_pointer_dangling="${guard_run_prefix}-evidence-pointer-dangling"
  guard_profile_tuple_rewrite="${guard_run_prefix}-evidence-profile-tuple-rewrite"
  guard_evidence_pointer_misbound="${guard_run_prefix}-evidence-pointer-misbound"
  guard_symlink_root="${guard_run_prefix}-evidence-symlink-root"
  guard_stale_semantic="${guard_run_prefix}-evidence-stale-semantic"
  guard_fresh_semantic="${guard_run_prefix}-evidence-fresh-semantic"
  guard_profile_mismatch="${guard_run_prefix}-evidence-profile-mismatch"
  guard_older_candidate="${guard_run_prefix}-evidence-older-candidate"
  guard_newest_candidate="${guard_run_prefix}-evidence-newest-candidate"
  guard_manifest_status="${guard_run_prefix}-evidence-manifest-status"
  guard_manifest_missing="${guard_run_prefix}-evidence-manifest-missing"
  guard_manifest_naive="${guard_run_prefix}-evidence-manifest-naive"
  guard_manifest_invalid="${guard_run_prefix}-evidence-manifest-invalid"
  guard_manifest_nonobject="${guard_run_prefix}-evidence-manifest-nonobject"
  guard_manifest_nonfinite="${guard_run_prefix}-evidence-manifest-nonfinite"
  guard_manifest_duplicate="${guard_run_prefix}-evidence-manifest-duplicate"
  guard_manifest_dangling="${guard_run_prefix}-evidence-manifest-dangling"
  guard_manifest_future="${guard_run_prefix}-evidence-manifest-future"
  guard_report_injected="${guard_run_prefix}-evidence-report-injected"
  guard_index_truncated="${guard_run_prefix}-evidence-index-truncated"
  guard_index_wrong_profile="${guard_run_prefix}-evidence-index-wrong-profile"
  guard_index_missing_asset="${guard_run_prefix}-evidence-index-missing-asset"
  guard_index_hash_mismatch="${guard_run_prefix}-evidence-index-hash-mismatch"
  guard_marker_missing="${guard_run_prefix}-evidence-marker-missing"
  guard_marker_stale="${guard_run_prefix}-evidence-marker-stale"
  guard_legacy_prefix="${guard_run_prefix}-evidence-legacy-prefix"
  guard_legacy_duplicate="${guard_run_prefix}-evidence-legacy-duplicate"
  guard_fraction_early="${guard_run_prefix}-evidence-fraction-early"
  guard_fraction_late="${guard_run_prefix}-evidence-fraction-late"
  guard_fraction_before_trigger="${guard_run_prefix}-evidence-fraction-before-trigger"
  guard_change_epoch=$(stat -c '%Y' "$E2E_ROOT_DIR/.github/AGENTS.md")
  guard_fresh_updated_at=$(date -d "@$((guard_change_epoch + 1))" '+%Y-%m-%d %H:%M:%S %z')
  guard_newest_updated_at=$(date -d "@$((guard_change_epoch + 2))" '+%Y-%m-%d %H:%M:%S %z')
  guard_fraction_base=$(date -u -d "@$((guard_change_epoch + 3))" '+%Y-%m-%d %H:%M:%S')
  guard_refresh_completion() {
    local fixture_dir=$1
    mkdir -p "$fixture_dir/evidence" || return 1
    python3 - "$fixture_dir" "$E2E_ROOT_DIR" <<'PY' || return 1
import hashlib
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
repo_root = Path(sys.argv[2]).resolve()
run_id = root.name
run_rel = root.relative_to(repo_root).as_posix()
manifest_path = root / "run-manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
started_at = str(manifest["started_at"])
updated_at = str(manifest["updated_at"])
profile_root = repo_root / ".github" / "e2e" / "profiles"
profile_order: list[str] = []
nodes: list[dict[str, str]] = []


def visit(profile: str, stack: list[str]) -> None:
    if not re.fullmatch(r"[A-Za-z0-9_.-]+", profile) or profile in stack or len(stack) >= 64:
        raise ValueError("invalid profile closure")
    path = profile_root / f"{profile}.tsv"
    if path.is_symlink() or not path.is_file():
        raise ValueError("missing ordinary profile")
    if profile not in profile_order:
        profile_order.append(profile)
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("#"):
            continue
        parts = line.split("|", 5)
        if len(parts) != 6:
            raise ValueError("malformed profile row")
        node_id, module, function, owner, inputs, outputs = parts
        if node_id == "@include":
            if not module or any((function, owner, inputs, outputs)):
                raise ValueError("malformed include")
            visit(module, [*stack, profile])
            continue
        if not all((node_id, module, function, owner)):
            raise ValueError("incomplete profile node")
        evidence = f"{run_rel}/evidence/{node_id}.log"
        nodes.append(
            {
                "node_id": node_id,
                "owner_agent": owner,
                "module": module,
                "status": "PASS",
                "inputs": inputs,
                "outputs": outputs,
                "evidence": evidence,
                "source_profile": profile,
                "function": function,
            }
        )


visit("agent-system", [])
if not nodes or len({node["node_id"] for node in nodes}) != len(nodes):
    raise ValueError("invalid resolved node set")

evidence_dir = root / "evidence"
assets: list[tuple[Path, str, int, str]] = []
for node in nodes:
    path = evidence_dir / f"{node['node_id']}.log"
    path.write_text(f"PASS {node['node_id']}\n", encoding="utf-8")
    raw = path.read_bytes()
    assets.append((path, node["evidence"], len(raw), hashlib.sha256(raw).hexdigest()))
evidence_size = sum(item[2] for item in assets)

manifest["run_id"] = run_id
manifest["trace_id"] = f"e2e:{run_id}"
manifest["task_slug"] = "guard-fixture"
manifest["profile"] = "agent-system"
manifest["graph_template"] = "modular-agent-e2e"
manifest["graph_mode"] = "static"
manifest["publication_contract"] = "db-marker-v1"
manifest["status"] = "completed"
manifest["started_at"] = started_at
manifest["updated_at"] = updated_at
manifest["artifacts"] = {
    "run_dir": run_rel,
    "task_report": f"{run_rel}/task-report.md",
    "dispatch_log": f"{run_rel}/dispatch-log.md",
    "context_brief": f"{run_rel}/context-brief.md",
    "profile_resolve": f"{run_rel}/profile-resolve.md",
    "evidence_index": f"{run_rel}/evidence-index.md",
    "nodes": f"{run_rel}/nodes.tsv",
    "evidence_dir": f"{run_rel}/evidence",
    "run_manifest": f"{run_rel}/run-manifest.json",
}
manifest["db"] = {"markdown_archive": True, "raw_evidence_index_only": True}
manifest["evidence"] = {
    "asset_count": len(assets),
    "by_kind": {"log": len(assets)},
    "total_size_bytes": evidence_size,
}
manifest["node_counts"] = {"total": len(nodes), "by_status": {"PASS": len(nodes)}}
manifest["nodes"] = nodes
manifest_path.write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
node_rows = []
for node in nodes:
    node_rows.append(
        "\t".join(
            [
                node["node_id"],
                node["owner_agent"],
                node["module"],
                "PASS",
                node["inputs"],
                node["outputs"],
                node["evidence"],
                node["source_profile"],
                node["function"],
            ]
        )
    )
(root / "nodes.tsv").write_text("\n".join(node_rows) + "\n", encoding="utf-8")

report_lines = [
    "# 任务报告",
    "",
    "## 基本信息",
    "",
    f"- `task_id`: {run_id}",
    f"- `trace_id`: e2e:{run_id}",
    "- `task_slug`: guard-fixture",
    "- `graph_template`: modular-agent-e2e",
    "- `profile`: agent-system",
    "- `graph_mode`: static",
    "- `publication_contract`: db-marker-v1",
    "- `status`: completed",
    f"- `started_at`: {started_at}",
    f"- `updated_at`: {updated_at}",
    "",
    "## 节点概览",
    "",
    "| 节点ID (`node_id`) | 负责 Agent (`owner_agent`) | 模块 (`module`) | 状态 (`status`) | 输入 (`inputs`) | 输出 (`outputs`) | 证据 (`evidence`) |",
    "| ------------------ | -------------------------- | --------------- | --------------- | --------------- | ----------------- | ----------------- |",
]
for node in nodes:
    report_lines.append(
        f"| `{node['node_id']}` | `{node['owner_agent']}` | `{node['module']}` | `PASS` | "
        f"{node['inputs']} | {node['outputs']} | {node['evidence']} |"
    )
report_lines.extend(["", "## 收尾结论", "", "- `final_result`: guard fixture completed", ""])
(root / "task-report.md").write_text("\n".join(report_lines), encoding="utf-8")

resolve_lines = [
    "# E2E Resolved Profile",
    "",
    "- `source`: live-or-stored",
    "- `profile`: agent-system",
    "- `ok`: True",
    f"- `expanded_node_count`: {len(nodes)}",
    f"- `profile_order`: {', '.join(profile_order)}",
    f"- `modules`: {', '.join(sorted({node['module'] for node in nodes}))}",
    f"- `owners`: {', '.join(sorted({node['owner_agent'] for node in nodes}))}",
    "- `command`: scripts/agent-e2e.sh --profile agent-system",
    "- `validate_command`: scripts/agent-e2e.sh --validate-profile --profile agent-system",
    "",
    "## Nodes",
]
for index, node in enumerate(nodes, start=1):
    resolve_lines.append(
        f"{index}. `{node['node_id']}` source=`{node['source_profile']}` module=`{node['module']}` "
        f"owner=`{node['owner_agent']}` function=`{node['function']}`"
    )
resolve_lines.append("")
(root / "profile-resolve.md").write_text("\n".join(resolve_lines), encoding="utf-8")

dispatch_lines = [
    "# 派发日志",
    "",
    "## 基本信息",
    "",
    f"- `task_id`: {run_id}",
    f"- `trace_id`: e2e:{run_id}",
    "- `task_slug`: guard-fixture",
    "- `graph_template`: modular-agent-e2e",
    "- `profile`: agent-system",
    "- `log_policy`: append-only",
    "",
    "---",
]


def append_event(node_id: str, status: str, fields: dict[str, str]) -> None:
    dispatch_lines.extend(["", f"### [{updated_at}] `{node_id}` - `{status}`", ""])
    for key in (
        "owner_agent",
        "module",
        "trigger",
        "depends_on",
        "inputs",
        "action",
        "outputs",
        "evidence",
        "handoff_to",
        "next_step",
        "notes",
    ):
        dispatch_lines.append(f"- `{key}`: {fields[key]}")


append_event(
    "context-brief",
    "PASS",
    {
        "owner_agent": "agent-system",
        "module": "github-index",
        "trigger": "e2e:agent-system",
        "depends_on": "",
        "inputs": ".github live index + retained memory/log",
        "action": "github-index brief",
        "outputs": f"{run_rel}/context-brief.md",
        "evidence": f"{run_rel}/context-brief.md",
        "handoff_to": "",
        "next_step": "DB-indexed startup context generated before dispatch",
        "notes": "",
    },
)
append_event(
    "profile-resolve",
    "PASS",
    {
        "owner_agent": "agent-system",
        "module": "github-index",
        "trigger": "e2e:agent-system",
        "depends_on": "",
        "inputs": ".github/e2e/profiles/agent-system.tsv",
        "action": "github-index resolve-profile",
        "outputs": f"{run_rel}/profile-resolve.md",
        "evidence": f"{run_rel}/profile-resolve.md",
        "handoff_to": "",
        "next_step": "live/indexed e2e profile include closure generated before dispatch",
        "notes": "",
    },
)
for node in nodes:
    base = {
        "owner_agent": node["owner_agent"],
        "module": node["module"],
        "trigger": "e2e:agent-system",
        "depends_on": "",
        "inputs": node["inputs"],
        "action": node["function"],
        "outputs": node["outputs"],
        "evidence": node["evidence"],
        "handoff_to": "",
        "notes": "",
    }
    append_event(node["node_id"], "in-progress", {**base, "next_step": "等待节点结果"})
    append_event(node["node_id"], "PASS", {**base, "next_step": "进入下一节点"})
(root / "dispatch-log.md").write_text("\n".join(dispatch_lines) + "\n", encoding="utf-8")

index_lines = [
    "# Evidence Index",
    "",
    "## 基本信息",
    "",
    f"- `task_id`: {run_id}",
    "- `task_slug`: guard-fixture",
    "- `profile`: agent-system",
    f"- `asset_count`: {len(assets)}",
    f"- `total_size_bytes`: {evidence_size}",
    "",
    "## 证据资产",
]
for path, rel, size, digest in assets:
    index_lines.extend(
        [
            "",
            f"### {rel}",
            "",
            "- `kind`: log",
            f"- `size_bytes`: {size}",
            "- `line_count`: 1",
            f"- `sha256`: {digest}",
        ]
    )
index_lines.append("")
(root / "evidence-index.md").write_text("\n".join(index_lines), encoding="utf-8")
PY
    e2e_validate_evidence_index "$E2E_ROOT_DIR" "$fixture_dir" agent-system || return 1
    e2e_validate_task_run_bundle "$fixture_dir" agent-system || return 1
    e2e_write_completion_marker_for_dir "$fixture_dir" agent-system
  }
  guard_set_bundle_updated_at() {
    local fixture_dir=$1 fixture_updated_at=$2
    python3 - "$fixture_dir" "$fixture_updated_at" <<'PY'
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
updated_at = sys.argv[2]
report_path = root / "task-report.md"
report = report_path.read_text(encoding="utf-8")
report, count = re.subn(
    r"(?m)^- `updated_at`:\s*.*$",
    f"- `updated_at`: {updated_at}",
    report,
)
if count != 1:
    raise SystemExit(1)
report_path.write_text(report, encoding="utf-8")
manifest_path = root / "run-manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
manifest["updated_at"] = updated_at
manifest_path.write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
PY
  }
  mkdir -p "$guard_evidence"
  cat > "$guard_evidence/task-report.md" <<'EOF'
# 任务报告

## 基本信息

- `task_id`: __GUARD_RUN_ID__
- `trace_id`: e2e:__GUARD_RUN_ID__
- `task_slug`: guard-fixture
- `graph_template`: modular-agent-e2e
- `profile`: agent-system
- `graph_mode`: static
- `publication_contract`: db-marker-v1
- `status`: completed
- `started_at`: __GUARD_UPDATED_AT__
- `updated_at`: __GUARD_UPDATED_AT__

## 节点概览

| 节点ID (`node_id`) | 负责 Agent (`owner_agent`) | 模块 (`module`) | 状态 (`status`) | 输入 (`inputs`) | 输出 (`outputs`) | 证据 (`evidence`) |
| ------------------ | -------------------------- | --------------- | --------------- | --------------- | ----------------- | ----------------- |
| `guard-node` | `agent-system` | `agent-system` | `PASS` | guard input | guard output | evidence/probe.log |
EOF
  sed -i \
    -e "s/__GUARD_RUN_ID__/$guard_run_id/g" \
    -e "s/__GUARD_UPDATED_AT__/$guard_fresh_updated_at/g" \
    "$guard_evidence/task-report.md"
  cat > "$guard_evidence/context-brief.md" <<'EOF'
# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: agent-system
- `terms`: agent-system guard-fixture
- `focus_scope`: non-history
- `token_estimate`: 120 / 1800

## Chunks

### .github/AGENTS.md#chunk-0001

- `kind`: agent-rule
- `lines`: 1-1
- `tokens`: 1
- `heading`: canonical rule
- `summary`: canonical rule summary

canonical rule content

### .github/e2e/profiles/agent-system.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-1
- `tokens`: 1
- `heading`: requested profile
- `summary`: requested profile summary

requested profile content

### AI_ENVIRONMENT.md#chunk-0001

- `kind`: agent-environment
- `lines`: 1-1
- `tokens`: 1
- `heading`: independent focus
- `summary`: independent focus summary

independent focus content
EOF
  cat > "$guard_evidence/profile-resolve.md" <<'EOF'
# E2E Resolved Profile

- `source`: live-or-stored
- `profile`: agent-system
- `ok`: True
- `expanded_node_count`: 1
- `profile_order`: agent-system
- `modules`: agent-system
- `owners`: agent-system
- `command`: scripts/agent-e2e.sh --profile agent-system
- `validate_command`: scripts/agent-e2e.sh --validate-profile --profile agent-system

## Nodes
1. `guard-node` source=`agent-system` module=`agent-system` owner=`agent-system` function=`guard_fixture`
EOF
  cat > "$guard_evidence/run-manifest.json" <<EOF
{
  "run_id": "$guard_run_id",
  "trace_id": "e2e:$guard_run_id",
  "task_slug": "guard-fixture",
  "profile": "agent-system",
  "graph_template": "modular-agent-e2e",
  "graph_mode": "static",
  "publication_contract": "db-marker-v1",
  "status": "completed",
  "started_at": "$guard_fresh_updated_at",
  "updated_at": "$guard_fresh_updated_at",
  "node_counts": {"total": 1, "by_status": {"PASS": 1}},
  "nodes": [
    {
      "node_id": "guard-node",
      "owner_agent": "agent-system",
      "module": "agent-system",
      "status": "PASS",
      "inputs": "guard input",
      "outputs": "guard output",
      "evidence": "evidence/probe.log",
      "source_profile": "agent-system",
      "function": "guard_fixture"
    }
  ]
}
EOF
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    guard-node agent-system agent-system PASS 'guard input' 'guard output' evidence/probe.log \
    agent-system guard_fixture \
    > "$guard_evidence/nodes.tsv"
  cat > "$guard_evidence/dispatch-log.md" <<'EOF'
# 派发日志

## 基本信息

- `task_id`: __GUARD_RUN_ID__
- `trace_id`: e2e:__GUARD_RUN_ID__
- `task_slug`: guard-fixture
- `graph_template`: modular-agent-e2e
- `profile`: agent-system
- `log_policy`: append-only

---

### [2000-01-01 00:00:00 +0000] `context-brief` - `PASS`

### [2000-01-01 00:00:00 +0000] `profile-resolve` - `PASS`

### [2000-01-01 00:00:00 +0000] `guard-node` - `PASS`
EOF
  sed -i "s/__GUARD_RUN_ID__/$guard_run_id/g" "$guard_evidence/dispatch-log.md"
  if ! guard_refresh_completion "$guard_evidence"; then
    printf 'FAIL unable to build canonical guard fixture evidence\n'
    evidence_guard_ok=0
  fi
  touch -d "@$((guard_change_epoch + 1))" "$guard_evidence/task-report.md"
  printf '%s\n' '.github/AGENTS.md' > "$guard_paths"
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" --evidence-dir "$guard_evidence" >/dev/null 2>&1; then
    printf 'PASS e2e evidence guard accepts matching completed task-run evidence\n'
  else
    printf 'FAIL e2e evidence guard rejected matching completed task-run evidence\n'
    evidence_guard_ok=0
  fi
  mkdir -p \
    "$guard_resolve_tuple_mismatch" \
    "$guard_dispatch_orphan" \
    "$guard_dispatch_field_mismatch" \
    "$guard_dispatch_order_mismatch" \
    "$guard_manifest_summary_mismatch" \
    "$guard_evidence_pointer_dangling" \
    "$guard_profile_tuple_rewrite" \
    "$guard_evidence_pointer_misbound"
  for guard_fixture_dir in \
    "$guard_resolve_tuple_mismatch" \
    "$guard_dispatch_orphan" \
    "$guard_dispatch_field_mismatch" \
    "$guard_dispatch_order_mismatch" \
    "$guard_manifest_summary_mismatch" \
    "$guard_evidence_pointer_dangling" \
    "$guard_profile_tuple_rewrite" \
    "$guard_evidence_pointer_misbound"; do
    cp -a "$guard_evidence/." "$guard_fixture_dir/"
    guard_refresh_completion "$guard_fixture_dir" || evidence_guard_ok=0
  done
  python3 - \
    "$E2E_ROOT_DIR" \
    "$guard_resolve_tuple_mismatch" \
    "$guard_dispatch_orphan" \
    "$guard_dispatch_field_mismatch" \
    "$guard_dispatch_order_mismatch" \
    "$guard_manifest_summary_mismatch" \
    "$guard_evidence_pointer_dangling" \
    "$guard_profile_tuple_rewrite" \
    "$guard_evidence_pointer_misbound" <<'PY' || evidence_guard_ok=0
import json
import re
import sys
from pathlib import Path

repo_root = Path(sys.argv[1]).resolve()
resolve_dir, orphan_dir, field_dir, order_dir, summary_dir, pointer_dir, rewrite_dir, misbound_dir = [
    Path(raw).resolve() for raw in sys.argv[2:]
]

resolve_path = resolve_dir / "profile-resolve.md"
resolve_text = resolve_path.read_text(encoding="utf-8")
resolve_text, count = re.subn(
    r"function=`([^`]+)`",
    lambda match: f"function=`{match.group(1)}_mutated`",
    resolve_text,
    count=1,
)
if count != 1:
    raise SystemExit(1)
resolve_path.write_text(resolve_text, encoding="utf-8")

orphan_manifest = json.loads((orphan_dir / "run-manifest.json").read_text(encoding="utf-8"))
updated_at = orphan_manifest["updated_at"]
orphan_dispatch = orphan_dir / "dispatch-log.md"
orphan_dispatch.write_text(
    orphan_dispatch.read_text(encoding="utf-8")
    + f"""

### [{updated_at}] `orphan-node` - `in-progress`

- `owner_agent`: agent-system
- `module`: agent-system
- `trigger`: e2e:agent-system
- `depends_on`:
- `inputs`: orphan input
- `action`: orphan_function
- `outputs`: orphan output
- `evidence`: orphan evidence
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:
""",
    encoding="utf-8",
)

field_path = field_dir / "dispatch-log.md"
field_text = field_path.read_text(encoding="utf-8")
field_text, field_count = re.subn(
    r"(?m)^- `notes`:\s*$",
    "- `notes`: hash-consistent mutation",
    field_text,
    count=1,
)
if field_count != 1:
    raise SystemExit(1)
field_path.write_text(field_text, encoding="utf-8")

order_path = order_dir / "dispatch-log.md"
order_text = order_path.read_text(encoding="utf-8")
parts = re.split(r"(?=^### \[)", order_text, flags=re.MULTILINE)
if len(parts) < 5:
    raise SystemExit(1)
parts[1], parts[2] = parts[2], parts[1]
order_path.write_text("".join(parts), encoding="utf-8")

summary_path = summary_dir / "run-manifest.json"
summary = json.loads(summary_path.read_text(encoding="utf-8"))
summary["evidence"]["asset_count"] += 1
summary_path.write_text(
    json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)

pointer_rel = pointer_dir.relative_to(repo_root).as_posix()
dangling = f"{pointer_rel}/evidence/missing.log"
manifest_path = pointer_dir / "run-manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
original = manifest["nodes"][0]["evidence"]
manifest["nodes"][0]["evidence"] = dangling
manifest_path.write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
nodes_path = pointer_dir / "nodes.tsv"
node_lines = nodes_path.read_text(encoding="utf-8").splitlines()
node_fields = node_lines[0].split("\t")
if len(node_fields) != 9 or node_fields[6] != original:
    raise SystemExit(1)
node_fields[6] = dangling
node_lines[0] = "\t".join(node_fields)
nodes_path.write_text("\n".join(node_lines) + "\n", encoding="utf-8")
report_path = pointer_dir / "task-report.md"
report = report_path.read_text(encoding="utf-8")
report, report_count = report.replace(f"| {original} |", f"| {dangling} |", 1), report.count(
    f"| {original} |"
)
if report_count != 1:
    raise SystemExit(1)
report_path.write_text(report, encoding="utf-8")
dispatch_path = pointer_dir / "dispatch-log.md"
dispatch = dispatch_path.read_text(encoding="utf-8")
if dispatch.count(f"- `evidence`: {original}") != 2:
    raise SystemExit(1)
dispatch_path.write_text(
    dispatch.replace(f"- `evidence`: {original}", f"- `evidence`: {dangling}"),
    encoding="utf-8",
)

rewrite_manifest_path = rewrite_dir / "run-manifest.json"
rewrite_manifest = json.loads(rewrite_manifest_path.read_text(encoding="utf-8"))
rewrite_node = rewrite_manifest["nodes"][0]
old_function = rewrite_node["function"]
new_function = f"{old_function}_globally_rewritten"
rewrite_node["function"] = new_function
rewrite_manifest_path.write_text(
    json.dumps(rewrite_manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
rewrite_resolve_path = rewrite_dir / "profile-resolve.md"
rewrite_resolve = rewrite_resolve_path.read_text(encoding="utf-8")
if rewrite_resolve.count(f"function=`{old_function}`") != 1:
    raise SystemExit(1)
rewrite_resolve_path.write_text(
    rewrite_resolve.replace(f"function=`{old_function}`", f"function=`{new_function}`"),
    encoding="utf-8",
)
rewrite_nodes_path = rewrite_dir / "nodes.tsv"
rewrite_lines = rewrite_nodes_path.read_text(encoding="utf-8").splitlines()
rewrite_fields = rewrite_lines[0].split("\t")
if len(rewrite_fields) != 9 or rewrite_fields[8] != old_function:
    raise SystemExit(1)
rewrite_fields[8] = new_function
rewrite_lines[0] = "\t".join(rewrite_fields)
rewrite_nodes_path.write_text("\n".join(rewrite_lines) + "\n", encoding="utf-8")
rewrite_dispatch_path = rewrite_dir / "dispatch-log.md"
rewrite_dispatch = rewrite_dispatch_path.read_text(encoding="utf-8")
if rewrite_dispatch.count(f"- `action`: {old_function}") != 2:
    raise SystemExit(1)
rewrite_dispatch_path.write_text(
    rewrite_dispatch.replace(f"- `action`: {old_function}", f"- `action`: {new_function}"),
    encoding="utf-8",
)

misbound_manifest_path = misbound_dir / "run-manifest.json"
misbound_manifest = json.loads(misbound_manifest_path.read_text(encoding="utf-8"))
if len(misbound_manifest["nodes"]) < 2:
    raise SystemExit(1)
misbound_node = misbound_manifest["nodes"][0]
misbound_original = misbound_node["evidence"]
misbound_target = misbound_manifest["nodes"][1]["evidence"]
misbound_node["evidence"] = misbound_target
misbound_manifest_path.write_text(
    json.dumps(misbound_manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
misbound_nodes_path = misbound_dir / "nodes.tsv"
misbound_lines = misbound_nodes_path.read_text(encoding="utf-8").splitlines()
misbound_fields = misbound_lines[0].split("\t")
if len(misbound_fields) != 9 or misbound_fields[6] != misbound_original:
    raise SystemExit(1)
misbound_fields[6] = misbound_target
misbound_lines[0] = "\t".join(misbound_fields)
misbound_nodes_path.write_text("\n".join(misbound_lines) + "\n", encoding="utf-8")
misbound_report_path = misbound_dir / "task-report.md"
misbound_report = misbound_report_path.read_text(encoding="utf-8")
if misbound_report.count(f"| {misbound_original} |") != 1:
    raise SystemExit(1)
misbound_report_path.write_text(
    misbound_report.replace(f"| {misbound_original} |", f"| {misbound_target} |"),
    encoding="utf-8",
)
misbound_dispatch_path = misbound_dir / "dispatch-log.md"
misbound_dispatch = misbound_dispatch_path.read_text(encoding="utf-8")
if misbound_dispatch.count(f"- `evidence`: {misbound_original}") != 2:
    raise SystemExit(1)
misbound_dispatch_path.write_text(
    misbound_dispatch.replace(
        f"- `evidence`: {misbound_original}",
        f"- `evidence`: {misbound_target}",
    ),
    encoding="utf-8",
)
PY
  for guard_fixture_dir in \
    "$guard_resolve_tuple_mismatch" \
    "$guard_dispatch_orphan" \
    "$guard_dispatch_field_mismatch" \
    "$guard_dispatch_order_mismatch" \
    "$guard_manifest_summary_mismatch" \
    "$guard_evidence_pointer_dangling" \
    "$guard_profile_tuple_rewrite" \
    "$guard_evidence_pointer_misbound"; do
    e2e_write_completion_marker_for_dir "$guard_fixture_dir" agent-system || evidence_guard_ok=0
  done
  if e2e_validate_task_run_bundle "$guard_resolve_tuple_mismatch" agent-system ||
     e2e_validate_task_run_bundle "$guard_dispatch_orphan" agent-system ||
     e2e_validate_task_run_bundle "$guard_dispatch_field_mismatch" agent-system ||
     e2e_validate_task_run_bundle "$guard_dispatch_order_mismatch" agent-system ||
     e2e_validate_task_run_bundle "$guard_manifest_summary_mismatch" agent-system ||
     e2e_validate_task_run_bundle "$guard_evidence_pointer_dangling" agent-system ||
     e2e_validate_task_run_bundle "$guard_profile_tuple_rewrite" agent-system ||
     e2e_validate_task_run_bundle "$guard_evidence_pointer_misbound" agent-system; then
    printf 'FAIL e2e bundle accepted a hash-consistent or live-profile/evidence-owner mutation\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e bundle rejects hash-consistent mutations and binds live profile/evidence owner\n'
  fi
  guard_context_history_primary="${guard_run_prefix}-evidence-context-history-primary"
  mkdir -p "$guard_context_empty_chunks" "$guard_context_history_primary" "$guard_resolve_duplicate_nodes"
  cp "$guard_evidence/context-brief.md" "$guard_context_history_primary/context-brief.md"
  sed -i \
    -e 's|### AI_ENVIRONMENT.md#chunk-0001|### .github/task-runs/old-blocked/context-brief.md#chunk-0001|' \
    -e 's/- `kind`: agent-environment/- `kind`: task-run/' \
    "$guard_context_history_primary/context-brief.md"
  if e2e_validate_recall_header context \
      "$guard_context_history_primary/context-brief.md" agent-system; then
    printf 'FAIL recall validator accepted a historical task-run as non-history primary focus\n'
    evidence_guard_ok=0
  else
    printf 'PASS recall validator rejects a historical task-run as non-history primary focus\n'
  fi
  cat > "$guard_context_empty_chunks/context-brief.md" <<'EOF'
# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: agent-system
- `terms`: agent-system empty-shell
- `token_estimate`: 3 / 1800

## Chunks

### .github/AGENTS.md#chunk-0001
### .github/e2e/profiles/agent-system.tsv#chunk-0001
### AI_ENVIRONMENT.md#chunk-0001
EOF
  if e2e_validate_recall_header context \
      "$guard_context_empty_chunks/context-brief.md" agent-system; then
    printf 'FAIL recall validator accepted three empty chunk headings\n'
    evidence_guard_ok=0
  else
    printf 'PASS recall validator requires metadata and nonempty content in every chunk\n'
  fi
  cat > "$guard_resolve_duplicate_nodes/profile-resolve.md" <<'EOF'
# E2E Resolved Profile

- `source`: live-or-stored
- `profile`: agent-system
- `ok`: True
- `expanded_node_count`: 2
- `profile_order`: agent-system
- `modules`: agent-system
- `owners`: agent-system
- `command`: scripts/agent-e2e.sh --profile agent-system
- `validate_command`: scripts/agent-e2e.sh --validate-profile --profile agent-system

## Nodes
1. `guard-node` source=`agent-system` module=`agent-system` owner=`agent-system` function=`guard_fixture`
1. `guard-node` source=`agent-system` module=`agent-system` owner=`agent-system` function=`guard_fixture`
EOF
  if e2e_validate_recall_header resolve \
      "$guard_resolve_duplicate_nodes/profile-resolve.md" agent-system 2; then
    printf 'FAIL resolve validator accepted duplicate numbering and node IDs\n'
    evidence_guard_ok=0
  else
    printf 'PASS resolve validator requires consecutive numbering and unique node IDs\n'
  fi
  mkdir -p "$guard_manifest_skip" "$guard_identity_mismatch" "$guard_time_mismatch"
  cp -a "$guard_evidence/." "$guard_manifest_skip/"
  cp -a "$guard_evidence/." "$guard_identity_mismatch/"
  cp -a "$guard_evidence/." "$guard_time_mismatch/"
  guard_refresh_completion "$guard_manifest_skip" || evidence_guard_ok=0
  guard_refresh_completion "$guard_identity_mismatch" || evidence_guard_ok=0
  guard_refresh_completion "$guard_time_mismatch" || evidence_guard_ok=0
  python3 - "$guard_manifest_skip" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
path = root / "run-manifest.json"
manifest = json.loads(path.read_text(encoding="utf-8"))
node_id = manifest["nodes"][0]["node_id"]
manifest["nodes"][0]["status"] = "SKIP"
manifest["node_counts"]["by_status"] = {"PASS": len(manifest["nodes"]) - 1, "SKIP": 1}
path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
nodes_path = root / "nodes.tsv"
node_lines = nodes_path.read_text(encoding="utf-8").splitlines()
fields = node_lines[0].split("\t")
if len(fields) != 9 or fields[0] != node_id or fields[3] != "PASS":
    raise SystemExit(1)
fields[3] = "SKIP"
node_lines[0] = "\t".join(fields)
nodes_path.write_text("\n".join(node_lines) + "\n", encoding="utf-8")
report_path = root / "task-report.md"
report = report_path.read_text(encoding="utf-8")
old_row = f"| `{node_id}` | `{fields[1]}` | `{fields[2]}` | `PASS` |"
new_row = f"| `{node_id}` | `{fields[1]}` | `{fields[2]}` | `SKIP` |"
if report.count(old_row) != 1:
    raise SystemExit(1)
report_path.write_text(report.replace(old_row, new_row, 1), encoding="utf-8")
dispatch_path = root / "dispatch-log.md"
dispatch = dispatch_path.read_text(encoding="utf-8")
old_heading = f"`{node_id}` - `PASS`"
if dispatch.count(old_heading) != 1:
    raise SystemExit(1)
dispatch_path.write_text(
    dispatch.replace(old_heading, f"`{node_id}` - `SKIP`", 1),
    encoding="utf-8",
)
PY
  e2e_write_completion_marker_for_dir "$guard_manifest_skip" agent-system || evidence_guard_ok=0
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_manifest_skip" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted a hash-consistent completed bundle with SKIP\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard requires every completed profile node to be PASS\n'
  fi
  sed -i 's/^- `task_id`:.*/- `task_id`: unrelated-report/' \
    "$guard_identity_mismatch/task-report.md"
  sed -i 's/^- `task_id`:.*/- `task_id`: unrelated-dispatch/' \
    "$guard_identity_mismatch/dispatch-log.md"
  python3 - "$guard_identity_mismatch/run-manifest.json" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
manifest = json.loads(path.read_text(encoding="utf-8"))
manifest["run_id"] = "unrelated-manifest"
manifest["trace_id"] = "e2e:unrelated-manifest"
path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
  e2e_write_completion_marker_for_dir "$guard_identity_mismatch" agent-system || evidence_guard_ok=0
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_identity_mismatch" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted cross-task report/manifest/dispatch identities\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard binds run/report/manifest/index/dispatch identities\n'
  fi
  sed -i \
    -e 's/^- `started_at`:.*/- `started_at`: 2000-01-01 00:00:00 +0000/' \
    -e 's/^- `updated_at`:.*/- `updated_at`: 2000-01-01 00:00:00 +0000/' \
    "$guard_time_mismatch/task-report.md"
  e2e_write_completion_marker_for_dir "$guard_time_mismatch" agent-system || evidence_guard_ok=0
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_time_mismatch" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted report/manifest semantic time mismatch\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard binds report and manifest semantic timestamps\n'
  fi
  mkdir -p "$guard_index_truncated" "$guard_index_wrong_profile" \
    "$guard_index_missing_asset" "$guard_index_hash_mismatch"
  cp -a "$guard_evidence/." "$guard_index_truncated/"
  cp -a "$guard_evidence/." "$guard_index_wrong_profile/"
  cp -a "$guard_evidence/." "$guard_index_missing_asset/"
  cp -a "$guard_evidence/." "$guard_index_hash_mismatch/"
  guard_refresh_completion "$guard_index_truncated" || evidence_guard_ok=0
  guard_refresh_completion "$guard_index_wrong_profile" || evidence_guard_ok=0
  guard_refresh_completion "$guard_index_missing_asset" || evidence_guard_ok=0
  guard_refresh_completion "$guard_index_hash_mismatch" || evidence_guard_ok=0
  printf '# Evidence Index\n' > "$guard_index_truncated/evidence-index.md"
  sed -i 's/- `profile`: agent-system/- `profile`: npc-dev/' \
    "$guard_index_wrong_profile/evidence-index.md"
  while IFS=$'\t' read -r guard_missing_node _; do
    rm -f -- "$guard_index_missing_asset/evidence/${guard_missing_node}.log"
    break
  done < "$guard_index_missing_asset/nodes.tsv"
  sed -i 's/- `sha256`: [0-9a-f]\{64\}/- `sha256`: 0000000000000000000000000000000000000000000000000000000000000000/' \
    "$guard_index_hash_mismatch/evidence-index.md"
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_index_truncated" >/dev/null 2>&1 ||
     "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_index_wrong_profile" >/dev/null 2>&1 ||
     "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_index_missing_asset" >/dev/null 2>&1 ||
     "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_index_hash_mismatch" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted truncated, mismatched, missing or stale evidence index\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard verifies evidence-index profile, assets and hashes\n'
  fi
  mkdir -p "$guard_marker_missing" "$guard_marker_stale"
  cp -a "$guard_evidence/." "$guard_marker_missing/"
  cp -a "$guard_evidence/." "$guard_marker_stale/"
  guard_refresh_completion "$guard_marker_missing" || evidence_guard_ok=0
  guard_refresh_completion "$guard_marker_stale" || evidence_guard_ok=0
  rm -f -- "$guard_marker_missing/complete.marker"
  printf '\n## Late mutation\n' >> "$guard_marker_stale/task-report.md"
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_marker_missing" >/dev/null 2>&1 ||
     "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_marker_stale" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted missing or stale completion marker\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard requires hash-bound completion marker\n'
  fi
  mkdir -p "$guard_context_injected" "$guard_context_profile_mismatch"
  cp -a "$guard_evidence/." "$guard_context_injected/"
  cp -a "$guard_evidence/." "$guard_context_profile_mismatch/"
  cat > "$guard_context_injected/context-brief.md" <<'EOF'
# Agent Brief

- `ok`: false
- `recall_status`: failed
- `profile`: agent-system

## Diagnostic

```text
- `ok`: true
- `recall_status`: complete
- `profile`: agent-system
```
EOF
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_context_injected" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted complete marker inside diagnostic fence\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects complete marker inside diagnostic fence\n'
  fi
  cat > "$guard_context_profile_mismatch/context-brief.md" <<'EOF'
# Agent Brief

- `ok`: true
- `recall_status`: complete
- `profile`: github-index
EOF
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_context_profile_mismatch" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted context/report profile mismatch\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects context/report profile mismatch\n'
  fi
  mkdir -p "$guard_context_indented_heading"
  cp -a "$guard_evidence/." "$guard_context_indented_heading/"
  cat > "$guard_context_indented_heading/context-brief.md" <<'EOF'
# Agent Brief

 ## Diagnostic
- `ok`: true
- `recall_status`: complete
- `profile`: agent-system
EOF
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_context_indented_heading" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted success fields below indented ATX heading\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects success fields below indented ATX heading\n'
  fi
  mkdir -p "$guard_context_truncated"
  cp -a "$guard_evidence/." "$guard_context_truncated/"
  cat > "$guard_context_truncated/context-brief.md" <<'EOF'
# Agent Brief

- `ok`: true
- `recall_status`: complete
- `profile`: agent-system
EOF
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_context_truncated" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted header-only context brief\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects header-only context brief\n'
  fi
  mkdir -p "$guard_resolve_injected" "$guard_resolve_profile_mismatch"
  cp -a "$guard_evidence/." "$guard_resolve_injected/"
  cp -a "$guard_evidence/." "$guard_resolve_profile_mismatch/"
  cat > "$guard_resolve_injected/profile-resolve.md" <<'EOF'
# E2E Resolved Profile

- `profile`: agent-system
- `ok`: False

## Diagnostic

```text
- `profile`: agent-system
- `ok`: True
```
EOF
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_resolve_injected" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted successful resolve marker inside diagnostic fence\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects successful resolve marker inside diagnostic fence\n'
  fi
  cat > "$guard_resolve_profile_mismatch/profile-resolve.md" <<'EOF'
# E2E Resolved Profile

- `profile`: github-index
- `ok`: True
EOF
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_resolve_profile_mismatch" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted resolve/report profile mismatch\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects resolve/report profile mismatch\n'
  fi
  mkdir -p "$guard_resolve_indented_heading"
  cp -a "$guard_evidence/." "$guard_resolve_indented_heading/"
  cat > "$guard_resolve_indented_heading/profile-resolve.md" <<'EOF'
# E2E Resolved Profile

 ## Diagnostic
- `profile`: agent-system
- `ok`: True
EOF
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_resolve_indented_heading" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted resolve fields below indented ATX heading\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects resolve fields below indented ATX heading\n'
  fi
  mkdir -p "$guard_resolve_truncated"
  cp -a "$guard_evidence/." "$guard_resolve_truncated/"
  cat > "$guard_resolve_truncated/profile-resolve.md" <<'EOF'
# E2E Resolved Profile

- `source`: live-or-stored
- `profile`: agent-system
- `ok`: True
- `expanded_node_count`: 1
- `profile_order`: agent-system
- `modules`: agent-system
- `owners`: agent-system
- `command`: scripts/agent-e2e.sh --profile agent-system
- `validate_command`: scripts/agent-e2e.sh --validate-profile --profile agent-system
EOF
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_resolve_truncated" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted resolve without Nodes closure\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects resolve without Nodes closure\n'
  fi
  ln -s "$guard_evidence" "$guard_symlink_root"
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_symlink_root" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted symlink evidence root\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects symlink evidence root\n'
  fi
  mkdir -p "$guard_stale_semantic" "$guard_fresh_semantic" "$guard_profile_mismatch"
  mkdir -p "$guard_older_candidate" "$guard_newest_candidate"
  cp -a "$guard_evidence/." "$guard_stale_semantic/"
  cp -a "$guard_evidence/." "$guard_fresh_semantic/"
  cp -a "$guard_evidence/." "$guard_profile_mismatch/"
  cp -a "$guard_evidence/." "$guard_older_candidate/"
  cp -a "$guard_evidence/." "$guard_newest_candidate/"
  cat > "$guard_stale_semantic/run-manifest.json" <<'EOF'
{
  "profile": "agent-system",
  "status": "completed",
  "updated_at": "2000-01-01 00:00:00 +0000"
}
EOF
  touch -d "@$((guard_change_epoch + 1))" "$guard_stale_semantic/task-report.md"
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_stale_semantic" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted stale semantic time after report touch\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects stale semantic time after report touch\n'
  fi
  guard_refresh_completion "$guard_fresh_semantic" || evidence_guard_ok=0
  touch -d '2000-01-01 00:00:00 +0000' "$guard_fresh_semantic/task-report.md"
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_fresh_semantic" >/dev/null 2>&1; then
    printf 'PASS e2e evidence guard accepts fresh semantic time with old report mtime\n'
  else
    printf 'FAIL e2e evidence guard rejected fresh semantic time with old report mtime\n'
    evidence_guard_ok=0
  fi
  cat > "$guard_profile_mismatch/run-manifest.json" <<EOF
{
  "profile": "npc-dev",
  "status": "completed",
  "updated_at": "$guard_fresh_updated_at"
}
EOF
  touch -d "@$((guard_change_epoch + 1))" "$guard_profile_mismatch/task-report.md"
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_profile_mismatch" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted manifest/report profile mismatch\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects manifest/report profile mismatch\n'
  fi
  guard_set_bundle_updated_at "$guard_newest_candidate" "$guard_newest_updated_at" || evidence_guard_ok=0
  guard_refresh_completion "$guard_older_candidate" || evidence_guard_ok=0
  guard_refresh_completion "$guard_newest_candidate" || evidence_guard_ok=0
  touch -d "@$((guard_change_epoch + 1))" \
    "$guard_older_candidate/task-report.md" \
    "$guard_newest_candidate/task-report.md"
  if guard_select_out=$(
    "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_older_candidate" \
      --evidence-dir "$guard_newest_candidate" 2>&1
  ) &&
     grep -Fq -- "evidence=$guard_newest_candidate" <<< "$guard_select_out"; then
    printf 'PASS e2e evidence guard selects newest semantic evidence candidate\n'
  else
    printf '%s\n' "$guard_select_out"
    printf 'FAIL e2e evidence guard did not select newest semantic evidence candidate\n'
    evidence_guard_ok=0
  fi
  mkdir -p "$guard_manifest_status" "$guard_manifest_missing" "$guard_manifest_naive"
  mkdir -p "$guard_manifest_invalid" "$guard_manifest_nonobject"
  mkdir -p "$guard_manifest_nonfinite" "$guard_manifest_duplicate" "$guard_manifest_dangling"
  mkdir -p "$guard_manifest_future" "$guard_report_injected"
  mkdir -p "$guard_legacy_prefix" "$guard_legacy_duplicate"
  mkdir -p "$guard_fraction_early" "$guard_fraction_late"
  cp -a "$guard_evidence/." "$guard_manifest_status/"
  cp -a "$guard_evidence/." "$guard_manifest_missing/"
  cp -a "$guard_evidence/." "$guard_manifest_naive/"
  cp -a "$guard_evidence/." "$guard_manifest_invalid/"
  cp -a "$guard_evidence/." "$guard_manifest_nonobject/"
  cp -a "$guard_evidence/." "$guard_manifest_nonfinite/"
  cp -a "$guard_evidence/." "$guard_manifest_duplicate/"
  cp -a "$guard_evidence/." "$guard_manifest_dangling/"
  cp -a "$guard_evidence/." "$guard_manifest_future/"
  cp -a "$guard_evidence/." "$guard_report_injected/"
  cp -a "$guard_evidence/." "$guard_legacy_prefix/"
  cp -a "$guard_evidence/." "$guard_legacy_duplicate/"
  cp -a "$guard_evidence/." "$guard_fraction_early/"
  cp -a "$guard_evidence/." "$guard_fraction_late/"
  cat > "$guard_manifest_status/run-manifest.json" <<EOF
{
  "profile": "agent-system",
  "status": "blocked",
  "updated_at": "$guard_fresh_updated_at"
}
EOF
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_manifest_status" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted non-completed manifest status\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects non-completed manifest status\n'
  fi
  cat > "$guard_manifest_missing/run-manifest.json" <<'EOF'
{
  "profile": "agent-system",
  "status": "completed"
}
EOF
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_manifest_missing" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted manifest without updated_at\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects manifest without updated_at\n'
  fi
  cat > "$guard_manifest_naive/run-manifest.json" <<EOF
{
  "profile": "agent-system",
  "status": "completed",
  "updated_at": "$guard_fraction_base"
}
EOF
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_manifest_naive" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted timezone-less manifest timestamp\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects timezone-less manifest timestamp\n'
  fi
  cat > "$guard_manifest_future/run-manifest.json" <<'EOF'
{
  "profile": "agent-system",
  "status": "completed",
  "updated_at": "2099-01-01 00:00:00 +0000"
}
EOF
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_manifest_future" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted implausibly future evidence\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects implausibly future evidence\n'
  fi
  printf '{\n' > "$guard_manifest_invalid/run-manifest.json"
  if guard_invalid_out=$(
    "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_manifest_invalid" 2>&1
  ); then
    printf 'FAIL e2e evidence guard accepted invalid manifest JSON\n'
    evidence_guard_ok=0
  elif grep -Fq -- 'Traceback' <<< "$guard_invalid_out"; then
    printf '%s\n' "$guard_invalid_out"
    printf 'FAIL e2e evidence guard leaked traceback for invalid manifest JSON\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects invalid manifest JSON cleanly\n'
  fi
  printf '[]\n' > "$guard_manifest_nonobject/run-manifest.json"
  if guard_invalid_out=$(
    "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_manifest_nonobject" 2>&1
  ); then
    printf 'FAIL e2e evidence guard accepted non-object manifest JSON\n'
    evidence_guard_ok=0
  elif grep -Fq -- 'Traceback' <<< "$guard_invalid_out"; then
    printf '%s\n' "$guard_invalid_out"
    printf 'FAIL e2e evidence guard leaked traceback for non-object manifest JSON\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects non-object manifest JSON cleanly\n'
  fi
  cat > "$guard_manifest_nonfinite/run-manifest.json" <<EOF
{
  "profile": "agent-system",
  "status": "completed",
  "updated_at": "$guard_fresh_updated_at",
  "extra": NaN
}
EOF
  if guard_invalid_out=$(
    "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_manifest_nonfinite" 2>&1
  ); then
    printf 'FAIL e2e evidence guard accepted non-finite manifest JSON constant\n'
    evidence_guard_ok=0
  elif grep -Fq -- 'Traceback' <<< "$guard_invalid_out"; then
    printf '%s\n' "$guard_invalid_out"
    printf 'FAIL e2e evidence guard leaked traceback for non-finite JSON constant\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects non-finite manifest JSON cleanly\n'
  fi
  cat > "$guard_manifest_duplicate/run-manifest.json" <<EOF
{
  "profile": "agent-system",
  "profile": "npc-dev",
  "status": "completed",
  "updated_at": "$guard_fresh_updated_at"
}
EOF
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_manifest_duplicate" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted duplicate manifest JSON keys\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects duplicate manifest JSON keys\n'
  fi
  rm -f -- "$guard_manifest_dangling/run-manifest.json"
  ln -s 'missing-manifest.json' "$guard_manifest_dangling/run-manifest.json"
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_manifest_dangling" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted dangling manifest symlink as legacy evidence\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects dangling manifest symlink\n'
  fi
  cat > "$guard_legacy_prefix/task-report.md" <<'EOF'
# Legacy Prefix Collision

- `profile`: agent-system-old
- `status`: completed-with-warning
- `updated_at`: __GUARD_UPDATED_AT__
EOF
  sed -i "s/__GUARD_UPDATED_AT__/$guard_fresh_updated_at/" \
    "$guard_legacy_prefix/task-report.md"
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_legacy_prefix" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted legacy profile/status prefix collision\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects legacy profile/status prefix collision\n'
  fi
  cat > "$guard_legacy_duplicate/task-report.md" <<'EOF'
# Legacy Duplicate Fields

- `profile`: agent-system
- `profile`: npc-dev
- `status`: completed
- `updated_at`: __GUARD_UPDATED_AT__
EOF
  sed -i "s/__GUARD_UPDATED_AT__/$guard_fresh_updated_at/" \
    "$guard_legacy_duplicate/task-report.md"
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_legacy_duplicate" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted conflicting legacy report fields\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects conflicting legacy report fields\n'
  fi
  cat > "$guard_report_injected/task-report.md" <<'EOF'
# Failed Diagnostic

## Diagnostic

```text
- `profile`: agent-system
- `status`: completed
- `updated_at`: 2099-01-01 00:00:00 +0000
```
EOF
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_report_injected" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted report fields from diagnostic fence\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard requires canonical task-report basic-info header\n'
  fi
  guard_set_bundle_updated_at "$guard_fraction_early" "$guard_fraction_base.100000 +0000" || evidence_guard_ok=0
  guard_set_bundle_updated_at "$guard_fraction_late" "$guard_fraction_base.900000 +0000" || evidence_guard_ok=0
  guard_refresh_completion "$guard_fraction_early" || evidence_guard_ok=0
  guard_refresh_completion "$guard_fraction_late" || evidence_guard_ok=0
  if guard_fraction_out=$(
    "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_fraction_early" \
      --evidence-dir "$guard_fraction_late" 2>&1
  ) &&
     grep -Fq -- "evidence=$guard_fraction_late" <<< "$guard_fraction_out"; then
    printf 'PASS e2e evidence guard preserves fractional timestamp ordering\n'
  else
    printf '%s\n' "$guard_fraction_out"
    printf 'FAIL e2e evidence guard lost fractional timestamp ordering\n'
    evidence_guard_ok=0
  fi
  mkdir -p "$guard_fraction_before_trigger"
  cp -a "$guard_evidence/." "$guard_fraction_before_trigger/"
  guard_before_trigger_timestamp=$(python3 - "$E2E_ROOT_DIR/.github/AGENTS.md" <<'PY'
import os
import sys
from datetime import datetime, timezone

trigger_us = (os.stat(sys.argv[1]).st_mtime_ns + 999) // 1000
before_us = max(0, trigger_us - 1)
value = datetime.fromtimestamp(before_us / 1_000_000, timezone.utc)
print(value.strftime("%Y-%m-%d %H:%M:%S.%f +0000"))
PY
  )
  cat > "$guard_fraction_before_trigger/run-manifest.json" <<EOF
{
  "profile": "agent-system",
  "status": "completed",
  "updated_at": "$guard_before_trigger_timestamp"
}
EOF
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_fraction_before_trigger" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted same-second evidence before trigger mtime\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard preserves trigger mtime microseconds\n'
  fi
  printf '%s\n' 'scripts/e2e/definitely-deleted-guard-probe.sh' > "$guard_paths"
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" \
      --evidence-dir "$guard_evidence" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted unknown nonexistent trigger with old baseline\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects unknown nonexistent trigger without epoch-zero fallback\n'
  fi
  printf '%s\n' '.github/AGENTS.md' > "$guard_paths"
  mkdir -p "$guard_report_only"
  cat > "$guard_report_only/task-report.md" <<'EOF'
# 任务报告

- `profile`: agent-system
- `status`: completed
EOF
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" --evidence-dir "$guard_report_only" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted report without DB recall artifacts\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects report without DB recall artifacts\n'
  fi
  printf '%s\n' 'npc/rv64/vsrc/OooCore.v' > "$guard_paths"
  if "$runner_sh" --guard --guard-mode strict --paths-file "$guard_paths" --evidence-dir "$guard_evidence" >/dev/null 2>&1; then
    printf 'FAIL e2e evidence guard accepted missing npc-dev evidence\n'
    evidence_guard_ok=0
  else
    printf 'PASS e2e evidence guard rejects missing recommended profile evidence\n'
  fi
  local guard_fixture_dir
  if [[ ${E2E_KEEP_TEST_TMP:-0} = 1 ]]; then
    printf '[agent-system] kept guard fixture prefix at %s\n' "$guard_run_prefix"
  else
    for guard_fixture_dir in \
      "$guard_evidence" "$guard_report_only" \
      "$guard_context_injected" "$guard_context_profile_mismatch" \
      "$guard_context_indented_heading" "$guard_context_truncated" \
      "$guard_context_empty_chunks" "$guard_context_history_primary" \
      "$guard_resolve_injected" \
      "$guard_resolve_profile_mismatch" "$guard_resolve_indented_heading" \
      "$guard_resolve_truncated" "$guard_resolve_duplicate_nodes" \
      "$guard_manifest_skip" "$guard_identity_mismatch" "$guard_time_mismatch" \
      "$guard_resolve_tuple_mismatch" "$guard_dispatch_orphan" \
      "$guard_dispatch_field_mismatch" "$guard_dispatch_order_mismatch" \
      "$guard_manifest_summary_mismatch" "$guard_evidence_pointer_dangling" \
      "$guard_profile_tuple_rewrite" "$guard_evidence_pointer_misbound" \
      "$guard_symlink_root" "$guard_stale_semantic" "$guard_fresh_semantic" \
      "$guard_profile_mismatch" "$guard_older_candidate" "$guard_newest_candidate" \
      "$guard_manifest_status" "$guard_manifest_missing" "$guard_manifest_naive" \
      "$guard_manifest_invalid" "$guard_manifest_nonobject" "$guard_manifest_nonfinite" \
      "$guard_manifest_duplicate" "$guard_manifest_dangling" "$guard_manifest_future" \
      "$guard_report_injected" "$guard_index_truncated" "$guard_index_wrong_profile" \
      "$guard_index_missing_asset" "$guard_index_hash_mismatch" \
      "$guard_marker_missing" "$guard_marker_stale" "$guard_legacy_prefix" \
      "$guard_legacy_duplicate" "$guard_fraction_early" "$guard_fraction_late" \
      "$guard_fraction_before_trigger"; do
      [[ $guard_fixture_dir = "${guard_run_prefix}-"* ]] || return 1
      rm -rf -- "$guard_fixture_dir"
    done
    rm -rf -- "$guard_tmp"
  fi
  if [[ $evidence_guard_ok -ne 1 ]]; then
    rc=1
  fi

  echo "[agent-system] scenario profile isolation"
  local profile_isolation_ok=1
  for doc in "$workflow_doc" "$e2e_readme"; do
    if e2e_file_contains "$doc" 'nemu-dev' &&
       e2e_file_contains "$doc" 'npc-dev' &&
       e2e_file_contains "$doc" '场景隔离'; then
      printf 'PASS scenario profile isolation documented in %s\n' "$doc"
    else
      printf 'FAIL scenario profile isolation documented in %s\n' "$doc"
      profile_isolation_ok=0
    fi
  done
  if e2e_file_contains .github/e2e/profiles/nemu-dev.tsv '@include|nemu-ubuntu-focused' &&
     e2e_file_contains .github/e2e/profiles/nemu-dev-full-gate.tsv '@include|nemu-dev' &&
     e2e_file_contains .github/e2e/profiles/npc-dev.tsv 'npc-sim-contract|npc|e2e_npc_sim_contract' &&
     ! e2e_file_contains .github/e2e/profiles/nemu-dev.tsv 'npc-' &&
     ! e2e_file_contains .github/e2e/profiles/npc-dev.tsv 'nemu-ubuntu'; then
    printf 'PASS scenario dev profiles are split\n'
  else
    printf 'FAIL scenario dev profiles are split\n'
    profile_isolation_ok=0
  fi
  if e2e_file_contains .github/e2e/profiles/nemu-ubuntu-gate.tsv '@include|nemu-ubuntu' &&
     e2e_file_contains .github/e2e/profiles/nemu-ubuntu-full-gate.tsv '@include|nemu-ubuntu' &&
     e2e_file_contains .github/e2e/profiles/nemu-ubuntu-full-soak.tsv '@include|nemu-ubuntu'; then
    printf 'PASS existing NEMU Ubuntu integration profiles are preserved\n'
  else
    printf 'FAIL existing NEMU Ubuntu integration profiles are preserved\n'
    profile_isolation_ok=0
  fi
  if grep -Fq 'validate_profile_boundary' "$runner_sh" &&
     grep -Fq 'mode=NEMU-only' "$runner_sh" &&
     grep -Fq 'mode=NPC-only' "$runner_sh" &&
     grep -Fq 'NEMU-only dev profile pulled NPC work' "$runner_sh" &&
     grep -Fq 'NPC-only dev profile pulled NEMU work' "$runner_sh"; then
    printf 'PASS agent-e2e enforces runtime scenario profile boundary\n'
  else
    printf 'FAIL agent-e2e enforces runtime scenario profile boundary\n'
    profile_isolation_ok=0
  fi
  local scenario_runtime_sh="$E2E_ROOT_DIR/scripts/e2e/lib/common.sh"
  if grep -Fq 'e2e_validate_scenario_runtime_isolation' "$runner_sh" &&
     grep -Fq 'e2e_profile_runtime_scenario' "$scenario_runtime_sh" &&
     grep -Fq 'AGENT_E2E_SCENARIO_RUNTIME_ISOLATION' "$scenario_runtime_sh" &&
     grep -Fq 'AGENT_E2E_SCENARIO_RUNTIME_STALE_SECONDS' "$scenario_runtime_sh" &&
     grep -Fq 'E2E_SCENARIO_RUNTIME_PS_FILE' "$scenario_runtime_sh" &&
     grep -Fq 'ps -eo pid=,etimes=,args=' "$scenario_runtime_sh" &&
     grep -Fq 'run-guest-uart-ping' "$scenario_runtime_sh" &&
     grep -Fq 'nemu-python-int' "$scenario_runtime_sh"; then
    printf 'PASS agent-e2e exposes configurable active scenario runtime isolation\n'
  else
    printf 'FAIL agent-e2e active scenario runtime isolation hook missing\n'
    profile_isolation_ok=0
  fi
  local scenario_ps_file
  scenario_ps_file=$(mktemp)
  printf '%s\n' \
    '123 bash .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/run-guest-uart-ping-slow.sh' \
    '456 bash .github/task-runs/2026-06-16-nemu-python-int-full-lite-wide-ifetch-off/run.sh' \
    > "$scenario_ps_file"
  if AGENT_E2E_SCENARIO_RUNTIME_ISOLATION=warn E2E_SCENARIO_RUNTIME_PS_FILE="$scenario_ps_file" e2e_validate_scenario_runtime_isolation nemu-dev >/dev/null 2>&1 &&
     AGENT_E2E_SCENARIO_RUNTIME_ISOLATION=warn E2E_SCENARIO_RUNTIME_PS_FILE="$scenario_ps_file" e2e_validate_scenario_runtime_isolation npc-dev >/dev/null 2>&1; then
    printf 'PASS scenario runtime guard warns but allows conflicting fake processes by default\n'
  else
    printf 'FAIL scenario runtime guard blocks default parallel fake processes\n'
    profile_isolation_ok=0
  fi
  if AGENT_E2E_SCENARIO_RUNTIME_ISOLATION=strict E2E_SCENARIO_RUNTIME_PS_FILE="$scenario_ps_file" e2e_validate_scenario_runtime_isolation nemu-dev >/dev/null 2>&1 ||
     AGENT_E2E_SCENARIO_RUNTIME_ISOLATION=strict E2E_SCENARIO_RUNTIME_PS_FILE="$scenario_ps_file" e2e_validate_scenario_runtime_isolation npc-dev >/dev/null 2>&1; then
    printf 'FAIL scenario runtime strict guard accepts conflicting fake processes\n'
    profile_isolation_ok=0
  else
    printf 'PASS scenario runtime strict guard rejects conflicting fake processes\n'
  fi
  printf '%s\n' \
    '789 bash .github/task-runs/2026-06-16-nemu-python-int-full-lite-wide-ifetch-off/run.sh' \
    > "$scenario_ps_file"
  if AGENT_E2E_SCENARIO_RUNTIME_ISOLATION=strict E2E_SCENARIO_RUNTIME_PS_FILE="$scenario_ps_file" e2e_validate_scenario_runtime_isolation nemu-dev >/dev/null 2>&1; then
    printf 'PASS scenario runtime strict guard accepts same-scenario fake process\n'
  else
    printf 'FAIL scenario runtime strict guard rejects same-scenario fake process\n'
    profile_isolation_ok=0
  fi
  printf '%s\n' \
    '321 90000 bash .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/run-login-generators-enabled.sh' \
    > "$scenario_ps_file"
  if AGENT_E2E_SCENARIO_RUNTIME_ISOLATION=warn E2E_SCENARIO_RUNTIME_PS_FILE="$scenario_ps_file" e2e_validate_scenario_runtime_isolation nemu-dev >/dev/null 2>&1; then
    printf 'FAIL scenario runtime guard allows stale conflicting fake process by default\n'
    profile_isolation_ok=0
  else
    printf 'PASS scenario runtime guard rejects stale conflicting fake process by default\n'
  fi
  if AGENT_E2E_SCENARIO_RUNTIME_ISOLATION=warn AGENT_E2E_SCENARIO_RUNTIME_STALE_SECONDS=0 E2E_SCENARIO_RUNTIME_PS_FILE="$scenario_ps_file" e2e_validate_scenario_runtime_isolation nemu-dev >/dev/null 2>&1; then
    printf 'PASS scenario runtime stale guard can be disabled for explicit parallel long-runs\n'
  else
    printf 'FAIL scenario runtime stale guard ignores disable override\n'
    profile_isolation_ok=0
  fi
  rm -f "$scenario_ps_file"
  if [[ $profile_isolation_ok -ne 1 ]]; then
    rc=1
  fi

  echo "[agent-system] tracked persistent agent/e2e sources"
  local untracked_agent_sources
  untracked_agent_sources=$(
    git -C "$E2E_ROOT_DIR" ls-files --others --exclude-standard -- \
      AGENTS.md \
      AI_ENVIRONMENT.md \
      .github/AGENTS.md \
      .github/ai-env \
      .github/agents \
      .github/e2e/README.md \
      .github/e2e/modules \
      .github/e2e/profiles \
      .github/instructions \
      .github/skills \
      .github/workflows \
      .github/ai-env/contracts/agent-env-policy.json \
      .github/ai-env/contracts/agent-env-rebuild-matrix.json \
      .github/ai-env/contracts/agent-env-schema-contract.json \
      .github/ai-env/contracts/agent-env-observability.json \
      .github/ai-env/contracts/agent-env-state-traceability.json \
      .github/ai-env/contracts/agent-env-runtime-artifacts.json \
      .github/ai-env/contracts/agent-env-review-routing.json \
      .github/ai-env/contracts/agent-env-branch-health.json \
      .github/ai-env/contracts/agent-env-delivery.json \
      .github/memory/modules \
      deliverables/ai-dev-env-commercial-v1 \
      scripts/README.md \
      scripts/agent-env.sh \
      scripts/agent-run.sh \
      scripts/agent-maintain.sh \
      scripts/package-ai-dev-env.sh \
      scripts/agent-e2e.sh \
      scripts/e2e/modules 2>/dev/null || true
  )
  if [[ -z $untracked_agent_sources ]]; then
    printf 'PASS persistent agent/e2e source files are tracked\n'
  else
    printf 'FAIL persistent agent/e2e source files are untracked\n%s\n' "$untracked_agent_sources"
    rc=1
  fi

  echo "[agent-system] task-run text artifact sanitizer"
  local report_sh="$E2E_ROOT_DIR/scripts/e2e/lib/report.sh"
  local sanitizer_probe_dir sanitizer_probe_file
  sanitizer_probe_dir="$E2E_EVIDENCE_DIR/agent-system-sanitizer-probe"
  sanitizer_probe_file="$sanitizer_probe_dir/trailing-blank-lines.md"
  if [[ $(grep -Fc 'e2e_sanitize_task_run_text_artifacts' "$report_sh") -ge 2 ]]; then
    printf 'PASS report.sh sanitizer defined and called\n'
  else
    printf 'FAIL report.sh sanitizer defined and called\n'
    rc=1
  fi
  if grep -Fq "LC_ALL=C sed -i 's/[ \\t\\r]*$//'" "$report_sh"; then
    printf 'PASS report.sh strips trailing blanks and CR\n'
  else
    printf 'FAIL report.sh strips trailing blanks and CR\n'
    rc=1
  fi
  if grep -Fq "find \"\$E2E_RUN_DIR\" -type f" "$report_sh"; then
    printf 'PASS report.sh limits sanitizer to current task-run\n'
  else
    printf 'FAIL report.sh limits sanitizer to current task-run\n'
    rc=1
  fi

  mkdir -p "$sanitizer_probe_dir"
  printf 'line  \r\n\n\n' > "$sanitizer_probe_file"
  if (
    E2E_RUN_DIR="$sanitizer_probe_dir"
    e2e_sanitize_task_run_text_artifacts
    cmp -s <(printf 'line\n') "$sanitizer_probe_file"
  ); then
    printf 'PASS report.sh removes trailing blank lines, trailing spaces, and CR\n'
  else
    printf 'FAIL report.sh sanitizer mutation probe retained trailing text noise\n'
    rc=1
  fi
  if grep -Fq '# 任务报告' "$report_sh" &&
     grep -Fq '# 派发日志' "$report_sh" &&
     grep -Fq '# 任务报告' "$E2E_ROOT_DIR/.github/task-runs/templates/task-report.template.md" &&
     grep -Fq '# 派发日志' "$E2E_ROOT_DIR/.github/task-runs/templates/dispatch-log.template.md"; then
    printf 'PASS task-run human-readable report titles are localized in Chinese\n'
  else
    printf 'FAIL task-run human-readable report titles are not localized in Chinese\n'
    rc=1
  fi
  if grep -Fq 'e2e_archive_task_run_markdown_to_db' "$report_sh" &&
     grep -Fq 'archive-markdown "$run_rel"' "$report_sh" &&
     grep -Fq 'E2E_TASK_RUN_DB_BACKUP_DIR' "$report_sh" &&
     grep -Fq 'e2e_validate_task_run_db_archive' "$report_sh"; then
    printf 'PASS report.sh publishes and revalidates task-run Markdown in retained database\n'
  else
    printf 'FAIL report.sh task-run Markdown DB publication/validation hook missing\n'
    rc=1
  fi
  if grep -Fq 'e2e_generate_context_brief' "$report_sh" &&
     grep -Fq 'e2e_context_brief_terms' "$report_sh" &&
     grep -Fq 'e2e_refresh_live_index_for_recall()' "$report_sh" &&
     grep -Fq 'github_index_db.py" rebuild' "$report_sh" &&
     grep -Fq -- '--exclude .github/task-runs' "$report_sh" &&
     grep -Fq -- '--exclude .github/memory' "$report_sh" &&
     grep -Fq -- '--exclude .github/archive' "$report_sh" &&
     grep -Fq -- '--exclude .github/shujuku_aireview' "$report_sh" &&
     grep -Fq 'E2E_LIVE_INDEX_REFRESH_OK' "$report_sh" &&
     grep -Fq 'E2E_CONTEXT_BRIEF_FILE' "$report_sh" &&
     grep -Fq 'github_index_db.py" brief "${brief_terms[@]}"' "$report_sh" &&
     grep -Fq -- '--focus-scope non-history' "$report_sh" &&
     grep -Fq 'e2e_refresh_live_index_for_recall' "$runner_sh" &&
     awk '
       /e2e_refresh_live_index_for_recall/ && refresh == 0 { refresh = NR }
       /e2e_generate_context_brief/ && generate == 0 { generate = NR }
       END { exit !(refresh > 0 && generate > refresh) }
     ' "$runner_sh" &&
     ! grep -Fq 'brief "$E2E_PROFILE" "$E2E_TASK_SLUG"' "$report_sh"; then
    printf 'PASS report.sh refreshes live index before bounded non-history recall\n'
  else
    printf 'FAIL report.sh live-index refresh or context brief contract missing\n'
    rc=1
  fi
  if awk '
      index($0, "github_index_db.py brief") &&
      !index($0, "--focus-scope non-history") { invalid = 1 }
      END { exit invalid }
    ' \
      "$E2E_ROOT_DIR/AGENTS.md" \
      "$E2E_ROOT_DIR/AI_ENVIRONMENT.md" \
      "$E2E_ROOT_DIR/.github/AGENTS.md" \
      "$E2E_ROOT_DIR/.github/copilot-instructions.md" \
      "$E2E_ROOT_DIR/.github/instructions/agent-e2e-workflow.instructions.md" \
      "$E2E_ROOT_DIR/.github/e2e/README.md"; then
    printf 'PASS startup brief commands require non-history primary focus\n'
  else
    printf 'FAIL startup brief command can be self-certified by historical task-runs\n'
    rc=1
  fi
  if grep -Fq 'max_tokens=${E2E_CONTEXT_BRIEF_MAX_TOKENS:-2400}' "$report_sh" &&
     grep -Fq 'brief_cmd.add_argument("--max-tokens", type=int, default=2400)' \
       "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq 'max_tokens = request_int(request, "max_tokens", 2400, 0)' \
       "$E2E_ROOT_DIR/scripts/dev_memory/api.py"; then
    printf 'PASS e2e context brief default matches bounded brief CLI budget\n'
  else
    printf 'FAIL e2e context brief default diverges from bounded brief CLI budget\n'
    rc=1
  fi
  if grep -Fq -- '- `recall_status`: failed' "$report_sh" &&
     grep -Fq 'e2e_generate_context_brief || E2E_OVERALL_RC=1' "$runner_sh" &&
     grep -Fq 'e2e_validate_recall_header context' "$runner_sh" &&
     grep -Fq 'e2e_validate_recall_header()' "$report_sh"; then
    printf 'PASS context brief failure is fail-closed through runner and strict guard\n'
  else
    printf 'FAIL context brief failure can be downgraded or accepted without complete recall\n'
    rc=1
  fi

  local brief_probe_root brief_probe_context brief_probe_resolve brief_probe_rc
  local compound_slug_terms default_slug_terms lifecycle_slug_terms lifecycle_slug_rc
  local controlled_revision_terms lifecycle_revision_terms lifecycle_revision_rc
  local v8_business_terms v2ray_business_terms eight_term_revision_terms
  local malformed_revision_terms malformed_revision_rc
  local node_probe_root
  local render_probe_workspace render_probe_root render_probe_stage render_probe_failed
  compound_slug_terms=$(e2e_context_brief_terms "rv64-q2-v8a-contract-rerun-2")
  default_slug_terms=$(e2e_context_brief_terms "agent-e2e-npc-dev")
  controlled_revision_terms=$(e2e_context_brief_terms "no-tools-rtl-subagent-contract-revtag-v8q")
  v8_business_terms=$(e2e_context_brief_terms "node-javascript-engine-v8")
  v2ray_business_terms=$(e2e_context_brief_terms "network-client-v2ray")
  eight_term_revision_terms=$(e2e_context_brief_terms "one-two-three-four-five-six-seven-eight-revtag-v8q")
  lifecycle_slug_rc=0
  lifecycle_slug_terms=$(e2e_context_brief_terms "agent-e2e-run-rerun-final-2026-2") || lifecycle_slug_rc=$?
  lifecycle_revision_rc=0
  lifecycle_revision_terms=$(e2e_context_brief_terms "agent-e2e-run-revtag-v8q") || lifecycle_revision_rc=$?
  malformed_revision_rc=0
  malformed_revision_terms=$(e2e_context_brief_terms "rtl-contract-revtag-latest") || malformed_revision_rc=$?
  if [[ $compound_slug_terms == $'rv64\nq2\nv8a\ncontract' ]] &&
     [[ $default_slug_terms == $'npc\ndev' ]] &&
     [[ $controlled_revision_terms == $'no\ntools\nrtl\nsubagent\ncontract' ]] &&
     [[ $v8_business_terms == $'node\njavascript\nengine\nv8' ]] &&
     [[ $v2ray_business_terms == $'network\nclient\nv2ray' ]] &&
     [[ $eight_term_revision_terms == $'one\ntwo\nthree\nfour\nfive\nsix\nseven\neight' ]] &&
     [[ $lifecycle_slug_rc -ne 0 && -z $lifecycle_slug_terms ]] &&
     [[ $lifecycle_revision_rc -ne 0 && -z $lifecycle_revision_terms ]] &&
     [[ $malformed_revision_rc -ne 0 && -z $malformed_revision_terms ]]; then
    printf 'PASS context brief term normalization uses explicit revision metadata and preserves business version terms\n'
  else
    printf 'FAIL context brief term normalization accepted identity noise or lost semantic terms\n'
    rc=1
  fi
  brief_probe_root=$(mktemp -d)
  brief_probe_context="$brief_probe_root/run/context-brief.md"
  mkdir -p "$brief_probe_root/scripts" "$brief_probe_root/run"
  printf '%s\n' \
    'import sys' \
    'print("argv: " + " ".join(sys.argv), file=sys.stderr)' \
    'print("intentional brief failure", file=sys.stderr)' \
    'raise SystemExit(9)' \
    > "$brief_probe_root/scripts/github_index_db.py"
  (
    E2E_ROOT_DIR="$brief_probe_root"
    E2E_RUN_DIR="$brief_probe_root/run"
    E2E_CONTEXT_BRIEF_FILE="$brief_probe_context"
    E2E_PROFILE="failure-probe"
    E2E_TASK_SLUG="rv64-q2-v8a-contract-rerun-2"
    unset E2E_CONTEXT_BRIEF_MAX_TOKENS
    e2e_append_dispatch() { return 0; }
    e2e_generate_context_brief
  )
  brief_probe_rc=$?
  if [[ $brief_probe_rc -ne 0 ]] &&
     grep -Fq -- '- `recall_status`: failed' "$brief_probe_context" &&
     grep -Fq -- '--max-tokens 2400' "$brief_probe_context" &&
     grep -Fq -- ' brief rv64 q2 v8a contract --repo-root ' "$brief_probe_context" &&
     grep -Fq -- ' --profile failure-probe --focus-scope non-history --max-tokens 2400' "$brief_probe_context" &&
     ! grep -Fq -- ' brief failure-probe ' "$brief_probe_context" &&
     grep -Fq -- 'intentional brief failure' "$brief_probe_context" &&
     [[ ! -e ${brief_probe_context}.tmp ]]; then
    printf 'PASS failed context recall emits diagnostic marker and nonzero status\n'
  else
    printf 'FAIL failed context recall did not remain fail-closed\n'
    rc=1
  fi
  (
    E2E_ROOT_DIR="$brief_probe_root"
    E2E_RUN_DIR="$brief_probe_root/run"
    E2E_CONTEXT_BRIEF_FILE="$brief_probe_context"
    E2E_PROFILE="failure-probe"
    E2E_TASK_SLUG="failure-probe"
    E2E_CONTEXT_BRIEF_MAX_TOKENS=1800
    e2e_append_dispatch() { return 0; }
    e2e_generate_context_brief
  ) >/dev/null 2>&1
  brief_probe_rc=$?
  if [[ $brief_probe_rc -ne 0 ]] &&
     grep -Fq -- '--max-tokens 1800' "$brief_probe_context"; then
    printf 'PASS explicit context brief budget override reaches the recall CLI\n'
  else
    printf 'FAIL explicit context brief budget override was ignored\n'
    rc=1
  fi
  printf '%s\n' \
    'print("# Wrong Heading\\n\\n- `ok`: true\\n- `recall_status`: complete\\n- `profile`: failure-probe")' \
    > "$brief_probe_root/scripts/github_index_db.py"
  (
    E2E_ROOT_DIR="$brief_probe_root"
    E2E_RUN_DIR="$brief_probe_root/run"
    E2E_CONTEXT_BRIEF_FILE="$brief_probe_context"
    E2E_PROFILE="failure-probe"
    E2E_TASK_SLUG="failure-probe"
    unset E2E_CONTEXT_BRIEF_MAX_TOKENS
    e2e_append_dispatch() { return 0; }
    e2e_generate_context_brief
  ) >/dev/null 2>&1
  brief_probe_rc=$?
  if [[ $brief_probe_rc -ne 0 ]] &&
     grep -Fq -- '- `recall_status`: failed' "$brief_probe_context"; then
    printf 'PASS context generator rejects success fields under a noncanonical heading\n'
  else
    printf 'FAIL context generator accepted a noncanonical success heading\n'
    rc=1
  fi
  rm -f -- "$brief_probe_context"
  mkdir -p "$brief_probe_context"
  printf '%s\n' \
    'print("# Agent Brief\\n\\n- `ok`: true\\n- `recall_status`: complete\\n- `profile`: failure-probe")' \
    > "$brief_probe_root/scripts/github_index_db.py"
  (
    E2E_ROOT_DIR="$brief_probe_root"
    E2E_RUN_DIR="$brief_probe_root/run"
    E2E_CONTEXT_BRIEF_FILE="$brief_probe_context"
    E2E_PROFILE="failure-probe"
    E2E_TASK_SLUG="failure-probe"
    unset E2E_CONTEXT_BRIEF_MAX_TOKENS
    e2e_append_dispatch() { return 0; }
    e2e_generate_context_brief
  ) >/dev/null 2>&1
  brief_probe_rc=$?
  if [[ $brief_probe_rc -ne 0 && -d $brief_probe_context ]] &&
     [[ ! -e ${brief_probe_context}.tmp ]] &&
     [[ ! -e $brief_probe_context/context-brief.md.tmp ]]; then
    printf 'PASS context recall rejects a directory destination without nested move\n'
  else
    printf 'FAIL context recall accepted or nested-moved into a directory destination\n'
    rc=1
  fi
  brief_probe_resolve="$brief_probe_root/run/profile-resolve.md"
  printf '%s\n' \
    'print("# E2E Resolved Profile\\n\\n## Diagnostic\\n\\n```text\\n- `profile`: failure-probe\\n- `ok`: True\\n```")' \
    > "$brief_probe_root/scripts/github_index_db.py"
  (
    E2E_ROOT_DIR="$brief_probe_root"
    E2E_RUN_DIR="$brief_probe_root/run"
    E2E_PROFILE_RESOLVE_FILE="$brief_probe_resolve"
    E2E_PROFILE="failure-probe"
    e2e_append_dispatch() { return 0; }
    e2e_generate_profile_resolve
  ) >/dev/null 2>&1
  brief_probe_rc=$?
  if [[ $brief_probe_rc -ne 0 ]] &&
     grep -Fq -- '- `ok`: False' "$brief_probe_resolve" &&
     [[ ! -e ${brief_probe_resolve}.tmp ]]; then
    printf 'PASS invalid profile resolve output emits failure marker and nonzero status\n'
  else
    printf 'FAIL invalid profile resolve output was accepted or left stale temp state\n'
    rc=1
  fi
  printf '%s\n' \
    '# E2E Resolved Profile' \
    '' \
    '- `profile`: failure-probe' \
    '- `ok`: True' \
    > "$brief_probe_resolve"
  (
    E2E_ROOT_DIR="$brief_probe_root"
    E2E_RUN_DIR="$brief_probe_root/run"
    E2E_PROFILE_RESOLVE_FILE="$brief_probe_resolve"
    E2E_PROFILE="failure-probe"
    E2E_GENERATE_PROFILE_RESOLVE=0
    e2e_append_dispatch() { return 0; }
    e2e_generate_profile_resolve
  ) >/dev/null 2>&1
  brief_probe_rc=$?
  if [[ $brief_probe_rc -ne 0 ]] &&
     grep -Fq -- '- `ok`: False' "$brief_probe_resolve" &&
     ! grep -Fq -- '- `ok`: True' "$brief_probe_resolve"; then
    printf 'PASS disabled profile resolve invalidates old success and returns nonzero\n'
  else
    printf 'FAIL disabled profile resolve reused an old success artifact\n'
    rc=1
  fi
  rm -rf -- "$brief_probe_root"

  node_probe_root=$(mktemp -d)
  mkdir -p "$node_probe_root/evidence"
  if (
    E2E_ROOT_DIR="$node_probe_root"
    E2E_EVIDENCE_DIR="$node_probe_root/evidence"
    E2E_OVERALL_RC=0
    E2E_KEEP_GOING=1
    probe_gate() { return 0; }
    e2e_append_dispatch() { return 0; }
    e2e_record_node() { return 41; }
    e2e_run_function_node function-record owner module probe_gate inputs outputs
    node_probe_rc=$?
    [[ $node_probe_rc -ne 0 && $E2E_OVERALL_RC -eq 1 ]]
  ); then
    printf 'PASS function node propagates PASS record failure\n'
  else
    printf 'FAIL function node masked PASS record failure\n'
    rc=1
  fi
  if (
    E2E_ROOT_DIR="$node_probe_root"
    E2E_EVIDENCE_DIR="$node_probe_root/evidence"
    E2E_OVERALL_RC=0
    E2E_KEEP_GOING=1
    probe_gate() { return 0; }
    e2e_append_dispatch() { return 42; }
    e2e_record_node() { return 0; }
    e2e_run_function_node function-dispatch owner module probe_gate inputs outputs
    node_probe_rc=$?
    [[ $node_probe_rc -ne 0 && $E2E_OVERALL_RC -eq 1 ]]
  ); then
    printf 'PASS function node propagates dispatch write failure\n'
  else
    printf 'FAIL function node masked dispatch write failure\n'
    rc=1
  fi
  if (
    E2E_ROOT_DIR="$node_probe_root"
    E2E_EVIDENCE_DIR="$node_probe_root/evidence"
    E2E_OVERALL_RC=0
    E2E_KEEP_GOING=1
    e2e_append_dispatch() { return 0; }
    e2e_record_node() { return 41; }
    e2e_run_shell_node shell-record owner module inputs outputs true
    node_probe_rc=$?
    [[ $node_probe_rc -ne 0 && $E2E_OVERALL_RC -eq 1 ]]
  ); then
    printf 'PASS shell node propagates PASS record failure\n'
  else
    printf 'FAIL shell node masked PASS record failure\n'
    rc=1
  fi
  mkdir -p "$node_probe_root/evidence/shell-cmd.cmd"
  if (
    E2E_ROOT_DIR="$node_probe_root"
    E2E_EVIDENCE_DIR="$node_probe_root/evidence"
    E2E_OVERALL_RC=0
    E2E_KEEP_GOING=1
    e2e_append_dispatch() { return 0; }
    e2e_record_node() { return 0; }
    e2e_run_shell_node shell-cmd owner module inputs outputs true
    node_probe_rc=$?
    [[ $node_probe_rc -ne 0 && $E2E_OVERALL_RC -eq 1 ]]
  ); then
    printf 'PASS shell node propagates command artifact write failure\n'
  else
    printf 'FAIL shell node masked command artifact write failure\n'
    rc=1
  fi
  rm -rf -- "$node_probe_root"

  render_probe_workspace=$(mktemp -d)
  render_probe_root="$render_probe_workspace/.github/task-runs/probe"
  mkdir -p "$render_probe_root/evidence"
  : > "$render_probe_root/nodes.tsv"
  if (
    find() { return 42; }
    E2E_ROOT_DIR="$render_probe_workspace"
    E2E_RUN_DIR="$render_probe_root"
    e2e_sanitize_task_run_text_artifacts
  ) >/dev/null 2>&1; then
    printf 'FAIL sanitizer masked find enumeration failure\n'
    rc=1
  else
    printf 'PASS sanitizer propagates find enumeration failure\n'
  fi
  : > "$render_probe_root/nodes-target.tsv"
  ln -s "$render_probe_root/nodes-target.tsv" "$render_probe_root/nodes-link.tsv"
  if (
    E2E_NODES_FILE="$render_probe_root/missing-nodes.tsv"
    e2e_render_report
  ) >/dev/null 2>&1 || (
    E2E_NODES_FILE="$render_probe_root/nodes-link.tsv"
    e2e_render_report
  ) >/dev/null 2>&1; then
    printf 'FAIL report renderer accepted missing or symlink nodes input\n'
    rc=1
  else
    printf 'PASS report renderer rejects missing and symlink nodes input\n'
  fi
  mkdir -p "$render_probe_workspace/.github/task-runs/symlink-target"
  ln -s "$render_probe_workspace/.github/task-runs/symlink-target" \
    "$render_probe_workspace/.github/task-runs/symlink-run"
  if (
    E2E_ROOT_DIR="$render_probe_workspace"
    E2E_RUN_DIR="$render_probe_workspace/.github/task-runs/symlink-run"
    E2E_TASK_SLUG="failure-probe"
    e2e_allocate_run_dir
  ) >/dev/null 2>&1 || (
    E2E_ROOT_DIR="$render_probe_workspace"
    E2E_RUN_DIR="$render_probe_workspace/.github/task-runs/symlink-run"
    e2e_sanitize_task_run_text_artifacts
  ) >/dev/null 2>&1; then
    printf 'FAIL allocation or sanitizer accepted a symlink run directory\n'
    rc=1
  else
    printf 'PASS allocation and sanitizer reject symlink run directories\n'
  fi
  mkdir -p \
    "$render_probe_workspace/.github/task-runs/preexisting-run" \
    "$render_probe_workspace/.github/task-runs/preexisting-target"
  ln -s "$render_probe_workspace/.github/task-runs/preexisting-target" \
    "$render_probe_workspace/.github/task-runs/preexisting-run/nodes.tsv"
  if (
    E2E_ROOT_DIR="$render_probe_workspace"
    E2E_RUN_DIR="$render_probe_workspace/.github/task-runs/preexisting-run"
    E2E_TASK_SLUG="failure-probe"
    e2e_allocate_run_dir
  ) >/dev/null 2>&1; then
    printf 'FAIL allocation accepted a nonempty run directory with an internal artifact symlink\n'
    rc=1
  else
    printf 'PASS allocation requires a fresh empty run directory and rejects internal artifact symlinks\n'
  fi
  render_probe_failed=0
  for render_probe_stage in manifest sanitize index archive; do
    if (
      E2E_ROOT_DIR="$render_probe_workspace"
      E2E_RUN_DIR="$render_probe_root"
      E2E_EVIDENCE_DIR="$render_probe_root/evidence"
      E2E_REPORT_FILE="$render_probe_root/task-report.md"
      E2E_DISPATCH_FILE="$render_probe_root/dispatch-log.md"
      E2E_CONTEXT_BRIEF_FILE="$render_probe_root/context-brief.md"
      E2E_PROFILE_RESOLVE_FILE="$render_probe_root/profile-resolve.md"
      E2E_EVIDENCE_INDEX_FILE="$render_probe_root/evidence-index.md"
      E2E_RUN_MANIFEST_FILE="$render_probe_root/run-manifest.json"
      E2E_NODES_FILE="$render_probe_root/nodes.tsv"
      E2E_PROFILE="failure-probe"
      E2E_TASK_SLUG="failure-probe"
      E2E_STARTED_AT="2000-01-01 00:00:00 +0000"
      E2E_OVERALL_RC=0
      E2E_SKIP_COUNT=0
      e2e_render_run_manifest() { [[ $render_probe_stage != manifest ]]; }
      e2e_sanitize_task_run_text_artifacts() { [[ $render_probe_stage != sanitize ]]; }
      e2e_index_task_run_evidence_assets() { [[ $render_probe_stage != index ]]; }
      e2e_archive_task_run_markdown_to_db() { [[ $render_probe_stage != archive ]]; }
      e2e_render_report
    ); then
      printf 'FAIL report finalization masked %s failure\n' "$render_probe_stage"
      render_probe_failed=1
    fi
  done
  if [[ $render_probe_failed -eq 0 ]]; then
    printf 'PASS report finalization preserves every stage failure status\n'
  else
    rc=1
  fi
  local render_publish_probe="$render_probe_root/publish-called"
  if (
    E2E_ROOT_DIR="$render_probe_workspace"
    E2E_RUN_DIR="$render_probe_root"
    E2E_EVIDENCE_DIR="$render_probe_root/evidence"
    E2E_REPORT_FILE="$render_probe_root/task-report.md"
    E2E_DISPATCH_FILE="$render_probe_root/dispatch-log.md"
    E2E_CONTEXT_BRIEF_FILE="$render_probe_root/context-brief.md"
    E2E_PROFILE_RESOLVE_FILE="$render_probe_root/profile-resolve.md"
    E2E_EVIDENCE_INDEX_FILE="$render_probe_root/evidence-index.md"
    E2E_RUN_MANIFEST_FILE="$render_probe_root/run-manifest.json"
    E2E_COMPLETE_MARKER_FILE="$render_probe_root/complete.marker"
    E2E_NODES_FILE="$render_probe_root/nodes.tsv"
    E2E_PROFILE="failure-probe"
    E2E_TASK_SLUG="failure-probe"
    E2E_STARTED_AT="2000-01-01 00:00:00 +0000"
    E2E_OVERALL_RC=0
    E2E_SKIP_COUNT=0
    e2e_render_run_manifest() { return 0; }
    e2e_sanitize_task_run_text_artifacts() { return 0; }
    e2e_index_task_run_evidence_assets() { return 0; }
    e2e_validate_evidence_index() { return 0; }
    e2e_validate_recall_header() { return 0; }
    e2e_validate_task_run_bundle() { return 0; }
    e2e_write_completion_marker_for_dir() { return 88; }
    e2e_archive_task_run_markdown_to_db() { : > "$render_publish_probe"; }
    e2e_validate_task_run_db_archive() { return 0; }
    e2e_render_report
  ) >/dev/null 2>&1 || [[ ! -e $render_publish_probe ]]; then
    if [[ -e $render_publish_probe ]]; then
      printf 'FAIL report finalization published completed DB state after marker preparation failed\n'
      rc=1
    else
      printf 'PASS marker preparation failure prevents completed DB publication\n'
    fi
  else
    printf 'FAIL report finalization accepted marker preparation failure\n'
    rc=1
  fi
  rm -f -- "$render_publish_probe"
  if (
    E2E_ROOT_DIR="$render_probe_workspace"
    E2E_RUN_DIR="$render_probe_root"
    E2E_EVIDENCE_DIR="$render_probe_root/evidence"
    E2E_REPORT_FILE="$render_probe_root/task-report.md"
    E2E_DISPATCH_FILE="$render_probe_root/dispatch-log.md"
    E2E_CONTEXT_BRIEF_FILE="$render_probe_root/context-brief.md"
    E2E_PROFILE_RESOLVE_FILE="$render_probe_root/profile-resolve.md"
    E2E_EVIDENCE_INDEX_FILE="$render_probe_root/evidence-index.md"
    E2E_RUN_MANIFEST_FILE="$render_probe_root/run-manifest.json"
    E2E_COMPLETE_MARKER_FILE="$render_probe_root/complete.marker"
    E2E_NODES_FILE="$render_probe_root/nodes.tsv"
    E2E_PROFILE="failure-probe"
    E2E_TASK_SLUG="failure-probe"
    E2E_STARTED_AT="2000-01-01 00:00:00 +0000"
    E2E_OVERALL_RC=0
    E2E_SKIP_COUNT=0
    e2e_render_run_manifest() { return 0; }
    e2e_sanitize_task_run_text_artifacts() { return 0; }
    e2e_index_task_run_evidence_assets() { return 0; }
    e2e_validate_evidence_index() { return 0; }
    e2e_validate_recall_header() { return 0; }
    e2e_validate_task_run_bundle() { return 0; }
    e2e_write_completion_marker_for_dir() { : > "$E2E_COMPLETE_MARKER_FILE"; }
    e2e_archive_task_run_markdown_to_db() { return 89; }
    e2e_validate_task_run_db_archive() { return 0; }
    e2e_render_report
  ) >/dev/null 2>&1; then
    printf 'FAIL report finalization accepted completed DB publication failure\n'
    rc=1
  elif [[ -e $render_probe_root/complete.marker ]]; then
    printf 'FAIL report finalization retained prepared marker after DB publication failure\n'
    rc=1
  else
    printf 'PASS DB publication failure removes prepared completion marker\n'
  fi
  rm -rf -- "$render_probe_workspace"
  if grep -Fq 'e2e_generate_profile_resolve' "$report_sh" &&
     grep -Fq 'E2E_PROFILE_RESOLVE_FILE' "$report_sh" &&
     grep -Fq 'github_index_db.py" resolve-profile' "$report_sh" &&
     grep -Fq 'e2e_generate_profile_resolve || E2E_OVERALL_RC=1' "$runner_sh" &&
     grep -Fq 'if ! e2e_render_report; then' "$runner_sh"; then
    printf 'PASS profile resolve and report finalization failures propagate to overall status\n'
  else
    printf 'FAIL profile resolve or report finalization failure propagation is missing\n'
    rc=1
  fi
  return "$rc"
}

e2e_agent_system_three_layer_contract() {
  echo "[agent-system] three-layer AI environment contract"
  local rc=0
  local layer_doc=".github/instructions/agent-env-layer-contract.instructions.md"
  local nav_doc="AI_ENVIRONMENT.md"
  local policy_doc=".github/ai-env/contracts/agent-env-policy.json"
  local matrix_doc=".github/ai-env/contracts/agent-env-rebuild-matrix.json"
  local schema_doc=".github/ai-env/contracts/agent-env-schema-contract.json"
  local observability_doc=".github/ai-env/contracts/agent-env-observability.json"
  local state_trace_doc=".github/ai-env/contracts/agent-env-state-traceability.json"
  local artifact_doc=".github/ai-env/contracts/agent-env-runtime-artifacts.json"
  local review_doc=".github/ai-env/contracts/agent-env-review-routing.json"
  local branch_doc=".github/ai-env/contracts/agent-env-branch-health.json"
  local delivery_doc=".github/ai-env/contracts/agent-env-delivery.json"
  local rtl_task_doc=".github/ai-env/contracts/agent-env-rtl-task-contract.json"
  local state_doc=".github/instructions/agent-env-state-machine.instructions.md"
  local skill_doc=".github/skills/agent-env-maintenance/SKILL.md"
  local rtl_task_skill=".github/skills/prepare-rtl-task-contract/SKILL.md"
  local workflow_yml=".github/workflows/agent-maintain.yml"
  local maintain_sh="scripts/agent-maintain.sh"

  e2e_print_required_files \
    "$nav_doc" \
    "$layer_doc" \
    "$policy_doc" \
    "$matrix_doc" \
    "$schema_doc" \
    "$observability_doc" \
    "$state_trace_doc" \
    "$artifact_doc" \
    "$review_doc" \
    "$branch_doc" \
    "$delivery_doc" \
    "$rtl_task_doc" \
    "$state_doc" \
    "$skill_doc" \
    "$rtl_task_skill" \
    "$workflow_yml" \
    "$maintain_sh" || rc=1

  if e2e_file_contains "$layer_doc" 'Database = 长期记忆层' &&
     e2e_file_contains "$layer_doc" 'Skill = 标准化处理规则层' &&
     e2e_file_contains "$layer_doc" 'Agent = 自动维护流程层' &&
     e2e_file_contains "$layer_doc" 'scripts/agent-maintain.sh --mode check'; then
    printf 'PASS layer contract documents Database/Skill/Agent boundaries\n'
  else
    printf 'FAIL layer contract missing Database/Skill/Agent boundaries\n'
    rc=1
  fi

  if e2e_file_contains "$nav_doc" '日常开工（最短路径）' &&
     e2e_file_contains "$nav_doc" '单一真源与内容去向' &&
     e2e_file_contains "$nav_doc" '使用中迭代' &&
     e2e_file_contains "$nav_doc" '.github/ai-env/contracts/' &&
     ! grep -Fq '.github/agent-env-' "$layer_doc"; then
    printf 'PASS one-page navigation and canonical contract paths are explicit\n'
  else
    printf 'FAIL one-page navigation missing or layer contract still references compatibility shims\n'
    rc=1
  fi

  if e2e_file_contains "$policy_doc" '"agent_tools"' &&
     e2e_file_contains "$policy_doc" '"allowed_tools"' &&
     e2e_file_contains "$policy_doc" '"retention"' &&
     e2e_file_contains "$policy_doc" '"raw_evidence_policy": "index-only"' &&
     e2e_file_contains "$policy_doc" '"traceability"' &&
     e2e_file_contains "$policy_doc" '"schema_contract": ".github/ai-env/contracts/agent-env-schema-contract.json"' &&
     e2e_file_contains "$policy_doc" '"observability_contract": ".github/ai-env/contracts/agent-env-observability.json"' &&
     e2e_file_contains "$policy_doc" '"state_traceability_contract": ".github/ai-env/contracts/agent-env-state-traceability.json"' &&
     e2e_file_contains "$policy_doc" '"runtime_artifact_contract": ".github/ai-env/contracts/agent-env-runtime-artifacts.json"' &&
     e2e_file_contains "$policy_doc" '"delivery_contract": ".github/ai-env/contracts/agent-env-delivery.json"' &&
     e2e_file_contains "$policy_doc" '"rtl_task_contract": ".github/ai-env/contracts/agent-env-rtl-task-contract.json"' &&
     e2e_file_contains "$policy_doc" '"task_delegation"' &&
     e2e_file_contains "$policy_doc" '"contract_before_dispatch_required": true' &&
     e2e_file_contains "$policy_doc" '"trace_id_required": true' &&
     e2e_file_contains "$policy_doc" '"run_manifest_required": true' &&
     e2e_file_contains "$policy_doc" '"traceback_required": true' &&
     e2e_file_contains "$policy_doc" '"runtime_artifacts"' &&
     e2e_file_contains "$policy_doc" '"artifact_store_root": ".github/runtime-artifacts"' &&
     e2e_file_contains "$policy_doc" '"review_routing": ".github/ai-env/contracts/agent-env-review-routing.json"' &&
     e2e_file_contains "$policy_doc" '"branch_health_dashboard": ".github/ai-env/contracts/agent-env-branch-health.json"' &&
     e2e_file_contains "$policy_doc" '"state_machine"' &&
     e2e_file_contains "$policy_doc" '"branch_health"' &&
     e2e_file_contains "$policy_doc" '"delivery"' &&
     e2e_file_contains "$policy_doc" '"package_script": "scripts/package-ai-dev-env.sh"' &&
     e2e_file_contains "$policy_doc" '"required_workflow": ".github/workflows/agent-maintain.yml"' &&
     e2e_file_contains "$policy_doc" '"nightly_required": true'; then
    printf 'PASS agent environment policy captures tools, retention, delivery, branch health, and CI contract\n'
  else
    printf 'FAIL agent environment policy missing tools, retention, delivery, branch health, or CI contract\n'
    rc=1
  fi

  if e2e_file_contains "$state_trace_doc" '"audit_command": "python3 scripts/github_index_db.py state-audit"' &&
     e2e_file_contains "$state_trace_doc" '"required_traceback_fields"' &&
     e2e_file_contains "$state_trace_doc" '"state-machine-traceback"' &&
     e2e_file_contains "$state_trace_doc" '"reviewer-inspector-gate"' &&
     e2e_file_contains "$state_trace_doc" '"required_run_manifest_field": "state_traceback"'; then
    printf 'PASS state traceability contract defines traceback fields and reviewer/inspector nodes\n'
  else
    printf 'FAIL state traceability contract missing traceback fields or reviewer/inspector nodes\n'
    rc=1
  fi

  if e2e_file_contains "$observability_doc" '"trace_id_format": "e2e:<run_id>"' &&
     e2e_file_contains "$observability_doc" '"run_manifest_path": ".github/task-runs/<run_id>/run-manifest.json"' &&
     e2e_file_contains "$observability_doc" '"required_manifest_fields"' &&
     e2e_file_contains "$observability_doc" '"database_mapping"' &&
     e2e_file_contains "$observability_doc" '"runtime_artifact_contract": ".github/ai-env/contracts/agent-env-runtime-artifacts.json"' &&
     e2e_file_contains "$observability_doc" '"run_manifest_index"'; then
    printf 'PASS observability contract defines trace id, run manifest, and DB mapping\n'
  else
    printf 'FAIL observability contract missing trace id, run manifest, or DB mapping\n'
    rc=1
  fi

  if e2e_file_contains "$schema_doc" '"runtime_schema_version": "4"' &&
     e2e_file_contains "$schema_doc" '"tables"' &&
     e2e_file_contains "$schema_doc" '"db_documents"' &&
     e2e_file_contains "$schema_doc" '"evidence_assets"' &&
     e2e_file_contains "$schema_doc" '"runtime_artifacts"' &&
     e2e_file_contains "$schema_doc" '"runtime_artifact_contract": ".github/ai-env/contracts/agent-env-runtime-artifacts.json"' &&
     e2e_file_contains "$schema_doc" '"required_operations"' &&
     e2e_file_contains "$schema_doc" '"resolve-profile"'; then
    printf 'PASS explicit schema/API contract covers DB tables and read-only API operations\n'
  else
    printf 'FAIL explicit schema/API contract missing DB tables or API operations\n'
    rc=1
  fi

  if e2e_file_contains "$matrix_doc" '"source_report"' &&
     e2e_file_contains "$matrix_doc" '"requirements"' &&
     e2e_file_contains "$matrix_doc" '"R1"' &&
     e2e_file_contains "$matrix_doc" '"R9"' &&
     e2e_file_contains "$matrix_doc" 'branch-health-report' &&
     e2e_file_contains "$matrix_doc" 'artifact-audit' &&
     e2e_file_contains "$matrix_doc" '"implemented"' &&
     ! e2e_file_contains "$matrix_doc" '"partial"' &&
     ! e2e_file_contains "$matrix_doc" '"planned"'; then
    printf 'PASS report-derived rebuild matrix tracks all implemented requirements\n'
  else
    printf 'FAIL report-derived rebuild matrix missing required tracking fields\n'
    rc=1
  fi

  if e2e_file_contains "$artifact_doc" '"audit_command": "python3 scripts/github_index_db.py artifact-audit"' &&
     e2e_file_contains "$artifact_doc" '"local_root": ".github/runtime-artifacts"' &&
     e2e_file_contains "$artifact_doc" '"raw_evidence_index_table": "evidence_assets"' &&
     e2e_file_contains "$artifact_doc" '"large_artifacts_externalized": true' &&
     e2e_file_contains "$artifact_doc" '"waveform_artifacts_externalized": true' &&
     e2e_file_contains "$artifact_doc" '"runtime-artifact-boundary"'; then
    printf 'PASS runtime artifact contract defines source/runtime retention boundary\n'
  else
    printf 'FAIL runtime artifact contract missing source/runtime boundary fields\n'
    rc=1
  fi

  if e2e_file_contains "$review_doc" '"review_routes"' &&
     e2e_file_contains "$review_doc" '"database-layer"' &&
     e2e_file_contains "$review_doc" '"skill-layer"' &&
     e2e_file_contains "$review_doc" '"agent-layer"' &&
     e2e_file_contains "$review_doc" '"requirement_routes"' &&
     e2e_file_contains "$review_doc" '"R9": "agent-layer"' &&
     e2e_file_contains "$review_doc" '"state-audit"'; then
    printf 'PASS review routing contract covers Database/Skill/Agent and R1-R9 routes\n'
  else
    printf 'FAIL review routing contract missing layer or requirement routes\n'
    rc=1
  fi

  if e2e_file_contains "$branch_doc" '"report_command": "python3 scripts/github_index_db.py branch-health-report"' &&
     e2e_file_contains "$branch_doc" '"audit_command": "python3 scripts/github_index_db.py branch-health-audit"' &&
     e2e_file_contains "$branch_doc" '"current_branch"' &&
     e2e_file_contains "$branch_doc" '"git_status_counts"' &&
     e2e_file_contains "$branch_doc" '"maintenance_gates"' &&
     e2e_file_contains "$branch_doc" '"delivery-audit"'; then
    printf 'PASS branch health dashboard contract exposes required signals and commands\n'
  else
    printf 'FAIL branch health dashboard contract missing signals or commands\n'
    rc=1
  fi

  if e2e_file_contains "$delivery_doc" '"audit_command": "python3 scripts/github_index_db.py delivery-audit"' &&
     e2e_file_contains "$delivery_doc" '"delivery_root": "deliverables/ai-dev-env-commercial-v1"' &&
     e2e_file_contains "$delivery_doc" '"package_root": "dist/ai-dev-env-commercial-v1/package/ysyx-ai-dev-env-commercial"' &&
     e2e_file_contains "$delivery_doc" '"archive_root": ".github/archive/legacy-ai-dev-env-2026-06-13"' &&
     e2e_file_contains "$delivery_doc" '"active_legacy_roots_must_be_absent"' &&
     e2e_file_contains "$delivery_doc" '"required_package_paths"'; then
    printf 'PASS delivery contract defines archive, package, and active legacy boundaries\n'
  else
    printf 'FAIL delivery contract missing archive, package, or legacy boundaries\n'
    rc=1
  fi

  if e2e_file_contains "$state_doc" 'recall_context' &&
     e2e_file_contains "$state_doc" 'state traceback' &&
     e2e_file_contains "$state_doc" 'state_traceback' &&
     e2e_file_contains "$state_doc" 'state-machine-traceback' &&
     e2e_file_contains "$state_doc" 'reviewer-inspector-gate' &&
     e2e_file_contains "$state_doc" 'Reviewer / Inspector' &&
     e2e_file_contains "$state_doc" 'agent-system' &&
     e2e_file_contains "$state_doc" '不能把弱证据写成完成'; then
    printf 'PASS state machine instruction captures rollback and inspector rules\n'
  else
    printf 'FAIL state machine instruction missing rollback or inspector rules\n'
    rc=1
  fi

  if e2e_file_contains "$skill_doc" 'name: agent-env-maintenance' &&
     e2e_file_contains "$skill_doc" '数据库层' &&
     e2e_file_contains "$skill_doc" 'Skill 层' &&
     e2e_file_contains "$skill_doc" 'Agent 层' &&
     e2e_file_contains "$rtl_task_skill" 'name: prepare-rtl-task-contract' &&
     e2e_file_contains "$rtl_task_skill" 'rtl_task_contract.py self-test'; then
    printf 'PASS live skills expose three-layer maintenance and RTL task delegation workflows\n'
  else
    printf 'FAIL live skills missing three-layer or RTL task delegation workflow\n'
    rc=1
  fi

  if grep -Fq 'report-audit' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'schema-audit' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'artifact-audit' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'package-ai-dev-env.sh' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'delivery-audit' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'trace-audit' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'state-audit' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'policy-audit' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'skill-audit' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'rtl_task_contract.py audit' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'rtl_task_contract.py self-test' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'branch-health-report' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'branch-health-audit' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'audit-db-first' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'audit-markdown-coverage --fail-on-live-evidence' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq -- '--validate-all-profiles' "$E2E_ROOT_DIR/$maintain_sh"; then
    printf 'PASS agent-maintain check covers policy, DB, Skill, markdown, and Agent profile gates\n'
  else
    printf 'FAIL agent-maintain check missing required gates\n'
    rc=1
  fi

  if grep -Fq 'rehydrate --backup-dir .github/db-backup/stored-snapshot --yes' "$E2E_ROOT_DIR/$workflow_yml" &&
     grep -Fq 'rehydrate --backup-dir .github/db-backup/task-runs --yes' "$E2E_ROOT_DIR/$workflow_yml" &&
     grep -Fq 'scripts/agent-maintain.sh --mode check' "$E2E_ROOT_DIR/$workflow_yml" &&
     grep -Fq 'scripts/agent-e2e.sh --validate-all-profiles' "$E2E_ROOT_DIR/$workflow_yml" &&
     grep -Fq 'python3 scripts/github_index_db.py delivery-audit' "$E2E_ROOT_DIR/$workflow_yml" &&
     grep -Fq 'schedule:' "$E2E_ROOT_DIR/$workflow_yml"; then
    printf 'PASS agent-maintain workflow rehydrates DB memory and runs nightly gate\n'
  else
    printf 'FAIL agent-maintain workflow missing DB rehydrate or nightly gate\n'
    rc=1
  fi

  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" report-audit || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" schema-audit || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" artifact-audit || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" delivery-audit || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" trace-audit || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" state-audit || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" policy-audit || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" skill-audit || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" branch-health-report || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" branch-health-audit || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" audit-markdown-coverage --fail-on-live-evidence || rc=1
  return "$rc"
}

e2e_agent_system_runtime_artifact_boundary() {
  echo "[agent-system] runtime artifact boundary"
  local rc=0
  local artifact_doc=".github/ai-env/contracts/agent-env-runtime-artifacts.json"
  local policy_doc=".github/ai-env/contracts/agent-env-policy.json"
  local schema_doc=".github/ai-env/contracts/agent-env-schema-contract.json"
  local observability_doc=".github/ai-env/contracts/agent-env-observability.json"
  local report_sh="scripts/e2e/lib/report.sh"
  local maintain_sh="scripts/agent-maintain.sh"
  local profile_doc=".github/e2e/profiles/agent-system.tsv"

  e2e_print_required_files \
    "$artifact_doc" \
    "$policy_doc" \
    "$schema_doc" \
    "$observability_doc" \
    "$report_sh" \
    "$maintain_sh" \
    "$profile_doc" || rc=1

  if e2e_file_contains "$artifact_doc" '"runtime_payload_roots"' &&
     e2e_file_contains "$artifact_doc" '".github/task-runs/*/evidence"' &&
     e2e_file_contains "$artifact_doc" '".github/runtime-artifacts"' &&
     e2e_file_contains "$artifact_doc" '"raw_evidence_fulltext_in_db": false' &&
     e2e_file_contains "$artifact_doc" '"raw_evidence_index_required": true' &&
     e2e_file_contains "$artifact_doc" '"max_tracked_evidence_bytes": 1048576'; then
    printf 'PASS runtime artifact contract declares payload roots and retention limits\n'
  else
    printf 'FAIL runtime artifact contract missing payload roots or retention limits\n'
    rc=1
  fi

  if grep -Fq '.github/runtime-artifacts/**' "$E2E_ROOT_DIR/.gitignore" &&
     grep -Fq '!.github/runtime-artifacts/.gitkeep' "$E2E_ROOT_DIR/.gitignore" &&
     grep -Fq '.github/task-runs/**/evidence/*.vcd' "$E2E_ROOT_DIR/.gitignore" &&
     grep -Fq '.github/task-runs/**/evidence/*.raw' "$E2E_ROOT_DIR/.gitignore"; then
    printf 'PASS .gitignore keeps runtime artifact store and heavy evidence out of source\n'
  else
    printf 'FAIL .gitignore missing runtime artifact store or heavy evidence patterns\n'
    rc=1
  fi

  if grep -Fq 'e2e_index_task_run_evidence_assets' "$E2E_ROOT_DIR/$report_sh" &&
     grep -Fq 'raw_evidence_index_only' "$E2E_ROOT_DIR/$report_sh" &&
     grep -Fq 'run-manifest.json' "$E2E_ROOT_DIR/$report_sh" &&
     grep -Fq 'archive-markdown' "$E2E_ROOT_DIR/$report_sh"; then
    printf 'PASS report.sh emits manifest pointers and DB evidence asset indexes\n'
  else
    printf 'FAIL report.sh missing runtime artifact indexing hooks\n'
    rc=1
  fi

  if e2e_file_contains "$profile_doc" 'runtime-artifact-boundary|agent-system|e2e_agent_system_runtime_artifact_boundary|agent-system|' &&
     grep -Fq 'artifact-audit' "$E2E_ROOT_DIR/$maintain_sh"; then
    printf 'PASS agent-system profile and maintenance gate execute artifact-audit\n'
  else
    printf 'FAIL agent-system profile or maintenance gate missing runtime artifact audit\n'
    rc=1
  fi

  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" artifact-audit || rc=1
  return "$rc"
}

e2e_agent_system_state_traceback() {
  echo "[agent-system] state machine traceback"
  local rc=0
  local state_doc=".github/instructions/agent-env-state-machine.instructions.md"
  local state_trace_doc=".github/ai-env/contracts/agent-env-state-traceability.json"
  local report_sh="scripts/e2e/lib/report.sh"

  e2e_print_required_files \
    "$state_doc" \
    "$state_trace_doc" \
    "$report_sh" || rc=1

  if e2e_file_contains "$state_doc" 'recall_context' &&
     e2e_file_contains "$state_doc" 'classify_layer' &&
     e2e_file_contains "$state_doc" 'plan_graph' &&
     e2e_file_contains "$state_doc" 'implement' &&
     e2e_file_contains "$state_doc" 'verify' &&
     e2e_file_contains "$state_doc" 'inspect' &&
     e2e_file_contains "$state_doc" 'persist' &&
     e2e_file_contains "$state_doc" 'state_traceback'; then
    printf 'PASS state machine instruction covers executable states and state_traceback\n'
  else
    printf 'FAIL state machine instruction missing executable states or state_traceback\n'
    rc=1
  fi

  if grep -Fq '"state_traceback"' "$E2E_ROOT_DIR/$report_sh" &&
     grep -Fq 'state_sequence' "$E2E_ROOT_DIR/$report_sh" &&
     grep -Fq 'failure_state' "$E2E_ROOT_DIR/$report_sh" &&
     grep -Fq 'rollback_target' "$E2E_ROOT_DIR/$report_sh"; then
    printf 'PASS report.sh emits state_traceback fields into task-run artifacts\n'
  else
    printf 'FAIL report.sh missing state_traceback artifact fields\n'
    rc=1
  fi

  if python3 - "$E2E_ROOT_DIR" <<'PY'
import sqlite3
import sys
import tempfile
from pathlib import Path

source_root = Path(sys.argv[1]).resolve()
sys.path.insert(0, str(source_root))

from scripts.dev_memory.core import init_schema
from scripts.dev_memory.maintenance import validate_state_traceback_payload

run_id = "state-probe"
sequence = [
    "recall_context",
    "classify_layer",
    "plan_graph",
    "implement",
    "verify",
    "inspect",
    "persist",
]
traceback = {
    "state_sequence": sequence,
    "current_state": "persist",
    "failure_state": "",
    "rollback_target": "",
    "failure_reason": "",
    "reviewer": "ysyx-coordinator",
    "inspector": "agent-system",
    "evidence_policy": "task-report + dispatch-log + run-manifest + evidence-index",
}
manifest = {"status": "completed", "state_traceback": traceback}

with tempfile.TemporaryDirectory() as tmp:
    repo_root = Path(tmp).resolve()
    report = repo_root / ".github/task-runs" / run_id / "task-report.md"
    report.parent.mkdir(parents=True)
    report.write_text(
        "# 任务报告\n\n"
        + "\n".join(f"- `{key}`: {value}" for key, value in traceback.items())
        + "\n",
        encoding="utf-8",
    )
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
    init_schema(conn)
    try:
        result, errors = validate_state_traceback_payload(
            repo_root,
            conn,
            run_id,
            manifest,
        )
    finally:
        conn.close()

ok = not errors and result.get("current_state") == "persist"
raise SystemExit(0 if ok else 1)
PY
  then
    printf 'PASS targeted state audit resolves task report from canonical task-run root\n'
  else
    printf 'FAIL targeted state audit did not resolve canonical task-run report fields\n'
    rc=1
  fi

  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" state-audit || rc=1
  return "$rc"
}

e2e_agent_system_dual_role_docs_valid() {
  local agents_doc=${1:-.github/AGENTS.md}
  local copilot_doc=${2:-.github/copilot-instructions.md}
  local agent_system_doc=${3:-.github/agents/agent-system.agent.md}
  local state_machine_doc=${4:-.github/instructions/agent-env-state-machine.instructions.md}

  e2e_file_contains "$agents_doc" '实现者' &&
    e2e_file_contains "$agents_doc" '审查者' &&
    e2e_file_contains "$agents_doc" '双角色复核' &&
    e2e_file_contains "$copilot_doc" '实现者' &&
    e2e_file_contains "$copilot_doc" '审查者' &&
    e2e_file_contains "$copilot_doc" '双角色复核' &&
    e2e_file_contains "$agent_system_doc" '实现者人格' &&
    e2e_file_contains "$agent_system_doc" '审查者人格' &&
    e2e_file_contains "$state_machine_doc" '实现者/审查者双角色复核'
}

e2e_agent_system_reviewer_inspector_gate() {
  echo "[agent-system] reviewer/inspector execution gate"
  local rc=0
  local profile_doc=".github/e2e/profiles/agent-system.tsv"
  local review_doc=".github/ai-env/contracts/agent-env-review-routing.json"
  local policy_doc=".github/ai-env/contracts/agent-env-policy.json"
  local state_trace_doc=".github/ai-env/contracts/agent-env-state-traceability.json"

  e2e_print_required_files \
    "$profile_doc" \
    "$review_doc" \
    "$policy_doc" \
    "$state_trace_doc" || rc=1

  if e2e_file_contains "$profile_doc" 'state-machine-traceback|agent-system|e2e_agent_system_state_traceback|agent-system|' &&
     e2e_file_contains "$profile_doc" 'reviewer-inspector-gate|agent-system|e2e_agent_system_reviewer_inspector_gate|agent-system|'; then
    printf 'PASS agent-system profile executes state traceback and reviewer/inspector nodes\n'
  else
    printf 'FAIL agent-system profile missing R7 execution nodes\n'
    rc=1
  fi

  if e2e_file_contains "$review_doc" '"R7": "agent-layer"' &&
     e2e_file_contains "$review_doc" '"primary_agent": "ysyx-coordinator"' &&
     e2e_file_contains "$review_doc" '"inspector": "agent-system"' &&
     e2e_file_contains "$review_doc" '"state-audit"' &&
     e2e_file_contains "$review_doc" '"adversarial_personas"' &&
     e2e_file_contains "$review_doc" '"implementer_persona"' &&
     e2e_file_contains "$review_doc" '"reviewer_persona"' &&
     e2e_file_contains "$review_doc" '"conflict_resolution_required": true'; then
    printf 'PASS review routing maps R7 to reviewer/inspector gate\n'
  else
    printf 'FAIL review routing missing R7 reviewer/inspector gate\n'
    rc=1
  fi

  if e2e_file_contains "$policy_doc" '"reviewer_profile_nodes"' &&
     e2e_file_contains "$policy_doc" '"state-machine-traceback"' &&
     e2e_file_contains "$policy_doc" '"reviewer-inspector-gate"' &&
     e2e_file_contains "$policy_doc" '"adversarial_personas_required": true' &&
     e2e_file_contains "$policy_doc" '"conflict_resolution_required": true'; then
    printf 'PASS policy requires reviewer/inspector profile nodes\n'
  else
    printf 'FAIL policy missing reviewer/inspector profile node requirements\n'
    rc=1
  fi

  # Check the delivery contract by semantic anchors instead of one exact
  # punctuation/persona spelling.  The rule remains strict about both roles and
  # the dual-role review, while allowing the canonical docs to use
  # “实现者 / 审查者” or “实现者人格 / 审查者人格”.
  if e2e_agent_system_dual_role_docs_valid; then
    printf 'PASS implementer/reviewer dual-role delivery rule is documented\n'
  else
    printf 'FAIL implementer/reviewer dual-role delivery rule missing from docs\n'
    rc=1
  fi

  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" state-audit || rc=1
  return "$rc"
}

e2e_agent_system_rtl_task_contract() {
  echo "[agent-system] local RTL task contract"
  local rc=0
  local contract_doc=".github/ai-env/contracts/agent-env-rtl-task-contract.json"
  local policy_doc=".github/ai-env/contracts/agent-env-policy.json"
  local instruction_doc=".github/instructions/rtl-agent-task-contract.instructions.md"
  local skill_doc=".github/skills/prepare-rtl-task-contract/SKILL.md"
  local skill_meta=".github/skills/prepare-rtl-task-contract/agents/openai.yaml"
  local contract_tool=".github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py"
  local coordinator_doc=".github/agents/ysyx-coordinator.agent.md"
  local npc_doc=".github/agents/npc.agent.md"
  local profile_doc=".github/e2e/profiles/agent-system.tsv"

  e2e_print_required_files \
    "$contract_doc" \
    "$policy_doc" \
    "$instruction_doc" \
    "$skill_doc" \
    "$skill_meta" \
    "$contract_tool" \
    "$coordinator_doc" \
    "$npc_doc" \
    "$profile_doc" || rc=1

  if (set -o pipefail; e2e_file_contains "$skill_doc" 'name: prepare-rtl-task-contract'); then
    printf 'PASS file marker lookup remains exact under pipefail\n'
  else
    printf 'FAIL file marker lookup reported a pipefail/SIGPIPE false negative\n'
    rc=1
  fi

  if e2e_file_contains "$instruction_doc" 'engineering_domain' &&
     e2e_file_contains "$instruction_doc" 'canonical v2 `scope`' &&
     e2e_file_contains "$instruction_doc" 'allowed_paths' &&
     e2e_file_contains "$instruction_doc" 'write_paths' &&
     e2e_file_contains "$instruction_doc" 'allowed_commands' &&
     e2e_file_contains "$instruction_doc" '`mode/purpose` 必须逐字匹配 canonical catalog' &&
     e2e_file_contains "$instruction_doc" '`--repo-root`' &&
     e2e_file_contains "$instruction_doc" 'required_context' &&
     e2e_file_contains "$instruction_doc" 'deliverables' &&
     e2e_file_contains "$instruction_doc" 'success_criteria' &&
     e2e_file_contains "$instruction_doc" 'JSON 的仓库相对路径' &&
     e2e_file_contains "$instruction_doc" '该文件 SHA-256' &&
     e2e_file_contains "$instruction_doc" '哈希只绑定该 JSON' &&
     e2e_file_contains "$instruction_doc" '工程 shell 为 single-flight' &&
     e2e_file_contains "$instruction_doc" '文本反例不是验证证据' &&
     e2e_file_contains "$instruction_doc" 'JSON 精确声明 `allowed_commands=[]`、`write_paths=[]`' &&
     e2e_file_contains "$instruction_doc" '不执行工程命令或仓库读取' &&
     e2e_file_contains "$instruction_doc" 'prompt-supplied-self-contained' &&
     e2e_file_contains "$instruction_doc" '`--self-contained-no-tools`' &&
     e2e_file_contains "$instruction_doc" '默认只读探索' &&
     e2e_file_contains "$instruction_doc" '限定材料复核' &&
     e2e_file_contains "$instruction_doc" '`scope_extension_request`' &&
     e2e_file_contains "$instruction_doc" '信息不足时允许 `inconclusive`' &&
     e2e_file_contains "$instruction_doc" '不得设置固定 blocker/发现数量' &&
     e2e_file_contains "$instruction_doc" '校验器必须拒绝' &&
     e2e_file_contains "$instruction_doc" '`review_pending`' &&
     e2e_file_contains "$instruction_doc" '父目标保持 `active`' &&
     e2e_file_contains "$instruction_doc" '`rv64-hardware-professional`' &&
     e2e_file_contains "$instruction_doc" '本地作用域开场' &&
     e2e_file_contains "$instruction_doc" '对象、层级、作用域和工程目的' &&
     e2e_file_contains "$instruction_doc" '不附加平台处理' &&
     e2e_file_contains "$instruction_doc" '关键词拒绝' &&
     e2e_file_contains "$instruction_doc" '精简技术提示' &&
     e2e_file_contains "$instruction_doc" 'CPU 债务项、schema 字段、定向单测和' &&
     e2e_file_contains "$instruction_doc" '不改变工具、shell、路径、上下文或推理能力'; then
    printf 'PASS RTL task instruction binds scope, outputs, evidence and review containment\n'
  else
    printf 'FAIL RTL task instruction missing required scope or review containment fields\n'
    rc=1
  fi

  if e2e_file_contains "$skill_doc" 'name: prepare-rtl-task-contract' &&
     e2e_file_contains "$skill_doc" '新建合同使用 schema v2' &&
     e2e_file_contains "$skill_doc" 'rtl_task_contract.py create' &&
     e2e_file_contains "$skill_doc" 'rtl_task_contract.py validate' &&
     e2e_file_contains "$skill_doc" 'rtl_task_contract.py render' &&
     e2e_file_contains "$skill_doc" 'rtl_task_contract.py cli-self-test' &&
     e2e_file_contains "$skill_doc" '--allow-read-command' &&
     e2e_file_contains "$skill_doc" '该哈希只绑定 JSON' &&
     e2e_file_contains "$skill_doc" 'single-flight' &&
     e2e_file_contains "$skill_doc" '文本反例本身不能作为 GREEN 证据' &&
     e2e_file_contains "$skill_doc" '`allowed_commands=[]`、`write_paths=[]`' &&
     e2e_file_contains "$skill_doc" '不执行工程命令或仓库读取' &&
     e2e_file_contains "$skill_doc" 'prompt-supplied-self-contained' &&
     e2e_file_contains "$skill_doc" '--self-contained-no-tools' &&
     e2e_file_contains "$skill_doc" '默认只读探索' &&
     e2e_file_contains "$skill_doc" '限定材料复核' &&
     e2e_file_contains "$skill_doc" '`scope_extension_request`' &&
     e2e_file_contains "$skill_doc" '允许 `inconclusive`' &&
     e2e_file_contains "$skill_doc" '`rv64-hardware-professional`' &&
     e2e_file_contains "$skill_doc" '对象、层级、作用域和工程目的' &&
     e2e_file_contains "$skill_doc" '.github/agentic-hardware-blueprint.md' &&
     e2e_file_contains "$skill_doc" '不进入子 agent 渲染提示' &&
     e2e_file_contains "$skill_doc" '不建立关键词黑名单' &&
     e2e_file_contains "$skill_doc" '精简的硬件事实提示' &&
     e2e_file_contains "$skill_doc" '泛化的校验器、引用拓扑或输入空间' &&
     e2e_file_contains "$skill_doc" '不改变任何工具、shell、路径或推理能力' &&
     e2e_file_contains "$contract_doc" '"default_mode": "workspace-files"' &&
     e2e_file_contains "$contract_doc" '"no_tools_mode": "prompt-supplied-self-contained"' &&
     e2e_file_contains "$contract_doc" '"no_tools_usage": "exceptional-bounded-evidence-review"' &&
     e2e_file_contains "$contract_doc" '"reasoning_policy"' &&
     e2e_file_contains "$contract_doc" '"fixed_finding_cap_forbidden": true' &&
     e2e_file_contains "$contract_doc" '"no_tools_task_kinds"' &&
     e2e_file_contains "$contract_doc" '"wording_profile"' &&
     e2e_file_contains "$contract_doc" '"schema_version": 2' &&
     e2e_file_contains "$contract_doc" '"scope_defaults"' &&
     e2e_file_contains "$contract_doc" '"profile": "rv64-hardware-professional"' &&
     e2e_file_contains "$contract_doc" '"reference": ".github/agentic-hardware-blueprint.md#rv64-hardware-professional-task-wording"' &&
     e2e_file_contains "$contract_doc" '"domain_reference": "npc/rv64/design/arch/rv64-hardware-wording-profile.md"' &&
     e2e_file_contains "$contract_doc" '"keyword_blacklist_forbidden": true' &&
     e2e_file_contains "$contract_doc" '"does_not_change_capabilities": true' &&
     e2e_file_contains "$contract_doc" '"positive_local_scope_preamble_required": true' &&
     e2e_file_contains "$contract_doc" '"rendered_prompt_style": "compact-rv64-hardware-evidence"' &&
     e2e_file_contains "$contract_doc" '"technical_narrative_subject": "local-rv64-rtl-object-or-evidence"' &&
     e2e_file_contains "$contract_doc" '"coordination_metadata_in_rendered_prompt": false' &&
     e2e_file_contains "$contract_doc" '"final_response_evidence_order"' &&
     e2e_file_contains "$contract_doc" '"testbench-or-eda-observation"' &&
     e2e_file_contains "$contract_doc" '"engineering-purpose"' &&
     e2e_file_contains "$contract_tool" 'fixed finding count caps are forbidden' &&
     e2e_file_contains "$contract_tool" 'CANONICAL_SCOPE_FIELDS' &&
     e2e_file_contains "$contract_tool" 'RV64 RTL 结论｜对象=<module/signal/本地证据路径>' &&
     e2e_file_contains "$contract_tool" '## 最终技术回复' &&
     e2e_file_contains "$contract_tool" 'CPU 证据对象、具体 schema 字段、工作区相对路径、测试名和返回码' &&
     e2e_file_contains "$contract_tool" 'rendered hardware prompt leaked coordinator-only wording' &&
     e2e_file_contains "$skill_meta" 'Use $prepare-rtl-task-contract'; then
    printf 'PASS RTL task skill is discoverable and exposes create/validate/render\n'
  else
    printf 'FAIL RTL task skill or OpenAI metadata is incomplete\n'
    rc=1
  fi

  if e2e_file_contains "$policy_doc" '"task_delegation"' &&
     e2e_file_contains "$policy_doc" '"contract_before_dispatch_required": true' &&
     e2e_file_contains "$policy_doc" '"local_rtl_material_source": "declared-workspace-paths"' &&
     e2e_file_contains "$policy_doc" '"hardware_wording_profile_required": true' &&
     e2e_file_contains "$policy_doc" '"positive_local_scope_preamble_required": true' &&
     e2e_file_contains "$policy_doc" '"ambiguous_terms_require_hardware_context": true' &&
     e2e_file_contains "$policy_doc" '"final_response_hardware_evidence_first_required": true' &&
     e2e_file_contains "$policy_doc" '"rendered_prompt_platform_meta_forbidden": true' &&
     e2e_file_contains "$policy_doc" '"rendered_prompt_coordination_meta_forbidden": true' &&
     e2e_file_contains "$policy_doc" '"rendered_prompt_style": "compact-rv64-hardware-evidence"' &&
     e2e_file_contains "$policy_doc" '"technical_narrative_subject": "local-rv64-rtl-object-or-evidence"' &&
     e2e_file_contains "$policy_doc" '"wording_profile_changes_capabilities": false' &&
     e2e_file_contains "$policy_doc" '"wording_keyword_blacklist_forbidden": true' &&
     e2e_file_contains "$coordinator_doc" '$prepare-rtl-task-contract' &&
     e2e_file_contains "$coordinator_doc" '`rv64-hardware-professional`' &&
     e2e_file_contains "$npc_doc" 'rtl-agent-task-contract.instructions.md' &&
     e2e_file_contains "$npc_doc" '`rv64-hardware-professional`' &&
     e2e_file_contains "$profile_doc" 'rtl-task-contract|agent-system|e2e_agent_system_rtl_task_contract|agent-system|'; then
    printf 'PASS policy, coordinator, NPC agent and profile route through the task contract\n'
  else
    printf 'FAIL RTL task contract is not fully wired into policy or dispatch routes\n'
    rc=1
  fi

  python3 "$E2E_ROOT_DIR/$contract_tool" audit || rc=1
  python3 "$E2E_ROOT_DIR/$contract_tool" self-test || rc=1
  python3 "$E2E_ROOT_DIR/$contract_tool" cli-self-test || rc=1
  return "$rc"
}

e2e_agent_system_commercial_delivery_readiness() {
  echo "[agent-system] commercial delivery readiness"
  local rc=0
  local delivery_doc=".github/ai-env/contracts/agent-env-delivery.json"
  local package_script="scripts/package-ai-dev-env.sh"
  local delivery_root="deliverables/ai-dev-env-commercial-v1"
  local package_root="dist/ai-dev-env-commercial-v1/package/ysyx-ai-dev-env-commercial"
  local archive_manifest=".github/archive/legacy-ai-dev-env-2026-06-13/ARCHIVE_MANIFEST.md"
  local archive_checksums=".github/archive/legacy-ai-dev-env-2026-06-13/CHECKSUMS.txt"
  local archive_pointers=".github/archive/legacy-ai-dev-env-2026-06-13/POINTERS.md"
  local package_filelist="$package_root/PACKAGE_FILELIST.txt"
  local sensitive_log
  local marker_home="/home/""lyg"
  local marker_windows="C:/Users/""17279"
  local marker_id="260""10035"
  local marker_tag="ysyx_""260""10035"

  sensitive_log=$(mktemp)

  e2e_print_required_files \
    "$delivery_doc" \
    "$package_script" \
    "$delivery_root/README.md" \
    "$delivery_root/PACKAGING_MANIFEST.md" \
    "$delivery_root/COMMERCIAL_READINESS.md" \
    "$delivery_root/docs/ARCHITECTURE.md" \
    "$delivery_root/docs/OPERATIONS.md" \
    "$delivery_root/docs/QUALITY_GATES.md" \
    "$archive_manifest" \
    "$archive_checksums" \
    "$archive_pointers" || rc=1

  bash "$E2E_ROOT_DIR/$package_script" || rc=1

  e2e_print_required_files \
    "$package_root/README.md" \
    "$package_root/AI_ENVIRONMENT.md" \
    "$package_root/PACKAGING_MANIFEST.md" \
    "$package_root/.github/AGENTS.md" \
    "$package_root/.github/ai-env/README.md" \
    "$package_root/.github/ai-env/contracts/agent-env-delivery.json" \
    "$package_root/.github/ai-env/contracts/agent-env-policy.json" \
    "$package_root/.github/agents/AGENT_INDEX.md" \
    "$package_root/.github/skills/agent-env-maintenance/SKILL.md" \
    "$package_root/scripts/README.md" \
    "$package_root/scripts/agent-maintain.sh" \
    "$package_root/scripts/github_index_db.py" \
    "$package_filelist" || rc=1

  if [[ ! -e "$E2E_ROOT_DIR/outputs" && ! -e "$E2E_ROOT_DIR/.github/e2e/_manual" ]]; then
    printf 'PASS legacy active outputs are absent from the live workspace\n'
  else
    printf 'FAIL legacy active outputs still exist in live workspace\n'
    rc=1
  fi

  if e2e_file_contains "$archive_manifest" 'outputs/' &&
     e2e_file_contains "$archive_manifest" '.github/e2e/_manual'; then
    printf 'PASS archive manifest records moved legacy output roots\n'
  else
    printf 'FAIL archive manifest missing moved legacy output roots\n'
    rc=1
  fi

  if grep -Fq 'README.md' "$E2E_ROOT_DIR/$package_filelist" &&
     grep -Fq 'AI_ENVIRONMENT.md' "$E2E_ROOT_DIR/$package_filelist" &&
     grep -Fq '.github/ai-env/README.md' "$E2E_ROOT_DIR/$package_filelist" &&
     grep -Fq '.github/ai-env/contracts/agent-env-delivery.json' "$E2E_ROOT_DIR/$package_filelist" &&
     grep -Fq '.github/agents/AGENT_INDEX.md' "$E2E_ROOT_DIR/$package_filelist" &&
     grep -Fq 'scripts/README.md' "$E2E_ROOT_DIR/$package_filelist" &&
     grep -Fq 'scripts/agent-maintain.sh' "$E2E_ROOT_DIR/$package_filelist" &&
     grep -Fq 'scripts/github_index_db.py' "$E2E_ROOT_DIR/$package_filelist" &&
     ! grep -Fq "$marker_home" "$E2E_ROOT_DIR/$package_filelist"; then
    printf 'PASS package filelist is relative and contains required delivery entries\n'
  else
    printf 'FAIL package filelist missing required entries or contains absolute paths\n'
    rc=1
  fi

  if [[ ! -d "$E2E_ROOT_DIR/$package_root/.github/e2e/modules/modules" &&
        ! -d "$E2E_ROOT_DIR/$package_root/.github/e2e/profiles/profiles" ]]; then
    printf 'PASS package e2e directories are not nested twice\n'
  else
    printf 'FAIL package contains duplicated e2e module/profile directories\n'
    rc=1
  fi

  if rg -n -e "$marker_home" -e "$marker_windows" -e "$marker_id" -e "$marker_tag" "$E2E_ROOT_DIR/$package_root" >"$sensitive_log" 2>/dev/null; then
    printf 'FAIL package contains local/private markers\n'
    sed -n '1,10p' "$sensitive_log"
    rc=1
  else
    printf 'PASS package contains no local/private marker scan hits\n'
  fi

  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" delivery-audit || rc=1
  rm -f "$sensitive_log"
  return "$rc"
}

e2e_agent_system_task_run_status_fail_closed() {
  echo "[agent-system] RV64 long-run status fail-closed"
  local rc=0
  local status_helper="scripts/task-run-status.sh"
  local status_test="scripts/tests/test-task-run-status.sh"
  local maintain_sh="scripts/agent-maintain.sh"
  local strict_runner=".github/task-runs/2026-07-24-rv64-v9s-serialize-default/run-v9s-rootfs-csr-qh-systemd-strict.sh"
  local full_runner=".github/task-runs/2026-07-24-rv64-v9s-serialize-default/run-v9s-rootfs-csr-qh-on-current.sh"

  e2e_print_required_files \
    "$status_helper" \
    "$status_test" \
    "$maintain_sh" \
    "$strict_runner" \
    "$full_runner" || rc=1

  if grep -Fq 'TASK_RUN_STATUS_EVIDENCE_COMPLETE=0' "$E2E_ROOT_DIR/$status_helper" &&
     grep -Fq 'task_run_status_mark_evidence_complete' "$E2E_ROOT_DIR/$status_helper" &&
     grep -Fq 'task_run_status_install_signal_traps' "$E2E_ROOT_DIR/$status_helper" &&
     grep -Fq 'cleanup_rc=' "$E2E_ROOT_DIR/$status_helper"; then
    printf 'PASS task-run status helper binds completion, signal, stage, and cleanup state\n'
  else
    printf 'FAIL task-run status helper misses completion, signal, stage, or cleanup state\n'
    rc=1
  fi

  if grep -Fq 'task-run status fail-closed self-test' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'scripts/tests/test-task-run-status.sh' "$E2E_ROOT_DIR/$maintain_sh"; then
    printf 'PASS agent-maintain check executes task-run status fail-closed self-test\n'
  else
    printf 'FAIL agent-maintain check misses task-run status fail-closed self-test\n'
    rc=1
  fi

  for runner in "$strict_runner" "$full_runner"; do
    if grep -Fq 'source "${status_helper}"' "$E2E_ROOT_DIR/$runner" &&
       grep -Fq 'task_run_status_mark_evidence_complete' "$E2E_ROOT_DIR/$runner" &&
       ! grep -Eq 'if .*rc.*-eq 0.*PASS' "$E2E_ROOT_DIR/$runner"; then
      printf 'PASS RV64 runner uses explicit completion latch: %s\n' "$runner"
    else
      printf 'FAIL RV64 runner does not use fail-closed completion latch: %s\n' "$runner"
      rc=1
    fi
  done

  "$E2E_ROOT_DIR/$status_test" || rc=1
  return "$rc"
}

e2e_agent_system_profile_index() {
  echo "[agent-system] e2e profiles"
  find "$E2E_ROOT_DIR/.github/e2e/profiles" -maxdepth 1 -type f -name '*.tsv' -printf '%f\n' | sort
}
