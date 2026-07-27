#!/usr/bin/env bash
set -u

: "${V10B_REAL_IVERILOG:?missing V10B_REAL_IVERILOG}"
: "${V10B_COMPILE_RC_FILE:?missing V10B_COMPILE_RC_FILE}"

"${V10B_REAL_IVERILOG}" "$@"
rc=$?
printf '%s\n' "${rc}" > "${V10B_COMPILE_RC_FILE}"
exit "${rc}"
