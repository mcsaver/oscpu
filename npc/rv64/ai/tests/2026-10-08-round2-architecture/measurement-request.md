按你修订后的方案C，我们已经实现并完成候选验证和同约束完整综合/STA。出现了你6.3要求回传的真实取舍。请继续作为主要架构设计者，对这个完整候选作出有依据的裁决；我没有先换成其他优化。

实现与合同：取消前六源候选；真实capture使用原握手及当拍存活；sparse10不压紧；每lane两固定槽，payload仅对旧Q空槽预写且!rst，同边沿真实capture才建owner；原ready、kill时刻、LSQ/token/drain/store/WB资格不变。没有新增正常流水级。生产只改R64Lsu.v、R64LsuCompletion.v，所有结果绑定同一冻结RTL。

功能已完成：原CQ及payload/WB-request测试、30,022拍独立FIFO/非干扰验证（21022 capture =19493 WB+1529取消；sparse10 3211次）、6003拍冻结旧CQ无取消逐拍等价、13122组独立六源仲裁oracle、真实响应BYPASS0/1×普通/背压及flush反例/sparse10、14项相关模块、2项预期fatal负向合同、12项SystemTop完整NEMU+ASSERT短测试均通过。load_chain仍114849/114893周期，8194次普通load response→CQ0拍、response→WB2拍。

完整CoreMark10已自然PASS：baseline=candidate=8968518周期、3218537退休、CPI2.7865200866、2416reads、148107writes。五项CRC、全部旧CPI/LOAD_PROFILE与17延迟桶完全相同。新计数tentative_winner_killed=599（rank次数），sparse_capture10=0，dead-first/one-credit=0。不存在本轮printf差异。
Dhrystone10000仍在原固定镜像运行，已超过1200万周期，没有DiffTest/断言失败，采样前缀与基线一致，但尚未自然结束，最终周期及正确性资格不得假定通过。baseline完整14267505周期、4260670退休；我会继续跑完。请对保留条件明确注明这项尚未完成，若物理结果已足够否定当前候选也可据实裁决，不必假设它会退化。

物理真实条件完全保持：全R64SystemTop，真实数组标准单元，无blackbox；icsprout55 TT1.2V25C，1ns，uncertainty .05ns，ABC600ps，fanout8，相同工具/脚本/约束/Liberty。原生make sta完成综合、check 0 problems、export、OpenSTA；rc2来自原timing checker真实FAIL，不是工具失败。没有删除reset/flush路径或加时序例外。

全局 B→C：
area 3144021.999995→3142155.239995 μm²，−1866.76（−0.059375%）；
setup WNS −2.119304419→−2.164543390 ns，退化45.238971ps；
setup TNS −137753.000000→−137741.593750 ns，改善11.406250ns；
hold WNS −0.036660694不变，hold TNS −0.087889202不变。全部负hold端点3→3，语义对应相同，无新增/消失（CLINT reset、fabric reset、request_queue ICG同80FF集合）。两版都FAIL1ns，禁止推算Fmax/真实执行时间。

原global worst实际语义链：rst_i→commit full_flush→kill_mask[18]→event_select.valid[1]→event_second[2]→event_before_q[0]。
新global worst：rst_i→commit full_flush→cancel_candidates[15]→forward_query.out_valid[0]→mem_valid[0]→mem_ready[0]→LSU effect_q[14]。不是CQ payload路径；全局瓶颈迁移。

CQ/raw输入 all-startpoints setup max / hold min，单位ns，保留reset输入：
cq_control(5→7D): max −1.650204420→−1.635059953; min .046396572→.058652125
cq_payload(596→596D): max −2.111715555→−1.302782774; min .101587519→.248354346
cq_payload_ICG(4→4E): max −.936215937→+.326810688; min .011962098→.059529953
raw_control(6→6D): max −1.969095349→−1.762629390; min .031943168→.031943168
raw_payload(772→772D): max −.355279922→−.398821324; min .121811524→.121722870
raw_ICG(4→4E): max .331729323不变; min .057298563不变
Q-only cq_payload max −1.892150521→−1.302782774。端点按新网表全部slot/owner/ICG重新取，没有限制为旧Q集合。

实际 CQ Q→WB D：
payload/tag 298D，reachable CQ Q 298→598，max .489983857→.155513659，min .121043526→.187528744；
accepted 72D，Q 12→26，max .013875512→.029436233，min .126087084→.206057563；
bank certificate 72D，Q14→30，max −.292893618→−.478821874，min .265788913→.336523235。
相关WB FF直接时钟，没有ICG端点。固定槽输出mux确实带来数据余量−334.470198ps与certificate余量−185.928256ps。

机制预测的真实网表证明：使用actual full_flush驱动pin作-through，并独立检查其是否在真实timing fanin。baseline CQ payload596D与4ICG E都含flush，有max/min路径；candidate两组fanin均无flush，max/min均0路径；CQ owner-control D baseline5/candidate7仍含flush且有路径，作为阳性对照。不是假路径。由此局部解耦成立，但不能替代全局收益。

请回答：
1. 基于当前证据，特别是在Dhrystone最终保持周期不变的条件下，这个完整候选应该保留到主工作树，还是淘汰并恢复本轮前实现，或有哪些真正改变裁决的缺失证据？不要把1ns仍FAIL或局部输入改善包装成整核性能提升。
2. 哪个架构假设被支持、哪个收益预期没有兑现？需要区分已测事实、解释和未知；若对global迁移的原因需要额外反事实测量，明确不能由一个路径推断因果。
3. 如果不保留，请给出下一轮最有价值的一项有界诊断/架构问题，解释它会如何改变选型；不要为了拯救当前候选无限扩大为另一个未定义的大改造。
本轮先对已实现的完整候选闭环；昂贵基线不重复制造。候选快照/差异/真实失败与成功证据都会保留。