#!/usr/bin/env bash

set -euo pipefail
export LC_ALL=C

readonly ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
readonly TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3j-fetch-read-window"
readonly EVIDENCE_ROOT="$TASK_DIR/evidence"
readonly OUT_DIR="$EVIDENCE_ROOT/current-contract-final"
readonly BRIDGE="$ROOT_DIR/npc/rv64/vsrc/frontend/OooFetchAxiBridge.v"
readonly CACHE="$ROOT_DIR/npc/rv64/vsrc/cache/OooFetchPacketCache.v"

die() {
  printf '[T3J-CURRENT-CONTRACT-EVIDENCE] FAIL: %s\n' "$*" >&2
  exit 2
}

[[ $(git -C "$ROOT_DIR" rev-parse --show-toplevel) == "$ROOT_DIR" ]] \
  || die "not rooted at the expected Git worktree"
case $(realpath -m -- "$OUT_DIR") in
  "$(realpath -m -- "$EVIDENCE_ROOT")"/*) ;;
  *) die "final output escapes the T3J evidence root" ;;
esac
[[ ! -e $OUT_DIR ]] \
  || die "refusing stale final evidence directory: $OUT_DIR"

readonly -a INPUTS=(
  "$BRIDGE"
  "$CACHE"
  "$TASK_DIR/t3j_verilog_contract.py"
  "$TASK_DIR/check-t3j-source-contract.py"
  "$TASK_DIR/prove-t3j-window-domain.py"
  "$TASK_DIR/run-t3j-source-mutations.py"
)
for input in "${INPUTS[@]}"; do
  [[ -f $input && ! -L $input && -s $input ]] \
    || die "missing, empty, or non-regular current input: $input"
done

mkdir -- "$OUT_DIR"
(
  cd "$ROOT_DIR"
  sha256sum -- "${INPUTS[@]#"$ROOT_DIR"/}"
) >"$OUT_DIR/inputs.pre.sha256"

python3 "$TASK_DIR/check-t3j-source-contract.py" "$ROOT_DIR" \
  >"$OUT_DIR/source-contract.log" 2>&1
python3 "$TASK_DIR/prove-t3j-window-domain.py" "$ROOT_DIR" \
  >"$OUT_DIR/window-domain-proof.log" 2>&1
python3 "$TASK_DIR/run-t3j-source-mutations.py" "$ROOT_DIR" \
  >"$OUT_DIR/source-mutations.log" 2>&1

(
  cd "$ROOT_DIR"
  sha256sum -- "${INPUTS[@]#"$ROOT_DIR"/}"
) >"$OUT_DIR/inputs.post.sha256"
cmp -s "$OUT_DIR/inputs.pre.sha256" "$OUT_DIR/inputs.post.sha256" \
  || die "RTL/proof inputs changed while current evidence was running"
(
  cd "$ROOT_DIR"
  sha256sum --strict -c \
    "${OUT_DIR#"$ROOT_DIR/"}/inputs.post.sha256"
) >/dev/null || die "post-run input checksum verification failed"

declare -A REQUIRED_MARKERS=(
  [source-contract.log]='[T3J-SOURCE-CONTRACT] PASS '
  [window-domain-proof.log]='[T3J-WINDOW-DOMAIN-PROOF] PASS '
  [source-mutations.log]='[T3J-SOURCE-MUTATIONS] PASS '
)
for log_name in "${!REQUIRED_MARKERS[@]}"; do
  marker=${REQUIRED_MARKERS[$log_name]}
  [[ $(grep -F -c -- "$marker" "$OUT_DIR/$log_name") -eq 1 ]] \
    || die "$log_name lacks exactly one current PASS marker"
  if grep -Eq '\[(T3J-[^]]+)\] FAIL' "$OUT_DIR/$log_name"; then
    die "$log_name contains a fail marker"
  fi
done

{
  printf 'status=COMPLETE\n'
  printf 'git_head=%s\n' "$(git -C "$ROOT_DIR" rev-parse HEAD)"
  printf 'input_manifest_sha256=%s\n' \
    "$(sha256sum "$OUT_DIR/inputs.post.sha256" | cut -d' ' -f1)"
  printf 'source_contract_log_sha256=%s\n' \
    "$(sha256sum "$OUT_DIR/source-contract.log" | cut -d' ' -f1)"
  printf 'window_domain_proof_log_sha256=%s\n' \
    "$(sha256sum "$OUT_DIR/window-domain-proof.log" | cut -d' ' -f1)"
  printf 'source_mutations_log_sha256=%s\n' \
    "$(sha256sum "$OUT_DIR/source-mutations.log" | cut -d' ' -f1)"
} >"$OUT_DIR/complete.txt"

printf '[T3J-CURRENT-CONTRACT-EVIDENCE] PASS: fresh_dir=%s\n' "$OUT_DIR"
