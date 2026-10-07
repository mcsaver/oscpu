#!/usr/bin/env bash
set -euo pipefail
pkg-config --atleast-version=4.7 slirp && exit 0
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
env_root=${YSYX_LINUX_ENV_ROOT:-"$script_dir/../env"}
prefix=${NEMU_SLIRP_PREFIX:-"$env_root/tools/libslirp"}
[[ -f "$prefix/usr/include/slirp/libslirp.h" && -s "$prefix/usr/lib/x86_64-linux-gnu/libslirp.a" ]] && exit 0
# A system libslirp-dev can be used on any supported native Linux host.
# This local binary fallback is pinned to the workspace's Ubuntu 24.04 amd64 host.
. /etc/os-release
[[ $ID == ubuntu && $VERSION_ID == 24.04 && $(uname -m) == x86_64 ]] || {
  echo "[libslirp] install native libslirp development files or set NEMU_SLIRP_PREFIX" >&2
  exit 1
}
pkg-config --exists glib-2.0
downloads="$env_root/downloads/libslirp"
mkdir -p "$downloads" "$prefix"
exec 9>"$prefix/.prepare.lock"
flock 9
while read -r package digest; do
  name="${package}_4.7.0-1ubuntu3.1_amd64.deb"
  archive="$downloads/$name"
  if [[ ! -f $archive ]]; then
    tmp=$(mktemp "$downloads/.$name.XXXXXX")
    trap 'rm -f -- "$tmp"' EXIT
    curl -fLsS --connect-timeout 15 --speed-limit 1024 --speed-time 30 --retry 3 \
      "https://mirrors.ustc.edu.cn/ubuntu/pool/main/libs/libslirp/$name" -o "$tmp"
    printf '%s  %s\n' "$digest" "$tmp" | sha256sum -c -
    mv "$tmp" "$archive"
    trap - EXIT
  fi
  printf '%s  %s\n' "$digest" "$archive" | sha256sum -c -
  dpkg-deb -x "$archive" "$prefix"
done <<'EOF'
libslirp0 4efa2d1c509de4d10fe965e86a3d864bf542996caf476d9111fd882c73857164
libslirp-dev 5e499e161e6785abc35d03d8c70cdd6fb99581b81508c3e81a2fa33f36ca052a
EOF
