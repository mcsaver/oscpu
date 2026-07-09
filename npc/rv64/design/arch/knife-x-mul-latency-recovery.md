# 规范：刀 X——MUL 拍数收复（radix-4 无符号数字 + CLZ 早退出 + swap）

> 状态：**spec 冻结（2026-07-09，三路侦查+对抗审查后成文，
> 侦查原文存 `.github/task-runs/2026-07-09-knife-x-recon/evidence/`）**。
> 动机：CPI 考证（`.github/task-runs/2026-07-09-cpi-regression-forensics/`）实锤
> 07-08 iter-mul 重写（MUL 单拍→固定 64 拍 shift-add）贡献 **ΔCPI +1.76（70%）**，
> 是全部退化因素之首；本刀在保住 iter-mul 综合动机（不回单拍 128b 大锥）的前提下
> 收复其中大部分。实施后回填数据；权威单元 spec `../specs/ooo-muldiv-unit.md` 同步更新。

## 1. 冻结形态（一句话）

radix-4 **无符号数字**（digit∈{0..3}，3M 装载拍预算寄存 `mul_m3_q`，逐字镜像 DIV 的
`div_d3_q` 模式）+ CLZ 早退出（打在 swap 选出的 min 幅值 multiplier 上，
`count_init = 64 - clz_even`）+ **选出侧幅值==0 装载拍直进 RESP**；
零新 FSM 状态、kill/flush 逻辑与末拍取反/切片路径一行不动。
**显式弃用**：Booth 编码（负数字/补码尾差/与 CLZ 交互陷阱，全不引入）；
迭代内 `multiplier_next==0` 全零检测（CLZ 已精确到 ±1 组，NOR 树只加深迭代拍）。

## 2. 设计要点与正确性论证

- **早退出对全部 5 变体无条件安全**：现结构符号在装载拍剥离（abs + 末拍
  `mul_neg` 条件取补，`OooMulDivUnit.v:89-95/130-132`），迭代域是纯无符号幅值乘法。
  不变量：k 组迭代后 `acc = M × multiplier[2k-1:0]`；剩余位全 0 ⇒ acc 已是精确
  128 位幅值积 ⇒ 高 64 位切片（MULH/MULHU/MULHSU）与低 64 位同时精确。
- **swap 符号代价严格为零**：`mul_neg = op1_neg ^ op2_neg` 与角色无关；MULHSU 的
  非对称符号提取发生在 swap 之前的原始角色上。选边判据：64 位无符号比较
  `op1_abs < op2_abs`（与 clz 比较单调等价），小者当 multiplier。
- **零特判必须打在两侧**：`(op1_abs==0 || op2_abs==0)` 装载拍直进 RESP（结果 0，
  全变体正确）。★只查固定一侧（照抄 DIV `req_op1_zero_w` 形态）在
  op1=0/op2 大 + swap 场景漏判 → radix-4 下 count=0 绕回 ~64 拍**结果仍正确**、
  TB max_cycles=80 内、全门禁假 pass——全方案最高危单点（风险表 R1）。
- **每拍方程**：`digit = multiplier[1:0]`；addend 4:1 mux（0 / multiplicand /
  multiplicand<<1 纯布线 / mul_m3_q）→ 原 128 位加法器不变；multiplicand<<=2、
  m3_q<<=2（3M<<2=3×(M<<2)，移位免费）、multiplier>>=2、count-=2；
  `count==2` 收尾（镜像 DIV `:311-315`，resp 取当拍 `acc_next` 合并语义保留）。
- **MULW 免费收益**：word 操作数 sext 后取 abs 幅值 ≤2^31 → CLZ 自动 ≤32 拍
  实际（radix-4 ≤16+2），无需单独分支。
- **唯一新增状态**：`mul_m3_q`（128FF），进复位/flush 清零表；kill_inflight_w
  状态枚举（`:214-216`）不动。
- **iverilog14 布局**：新 wire 全部声明在 `div_clz64` 函数（L150）之后
  （前向引用三类禁令）；全 `.v`，`always@(posedge)/always@(*)`。

## 3. 拍数与收益预估（验收不拿预估当合格线）

| 场景 | 现在 | 刀 X 后 |
| --- | --- | --- |
| 每 MUL 占用 | 66 拍（1 装载+64 迭代+1 握手） | 2+ceil(eff/2)+2：eff=8→6、16→10、32→18、64→34 |
| CoreMark ΔCPI | 基线 3.280 | 预估收复 1.3~1.5（模型偏乐观：busy 阴影内 issue1 仍单发，实际收复量会低些） |
| **验收标准** | matrix-mul 67766 cycles（07-09 实测，单拍时代 10301） | **回到 ~1-2 万量级** + CoreMark 10 迭代 0xfcaf 对比 |

## 4. 实施步骤

- **S1（RTL，两个 commit）**：commit-1 纯 radix-4 化（固定 count_init=64→32 拍）
  focused TB 全绿；commit-2 叠 CLZ+swap+两侧零特判（+`mul_m3_q` 清零表）。
  每步 iverilog 模块 TB + verilator lint 双变体。
- **S2（单元验证，同 PR）**：
  - TB 扩充：5 变体×{0, 1, -1, ±2^63, 小×小, 小×大, 奇有效位, swap 两向,
    **MUL×0 / 0×MUL**} + **8×8 全交叉穷举**（4096 组，杀末拍 off-by-one）+ 随机 64 位；
  - **拍数上限断言**（≤ 2+ceil(eff/2)+2，wait_i 打进 CHECK 信息）——R1 的唯一解药，must-have；
  - **MUL 中途 kill + RESP 拍 kill 两用例**（现 TB `kill_valid_i` 恒 0，kill 防线是
    零测试覆盖的纸面防线；大操作数保窗口/小操作数打 RESP 拍）+ MUL 中途 flush（现只测 DIV）；
  - OOO_ASSERT 等价断言：**装载拍用 `*` 一步算出最终期望 resp_data（含
    negate+切片+sext）寄存，RESP 拍纯等值比对**（断言逻辑最小化）；
  - 负测试：一次性 mutation 手测（故意放宽早退出一位→断言 fire→复原），
    **否决** MUL_EARLY_EXIT 参数化常驻分叉。
- **S3（集成+综合+文档）**：module TB 全量 + rv64um tohost + AM
  matrix-mul/mul-longlong cycles A/B + CoreMark 10 迭代；OooMulDivUnit OOC full
  stdcell 重跑（对照 area 18944.80，确认 iter-mul 综合动机不回退）+ IntBackend
  分块 ABC delay 对照 89（同 non-signoff 语境相对比）；`ooo-muldiv-unit.md`
  §2 时序行/§3/§5（count==2）/§6 补 MD-I6（MUL CLZ 等价）+MD-I7（count 恒偶且
  ≥2，零特判保证）/§7/§9 同步。全状态 difftest 按 07-08 决策留整体收口。

## 5. 风险表

| # | 风险 | 等级 | 缓解/门禁 |
| --- | --- | --- | --- |
| R1 | 零特判漏 swap 侧→count 绕回 ~64 拍、结果正确、**全门禁假 pass** | 高 | 特判=(op1_abs==0‖op2_abs==0)；拍数上限断言；MUL×0 用例 |
| R2 | 末拍 off-by-one（count==2 收尾+acc_next 合并错位） | 高 | 8×8 穷举+等价断言 RESP 拍终值比对 |
| R3 | kill/RESP 竞态零测试覆盖，早退出扩大竞态占比 | 中 | S2 kill 两用例必做，非可选 |
| R4 | 装载拍组合锥加深（abs→swap 比较→CLZ 与 abs→选路→3M 两链） | 中 | 退路①去 swap（只 CLZ op2_abs）；退路②装载拆 2 拍——**拆 2 拍须补 kill_inflight/kill_new_req 状态枚举**（UC-A 家族入口） |
| R5 | 按 Booth 思路落 TB（侦查材料间矛盾） | 中 | 本 spec 钉死"非 Booth 无符号数字" |
| R6 | 收益模型忽略阴影内 issue1 单发 | 低 | 验收=matrix-mul cycles 绝对值 |

## 6. 后续刀预告

- **刀 F（fetch 侧）形态修正**：CPI 考证证明 fetch 吞吐减半（S_LOOKUP 不在 ready
  集合→1 包/2 拍=前端供给上限 1 指令/拍）是 CPI 地板元凶（+0.50 主体），且全核 STA
  top 违例=fetch 判决链。刀 F 必须做 **lookup 流水化**（S_LOOKUP 期间重叠下一请求
  的 SRAM 读），不走"加判决拍"老路——时序与吞吐一起治。等刀 X 数据后排期。
- 刀 X 二期（radix-16 / 流水阵列乘法器）：触发条件=一期后 CoreMark 剖析 MUL 仍在
  top 桶（预期不会，radix-4+CLZ 后 MUL 残余贡献 ~0.2-0.3）。

## 7. 变更记录

- 2026-07-09：spec 冻结（三路侦查+对抗审查；审查修正=钉死非 Booth/零特判两侧/
  验收改绝对值/否决参数化负测试）。
