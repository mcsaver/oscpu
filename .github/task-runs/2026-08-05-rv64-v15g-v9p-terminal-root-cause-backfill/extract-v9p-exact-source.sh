#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
source_result_rel=.github/task-runs/2026-07-23-rv64-v9p-serialize-current-design/architecture-current-design.result.json
run_rel=.github/task-runs/2026-08-05-rv64-v15g-v9p-terminal-root-cause-backfill
source_result=${repo_root}/${source_result_rel}
evidence_dir=${repo_root}/${run_rel}/evidence/v9p-exact-source
source_dir=${evidence_dir}/sources
expected_design_sha=9ac1ae14b18635cf25ea80efa7ce4cd85a07bdd6f0e525755658dc8dcd26207a
anchor_commit=c29532ead32bf2a268b821cef9665a44aec58f9f
diagnostic_commit=d2bd4d2bad5f285a76ec0883dd7fe7ff0d2f1ccd
diagnostic_tb_path=npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv
diagnostic_tb_object=90c89d5cfc270e69f32bae8b540e73af5fd1f916
diagnostic_tb_sha256=fc6d14ad406c8758dbd87238b05f2e962fabd52ef28a61bc204c4df1ccdac7b2

paths=(
  npc/rv64/vsrc/execute/OooIntBackend.v
  npc/rv64/vsrc/memory/OooMemAxiBridge.v
  npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v
  npc/rv64/vsrc/memory/OooStoreQueue.v
  npc/rv64/vsrc/memory/OooMemInflightQueue.v
  npc/rv64/vsrc/scheduling/OooIntIssueQueue.v
)
objects=(
  b21a29e6a0c949ee196479921494260f44fa025e
  e1900f4c0aa5a91ceb5b86fe9648825fb733bf3b
  ba94cafcdd1dae8225c10e0709ce705ee5b58ad9
  deb3f2c8f1311c0a1ff074eb2f2b8c1b3ee30bec
  0523a861c7c4944c82e4d1f73451d2e1409acbb1
  2d407b18fedbffe0e14b17282eed00a376d87081
)
expected_sha256=(
  87834cb81902f8329aac5ac68dc40565a3407ce7410ab8a5e89c615e54a944fa
  b4386aec043987aa6661e0d608153b1f1a7b540380b42b0476ca321d62530d62
  be48ff513dcccbd5ea2dd7c15ac83832289753bf706c1efbeda6b4833807556c
  5a5179a0cbfa01048510cb842615b4f63e106816d06c15afdcec02a6b8c68241
  7a9bf388210313dca93ec647d1c1cd6c2e64ed7b1a149f587abd1098b8878ad6
  d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced94f9c218b
)
provenance=(
  dangling-git-blob
  dangling-git-blob
  commit:${anchor_commit}
  commit:${anchor_commit}
  commit:${anchor_commit}
  commit:${anchor_commit}
)

diagnostic_dep_paths=(
  npc/rv64/vsrc/memory/PmpChecker.v
  npc/rv64/vsrc/memory/OooTypedPmaChecker.v
  npc/rv64/vsrc/memory/OooTypedMemoryClassifier.v
  npc/rv64/vsrc/memory/OooPmaChecker.v
  npc/rv64/vsrc/memory/OooPostTranslateMemoryClass.v
  npc/rv64/vsrc/cache/OooDataWordCache.v
  npc/rv64/vsrc/sram/Sram4096x113.v
  npc/rv64/vsrc/memory/OooSv39Tlb.v
)
diagnostic_dep_objects=(
  77ffb1b0b9972206eb6742cb17923cf96a710074
  6d9ab8bd7000e27fd354f3062cfaea23f54f3932
  660faead2638e82555f8f48ae6f2f314740d7fd4
  2b2a2d9f9c93c217cadcd6b76d633c1c6512a956
  2f336e71357a9a50d28dae03d757c275c86598a3
  828dbfa87286c943a2f2a1841acfcc5b910dc013
  0915527d9042ce92596678b9d11d4a73c4b2aafe
  6c2129890ce7bb8b7177328a47f2a54a5bcae38a
)
diagnostic_dep_sha256=(
  f4600c320b03f0ffd3bcdff9336bcea2a17580fa7b8752da18d7db35956da4c2
  ce644709dd4bfa8d2710fc4e32dea24b660ab24f55d745552ab5aebd09263de0
  aa573507b2ec3b76053470784a9d303b63eee5c9716807daada3f9a51c742649
  e197b137bfe1126f9191eaf3b2cfce779d26bdce0ead4a94d831552fe5732c2b
  717edd10049be5a00edb8f100fff59a1577704eb81564619bea4f262837553b9
  50ee1121c91ec92bcc8c53b1bbb9715ca719c3181b403c1944c3634f7653c57d
  cf3b7f4f920c6ce5383e1cf276b6528dd4233469c4236978b8c0660761997fad
  5f94c50b5932aab0318541bbbf8421330e09e622716202cd16ed752c80380c8f
)

[[ -f ${source_result} ]]
[[ ! -L ${run_rel} ]]
mkdir -p "${evidence_dir}"
[[ ! -L ${evidence_dir} ]]

tmp_dir=$(mktemp -d "${repo_root}/.github/runtime-artifacts/v9p-source-extract.XXXXXX")
cleanup() {
  rm -rf -- "${tmp_dir}"
}
trap cleanup EXIT

publish_exact() {
  local candidate=$1
  local target=$2
  if [[ -e ${target} ]]; then
    [[ -f ${target} && ! -L ${target} ]]
    cmp -s -- "${candidate}" "${target}"
    rm -f -- "${candidate}"
    return
  fi
  mkdir -p -- "$(dirname -- "${target}")"
  mv -- "${candidate}" "${target}"
}

source_result_sha256=$(sha256sum -- "${source_result}" | awk '{print $1}')
design_id=$(jq -er '.rtl_source_set.design_id' "${source_result}")
source_set_sha256=$(jq -er '.rtl_source_set.sha256' "${source_result}")
file_count=$(jq -er '.rtl_source_set.file_count' "${source_result}")
recomputed_source_set_sha256=$(
  jq -cSj '.rtl_source_set.files' "${source_result}" | sha256sum | awk '{print $1}'
)
[[ ${design_id} == sha256:${expected_design_sha} ]]
[[ ${source_set_sha256} == ${expected_design_sha} ]]
[[ ${recomputed_source_set_sha256} == ${expected_design_sha} ]]
[[ ${file_count} == 146 ]]

selected_tsv=${tmp_dir}/selected-files.tsv
: >"${selected_tsv}"
for index in "${!paths[@]}"; do
  path=${paths[${index}]}
  object=${objects[${index}]}
  expected=${expected_sha256[${index}]}
  origin=${provenance[${index}]}
  [[ $(git cat-file -t "${object}") == blob ]]
  manifest_sha=$(jq -er --arg path "${path}" '.rtl_source_set.files[$path]' "${source_result}")
  [[ ${manifest_sha} == ${expected} ]]
  candidate=${tmp_dir}/${index}.rtl
  git cat-file blob "${object}" >"${candidate}"
  actual=$(sha256sum -- "${candidate}" | awk '{print $1}')
  [[ ${actual} == ${expected} ]]
  publish_exact "${candidate}" "${source_dir}/${path}"
  printf '%s\t%s\t%s\t%s\n' "${path}" "${object}" "${expected}" "${origin}" >>"${selected_tsv}"
done

selected_json=${tmp_dir}/selected-files.json
jq -Rn '[inputs | split("\t") | {
  path: .[0], object_id: .[1], sha256: .[2], provenance: .[3]
}]' <"${selected_tsv}" >"${selected_json}"
selected_source_set_sha256=$(
  jq -cSj 'map({key: .path, value: .sha256}) | from_entries' \
    "${selected_json}" | sha256sum | awk '{print $1}'
)

receipt_candidate=${tmp_dir}/reconstruction-receipt.json
jq -n \
  --arg schema npc-rv64-v9p-exact-source-reconstruction-v1 \
  --arg source_result "${source_result_rel}" \
  --arg source_result_sha256 "${source_result_sha256}" \
  --arg design_id "${design_id}" \
  --arg source_set_sha256 "${source_set_sha256}" \
  --arg recomputed_source_set_sha256 "${recomputed_source_set_sha256}" \
  --arg selected_source_set_sha256 "${selected_source_set_sha256}" \
  --arg anchor_commit "${anchor_commit}" \
  --argjson file_count "${file_count}" \
  --slurpfile artifacts "${selected_json}" \
  '{
    schema: $schema,
    status: "PASS",
    frozen_binding: {
      source_result: $source_result,
      source_result_sha256: $source_result_sha256,
      design_id: $design_id,
      source_set_sha256: $source_set_sha256,
      recomputed_source_set_sha256: $recomputed_source_set_sha256,
      file_count: $file_count
    },
    reconstruction: {
      anchor_commit: $anchor_commit,
      selected_source_set_sha256: $selected_source_set_sha256,
      artifact_count: ($artifacts[0] | length),
      artifacts: $artifacts[0]
    }
  }' >"${receipt_candidate}"
publish_exact "${receipt_candidate}" "${evidence_dir}/reconstruction-receipt.json"

[[ $(git cat-file -t "${diagnostic_tb_object}") == blob ]]
diagnostic_tb_candidate=${tmp_dir}/tb_ooo_mem_axi_bridge.sv
git cat-file blob "${diagnostic_tb_object}" >"${diagnostic_tb_candidate}"
[[ $(sha256sum -- "${diagnostic_tb_candidate}" | awk '{print $1}') == \
   ${diagnostic_tb_sha256} ]]
publish_exact "${diagnostic_tb_candidate}" \
  "${evidence_dir}/testbench/${diagnostic_tb_path}"

diagnostic_receipt_candidate=${tmp_dir}/diagnostic-testbench-receipt.json
jq -n \
  --arg schema npc-rv64-v9p-terminal-diagnostic-testbench-v1 \
  --arg commit "${diagnostic_commit}" \
  --arg path "${diagnostic_tb_path}" \
  --arg object_id "${diagnostic_tb_object}" \
  --arg sha256 "${diagnostic_tb_sha256}" \
  '{
    schema: $schema,
    status: "PASS",
    purpose: "V9R SQ-query retry C0 focused negative/positive RTL test",
    testbench: {
      commit: $commit,
      path: $path,
      object_id: $object_id,
      sha256: $sha256
    }
  }' >"${diagnostic_receipt_candidate}"
publish_exact "${diagnostic_receipt_candidate}" \
  "${evidence_dir}/diagnostic-testbench-receipt.json"

diagnostic_dep_tsv=${tmp_dir}/diagnostic-dependencies.tsv
: >"${diagnostic_dep_tsv}"
for index in "${!diagnostic_dep_paths[@]}"; do
  path=${diagnostic_dep_paths[${index}]}
  object=${diagnostic_dep_objects[${index}]}
  expected=${diagnostic_dep_sha256[${index}]}
  [[ $(git cat-file -t "${object}") == blob ]]
  [[ $(jq -er --arg path "${path}" '.rtl_source_set.files[$path]' \
       "${source_result}") == ${expected} ]]
  candidate=${tmp_dir}/diagnostic-dependency-${index}.rtl
  git cat-file blob "${object}" >"${candidate}"
  [[ $(sha256sum -- "${candidate}" | awk '{print $1}') == ${expected} ]]
  publish_exact "${candidate}" "${source_dir}/${path}"
  printf '%s\t%s\t%s\n' "${path}" "${object}" "${expected}" \
    >>"${diagnostic_dep_tsv}"
done

diagnostic_dep_json=${tmp_dir}/diagnostic-dependencies.json
jq -Rn '[inputs | split("\t") | {
  path: .[0], object_id: .[1], sha256: .[2]
}]' <"${diagnostic_dep_tsv}" >"${diagnostic_dep_json}"
diagnostic_dep_set_sha256=$(
  jq -cSj 'map({key: .path, value: .sha256}) | from_entries' \
    "${diagnostic_dep_json}" | sha256sum | awk '{print $1}'
)
diagnostic_dep_receipt_candidate=${tmp_dir}/diagnostic-dependency-receipt.json
jq -n \
  --arg schema npc-rv64-v9p-exact-bridge-diagnostic-dependencies-v1 \
  --arg design_id "${design_id}" \
  --arg anchor_commit "${anchor_commit}" \
  --arg source_set_sha256 "${diagnostic_dep_set_sha256}" \
  --slurpfile artifacts "${diagnostic_dep_json}" \
  '{
    schema: $schema,
    status: "PASS",
    design_id: $design_id,
    anchor_commit: $anchor_commit,
    source_set_sha256: $source_set_sha256,
    artifact_count: ($artifacts[0] | length),
    artifacts: $artifacts[0]
  }' >"${diagnostic_dep_receipt_candidate}"
publish_exact "${diagnostic_dep_receipt_candidate}" \
  "${evidence_dir}/diagnostic-dependency-receipt.json"

printf '[RV64-V9P-EXACT-SOURCE][PASS] design_id=%s artifacts=%s selected_sha256=%s\n' \
  "${design_id}" "${#paths[@]}" "${selected_source_set_sha256}"
printf '[RV64-V9P-DIAGNOSTIC-TB][PASS] commit=%s object=%s sha256=%s\n' \
  "${diagnostic_commit}" "${diagnostic_tb_object}" "${diagnostic_tb_sha256}"
printf '[RV64-V9P-DIAGNOSTIC-DEPS][PASS] artifacts=%s source_set_sha256=%s\n' \
  "${#diagnostic_dep_paths[@]}" "${diagnostic_dep_set_sha256}"
