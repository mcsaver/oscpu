#!/usr/bin/env bash
set -euo pipefail

root="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
cd "$root"

python3 \
  "$root/.github/task-runs/2026-07-22-rv64-v9l-functional-aggregate-current-design/run-functional-aggregate.py"

python3 -m unittest \
  npc.rv64.eval.ppa.tests.test_functional_aggregate \
  -v

python3 -m unittest \
  npc.rv64.eval.ppa.tests.test_arch_stable_freeze.PureFunctionTests \
  npc.rv64.eval.ppa.tests.test_arch_stable_freeze.EndToEndFixtureTests \
  -v

sed -n '1,120p' \
  "$root/npc/rv64/eval/ppa/evidence/functional-aggregate.log"
