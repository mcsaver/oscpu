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

说明:
  profile 定义放在 .github/e2e/profiles/*.tsv。
  具体模块 gate 放在 scripts/e2e/modules/*.sh。
  本脚本只负责展开 profile、调度节点和生成 task-run 证据包。
  validate 模式只检查 profile 展开和函数绑定，不执行具体 gate。

示例:
  scripts/agent-e2e.sh --list-profiles
  scripts/agent-e2e.sh --validate-all-profiles
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

reset_profile_arrays() {
  PROFILE_NODE_IDS=()
  PROFILE_MODULES=()
  PROFILE_FUNCTIONS=()
  PROFILE_OWNERS=()
  PROFILE_INPUTS=()
  PROFILE_OUTPUTS=()
}

load_profile() {
  local profile=$1
  local profile_file="$E2E_ROOT_DIR/.github/e2e/profiles/${profile}.tsv"
  if [[ ! -f $profile_file ]]; then
    echo "找不到 e2e profile: $profile_file" >&2
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
  done < "$profile_file"
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
  done < <(list_profiles)
  return "$rc"
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

  reset_profile_arrays
  load_profile "$E2E_PROFILE"

  if [[ $E2E_VALIDATE_PROFILE -eq 1 ]]; then
    validate_loaded_profile "$E2E_PROFILE"
    exit $?
  fi

  E2E_STARTED_AT=$(e2e_now)
  E2E_OVERALL_RC=0
  E2E_SKIP_COUNT=0
  e2e_allocate_run_dir
  e2e_init_dispatch_log

  echo "[agent-e2e] profile=$E2E_PROFILE"
  echo "[agent-e2e] run_dir=$(e2e_relpath "$E2E_RUN_DIR")"
  dispatch_profile
  e2e_render_report
  echo "[agent-e2e] report=$(e2e_relpath "$E2E_REPORT_FILE")"
  echo "[agent-e2e] dispatch=$(e2e_relpath "$E2E_DISPATCH_FILE")"
  exit "$E2E_OVERALL_RC"
}

main "$@"
