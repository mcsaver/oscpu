# V9K PTW-PMP-G1 current-design contract

## 本地 RV64 RTL 范围

本任务只验证 `OooFetchAxiBridge` 与 `OooMemAxiBridge` 的隐式页表 PTE
A/D 写回。PTE READ 许可不能替代后续 PTE WRITE 许可；WRITE query 必须使用
当前 leaf PTE 物理地址、8B access size、S-mode privilege 与 WRITE access type。

## 必须成立的周期合同

1. WRITE deny 的 leaf response 接受拍不进入 `S_AD_UPDATE`，且该拍
   `AWVALID=0`、`WVALID=0`。
2. 下一拍形成原 instruction/load/store 的 access fault，而非 page fault；响应保持期间
   `ARVALID/AWVALID/WVALID` 继续为零。
3. IFU second-page WRITE deny 在 F=2/4/6 时保留此前成功 instruction byte prefix，
   fault suffix 不产生更年轻 instruction AR。
4. LSU load-A/store-D deny 保持已接受事务的 owner kind、token、MMU epoch 与 original VA
   `fault_tval`，不受后续 live request input 改变影响。
5. WRITE grant 必须进入 `S_AD_UPDATE`，`AWADDR` 必须逐位等于产生该次
   checker grant 的 registered PTE physical address；以 `AWSIZE=3`、全 8B
   WSTRB 呈现 AW/W。
6. 8B partial-cover PMP counterexample 必须 deny；这用于区别错误的 4B checker。
7. AW/W 允许独立 READY/VALID 握手；任一通道 `VALID&&!READY` 时其
   VALID 与 payload 必须保持，每个通道恰好接受一次，两者均接受前
   不得完成该 PTE 写事务。
8. LSU WRITE deny 形成的 response 必须对 READY 延迟 0/1/2/3/5 拍逐点成立；
   owner kind/token/MMU epoch/original VA `fault_tval` 与 fault class 不变。
   周期监视器从 checker deny 决策跟踪到 response handshake/drop terminal，
   在 `AWREADY=WREADY=1` 的全区间要求 `AWVALID=WVALID=0`，包含终止拍。
9. 静默区间的上界不依赖有限激励拍数：生产 RTL 中 `lsu_axi_awvalid_o`
   与 `lsu_axi_wvalid_o` 的完整连续赋值只含 `S_WRITE_REQ`/`S_AD_UPDATE`，
   不含 `S_RESP`；WRITE deny 精确进入 `S_RESP`，`rsp_ready_w=0` 时
   `stage_advance_w=0` 且正常 FSM 保持 `S_RESP`，kill 分支则产生 exact drop terminal。
   该结构证书必须通过对 `S_RESP` 加入 AW/W VALID 译码项的静态负例。

## 证据与声明边界

- canonical command：`make -C npc/rv64 check-ptw-pmp`。
- focused bridge TB、完整 module aggregate、compile-success current-source RTL variants、
  fail-closed evidence parser 与 architecture freeze validator 必须共同通过。
- current-design result 必须绑定 full RTL design_id 与所有 source/test/tool 输入 SHA。
- PTW-PMP-G1 的 IFU 边界终止于 bridge 输出的 exact successful byte prefix 与
  instruction access-fault class。下游 lane owner/故障 PC/`tval` 传播分别由已闭合的
  `IFU-ACCESS-G1` 与 `IFU-TVAL-G1` 管理，不在本 gate 重复声称。
- 本地 bridge 的 PTE WRITE 接口无 `AWPROT` port；本 gate 不虚构该字段。
- 本任务不修改 production `.v` RTL；PPA 保持 `UNQUALIFIED`，
  `promotion_eligible=false`，不得外推为 full-core arch-stable 或 200MHz 完成。
