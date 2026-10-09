继续上一轮 RV64core 架构审查。本次范围已改变：用户现在明确要求“使用工作流完成一次完整的架构优化”，授权 Codex 修改 RTL、运行真实正确性/性能/综合 STA 并作保留或淘汰裁决。上次只做诊断、不修改 RTL 的限制不再适用。请针对下面一个具体候选做深入架构评审，不要转成需要再次授权的流程。你提供建议，Codex 负责本地核查与执行。

目标：当前 2-wide RV64 OoO，固定 ROB32、IQ16、LSQ20、PRF64、2 WB，不扩容量；缩短真实依赖 load 的完成链。现有 early ALU wake、WB hint、RR bypass 已实现。

本地源码事实：物理访存响应 real handshake → 两个物理 lane 各 2 entry 的 raw response queue → 六源 round robin（raw0/raw1、fault0/fault1、full-forward0/full-forward1） → 双 lane completion queue → 原有 WB 捕获与 ROB wb_accept/PRF write/canonical wake。原始 response queue 的 in_ready 是寄存 occupancy 的信用，out_occupied 是真实 Q head valid；out_valid 另外被 flush/kill 门控。队列有 invariant：任何 slot occupied 则 head occupied。响应 canonical metadata 来自响应 token 指向的 LSQ row，含 full generation tag、func/VA/error/partial-store-forward byte mask/data。live fire = real handshake && alive && !killed。dead load drain 仍接收已承诺的晚到响应而不发完成。LSQ release_alive 和 mem_end 在真实响应握手处执行，reuse protection 是 LSQ/raw/CQ/WB 等 owner 的投影。

候选：仅对 live、无错、对齐、普通 RAM load（排除 store、atomic、MMIO/side_effect、misalign）在该 raw lane 的真实 Q occupancy 为 0 时，允许本拍响应作为原 raw event slot 的候选直接参加同一个六源 round robin。event payload 在 Q occupied 时保持旧 Q owner，否则取 incoming payload。bypass_offer = original_raw_fire && !raw_occupied_Q && eligible；bypass_fire = offer && 原 event_grant；raw_queue_in_fire = original_raw_fire && !bypass_fire。若 CQ 无信用或本拍没赢仲裁，则正常进入 raw queue。上游 mem_rsp_ready/raw_credit 不变，不组合依赖 CQ/WB ready。原 CQ/WB/ROB 权限、kill、精确异常、store B 义务不变。预期只消去一拍 raw 暂存，最多产生一次完成，不增加新的优先级或完成源。

核查到的风险：不能用 !out_valid 代替 !out_occupied（同拍 killed raw head 仍占 Q，避免新 owner 偷位置）；原 raw_data 与 event_data 要分开；源选择与 incoming metadata/forward byte merge/load-format/6-way arbitration/CQ ingress 组合链可能恶化时序。现有基线 1ns 约束本来 setup/hold 都 FAIL，不能把新结果称作时序通过或最终 Fmax。若需缩小到 full-width LD 且没有部分转发等，必须说明这是一次不同资格条件的实验，不偷偷改口径。

证据与正在运行的工作：本次基于当前源码重新构建 SystemTop + R64_ASSERT + 正式 NEMU，两个完整工作负载 CoreMark 10 iterations、Dhrystone 10000 runs 已运行中；新旧候选将用同一 ELF/bin、同一 reference 和约束。旧历史仅参考：9.242M cycles/3.219M commits、14.568M/4.261M。旧 rob_nonempty_notdone 计数用 !rob_commit_valid，混入 recovery freeze，不能算收益上限；仿真观测正在补真实 head !done vs freeze，并计响应→CQ→WB 直方图及 empty-raw/CQ-credit 机会。没有将相关 stall 比例当因果，完整本轮数据还未完成。旧只有 93/53 个 load bus internal command，不支持贸然扩大 MSHR。

请回答：
1. 这个候选的完整架构合同是否成立？指出最可能漏掉的具体并发反例（旧 Q owner 被 kill、新响应、CQ backpressure、两 lane、LSQ reuse 等）和必要修正。尤其审查 Q 空的透传是否保持 occupancy-credit 隔离与 full-tag 生命周期。
2. 给出你会采用的最小完整设计，明确 request/offer/grant/capture/retire 的归属，不另造泛泛大架构。
3. 有哪些真实证据会支持/否定这个候选？定向依赖 load 与完整程序、正确性和同约束 STA 如何联合裁决？如果只局部快一拍但完整无收益/物理代价更差，应明确淘汰。
4. 设计最有杀伤力的定向用例（含两 lane/CQ full/kill/reuse/错误排除），并指出本轮最大的不确定性。可反对该方案，但需基于以上链路给出可检验理由。