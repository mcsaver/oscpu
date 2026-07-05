---
name: fp-cluster-eleven-root-causes
description: "FP 簇整体一次成型落地——uf/ud 23/23 全绿,11 个根因修复全记录(spec §8);pending-FP 拆除/TB 对齐仍遗留"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2308cc05-b4f1-42ae-9110-1dbbdc38b531
---

npc/rv64 FP 簇(真乱序)于 2026-07-02 整体落地,rv64uf+rv64ud 23/23 全绿。**11 个根因**详录于 `npc/rv64/design/specs/ooo-fp-cluster-implementation-plan.md` §8.2,最深的三个:
1. **旧"FP=stop/pending 类"假设残留家族**(SPS fp 臂抢写 stop_pending=0、arbiter 11 处 fp gate、ClassifyGate stop_raw 含 fp_raw)——FP 迁域 A 后这些 gate 反而把**与 FP 同包的 lane1 CSR 指令静默丢成 NOP**(fsflags 消失,fadd case3 fail 的真因)。
2. **CSR 注入 rd 值 capture 拍锁存太早**——与产生 fflags 的 FP 同窗口时读旧值;修=PSS 在 backend_drained(组合)拍刷新 rdata 锁存;**直连实时 rdata 会成真组合环**(commit inst→CSR 读→注入 imm→commit)。
3. **FP load 的 SQ store→load 前递路无 FP 分流**(ex0 单拍完成只有整数 wb)→fld 命中前递即僵死下游;修=FP load 禁前递按序等 drain。伴生:issue1 进 mem_buffer 漏 `mem_buffer_pdest_fp_q`。

**Why**: 这些坑全是"域 B 串行时代的结构不变量"在 FP 迁域 A 后失效——后续拆任何 pending 通道(jump/mem/system)都要先 grep 对应 fact 的全部 gate/clear/stop 消费者。
**How to apply**: 遇到"指令静默消失/NOP 化"先查 [[lsq-sq-switch-landed]] 式的包级探针(head pc/inst/facts/dv/fire/bar 一行);遇到"FP 结果不回"查完成通道五源(arith 流水 meta/exec1/long hold/done FIFO killed/fpwb)与 mem 通路的 pdest_fp 标记随行(直通/buffer/前递三路)。pending-FP 壳已于同日第二批拆净(4 文件删/净删 800 行/F8 fp_dirty 换源 commit is_fp_rd 六层 plumb, spec §9);difftest 基线亦修复(153/153 NEMU 对拍全绿, spec §10: dut 缺 ecall commit 事件+NEMU fp.c 五项/Zbb-W 家族缺失)。F2(免 redirect)第五轮撤退:三个新结构障碍数据化入 #105(flush 漏杀 in-flight rsp/拍内解析与 pred taken 项不同源/redirect 后 bypass 蒸发 head1),正解=per-packet threaded 结构改造;pred_npc 哨兵化+CoreMark difftest 条级可用两资产保留(spec §11)。遗留:UNOPTFLAT 族甄别(+OooRenameMap/IntIQ/DBE 三处新围栏)。B-LSQ Phase2+3 亦落地(2026-07-03):MIQ 在飞队列(rsp 恒配队头,撞号免疫)+dcache byte-window→对齐 line 重写(miss -98%,CoreMark 2.612→2.869);第二刀桥 MSHR 因 miss 稀少 ROI 消失裁决不做(lsq spec §4/§5);踩坑=PROBE 成功也须 wb 标 done、更老 PROBE 须显式拦 load。
