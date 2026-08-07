#!/usr/bin/env bash
set -euo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
template="${repo_root}/.github/task-runs/2026-08-07-rv64-v15q-current-reference-ppa-337-a1/driver/run-current-fresh-a1.sh"
driver_dir="${repo_root}/.github/task-runs/2026-08-07-rv64-v15r-current-timing-recovery-analysis-337de8bf/driver"
generated="${driver_dir}/run-ppa-candidate-f784-a1.generated.sh"
expected_template_sha=b8526a181a532102fcaf6499b708c03278cb1558b9d8db4a00b68505b8656a5f
expected_design_id=sha256:f784b60a858e4c947316b67e9d16f1c0715f8328b1424eb5ae9b3a377566cef3

[[ -f "${template}" && ! -L "${template}" ]] || {
  printf '%s\n' '[V15R-PPA-PREPARE][FAIL] frozen template missing or symlinked' >&2
  exit 2
}
[[ "$(sha256sum "${template}" | awk '{print $1}')" == "${expected_template_sha}" ]] || {
  printf '%s\n' '[V15R-PPA-PREPARE][FAIL] frozen template hash drift' >&2
  exit 2
}

observed_design_id="$(python3 -B -c \
  'from pathlib import Path; from npc.rv64.eval.ppa.tools.architecture_hard_gates import rtl_binding; print("sha256:" + rtl_binding(Path.cwd())[0])')"
[[ "${observed_design_id}" == "${expected_design_id}" ]] || {
  printf '%s\n' \
    "[V15R-PPA-PREPARE][FAIL] design-id expected=${expected_design_id} observed=${observed_design_id}" >&2
  exit 2
}

mkdir -p -- "${driver_dir}"
[[ ! -e "${generated}" ]] || {
  printf '%s\n' "[V15R-PPA-PREPARE][FAIL] generated driver already exists: ${generated}" >&2
  exit 2
}
sed \
  -e 's/2026-08-07-rv64-v15q-current-reference-ppa-337-a1/2026-08-07-rv64-v15r-current-timing-recovery-analysis-337de8bf/g' \
  -e 's/current-fresh-a1/ppa-candidate-f784-a1/g' \
  -e 's/v15q-current-reference-ppa-337-a1/v15r-mem-birth-factor-f784-a1/g' \
  -e 's/v15q-current-reference-ppa/v15r-mem-birth-factor/g' \
  "${template}" >"${generated}"
chmod 0755 "${generated}"

printf '%s\n' \
  "[V15R-PPA-PREPARE][PASS] design_id=${observed_design_id}" \
  "[V15R-PPA-PREPARE] driver=${generated}"
exec "${generated}"
