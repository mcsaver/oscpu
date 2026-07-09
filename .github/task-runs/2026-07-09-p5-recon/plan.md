全部输入已核实(治理 spec、STA top10 全文、OooIntBackend ready 链、IQ bypass/select、DispatchBackend ready、PRF、桥 req 口、timing-dispatch-issue-path.md 历史实验)。以下为决策材料。

# P5 第一刀候选切点决策材料(不实施)

## 0. 路径解剖(STA 实测 + RTL 锚点)

20ns/240 级路径 = **dispatch→issue→AGU→SQ-CAM→mem_can_fire→桥→dcache SRAM addr 单拍全组合贯通**:

| 段 | 时间 | RTL 锚点 |
|---|---|---|
| 顶层宽比较树 | 0–3.4 | 起点 FF _121587_,mangled 名无法确证归属(顶层未 keep 区=glue/ControlPlane/CsrFile 之一)——**不确定性①** |
| frontend | 3.4–4.1 | dispatch valid/payload 通路 |
| int_backend 主体 | 4.1–9.3 | rename/busytable 活值→`dispatch*_src*_ready` 比较树(IQ.v:411-435 bypass 用),含 8 级 BUF 高扇出链(8.0–8.7) |
| issue_queue | 9.3–10.4 | bypass select + issue payload mux(IQ.v:436-630,636-679) |
| int_backend | 10.4–11.4 | 10 级 BUFX7=issue0 payload 广播(去 PRF/ALU/AGU/SQ/muldiv) |
| int_backend | 11.4–17.0 | PRF 读(:512,含写透)→AGU(`issue0_mem_addr_w` :789-807)→MMIO 判定(:1084)→SQ CAM(:1273-1290)+MIQ probe(:1506-1527)→`mem_order_ready/can_fire`(:1571-1607)→req mux(:1889-1902) |
| mem_bridge | 17.0–19.8 | `mem0_req_ready_o`(:311 组合)+dcache 发射拍 lookup(:390-418)→SRAM addr |

**评估前提的 4 个关键事实**:
1. **本核唤醒在 wb 拍而非 select 拍**(IQ wakeup 接 `wb0/wb1_valid_i`,DispatchBackend:435-438;wb0=ex0_q 寄存优先,IntBackend:2296),且 **PRF 有同拍写透**(OooPhysRegFile.v:51-53)→ 今天背靠背相关 ALU 启动间隔=1 拍(issue 拍即 EX 拍)。
2. **dispatch 侧 ready 已计数化解耦**(DispatchBackend:307-322 注释实锤:容量计数生成,不反喂组合环)→ C 刀在 dispatch 侧**已经做过了**,残余反压环只在 issue 侧(`issue1_valid_o` 组合消费 `issue0_fire_w`,IQ:682;count/压缩次态消费双 fire)。
3. **B 刀有完整历史实测**:timing-dispatch-issue-path.md §6c,B-cut-1(全禁 dispatch→issue bypass)= 级数 39→24(−38%)、logic delay −54%、**CPI +5.5%**(1.2647→1.3340);当年不 ship 唯一理由"routed Fmax 不可验"——**yosys-sta 全核流程现已存在,重启条件①实质满足**。
4. **A 刀有 P2 先例**:FP 侧 exec1 已是 Issue→EX PipeStageReg(kill 年龄比较留使用方)。

## A. Issue→RegRead/EX 打拍

- **唤醒时序**:裸打拍后 wb 晚 1 拍 → 相关链启动间隔 1→2 拍,依赖密集负载重伤(未实测,参照 B-cut-1 仅去 bypass 就 +5.5%,估 +15~30%,**需实验**)。标准解法在本核有特殊利好:从 issue-reg(EX 拍)广播 ALU 类 pdest 是**确定性早唤醒而非投机**——EX 恒 1 拍、ex_q down_ready≡1(P1 已实锤 ROB wb 口恒收)、wb0 mux ex 恒占先 → 无需 replay;数据传递由 PRF 写透现成覆盖。mem/muldiv 保持 rsp/resp 拍唤醒。
- **kill 窗口移动面**:issue-reg 成新 kill 点(需 age 比较,FP exec1 模板);相关性保证安全(消费者必比生产者年轻,kill 生产者必同时 kill 消费者)。**真雷在 mem 类**:队头独占谓词(MMIO/AMO/SC/probe-block)依赖 EX 拍才算出的地址,select 拍不可知;不能 fire 的 mem uop 驻留 issue-reg 会堵死唯一 store 端口(issue0)→ 更老 store 发不出=死锁(队头序安全家族,雷区 §7.2 直接命中)。正确形态=AGU 拍后进 LSQ/MIQ 自主重试,**A 完整形态绑定 mem-lsq.md 战役**。
- **规模**:IQ 端口+2×issue-reg+双源唤醒+issue_ready 拆分+mem 重试机制,~千行级、数周,雷区 1/2/4 全踩。
- **收益**:切点在 10.4ns 处。头=FF→select→reg≈10.5ns(**仍超 10ns**,因头段自己就 10.4),尾≈9.6ns。单独做勉强不达标,且不砍头段。

## B. Dispatch→IQ/ROB 写打拍

- **本质澄清**:IQ 阵列本身就是寄存,dispatch 当拍写阵列、次拍可选=已是"打拍"。B 的正确形态=**B-cut-1(删 bypass)**,无需新增 PipeStageReg;"寄存 rename 结果再喂 bypass"的变体 select 同样落在 N+1 拍,IPC 与 B-cut-1 完全相同而逻辑更多,被支配,弃。ROB/SQ/busytable/rename map 写全不动(避免"寄存后 kill 时 rename 副作用无 ROB walk 项可恢复"的深坑)。
- **对 bypass 的影响**:整族删除(IQ:274-320 函数、:336-435 allowed/entry_ready、:525-629 虚拟队尾臂、:636-679 payload 直通臂)。
- **IPC**:**+5.5% 已实测**(集中在依赖密集 ALU 环:wanshu +39%/select-sort +36%;branch-resolve-loop 访存受限几乎不变)。但 06-28 数据基于老核(F2/SQ/FP 大改前),**需重测——不确定性②**。
- **规模**:IQ 删 ~250-300 行+tb_ooo_int_issue_queue 契约重写(断言新时序,不可弱化)。1-2 天。风险最低(纯删除)。
- **收益**:砍掉 0–9.3 全部头段(顶层树+frontend+busytable 比较树+8 级 BUF 链随 fan-in 消失)。新周期≈wakeup-CAM+16 项老优先 scan(~2.5)+广播(~1)+PRF/AGU/SQ/can_fire(5.6)+桥(2.8)≈**12ns→~83MHz,WNS -10.3→约 -2**。单独不达 100MHz。

## C. ready 反压链 skid-buffer 化(只切控制环)

- **现状**:dispatch 侧已解耦(事实 2);issue 侧反压环(`issue1_valid←issue0_fire`、count 次态)的终点是 IQ 内部寄存器——**top10 路径全部终点是 dcache SRAM(前向路径),反压环一条未上榜**。
- **收益**:对当前 WNS ≈ 0。两段 BUF 链都是前向广播(dispatch 比较树扇出/issue payload 扇出),不是 ready 网络,skid 化不消除它们。
- **IPC/风险**:通用 skid 让不能 fire 的 mem uop 停车在缓冲=与 A 相同的队头死锁家族;若只对非 mem 类 skid,则关键路径(mem 类)原封不动。
- **规模**:~200 行,但**当前做是白刀**。正确定位=B/桥刀落地后若反压环在新 top10 上位,再作为收尾刀。

## 推荐:组合刀 B + M(桥侧访存请求打拍),C 缓做,A 并入 LSQ 战役

B 砍头(0–9.3),但尾段(select→AGU→SQ→桥→SRAM≈12ns)仍超。三候选之外必须点名第四刀 **M:桥侧 req/dcache lookup 打拍**(mem_req 在桥内先寄存、dcache lookup 次拍,load hit 2→3 拍)——它与 Issue/Dispatch 正交、不触 IQ 调度器、kill 语义清晰(寄存站=未发 AXI 事务,可清;已发只能 drain 铁律不动)。B+M 后该家族≈max(9.3 头段前推残余, 2.5+1+5.6≈9.1, 桥内寄存→SRAM≈3)≈**9.3ns,~105MHz**。A 的"确定性早唤醒"洞察保留为 LSQ 战役的设计输入。

### 六类契约草案(B+M 组合刀)

1. **握手**:dispatch→IQ 保持容量计数 ready(现状,不反喂);IQ issue 口 valid 仅由**已寄存**阵列项+已寄存唤醒源(wb/resp 寄存)生成,当拍 dispatch 项不参与 select——"dispatch fire 与 issue fire 同拍组合无依赖"成为可断言不变量(新增 IQ-NO-BYPASS 立即断言:`issue*_valid → !issue*_dispatch*` 结构性成立后此断言退化为编译期事实,改为断言 select 源恒为 valid_q 项)。桥口:core→桥 req 握手不变;桥内新增 req 寄存站,`mem0_req_ready_o = !req_stage_valid_q || stage_advance`,ready 不再当拍依赖 dcache 判决态(`dcache_rmw_busy_w` 移到寄存站推进条件)。
2. **stall**:IQ select 结果非承诺(ready=0 下拍全量重算,无副作用——现状语义保留);桥寄存站 stall 时整拍冻结(PSR-HOLD 型断言);issue 拍不再依赖桥当拍 ready 的组合细节,`mem_can_fire` 中 `mem_req_ready_i` 项语义变为"寄存站有空位"。
3. **flush**:IQ flush/recover/kill 拍压 issue valid(现状 :635,682 保留);**kill 窗口核对义务(雷区 §7.1)**:删 bypass 后"当拍 dispatch 写入+同拍 kill 边沿"的新写项必须被 IQ kill younger-后缀清除覆盖(现状由 bypass 的 kill_valid_i 压 valid 兜住,删后需核对阵列写入臂——实施步骤 S2 强制核对项);桥寄存站 flush 清 valid、payload 留脏(全核惯例),**nokill 事务(sq drain)在寄存站也不可清**——寄存站需透传 nokill 属性并豁免 flush。
4. **异常序**:不变。异常仍 EX/issue 拍判定、ROB 单一真源承载;B 删的 bypass 不承载异常;M 刀不改异常判定时点(misaligned/xpage 在 req 前已判)。
5. **访存序**:`mem_order_ready`/SQ CAM/MIQ probe 判定拍不动(仍 issue 拍);M 刀移动的是"桥收下"时点→**MIQ push 时点契约**:push 仍与 req fire 同拍(:1924-1973),fire 定义改为"进入寄存站"——序记账以寄存站接纳序为准,寄存站 FIFO 序=AXI 发出序(单深度平凡成立),AMO/drain 独占谓词(`mem_idle_o` :1104)须把寄存站占用计入 pending(否则 mem_quiet 类中间态死锁家族复发,serialize-at-retire 教训)。
6. **投机恢复/单一真源**:rob_idx 年龄比较留使用方(PipeStageReg 契约 §3⑥);删 bypass 后 pred_npc 恒取 pred_npc_q(:642-645 注释的 loop-free 性质由结构保证,注释可简化);select 唯一真源=阵列+寄存唤醒,dispatch 活值退出 select 锥。

### 分阶段实施

- **S0(实验先行,不动刀)**:重测 B-cut-1 CPI(现核,CoreMark 10 迭代+eval 加权;可用 ace-sim 先建模 load hit +1 拍的 M 刀 CPI);同时用 keep_hierarchy STA 确认顶层 0-3.4 比较树归属(不确定性①)。
- **S1(刀 B)**:删 IQ bypass 族→TB 契约重写→kill 窗口核对(§3 契约 3)→focused TB+module TB 86+lint+check-contract。
- **S2**:yosys-sta 全核重跑,拿 B 后新 top10(验证 12ns 预估,决定 M 刀优先级)。
- **S3(刀 M,独立 spec)**:桥内 req 寄存站+MIQ 时点+nokill/AMO 独占审查+dcache spec 同步;大节点 tohost(riscv 177+AM+CoreMark+linux-mini)。
- **S4**:再跑 STA;若反压环上榜再立 C 刀。全状态 difftest 按既定策略留重构整体收口。
- **远期**:A 完整形态(issue-reg+确定性早唤醒+LSQ 自主发射)并入 mem-lsq 战役 spec。

### 验证链

每刀:focused TB→全量 module TB(86)→lint 双变体→check-contract 计数不降→大节点 tohost 回归→yosys-sta WNS 对比(cycle-exact 禁用,拍数必变,雷区 §7.3)。负测试:B 刀故意保留一条 bypass 臂应使 IQ-NO-BYPASS 型断言 fire。

### 不确定性(需实验数据)

①顶层 0-3.4ns 树归属未确证,若与 dispatch 无关则 B 后它仍在别处;②+5.5% CPI 是老核数据,现核需重测;③B 后 12ns 是分段线性外推,ABC 重综合会重构(BUF 链缩短方向有利),真值以 S2 为准;④M 刀 load hit +1 拍 CPI 未测(估 +3~8%);⑤达成 100MHz 后 FpBackend(ABC delay 90)/FetchAxiBridge(50)将成新瓶颈,P5 不治它们;⑥A 的"确定性早唤醒"论断依赖 wb0 口 ex 恒占先,若未来 wb 仲裁语义变化则失效。

相关文件:`/home/lyg/PA/ysyx-workbench/npc/rv64/build/sta/NpcTop-100MHz/NpcTop.opensta.rpt`、`/home/lyg/PA/ysyx-workbench/npc/rv64/design/arch/pipeline-stage-boundary.md`、`/home/lyg/PA/ysyx-workbench/npc/rv64/design/arch/timing-dispatch-issue-path.md`(§6c 重启条件)、`/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v`(:274-679 bypass 族)、`/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v`(:1571-1667 ready 锥,:1889-1902 req mux)、`/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v`(:307-322 计数化 ready)、`/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v`(:296-418 req/lookup)。