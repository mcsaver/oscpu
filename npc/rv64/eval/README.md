# NPC RV64 评估系统（eval/）

本目录是 RV64 OoO 核的**统一评估入口**。每轮优化/重构迭代后，用它做"深度再评估"，
产出可对比、可追溯的报告，作为下一步决策依据。

## 设计原则
- **一条命令完成评估**：正确性 gate（模块 TB / riscv-tests）+ 性能画像（AM cpu-tests CPI）一次跑齐。
- **可对比**：每次结果带时间戳落盘，自动与上一次对比加权 CPI。
- **可追溯**：记录 git HEAD、工作树脏文件数、运行参数。
- **不污染仓库**：原始日志和大产物落在 `results/`（已 gitignore），结论写进 `summary.md` 并在文档/记忆中引用。

## 用法
```bash
cd npc/rv64
eval/npc-eval.sh --all            # 模块 TB + riscv-tests + AM cpu-tests(CPI)
eval/npc-eval.sh --build --all    # 先重建再全量评估
eval/npc-eval.sh --quick          # 仅 AM cpu-tests CPI（最快性能回归）
eval/npc-eval.sh --am --tag div-radix4   # 给结果打标签便于对比
eval/npc-eval.sh --bench          # CoreMark/Dhrystone（长）
```

## 产物布局
```
eval/results/<时间戳>[-tag]/
  summary.md      # 人读汇总：gate 状态 + 加权 CPI + 三类样本 + top cycles 贡献 + 与上次对比
  am-cpi.tsv      # AM 每测试 result/cycles/commits/cpi（机器可读，用于对比/绘图）
  riscv.log       # riscv-tests 原始日志
  module.log      # 模块 TB 原始日志
  meta.txt        # 时间/tag/git HEAD/脏文件数/max-cycles
```

## 评估自校验(两层)
1. **dummy smoke**:跑前确认已知必过的 dummy GOOD TRAP,否则判环境异常中止(不输出误导结果)。
2. **逐测试 CPI 回归检测**:每个 PASS 测试 CPI 与上次对比,|Δ|>20% 标红——同时抓性能回归与评估漂移(评估的评估)。

## 三大正确性 gate（任何 RTL 改动后必须全绿）
| gate | 内容 | 当前基准 |
| --- | --- | --- |
| 模块 testbench | `testbench/` 下 112 个 tb（iverilog） | 112/112 |
| 官方 riscv-tests | rv64ui/um/uc/uzb* + 特权 mi/si（tohost 协议） | 271/0 |
| AM cpu-tests | 56 项功能 + 性能（ebreak GOOD TRAP） | 56/56 |

## 性能方法学（对齐 `.github/instructions/npc-optimization-workflow`）
- 加权 CPI = Σcycles / Σcommits（仅 PASS 子集）。所有 AM 测试经 `trm.c` 配 PMP（真实场景）。
- 每轮分析三类代表样本（highest/lowest CPI）+ top cycles 贡献，定位下一瓶颈；不只看 `add`。
- 负优化（无改善或微升）必须撤回，原因写入 task-run/记忆。

## 可选观测：分支预测率 / cache 命中率
默认(perf)配置不挂这些观测钩子，故 eval 输出里 `branch accuracy 0/0`、`dcache access=0`
属**预期**(非 bug)，不影响 cycles/CPI 这一核心指标。需要深入分支/cache 分析时，用带
`CONFIG_NPC_BRANCH_STATS` 的分析版构建后再跑 eval；RTL cache 事件统计需在 NpcSimTop.sv
用层次化引用采样(已知 TODO)。日常优化以 cycles/CPI 为准即可。

## 关于 difftest
当前环境 NEMU 因 `vga.o` 警告当错误无法构建，difftest 暂不可用。涉及访存顺序 / response
ownership 等高风险改动前，应先恢复 difftest 作参考模型（见 `design/arch/ROADMAP.md`）。
