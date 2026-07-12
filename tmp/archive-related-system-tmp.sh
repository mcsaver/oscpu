#!/usr/bin/env bash
set -euo pipefail

readonly source_root=/tmp
readonly workspace_root=/home/lyg/PA/ysyx-workbench
readonly archive_dir="${workspace_root}/tmp"
readonly stem=2026-07-13-goal-tmp-snapshot
readonly archive="${archive_dir}/${stem}.tar.zst"
readonly inventory="${archive_dir}/${stem}.inventory.tsv"
readonly contents="${archive_dir}/${stem}.contents.txt"
readonly source_list="${archive_dir}/${stem}.source-list.txt"
readonly exclusions="${archive_dir}/2026-07-13-goal-tmp-exclusions.md"
readonly worktree_metadata="${archive_dir}/2026-07-13-goal-tmp-worktree-metadata.txt"
readonly checksum_file="${archive_dir}/SHA256SUMS"
readonly nul_list="${archive_dir}/.${stem}.source-list.nul"
readonly archive_tmp="${archive}.tmp.$$"

mode=archive
case ${1:-} in
  "") ;;
  --preflight) mode=preflight ;;
  *)
    echo "usage: $0 [--preflight]" >&2
    exit 2
    ;;
esac

cleanup() {
  rm -f -- "${nul_list}" "${archive_tmp}"
}
trap cleanup EXIT

mkdir -p -- "${archive_dir}"

# This is deliberately an allowlist.  It captures every top-level artifact family
# produced by the RV64 architecture goal while excluding OS/editor IPC, anonymous
# Icarus/Yosys scratch, and the clean duplicate repository worktree.
mapfile -d '' candidates < <(
  find "${source_root}" -mindepth 1 -maxdepth 1 -printf '%f\0' | sort -z
)

selected=()
for name in "${candidates[@]}"; do
  case "${name}" in
    access-* | \
    b2* | \
    codex-g2-review-* | \
    dead-forward-* | \
    f1a-* | \
    fetch-g2-* | \
    g2-* | \
    ifu-* | \
    lane1-* | \
    mem-issue-* | \
    rv64-* | \
    tb_* | \
    xret-* | \
    ysyx-axi-* | \
    ysyx-f0-* | \
    ysyx-strict-guard-* | \
    known-issues.json | \
    lint.log | \
    npc-memory.json | \
    project-status.json | \
    t3refs.txt | \
    ysyx-memory-edit-dead-forward)
      selected+=("${name}")
      ;;
  esac
done

if ((${#selected[@]} == 0)); then
  echo "error: no project-related /tmp entries matched the allowlist" >&2
  exit 1
fi

printf '%s\0' "${selected[@]}" > "${nul_list}"
printf '%s\n' "${selected[@]}" > "${source_list}"

{
  printf 'bytes\ttype\tmtime\tsource\n'
  for name in "${selected[@]}"; do
    path="${source_root}/${name}"
    bytes=$(du -sb -- "${path}" | awk '{print $1}')
    type=$(stat -c '%F' -- "${path}")
    mtime=$(stat -c '%y' -- "${path}")
    printf '%s\t%s\t%s\t/tmp/%s\n' "${bytes}" "${type}" "${mtime}" "${name}"
  done
} > "${inventory}"

{
  printf 'source=/tmp/ysyx-bpu-static-a\n'
  if [[ -e /tmp/ysyx-bpu-static-a ]]; then
    printf 'size_human=%s\n' "$(du -sh -- /tmp/ysyx-bpu-static-a | awk '{print $1}')"
    printf 'size_bytes=%s\n' "$(du -sb -- /tmp/ysyx-bpu-static-a | awk '{print $1}')"
    printf 'head=%s\n' "$(git -C /tmp/ysyx-bpu-static-a rev-parse HEAD)"
    branch=$(git -C /tmp/ysyx-bpu-static-a branch --show-current)
    printf 'branch=%s\n' "${branch:-DETACHED}"
    printf 'status_short_begin\n'
    git -C /tmp/ysyx-bpu-static-a status --short --untracked-files=normal
    printf 'status_short_end\n'
  else
    printf 'not present at archive time\n'
  fi
} > "${worktree_metadata}"

total_bytes=$(awk -F '\t' 'NR > 1 {sum += $1} END {printf "%.0f", sum}' "${inventory}")
if [[ "${mode}" == preflight ]]; then
  printf 'ARCHIVE_PREFLIGHT_OK entries=%d bytes=%s\n' "${#selected[@]}" "${total_bytes}"
  exit 0
fi

rm -f -- "${archive_tmp}"
nice -n 10 tar \
  --create \
  --file="${archive_tmp}" \
  --directory="${source_root}" \
  --null \
  --files-from="${nul_list}" \
  --use-compress-program='zstd -T0 -10'
mv -- "${archive_tmp}" "${archive}"

zstd --test --quiet -- "${archive}"
tar --list --file="${archive}" > "${contents}"

(
  cd "${archive_dir}"
  sha256sum \
    "$(basename "${archive}")" \
    "$(basename "${inventory}")" \
    "$(basename "${contents}")" \
    "$(basename "${source_list}")" \
    "$(basename "${exclusions}")" \
    "$(basename "${worktree_metadata}")" \
    > "$(basename "${checksum_file}")"
)

printf 'ARCHIVE_OK entries=%d bytes=%s archive=%s\n' \
  "${#selected[@]}" "${total_bytes}" "${archive}"
