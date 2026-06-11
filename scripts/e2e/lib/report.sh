#!/usr/bin/env bash

# task-run 记录层：所有 e2e profile 都通过这里生成统一证据包。

e2e_allocate_run_dir() {
  local date_stamp base candidate idx
  date_stamp=$(date '+%Y-%m-%d')

  if [[ -z ${E2E_RUN_DIR:-} ]]; then
    base="$E2E_ROOT_DIR/.github/task-runs/${date_stamp}-${E2E_TASK_SLUG}"
    candidate=$base
    idx=2
    while [[ -e $candidate ]]; do
      candidate="${base}-${idx}"
      idx=$((idx + 1))
    done
    E2E_RUN_DIR=$candidate
  else
    E2E_RUN_DIR=$(e2e_abspath_from_root "$E2E_RUN_DIR")
  fi

  E2E_EVIDENCE_DIR="$E2E_RUN_DIR/evidence"
  E2E_REPORT_FILE="$E2E_RUN_DIR/task-report.md"
  E2E_DISPATCH_FILE="$E2E_RUN_DIR/dispatch-log.md"
  E2E_NODES_FILE="$E2E_RUN_DIR/nodes.tsv"
  mkdir -p "$E2E_EVIDENCE_DIR"
  : > "$E2E_NODES_FILE"
}

e2e_sanitize_task_run_text_artifacts() {
  local file
  [[ -n ${E2E_RUN_DIR:-} && -d $E2E_RUN_DIR ]] || return 0

  # 统一清理 e2e 证据包中的行尾空白和 CR，避免生成物过不了 git diff --check。
  while IFS= read -r -d '' file; do
    LC_ALL=C sed -i 's/[ \t\r]*$//' "$file"
  done < <(
    find "$E2E_RUN_DIR" -type f \
      \( -name '*.md' -o -name '*.tsv' -o -name '*.log' -o -name '*.cmd' -o -name '*.txt' \) \
      -print0
  )
}

e2e_init_dispatch_log() {
  cat > "$E2E_DISPATCH_FILE" <<EOF
# Dispatch Log

## 基本信息

- \`task_id\`: $(basename "$E2E_RUN_DIR")
- \`task_slug\`: $E2E_TASK_SLUG
- \`graph_template\`: modular-agent-e2e
- \`profile\`: $E2E_PROFILE
- \`log_policy\`: append-only

---
EOF
}

e2e_append_dispatch() {
  local node_id=$1 status=$2 owner=$3 module=$4 action=$5 inputs=$6 outputs=$7 evidence=$8 next_step=$9 notes=${10:-}
  cat >> "$E2E_DISPATCH_FILE" <<EOF

### [$(e2e_now)] \`$node_id\` - \`$status\`

- \`owner_agent\`: $owner
- \`module\`: $module
- \`trigger\`: e2e:$E2E_PROFILE
- \`depends_on\`: ${E2E_NODE_DEPENDS_ON:-}
- \`inputs\`: $inputs
- \`action\`: $action
- \`outputs\`: $outputs
- \`evidence\`: $evidence
- \`handoff_to\`: ${E2E_NODE_HANDOFF_TO:-}
- \`next_step\`: $next_step
- \`notes\`: $notes
EOF
}

e2e_record_node() {
  local node_id=$1 owner=$2 module=$3 status=$4 inputs=$5 outputs=$6 evidence=$7
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$node_id" "$owner" "$module" "$status" "$inputs" "$outputs" "$evidence" >> "$E2E_NODES_FILE"
}

e2e_record_skip() {
  local node_id=$1 owner=$2 module=$3 inputs=$4 reason=$5 next_step=$6
  local log_file="$E2E_EVIDENCE_DIR/${node_id}.log"
  local evidence
  evidence=$(e2e_relpath "$log_file")
  {
    printf 'SKIP %s\n' "$node_id"
    printf 'reason=%s\n' "$reason"
    printf 'next_step=%s\n' "$next_step"
  } > "$log_file"
  E2E_SKIP_COUNT=$((E2E_SKIP_COUNT + 1))
  e2e_record_node "$node_id" "$owner" "$module" "SKIP" "$inputs" "$reason" "$evidence"
  e2e_append_dispatch "$node_id" "SKIP" "$owner" "$module" "skip" "$inputs" "$reason" "$evidence" "$next_step"
}

e2e_run_function_node() {
  local node_id=$1 owner=$2 module=$3 function_name=$4 inputs=$5 outputs=$6
  local log_file="$E2E_EVIDENCE_DIR/${node_id}.log"
  local evidence
  evidence=$(e2e_relpath "$log_file")

  e2e_append_dispatch "$node_id" "in-progress" "$owner" "$module" "$function_name" "$inputs" "$outputs" "$evidence" "等待节点结果"
  local rc=0
  "$function_name" > "$log_file" 2>&1 || rc=$?
  if [[ $rc -eq 0 ]]; then
    e2e_record_node "$node_id" "$owner" "$module" "PASS" "$inputs" "$outputs" "$evidence"
    e2e_append_dispatch "$node_id" "PASS" "$owner" "$module" "$function_name" "$inputs" "$outputs" "$evidence" "进入下一节点"
    return 0
  fi

  if [[ $rc -eq 77 ]]; then
    E2E_SKIP_COUNT=$((E2E_SKIP_COUNT + 1))
    e2e_record_node "$node_id" "$owner" "$module" "SKIP" "$inputs" "$outputs" "$evidence"
    e2e_append_dispatch "$node_id" "SKIP" "$owner" "$module" "$function_name" "$inputs" "$outputs" "$evidence" "查看 SKIP 原因后切换配置或补依赖"
    return 0
  fi

  e2e_record_node "$node_id" "$owner" "$module" "FAIL" "$inputs" "exit=$rc" "$evidence"
  e2e_append_dispatch "$node_id" "FAIL" "$owner" "$module" "$function_name" "$inputs" "exit=$rc" "$evidence" "检查日志并按 regression-debug-loop 扩图"
  E2E_OVERALL_RC=1
  if [[ ${E2E_KEEP_GOING:-1} -eq 0 ]]; then
    e2e_render_report
    exit "$rc"
  fi
  return 0
}

e2e_run_shell_node() {
  local node_id=$1 owner=$2 module=$3 inputs=$4 outputs=$5 cmd=$6 timeout_note=${7:-} validator=${8:-}
  local log_file="$E2E_EVIDENCE_DIR/${node_id}.log"
  local cmd_file="$E2E_EVIDENCE_DIR/${node_id}.cmd"
  local evidence
  evidence="$(e2e_relpath "$log_file"), $(e2e_relpath "$cmd_file")"
  printf '%s\n' "$cmd" > "$cmd_file"

  e2e_append_dispatch "$node_id" "in-progress" "$owner" "$module" "$(e2e_relpath "$cmd_file")" "$inputs" "$outputs" "$evidence" "等待命令完成" "$timeout_note"
  local rc=0
  (cd "$E2E_ROOT_DIR" && bash -lc "$cmd") > "$log_file" 2>&1 || rc=$?
  if [[ $rc -eq 0 && -n $validator ]]; then
    "$validator" "$log_file" || rc=99
  fi

  if [[ $rc -eq 0 ]]; then
    e2e_record_node "$node_id" "$owner" "$module" "PASS" "$inputs" "$outputs" "$evidence"
    e2e_append_dispatch "$node_id" "PASS" "$owner" "$module" "$(e2e_relpath "$cmd_file")" "$inputs" "$outputs" "$evidence" "进入下一节点" "$timeout_note"
    return 0
  fi

  e2e_record_node "$node_id" "$owner" "$module" "FAIL" "$inputs" "exit=$rc" "$evidence"
  e2e_append_dispatch "$node_id" "FAIL" "$owner" "$module" "$(e2e_relpath "$cmd_file")" "$inputs" "exit=$rc" "$evidence" "检查日志并按 regression-debug-loop 扩图" "$timeout_note"
  E2E_OVERALL_RC=1
  if [[ ${E2E_KEEP_GOING:-1} -eq 0 ]]; then
    e2e_render_report
    exit "$rc"
  fi
  return 0
}

e2e_render_report() {
  local status updated final_result risk next_step
  updated=$(e2e_now)
  if [[ $E2E_OVERALL_RC -eq 0 ]]; then
    status=completed
    if [[ ${E2E_SKIP_COUNT:-0} -gt 0 ]]; then
      final_result="profile=$E2E_PROFILE 无 hard fail，但有 ${E2E_SKIP_COUNT} 个节点因当前环境配置或依赖边界跳过；不能把 SKIP 节点当作已验证。"
      risk="无 hard fail；SKIP 节点和 optional tool 缺失只作为后续节点风险。"
    else
      final_result="profile=$E2E_PROFILE 通过，当前 modular e2e 证据链可复用。"
      risk="无 hard fail；optional tool 缺失只作为后续节点风险。"
    fi
    next_step="按模块或跨模块目标选择更深 profile，或进入具体静态图。"
  else
    status=blocked
    final_result="profile=$E2E_PROFILE 存在失败节点；不能把后续工程判断建立在该节点上。"
    risk="需要先查看 evidence 日志，按 regression-debug-loop 补 reproduce/collect/localize。"
    next_step="修复失败节点或切换到更小 profile。"
  fi

  cat > "$E2E_REPORT_FILE" <<EOF
# Task Report

## 基本信息

- \`task_id\`: $(basename "$E2E_RUN_DIR")
- \`task_slug\`: $E2E_TASK_SLUG
- \`graph_template\`: modular-agent-e2e
- \`profile\`: $E2E_PROFILE
- \`graph_mode\`: static
- \`status\`: $status
- \`owner\`: agent-system + hardware-flow + module agents
- \`started_at\`: $E2E_STARTED_AT
- \`updated_at\`: $updated

## 任务目标

- \`source_request\`: 将 agent 系统从纯语言提示升级为分层、分模块、可闭环和可优化的 e2e 流水线
- \`goal\`: 依据 profile 执行模块化 e2e 节点，生成可复核证据包
- \`scope\`: profile=$E2E_PROFILE；不越级声明未执行模块或业务 gate 已完成

## 选图说明

- \`selected_template\`: modular-agent-e2e
- \`why_this_graph\`: 本 profile 从 \`.github/e2e/profiles/\` 读取节点，把 agent/instructions/memory 中的模块职责转换为可执行 gate。
- \`dynamic_nodes_added\`: 无
- \`why_dynamic_nodes_were_needed\`: 无

## 节点概览

| node_id | owner_agent | module | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------ | ------- | -------- |
EOF

  while IFS=$'\t' read -r node owner module node_status inputs outputs evidence; do
    printf '| `%s` | `%s` | `%s` | `%s` | %s | %s | %s |\n' "$node" "$owner" "$module" "$node_status" "$inputs" "$outputs" "$evidence" >> "$E2E_REPORT_FILE"
  done < "$E2E_NODES_FILE"

  cat >> "$E2E_REPORT_FILE" <<EOF

## 关键产物

- \`artifacts\`: $(e2e_relpath "$E2E_RUN_DIR")
- \`logs_or_traces\`: $(e2e_relpath "$E2E_EVIDENCE_DIR")
- \`profile_manifest\`: .github/e2e/profiles/$E2E_PROFILE.tsv
- \`linked_memory_updates\`: 由 agent 在收尾阶段按本轮稳定结论更新 memory

## 当前阻塞点

- \`blockers\`: $([[ $E2E_OVERALL_RC -eq 0 ]] && printf '无' || printf '存在失败节点，详见 evidence 日志')
- \`missing_dependencies\`: 见对应 tool/env 节点日志
- \`risk_assessment\`: $risk

## 下一步建议

1. $next_step
2. 对含 \`SKIP\` 的模块，先补依赖或切换到合适配置，再把该模块提升到 PASS 证据。

## 模板升级候选

- \`repeated_dynamic_subgraph\`: 无
- \`should_promote_to_static_template\`: 已作为 modular-agent-e2e profile 固化
- \`reason\`: profile + module library + task-run 证据包能把 agent 提示转为可执行流水线

## 收尾结论

- \`final_result\`: $final_result
- \`evidence_summary\`: 详见节点表与 \`evidence/\`
- \`notes\`: 这是模块化 e2e gate，不替代未执行模块的功能回归、DiffTest、Linux/Ubuntu 分层 gate 或 PPA/STA signoff。
EOF
  e2e_sanitize_task_run_text_artifacts
}
