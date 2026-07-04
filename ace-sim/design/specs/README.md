# ACE-Sim 模块 spec 索引

每个核心模块一份 spec(镜像 npc `design/specs/ooo-*.md` 的 file↔module↔tb↔spec 1:1 对应)。
工程约定见 [`../arch/engineering.md`](../arch/engineering.md);内核不变量见 [`../../DESIGN.md`](../../DESIGN.md)。

| spec | 模块(`src/core/…`) | 单元测试 | ↔ npc |
|---|---|---|---|
| [bpu](bpu.md) | `frontend/Bpu`(bimodal + gshare) | `test/unit/tb_modules.cc::test_Bpu` | OooBranchDirectionPredictor |
| [ras](ras.md) | `frontend/Ras` | (整核 demo/fuzz `run-gshare`) | RAS + IndirectPredictor |
| [fetch](fetch.md) | `frontend/Fetch` | (整核 fuzz) | OooFetchPacketDecode + PcOutstandingSequencer |
| [rename-map](rename-map.md) | `rename/RenameMap` | `::test_rename_freelist` | OooRenameMap |
| [free-list](free-list.md) | `rename/FreeList` | `::test_rename_freelist` | OooFreeList |
| [phys-reg-file](phys-reg-file.md) | `regfile/PhysRegFile` | `::test_physregfile` | OooPhysRegFile + OooBusyTable |
| [alu](alu.md) | `execute/Alu` | `::test_execute` | ALU + CompareUnit |
| [mul-div](mul-div.md) | `execute/MulDiv` | `::test_execute` | OooMulDivUnit |
| [branch-resolve](branch-resolve.md) | `execute/BranchResolve` | `::test_execute` | OooDirectBranchResolveGate |
| [fp-alu](fp-alu.md) | `execute/FpAlu` | (整核 fuzz `run-fp`) | OooFpArithGate |
| [csr-file](csr-file.md) | `control/CsrFile` | (整核 demo/fuzz `run-csr`) | CsrFile + Ooo*TrapRequestMux |
| [tlb](tlb.md) | `mmu/Tlb`(+ `mem/mmu.hh`) | (整核 demo/fuzz `run-mmu`) | Sv39Tlb + PageTableWalker |
| [issue-queue](issue-queue.md) | `issue/IssueQueue` | `::test_issue_queue` | OooIntIssueQueue |
| [store-queue](store-queue.md) | `memory/StoreQueue`(STA/STD) | `::test_store_queue` | OooStoreQueue |
| [load-unit](load-unit.md) | `memory/LoadUnit` | (整核 fuzz `run-mmu`/`run-sta`) | OooLoadUnit / AGU |
| [decode](decode.md) | `decode/Decode` | (整核回归) | OooDecode |
| [block-interp](block-interp.md) | `isa/BlockInterpreter` | (`run-dbt` demo/fuzz) | —(DBT fast-forward) |
| [rob](rob.md) | `dispatch/Rob` | `::test_rob` | OooRob |
| [cpu-top](cpu-top.md) | `top/CpuTop` | (五版 demo + fuzz) | OooCoreTopGlue / NpcCoreTop |

**未镜像**:npc `[DEAD]` 模块(pending 链 / BTC / JALR-BTB / prefetch / synthetic-lane1)。
**gem5 广度扩展 ①-⑦ 全部落地**(各带 difftest 护栏):cache 层级(①)、FP(`fp-alu`,②)、CSR/trap/中断(`csr-file`,③)、
TLB/MMU(`tlb`+`load-unit`,④)、gshare+RAS+JAL/JALR(`ras`+`bpu`,⑤)、STA/STD+Decode+LoadUnit(`decode`+`store-queue`,⑥)、DBT block 解释(`block-interp`,⑦)。
