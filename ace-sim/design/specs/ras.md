# Ras — 返回地址栈

**文件**:`src/core/frontend/Ras.hh` · **↔ npc**:`RAS`(返回地址栈)

## 职责
预测 `ret`(JALR rs=ra)的返回目标:`call`(JAL rd=ra)取指拍 push 返回地址(pc+1),`ret` 取指拍 pop 得预测目标。
**投机**结构:错误路径的 push/pop 会污染栈,但架构正确性由 execute 解析 + squash 保证 —— RAS 只影响**预测准确率**(与 gshare/TLB 同理:预测/时序 ≠ 架构结果)。

## 状态
- `stack_[depth]` + `sp_`:定深饱和栈(满则丢弃 push,空则 pop 返回 fallback)。

## 接口
- `push(ret_addr)`:call 取指拍压入(满饱和)。
- `pop(fallback)`:ret 取指拍弹出预测目标;空则返回 `fallback`(通常 pc+1)。

## 调用/返回控制流(⑤)
- **JAL**(直接调用):目标 imm 取指即知,fetch 直接重定向;`is_call`(rd==RA_REG)则 `push(pc+1)`;dispatch 写链接 rd=pc+1 即 done(无误判)。
- **JALR**(间接跳转/返回):目标 reg[rs]+off execute 才知。fetch:`is_ret`(rs==RA_REG&&无 rd)则 `pred = pop(pc+1)`,否则暂预测 fall-through。dispatch 写链接 + 记 `pred_next_pc` + `rat_ckpt` + 进 IQ(等 rs);issue 算 `actual = reg[rs]+off`;wakeup `resolve_jalr`:`actual != pred` → squash + 重定向(同分支)。

## 不变量 / 行为
- push/pop 在**正确路径**上平衡(每 call 一 push,每 ret 一 pop)→ 返回目标精确预测。
- RAS 污染(错误路径)只降准确率,不改架构结果(difftest 守恒)。

## 测试
`make run-gshare`:demo(两次 call SUB → ret 回不同返回点,RAS 零误判)+ fuzz 2 万程序 / 2.4 万 call / 2.3 万 ret(正确路径 RAS 命中 100%)对拍功能金标准。
