#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${run_dir}/../../../.." && pwd)"
rtl_rel="npc/rv64/vsrc/writeback/OooRob.v"
tb_rel=".github/task-runs/2026-07-19-rv64-v8c-producer-identity-p0/rob-reuse-red/tb_ooo_rob_reuse_red.sv"
runner_rel=".github/task-runs/2026-07-19-rv64-v8c-producer-identity-p0/rob-reuse-red/run-rob-reuse-red.sh"
readme_rel=".github/task-runs/2026-07-19-rv64-v8c-producer-identity-p0/rob-reuse-red/README.md"
evidence_dir="${run_dir}/evidence"
build_dir="${ROB_REUSE_RED_BUILD_DIR:-$(mktemp -d /tmp/rob-reuse-red.XXXXXX)}"

mkdir -p "${evidence_dir}" "${build_dir}/release" "${build_dir}/assert"
rm -f "${evidence_dir}/release.compile.log" \
      "${evidence_dir}/release.sim.log" \
      "${evidence_dir}/assert.compile.log" \
      "${evidence_dir}/assert.sim.log" \
      "${evidence_dir}/source.pre.sha256" \
      "${evidence_dir}/source.post.sha256" \
      "${evidence_dir}/source.sha256" \
      "${evidence_dir}/source-check.log" \
      "${evidence_dir}/summary.txt" \
      "${evidence_dir}/expected-red.complete"

iverilog_bin="${IVERILOG:-$(command -v iverilog)}"
vvp_bin="${VVP:-$(command -v vvp)}"
if [[ ! -x "${iverilog_bin}" ]] || [[ ! -x "${vvp_bin}" ]]; then
  echo "iverilog/vvp unavailable" >&2
  exit 1
fi

(
  cd "${repo_root}"
  sha256sum "${rtl_rel}" "${tb_rel}" "${runner_rel}" "${readme_rel}"
) >"${evidence_dir}/source.pre.sha256"

run_variant() {
  local variant="$1"
  local extra=()
  if [[ "${variant}" == "assert" ]]; then
    extra=(-DOOO_ASSERT)
  fi

  "${iverilog_bin}" -g2012 -Wall \
    -I "${repo_root}/npc/rv64/vsrc" \
    -I "${repo_root}/npc/rv64/vsrc/include" \
    "${extra[@]}" -s tb_ooo_rob_reuse_red \
    -o "${build_dir}/${variant}/tb.vvp" \
    "${repo_root}/${tb_rel}" "${repo_root}/${rtl_rel}" \
    >"${evidence_dir}/${variant}.compile.log" 2>&1

  "${vvp_bin}" "${build_dir}/${variant}/tb.vvp" \
    >"${evidence_dir}/${variant}.sim.log" 2>&1

  if [[ "$(grep -Fxc '[ROB-REUSE-RED][PASS] expected_current_red=1 positive_control=1 branch_recovery=1 slot_wrap=1' "${evidence_dir}/${variant}.sim.log" || true)" -ne 1 ]]; then
    echo "${variant}: expected-current-RED PASS marker missing" >&2
    exit 1
  fi
  if [[ "$(grep -Fc '[ROB-REUSE-RED][WITNESS]' "${evidence_dir}/${variant}.sim.log" || true)" -ne 1 ]] || \
     [[ "$(grep -Fc '[ROB-REUSE-RED][POSITIVE]' "${evidence_dir}/${variant}.sim.log" || true)" -ne 1 ]]; then
    echo "${variant}: witness or positive-control marker count drift" >&2
    exit 1
  fi
  if grep -Eq '\[TB-FAIL\]|(^|[[:space:]])ERROR:|(^|[[:space:]])FATAL:' \
      "${evidence_dir}/${variant}.sim.log"; then
    echo "${variant}: simulation reported an unexpected failure" >&2
    exit 1
  fi
}

run_variant release
run_variant assert

(
  cd "${repo_root}"
  sha256sum "${rtl_rel}" "${tb_rel}" "${runner_rel}" "${readme_rel}"
) >"${evidence_dir}/source.post.sha256"
if ! cmp -s "${evidence_dir}/source.pre.sha256" "${evidence_dir}/source.post.sha256"; then
  echo "reviewed source changed during characterization" >&2
  exit 1
fi
cp "${evidence_dir}/source.post.sha256" "${evidence_dir}/source.sha256"
(
  cd "${repo_root}"
  sha256sum -c ".github/task-runs/2026-07-19-rv64-v8c-producer-identity-p0/rob-reuse-red/evidence/source.sha256"
) >"${evidence_dir}/source-check.log"

cat >"${evidence_dir}/summary.txt" <<EOF
RV64 OooRob raw-index reuse current-RED characterization
scope=production-OooRob-leaf
rtl_mutated=no
squash=real-branch-recovery-ROB-walk
wrap=branch@15-old@0-new@0
late_old_writeback=wb1
positive_new_writeback=wb0
release_expected_red_witness=PASS
assert_expected_red_witness=PASS
failure_mode=registered-done-and-payload-slot-alias
existing_pdest_sentinel=same-pdest-reuse-not-distinguishable
runner_semantics=PASS-only-when-current-slot-alias-gap-and-positive-control-are-both-observed
global_full_identity=RED
shared_PRF_wakeup=NOT_TESTED
linux_ppa_timing=NOT_TESTED
iverilog_version=$(${iverilog_bin} -V 2>&1 | sed -n '1p')
build_dir=${build_dir}
EOF

sha256sum "${evidence_dir}/summary.txt" \
          "${evidence_dir}/release.sim.log" \
          "${evidence_dir}/assert.sim.log" \
          "${evidence_dir}/source.sha256" \
  >"${evidence_dir}/expected-red.complete"

printf '%s\n' "flock /tmp/ysyx-workbench-wsl.lock bash ${runner_rel}" \
  >"${evidence_dir}/reproduce.cmd"

printf '[ROB-REUSE-EXPECTED-RED][PASS] release/assert=2/2 real-recovery wrap witness + positive control\n'
printf '[ROB-REUSE-EXPECTED-RED][EVIDENCE] %s\n' "${evidence_dir}"
