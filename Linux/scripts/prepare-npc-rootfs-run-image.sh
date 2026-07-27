#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
用法:
  prepare-npc-rootfs-run-image.sh \
    --template <pristine.ext4> \
    --run-image <per-run.ext4> \
    --binding-out <binding.txt> \
    [--expected-template-sha256 <sha256>]

说明:
  从只读证据模板创建本轮 NPC/Verilator 可写 block-image 副本。
  已存在的 run-image 会被拒绝，避免覆盖历史系统回放现场。
EOF
}

template=""
run_image=""
binding_out=""
expected_template_sha256=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --template)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      template=$2
      shift 2
      ;;
    --run-image)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      run_image=$2
      shift 2
      ;;
    --binding-out)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      binding_out=$2
      shift 2
      ;;
    --expected-template-sha256)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      expected_template_sha256=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf '%s\n' "[npc-rootfs-run-image] unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

[[ -n "${template}" && -n "${run_image}" && -n "${binding_out}" ]] || {
  usage >&2
  exit 2
}
if [[ -n "${expected_template_sha256}" &&
      ! "${expected_template_sha256}" =~ ^[0-9a-f]{64}$ ]]; then
  printf '%s\n' "[npc-rootfs-run-image] invalid expected SHA-256" >&2
  exit 2
fi

template="$(readlink -e -- "${template}")"
run_image="$(readlink -m -- "${run_image}")"
binding_out="$(readlink -m -- "${binding_out}")"

[[ -s "${template}" ]] || {
  printf '%s\n' "[npc-rootfs-run-image] template is missing or empty: ${template}" >&2
  exit 3
}
[[ "${run_image}" != "${template}" ]] || {
  printf '%s\n' "[npc-rootfs-run-image] run image must differ from template" >&2
  exit 3
}
[[ "${binding_out}" != "${template}" && "${binding_out}" != "${run_image}" ]] || {
  printf '%s\n' "[npc-rootfs-run-image] binding path aliases an image path" >&2
  exit 3
}
[[ ! -e "${run_image}" ]] || {
  printf '%s\n' "[npc-rootfs-run-image] run image already exists: ${run_image}" >&2
  exit 4
}

template_sha256="$(sha256sum "${template}" | awk '{print $1}')"
if [[ -n "${expected_template_sha256}" &&
      "${template_sha256}" != "${expected_template_sha256}" ]]; then
  printf '%s\n' \
    "[npc-rootfs-run-image] template SHA-256 mismatch: expected=${expected_template_sha256} actual=${template_sha256}" >&2
  exit 5
fi

mkdir -p "$(dirname -- "${run_image}")" "$(dirname -- "${binding_out}")"
cp --reflink=auto --sparse=always -- "${template}" "${run_image}"
run_sha256="$(sha256sum "${run_image}" | awk '{print $1}')"
if [[ "${run_sha256}" != "${template_sha256}" ]]; then
  printf '%s\n' \
    "[npc-rootfs-run-image] copied run image hash mismatch: template=${template_sha256} run=${run_sha256}" >&2
  exit 6
fi

binding_tmp="${binding_out}.tmp.$$"
{
  printf 'rootfs_template=%s\n' "${template}"
  printf 'rootfs_run_image=%s\n' "${run_image}"
  printf 'rootfs_template_sha256_pre=%s\n' "${template_sha256}"
  printf 'rootfs_run_image_sha256_pre=%s\n' "${run_sha256}"
  printf 'rootfs_logical_bytes=%s\n' "$(stat -c %s "${run_image}")"
  printf '%s\n' "copy_mode=reflink-auto+sparse"
} >"${binding_tmp}"
mv -f -- "${binding_tmp}" "${binding_out}"

printf '%s\n' \
  "[npc-rootfs-run-image] PASS template=${template_sha256} run=${run_sha256}"
