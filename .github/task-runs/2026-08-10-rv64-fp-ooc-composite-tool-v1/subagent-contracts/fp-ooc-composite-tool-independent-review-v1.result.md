# FP OOC composite tool independent review v1

RV64 RTL 结论｜对象=NpcTop FP OOC composite Registry→runner→五 child/top Tcl→parser→summary/receipt｜周期/配置=5.0ns、mapped-5ns-fp-arith-production-children-ooc-boundary-v1、live sha256:9d8bb6af｜TB/EDA 观测=定向 unittest 36/36 PASS、Registry/render/bash 门禁各一次、production Yosys/OpenSTA=0；源码攻击发现承重假绿与正常路径误拒绝｜范围=GAP

## 裁决

**BLOCK**。当前版本不得启动 production diagnostic run。三类边界与证据图方向正确，但 Liberty 数值、mapped-cell 完整性、真实 Q launch、同步控制覆盖、顶层对象类型和 cleanup 后网表可复核性仍可产生假绿或误拒绝。

## 已闭合

- Registry 已互斥区分 `inline_rtl=OooFpArithGate`、五个 `known_ooc_macro` 与 SRAM/BPU `unknown_placeholder`。
- runner 按五 child→top 顺序执行；generic mapped summary stamping 被拒绝。
- 当前 RTL 端口/宽度与五份 `child_contracts` 一致；MulProduct 正确标为单级、无 reg→reg。
- parser 接受 zero-negative，并将 child/top negative 聚合为 `VIOLATED`。
- 面积意图为 top stdcell area 加五份 OOC area各一次；power 固定 incomplete/GAP。
- artifact helper 拒绝 symlink、hardlink、跨 evidence-dir 路径并绑定 run/design/config/profile/tool/source。
- 只有 compose、retained validate 和 cleanup 全成功时 runner 才写最终 PASS。

## 阻断反例

1. `render-liberty-from-artifacts` 只检查 timing TSV 可解析，却固定写入 max setup/hold/clk-to-Q=`0.10/0.05/0.20ns`、min=`0.02/0.01/0.05ns`。真实 path slack/延迟变化不会改变 Liberty 数值；validator 仍会 PASS。
2. `yosys.tcl` 使用 `check -mapped` 而非非零退出的 mapped assertion；parser 未核对 leaf cell 属于 stdlib。残留 `$mul/$add/$mux` 等 generic cell 可能通过。
3. child Tcl 把 `all_registers -data_pins` 用作 reg→reg/reg→port 的 `-from`；D pin 不是 Q launch。
4. `rst` 与 `flush_i` 合并后只要求总计一条路径，断开任一控制仍可通过；数据端口同样缺少逐端口/逐位族覆盖。
5. top Tcl 由调用参数给对象贴 `MACRO/REG/PORT` 前缀，没有验证实际 OpenSTA object class；宽泛内部 pin可冒充 completion endpoint。
6. cleanup 后 mapped netlist 被删除，最终只保留 hash/size，没有 retained netlist receipt 或完整 port/leaf-cell/instance manifest。
7. 合同声明 `gate-status.tsv`，实际封存并绑定 `gate-status.txt`；前者不存在。

## 解除 BLOCK 的门槛

- 从机器产生的 per-port max/min arc inventory 机械导出 setup、hold、clk-to-Q；否则移除 timing CLEAN/VIOLATED 含义并降为 reachability-only。
- child Tcl 使用真实 Q/output pins；对 Registry 的每个 input/output、`rst` 与 `flush_i` 分别建立 coverage/cardinality。
- Yosys mapped assertion必须导致非零退出；parser 建 stdlib leaf whitelist 并拒绝所有 `$*` generic cell。
- 顶层使用实际对象类型和精确 instance/pin contract 校验 boundary，不能信任调用者标签。
- 保留 mapped netlist，或保留从同一网表机械生成并绑定的完整 port/leaf-cell/instance manifest。
- 增加针对上述真实调用链的定向 mutation，并修正 gate-status 路径。

## 身份

- review contract SHA：`4c2e9819d3bfc693e3fa2864d8b31f5770121fe44d905993d8a2033ca9980952`
- implementation result SHA：`5490ea615d776b43874e5f5497fdce0fc2dee17c6fd4f0138ee0700551c439e2`
- parser SHA prefix：`9abdd83a`
- runner SHA prefix：`7129ba8c`
- 实际 gate-status.txt SHA prefix：`06cbffcd`
- 本 review 未运行 Python、测试、仿真、综合、OpenSTA 或 parser，未修改文件；shell 已归还。
