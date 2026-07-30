# V11C OooMemOwnerTracker 推导

## 竞争假设

- H1：production map/live-set 在合法二态输入下存在 birth/death 语义错误。
- H2：production 数据路正确，但旧 TB 由 count/PID 间接推断 token set，
  缺 exact membership、same-edge dying-token 与 X-known oracle。
- H3：V8G/V8L 历史 mutation 已足以直接晋级当前两个单元。

## 裁决

- H1 未找到反例。`live_next_r` 与 `producer_live_next_r` 使用相同
  edge-old death/birth 代数，token encoder 不读取 post-death state。
- H2 成立。旧 TB 不读取 `live_mask_o`；把该输出改成常零是明确假绿反例。
  旧同沿测试又使用相同 PID，无法隔离 token scan 与 PID guard。
- H3 拒绝。V8G tracker mutation 绑定旧 RTL/TB；V8L 当前 mutation
  集中于 backend/dispatch，并非 tracker map/live-set。

## 最小动作

生产 RTL 保持不变。TB 增加独立逐沿状态模型和“满表 + dying token +
不同合法 PID”exact/bulk 两条轨迹；外部 checker 增加四态身份/集合合同。
九个 RTL variant 分别切断 public live mask、live birth/death、map birth/
clear、ProducerId bitmap birth、exact/bulk edge-old scan 与 dual-PID exclusion。
