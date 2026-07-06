# Sv39 HW-managed A/D 更新实现规格（SW→HW，对齐 NEMU）

> **类型**: plan（实施计划）。**归宿**: 落地并验证后归档至 `design/specs/history/`。
> **缘起**: 主线 CSR/FPR difftest 前置——NPC 现为 SW-managed A/D（非 Svadu，A/D 缺失即 page fault），
> NEMU 为 HW-managed（任意访问 HW 置 A/D）。二者在 Sv39 A/D 路径**发散**，阻碍全状态 difftest。
> 本规格把 NPC 改为 HW-managed 以对齐 NEMU。**2026-07-06 冻结，写 RTL 前的 interface-contract-first 强制产物。**

## §1 现状（勘察真源）
- **数据侧** `memory/OooMemAxiBridge.v`：A/D fault 在 `data_permission_fault`（:224-236）的
  `!pte[6] || (write_access && !pte[7])`。walker FSM（`state_q`，:536 主 always）：
  `S_IDLE/S_WALK_AR(1)/S_WALK_R(2)/S_READ_ADDR(3)/S_READ_DATA(4)/S_WRITE_REQ(5)/S_WRITE_RESP(6)/S_RESP(7)`。
  **已有 AXI 写路径**（AW/W/B 服务 data store）。leaf 处理在 S_WALK_R（:659-711）。TLB fill = `dtlb_fill_valid_w`（:327）。
- **取指侧** `frontend/OooFetchAxiBridge.v`（757 行）：A fault 在 `exec_permission_fault`（:157）的 `!pte[6]`。
  **只有 AR/R（只读，无 AW/W/B）** —— 需新加 AXI 写通道 + IFU 总线 plumbing（用户 2026-07-06 定此方案）。

## §2 契约（HW A/D 更新语义）
- **触发**: leaf PTE 真权限全通过（R/W/X、U/S、MXR/SUM、非 invalid、非 reserved、PTE 读 PMP 过）
  但 `A=0`（任意访问）或 `D=0`（store/AMO）→ **不 fault，改更新**。
- **写什么**: `PTE | (1<<6) | (write ? (1<<7) : 0)` 写回**本级 leaf PTE 物理地址**（`walk_pte_addr`），
  8 字节全写、**非原子简单写**（对齐 NEMU；NEMU 用 dcache_coherent_write 简单写，非 RMW）。
- **保留真 fault**: R/W/X 违规、U/S 违规、invalid、reserved、superpage misaligned、PTE 读/leaf 的 PMP —— 仍 fault。
- **TLB**: 更新后 TLB 缓存**置位后的 PTE**（A/D=1），后续命中不再 fault/update。
- **PMP**: A/D 写 PTE 地址须过 PMP（8B 写，用被翻译访问的 priv，与 PTE 读的 `walk_pte_pmp_checker` 对称）。
- **不改**: PTE 其它位、其它 PTE、非 leaf 级 PTE。

## §3 实现设计（数据侧，先做）
**新增**: 状态 `S_AD_UPDATE = 4'd8`；reg `ad_pte_q`（置位后 PTE）。walk_pte_addr 在 walk 态稳定可复用。

**fault 拆分**（`data_permission_fault` → 两组件）:
- `data_perm_fault_real(pte,write,priv,status)` = `(write?!pte[2]:!data_read_ok) || !data_user_ok`（去 A/D）。
- `data_ad_update_needed(pte,write)` = `!pte[6] || (write && !pte[7])`。
- 三处消费改用组件: S_WALK_R fault(:675) 用 real; `dtlb_fill_valid_w`(:334) / `req_dtlb_perm_fault_w`(:298) 见下。

**S_WALK_R leaf-OK 分支**(:684) 增判: 若 `data_ad_update_needed` →
`ad_pte_q <= pte|(1<<6)|(write_q?(1<<7):0)`; `paddr_q <= walk_leaf_paddr_w`; → `S_AD_UPDATE`。否则原样。

**S_AD_UPDATE**: AXI 写 `awaddr=walk_pte_addr, wdata=ad_pte_q, wstrb=all` → AW+W done → 等 B →
bresp OK 后**用 ad_pte_q 填 TLB** + 接**续流**（复用 leaf-OK 的 probe 短路/dcache 命中/read/write 决策）。

**5 个坑的处置**:
1. **续流去重**: 抽 leaf-OK 决策为共享逻辑（或 S_AD_UPDATE 完成拍内联同一决策），避免复制。
2. **TLB fill 时机**: `dtlb_fill_valid_w` 拆两触发——无更新走 S_WALK_R(原始 PTE)、有更新走 S_AD_UPDATE 完成(ad_pte_q)。
3. **probe/pretrans**: pretrans 跳翻译无 walk→无 A/D; probe-store 走 walk write→置 A+D 后短路返 PA; load→置 A。
4. **flush-during-write**: S_AD_UPDATE 的 AXI 写在飞不可撤——按 nokill 语义处理(写必达/免 kill)，flush 后 re-exec 会重走(幂等: 再置 A/D 无害)。
5. **AXI 写输出 mux**: `awaddr/wdata/wstrb` 在 `S_AD_UPDATE` 选 PTE 地址/ad_pte_q/全 8B，`S_WRITE_REQ` 选 store 值。

## §4 实现设计（取指侧，后做）
- `exec_permission_fault` 去 `!pte[6]`; 加 `exec_ad_update_needed = !pte[6]`（取指只置 A）。
- OooFetchAxiBridge 加最小 AXI 写通道(AW/W/B) + `S_AD_UPDATE` 态 + 写输出，A=0 时写 `PTE|(1<<6)`。
- plumb `ifu_axi_aw/w/b` 到 `NpcCoreTop → NpcAxiBus`，xbar 接 IFU 写口(现只接 IFU 读口)。

## §5 观测层守护（vsrc/debug/，用三层观测方法学）
`OooAdUpdateChecker.sv`（挂 SIM_TOP，XMR 订阅两桥的 S_AD_UPDATE + PTE 信号）断言:
- A/D 更新只在 leaf 且真权限通过时发生（`data_perm_fault_real==0`）；
- 写地址 == 本级 `walk_pte_addr`；写数据只置 A(D)位、其余位 == 原 PTE（`ad_pte ^ orig_pte` 只可能是 bit6/bit7）；
- 真 fault（perm_real/invalid/reserved/pmp）仍导致 page/access fault（不被 A/D 更新吞掉）。

## §6 验证
- `sv39-ad-bits`（AM，专测 A/D）+ `sv39-xpage-misalign`/`sv39-ras-relocate`；
- **NEMU difftest**：A/D 对齐后 Sv39 路径应不再发散（这正是本步目的）——`am-kernels/rv64dv` 或 core difftest；
- riscv-tests 355/0 + AM 59/0 恒静默 + 观测层 checker 恒静默 + 每断言非真空。
- 每步差分回归数字不变（幂等性: 重执行 A/D 更新无害）。

## §7 状态
- [x] **数据侧 S_AD_UPDATE + fault 拆分 + TLB fill 时机 + dcache coherence**（2026-07-06 落地并验证）
      - 8 处 edit: fault 拆分(`data_permission_fault` 去 A/D + `data_ad_update_needed`) / TLB-hit ad_needed 门控 /
        S_AD_UPDATE 态 + ad_pte_q reg / dtlb_fill 双触发(walk 原始 / ad 置位) / AXI 写输出 mux / S_WALK_R leaf 分支 /
        FSM 双分支(flush 写必达 + normal B 后续访问) / **★dcache coherence(PTE 写回维护 dcache)**。
      - **★验证网抓 bug**: 初版 rv64si-p-dirty FAIL —— 根因 = A/D 写 PTE 到内存但测试读 PTE(当数据)命中 stale dcache;
        补 dcache 维护(对齐 NEMU dcache_coherent_write)后过。
      - **验证全绿**: riscv 355/0(含 rv64si-p-dirty D 位) + AM 59/0(含 sv39-ad-bits) + 观测层 checker 恒静默 + CPI 1.2638 不变。
      - 第 6 个坑(施工中新发现): TLB-hit ad_needed(load 填的 A=1/D=0 项被 store 命中)→ 视为 miss 走 walk 更新。
- [ ] 取指侧新写通道 + 总线 plumbing
- [ ] OooAdUpdateChecker 观测层守护(数据+取指双桥)
- [ ] NEMU difftest 验 A/D 对齐(需 DIFFTEST=y + NEMU ref)
