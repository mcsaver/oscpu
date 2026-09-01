#!/usr/bin/env python3
"""Qwen F32 ALU production CMake/elaboration source identity helper."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import pathlib
import re
import shlex
import stat
import sys
import uuid
from collections.abc import Iterable, Mapping, Sequence
from typing import Any


SCHEMA_CMAKE = "qwen-f32-alu-build-identity-v1"
SCHEMA_VERFILES = "qwen-f32-alu-elaboration-identity-v1"
SCHEMA_COMPILER_ARGV = "qwen-f32-alu-compiler-argv-v1"

F32_EXECUTE_FUNCTION = "npu_verilator_execute_f32_alu"
EXPECTED_PRODUCTION_CPP_SHA256 = (
    "b5581ad476afa265d351906c95e072fc6c9d0957114b29b170e03687473a348e"
)
EXPECTED_CMAKE_SHA256 = (
    "7e2c408c5d4c9b1837177f6e8b8638eb635ef5f736a225b52e9e2d95eb13254f"
)
EXPECTED_F32_CONSTRUCTOR_ARGS: tuple[str, ...] = (
    "profile",
    "npu_f32_alu_mode::positive",
    "src0_allocation",
    "src0_allocation_bytes",
    "src1_allocation",
    "src1_allocation_bytes",
    "dst_shadow",
    "dst_shadow_bytes",
    "nullptr",
    "0",
    "result",
)

EXPECTED_F32_FUNCTION_TEMPLATE = r"""
bool npu_verilator_execute_f32_alu(
        std::uint32_t profile_id,
        const std::uint8_t * src0_allocation,
        std::size_t src0_allocation_bytes,
        const std::uint8_t * src1_allocation,
        std::size_t src1_allocation_bytes,
        std::uint8_t * dst_shadow,
        std::size_t dst_shadow_bytes,
        npu_verilator_f32_alu_result * result) {
    if (result == nullptr) {
        return false;
    }
    *result = {};
    npu_f32_alu_profile profile = {};
    if (!npu_f32_alu_profile_by_id(profile_id, &profile)) {
        result->runner_error_code = runner_f32_profile;
        return false;
    }
    try {
        f32_alu_harness harness(
            profile,
            npu_f32_alu_mode::positive,
            src0_allocation,
            src0_allocation_bytes,
            src1_allocation,
            src1_allocation_bytes,
            dst_shadow,
            dst_shadow_bytes,
            nullptr,
            0,
            result);
        return harness.run();
    } catch (...) {
        result->passed = false;
        result->runner_error_code = runner_allocation;
        return false;
    }
}
"""

EXPECTED_RTL_SOURCES: tuple[str, ...] = (
    "third_party/fpu-sp/verilog/src/float/fp_wire.sv",
    "third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv",
    "third_party/fpu-sp/verilog/src/lzc/lzc_4.sv",
    "third_party/fpu-sp/verilog/src/lzc/lzc_8.sv",
    "third_party/fpu-sp/verilog/src/lzc/lzc_16.sv",
    "third_party/fpu-sp/verilog/src/lzc/lzc_32.sv",
    "third_party/fpu-sp/verilog/src/lzc/lzc_64.sv",
    "third_party/fpu-sp/verilog/src/lzc/lzc_128.sv",
    "third_party/fpu-sp/verilog/src/float/fp_ext.sv",
    "third_party/fpu-sp/verilog/src/float/fp_fma.sv",
    "third_party/fpu-sp/verilog/src/float/fp_rnd.sv",
    "rtl/TensorNpuFp32AddMul.v",
    "rtl/TensorNpuF32TensorAlu.v",
    "rtl/TensorNpuVectorF32Adapter.v",
    "rtl/TensorNpuCoprocessor.v",
    "rtl/TensorNpuCommandDecoder.v",
    "rtl/TensorNpuRegisterFile.v",
    "rtl/TensorNpuMm2Engine.v",
    "rtl/TensorNpuDmaEngine.v",
    "rtl/TensorNpuLocalMemory.v",
    "rtl/tensor_npu_defs.vh",
)

EXPECTED_CMAKE_PRODUCER_TEMPLATE: tuple[tuple[str, str], ...] = (
    ("unquoted", "OUTPUT"),
    ("quoted", "${NPU_VERILATED_ARCHIVE}"),
    ("unquoted", "BYPRODUCTS"),
    ("quoted", "${NPU_VERILATED_HEADER}"),
    ("unquoted", "COMMAND"),
    ("quoted", "${CMAKE_COMMAND}"),
    ("unquoted", "-E"),
    ("unquoted", "make_directory"),
    ("quoted", "${NPU_VERILATED_MDIR}"),
    ("unquoted", "COMMAND"),
    ("quoted", "${VERILATOR_EXECUTABLE}"),
    ("unquoted", "--cc"),
    ("unquoted", "-O3"),
    ("unquoted", "-Wall"),
    ("unquoted", "-Wno-fatal"),
    ("unquoted", "--no-assert"),
    ("unquoted", "--no-trace"),
    ("quoted", "-I${NPU_PROJECT_ROOT}/rtl"),
    ("unquoted", "--Mdir"),
    ("quoted", "${NPU_VERILATED_MDIR}"),
    ("unquoted", "--top-module"),
    ("unquoted", "TensorNpuCoprocessor"),
    ("unquoted", "-CFLAGS"),
    ("quoted", "-O3 -DNDEBUG -march=native -fPIC"),
    ("unquoted", "${NPU_RTL_SOURCES}"),
    ("unquoted", "COMMAND"),
    ("quoted", "${NPU_MAKE_EXECUTABLE}"),
    ("unquoted", "-C"),
    ("quoted", "${NPU_VERILATED_MDIR}"),
    ("unquoted", "-f"),
    ("unquoted", "VTensorNpuCoprocessor.mk"),
    ("unquoted", "-j${NPU_VERILATOR_JOBS}"),
    ("unquoted", "VTensorNpuCoprocessor__ALL.a"),
    ("unquoted", "DEPENDS"),
    ("unquoted", "${NPU_RTL_SOURCES}"),
    ("unquoted", "WORKING_DIRECTORY"),
    ("quoted", "${NPU_PROJECT_ROOT}"),
    ("unquoted", "COMMENT"),
    ("quoted", "Generating O3/no-assert/no-trace TensorNpuCoprocessor model"),
    ("unquoted", "VERBATIM"),
)

EXPECTED_CMAKE_TARGET_TEMPLATE: tuple[tuple[str, str], ...] = (
    ("unquoted", "npu-verilated-model"),
    ("unquoted", "DEPENDS"),
    ("quoted", "${NPU_VERILATED_ARCHIVE}"),
)


class IdentityError(ValueError):
    """输入不能形成精确、无歧义的 production source identity。"""


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _safe_lstat(path: pathlib.Path) -> os.stat_result:
    try:
        result = path.lstat()
    except OSError as exc:
        raise IdentityError(f"cannot lstat {path}: {exc}") from exc
    if stat.S_ISLNK(result.st_mode):
        raise IdentityError(f"symlink input rejected: {path}")
    if not stat.S_ISREG(result.st_mode):
        raise IdentityError(f"non-regular input rejected: {path}")
    return result


def read_bytes_stable(path: pathlib.Path) -> bytes:
    """从同一 inode 读取一次 bytes，并拒绝读取期间的路径替换。"""

    path = pathlib.Path(path)
    lexical_before = _safe_lstat(path)
    flags = os.O_RDONLY
    flags |= getattr(os, "O_CLOEXEC", 0)
    flags |= getattr(os, "O_NOFOLLOW", 0)
    try:
        descriptor = os.open(path, flags)
    except OSError as exc:
        raise IdentityError(f"cannot open stable input {path}: {exc}") from exc
    try:
        fd_before = os.fstat(descriptor)
        if not stat.S_ISREG(fd_before.st_mode):
            raise IdentityError(f"opened input is not regular: {path}")
        chunks: list[bytes] = []
        while True:
            chunk = os.read(descriptor, 1024 * 1024)
            if not chunk:
                break
            chunks.append(chunk)
        fd_after = os.fstat(descriptor)
    finally:
        os.close(descriptor)
    lexical_after = _safe_lstat(path)
    identities = {
        (lexical_before.st_dev, lexical_before.st_ino),
        (fd_before.st_dev, fd_before.st_ino),
        (fd_after.st_dev, fd_after.st_ino),
        (lexical_after.st_dev, lexical_after.st_ino),
    }
    fd_metadata_before = (
        fd_before.st_size,
        fd_before.st_mtime_ns,
        fd_before.st_ctime_ns,
    )
    fd_metadata_after = (
        fd_after.st_size,
        fd_after.st_mtime_ns,
        fd_after.st_ctime_ns,
    )
    lexical_metadata_before = (
        lexical_before.st_size,
        lexical_before.st_mtime_ns,
        lexical_before.st_ctime_ns,
    )
    lexical_metadata_after = (
        lexical_after.st_size,
        lexical_after.st_mtime_ns,
        lexical_after.st_ctime_ns,
    )
    if (
        len(identities) != 1
        or fd_metadata_before != fd_metadata_after
        or lexical_metadata_before != lexical_metadata_after
        or fd_metadata_before != lexical_metadata_before
    ):
        raise IdentityError(f"input replaced or changed while reading: {path}")
    return b"".join(chunks)


def read_json_same_bytes(path: pathlib.Path) -> tuple[Any, str, bytes]:
    """hash 与 JSON parse 严格消费同一个不可变 bytes 对象。"""

    data = read_bytes_stable(path)
    digest = sha256_bytes(data)
    try:
        value = json.loads(data)
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise IdentityError(f"invalid JSON bytes in {path}: {exc}") from exc
    return value, digest, data


def _check_parent_chain(parent: pathlib.Path) -> None:
    if not parent.is_absolute():
        raise IdentityError(f"atomic output must be absolute: {parent}")
    current = parent
    while True:
        try:
            current_stat = current.lstat()
        except OSError as exc:
            raise IdentityError(f"atomic output parent missing {current}: {exc}") from exc
        if stat.S_ISLNK(current_stat.st_mode):
            raise IdentityError(f"atomic output parent symlink rejected: {current}")
        if not stat.S_ISDIR(current_stat.st_mode):
            raise IdentityError(f"atomic output parent is not a directory: {current}")
        if current == current.parent:
            break
        current = current.parent


def atomic_write_bytes(path: pathlib.Path, data: bytes, mode: int = 0o644) -> str:
    """以 exclusive temp + hard-link no-replace 原子发布 fresh artifact。"""

    path = pathlib.Path(path)
    if not path.is_absolute():
        path = path.resolve(strict=False)
    _check_parent_chain(path.parent)
    if path.exists() or path.is_symlink():
        raise IdentityError(f"fresh atomic output already exists: {path}")
    temporary = path.parent / f".{path.name}.tmp.{os.getpid()}.{uuid.uuid4().hex}"
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
    flags |= getattr(os, "O_CLOEXEC", 0)
    flags |= getattr(os, "O_NOFOLLOW", 0)
    descriptor = -1
    linked = False
    try:
        descriptor = os.open(temporary, flags, mode)
        view = memoryview(data)
        while view:
            written = os.write(descriptor, view)
            if written <= 0:
                raise IdentityError(f"short atomic write: {temporary}")
            view = view[written:]
        os.fsync(descriptor)
        os.fchmod(descriptor, mode)
        os.close(descriptor)
        descriptor = -1
        # link(2) 提供 no-replace publication；并发 final-file 注入会失败。
        os.link(temporary, path, follow_symlinks=False)
        linked = True
        os.unlink(temporary)
        directory_fd = os.open(path.parent, os.O_RDONLY | getattr(os, "O_CLOEXEC", 0))
        try:
            os.fsync(directory_fd)
        finally:
            os.close(directory_fd)
    except OSError as exc:
        raise IdentityError(f"atomic publication failed for {path}: {exc}") from exc
    finally:
        if descriptor >= 0:
            os.close(descriptor)
        if temporary.exists() or temporary.is_symlink():
            temporary.unlink()
        if not linked and (path.exists() or path.is_symlink()):
            # link 成功前本函数绝不拥有 final；不能删除并发创建者的文件。
            pass
    published = read_bytes_stable(path)
    if published != data:
        raise IdentityError(f"published bytes mismatch: {path}")
    return sha256_bytes(data)


def canonical_json_bytes(value: Any) -> bytes:
    return (json.dumps(value, sort_keys=True, indent=2) + "\n").encode("utf-8")


def atomic_write_json(path: pathlib.Path, value: Any) -> str:
    return atomic_write_bytes(path, canonical_json_bytes(value))


def _mask_preserving_newlines(characters: list[str], start: int, end: int) -> None:
    for index in range(start, end):
        if characters[index] not in {"\n", "\r"}:
            characters[index] = " "


def _cpp_phase2_source_view(source: str) -> dict[str, Any]:
    """先执行 phase-2 splice，并保留每个 logical character 的原始 offset。"""

    logical: list[str] = []
    original_offsets: list[int] = []
    splices: list[tuple[int, int]] = []
    index = 0
    while index < len(source):
        width = 0
        if source.startswith("\\\r\n", index):
            width = 3
        elif source.startswith("\\\n", index) or source.startswith("\\\r", index):
            width = 2
        if width:
            splices.append((index, index + width))
            index += width
            continue
        logical.append(source[index])
        original_offsets.append(index)
        index += 1
    return {
        "logical": "".join(logical),
        "original_offsets": tuple(original_offsets),
        "splices": tuple(splices),
    }


def _cpp_phase3_lexical_mask(logical: str) -> str:
    """在 phase-2 view 上把 comment/literal 替换为空白，保留 logical newline。"""

    output = list(logical)
    raw_prefixes = ("u8R\"", "uR\"", "UR\"", "LR\"", "R\"")
    ordinary_prefixes = ("u8\"", "u\"", "U\"", "L\"", "u8'", "u'", "U'", "L'")
    index = 0
    while index < len(logical):
        previous_is_identifier = index > 0 and (
            logical[index - 1].isalnum() or logical[index - 1] == "_"
        )
        if logical.startswith("//", index):
            closing = logical.find("\n", index + 2)
            closing = len(logical) if closing < 0 else closing
            _mask_preserving_newlines(output, index, closing)
            index = closing
            continue
        if logical.startswith("/*", index):
            closing = logical.find("*/", index + 2)
            if closing < 0:
                raise IdentityError("unterminated C++ block comment")
            closing += 2
            _mask_preserving_newlines(output, index, closing)
            index = closing
            continue
        raw_prefix = next(
            (prefix for prefix in raw_prefixes if logical.startswith(prefix, index)), None
        )
        if raw_prefix is not None and not previous_is_identifier:
            quote = index + len(raw_prefix) - 1
            opening = logical.find("(", quote + 1)
            if opening < 0:
                raise IdentityError("malformed C++ raw string delimiter")
            delimiter = logical[quote + 1 : opening]
            if len(delimiter) > 16 or any(
                character.isspace() or character in {"(", ")", "\\"}
                for character in delimiter
            ):
                raise IdentityError("invalid C++ raw string delimiter")
            terminator = ")" + delimiter + '"'
            closing = logical.find(terminator, opening + 1)
            if closing < 0:
                raise IdentityError("unterminated C++ raw string")
            closing += len(terminator)
            _mask_preserving_newlines(output, index, closing)
            index = closing
            continue
        prefix = next(
            (candidate for candidate in ordinary_prefixes if logical.startswith(candidate, index)),
            None,
        )
        if prefix is not None and previous_is_identifier:
            prefix = None
        quote_character = ""
        quote_index = index
        if prefix is not None:
            quote_character = prefix[-1]
            quote_index = index + len(prefix) - 1
        elif logical[index] in {'"', "'"}:
            quote_character = logical[index]
        if quote_character:
            cursor = quote_index + 1
            while cursor < len(logical):
                character = logical[cursor]
                if character == "\\":
                    if cursor + 1 >= len(logical):
                        raise IdentityError("unterminated C++ escaped literal")
                    cursor += 2
                    continue
                if character == quote_character:
                    cursor += 1
                    break
                if character in {"\n", "\r"}:
                    raise IdentityError("unescaped newline in C++ literal")
                cursor += 1
            else:
                raise IdentityError("unterminated C++ literal")
            _mask_preserving_newlines(output, index, cursor)
            index = cursor
            continue
        index += 1
    return "".join(output)


def _cpp_constant_condition(expression: str) -> bool | None:
    expression = expression.strip()
    while expression.startswith("(") and expression.endswith(")"):
        expression = expression[1:-1].strip()
    if re.fullmatch(r"(?:0+[uUlL]*|false)", expression):
        return False
    if re.fullmatch(r"(?:1+[uUlL]*|true)", expression):
        return True
    return None


def _cpp_preprocessor_activity(lexical_code: str) -> tuple[list[bool], list[bool]]:
    """在 comment-as-space 的 phase-3 view 上解析受限条件指令。"""

    active = [True] * len(lexical_code)
    directive = [False] * len(lexical_code)
    frames: list[dict[str, Any]] = []

    def current_active() -> bool:
        return bool(frames[-1]["current"]) if frames else True

    offset = 0
    for line in lexical_code.splitlines(keepends=True):
        start = offset
        end = start + len(line)
        offset = end
        match = re.match(
            r"^[ \t\v\f\r]*#[ \t]*([A-Za-z_][A-Za-z0-9_]*)?(.*?)(?:\r?\n)?$",
            line,
            re.S,
        )
        before = current_active()
        if match is None:
            if not before:
                for position in range(start, end):
                    active[position] = False
            continue
        for position in range(start, end):
            active[position] = False
            directive[position] = True
        keyword = (match.group(1) or "").lower()
        tail = match.group(2).strip()
        if not keyword:
            raise IdentityError("malformed C++ preprocessor directive")
        if keyword == "if":
            condition = _cpp_constant_condition(tail)
            if condition is None:
                raise IdentityError("unknown C++ preprocessor condition rejected")
            frames.append(
                {
                    "parent": before,
                    "taken": condition,
                    "current": before and condition,
                    "else_seen": False,
                }
            )
        elif keyword in {"ifdef", "ifndef"}:
            raise IdentityError("unknown C++ preprocessor condition rejected")
        elif keyword == "elif":
            if not frames or frames[-1]["else_seen"]:
                raise IdentityError("malformed C++ preprocessor #elif")
            condition = _cpp_constant_condition(tail)
            if condition is None:
                raise IdentityError("unknown C++ preprocessor condition rejected")
            frame = frames[-1]
            frame["current"] = frame["parent"] and not frame["taken"] and condition
            frame["taken"] = frame["taken"] or condition
        elif keyword == "else":
            if tail or not frames or frames[-1]["else_seen"]:
                raise IdentityError("malformed C++ preprocessor #else")
            frame = frames[-1]
            frame["else_seen"] = True
            frame["current"] = frame["parent"] and not frame["taken"]
            frame["taken"] = True
        elif keyword == "endif":
            if tail or not frames:
                raise IdentityError("unmatched C++ preprocessor #endif")
            frames.pop()
        elif keyword == "include":
            if frames and not before:
                continue
        else:
            raise IdentityError(
                f"C++ preprocessor dependency/directive rejected: #{keyword}"
            )
    if offset < len(lexical_code):
        if not current_active():
            for position in range(offset, len(lexical_code)):
                active[position] = False
    if frames:
        raise IdentityError("unterminated C++ preprocessor conditional")
    return active, directive


def _cpp_code_view(source: str) -> dict[str, Any]:
    phase2 = _cpp_phase2_source_view(source)
    lexical = _cpp_phase3_lexical_mask(phase2["logical"])
    active, directive = _cpp_preprocessor_activity(lexical)
    code = list(lexical)
    for index, enabled in enumerate(active):
        if not enabled or directive[index]:
            if code[index] not in {"\n", "\r"}:
                code[index] = " "
    return {
        **phase2,
        "lexical": lexical,
        "active": tuple(active),
        "directive": tuple(directive),
        "code": "".join(code),
    }


def mask_cpp_noncode(source: str) -> str:
    """返回映射回物理 source offset 的 phase-2/phase-3 code mask。"""

    view = _cpp_code_view(source)
    output = [character if character in {"\n", "\r"} else " " for character in source]
    for logical_index, original_index in enumerate(view["original_offsets"]):
        character = view["code"][logical_index]
        if not character.isspace():
            output[original_index] = character
    return "".join(output)


def _cpp_tokens(source: str) -> list[dict[str, Any]]:
    view = _cpp_code_view(source)
    code = view["code"]
    origins = view["original_offsets"]
    tokens: list[dict[str, Any]] = []
    index = 0

    def append_token(text: str, start: int, end: int) -> None:
        tokens.append(
            {
                "text": text,
                "start": origins[start],
                "end": origins[end - 1] + 1,
                "logical_start": start,
                "logical_end": end,
            }
        )

    while index < len(code):
        character = code[index]
        if character.isspace():
            index += 1
            continue
        if character.isalpha() or character == "_":
            start = index
            index += 1
            while index < len(code) and (code[index].isalnum() or code[index] == "_"):
                index += 1
            append_token(code[start:index], start, index)
            continue
        if character.isdigit():
            start = index
            index += 1
            while index < len(code) and (code[index].isalnum() or code[index] in "._'"):
                index += 1
            append_token(code[start:index], start, index)
            continue
        punctuator = next(
            (
                item
                for item in (
                    "<=>", "<<=", ">>=", "->*", "...", "::", "->", "++", "--",
                    "&&", "||", "==", "!=", "<=", ">=", "<<", ">>", "+=", "-=",
                    "*=", "/=", "%=", "&=", "|=", "^=", ".*",
                )
                if code.startswith(item, index)
            ),
            character,
        )
        append_token(punctuator, index, index + len(punctuator))
        index += len(punctuator)
    return tokens


def _find_matching_cpp_token(
    tokens: Sequence[Mapping[str, Any]], opening: int, left: str, right: str
) -> int:
    if opening >= len(tokens) or tokens[opening]["text"] != left:
        raise IdentityError(f"C++ balanced opening mismatch: {left}")
    depth = 0
    for index in range(opening, len(tokens)):
        text = tokens[index]["text"]
        if text == left:
            depth += 1
        elif text == right:
            depth -= 1
            if depth == 0:
                return index
            if depth < 0:
                break
    raise IdentityError(f"unbalanced C++ token structure: {left}{right}")


def _split_cpp_argument_tokens(
    tokens: Sequence[Mapping[str, Any]],
    first: int,
    last: int,
) -> tuple[list[str], list[tuple[int, int]]]:
    if first >= last:
        return [], []
    depths = {"(": 0, "[": 0, "{": 0}
    closing = {")": "(", "]": "[", "}": "{"}
    segments: list[tuple[int, int]] = []
    segment_start = first
    for index in range(first, last):
        text = tokens[index]["text"]
        if text in depths:
            depths[text] += 1
        elif text in closing:
            owner = closing[text]
            if depths[owner] == 0:
                raise IdentityError("unbalanced nested C++ constructor argument")
            depths[owner] -= 1
        elif text == "," and not any(depths.values()):
            if segment_start == index:
                raise IdentityError("empty C++ constructor argument")
            segments.append((segment_start, index))
            segment_start = index + 1
    if any(depths.values()) or segment_start >= last:
        raise IdentityError("unbalanced or empty C++ constructor arguments")
    segments.append((segment_start, last))
    arguments: list[str] = []
    original_ranges: list[tuple[int, int]] = []
    for start, end in segments:
        arguments.append("".join(str(tokens[index]["text"]) for index in range(start, end)))
        original_ranges.append((int(tokens[start]["start"]), int(tokens[end - 1]["end"])))
    return arguments, original_ranges


def _cpp_token_identity(tokens: Sequence[Mapping[str, Any]]) -> tuple[list[str], str]:
    values = [str(token["text"]) for token in tokens]
    digest = sha256_bytes(("\0".join(values) + "\0").encode("utf-8"))
    return values, digest


def audit_f32_constructor_bytes(
    data: bytes, *, enforce_frozen_hash: bool = True
) -> dict[str, Any]:
    """冻结完整 C++ bytes、真实 class identity 与完整 production function template。"""

    try:
        source = data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise IdentityError(f"production C++ is not UTF-8: {exc}") from exc
    cpp_sha256 = sha256_bytes(data)
    if enforce_frozen_hash and cpp_sha256 != EXPECTED_PRODUCTION_CPP_SHA256:
        raise IdentityError(
            "production C++ frozen SHA-256 mismatch: "
            f"expected={EXPECTED_PRODUCTION_CPP_SHA256} actual={cpp_sha256}"
        )
    tokens = _cpp_tokens(source)

    class_definitions: list[tuple[int, int]] = []
    for index in range(len(tokens) - 2):
        if (
            tokens[index]["text"] == "class"
            and tokens[index + 1]["text"] == "f32_alu_harness"
            and tokens[index + 2]["text"] == "{"
        ):
            closing = _find_matching_cpp_token(tokens, index + 2, "{", "}")
            if closing + 1 >= len(tokens) or tokens[closing + 1]["text"] != ";":
                raise IdentityError("f32_alu_harness class definition terminator mismatch")
            class_definitions.append((index, closing + 1))
    if len(class_definitions) != 1:
        raise IdentityError(
            f"f32_alu_harness class definition count mismatch: {len(class_definitions)}"
        )
    class_start, class_close = class_definitions[0]
    class_token_values, class_token_sha256 = _cpp_token_identity(
        tokens[class_start : class_close + 1]
    )

    definitions: list[tuple[int, int, int, int]] = []
    for index in range(len(tokens) - 2):
        if (
            tokens[index]["text"] == "bool"
            and tokens[index + 1]["text"] == F32_EXECUTE_FUNCTION
            and tokens[index + 2]["text"] == "("
        ):
            parameters_close = _find_matching_cpp_token(tokens, index + 2, "(", ")")
            following = parameters_close + 1
            if following < len(tokens) and tokens[following]["text"] == "{":
                body_close = _find_matching_cpp_token(tokens, following, "{", "}")
                definitions.append((index, following, body_close, parameters_close))
    if len(definitions) != 1:
        raise IdentityError(
            f"production execute definition count mismatch: {len(definitions)}"
        )
    definition_index, body_open, body_close, parameters_close = definitions[0]
    function_tokens = tokens[definition_index : body_close + 1]
    function_token_values, function_token_sha256 = _cpp_token_identity(function_tokens)
    expected_tokens = _cpp_tokens(EXPECTED_F32_FUNCTION_TEMPLATE)
    expected_token_values, expected_token_sha256 = _cpp_token_identity(expected_tokens)
    if function_token_values != expected_token_values:
        mismatch = next(
            (
                index
                for index, pair in enumerate(zip(function_token_values, expected_token_values))
                if pair[0] != pair[1]
            ),
            min(len(function_token_values), len(expected_token_values)),
        )
        raise IdentityError(
            "production function token template mismatch: "
            f"index={mismatch} expected_count={len(expected_token_values)} "
            f"actual_count={len(function_token_values)}"
        )
    constructors: list[tuple[int, int, int, str]] = []
    cursor = body_open + 1
    while cursor + 2 < body_close:
        if (
            tokens[cursor]["text"] == "f32_alu_harness"
            and re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", tokens[cursor + 1]["text"])
            and tokens[cursor + 2]["text"] == "("
        ):
            call_close = _find_matching_cpp_token(tokens, cursor + 2, "(", ")")
            if call_close >= body_close:
                raise IdentityError("production constructor escapes function body")
            constructors.append((cursor, cursor + 2, call_close, tokens[cursor + 1]["text"]))
            cursor = call_close + 1
            continue
        cursor += 1
    if len(constructors) != 1:
        raise IdentityError(
            f"production f32_alu_harness constructor count mismatch: {len(constructors)}"
        )
    call_start, call_open, call_close, variable = constructors[0]
    arguments, argument_ranges = _split_cpp_argument_tokens(tokens, call_open + 1, call_close)
    if tuple(arguments) != EXPECTED_F32_CONSTRUCTOR_ARGS:
        raise IdentityError(f"production constructor arguments mismatch: {arguments}")
    return {
        "definition_count": 1,
        "definition_body_balanced": True,
        "definition_extractor": "cpp-phase2-phase3-full-function-template-v2",
        "definition_start": tokens[definition_index]["start"],
        "definition_name_start": tokens[definition_index + 1]["start"],
        "definition_name_end": tokens[definition_index + 1]["end"],
        "parameters_close": tokens[parameters_close]["end"],
        "body_open": tokens[body_open]["start"],
        "body_close": tokens[body_close]["start"],
        "call_count": 1,
        "call_start": tokens[call_start]["start"],
        "call_end": tokens[call_close]["end"],
        "call_arguments_start": tokens[call_open]["end"],
        "call_arguments_end": tokens[call_close]["start"],
        "call_variable": variable,
        "argument_count": len(arguments),
        "arguments": arguments,
        "argument_ranges": argument_ranges,
        "argument_tail": arguments[-3:],
        "cpp_sha256": cpp_sha256,
        "frozen_complete_file_sha256": EXPECTED_PRODUCTION_CPP_SHA256,
        "frozen_complete_file_sha256_verified": enforce_frozen_hash,
        "function_template_token_count": len(function_token_values),
        "function_template_tokens": function_token_values,
        "function_template_sha256": function_token_sha256,
        "expected_function_template_sha256": expected_token_sha256,
        "class_definition_count": 1,
        "class_definition_start": tokens[class_start]["start"],
        "class_definition_end": tokens[class_close]["end"],
        "class_definition_token_count": len(class_token_values),
        "class_definition_token_sha256": class_token_sha256,
        "class_identity_bound_to_frozen_cpp_sha256": enforce_frozen_hash,
        "lexical_mask_preserves_positions": True,
        "translation_phase2_before_phase3": True,
        "phase2_splice_count": len(_cpp_phase2_source_view(source)["splices"]),
        "original_offset_mapping_retained": True,
        "comment_prefixed_directive_recognized": True,
        "unknown_preprocessor_condition_fail_closed": True,
        "preprocessor_if0_masked": True,
        "macro_directives_masked": True,
    }


def f32_constructor_mutation_self_test(data: bytes) -> dict[str, Any]:
    """覆盖 phase2/phase3、完整 function template 与 complete-file hash killer。"""

    source = data.decode("utf-8")
    baseline = audit_f32_constructor_bytes(data)
    definition = source[baseline["definition_start"] : baseline["body_close"] + 1]
    call = source[baseline["call_start"] : baseline["call_end"]]
    argument_indent = "\n            "
    old_arguments = list(EXPECTED_F32_CONSTRUCTOR_ARGS[:8]) + ["false", "result"]
    missing_result_arguments = list(EXPECTED_F32_CONSTRUCTOR_ARGS[:-1])

    def with_arguments(arguments: Sequence[str]) -> str:
        replacement = argument_indent + ("," + argument_indent).join(arguments) + "\n        "
        return (
            source[: baseline["call_arguments_start"]]
            + replacement
            + source[baseline["call_arguments_end"] :]
        )

    old_form = with_arguments(old_arguments)
    missing_result = with_arguments(missing_result_arguments)
    renamed_missing = (
        source[: baseline["definition_name_start"]]
        + F32_EXECUTE_FUNCTION
        + "_decoy_removed"
        + source[baseline["definition_name_end"] :]
    )
    call_type_end = baseline["call_start"] + len("f32_alu_harness")
    macro_call = (
        source[: baseline["call_start"]]
        + "F32_ALU_HARNESS_ALIAS"
        + source[call_type_end:]
        + "\n#define F32_ALU_HARNESS_ALIAS f32_alu_harness\n"
    )
    declaration_only = (
        source[: baseline["body_open"]]
        + ";"
        + source[baseline["body_close"] + 1 :]
    )
    duplicate_call = (
        source[: baseline["call_start"]]
        + call
        + ";\n        "
        + source[baseline["call_start"] :]
    )
    ordinary_decoy = old_form + (
        '\nconst char * f32_ctor_decoy = "f32_alu_harness harness('
        + ", ".join(EXPECTED_F32_CONSTRUCTOR_ARGS)
        + ')";\n'
    )
    raw_decoy = old_form + (
        '\nconst char * f32_raw_decoy = R"tag(f32_alu_harness harness('
        + ", ".join(EXPECTED_F32_CONSTRUCTOR_ARGS)
        + '))tag";\n'
    )
    escaped_decoy = old_form + (
        '\nconst char * f32_escaped_decoy = "f32_alu_harness\\\n harness('
        + ", ".join(EXPECTED_F32_CONSTRUCTOR_ARGS)
        + ')";\n'
    )
    character_preprocessor_decoy = renamed_missing + (
        "\nchar f32_chars[] = {'{', '(', ')', '}'};\n"
        "#define F32_FAKE_DEFINITION bool npu_verilator_execute_f32_alu() { "
        "f32_alu_harness harness(profile); }\n"
    )
    if0_decoy = renamed_missing + "\n#if 0\n" + definition + "\n#endif\n"
    variable_renamed_old_with_decoy = old_form.replace(
        "f32_alu_harness harness(", "f32_alu_harness renamed_harness(", 1
    ) + (
        '\nconst char * exact_call_decoy = "f32_alu_harness harness('
        + ", ".join(EXPECTED_F32_CONSTRUCTOR_ARGS)
        + ')";\n'
    )
    successor = "npu_verilator_run_f32_alu_self_test"
    if source.count(successor) != 1:
        raise IdentityError("successor rename fixture count mismatch")
    successor_renamed = source.replace(successor, successor + "_renamed", 1)

    body_insert = baseline["body_open"] + 1
    physical_line_comment = (
        source[: baseline["call_start"]]
        + "// phase2 comment continues "
        + chr(92)
        + "\n        "
        + source[baseline["call_start"] :]
    )
    comment_prefixed_if0 = (
        source
        + "\n/**/ #if 0\n"
        + definition
        + "\n#endif\n"
    )
    if_false = source[:body_insert] + "\n    if (false) { return true; }\n" + source[body_insert:]
    uncalled_lambda = source[:body_insert] + "\n    auto decoy = [] { return true; };\n" + source[body_insert:]
    local_using = source[:body_insert] + "\n    using f32_alu_harness_alias = f32_alu_harness;\n" + source[body_insert:]
    local_typedef = source[:body_insert] + "\n    typedef f32_alu_harness harness_type;\n" + source[body_insert:]
    type_rebind = source[:body_insert] + "\n    auto & f32_alu_harness = profile;\n" + source[body_insert:]
    argument_rebind = source[:body_insert] + "\n    auto & profile = profile_id;\n" + source[body_insert:]
    function_pointer_decoy = source + (
        "\nusing execute_pointer = bool (*)(std::uint32_t, const std::uint8_t *, "
        "std::size_t, const std::uint8_t *, std::size_t, std::uint8_t *, "
        "std::size_t, npu_verilator_f32_alu_result *);\n"
        "execute_pointer execute_decoy = &npu_verilator_execute_f32_alu;\n"
    )
    overload_decoy = source + "\nbool npu_verilator_execute_f32_alu(int) { return false; }\n"
    unknown_conditional = source + "\n#if F32_UNKNOWN_SWITCH\n" + definition + "\n#endif\n"

    template_harmful = {
        "ordinary_string_decoy": ordinary_decoy,
        "raw_string_decoy": raw_decoy,
        "escaped_literal_decoy": escaped_decoy,
        "macro_decoy": macro_call,
        "renamed_real_with_string_decoy": variable_renamed_old_with_decoy,
        "declaration_without_definition": declaration_only,
        "missing_definition": renamed_missing,
        "duplicate_definition": source + "\n" + definition + "\n",
        "unbalanced_body": source[: baseline["body_close"]],
        "duplicate_real_call": duplicate_call,
        "old_ten_argument_form": old_form,
        "missing_result": missing_result,
        "physical_line_comment_splice": physical_line_comment,
        "if_false_dead_flow": if_false,
        "uncalled_lambda": uncalled_lambda,
        "local_using_decoy": local_using,
        "local_typedef_decoy": local_typedef,
        "local_type_rebind": type_rebind,
        "argument_rebind": argument_rebind,
    }
    hash_harmful = {
        "character_preprocessor_decoy": character_preprocessor_decoy,
        "if0_fake_definition_call": if0_decoy,
        "comment_prefixed_if0": comment_prefixed_if0,
        "declaration_decoy": source + "\nbool npu_verilator_execute_f32_alu(int);\n",
        "overload_decoy": overload_decoy,
        "function_pointer_decoy": function_pointer_decoy,
    }
    preprocessor_harmful = {"unknown_preprocessor_condition": unknown_conditional}
    rejected: dict[str, bool] = {}
    rejection_reasons: dict[str, str] = {}
    classifiers: dict[str, str] = {}
    for name, mutant in template_harmful.items():
        try:
            audit_f32_constructor_bytes(mutant.encode("utf-8"), enforce_frozen_hash=False)
        except IdentityError as exc:
            rejected[name] = True
            rejection_reasons[name] = str(exc)
            classifiers[name] = "lexical-or-function-template"
        else:
            raise IdentityError(f"C++ function-template mutation unexpectedly accepted: {name}")
    for name, mutant in hash_harmful.items():
        try:
            audit_f32_constructor_bytes(mutant.encode("utf-8"))
        except IdentityError as exc:
            if "frozen SHA-256 mismatch" not in str(exc):
                raise IdentityError(f"C++ hash mutation reached wrong classifier: {name}: {exc}") from exc
            rejected[name] = True
            rejection_reasons[name] = str(exc)
            classifiers[name] = "complete-file-sha256"
        else:
            raise IdentityError(f"C++ complete-file mutation unexpectedly accepted: {name}")
    for name, mutant in preprocessor_harmful.items():
        try:
            audit_f32_constructor_bytes(mutant.encode("utf-8"), enforce_frozen_hash=False)
        except IdentityError as exc:
            if "unknown C++ preprocessor condition" not in str(exc):
                raise IdentityError(
                    f"C++ preprocessor mutation reached wrong classifier: {name}: {exc}"
                ) from exc
            rejected[name] = True
            rejection_reasons[name] = str(exc)
            classifiers[name] = "preprocessor-fail-closed"
        else:
            raise IdentityError(f"C++ preprocessor mutation unexpectedly accepted: {name}")
    successor_observation = audit_f32_constructor_bytes(
        successor_renamed.encode("utf-8"), enforce_frozen_hash=False
    )
    baseline_observation = audit_f32_constructor_bytes(data, enforce_frozen_hash=False)
    for key in (
        "arguments",
        "function_template_tokens",
        "function_template_sha256",
        "class_definition_token_sha256",
    ):
        if successor_observation[key] != baseline_observation[key]:
            raise IdentityError(f"successor rename changed production template observation: {key}")
    return {
        "harmful_mutations_rejected": rejected,
        "rejection_reasons": rejection_reasons,
        "classifiers": classifiers,
        "successor_rename_accepted": True,
        "successor_template_observation_unchanged": True,
        "successor_hash_check_intentionally_disabled": True,
    }


def _cmake_bracket_open(text: str, index: int) -> tuple[str, int] | None:
    match = re.match(r"\[(=*)\[", text[index:])
    if match is None:
        return None
    equals = match.group(1)
    return "]" + equals + "]", len(match.group(0))


def _cmake_skip_space_comment(text: str, index: int) -> int:
    while index < len(text):
        if text[index].isspace():
            index += 1
            continue
        if text[index] != "#":
            break
        bracket = _cmake_bracket_open(text, index + 1)
        if bracket is not None:
            terminator, width = bracket
            closing = text.find(terminator, index + 1 + width)
            if closing < 0:
                raise IdentityError("unterminated CMake bracket comment")
            index = closing + len(terminator)
            continue
        closing = text.find("\n", index + 1)
        index = len(text) if closing < 0 else closing + 1
    return index


def _cmake_extract_command(text: str, opening: int) -> tuple[int, int, int]:
    depth = 1
    index = opening + 1
    while index < len(text):
        character = text[index]
        if character == "#":
            index = _cmake_skip_space_comment(text, index)
            continue
        bracket = _cmake_bracket_open(text, index)
        if bracket is not None:
            terminator, width = bracket
            closing = text.find(terminator, index + width)
            if closing < 0:
                raise IdentityError("unterminated CMake bracket argument")
            index = closing + len(terminator)
            continue
        if character == '"':
            index += 1
            while index < len(text):
                if text[index] == "\\":
                    index += 2
                    continue
                if text[index] == '"':
                    index += 1
                    break
                index += 1
            else:
                raise IdentityError("unterminated CMake quoted argument")
            continue
        if character == "(":
            depth += 1
        elif character == ")":
            depth -= 1
            if depth == 0:
                return opening + 1, index, index + 1
        index += 1
    raise IdentityError("unterminated CMake command invocation")


def _cmake_tokens(body: str) -> list[dict[str, str]]:
    tokens: list[dict[str, str]] = []
    index = 0
    while index < len(body):
        index = _cmake_skip_space_comment(body, index)
        if index >= len(body):
            break
        bracket = _cmake_bracket_open(body, index)
        if bracket is not None:
            terminator, width = bracket
            closing = body.find(terminator, index + width)
            if closing < 0:
                raise IdentityError("unterminated CMake bracket token")
            tokens.append(
                {
                    "kind": "bracket",
                    "raw": body[index : closing + len(terminator)],
                    "value": body[index + width : closing],
                }
            )
            index = closing + len(terminator)
            continue
        if body[index] == '"':
            start = index
            index += 1
            value: list[str] = []
            while index < len(body):
                if body[index] == "\\":
                    if index + 1 >= len(body):
                        raise IdentityError("unterminated CMake quoted escape")
                    value.append(body[index + 1])
                    index += 2
                    continue
                if body[index] == '"':
                    index += 1
                    break
                value.append(body[index])
                index += 1
            else:
                raise IdentityError("unterminated CMake quoted token")
            tokens.append(
                {"kind": "quoted", "raw": body[start:index], "value": "".join(value)}
            )
            continue
        start = index
        while index < len(body) and not body[index].isspace() and body[index] != "#":
            index += 1
        if start == index:
            raise IdentityError("unparsed CMake command byte")
        tokens.append(
            {"kind": "unquoted", "raw": body[start:index], "value": body[start:index]}
        )
    return tokens


def parse_cmake_commands_bytes(data: bytes) -> list[dict[str, Any]]:
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise IdentityError(f"CMakeLists.txt is not UTF-8: {exc}") from exc
    commands: list[dict[str, Any]] = []
    blocks: list[tuple[str, str]] = []
    openers = {
        "if": "endif",
        "foreach": "endforeach",
        "while": "endwhile",
        "function": "endfunction",
        "macro": "endmacro",
        "block": "endblock",
    }
    closers = {value: key for key, value in openers.items()}
    index = 0
    while index < len(text):
        index = _cmake_skip_space_comment(text, index)
        if index >= len(text):
            break
        if text[index] == '"' or _cmake_bracket_open(text, index) is not None:
            raise IdentityError("top-level CMake literal outside command rejected")
        name_match = re.match(r"[A-Za-z_][A-Za-z0-9_]*", text[index:])
        if name_match is None:
            raise IdentityError(f"unparsed top-level CMake byte at offset {index}")
        name = name_match.group(0).lower()
        command_start = index
        index += len(name_match.group(0))
        index = _cmake_skip_space_comment(text, index)
        if index >= len(text) or text[index] != "(":
            raise IdentityError(f"CMake command opening parenthesis missing: {name}")
        body_start, body_end, command_end = _cmake_extract_command(text, index)
        if name in closers:
            if not blocks or blocks[-1][1] != name:
                raise IdentityError(f"mismatched CMake block closer: {name}")
            scope = tuple(item[0] for item in blocks)
            blocks.pop()
        else:
            scope = tuple(item[0] for item in blocks)
        command = {
            "name": name,
            "start": command_start,
            "end": command_end,
            "scope": scope,
            "tokens": _cmake_tokens(text[body_start:body_end]),
        }
        commands.append(command)
        if name in openers:
            blocks.append((name, openers[name]))
        index = command_end
    if blocks:
        raise IdentityError(f"unterminated CMake block scope: {blocks[-1][0]}")
    return commands


def _cmake_variable_expansions(token: Mapping[str, str]) -> int:
    if token["kind"] == "bracket":
        return 0
    return len(re.findall(r"(?<!\\)\$\{NPU_RTL_SOURCES\}", token["raw"]))


def _cmake_token_template(
    tokens: Sequence[Mapping[str, str]],
) -> tuple[tuple[str, str], ...]:
    return tuple((token["kind"], token["value"]) for token in tokens)


def _cmake_template_sha256(template: Sequence[tuple[str, str]]) -> str:
    return sha256_bytes(
        ("".join(f"{kind}\0{value}\0" for kind, value in template)).encode("utf-8")
    )


def _cmake_require_canonical_token_spellings(
    tokens: Sequence[Mapping[str, str]], context: str
) -> None:
    """拒绝会改变 CMake 展开语义、却归一到相同 value 的 escape 拼写。"""

    for token in tokens:
        if token["kind"] == "quoted":
            expected_raw = f'"{token["value"]}"'
        elif token["kind"] == "unquoted":
            expected_raw = token["value"]
        else:
            raise IdentityError(f"frozen CMake {context} bracket token rejected")
        if token["raw"] != expected_raw:
            raise IdentityError(f"frozen CMake {context} token spelling mismatch")


def _cmake_require_exact_set(
    commands: Sequence[Mapping[str, Any]], name: str, expected_value: str
) -> None:
    matches = [
        command
        for command in commands
        if command["name"] == "set"
        and command["tokens"]
        and command["tokens"][0]["value"] == name
    ]
    expected = (("unquoted", name), ("quoted", expected_value))
    if (
        len(matches) != 1
        or matches[0]["scope"] != ()
        or _cmake_token_template(matches[0]["tokens"]) != expected
    ):
        raise IdentityError(f"frozen CMake producer variable mismatch: {name}")
    _cmake_require_canonical_token_spellings(matches[0]["tokens"], name)


def _cmake_source_and_consumer_audit(data: bytes) -> dict[str, Any]:
    commands = parse_cmake_commands_bytes(data)
    producers = [command for command in commands if command["name"] == "add_custom_command"]
    if len(producers) != 1 or producers[0]["scope"] != ():
        raise IdentityError(
            f"frozen CMake competing producer/count mismatch: {len(producers)}"
        )
    producer = producers[0]

    for command in commands:
        if command["name"] == "return":
            raise IdentityError("restricted CMake return rejected")
        if command["name"] == "cmake_language":
            raise IdentityError("restricted CMake dynamic EVAL/CALL rejected")
        if command["name"] == "variable_watch":
            raise IdentityError("restricted CMake variable_watch rejected")
        if command["start"] < producer["end"] and command["name"] in {
            "function",
            "endfunction",
            "macro",
            "endmacro",
            "block",
            "endblock",
            "foreach",
            "endforeach",
            "while",
            "endwhile",
            "unset",
            "list",
            "string",
        }:
            raise IdentityError(
                f"restricted CMake pre-producer control/mutation rejected: {command['name']}"
            )
        for token in command["tokens"]:
            raw = token["raw"]
            if "${${" in raw or re.search(r"\$\{[^{}]*\$\{", raw):
                raise IdentityError("restricted CMake indirect variable construction rejected")

    allowed_includes = [
        command
        for command in commands
        if command["name"] == "include"
        and command["scope"] == ()
        and [token["value"] for token in command["tokens"]] == ["ProcessorCount"]
    ]
    includes = [command for command in commands if command["name"] == "include"]
    if len(allowed_includes) != 1 or len(includes) != 1:
        raise IdentityError("restricted CMake include/override rejected")

    target_sets: list[dict[str, Any]] = []
    for command in commands:
        tokens = command["tokens"]
        direct_positions = [
            index for index, token in enumerate(tokens) if token["value"] == "NPU_RTL_SOURCES"
        ]
        if command["name"] == "set" and direct_positions == [0]:
            target_sets.append(command)
            continue
        if command is producer:
            continue
        if any("NPU_RTL_SOURCE" in token["raw"] for token in tokens):
            raise IdentityError(
                f"restricted CMake variable mutation/alias/indirection rejected: {command['name']}"
            )
    if len(target_sets) != 1 or target_sets[0]["scope"] != ():
        raise IdentityError(
            "unconditional top-level set(NPU_RTL_SOURCES ...) count must be one"
        )
    source_tokens = target_sets[0]["tokens"][1:]
    if not source_tokens or any(token["kind"] != "quoted" for token in source_tokens):
        raise IdentityError("NPU_RTL_SOURCES requires only quoted literal path arguments")
    ordered = validate_ordered_sources(
        [_canonicalize_cmake_token(token["value"]) for token in source_tokens]
    )
    for token, relative in zip(source_tokens, ordered, strict=True):
        expected_raw = f'"${{NPU_PROJECT_ROOT}}/{relative}"'
        if token["raw"] != expected_raw:
            raise IdentityError("frozen CMake quoted source token spelling mismatch")

    producer_template = _cmake_token_template(producer["tokens"])
    if any("$<" in token["raw"] for token in producer["tokens"]):
        raise IdentityError("restricted CMake producer generator expression rejected")
    if producer_template != EXPECTED_CMAKE_PRODUCER_TEMPLATE:
        raise IdentityError("frozen CMake producer token template mismatch")
    _cmake_require_canonical_token_spellings(producer["tokens"], "producer")

    expansions: list[tuple[dict[str, Any], int]] = []
    name_mentions: list[tuple[dict[str, Any], int]] = []
    for command in commands:
        for index, token in enumerate(command["tokens"]):
            if "NPU_RTL_SOURCES" in token["raw"]:
                name_mentions.append((command, index))
            for _ in range(_cmake_variable_expansions(token)):
                expansions.append((command, index))
    allowed_mentions = {(id(target_sets[0]), 0), (id(producer), 24), (id(producer), 34)}
    observed_mentions = {(id(command), index) for command, index in name_mentions}
    if observed_mentions != allowed_mentions:
        raise IdentityError("restricted CMake NPU_RTL_SOURCES mention allowlist mismatch")
    if len(expansions) != 2 or any(command is not producer for command, _ in expansions):
        raise IdentityError("NPU_RTL_SOURCES consumers must share one top-level add_custom_command")
    expansion_indices = [index for _, index in expansions]
    for index in expansion_indices:
        token = producer["tokens"][index]
        if token["kind"] != "unquoted" or token["raw"] != "${NPU_RTL_SOURCES}":
            raise IdentityError("NPU_RTL_SOURCES consumer must be bare unquoted exact token")

    section_keywords = {
        "OUTPUT", "COMMAND", "MAIN_DEPENDENCY", "DEPENDS", "BYPRODUCTS",
        "IMPLICIT_DEPENDS", "WORKING_DIRECTORY", "COMMENT", "DEPFILE",
        "JOB_POOL", "VERBATIM", "APPEND", "USES_TERMINAL", "COMMAND_EXPAND_LISTS",
        "JOB_SERVER_AWARE", "CODEGEN",
    }
    section = ""
    expansion_sections: list[str] = []
    expansion_index_set = set(expansion_indices)
    for index, token in enumerate(producer["tokens"]):
        if token["kind"] == "unquoted" and token["value"] in section_keywords:
            section = token["value"]
        if index in expansion_index_set:
            expansion_sections.append(section)
    if expansion_sections != ["COMMAND", "DEPENDS"]:
        raise IdentityError(
            f"NPU_RTL_SOURCES consumer sections mismatch: {expansion_sections}"
        )

    targets = [command for command in commands if command["name"] == "add_custom_target"]
    if (
        len(targets) != 1
        or targets[0]["scope"] != ()
        or _cmake_token_template(targets[0]["tokens"])
        != EXPECTED_CMAKE_TARGET_TEMPLATE
    ):
        raise IdentityError("frozen CMake downstream target template mismatch")
    if any("$<" in token["raw"] for token in targets[0]["tokens"]):
        raise IdentityError("restricted CMake downstream generator expression rejected")
    _cmake_require_canonical_token_spellings(targets[0]["tokens"], "downstream target")

    _cmake_require_exact_set(
        commands,
        "NPU_VERILATED_ARCHIVE",
        "${NPU_VERILATED_MDIR}/VTensorNpuCoprocessor__ALL.a",
    )
    _cmake_require_exact_set(
        commands,
        "NPU_VERILATED_HEADER",
        "${NPU_VERILATED_MDIR}/VTensorNpuCoprocessor.h",
    )
    return {
        "ordered_sources": ordered,
        "consumer_binding": {
            "same_variable": "NPU_RTL_SOURCES",
            "all_expansion_count": 2,
            "verilator_command_expansion_count": 1,
            "depends_expansion_count": 1,
            "verilator_and_depends_bound": True,
            "unconditional_top_level_set": True,
            "unconditional_top_level_custom_command": True,
            "bare_unquoted_exact_consumers": True,
            "producer_template_exact": True,
            "producer_template_sha256": _cmake_template_sha256(producer_template),
            "canonical_token_spellings": True,
            "downstream_target_template_exact": True,
            "competing_producer_count": 0,
            "active_structure_allowlist": True,
            "restricted_parser": "cmake-frozen-producer-grammar-v2",
        },
        "command_count": len(commands),
    }


def category_for_source(relative: str) -> str:
    if relative.startswith("third_party/fpu-sp/verilog/src/float/"):
        return "fpu-float"
    if relative.startswith("third_party/fpu-sp/verilog/src/lzc/"):
        return "fpu-lzc"
    if relative.startswith("rtl/") and relative.endswith(".v"):
        return "rtl-verilog"
    if relative.startswith("rtl/") and relative.endswith(".vh"):
        return "rtl-include"
    return "unknown"


def _canonicalize_cmake_token(token: str) -> str:
    prefix = "${NPU_PROJECT_ROOT}/"
    if not token.startswith(prefix):
        raise IdentityError(f"non-canonical NPU_PROJECT_ROOT token: {token}")
    relative = token[len(prefix) :]
    if not relative or "\\" in relative or "//" in relative:
        raise IdentityError(f"path alias rejected: {token}")
    parts = pathlib.PurePosixPath(relative).parts
    if any(part in {"", ".", ".."} for part in parts):
        raise IdentityError(f"path alias rejected: {token}")
    canonical = pathlib.PurePosixPath(*parts).as_posix()
    if canonical != relative:
        raise IdentityError(f"path alias rejected: {token}")
    return canonical


def validate_ordered_sources(actual: Sequence[str]) -> tuple[str, ...]:
    actual_tuple = tuple(actual)
    duplicates = sorted({item for item in actual_tuple if actual_tuple.count(item) > 1})
    if duplicates:
        raise IdentityError("duplicate source rejected: " + ",".join(duplicates))
    if len(actual_tuple) < len(EXPECTED_RTL_SOURCES):
        missing = [item for item in EXPECTED_RTL_SOURCES if item not in actual_tuple]
        raise IdentityError("missing source rejected: " + ",".join(missing))
    if len(actual_tuple) > len(EXPECTED_RTL_SOURCES):
        extra = [item for item in actual_tuple if item not in EXPECTED_RTL_SOURCES]
        raise IdentityError("extra source rejected: " + ",".join(extra))
    for index, (actual_item, expected_item) in enumerate(
        zip(actual_tuple, EXPECTED_RTL_SOURCES, strict=True)
    ):
        if actual_item == expected_item:
            continue
        actual_category = category_for_source(actual_item)
        expected_category = category_for_source(expected_item)
        if actual_category != expected_category:
            raise IdentityError(
                "category collision rejected at "
                f"index {index}: expected={expected_category}:{expected_item} "
                f"actual={actual_category}:{actual_item}"
            )
        raise IdentityError(
            f"source substitution rejected at index {index}: "
            f"expected={expected_item} actual={actual_item}"
        )
    if set(actual_tuple) != set(EXPECTED_RTL_SOURCES):
        raise IdentityError("exact ordered source set mismatch")
    return actual_tuple


def parse_cmake_sources_bytes(data: bytes) -> tuple[str, ...]:
    return _cmake_source_and_consumer_audit(data)["ordered_sources"]


def validate_cmake_consumers(data: bytes) -> dict[str, Any]:
    """确认同一个 source set 只驱动同一个 top-level command 与 DEPENDS。"""

    return _cmake_source_and_consumer_audit(data)["consumer_binding"]


def build_cmake_identity(
    repo_root: pathlib.Path, cmake_path: pathlib.Path
) -> dict[str, Any]:
    repo_root = repo_root.resolve(strict=True)
    npu_root = (repo_root / "npu/version_0820").resolve(strict=True)
    cmake_data = read_bytes_stable(cmake_path)
    cmake_sha256 = sha256_bytes(cmake_data)
    if cmake_sha256 != EXPECTED_CMAKE_SHA256:
        raise IdentityError(
            "production CMake frozen SHA-256 mismatch: "
            f"expected={EXPECTED_CMAKE_SHA256} actual={cmake_sha256}"
        )
    ordered = parse_cmake_sources_bytes(cmake_data)
    consumer_binding = validate_cmake_consumers(cmake_data)
    records: list[dict[str, Any]] = []
    for index, relative in enumerate(ordered):
        source = npu_root / relative
        resolved = source.resolve(strict=True)
        try:
            resolved.relative_to(npu_root)
        except ValueError as exc:
            raise IdentityError(f"source escapes NPU root: {relative}") from exc
        if resolved != source.absolute():
            raise IdentityError(f"source symlink/path alias rejected: {relative}")
        data = read_bytes_stable(source)
        records.append(
            {
                "index": index,
                "path": relative,
                "category": category_for_source(relative),
                "sha256": sha256_bytes(data),
                "size_bytes": len(data),
            }
        )
    aggregate = "".join(
        f"{item['index']}\t{item['category']}\t{item['path']}\t{item['sha256']}\n"
        for item in records
    ).encode("utf-8")
    return {
        "schema": SCHEMA_CMAKE,
        "cmake_path": cmake_path.resolve(strict=True).relative_to(repo_root).as_posix(),
        "cmake_sha256": cmake_sha256,
        "frozen_complete_file_sha256": EXPECTED_CMAKE_SHA256,
        "frozen_complete_file_sha256_verified": True,
        "source_count": len(records),
        "exact_order": True,
        "ordered_source_identity_sha256": sha256_bytes(aggregate),
        "ordered_sources": records,
        "consumer_binding": consumer_binding,
        "frozen_cmake_template": "PASS",
        "actual_configured_argv": "GAP",
        "compile_membership_status": "GAP",
        "verfiles_observed": False,
    }


def _canonical_manifest_relative(relative: str) -> pathlib.PurePosixPath:
    if not relative or "\\" in relative or relative.startswith("/") or "//" in relative:
        raise IdentityError(f"non-canonical artifact path rejected: {relative}")
    pure = pathlib.PurePosixPath(relative)
    if any(part in {"", ".", ".."} for part in pure.parts) or pure.as_posix() != relative:
        raise IdentityError(f"non-canonical artifact path rejected: {relative}")
    return pure


def build_artifact_record(
    root: pathlib.Path, path: pathlib.Path, expected_schema: str | None = None
) -> dict[str, Any]:
    """绑定 fresh staging artifact 的 canonical path/bytes/size/schema。"""

    root = root.resolve(strict=True)
    path = pathlib.Path(path)
    resolved = path.resolve(strict=True)
    try:
        relative = resolved.relative_to(root).as_posix()
    except ValueError as exc:
        raise IdentityError(f"artifact escapes root: {path}") from exc
    if path.absolute() != resolved:
        raise IdentityError(f"artifact symlink/path alias rejected: {path}")
    _canonical_manifest_relative(relative)
    data = read_bytes_stable(path)
    record: dict[str, Any] = {
        "sha256": sha256_bytes(data),
        "size_bytes": len(data),
        "kind": "json" if expected_schema is not None else "bytes",
        "schema": expected_schema,
    }
    if expected_schema is not None:
        try:
            value = json.loads(data)
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise IdentityError(f"invalid staged JSON artifact {relative}: {exc}") from exc
        if not isinstance(value, dict) or value.get("schema") != expected_schema:
            raise IdentityError(
                f"staged artifact schema mismatch: {relative}: {expected_schema}"
            )
    return record


def revalidate_bound_artifacts(
    root: pathlib.Path, artifacts: Mapping[str, Mapping[str, Any]]
) -> dict[str, Any]:
    """晚期逐项重开 manifest 对象；不复用首次 hash/parse 的内存结果。"""

    root = root.resolve(strict=True)
    if not artifacts:
        raise IdentityError("bound artifact manifest must be non-empty")
    aggregate: list[str] = []
    for relative in sorted(artifacts):
        pure = _canonical_manifest_relative(relative)
        record = artifacts[relative]
        if set(record) != {"sha256", "size_bytes", "kind", "schema"}:
            raise IdentityError(f"artifact record field mismatch: {relative}")
        path = root / pure
        observed = build_artifact_record(
            root,
            path,
            record["schema"] if record["kind"] == "json" else None,
        )
        if observed != dict(record):
            raise IdentityError(f"late artifact replacement/drift rejected: {relative}")
        aggregate.append(
            f"{relative}\t{record['kind']}\t{record['schema']}\t"
            f"{record['size_bytes']}\t{record['sha256']}\n"
        )
    return {
        "artifact_count": len(artifacts),
        "artifact_identity_sha256": sha256_bytes("".join(aggregate).encode("utf-8")),
        "all_reopened": True,
        "all_schema_revalidated": True,
    }


def parse_verfiles_s_rows(data: bytes) -> list[str]:
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise IdentityError(f"verFiles.dat is not UTF-8: {exc}") from exc
    rows: list[str] = []
    for line in text.splitlines():
        try:
            fields = shlex.split(line, comments=False, posix=True)
        except ValueError as exc:
            raise IdentityError(f"invalid verFiles.dat row: {line}: {exc}") from exc
        if not fields or fields[0] != "S":
            continue
        if len(fields) < 2:
            raise IdentityError(f"empty S row rejected: {line}")
        # Preserve the spelling recorded by Verilator.  Canonicalisation belongs
        # to the caller so aliases (``..`` components and symlink spellings) are
        # rejected instead of silently normalised into an allowed source.
        rows.append(fields[-1])
    if not rows:
        raise IdentityError("verFiles.dat contains no S rows")
    return rows


def parse_make_depfile_bytes(data: bytes) -> list[dict[str, list[str]]]:
    """解析 deterministic Make depfile，支持 continuation/escaped space/backslash。"""

    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise IdentityError(f"depfile is not UTF-8: {exc}") from exc
    if "\0" in text:
        raise IdentityError("depfile NUL byte rejected")
    logical: list[str] = []
    index = 0
    while index < len(text):
        if text.startswith("\\\r\n", index):
            logical.append(" ")
            index += 3
            continue
        if text.startswith("\\\n", index):
            logical.append(" ")
            index += 2
            continue
        logical.append(text[index])
        index += 1
    joined = "".join(logical)

    def split_fields(fragment: str) -> list[str]:
        fields: list[str] = []
        value: list[str] = []
        cursor = 0
        while cursor < len(fragment):
            character = fragment[cursor]
            if character == "\\":
                if cursor + 1 >= len(fragment):
                    raise IdentityError("dangling depfile escape")
                escaped = fragment[cursor + 1]
                if escaped not in {" ", "\t", "\\", "#", ":"}:
                    raise IdentityError(f"unsupported depfile escape: \\{escaped}")
                value.append(escaped)
                cursor += 2
                continue
            if character.isspace():
                if value:
                    fields.append("".join(value))
                    value = []
                cursor += 1
                continue
            if character in {"#", "$", "%", "*", "?", "[", "]", "|"}:
                raise IdentityError(f"non-deterministic depfile syntax rejected: {character}")
            value.append(character)
            cursor += 1
        if value:
            fields.append("".join(value))
        return fields

    rules: list[dict[str, list[str]]] = []
    for raw_line in joined.splitlines():
        if not raw_line.strip():
            continue
        colons: list[int] = []
        escaped = False
        for position, character in enumerate(raw_line):
            if escaped:
                escaped = False
                continue
            if character == "\\":
                escaped = True
            elif character == ":":
                colons.append(position)
        if escaped:
            raise IdentityError("dangling depfile line escape")
        if len(colons) != 1:
            raise IdentityError(f"depfile rule colon count mismatch: {len(colons)}")
        targets = split_fields(raw_line[: colons[0]])
        prerequisites = split_fields(raw_line[colons[0] + 1 :])
        if not targets or not prerequisites:
            raise IdentityError("depfile rule requires target and prerequisites")
        if len(targets) != len(set(targets)) or len(prerequisites) != len(set(prerequisites)):
            raise IdentityError("duplicate depfile target/prerequisite rejected")
        rules.append({"targets": targets, "prerequisites": prerequisites})
    if not rules:
        raise IdentityError("empty depfile rejected")
    return rules


def _canonical_existing_path(
    value: str | pathlib.Path,
    *,
    cwd: pathlib.Path | None = None,
    require_directory: bool = False,
) -> pathlib.Path:
    raw = pathlib.Path(value).as_posix()
    if not raw or "//" in raw:
        raise IdentityError(f"path alias rejected: {value}")
    pure = pathlib.PurePosixPath(raw)
    if any(part in {"", ".", ".."} for part in pure.parts):
        raise IdentityError(f"path alias rejected: {value}")
    candidate = pathlib.Path(raw)
    if not candidate.is_absolute():
        if cwd is None:
            raise IdentityError(f"relative path lacks declared cwd: {value}")
        candidate = cwd / candidate
    try:
        resolved = candidate.resolve(strict=True)
    except OSError as exc:
        raise IdentityError(f"declared dependency path is stale/missing: {value}: {exc}") from exc
    if candidate.absolute() != resolved:
        raise IdentityError(f"path alias/symlink rejected: {value}")
    try:
        observed = resolved.lstat()
    except OSError as exc:
        raise IdentityError(f"cannot lstat declared dependency path: {value}: {exc}") from exc
    if require_directory:
        if not stat.S_ISDIR(observed.st_mode):
            raise IdentityError(f"declared root is not a directory: {value}")
    elif not stat.S_ISREG(observed.st_mode):
        raise IdentityError(f"dependency object is not regular: {value}")
    return resolved


def _inside_declared_roots(path: pathlib.Path, roots: Sequence[pathlib.Path]) -> bool:
    for root in roots:
        try:
            path.relative_to(root)
            return True
        except ValueError:
            continue
    return False


def _compare_classified_rows(
    actual: Mapping[str, Sequence[str]], expected: Mapping[str, Sequence[str]]
) -> None:
    owners: dict[str, set[str]] = {}
    for class_name, rows in actual.items():
        for row in rows:
            owners.setdefault(row, set()).add(class_name)
    collisions = {path: classes for path, classes in owners.items() if len(classes) != 1}
    if collisions:
        raise IdentityError(f"verFiles category collision rejected: {collisions}")
    flattened = [row for rows in actual.values() for row in rows]
    duplicates = sorted({row for row in flattened if flattened.count(row) > 1})
    if duplicates:
        raise IdentityError("duplicate verFiles S row rejected: " + ",".join(duplicates))
    for class_name in sorted(set(actual) | set(expected)):
        actual_set = set(actual.get(class_name, ()))
        expected_set = set(expected.get(class_name, ()))
        missing = sorted(expected_set - actual_set)
        extra = sorted(actual_set - expected_set)
        if missing or extra:
            raise IdentityError(
                f"verFiles {class_name} membership mismatch: "
                f"missing={missing} extra={extra}"
            )


def _verfiles_mutation_self_test(expected: Mapping[str, Sequence[str]]) -> dict[str, bool]:
    baseline = {name: list(rows) for name, rows in expected.items()}
    design = baseline.get("design", [])
    if not design:
        raise IdentityError("verFiles mutation baseline has no design rows")
    mutations: dict[str, dict[str, list[str]]] = {}
    missing = {name: list(rows) for name, rows in baseline.items()}
    missing["design"] = missing["design"][1:]
    mutations["missing"] = missing
    extra = {name: list(rows) for name, rows in baseline.items()}
    extra["design"].append("/invalid/extra-production-source.v")
    mutations["extra"] = extra
    substitution = {name: list(rows) for name, rows in baseline.items()}
    substitution["design"][0] = "/invalid/substituted-production-source.sv"
    mutations["substitution"] = substitution
    collision = {name: list(rows) for name, rows in baseline.items()}
    collision.setdefault("control", []).append(collision["design"][0])
    mutations["class_collision"] = collision
    results: dict[str, bool] = {}
    for name, mutant in mutations.items():
        try:
            _compare_classified_rows(mutant, baseline)
        except IdentityError:
            results[name] = True
        else:
            raise IdentityError(f"verFiles mutation unexpectedly accepted: {name}")
    return results


def audit_verfiles(
    repo_root: pathlib.Path,
    cmake_path: pathlib.Path,
    verfiles_path: pathlib.Path,
    transitive_sources: Sequence[pathlib.Path],
    control_sources: Sequence[pathlib.Path],
    tool_sources: Sequence[pathlib.Path],
    dependency_files: Sequence[pathlib.Path],
    *,
    expected_build_root: pathlib.Path,
    object_targets: Sequence[pathlib.Path],
    compiler_argv_path: pathlib.Path,
    compiler_argv_sha256: str,
    declared_roots: Sequence[pathlib.Path],
) -> dict[str, Any]:
    if not control_sources or not tool_sources:
        raise IdentityError("verFiles control/tool closure must be explicit and non-empty")
    if not dependency_files:
        raise IdentityError("actual compiler dependency files must be parsed and sealed")
    if not object_targets or not declared_roots:
        raise IdentityError("object targets and declared roots must be explicit and non-empty")
    if not re.fullmatch(r"[0-9a-f]{64}", compiler_argv_sha256):
        raise IdentityError("caller-supplied compiler argv SHA-256 is invalid")

    repo_root = repo_root.resolve(strict=True)
    npu_root = (repo_root / "npu/version_0820").resolve(strict=True)
    build_root = _canonical_existing_path(
        expected_build_root, require_directory=True
    )
    roots = [
        _canonical_existing_path(path, require_directory=True) for path in declared_roots
    ]
    if npu_root not in roots or build_root not in roots:
        raise IdentityError("declared roots must include exact NPU and expected build roots")

    cmake_identity = build_cmake_identity(repo_root, cmake_path)
    expected: dict[str, list[str]] = {
        "design": [str(_canonical_existing_path(npu_root / item["path"])) for item in cmake_identity["ordered_sources"]],
        "transitive": [str(_canonical_existing_path(path)) for path in transitive_sources],
        "control": [str(_canonical_existing_path(path)) for path in control_sources],
        "tool": [str(_canonical_existing_path(path)) for path in tool_sources],
    }
    expected_owners: dict[str, list[str]] = {}
    for class_name, rows in expected.items():
        for row in rows:
            if not _inside_declared_roots(pathlib.Path(row), roots):
                raise IdentityError(f"declared prerequisite escapes roots: {row}")
            expected_owners.setdefault(row, []).append(class_name)
    collisions = {path: names for path, names in expected_owners.items() if len(names) != 1}
    if collisions:
        raise IdentityError(f"declared closure category collision: {collisions}")

    verfiles_path = _canonical_existing_path(verfiles_path)
    try:
        verfiles_path.relative_to(build_root)
    except ValueError as exc:
        raise IdentityError("verFiles.dat is outside expected build root") from exc
    verfiles_data = read_bytes_stable(verfiles_path)
    rows = [str(_canonical_existing_path(row)) for row in parse_verfiles_s_rows(verfiles_data)]
    actual: dict[str, list[str]] = {name: [] for name in expected}
    for row in rows:
        owners = expected_owners.get(row, [])
        if len(owners) != 1:
            raise IdentityError(f"unclassified/ambiguous verFiles S row: {row}")
        actual[owners[0]].append(row)
    _compare_classified_rows(actual, expected)

    targets = [_canonical_existing_path(path) for path in object_targets]
    if len(targets) != len(set(targets)):
        raise IdentityError("duplicate actual object target rejected")
    for target in targets:
        try:
            target.relative_to(build_root)
        except ValueError as exc:
            raise IdentityError(f"object target outside expected build root: {target}") from exc

    dep_paths = [_canonical_existing_path(path) for path in dependency_files]
    if len(dep_paths) != len(set(dep_paths)):
        raise IdentityError("duplicate dependency file rejected")
    for path in dep_paths:
        try:
            path.relative_to(build_root)
        except ValueError as exc:
            raise IdentityError(f"depfile outside expected build root: {path}") from exc

    argv_path = _canonical_existing_path(compiler_argv_path)
    try:
        argv_path.relative_to(build_root)
    except ValueError as exc:
        raise IdentityError("compiler argv identity outside expected build root") from exc
    argv_value, argv_sha, argv_bytes = read_json_same_bytes(argv_path)
    if argv_sha != compiler_argv_sha256:
        raise IdentityError("compiler argv external identity mismatch")
    if not isinstance(argv_value, dict) or argv_value.get("schema") != SCHEMA_COMPILER_ARGV:
        raise IdentityError("compiler argv schema mismatch")
    expected_category_rows = {name: sorted(values) for name, values in expected.items()}
    expected_target_rows = [str(path) for path in targets]
    expected_dep_rows = [str(path) for path in dep_paths]
    if (
        argv_value.get("build_root") != str(build_root)
        or argv_value.get("cwd") != str(build_root)
        or argv_value.get("object_targets") != expected_target_rows
        or argv_value.get("verfiles_path") != str(verfiles_path)
        or argv_value.get("dependency_files") != expected_dep_rows
        or argv_value.get("prerequisite_categories") != expected_category_rows
    ):
        raise IdentityError("compiler argv provenance/build-root/category mismatch")
    argv = argv_value.get("argv")
    if (
        not isinstance(argv, list)
        or not argv
        or any(not isinstance(item, str) or not item for item in argv)
    ):
        raise IdentityError("compiler argv token list invalid")
    compiler = _canonical_existing_path(argv[0], cwd=build_root)
    if str(compiler) not in expected["tool"]:
        raise IdentityError("compiler argv producer is not the declared tool owner")
    if not os.access(compiler, os.X_OK):
        raise IdentityError("compiler argv producer is not executable")
    if any(str(target) not in argv for target in targets):
        raise IdentityError("compiler argv does not name every actual object target")
    if any(str(path) not in argv for path in dep_paths):
        raise IdentityError("compiler argv does not name every actual dependency file")

    expected_prerequisites = {str(verfiles_path), *expected_owners.keys()}
    observed_targets: list[str] = []
    observed_prerequisites: list[str] = []
    dependency_identity: list[dict[str, Any]] = []
    for path in dep_paths:
        data = read_bytes_stable(path)
        rules = parse_make_depfile_bytes(data)
        canonical_rules: list[dict[str, list[str]]] = []
        for rule in rules:
            rule_targets = [
                str(_canonical_existing_path(item, cwd=build_root)) for item in rule["targets"]
            ]
            rule_prerequisites = [
                str(_canonical_existing_path(item, cwd=build_root))
                for item in rule["prerequisites"]
            ]
            for item in [*rule_targets, *rule_prerequisites]:
                if not _inside_declared_roots(pathlib.Path(item), roots):
                    raise IdentityError(f"depfile path escapes declared roots: {item}")
            observed_targets.extend(rule_targets)
            observed_prerequisites.extend(rule_prerequisites)
            canonical_rules.append(
                {"targets": rule_targets, "prerequisites": rule_prerequisites}
            )
        dependency_identity.append(
            {
                "path": str(path),
                "sha256": sha256_bytes(data),
                "size_bytes": len(data),
                "rules": canonical_rules,
            }
        )
    if len(observed_targets) != len(set(observed_targets)):
        raise IdentityError("duplicate depfile target across closure rejected")
    if len(observed_prerequisites) != len(set(observed_prerequisites)):
        raise IdentityError("duplicate depfile prerequisite across closure rejected")
    if set(observed_targets) != set(expected_target_rows):
        raise IdentityError(
            f"depfile target closure mismatch: expected={expected_target_rows} actual={observed_targets}"
        )
    if set(observed_prerequisites) != expected_prerequisites:
        missing = sorted(expected_prerequisites - set(observed_prerequisites))
        extra = sorted(set(observed_prerequisites) - expected_prerequisites)
        raise IdentityError(
            f"depfile prerequisite closure mismatch: missing={missing} extra={extra}"
        )
    return {
        "schema": SCHEMA_VERFILES,
        "cmake_identity": cmake_identity,
        "expected_build_root": str(build_root),
        "declared_roots": [str(path) for path in roots],
        "object_targets": expected_target_rows,
        "compiler_argv_identity": {
            "path": str(argv_path),
            "sha256": argv_sha,
            "size_bytes": len(argv_bytes),
            "schema": SCHEMA_COMPILER_ARGV,
            "producer": str(compiler),
        },
        "verfiles_path": str(verfiles_path),
        "verfiles_sha256": sha256_bytes(verfiles_data),
        "raw_s_row_count": len(rows),
        "classes": {name: sorted(values) for name, values in actual.items()},
        "class_counts": {name: len(values) for name, values in actual.items()},
        "mutations_rejected": _verfiles_mutation_self_test(expected),
        "compiler_dependency_files": dependency_identity,
        "depfile_target_count": len(observed_targets),
        "depfile_prerequisite_count": len(observed_prerequisites),
        "depfile_exact_closure": True,
        "depfile_provenance_bound": True,
        "compile_membership_status": "PASS",
        "verfiles_observed": True,
    }


def _paths(values: Iterable[str]) -> list[pathlib.Path]:
    return [pathlib.Path(value) for value in values]


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    cmake = subparsers.add_parser("audit-cmake")
    cmake.add_argument("--repo-root", required=True, type=pathlib.Path)
    cmake.add_argument("--cmake", required=True, type=pathlib.Path)
    cmake.add_argument("--output", required=True, type=pathlib.Path)
    verfiles = subparsers.add_parser("audit-verfiles")
    verfiles.add_argument("--repo-root", required=True, type=pathlib.Path)
    verfiles.add_argument("--cmake", required=True, type=pathlib.Path)
    verfiles.add_argument("--verfiles", required=True, type=pathlib.Path)
    verfiles.add_argument("--transitive-source", action="append", default=[])
    verfiles.add_argument("--control-source", action="append", default=[])
    verfiles.add_argument("--tool-source", action="append", default=[])
    verfiles.add_argument("--depfile", action="append", default=[])
    verfiles.add_argument("--expected-build-root", required=True, type=pathlib.Path)
    verfiles.add_argument("--object-target", action="append", required=True)
    verfiles.add_argument("--compiler-argv", required=True, type=pathlib.Path)
    verfiles.add_argument("--compiler-argv-sha256", required=True)
    verfiles.add_argument("--declared-root", action="append", required=True)
    verfiles.add_argument("--output", required=True, type=pathlib.Path)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    arguments = build_parser().parse_args(argv)
    try:
        if arguments.command == "audit-cmake":
            payload = build_cmake_identity(arguments.repo_root, arguments.cmake)
        else:
            payload = audit_verfiles(
                arguments.repo_root,
                arguments.cmake,
                arguments.verfiles,
                _paths(arguments.transitive_source),
                _paths(arguments.control_source),
                _paths(arguments.tool_source),
                _paths(arguments.depfile),
                expected_build_root=arguments.expected_build_root,
                object_targets=_paths(arguments.object_target),
                compiler_argv_path=arguments.compiler_argv,
                compiler_argv_sha256=arguments.compiler_argv_sha256,
                declared_roots=_paths(arguments.declared_root),
            )
        atomic_write_json(arguments.output, payload)
    except (IdentityError, OSError) as exc:
        print(f"[qwen-f32-alu-build-identity][FAIL] {exc}", file=sys.stderr)
        return 2
    print(
        "[qwen-f32-alu-build-identity][PASS] "
        f"schema={payload['schema']} source_count="
        f"{payload['cmake_identity']['source_count'] if arguments.command == 'audit-verfiles' else payload['source_count']} "
        f"compile_membership={payload['compile_membership_status']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
