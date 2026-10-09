# R3 Backend 与 native 模块验证

日期：2026-10-08。范围：Backend CQ early wake/value bypass 定向验证、完整 native 默认模块回归与既有参数/行为矩阵。LSU/Commit 开启模式、整核 DiffTest/软件、CPI 与 STA 由本轮最终 `RESULT` 汇总；这里不代替这些证据。

## 结论与候选身份

完整 native 兼容性回归已完成：**135/135 默认模块 target、1/1 额外 prepared-store target、34/34 矩阵场景、12/12 预期负测试**。冻结候选上另行重跑 **2/2 CQ 开启定向正测试**，以及 **1/1 CQ forwarding 同值负测试**，全部满足原检查条件。

候选为 `build/ai-r3-20261008/candidate-vsrc`。运行开始时当前 RTL 与冻结候选逐文件 SHA-256 一致；结束时记录的 225 个 RTL/测试 fixture/Makefile 文件无变化。该验证任务没有修改 RTL、冻结树、测试向量、DUT 时钟、oracle 或断言，也没有修改 Makefile 全局规则。

首轮整套命令真实返回 `2`，唯一中断是未改动的 `tb_r64_mul_booth` 达到宿主机 60 秒超时。它在相同 vvp、相同 20,000 向量下独立通过，随后完整续跑返回 `0`。这一失败及诊断单独保留，不能将首轮写成全部通过。

完整清单和逐项证据：

- [完整计数与逐项日志索引](../../../results/ai-r3-20261008/full-modules/SUMMARY.json)
- [可读汇总](../../../results/ai-r3-20261008/full-modules/SUMMARY.md)
- [源码 SHA-256 清单](../../../results/ai-r3-20261008/full-modules/source-manifest.json)
- [归档的逐用例日志目录](../../../results/ai-r3-20261008/full-modules/logs/)

## Backend 定向验证

开发阶段在独立 `backend-modules` 构建目录完成以下 7 个 target，全部 PASS：

|Target|主要覆盖|
|---|---|
|`tb_r64_regread_pipeline`|既有 RR 寄存边界和读数行为兼容性|
|`tb_r64_issue_regread`|既有 Issue/RR 连接和发射行为兼容性|
|`tb_r64_rob_rename`|既有 ROB/Rename 所有权行为兼容性|
|`tb_r64_early_wakeup`|既有 early wake 与真实执行/写回 owner 行为|
|`tb_r64_backend`|Backend 默认参数兼容性|
|`tb_r64_regread_cq`|CQ 开启后的实际值快照、数据连续性和阻塞保持|
|`tb_r64_cq_owner_wake`|6 路 short-owner 下 CQ 资格和 IQ 唤醒边沿|

开发阶段 [RESULT.json](../../../results/ai-r3-20261008/backend-modules/RESULT.json) 同时记录 CQ 不同值负测试真实 `rc=1`、同值断言匹配、修正组合向量自回读后的 RR 重测 `rc=0` 及当时的定向 diff-check `rc=0`。这里的 7 个 target 与完整 native 清单存在重叠，不相加成独立用例数。

冻结候选后，两个新增 CQ target 再次在独立 `full-modules/cq-enabled` 子目录编译和执行。明确使用 `TESTS=tb_r64_regread_cq tb_r64_cq_owner_wake`，未把它们暗中加入默认清单；make 真实 `rc=0`，耗时 `5.714 s`。具体覆盖为：

- `tb_r64_regread_cq`：两个 CQ 源和两个 RR lane；原读边沿捕获实际 forwarding 值；CQ 变化或撤销后的值保持；CQ 与 WB 同 preg 同值时保留旧源优先级；WB forwarding 与 PRF 写入同拍、后继消费者经 PRF 读数；terminal 满时 ingress 保存原值并在随后正确转移；forwarded B 生成正确 shift amount；部分 kill 清理 consumer。
- `tb_r64_cq_owner_wake`：真实 ROB 分配的双 owner；CQ 对应 short port 4/5 无需 WB grant 即可查询；错误 generation、错误 pdst、零寄存器拒绝；普通 WB/ALU 不唤醒的前提下，只由 CQ 唤醒驻留 entry；`DEFER_READY` 初始化边沿只有 CQ 命中的情形；不出现组合直通到同拍 issue；完成后的 ROB owner 和 full flush 撤销资格。
- `tb_r64_regread_cq +bad-value`：故意使同 preg 的 WB/CQ 值不一致，真实 `rc=1`，匹配 `R64 two forwarding stages disagree on a live physical value`。没有通过关闭断言或改变数据匹配判据来放行。

证据：[CQ 命令](../../../results/ai-r3-20261008/full-modules/cq-enabled-command.json)、[返回码与负测结果](../../../results/ai-r3-20261008/full-modules/cq-enabled-result.json)、[RR 日志](../../../results/ai-r3-20261008/full-modules/logs/cq-enabled/tb_r64_regread_cq.log)、[owner/wake 日志](../../../results/ai-r3-20261008/full-modules/logs/cq-enabled/tb_r64_cq_owner_wake.log)、[预期负测日志](../../../results/ai-r3-20261008/full-modules/cq-enabled-negative.log)。

## 完整默认模块与参数矩阵

工作目录 `/home/lyg/PA/ysyx-workbench`，独立构建目录 `npc/rv64/build/ai-r3-20261008/full-modules`。原始命令：

```text
make -C npc/rv64/testbench/chengyue64 -j3   run negative pipeline-matrix admission-matrix store-matrix trigger-matrix rr-qcredit-matrix   BUILD_DIR=/home/lyg/PA/ysyx-workbench/npc/rv64/build/ai-r3-20261008/full-modules
```

最终按 Makefile target 和明确场景计数，不用嵌套参考模块或重复日志中的 PASS 行增加通过数：

|范围|通过数|说明|
|---|---:|---|
|默认 `TESTS` 清单|135/135|全部对应 `.pass` 标记；默认参数兼容性|
|额外 prepared store target|1/1|`tb_r64_lsu_prepared`，来自 `store-matrix`|
|Pipeline 矩阵|7/7|4 个 plain workload + 3 个 stalls workload|
|Admission 矩阵|16/16|credit-cap 6/4 × mode 0–3 × plain/stalls|
|Dispatch query 矩阵|4/4|mode 0/1/3 与 mode 2 stop-query|
|Store 额外场景|2/2|baseline 与 source-pin；默认 coupled 和 prepared 不重复计数|
|Trigger 场景|1/1|load/store/LR/SC/AMO、取消、代际与无副作用检查|
|RR qcredit 矩阵|4/4|Q_ONLY_TERMINAL 0/1 × TARGET_INGRESS_KILL 0/1|

34 个矩阵场景全部匹配各自 PASS 判据。默认 `tb_r64_lsu_progress` target 内部还执行 4 个 late 场景，这里保持按 1 个默认 target 计数。没有发现预期负测以外的 FATAL 日志。

## 预期负测试

既有 `negative` 目标的 12 个场景全部满足“进程非零退出，且匹配指定断言”的原 Makefile 判据；完整续跑 make `rc=0` 确认该条件，而不是将单独的 FATAL 字样当作通过。

|场景|匹配的断言语义|
|---|---|
|AXI read bad ID|响应无 owner 或 RLAST 错误|
|AXI write early B|AW/W owner 未完成便到达 B|
|Fabric bad last|WLAST 与接受的 AWLEN 不一致|
|LSU bad owner|物理响应无 owner|
|LSU bad store cancel|取消较老 store 后仍保留较年轻 memory owner|
|Store bad flush|可见 store 在退休前被取消|
|LSU bind class|bind 改变已预留分类|
|LSU duplicate bind|重复绑定 live owner|
|Data terminal|保留终端响应被背压|
|FP qcredit overflow|occupied ingress 被覆盖或无 credit 接收|
|AXI bypass early B|bypass 路径的 AW/W owner 未完成便到达 B|
|Memory service request hint|live CPU 请求的 hint 不一致|

[SUMMARY.json](../../../results/ai-r3-20261008/full-modules/SUMMARY.json) 保存每项实际匹配语句和日志名。默认负测试的非零条件由 Makefile 原 recipe 验证；没有凭空补造每个子进程的数值返回码。新增 CQ 不同值负测的数值返回码单独捕获为 `1`。

## Booth 超时与复跑记录

1. 首轮完整命令 `rc=2`，耗时 `343.273 s`，停止时有 102 个 `.pass`。唯一 make 失败为 `tb_r64_mul_booth` 的 `timeout 60` 返回 `124`，运行日志为空，无数值比较或断言失败输出。
2. 此 TB 只实例化 `R64Multiply`；该模块与 `baseline-vsrc` 字节一致。TB 的目标是固定 20,000 个向量，带 40,000 个模拟周期的内部边界。
3. 明确仅以 `TEST_TIMEOUT_tb_r64_mul_booth=180` 增加这一 case 的宿主等待上限，独立执行同一已编译 vvp，真实 make `rc=0`，实际 `47.272 s`。20,000 向量全部完成，连续吞吐记录 `II1=1993`；时钟、向量、oracle、断言均未变。这支持首次超时源于并发构建/模拟的宿主负载。
4. 在保留已通过 target 的基础上，续跑原完整命令并显式携带上述单 case timeout 参数。续跑真实 `rc=0`，耗时 `357.445 s`，最终 136 个常规模块 `.pass` 等于默认 135 加额外 prepared 1。CQ 开启 2 个 `.pass` 位于独立子目录，另计。

原始证据：[首轮命令](../../../results/ai-r3-20261008/full-modules/command.json)、[首轮结果](../../../results/ai-r3-20261008/full-modules/result.json)、[首轮日志](../../../results/ai-r3-20261008/full-modules/make.log)、[原超时空日志](../../../results/ai-r3-20261008/full-modules/tb_r64_mul_booth-first-timeout60.log)、[单例诊断命令](../../../results/ai-r3-20261008/full-modules/booth-timeout-diagnostic-command.json)、[诊断结果](../../../results/ai-r3-20261008/full-modules/booth-timeout-diagnostic-result.json)、[续跑命令](../../../results/ai-r3-20261008/full-modules/resume-command.json)、[续跑结果](../../../results/ai-r3-20261008/full-modules/resume-result.json)。

## 覆盖边界

这些结果确认现有模块兼容性，以及局部 CQ qualification、wake 边沿、值快照和转移不变量。它们不能单独证明全核性能收益、所有异常/取消交织、实际 STA 路径和 PPA 改善。Backend 新定向 owner/wake TB 覆盖 full flush；完整部分 branch kill 与 LSU late-response/ticket 生命周期由相应独立验证及整核测试承担，不能从这两项局部 TB 外推已穷尽覆盖。
