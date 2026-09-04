#!/usr/bin/env bash
set -euo pipefail

if (($# != 1)); then
  echo "usage: $0 MANIFEST" >&2
  exit 2
fi

manifest=$1
if [[ -L $manifest || ! -f $manifest ]]; then
  echo "invalid NEMU build profile manifest: $manifest" >&2
  exit 1
fi

sha256sum -- "$manifest" | cut -c1-16
