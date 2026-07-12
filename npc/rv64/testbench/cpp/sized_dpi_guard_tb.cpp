#include "VAxiDpiSlave.h"

#include <svdpi.h>
#include <verilated.h>

#include <cstdarg>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>

#include <sys/mman.h>
#include <sys/resource.h>
#include <sys/wait.h>
#include <unistd.h>

// 直接编译真实 paddr 实现，并在同一 translation unit 内把它的私有 PMEM
// 指针绑定到 guard page；不复制 host_read_sized，避免测试与实现同盲区。
#include "../../csrc/memory/paddr.c"

// paddr.c 的越界 fallback 会引用这些平台服务；边界测试不建 MMIO/trace，
// 用明确的 test-only stub 保持被测对象只聚焦真实 PMEM + sized DPI 路径。
extern "C" bool npc_mmio_read(uint32_t, uint32_t *, enum NpcBusAccess) {
  return false;
}

extern "C" bool npc_mmio_write(uint32_t, uint32_t, uint32_t,
                                enum NpcBusAccess) {
  return false;
}

extern "C" bool npc_mtrace_enabled(void) {
  return false;
}

extern "C" void npc_log_impl(const char *, int, const char *, const char *, ...) {}
extern "C" void npc_log_both_impl(const char *, int, const char *, const char *, ...) {}

namespace {

int g_failures = 0;

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

void reset(VAxiDpiSlave &dut) {
  dut.rst = 1;
  dut.s_axi_arvalid_i = 0;
  dut.s_axi_araddr_i = 0;
  dut.s_axi_arsize_i = 0;
  dut.s_axi_arprot_i = 0;
  dut.s_axi_rready_i = 0;
  dut.s_axi_awvalid_i = 0;
  dut.s_axi_awaddr_i = 0;
  dut.s_axi_wvalid_i = 0;
  dut.s_axi_wdata_i = 0;
  dut.s_axi_wstrb_i = 0;
  dut.s_axi_bready_i = 0;
  tick(dut);
  tick(dut);
  dut.rst = 0;
  dut.eval();
}

void issue_read(VAxiDpiSlave &dut, npc_paddr_t addr, uint32_t arsize,
                uint32_t arprot, npc_word_t expected_data,
                uint32_t expected_resp) {
  dut.s_axi_araddr_i = addr;
  dut.s_axi_arsize_i = arsize;
  dut.s_axi_arprot_i = arprot;
  dut.s_axi_arvalid_i = 1;
  dut.s_axi_rready_i = 0;
  dut.eval();
  expect(dut.s_axi_arready_o == 1, "真实 DPI 请求前 ARREADY 应为 1");

  tick(dut);
  dut.s_axi_arvalid_i = 0;
  dut.eval();
  expect(dut.s_axi_rvalid_o == 1, "真实 DPI 请求应产生 RVALID");
  expect(dut.s_axi_rdata_o == expected_data, "真实 DPI 请求的 RDATA 不符");
  expect(dut.s_axi_rresp_o == expected_resp, "真实 DPI 请求的 RRESP 不符");

  dut.s_axi_rready_i = 1;
  tick(dut);
  dut.s_axi_rready_i = 0;
  dut.eval();
  expect(dut.s_axi_rvalid_o == 0, "真实 DPI 响应 fire 后必须撤销 RVALID");
}

}  // namespace

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  const long page_size_l = sysconf(_SC_PAGESIZE);
  if (page_size_l <= 0) {
    std::perror("sysconf(_SC_PAGESIZE)");
    return 2;
  }
  const size_t page_size = static_cast<size_t>(page_size_l);
  void *mapping = mmap(nullptr, page_size * 2, PROT_READ | PROT_WRITE,
                       MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  if (mapping == MAP_FAILED) {
    std::perror("mmap");
    return 2;
  }
  auto *mapping_bytes = static_cast<uint8_t *>(mapping);
  if (mprotect(mapping_bytes + page_size, page_size, PROT_NONE) != 0) {
    std::perror("mprotect");
    munmap(mapping, page_size * 2);
    return 2;
  }

  constexpr size_t kLogicalPmemSize = 16;
  g_pmem = mapping_bytes + page_size - kLogicalPmemSize;
  g_pmem_size = kLogicalPmemSize;
  g_img_size = 0;
  for (size_t i = 0; i < kLogicalPmemSize; ++i) {
    g_pmem[i] = static_cast<uint8_t>(0x80u + i);
  }

  // 非真空证明：同一地址若真的做固定 8B host read，子进程必须撞上 guard page。
  const pid_t probe_pid = fork();
  if (probe_pid < 0) {
    std::perror("fork");
    munmap(mapping, page_size * 2);
    return 2;
  }
  if (probe_pid == 0) {
    const struct rlimit no_core = {0, 0};
    setrlimit(RLIMIT_CORE, &no_core);
    volatile const uint8_t *fixed8_base = g_pmem + kLogicalPmemSize - 2;
    volatile uint64_t fixed8_data = 0;
    for (unsigned lane = 0; lane < 8; ++lane) {
      fixed8_data |= static_cast<uint64_t>(fixed8_base[lane]) << (lane * 8);
    }
    _exit(static_cast<int>(fixed8_data & 0xffu));
  }
  int probe_status = 0;
  if (waitpid(probe_pid, &probe_status, 0) != probe_pid) {
    std::perror("waitpid");
    munmap(mapping, page_size * 2);
    return 2;
  }
  expect(WIFSIGNALED(probe_status) && WTERMSIG(probe_status) == SIGSEGV,
         "guard page 非真空探针必须让固定 8B read 触发 SIGSEGV");

  // 最后两个合法字节紧贴 PROT_NONE 页。完整走
  // AxiDpiSlave -> npc_*_sized -> npc_paddr_read_sized：固定 8B host read
  // 会越过页边界，而正确的 2B 路径必须返回成功。
  const npc_paddr_t tail_addr = NPC_PMEM_BASE + kLogicalPmemSize - 2;
  const npc_word_t expected = UINT64_C(0x8f8e);

  VAxiDpiSlave dut;
  reset(dut);
  issue_read(dut, tail_addr, 1, 4, expected << 48, 0);
  issue_read(dut, tail_addr, 1, 0, expected, 0);
  // 紧邻 PMEM 之后的 IFU 请求不得碰 guard page，应返回 SLVERR + zero。
  issue_read(dut, NPC_PMEM_BASE + kLogicalPmemSize, 1, 4, 0, 2);
  dut.final();

  munmap(mapping, page_size * 2);
  g_pmem = nullptr;
  g_pmem_size = 0;

  if (g_failures != 0) {
    std::fprintf(stderr, "SIZED_DPI_GUARD_FAIL failures=%d\n", g_failures);
    return 1;
  }
  std::printf("SIZED_DPI_GUARD_PASS e2e=AxiDpiSlave-dpi-paddr tail_addr=0x%016llx bytes=2 guard=PROT_NONE guard_probe=SIGSEGV data=0x%04llx\n",
              static_cast<unsigned long long>(tail_addr),
              static_cast<unsigned long long>(expected));
  return 0;
}
