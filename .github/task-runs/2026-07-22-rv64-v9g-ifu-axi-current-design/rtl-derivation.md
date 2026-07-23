# V9G IFU-AXI-G1 RTL 推导记录

## Phase 1：接口与 owner

写事务 owner 位于 OooFetchAxiBridge.state_q=S_AD_UPDATE；AW/W accepted 位分别是
aw_done_q 与 w_done_q；ad_drop_q 不拥有物理事务，只决定 B completion 后是否继续 re-walk。
AxiXbar 只保存已经由 master 端接受的 AW/W，并在 slave B fire 时释放对应 owner。

## Phase 2a：握手方程

aw_accepted_next = aw_done_q or aw_fire

w_accepted_next = w_done_q or w_fire

write_complete = aw_accepted_next and w_accepted_next and BVALID and BREADY

effective_drop = ad_drop_q or mmu_flush_i

## Phase 2b：同拍优先级

全局 rst 最高；非 reset 拍先承认 AW/W/B fire，再以 effective_drop 选择完成后继。
mmu_flush_i 单独出现时只把 ad_drop_q 置一，不能进入普通 flush 清理分支。

write owner 只在寄存状态已经是 S_AD_UPDATE 时成立。旧状态仍为 S_WALK_R 的 flush 拍由
读侧取消/排水分支处理，即使该拍返回 A=0 PTE，也不能跨越 flush 新建 write owner。

## Phase 2c：反压与 payload

AWADDR 真源是 walk_pte_addr_q，WDATA 真源是 ad_pte_q。任一 channel 尚未 fire 时，
valid 与 payload 在 repeated flush 和 ready 反压期间保持；已经 fire 的 channel 不重复呈现。
BREADY 在整个 S_AD_UPDATE owner 期间保持。

## Phase 2d：语义静默

sticky drop 后只允许补齐 AW/W 与消费 B。fetch_req_ready、fetch_rsp_valid 和 ARVALID 均为零；
B completion 后直接回 IDLE，不产生 re-walk 或旧请求 fault。

## Phase 2e：结论

当前生产 RTL 的 3/3 focused、109/109 module aggregate 与 18/18 compile-success RTL
verification variants 全部通过，代码结构与上述方程一致。本轮不修改生产 `.v`；增加了
对称同拍 TB、BREADY 背压 owner 检查、机器标记、当前源码验证变体、独立证据重建与账本绑定。
架构来源重绑只更新 Makefile/TB provenance，九项 directed record 的非 provenance 语义投影不变。
