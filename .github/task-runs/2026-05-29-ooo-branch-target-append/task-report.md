# OoO Branch Target Append 任务报告

## 目标

- 在 CPU-test 全量正确性优先的前提下继续降低 OoO/superscalar 实验核 CPI。
- 不局限于 `add`，用全量 CPI 分布选择代表样本和高权重瓶颈。
- 继续保持一个 module 一个源文件；本轮未新增 module，只修改既有 `OooAluFetchCore.v`。

## RTL 推导摘要

- 需求要点：lane0 branch 已经在 dispatch-stage 得到真实方向和 next PC 时，减少前端 redirect 后重新取真实下一条指令带来的空泡。
- 协议规则：只有 lane0 branch 确认 fire、解析结果 PC 匹配且 target 未 misalign 时才能尝试 append；taken 只能使用由真实 taken target fetch 捕获且 full-PC tag 命中的 target cache；not-taken 只能使用同 packet 中已通过 safe filter 的 head1；lane1 后端资源不足时退化为旧 redirect。
- 状态机与不变量：append 不改变后端 ROB/IQ/commit/memory/checkpoint 协议；target cache 仅保存真实 taken target 首指令，store request fire 或 `MISC_MEM`/fence 类提交时全表失效；cache tag 为完整 PC，index 冲突只能损失命中，不能错误派发。
- 数据通路约束：`dispatch1_optional_w` 使用不依赖 ready/fire 回边的 candidate；真正的 lane1 valid/fire 再由 resolved attempt 控制，避免 `dispatch0_ready` 与 `dispatch1_optional` 形成组合环。target cache index 从 1 bit 扩到 4 bit，数组增至 16 项。

## 实现记录

- `OooAluFetchCore.v` 增加 resolved branch target append 与 fallthrough append。
- branch target cache 从 2 项扩为 16 项，仍使用 full-PC tag。
- 增加 store/MISC_MEM 边界失效，覆盖自修改代码和 fence/fence.i 类场景。
- 修复一次中途实验：直接把 append attempt 接入 `dispatch1_optional_w` 会在 `matrix-mul` 下触发 Verilator active region did not converge，已拆分 candidate/attempt 后保留。

## 验证证据

- `make -C npc/single NPC_OOO_ALU_EXPERIMENT=1 -B -j4`：PASS。
- `make -C npc/single/testbench run TESTS=tb_ooo_alu_fetch_core RESULT_DIR=/tmp/npc-ooo-btc16-tb`：`1/1 PASS`。
- CPU-test 全量：`/tmp/ysyx-ooo-full-cputests-btc16.tsv`，`40/40 GOOD`，`cycles=64609/commits=78679/weighted CPI=0.821172104`。

## 全量代表样本

| 类别 | 测试 | cycles | commits | CPI | 主要等待 |
| --- | --- | ---: | ---: | ---: | --- |
| highest_cpi | dummy | 46 | 12 | 3.833333 | 短程序固定开销 |
| lowest_cpi | crc32 | 8676 | 16305 | 0.532107 | 已接近双发吞吐 |
| near_average_cpi | leap-year | 1377 | 1692 | 0.813830 | branch wait 192 |

## A/B 对比

- lane1-ret 基线 `/tmp/ysyx-ooo-full-cputests-lane1-ret.tsv`：`cycles=66269/commits=78682/weighted CPI=0.842238377`。
- 2-entry branch append `/tmp/ysyx-ooo-full-cputests-branch-append.tsv`：`cycles=64821/commits=78679/weighted CPI=0.823866597`。
- 16-entry target cache 最终版 `/tmp/ysyx-ooo-full-cputests-btc16.tsv`：`cycles=64609/commits=78679/weighted CPI=0.821172104`。
- 相对 lane1-ret 总 cycles 减少 1660；16-entry 相对 2-entry 再减少 212。

主要收益：`crc32 -751`、`quick-sort -188`、`string -169`、`select-sort -108`、`to-lower-case -87`。小退化：`recursion +38`、`fact +23`、`matrix-mul +14`、`shuixianhua +5`。

## 结论与下一步

本轮优化保留，正确性闭合且全量加权 CPI 改善到 `0.821172`，但目标 `CPI=0.5` 未完成。下一轮不能只继续压 `add` 或 OoO 后端局部，应从全局 excess 看 `recursion` 的 indirect JALR jump wait=2631，以及 `bubble-sort/matrix-mul/quick-sort/hello-str/leap-year` 等 branch wait 面；若做 JALR/branch 预测，必须先补源值 ready/forwarding 或 checkpoint/rollback 协议，不能直接用 arch GPR 或 BTB 预测提交语义。
