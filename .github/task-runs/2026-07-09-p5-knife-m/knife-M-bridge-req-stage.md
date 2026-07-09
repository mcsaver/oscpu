# P5 刀 M:桥侧 req 寄存站(2026-07-09)

> spec:`npc/rv64/design/arch/p5-repipeline-first-batch.md` §2(落地记录已同步);
> 权威契约:侦查报告(行号级实施契约,原文见任务下发;上游草案 `../2026-07-09-p5-recon/plan.md`)。
> 执行:子代理(刀 M)。桥 spec `design/specs/ooo-mem-axi-bridge-fsm.md` §2/§3/§5/变更记录已更新。

## 1. 实施内容(契约逐条)

- **寄存站(§1)**:`OooMemAxiBridge.v` 新增 `stg_{valid,addr,wdata,wstrb,write,probe,pretrans,nokill}_q`
  8 字段(~139 FF)。req fire 拍**零计算**只锁存字段(core 侧 req mux 组合、次拍消失,必须当拍接住);
  翻译(DTLB CAM :430-431 换源)/PMP(:447)/dcache 组合口(:488-489)/lookup 发射(`req_read_lookup_fire_w`
  改 `stage_advance_w` 门)/全部分流决策(accept_request)整体迁 advance 拍。CSR 上下文不进站
  (serialize-at-retire 论证,KM-STG-CTX 断言固化)。
- **ready 重定义(§2)**:`stage_advance_w = stg_valid_q && !rmw_busy && (S_IDLE ||
  (S_RESP && rsp_ready)) && (!cpu_kill || stg_nokill_q)`;
  `mem0_req_ready_o = !flush_i && (!stg_valid_q || stage_advance_w)`。
  `!flush_i` 保留(MIQ else-if flush 分支漏 push→双射铁律);`drop_rsp_q` 退出 ready(免费 skid);
  rmw 迁入 advance。plan-B(`ready=!flush_i && !stg_valid_q`)未启用。
- **MIQ push(§3)**:IntBackend push 逻辑**文本零改动**,fire 语义重释=进寄存站(注释层
  IntBackend :1923 区/MIQ :31 区已改)。序=单深度平凡 FIFO,rsp 配对不破。
- **独占谓词(§4)**:零消费点加 term——寄存站占用⇒MIQ 非空⇒mem_idle=0 自动成立,断言化
  (KM-STG-MIQ)。`mem_idle_for_sc_w` 例外照旧(spec 备注既有语义)。
- **flush/nokill(§5)**:寄存站 flush 臂 `flush_i && !stg_nokill_q → 清`(payload 留脏);
  nokill 项存活且可 flush 拍经 advance 豁免进 FSM(写必达);FSM 内 nokill 语义一字未动。
  accept 调用上提为 stage_advance 最高优先分支(S_IDLE/S_RESP 两臂的 accept 移除,
  依赖"S_IDLE/S_RESP 态 drop_rsp_q 恒 0"不变量,BRG-ADV-NODROP 断言化)。
- **RMW/S_LOOKUP(§6)**:`!rmw_busy` 从 ready 迁 stage_advance,bubble 数不变、观察点变
  寄存站保持;`dcache_lookup_en_w`/arvalid/S_LOOKUP 转移的 `!rmw_busy` 安全网与
  MEM-RMW-PORT 断言全部保留。walk/AD 路发射拍不变;req 路 dcache 发射拍 fire→advance,
  load hit 2→3 拍。

## 2. 断言(全部立即断言形态,桥内 5 条 + 跨模块 2 条)

- 桥内(`OOO_ASSERT`):BRG-NOFIRE-FLUSH / BRG-ADV-NODROP / BRG-STG-LOOKUP / BRG-STG-HOLD
  (PSR-HOLD 型字段冻结) / BRG-STG-NOKILL;MEM-RMW-PORT 保留重验。
- NpcSimTop 跨模块:KM-STG-MIQ(`stg_valid_q ⇒ !miq_empty_w`,mem_quiet 死锁家族守卫+桥/MIQ
  flush 相位双射核对);KM-STG-CTX(站占用期 satp/mstatus/priv/svpbmt 冻结,**pretrans 豁免**
  ——drain 落存 accept 不消费翻译上下文,且 trap 拍其跨 flush 存活属既定语义)。
- NpcSimTop dcache 统计打拍源 `mem0_req_fire_w`→`stage_advance_w`(否则 hit 配对错 1 拍);
  `sim_ooo_mem_busy_w` 采样桶补 `stg_valid_q` 项(FSM idle+站内保持拍不漏计);:1063 事件
  dump 列保留 fire(事件语义仍成立=进站)。TB 静态 check 调用点 147→196(强度不减)。

## 3. 负测试(断言不可弱化证据,fire→复原 0 fire)

| # | 故意破坏 | 结果 | 日志 |
|---|---|---|---|
| 1 | req lookup 加回 fire 拍路径 | TB 锚点 `mem0 read no req lookup at fire` FAIL + `[BRG-STG-LOOKUP]` fatal | `neg1-fire-cycle-lookup-fires.log` |
| 2 | stage_advance 漏 `!rmw_busy`(独占谓词漏计寄存站,模块级) | TB rmw bubble 两检查 FAIL + `[MEM-RMW-PORT]` fatal | `neg2-rmw-predicate-misses-stage-fires.log` |
| 3 | 寄存站 flush 臂连 nokill 一起清 | TB nokill 存活两检查 FAIL + `[BRG-STG-NOKILL]` fatal | `neg3-nokill-flush-cleared-fires.log` |
| 4 | IntBackend MIQ push 漏记 drain(独占谓词漏计寄存站,全核级) | 全核 CoreMark 即时 `[KM-STG-MIQ]` fatal | `neg4-miq-drain-unaccounted-fires.log` |
| — | 全部复原 | 桥 TB PASS、断言 0 fire;全核 CoreMark 0xfcaf 0 fire | `neg-restored-zero-fires.log` / `m5-coremark-knife-m.log` |

## 4. TB 契约重写(不可弱化)

`tb_ooo_mem_axi_bridge.sv`:全量 fire→rsp 对拍 +1(fire/advance/判决三拍口径);
"flush blocks new request"(ready 含 !flush_i)保留;RMW bubble 重述(判决拍 ready 可为 1=进站,
`stage_advance_w`/`req_read_lookup_fire_w` 为观察点,bubble 数不变);drop 窗口 skid 定向
(partial_write_flush_drain 扩展);back-to-back 经寄存站定向(store_rmw 任务重写);新增
`stage_skid_hold_and_flush_semantics`(PSR-HOLD 字段冻结+plain 项 flush 当拍清除 0 副作用+
nokill 项 flush 存活后完成写);负测试锚点(fire 拍 req 源 lookup 恒 0)。
`tb_ooo_data_word_cache`/`OooDataWordCacheChecker.sv` 未动(dcache 两拍协议无变)。

## 5. 竣工验证

| 项 | 结果 | 证据 |
|---|---|---|
| focused TB(tb_ooo_mem_axi_bridge/tb_ooo_int_backend 等) | PASS | `m4-module-tb-full.log` |
| 全量 module TB `make -k run` | **86/86 PASS** | 同上 |
| lint 双变体(默认 / OOO_CSR_QUEUE_HEAD=1) | 双绿 exit=0 | `m4-lint-two-variants.log` |
| check-contract | PASS,断言计数 **29≥20**(刀 B 后 24,+5=BRG 断言族) | `m4-check-contract.log` |
| CoreMark 10 迭代 | **0xfcaf PASS**,cycles=10,555,505 commits=3,218,614 | `m5-coremark-knife-m.log` |
| CPI 对比 | 基线 3.197(10,291,429)→**3.280(+2.57%)**,优于预估 +3~8%,远低 12% 停止线 | 同上 |
| Neg-4 复原交叉验证 | 复原重建 cycles 逐拍一致(10,555,505)+0xfcaf,断言 0 fire | `m5-coremark-restored-final.log` |
| 最终源(含 mem_busy 采样桶补寄存站项)复跑 | 0xfcaf + lint 双变体复绿 | `m5-coremark-final-sources.log` / `m4-lint-two-variants.log` 尾段 |

## 6. 偏差与遗留(如实报)

- **M5 大节点**中 riscv177/AM 全量/linux-mini 与 **M6 全核 yosys-sta WNS 对比**未在本次执行
  (竣工标准 a–e 未含;按"综合驱动重构期 difftest 策略"与 P5 spec §3 留整体收口/另排 STA 批次)。
- 全状态 difftest 按既定策略不做小步验证(用户 07-08 决策)。
- KM-STG-CTX 增加了契约未列的 svpbmt 冻结项(同族 1 bit,加强非弱化);pretrans 豁免为实施期
  补充论证(drain 上下文不敏感+trap 拍存活既定),契约原文未展开——已在 spec §2 寄存站行固化。
- cycle-exact 类比较全程未用(拍数必变,契约明令禁用)。
