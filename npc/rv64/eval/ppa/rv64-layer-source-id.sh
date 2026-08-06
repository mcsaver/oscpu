#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../.." && pwd)
layer=
if [[ "${1:-}" == --layer ]]; then
  layer=${2:-}
fi
case "${layer}" in l2|l3) ;; *) printf '%s\n' 'usage: rv64-layer-source-id.sh --layer l2|l3' >&2; exit 2 ;; esac
cd -- "${repo_root}"

opensbi_root=Linux/env/src/opensbi
[[ -d "${opensbi_root}" && ! -L "${opensbi_root}" ]]
opensbi_commit=$(git -C "${opensbi_root}" rev-parse HEAD)
opensbi_diff_sha=$(git -C "${opensbi_root}" diff --no-ext-diff --binary HEAD | \
  sha256sum | awk '{print $1}')

if [[ "${layer}" == l2 ]]; then
  direct_files=(
    Linux/mini-system/rv64-l2-payload.S
    Linux/mini-system/rv64-l2-payload.ld
    Linux/scripts/build-rv64-mini-system.sh
    Linux/scripts/build-opensbi.sh
    Linux/platform/gen_dts.py
    Linux/platform/common-rv64.yml
    Linux/platform/npc-rv64.yml
  )
  {
    printf 'schema=npc-rv64-layer-source-id-v1\nlayer=l2\n'
    sha256sum -- "${direct_files[@]}"
    printf 'opensbi_commit=%s\nopensbi_diff_sha256=%s\n' \
      "${opensbi_commit}" "${opensbi_diff_sha}"
  } | sha256sum | awk '{print $1}'
  exit 0
fi

linux_root=Linux/env/src/linux
[[ -d "${linux_root}" && ! -L "${linux_root}" ]]
linux_content_sha=$(find "${linux_root}" -type f -print0 | \
  LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum | awk '{print $1}')
direct_files=(
  Linux/lightweight/rv64-l3-kernel.config
  Linux/lightweight/rv64-l3-init.c
  Linux/scripts/build-rv64-lightweight-linux.sh
  Linux/scripts/check-rv64-lightweight-linux-config.sh
  Linux/scripts/build-opensbi.sh
  Linux/platform/gen_dts.py
  Linux/platform/common-rv64.yml
  Linux/platform/npc-rv64.yml
)
{
  printf 'schema=npc-rv64-layer-source-id-v1\nlayer=l3\n'
  printf 'linux_tree_content_sha256=%s\n' "${linux_content_sha}"
  sha256sum -- "${direct_files[@]}"
  printf 'opensbi_commit=%s\nopensbi_diff_sha256=%s\n' \
    "${opensbi_commit}" "${opensbi_diff_sha}"
} | sha256sum | awk '{print $1}'
