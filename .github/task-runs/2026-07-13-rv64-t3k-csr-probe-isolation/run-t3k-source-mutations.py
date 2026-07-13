#!/usr/bin/env python3
"""Mutation ratchet for T3K structure and legality-domain evidence."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
import subprocess
import sys
import tempfile

from t3k_csr_contract import ContractError, replace_unique, require, source_paths


MARKER = "[T3K-SOURCE-MUTATIONS]"
TASK_DIR = Path(__file__).resolve().parent
CHECKER = TASK_DIR / "check-t3k-source-contract.py"
PROOF = TASK_DIR / "prove-t3k-legality-domain.py"
SOURCE_NAMES = (
    "OooCsrAccessRequestMux.v",
    "OooControlPlane.v",
    "OooCoreTopGlue.v",
    "NpcCoreTop.v",
    "CsrFile.v",
)


@dataclass(frozen=True)
class Result:
    returncode: int
    output: str


def run(script: Path, root: Path, files: tuple[Path, ...]) -> Result:
    command = [
        sys.executable,
        str(script),
        str(root),
        "--mux",
        str(files[0]),
        "--control",
        str(files[1]),
        "--glue",
        str(files[2]),
        "--top",
        str(files[3]),
        "--csr",
        str(files[4]),
    ]
    result = subprocess.run(
        command,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    return Result(result.returncode, result.stdout)


def exact_failure(result: Result, marker: str, code: str, label: str) -> None:
    needle = f"{marker} FAIL {code}:"
    count = result.output.count(needle)
    require(
        result.returncode != 0 and count == 1,
        "E_MUTATION_NOT_REJECTED",
        f"{label}: expected one {needle}, rc={result.returncode} count={count}\n{result.output}",
    )
    require(
        f"{marker} PASS " not in result.output,
        "E_MUTATION_FALSE_GREEN",
        f"{label}: failure output also contains PASS\n{result.output}",
    )


def write_case(case_dir: Path, sources: tuple[str, ...]) -> tuple[Path, ...]:
    case_dir.mkdir()
    paths = tuple(case_dir / name for name in SOURCE_NAMES)
    for path, source in zip(paths, sources):
        path.write_text(source, encoding="utf-8")
    return paths


def source_mutation(
    name: str,
    root: Path,
    work_dir: Path,
    sources: tuple[str, ...],
    index: int,
    old: str,
    new: str,
    expected_code: str,
) -> None:
    mutated = list(sources)
    mutated[index] = replace_unique(mutated[index], old, new)
    files = write_case(work_dir / name, tuple(mutated))
    result = run(CHECKER, root, files)
    exact_failure(result, "[T3K-SOURCE-CONTRACT]", expected_code, name)
    print(f"[T3K-MUTATION-{name.upper().replace('-', '_')}] PASS gate=source expected={expected_code}")


def semantic_mutation(
    name: str,
    root: Path,
    work_dir: Path,
    sources: tuple[str, ...],
    old: str,
    new: str,
    mismatch_marker: str = "[T3K-RAW-REFERENCE-MISMATCH]",
) -> None:
    mutated = list(sources)
    mutated[4] = replace_unique(mutated[4], old, new)
    files = write_case(work_dir / name, tuple(mutated))
    source_result = run(CHECKER, root, files)
    require(
        source_result.returncode == 0 and source_result.output.count("[T3K-SOURCE-CONTRACT] PASS ") == 1,
        "E_MUTATION_SEMANTIC_PREMISE",
        f"{name}: semantic mutation must pass structure gate before domain proof\n{source_result.output}",
    )
    proof_result = run(PROOF, root, files)
    exact_failure(proof_result, "[T3K-LEGALITY-DOMAIN-PROOF]", "E_PROOF_FAIL_MARKER", name)
    require(
        proof_result.output.count(mismatch_marker) == 1,
        "E_MUTATION_MISMATCH_MARKER",
        f"{name}: expected one runtime mismatch marker {mismatch_marker}\n{proof_result.output}",
    )
    print(
        f"[T3K-MUTATION-{name.upper().replace('-', '_')}] PASS "
        f"gate=domain structure=GREEN expected_runtime={mismatch_marker}"
    )


def execute(root: Path, work_dir: Path, paths: tuple[Path, ...]) -> int:
    sources = tuple(path.read_text(encoding="utf-8") for path in paths)
    baseline_source = run(CHECKER, root, paths)
    require(
        baseline_source.returncode == 0 and baseline_source.output.count("[T3K-SOURCE-CONTRACT] PASS ") == 1,
        "E_MUTATION_BASELINE",
        f"source baseline must pass before mutations\n{baseline_source.output}",
    )
    baseline_proof = run(PROOF, root, paths)
    require(
        baseline_proof.returncode == 0 and baseline_proof.output.count("[T3K-LEGALITY-DOMAIN-PROOF] PASS ") == 1,
        "E_MUTATION_BASELINE",
        f"domain baseline must pass before mutations\n{baseline_proof.output}",
    )
    print(baseline_source.output.rstrip())
    print(baseline_proof.output.rstrip())

    source_mutation(
        "legacy-single-port",
        root,
        work_dir,
        sources,
        4,
        "assign csr_illegal_o = csr_probe_illegal_w;",
        "assign csr_illegal_o = csr_access_illegal_w;",
        "E_CSR_PROBE_CALL",
    )
    source_mutation(
        "probe-call-uses-access-payload",
        root,
        work_dir,
        sources,
        4,
        "csr_probe_addr_i, csr_probe_funct3_i, csr_probe_rs1_idx_i,",
        "csr_addr_i, csr_funct3_i, csr_rs1_idx_i,",
        "E_CSR_PROBE_CALL",
    )
    source_mutation(
        "side-effect-uses-public-probe",
        root,
        work_dir,
        sources,
        4,
        "csr_commit_i && csr_valid_i && ~csr_access_illegal_w && csr_need_write_w",
        "csr_commit_i && csr_valid_i && ~csr_illegal_o && csr_need_write_w",
        "E_CSR_SIDE_EFFECT_GUARD",
    )
    source_mutation(
        "probe-valid-polluted-by-pending",
        root,
        work_dir,
        sources,
        0,
        "assign csr_probe_valid_o = head0_csr_raw_i || head1_csr_probe_o;",
        "assign csr_probe_valid_o = pending_system_i || head0_csr_raw_i || head1_csr_probe_o;",
        "E_MUX_PROBE_VALID",
    )
    source_mutation(
        "probe-priority-reversed",
        root,
        work_dir,
        sources,
        0,
        "wire [`INST_W-1:0] csr_probe_inst_w =\n"
        "      head1_csr_probe_o ? head_inst1_i : head_inst0_i;",
        "wire [`INST_W-1:0] csr_probe_inst_w =\n"
        "      head0_csr_raw_i ? head_inst0_i : head_inst1_i;",
        "E_MUX_PROBE_PRIORITY",
    )
    source_mutation(
        "top-probe-addr-crosswired",
        root,
        work_dir,
        sources,
        3,
        ".csr_probe_addr_i(ooo_csr_probe_addr_w)",
        ".csr_probe_addr_i(ooo_csr_access_addr_w)",
        "E_WIRE_TOP_CSR",
    )

    semantic_mutation(
        "drop-tvm-policy",
        root,
        work_dir,
        sources,
        "          csr_satp_tvm_illegal ||",
        "          1'b0 ||",
    )
    semantic_mutation(
        "drop-counter-policy",
        root,
        work_dir,
        sources,
        "          !csr_counter_allowed ||",
        "          1'b0 ||",
    )
    semantic_mutation(
        "invert-privilege-boundary",
        root,
        work_dir,
        sources,
        "          !(priv_mode >= csr_addr[9:8]) ||",
        "          !(priv_mode > csr_addr[9:8]) ||",
    )
    semantic_mutation(
        "invert-writable-test",
        root,
        work_dir,
        sources,
        "           !csr_addr_writable(csr_addr));",
        "           csr_addr_writable(csr_addr));",
    )
    return 10


def parse_args() -> argparse.Namespace:
    default_root = Path(__file__).resolve().parents[3]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo_root", nargs="?", type=Path, default=default_root)
    parser.add_argument("--mux", type=Path)
    parser.add_argument("--control", type=Path)
    parser.add_argument("--glue", type=Path)
    parser.add_argument("--top", type=Path)
    parser.add_argument("--csr", type=Path)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    root = args.repo_root.resolve()
    defaults = source_paths(root)
    paths = tuple(
        (override or default).resolve()
        for override, default in zip(
            (args.mux, args.control, args.glue, args.top, args.csr),
            defaults,
        )
    )
    try:
        with tempfile.TemporaryDirectory(prefix="t3k-source-mutations-") as temporary:
            count = execute(root, Path(temporary), paths)
    except (ContractError, OSError, UnicodeError) as error:
        code = error.code if isinstance(error, ContractError) else "E_IO"
        print(f"{MARKER} FAIL {code}: {error}", file=sys.stderr)
        raise SystemExit(1)
    print(f"{MARKER} PASS cases={count} source_red=6 semantic_domain_red=4")


if __name__ == "__main__":
    main()
