# 2026-07-03 · rv64 OoO 核全 RTL 从零重读 + 文档归档校正

## 任务

用户判定既有 rv64 设计文档生命周期已结束,要求**不依赖任何 .md**、纯从 RTL 从零重建架构认知,
明确"能实现什么/不能实现什么",并据此归档/校正过时文档。

## 方法

1. **9 路子系统并行 RTL 审计**(禁止读文档,每条结论带 file:line 证据,核实实例化/判定死代码):
   取指通路 / 分支预测与恢复 / 译码重命名分发 / 整数发射执行 / FP 簇 / 访存 / 控制平面与特权 /
   顶层 SoC 总线仿真 / 构建与验证现状 → `report-0..8-*.json`
2. **矛盾裁定**:13 条跨报告矛盾逐条复核源码裁定 → `contradictions.json`
3. **追问验证**(6 项,形式化证据链):dispatch 快解析死硅族、SMC/fence.i 闭合性、
   difftest RVC MMIO skip、内存窗口三方一致性、pending_mem 可达性终裁、跨页 misaligned → `answers.json`
4. **综合**: `npc/rv64/design/arch/rtl-ground-truth-2026-07-03.md`(真相基线,新的权威现状快照)
5. **文档审计**(11 组并行,85 份):arch 过程文档 + specs 全量 + 三个 README,
   逐份判定 CURRENT/DRIFT_FIXED/ARCHIVE 并修正/归档。

## 关键结论(细节见真相基线)

- 核 = RV64IMAFDC+Zb* / M-S-U / Sv39 / 2-wide OoO;域 B 只剩 system/trap 类;
  branch/jump/fp/mem 四类 pending 已迁域 A 或被形式化证死(pending_mem 从未可达)。
- **硬正确性缺口 4 项**:SMC 8B store 漏失效+fence.i 真 no-op;Sv39 跨页 misaligned 静默错译;
  difftest MMIO skip 对 RVC 压缩访存 ref.pc=pc+4 毒化;unsupported 指令域 B trap 出口悬置。
- **死硅普查**:pending branch/jump/mem 三链、dispatch 快解析族、BTC/JALR-BTB 更新/prefetch 家族、
  checkpoint 五套影子、SyntheticLane1Ret、RedirectArbiter(未编译)、PRF 5 个无效读口等
  (见基线 §4 全表)。
- 结构参数与 define.v 宏多处不一致(RAS 实 32 vs 宏 16;CACHEABLE_* 死宏与 256MB PMEM mask 矛盾)。

## 产物

- `npc/rv64/design/arch/rtl-ground-truth-2026-07-03.md` — 真相基线(新增)
- `npc/rv64/design/arch/ooo-core-architecture.md` — 宪法 v0.2(【现状】层同步)
- `design/specs/*` 逐份校正 + 归档(见 `design/specs/history/README.md` 新增表项)
- `.github/memory/{project-status,known-issues,modules/npc}.md` 同步
- 本目录:9 份子系统报告 + 矛盾 + 追问答案(JSON,含全部 file:line 证据)
