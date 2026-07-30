#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import hashlib
import json
import shlex
import subprocess


ROOT = Path(".")
RUN_DIR = (
    ROOT
    / ".github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert"
)
OUT = RUN_DIR / "review-v3"
RUNNER_PATH = RUN_DIR / "run-v10e-current-design-systemd-strict.sh"
SELFTEST_PATH = RUN_DIR / "test-runner-contract.py"
EXPECTED_DESIGN = (
    "c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594"
)


def read_rc(path: Path) -> int:
    return int(path.read_text(encoding="utf-8").split("rc=", 1)[1].strip())


runner_text = RUNNER_PATH.read_text(encoding="utf-8")
selftest_text = SELFTEST_PATH.read_text(encoding="utf-8")
runner_lines = runner_text.splitlines()
selftest_lines = selftest_text.splitlines()

pattern_line_no, pattern_line = next(
    (number, line)
    for number, line in enumerate(runner_lines, 1)
    if "V9Q-(BRIDGE-HOLDER" in line
)
pattern_token = pattern_line.rstrip()
if pattern_token.endswith("\\"):
    pattern_token = pattern_token[:-1].rstrip()
pattern = shlex.split(pattern_token)[0]
sample = (
    "[V10D-FIXTURE-FAIL]\n"
    "RTL assertion fixture\n"
    "[FIXTURE_ASSERT_FAIL]\n"
)
rg_bad = subprocess.run(
    ["rg", pattern],
    input=sample,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    check=False,
)
corrected = pattern.replace(r"\\[", r"\[").replace(r"\\]", r"\]")
rg_control = subprocess.run(
    ["rg", corrected],
    input=sample,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    check=False,
)
simple_line_no = next(
    number
    for number, line in enumerate(selftest_lines, 1)
    if '["rg", "RTL assertion"' in line
)

fixture_parts = [
    (
        "[V10E-V3][ASSERTION-REGEX-SOURCE] "
        f"{RUNNER_PATH.as_posix()}:{pattern_line_no}\n"
    ),
    (
        "[V10E-V3][ASSERTION-REGEX-ARGV] "
        + json.dumps(["rg", pattern], ensure_ascii=False)
        + "\n"
    ),
    f"[V10E-V3][ASSERTION-REGEX-INPUT] {sample!r}\n",
    f"[V10E-V3][ASSERTION-REGEX-RC] {rg_bad.returncode}\n",
    "[V10E-V3][ASSERTION-REGEX-OUTPUT-BEGIN]\n",
    rg_bad.stdout,
    "[V10E-V3][ASSERTION-REGEX-OUTPUT-END]\n",
    (
        "[V10E-V3][CONTROL-REGEX-ARGV] "
        + json.dumps(["rg", corrected], ensure_ascii=False)
        + "\n"
    ),
    f"[V10E-V3][CONTROL-REGEX-RC] {rg_control.returncode}\n",
    "[V10E-V3][CONTROL-REGEX-OUTPUT-BEGIN]\n",
    rg_control.stdout,
    "[V10E-V3][CONTROL-REGEX-OUTPUT-END]\n",
    (
        "[V10E-V3][SELFTEST-SIMPLIFIED-PATTERN] "
        f"{SELFTEST_PATH.as_posix()}:{simple_line_no}\n"
    ),
    (
        "[V10E-V3][GAP] production assertion regex fails to compile; "
        "selftest exercises a different simplified regex\n"
    ),
]
(OUT / "assertion-regex-fixture.log").write_text(
    "".join(fixture_parts), encoding="utf-8"
)

contract_log = (OUT / "runner-contract.log").read_text(encoding="utf-8")
negative_markers = [
    line
    for line in contract_log.splitlines()
    if "[V10E-RUNNER-CONTRACT][NEGATIVE]" in line
]
dynamic_markers = [
    line
    for line in contract_log.splitlines()
    if "[V10E-RUNNER-CONTRACT][DYNAMIC]" in line
]
status_rc = read_rc(OUT / "task-run-status.rc")
syntax_rc = read_rc(OUT / "bash-syntax.rc")
contract_rc = read_rc(OUT / "runner-contract.rc")
configured_design = next(
    line.split("=", 1)[1].strip().strip('"')
    for line in runner_lines
    if line.startswith("expected_design_sha=")
)

summary = {
    "schema": "v10e-runner-prelaunch-review-v3-evidence-v1",
    "contract_json": (
        RUN_DIR
        / "subagent-contracts/v10e_runner_prelaunch_review_v3.json"
    ).as_posix(),
    "contract_sha256": (
        "0af8b5154790a3ecff4a879f9d8d4de0852d518ae65a42933a3fd965fae023dc"
    ),
    "syntax": {
        "rc": syntax_rc,
        "result": "PASS" if syntax_rc == 0 else "FAIL",
    },
    "status_helper_suite": {
        "rc": status_rc,
        "result": "PASS" if status_rc == 0 else "FAIL",
    },
    "runner_contract": {
        "rc": contract_rc,
        "static_negative_rejected": len(negative_markers),
        "static_negative_expected": 40,
        "dynamic_fixture_markers": len(dynamic_markers),
        "dynamic_fixture_expected": 7,
        "raw_negative_markers": negative_markers,
        "raw_dynamic_markers": dynamic_markers,
    },
    "assertion_regex_exact_fixture": {
        "runner_line": pattern_line_no,
        "argv": ["rg", pattern],
        "rc": rg_bad.returncode,
        "expected_clean_or_match_rc": [0, 1],
        "control_corrected_rc": rg_control.returncode,
        "result": "FAIL",
        "selftest_simplified_pattern_line": simple_line_no,
    },
    "design_id": {
        "configured_expected": configured_design,
        "contract_expected": EXPECTED_DESIGN,
        "configured_match": configured_design == EXPECTED_DESIGN,
        "rtl_binding_recomputed": False,
        "scope_gap": (
            "npc/rv64/vsrc/** is not an allowed input path in the V3 contract"
        ),
    },
    "prelaunch_result": "GAP",
    "long_simulation_authorized": False,
}
(OUT / "gate-summary.json").write_text(
    json.dumps(summary, indent=2, ensure_ascii=False) + "\n",
    encoding="utf-8",
)

commands = [
    (
        "sha256sum",
        "subagent-contracts/v10e_runner_prelaunch_review_v3.json",
        0,
    ),
    (
        "bash -n",
        "V10E runner + V10E launcher + V9S launcher + status helper",
        syntax_rc,
    ),
    ("bash", "scripts/tests/test-task-run-status.sh", status_rc),
    ("python3", SELFTEST_PATH.as_posix(), contract_rc),
    (
        "rg",
        f"exact production assertion regex from runner:{pattern_line_no}",
        rg_bad.returncode,
    ),
]
(OUT / "commands.tsv").write_text(
    "command\tpurpose\trc\n"
    + "".join(
        f"{command}\t{purpose}\t{return_code}\n"
        for command, purpose, return_code in commands
    ),
    encoding="utf-8",
)

hash_targets = [
    "bash-syntax.log",
    "bash-syntax.rc",
    "task-run-status.log",
    "task-run-status.rc",
    "runner-contract.log",
    "runner-contract.rc",
    "assertion-regex-fixture.log",
    "gate-summary.json",
    "commands.tsv",
]
hash_lines = []
for name in hash_targets:
    digest = hashlib.sha256((OUT / name).read_bytes()).hexdigest()
    hash_lines.append(f"{digest}  {name}")
(OUT / "sha256sums.txt").write_text(
    "\n".join(hash_lines) + "\n", encoding="utf-8"
)

report = f"""RV64 RTL 结论｜对象={RUNNER_PATH.as_posix()}::capture_terminal_evidence / review-v3｜周期/配置=pre-launch, max_cycles=6000000000, OOO_CSR_QUEUE_HEAD=1, OOO_ASSERT=1, OOO_TERMINAL_HOLDER_ASSERT=1｜TB/EDA 观测=bash syntax rc=0；status-helper rc=0；40/40 static + 7/7 dynamic selftest；exact assertion rg rc=2｜范围=GAP

# V10E runner pre-launch independent review V3

## 结论

禁止启动 6B-cycle systemd-strict 回放。生产 runner 在
`{RUNNER_PATH.as_posix()}:{pattern_line_no}` 把双反斜杠 assertion
pattern 作为 argv 传给 `rg`；V3 exact-argv fixture 返回
rc={rg_bad.returncode}，原始 marker 为
`[V10E-V3][ASSERTION-REGEX-RC] {rg_bad.returncode}`。
`record_optional_rg` 正确把 rc>1 视为错误，因此
`capture_terminal_evidence` 会返回非零；strict-marker-check 的显式调用或
EXIT cleanup 均不能得到 PASS。这是 fail-closed，但会让当前 runner 无法完成
pre-launch PASS。

现有 `test-runner-contract.py` 仍 rc={contract_rc}，并记录
{len(negative_markers)}/40 个 `[NEGATIVE]` 与
{len(dynamic_markers)}/7 个 `[DYNAMIC]` marker；假绿根因是其定向读错
fixture 在 `{SELFTEST_PATH.as_posix()}:{simple_line_no}` 运行简化的
`rg "RTL assertion" <missing-log>`，没有编译生产 pattern。静态检查仅要求
`record_optional_rg()` 与 `EVIDENCE-QUERY-FAIL` token 存在，也没有验证
exact regex argv。

## V2 六项反例裁决

1. PASS 写失败：既有 helper suite rc={status_rc}，`PASS-write fallback`
   marker PASS；在该定向注入模型内闭合。
2. cleanup signal：7 类动态 fixture 中 TERM rc=143 且状态 FAIL，闭合。
3. post-binding 输出失败：动态 rc=1 且状态 FAIL，闭合。
4. assertion 日志读取错误：未闭合。exact production regex 自身编译
   rc=2；selftest 的简化 missing-log probe 不能证明生产查询正确。
5. runtime control/post-hash：40 个静态负向变体中的声明项均被拒绝；
   本轮未启动长回放，不越级证明运行期无漂移。
6. 全工作区锁：动态 V9S contention rc=3，且两份 launcher 的背景
   rc=73/status publisher 静态 token 被接受；合同内 fixture 闭合，但未启动
   真实后台系统回放。

重复 terminal marker 的五个 `-eq 1` oracle 在生产 runner 中存在；40 个静态
负向 marker 包含 `allow-duplicate-strict-done` 与
`allow-duplicate-good-trap` 被拒绝。由于 assertion query blocker 已先失败，
本轮不授权任何 terminal PASS。

## design-id 与范围

runner 内配置的 `expected_design_sha={configured_design}` 与合同目标相同。
V3 合同未授权读取 `npc/rv64/vsrc/**`，因此未独立执行
`architecture_hard_gates.rtl_binding()`；实际当前 RTL design-id 只能记为
scope GAP，不能用配置常量替代 RTL 源集合哈希。

scope_extension_request：若后续需要独立关闭 design-id gate，新版本合同需增加
只读 `npc/rv64/vsrc/**`，再以已声明 `python3` 调用
`architecture_hard_gates.rtl_binding()`；本 V3 未扩权、未执行。

## unknowns / assumptions / alternatives

- unknowns：未运行 Verilator、testbench、综合或 STA；未观察 17/17 guest
  transaction、natural poweroff、reset-syscon 或 `GOOD TRAP`。
- assumption：`shlex` 对 runner 单引号参数的还原等价于 Bash；control pattern
  将双反斜杠方括号降为单反斜杠后，在同一输入上 rc={rg_control.returncode}，
  支持根因定位为 shell regex 过度转义。
- alternative：若期望匹配 literal `[`/`]`，生产 argv 应只携带单反斜杠转义；
  最终修复必须由生产 runner 的 exact-pattern fixture 验证，不能只复用简化
  `rg` probe。
- confidence_and_basis：高；语法/状态/selftest 原始日志、exact argv、rg parser
  原始 stderr 与 SHA-256 均保存在本目录。

## 实现者 / 审查者复核

- 实现者证据：未修改生产 RTL、TB、runner、launcher 或共享 helper；
  `bash-syntax.log`、`task-run-status.log`、`runner-contract.log` 记录 rc=0
  与原始 PASS marker。
- 审查者反例：`assertion-regex-fixture.log` 复现 production argv rc=2，
  否决 selftest overall PASS 对实际 `capture_terminal_evidence` 可执行性的
  越级结论。
- 分歧裁决：pre-launch 只能为 GAP；6B-cycle runner 不得启动。

本报告写入完成后本节点不再运行 WSL 工程命令；
single-flight ownership=RETURNED。
"""
(OUT / "review.md").write_text(report, encoding="utf-8")

print(
    f"[V10E-V3][STATIC] negative={len(negative_markers)}/40 "
    f"dynamic={len(dynamic_markers)}/7"
)
print(f"[V10E-V3][ASSERTION-REGEX-RC] {rg_bad.returncode}")
print(
    "[V10E-V3][GAP] exact production assertion regex is invalid; "
    "long run not authorized"
)
print("[V10E-V3][SINGLE-FLIGHT] RETURNED")
