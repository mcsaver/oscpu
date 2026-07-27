# V9U 完成定义

以下条件必须同时满足：

1. `mtvec/stvec` MODE=00/01 原样保存，MODE=10/11 钳位为同 BASE 的 Direct。
2. trap 只从一个 `mem > ex > irq` 选中记录派生 xEPC/xCAUSE/xTVAL、delegation
   与 redirect target；同步异常只到 BASE，中断 MODE=01 到 `BASE+4×cause`。
3. 未委派 SSI/STI/SEI 以原 cause 进入 M；已委派 supervisor interrupt 只在
   低于 M-mode 时进入 S；M-mode 中已委派 supervisor interrupt 被屏蔽。
4. `OOO_ASSERT` 的 A1..A5 保持启用，A5 使用独立 pending/cause 参考表达式；
   不以生产表达式自证。
5. CsrFile focused 13/13、完整核 M interrupt/S interrupt/M synchronous exception
   3/3、CSR regression 1/1、原始重复 terminal event 0。
6. 7 个 compile-success RTL 负向版本必须全部被定向 oracle 动态拒绝，其中包括
   `drop_nondelegated_supervisor_irq`。
7. `rv64mi-p-illegal` 定向官方用例 PASS；完整 F0 为 module 111/111、
   official 177/177、AM 59/59、DiffTest mismatch 0。
8. 当前设计的 9 个 directed architecture gate 为 GREEN，V9O index 独立 replay
   通过，CLOSED debt ledger 使用同一设计 SHA。
9. full-core candidate 保持 `GAP`、PPA 保持 `UNQUALIFIED`、promotion=false；
   未完成 scope/census/cohort/freeze-input 项继续作为显式 blocker。

