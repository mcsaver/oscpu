#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source_file="${repo_root}/scripts/agent-flow.c"
binary_dir="${AGENT_FLOW_BIN_DIR:-${repo_root}/.github/cache/agent-flow}"
binary="${binary_dir}/agent-flow"

mkdir -p "${binary_dir}"

if [[ ! -x "${binary}" || "${source_file}" -nt "${binary}" ]]; then
  temporary="${binary}.tmp.${BASHPID}"
  cleanup_compile() {
    rm -f -- "${temporary}"
  }
  trap cleanup_compile EXIT
  "${CC:-cc}" -std=c11 -O2 -Wall -Wextra -Werror \
    "${source_file}" -o "${temporary}"
  chmod 0755 "${temporary}"
  mv -f -- "${temporary}" "${binary}"
  trap - EXIT
fi

exec "${binary}" --repo "${repo_root}" "$@"
