#!/usr/bin/env bash

set -uo pipefail

E2E_ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
E2E_PROFILE=quick
E2E_TASK_SLUG=
E2E_RUN_DIR=
E2E_KEEP_GOING=1
E2E_LIST_PROFILES=0
E2E_VALIDATE_PROFILE=0
E2E_VALIDATE_ALL_PROFILES=0
E2E_GUARD=0
E2E_GUARD_MODE=strict
E2E_GUARD_SINCE_REF=HEAD
E2E_GUARD_PATHS_FILE=
E2E_GUARD_PATH_ARGS=()
E2E_GUARD_EVIDENCE_DIRS=()

source "$E2E_ROOT_DIR/scripts/agent-env.sh"
source "$E2E_ROOT_DIR/scripts/e2e/lib/common.sh"
source "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh"
for module_lib in "$E2E_ROOT_DIR"/scripts/e2e/modules/*.sh; do
  source "$module_lib"
done

usage() {
  cat <<'EOF'
用法:
  scripts/agent-e2e.sh [--profile name] [--task-slug slug] [--run-dir dir] [--stop-on-fail] [--list-profiles]
  scripts/agent-e2e.sh --validate-profile [--profile name]
  scripts/agent-e2e.sh --validate-all-profiles
  scripts/agent-e2e.sh --guard [--guard-mode strict|warn] [--paths-file file] [--path path] [--evidence-dir dir]

说明:
  profile 定义放在 .github/e2e/profiles/*.tsv。
  具体模块 gate 放在 scripts/e2e/modules/*.sh。
  本脚本只负责展开 profile、调度节点和生成 task-run 证据包。
  validate 模式只检查 profile 展开和函数绑定，不执行具体 gate。
  guard 模式按工作树触碰路径推导推荐 profile，并检查本轮 task-run 证据和 DB 召回产物。

示例:
  scripts/agent-e2e.sh --list-profiles
  scripts/agent-e2e.sh --validate-all-profiles
  scripts/agent-e2e.sh --guard --guard-mode strict
  scripts/agent-e2e.sh --profile discovery
  scripts/agent-e2e.sh --profile abstract-machine
  scripts/agent-e2e.sh --profile npc
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --profile)
        [[ $# -ge 2 ]] || { echo "--profile 需要一个参数" >&2; exit 2; }
        E2E_PROFILE=$2
        shift 2
        ;;
      --task-slug)
        [[ $# -ge 2 ]] || { echo "--task-slug 需要一个参数" >&2; exit 2; }
        E2E_TASK_SLUG=$2
        shift 2
        ;;
      --run-dir)
        [[ $# -ge 2 ]] || { echo "--run-dir 需要一个目录参数" >&2; exit 2; }
        E2E_RUN_DIR=$2
        shift 2
        ;;
      --stop-on-fail)
        E2E_KEEP_GOING=0
        shift
        ;;
      --list-profiles)
        E2E_LIST_PROFILES=1
        shift
        ;;
      --validate-profile)
        E2E_VALIDATE_PROFILE=1
        shift
        ;;
      --validate-all-profiles)
        E2E_VALIDATE_ALL_PROFILES=1
        shift
        ;;
      --guard)
        E2E_GUARD=1
        shift
        ;;
      --guard-mode)
        [[ $# -ge 2 ]] || { echo "--guard-mode 需要 strict 或 warn" >&2; exit 2; }
        E2E_GUARD_MODE=$2
        shift 2
        ;;
      --since-ref)
        [[ $# -ge 2 ]] || { echo "--since-ref 需要一个 Git ref" >&2; exit 2; }
        E2E_GUARD_SINCE_REF=$2
        shift 2
        ;;
      --paths-file)
        [[ $# -ge 2 ]] || { echo "--paths-file 需要一个文件参数" >&2; exit 2; }
        E2E_GUARD_PATHS_FILE=$2
        shift 2
        ;;
      --path)
        [[ $# -ge 2 ]] || { echo "--path 需要一个路径参数" >&2; exit 2; }
        E2E_GUARD_PATH_ARGS+=("$2")
        shift 2
        ;;
      --evidence-dir)
        [[ $# -ge 2 ]] || { echo "--evidence-dir 需要一个 task-run 目录参数" >&2; exit 2; }
        E2E_GUARD_EVIDENCE_DIRS+=("$2")
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "未知参数: $1" >&2
        usage >&2
        exit 2
        ;;
    esac
  done

  if [[ -z $E2E_TASK_SLUG ]]; then
    E2E_TASK_SLUG="agent-e2e-$E2E_PROFILE"
  fi

  case "$E2E_GUARD_MODE" in
    strict|warn) ;;
    *)
      echo "未知 guard mode: $E2E_GUARD_MODE" >&2
      exit 2
      ;;
  esac
}

list_profiles() {
  find "$E2E_ROOT_DIR/.github/e2e/profiles" -maxdepth 1 -type f -name '*.tsv' -printf '%f\n' \
    | sed 's/\.tsv$//' \
    | sort
}

PROFILE_NODE_IDS=()
PROFILE_MODULES=()
PROFILE_FUNCTIONS=()
PROFILE_OWNERS=()
PROFILE_INPUTS=()
PROFILE_OUTPUTS=()
PROFILE_SOURCES=()

reset_profile_arrays() {
  PROFILE_NODE_IDS=()
  PROFILE_MODULES=()
  PROFILE_FUNCTIONS=()
  PROFILE_OWNERS=()
  PROFILE_INPUTS=()
  PROFILE_OUTPUTS=()
  PROFILE_SOURCES=()
}

load_profile() {
  local profile=$1
  local profile_rel=".github/e2e/profiles/${profile}.tsv"
  local profile_file="$E2E_ROOT_DIR/$profile_rel"
  if [[ ! -f $profile_file ]]; then
    echo "找不到 e2e profile: $profile_file" >&2
    exit 2
  fi

  local profile_content
  if ! profile_content=$(e2e_file_text "$profile_rel"); then
    echo "无法读取 e2e profile: $profile_file" >&2
    exit 2
  fi

  local line node module function owner inputs outputs
  while IFS= read -r line || [[ -n $line ]]; do
    [[ -z $line ]] && continue
    [[ $line = \#* ]] && continue
    IFS='|' read -r node module function owner inputs outputs <<< "$line"
    if [[ $node = "@include" ]]; then
      load_profile "$module"
      continue
    fi
    PROFILE_NODE_IDS+=("$node")
    PROFILE_MODULES+=("$module")
    PROFILE_FUNCTIONS+=("$function")
    PROFILE_OWNERS+=("$owner")
    PROFILE_INPUTS+=("$inputs")
    PROFILE_OUTPUTS+=("$outputs")
    PROFILE_SOURCES+=("$profile")
  done <<< "$profile_content"
}

validate_profile_boundary_value() {
  local profile=$1 field=$2 value=$3 expected=$4
  if [[ $value = "$expected" ]]; then
    return 0
  fi
  printf '[agent-e2e] FAIL profile-boundary profile=%s field=%s value=%s expected=%s\n' \
    "$profile" "$field" "$value" "$expected" >&2
  return 1
}

validate_nemu_dev_boundary() {
  local profile=$1
  local i node module function owner source rc=0
  printf '[agent-e2e] profile-boundary=%s mode=NEMU-only\n' "$profile"
  for i in "${!PROFILE_NODE_IDS[@]}"; do
    node=${PROFILE_NODE_IDS[$i]}
    module=${PROFILE_MODULES[$i]}
    function=${PROFILE_FUNCTIONS[$i]}
    owner=${PROFILE_OWNERS[$i]}
    source=${PROFILE_SOURCES[$i]}

    case "$module" in
      nemu|software-flow) ;;
      *) validate_profile_boundary_value "$profile" "module" "$module" "nemu|software-flow" || rc=1 ;;
    esac
    case "$owner" in
      nemu|software-flow) ;;
      *) validate_profile_boundary_value "$profile" "owner" "$owner" "nemu|software-flow" || rc=1 ;;
    esac
    case "$source" in
      nemu-dev|nemu-dev-gate|nemu-dev-full-gate|nemu-dev-full-soak|nemu-ubuntu|nemu-ubuntu-focused|nemu-ubuntu-profile|nemu-ubuntu-gate|nemu-ubuntu-full-gate|nemu-ubuntu-full-soak|software-flow) ;;
      *) validate_profile_boundary_value "$profile" "source_profile" "$source" "NEMU dev closure" || rc=1 ;;
    esac
    if [[ $node = npc-* || $function = e2e_npc_* || $module = npc || $owner = npc ]]; then
      printf '[agent-e2e] FAIL profile-boundary profile=%s node=%s: NEMU-only dev profile pulled NPC work\n' \
        "$profile" "$node" >&2
      rc=1
    fi
  done
  if [[ $rc -eq 0 ]]; then
    printf '[agent-e2e] PASS profile-boundary %s NEMU-only closure\n' "$profile"
  fi
  return "$rc"
}

validate_npc_dev_boundary() {
  local profile=$1
  local i node module function owner source rc=0
  printf '[agent-e2e] profile-boundary=%s mode=NPC-only\n' "$profile"
  for i in "${!PROFILE_NODE_IDS[@]}"; do
    node=${PROFILE_NODE_IDS[$i]}
    module=${PROFILE_MODULES[$i]}
    function=${PROFILE_FUNCTIONS[$i]}
    owner=${PROFILE_OWNERS[$i]}
    source=${PROFILE_SOURCES[$i]}

    case "$module" in
      npc|software-flow) ;;
      *) validate_profile_boundary_value "$profile" "module" "$module" "npc|software-flow" || rc=1 ;;
    esac
    case "$owner" in
      npc|software-flow) ;;
      *) validate_profile_boundary_value "$profile" "owner" "$owner" "npc|software-flow" || rc=1 ;;
    esac
    case "$source" in
      npc-dev|software-flow) ;;
      *) validate_profile_boundary_value "$profile" "source_profile" "$source" "NPC dev closure" || rc=1 ;;
    esac
    if [[ $node = nemu-* || $function = e2e_nemu_* || $module = nemu || $owner = nemu ]]; then
      printf '[agent-e2e] FAIL profile-boundary profile=%s node=%s: NPC-only dev profile pulled NEMU work\n' \
        "$profile" "$node" >&2
      rc=1
    fi
  done
  if [[ $rc -eq 0 ]]; then
    printf '[agent-e2e] PASS profile-boundary %s NPC-only closure\n' "$profile"
  fi
  return "$rc"
}

validate_profile_boundary() {
  local profile=$1
  case "$profile" in
    nemu-dev|nemu-dev-gate|nemu-dev-full-gate|nemu-dev-full-soak|nemu-ubuntu|nemu-ubuntu-focused|nemu-ubuntu-profile|nemu-ubuntu-gate|nemu-ubuntu-full-gate|nemu-ubuntu-full-soak)
      validate_nemu_dev_boundary "$profile"
      ;;
    npc-dev)
      validate_npc_dev_boundary "$profile"
      ;;
    *)
      return 0
      ;;
  esac
}

validate_loaded_profile() {
  local profile=$1
  local i node module function owner inputs outputs rc=0
  printf '[agent-e2e] validate profile=%s nodes=%s\n' "$profile" "${#PROFILE_NODE_IDS[@]}"
  for i in "${!PROFILE_NODE_IDS[@]}"; do
    node=${PROFILE_NODE_IDS[$i]}
    module=${PROFILE_MODULES[$i]}
    function=${PROFILE_FUNCTIONS[$i]}
    owner=${PROFILE_OWNERS[$i]}
    inputs=${PROFILE_INPUTS[$i]}
    outputs=${PROFILE_OUTPUTS[$i]}
    if [[ -z $node || -z $module || -z $function || -z $owner ]]; then
      printf '[agent-e2e] FAIL profile=%s node=%s: TSV 字段不完整\n' "$profile" "$node" >&2
      rc=1
      continue
    fi
    if ! declare -F "$function" >/dev/null 2>&1; then
      printf '[agent-e2e] FAIL profile=%s node=%s function=%s: 函数不存在\n' "$profile" "$node" "$function" >&2
      rc=1
      continue
    fi
    printf '[agent-e2e] OK %s | %s | %s | %s | %s -> %s\n' "$node" "$owner" "$module" "$function" "$inputs" "$outputs"
  done
  return "$rc"
}

validate_all_profiles() {
  local profile rc=0 catalog_file
  catalog_file=$(mktemp) || return 1
  if ! list_profiles > "$catalog_file"; then
    rm -f -- "$catalog_file"
    return 1
  fi
  if [[ ! -s $catalog_file ]]; then
    rm -f -- "$catalog_file"
    return 1
  fi
  while IFS= read -r profile; do
    reset_profile_arrays
    load_profile "$profile"
    validate_loaded_profile "$profile" || rc=1
    validate_profile_boundary "$profile" || rc=1
  done < "$catalog_file"
  rm -f -- "$catalog_file" || return 1
  return "$rc"
}

E2E_GUARD_PATHS=()
E2E_GUARD_PROFILES=()
E2E_GUARD_PROFILE_REASONS=()
E2E_GUARD_PROFILE_MTIME_US=()
E2E_GUARD_AUTO_EVIDENCE_DIRS=()

e2e_guard_add_unique_path() {
  local path=$1 existing
  [[ -n $path ]] || return 0
  for existing in "${E2E_GUARD_PATHS[@]}"; do
    [[ $existing = "$path" ]] && return 0
  done
  E2E_GUARD_PATHS+=("$path")
}

e2e_guard_add_unique_evidence_dir() {
  local dir=$1 existing
  [[ -n $dir ]] || return 0
  for existing in "${E2E_GUARD_AUTO_EVIDENCE_DIRS[@]}"; do
    [[ $existing = "$dir" ]] && return 0
  done
  E2E_GUARD_AUTO_EVIDENCE_DIRS+=("$dir")
}

e2e_guard_path_mtime_us() {
  local reason=$1 absolute_path="$E2E_ROOT_DIR/$1" parent index_path deletion_known=0
  if [[ -e $absolute_path || -L $absolute_path ]]; then
    python3 - "$absolute_path" <<'PY'
import os
import sys

try:
    mtime_ns = os.lstat(sys.argv[1]).st_mtime_ns
except OSError:
    raise SystemExit(1)
print((mtime_ns + 999) // 1000)
PY
    return $?
  fi

  if git -C "$E2E_ROOT_DIR" ls-files --deleted -- "$reason" 2>/dev/null | grep -Fqx -- "$reason"; then
    deletion_known=1
  elif ! git -C "$E2E_ROOT_DIR" diff --cached --quiet --no-renames --diff-filter=D -- "$reason" 2>/dev/null; then
    deletion_known=1
  fi
  [[ $deletion_known -eq 1 ]] || return 1

  parent=$(dirname -- "$absolute_path")
  while [[ ! -e $parent && $parent != "$E2E_ROOT_DIR" && $parent != / ]]; do
    parent=$(dirname -- "$parent")
  done
  [[ -d $parent ]] || return 1
  index_path=$(git -C "$E2E_ROOT_DIR" rev-parse --git-path index 2>/dev/null) || return 1
  [[ $index_path = /* ]] || index_path="$E2E_ROOT_DIR/$index_path"
  python3 - "$parent" "$index_path" <<'PY'
import os
import sys

mtimes = []
for raw_path in sys.argv[1:]:
    try:
        mtimes.append(os.lstat(raw_path).st_mtime_ns)
    except OSError:
        pass
if not mtimes:
    raise SystemExit(1)
print((max(mtimes) + 999) // 1000)
PY
}

e2e_guard_add_profile() {
  local profile=$1 reason=$2 i mtime_us
  if ! mtime_us=$(e2e_guard_path_mtime_us "$reason"); then
    # An unknown nonexistent trigger cannot inherit epoch zero and accept any
    # historical evidence.  A real tracked deletion uses parent/index mtime.
    mtime_us=9223372036854775807
  fi
  for i in "${!E2E_GUARD_PROFILES[@]}"; do
    if [[ ${E2E_GUARD_PROFILES[$i]} = "$profile" ]]; then
      E2E_GUARD_PROFILE_REASONS[$i]="${E2E_GUARD_PROFILE_REASONS[$i]}; $reason"
      if [[ $mtime_us -gt ${E2E_GUARD_PROFILE_MTIME_US[$i]} ]]; then
        E2E_GUARD_PROFILE_MTIME_US[$i]=$mtime_us
      fi
      return 0
    fi
  done
  E2E_GUARD_PROFILES+=("$profile")
  E2E_GUARD_PROFILE_REASONS+=("$reason")
  E2E_GUARD_PROFILE_MTIME_US+=("$mtime_us")
}

e2e_guard_collect_paths() {
  local path auto_paths auto_paths_sorted collect_rc=0
  E2E_GUARD_PATHS=()
  E2E_GUARD_AUTO_EVIDENCE_DIRS=()

  if [[ -n $E2E_GUARD_PATHS_FILE ]]; then
    [[ -f $E2E_GUARD_PATHS_FILE ]] || { echo "[agent-e2e-guard] FAIL paths-file not found: $E2E_GUARD_PATHS_FILE" >&2; return 2; }
    while IFS= read -r path || [[ -n $path ]]; do
      e2e_guard_add_unique_path "$path"
    done < "$E2E_GUARD_PATHS_FILE"
  fi

  for path in "${E2E_GUARD_PATH_ARGS[@]}"; do
    e2e_guard_add_unique_path "$path"
  done

  if [[ ${#E2E_GUARD_PATHS[@]} -eq 0 ]]; then
    auto_paths=$(mktemp) || return 2
    auto_paths_sorted=$(mktemp) || { rm -f -- "$auto_paths"; return 2; }
    git -C "$E2E_ROOT_DIR" diff --name-only "$E2E_GUARD_SINCE_REF" -- >> "$auto_paths" 2>/dev/null || collect_rc=1
    git -C "$E2E_ROOT_DIR" diff --name-only --cached -- >> "$auto_paths" 2>/dev/null || collect_rc=1
    git -C "$E2E_ROOT_DIR" diff --name-only -- >> "$auto_paths" 2>/dev/null || collect_rc=1
    git -C "$E2E_ROOT_DIR" ls-files --others --exclude-standard >> "$auto_paths" 2>/dev/null || collect_rc=1
    if [[ $collect_rc -ne 0 ]] || ! awk 'NF' "$auto_paths" | sort -u > "$auto_paths_sorted"; then
      rm -f -- "$auto_paths" "$auto_paths_sorted"
      printf '[agent-e2e-guard] FAIL unable to enumerate changed paths\n' >&2
      return 2
    fi
    while IFS= read -r path || [[ -n $path ]]; do
      e2e_guard_add_unique_path "$path"
    done < "$auto_paths_sorted"
    rm -f -- "$auto_paths" "$auto_paths_sorted" || return 2
  fi

  for path in "${E2E_GUARD_PATHS[@]}"; do
    path=${path#./}
    case "$path" in
      .github/task-runs/*)
        IFS=/ read -r _gh _task_runs run_id _rest <<< "$path"
        [[ -n ${run_id:-} ]] && e2e_guard_add_unique_evidence_dir ".github/task-runs/$run_id"
        ;;
    esac
  done
}

e2e_guard_ignore_path() {
  local path=$1
  case "$path" in
    ''|.git/*|.github/task-runs/*|.github/db-backup/*|.github/cache/*|.github/runtime-artifacts/*|dist/*|outputs/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

e2e_guard_profiles_for_path() {
  local path=$1
  e2e_guard_ignore_path "$path" && return 0

  case "$path" in
    AGENTS.md|CLAUDE.md|GEMINI.md|CONVENTIONS.md|.windsurfrules|.cursor/rules/agents.mdc|\
    .github/AGENTS.md|.github/copilot-instructions.md|.github/agentic-hardware-blueprint.md|\
    .github/agents/*|.github/instructions/*|.github/e2e/*|.github/ai-env/*|.github/skills/*|\
    .github/workflows/agent-maintain.yml|.github/memory/modules/agent-system.md|\
    scripts/agent-e2e.sh|scripts/agent-maintain.sh|scripts/agent-env.sh|scripts/agent-run.sh|\
    scripts/e2e/*|scripts/package-ai-dev-env.sh|scripts/README.md)
      e2e_guard_add_profile "agent-system" "$path"
      ;;
  esac

  case "$path" in
    scripts/dev_memory/*|scripts/github_index_db.py)
      e2e_guard_add_profile "github-index" "$path"
      ;;
  esac

  case "$path" in
    *difftest*|npc/rv64/csrc/cpu/difftest*|nemu/src/isa/riscv64/difftest*)
      e2e_guard_add_profile "difftest" "$path"
      return 0
      ;;
  esac

  case "$path" in
    npc/rv64/*|npc/sim/*|npc/single/*|npc/soc/*)
      e2e_guard_add_profile "npc-dev" "$path"
      ;;
    nemu/*)
      e2e_guard_add_profile "nemu-dev" "$path"
      ;;
    Linux/*)
      e2e_guard_add_profile "rv64-linux" "$path"
      ;;
    abstract-machine/*)
      e2e_guard_add_profile "abstract-machine" "$path"
      ;;
    am-kernels/*)
      e2e_guard_add_profile "am-kernels" "$path"
      ;;
    ysyxSoC/*)
      e2e_guard_add_profile "ysyx-soc" "$path"
      ;;
    yosys-sta/*)
      e2e_guard_add_profile "yosys-sta" "$path"
      ;;
    nvboard/*)
      e2e_guard_add_profile "nvboard" "$path"
      ;;
    fceux-am/*)
      e2e_guard_add_profile "fceux-am" "$path"
      ;;
    digital_logic_experiment/*)
      e2e_guard_add_profile "digital-logic" "$path"
      ;;
    ace-sim/*)
      e2e_guard_add_profile "software-flow" "$path"
      ;;
  esac
}

e2e_guard_evidence_has_db_recall() {
  local dir=$1 expected_profile=$2
  e2e_validate_recall_header context "$dir/context-brief.md" "$expected_profile" || return 1
  e2e_validate_recall_header resolve "$dir/profile-resolve.md" "$expected_profile" || return 1
  [[ -f $dir/evidence-index.md && ! -L $dir/evidence-index.md ]] || return 1
}

e2e_guard_evidence_has_db_archive() {
  local dir=$1
  [[ ${E2E_GUARD_REQUIRE_DB_ARCHIVE:-1} = 1 ]] || return 0
  e2e_validate_task_run_db_archive \
    "$E2E_ROOT_DIR" \
    "$dir" \
    "${E2E_GITHUB_INDEX_DB:-.github/cache/github-index.sqlite}"
}

e2e_guard_evidence_updated_epoch() {
  local evidence_root=$1 profile=$2
  python3 - "$evidence_root" "$profile" <<'PY'
import json
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

evidence_root = Path(sys.argv[1])
expected_profile = sys.argv[2]
manifest_path = evidence_root / "run-manifest.json"
report_path = evidence_root / "task-report.md"
resolve_path = evidence_root / "profile-resolve.md"
markdown_field_re = re.compile(r"^- `([A-Za-z0-9_.-]+)`:\s*(.*?)\s*$")
max_future_us = time.time_ns() // 1000 + 300 * 1_000_000


def parse_epoch_us(raw: object) -> int:
    if not isinstance(raw, str) or not raw.strip():
        raise ValueError("missing timestamp")
    parsed = datetime.fromisoformat(raw.strip())
    if parsed.tzinfo is None or parsed.utcoffset() is None:
        raise ValueError("timezone is required")
    parsed_utc = parsed.astimezone(timezone.utc)
    epoch = datetime(1970, 1, 1, tzinfo=timezone.utc)
    delta = parsed_utc - epoch
    value = (
        (delta.days * 86400 + delta.seconds) * 1_000_000
        + delta.microseconds
    )
    if value < 0:
        raise ValueError("timestamp predates Unix epoch")
    if value > max_future_us:
        raise ValueError("timestamp is implausibly far in the future")
    return value


def parse_report_fields(report: str) -> dict[str, str]:
    lines = report.splitlines()
    if len(lines) < 5 or lines[:4] != ["# 任务报告", "", "## 基本信息", ""]:
        raise ValueError("noncanonical report heading")
    fields: dict[str, str] = {}
    index = 4
    while index < len(lines) and lines[index] != "":
        match = markdown_field_re.fullmatch(lines[index])
        if match is None:
            raise ValueError("noncanonical report basic-info field")
        key, value = match.groups()
        if key in fields:
            raise ValueError(f"duplicate report field: {key}")
        fields[key] = value.strip()
        index += 1
    if fields.get("profile") != expected_profile:
        raise ValueError("report profile mismatch")
    if fields.get("status") != "completed":
        raise ValueError("report is not completed")
    if not fields.get("updated_at"):
        raise ValueError("report updated_at missing")
    return fields


def unique_object(pairs: list[tuple[str, object]]) -> dict[str, object]:
    result: dict[str, object] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def reject_json_constant(value: str) -> object:
    raise ValueError(f"non-standard JSON constant: {value}")


try:
    report = report_path.read_text(encoding="utf-8")
    report_fields = parse_report_fields(report)
    updated_us = parse_epoch_us(report_fields["updated_at"])
    if manifest_path.is_symlink():
        raise ValueError("manifest symlinks are not accepted")
    if manifest_path.exists():
        manifest = json.loads(
            manifest_path.read_text(encoding="utf-8"),
            object_pairs_hook=unique_object,
            parse_constant=reject_json_constant,
        )
        if not isinstance(manifest, dict):
            raise ValueError("manifest must be a JSON object")
        if manifest.get("profile") != expected_profile:
            raise ValueError("manifest profile mismatch")
        if manifest.get("status") != "completed":
            raise ValueError("manifest is not completed")
        updated_us = parse_epoch_us(manifest.get("updated_at"))
        if "started_at" in manifest and parse_epoch_us(manifest.get("started_at")) > updated_us:
            raise ValueError("manifest started_at is after updated_at")
        resolve_lines = resolve_path.read_text(encoding="utf-8").splitlines()
        resolve_fields: dict[str, str] = {}
        for line in resolve_lines[2:]:
            if line == "":
                break
            match = markdown_field_re.fullmatch(line)
            if match is None or match.group(1) in resolve_fields:
                raise ValueError("noncanonical resolve header")
            resolve_fields[match.group(1)] = match.group(2)
        expanded_nodes = int(resolve_fields.get("expanded_node_count", ""))
        node_counts = manifest.get("node_counts")
        if not isinstance(node_counts, dict) or node_counts.get("total") != expanded_nodes:
            raise ValueError("manifest/resolve node-count mismatch")
        node_re = re.compile(
            r"^([0-9]+)\. `([^`]+)` source=`([^`]+)` module=`([^`]+)` "
            r"owner=`([^`]+)` function=`([^`]+)`$"
        )
        try:
            nodes_heading = resolve_lines.index("## Nodes")
        except ValueError as exc:
            raise ValueError("resolve nodes heading missing") from exc
        resolve_nodes: list[str] = []
        resolve_numbers: list[int] = []
        for line in resolve_lines[nodes_heading + 1 :]:
            if not line:
                continue
            match = node_re.fullmatch(line)
            if match is None:
                raise ValueError("noncanonical resolve node")
            resolve_numbers.append(int(match.group(1)))
            resolve_nodes.append(match.group(2))
        if resolve_numbers != list(range(1, expanded_nodes + 1)):
            raise ValueError("resolve node numbering mismatch")
        if len(resolve_nodes) != expanded_nodes or len(set(resolve_nodes)) != expanded_nodes:
            raise ValueError("resolve node IDs are incomplete or duplicated")
        manifest_nodes = manifest.get("nodes")
        if not isinstance(manifest_nodes, list) or len(manifest_nodes) != expanded_nodes:
            raise ValueError("manifest node list mismatch")
        manifest_node_ids: list[str] = []
        for node in manifest_nodes:
            if not isinstance(node, dict) or not isinstance(node.get("node_id"), str):
                raise ValueError("noncanonical manifest node")
            if node.get("status") != "PASS":
                raise ValueError("completed manifest contains a non-PASS node")
            manifest_node_ids.append(node["node_id"])
        if manifest_node_ids != resolve_nodes or len(set(manifest_node_ids)) != expanded_nodes:
            raise ValueError("manifest/resolve node-ID mismatch")
        if node_counts.get("by_status") != {"PASS": expanded_nodes}:
            raise ValueError("completed manifest status counts are not all PASS")
except (
    OSError,
    OverflowError,
    TypeError,
    UnicodeError,
    ValueError,
    json.JSONDecodeError,
):
    raise SystemExit(1)

print(updated_us)
PY
}

e2e_guard_find_evidence_for_profile() {
  local profile=$1 min_change_us=$2 dir report evidence_root evidence_real evidence_epoch_us task_root_real
  local best_dir= best_epoch_us=-1
  task_root_real=$(realpath -e -- "$E2E_ROOT_DIR/.github/task-runs" 2>/dev/null) || return 1
  for dir in "${E2E_GUARD_EVIDENCE_DIRS[@]}" "${E2E_GUARD_AUTO_EVIDENCE_DIRS[@]}"; do
    [[ -n $dir ]] || continue
    if [[ $dir = /* ]]; then
      evidence_root=$dir
    else
      evidence_root="$E2E_ROOT_DIR/${dir#./}"
    fi
    evidence_real=$(realpath -e -- "$evidence_root" 2>/dev/null) || continue
    [[ $evidence_real = "$evidence_root" && -d $evidence_root && ! -L $evidence_root ]] || continue
    case "$evidence_real" in
      "$task_root_real"/*) ;;
      *) continue ;;
    esac
    report="$evidence_root/task-report.md"
    [[ -f $report && ! -L $report ]] || continue
    if e2e_guard_evidence_has_db_recall "$evidence_root" "$profile" &&
       e2e_guard_evidence_has_db_archive "$evidence_root" &&
       e2e_validate_task_run_bundle "$evidence_root" "$profile" &&
       evidence_epoch_us=$(e2e_guard_evidence_updated_epoch "$evidence_root" "$profile") &&
       [[ $evidence_epoch_us =~ ^[0-9]+$ ]] &&
       (( evidence_epoch_us >= min_change_us )) &&
       (( evidence_epoch_us > best_epoch_us )) &&
       e2e_validate_evidence_index "$E2E_ROOT_DIR" "$evidence_root" "$profile" &&
       e2e_validate_completion_marker "$evidence_root" "$profile"; then
      best_epoch_us=$evidence_epoch_us
      best_dir=${dir#./}
    fi
  done
  [[ -n $best_dir ]] || return 1
  printf '%s\n' "$best_dir"
}

e2e_guard_run() {
  local path i profile reason evidence missing=0
  E2E_GUARD_PROFILES=()
  E2E_GUARD_PROFILE_REASONS=()
  E2E_GUARD_PROFILE_MTIME_US=()

  e2e_guard_collect_paths || return $?
  for path in "${E2E_GUARD_PATHS[@]}"; do
    e2e_guard_profiles_for_path "${path#./}"
  done

  printf '[agent-e2e-guard] mode=%s changed_paths=%s required_profiles=%s\n' \
    "$E2E_GUARD_MODE" "${#E2E_GUARD_PATHS[@]}" "${#E2E_GUARD_PROFILES[@]}"

  if [[ ${#E2E_GUARD_PROFILES[@]} -eq 0 ]]; then
    printf '[agent-e2e-guard] PASS no profile-triggering paths\n'
    return 0
  fi

  for i in "${!E2E_GUARD_PROFILES[@]}"; do
    profile=${E2E_GUARD_PROFILES[$i]}
    reason=${E2E_GUARD_PROFILE_REASONS[$i]}
    if evidence=$(e2e_guard_find_evidence_for_profile "$profile" "${E2E_GUARD_PROFILE_MTIME_US[$i]}"); then
      printf '[agent-e2e-guard] PASS profile=%s evidence=%s reason=%s\n' "$profile" "$evidence" "$reason"
    else
      printf '[agent-e2e-guard] %s missing_evidence profile=%s reason=%s suggested=\"scripts/agent-e2e.sh --profile %s --task-slug <task> --stop-on-fail\"\n' \
        "$( [[ $E2E_GUARD_MODE = strict ]] && printf FAIL || printf WARN )" \
        "$profile" "$reason" "$profile"
      missing=1
    fi
  done

  if [[ $missing -ne 0 && $E2E_GUARD_MODE = strict ]]; then
    return 1
  fi
  return 0
}

dispatch_profile() {
  local i node module function owner inputs outputs source
  for i in "${!PROFILE_NODE_IDS[@]}"; do
    node=${PROFILE_NODE_IDS[$i]}
    module=${PROFILE_MODULES[$i]}
    function=${PROFILE_FUNCTIONS[$i]}
    owner=${PROFILE_OWNERS[$i]}
    inputs=${PROFILE_INPUTS[$i]}
    outputs=${PROFILE_OUTPUTS[$i]}
    source=${PROFILE_SOURCES[$i]}

    E2E_CURRENT_NODE_ID=$node
    E2E_CURRENT_MODULE=$module
    E2E_CURRENT_OWNER=$owner
    E2E_CURRENT_SOURCE_PROFILE=$source
    E2E_CURRENT_FUNCTION=$function

    if ! declare -F "$function" >/dev/null 2>&1; then
      E2E_OVERALL_RC=1
      e2e_record_node "$node" "$owner" "$module" "FAIL" "$inputs" "missing function: $function" "<none>" || true
      e2e_append_dispatch "$node" "FAIL" "$owner" "$module" "$function" "$inputs" "missing function" "<none>" "补 scripts/e2e/modules 中的实现" || true
      [[ $E2E_KEEP_GOING -eq 0 ]] && break
      continue
    fi

    if ! e2e_run_function_node "$node" "$owner" "$module" "$function" "$inputs" "$outputs"; then
      E2E_OVERALL_RC=1
      [[ $E2E_KEEP_GOING -eq 0 ]] && break
    fi
  done
}

main() {
  parse_args "$@"

  if [[ $E2E_LIST_PROFILES -eq 1 ]]; then
    list_profiles
    exit $?
  fi

  if [[ $E2E_VALIDATE_ALL_PROFILES -eq 1 ]]; then
    validate_all_profiles
    exit $?
  fi

  if [[ $E2E_GUARD -eq 1 ]]; then
    e2e_guard_run
    exit $?
  fi

  reset_profile_arrays
  load_profile "$E2E_PROFILE"
  validate_profile_boundary "$E2E_PROFILE" || exit 2

  if [[ $E2E_VALIDATE_PROFILE -eq 1 ]]; then
    validate_loaded_profile "$E2E_PROFILE"
    exit $?
  fi

  e2e_validate_scenario_runtime_isolation "$E2E_PROFILE" || exit 2

  E2E_STARTED_AT=$(e2e_now)
  E2E_OVERALL_RC=0
  E2E_SKIP_COUNT=0
  e2e_allocate_run_dir || exit 1
  e2e_init_dispatch_log || exit 1
  if e2e_refresh_live_index_for_recall; then
    E2E_LIVE_INDEX_REFRESH_OK=1
  else
    E2E_LIVE_INDEX_REFRESH_OK=0
    E2E_OVERALL_RC=1
  fi
  e2e_generate_context_brief || E2E_OVERALL_RC=1
  e2e_generate_profile_resolve || E2E_OVERALL_RC=1

  echo "[agent-e2e] profile=$E2E_PROFILE"
  echo "[agent-e2e] run_dir=$(e2e_relpath "$E2E_RUN_DIR")"
  dispatch_profile
  if ! e2e_render_report; then
    E2E_OVERALL_RC=1
    e2e_render_report || true
  fi
  echo "[agent-e2e] report=$(e2e_relpath "$E2E_REPORT_FILE")"
  echo "[agent-e2e] dispatch=$(e2e_relpath "$E2E_DISPATCH_FILE")"
  exit "$E2E_OVERALL_RC"
}

main "$@"
