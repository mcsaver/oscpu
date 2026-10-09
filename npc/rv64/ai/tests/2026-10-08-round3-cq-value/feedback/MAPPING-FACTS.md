# 本地补充：ABC 模块边界与最终扇出

只读核对，由 Codex 在网页 Pro 思考期间取得；这份文件尚未发送网页。未运行新 EDA，未修改 RTL/约束。

`SYNTH_MAX_FANOUT=8` 不是最终全局 `full_flush` 扇出不超过 8 的硬保证。当前流程先按模块映射，再展平导出，展平后没有全局 ABC 重映射或扇出修复。

- `npc/rv64/Makefile:90` 配置 `SYNTH_FLATTEN=0`、`SYNTH_SHARE=0`、`SYNTH_STA_FLATTEN_EXPORT=1`、负载20 fF、fanout8、ABC600 ps。
- `yosys-sta/scripts/yosys.tcl:431` 调用 ABC；第213行的 DELAY-4 策略含 `&nf,{D}`、`buffer -c -N ${max_FO}`、`upsize,{D}`、`dnsize,{D}`。第516行才 flatten，第519行 opt_clean。
- `npc/rv64/syn/export_sta.tcl:12–16` 再作展平、opt_clean、最终面积统计，没有 ABC 或 repair。
- R3 `results/ai-r3-20261008/candidate-sta/R64SystemTop-1000MHz/yosys.log:293364` 单独提取 R64Lsu，第293419/293423行执行 `buffer -c -N 8` / `upsize -D 600`；ROB、Execute、Backend 亦分别提取；第327141行才展平。
- B 原始综合来自 `results/ai-architecture-20261008/candidate-sta`，其 yosys.log 第292649行单独映射 LSU，第292704/292708行同样执行 buffer/upsize。B 完整展平通过 `mapped-export-recovery/prepare.tcl:15` 读取已映射网表，`finish.tcl:26–29` 展平清理，没有重新 ABC。
- 两份原始日志第7行均为 Yosys 0.66+197 / aa18c921a；上述相关实际命令一致。既有 physical-diagnostics/RESULT.json 另核对 OpenSTA、SDC、库及 common/PDK 脚本身份。这并不构成整个历史 yosys.tcl 逐字相同的证明。

模块端口的映射负载模型与展平后的跨模块真实引脚负载有区别，故最终 fanout92 与执行过 -N8 不矛盾。局部状态赋值源码相同，也不要求全模块重新优化后的逻辑分解、单元选择和共享节点相同。

此核查没有证明 fanout92 独立导致 LSU fire→state 尾段424 ps退化，也没有测过修改综合流程的性能结果。改变映射流程时应对 B 和候选成对比较，不能只重映射 R3 后和旧 B 混比。

## 后续窄核查：双关不是已证明的 B 物理控制

冻结 R3 双关在已测短程序上与 B 行为一致，但仍有源级差异。以下相对位置基于 `build/ai-r3-20261008/candidate-vsrc/`。

1. `backend/R64RegRead.v:207–215`：原 B 的四路 OR 数据选择改为先 stored_masked 再 for 累积 OR。关闭 CQ 后 FORWARD_N=4，布尔结果相同，源表达式树仍不同。
2. `lsu/R64Lsu.v:98–105,140–143,185`：直接 canonical kill 取位改为 owner_cancel 函数；local 模式关时返回 canonical[slot]。常量传播后可能相同，不能声称映射必然不同。
3. `backend/R64Rob.v:255–256`：新增 partial-cancel 输出无条件存在，双关时 CoreTop:594–596 选旧输入。结合先模块映射后展平，不能只凭全核短测证明新增、最终不用的模块输出对优化完全无影响。
4. `lsu/R64Lsu.v:1395–1399`：raw packet 中间别名层，关闭CQ时恢复宽度并清零ticket，语义等价，预计可优化清理，但非原源码。

尤其需要明确：`R64_CQ_VALUE_PROFILE` 宏会使 CoreTop:93–98 的 R3_LSU_VALUE_TICKET=1，即使 CQ bypass 关闭也保留观测 ticket。不能把 profile 双关构建当成原 B 的独立物理消融点。主 R3 性能和 PPA 使用的是归档的无 profile 完整候选；本条并不推翻原主候选同源结果。

本轮补丁没有修改 R64Execute.v，不支持“无条件重写 Execute lsu_fire 分配”这种归因。以上只证明源码差异残留；没有新增映射证据，没有把有限测试行为相等扩大成普遍形式等价。
