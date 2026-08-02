# V13J 独立审查结果

## 裁决

`GAP`。对象为 `performance-measurement-contract-v1.json`、`NpcSimTop.sv`/`cpu-exec.cpp`
committed-PC probe，以及 `OooIntBackend`/`OooFpBackend` 的物理 issue terminal；未运行仿真、综合或
STA，只进行合同限定的静态复核。

## 已确认

- CoreMark PC `0x800017a8 -> 0x800017b0`、Dhrystone PC
  `0x80000334 -> 0x8000047c` 与现有 policy 一致。
- `NpcSimTop.sv` 以 lane0→lane1 上报提交，`cpu-exec.cpp` 用 `retired_before` 保持同拍年龄顺序；
  `cycles=end_cycle-start_cycle` 与 `retired=end_retired_before-start_retired_before` 算术一致。
- 现有百万周期 OoO bucket 明示 overlap，不能构成守恒 CPI stack。
- 物理发射 terminal 是 integer 2 路加独立 FP 1 路；在全局 slot 合同冻结前，不得按
  `issue_width=2` 推导全局发射容量。

## 必须闭合的反例

1. 当前 `region_probe RESULT` 在首次 end PC 提交时输出，之后虽继续累计 marker hits，却没有最终
   输出或检查；post-end 重复 marker 可在日志仍显示 `1/1` 时假绿。必须增加 termination-time
   authoritative `FINAL`，或把现有字段降格为 `hits_through_first_end`。
2. V13I `design_id` 的 `groups.rtl` 是包含 simulation-only 源码的混合 closure，不是
   production-only closure，也不是带 filelist/define/parameter/top/tool/model 的 elaborated identity。
3. 当前没有 checker 强制绑定 contract ID、`performance_baseline_eligible` 与
   `counter_qualification`；仅修改独立 JSON 布尔值不能阻止机器消费者越级晋级。
4. `cpi-neutral.json` 的 `PASS` 仅属于 whole-program intermediate checkpoint；它没有 region scope、
   三次 repetition 或本合同 ID，不能包装成 qualified baseline。

## 本轮处理

机器合同已按上述反例降格并拆分 typed identity；正式 baseline 继续保持未资格化。下一实现入口为
`performance_counter_schema_v1`，先闭合 FINAL marker、identity manifest 与 fail-closed consumer。
