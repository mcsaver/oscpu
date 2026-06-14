# RV64 Sv39 helper 函数 waiver 清理

## 目标

继续按商业 ASIC RTL 风格清理 RV64 活动路径中的仿真式写法。本轮聚焦 Sv39 翻译路径中三个重复 helper：

- `npc/rv64/vsrc/common/OooSv39Tlb.v`
- `npc/rv64/vsrc/core/OooFetchAxiBridge.v`
- `npc/rv64/vsrc/core/OooMemAxiBridge.v`

目标是去掉函数级 `BLKSEQ` waiver，不改变 IFU/LSU page-walk FSM、TLB fill/lookup、fault 语义或 cache 行为。

## RTL 推导

### 需求

原实现中 `leaf_paddr()` 在 function 内先用临时 `leaf_ppn` reg，再用 blocking `case` 赋值，外侧需要 `verilator lint_off BLKSEQ`。`OooMemAxiBridge` 的 `data_permission_fault()` 也在同一个 waiver block 内用 `read_ok/user_ok` 临时变量。

这些 helper 是纯组合地址/权限计算，不应该依赖 sequential 风格 waiver。商业 lint 审查时，这类 waiver 会掩盖真正的时序 always blocking 赋值问题。

### 协议规则

Sv39 leaf physical address 拼接保持不变：

- level2 leaf：`PPN2` 来自 PTE，`PPN1/PPN0` 来自 VA。
- level1 leaf：`PPN2/PPN1` 来自 PTE，`PPN0` 来自 VA。
- level0 leaf：完整 PPN 来自 PTE。
- page offset 总是来自 VA `[11:0]`。

LSU data permission 保持不变：

- read 允许条件：`PTE.R || (mstatus.MXR && PTE.X)`。
- write 必须要求 `PTE.W`。
- U page 在 U-mode 可访问；S/M effective data privilege 访问 U page 需要 `mstatus.SUM`。

### 状态机/不变量

- `OooFetchAxiBridge` page-walk 状态、跨页 fetch packet 合并、ITLB fill 行为不变。
- `OooMemAxiBridge` page-walk、flush/drop、读写响应 ownership、DTLB fill 行为不变。
- `OooSv39Tlb` lookup hit、SATP context tag、VPN match、leaf paddr 输出不变。
- page fault/access fault 判定不因 helper 写法改变而变化。

### 数据通路约束

- `leaf_paddr()` 用单表达式组合 mux 直接生成 `{8'b0, selected_ppn, vaddr[11:0]}`。
- `data_permission_fault()` 拆成 `data_read_ok()` 与 `data_user_ok()` 两个纯组合 helper，再组合出 fault。
- 不新增状态、不新增端口、不改变 filelist。

## 代码改动

- `OooSv39Tlb.v`
  - 删除 `leaf_paddr()` 外侧 `BLKSEQ` waiver。
  - 删除临时 `leaf_ppn` reg。
  - 用单表达式组合 mux 直接拼物理地址。
- `OooFetchAxiBridge.v`
  - 同步改写 IFU page-walk 的 `leaf_paddr()`。
- `OooMemAxiBridge.v`
  - 同步改写 LSU page-walk 的 `leaf_paddr()`。
  - 将 data permission 中的 read/user 子表达式拆成纯组合 helper，删除 waiver block。

## 验证

- `rg -n "BLKSEQ|lint_off" npc/rv64/vsrc/common/OooSv39Tlb.v npc/rv64/vsrc/core/OooFetchAxiBridge.v npc/rv64/vsrc/core/OooMemAxiBridge.v`: 无命中
- `make -C npc/rv64/testbench TESTS='tb_ooo_fetch_axi_bridge tb_ooo_mem_axi_bridge tb_ooo_sv39_boot' RESULT_TIMESTAMP=20260603-sv39-helper-waiver-cleanup run`: PASS 3/3
- `make -C npc/rv64 lint`: PASS
- `make -C npc/rv64 -j2`: PASS
- `make -C Linux/tools smoke-sret-user-sv39 smoke-sret-user-sv39-halfword smoke-virtio-blk`: GOOD TRAP
  - `smoke-sret-user-sv39`: cycles=287, commits=107
  - `smoke-sret-user-sv39-halfword`: cycles=358, commits=134
  - `smoke-virtio-blk`: cycles=18293, commits=7844
- `git diff --check`: PASS

## 边界

- 本轮是 lint/RTL 风格收敛，不是 Sv39 功能重构。
- 单模块 strict lint 仍会报部分 helper 宽输入 `UNUSEDSIGNAL` 告警；项目级 lint 当前统一 `-Wno-UNUSEDSIGNAL`。后续可继续按函数入参切片或显式 unused 聚合清理。
- `OooFetchAxiBridge` 与 `OooMemAxiBridge` 仍是较重的 page-walk owner；更大的 PPA 收敛应继续评估 page-walk helper 复用、TLB/SRAM macro 化和 response ownership 队列化。

