# 派发日志：FPC/DWC SRAM 宏化重构

| 节点 | 动作 | 结果 |
| --- | --- | --- |
| recall | DB brief 等效（前置 task-run `2026-07-08-cache-bpu-ooc-probe` 根因 + yosys-sta memory） | 契约输入就绪 |
| recon(workflow×5) | 全 RTL 存储普查 / 两 bridge FSM 时序分析 / BPU+TLB 使用方 / spec 合同提取 | 范围=FPC+DWC；读口互斥性证明；satp 不可删反证；walk 口 bug 发现 |
| infra | vsrc/sram/ 目录+两宏+README；filelist/testbench Makefile 接入 | 冲突面预清零 |
| impl(workflow×2 并行) | fetch 通路 / mem 通路各 8 文件（cache+bridge+Facts+Checker+TB×2+spec×2） | 各自 focused TB+lint 绿；mem 路顺手修 walk 口 2 个既有 bug |
| 收尾-探针 | NpcSimTop 统计探针精确化（打拍+分拍上报，修 fire 拍门控恒 0 bug） | CoreMark dcache 统计恢复正常 |
| 收尾-合同 | 宏边界总表 v1+3 checker 正则+NETLIST_BLACKBOX_OF 映射 | spec/RTL 检查 PASS |
| verify | 全量 module TB / lint / check-contract / core-regress / CoreMark | 84/84；PASS；15≥12；rc=0(177/177)；0xfcaf |
| syn | NpcTop 新黑盒集综合（Sram×2+FP+BPU） | 3000s 达 120/120 ABC loop-breaking（旧 full 卡 blif 提取不可比拟）；6000s 重跑见下 |

## 综合最终轮记录

- 命令：`make -B syn STA_CLK_FREQ_MHZ=100 STA_SYNTH_FLATTEN=1 STA_SYNTH_PUBLIC_AUTONAME=0 STA_SYNTH_DFF_AUTONAME=0 STA_SYNTH_BLACKBOX_MODULES="Sram4096x199 Sram4096x113 OooFpArithGate OooBranchDirectionPredictor"`
- 结果：**3000s 与 6000s 两轮均 timeout 于 120/120 最终 ABC(liberty map) 的 loop-breaking 阶段**
  (日志 1.6GB，1265+ 处环打破，稳定推进非死循环)。对照四黑盒版 1020s 可完成：增量=FPC/DWC
  控制逻辑+8192 valid FF 进 stdcell 后 flatten 全核语境的 ABC 负担。
- **判定：结构性突破已确认**——SRAM 化前 full 综合连 memory_map 后的 ABC blif 提取都完不成
  (600s 卡死在 7.6.1)；SRAM 化后全流程推进到最终 mapping，剩余是"时间预算/cone 切割"问题
  而非"结构不可能"。正解=级间边界治理 P3 的 keep_hierarchy 切 cone(实验已启动,
  STA_KEEP_HIERARCHY_MODULES=7 大模块,结果另记)。netlist 宏实例检查待新网表产出后复验。
