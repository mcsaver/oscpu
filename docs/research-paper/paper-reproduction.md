# 论文证据与构建复现

## 1. 范围

本文只读取现有工程记录，并新增：

- `docs/research-paper/` 下的研究台账、实验计划和只读脚本；
- `docs/research-paper/ubuntu-19h-milestone-evidence.md`；
- `docs/research-paper/case-selection-protocol.md` 与 `independent-claim-review.tsv`；
- `docs/thinking/verifiable-ai-hardware-engineering.tex`；
- 同名 PDF；
- 原 TeX 的备份 `verifiable-ai-hardware-engineering.before-evidence-integration.tex`。

不会修改生产 RTL、testbench、EDA 脚本、历史 task-run 或数据库记录。文档构建不依赖 LibreOffice。

公开仓库：

<https://github.com/mcsaver/oscpu>

## 2. 环境

本文在 Windows 上通过 WSL Ubuntu 工作区构建：

```text
/home/lyg/PA/ysyx-workbench
```

所需工具：

- Python 3.10 或更新版本；
- XeLaTeX；
- Poppler 的 `pdfinfo`、`pdftoppm`（视觉复核时使用）；
- 仓库自带的 `scripts/github_index_db.py`。

LaTeX 使用 `ctexart`、`fontspec`、`booktabs`、`tabularx`、`longtable`、`listings` 和 `tikz`。当前版本优先使用 Windows 常见的宋体、黑体和 Times New Roman；若在纯 Linux 环境复现，可在导言区替换为可用的 CJK 字体，不改变正文内容。

## 3. 只读证据盘点

```bash
python3 docs/research-paper/scripts/paper_evidence_extract.py
```

脚本对 `.github/task-runs/` 顶层目录做只读盘点。它不会把目录数解释为独立实验数。

在 2026-08-04 的工作区快照中，脚本得到：

| 月份 | workflow-event directory |
|---|---:|
| 2026-04 | 8 |
| 2026-05 | 137 |
| 2026-06 | 1246 |
| 2026-07 | 756 |

这些数字只描述记录目录密度。仓库继续演进后，脚本输出会自然变化。

## 4. 主张—证据映射检查

```bash
python3 docs/research-paper/scripts/paper_evidence_extract.py \
  --verify-claims docs/research-paper/claim-evidence-map.tsv
```

预期：

```text
claim_map_check.ok = true
claim_map_check.errors = []
claim_map_check.path_warnings = []
rows = 30
status_counts = SUPPORTED 18, PARTIALLY_SUPPORTED 4,
                OBSERVATIONAL_ONLY 1, CONTRADICTED 6, MISSING 1
claim-map SHA-256 = f20a63ce701d31703f9fe3615d9bb7ae45c134b8b681293c1d98515facf7ab7a
```

路径存在只说明材料可回查，不自动把某条主张升级为 `SUPPORTED`。状态仍需根据设计身份、配置、负向证据和结论边界审计。固定的 12/30 第二 Agent 抽样、初次分歧和修订结论见 `independent-claim-review.tsv`；它不是人类双编码一致性实验。

## 5. DB-first 回查示例

先生成有界上下文：

```bash
python3 scripts/github_index_db.py brief design-id \
  --profile agent-system \
  --focus-scope non-history
```

查询已发布运行：

```bash
python3 scripts/github_index_db.py runs rv64 \
  --profile agent-system \
  --limit 20 \
  --json
```

查询指定 run 的证据摘要：

```bash
python3 scripts/github_index_db.py evidence \
  --run-id 2026-07-23-control-event-rtl-evidence \
  --json
```

读取已索引报告：

```bash
python3 scripts/github_index_db.py load \
  --source auto \
  --path .github/task-runs/2026-05-29-ooo-cpi-645-iq-fix/task-report.md \
  --max-tokens 6500
```

如果历史材料没有进入 DB，先保留这一召回缺口，再对台账已列出的精确路径做只读检查；不要用全仓库无界日志搜索替代 DB-first。

## 6. 关键证据路径

| 论证 | 路径 |
|---|---|
| 4 月 lint-only 边界 | `.github/task-runs/2026-04-13-rv32i-nonpipe-core/task-report.md` |
| RV32 single 动态闭环 | `.github/task-runs/2026-04-13-npc-dpic-bringup/task-report.md` |
| RV32 SoC 的 AM/NEMU 39/39 对拍 | `.github/task-runs/2026-05-23-am-ysyxsoc-platform/task-report.md` |
| ysyxSoCFull 镜像、UART、cache/PSRAM | `.github/task-runs/2026-05-24-b2-ysyxsocfull-cache/task-report.md` |
| NPC RV64 首个 38/38 冻结点 | `.github/task-runs/2026-05-29-npc-rv64-backend/task-report.md` |
| NEMU RV64 reference 与 40/40 DiffTest | `.github/task-runs/2026-05-30-rv64-nemu-difftest/task-report.md` |
| 真实 OpenSBI mini handoff | `.github/task-runs/2026-05-30-rv64-opensbi-mini-boot/task-report.md` |
| 5 月 IQ、CPI 与回滚 | `.github/task-runs/2026-05-29-ooo-cpi-645-iq-fix/task-report.md` |
| 6 月分支推测失败与回退 | `.github/task-runs/2026-06-29-rv64-ooo-core-architecture-constitution/report.md` |
| NEMU Ubuntu `/bin/sh` | `Linux/env/logs/linux-front/riscv64-nemu-ubuntu-rootfs-virtio-8b/console.log` |
| NPC systemd/banner | `.github/task-runs/2026-06-15-npc-ubuntu-current-direct/evidence/npc-rv64-linux-rootfs-mount-smoke-script/console.log` |
| NPC 十九小时 A3 原始 console | `.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/rootfs-c1b531-systemd-strict-6b-a3/guest/console.log` |
| A3 结构化 systemd transaction | `.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/rootfs-c1b531-systemd-strict-6b-a3/systemd-transaction-evidence.json` |
| A3 冻结 oracle 重放 | `.github/task-runs/2026-07-28-rv64-v10f-a3-checker-replay-v2/evidence/replay-verdict.log` |
| 十九小时里程碑复核表 | `docs/research-paper/ubuntu-19h-milestone-evidence.md` |
| Yosys 结构统计 | `.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/ppa-r3p4-alu-terminal/light-yosys/yosys.log` |
| IFU 19 个变体 | `.github/task-runs/2026-07-22-rv64-v9i-ifu-access-current-design/task-report.md` |
| V9L 功能聚合 | `.github/task-runs/2026-07-22-rv64-v9l-functional-aggregate-current-design/task-report.md` |
| FENCE V9M | `.github/task-runs/2026-07-23-rv64-v9m-fence-ordering-current-design/task-report.md` |
| STORE/AMO V9N | `.github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/task-report.md` |
| CONTROL-EVENT V9O 身份快照冲突 | `.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/task-report.md` 与同目录 `evidence-index.md` |
| 5 ns proxy setup 边界 | `.github/task-runs/2026-07-14-rv64-t4i-standard-axi-lanes/evidence/opensta-fresh-t4i-final/opensta-current-check-setup.txt` |
| drain gate 三快照演化 | `docs/research-paper/module-evolution-evidence.md` |
| 当前 ARCH_STABLE | `npc/rv64/eval/ppa/evidence/arch-stable-current.json` |
| endpoint-corrected PERF_BASELINE | `npc/rv64/eval/ppa/evidence/performance-baseline-current.json` |
| 性能基线原始 FAIL 与 checker replay | `.github/task-runs/2026-08-04-rv64-v14n-performance-baseline-current-v2/` |
| CPI bottleneck census | `.github/task-runs/2026-08-04-rv64-v14o-cpi-bottleneck-census-v2/evidence/cpi-bottleneck-census/census.json` |
| owner-timing 诊断 link | `.github/task-runs/2026-08-04-rv64-v14p-cpi-owner-timing-diagnostics-v1/evidence/owner-timing-diagnostics/command-status.txt` |
| owner-timing workload A/B 失败关闭 | `.github/task-runs/2026-08-04-rv64-v14q-owner-timing-workload-ab-v1/owner-timing-workload-ab.status` |
| invalid owner 负向重放 | `.github/task-runs/2026-08-04-rv64-v14q-owner-timing-invalid-probe-replay-v3/evidence/owner-timing-invalid-probe-replay/result.json` |

逐条字段见 `claim-evidence-map.tsv`。

### 6.1 单模块三快照源码身份

以下命令只读取不可变 Git 对象：

```bash
git show 0bb371593315afe507752dc134cabf122ed9751c:npc/rv64/vsrc/control/OooPendingDrainResolveGate.v \
  | sha256sum

git show 8532bad0794cb34199c8adf49b080e1773b1f16f:npc/rv64/vsrc/control/OooPendingDrainResolveGate.v \
  | sha256sum

git show c29532ead32bf2a268b821cef9665a44aec58f9f:npc/rv64/vsrc/control/OooPendingDrainResolveGate.v \
  | sha256sum
```

预期依次为：

```text
e0ac0be2253d84ffd41bb83314f1d24f65a861a0d8b45cd6555a2b222a6a38c7
574fc78abebb587937e828ba961d1a6405cb20463d8f0ff0b7a9251d84e5628f
6be380f766d03dfffbbe970b696226c14fd6eea4c6d741b491108c760be108b6
```

比较变化：

```bash
git diff 0bb371593315afe507752dc134cabf122ed9751c \
  8532bad0794cb34199c8adf49b080e1773b1f16f -- \
  npc/rv64/vsrc/control/OooPendingDrainResolveGate.v

git diff 8532bad0794cb34199c8adf49b080e1773b1f16f \
  c29532ead32bf2a268b821cef9665a44aec58f9f -- \
  npc/rv64/vsrc/control/OooPendingDrainResolveGate.v
```

源码 diff 证明合同发生变化，但不能单独承担性能或正确性的因果归因。逐阶段的正向、负向证据和非蕴含边界见 `module-evolution-evidence.md`。

## 7. LaTeX 构建

在 `docs/thinking` 中运行两遍 XeLaTeX：

```bash
xelatex -interaction=nonstopmode -halt-on-error \
  -file-line-error verifiable-ai-hardware-engineering.tex

xelatex -interaction=nonstopmode -halt-on-error \
  -file-line-error verifiable-ai-hardware-engineering.tex
```

两遍用于稳定交叉引用、图表编号和页码。输出：

```text
docs/thinking/verifiable-ai-hardware-engineering.pdf
```

检查 PDF：

```bash
pdfinfo docs/thinking/verifiable-ai-hardware-engineering.pdf
```

视觉抽样：

```bash
mkdir -p /tmp/ysyx-paper-render
pdftoppm -png -r 120 \
  docs/thinking/verifiable-ai-hardware-engineering.pdf \
  /tmp/ysyx-paper-render/page
```

重点查看：

- 摘要和关键词是否单页溢出；
- 长表是否越过版心；
- 代码和路径是否截断；
- TikZ 流程图是否有文字重叠；
- NEMU/NPC、Yosys 日志块是否保持等宽且可读；
- drain gate 三快照表、三段代码和负向证据摘要是否连续、无浮动错位；
- `agent-flow.c` 状态机表、当前性能基线/CPI census 表与 owner-timing 代码是否越界；
- 首次 owner-timing workload A/B 的 FAIL 日志是否保持可读，且没有被图表浮动拆散；
- “自建术语的操作性定义”长表是否跨页正确、表头重复且没有文字越界；
- 参考证据附录是否出现空白页。

## 8. 可复现性边界

1. 当前材料是单仓库的纵向案例，不是随机对照实验。
2. 早期 task-run 没有与七月相同的 publication 和 design-id 字段，不能事后补造。
3. task-run 目录数不是独立样本数。
4. 论文不复跑生产 RTL、Linux、综合或 STA；它复核已有证据。
5. 代理 PPA 没有完整物理约束，统一保持 `PPA UNQUALIFIED`。
6. mutation 只支持指定且非等价的 fault set。
7. “Loop 是否优于 Prompt”须按 `experiment-plan.md` 的 B0—B3 方案重新采集受控数据。
