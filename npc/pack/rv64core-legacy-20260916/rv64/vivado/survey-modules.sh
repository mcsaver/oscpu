#!/usr/bin/env bash
# 顺序普查多个嫌疑模块的关键路径(一次只跑一个 vivado=内存安全,不崩 WSL)。
# 结果汇总到 out/survey-<ts>.txt：每模块最差路径数据延迟(ns)。
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"; SUM="$HERE/out/survey-$TS.txt"
mkdir -p "$HERE/out"
MODS=("${@:-}")
if [ -z "${MODS[*]}" ]; then
  MODS=(OooIntIssueQueue PmpChecker OooDispatchBackend OooFrontendBackendDispatchMux \
        OooFetchAxiBridge OooMemAxiBridge OooFpArithGate OooFpConvertGate CsrFile \
        OooRob OooPhysRegFile OooBranchDirectionPredictor)
fi
echo "# 关键路径普查 $TS" > "$SUM"
for m in "${MODS[@]}"; do
  echo "[survey] $m ..." | tee -a "$SUM"
  "$HERE/run-synth-module.sh" "$m" 2.0 >/dev/null 2>&1 || { echo "  $m: SYNTH FAILED" | tee -a "$SUM"; continue; }
  d="$HERE/out/latest-mod"
  delay=$(grep -E 'Data Path Delay' "$d/timing_paths.rpt" 2>/dev/null | head -1 | grep -oE 'logic [0-9.]+ns' | grep -oE '[0-9.]+ns')
  lvl=$(grep -E 'Logic Levels' "$d/timing_paths.rpt" 2>/dev/null | head -1 | grep -oE '[0-9]+' | head -1)
  src=$(grep -E '^\s*Source:' "$d/timing_paths.rpt" 2>/dev/null | head -1 | sed 's/.*Source: *//')
  dst=$(grep -E '^\s*Destination:' "$d/timing_paths.rpt" 2>/dev/null | head -1 | sed 's/.*Destination: *//')
  echo "  $m: logic_delay=${delay:-NA} levels=${lvl:-NA}  $src -> $dst" | tee -a "$SUM"
done
echo "[survey] done -> $SUM" | tee -a "$SUM"
# 按延迟排序
echo "=== 按数据延迟排序 ===" | tee -a "$SUM"
grep -E 'logic_delay=' "$SUM" | sort -t= -k2 -rn | tee -a "$SUM"
