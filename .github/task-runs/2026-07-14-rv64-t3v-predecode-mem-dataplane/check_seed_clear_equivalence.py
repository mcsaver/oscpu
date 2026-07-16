#!/usr/bin/env python3
"""Exhaustively compare the legacy seed mux with the T3V clear-only form.

The production frontend proves all three legacy seed owners unreachable:

* branch fallthrough capture = 0;
* branch-prefetch hit-to-FIFO = 0;
* JALR-prefetch hit = 0.

Under those constraints, the legacy encoder must never assert ``seed_valid``
and its ``clear`` output must equal the T3V clear-only encoder for every
combination of the remaining controls.
"""

from __future__ import annotations

from itertools import product


CONTROL_NAMES = (
    "csr_trap",
    "direct_flush",
    "branch_spec_restore",
    "pending_branch_commit_resolve",
    "pending_branch_match",
    "pending_branch_misaligned",
    "branch_resolve_untracked",
    "pending_jump_resolve",
    "pending_jump_misaligned",
    "pending_jump_redirect",
    "pending_mem_resolve",
    "system_csr_dispatch",
    "pending_system_csr_commit",
    "head0_csr_commit",
    "drain_complete",
    "drain_pending_arch_trap",
    "drain_pending_system",
    "drain_pending_branch_undispatched",
    "drain_pending_jump",
    "drain_pending_mem",
)


def legacy_outputs(bits: tuple[bool, ...]) -> tuple[bool, bool]:
    control = dict(zip(CONTROL_NAMES, bits, strict=True))
    clear = False
    seed_valid = False

    # Production constraints for all former set_seed guards.
    fallthrough_capture = False
    branch_prefetch_hit = False
    jalr_prefetch_hit = False

    def set_clear() -> None:
        nonlocal clear, seed_valid
        clear = True
        seed_valid = False

    def set_seed() -> None:
        nonlocal clear, seed_valid
        clear = False
        seed_valid = True

    if control["csr_trap"]:
        set_clear()
    elif control["direct_flush"]:
        set_clear()
        if fallthrough_capture:
            set_seed()

    if not control["direct_flush"] and control["branch_spec_restore"]:
        set_clear()

    if control["pending_branch_commit_resolve"]:
        set_clear()
    elif not control["direct_flush"] and control["pending_branch_match"]:
        if control["pending_branch_misaligned"]:
            set_clear()
        elif branch_prefetch_hit:
            set_seed()
        else:
            set_clear()
    elif not control["direct_flush"] and control["branch_resolve_untracked"]:
        set_clear()
    elif not control["direct_flush"] and control["pending_jump_resolve"]:
        if control["pending_jump_misaligned"]:
            set_clear()
        elif control["pending_jump_redirect"]:
            if jalr_prefetch_hit:
                set_seed()
            else:
                set_clear()
    elif not control["direct_flush"] and control["pending_mem_resolve"]:
        pass
    elif not control["direct_flush"] and control["system_csr_dispatch"]:
        pass
    elif not control["direct_flush"] and (
        control["pending_system_csr_commit"] or control["head0_csr_commit"]
    ):
        set_clear()
    elif (
        not control["csr_trap"]
        and not control["direct_flush"]
        and control["drain_complete"]
    ):
        if control["drain_pending_arch_trap"]:
            set_clear()
        elif control["drain_pending_system"]:
            set_clear()
        elif control["drain_pending_branch_undispatched"]:
            set_clear()
        elif control["drain_pending_jump"]:
            if jalr_prefetch_hit:
                set_seed()
            else:
                set_clear()
        elif control["drain_pending_mem"]:
            set_clear()

    if control["csr_trap"]:
        set_clear()

    return clear, seed_valid


def clear_only_output(bits: tuple[bool, ...]) -> bool:
    control = dict(zip(CONTROL_NAMES, bits, strict=True))
    clear = False

    if control["csr_trap"]:
        clear = True
    elif control["direct_flush"]:
        clear = True

    if not control["direct_flush"] and control["branch_spec_restore"]:
        clear = True

    if control["pending_branch_commit_resolve"]:
        clear = True
    elif not control["direct_flush"] and control["pending_branch_match"]:
        clear = True
    elif not control["direct_flush"] and control["branch_resolve_untracked"]:
        clear = True
    elif not control["direct_flush"] and control["pending_jump_resolve"]:
        if control["pending_jump_misaligned"] or control["pending_jump_redirect"]:
            clear = True
    elif not control["direct_flush"] and control["pending_mem_resolve"]:
        pass
    elif not control["direct_flush"] and control["system_csr_dispatch"]:
        pass
    elif not control["direct_flush"] and (
        control["pending_system_csr_commit"] or control["head0_csr_commit"]
    ):
        clear = True
    elif (
        not control["csr_trap"]
        and not control["direct_flush"]
        and control["drain_complete"]
        and (
            control["drain_pending_arch_trap"]
            or control["drain_pending_system"]
            or control["drain_pending_branch_undispatched"]
            or control["drain_pending_jump"]
            or control["drain_pending_mem"]
        )
    ):
        clear = True

    if control["csr_trap"]:
        clear = True

    return clear


def main() -> int:
    checked = 0
    for raw_bits in product((False, True), repeat=len(CONTROL_NAMES)):
        bits = tuple(raw_bits)
        legacy_clear, legacy_seed_valid = legacy_outputs(bits)
        clear_only = clear_only_output(bits)
        checked += 1

        if legacy_seed_valid or legacy_clear != clear_only:
            controls = dict(zip(CONTROL_NAMES, map(int, bits), strict=True))
            print("FAIL seed_clear_equivalence")
            print(f"controls={controls}")
            print(
                "legacy_clear={} legacy_seed_valid={} clear_only={}".format(
                    int(legacy_clear), int(legacy_seed_valid), int(clear_only)
                )
            )
            return 1

    expected = 1 << len(CONTROL_NAMES)
    if checked != expected:
        print(f"FAIL checked={checked} expected={expected}")
        return 1

    print("PASS seed_clear_equivalence")
    print(f"control_bits={len(CONTROL_NAMES)}")
    print(f"combinations={checked}")
    print("constraints=fallthrough_capture=0,branch_prefetch_hit=0,jalr_prefetch_hit=0")
    print("conclusion=legacy_seed_valid_is_zero_and_clear_outputs_match")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
