#!/usr/bin/env bash

set -euo pipefail
export LC_ALL=C

readonly ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
readonly TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation"
readonly EVIDENCE_ROOT="$TASK_DIR/evidence"
readonly OUT_DIR_RAW=${1:-"$EVIDENCE_ROOT/current-contract-final"}
readonly OUT_DIR=$(realpath -m -- "$OUT_DIR_RAW")
readonly -a INPUTS=(
  "$ROOT_DIR/npc/rv64/vsrc/control/OooCsrAccessRequestMux.v"
  "$ROOT_DIR/npc/rv64/vsrc/control/OooControlPlane.v"
  "$ROOT_DIR/npc/rv64/vsrc/core/OooCoreTopGlue.v"
  "$ROOT_DIR/npc/rv64/vsrc/core/NpcCoreTop.v"
  "$ROOT_DIR/npc/rv64/vsrc/core/CsrFile.v"
  "$ROOT_DIR/npc/rv64/testbench/scripts/check_tb_result.py"
  "$TASK_DIR/t3k_csr_contract.py"
  "$TASK_DIR/check-t3k-source-contract.py"
  "$TASK_DIR/prove-t3k-legality-domain.py"
  "$TASK_DIR/run-t3k-source-mutations.py"
  "$TASK_DIR/tb-t3k-csr-equiv-negative.sv"
  "$TASK_DIR/check-t3k-negative-probe-log.py"
  "$TASK_DIR/run-t3k-negative-probes.sh"
  "$TASK_DIR/run-t3k-contract-evidence.sh"
)

die() {
  printf '[T3K-CONTRACT-EVIDENCE] FAIL: %s\n' "$*" >&2
  exit 2
}

[[ $(git -C "$ROOT_DIR" rev-parse --show-toplevel) == "$ROOT_DIR" ]] \
  || die "not rooted at the expected Git worktree"
case "$OUT_DIR" in
  "$(realpath -m -- "$EVIDENCE_ROOT")"/*) ;;
  *) die "output escapes the T3K evidence root: $OUT_DIR" ;;
esac
[[ ! -e "$OUT_DIR" ]] || die "refusing stale contract evidence: $OUT_DIR"
for input in "${INPUTS[@]}"; do
  [[ -f "$input" && ! -L "$input" && -s "$input" ]] \
    || die "missing, empty, or symlink current input: $input"
done

mkdir -p -- "$OUT_DIR"
(
  cd "$ROOT_DIR"
  sha256sum -- "${INPUTS[@]#"$ROOT_DIR"/}"
) >"$OUT_DIR/inputs.pre.sha256"

python3 "$TASK_DIR/check-t3k-source-contract.py" "$ROOT_DIR" \
  >"$OUT_DIR/source-contract.log" 2>&1
python3 "$TASK_DIR/prove-t3k-legality-domain.py" "$ROOT_DIR" \
  >"$OUT_DIR/legality-domain-proof.log" 2>&1
python3 "$TASK_DIR/run-t3k-source-mutations.py" "$ROOT_DIR" \
  >"$OUT_DIR/source-mutations.log" 2>&1
bash "$TASK_DIR/run-t3k-negative-probes.sh" "$OUT_DIR/negative-csr-equiv" \
  >"$OUT_DIR/negative-probe-console.log" 2>&1

(
  cd "$ROOT_DIR"
  sha256sum -- "${INPUTS[@]#"$ROOT_DIR"/}"
) >"$OUT_DIR/inputs.post.sha256"
cmp -s "$OUT_DIR/inputs.pre.sha256" "$OUT_DIR/inputs.post.sha256" \
  || die "RTL/contract inputs changed while evidence was running"
(
  cd "$ROOT_DIR"
  sha256sum --strict -c "${OUT_DIR#"$ROOT_DIR/"}/inputs.post.sha256"
) >/dev/null || die "post-run input checksum verification failed"

declare -A REQUIRED_MARKERS=(
  [source-contract.log]='[T3K-SOURCE-CONTRACT] PASS '
  [legality-domain-proof.log]='[T3K-LEGALITY-DOMAIN-PROOF] PASS '
  [source-mutations.log]='[T3K-SOURCE-MUTATIONS] PASS '
  [negative-probe-console.log]='[T3K-NEGATIVE-PROBES] PASS '
)
for log_name in "${!REQUIRED_MARKERS[@]}"; do
  marker=${REQUIRED_MARKERS[$log_name]}
  [[ $(grep -F -c -- "$marker" "$OUT_DIR/$log_name") -eq 1 ]] \
    || die "$log_name lacks exactly one canonical PASS marker"
  if grep -Eq '\[T3K-[^]]+\] FAIL' "$OUT_DIR/$log_name"; then
    die "$log_name contains an unexpected T3K FAIL marker"
  fi
done

[[ $(grep -F -c '[CSR-LEGAL-VIEW-EQUIV]' "$OUT_DIR/negative-csr-equiv/result.log") -eq 1 ]] \
  || die "negative assertion marker is not exact-one"
[[ $(grep -F -c '[T3K-NEGATIVE-PREMISE] valid=1 same_tuple=1 forced_divergence=1' \
       "$OUT_DIR/negative-csr-equiv/result.log") -eq 1 ]] \
  || die "negative non-vacuous premise marker is not exact-one"
[[ $(grep -F -c '[T3K-NEGATIVE-LOG-SELFTEST] PASS ' \
       "$OUT_DIR/negative-csr-equiv/audit.log") -eq 1 ]] \
  || die "negative log fail-closed self-test marker is missing"

{
  printf 'status=COMPLETE\n'
  printf 'git_head=%s\n' "$(git -C "$ROOT_DIR" rev-parse HEAD)"
  printf 'raw_domain_cases=720896\n'
  printf 'routing_cases=45056\n'
  printf 'isolation_cases=45056\n'
  printf 'mutation_cases=10\n'
  printf 'negative_assertion_marker_count=1\n'
  printf 'input_manifest_sha256=%s\n' \
    "$(sha256sum "$OUT_DIR/inputs.post.sha256" | cut -d' ' -f1)"
  for artifact in \
    source-contract.log \
    legality-domain-proof.log \
    source-mutations.log \
    negative-probe-console.log \
    negative-csr-equiv/result.log \
    negative-csr-equiv/audit.log; do
    key=${artifact//\//_}
    key=${key//-/_}
    key=${key//./_}
    printf '%s_sha256=%s\n' "$key" "$(sha256sum "$OUT_DIR/$artifact" | cut -d' ' -f1)"
  done
} >"$OUT_DIR/complete.txt"

printf '[T3K-CONTRACT-EVIDENCE] PASS fresh_dir=%s raw_cases=720896 mutation_cases=10 negative_assertion=exact-one\n' \
  "$OUT_DIR"
