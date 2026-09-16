#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
workspace=$(cd -- "$script_dir/../../../.." && pwd)
nemu_dir="$workspace/nemu"
output_dir="${1:-$nemu_dir/build/rv64-rebuild-reference}"
output_dir=$(realpath -m -- "$output_dir")
case "$output_dir" in "$nemu_dir"/build/*) ;; *) echo "reference output must be beneath NEMU build" >&2; exit 1;; esac
mkdir -p "$output_dir/include/config" "$output_dir/include/generated"
if ! cmp -s "$script_dir/reference.config" "$output_dir/.config"; then
  cp -- "$script_dir/reference.config" "$output_dir/.config"
fi
export KCONFIG_CONFIG="$output_dir/.config"
export KCONFIG_AUTOCONFIG="$output_dir/include/config/auto.conf"
export KCONFIG_AUTOCONFIG_DEP="$output_dir/include/config/auto.conf.cmd"
export KCONFIG_AUTOHEADER="$output_dir/include/generated/autoconf.h"
export KCONFIG_SPLITCONFIG="$output_dir/include/config/"
"$workspace/tool/kconfig/build/conf" -s --syncconfig "$nemu_dir/Kconfig"
make -C "$nemu_dir" NEMU_HOME="$nemu_dir" NEMU_CONFIG_DIR="$output_dir" BUILD_DIR="$output_dir" SHARE=1 -j "${R64_REFERENCE_JOBS:-6}"
