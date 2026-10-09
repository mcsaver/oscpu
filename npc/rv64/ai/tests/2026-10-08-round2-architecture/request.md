请作为这个 RV64 项目的主要微架构设计者，深度推导下一轮完整架构优化方案。用户明确要求“网页 Pro 是思考者，Codex 是执行者”，而不是 Codex 先选局部优化再请你审查。本会话新开以减少历史讨论对选型的锚定；下面是独立、自含的已核实事实包，不是预设方案。请用中文回答。你没有本地仓库访问能力，需要信息可提出具体源码/测量请求；Codex 会采集、实现、验证，并在实测推翻前提时回传给你修订架构选择。不要假装已经运行或读取未提供的源码。当前下一轮尚未修改 RTL，也没有预定 CQ 优化为答案。

目标与边界：在现有真实 RV64core 上完成一轮有工程价值的架构优化，改变必要的跨模块结构和事务生命周期，而不是无止境的局部微调；按完整程序周期、真实库面积和同约束布局前 STA 联合评价。每个候选必须保证现有 ISA、精确异常、取消、晚到响应、真实总线握手与完整 NEMU DiffTest/断言。不能通过关闭检查、理想化存储器、SRAM 黑盒、放松时序、删工作负载来制造收益。允许有理有据的有界联合重构，不要求每一个中间提交都独立提高 CPI。不要承诺没有证据的倍数。最终实现频率尚未闭合，不能把负 WNS 直接反算可靠 Fmax。

当前结构（来自本地源码）：
- 双分配、双发射、双写回、双退休；ROB 32、IQ 16、LSQ 20；整数/浮点物理寄存各64；GPR 4、FPR 3 读口；2 ALU、乘除/CLMUL等，9个完成来源竞争2个WB口。
- 分支：256项 bimodal BHT、64项间接目标、8项RAS。错误恢复从最年轻向前每拍回滚2条，恢复期间分配/退休冻结。
- I/D各8KiB两路；Dcache双bank、64B line、write-through。Dcache有一个主要read/refill owner、有条件的hit-under-miss、独立store B-response owner；不是完全非阻塞，也不是所有事务完全串行。
- Store须先取得head/effect许可，退休依赖真实写接受和真实B响应，成功B响应才更新cache；错误要保持精确异常。没有已被证明可合法提前退休的无错 RAM 合同。不能直接把posted store buffer当无条件可用答案。
- LSU包含未确定属性、未绑定/非对齐、原子/IO、翻译与A/D条件造成的序关系限制。普通load可乱序，forward/fault/raw各有独立owner。
- 已有：ALU early wake/bypass、有限RR bypass、LSU WB请求提示、descriptor同边沿接力，以及上一轮成功load response空raw bypass。请不要把这些作为新建议。历史只增IQ16→32对两完整程序仅约0.09%/0.31%周期改善且timing变差；这只能否定孤立加IQ，不能否定协同扩大整个窗口。

上一轮已完成、保留的真实变化，现在是新基线：
R64Lsu RESPONSE_BYPASS默认1：仅成功、对齐、普通RAM load（非store/atomic/side_effect且class<2）在对应raw lane真实寄存占用为空时，以该raw来源参与原六源RR选择；仅CQ本拍真正捕获才抑制raw enqueue。未赢仲裁、无CQ信用或不合资格均回退原raw queue。raw_ready只依赖寄存信用或旧dead-load drain，不依赖CQ/WB当前组合反馈。真实raw_fire、mem_end、LSQ释放、完整tag、reuse保护、flush/kill/晚到drain保持。LSU全局flush取消所有现有owner，不是保留较老owner；外部物理response token为受生命周期保护的LSQ slot，并非外部携带完整ROB tag，CQ捕获后自己持有完整ROB tag。
机制结果：8194个串行依赖load response→CQ从1拍减到0，response→WB从3减到2；load_chain 123042→114849 cycles（-6.66%）；但争用负载仅-0.034%/背压-0.211%。完整程序同ELF/bin、完整NEMU+assert、自然退出PASS：CoreMark10 iterations 9241964→8968518（-2.9587%）；Dhrystone10000 14568135→14267505（-2.0636%）。CoreMark因计时改变最终printf输入，从096到129精确解释+13 commits/+2 writes，CRC完全相同；Dhry commits完全一致。当前基线的完整程序数据如下。

当前完整CoreMark：cycles8968518，commits3218537，CPI2.786520087，dual-retire cycles1261732。
原始观测cycles8968519（一拍边界差）；retire_zero7011714，retire_one695073，retire_two1261732；frontend_empty1897220，frontend_full4228247，decode_empty1842341；birth_zero6509296，birth_two1510682；decode_rob_block1281756，decode_iq_block3493948，decode_prf_block0，decode_lsq_block810；recover392529，branch_redirect54926，prediction_redirect69315；icache_fill5064，store_b_owner592424；head_serial30；issue_zero6429815，issue_two1056583；write_command148644，write_wait0，load_bus_command93，wb_backpressure628167。
新增较严格ROB观测：head_notdone6296164，head_notdone_unfrozen6192140，freeze446883。旧rob_nonempty_notdone6639023含冻结混合语义，不能代替新值。
load完成：eligible549089，raw_empty549048，raw_empty_credit549021，raw_empty_two_credit548911；548982个同拍CQ捕获。cq_captured549089，wb_accepted545666，cancelled3423，pending0，tag_collision0。

当前完整Dhrystone：cycles14267505，commits4260670，CPI3.348652911，dual-retire cycles1734506。
原始观测cycles14267506；retire_zero11741342，retire_one791658，retire_two1734506；frontend_empty2141592，frontend_full8445625，decode_empty2130982；birth_zero11220027，birth_two1855421；decode_rob_block8298316，decode_iq_block350718，decode_prf_block0，decode_lsq_block570310；recover321163，branch_redirect50220，prediction_redirect120817；icache_fill2482，store_b_owner2404764；head_serial30；issue_zero11048617，issue_two1413161；write_command601433，write_wait0，load_bus_command53，wb_backpressure1332443。
严格观测head_notdone11238283，head_notdone_unfrozen11007672，freeze371380；旧混合rob_nonempty_notdone11379052。
load完成eligible1011563，raw_empty1011558，raw_empty_credit1011558，raw_empty_two_credit1011549；1011552同拍入CQ；cq_captured1011563，wb_accepted1011558，cancelled5，pending0，tag_collision0。
注意这些事件可重叠，不能相加当可回收周期；head_notdone尚无真正依赖链归因，MLP/分支恢复损失也没有因果归因。load_bus_command只是片外命令计数，不是所有load次数；53/93不能直接证明整个内存执行不是瓶颈。

物理基线（真实全R64SystemTop，包括数组标准单元映射，无SRAM占位，icsprout55 TT/1.2V/25C，1ns/uncertainty .05ns，ABC600ps、fanout8）：当前area3144021.999995平方微米，setupWNS -2.119304419ns，setupTNS -137753，holdWNS -0.036660694ns，holdTNS -0.087889202ns。全局setup比上轮前改善约.0546ns，area只+.0865%，但仍FAIL1ns。布局前映射STA不是实际布线后签核。
重要局部代价：load bypass让内部寄存器Q→CQ payload最坏slack从-1.531424046到-1.892150521ns（恶化.360726475ns），CQcontrol恶化.144790ns，rawcontrol恶化.281939ns，CQ ICG恶化.005770ns。包含输入起点后的CQ payload最坏-2.111715555，与global仅7.588864ps差，不能宣称有227ps余量。三个负hold端点两版均相同，reset起点到platform、fabric、LSUrequest_queue ICG。
已将局部最坏路径映射回源码（这是事实线索而非本轮预选方向）：
commit event_trap_q -> full_flush -> ROB kill_mask[18] -> LSU row5 tag所指向kill/live -> response lane1 token选择 -> bypass_offer/event_valid[1] -> 六源RR第二winner source0 -> 第二个completion_result bit43 -> CQ物理lane与back/input mux -> front_result_q[0][43]。全路径arrival2.807798862ns；flush输出到.7489ns，ROBkill到1.2144，LSUrowkill1.4849，response资格2.0111，selector输入约2.071，selector出口2.2998，宽payload2.6230，CQ2.8078。映射别名含clmul_flush但不是CLMUL算术路径。上一轮前已存在trap→fault cancel→eventmux→CQ路径，当前是加深已有控制/数据耦合。

当前合同与局部源码语义：
ROB kill_mask[k]=valid_q[k] && (flush_i || (publication_kill && plan_younger_q[k]))；cancel_candidates=valid_q[k] && (flush_i || plan_younger_q[k])；cancel_active=flush_i || publication_kill。publication_kill默认本地模式用 !rst && native_registered_kill_pending && plan_valid_q，备选模式kill_w。不能凭名字把当前cancel_candidates当无flush依赖信号。
LSU killed[row]=flush_i || kill_mask[tag_q[row].rob_index]；input_live=alive_q[token] && !killed[token]；mem_rsp_ready=!rst && (raw_credit || qualified_registered_dead_load)；raw_fire=mem_rsp_valid && mem_rsp_ready && input_live；response_bypass_offer=enabled && raw_fire && !raw_occupied && !rsp_error && selected_eligible；bypass_fire=offer && event_grant[raw_lane]；raw_enqueue=raw_fire && !bypass_fire。
六源event_valid={两个forward_valid&&!forward_killed、两个faultqueue.out_valid、两个raw.out_valid|bypass_offer}。来源按RR优先级选择first/second winner，event_before_q只在真正event_grant时更新。completion_fire={至少两个valid,至少一个valid}&CQ信用；event_grant=first&credit0 | second&credit1；宽tag/result用first/second onehot选择，本来就不再经过credit。因此简单说“从payload去掉credit”不构成新优化。
CQ由两条front+back skid lane构成，输出被背压时owner不跨lane迁移；free=~back_q，first=free[turn_q]?turn_q:!turn_q，in_ready={&free,|free}&!rst&&!flush，只接受prefix00/01/11。front_remove=front_q&&(out_ready||flush||kill(front_tag))；first/second输入按Q态first分到物理lane。现有payload在空位置可预写：front_payload_write=!front_q||front_remove；back_payload_write=!back_q&&front_q&&!front_remove。有效位只由真实fire产生owner，满/持有位置稳定。in_result物理lane mux已与finalgrant分离。CQ输出request允许早于VALID做WB口需求提示，只有VALID+真实accept能写寄存器/ROB。尽管RTL clk直连，实际综合会映射ICG，要检查D/控制/ICG真实路径。

可用工程手段与成本：本地可读全源码、加只观察不驱动DUT的归因、做可逆完整RTL原型、定向模块+整核对拍、同工作负载A/B、真实库综合/STA。完整基准一轮约35–60min宿主成本，完整综合STA约55min；机器15GiB RAM+9GiB swap，原综合实测RSS~8.6GiB，不会再用6GiB cap导致导出失败。每轮优先一个由你选择的最小完整候选及必要正确性修复；基线92个RTL/头文件已逐字节核对并冻结，可复用上一轮最终候选的基线结果。避免无意义重复同一昂贵基线，但不会把不兼容证据拼在一起。

请先独立推导，再给出可执行的架构决策：
1. 从以上证据识别最可能的结构性限制；把已证明与尚待区分分开。不要只按某个大计数排序，也不要默认本地给了CQ路径就只能优化CQ。
2. 提出2–3个机制明确、有完整联合修改范围的竞争架构方案（可以跨发射/唤醒/执行/LSU/取消/完成/退休），解释依赖链或事务生命周期如何改变、代价转移到哪里，和为何比“多加一点队列/改一个门”更有价值。可反对不适合本工程的大方向。
3. 选出你建议本轮实施的一项，并说明相对其它项的收益/风险和证据依据；若当前信息不足以负责任选择，先请求最多3个真正影响选型的精确源码片段或最便宜归因实验，并给出各可能结果如何改变选择，不要泛泛要求再profile一遍。
4. 对首选给出最小完整状态机/接口合同：owner归属，valid/ready/credit，tag与reuse，flush/部分kill，持有与同拍替换，错误与副作用，晚响应；标注哪些决策必须联合改、哪些保持。必要时用时序表/伪RTL，勿凭未提供代码猜具体端口已存在。
5. 给出可证伪预测、最低充分验证与同基线比较方式；讲清楚能预期消除哪条依赖而不是捏造精确百分比。若目标主要是物理路径而周期不变，也请明确预期和整核代价。请给Codex执行的清楚任务，不止泛化架构综述。

你负责提出和修订架构，Codex负责提供真实证据与实现闭环。最终是否保留由真实正确性/性能/物理证据决定，不把你的回答本身当性能提升。