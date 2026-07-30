#!/usr/bin/env bash
set -euo pipefail

task_root=".github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert"
contract="${task_root}/subagent-contracts/v10e-checker-debug-valid-final-review-v4.json"
rendered="${task_root}/subagent-contracts/v10e-checker-debug-valid-final-review-v4.rendered.txt"
tool=".github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py"

test ! -e "${contract}"
test ! -e "${rendered}"

python3 "${tool}" create \
  --task-id v10e_checker_debug_valid_final_review_v4 \
  --task-kind read-only-review \
  --goal "独立复核本地 RV64 systemd natural-poweroff 终端事务与 NpcSimTop.debug_ooo_flags_o 开启态证据：六类 raw terminal event 按出现次数精确为一且保持周期顺序；宿主预算结束前 RTL assertion marker 优先判 FAIL；bit63 仅表示诊断 payload 配置有效；64-cycle Verilator 观测绑定 current design-id、仿真器、RTL/C++ 源文件与三份配置哈希。" \
  --allow-path Linux/scripts/check-npc-systemd-guest.sh \
  --allow-path Linux/scripts/npc-systemd-strict-check.sh \
  --allow-path Linux/scripts/npc_systemd_transaction_evidence.py \
  --allow-path Linux/scripts/tests/test_check_npc_systemd_guest_contract.py \
  --allow-path Linux/scripts/tests/test_npc_systemd_strict_check.py \
  --allow-path Linux/scripts/tests/test_npc_systemd_transaction_evidence.py \
  --allow-path npc/rv64/vsrc/sim/NpcSimTop.sv \
  --allow-path npc/rv64/csrc/cpu/cpu-exec.cpp \
  --allow-path npc/rv64/testbench/scripts/test_debug_ooo_flags_contract.py \
  --allow-path npc/rv64/eval/ppa/tools/architecture_hard_gates.py \
  --allow-path "${task_root}/run-v10e-current-design-systemd-strict.sh" \
  --allow-path "${task_root}/launch-v10e-current-design-systemd-strict.sh" \
  --allow-path "${task_root}/test-runner-contract.py" \
  --allow-path "${task_root}/run-debug-valid-enabled-smoke.sh" \
  --allow-path "${task_root}/test-strict-checker-current.log" \
  --allow-path "${task_root}/test-guest-checker-current.log" \
  --allow-path "${task_root}/test-transaction-parser-current.log" \
  --allow-path "${task_root}/test-debug-flags-current.log" \
  --allow-path "${task_root}/test-runner-contract-current.log" \
  --allow-path "${task_root}/debug-valid-enabled-smoke-v2.status" \
  --allow-path .github/runtime-artifacts/rv64-systemd-strict/prelaunch-5f9dd068-debug-valid-enabled-v2/validation.log \
  --allow-path .github/runtime-artifacts/rv64-systemd-strict/prelaunch-5f9dd068-debug-valid-enabled-v2/console.log \
  --allow-path .github/runtime-artifacts/rv64-systemd-strict/prelaunch-5f9dd068-debug-valid-enabled-v2/sim-build/obj_dir/VNpcSimTop__verFiles.dat \
  --allow-path "${task_root}/rootfs-c1b531-systemd-strict-6b-a3/binding.txt" \
  --allow-path "${task_root}/rootfs-c1b531-systemd-strict-6b-a3/guest/console.log" \
  --allow-path "${task_root}/rootfs-c1b531-systemd-strict-6b-a3.status" \
  --allow-path .github/AGENTS.md \
  --allow-path .github/instructions/rtl-agent-task-contract.instructions.md \
  --allow-path "${contract}" \
  --allow-read-command rg \
  --allow-read-command sed \
  --allow-read-command sha256sum \
  --required-context .github/AGENTS.md \
  --required-context .github/instructions/rtl-agent-task-contract.instructions.md \
  --required-context Linux/scripts/check-npc-systemd-guest.sh \
  --required-context npc/rv64/vsrc/sim/NpcSimTop.sv \
  --required-context npc/rv64/csrc/cpu/cpu-exec.cpp \
  --required-context "${task_root}/run-v10e-current-design-systemd-strict.sh" \
  --deliverable "按 RTL 对象或本地证据文件、周期或编译配置、testbench/EDA 观测、PASS/GAP 范围组织结论；优先尝试构造同一日志行重复终端事件、断言查询返回码大于一、unexpected sim_rc、源码或配置 post-hash 漂移造成假绿的具体反例；保留 a3 历史 RED、a4 尚未运行与 PPA 未资格化边界。" \
  --success-criterion "guest checker 当前日志为 12/12 PASS，源码同时覆盖六类跨行重复、六类同一行重复、五个相邻逆序、两种 V9R marker 乘 host-timeout/max-cycle 以及 assertion 查询 rc=2；runner contract 明确拒绝按行计数和忽略终端查询错误两个变体；enabled v2 status 为 PASS，观测 bit63=1、bits62:46=0、valid=1、64 cycles/6 commits、sim_rc=1，design-id 前后均为 5f9dd06860a91dfc5461357c731fa2d4c34b91cb3b3cdedc754f0972f8bf4c5a，NpcSimTop/cpu-exec/.config/auto.conf/autoconf.h 前后哈希一致。" \
  --out "${contract}"

python3 "${tool}" validate "${contract}"
python3 "${tool}" render "${contract}" >"${rendered}"
sha256sum "${contract}" "${rendered}"
