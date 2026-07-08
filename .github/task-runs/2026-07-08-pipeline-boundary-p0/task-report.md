# 任务报告：级间边界显式化治理 P0（spec 冻结 + PipeStageReg 原语 + keep_hierarchy 机制）

## 目标

用户宪法级治理指示：级间边界显式化（弹性/刚性两类归一）、PipeStageReg 原语、
六类契约 spec 先行、逐边界提取、flush 单点化搭车、综合侧 keep_hierarchy 兑现。
本 task-run 只交付 **P0**（spec+原语+机制），边界提取 P1+ 未动 RTL。

## 实现者人格

### 四路只读侦查（workflow）

1. **隐式刚性边界普查**——重大现实校正：四条候选边界只有 **EX→WB 真有打拍**
   （OooIntBackend ex0/ex1 簇 145b×2 lane，语义=down_ready≡1 的退化 PipeStageReg，
   flush 单臂、无 stall 保持、kill 不清）；Decode→Rename / Rename→Dispatch /
   Issue→RegRead→EX 全是**零寄存融合拍**——在这些切点插寄存是"重新流水化"
   （改 IPC/唤醒时序）而非"提取"，spec 已把两类动作分开，后者逐条独立决策。
2. **弹性边界+全核骨架图**：PacketFifo 是裸存储原语（握手在外部 FlowControl，
   有 0 拍 bypass 臂）；IQ 是压缩队列+CAM+同拍 bypass（是调度器，禁套原语）；
   ROB walk/recover 窗口语义确认。
3. **flush 散落点普查**：权威契约 `ooo-flush-redirect-contract.md` 已在（13 事件族/
   7 汇合点/无集中仲裁）；**OooRedirectArbiter.v（13 例年龄律 TB 全绿）可 git 复活**
   （`git show fece978e6^:...`）；宪法裁定年龄律为正解；big-bang 判死史 →
   assert-then-converge + shadow-equivalence 切换路径；三条铁律不进 arbiter。
4. **keep_hierarchy PoC**（scratchpad/keephier-poc/）：RTL `(* keep_hierarchy *)` 属性
   双仿真器零告警、穿透 $paramod；yosys setattr 机制有 **paramod 陷阱**（read_verilog
   后直接 setattr 会被重派生丢弃，须先 `hierarchy -check -top`）；端到端验证 ABC 对
   keep 模块分别抽取映射（cone 切割机制成立）、iEDA STA 读层次化网表兼容。

### 落地物

- `npc/rv64/design/arch/pipeline-stage-boundary.md`：边界清单+两类动作区分+
  PipeStageReg 六类契约映射+P0..P5 分阶段计划+flush 单点化路线+雷区。
- `npc/rv64/vsrc/pipeline/PipeStageReg.v`（独立目录 README 管理约定）：valid/ready
  握手+payload 打拍+flush_i/kill_i 分端口+PSR-HOLD/PSR-FLUSH-EMPTY 立即断言+
  `(* keep_hierarchy *)`；参数化 WIDTH（非黑盒合法）。
- `testbench/tests/tb_pipe_stage_reg.sv`：装载/反压冻结/背靠背/flush 压同拍装载/kill
  八场景，**PASS**（-DOOO_ASSERT 断言全程使能）。
- `KEEP_HIERARCHY_MODULES` 三层接通：yosys.tcl（含 hierarchy-first 陷阱修复注释）/
  yosys-sta Makefile / npc/rv64 Makefile（STA_KEEP_HIERARCHY_MODULES）。

### 首个应用实验（进行中）

SRAM 化后 NpcTop flatten 全核综合两轮 timeout 于最终 ABC loop-breaking →
用新机制跑 `STA_KEEP_HIERARCHY_MODULES="OooIntBackend OooFpBackend OooFrontend
OooFetchAxiBridge OooMemAxiBridge OooRob OooIntIssueQueue"` 的对照实验（后台）。

## 审查者人格

- P0 交付的是**装置**（spec/原语/机制），未提取任何真实边界——不得声明治理完成；
  P1（EX→WB 第一刀）是下一个最小闭环。
- keep_hierarchy 实验结果未落（timeout 6000s 窗口），"切 cone 解决 ABC 慢"当前是
  机制已验证+全核效果待证；若无效，备选=ABC 参数调优/减 valid FF 扇出。
- 用户路线图中"Decode→Rename 链切开对综合收益大"经侦查校正为重新流水化类
  （零寄存融合拍），收益判断成立但动作类别升级，须用户再确认后单独 spec。
- flush 单点化 P4 未动，输入清单已冻结；取指侧无 age 字段是最大 plumbing 缺口。
