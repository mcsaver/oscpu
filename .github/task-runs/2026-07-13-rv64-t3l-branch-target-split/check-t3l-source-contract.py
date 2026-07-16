#!/usr/bin/env python3

from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

from t3l_branch_target_contract import FILES, ContractError, load_live, validate_sources


def load_revision(repo_root: Path, revision: str) -> dict[str, str]:
    result: dict[str, str] = {}
    for key, rel in FILES.items():
        proc = subprocess.run(
            ["git", "-C", str(repo_root), "show", f"{revision}:{rel.as_posix()}"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        if proc.returncode != 0:
            result[key] = ""
        else:
            result[key] = proc.stdout
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--git-revision")
    parser.add_argument("--expect", choices=("fresh", "legacy"), default="fresh")
    args = parser.parse_args()
    root = args.repo_root.resolve()
    files = load_revision(root, args.git_revision) if args.git_revision else load_live(root)
    try:
        stats = validate_sources(files)
    except ContractError as exc:
        if args.expect == "legacy":
            print(f"[T3L-SOURCE-CONTRACT] EXPECTED-RED code={exc.code} detail={exc.detail}")
            return 0
        print(f"[T3L-SOURCE-CONTRACT] FAIL code={exc.code} detail={exc.detail}")
        return 1
    if args.expect == "legacy":
        print("[T3L-SOURCE-CONTRACT] FALSE-GREEN legacy source passed fresh contract")
        return 1
    print(
        "[T3L-SOURCE-CONTRACT] PASS "
        f"decoder_bimm_ports={stats.decoder_bimm_ports} "
        f"frontend_bimm_wires={stats.frontend_bimm_wires} "
        f"target_instances={stats.target_instances} "
        f"target_named_connections={stats.target_named_connections} "
        f"filelist_references={stats.filelist_references}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
