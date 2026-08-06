#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
checker="${repo_root}/scripts/check-source-tree-artifact-hygiene.sh"
test_root=$(mktemp -d)

cleanup() {
  local rc=$?
  case "$test_root" in
    /tmp/*) rm -rf -- "$test_root" ;;
    *)
      printf '[SOURCE-ARTIFACT-HYGIENE-TEST][FAIL] unsafe test root: %s\n' \
        "$test_root" >&2
      ;;
  esac
  exit "$rc"
}
trap cleanup EXIT

make_fixture() {
  local target=$1
  mkdir -p \
    "${target}/E_4/preprocessing" \
    "${target}/scripts" \
    "${target}/tool/softfloat/build/Linux-x86_64-GCC" \
    "${target}/ysyxSoC/rocket-chip/dependencies/chisel/.github/workflows/build-scala-cli-template" \
    "${target}/yosys-sta/scripts" \
    "${target}/.github/runtime-artifacts"
  cp "${repo_root}/.gitignore" "${target}/.gitignore"
  printf 'source\n' >"${target}/E_4/preprocessing/source.s"
  printf 'source\n' >"${target}/scripts/build-helper.py"
  printf 'source\n' >"${target}/tool/softfloat/build/Linux-x86_64-GCC/Makefile"
  printf 'source\n' >"${target}/tool/softfloat/build/Linux-x86_64-GCC/platform.h"
  printf 'source\n' >"${target}/tool/softfloat/build/Linux-x86_64-GCC/.gitignore"
  printf 'source\n' \
    >"${target}/ysyxSoC/rocket-chip/dependencies/chisel/.github/workflows/build-scala-cli-template/chisel-template.scala"
  printf 'source\n' >"${target}/yosys-sta/Makefile"
  printf 'source\n' >"${target}/yosys-sta/scripts/flow.tcl"
  printf 'keep\n' >"${target}/.github/runtime-artifacts/.gitkeep"
  git -C "$target" init -q
  git -C "$target" add -f -- .
}

expect_fail() {
  local name=$1
  local target=$2
  if "$checker" --repo-root "$target" >"${test_root}/${name}.log" 2>&1; then
    printf '[SOURCE-ARTIFACT-HYGIENE-TEST][FAIL] negative case accepted: %s\n' \
      "$name" >&2
    exit 1
  fi
}

positive="${test_root}/positive"
make_fixture "$positive"
"$checker" --repo-root "$positive" >"${test_root}/positive.log"

pycache_case="${test_root}/tracked-pycache"
cp -a "$positive" "$pycache_case"
mkdir -p "${pycache_case}/module/__pycache__"
printf 'bytecode\n' >"${pycache_case}/module/__pycache__/unit.pyc"
git -C "$pycache_case" add -f -- module/__pycache__/unit.pyc
expect_fail tracked-pycache "$pycache_case"

pyd_case="${test_root}/tracked-pyd"
cp -a "$positive" "$pyd_case"
mkdir -p "${pyd_case}/module"
printf 'extension\n' >"${pyd_case}/module/unit.pyd"
git -C "$pyd_case" add -f -- module/unit.pyd
expect_fail tracked-pyd "$pyd_case"

build_case="${test_root}/tracked-build"
cp -a "$positive" "$build_case"
mkdir -p "${build_case}/module/build"
printf 'object\n' >"${build_case}/module/build/unit.o"
git -C "$build_case" add -f -- module/build/unit.o
expect_fail tracked-build "$build_case"

yosys_case="${test_root}/tracked-yosys-result"
cp -a "$positive" "$yosys_case"
mkdir -p "${yosys_case}/yosys-sta/reports"
printf 'report\n' >"${yosys_case}/yosys-sta/reports/timing.rpt"
git -C "$yosys_case" add -f -- yosys-sta/reports/timing.rpt
expect_fail tracked-yosys-result "$yosys_case"

runtime_case="${test_root}/tracked-runtime-artifact"
cp -a "$positive" "$runtime_case"
printf 'runtime\n' >"${runtime_case}/.github/runtime-artifacts/cache.bin"
git -C "$runtime_case" add -f -- .github/runtime-artifacts/cache.bin
expect_fail tracked-runtime-artifact "$runtime_case"

assembly_case="${test_root}/assembly-hidden"
cp -a "$positive" "$assembly_case"
printf '*.s\n' >>"${assembly_case}/.gitignore"
git -C "$assembly_case" add -f -- .gitignore
expect_fail assembly-hidden "$assembly_case"

github_pycache_case="${test_root}/github-pycache-reincluded"
cp -a "$positive" "$github_pycache_case"
grep -Fv \
  -e '.github/**/__pycache__/' \
  -e '.github/**/*.py[cod]' \
  "${positive}/.gitignore" >"${github_pycache_case}/.gitignore"
git -C "$github_pycache_case" add -f -- .gitignore
expect_fail github-pycache-reincluded "$github_pycache_case"

printf '%s\n' \
  '[SOURCE-ARTIFACT-HYGIENE-TEST][PASS] positive=1 negative=7 git_scope=index-only'
