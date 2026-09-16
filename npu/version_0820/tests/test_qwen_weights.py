#!/usr/bin/env python3

from __future__ import annotations

import os
import pathlib
import tempfile
import unittest
from types import SimpleNamespace

from compiler.qwen_weights import WeightSourceError, extract_gguf_tensor_bytes


class _Shape:
    def __init__(self, values: list[int]):
        self._values = values

    def tolist(self) -> list[int]:
        return list(self._values)


class _Type:
    def __init__(self, name: str):
        self.name = name


def _factory(*tensors: object):
    return lambda _path: SimpleNamespace(tensors=list(tensors))


class QwenWeightTests(unittest.TestCase):
    def _tensor(
        self,
        *,
        name: str = "blk.0.ssm_dt.bias",
        tensor_type: str = "F32",
        shape: list[int] | None = None,
        n_bytes: int = 64,
        data_offset: int = 32,
    ) -> object:
        return SimpleNamespace(
            name=name,
            tensor_type=_Type(tensor_type),
            shape=_Shape([16] if shape is None else shape),
            n_bytes=n_bytes,
            data_offset=data_offset,
        )

    def test_reads_exact_file_interval_without_transform(self) -> None:
        prefix = bytes(range(32))
        payload = bytes((index * 37 + 11) & 0xFF for index in range(64))
        suffix = bytes(range(17))
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "model.gguf"
            path.write_bytes(prefix + payload + suffix)
            result = extract_gguf_tensor_bytes(
                path,
                "blk.0.ssm_dt.bias",
                expected_type="f32",
                expected_shape=[16, 1, 1, 1],
                expected_nbytes=64,
                reader_factory=_factory(self._tensor()),
            )
        self.assertEqual(result.data, payload)
        self.assertEqual(result.file_offset, 32)
        self.assertEqual(result.shape, (16,))
        self.assertEqual(result.ggml_type, "f32")
        self.assertEqual(
            result.sha256,
            "94eb5de4943613fd048dc93393ab06877405faa39c11f53e9386083339833e7e",
        )

    def test_fail_closed_identity_and_range_checks(self) -> None:
        payload = bytes(96)
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "model.gguf"
            path.write_bytes(payload)
            cases = (
                (
                    "GGUF_TENSOR_LOOKUP",
                    _factory(),
                    {},
                ),
                (
                    "GGUF_TENSOR_LOOKUP",
                    _factory(self._tensor(), self._tensor()),
                    {},
                ),
                (
                    "GGUF_TENSOR_TYPE",
                    _factory(self._tensor(tensor_type="F16")),
                    {},
                ),
                (
                    "GGUF_SHAPE",
                    _factory(self._tensor(shape=[8, 2])),
                    {},
                ),
                (
                    "GGUF_TENSOR_SIZE",
                    _factory(self._tensor(n_bytes=60)),
                    {},
                ),
                (
                    "GGUF_TENSOR_RANGE",
                    _factory(self._tensor(data_offset=64)),
                    {},
                ),
            )
            for code, factory, overrides in cases:
                with self.subTest(code=code), self.assertRaises(WeightSourceError) as caught:
                    extract_gguf_tensor_bytes(
                        path,
                        "blk.0.ssm_dt.bias",
                        expected_type="f32",
                        expected_shape=[16, 1, 1, 1],
                        expected_nbytes=64,
                        reader_factory=factory,
                        **overrides,
                    )
                self.assertEqual(caught.exception.code, code)

    @unittest.skipUnless(
        os.environ.get("NPU_QWEN_GGUF"),
        "set NPU_QWEN_GGUF for the real-model raw-byte extraction check",
    )
    def test_real_qwen_bias_bytes(self) -> None:
        result = extract_gguf_tensor_bytes(
            os.environ["NPU_QWEN_GGUF"],
            "blk.0.ssm_dt.bias",
            expected_type="f32",
            expected_shape=[16, 1, 1, 1],
            expected_nbytes=64,
        )
        self.assertEqual(result.name, "blk.0.ssm_dt.bias")
        self.assertEqual(len(result.data), 64)
        self.assertEqual(
            result.data.hex(),
            "000023400000b3c0000094c000000641000069400000a1c00000a2c000008abf"
            "000051c10000aec000009ac00000ce4000009ec00000f3400000c2c000004fc0",
        )


if __name__ == "__main__":
    unittest.main()
