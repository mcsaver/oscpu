#!/usr/bin/env python3

from __future__ import annotations

from t3l_branch_target_contract import MASK52, reference_target, signed_bimm, split_target


def main() -> int:
    cases = 0
    quadrant_counts = {(0, 0): 0, (0, 1): 0, (1, 0): 0, (1, 1): 0}
    for pc_low in range(4096):
        for sign in (0, 1):
            for imm_low in range(0, 4096, 2):
                bimm = (sign << 12) | imm_low
                low_sum = pc_low + imm_low
                carry = low_sum >> 12
                split_low = low_sum & 0xFFF
                split_delta = carry - sign
                integer_total = pc_low + signed_bimm(bimm)
                reference_low = integer_total & 0xFFF
                reference_delta = integer_total // 4096
                if split_low != reference_low or split_delta != reference_delta:
                    raise SystemExit(
                        "[T3L-TARGET-DOMAIN] FAIL "
                        f"pc_low={pc_low:#x} bimm={bimm:#x} "
                        f"split=({split_delta},{split_low:#x}) "
                        f"reference=({reference_delta},{reference_low:#x})"
                    )
                quadrant_counts[(sign, carry)] += 1
                cases += 1

    boundary_cases = 0
    pc_high_values = (0, 1, MASK52 - 1, MASK52)
    pc_low_values = (0, 1, 2, 0x7FE, 0x7FF, 0x800, 0xFFE, 0xFFF)
    for pc_high in pc_high_values:
        for pc_low in pc_low_values:
            pc = (pc_high << 12) | pc_low
            for bimm in range(0, 0x2000, 2):
                if split_target(pc, bimm) != reference_target(pc, bimm):
                    raise SystemExit(
                        "[T3L-TARGET-DOMAIN] FAIL boundary "
                        f"pc={pc:#x} bimm={bimm:#x}"
                    )
                boundary_cases += 1

    print(
        "[T3L-TARGET-DOMAIN] PASS "
        f"low_imm_cases={cases} high_wrap_cases={boundary_cases} "
        "quadrants="
        + ",".join(
            f"s{sign}c{carry}:{quadrant_counts[(sign, carry)]}"
            for sign in (0, 1)
            for carry in (0, 1)
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
