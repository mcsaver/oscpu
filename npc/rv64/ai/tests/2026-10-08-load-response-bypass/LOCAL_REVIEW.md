# 网页建议的本地核查

来源：[原咨询会话](https://chatgpt.com/c/6ac6309d-96a4-83e8-bbce-538e0ec038ed)。
本次发送时输入模型按钮显示 Pro；同一侧边栏会话先前已核对 GPT-6、Pro 第5/5项。
页面记录本次“思考了16m22s”。本次回答等待至页面出现“回答已完成”，由最后一条 ChatGPT 回答容器的可见 innerText 完整读取；
原样保存 response.txt（网页数学排版的可见文本可能重复），另保存完整 AX 状态及完成截图。
没有用本地代理回答冒称网页 Pro。

网页处理期间已完成本地独立合同审查和草稿定向测试；为与长仿真并行，
先启动了可逆候选实现。网页全文回来后再核查，不把异步等待增加为批准门槛。
当前没有把网页裁决当作本轮测量结论。

## 接受并落实

- 原 response fire 与 raw queue fire 分离；raw_credit/mem_rsp_ready 方程未变。
- 真正寄存 occupancy 判空，不能用 kill 门控后的 out_valid。
- 仅原六源仲裁的实际 CQ capture 才抑制 raw 入队；未赢 grant 正常保存响应。
- 原始 metadata、partial forwarding merge 与 load formatter 复用，没有复制另一套格式器。
- full tag 在同一边沿由 LSQ 转交 raw/CQ，保留现有 reuse 投影与 WB/ROB 权限。
- eligibility 正向要求 class<2，并排除 store、atomic、side effect、misalign、bus error。
- 双路、背压、同拍 kill、复用、竞争、错误排除由真实接口定向覆盖。
- 依赖 load 链与两个完整程序分别证明机制和收益；旧 profile 的 freeze 混合问题单列纠正。
- 物理对比除了标准 WNS/hold/面积，还准备同网表的相关时序锥/TNS补充诊断。

## 按实际实现细化的边界

1. 网页提出“flush 同拍还有未被杀的较老 load”作为通用反例。
   当前 LSU killed_w 明确定义为 flush_i OR 对应 kill_mask，flush 清掉所有本单元活owner，
   因而本设计不存在该幸存响应。已测当前真实语义的 kill/flush drain，而不是造不合法幸存项。
2. 网页要求“晚到响应先匹配 full tag”。实际物理响应接口携带 LSQ slot token；
   该 slot 在已发响应未 drain 时不会释放给新 owner。full canonical ROB tag 从仍归该事务的
   LSQ row 读取。不能让 A 尚欠响应时先复用其 LSQ slot，再指望接口上不存在的 full tag 修复。
   本轮保留这一既有 token ownership 合同，测试跨槽存活与 CQ 持有时 LSQ/ROB generation复用。
3. 网页提出检查 CQ ICG 使能。RTL 的 R64LsuCompletion 直接接 clk_i，没有手写独立 CQ gate；
   但综合会映射真实 ICG，不能据 RTL 写法排除映射后的时钟门控检查。补充 STA 将检查从真实
   sequential cell 时钟连接识别出的 ICG E pin，且保持全局 setup/hold 检查。
4. event_grant 在本实现不是仅 hint：它由 source winner AND completion_credit 产生，
   与 completion_fire 同一组 Q-only credit，一一对应实际捕获。out_request 才是 WB hint。
   因而无需引入第二套 capture ready 或新的上游反馈。
5. 参数0模块对照需消掉旁路 payload mux；已由常量参数直接选择原 raw 数据。
   正式全核 baseline 仍来自修改前完整源快照，不使用候选代码作为历史物理基线。

## 已得机制证据，最终裁决仍待完整 A/B 和 STA

baseline / candidate 的 load_chain commits 均9223，cycles 123042 / 114849；
随机请求阻塞模式123083 / 114893。原8194条合格响应到CQ1拍、到WB3拍，
候选到CQ0拍、到WB2拍。该序列包含8192条依赖load及2条la展开的GOT load。
lsu_contention改善仅29436→29426，说明机会计数不能直接换算为程序节省。

网页返回后的新增定向矩阵进一步覆盖“两lane同时返回、CQ仅一个信用”；
候选恰好一路直达、另一路fallback，参数0/1与plain/request-stalls共四组通过。
相关原生系统10组、LSU/cache等16模块及5项负向检查已通过。最终物理结论与完整性能数字见本轮RESULT。


## 最终闭环

完整CoreMark10/Dhrystone10000周期减少2.958743%/2.063613%，相关正确性验证通过；同约束全局setup改善、hold端点不变、面积+0.0865%。CQ局部payload路径恶化约0.361ns，含输入的最差路径已接近全局，不能称为无时序代价。最终保留局部CPI优化，1ns仍FAIL。完整证据、恢复及限定见[最终报告](RESULT.md)。
