#!/usr/bin/env python3
"""Create one compile-success Q1A semantic mutant with an exact replacement."""

from __future__ import annotations

import sys
from pathlib import Path


MUTATIONS = {
    "no-lookahead": (
        "assign capture_block_o = abort_valid_i || abort_rearm_q ||\n"
        "      ((state_q != ST_UNLOCKED) || request_valid_i);",
        "assign capture_block_o = abort_valid_i || abort_rearm_q ||\n"
        "      (state_q != ST_UNLOCKED);",
    ),
    "no-quiet": ("if (full_quiet_w)", "if (owner_live_empty_i)"),
    "no-live-empty": ("if (full_quiet_w)", "if (mem_context_quiet_i)"),
    "ready-dependent-grant": (
        "assign grant_valid_o = (state_q == ST_COMMIT) && !abort_valid_i;",
        "assign grant_valid_o = (state_q == ST_COMMIT) && !abort_valid_i && grant_ready_i;",
    ),
    "live-input-payload": (
        "assign grant_payload_o = held_payload_q;",
        "assign grant_payload_o = request_payload_i;",
    ),
    "advance-before-consume": (
        "if (grant_fire_w) begin\n"
        "            // grant fire 是 context apply 与 epoch publish 的唯一原子边界。",
        "if (grant_valid_o) begin\n"
        "            // grant fire 是 context apply 与 epoch publish 的唯一原子边界。",
    ),
    "saturating-epoch": (
        "mmu_epoch_q <= mmu_epoch_q + 2'b01;",
        "mmu_epoch_q <= (&mmu_epoch_q) ? mmu_epoch_q : (mmu_epoch_q + 2'b01);",
    ),
    "no-abort-lookahead": (
        "assign capture_block_o = abort_valid_i || abort_rearm_q ||\n"
        "      ((state_q != ST_UNLOCKED) || request_valid_i);",
        "assign capture_block_o = abort_rearm_q ||\n"
        "      ((state_q != ST_UNLOCKED) || request_valid_i);",
    ),
    "no-abort-ready-mask": (
        "!abort_valid_i && !abort_rearm_q;",
        "!abort_rearm_q;",
    ),
    "no-abort-grant-mask": (
        "assign grant_valid_o = (state_q == ST_COMMIT) && !abort_valid_i;",
        "assign grant_valid_o = (state_q == ST_COMMIT);",
    ),
    "low-abort-priority": (
        "end else if (abort_valid_i) begin",
        "end else if (1'b0 && abort_valid_i) begin",
    ),
    "abort-advances-epoch": (
        "abort_rearm_q <= request_valid_i;\n"
        "    end else begin",
        "abort_rearm_q <= request_valid_i;\n"
        "      mmu_epoch_q <= mmu_epoch_q + 2'b01;\n"
        "    end else begin",
    ),
    "no-abort-rearm": (
        "abort_rearm_q <= request_valid_i;",
        "abort_rearm_q <= 1'b0;",
    ),
}


def main() -> int:
    if len(sys.argv) != 4 or sys.argv[3] not in MUTATIONS:
        names = ",".join(sorted(MUTATIONS))
        print(f"usage: {sys.argv[0]} <source> <dest> <mutation>; names={names}", file=sys.stderr)
        return 2
    source = Path(sys.argv[1])
    dest = Path(sys.argv[2])
    old, new = MUTATIONS[sys.argv[3]]
    text = source.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        print(f"mutation {sys.argv[3]} expected one source match, got {count}", file=sys.stderr)
        return 1
    dest.write_text(text.replace(old, new, 1), encoding="utf-8")
    if dest.read_text(encoding="utf-8") == text:
        print(f"mutation {sys.argv[3]} did not change source", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
