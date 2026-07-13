#!/usr/bin/env bash

set -euo pipefail

readonly ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
readonly TASK_SLUG=2026-07-13-rv64-t3i-drain-retire-redundancy
readonly TASK_DIR="$ROOT_DIR/.github/task-runs/$TASK_SLUG"
readonly TASK_TMP="$ROOT_DIR/tmp/$TASK_SLUG"
readonly BUILD_DIR="$TASK_TMP/sta-build/NpcTop-200MHz"
readonly OUT_DIR="$TASK_TMP/fresh-sta-archive"
readonly ARCHIVE_NAME=NpcTop-200MHz-t3i-drain-retire-redundancy.tar.zst
readonly ARCHIVE="$OUT_DIR/$ARCHIVE_NAME"
readonly SOURCE_NUL="$OUT_DIR/source-manifest.nul"
readonly SOURCE_TXT="$OUT_DIR/source-manifest.txt"
readonly INVENTORY="$OUT_DIR/source-inventory.tsv"
readonly CONTENTS="$OUT_DIR/archive-contents.txt"
readonly PROVENANCE="$OUT_DIR/archive-provenance.txt"
readonly SUMS="$OUT_DIR/SHA256SUMS"
readonly STA_PROVENANCE="$TASK_TMP/sta-provenance.md"
readonly SYNTH_AUDIT="$TASK_DIR/evidence/synthesis/audit.json"
readonly FOCUSED_DIR="$TASK_DIR/evidence/opensta-focused-fresh"
readonly GLOBAL_DIR="$TASK_DIR/evidence/opensta-fresh"

usage() {
  cat <<'EOF'
Usage: archive-fresh-sta.sh [--dry-run]

Archive the completed T3I fresh 200 MHz synthesis and fresh OpenSTA evidence.
The default mode refuses missing/empty inputs and refuses to overwrite an
existing fresh-sta-archive directory.  --dry-run performs the same input,
provenance, and path checks without creating or changing any file.

Before running, sta-provenance.md must exist at:
  tmp/2026-07-13-rv64-t3i-drain-retire-redundancy/sta-provenance.md
It must bind the run with exact `period_ns=5.0` and `netlist_sha256=<sha>` lines.
EOF
}

die() {
  printf '[T3I-STA-ARCHIVE] FAIL: %s\n' "$*" >&2
  exit 2
}

assert_under() {
  local path=$1
  local root=$2
  local resolved_path resolved_root
  resolved_path=$(realpath -m -- "$path")
  resolved_root=$(realpath -m -- "$root")
  case "$resolved_path" in
    "$resolved_root"/*) ;;
    *) die "path escapes allowed root: $path (allowed $root)" ;;
  esac
}

require_regular() {
  local path=$1
  local allowed_root=$2
  assert_under "$path" "$allowed_root"
  [[ -f $path && ! -L $path && -s $path ]] \
    || die "missing, empty, or non-regular input: $path"
}

validate_checksum_manifest() {
  local manifest=$1
  local allowed_root=$2
  local line digest marker path count=0

  while IFS= read -r line || [[ -n $line ]]; do
    [[ $line =~ ^([0-9a-f]{64})\ ([\ \*])(.+)$ ]] \
      || die "malformed sha256 manifest line in $manifest: $line"
    digest=${BASH_REMATCH[1]}
    marker=${BASH_REMATCH[2]}
    path=${BASH_REMATCH[3]}
    [[ $marker == ' ' ]] || die "binary-mode checksum entry is not expected: $path"
    [[ $path == /* ]] || die "manifest path is not absolute: $path"
    require_regular "$path" "$allowed_root"
    ((count += 1))
  done <"$manifest"
  ((count > 0)) || die "empty checksum manifest: $manifest"
  sha256sum --strict -c "$manifest" >/dev/null \
    || die "checksum verification failed: $manifest"
}

validate_machine_provenance() {
  local netlist=$1
  local netlist_sha
  netlist_sha=$(sha256sum "$netlist" | cut -d' ' -f1)

  grep -Fxq 'period_ns=5.0' "$STA_PROVENANCE" \
    || die "sta-provenance.md lacks exact period_ns=5.0 binding"
  grep -Fxq "netlist_sha256=$netlist_sha" "$STA_PROVENANCE" \
    || die "sta-provenance.md lacks the fresh netlist hash binding"

  python3 - "$SYNTH_AUDIT" "$GLOBAL_DIR/summary.json" \
    "$GLOBAL_DIR/opensta-current-complete.txt" \
    "$FOCUSED_DIR/opensta-t3i-focused-complete.txt" \
    "$netlist" <<'PY'
import hashlib
import json
import sys
from pathlib import Path

audit_path, summary_path, global_marker_path, focused_marker_path, netlist_path = (
    map(Path, sys.argv[1:])
)
netlist = netlist_path.resolve()
netlist_sha = hashlib.sha256(netlist.read_bytes()).hexdigest()
audit = json.loads(audit_path.read_text())
summary = json.loads(summary_path.read_text())

if audit.get("netlist_sha256") != netlist_sha:
    raise SystemExit("synthesis audit is not bound to the archived netlist")
if audit.get("module_count") != 110 or audit.get("error_lines") != 0:
    raise SystemExit("synthesis audit does not describe a clean 110-module result")
if summary.get("period_ns") != 5.0 or summary.get("path_count") != 40:
    raise SystemExit("global STA summary is not the exact 5 ns/top40 result")
if summary.get("combinational_loops") != 0:
    raise SystemExit("global STA summary reports a combinational loop")

def marker(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text().splitlines():
        if line.count("=") != 1:
            raise SystemExit(f"malformed completion marker: {path}")
        key, value = line.split("=", 1)
        if not key or key in result:
            raise SystemExit(f"duplicate/empty completion key: {path}")
        result[key] = value
    return result

expected_common = {
    "status": "COMPLETE",
    "period_ns": "5.0",
    "netlist": str(netlist),
    "netlist_sha256": netlist_sha,
}
global_marker = marker(global_marker_path)
if global_marker != expected_common:
    raise SystemExit("global STA completion marker/provenance mismatch")
focused_marker = marker(focused_marker_path)
if focused_marker != {**expected_common, "expect": "absent"}:
    raise SystemExit("focused STA completion marker/provenance mismatch")
PY
}

validate_inputs() {
  local path
  local netlist="$BUILD_DIR/NpcTop.netlist.v"
  local -a tmp_inputs=(
    "$BUILD_DIR/NpcTop.netlist.v"
    "$BUILD_DIR/NpcTop.netlist.v.sim"
    "$BUILD_DIR/abc.sdc"
    "$BUILD_DIR/synth_check.txt"
    "$BUILD_DIR/synth_stat.txt"
    "$BUILD_DIR/yosys.log"
    "$TASK_TMP/synth-exit-status.txt"
    "$TASK_TMP/synth-input-hash-cmp.txt"
    "$TASK_TMP/synth-rtl-inputs.pre.sha256"
    "$TASK_TMP/synth-rtl-inputs.post.sha256"
    "$TASK_TMP/synth-vsrc-tree.pre.sha256"
    "$TASK_TMP/synth-vsrc-tree.post.sha256"
    "$TASK_TMP/synth-flow-inputs.pre.sha256"
    "$TASK_TMP/synth-flow-inputs.post.sha256"
    "$TASK_TMP/synth-provenance.pre.txt"
    "$STA_PROVENANCE"
  )
  local -a task_inputs=(
    "$SYNTH_AUDIT"
    "$FOCUSED_DIR/opensta-console.log"
    "$FOCUSED_DIR/checker.log"
    "$FOCUSED_DIR/opensta-t3i-focused-complete.txt"
    "$FOCUSED_DIR/opensta-t3i-focused-counts.txt"
    "$FOCUSED_DIR/opensta-t3i-focused-objects.txt"
    "$FOCUSED_DIR/opensta-t3i-focused-queries.txt"
    "$FOCUSED_DIR/opensta-t3i-retire-fanout-endpoints.txt"
    "$FOCUSED_DIR/opensta-t3i-retire-to-fetch.rpt"
    "$FOCUSED_DIR/opensta-t3i-retire-to-pending-trap.rpt"
    "$FOCUSED_DIR/opensta-t3i-rob-count-to-fetch.rpt"
    "$FOCUSED_DIR/opensta-t3i-rob-count-to-pending-trap.rpt"
    "$GLOBAL_DIR/opensta-console.log"
    "$GLOBAL_DIR/checker.log"
    "$GLOBAL_DIR/opensta-current-check-setup.txt"
    "$GLOBAL_DIR/opensta-current-top40.rpt"
    "$GLOBAL_DIR/opensta-current-power.rpt"
    "$GLOBAL_DIR/opensta-current-complete.txt"
    "$GLOBAL_DIR/summary.json"
  )

  [[ $(git -C "$ROOT_DIR" rev-parse --show-toplevel) == "$ROOT_DIR" ]] \
    || die "script is not rooted at the expected Git worktree"
  assert_under "$TASK_DIR" "$ROOT_DIR"
  assert_under "$TASK_TMP" "$ROOT_DIR"
  assert_under "$OUT_DIR" "$TASK_TMP"
  [[ ! -e $OUT_DIR ]] || die "refusing stale archive output: $OUT_DIR"

  for path in "${tmp_inputs[@]}"; do
    require_regular "$path" "$TASK_TMP"
  done
  for path in "${task_inputs[@]}"; do
    require_regular "$path" "$TASK_DIR"
  done

  [[ $(<"$TASK_TMP/synth-exit-status.txt") == 0 ]] \
    || die "synthesis exit status is not zero"
  mapfile -t freeze_lines <"$TASK_TMP/synth-input-hash-cmp.txt"
  [[ ${#freeze_lines[@]} -eq 3 \
     && ${freeze_lines[0]} == 'rtl_inputs=PASS' \
     && ${freeze_lines[1]} == 'vsrc_tree=PASS' \
     && ${freeze_lines[2]} == 'flow_inputs=PASS' ]] \
    || die "synthesis input-freeze result is not the exact three-line PASS"

  cmp -s "$TASK_TMP/synth-rtl-inputs.pre.sha256" \
    "$TASK_TMP/synth-rtl-inputs.post.sha256" \
    || die "pre/post synthesis manifest mismatch: rtl"
  cmp -s "$TASK_TMP/synth-vsrc-tree.pre.sha256" \
    "$TASK_TMP/synth-vsrc-tree.post.sha256" \
    || die "pre/post synthesis manifest mismatch: vsrc-tree"
  cmp -s "$TASK_TMP/synth-flow-inputs.pre.sha256" \
    "$TASK_TMP/synth-flow-inputs.post.sha256" \
    || die "pre/post synthesis manifest mismatch: flow"
  validate_checksum_manifest "$TASK_TMP/synth-rtl-inputs.post.sha256" "$ROOT_DIR"
  validate_checksum_manifest "$TASK_TMP/synth-vsrc-tree.post.sha256" "$ROOT_DIR"
  validate_checksum_manifest "$TASK_TMP/synth-flow-inputs.post.sha256" "$ROOT_DIR"

  grep -Fq '[T3I-OPENSTA-FOCUSED] PASS:' "$FOCUSED_DIR/checker.log" \
    || die "focused OpenSTA checker PASS marker missing"
  grep -Fq '[T3I-GLOBAL-STA] PASS:' "$GLOBAL_DIR/checker.log" \
    || die "global OpenSTA checker PASS marker missing"
  validate_machine_provenance "$netlist"
}

source_paths() {
  printf '%s\0' \
    "tmp/$TASK_SLUG/sta-build/NpcTop-200MHz/NpcTop.netlist.v" \
    "tmp/$TASK_SLUG/sta-build/NpcTop-200MHz/NpcTop.netlist.v.sim" \
    "tmp/$TASK_SLUG/sta-build/NpcTop-200MHz/abc.sdc" \
    "tmp/$TASK_SLUG/sta-build/NpcTop-200MHz/synth_check.txt" \
    "tmp/$TASK_SLUG/sta-build/NpcTop-200MHz/synth_stat.txt" \
    "tmp/$TASK_SLUG/sta-build/NpcTop-200MHz/yosys.log" \
    "tmp/$TASK_SLUG/synth-exit-status.txt" \
    "tmp/$TASK_SLUG/synth-input-hash-cmp.txt" \
    "tmp/$TASK_SLUG/synth-rtl-inputs.pre.sha256" \
    "tmp/$TASK_SLUG/synth-rtl-inputs.post.sha256" \
    "tmp/$TASK_SLUG/synth-vsrc-tree.pre.sha256" \
    "tmp/$TASK_SLUG/synth-vsrc-tree.post.sha256" \
    "tmp/$TASK_SLUG/synth-flow-inputs.pre.sha256" \
    "tmp/$TASK_SLUG/synth-flow-inputs.post.sha256" \
    "tmp/$TASK_SLUG/synth-provenance.pre.txt" \
    "tmp/$TASK_SLUG/sta-provenance.md" \
    ".github/task-runs/$TASK_SLUG/evidence/synthesis/audit.json" \
    ".github/task-runs/$TASK_SLUG/evidence/opensta-focused-fresh/opensta-console.log" \
    ".github/task-runs/$TASK_SLUG/evidence/opensta-focused-fresh/checker.log" \
    ".github/task-runs/$TASK_SLUG/evidence/opensta-focused-fresh/opensta-t3i-focused-complete.txt" \
    ".github/task-runs/$TASK_SLUG/evidence/opensta-focused-fresh/opensta-t3i-focused-counts.txt" \
    ".github/task-runs/$TASK_SLUG/evidence/opensta-focused-fresh/opensta-t3i-focused-objects.txt" \
    ".github/task-runs/$TASK_SLUG/evidence/opensta-focused-fresh/opensta-t3i-focused-queries.txt" \
    ".github/task-runs/$TASK_SLUG/evidence/opensta-focused-fresh/opensta-t3i-retire-fanout-endpoints.txt" \
    ".github/task-runs/$TASK_SLUG/evidence/opensta-focused-fresh/opensta-t3i-retire-to-fetch.rpt" \
    ".github/task-runs/$TASK_SLUG/evidence/opensta-focused-fresh/opensta-t3i-retire-to-pending-trap.rpt" \
    ".github/task-runs/$TASK_SLUG/evidence/opensta-focused-fresh/opensta-t3i-rob-count-to-fetch.rpt" \
    ".github/task-runs/$TASK_SLUG/evidence/opensta-focused-fresh/opensta-t3i-rob-count-to-pending-trap.rpt" \
    ".github/task-runs/$TASK_SLUG/evidence/opensta-fresh/opensta-console.log" \
    ".github/task-runs/$TASK_SLUG/evidence/opensta-fresh/checker.log" \
    ".github/task-runs/$TASK_SLUG/evidence/opensta-fresh/opensta-current-check-setup.txt" \
    ".github/task-runs/$TASK_SLUG/evidence/opensta-fresh/opensta-current-top40.rpt" \
    ".github/task-runs/$TASK_SLUG/evidence/opensta-fresh/opensta-current-power.rpt" \
    ".github/task-runs/$TASK_SLUG/evidence/opensta-fresh/opensta-current-complete.txt" \
    ".github/task-runs/$TASK_SLUG/evidence/opensta-fresh/summary.json" \
    "tmp/$TASK_SLUG/fresh-sta-archive/source-manifest.nul" \
    "tmp/$TASK_SLUG/fresh-sta-archive/source-manifest.txt" \
    "tmp/$TASK_SLUG/fresh-sta-archive/archive-provenance.txt"
}

mode=archive
case ${1:-} in
  '') ;;
  --dry-run) mode=dry-run ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 64 ;;
esac
[[ $# -le 1 ]] || { usage >&2; exit 64; }

for tool in git realpath sha256sum cmp grep python3 tar zstd stat; do
  command -v "$tool" >/dev/null || die "required tool not found: $tool"
done
validate_inputs

if [[ $mode == dry-run ]]; then
  printf '[T3I-STA-ARCHIVE] DRY-RUN PASS: inputs/provenance frozen; output=%s\n' \
    "$ARCHIVE"
  exit 0
fi

mkdir -- "$OUT_DIR"
source_paths >"$SOURCE_NUL"
tr '\0' '\n' <"$SOURCE_NUL" >"$SOURCE_TXT"

{
  printf 'format=T3I_FRESH_STA_ARCHIVE_V1\n'
  printf 'created_at=%s\n' "$(date --iso-8601=seconds)"
  printf 'task_slug=%s\n' "$TASK_SLUG"
  printf 'head=%s\n' "$(git -C "$ROOT_DIR" rev-parse HEAD)"
  printf 'script_sha256=%s\n' "$(sha256sum "${BASH_SOURCE[0]}" | cut -d' ' -f1)"
  printf 'source_manifest_sha256=%s\n' \
    "$(sha256sum "$SOURCE_NUL" | cut -d' ' -f1)"
  printf 'netlist_sha256=%s\n' \
    "$(sha256sum "$BUILD_DIR/NpcTop.netlist.v" | cut -d' ' -f1)"
  printf 'yosys_log_sha256=%s\n' \
    "$(sha256sum "$BUILD_DIR/yosys.log" | cut -d' ' -f1)"
  printf 'synthesis_audit_sha256=%s\n' \
    "$(sha256sum "$SYNTH_AUDIT" | cut -d' ' -f1)"
  printf 'global_sta_summary_sha256=%s\n' \
    "$(sha256sum "$GLOBAL_DIR/summary.json" | cut -d' ' -f1)"
  printf 'sta_provenance_sha256=%s\n' \
    "$(sha256sum "$STA_PROVENANCE" | cut -d' ' -f1)"
  printf 'zstd=%s\n' "$(zstd --version | head -1)"
} >"$PROVENANCE"

printf 'bytes\tsha256\tpath\n' >"$INVENTORY"
while IFS= read -r -d '' relative; do
  [[ $relative != /* && $relative != *'..'* ]] \
    || die "unsafe archive member path: $relative"
  require_regular "$ROOT_DIR/$relative" "$ROOT_DIR"
  printf '%s\t%s\t%s\n' \
    "$(stat -c '%s' -- "$ROOT_DIR/$relative")" \
    "$(sha256sum -- "$ROOT_DIR/$relative" | cut -d' ' -f1)" \
    "$relative" >>"$INVENTORY"
done <"$SOURCE_NUL"

archive_tmp="$ARCHIVE.tmp.$$"
trap 'rm -f -- "$archive_tmp"' EXIT
tar -C "$ROOT_DIR" --create --file=- --null --files-from="$SOURCE_NUL" \
  | zstd -T1 -10 -o "$archive_tmp"
mv -- "$archive_tmp" "$ARCHIVE"
trap - EXIT

zstd --test --quiet -- "$ARCHIVE"
zstd -dc -- "$ARCHIVE" | tar --list --file=- >"$CONTENTS"
cmp -s "$SOURCE_TXT" "$CONTENTS" \
  || die "archive contents differ from the exact source manifest"

(
  cd "$ROOT_DIR"
  sha256sum -- \
    "${ARCHIVE#"$ROOT_DIR/"}" \
    "${SOURCE_NUL#"$ROOT_DIR/"}" \
    "${SOURCE_TXT#"$ROOT_DIR/"}" \
    "${INVENTORY#"$ROOT_DIR/"}" \
    "${CONTENTS#"$ROOT_DIR/"}" \
    "${PROVENANCE#"$ROOT_DIR/"}" \
    >"${SUMS#"$ROOT_DIR/"}"
  sha256sum --strict -c "${SUMS#"$ROOT_DIR/"}"
)

printf '[T3I-STA-ARCHIVE] PASS: members=%s bytes=%s archive=%s\n' \
  "$(wc -l <"$CONTENTS")" "$(stat -c '%s' "$ARCHIVE")" "$ARCHIVE"
