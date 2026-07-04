# BlockInterpreter — DBT basic-block 解释器

**文件**:`src/isa/block_interp.hh` · **↔ npc**:—(功能后端加速,对应 gem5 KVM/FastModel fast-forward + DBT 思路)

## 职责
功能后端从逐指令解释升级为 **basic-block 块级执行**,加速 fast-forward。按 basic block(直线段 + 一条终结指令)切分,
按入口 PC 缓存块边界;循环体的块只翻译一次、复用多次执行 → 摊销边界扫描。

## 状态
- `st_`:`FuncState`(regs/mem/csr/pc,与逐指令解释共用结构)。
- `cache_`:`入口 PC -> Block{start, term}`(翻译缓存)。
- 计数:`translations_`(块翻译 = 边界扫描)、`block_execs_`、`insts_`。

## 语义单一来源
块解释与逐指令解释(`FunctionalBackend::step_one`)**共用** `FunctionalBackend::apply_inst(in, st, mmu_on)`(静态,就地改 st 含 pc)。
故两者对任意程序最终态逐位一致(difftest 护栏)。`is_terminator(fu)`(inst.hh)判块边界:BRANCH/JUMP/JAL/JALR/ECALL/MRET/HALT。

## 执行
`run(budget)`:取(或翻译)入口块 → 直线体 `[start, term)` 不再逐条判终结,直接 `apply_inst` → 终结指令 `apply_inst`(自设 pc)。
翻译缓存命中即复用(循环)。budget 上限兜底畸形/无限循环。

## 不变量 / 行为
- 块解释 == 逐指令解释 == 详细核(三方最终态一致)。
- 循环:翻译数有界(= 循环内不同块数),块执行数随迭代增长 → 复用比 execs/translations ≫ 1。

## 测试
`make run-dbt`:循环 N=1000 demo(块翻译 2 次 / 执行 1001 次,三方一致)+ fuzz 2 万随机程序(含循环/分支/mem;复用比 ~2662×,块 vs 逐指令逐位一致)。
