#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_DIR="$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery"
CHECKER="$TASK_DIR/check-r4-p0a-fixed-benchmarks.py"
BASELINE_BIN="$ROOT/tmp/2026-07-15-rv64-ppa-architecture-recovery/build-r4-s0-posttranslate/NpcSimTop"
BASELINE_BUILD="$ROOT/tmp/2026-07-15-rv64-ppa-architecture-recovery/build-r4-s0-posttranslate"
BASELINE_BINDING="$TASK_DIR/evidence/r4-s0-correctness-checkpoint/performance/rep01/coremark"
BASELINE_PRE_MANIFEST="$BASELINE_BINDING/binding.pre.sha256"
BASELINE_POST_MANIFEST="$BASELINE_BINDING/binding.post.sha256"
BASELINE_VERFILES="$BASELINE_BUILD/obj_dir/VNpcSimTop__verFiles.dat"
CORE_IMAGE="$ROOT/am-kernels/benchmarks/coremark/build/coremark-riscv64-npc.bin"
DHR_IMAGE="$ROOT/am-kernels/benchmarks/dhrystone/build/dhrystone-riscv64-npc.bin"
DEFAULT_EVIDENCE="$TASK_DIR/evidence/r4-p0a-wb-valid/performance-abbaab"

CANDIDATE_BIN=${P0A_BIN:-}
CANDIDATE_VERFILES=${P0A_VERFILES:-}
EVIDENCE=${P0A_EVIDENCE_DIR:-$DEFAULT_EVIDENCE}
TIMEOUT_SECONDS=${P0A_TIMEOUT_SECONDS:-1200}
MAX_CYCLES=${P0A_MAX_CYCLES:-20000000}

usage() {
  cat <<'EOF'
Usage:
  run-r4-p0a-fixed-benchmarks-abbaab.sh --candidate-bin PATH [options]

Required:
  --candidate-bin PATH       Fresh P0-A NpcSimTop binary. Alternatively set P0A_BIN.

Options:
  --candidate-verfiles PATH  Candidate obj_dir/VNpcSimTop__verFiles.dat.
                             Default: <candidate-dir>/obj_dir/VNpcSimTop__verFiles.dat
  --evidence-dir PATH        Fresh output directory inside the workspace.
  --timeout-seconds N        Per-window host timeout (default: 1200).
  --max-cycles N             Per-window guest cycle bound (default: 20000000).
  -h, --help                 Show this help without running benchmarks.

The fixed order is A-B-B-A-A-B independently for CoreMark and Dhrystone.
The runner refuses stale output and requires all selected P0-A region counters
to remain cycle-exact with the R4-S0 checkpoint.
EOF
}

while (($# > 0)); do
  case "$1" in
    --candidate-bin)
      (($# >= 2)) || { printf '[P0A-ABBAAB] missing value for %s\n' "$1" >&2; exit 64; }
      CANDIDATE_BIN=$2
      shift 2
      ;;
    --candidate-verfiles)
      (($# >= 2)) || { printf '[P0A-ABBAAB] missing value for %s\n' "$1" >&2; exit 64; }
      CANDIDATE_VERFILES=$2
      shift 2
      ;;
    --evidence-dir)
      (($# >= 2)) || { printf '[P0A-ABBAAB] missing value for %s\n' "$1" >&2; exit 64; }
      EVIDENCE=$2
      shift 2
      ;;
    --timeout-seconds)
      (($# >= 2)) || { printf '[P0A-ABBAAB] missing value for %s\n' "$1" >&2; exit 64; }
      TIMEOUT_SECONDS=$2
      shift 2
      ;;
    --max-cycles)
      (($# >= 2)) || { printf '[P0A-ABBAAB] missing value for %s\n' "$1" >&2; exit 64; }
      MAX_CYCLES=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf '[P0A-ABBAAB] unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

[[ -n $CANDIDATE_BIN ]] || {
  printf '[P0A-ABBAAB] --candidate-bin or P0A_BIN is required\n' >&2
  exit 64
}
[[ $TIMEOUT_SECONDS =~ ^[1-9][0-9]*$ ]] || {
  printf '[P0A-ABBAAB] timeout must be a positive integer\n' >&2
  exit 64
}
[[ $MAX_CYCLES =~ ^[1-9][0-9]*$ ]] || {
  printf '[P0A-ABBAAB] max-cycles must be a positive integer\n' >&2
  exit 64
}

CANDIDATE_BIN=$(realpath -e "$CANDIDATE_BIN")
if [[ -z $CANDIDATE_VERFILES ]]; then
  CANDIDATE_VERFILES="$(dirname "$CANDIDATE_BIN")/obj_dir/VNpcSimTop__verFiles.dat"
fi
CANDIDATE_VERFILES=$(realpath -e "$CANDIDATE_VERFILES")
EVIDENCE=$(realpath -m "$EVIDENCE")
case "$EVIDENCE/" in
  "$ROOT"/*) ;;
  *)
    printf '[P0A-ABBAAB] evidence directory must stay inside workspace: %s\n' \
      "$EVIDENCE" >&2
    exit 64
    ;;
esac

for required in \
  "$CHECKER" \
  "$BASELINE_BIN" \
  "$BASELINE_PRE_MANIFEST" \
  "$BASELINE_POST_MANIFEST" \
  "$BASELINE_VERFILES" \
  "$CANDIDATE_BIN" \
  "$CANDIDATE_VERFILES" \
  "$CORE_IMAGE" \
  "$DHR_IMAGE"; do
  [[ -f $required ]] || {
    printf '[P0A-ABBAAB] missing required file: %s\n' "$required" >&2
    exit 2
  }
done
[[ -x $BASELINE_BIN && -x $CANDIDATE_BIN ]] || {
  printf '[P0A-ABBAAB] both simulator binaries must be executable\n' >&2
  exit 2
}
[[ ! -e $EVIDENCE ]] || {
  printf '[P0A-ABBAAB] refusing stale evidence directory: %s\n' "$EVIDENCE" >&2
  exit 2
}

mkdir -p "$EVIDENCE/bindings"
BASELINE_INPUTS="$EVIDENCE/bindings/a-r4-s0-source-inputs.json"
CANDIDATE_INPUTS="$EVIDENCE/bindings/b-p0a-source-inputs.json"

python3 "$CHECKER" normalize-historical \
  --binary "$BASELINE_BIN" \
  --pre-manifest "$BASELINE_PRE_MANIFEST" \
  --post-manifest "$BASELINE_POST_MANIFEST" \
  --verfiles "$BASELINE_VERFILES" \
  --output "$BASELINE_INPUTS"

python3 "$CHECKER" capture-live \
  --binary "$CANDIDATE_BIN" \
  --verfiles "$CANDIDATE_VERFILES" \
  --output "$CANDIDATE_INPUTS"

# 在付出 12 个长窗口前先拒绝“候选其实还是 S0 输入”的假 A/B。
python3 "$CHECKER" compare-inputs \
  --baseline "$BASELINE_INPUTS" \
  --candidate "$CANDIDATE_INPUTS"

read -r CORE_START CORE_STOP CORE_CYCLES CORE_RETIRED < <(
  python3 "$CHECKER" contract coremark
)
read -r DHR_START DHR_STOP DHR_CYCLES DHR_RETIRED < <(
  python3 "$CHECKER" contract dhrystone_10000
)

run_one() {
  local benchmark=$1
  local ordinal=$2
  local design=$3
  local binary=$4
  local source_inputs=$5
  local image=$6
  local start_pc=$7
  local stop_pc=$8
  local expected_cycles=$9
  local expected_retired=${10}
  local lower_design
  local destination
  local run_rc

  lower_design=${design,,}
  destination=$(printf '%s/%s/%02d-%s' "$EVIDENCE" "$benchmark" "$ordinal" "$lower_design")
  [[ ! -e $destination ]] || {
    printf '[P0A-ABBAAB] refusing stale window: %s\n' "$destination" >&2
    exit 2
  }
  mkdir -p "$destination"

  python3 "$CHECKER" snapshot \
    --design "$design" \
    --ordinal "$ordinal" \
    --benchmark "$benchmark" \
    --binary "$binary" \
    --image "$image" \
    --source-inputs "$source_inputs" \
    --runner "${BASH_SOURCE[0]}" \
    --timeout-seconds "$TIMEOUT_SECONDS" \
    --max-cycles "$MAX_CYCLES" \
    --output "$destination/binding.pre.json"

  set +e
  NPC_REGION_START_PC="$start_pc" NPC_REGION_END_PC="$stop_pc" \
    timeout "$TIMEOUT_SECONDS" "$binary" "$image" \
      --no-progress --max-cycles "$MAX_CYCLES" \
      >"$destination/raw.log" 2>&1
  run_rc=$?
  set -e
  printf '%s\n' "$run_rc" >"$destination/run.exit-status.txt"

  # 即使进程失败也先做 post binding，避免把中途输入漂移误报成单纯 benchmark 失败。
  python3 "$CHECKER" snapshot \
    --design "$design" \
    --ordinal "$ordinal" \
    --benchmark "$benchmark" \
    --binary "$binary" \
    --image "$image" \
    --source-inputs "$source_inputs" \
    --runner "${BASH_SOURCE[0]}" \
    --timeout-seconds "$TIMEOUT_SECONDS" \
    --max-cycles "$MAX_CYCLES" \
    --output "$destination/binding.post.json"
  cmp "$destination/binding.pre.json" "$destination/binding.post.json"

  if ((run_rc != 0)); then
    printf '[P0A-ABBAAB] process failed benchmark=%s ordinal=%02d design=%s rc=%d\n' \
      "$benchmark" "$ordinal" "$design" "$run_rc" >&2
    exit "$run_rc"
  fi

  # canonical v3 parser owns semantic, exit, region arithmetic and exact-counter checks.
  python3 "$CHECKER" validate-log \
    --log "$destination/raw.log" \
    --benchmark "$benchmark" \
    --expected-cycles "$expected_cycles" \
    --expected-retired "$expected_retired" \
    --output "$destination/parsed.json"

  printf '[P0A-ABBAAB] PASS benchmark=%s ordinal=%02d design=%s cycles=%s retired=%s\n' \
    "$benchmark" "$ordinal" "$design" "$expected_cycles" "$expected_retired"
}

DESIGNS=(A B B A A B)
for benchmark in coremark dhrystone_10000; do
  case "$benchmark" in
    coremark)
      image=$CORE_IMAGE
      start_pc=$CORE_START
      stop_pc=$CORE_STOP
      expected_cycles=$CORE_CYCLES
      expected_retired=$CORE_RETIRED
      ;;
    dhrystone_10000)
      image=$DHR_IMAGE
      start_pc=$DHR_START
      stop_pc=$DHR_STOP
      expected_cycles=$DHR_CYCLES
      expected_retired=$DHR_RETIRED
      ;;
    *)
      printf '[P0A-ABBAAB] internal benchmark dispatch error: %s\n' "$benchmark" >&2
      exit 70
      ;;
  esac
  for index in "${!DESIGNS[@]}"; do
    ordinal=$((index + 1))
    design=${DESIGNS[$index]}
    if [[ $design == A ]]; then
      binary=$BASELINE_BIN
      source_inputs=$BASELINE_INPUTS
    else
      binary=$CANDIDATE_BIN
      source_inputs=$CANDIDATE_INPUTS
    fi
    run_one \
      "$benchmark" "$ordinal" "$design" "$binary" "$source_inputs" \
      "$image" "$start_pc" "$stop_pc" "$expected_cycles" "$expected_retired"
  done
done

python3 "$CHECKER" validate-runset \
  --evidence-dir "$EVIDENCE" \
  --require-cycle-exact \
  --output "$EVIDENCE/summary.json"

find "$EVIDENCE" -type f ! -name SHA256SUMS -print0 \
  | LC_ALL=C sort -z \
  | xargs -0 sha256sum >"$EVIDENCE/SHA256SUMS"

printf '[P0A-ABBAAB] PASS evidence=%s summary=%s\n' \
  "$EVIDENCE" "$EVIDENCE/summary.json"
