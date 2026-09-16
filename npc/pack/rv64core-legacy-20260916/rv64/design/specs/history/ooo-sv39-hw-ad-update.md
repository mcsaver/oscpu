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

## §4 实现设计（取指侧，后做）—— 已落地 2026-07-06
- `exec_permission_fault` 去 `!pte[6]`; 加 `exec_ad_update_needed = !pte[6]`（取指只置 A）。
- OooFetchAxiBridge 加最小 AXI 写通道(AW/W/B) + `S_AD_UPDATE` 态 + 写输出，A=0 时写 `PTE|(1<<6)`。
- plumb `ifu_axi_aw/w/b` 到 `NpcCoreTop → NpcTop → NpcAxiBus`，xbar 接 IFU 写口(现只接 IFU 读口)。
- **★方案差异（取指侧比数据侧简单）**: 取指侧用 **re-walk** 而非续流复制——leaf-OK 但 A=0
  → 锁 `ad_pte_q=pte|A` → `S_AD_UPDATE` 写 `walk_pte_addr_w`(组合 off walk_ppn_q/level, 写期间
  仍有效) → 等 B → **回 `S_WALK_AR` 重走当前级**(walk_ppn_q/level 不变 → 重读同一 leaf PTE, 此时
  A=1 → 走正常 leaf-OK 续流)。零续流复制、无死循环。
- **TLB 永不缓存 A=0**: `itlb_fill_valid_w` 加 `&& !exec_ad_update_needed`, 首遍 A=0 不填、re-walk 后
  A=1 才填 → TLB 命中路径无需 A 门控(对比数据侧因 D 位需 TLB-hit ad_needed 门控)。
- **bresp 错误处理**: A 写 B 若非 OK → 取指 access fault(避免 A=0 无限重试)。
- **flush 期丢写**: mmu_flush 打回 S_IDLE 丢写, 对取指侧**正确**(A 更新是优化, re-fetch 幂等重做);
  PTE 恒落 always-ready PMEM, AW/W 同拍握手无 split-window, 不需数据侧的 write-drain 机制。
- **总线**: xbar 本就读+写全功能(`m_awvalid_i`/`wr_master_busy_q`), M_IFU=0 已是 master, NpcAxiBus
  原把 M_IFU 写口恒接 0 → 改接真信号即可(无需改 xbar 仲裁)。

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
- [x] **取指侧新写通道 + 总线 plumbing**（2026-07-06 落地并验证）
      - 4 文件: OooFetchAxiBridge(re-walk 方案 + AW/W/B + S_AD_UPDATE + fault 拆分 + itlb A 门控 +
        bresp 错误处理) / NpcCoreTop / NpcTop / NpcAxiBus(接 M_IFU 写 master 口)。
      - **★验证网抓 TB 契约漂移**: core-regress 的 module-testbench 抓到**两个** TB 编码旧 SW-managed
        契约: (1) `tb_ooo_fetch_axi_bridge` "user fetch A=0 → page fault"; (2) `tb_ooo_mem_axi_bridge`
        "A=0 load/D=0 store → page fault"(**后者是上一会话数据侧落地时遗留未改**——当时验证未含
        module-testbench)。均改写为 HW-managed 更新期望(取指=A 更新写+re-walk; 数据=A/D 更新写+续流,
        且用独立数据地址 0x8000_a000 避免 store 污染物理 dcache 干扰后续 dtlb 测试)。
      - **验证全绿**: core-regress overall_rc=0 —— riscv 153/0 + am-cpu-tests PASS + module-testbench
        82/82(两桥 TB 双绿) + lint 0 警告。
      - ★教训: RTL 契约变更必须同步更新编码旧契约的模块 TB, 且**验证须含 module-testbench**(否则如
        数据侧那样带 TB 回归静默落地)。
- [x] **OooAdUpdateChecker 观测层守护(数据+取指双桥)**（2026-07-06 落地并验证）
      - 通用单桥 checker(`vsrc/debug/OooAdUpdateChecker.sv`), NpcSimTop XMR 双实例化(取指 ALLOW_D=0 /
        数据 ALLOW_D=1), filelist.mk 登记进 SIM_TOP_SRCS(DCE 零面积)。5 不变量: 写地址==walk_pte_addr /
        ad_pte^orig 只改 bit6/7 / A 位必置 / 取指绝不改 D / wstrb 全置。orig leaf PTE 由观测 S_WALK_R 末拍
        rdata 锁存。断言 `$error`+`$fatal`(对齐 redirect checker 风格)。
      - **★非真空已验**(sv39-ad-bits, 临时探针): 两桥**双双命中**真实 A/D 更新且全不变量成立——
        取指桥 orig=..000f(A=0)→ad_pte=..004f(仅+A), awaddr==walk_pte_addr=0x80001010;
        数据桥 orig=..004f(D=0)→ad_pte=..00cf(仅+D), awaddr==walk_pte_addr=0x80001ff0。
        **证明取指侧 inst A=0 更新确被 sv39-ad-bits 行使**(非假想路径)。
      - **验证全绿**: core-regress overall_rc=0(checker 激活下 153/0 + AM + module TB 全静默) + lint 0 警告。
- [x] **NEMU difftest 验 A/D 对齐**（2026-07-06 验证）
      - 流程: 备份 NPC 三件套(.config/auto.conf/autoconf.h)+NEMU .config → `make difftest-ref`(建 NEMU
        参考 .so, GUEST_ISA=riscv64 含 SoftFloat) → sed CONFIG_NPC_DIFFTEST=y + `conf --syncconfig`(三处一致)
        → 构建 NPC difftest 版 → 跑 workload → 恢复全部配置。
      - **★A/D 对齐成功**: `sv39-ad-bits`(A/D 专测) difftest **HIT GOOD TRAP + 全程锁步无 mismatch** ——
        NPC HW-managed A/D 与 NEMU 一致(无 PC/GPR 发散)。旁证 `sv39-ras-relocate` + 5 个 compute 测试
        (add/mul-longlong/bubble-sort/fib/dummy)均 difftest 锁步。
      - **out-of-scope 发现(非 A/D, 记录不修)**: `sv39-xpage-misalign` difftest 发散 —— control-flow
        mismatch(NPC 提交 trap 处理器 pc=0x80000010 读 mcause=6, NEMU 期望顺序 pc=0x80000084)。根因 =
        **misaligned 普通访存策略差**: NPC 硬件对 misaligned load/store 取 fault(cause 4/6, spec 允许),
        NEMU 只对 AMO 查对齐(amo.c), 普通访存 misaligned 透明处理不 fault。与 A/D 无关(A/D 是 page-fault
        cause 13/15)。属后续 step 4 全状态 difftest 扩展要处理的 misalign 策略对齐范畴, 非本 spec。

## §8 结论
本 spec 全部完成(数据侧 + 取指侧 + 观测层 checker + NEMU difftest 验证)。NPC Sv39 A/D 从 SW-managed
(缺失即 page fault)全面改为 HW-managed(Svadu, 任意访问 HW 置位), **与 NEMU 语义对齐**。A/D 路径不再是
NPC↔NEMU difftest 的发散源。归档条件已满足(可迁 `design/specs/history/`)。
