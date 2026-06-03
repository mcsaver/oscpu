#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <repo-root> <output-filelist>" >&2
  exit 2
fi

repo_root="$(realpath "$1")"
out_file="$(realpath -m "$2")"
vsrc_dir="$repo_root/npc/rv64/vsrc"
filelist_mk="$vsrc_dir/filelist.mk"

if [ ! -f "$filelist_mk" ]; then
  echo "[fpga] missing RV64 filelist: $filelist_mk" >&2
  exit 1
fi

tmp_mk="$(mktemp)"
trap 'rm -f "$tmp_mk"' EXIT

cat > "$tmp_mk" <<'MAKE_EOF'
VSRCDIR ?=
include $(VSRCDIR)/filelist.mk
.PHONY: print
print:
	@printf '%s\n' $(RTL_DEFINE) $(RTL_CORE_SRCS)
MAKE_EOF

mkdir -p "$(dirname "$out_file")"
make -s --no-print-directory -f "$tmp_mk" VSRCDIR="$vsrc_dir" print \
  | awk 'NF { print }' \
  | while IFS= read -r src; do
      realpath "$src"
    done \
  > "$out_file"

missing=0
while IFS= read -r src; do
  if [ ! -f "$src" ]; then
    echo "[fpga] missing source: $src" >&2
    missing=1
  fi
done < "$out_file"

if [ "$missing" -ne 0 ]; then
  exit 1
fi

echo "[fpga] wrote $(wc -l < "$out_file") RTL sources to $out_file"
