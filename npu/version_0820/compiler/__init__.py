"""Versioned NPU compiler artifact support.

The package intentionally starts at the compiler/runtime boundary: a compiler
produces an immutable command template, a weight image, and canonical metadata;
the runtime validates the three files before applying IOVA relocations.
"""

from .npu_artifact import (
    ABI_MAJOR,
    ABI_MINOR,
    COMMAND_HEADER_BYTES,
    COMMAND_RECORD_BYTES,
    COMMAND_RECORD_WORDS,
    METADATA_SCHEMA,
    ArtifactBundle,
    ArtifactError,
    LoadedBundle,
    apply_relocations,
    compile_graph,
    load_bundle,
    pack_command_file,
    tiny_two_command_graph,
    unpack_command_file,
)

__all__ = [
    "ABI_MAJOR",
    "ABI_MINOR",
    "COMMAND_HEADER_BYTES",
    "COMMAND_RECORD_BYTES",
    "COMMAND_RECORD_WORDS",
    "METADATA_SCHEMA",
    "ArtifactBundle",
    "ArtifactError",
    "LoadedBundle",
    "apply_relocations",
    "compile_graph",
    "load_bundle",
    "pack_command_file",
    "tiny_two_command_graph",
    "unpack_command_file",
]
