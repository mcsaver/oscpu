---
name: lsq-sq-switch-landed
description: "LSQ SQ 切换步已落地(b1e39e6b2)——store 迁 SQ+probe 精确异常;三个\"队头=序安全\"不变量腐蚀坑家族"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2308cc05-b4f1-42ae-9110-1dbbdc38b531
---

2026-07-02 LSQ Phase1 完整落地:①SQ 切换步(b1e39e6b2,`OOO_SQ_STORE_PATH=1`):plain store = issue 拍 probe(桥 probe 事务:翻译+PMP 不写、PA 经 rsp_rdata 回传,fault 精确)→ SQ 存 PA → 退休 → drain 落存(pretrans+nokill 写必达);②store→load 前递(2fad775f3):最年轻的更老全覆盖 entry 单拍取数,**区间包含判定**(LSU 字节语义=addr 起顺序字节、wstrb 连续 1、数据低位对齐——非 8B lane!),CoreMark CPI 1.227→1.208。全 gate 绿:TB 99/99、riscv 177/177、difftest 逐指令、AM。

**Why:** SQ 使"store 退休 ≠ 已落存",全核所有基于"ROB 队头/ROB 空 = 内存序天然安全"的旧不变量全部腐蚀——本次实测修了三处:①mem_order_ready 队头豁免放行与 SQ committed 重叠的 load;②等待判定被 rob_head_valid gate 短路(dispatch-bypass 发射拍自身 ROB 记账不可见);③AMO 静默 gate 只在 can_fire 不在 mux valid → 占 mux 饿死低优先级 drain(死锁)。

**How to apply:** 后续 LSQ Phase(前递/LQ/MSHR/投机 load)每碰一个"队头/ROB 空/head_valid"判定,先问"SQ 里是否还有已退休未落存的 store"; 发射条件收紧时必须同步收紧对应的请求 mux valid(否则永不 fire 的 valid 饿死低优先级源)。剩余切片:store→load 前递(现重叠即等 drain)、Sv39 load-vs-SQ 精确判定(现 blind)、PMA 前置(未映射 store fault 现降级 [SQ-DRAIN-ERROR] 警告)。相关 [[nemu-act4-am-devtree-unify]] [[coremark-10-iterations]]。
