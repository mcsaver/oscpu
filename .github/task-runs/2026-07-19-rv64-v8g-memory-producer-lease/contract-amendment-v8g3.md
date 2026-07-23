# v8g.3 third-review blocker amendment

## 三次独立复核结果

reviewer 拒绝了 v8g.2 scoped green，给出 5 个可执行反例：MIQ/response epoch
与 tracker epoch 不同仍可借新 PID 完成；request 发出后旧路径可提前置 ROB done；
terminal credit 读其它 fire 可间接成环；bounded grant 漏了 side-effect credit；AMO
write 已发后的 closed final 不能按可取消 AMO 回收。

三次 verdict 仍为“不可进入 RTL”；父目标保持 `active`。

## 冻结修订

| blocker | v8g.3 冻结结论 | 承重证据 |
| --- | --- | --- |
| tracker tag | `tracker_exact=live&&kind==holder.kind&&epoch==holder.epoch`；只有 exact 后才可使用 table PID | wrong-kind/epoch 不 WB、不 collector/free mutation |
| post-launch done | STORE/AMO request 已发到 final response completion 前 head full PID exact-open 且 `!done`；final completion 是唯一 done/terminal 事件 | AW/W/address/data 早 done mutation + outstanding watchdog |
| terminal DAG | other raw terminal candidates 不读任何 ready/fire/grant，且固定优先于 response；response credit 只读 edge-old pending 和 raw candidate tuple | cone structural audit + same-token collision hold |
| bounded completion | 本结构的 PRF/Busy/IQ/public/SQ fill 无 ready，冻结 `side_effect_credit=1`；所有非-WB credit 稳定时检查下拍 `completion_fire` | full-WB 一拍 watchdog |
| irrevocable AMO | `amo_write_sent=1` 后 closed final 与 STORE DRAIN 同类：bus pop+fatal+poison，不 WB/不 collector/不 normal death | write-sent + done_now/ROB mismatch case |

active spec、task contract 与 RTL derivation 已同步 v8g.3。第四次 reviewer
给出 `scoped green`：合同层未再发现阻止进入 RTL 的反例；global no-live-reuse
仍为 RED。
