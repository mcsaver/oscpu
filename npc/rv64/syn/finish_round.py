#!/usr/bin/env python3
"""Discard only known regenerable products from one completed synthesis round."""
import argparse
from datetime import datetime, timezone
import gzip
import json
import os
from pathlib import Path
import re
import stat
import sys

WORKSPACE = Path(__file__).resolve().parents[3]
ECOS_CELL_PREFIX = "ics55_ecos_sram_"
NETLIST_SUFFIXES = (".netlist.v", ".netlist.v.sim", ".netlist.v.json",
                    ".netlist.v.il", ".sta.v")
ABC_DIRECTORY = re.compile(r"(?:_tmp_)?yosys-abc-[A-Za-z0-9_-]+$")
ABC_PRODUCTS = {"abc.script", "input.blif", "output.blif", "stdcells.genlib"}
BUILD_TOOLS = {"yosys", "yosys-abc", "abc", "sta", "opensta", "iEDA",
               "verilator", "verilator_bin", "iverilog", "vvp", "make", "gmake"}


def validate_round_dir(directory, workspace=WORKSPACE):
    """Require a concrete existing descendant, without any symlink components."""
    if not str(directory):
        raise ValueError("--round-dir must name an explicit completed round")
    workspace = Path(workspace).resolve(strict=True)
    raw = Path(directory)
    if ".." in raw.parts:
        raise ValueError("round directory must not contain '..'")
    target = raw.absolute()
    allowed = [workspace / "build", workspace / "npc/rv64/build"]
    root = next((root for root in allowed if target.is_relative_to(root)), None)
    if root is None or len(target.relative_to(root).parts) < 2:
        raise ValueError("select a specific round directory at least two levels below a workspace build root")
    current = workspace
    for part in target.relative_to(workspace).parts:
        current /= part
        if current.is_symlink():
            raise ValueError(f"symlink path is not allowed: {current}")
    if not target.is_dir():
        raise ValueError(f"round directory does not exist: {target}")
    if target.resolve(strict=True) != target:
        raise ValueError(f"round directory is not canonical: {target}")
    return target


def regular_file(path):
    if path.is_symlink():
        raise ValueError(f"refusing symlink product: {path}")
    if path.exists() and not stat.S_ISREG(path.stat().st_mode):
        raise ValueError(f"expected a regular generated file: {path}")
    return path.is_file()


def plan_products(directory, top):
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_$]*", top):
        raise ValueError("top must be a simple Verilog module name")
    products, empty_dirs = [], []
    for suffix in NETLIST_SUFFIXES:
        for compression in ("", ".gz"):
            candidate = directory / (top + suffix + compression)
            if regular_file(candidate):
                products.append(candidate)
    # ABC logs and unknown content stay in place, even in a confirmed temp dir.
    for entry in sorted(directory.iterdir()):
        if not ABC_DIRECTORY.fullmatch(entry.name):
            continue
        if entry.is_symlink():
            raise ValueError(f"refusing symlink ABC directory: {entry}")
        if not entry.is_dir():
            continue
        script, netlist = entry / "abc.script", entry / "input.blif"
        if not regular_file(script) or not regular_file(netlist):
            continue
        if "input.blif" not in script.read_text(errors="replace"):
            continue
        for name in sorted(ABC_PRODUCTS):
            product = entry / name
            if regular_file(product):
                products.append(product)
        empty_dirs.append(entry)
    return sorted(products), empty_dirs


def active_builds(directory):
    """Read-only Linux check; explicit invocation still belongs after tool exit."""
    found, ancestors = [], set()
    pid = os.getpid()
    while pid and pid not in ancestors:
        ancestors.add(pid)
        try:
            status = Path(f"/proc/{pid}/status").read_text()
            pid = int(re.search(r"^PPid:\s+(\d+)", status, re.MULTILINE).group(1))
        except (OSError, AttributeError):
            break
    for process in Path("/proc").iterdir():
        if not process.name.isdigit() or int(process.name) in ancestors:
            continue
        try:
            arguments = (process / "cmdline").read_bytes().split(b"\0")
            arguments = [arg.decode(errors="replace") for arg in arguments if arg]
            if not arguments:
                continue
            executable = Path(arguments[0]).name
            # Verilator executables have arbitrary names; /proc/exe identifies
            # a live generated simulator even when its cwd is outside the round.
            image = (process / "exe").resolve(strict=True)
            generated_image = image == directory or directory in image.parents
            if executable not in BUILD_TOOLS and not generated_image:
                continue
            cwd = (process / "cwd").resolve(strict=True)
            references = generated_image or cwd == directory or directory in cwd.parents
            references |= any(str(directory) in argument for argument in arguments)
            for descriptor in (process / "fd").iterdir():
                try:
                    name = descriptor.resolve(strict=True)
                    references |= name == directory or directory in name.parents
                except OSError:
                    continue
            if references:
                found.append({"pid": int(process.name), "tool": executable})
        except OSError:
            continue
    return found


def macro_owner(instance):
    lowered = instance.lower()
    if "dcache" in lowered or re.search(r"cache.*g_data_bank", lowered):
        return "DCache"
    if "icache" in lowered or re.search(r"frontend.*cache.*data", lowered):
        return "ICache"
    return "unclassified"


def collect_macros(directory, top):
    candidates = [directory / (top + suffix) for suffix in (".sta.v", ".sta.v.gz")]
    source = next((path for path in candidates if regular_file(path)), None)
    if source is None:
        return {"status": "unavailable", "reason": "no flattened STA netlist remains",
                "cell_family": ECOS_CELL_PREFIX + "*", "instances": [], "count": None}
    opener = gzip.open if source.suffix == ".gz" else open
    module, pending, instances = None, None, []
    identifier = r"(\\[^\s]+|[A-Za-z_$][\w$]*)"
    instance_pattern = re.compile(r"^\s*" + identifier + r"\s*\(")
    module_pattern = re.compile(r"^\s*module\s+" + identifier)
    cell_pattern = re.compile(r"^\s*\\?(" + re.escape(ECOS_CELL_PREFIX) + r"[A-Za-z0-9_]+)\s+(.*)")
    seen_top, finished_top, parse_errors = False, False, []
    with opener(source, "rt", encoding="utf-8", errors="strict") as stream:
        for number, line in enumerate(stream, 1):
            declaration = module_pattern.match(line)
            if declaration:
                module = declaration.group(1).lstrip("\\")
                seen_top |= module == top
            if re.match(r"^\s*endmodule\b", line):
                finished_top |= module == top
                module = None
            cell = cell_pattern.match(line)
            cell_name = cell.group(1) if cell else pending
            text = cell.group(2) if cell else (line if pending else None)
            if text is None:
                continue
            if not text.strip():
                pending = cell_name
                continue
            match = instance_pattern.match(text)
            pending = None
            if not match:
                parse_errors.append(f"unrecognized macro declaration at line {number}")
                continue
            instance = match.group(1).lstrip("\\")
            instances.append({"cell": cell_name, "module": module, "instance": instance,
                              "owner": macro_owner(instance), "line": number})
    if pending:
        parse_errors.append("incomplete macro declaration at end of file")
    complete = seen_top and finished_top and not parse_errors and all(
        item["module"] == top for item in instances)
    return {"status": "collected" if complete else "incomplete",
            "source": source.name, "cell_family": ECOS_CELL_PREFIX + "*", "count": len(instances),
            "by_owner": {owner: sum(item["owner"] == owner for item in instances)
                         for owner in ("DCache", "ICache", "unclassified")},
            "by_cell": {cell: sum(item["cell"] == cell for item in instances)
                        for cell in sorted({item["cell"] for item in instances})},
            "instances": instances, "diagnostics": parse_errors,
            "note": "Observed declarations only; no synthesis, timing or functional PASS assertion."}


def write_json_new(path, value):
    # Exclusive creation preserves earlier evidence and rejects output symlinks.
    with path.open("x", encoding="utf-8") as output:
        json.dump(value, output, indent=2, ensure_ascii=False)
        output.write("\n")


def main(argv=None, *, workspace=WORKSPACE):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--round-dir", required=True,
                        help="completed STA result directory; no historical-round traversal")
    parser.add_argument("--top", default="R64CoreTop")
    parser.add_argument("--dry-run", action="store_true", help="list products without writing or deleting")
    parser.add_argument("--upstream-exit-code", type=int, default=None,
                        help="record and return the original runner/STA exit code (0..255)")
    args = parser.parse_args(argv)
    original_code = args.upstream_exit_code
    if original_code is not None and not 0 <= original_code <= 255:
        parser.error("--upstream-exit-code must be in 0..255")
    try:
        directory = validate_round_dir(args.round_dir, workspace)
        products, abc_dirs = plan_products(directory, args.top)
        if active := active_builds(directory):
            raise ValueError(f"build tools still reference this round: {active}")
        inventory_path = directory / "ecos-macro-instances.json"
        if inventory_path.is_symlink():
            raise ValueError(f"refusing symlink inventory: {inventory_path}")
        records = [{"path": str(path.relative_to(directory)),
                    "bytes": path.stat().st_size} for path in products]
        report = {"round_dir": str(directory), "top": args.top,
                  "upstream_exit_code": original_code,
                  "mode": "dry-run" if args.dry_run else "results-only",
                  "products": records, "planned_bytes": sum(row["bytes"] for row in records),
                  "removed": [], "reclaimed_bytes": 0,
                  "note": "Existing results and return codes are unchanged. Re-synthesize to inspect netlists again."}
        if args.dry_run:
            print(json.dumps(report, indent=2, ensure_ascii=False))
            return original_code or 0
        stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
        report_path = directory / f"finish-round-{stamp}-{os.getpid()}.json"
        # Re-synthesis in the same directory gets a fresh inventory; prior evidence stays.
        if inventory_path.exists() and any((directory / (args.top + suffix)).is_file()
                                           for suffix in (".sta.v", ".sta.v.gz")):
            inventory_path = directory / f"ecos-macro-instances-{stamp}-{os.getpid()}.json"
        if not inventory_path.exists():
            try:
                inventory = collect_macros(directory, args.top)
            except (OSError, UnicodeError, EOFError) as error:
                inventory = {"status": "incomplete", "cell_family": ECOS_CELL_PREFIX + "*",
                             "reason": str(error), "count": None}
            write_json_new(inventory_path, inventory)
        report["macro_inventory"] = inventory_path.name
        # Persist the plan first so an interrupted cleanup cannot hide its scope.
        write_json_new(report_path, report)
        cleanup_error = None
        try:
            for path, record in zip(products, records):
                if not regular_file(path):
                    raise ValueError(f"product changed during cleanup: {path}")
                path.unlink()
                report["removed"].append(record)
                report["reclaimed_bytes"] += record["bytes"]
            for entry in abc_dirs:
                if not any(entry.iterdir()):
                    entry.rmdir()
        except (OSError, ValueError) as error:
            cleanup_error = str(error)
            report["error"] = cleanup_error
        report["cleanup_complete"] = cleanup_error is None
        report_path.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(json.dumps(report, indent=2, ensure_ascii=False))
        return original_code or (1 if cleanup_error else 0)
    except (OSError, ValueError) as error:
        print(f"finish_round: {error}", file=sys.stderr)
        return original_code or 1


if __name__ == "__main__":
    sys.exit(main())
