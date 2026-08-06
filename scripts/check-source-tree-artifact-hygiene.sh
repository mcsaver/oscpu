#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-root)
      repo_root=$2
      shift 2
      ;;
    *)
      printf '[SOURCE-ARTIFACT-HYGIENE][FAIL] unknown argument: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

repo_root=$(cd "$repo_root" && pwd -P)
if ! git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf '[SOURCE-ARTIFACT-HYGIENE][FAIL] not a Git worktree: %s\n' "$repo_root" >&2
  exit 1
fi

violations=()
tracked_count=0
allowed_build_descriptions=0

while IFS= read -r -d '' path; do
  tracked_count=$((tracked_count + 1))

  case "$path" in
    tool/softfloat/build/Linux-x86_64-GCC/.gitignore|\
    tool/softfloat/build/Linux-x86_64-GCC/Makefile|\
    tool/softfloat/build/Linux-x86_64-GCC/platform.h|\
    ysyxSoC/rocket-chip/dependencies/chisel/.github/workflows/build-scala-cli-template/*)
      allowed_build_descriptions=$((allowed_build_descriptions + 1))
      continue
      ;;
  esac

  case "$path" in
    build/*|*/build/*|build-*/*|*/build-*/*|build_*/*|*/build_*/*|\
    obj_dir/*|*/obj_dir/*|CMakeFiles/*|*/CMakeFiles/*|\
    *__pycache__/*|*.pyc|*.pyo|*.pyd|*.vvp|*.vcd|*.fst|*.fsdb|*.wlf|*.vpd|*.ghw|*.o)
      violations+=("$path")
      continue
      ;;
  esac

  case "$path" in
    yosys-sta/Makefile|yosys-sta/scripts/*)
      ;;
    yosys-sta/*)
      violations+=("$path")
      ;;
    .github/runtime-artifacts/.gitkeep)
      ;;
    .github/runtime-artifacts/*)
      violations+=("$path")
      ;;
  esac
done < <(git -C "$repo_root" ls-files -z)

if ((${#violations[@]} != 0)); then
  limit=${#violations[@]}
  if ((limit > 100)); then
    limit=100
  fi
  for ((index = 0; index < limit; index++)); do
    printf '[SOURCE-ARTIFACT-HYGIENE][VIOLATION] %s\n' "${violations[index]}" >&2
  done
  printf '[SOURCE-ARTIFACT-HYGIENE][FAIL] tracked_generated=%d shown=%d\n' \
    "${#violations[@]}" "$limit" >&2
  exit 1
fi

require_ignored() {
  local probe=$1
  if ! git -C "$repo_root" check-ignore --no-index -q -- "$probe"; then
    printf '[SOURCE-ARTIFACT-HYGIENE][FAIL] generated probe is not ignored: %s\n' \
      "$probe" >&2
    exit 1
  fi
}

require_visible() {
  local probe=$1
  if git -C "$repo_root" check-ignore --no-index -q -- "$probe"; then
    printf '[SOURCE-ARTIFACT-HYGIENE][FAIL] source probe is unexpectedly ignored: %s\n' \
      "$probe" >&2
    exit 1
  fi
}

require_ignored 'npc/rv64/build/artifact-hygiene-probe.o'
require_ignored 'npc/rv64/testbench/build-hygiene/artifact-hygiene-probe.vvp'
require_ignored 'yosys-sta/reports/artifact-hygiene-probe.rpt'
require_ignored '.github/runtime-artifacts/artifact-hygiene-probe.bin'
require_ignored '.github/task-runs/artifact-hygiene-probe/__pycache__/checker.pyc'
require_ignored '.github/task-runs/artifact-hygiene-probe/checker.pyc'
require_ignored '.github/task-runs/artifact-hygiene-probe/checker.pyd'
require_visible 'E_4/preprocessing/artifact-hygiene-probe.s'
require_visible 'E_4/preprocessing/artifact-hygiene-probe.S'
require_visible 'tool/softfloat/build/Linux-x86_64-GCC/Makefile'
require_visible \
  'ysyxSoC/rocket-chip/dependencies/chisel/.github/workflows/build-scala-cli-template/chisel-template.scala'

printf '[SOURCE-ARTIFACT-HYGIENE][PASS] tracked=%d generated=0 allowed_build_descriptions=%d probes=11\n' \
  "$tracked_count" "$allowed_build_descriptions"
