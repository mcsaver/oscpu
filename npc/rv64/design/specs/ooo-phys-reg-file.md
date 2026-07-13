# 规范：物理寄存器堆 OooPhysRegFile

> 模块：`vsrc/regread_bypass/OooPhysRegFile.v`。模板见 `../arch/SPEC-TEMPLATE.md`。状态：已实现并验证。

## 1. 目的与范围
统一 PRF(整数),容量 PHY_REG_COUNT=64(`OOO_PHY_REG_ADDR_W`=6)，实体接口为 5R2W：read0-3
服务 issue0/1 的 src1/src2，read8 服务 FP 簇 GPR 源，两个写口服务整数 writeback。
历史 read4-7/9 死读口已随消费端物理删除。提供同拍写-读旁路，使 WB wakeup 后同拍 select
的新发射 uop 直接取得新值。不含 FP(见 OooFpPhysRegFile)。

## 2. 接口与端口
- 读:多个 `readN_addr_i`→`readN_data_o`(组合读)。
- full写:`write0/1_valid_i + write0/1_addr_i + write0/1_data_i`(时序写，所有正式WB source)。
- fast旁路:`bypass0/1_valid_i + bypass0/1_addr_i + bypass0/1_data_i`，只允许 EX winner；
  只由 read0–3 消费。read8 不消费 full 或 fast 同拍旁路。
- 复位:regs_q 全 0(x0 物理寄存器恒 0)。
- 恢复:`recover_i`(flush 拍)时 preg1..31 载入已提交架构 GPR(`recover_gprs_i`)、preg32..63 清零
  ——隐含 rename map/freelist 必须同拍复位为恒等映射(flush=映射归位+架构值回灌)。

## 3. 旁路与时序
- **写-读旁路**:read0–3若 addr 命中本拍 fast bypass，直接返回新数据；non-fast full write
  在沿前仍读旧 `regs_q`、上升沿写入后读新值。read8 始终只读
  已落账 `regs_q`，不存在写-读旁路。
- **写口优先级**:write1 优先于 write0(同 addr 时 write1 胜),保证两拍 writeback 的较新结果生效。
- **旁路优先级**:bypass1优先于bypass0；每个 bypass 必须是同 lane full write 的逐位子集。
- **x0**:preg0 读恒 0,写被忽略(zero 寄存器语义)。

## 4. 不变量
- **PRF-I1 x0 恒 0**:任何对 preg0 的读返回 0,写无效。
- **PRF-I2 分类可见**:fast bypass 与 read0–3同拍命中→见新值；full-only write同拍→read0–3
  沿前旧、沿后新；read8 对任何 full/fast 事件都是沿前旧、沿后新。
  read0–3 的 fast 冲突中 lane1 优先级高于 lane0。
- **PRF-I3 容量**:addr ∈ [0,63];由 rename/free-list 保证不越界。
- **PRF-I4 fast/full 子集**:任一 bypass valid 必须匹配同 lane full write valid/addr/data；
  fast 不写状态，full write仍是 `regs_q` 唯一更新真源。

## 5. 关键路径
Vivado OOC:PRF 单独 3 逻辑级/logic ~0.4ns(浅,健康),非 Fmax 瓶颈。多读口 mux 在综合下为分布式 RAM/LUT。

## 6. 验证
- 模块 TB `tb_ooo_phys_reg_file`;集成 riscv-tests/AM(数据相关、两拍 writeback 旁路、x0 语义)。

## 7. 变更记录
- 2026-06-28：逆向文档化(多读 2 写 / 写-读旁路 / write1>write0 / x0)。
- 2026-07-13：T3B 把 read0–3 收窄为 EX/MEM fast bypass；T3F 进一步删除 read8
  同拍旁路；T3G 再将 read0–3 fast 收紧为 EX-only，MEM 在 formal WB 后 N+1 读取。
