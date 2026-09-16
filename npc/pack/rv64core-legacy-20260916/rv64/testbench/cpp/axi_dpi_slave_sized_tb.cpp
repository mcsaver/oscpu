#include "VAxiDpiSlave.h"

#include <svdpi.h>
#include <verilated.h>

#include <cstdint>
#include <cstdio>

namespace {

enum class ReadKind {
  kNone,
  kIfetch,
  kData,
};

struct ReadCall {
  ReadKind kind = ReadKind::kNone;
  uint64_t addr = 0;
  uint32_t nbytes = 0;
};

ReadCall g_last_call;
unsigned g_read_calls = 0;
struct WriteCall {
  uint64_t addr = 0;
  uint64_t data = 0;
  uint64_t mask = 0;
};
WriteCall g_last_write;
unsigned g_write_calls = 0;
int g_failures = 0;

uint64_t ifetch_payload(uint64_t addr, uint32_t nbytes) {
  const uint64_t mask = nbytes == 8 ? ~UINT64_C(0)
                                    : ((UINT64_C(1) << (nbytes * 8)) - 1);
  return (UINT64_C(0xa000) | (addr & UINT64_C(0xff))) & mask;
}

uint64_t data_payload(uint64_t addr, uint32_t nbytes) {
  const uint64_t mask = nbytes == 8 ? ~UINT64_C(0)
                                    : ((UINT64_C(1) << (nbytes * 8)) - 1);
  return (UINT64_C(0x8877665544330000) | (addr & UINT64_C(0xffff))) & mask;
}

void expect(bool condition, const char *message) {
  if (!condition) {
    std::fprintf(stderr, "[FAIL] %s\n", message);
    ++g_failures;
  }
}

void tick(VAxiDpiSlave &dut) {
  dut.clk = 0;
  dut.eval();
  dut.clk = 1;
  dut.eval();
  dut.clk = 0;
  dut.eval();
}

void init_inputs(VAxiDpiSlave &dut) {
  dut.rst = 1;
  dut.s_axi_arvalid_i = 0;
  dut.s_axi_araddr_i = 0;
  dut.s_axi_arsize_i = 0;
  dut.s_axi_arprot_i = 0;
  dut.s_axi_rready_i = 0;
  dut.s_axi_awvalid_i = 0;
  dut.s_axi_awaddr_i = 0;
  dut.s_axi_awsize_i = 0;
  dut.s_axi_wvalid_i = 0;
  dut.s_axi_wdata_i = 0;
  dut.s_axi_wstrb_i = 0;
  dut.s_axi_bready_i = 0;
}

void reset(VAxiDpiSlave &dut) {
  init_inputs(dut);
  tick(dut);
  tick(dut);
  dut.rst = 0;
  dut.eval();
  expect(dut.s_axi_arready_o == 1, "reset 后读地址通道应 ready");
  expect(dut.s_axi_rvalid_o == 0, "reset 后不应残留读响应");
}

void issue_read(VAxiDpiSlave &dut, uint64_t addr, uint32_t arsize,
                uint32_t arprot, uint64_t expected_data,
                uint32_t expected_resp, ReadKind expected_kind,
                uint32_t expected_nbytes) {
  const unsigned calls_before = g_read_calls;
  dut.s_axi_araddr_i = addr;
  dut.s_axi_arsize_i = arsize;
  dut.s_axi_arprot_i = arprot;
  dut.s_axi_arvalid_i = 1;
  dut.s_axi_rready_i = 0;
  dut.eval();
  expect(dut.s_axi_arready_o == 1, "发读请求前 ARREADY 应为 1");

  tick(dut);
  dut.s_axi_arvalid_i = 0;
  dut.eval();

  expect(dut.s_axi_rvalid_o == 1, "AR fire 后应产生 RVALID");
  expect(dut.s_axi_rdata_o == expected_data, "RDATA 与 lane/low-window 预期不符");
  expect(dut.s_axi_rresp_o == expected_resp, "RRESP 与预期不符");
  if (expected_kind == ReadKind::kNone) {
    expect(g_read_calls == calls_before, "非法 ARSIZE 不应调用任何 DPI read");
  } else {
    expect(g_read_calls == calls_before + 1, "一次 AXI read 必须恰好调用一次 DPI read");
    expect(g_last_call.kind == expected_kind, "ARPROT[2] 没有选择正确的 DPI read 类型");
    expect(g_last_call.addr == addr, "DPI read 地址与 ARADDR 不一致");
    expect(g_last_call.nbytes == expected_nbytes, "DPI nbytes 与 ARSIZE 不一致");
  }

  const uint64_t held_data = dut.s_axi_rdata_o;
  const uint32_t held_resp = dut.s_axi_rresp_o;
  tick(dut);
  expect(dut.s_axi_rvalid_o == 1, "RREADY=0 时 RVALID 不得撤回");
  expect(dut.s_axi_rdata_o == held_data && dut.s_axi_rresp_o == held_resp,
         "RREADY=0 时响应 payload 必须稳定");

  dut.s_axi_rready_i = 1;
  tick(dut);
  dut.s_axi_rready_i = 0;
  dut.eval();
  expect(dut.s_axi_rvalid_o == 0, "R fire 后必须撤销 RVALID");
}

void issue_write(VAxiDpiSlave &dut, uint64_t addr, uint32_t awsize,
                 uint64_t bus_data, uint64_t bus_strb,
                 uint32_t expected_resp, bool expect_dpi,
                 uint64_t expected_data, uint64_t expected_mask) {
  const unsigned calls_before = g_write_calls;
  dut.s_axi_awaddr_i = addr;
  dut.s_axi_awsize_i = awsize;
  dut.s_axi_wdata_i = bus_data;
  dut.s_axi_wstrb_i = bus_strb;
  dut.s_axi_awvalid_i = 1;
  dut.s_axi_wvalid_i = 1;
  dut.s_axi_bready_i = 0;
  dut.eval();
  expect(dut.s_axi_awready_o == 1, "发写请求前 AWREADY 应为 1");
  expect(dut.s_axi_wready_o == 1, "发写请求前 WREADY 应为 1");

  tick(dut);
  dut.s_axi_awvalid_i = 0;
  dut.s_axi_wvalid_i = 0;
  dut.eval();
  expect(dut.s_axi_bvalid_o == 1, "AW/W fire 后应产生 BVALID");
  expect(dut.s_axi_bresp_o == expected_resp, "BRESP 与预期不符");
  if (expect_dpi) {
    expect(g_write_calls == calls_before + 1,
           "合法 AXI write 必须恰好调用一次 DPI write");
    expect(g_last_write.addr == addr, "DPI write 地址与 AWADDR 不一致");
    expect(g_last_write.data == expected_data,
           "标准 lane WDATA 未归一化为 DPI low-window");
    expect(g_last_write.mask == expected_mask,
           "标准 lane WSTRB 未归一化为 DPI low-window");
  } else {
    expect(g_write_calls == calls_before,
           "非法 AXI write 不应调用 DPI write");
  }

  const uint32_t held_resp = dut.s_axi_bresp_o;
  tick(dut);
  expect(dut.s_axi_bvalid_o == 1, "BREADY=0 时 BVALID 不得撤回");
  expect(dut.s_axi_bresp_o == held_resp,
         "BREADY=0 时写响应 payload 必须稳定");

  dut.s_axi_bready_i = 1;
  tick(dut);
  dut.s_axi_bready_i = 0;
  dut.eval();
  expect(dut.s_axi_bvalid_o == 0, "B fire 后必须撤销 BVALID");
}

}  // namespace

extern "C" void npc_ifetch_sized(uint64_t addr, uint32_t nbytes,
                                  uint64_t *data, svBit *error) {
  g_last_call = {ReadKind::kIfetch, addr, nbytes};
  ++g_read_calls;
  *data = ifetch_payload(addr, nbytes);
  *error = 0;
}

extern "C" void npc_mem_read_sized(uint64_t addr, uint32_t nbytes,
                                    uint64_t *data, svBit *error) {
  g_last_call = {ReadKind::kData, addr, nbytes};
  ++g_read_calls;
  *data = data_payload(addr, nbytes);
  *error = 0;
}

extern "C" void npc_mem_write(uint64_t addr, uint64_t data, uint64_t mask,
                                svBit *error) {
  g_last_write = {addr, data, mask};
  ++g_write_calls;
  *error = 0;
}

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  VAxiDpiSlave dut;
  reset(dut);

  // IFU 2B read 必须按 ARADDR[2:0] 放入标准 AXI byte lane。
  for (uint64_t lane = 0; lane < 8; lane += 2) {
    const uint64_t addr = UINT64_C(0x80000000) + lane;
    const uint64_t low = ifetch_payload(addr, 2);
    issue_read(dut, addr, 1, 4, low << (lane * 8), 0,
               ReadKind::kIfetch, 2);
  }

  // LSU/PTW 与 IFU 使用同一标准 AXI byte-lane ABI。
  const uint64_t data_addr = UINT64_C(0x80000006);
  issue_read(dut, data_addr, 1, 0,
             data_payload(data_addr, 2) << (6 * 8), 0,
             ReadKind::kData, 2);
  const uint64_t ptw_addr = UINT64_C(0x80000008);
  issue_read(dut, ptw_addr, 3, 0, data_payload(ptw_addr, 8), 0,
             ReadKind::kData, 8);

  // AXI size > 8B 不能下沉到宿主，必须本地返回 SLVERR。
  issue_read(dut, UINT64_C(0x80000000), 4, 4, 0, 2,
             ReadKind::kNone, 0);

  // 写通道从标准 lane 归一化回 exact-address + low-window DPI ABI。
  issue_write(dut, UINT64_C(0x80000005), 0,
              UINT64_C(0xab) << (5 * 8), UINT64_C(1) << 5,
              0, true, UINT64_C(0xab), UINT64_C(0x1));
  issue_write(dut, UINT64_C(0x80000006), 1,
              UINT64_C(0xbeef) << (6 * 8), UINT64_C(0x3) << 6,
              0, true, UINT64_C(0xbeef), UINT64_C(0x3));
  issue_write(dut, UINT64_C(0x80000004), 2,
              UINT64_C(0x11223344) << 32, UINT64_C(0xf0),
              0, true, UINT64_C(0x11223344), UINT64_C(0xf));
  issue_write(dut, UINT64_C(0x80000008), 3,
              UINT64_C(0x8877665544332211), UINT64_C(0xff),
              0, true, UINT64_C(0x8877665544332211), UINT64_C(0xff));

  // 跨 bus-window、稀疏 strobe 与超大 size 都必须本地 SLVERR，零 DPI 副作用。
  issue_write(dut, UINT64_C(0x80000007), 1,
              UINT64_C(0xaa) << 56, UINT64_C(0x80),
              2, false, 0, 0);
  issue_write(dut, UINT64_C(0x80000000), 2,
              UINT64_C(0x44332211), UINT64_C(0x3),
              2, false, 0, 0);
  issue_write(dut, UINT64_C(0x80000000), 4,
              UINT64_C(0), UINT64_C(0),
              2, false, 0, 0);

  dut.final();
  if (g_failures != 0) {
    std::fprintf(stderr, "AXI_DPI_SIZED_FAIL failures=%d calls=%u\n",
                 g_failures, g_read_calls);
    return 1;
  }
  std::printf("AXI_DPI_SIZED_PASS ifetch_lanes=4 data_lanes=2 invalid_read=1 "
              "write_lanes=4 invalid_writes=3 read_calls=%u write_calls=%u\n",
              g_read_calls, g_write_calls);
  return 0;
}
