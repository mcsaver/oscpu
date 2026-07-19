#!/usr/bin/env python3
"""Reproduce the exact bounded-recall threshold that exposed the runner default drift."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


RUN_DIR = Path(__file__).resolve().parent
REPO_ROOT = RUN_DIR.parents[2]
INDEX_CLI = REPO_ROOT / "scripts/github_index_db.py"
PROFILE = "npc-dev"
TERMS = "RV64-PPA-S2-Q2"
EXPECTED_FOCUS = ".github/memory/modules/npc.md#chunk-0002"


def brief(max_tokens: int) -> tuple[subprocess.CompletedProcess[str], dict[str, object]]:
    result = subprocess.run(
        [
            sys.executable,
            str(INDEX_CLI),
            "brief",
            TERMS,
            "--profile",
            PROFILE,
            "--focus-limit",
            "1",
            "--max-tokens",
            str(max_tokens),
            "--json",
        ],
        cwd=REPO_ROOT,
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return result, json.loads(result.stdout)


def main() -> int:
    underflow_result, underflow = brief(1905)
    exact_result, exact = brief(1906)
    underflow_focus = (underflow.get("primary_focus") or {}).get("chunk_id")
    exact_focus = (exact.get("primary_focus") or {}).get("chunk_id")
    checks = [
        underflow_result.returncode != 0,
        underflow.get("ok") is False,
        underflow.get("recall_status") == "failed",
        underflow_focus == EXPECTED_FOCUS,
        "primary focus exceeds remaining token budget" in str(underflow.get("error")),
        exact_result.returncode == 0,
        exact.get("ok") is True,
        exact.get("recall_status") == "complete",
        exact.get("token_estimate") == 1906,
        exact.get("max_tokens") == 1906,
        exact_focus == EXPECTED_FOCUS,
    ]
    if not all(checks):
        print(
            "FAIL ai-v10-brief-budget "
            f"underflow_rc={underflow_result.returncode} underflow={underflow} "
            f"exact_rc={exact_result.returncode} exact={exact}"
        )
        return 1
    print(
        "PASS ai-v10-brief-budget "
        "required_tokens=1906 underflow_tokens=1905 "
        f"primary_focus={EXPECTED_FOCUS}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
