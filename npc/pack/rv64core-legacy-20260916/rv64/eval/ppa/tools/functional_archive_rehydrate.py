#!/usr/bin/env python3
"""Rehydrate one compacted RV64 functional archive without executing the DUT.

The original execution result and compaction receipts remain immutable.  This
tool restores only content-identical simulator/reference/program artifacts,
rewrites their paths in a versioned aggregate, and runs the canonical
functional aggregate validator over the retained logs.
"""

from __future__ import annotations

import argparse
import copy
import errno
import hashlib
import json
import os
import pathlib
import shutil
import sys
from typing import Any, Iterable


PRE_SCHEMA = "rv64-v14e-f0-functional-pre-compaction-v1"
POST_SCHEMA = "rv64-v14e-f0-functional-post-compaction-v1"
RECEIPT_SCHEMA = "npc-rv64-functional-archive-rehydrate-v1"


class RehydrateError(RuntimeError):
    """The compacted execution cannot be restored exactly."""


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def canonical_sha256(value: Any) -> str:
    payload = json.dumps(
        value, allow_nan=False, ensure_ascii=False,
        sort_keys=True, separators=(",", ":"),
    ).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def load_json(path: pathlib.Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle, parse_constant=lambda raw: (_ for _ in ()).throw(
            ValueError(f"non-finite JSON constant: {raw}")))
    if not isinstance(value, dict):
        raise RehydrateError(f"JSON root is not an object: {path}")
    return value


def write_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    try:
        temporary.write_text(
            json.dumps(
                value, allow_nan=False, ensure_ascii=False,
                indent=2, sort_keys=True,
            ) + "\n",
            encoding="utf-8",
        )
        load_json(temporary)
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def find_repo_root(start: pathlib.Path) -> pathlib.Path:
    for candidate in (start.resolve(), *start.resolve().parents):
        if (candidate / "npc/rv64/vsrc").is_dir() and (
            candidate / ".github/AGENTS.md").is_file():
            return candidate
    raise RehydrateError("repository root was not found")


def regular_repo_file(root: pathlib.Path, raw: pathlib.Path) -> pathlib.Path:
    candidate = raw if raw.is_absolute() else root / raw
    resolved = candidate.resolve(strict=True)
    resolved.relative_to(root.resolve())
    if candidate.is_symlink() or not resolved.is_file():
        raise RehydrateError(f"not a regular repository file: {raw}")
    return resolved


def relative(root: pathlib.Path, path: pathlib.Path) -> str:
    return path.resolve().relative_to(root.resolve()).as_posix()


def artifact(root: pathlib.Path, path: pathlib.Path, kind: str) -> dict[str, Any]:
    resolved = regular_repo_file(root, path)
    return {
        "kind": kind,
        "path": relative(root, resolved),
        "sha256": sha256_file(resolved),
        "size_bytes": resolved.stat().st_size,
    }


def verify_record(
    root: pathlib.Path, record: Any, *, expected_kind: str | None = None,
) -> pathlib.Path:
    if not isinstance(record, dict) or not {
        "path", "sha256",
    } <= set(record):
        raise RehydrateError("artifact record lacks path/sha256")
    if expected_kind is not None and record.get("kind") != expected_kind:
        raise RehydrateError(
            f"artifact kind={record.get('kind')} expected={expected_kind}")
    path = regular_repo_file(root, pathlib.Path(str(record["path"])))
    observed = sha256_file(path)
    if observed != record.get("sha256"):
        raise RehydrateError(
            f"artifact hash drift: {record['path']} expected={record.get('sha256')} "
            f"observed={observed}")
    if "size_bytes" in record and path.stat().st_size != record["size_bytes"]:
        raise RehydrateError(f"artifact size drift: {record['path']}")
    return path


def iter_program_records(aggregate: dict[str, Any]) -> Iterable[dict[str, Any]]:
    for suite_name in ("official", "am"):
        suite = aggregate.get(suite_name)
        rows = suite.get("images") if isinstance(suite, dict) else None
        if not isinstance(rows, list):
            raise RehydrateError(f"{suite_name} image inventory is absent")
        for row in rows:
            image = row.get("image") if isinstance(row, dict) else None
            if not isinstance(image, dict):
                raise RehydrateError(f"{suite_name} image record is invalid")
            yield image
    benchmarks = aggregate.get("benchmarks")
    if not isinstance(benchmarks, dict):
        raise RehydrateError("benchmark image inventory is absent")
    for name in ("coremark", "dhrystone"):
        row = benchmarks.get(name)
        image = row.get("image") if isinstance(row, dict) else None
        if not isinstance(image, dict):
            raise RehydrateError(f"{name} image record is invalid")
        yield image


def exact_record_set(records: Iterable[dict[str, Any]]) -> set[tuple[str, str]]:
    result: set[tuple[str, str]] = set()
    for record in records:
        if not isinstance(record, dict) or record.get("kind") != "program_image":
            raise RehydrateError("program image record has an invalid kind")
        path = record.get("path")
        digest = record.get("sha256")
        if not isinstance(path, str) or not isinstance(digest, str):
            raise RehydrateError("program image record lacks path/sha256")
        key = (path, digest)
        if key in result:
            raise RehydrateError(f"duplicate program image record: {path}")
        result.add(key)
    return result


def record_identity(record: Any) -> tuple[Any, Any, Any]:
    if not isinstance(record, dict):
        return (None, None, None)
    return (record.get("kind"), record.get("path"), record.get("sha256"))


def validate_compaction_chain(
    *,
    root: pathlib.Path,
    aggregate_path: pathlib.Path,
    descriptor_path: pathlib.Path,
    pre_path: pathlib.Path,
    post_path: pathlib.Path,
) -> tuple[dict[str, Any], dict[str, Any], dict[str, Any]]:
    aggregate = load_json(aggregate_path)
    pre = load_json(pre_path)
    post = load_json(post_path)
    design_id = aggregate.get("design_id")
    if pre.get("schema") != PRE_SCHEMA or post.get("schema") != POST_SCHEMA:
        raise RehydrateError("compaction receipt schema mismatch")
    if pre.get("status") != "PASS" or post.get("status") != "PASS":
        raise RehydrateError("compaction receipt is not PASS")
    if pre.get("current_design_id") != design_id or (
        post.get("current_design_id") != design_id
    ):
        raise RehydrateError("compaction design_id differs from aggregate")
    verify_record(root, pre.get("aggregate"))
    if pre["aggregate"].get("path") != relative(root, aggregate_path):
        raise RehydrateError("pre-compaction receipt points at another aggregate")
    verify_record(root, pre.get("descriptor"))
    if pre["descriptor"].get("path") != relative(root, descriptor_path):
        raise RehydrateError("pre-compaction receipt points at another descriptor")
    verify_record(root, post.get("pre_compaction_receipt"))
    if post["pre_compaction_receipt"].get("path") != relative(root, pre_path):
        raise RehydrateError("post-compaction receipt points at another pre receipt")
    counts = pre.get("removed_counts")
    if counts != {"program_images": 240, "reference": 1, "simulator": 1}:
        raise RehydrateError(f"unexpected compacted artifact counts: {counts}")
    if post.get("removed_counts") != counts:
        raise RehydrateError("pre/post compacted artifact counts differ")
    if post.get("standalone_binary_replay_available") is not False or (
        post.get("rebuild_binding_available") is not True
    ):
        raise RehydrateError("post-compaction replay/rebuild boundary drifted")
    removed = pre.get("removed")
    if not isinstance(removed, dict):
        raise RehydrateError("removed artifact inventory is absent")
    if record_identity(removed.get("simulator")) != record_identity(
        aggregate.get("simulator")
    ):
        raise RehydrateError("compacted simulator differs from aggregate")
    difftest = aggregate.get("difftest")
    reference = difftest.get("reference") if isinstance(difftest, dict) else None
    if record_identity(removed.get("reference")) != record_identity(reference):
        raise RehydrateError("compacted reference differs from aggregate")
    removed_images = removed.get("program_images")
    if not isinstance(removed_images, list) or exact_record_set(
        removed_images
    ) != exact_record_set(iter_program_records(aggregate)):
        raise RehydrateError("compacted program-image inventory differs from aggregate")
    return aggregate, pre, post


def link_or_copy_exact(
    *, root: pathlib.Path, source: pathlib.Path, destination: pathlib.Path,
    expected_sha256: str, executable: bool = False,
) -> tuple[str, dict[str, Any], dict[str, Any]]:
    source = regular_repo_file(root, source)
    if sha256_file(source) != expected_sha256:
        raise RehydrateError(f"source hash mismatch: {relative(root, source)}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    method = "reused"
    if destination.exists():
        if destination.is_symlink() or not destination.is_file():
            raise RehydrateError(f"unsafe existing destination: {destination}")
        if sha256_file(destination) != expected_sha256:
            raise RehydrateError(f"existing destination hash mismatch: {destination}")
    else:
        try:
            os.link(source, destination)
            method = "hardlink"
        except OSError as exc:
            if exc.errno not in {errno.EXDEV, errno.EPERM, errno.EACCES}:
                raise
            shutil.copyfile(source, destination)
            method = "copy"
    if executable:
        destination.chmod(destination.stat().st_mode | 0o111)
    return method, artifact(root, source, "source"), artifact(
        root, destination, "restored")


def hash_index(directory: pathlib.Path) -> dict[str, pathlib.Path]:
    result: dict[str, pathlib.Path] = {}
    for path in sorted(directory.glob("*.bin")):
        if path.is_symlink() or not path.is_file():
            raise RehydrateError(f"unsafe binary candidate: {path}")
        digest = sha256_file(path)
        result.setdefault(digest, path)
    return result


def rehydrate(
    *,
    root: pathlib.Path,
    aggregate_path: pathlib.Path,
    descriptor_path: pathlib.Path,
    pre_path: pathlib.Path,
    post_path: pathlib.Path,
    output_dir: pathlib.Path,
    simulator_source: pathlib.Path,
    simulator_recovery_log: pathlib.Path,
    reference_source: pathlib.Path,
    official_image_dir: pathlib.Path,
    am_image_dir: pathlib.Path,
    coremark_image: pathlib.Path,
    dhrystone_image: pathlib.Path,
) -> dict[str, Any]:
    root = root.resolve(strict=True)
    output_dir = output_dir.resolve()
    output_dir.relative_to(root)
    for path in (aggregate_path, descriptor_path, pre_path, post_path):
        regular_repo_file(root, path)
    aggregate, pre, post = validate_compaction_chain(
        root=root,
        aggregate_path=aggregate_path.resolve(),
        descriptor_path=descriptor_path.resolve(),
        pre_path=pre_path.resolve(),
        post_path=post_path.resolve(),
    )
    recovery_log = regular_repo_file(root, simulator_recovery_log)
    recovery_text = recovery_log.read_text(encoding="utf-8")
    if recovery_text.count("[SIMULATOR-RECOVERY][PASS]") != 1 or (
        aggregate["simulator"]["sha256"] not in recovery_text
    ):
        raise RehydrateError("simulator exact-recovery PASS marker is absent or ambiguous")

    tools_dir = root / "npc/rv64/eval/ppa/tools"
    if str(tools_dir) not in sys.path:
        sys.path.insert(0, str(tools_dir))
    import arch_stable_freeze as freeze  # pylint: disable=import-outside-toplevel
    import architecture_hard_gates as architecture  # pylint: disable=import-outside-toplevel
    import functional_aggregate as functional  # pylint: disable=import-outside-toplevel

    live_design_hex, _ = architecture.rtl_binding(root)
    design_id = f"sha256:{live_design_hex}"
    if design_id != aggregate.get("design_id"):
        raise RehydrateError(
            f"live design_id={design_id} differs from compacted aggregate")

    restored = copy.deepcopy(aggregate)
    mappings: list[dict[str, Any]] = []

    def restore_record(
        record: dict[str, Any], source: pathlib.Path, destination: pathlib.Path,
        *, executable: bool = False,
    ) -> None:
        method, source_artifact, restored_artifact = link_or_copy_exact(
            root=root,
            source=source,
            destination=destination,
            expected_sha256=str(record["sha256"]),
            executable=executable,
        )
        old_path = record["path"]
        record["path"] = relative(root, destination)
        mappings.append({
            "old_path": old_path,
            "new_path": record["path"],
            "sha256": record["sha256"],
            "method": method,
            "source": source_artifact,
            "restored": restored_artifact,
        })

    restore_record(
        restored["simulator"], simulator_source,
        output_dir / "inputs/frozen/NpcSimTop", executable=True)
    restore_record(
        restored["difftest"]["reference"], reference_source,
        output_dir / "inputs/frozen/riscv64-nemu-interpreter-so",
        executable=True)

    official_dir = regular_repo_file(root, next(official_image_dir.glob("*.bin"))).parent
    official_rows = restored["official"]["images"]
    for row in official_rows:
        old_name = pathlib.PurePosixPath(row["image"]["path"]).name
        restore_record(
            row["image"], official_dir / old_name,
            output_dir / "inputs/images/official" / old_name)

    am_dir = regular_repo_file(root, next(am_image_dir.glob("*.bin"))).parent
    am_sources = hash_index(am_dir)
    for row in restored["am"]["images"]:
        digest = row["image"]["sha256"]
        source = am_sources.get(digest)
        if source is None:
            raise RehydrateError(f"AM source image is absent: {row['test_id']}")
        restore_record(
            row["image"], source,
            output_dir / "inputs/images/am" / f"{row['test_id']}.bin")

    restore_record(
        restored["benchmarks"]["coremark"]["image"], coremark_image,
        output_dir / "inputs/images/benchmarks/coremark.bin")
    restore_record(
        restored["benchmarks"]["dhrystone"]["image"], dhrystone_image,
        output_dir / "inputs/images/benchmarks/dhrystone.bin")

    if len(mappings) != 242:
        raise RehydrateError(f"restored artifact count={len(mappings)} expected=242")
    restored_paths = [item["new_path"] for item in mappings]
    if len(restored_paths) != len(set(restored_paths)):
        raise RehydrateError("restored destination paths are not unique")

    aggregate_output = output_dir / "functional-aggregate-rehydrated.json"
    write_json(aggregate_output, restored)
    schema_issues = freeze.schema_errors(root, restored, freeze.FUNCTIONAL_SCHEMA)
    if schema_issues:
        raise RehydrateError(
            "rehydrated aggregate schema: " + "; ".join(schema_issues[:8]))
    makefile = root / "npc/rv64/testbench/Makefile"
    required_tests, inventory_errors = freeze.parse_required_tests(
        makefile.read_text(encoding="utf-8"))
    if inventory_errors:
        raise RehydrateError("; ".join(inventory_errors))
    checks, blockers, observed = functional.validate_aggregate(
        root, restored, required_tests)
    if blockers:
        raise RehydrateError(
            "rehydrated aggregate validation: " + "; ".join(blockers[:8]))

    receipt_core = {
        "schema": RECEIPT_SCHEMA,
        "status": "PASS",
        "design_id": design_id,
        "cohort_id": restored.get("cohort_id"),
        "operation": {
            "dut_executed": False,
            "production_rtl_modified": False,
            "original_execution_status_rewritten": False,
            "content_identical_artifacts_restored": 242,
            "standalone_binary_replay_available": True,
        },
        "original": {
            "aggregate": artifact(root, aggregate_path, "functional_aggregate"),
            "descriptor": artifact(root, descriptor_path, "functional_descriptor"),
            "pre_compaction": artifact(root, pre_path, "pre_compaction_receipt"),
            "post_compaction": artifact(root, post_path, "post_compaction_receipt"),
            "pre_compaction_policy": pre.get("policy"),
            "post_compaction_boundary": {
                "standalone_binary_replay_available": post.get(
                    "standalone_binary_replay_available"),
                "rebuild_binding_available": post.get("rebuild_binding_available"),
            },
        },
        "recovery": {
            "simulator_log": artifact(
                root, recovery_log, "simulator_exact_recovery_log"),
            "mappings": mappings,
            "hardlinks": sum(item["method"] == "hardlink" for item in mappings),
            "copies": sum(item["method"] == "copy" for item in mappings),
            "reused": sum(item["method"] == "reused" for item in mappings),
        },
        "rehydrated_aggregate": artifact(
            root, aggregate_output, "functional_aggregate"),
        "validation": {
            "status": "PASS",
            "required_module_tests": len(required_tests),
            "check_count": len(checks),
            "blockers": [],
            "observed_sha256": canonical_sha256(observed),
        },
        "claim_boundary": {
            "architecture_freeze": "GAP",
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        },
    }
    receipt_core["receipt_sha256"] = canonical_sha256(receipt_core)
    receipt_path = output_dir / "rehydration-receipt.json"
    write_json(receipt_path, receipt_core)
    return receipt_core


def parse_args(argv: Iterable[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=pathlib.Path, default=pathlib.Path.cwd())
    parser.add_argument("--aggregate", type=pathlib.Path, required=True)
    parser.add_argument("--descriptor", type=pathlib.Path, required=True)
    parser.add_argument("--pre-compaction", type=pathlib.Path, required=True)
    parser.add_argument("--post-compaction", type=pathlib.Path, required=True)
    parser.add_argument("--output-dir", type=pathlib.Path, required=True)
    parser.add_argument("--simulator", type=pathlib.Path, required=True)
    parser.add_argument("--simulator-recovery-log", type=pathlib.Path, required=True)
    parser.add_argument("--reference", type=pathlib.Path, required=True)
    parser.add_argument("--official-image-dir", type=pathlib.Path, required=True)
    parser.add_argument("--am-image-dir", type=pathlib.Path, required=True)
    parser.add_argument("--coremark-image", type=pathlib.Path, required=True)
    parser.add_argument("--dhrystone-image", type=pathlib.Path, required=True)
    return parser.parse_args(list(argv) if argv is not None else None)


def main(argv: Iterable[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        root = find_repo_root(args.root)
        receipt = rehydrate(
            root=root,
            aggregate_path=regular_repo_file(root, args.aggregate),
            descriptor_path=regular_repo_file(root, args.descriptor),
            pre_path=regular_repo_file(root, args.pre_compaction),
            post_path=regular_repo_file(root, args.post_compaction),
            output_dir=(root / args.output_dir if not args.output_dir.is_absolute()
                        else args.output_dir),
            simulator_source=regular_repo_file(root, args.simulator),
            simulator_recovery_log=regular_repo_file(
                root, args.simulator_recovery_log),
            reference_source=regular_repo_file(root, args.reference),
            official_image_dir=(root / args.official_image_dir
                                if not args.official_image_dir.is_absolute()
                                else args.official_image_dir),
            am_image_dir=(root / args.am_image_dir
                          if not args.am_image_dir.is_absolute()
                          else args.am_image_dir),
            coremark_image=regular_repo_file(root, args.coremark_image),
            dhrystone_image=regular_repo_file(root, args.dhrystone_image),
        )
    except (OSError, ValueError, RehydrateError, json.JSONDecodeError) as exc:
        print(f"[FUNCTIONAL-ARCHIVE-REHYDRATE][FAIL] {exc}", file=sys.stderr)
        return 1
    print(
        "[FUNCTIONAL-ARCHIVE-REHYDRATE][PASS] "
        f"design_id={receipt['design_id']} artifacts=242 dut_executed=false")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
