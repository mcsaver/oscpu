#!/usr/bin/env bash

set -euo pipefail
export LC_ALL=C

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_SLUG=2026-07-13-rv64-t3k-csr-probe-isolation
TASK_DIR="$ROOT_DIR/.github/task-runs/$TASK_SLUG"
TASK_TMP="$ROOT_DIR/tmp/$TASK_SLUG"
OUT_DIR="$TASK_TMP/fresh-sta-archive"
ARCHIVE="$OUT_DIR/NpcTop-200MHz-t3k-csr-probe-isolation.tar.zst"

die() {
  printf '[T3K-STA-ARCHIVE] FAIL: %s\n' "$*" >&2
  exit 2
}

resolved_out=$(realpath -m -- "$OUT_DIR")
resolved_task=$(realpath -m -- "$TASK_TMP")
case "$resolved_out" in
  "$resolved_task"/*) ;;
  *) die "output escapes task tmp root: $resolved_out" ;;
esac
[[ ! -e $OUT_DIR ]] || die "refusing stale output: $OUT_DIR"

audit="$TASK_DIR/evidence/synthesis/audit.json"
summary="$TASK_DIR/evidence/opensta-fresh-t3k-root-final-v6/summary.json"
python3 - "$audit" "$summary" <<'PY'
import json
import sys
from pathlib import Path

audit = json.loads(Path(sys.argv[1]).read_text())
summary = json.loads(Path(sys.argv[2]).read_text())
assert audit["netlist_sha256"] == "0161d3d41300cd41a80f4da3cd649cc8defb98548c23eb324efc140fec583b32"
assert audit["module_count"] == 110 and audit["error_lines"] == 0
assert audit["input_counts"] == {"evidence": 9, "flow": 14, "liberty": 5, "rtl": 110, "tool_binary": 6, "vsrc": 133}
assert audit["dynamic_libraries_frozen"] is False
assert audit["tool_support_tree_frozen"] is False
assert summary["period_ns"] == 5.0 and summary["path_count"] == 40
assert summary["combinational_loops"] == 0
assert summary["wns_ns"] == -8.72 and summary["tns_ns"] == -199154.36
assert summary["target_200mhz_met"] is False
PY

grep -Fq '[T3K-FOCUSED-STA] PASS:' \
  "$TASK_DIR/evidence/opensta-focused-old-t3j-root-final-v6/checker.log" \
  || die 'old focused checker is not green'
grep -Fq '[T3K-FOCUSED-STA] PASS:' \
  "$TASK_DIR/evidence/opensta-focused-fresh-t3k-root-final-v6/checker.log" \
  || die 'fresh focused checker is not green'
grep -Fq '[T3K-GLOBAL-STA] PASS:' \
  "$TASK_DIR/evidence/opensta-fresh-t3k-root-final-v6/checker.log" \
  || die 'global checker is not green'

paths=(
  "tmp/$TASK_SLUG/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
  "tmp/$TASK_SLUG/sta-build/NpcTop-200MHz/NpcTop.netlist.v.sim"
  "tmp/$TASK_SLUG/sta-build/NpcTop-200MHz/abc.sdc"
  "tmp/$TASK_SLUG/sta-build/NpcTop-200MHz/synth_check.txt"
  "tmp/$TASK_SLUG/sta-build/NpcTop-200MHz/synth_stat.txt"
  "tmp/$TASK_SLUG/sta-build/NpcTop-200MHz/yosys.log"
  "tmp/$TASK_SLUG/synthesis-frozen-evidence-scripts"
  ".github/task-runs/$TASK_SLUG/evidence/synthesis"
  ".github/task-runs/$TASK_SLUG/evidence/netlist-structure-root-final-v6"
  ".github/task-runs/$TASK_SLUG/evidence/opensta-focused-old-t3j-root-final-v6"
  ".github/task-runs/$TASK_SLUG/evidence/opensta-focused-fresh-t3k-root-final-v6"
  ".github/task-runs/$TASK_SLUG/evidence/opensta-freeze-root-final-v6"
  ".github/task-runs/$TASK_SLUG/evidence/opensta-fresh-t3k-root-final-v6"
  "tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
)
while IFS= read -r path; do
  paths+=("$path")
done < <(find "tmp/$TASK_SLUG" -maxdepth 1 -type f -name 'synth-*' \
  ! -name 'synth-console.log' -printf '%p\n' | sort)

for path in "${paths[@]}"; do
  [[ -e $ROOT_DIR/$path && ! -L $ROOT_DIR/$path ]] || die "missing input: $path"
done
actual_netlist_sha=$(sha256sum \
  "$TASK_TMP/sta-build/NpcTop-200MHz/NpcTop.netlist.v" | cut -d' ' -f1)
[[ $actual_netlist_sha == 0161d3d41300cd41a80f4da3cd649cc8defb98548c23eb324efc140fec583b32 ]] \
  || die 'fresh netlist hash drifted'

mkdir -p -- "$OUT_DIR"
printf '%s\0' "${paths[@]}" | sort -zu >"$OUT_DIR/source-list.nul"
tr '\0' '\n' <"$OUT_DIR/source-list.nul" >"$OUT_DIR/source-list.txt"

write_inventory() {
  python3 - "$ROOT_DIR" "$OUT_DIR/source-list.txt" "$1" <<'PY'
import hashlib
import os
import sys
from pathlib import Path

root = Path(sys.argv[1])
selected = Path(sys.argv[2]).read_text().splitlines()
out = Path(sys.argv[3])
rows = []
for rel in selected:
    src = root / rel
    items = [src]
    if src.is_dir():
        items.extend(sorted(src.rglob("*")))
    for item in items:
        item_rel = item.relative_to(root).as_posix()
        if item.is_symlink():
            raise SystemExit(f"symlink input rejected: {item_rel}")
        if item.is_dir():
            rows.append(("d", 0, "-", item_rel))
        elif item.is_file():
            data = item.read_bytes()
            rows.append(("f", len(data), hashlib.sha256(data).hexdigest(), item_rel))
        else:
            raise SystemExit(f"unsupported input: {item_rel}")
with out.open("w") as f:
    f.write("type\tlogical_bytes\tsha256\tpath\n")
    for row in sorted(set(rows), key=lambda r: r[3]):
        f.write("\t".join(map(str, row)) + "\n")
PY
}

write_inventory "$OUT_DIR/source-inventory.pre.tsv"
tar -C "$ROOT_DIR" --one-file-system --null -T "$OUT_DIR/source-list.nul" -cf - \
  | zstd -T1 -10 -o "$ARCHIVE"
zstd --test --quiet -- "$ARCHIVE"
zstd -dc -- "$ARCHIVE" | tar -tf - >"$OUT_DIR/archive-contents.txt"
write_inventory "$OUT_DIR/source-inventory.post.tsv"
cmp -s "$OUT_DIR/source-inventory.pre.tsv" "$OUT_DIR/source-inventory.post.tsv" \
  || die 'source changed while archiving'
sha256sum -- "$ARCHIVE" >"$OUT_DIR/SHA256SUMS"

entries=$(awk 'NR > 1 { n++ } END { print n + 0 }' "$OUT_DIR/source-inventory.pre.tsv")
bytes=$(awk -F '\t' 'NR > 1 { n += $2 } END { printf "%.0f", n + 0 }' \
  "$OUT_DIR/source-inventory.pre.tsv")
{
  printf 'task_slug=%s\n' "$TASK_SLUG"
  printf 'period_ns=5.0\n'
  printf 'netlist_sha256=%s\n' "$actual_netlist_sha"
  printf 'wns_ns=-8.720\n'
  printf 'tns_ns=-199154.36\n'
  printf 'target_200mhz_met=false\n'
  printf 'inventory_entries=%s\n' "$entries"
  printf 'logical_bytes=%s\n' "$bytes"
  printf 'archive_sha256=%s\n' "$(sha256sum -- "$ARCHIVE" | cut -d' ' -f1)"
} >"$OUT_DIR/archive-provenance.txt"

printf '[T3K-STA-ARCHIVE] PASS: entries=%s bytes=%s archive=%s\n' \
  "$entries" "$bytes" "$ARCHIVE"
