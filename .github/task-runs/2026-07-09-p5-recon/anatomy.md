归属分析完成。以下为紧凑报告。

---

## 关键路径 RTL 归属(WNS -10.31ns,19.8ns/240 级)

**结论先行:top10 全是同一条路径**(同起点 `_121587_`、同终点 dcache SRAM,slack -10.27~-10.31),仅最后 2–3 个 cell 分岔到 SRAM 不同引脚(path1→`addr_i[8]`、path2→`en_i`、path4→`addr_i[6]`)。这是一条把 **PLIC 中断判定→前端 dispatch→分支解析→写回仲裁→唤醒→发射→PRF 读→旁路→mem 地址 mux→DTLB→dcache 索引** 全部塞进一拍的巨型组合锥,跨 5 个 keep 边界、串联约 7 个架构决策。

### 分段归属(证据 = 网表 net/port 名 + RTL 行号)

**① 0–3.4ns 顶层扁平区 = PLIC 优先级比较森林**
- 起点 `_121587_/Q = u_plic_axi.threshold_m_q[28]`(`vsrc/bus/AxiLitePlic.v:57`,M 态阈值寄存器)。
- 宽比较树 = `AxiLitePlic.v:163` 每源 `priority_q[i] > threshold_m_q` 的 32 位幅值比较 ×32 源 + claim 最大优先级归约(证据:`_065581_.B=priority_q[10][28]`、`_074089_.A=priority_q[31][29]`)。
- → meip → `NpcCoreTop.v:416` CsrFile 组合 `irq_pending_o`(`CsrFile.v:625`)→ `_087745_/Y = u_core.ooo_csr_irq_pending_w`。

**② 3.4–4.1ns frontend:irq 门控→ret 点火→next-PC**
- 入口 port `csr_irq_pending_w`(`OooFrontend.v:35`)。`_13344_` NAND4B(AN=csr_irq_pending_w, D=run_i)= dispatch 许可门;`_13353_` 混入 `head0_arch_trap_raw_w`;`_13581_/Y = direct_ret1_fire_w`(lane1 直接返回点火,dispatch gate 域)。
- 出口 `_21463_/Y = core_dispatch1_next_pc_w[0]`(ret1_fire 选择返回目标 vs 顺序 PC 的 mux,`OooFrontend.v:1845` u_frontend_dispatch_gate 输出)。

**③ 4.1–4.24ns issue_queue 直通**:`dispatch1_next_pc_i[0]` →2 级 OAI21(dispatch→issue **旁路直通 mux**)→ `issue1_next_pc_o[0]`。前端锥因此直接串进后端锥。

**④ 4.24–9.3ns int_backend:误预测比较→写回口仲裁级联(串行 4 连跳)**
- `_131370_` XNOR(`issue1_next_pc_w[0]`) + `_131753_`(`issue1_pred_npc_w[62]`)+ 归约树 = **全宽 next_pc vs pred_npc 误预测比较器**(4.4–5.1)。
- → `_144644_`(`branch_resolve_mispredict_o`)→ `_144647_/Z=muldiv_rsp_to_wb0_w`(5.4)→ `_094344_/Y=execute1_valid_o`(5.8,混 `fpwb_valid_w`)→ 途经 `_101567_` XOR `reservation_addr_q[63]`(SC 保留地址比较参与仲裁锥)、`_116224_`(`issue0_ready_w`)→ `_145244_/Y=branch_resolve_pick1_w`(7.3)→ `_144671_/Z=clmul_rsp_to_wb0_w`(8.0)。
- **BUF 链#1(8.08–8.70,_094323_.._094628_ 约 7 级)= `clmul_rsp_to_wb0_w` 高扇出**:该 grant 门控整个 wb0 payload mux,且串行喂 `_144672_/Z=clmul_rsp_to_wb1_w`(wb0→wb1 仲裁串行依赖)→ `_094398_`(`fpwb_pdest_w[4]`)→ `_144674_/Y = u_dispatch_backend.u_busy_table.wakeup1_pdest_i[4]`(9.2)= **唤醒总线 1 的 pdest 标签 mux**。

**⑤ 9.3–10.35ns issue_queue:唤醒 CAM+选择+payload mux**
- `wakeup1_pdest_i[4]` → `_30093_` XNOR vs `src2_preg_q[0][4]`(表项 src2 标签 CAM)→ NAND4 全匹配 + `src2_ready_q[0][0]` → `_30532_/_30538_` 请求/选择树 → `_34940_/Y = issue0_src2_preg_o[2]`(被选表项的 src2 物理寄存器号)。

**⑥ 10.35–13.9ns:PRF 读+旁路**
- **BUF 链#2(10.35–11.43,_094784_.._144772_ 共 12 级 BUFX7)= `issue0_src2_preg_w[2]`**,即 PRF 读地址位,扇出到 64 位读 mux 树。
- `_144922_` AOI22(`u_phys_reg_file.regs_q[1][1]`)→ `_144929_/Y=issue0_src2_data_w[1]`(11.9)→ 又一段 BUF(_101004_..)→ `_103152_` XOR `reservation_addr_q[49]`+`_104632_` 归约(SC 保留地址第二次比较)→ BUFX16/12 → `issue1_src2_value_w[0]`(13.9,旁路后 lane1 操作数)。

**⑦ 13.9–17.0ns:mem 发射判定锥+地址优先 mux**
- 宽归约(`_134391_` NOR4X6/AND4 群,14.9–15.7)+ XOR/进位段(`_140511_`)= 发射有效/地址选择判定;`_146573_`(A0=`sq_drain_addr_w[14]`)→ `_146578_/Y = mem_req_addr_o[14]`(17.0)。对应 `OooIntBackend.v:1897` 的 5 路优先 mux(amo/buffer/issue0/issue1/**sq_drain**),**晚到的是 select 端**。

**⑧ 17.0–19.8ns mem_bridge:DTLB→dcache 索引**
- 入口 `mem0_req_addr_i[14]` → BUF 脊柱 → `_098509_`(`u_dtlb.level_q[45][1]`)+XNOR/AND4/OR4 = **DTLB VPN CAM 匹配/级别选择**(17.4–18.2)→ PPN/命中选择 → 第二段归约(_112220_.._115966_)→ `_116238_` MUX2(S0 经 BUFX20 高扇出)= `OooMemAxiBridge.v:415` `dcache_lookup_addr_w = req_read_lookup_fire ? req_cache_addr : walk ? walk_leaf_paddr : paddr_q` → `dcache_lookup_addr_w[11]` → `_118031_` → `u_dcache.sram_addr_w[8]` → SRAM `addr_i[8]`(4096 深,11-3=8 ✓ 索引位映射)。

### 治理切点建议(P5 重新流水化候选,按性价比排序)
1. **PLIC meip 出口打一拍**(中断语义本就允许异拍):白送 3.4ns,最便宜。
2. `csr_irq_pending → frontend 门控` 再打一拍可另省 ~0.7ns(与 1 叠加需看新头)。
3. **wb 仲裁→wakeup pdest 切拍**(唤醒提前一拍 vs 数据,或 select/payload 分离):斩断 ④→⑤ 的 5ns 串行级联。
4. **issue→PRF 读→旁路→AGU→dcache lookup** 当前全组合(⑤–⑧ 共 ~10.5ns),是经典 2–3 级流水段。
5. IQ 的 dispatch→issue 旁路直通(③)使前后端锥缝合,若切流水应一并评估。

关键文件:报告 `/home/lyg/PA/ysyx-workbench/npc/rv64/build/sta/NpcTop-100MHz/NpcTop.opensta.rpt`、网表 `NpcTop.netlist.v`(NpcTop 区 1669412–2151915 行,int_backend 665639–,issue_queue 3–,frontend 1397169–,mem_bridge 2901560–)、RTL:`vsrc/bus/AxiLitePlic.v:163`、`vsrc/core/CsrFile.v:625`、`vsrc/frontend/OooFrontend.v:1677,1845`、`vsrc/execute/OooIntBackend.v:1897`、`vsrc/memory/OooMemAxiBridge.v:415`。