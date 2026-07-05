---
name: f2-true-branch-prediction-landed
description: "F2 真分支预测整体落地(8 轮失败史闭合):pred_npc 单源+dual 免 flush+BPU resolve-update;恒-mispredict 掩盖的预存漏洞家族(必读);CoreMark +18.3%"
metadata:
  type: project
  originSessionId: 2308cc05-b4f1-42ae-9110-1dbbdc38b531
---

npc/rv64 F2(真分支预测,免 redirect)于 2026-07-03 整体落地,#105/#110 八轮单点失败史闭合。CoreMark 2.869→3.395/MHz(+18.3%),branch_flush 34.7%→19.4%,riscv 153/153+CoreMark 10iter difftest 全绿。方案=**pred_npc 单一真源**(`direct_fire_succ` 一根 wire 同时喂 OutstandingSequencer.next_fetch 和 dispatch pred_npc——"同源"用共享 wire 机械保证,不靠事后重建)+not-taken 分支免 flush 双发(dual_go 谓词只用 head 侧裸事实:纯 BHT 寄存输出+decode 裸支持性,**不含 ready/valid**,否则经 pair-ready/core_dispatch1_valid 成 UNOPTFLAT 环——两处实测)+solo 拍 d1 影子 squash+bht_idx/pred_taken thread 进 IQ 的 resolve-update(此前 BPU update 四臂全死,BHT 恒零训练)。

**Why(最重要的经验)**:mode=1"恒 mispredict+恒 ROB-walk"是一张**掩盖预存漏洞的安全网**——每条控制流后全清洗,使"kill 窗口逃逸"类 bug 永不显形。拆网(免 redirect)后一次涌出三个此类预存漏洞:①flush 拍顺序取指臂用旧 next_fetch_pc_q 泄漏 wrong-path 请求;②MIQ kill 拍同拍 push 的 entry 漏标 killed(kill 扫描只看 valid_q 旧值),迟到 rsp 写"已被 walk 回收重分配"的 preg——**症状=架构 GPR 对拍全过而 IQ 消费者读脏**(commit 值来自 ROB 副本,preg 污染只毒 in-flight 读者);③MMIO load 按 plain load 投机发射(设备读副作用不可撤销+LEGACY 在飞不受 walk 保护)。
**How to apply**:今后任何"减少 flush/kill 频率"的优化(如 replay 化、部分 squash),先 grep 三类窗口:kill 拍同拍 push/issue 的实体是否被标记;walk 回收的 preg 是否还有 in-flight 写者;有副作用的操作(MMIO/AMO)是否可能投机发射。调试此类"架构态对但微架构读脏"用 [[single-line-cross-signal-probe-debug]]:rename(x→p)/WB(p←v)/issue(s1p,s1v)三视角同一时间轴,一眼看出 preg 复用撞写。

**difftest 基建坑(同刀修复)**:MMIO skip 旧机制(桥 rsp 拍/uart 总线拍置全局旗)与 commit 粗配对——SQ 化后 store 总线访问晚于 commit,UART store 吃不到 skip→NEMU ref 执行 MMIO store→fault→ref.pc=0;这就是既往"CoreMark difftest 3.2M 条预存墙"的真身。正解=commit 拍在 difftest.cpp 按 inst 解码 EA(load/store/AMO,gpr[rs1]+imm),EA<0x80000000 即 skip(ref 不步进+拷 dut GPR+ref.pc=pc+4)。RVC 压缩 mem 指令未解码(遇 RVC 设备访问需补)。

遗留/下一刀:taken fire 仍付 flush+重取延迟(fetch bucket 84%)——spec 重取走 redirect 臂省 1 拍/BTB 免 flush/fetch-time BPU;宪法使能件 4(serialize-at-retire)未动;pending branch/jump 壳成死路待 B4 删文件。
