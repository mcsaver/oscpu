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
  local profile rc=0
  while IFS= read -r profile; do
    reset_profile_arrays
    load_profile "$profile"
    validate_loaded_profile "$profile" || rc=1
    validate_profile_boundary "$profile" || rc=1
  done < <(list_profiles)
  return "$rc"
}

E2E_GUARD_PATHS=()
E2E_GUARD_PROFILES=()
E2E_GUARD_PROFILE_REASONS=()
E2E_GUARD_PROFILE_MTIMES=()
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

e2e_guard_add_profile() {
  local profile=$1 reason=$2 i mtime=0
  if [[ -e $E2E_ROOT_DIR/$reason ]]; then
    mtime=$(stat -c '%Y' "$E2E_ROOT_DIR/$reason" 2>/dev/null || printf '0')
  fi
  for i in "${!E2E_GUARD_PROFILES[@]}"; do
    if [[ ${E2E_GUARD_PROFILES[$i]} = "$profile" ]]; then
      E2E_GUARD_PROFILE_REASONS[$i]="${E2E_GUARD_PROFILE_REASONS[$i]}; $reason"
      if [[ $mtime -gt ${E2E_GUARD_PROFILE_MTIMES[$i]} ]]; then
        E2E_GUARD_PROFILE_MTIMES[$i]=$mtime
      fi
      return 0
    fi
  done
  E2E_GUARD_PROFILES+=("$profile")
  E2E_GUARD_PROFILE_REASONS+=("$reason")
  E2E_GUARD_PROFILE_MTIMES+=("$mtime")
}

e2e_guard_collect_paths() {
  local path
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
    while IFS= read -r path || [[ -n $path ]]; do
      e2e_guard_add_unique_path "$path"
    done < <(
      {
        git -C "$E2E_ROOT_DIR" diff --name-only "$E2E_GUARD_SINCE_REF" -- 2>/dev/null || true
        git -C "$E2E_ROOT_DIR" diff --name-only --cached -- 2>/dev/null || true
        git -C "$E2E_ROOT_DIR" diff --name-only -- 2>/dev/null || true
        git -C "$E2E_ROOT_DIR" ls-files --others --exclude-standard 2>/dev/null || true
      } | awk 'NF' | sort -u
    )
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

e2e_guard_report_matches_profile() {
  local report=$1 profile=$2
  [[ -f $report ]] || return 1
  if ! grep -Fq -- '- `status`: completed' "$report" &&
     ! grep -Fq -- 'status=completed' "$report"; then
    return 1
  fi
  grep -Fq -- '- `profile`: '"$profile" "$report" ||
    grep -Fq -- "profile=$profile" "$report" ||
    grep -Fq -- "profile: $profile" "$report"
}

e2e_guard_evidence_has_db_recall() {
  local dir=$1
  [[ -f $dir/context-brief.md ]] || return 1
  [[ -f $dir/profile-resolve.md ]] || return 1
  [[ -f $dir/evidence-index.md ]] || return 1
}

e2e_guard_find_evidence_for_profile() {
  local profile=$1 min_mtime=$2 dir report report_mtime evidence_root
  for dir in "${E2E_GUARD_EVIDENCE_DIRS[@]}" "${E2E_GUARD_AUTO_EVIDENCE_DIRS[@]}"; do
    [[ -n $dir ]] || continue
    if [[ $dir = /* ]]; then
      evidence_root=$dir
    else
      evidence_root="$E2E_ROOT_DIR/${dir#./}"
    fi
    report="$evidence_root/task-report.md"
    [[ -f $report ]] || continue
    report_mtime=$(stat -c '%Y' "$report" 2>/dev/null || printf '0')
    if [[ $report_mtime -ge $min_mtime ]] &&
       e2e_guard_report_matches_profile "$report" "$profile" &&
       e2e_guard_evidence_has_db_recall "$evidence_root"; then
      printf '%s\n' "${dir#./}"
      return 0
    fi
  done
  return 1
}

e2e_guard_run() {
  local path i profile reason evidence missing=0
  E2E_GUARD_PROFILES=()
  E2E_GUARD_PROFILE_REASONS=()
  E2E_GUARD_PROFILE_MTIMES=()

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
    if evidence=$(e2e_guard_find_evidence_for_profile "$profile" "${E2E_GUARD_PROFILE_MTIMES[$i]}"); then
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
  local i node module function owner inputs outputs
  for i in "${!PROFILE_NODE_IDS[@]}"; do
    node=${PROFILE_NODE_IDS[$i]}
    module=${PROFILE_MODULES[$i]}
    function=${PROFILE_FUNCTIONS[$i]}
    owner=${PROFILE_OWNERS[$i]}
    inputs=${PROFILE_INPUTS[$i]}
    outputs=${PROFILE_OUTPUTS[$i]}

    if ! declare -F "$function" >/dev/null 2>&1; then
      e2e_record_node "$node" "$owner" "$module" "FAIL" "$inputs" "missing function: $function" "<none>"
      e2e_append_dispatch "$node" "FAIL" "$owner" "$module" "$function" "$inputs" "missing function" "<none>" "补 scripts/e2e/modules 中的实现"
      E2E_OVERALL_RC=1
      [[ $E2E_KEEP_GOING -eq 0 ]] && break
      continue
    fi

    E2E_CURRENT_NODE_ID=$node
    E2E_CURRENT_MODULE=$module
    E2E_CURRENT_OWNER=$owner
    e2e_run_function_node "$node" "$owner" "$module" "$function" "$inputs" "$outputs"
  done
}

main() {
  parse_args "$@"

  if [[ $E2E_LIST_PROFILES -eq 1 ]]; then
    list_profiles
    exit 0
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
  e2e_allocate_run_dir
  e2e_init_dispatch_log
  e2e_generate_context_brief
  e2e_generate_profile_resolve

  echo "[agent-e2e] profile=$E2E_PROFILE"
  echo "[agent-e2e] run_dir=$(e2e_relpath "$E2E_RUN_DIR")"
  dispatch_profile
  e2e_render_report
  echo "[agent-e2e] report=$(e2e_relpath "$E2E_REPORT_FILE")"
  echo "[agent-e2e] dispatch=$(e2e_relpath "$E2E_DISPATCH_FILE")"
  exit "$E2E_OVERALL_RC"
}

main "$@"
