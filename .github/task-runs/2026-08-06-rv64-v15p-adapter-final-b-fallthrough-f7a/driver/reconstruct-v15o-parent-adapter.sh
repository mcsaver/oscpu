#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
source_path="${repo_root}/npc/rv64/vsrc/memory/OooLsuAxiLaneAdapter.v"
expected_parent_sha=3f59eb66967afca26700a520fedba6372a0ab7f96464048a5493642df55ab3b6

if [[ $# -ne 1 ]]; then
  echo "usage: $0 OUTPUT" >&2
  exit 2
fi
output_path="$(realpath -m "$1")"
mkdir -p "$(dirname "${output_path}")"
cp -- "${source_path}" "${output_path}"

perl -0pi -e '
  s/  assign u_axi_rresp_o = u_rresp_q;\n\n  assign d_axi_arvalid_o/  assign u_axi_rresp_o = u_rresp_q;\n  assign u_axi_bvalid_o = (state_q == S_B_RESP);\n  assign u_axi_bresp_o = u_bresp_q;\n\n  assign d_axi_arvalid_o/g;
  s/  wire split_write_more_beats_w =\n      cmd_split_q && \(next_beat_idx_w < cmd_nbytes_q\);\n  \/\/ The target B is already a registered terminal\.  Let only the final\n  \/\/ logical-write beat fall through to the upstream owner; a stalled owner is\n  \/\/ captured by the existing S_B_RESP register on the same edge\.  Keeping\n  \/\/ downstream BREADY state-only avoids a READY loop through the crossbar\.\n  wire final_b_fallthrough_w = !rst && \(state_q == S_W_RESP\) &&\n                               d_axi_bvalid_i &&\n                               !split_write_more_beats_w;\n  assign u_axi_bvalid_o = \(state_q == S_B_RESP\) \|\|\n                          final_b_fallthrough_w;\n  assign u_axi_bresp_o = final_b_fallthrough_w \? resp_with_b_w :\n                                                    u_bresp_q;\n//g;
  s/            if \(split_write_more_beats_w\) begin/            if (cmd_split_q && (next_beat_idx_w < cmd_nbytes_q)) begin/g;
  s/              state_q <= u_axi_bready_i \? S_IDLE : S_B_RESP;/              state_q <= S_B_RESP;/g;
  s/  reg u_b_stall_q;\n//g;
  s/  reg \[1:0\] u_bresp_stall_q;\n//g;
  s/      u_b_stall_q <= 1\x27b0;\n//g;
  s/      if \(u_b_stall_q &&\n          \(!u_axi_bvalid_o \|\| u_axi_bresp_o !== u_bresp_stall_q\)\) begin\n        \$error\("\[LANE-B-HOLD\] upstream B changed while stalled \@%0t", \$time\);\n        \$fatal;\n      end\n//g;
  s/      if \(\(state_q == S_W_RESP\) && d_axi_bvalid_i &&\n          split_write_more_beats_w && u_axi_bvalid_o\) begin\n        \$error\("\[LANE-B-SPLIT\] non-final split B escaped upstream \@%0t", \$time\);\n        \$fatal;\n      end\n//g;
  s/      if \(final_b_fallthrough_w &&\n          \(!u_axi_bvalid_o \|\| u_axi_bresp_o !== resp_with_b_w\)\) begin\n        \$error\("\[LANE-B-FALLTHROUGH\] final B response mismatch \@%0t", \$time\);\n        \$fatal;\n      end\n//g;
  s/      u_b_stall_q <= u_axi_bvalid_o && !u_axi_bready_i;\n//g;
  s/      u_bresp_stall_q <= u_axi_bresp_o;\n//g;
' "${output_path}"

actual_parent_sha="$(sha256sum "${output_path}" | awk '{print $1}')"
if [[ "${actual_parent_sha}" != "${expected_parent_sha}" ]]; then
  echo "[V15P-PARENT-ADAPTER][FAIL] expected=${expected_parent_sha} actual=${actual_parent_sha}" >&2
  exit 1
fi
echo "[V15P-PARENT-ADAPTER][PASS] sha256=${actual_parent_sha} path=${output_path}"
