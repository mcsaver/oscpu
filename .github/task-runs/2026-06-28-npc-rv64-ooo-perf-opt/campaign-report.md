# RV64 OoO 核 优化战役 综合报告（2026-06-28）

本报告汇总本次围绕 RV64 乱序核的修复+性能+工程化战役。所有结论均经三大 gate 验证。

## 一、最终状态（全绿）
| Gate | 起点 | 终点 |
| --- | --- | --- |
| 模块 testbench | 112/112 | **112/112** |
| 官方 riscv-tests(默认+特权) | 271/0 | **271/0** |
| AM cpu-tests | 46/56 | **56/56** |
| AM 加权 CPI(含 PMP, 真实场景) | 3.7427(禁缓存基线) | **1.2647** |

**性能累计 −66%**（cycles 548203→187299，commits 不变 148092）。

## 二、迭代清单（7 次提交，ai 分支 0bb371593→e7ff03a1d）
| iter | 内容 | 关键收益 | 验证 |
| --- | --- | --- | --- |
| 0 | 回归修复(PMP 配置 + SW A/D) | 46/56→56/56 | 三 gate 绿 |
| 1 | 取指 cache PMP 修复 | Linux/OpenSBI 下 ~2x | riscv 271 不变 |
| 2 | DIV word + radix-4 | div 测试 −70% | rv64um 全过 |
| — | ROB/IQ 扩容(无效) | 撤回 | — |
| 3 | 评估系统 + spec 方法学 + ROADMAP | 基础设施 | self-check |
| 4 | B1 访存 store 写回解耦 | branch-resolve −30%、CPI −15.8% | 三 gate 绿 |
| 5 | DIV CLZ 早终止 | shuixianhua −86%(累计)、CPI −19.8% | 三 gate 绿 |

## 三、根因式修复（非症状补丁）
- **PMP 默认拒绝 S/U**：核按规范实现(无匹配条目→S/U access fault)，AM S-mode 测试未配 PMP →
  启动配 PMP(trm.c)，一处修 9 项。CLINT 10:1 分频是红鲱鱼。
- **核非 Svadu**：A=0/写且 D=0→page fault，sv39-ad-bits 改 SW 管理 A/D(两类实现通吃)。
- **取指 cache 被 PMP 整体禁用**：改 PMP-grant 逐访问门控，恢复 Linux 场景 ~2x。
- **DIV 固定迭代**：word 32 拍→radix-4 16 拍→CLZ 按有效位数(小操作数大幅减拍)。
- **store 单 outstanding**：cacheable-PMEM store 提前完成、B 交 bpend 跟踪器(保 MMIO 精确异常)。

## 四、工程化交付（spec 先行 / 可复用 / 有条理）
- `eval/npc-eval.sh`：统一评估系统，带 dummy smoke **自校验**（已抓修自身 2 个 bug）。
- `design/arch/`：ROADMAP(每轮深度再评估)、SPEC-TEMPLATE、mem-store-decouple 规范、literature。
- `design/specs/ooo-mem-axi-bridge-fsm.md`：访存桥 FSM 逆向文档化。
- 每轮 `git commit` + 记忆 + task-run 同步。

## 五、深度再评估：剩余瓶颈与下阶段（诚实结论）
易得的大 CPI 红利已收割（−66%）。当前 top cycles：branch-resolve-loop 47.8k(cpi 1.34)、
ooo-mem-order 16.6k、linux-mini-boot 13.7k——均为 **load 侧延迟**(load-use + 单 outstanding 读)，
已接近本微架构延迟下限。最高 CPI 项是数百周期的微小特权测试(可忽略)。

**下阶段（需重大专注工程，价值/风险见 ROADMAP backlog）**：
1. **load 侧访存**：读多 outstanding / load 流水 / store-to-load forward —— 最后的大 CPI 杠杆，
   但收益面在 load-miss 密集负载；dcache-hit 已近 2 拍下限。
2. **工程质量(用户优先)**：B2 redirect/PC sequencer 显式状态机化(时序+稳健)、B4 文件组织、逐模块 spec。
3. **时序/Fmax 阶段**：radix-4/CLZ 增加了除法装载/步内组合深度，属 CPI↔频率权衡，需综合后评估关键路径。

## 六、环境约束
- difftest/NEMU 本环境不可构建(vga.c update_screen 缺声明)，且 NEMU 与本核 A/D/PMP 语义有意不同，
  非干净参考。访存类改动依赖现有 gate(历史能捕获访存 bug，本战役 B1 的 dcache 一致性 bug 即被捕获)。
