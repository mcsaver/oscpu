#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../.." && pwd)
cd -- "${repo_root}"

for input in npc/rv64/Makefile npc/rv64/.config \
  npc/rv64/include/config/auto.conf npc/rv64/include/generated/autoconf.h \
  npc/rv64/legacy/sim npc/rv64/vsrc npc/rv64/sim/vsrc; do
  [[ -e "${input}" && ! -L "${input}" ]]
done

find npc/rv64/Makefile npc/rv64/.config \
  npc/rv64/include/config/auto.conf npc/rv64/include/generated/autoconf.h \
  npc/rv64/legacy/sim npc/rv64/vsrc npc/rv64/sim/vsrc -type f -print0 | \
  LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum | awk '{print $1}'
