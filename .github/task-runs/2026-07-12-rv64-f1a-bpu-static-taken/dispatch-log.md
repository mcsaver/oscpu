# 派发日志

## 基本信息

- `task_id`: 2026-07-12-rv64-f1a-bpu-static-taken
- `graph_template`: architecture-refactor + timing-ab
- `log_policy`: append-only

---

### [2026-07-12 13:45 +0800] `recall-map` - PASS

- `owner_agent`: root + bpu_lookup_iface + bpu_macro_timing + frontend_dirty_safe。
- `action`: 对齐 PacketDecode B-imm→Frontend→BPU→checker/TB→macro generator/Liberty 全链，
  并冻结用户 `OooFrontend.v` 注释 hunk 的 SHA256。
- `outputs`: 真实行为只消费 sign；placeholder 每 lane 多挂 51 个同网 pin；用户 hunk不重叠。
- `handoff_to`: freeze-contract, structural-red。

### [2026-07-12 13:46 +0800] `freeze-contract` - PASS

- `owner_agent`: root。
- `action`: 在 dedicated/macro specs 冻结 scalar ABI、六类无变化合同、功能与 timing A/B 门禁。
- `outputs`: `BPU-ST1`、1-bit×2 macro ABI、当前 17674-bit state lower bound。
- `handoff_to`: structural-red, implement-scalar。

### [2026-07-12 13:46 +0800] `structural-red` - PASS

- `owner_agent`: root。
- `action`: 要求 predictor 已暴露两路 scalar static-taken 且无旧 imm port。
- `outputs`: rc=1，仅因 current RTL 仍有 6 处 `lookup*_imm_i` 声明/消费；RED 非环境失败。
- `handoff_to`: implement-scalar。

### [2026-07-12 13:49 +0800] `contract-checker-red` - PASS

- `owner_agent`: root + bpu_lookup_iface。
- `action`: 先增强 `check_bpu_macro_contract.py`，让它同时检查 current spec row、RTL、
  Frontend owner、generator 与 Liberty 的 scalar ABI，并校正 1024/GHR10/17674/two-cycle 事实。
- `outputs`: checker rc=1，spec/macro facts PASS 后精确停在 RTL 缺少两路 scalar port；证明旧
  “两份陈旧文档互相命中历史文本”的假绿已被打破。
- `handoff_to`: implement-scalar。

### [2026-07-12 13:55 +0800] `implement-scalar` - PASS

- `owner_agent`: root。
- `action`: predictor/checker/TB/Frontend owner/generator/Liberty 全链收窄为 1-bit×2；保留
  完整 B-imm target path，focused TB 增加 valid counter 覆盖翻转 static bit 反例。
- `outputs`: active source 旧 ABI 引用为 0；合同 checker PASS；错误接 `bimm[62]` 负探针
  rc=1；focused 2/2、module 87/87、lint/style、contract 38/38、Python/macro checks 全绿。
- `handoff_to`: timing-ab, record-review。

### [2026-07-12 13:56 +0800] `timing-ab` - RUNNING

- `owner_agent`: root + bpu_macro_timing。
- `action`: 启动 NpcTop/200MHz/DELAY-4 full remap，blackbox/keep/config 与 fresh A 基线一致；
  B 使用 scalar-port BPU placeholder。
- `outputs`: pending fresh netlist/OpenSTA 5ns report。
- `handoff_to`: timing analysis。

### [2026-07-12 14:12 +0800] `checker-selector-red-green` - PASS

- `owner_agent`: f1a_functional_review + root。
- `action`: 独立审查发现 debug checker 的 hybrid selector 第二条件误用
  `gshare_strong`；新增“gshare strong valid + local invalid”可达反例。首次仅组合 settle
  未跨 posedge 而假绿，补 tick 后精确 RED：`BPU-L0-PRED got=1 exp=0`，随后两 lane
  条件改为 `local_strong`。
- `outputs`: ticked RED runner rc=1 且仅命中目标 mismatch；修复后 focused PASS。
- `handoff_to`: final module regression, record-review。

### [2026-07-12 20:20 +0800] `timing-invalid-pair-reject` - PASS

- `owner_agent`: root。
- `action`: 首份 B full remap 完成后，发现复用 A 在 c6b、B 在 5bd+F1a，后端映射与路径归属
  已变化；按 fail-closed 门禁拒绝该比较。
- `outputs`: c6b/B 数字仅保留为审计历史，不进入 KEEP/REJECT；建立 detached clean
  `5bd7a1546` worktree，复制同 SHA256 `.config` 并绑定同一 Yosys/TCL/PDK 重跑 A。
- `handoff_to`: fresh-A5bd, timing-review。

### [2026-07-12 20:52 +0800] `timing-ab` - PASS

- `owner_agent`: root + f1a_timing_review。
- `action`: 对 clean A5bd 与 F1a B 运行同参数 DELAY-4 full synth、OpenSTA 5ns top40、sign-net
  report、worst-through report、power 与 check_setup；审计所有输入 hash。
- `outputs`: 两侧 post-map 0 problems；exact WNS 均 -12.895095ns；TNS
  `-198649.61→-197335.64ns`；top40 除 TNS 行逐字相同、40/40 D-cache→int IQ。lane0/1
  output-net total cap 各降 0.514448/0.492580pF，respective worst-through slack 各改善
  6.567661/6.021283ns。wide→scalar 少 126 个 setup endpoint，故 TNS 只作辅助证据。
- `decision`: `KEEP`（ABI 真实性 + 目标 cone 减载）；不是 WNS/200MHz win。reviewer `NO BLOCKER`。
- `handoff_to`: final-validation, record-review。

### [2026-07-12 20:53 +0800] `final-validation` - PASS

- `owner_agent`: f1a_final_validation。
- `action`: selector 修复后新鲜重跑 focused/module/lint/style/contract/macro/Python gates，核对
  source mtime/hash 与 mixed-selector 反例仍存在。
- `outputs`: focused 2/2、module 87/87、Verilator 5.051 lint、style、contract38/38、BPU checker、
  four-macro checker 与 py_compile 全部 rc=0。
- `handoff_to`: core-regress, record-review。

### [2026-07-12 21:04 +0800] `core-regress` - PASS

- `owner_agent`: f1a_core_regress。
- `action`: 当前 Difftest-OFF 配置下运行 clean build、AM 与 official p-mode riscv-tests；module/lint
  由上一节点覆盖。
- `outputs`: npc-build PASS，AM 59/59，official build 153/153 + run 153/153，failure marker=0；
  本轮未覆盖 Difftest 或 privileged rv64mi/rv64si。runner 更新了用户原已 dirty 的
  `build/linux-logs/npc-linux.log`，该文件继续排除 staging。
- `handoff_to`: memory/profile/strict-guard。

### [2026-07-12 21:14 +0800] `record-review` - PASS

- `owner_agent`: root + f1a_functional_review + f1a_timing_review。
- `action`: 实现者列交付证据；审查者寻找 checker 假绿、版本混杂、endpoint-count 混杂、
  placeholder 越级与用户 dirty file 污染。
- `outputs`: 功能与 KEEP 决策均 NO BLOCKER；已修 selector typo、重跑 A5bd、把 TNS 降为辅助
  证据并声明约束/宏限制。DB project/NPC/known-issues 已更新；fresh `npc-dev`、`yosys-sta`
  profiles completed/PASS。
- `handoff_to`: strict guard + commit。

### [2026-07-12 21:15 +0800] `strict-guard` - PASS

- `owner_agent`: root。
- `action`: 首轮 strict guard 要求 `.github/e2e/modules/yosys-sta.md` 的 `agent-system` 新鲜证据；
  补跑 profile 后重新归档/快照，再执行严格守门。
- `outputs`: `agent-system`、`npc-dev`、`yosys-sta` 三个 required profile 均命中新鲜
  completed/PASS evidence；guard rc=0。
- `handoff_to`: DB audit + partial stage + commit。
