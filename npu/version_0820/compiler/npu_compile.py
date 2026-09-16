#!/usr/bin/env python3
"""CLI for low-level v3 graphs and the exact Qwen P00 compiler slice."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Sequence

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
    from compiler.npu_artifact import (  # type: ignore[no-redef]
        ArtifactError,
        canonical_json_bytes,
        compile_graph_json,
        tiny_two_command_graph,
    )
    from compiler.qwen_p00_codegen import (  # type: ignore[no-redef]
        P00CodegenError,
        compile_exact_p00,
    )
    from compiler.qwen_p00_lowering import P00LoweringError  # type: ignore[no-redef]
    from compiler.qwen_weights import WeightSourceError  # type: ignore[no-redef]
else:
    from .npu_artifact import (
        ArtifactError,
        canonical_json_bytes,
        compile_graph_json,
        tiny_two_command_graph,
    )
    from .qwen_p00_codegen import P00CodegenError, compile_exact_p00
    from .qwen_p00_lowering import P00LoweringError
    from .qwen_weights import WeightSourceError


def _pretty_json(value: object) -> bytes:
    return (
        json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2, allow_nan=False) + "\n"
    ).encode("utf-8")


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Compile a low-level NPU graph to command.bin, weights.bin, and metadata.json",
    )
    parser.add_argument("graph", nargs="?", type=Path, help="npu-compiler-graph-v3 JSON input")
    parser.add_argument("-o", "--output-dir", type=Path, help="bundle output directory")
    parser.add_argument(
        "--tiny",
        action="store_true",
        help="compile the built-in deterministic two-command smoke graph",
    )
    parser.add_argument(
        "--emit-tiny-graph",
        type=Path,
        metavar="PATH",
        help="write the built-in two-command graph JSON and exit",
    )
    parser.add_argument(
        "--no-deduplicate-weights",
        action="store_true",
        help="place identical weight buffers independently",
    )
    parser.add_argument(
        "--qwen-manifest",
        type=Path,
        help="exact qwen-npu-graph-manifest-v2 envelope for production P00 lowering",
    )
    parser.add_argument(
        "--canonical-node",
        help="64-digit lowercase canonical ID of the exact P00 node to compile",
    )
    parser.add_argument(
        "--model",
        type=Path,
        help="GGUF model supplying the selected node's raw external weight bytes",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = _parser()
    args = parser.parse_args(argv)
    qwen_values = (args.qwen_manifest, args.canonical_node, args.model)
    qwen_mode = all(value is not None for value in qwen_values)
    if any(value is not None for value in qwen_values) and not qwen_mode:
        parser.error("--qwen-manifest, --canonical-node, and --model must be provided together")
    if args.emit_tiny_graph is not None:
        if args.graph is not None or args.tiny or qwen_mode or args.output_dir is not None:
            parser.error("--emit-tiny-graph cannot be combined with graph compilation options")
        args.emit_tiny_graph.parent.mkdir(parents=True, exist_ok=True)
        args.emit_tiny_graph.write_bytes(_pretty_json(tiny_two_command_graph()))
        print(args.emit_tiny_graph)
        return 0
    selected_inputs = int(args.tiny) + int(args.graph is not None) + int(qwen_mode)
    if selected_inputs != 1:
        parser.error("select exactly one input: GRAPH, --tiny, or the exact Qwen P00 options")
    if args.output_dir is None:
        parser.error("--output-dir is required when compiling")
    try:
        if qwen_mode:
            if args.no_deduplicate_weights:
                parser.error("--no-deduplicate-weights does not apply to the single-weight P00 slice")
            compiled = compile_exact_p00(
                args.qwen_manifest,
                args.canonical_node,
                args.model,
            )
            bundle = compiled.bundle
            mode = "qwen-exact-p00"
            details = {
                "bundle_id": compiled.verified.metadata["bundle_id"],
                "canonical_node": compiled.selection.canonical_id,
                "manifest_graph_index": compiled.selection.manifest_graph_index,
                "source_schedule_position": compiled.selection.schedule_position,
                "weight_sha256": compiled.weight.sha256,
            }
        else:
            graph_json = (
                canonical_json_bytes(tiny_two_command_graph())
                if args.tiny
                else args.graph.read_bytes()
            )
            bundle = compile_graph_json(
                graph_json,
                deduplicate_weights=not args.no_deduplicate_weights,
            )
            mode = "tiny" if args.tiny else "low-level-v3"
            details = {}
        bundle.write_to(args.output_dir)
    except (ArtifactError, P00CodegenError, P00LoweringError, WeightSourceError, OSError) as exc:
        print(f"npu-compile: {exc}", file=sys.stderr)
        return 2
    summary = {
        "command_bytes": len(bundle.command_bin),
        "metadata_bytes": len(bundle.metadata_json),
        "mode": mode,
        "output_dir": str(args.output_dir),
        "weights_bytes": len(bundle.weights_bin),
        **details,
    }
    print(canonical_json_bytes(summary).decode("utf-8"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
