# 模块规范索引（design/specs/）

按子系统组织的逐模块规范。★ = 本轮(2026-06-28)新增/升级的**专业规范**(图文并茂、状态机、不变量、
关键路径、验证);其余为 decompose 阶段的简明 owner 边界笔记(见 `../../vsrc/README.md` 总览)。
模板见 `../arch/SPEC-TEMPLATE.md`。动 RTL 前先写/更新对应 spec。

## 执行 / 调度 / 重命名（OoO 后端核心）
- ★ `ooo-muldiv-unit` — 整数乘除(radix-4+CLZ 算法图示)
- ★ `ooo-int-issue-queue` — 发射队列(压缩程序序/2 唤醒/2 oldest-ready/快路径)
- ★ `ooo-rename-alloc` — rename/free-list/busy-table/dispatch 分配链(**#1 Fmax 路径**)
- ★ `ooo-rob` — 重排序缓冲(2-wide 程序序提交/精确异常/checkpoint)
- ★ `ooo-phys-reg-file` — 物理寄存器堆(写-读旁路/write1>write0/x0)
- ★ `ooo-rename-map` — 重命名映射(同拍 RAW/WAW 前递/checkpoint)
- `ooo-int-backend-decompose`、`ooo-fp-pending-exec*`、`ooo-fp-reg-file`、`ooo-pending-fp-sequencer`

## 访存 / MMU
- ★ `ooo-mem-axi-bridge-fsm` — 访存桥 FSM(flush/drop 语义/store 解耦)
- ★ `ooo-sv39-tlb` — Sv39 TLB(64 项/上下文/superpage)
- ★ `pmp-checker` — PMP 检查器(规范默认拒绝 S/U + iter0 回归根因)
- `../arch/mem-store-decouple`(B1)、`ooo-pending-memory-sequencer`

## 取指 / 前端 / 分支预测
- ★ `ooo-fetch-axi-bridge` — 取指桥(取指 cache PMP-grant 门控 iter1)
- `ooo-frontend`、`ooo-fetch-packet-*`、`ooo-branch-*`、`ooo-pending-branch/jump-sequencer`、
  `ooo-fetch-pc-outstanding-sequencer`、`ooo-frontend-*-gate`、`ooo-direct-*`、`ooo-ras-*`、`ooo-jalr-*` 等

## 控制面 / 提交 / CSR
- ★ `ooo-csrfile` — CSR(M/S 特权/trap-return 栈/委托/PMP/satp/counters)
- `ooo-control-plane`、`ooo-commit-output-mux`、`ooo-csr-*-mux`、`ooo-pending-*-sequencer`、
  `ooo-trap-exit-*`、`ooo-synthetic-lane1-ret-*` 等

## 装配 / 总线
- `ooo-core-top-glue`、`ooo-{frontend,control-plane,execute-backend,writeback,memory-access}`(子系统 wrapper)

## 说明
- 当前 ★ 专业规范覆盖被本轮优化/分析触及的核心模块(12 个);其余模块规范为边界笔记,
  后续按需逐步升级到专业模板。整体架构与时序 track 见 `../arch/ROADMAP.md`。
