#!/usr/bin/env python3
"""Extract immutable tensor bytes from a GGUF file without tensor arithmetic.

The NPU compiler treats GGUF as a byte authority.  This module deliberately
does not dequantize, cast, reshape, or otherwise recreate tensor values.  It
uses llama.cpp's bundled GGUF reader only to validate the tensor directory,
then reads the declared byte interval directly from the model file.
"""

from __future__ import annotations

import hashlib
import os
import pathlib
import sys
from dataclasses import dataclass
from typing import Any, Callable, Sequence


PROJECT_ROOT = pathlib.Path(__file__).resolve().parents[1]
GGUF_PY_ROOT = PROJECT_ROOT / "third_party" / "llama.cpp" / "gguf-py"


class WeightSourceError(ValueError):
    """Fail-closed GGUF source diagnostic with a stable code and path."""

    def __init__(self, code: str, path: str, detail: str):
        super().__init__(f"{code} at {path}: {detail}")
        self.code = code
        self.path = path
        self.detail = detail


def _fail(code: str, path: str, detail: str) -> None:
    raise WeightSourceError(code, path, detail)


@dataclass(frozen=True)
class RawWeight:
    name: str
    ggml_type: str
    shape: tuple[int, ...]
    file_offset: int
    data: bytes
    sha256: str


def _default_reader_factory(path: pathlib.Path) -> Any:
    if str(GGUF_PY_ROOT) not in sys.path:
        sys.path.insert(0, str(GGUF_PY_ROOT))
    try:
        from gguf import GGUFReader  # type: ignore[import-not-found]
    except (ImportError, OSError) as error:
        _fail("GGUF_READER_UNAVAILABLE", "$model", str(error))
    try:
        return GGUFReader(path, "r")
    except (KeyError, OSError, RuntimeError, ValueError) as error:
        _fail("GGUF_INVALID", "$model", str(error))


def _normalized_shape(values: Sequence[Any], path: str) -> tuple[int, ...]:
    result: list[int] = []
    for index, value in enumerate(values):
        try:
            integer = int(value)
        except (TypeError, ValueError, OverflowError):
            _fail("GGUF_SHAPE", f"{path}[{index}]", "dimension is not an integer")
        if integer <= 0 or integer > (1 << 63) - 1:
            _fail("GGUF_SHAPE", f"{path}[{index}]", "dimension is outside signed u63")
        result.append(integer)
    while len(result) > 1 and result[-1] == 1:
        result.pop()
    return tuple(result)


def extract_gguf_tensor_bytes(
    model_path: str | os.PathLike[str],
    tensor_name: str,
    *,
    expected_type: str,
    expected_shape: Sequence[int],
    expected_nbytes: int,
    reader_factory: Callable[[pathlib.Path], Any] | None = None,
) -> RawWeight:
    """Return the exact on-disk bytes for one identity-checked GGUF tensor.

    ``expected_shape`` uses GGML dimension order and may include trailing unit
    dimensions (for example ``[16, 1, 1, 1]``).  The GGUF directory commonly
    omits those unit dimensions, so both sides are normalized only by removing
    trailing ones.  No data transformation is performed.
    """

    path = pathlib.Path(model_path)
    if type(tensor_name) is not str or not tensor_name or "\x00" in tensor_name:
        _fail("GGUF_TENSOR_NAME", "$tensor_name", "expected a non-empty NUL-free string")
    if type(expected_type) is not str or not expected_type:
        _fail("GGUF_TENSOR_TYPE", "$expected_type", "expected a non-empty string")
    if type(expected_nbytes) is not int or expected_nbytes <= 0:
        _fail("GGUF_TENSOR_SIZE", "$expected_nbytes", "expected a positive integer")
    wanted_shape = _normalized_shape(expected_shape, "$expected_shape")
    try:
        file_size = path.stat().st_size
    except OSError as error:
        _fail("GGUF_OPEN", str(path), str(error))
    if not path.is_file():
        _fail("GGUF_OPEN", str(path), "model path is not a regular file")

    factory = _default_reader_factory if reader_factory is None else reader_factory
    try:
        reader = factory(path)
        tensors = list(reader.tensors)
    except WeightSourceError:
        raise
    except (AttributeError, KeyError, OSError, RuntimeError, TypeError, ValueError) as error:
        _fail("GGUF_INVALID", str(path), str(error))

    matches = [tensor for tensor in tensors if getattr(tensor, "name", None) == tensor_name]
    if len(matches) != 1:
        _fail(
            "GGUF_TENSOR_LOOKUP",
            "$model.tensors",
            f"expected exactly one {tensor_name!r}, found {len(matches)}",
        )
    tensor = matches[0]
    raw_type = getattr(tensor, "tensor_type", None)
    actual_type = getattr(raw_type, "name", str(raw_type)).lower()
    if actual_type != expected_type.lower():
        _fail(
            "GGUF_TENSOR_TYPE",
            f"$model.tensors[{tensor_name!r}].type",
            f"expected {expected_type.lower()}, got {actual_type}",
        )
    raw_shape = getattr(tensor, "shape", None)
    try:
        shape_values = raw_shape.tolist() if hasattr(raw_shape, "tolist") else list(raw_shape)
    except (TypeError, ValueError) as error:
        _fail("GGUF_SHAPE", f"$model.tensors[{tensor_name!r}].shape", str(error))
    actual_shape = _normalized_shape(
        shape_values, f"$model.tensors[{tensor_name!r}].shape"
    )
    if actual_shape != wanted_shape:
        _fail(
            "GGUF_SHAPE",
            f"$model.tensors[{tensor_name!r}].shape",
            f"expected {wanted_shape}, got {actual_shape}",
        )
    try:
        declared_size = int(tensor.n_bytes)
        offset = int(tensor.data_offset)
    except (AttributeError, TypeError, ValueError, OverflowError) as error:
        _fail("GGUF_TENSOR_RANGE", f"$model.tensors[{tensor_name!r}]", str(error))
    if declared_size != expected_nbytes:
        _fail(
            "GGUF_TENSOR_SIZE",
            f"$model.tensors[{tensor_name!r}].n_bytes",
            f"expected {expected_nbytes}, got {declared_size}",
        )
    if offset < 0 or declared_size > file_size or offset > file_size - declared_size:
        _fail(
            "GGUF_TENSOR_RANGE",
            f"$model.tensors[{tensor_name!r}]",
            f"range [{offset}, {offset + declared_size}) is outside {file_size} bytes",
        )
    try:
        with path.open("rb") as handle:
            handle.seek(offset)
            data = handle.read(declared_size)
    except OSError as error:
        _fail("GGUF_READ", str(path), str(error))
    if len(data) != declared_size:
        _fail(
            "GGUF_READ",
            str(path),
            f"short read: expected {declared_size}, got {len(data)}",
        )
    return RawWeight(
        name=tensor_name,
        ggml_type=actual_type,
        shape=actual_shape,
        file_offset=offset,
        data=data,
        sha256=hashlib.sha256(data).hexdigest(),
    )

