#ifndef NPC_CPU_DIFFTEST_COMPARE_POLICY_H
#define NPC_CPU_DIFFTEST_COMPARE_POLICY_H

#include <cstdint>

namespace npc_difftest_policy {

// FS[14:13] and SD[63] are excluded because the dual-retire CSR snapshot
// cannot observe every same-cycle dirty-state transition precisely.  VS is
// intentionally not excluded: CsrFile retains mstatus.VS[10:9] for the
// privileged RV64 virtual-memory test profile even though misa.V is clear.
constexpr std::uint64_t kMstatusFsMask = UINT64_C(0x6000);
constexpr std::uint64_t kMstatusVsMask = UINT64_C(0x0600);
constexpr std::uint64_t kMstatusSdMask = UINT64_C(1) << 63;
constexpr std::uint64_t kMstatusProfileExcludedMask =
    kMstatusFsMask | kMstatusSdMask;

constexpr std::uint64_t csr_compare_mask(int csr_index) {
  return csr_index == 0
      ? ~kMstatusProfileExcludedMask
      : ~UINT64_C(0);
}

constexpr bool csr_values_match(
    int csr_index, std::uint64_t reference, std::uint64_t dut) {
  return (reference & csr_compare_mask(csr_index)) ==
         (dut & csr_compare_mask(csr_index));
}

static_assert(!csr_values_match(0, 0, kMstatusVsMask),
              "mstatus.VS must remain compared");
static_assert(!csr_values_match(0, 0, UINT64_C(3) << 11),
              "mstatus.MPP must remain compared");
static_assert(!csr_values_match(0, 0, UINT64_C(1) << 17),
              "mstatus.MPRV must remain compared");
static_assert(!csr_values_match(0, 0, UINT64_C(1) << 18),
              "mstatus.SUM must remain compared");
static_assert(!csr_values_match(0, 0, UINT64_C(1) << 19),
              "mstatus.MXR must remain compared");

}  // namespace npc_difftest_policy

#endif  // NPC_CPU_DIFFTEST_COMPARE_POLICY_H
