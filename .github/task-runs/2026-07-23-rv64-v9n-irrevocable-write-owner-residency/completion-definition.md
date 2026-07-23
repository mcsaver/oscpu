# V9N completion definition

本切片只有同时满足以下条件才可称为完成：

1. 独立只读 reviewer 枚举 SQ/AMO holder 的全部清除路径，确认是否存在
   “同沿清除后下一拍 guard 消失”的验证盲区，并给出反例与替代解释。
2. 可执行 checker 对 STORE 与 AMO 分别证明：无 exact terminal 的 request-sent
   owner 在下一拍保持同一 holder/full ProducerId/token/epoch。
3. 两份 current-source compile-success RTL variant 分别让 SQ exact owner-valid 与 AMO
   singleton type 在无 terminal 时提前消失；指定 checker 必须作为首个且唯一
   `[CHECK-FAIL]` 报告点，不能依赖编译失败、timeout 或无关 RTL 断言。
4. 正向 wrapper、负向 RTL variant、result/raw、live source SHA 与 current design-id
   形成可重算绑定，并有 fail-closed validator 反例单测。
5. `STORE-BRESP-G1` 的 ledger/ARCH_STABLE semantic validator 消费该证据；相关架构
   canonical target、audit 与 strict guard 重新通过。
6. 结论只限本切片；full-core `GAP`、PPA `UNQUALIFIED` 与 promotion=false 保持不变。

canonical `NpcCoreTop.u_ooo_core.flush_i` 必须继续静态连接 `1'b0`；该绑定用于证明
leaf `OooIntBackend.flush_i` 的无条件 singleton 清除不是生产顶层可达事务路径。
