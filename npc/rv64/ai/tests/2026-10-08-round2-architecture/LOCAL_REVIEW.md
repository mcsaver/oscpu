# Pro方案C：源码合同核查与实施后复核

本文记录实验候选C实施时的合同复核。完整测量后已按[Pro裁决](measurement-response.txt)淘汰并恢复B；以下通过结论仍只指向归档候选，不代表当前主树采用固定槽。
本轮比较基线为上一轮保留点；当前生产源码已实施候选C：取消前六源候选、稀疏capture、固定CQ物理槽。
方向由Pro在独立新会话选择，本地没有用早先候选替代。第一次完整回答见response.txt，反例提问见
clarification-request.md，Pro接受反例并修订的合同见revised-contract.txt。下列原接口行号对应实施前源码。

## 接口反例：原bus_fire仍受flush控制

R64LsuRequestQueue.v:58的in_ready为寄存容量且!rst&&!flush；作为response_queue输出raw_credit。
R64Lsu.v:1359 mem_rsp_ready=!rst&&(raw_credit||registered_dead_drain)。
对alive=1、合法load、raw空、响应valid=1、dead_match=0的固定Q状态，flush从0变1会使ready和bus_fire从1变0。
所以原Pro伪码中rsp_candidate包含bus_fire时，flush仍进入候选选择与宽数据锥，与其不变性预测矛盾。
Pro已接受该bus_fire反例并修订合同：候选可以呈现未握手响应，最终capture/raw_fire仍保持原真实握手。
实际实现已将candidate与ready/raw_fire/当前flush/kill解耦，原ready合同未改；未握手预写不产生任何owner权限。

## 六源数据准备

现有模块为R64LsuRequestQueue，out_occupied是valid_q[head_q]，out_tag/data直接来自Q槽，均不含当前cancel。
raw、faults和forwarding_results现均已接出out_occupied，供取消前候选选择使用。
注意forward_valid_q只是带q后缀的wire，驱动来自queue.out_valid，已经含cancel，不能当作取消前Q占用。
raw_event tag/data mux已只看参数与raw_occupied。成功普通load资格全部由受保护descriptor的Q字段解码。
无需新增流水级或改变响应token。

## token与reuse

LSQ只从state==FREE申请，不借本拍响应释放信用。已issued的MEMORY/TRANSLATING owner遇kill后保留state/tag，
先清alive，真实晚响应握手才清issued并drain释放。mem_end/drain不能改接candidate。
reuse覆盖所有非FREE LSQ，以及raw/CQ等占用owner；CQ捕获全tag后独立持有，不再回查LSQ descriptor。
空槽预写不产生owner、reuse或释放权限。dead drain与live raw_fire守恒分别核算。

## WB/PRF共同资格

CoreTop把memory两lane接external[1:0]。Writeback当前source_valid且!kill才登记accepted；flush清accepted。
ROB参考accept检查reset/flush、当前valid/!done、完整generation、kill和重复tag；生产certificate路径保留
reset/flush/kill等资格，且R64_ASSERT逐拍证明accept、PRF权限和目标物理寄存与参考等价。
Backend wb_write共同驱动RegRead真实PRF写、RR旁路、Rename ready及IQ wake。
实际实现保持这些连接，用共同写权限在同拍cancel抑制效果；合同复核没有以ROB拒绝代替PRF核查。

## 已落实的实施边界

- event_last_grant已按实际capture最高rank推进；被取消candidate不推进RR，capture=00时保持历史。
- sparse10不压缩，01/11保留原turn行为；Pro已确认并已实现10时turn=first_w，00时保持。
- CQ reuse包含两lane的全部四个占用槽；kill与WB ready同拍按取消终结，不与WB accepted重复记账。
- 原完成结果格式与RESPONSE_BYPASS=0寄存路径保留。
- 原store已有prepared、B_BYPASS、store_done→ROB专用完成；详见STORE_SOURCE_FACTS.md。
- CQ→WB基线补充STA使用既有保留candidate网表/约束，不重综合；结果在独立目录保存。

## 实施后独立合同复核

复核对象为当前两个生产文件：vsrc/lsu/R64Lsu.v与vsrc/lsu/R64LsuCompletion.v。
本节记录已经完成的只读复核，不重新运行测试；结论依据源码条件和状态转移，不以既有测试PASS替代判断。
未发现偏离Pro原方案及revised-contract.txt的实质功能问题，也未发现需要重新决定架构的反例。

- **取消前候选与真实交接分离。** response candidate只读响应VALID、alive Q、原始raw占用、
  descriptor资格、错误和reset；六源选择使用取消前候选。真实offer/capture仍要求原raw_fire、
  当前semantic valid及信用。未获CQ接收的live响应仍唯一回退raw。
- **capture与当拍数据写一致。** CQ rank到lane、目标槽和payload_write由旧Q状态确定，
  写使能另受!rst限制。合法capture必有旧Q空槽，且在同一边沿写入当前完整tag/result并建立owner；
  不存在仅凭上拍预写内容置valid的路径。
- **固定槽与sparse映射成立。** 10保持rank1的原物理lane，不压紧到rank0；单占用时新输入写另一空槽，
  双占用时不借本拍pop/kill信用。旧head未被接受或取消时，head和其payload保持不变；
  旧head离开只改变有效位和头指针，不搬移宽payload。
- **reset/flush与提示权限保持。** reset禁用候选、capture和payload预写，并清除有效状态。
  flush可允许旧Q空槽预写，但不能建立owner。WB request仍只来自有效驻留或真实take，
  未改接candidate或纯预写。
- **历史和身份保护保持。** RR按最高实际capture rank更新；CQ turn按00保持、01/11取!first_w、
  10取first_w更新。原mem_end、issued token保留、晚响应drain和store通路不变；
  CQ独立持有完整tag，reuse只覆盖occupied槽，不计入无效预写。
- **信用没有回到数据路由。** CQ公开in_ready仍含!rst/!flush，但仅参与最终capture。
  free_w、first_w、target_slot直接取Q状态，没有用含flush的ready控制宽payload选择。

功能合同复核结论为通过，范围限于上述源码与接口。完整程序CPI和物理测量仍在运行，
本节不作保留裁决，不声称性能或时序改善。物理结果还需关注固定槽新增的CQ输出mux到WB路径、
reset到payload写使能/ICG及hold，以及global、CQ/raw控制和面积是否出现代价转移。

