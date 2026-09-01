#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cmake_bin="${project_root}/tools/cmake-python/bin/cmake"
source_dir="${project_root}/runtime/llama-npu-backend"
frozen_coproc_sha="ee37cb2ba186ce0bc96bd83f7ac461d6a68dab19161d0b0ca9b9b5a018a57cb3"

mkdir -p -- "${project_root}/tmp"
project_tmp="$(realpath -e -- "${project_root}/tmp")"

fail_path() {
    printf '%s path must resolve inside project tmp (%s): %s\n' \
        "$1" "${project_tmp}" "$2" >&2
    exit 2
}

resolve_tmp_path() {
    local label="$1"
    local raw_path="$2"
    local candidate
    local resolved

    [[ -n "${raw_path}" ]] || fail_path "${label}" "<empty>"
    case "${raw_path}" in
        /*) candidate="${raw_path}" ;;
        *) candidate="${project_root}/${raw_path}" ;;
    esac
    resolved="$(realpath -m -- "${candidate}")"
    case "${resolved}" in
        "${project_tmp}"|"${project_tmp}/"*) ;;
        *) fail_path "${label}" "${raw_path}" ;;
    esac
    printf '%s\n' "${resolved}"
}

prepare_tmp_dir() {
    local label="$1"
    local resolved

    resolved="$(resolve_tmp_path "${label}" "$2")"
    mkdir -p -- "${resolved}"
    resolved="$(realpath -e -- "${resolved}")"
    case "${resolved}" in
        "${project_tmp}"|"${project_tmp}/"*) ;;
        *) fail_path "${label}" "$2" ;;
    esac
    printf '%s\n' "${resolved}"
}

build_dir="$(prepare_tmp_dir NPU_BACKEND_BUILD_DIR \
    "${NPU_BACKEND_BUILD_DIR:-${project_tmp}/build/npu-backend}")"
log_dir="$(prepare_tmp_dir NPU_BACKEND_LOG_DIR \
    "${NPU_BACKEND_LOG_DIR:-${project_tmp}/logs/npu-backend}")"
verilated_mdir="$(prepare_tmp_dir NPU_VERILATED_MDIR \
    "${NPU_VERILATED_MDIR:-${project_tmp}/build/npu-backend-verilated}")"
system_verilated_mdir="$(prepare_tmp_dir NPU_SYSTEM_VERILATED_MDIR \
    "${NPU_SYSTEM_VERILATED_MDIR:-${project_tmp}/build/npu-backend-system-verilated}")"
runtime_tmp="$(prepare_tmp_dir TMPDIR \
    "${TMPDIR:-${project_tmp}/runtime-tmp}")"
tmp_dir="$(prepare_tmp_dir TMP "${TMP:-${runtime_tmp}}")"
temp_dir="$(prepare_tmp_dir TEMP "${TEMP:-${runtime_tmp}}")"
cache_dir="$(prepare_tmp_dir XDG_CACHE_HOME \
    "${XDG_CACHE_HOME:-${project_tmp}/cache}")"
llama_build_dir="$(resolve_tmp_path LLAMA_BUILD_DIR \
    "${LLAMA_BUILD_DIR:-${project_tmp}/build/llama.cpp}")"
manifest="$(resolve_tmp_path NPU_MANIFEST \
    "${NPU_MANIFEST:-${project_tmp}/logs/qwen-graph-manifest-v5/dispatch.manifest.json}")"
steady_manifest="$(resolve_tmp_path NPU_STEADY_MANIFEST \
    "${NPU_STEADY_MANIFEST:-${project_tmp}/logs/qwen-graph-manifest-v5/steady.manifest.json}")"
if [[ ! -f "${manifest}" ]]; then
    printf 'missing NPU manifest: %s\n' "${manifest}" >&2
    exit 2
fi
if [[ ! -f "${steady_manifest}" ]]; then
    printf 'missing NPU steady manifest: %s\n' "${steady_manifest}" >&2
    exit 2
fi

export TMPDIR="${runtime_tmp}"
export TMP="${tmp_dir}"
export TEMP="${temp_dir}"
export XDG_CACHE_HOME="${cache_dir}"
export PYTHONPATH="${project_root}/tools/cmake-python"
export PYTHONDONTWRITEBYTECODE=1

printf '[NPU-BUILD-ENV] TMPDIR=%s TMP=%s TEMP=%s\n' \
    "${TMPDIR}" "${TMP}" "${TEMP}"
actual_coproc_sha="$(sha256sum \
    "${project_root}/rtl/TensorNpuCoprocessor.v" | awk '{print $1}')"
if [[ "${actual_coproc_sha}" != "${frozen_coproc_sha}" ]]; then
    printf 'frozen Coprocessor SHA mismatch: expected=%s actual=%s\n' \
        "${frozen_coproc_sha}" "${actual_coproc_sha}" >&2
    exit 2
fi
printf '[NPU-FROZEN-RTL] TensorNpuCoprocessor.v sha256=%s\n' \
    "${actual_coproc_sha}"

python3 "${project_root}/scripts/verify_locked_inputs.py" --allow-partial-model

manifest_bundle_log="${log_dir}/dispatch-manifest-bundle.log"
python3 "${project_root}/scripts/qwen_graph_manifest.py" bundle \
    "${manifest}" "${steady_manifest}" >"${manifest_bundle_log}" 2>&1
sed -n '1,120p' "${manifest_bundle_log}"
if ! grep -Fxq \
    '[NPU-GRAPH-MANIFEST-BUNDLE][PASS] nodes=1714 unchanged=1642 descriptor_deltas=72 zero_scale=36 p17=18 p18=18 steady_repeats=0 bundle_sha256=660a917fa0eac112837b6814bf07e3f9a7ad80e6a8310f8994072b855541b915' \
    "${manifest_bundle_log}"; then
    printf 'exact bootstrap/steady graph manifest bundle marker missing\n' >&2
    exit 2
fi

version_log="${log_dir}/llama-version.log"
"${llama_build_dir}/bin/llama-cli" --version >"${version_log}" 2>&1
if ! grep -Fq \
    'build 10507, commit 95c409c13625a23da2aa37270339ce9179215a18' \
    "${version_log}"; then
    sed -n '1,120p' "${version_log}" >&2
    printf 'pinned llama.cpp build identity mismatch\n' >&2
    exit 2
fi

"${cmake_bin}" --fresh -S "${source_dir}" -B "${build_dir}" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLAMA_BUILD_BIN:PATH="${llama_build_dir}/bin" \
    -DNPU_VERILATED_MDIR:PATH="${verilated_mdir}" \
    -DNPU_SYSTEM_VERILATED_MDIR:PATH="${system_verilated_mdir}" \
    -DNPU_Q8_GEMV_MANIFEST:FILEPATH="${manifest}" \
    -DNPU_QWEN_STEADY_MANIFEST:FILEPATH="${steady_manifest}"
"${cmake_bin}" --build "${build_dir}" --clean-first \
    --parallel "${NPU_BUILD_JOBS:-$(nproc)}"

# The legacy direct-port qualification DSO is deliberately excluded from the
# production dependency closure.  Build it explicitly because the later
# `--rtl-self-test` gate loads this optional module by path; a fresh build must
# not depend on a stale copy left by an earlier invocation.
"${cmake_bin}" --build "${build_dir}" \
    --target npu-direct-selftests \
    --parallel "${NPU_BUILD_JOBS:-$(nproc)}"

backend="${build_dir}/libggml-npu.so"
if [[ ! -f "${backend}" ]]; then
    printf 'missing NPU backend: %s\n' "${backend}" >&2
    exit 2
fi

canonical_id="$(python3 \
    "${project_root}/scripts/qwen_strict_canonical.py" emit-test-id \
    --manifest "${manifest}" --profile-id 0 --node-index 30)"
q8_canonical_id="$(python3 \
    "${project_root}/scripts/qwen_strict_canonical.py" emit-q8-id \
    --manifest "${manifest}")"
q8_gemv_canonical_id="$(python3 \
    "${project_root}/scripts/qwen_q8_gemv_profiles.py" emit-test-id \
    --manifest "${manifest}")"
q8_gemv_manifest_log="${log_dir}/q8-gemv-manifest.log"
python3 "${project_root}/scripts/qwen_q8_gemv_profiles.py" audit \
    --manifest "${manifest}" >"${q8_gemv_manifest_log}" 2>&1
sed -n '1,120p' "${q8_gemv_manifest_log}"
if ! grep -Fxq \
    '[NPU-Q8-GEMV-MANIFEST][PASS] nodes=187 profiles=10 excluded_f16=12 k=1024+2048+3584 b=32+64+112 m=16+512+1024+2048+3584+4096+6144+248320 canonical_set_sha256=f08be48521cc47cee08e078bff68df3a92c6a417edddf086ee6d76dc30aaf843 profile_set_sha256=d8fcffb195ccd1ed90b9af948d5460ebca4b8ea27b4d5872c87fe26469bf50b7' \
    "${q8_gemv_manifest_log}"; then
    printf 'exact canonical-v5 Q8 GEMV manifest marker missing\n' >&2
    exit 3
fi

f32_mover_manifest_log="${log_dir}/f32-mover-manifest.log"
python3 "${project_root}/scripts/qwen_f32_gather_repeat_profiles.py" audit \
    --manifest "${manifest}" >"${f32_mover_manifest_log}" 2>&1
sed -n '1,120p' "${f32_mover_manifest_log}"
if ! grep -Fxq \
    '[NPU-F32-MOVER-MANIFEST][PASS] nodes=91 get_rows=73 repeat=18 profiles=6 get_profiles=5 repeat_profiles=1 empty_get=36 canonical_set_sha256=ae86cbd2dc835aaabf7788968f37712ed8bd68b4f371e0145ac94867db0d3457 profile_set_sha256=0e7695679f94171303a5a52a59c4a6e57d79874f635e3f540deff9634fa7940a' \
    "${f32_mover_manifest_log}"; then
    printf 'exact canonical-v5 F32 mover manifest marker missing\n' >&2
    exit 3
fi

remaining_manifest_log="${log_dir}/remaining-433-manifest.log"
python3 "${project_root}/scripts/qwen_remaining_profiles.py" audit \
    --manifest "${manifest}" >"${remaining_manifest_log}" 2>&1
sed -n '1,120p' "${remaining_manifest_log}"
if ! grep -Fxq \
    '[NPU-QWEN-REMAINING-PROFILES][PASS] marker=QWEN_REMAINING_433_EXACT_V1 nodes=433 profiles=30 existing=646 sampler_argmax=1 required=1080 owners=UNARY:96,RMS_NORM:79,L2_NORM:36,SUM_ROWS:36,GLU:24,SSM_CONV:18,CPY:72,CONT:12,CONCAT:18,SET_ROWS:12,F16_MUL_MAT:12,ROPE:12,SOFT_MAX:6 owner_profiles=UNARY:6,RMS_NORM:5,L2_NORM:2,SUM_ROWS:1,GLU:1,SSM_CONV:1,CPY:4,CONT:2,CONCAT:1,SET_ROWS:2,F16_MUL_MAT:2,ROPE:2,SOFT_MAX:1 route_sentinels=15:local_operation;16:local_profile;17:local_profile;18:local_profile;19:local_profile;20:local_profile;21:local_profile;22:local_profile;25:local_operation;26:local_operation;27:local_operation;28:local_operation canonical_set_sha256=ef0a458d780a94185d7555c7f02e7ab65daa11ddc0c9432a665ba80cc9591048 profile_set_sha256=585980e9c9863e6df3823263222fee58fd4bba815e5aa4ebb21f78dcbd86ac05' \
    "${remaining_manifest_log}"; then
    printf 'exact final 433-node/30-profile manifest marker missing\n' >&2
    exit 3
fi

sampler_argmax_manifest_log="${log_dir}/sampler-argmax-manifest.log"
python3 "${project_root}/scripts/qwen_sampler_argmax_profile.py" audit \
    --manifest "${manifest}" >"${sampler_argmax_manifest_log}" 2>&1
sed -n '1,120p' "${sampler_argmax_manifest_log}"
sampler_argmax_manifest_pass='[NPU-SAMPLER-ARGMAX-PROFILE][PASS] profile=qwen35-0.8b-b1t1-unfused-nonflash-v5 profiles=1 node=1713 source=1712 canonical_id=333b5a00492fe61586c65c614c15fc3886d2da8661a6f4b818efcd78ef77d97d total=1714 compute=960 mover=120 metadata=634 external=375 source_edges=2474 required=1080'
if [[ "$(grep -Fxc "${sampler_argmax_manifest_pass}" \
        "${sampler_argmax_manifest_log}")" -ne 1 ]]; then
    printf 'exact strict-sampler ARGMAX manifest marker missing or duplicated\n' >&2
    exit 19
fi

sampler_argmax_profile_tests_log="${log_dir}/sampler-argmax-profile-tests.log"
if ! NPU_MANIFEST="${manifest}" \
    python3 "${project_root}/tests/test_qwen_sampler_argmax_profile.py" \
    >"${sampler_argmax_profile_tests_log}" 2>&1; then
    sed -n '1,200p' "${sampler_argmax_profile_tests_log}" >&2
    printf 'strict-sampler ARGMAX directed profile tests failed\n' >&2
    exit 20
fi
sed -n '1,200p' "${sampler_argmax_profile_tests_log}"
sampler_argmax_profile_test_pass='[NPU-SAMPLER-ARGMAX-PROFILE-TEST][PASS] manifest_source=NPU_MANIFEST non_skip=1 manifest_sha256=92d404d308cb9ca6a7741233ab05f8eb07be6659dc833fb99b7cd023958fe48e'
if [[ "$(grep -Ec '^test_.* \.\.\. ok$' \
        "${sampler_argmax_profile_tests_log}")" -ne 7 ]] || \
   grep -Eq '(^|[[:space:]])(skipped|FAIL|FAILED|ERROR)([[:space:]]|$)' \
        "${sampler_argmax_profile_tests_log}" || \
   ! grep -Eq '^Ran 7 tests in [0-9]+([.][0-9]+)?s$' \
        "${sampler_argmax_profile_tests_log}" || \
   [[ "$(grep -Fxc 'OK' "${sampler_argmax_profile_tests_log}")" -ne 1 ]] || \
   [[ "$(grep -Fxc "${sampler_argmax_profile_test_pass}" \
        "${sampler_argmax_profile_tests_log}")" -ne 1 ]]; then
    printf 'strict-sampler ARGMAX profile tests did not report exact 7/7 current-manifest PASS\n' >&2
    exit 20
fi
printf '[NPU-SAMPLER-ARGMAX-PROFILE-TESTS][PASS] tests=7 manifest=current-no-skip\n'

device_log="${log_dir}/list-devices.log"
GGML_BACKEND_PATH="${backend}" \
    "${llama_build_dir}/bin/llama-cli" --list-devices \
    >"${device_log}" 2>&1
sed -n '1,120p' "${device_log}"
if ! grep -Fq \
    'NPU: Verilated RISC-V Tensor NPU coprocessor' \
    "${device_log}"; then
    printf 'NPU backend did not register the required device marker\n' >&2
    exit 3
fi

abi_log="${log_dir}/backend-abi.log"
if ! timeout --signal=TERM --kill-after=2s 10s \
    "${build_dir}/test-npu-backend" "${backend}" \
    --canonical-id "${canonical_id}" >"${abi_log}" 2>&1; then
    sed -n '1,160p' "${abi_log}" >&2
    printf 'NPU backend ABI/fail-closed test failed\n' >&2
    exit 4
fi
sed -n '1,160p' "${abi_log}"
if ! grep -Fxq \
    '[NPU-BACKEND-ABI][PASS] checks=88 metadata=preserved exact16=required-canonical-verilated canonical-binding=duplicate+missing+profile-collision-fail-closed unsupported=fail-closed audit=v1+v2' \
    "${abi_log}"; then
    printf 'current NPU backend v2 ABI PASS marker missing\n' >&2
    exit 5
fi

f32_zero_system_log="${log_dir}/f32-zero-system.log"
if ! timeout --signal=TERM --kill-after=2s 30s \
    "${build_dir}/test-npu-f32-zero" \
    >"${f32_zero_system_log}" 2>&1; then
    sed -n '1,160p' "${f32_zero_system_log}" >&2
    printf 'NPU P17/P18 zero-cardinality SystemTop test failed\n' >&2
    exit 25
fi
sed -n '1,160p' "${f32_zero_system_log}"
f32_zero_p17_pass='[NPU-F32-ZERO-SYSTEM][PASS] profile=P17 executed=1 passed=1 error=0x0 system=1 required=1/1 portal_tx=1 groups=0 words=0/0 bytes=0/0 f32_start=0 result_bytes=0'
f32_zero_p18_pass='[NPU-F32-ZERO-SYSTEM][PASS] profile=P18 executed=1 passed=1 error=0x0 system=1 required=1/1 portal_tx=1 groups=0 words=0/0 bytes=0/0 f32_start=0 result_bytes=0'
f32_zero_summary_pass='[NPU-F32-ZERO-SYSTEM][PASS] profiles=2 generic_rejected=1 noncanonical_rejected=1'
if [[ "$(grep -Fxc "${f32_zero_p17_pass}" \
        "${f32_zero_system_log}")" -ne 1 ]] || \
   [[ "$(grep -Fxc "${f32_zero_p18_pass}" \
        "${f32_zero_system_log}")" -ne 1 ]] || \
   [[ "$(grep -Fxc "${f32_zero_summary_pass}" \
        "${f32_zero_system_log}")" -ne 1 ]]; then
    printf 'exact P17/P18 zero-cardinality SystemTop PASS markers missing or duplicated\n' >&2
    exit 26
fi

f32_zero_binding_log="${log_dir}/f32-zero-binding.log"
if ! timeout --signal=TERM --kill-after=2s 10s \
    "${build_dir}/test-npu-backend" "${backend}" \
    --f32-zero-binding >"${f32_zero_binding_log}" 2>&1; then
    sed -n '1,160p' "${f32_zero_binding_log}" >&2
    printf 'NPU P17/P18 zero-cardinality binding test failed\n' >&2
    exit 27
fi
sed -n '1,160p' "${f32_zero_binding_log}"
f32_zero_binding_pass='[NPU-BACKEND-F32-ZERO-BINDING][PASS] canonical_p17_p18=2 split_root_rejected=1 root_layout_rejected=1 gapped_index_rejected=1 canonical_id_rejected=1 arbitrary_name_rejected=1'
if [[ "$(grep -Fxc "${f32_zero_binding_pass}" \
        "${f32_zero_binding_log}")" -ne 1 ]]; then
    printf 'exact P17/P18 zero-cardinality binding PASS marker missing or duplicated\n' >&2
    exit 28
fi

for f32_full_profile in 17 18; do
    f32_full_log="${log_dir}/f32-alu-full-p${f32_full_profile}.log"
    if ! timeout --signal=TERM --kill-after=5s 180s \
        "${build_dir}/test-npu-backend" "${backend}" \
        --f32-alu-profile "${f32_full_profile}" \
        >"${f32_full_log}" 2>&1; then
        sed -n '1,200p' "${f32_full_log}" >&2
        printf 'NPU full P%s F32 ALU regression failed\n' \
            "${f32_full_profile}" >&2
        exit 29
    fi
    sed -n '1,200p' "${f32_full_log}"
done
if [[ "$(grep -Ec '^\[NPU-BACKEND-F32-ALU-V4\]\[PASS\] profile=P17 mode=0 status=0 class=0 read=0 write=0 elements=18432 cycles=[0-9]+ bound=10100768 private_shadow=1 emitted=1 accepted=1 observed_profile=17 required_delta=0/0$' \
        "${log_dir}/f32-alu-full-p17.log")" -ne 1 ]] || \
   [[ "$(grep -Ec '^\[NPU-BACKEND-F32-ALU-V4\]\[PASS\] profile=P18 mode=0 status=0 class=0 read=0 write=0 elements=262144 cycles=[0-9]+ bound=143654944 private_shadow=1 emitted=1 accepted=1 observed_profile=18 required_delta=0/0$' \
        "${log_dir}/f32-alu-full-p18.log")" -ne 1 ]]; then
    printf 'exact full P17/P18 F32 ALU PASS markers missing or duplicated\n' >&2
    exit 30
fi

q8_log="${log_dir}/q8-get-rows.log"
if ! timeout --signal=TERM --kill-after=2s 30s \
    "${build_dir}/test-npu-backend" "${backend}" \
    --q8-get-rows-graph "${q8_canonical_id}" >"${q8_log}" 2>&1; then
    sed -n '1,200p' "${q8_log}" >&2
    printf 'NPU Q8_0 GET_ROWS production graph test failed\n' >&2
    exit 6
fi
sed -n '1,200p' "${q8_log}"
if ! grep -Eq \
    '^\[NPU-BACKEND-Q8-GET-ROWS\]\[PASS\] graph=ggml_backend_graph_compute shape=D1024/N1/V248320/stride1088 index=V-1 owner=q8-get-rows-not-P00 required_delta=1/1 required_enqueued=1 required_completed=1 executed=1 commands=1/1/0 read=1296 write=4096 elements=1024 raw_fp32=1024/1024 identity=full256 cpu_fallback_attempts=0 host_tensor_arithmetic=0 negatives=missing-binding\+bad-src-dtype\+bad-index-dtype\+bad-shape\+bad-op-params\+index-oob\+duplicate-execution canonical_id=[0-9a-f]{64}$' \
    "${q8_log}"; then
    printf 'exact Q8_0 GET_ROWS production PASS marker missing\n' >&2
    exit 7
fi

q8_gemv_log="${log_dir}/q8-gemv.log"
if ! timeout --signal=TERM --kill-after=2s 120s \
    "${build_dir}/test-npu-backend" "${backend}" \
    --q8-gemv-graph "${q8_gemv_canonical_id}" \
    >"${q8_gemv_log}" 2>&1; then
    sed -n '1,240p' "${q8_gemv_log}" >&2
    printf 'NPU Q8_0 MUL_MAT production graph test failed\n' >&2
    exit 8
fi
sed -n '1,240p' "${q8_gemv_log}"
if ! grep -Fq \
    '[NPU-BACKEND-Q8-GEMV-TERMINAL-EMPTY][PASS] graph_node=1710 profile=9 shape=M248320/K1024/N0 owner=q8-gemv system=1 required=1/1 commands=1/1/0 portal_transaction=1 portal_groups=0 read=0 write=0 q8_macs=0 elements=0 identity=full256 cpu_fallback_attempts=0 host_tensor_arithmetic=0 negatives=half-empty+tail-stride+name' \
    "${q8_gemv_log}" || \
   ! grep -Eq \
    '^\[NPU-BACKEND-Q8-GEMV\]\[PASS\] graph=real-ggml_mul_mat shape=M16/K1024/B32 owner=q8-gemv-not-f32-alu-not-get-rows canonical_set=187 profiles=10 excluded_f16=12 required_delta=1/1 required_enqueued=1 required_completed=1 executed=1 commands=1/1/0 read=4104 write=64 q8_macs=16384 elements=16 raw_fp32=16/16 identity=full256 cpu_fallback_attempts=0 host_tensor_arithmetic=0 negatives=missing-binding\+bad-name-dtype-shape-opparams-source\+unknown-id\+identity-index-profile-collision\+overflow\+alias\+duplicate-execution canonical_id=[0-9a-f]{64}$' \
    "${q8_gemv_log}"; then
    printf 'exact Q8_0 MUL_MAT production PASS marker missing\n' >&2
    exit 9
fi

f32_mover_log="${log_dir}/f32-mover.log"
if ! timeout --signal=TERM --kill-after=2s 240s \
    "${build_dir}/test-npu-f32-mover" "${backend}" \
    >"${f32_mover_log}" 2>&1; then
    sed -n '1,280p' "${f32_mover_log}" >&2
    printf 'NPU F32 GET_ROWS/REPEAT production graph test failed\n' >&2
    exit 10
fi
sed -n '1,280p' "${f32_mover_log}"
if ! grep -Fq \
    '[NPU-BACKEND-F32-GET-ROWS][PASS] graph=real-ggml_get_rows shape=D1024/N1/V1 raw_fp32=1024/1024 poisoned_output=covered required_issued=1 required_completed=1 commands=1/1/0 gmem_read=0 gmem_write=0 portal_read=4100 portal_write=4096 portal_groups=129 elements=1024 identity=full256 private_commit=success-only cpu_fallback_attempts=0 host_tensor_arithmetic=0 negatives=index-bounds+overflow+alias+duplicate' \
    "${f32_mover_log}" || \
   ! grep -Fq \
    '[NPU-BACKEND-F32-GET-ROWS-EMPTY][PASS] profiles=2 canonical_nodes=36 shapes=D18432/N0+D262144/N0 real_dispatches=2 commands=2/2/0 read=0 write=0 elements=0 required_issued=2 required_completed=2 identity=full256 cpu_fallback_attempts=0 host_tensor_arithmetic=0' \
    "${f32_mover_log}" || \
   ! grep -Fq \
    '[NPU-BACKEND-F32-GET-ROWS-TERMINAL-EMPTY][PASS] graph_node=1709 profile=4 shape=D1024/N0 owner=f32-get-rows system=1 required=1/1 portal_transaction=1 portal_groups=0 read=0 write=0 elements=0 identity=full256 negatives=half-empty+tail-stride+name' \
    "${f32_mover_log}" || \
   ! grep -Fq \
    '[NPU-BACKEND-F32-REPEAT][PASS] graph=real-ggml_permute-to-ggml_repeat shape=[128,1,16]->[128,128,16] raw_fp32=262144/262144 poisoned_output=1048576/1048576 required_issued=1 required_completed=1 commands=1/1/0 gmem_read=0 gmem_write=0 portal_read=8192 portal_write=1048576 portal_groups=16512 elements=262144 identity=full256 private_commit=success-only cpu_fallback_attempts=0 host_tensor_arithmetic=0 negative=alias' \
    "${f32_mover_log}" || \
   ! grep -Fq \
    '[NPU-BACKEND-F32-MOVER][PASS] canonical_set=91 get_rows=73 repeat=18 empty_get=36 profiles=6 owners=f32-get-rows+f32-repeat-exclusive-from-f32-alu+q8-get+q8-gemv actual_graphs=get1024+empty18432+empty262144+terminal-empty1024+repeat1MiB required_issued=5 required_completed=5 identity=full256 cpu_fallback_attempts=0 host_tensor_arithmetic=0 canonical_sha=ae86cbd2dc835aaabf7788968f37712ed8bd68b4f371e0145ac94867db0d3457 profile_sha=0e7695679f94171303a5a52a59c4a6e57d79874f635e3f540deff9634fa7940a' \
    "${f32_mover_log}"; then
    printf 'exact F32 GET_ROWS/REPEAT production PASS markers missing\n' >&2
    exit 11
fi

argmax_rtl_log="${log_dir}/f32-argmax-rtl.log"
if ! timeout --signal=TERM --kill-after=5s 240s \
    "${build_dir}/test-npu-argmax" >"${argmax_rtl_log}" 2>&1; then
    sed -n '1,280p' "${argmax_rtl_log}" >&2
    printf 'NPU F32 ARGMAX RTL/SystemTop qualification failed\n' >&2
    exit 21
fi
sed -n '1,280p' "${argmax_rtl_log}"
argmax_rtl_pass='[NPU-F32-ARGMAX][PASS] kernel=0x514e0030 owner=f32-argmax positive_cases=11 reject_cases=3 actual_vocab=248320 generic_probe=1000000 oracle=ggml_vec_argmax_f32 semantics=equal-last+signed-zero-last+nan-max-reset full_sequential_scan=1 unaligned_4mod8=1 system_top=1 rv64_config=30 launch=1 terminal=31 private_commit=success-only q8_macs=0 runner_host_tensor_arithmetic=0 cpu_reference=test-only cpu_fallback_attempts=0'
if [[ "$(grep -Fxc "${argmax_rtl_pass}" "${argmax_rtl_log}")" -ne 1 ]]; then
    printf 'exact NPU F32 ARGMAX RTL/SystemTop PASS marker missing or duplicated\n' >&2
    exit 22
fi

sampler_argmax_backend_log="${log_dir}/sampler-argmax-backend.log"
if ! timeout --signal=TERM --kill-after=5s 240s \
    "${build_dir}/test-npu-backend" "${backend}" \
    --sampler-argmax-graph >"${sampler_argmax_backend_log}" 2>&1; then
    sed -n '1,280p' "${sampler_argmax_backend_log}" >&2
    printf 'NPU strict-sampler ARGMAX production graph test failed\n' >&2
    exit 23
fi
sed -n '1,280p' "${sampler_argmax_backend_log}"
sampler_argmax_ledger_pass='[NPU-SAMPLER-ARGMAX-LEDGER][PASS] dispatch=4001 transactions=1 expected_transactions=1 elements=248320 expected_elements=248320 read_bytes=993288 expected_read_bytes=993288 scalar_write_bytes=4 expected_scalar_write_bytes=4 sampled_tokens=1 expected_sampled_tokens=1 host_scalar_copy_bytes=4 full_vocab_host_exports=0 full_vocab_host_export_bytes=0 cpu_candidate_scans=0 invalid_tokens=0'
sampler_argmax_backend_pass='[NPU-BACKEND-SAMPLER-ARGMAX][PASS] graph=real-ggml_argmax graph_node=1713 source_node=1712 profile=0 shape=V248320-to-I32-scalar owner=sampler-argmax required_delta=1/1 required_enqueued=1 required_completed=1 executed=1 commands=1/1/0 read=993288 write=4 elements=248320 token=248319/248319 output_bytes=4 tail_untouched=28/28 identity=full256 oracle=ggml_vec_argmax_f32-test-only full_vocab_host_exports=0 cpu_candidate_scans=0 cpu_fallback_attempts=0 host_tensor_arithmetic=0 negatives=missing-binding+bad-name+bad-canonical canonical_id=333b5a00492fe61586c65c614c15fc3886d2da8661a6f4b818efcd78ef77d97d'
if [[ "$(grep -Fxc "${sampler_argmax_ledger_pass}" \
        "${sampler_argmax_backend_log}")" -ne 1 ]] || \
   [[ "$(grep -Fxc "${sampler_argmax_backend_pass}" \
        "${sampler_argmax_backend_log}")" -ne 1 ]]; then
    printf 'exact strict-sampler ARGMAX ledger/backend PASS marker missing or duplicated\n' >&2
    exit 24
fi

remaining_log="${log_dir}/remaining-433.log"
if ! timeout --signal=TERM --kill-after=5s 900s \
    "${build_dir}/test-npu-remaining" "${backend}" \
    >"${remaining_log}" 2>&1; then
    sed -n '1,360p' "${remaining_log}" >&2
    printf 'NPU final 433-node production graph tests failed\n' >&2
    exit 12
fi
sed -n '1,360p' "${remaining_log}"
if ! grep -Fq \
    '[NPU-BACKEND-REMAINING][PASS] canonical=433 profiles=30 owners=13 required_partition=646+433+1=1080 actual_graphs=unary+unary-inplace+rms+rms-inplace+ssm+cpy-empty2+cpy-view+cont+cont-view+set+attention+rope+rope-inplace+softmax+softmax-inplace route=global-to-public-local-explicit identity=full256 raw_transport_only=1 private_commit=success-only cpu_fallback_attempts=0 host_tensor_arithmetic=0 negatives=missing-binding+identity+profile+layout+alias-partial+alias-owner+alias-source-source+alias-view+duplicate+error canonical_sha=ef0a458d780a94185d7555c7f02e7ab65daa11ddc0c9432a665ba80cc9591048 profile_sha=585980e9c9863e6df3823263222fee58fd4bba815e5aa4ebb21f78dcbd86ac05' \
    "${remaining_log}"; then
    printf 'exact final 433-node runtime PASS marker missing\n' >&2
    exit 13
fi

rtl_log="${log_dir}/rtl-self-test.log"
if ! timeout --signal=TERM --kill-after=2s 10s \
    "${build_dir}/test-npu-backend" "${backend}" --rtl-self-test \
    >"${rtl_log}" 2>&1; then
    sed -n '1,160p' "${rtl_log}" >&2
    printf 'NPU Verilated RTL self-test failed\n' >&2
    exit 14
fi
sed -n '1,160p' "${rtl_log}"
if ! grep -Fxq \
    '[NPU-BACKEND-RTL][PASS] cycles=29 bytes=16 error=0' \
    "${rtl_log}"; then
    printf 'exact NPU Verilated RTL PASS marker missing\n' >&2
    exit 15
fi

static_log="${log_dir}/project-owned-warning-audit.log"
if ! /usr/bin/c++ \
        -isystem "${verilated_mdir}" \
        -isystem "${system_verilated_mdir}" \
        -isystem /usr/share/verilator/include \
        -isystem /usr/share/verilator/include/vltstd \
        -I"${build_dir}/generated" \
        -I"${source_dir}" \
        -I"${project_root}/third_party/llama.cpp/ggml/include" \
        -I"${project_root}/third_party/llama.cpp/ggml/src" \
        -DGGML_BACKEND_DL -DGGML_BACKEND_BUILD -DGGML_BACKEND_SHARED \
        -DGGML_SHARED \
        -O3 -DNDEBUG -Wall -Wextra -Wpedantic -std=c++17 \
        -fsyntax-only \
        "${source_dir}/npu-verilator-f32-mover-runner.cpp" \
        "${source_dir}/npu-verilator-argmax-runner.cpp" \
        "${source_dir}/npu-verilator-exact-runner.cpp" \
        "${source_dir}/ggml-npu.cpp" \
        "${source_dir}/test-f32-zero.cpp" \
        "${source_dir}/test-f32-mover.cpp" \
        "${source_dir}/test-argmax.cpp" \
        "${source_dir}/test-remaining.cpp" \
        >"${static_log}" 2>&1; then
    sed -n '1,200p' "${static_log}" >&2
    printf 'project-owned NPU runtime warning audit failed\n' >&2
    exit 16
fi
if [[ -s "${static_log}" ]]; then
    sed -n '1,200p' "${static_log}" >&2
    printf 'project-owned NPU runtime source emitted compiler warnings\n' >&2
    exit 17
fi
if ! bash -n \
        "${project_root}/scripts/build_npu_backend.sh" \
        "${project_root}/scripts/run_qwen_strict_smoke.sh"; then
    printf 'updated NPU shell script syntax audit failed\n' >&2
    exit 18
fi
printf '[NPU-PROJECT-SOURCE-WARNINGS][PASS] cpp=0 shell-syntax=pass python-manifest-audits=q8-gemv+f32-mover+remaining433+sampler-argmax\n' \
    >"${static_log}"
sed -n '1,40p' "${static_log}"

backend_pass='[NPU-BACKEND][PASS] device=NPU abi=v2 canonical-binding=v1 exact-existing=646-canonical-required-verilated exact-remaining=433-canonical-required-verilated exact-sampler-argmax=1-canonical-required-verilated required=1080 unsupported=0 raw-only=1 identity=full256 rtl-self-test=pass'
printf '%s\n' "${backend_pass}"
acceptance_summary="${log_dir}/acceptance-summary.log"
{
    printf '[NPU-BUILD-ENV] TMPDIR=%s TMP=%s TEMP=%s\n' \
        "${TMPDIR}" "${TMP}" "${TEMP}"
    printf '[NPU-FROZEN-RTL] TensorNpuCoprocessor.v sha256=%s\n' \
        "${actual_coproc_sha}"
    printf '[NPU-REMAINING-ACCEPTANCE][PASS] canonical=433 profiles=30 owners=13 actual_dispatches=8 strict_partition=646+433+1 strict_target=1080/0 cpu_fallback_attempts=0 host_tensor_arithmetic=0\n'
    printf '[NPU-SAMPLER-ARGMAX-ACCEPTANCE][PASS] canonical=1 directed_graph_dispatches=1 elements=248320 read_bytes=993288 scalar_write_bytes=4 sampled_tokens=1 full_vocab_host_exports=0 cpu_candidate_scans=0 cpu_fallback_attempts=0 host_tensor_arithmetic=0\n'
    printf '%s\n' "${backend_pass}"
} >"${acceptance_summary}"
sed -n '1,80p' "${acceptance_summary}"
