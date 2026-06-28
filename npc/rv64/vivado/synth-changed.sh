#!/usr/bin/env bash
# 增量时序回归:只综合 git 改动涉及的 vsrc 模块(每模块 OOC+内存看门狗),报告 logic 延迟/逻辑级。
# 把时序分析像 eval 一样融入每轮迭代,避免每次全核/全模块综合。
# 用法: synth-changed.sh [GIT_REF]
#   无参=working tree(已改未提交)的 *.v;给 ref(如 HEAD~1)=该 ref..HEAD 改动的 *.v。
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NPC_RV64="$(cd "$HERE/.." && pwd)"
ROOT="$(cd "$NPC_RV64/../.." && pwd)"
REF="${1:-}"
if [[ -n "$REF" ]]; then
  files=$(git -C "$ROOT" diff --name-only "$REF" -- 'npc/rv64/vsrc/**/*.v')
else
  files=$(git -C "$ROOT" status --porcelain -- 'npc/rv64/vsrc/**/*.v' | awk '{print $2}')
fi
mods=$(echo "$files" | grep -E '\.v$' | xargs -r -n1 basename 2>/dev/null | sed 's/\.v$//' | sort -u)
[[ -z "$mods" ]] && { echo "[synth-changed] 无改动的 vsrc 模块(${REF:-working tree})"; exit 0; }
echo "[synth-changed] 改动模块: $(echo $mods | tr '\n' ' ')"
for m in $mods; do
  echo "--- $m ---"
  "$HERE/run-synth-module.sh" "$m" 2.0 >/dev/null 2>&1 || { echo "  $m: 综合失败/无 reg-to-reg 路径"; continue; }
  grep -E 'Data Path Delay|Logic Levels' "$HERE/out/latest-mod/timing_paths.rpt" 2>/dev/null | head -2 | sed 's/^/  /'
done
echo "[synth-changed] 完成。logic delay+Logic Levels 是 OOC 下可信的相对时序指标(route 不可信)。"
