# 任务报告：FPC/DWC SRAM 宏化重构（A 方案：显式宏 wrapper，同步读 +1 拍）

## 目标

用户指令：检索全 RTL，把超大规模存储器改成可综合出 SRAM 的结构，用 A 方案
（显式宏 wrapper），SRAM 行为模型独立目录管理。承接 `2026-07-08-cache-bpu-ooc-probe`
的根因结论（大寄存器阵列+0-cycle 组合读 → memory_map FF/mux 海卡死 ABC）。

## 实现者人格

### 范围判定（全 RTL 普查，5 路侦查 workflow）

全 110 个 .v 文件 2D 数组普查：**FPC ~815Kb + DWC ~463Kb 占全核阵列位 >95%，
SRAM 化只做这两个**。明确不做并记录依据：BPU(18.4Kb，OOC 单独可过，lookup 在
next-PC 生成环上)、TLB×2(10Kb，深嵌请求路径，+1 拍=每次访存加气泡)、
PRF/ROB/IQ/SQ 等(结构性多口/CAM/全表操作且 ≤4Kb)。

### 基础设施

- `npc/rv64/vsrc/sram/`（独立目录，用户要求）：`Sram4096x199.v`(FPC payload)、
  `Sram4096x113.v`(DWC tag+data)、README 管理约定。**一规格一模块名**，无参数化
  实例（iEDA parameterized blackbox abort 教训）；1RW 同步读；内容无复位，
  valid 语义由使用方 FF 承担。
- `filelist.mk` 新增 `RTL_SRAM_DIR` 与两文件；testbench/Makefile 四个 TB_SRCS 接入。

### 两路并行实现（fetch 通路 / mem 通路，文件集零交叉）

**FPC(fetch)**：8 个 payload 阵列合并 1 个 Sram4096x199（位段
{paging,priv,satp,pc,inst0,inst1,resp0,resp1}）；两拍协议（fire 拍锁存+发射读，
判决拍输出有效，非判决拍 hit 恒 0）；valid 4096b FF 保留；**SMC 失效改 7 邻域
盲失效**（不读 pc 比较，超集覆盖已证明安全，pc_q 7 个失效读口消灭）；
**satp/paging/priv tag 原样保留**（satp 不可删：`OOO_CSR_QUEUE_HEAD=1` 时 satp 写
不拉 mmu_flush，satp tag 是唯一挡旧翻译机制——侦查反证 NpcCoreTop.v:396）；
桥 `OooFetchAxiBridge` 新增 S_LOOKUP 判决态，判决链整体搬迁，ITLB/PMP 用锁存值。

**DWC(mem)**：tag_q+data_q 合并 1 个 Sram4096x113；req/walk 双组合读视图合并为
单读口（状态互斥 {S_IDLE,S_RESP}∩{S_WALK_R,S_AD_UPDATE}=∅ 已证明）；
**store 改无条件失效**（清 valid 不读 tag 不写 SRAM，一期刻意丢 write-update
保热）；cacheable/line_cross 保持 0-cycle 纯地址组合；桥 `OooMemAxiBridge` 新增
S_LOOKUP，**顺手修复两个既有 bug**：①walk 读口无移位无跨线检查（S/U 态
DTLB-miss→walk-leaf→dcache hit 且 offset≠0 时 load 回错值）②S_AD_UPDATE 依赖
live lsu_axi_rdata_i（靠 xbar 保持才碰巧对）——判决拍统一 paddr_q 移位+cross 检查。

### 同刀更新

两 cache dedicated spec §8 合同 v0→v1（1-cycle/1RW/盲失效/无条件失效）；
Facts.vh 参照系；Checker.sv 断言打拍（FPC 新增 HIT-FRAME 断言；DWC 合并
HIT-GATE）；`yosys-macro-boundary-contracts.md` v1（blackbox 集迁移为
`Sram4096x199 Sram4096x113 OooFpArithGate OooBranchDirectionPredictor`）+ §1.1
迁移注记；三个 `check_*_macro_contract.py` 冻结正则对齐 v1；
`check_macro_contracts.py` 新增 NETLIST_BLACKBOX_OF 映射（两 cache 的 netlist
实例检查改为其内部 SRAM 宏）。NpcSimTop 统计探针精确化（access 打拍对齐判决拍，
hit/miss 与 access/store 分两拍上报——修复 fire 拍门控恒采 0 的错拍 bug）。

## 关键验证证据

| 护栏 | 结果 |
| --- | --- |
| focused TB ×4（两 cache+两 bridge，含新增两拍窗口/walk-hit/移位跨线定向测试） | PASS |
| 全量 module TB | **84/84 PASS** |
| verilator lint | PASS（0 错误 0 警告） |
| check-contract | PASS（立即断言 12→15，新增 SRAM 1RW/GEOM 断言） |
| 两 cache 宏合同 checker + check_macro_contracts(spec/RTL 部分) | PASS |
| core-regress 全量 | **overall_rc=0**（riscv-tests 177/177 含特权 + AM + build） |
| CoreMark 10 迭代 | **crcfinal=0xfcaf PASS**；CoreMark/MHz 1.157→0.966（-16.5%） |
| NpcTop 综合(新黑盒集) | 见 §综合验收 |

### 性能代价量化（一期接受，二期路标）

- CoreMark/MHz **-16.5%**（1.157→0.966）。
- icache：盲失效后 hit 率仍 99.7%（miss 1671→6413，+0.23%）——盲失效代价可忽略。
- dcache：load hit 率 **99.3%→76.4%**（miss 3784→139221）——**store 无条件失效是
  性能回归主因**。二期最高优先：byte-enable 写宏或 2 拍 RMW 恢复 write-update；
  其次 lookup 重叠流水恢复 1/拍吞吐。

### 综合验收（重构最终目的）

- 首轮 timeout 3000s：已推进到 **120/120 ABC(liberty map)** 的 loop-breaking
  （对照旧 full=卡死在 7.6.1 ABC blif 提取都完不成——**结构性突破已确认**），
  纯粹是新增 stdcell 逻辑量让 ABC 变慢。
- 6000s 重跑：同样 timeout 于最终 ABC loop-breaking——**flatten 全核喂 ABC 一整锅在新 stdcell
  规模下不可行，正解=keep_hierarchy 沿模块边界切 cone**(级间边界治理 spec §6 机制已接入，
  P3 实验进行中)。结论：SRAM 化的结构性目标达成(存储不再展开 FF 海)，全综合收口移交
  keep_hierarchy 路线。

## 审查者人格

- **满足"可综合出 SRAM 结构"的定义**：存储阵列已下沉为 1RW 同步读宏边界，
  netlist 中以 `Sram4096x199/Sram4096x113` 黑盒实例存在，可由 bsg_fakeram/工艺
  memory compiler 直接替换。但**尚未接入任何 Liberty/LEF**——STA/PPA 闭合仍 open
  （known-issues [112] 状态不变）。
- 全状态 difftest 按用户策略延后（重构整体收口后一次性跑）；本轮护栏为
  focused TB/checker/module TB/tohost 回归/CoreMark checksum，均绿。
- dcache load hit 率 -23pp 是刻意取舍但代价超预期（CoreMark 特有 store-then-load
  模式放大），若 Linux boot 类负载同样敏感，二期 write-update 恢复应提前。
- 集成 TB（tb_ooo_sv39_boot 等 78 个未改 TB）全绿证明桥对外握手协议未破坏；
  但上游流控（FetchRequestMux/FlowControl）对 ready 占空比的性能级假设未逐一审计，
  只有 CoreMark/riscv-tests 端到端证据。
