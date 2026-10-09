本地完成你要求的源码核查，方向仍是你选的C，尚未修改生产RTL。发现一处必须由你修订的接口定义矛盾，不能照4.2直接实现：

R64LsuRequestQueue.v:58（作为raw response_queue）实际为：
  in_ready_o[g] = !(&valid_q[g]) && !rst_i && !flush_i;
R64Lsu.v:1335把该ready接到raw_credit_w；:1359：
  mem_rsp_ready_o[g] = !rst_i && (raw_credit_w[g] || |dead_load_match_w);
  raw_fire = mem_rsp_valid && mem_rsp_ready && alive_q[token] && !killed_w[token];
dead_load_match必须!alive_q，因此live成功load不可能使用此drain例外。

具体反例：固定所有Q态（alive=1、issued MEMORY、合法普通load、raw lane真实为空、CQ有信用）与mem_rsp_valid=1/payload不变。flush=0时ready=1，bus_fire=1；flush=1时ready=0，bus_fire=0。因此你的rsp_candidate含bus_fire会把当前flush重新接到candidate/RR/宽payload锥，违反6.1“只切flush候选不变”的预测。当前取消前raw_occupied/tag/data、fault占用/tag/data、forward_valid_q/tag/data均可提供；没有必须新增正常load流水级或改变token的障碍。

请修订C中的response候选呈现合同：可否在仅用于数据预路由的candidate中使用mem_rsp_valid && alive_q[token] && !raw_occupied_q && !rsp_error && Q态descriptor资格，利用raw真实为空蕴含结构容量，而将原始bus_fire/语义存活完整留在最终capture与raw_fire/raw_enqueue？这只是提出最小修正供你判断，不会改变mem_rsp_ready、真实外部握手、kill生效或LSQ释放。请明确能否允许未握手的稳定response只预写无owner空CQ槽，所需断言和reset边界；或给出你认为正确的替代合同。不要回退成局部A或改变选定方向。

其余核查事实：
1. WB边界具备所需资格：CQ out_valid当拍屏蔽flush/kill；R64Writeback按source_valid及kill登记accepted，flush清accepted；ROB OWNER_CERTIFICATE路径permitted=!rst&&!flush&&wb_valid&&cert_valid&&!kill&&!duplicate，PRF写=permitted&&cert_rd_write&&!exception。该wb_write共同驱动真实PRF、rename ready、IQ wake、RR WB旁路。已有断言逐拍与完整generation/valid/!done的canonical reference_accept等价。不是仅ROB拒绝而PRF仍写。
2. LSQ分配只用state==FREE；已issued MEMORY/TRANSLATING被kill先清alive，但保留state/tag/token owner，不能cancel_free，直到真实晚响应握手才清issued/drain释放；reuse覆盖非FREE LSQ以及raw/CQ占用。CQ捕获fulltag后不再查可复用LSQ。原token合同可保留。
3. 原RR event_last_grant从candidate second+credit推导，需要按真实capture_rank最高rank更新；CQ turn原01/11皆设!first_w，可以保留正常行为，10时仅第二物理lane捕获，拟设turn=first_w（下一次优先另一lane）。这是sparse接口所需修正，不把预定但取消当grant。
4. 真实普通store已启用非头prepared、B_BYPASS和独立LSU store_done→ROB通道，不经过CQ/9→2 WB。本轮C不动它。你列出的B是更早的地址/数据部分发射，不能与已有prepared混同。

基线CQ输出→WB的补充STA已安排，只读既有映射网表，不重综合；结果稍后反馈。请针对上述反例修订候选/捕获定义，并明确可执行结论。