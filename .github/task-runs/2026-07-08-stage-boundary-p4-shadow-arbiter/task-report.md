# 任务报告：级间边界治理 P2+P3+P4 批次（用户指令"执行完 P4 后统一交付"）

## 目标与范围

按 `pipeline-stage-boundary.md` 连续执行 P2（FP exec1 簇提取）、P3（keep_hierarchy
综合兑现）、P4（flush 单点化 shadow-equivalence 阶段，S1-S4）。

## 实现者人格

### P2：OooFpBackend exec1 簇 → PipeStageReg（已完成）

- 侦查裁定可提取（P1 同型机械刀；long meta 簇两相写/done FIFO squash 队列维持不提取，
  exec1 是该模块唯一可提取纯流水簇）。
- `PipeStageReg #(.WIDTH(81))`，payload `{rob[80:77],pdest[76:71],dst_gpr[70],
  dst_en[69],value[68:5],fflags[4:0]}`；kill_i=使用方年龄比较组合线（契约⑥）；
  down_ready=!arith_out_valid_w（arith 完成仲裁优先的现状反压）；**issue_ready 保留
  `!exec1_valid_q` 项**（语义中性——原语 up_ready 允许"当拍排空当拍装载"比现行宽，
  省 1 拍属独立微优化不混入本刀）。消费点零文本改动。

### P3：keep_hierarchy 综合兑现（机制完成+首批数据，全核对照进行中）

- 7 大模块 keep 实验：**ABC 分模块独立 mapping 实锤**——OooMemAxiBridge
  66034 gates/area 131k/delay 45，OooFetchAxiBridge 93412 gates/area 175k/delay 50
  （SRAM 化后两 cache 控制逻辑 stdcell 成本首次量化）。
- **发现并修复哈希 paramod 漏保**：参数值长时 yosys 派生 `$paramod$<hash>\Mod`
  （模块名在末尾），原 glob 尾部强制 `\*` 不匹配 → 7 keep 5 漏（仅两个无参数 bridge
  存活）。yosys.tcl setattr 补 `=*\$module` 后缀 pattern，小例 PoC 验证命中。
- 修复版全核综合对照待跑（旧实验占用中）。

### P4：shadow RedirectArbiter + 等价断言（S1-S4 完成，切消费点为独立后续）

- **S1 复活**：`OooRedirectArbiter.v`（106 行年龄律仲裁器）+ 13 例 TB 逐字节复活自
  `fece978e6^`，`REDIR_REASON_*` 9 宏回填，进 RTL_CORE_SRCS（经 FRONTEND_HELPERS）。
- **S2 plumbing**：rob_head_idx 经 4 层 wrapper 透传到 glue（侦查估 2 层，实际
  IntBackend→AluDecodeBackend→AluCoreSlice→ExecuteBackend→glue）；OooFrontend 新增
  E4 目标口（照 Sequencer 装载臂构造）。纯增量端口。
- **S3 shadow+断言**（全 `ifdef OOO_ASSERT`，综合零影响）：glue 内 commit 家族
  pre-mux（E1>E5>E6 现行文本序）+ GAP-2 甲门（带"切换时删除"注释=可 grep 实体）+
  shadow arbiter 实例（trap 口 age≡0、direct 口 head-1 哨兵免取指侧 age plumbing）+
  SHADOW-EQ-PC/KILL/NUKE 三断言 + E7/E8/E9 排除谓词；OooControlPlane 加 INV-3b
  （GAP-2 乙监测断言）。断言基线 12→21。
- **S4 验证**：①负测试——故意错接 branch 口 pc 源 → tb_ooo_sv39_boot **15 次
  SHADOW-EQ-PC fire**，复原后 0 fire（断言非真空实锤，证据
  `s4-negative-test-evidence.log`）；②等价证据——module TB 86/86 + **riscv-tests
  177/177 + AM + CoreMark 0xfcaf 全程 OOO_ASSERT（Verilator build 默认带）零 fire**。

## 验证汇总（统一批次）

| 护栏 | 结果 |
| --- | --- |
| tb_ooo_redirect_arbiter（13 例年龄律） | PASS（复活零改动） |
| 全量 module TB | **86/86 PASS** |
| lint（默认 + OOO_ASSERT 两变体） | PASS 零告警 |
| check-rtl-style / check-contract | PASS（断言 17→21，基线升 21） |
| core-regress（OOO_ASSERT 在线） | **rc=0**（riscv 177/177 含特权） |
| CoreMark 10 迭代（OOO_ASSERT 在线） | **0xfcaf + GOOD TRAP + 0.966/MHz**（与 P1 后持平，P2/P4 零性能影响） |
| shadow/INV-3b fire 计数（全部上述负载） | **0**（负测试已证明会响） |

## 审查者人格（剩余风险与边界，不越级）

- **P4 交付的是 shadow 阶段**（等价证据链已闭合），**切消费点未做**——拆
  Sequencer/RequestMux 双机制是 shadow 全绿后的独立后续，须含 GAP-2 甲门删除
  （行为变化）+ 全量重验。不得声称"flush 单点化完成"。
- E2/E5-head0 支 flag=0 零 exercise——shadow 全绿不构成其等价证据（幸存者偏差，
  翻 flag 时 INV-3b 是哨兵）。
- E6-jump 臂 shadow 镜像死硅 tie-0，若真触发即 bug（PC 断言连带暴露）。
- glue 侧 win 谓词与 Sequencer 内谓词存在双写漂移风险，方向是断言误报（fail-loud）。
- **P3 修复版全核综合已闭合（补记）**：glob 修复后 7 keep 模块全部存活，
  **NpcTop 全核 stdcell 综合 4670.49s 首次跑通**（对照：flatten 全核 6000s×2 timeout）。
  ABC 10 块独立 mapping，首个全核 PPA 概览：总 stdcell ~855k area（不含 4 黑盒宏），
  关键路径大户 IntBackend(delay 89)/FpBackend(90)；PipeStageReg 实例各 5 gates（纯打拍零逻辑）。
  宏合同 checker 新网表全 PASS + iEDA 兼容 PASS。iEDA STA smoke：3600s timeout——
  较此前有推进(进到 StaDataPropagation 的 endpoint 枚举，之前是静默卡死)但 rpt/pwr
  仍未产出；工作假设=四黑盒(Sram×2/FpArithGate/BPU)无 Liberty timing 模型致
  data propagation 无法收敛，下一步=bsg_fakeram 生成两个 Sram 规格的 .lib 接入
  (SRAM 路线既定步骤)后重试。[112] 的 STA 完整闭合仍 open，综合侧已闭合。
  `OooFpArithGate` 内部子模块化单独立项未动。
- 全状态 difftest 按用户策略继续推迟至重构整体收口。
