# 规范：物理寄存器堆 OooPhysRegFile

> 模块：`vsrc/regread_bypass/OooPhysRegFile.v`。模板见 `../arch/SPEC-TEMPLATE.md`。状态：已实现并验证。

## 1. 目的与范围
统一 PRF(整数),容量 PHY_REG_COUNT=64(`OOO_PHY_REG_ADDR_W`=6)，实体接口为 5R2W：read0-3
服务 issue0/1 的 src1/src2，read8 服务 FP 簇 GPR 源，两个写口服务整数 writeback。
历史 read4-7/9 死读口已随消费端物理删除。提供同拍写-读旁路，使 WB wakeup 后同拍 select
的新发射 uop 直接取得新值。不含 FP(见 OooFpPhysRegFile)。

## 2. 接口与端口
- 读:多个 `readN_addr_i`→`readN_data_o`(组合读)。
- 写:`write0/1_en_i + write0/1_addr_i + write0/1_data_i`(时序写)。
- 复位:regs_q 全 0(x0 物理寄存器恒 0)。
- 恢复:`recover_i`(flush 拍)时 preg1..31 载入已提交架构 GPR(`recover_gprs_i`)、preg32..63 清零
  ——隐含 rename map/freelist 必须同拍复位为恒等映射(flush=映射归位+架构值回灌)。

## 3. 旁路与时序
- **写-读旁路**:读口若 addr 命中本拍 write0/1_addr,直接返回写数据(不等下一拍 regs_q)。
- **写口优先级**:write1 优先于 write0(同 addr 时 write1 胜),保证两拍 writeback 的较新结果生效。
- **x0**:preg0 读恒 0,写被忽略(zero 寄存器语义)。

## 4. 不变量
- **PRF-I1 x0 恒 0**:任何对 preg0 的读返回 0,写无效。
- **PRF-I2 同拍可见**:write 与 read 同拍且 addr 相同 → read 见新值(旁路),write1>write0。
- **PRF-I3 容量**:addr ∈ [0,63];由 rename/free-list 保证不越界。

## 5. 关键路径
Vivado OOC:PRF 单独 3 逻辑级/logic ~0.4ns(浅,健康),非 Fmax 瓶颈。多读口 mux 在综合下为分布式 RAM/LUT。

## 6. 验证
- 模块 TB `tb_ooo_phys_reg_file`;集成 riscv-tests/AM(数据相关、两拍 writeback 旁路、x0 语义)。

## 7. 变更记录
- 2026-06-28：逆向文档化(多读 2 写 / 写-读旁路 / write1>write0 / x0)。
