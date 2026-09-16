#!/usr/bin/env python3
"""Fast unit tests for the immutable NPU compiler/runtime artifact boundary."""

from __future__ import annotations

import copy
import hashlib
import json
import pathlib
import struct
import subprocess
import sys
import tempfile
import unittest


PROJECT_ROOT = pathlib.Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from compiler import npu_artifact as artifact  # noqa: E402


def resign_metadata(metadata: dict[str, object]) -> bytes:
    core = copy.deepcopy(metadata)
    core.pop("bundle_id")
    metadata = copy.deepcopy(metadata)
    metadata["bundle_id"] = hashlib.sha256(artifact.canonical_json_bytes(core)).hexdigest()
    return artifact.canonical_json_bytes(metadata)


def error_code(context: unittest.TestCase, expected: str):
    caught = context.assertRaises(artifact.ArtifactError)

    class _CodeContext:
        def __enter__(self):
            return caught.__enter__()

        def __exit__(self, exc_type, exc, traceback):
            result = caught.__exit__(exc_type, exc, traceback)
            if caught.exception is not None:
                context.assertEqual(caught.exception.code, expected)
            return result

    return _CodeContext()


def graph_descriptor_hash(graph: dict[str, object], command_index: int) -> str:
    command = graph["commands"][command_index]
    words = list(command["descriptor_words"])
    node_ids = command["node_ids"]
    digest = hashlib.sha256(
        b"".join(struct.pack("<Q", node_id) for node_id in node_ids)
    ).digest()
    words[5] = (words[5] & 0xFFFFFFFF00000000) | len(node_ids)
    words[6] = int.from_bytes(digest[0:8], "little")
    words[7] = int.from_bytes(digest[8:16], "little")
    return hashlib.sha256(artifact.COMMAND_RECORD.pack(*words)).hexdigest()


def refresh_graph_node_descriptor(graph: dict[str, object], command_index: int) -> None:
    node_ids = set(graph["commands"][command_index]["node_ids"])
    descriptor_hash = graph_descriptor_hash(graph, command_index)
    for binding in graph["provenance"]["node_bindings"]:
        if binding["artifact_node_id"] in node_ids:
            binding["command_descriptor_sha256"] = descriptor_hash


def refresh_metadata_node_descriptor(
    metadata: dict[str, object], command_index: int, descriptor_hash: str
) -> None:
    node_ids = set(metadata["commands"][command_index]["node_ids"])
    for binding in metadata["provenance"]["node_bindings"]:
        if binding["artifact_node_id"] in node_ids:
            binding["command_descriptor_sha256"] = descriptor_hash


def clone_buffer_provenance(
    container: dict[str, object], source_id: str, new_id: str, origin_index: int
) -> None:
    bindings = container["provenance"]["buffer_bindings"]
    source = next(row for row in bindings if row["buffer_id"] == source_id)
    binding = copy.deepcopy(source)
    binding["buffer_id"] = new_id
    binding["canonical_id"] = f"synthetic:tiny/tensor/{new_id.replace('_', '-')}"
    binding["storage_canonical_id"] = binding["canonical_id"]
    binding["origin_index"] = origin_index
    binding["storage_origin_index"] = origin_index
    bindings.append(binding)


def rename_buffer_provenance(
    container: dict[str, object], old_id: str, new_id: str, origin_index: int
) -> None:
    binding = next(
        row
        for row in container["provenance"]["buffer_bindings"]
        if row["buffer_id"] == old_id
    )
    binding["buffer_id"] = new_id
    binding["canonical_id"] = f"synthetic:tiny/tensor/{new_id.replace('_', '-')}"
    binding["storage_canonical_id"] = binding["canonical_id"]
    binding["origin_index"] = origin_index
    binding["storage_origin_index"] = origin_index


class CommandFileTest(unittest.TestCase):
    def setUp(self) -> None:
        self.bundle = artifact.compile_graph(artifact.tiny_two_command_graph())

    def test_fixed_header_and_two_30_word_records(self) -> None:
        self.assertEqual(artifact.COMMAND_HEADER.size, 64)
        self.assertEqual(artifact.COMMAND_RECORD.size, 30 * 8)
        self.assertEqual(len(self.bundle.command_bin), 64 + 2 * 30 * 8)
        header = artifact.COMMAND_HEADER.unpack_from(self.bundle.command_bin)
        self.assertEqual(header[0], artifact.COMMAND_MAGIC)
        self.assertEqual(header[1:5], (1, 1, 64, 240))
        self.assertEqual(header[5:8], (2, 0, 480))
        self.assertEqual(
            header[8],
            hashlib.sha256(self.bundle.command_bin[artifact.COMMAND_HEADER_BYTES :]).digest(),
        )
        records = artifact.unpack_command_file(self.bundle.command_bin)
        self.assertEqual(len(records), 2)
        self.assertTrue(all(len(record) == 30 for record in records))
        self.assertEqual([record[0] & 0xFFFFFFFF for record in records], [0x514E0010] * 2)

    def test_bad_magic_is_rejected(self) -> None:
        damaged = bytearray(self.bundle.command_bin)
        damaged[0] ^= 0x80
        with error_code(self, "COMMAND_MAGIC"):
            artifact.unpack_command_file(bytes(damaged))

    def test_bad_version_is_rejected(self) -> None:
        damaged = bytearray(self.bundle.command_bin)
        struct.pack_into("<H", damaged, 8, 2)
        with error_code(self, "COMMAND_VERSION"):
            artifact.unpack_command_file(bytes(damaged))

        legacy = bytearray(self.bundle.command_bin)
        struct.pack_into("<H", legacy, 10, 0)
        with error_code(self, "COMMAND_VERSION"):
            artifact.unpack_command_file(bytes(legacy))

    def test_truncation_and_trailing_data_are_rejected(self) -> None:
        with error_code(self, "COMMAND_TRUNCATED"):
            artifact.unpack_command_file(self.bundle.command_bin[:-1])
        with error_code(self, "COMMAND_TRAILING"):
            artifact.unpack_command_file(self.bundle.command_bin + b"\x00")

    def test_payload_hash_mismatch_is_rejected(self) -> None:
        damaged = bytearray(self.bundle.command_bin)
        damaged[-1] ^= 1
        with error_code(self, "COMMAND_HASH"):
            artifact.unpack_command_file(bytes(damaged))


class BundleTest(unittest.TestCase):
    def setUp(self) -> None:
        self.graph = artifact.tiny_two_command_graph()
        self.bundle = artifact.compile_graph(self.graph)

    def test_canonical_metadata_closes_three_file_bundle(self) -> None:
        loaded = artifact.load_bundle(
            self.bundle.command_bin,
            self.bundle.weights_bin,
            self.bundle.metadata_json,
        )
        metadata = loaded.metadata
        self.assertEqual(metadata["schema"], artifact.METADATA_SCHEMA)
        self.assertEqual(metadata["abi"]["major"], 1)
        self.assertEqual(metadata["abi"]["minor"], 1)
        self.assertEqual(metadata["runtime"], {"service_abi": {"major": 1, "minor": 1}})
        self.assertEqual(metadata["artifacts"]["command.bin"]["bytes"], 544)
        self.assertEqual(
            metadata["artifacts"]["command.bin"]["sha256"],
            hashlib.sha256(self.bundle.command_bin).hexdigest(),
        )
        self.assertEqual(
            metadata["artifacts"]["weights.bin"]["sha256"],
            hashlib.sha256(self.bundle.weights_bin).hexdigest(),
        )
        self.assertEqual(len(metadata["commands"]), 2)
        self.assertEqual(
            metadata["publication"],
            {
                "mode": "bundle_atomic",
                "entries": [
                    {
                        "buffer_id": "output",
                        "bytes": 64,
                        "source_offset": 0,
                        "target_offset": 0,
                    }
                ],
            },
        )
        expected_workload = {
            "schema": "f32-alu-v1",
            "request_groups": 4,
            "response_groups": 4,
            "read_groups": 2,
            "write_groups": 2,
            "input_words": 32,
            "output_words": 16,
            "read_bytes": 128,
            "write_bytes": 64,
            "completion_vector_elements": 16,
            "expected_starts": 1,
        }
        records = artifact.unpack_command_file(self.bundle.command_bin)
        for index, command in enumerate(metadata["commands"]):
            self.assertEqual(command["owner"], "f32_alu")
            self.assertEqual(command["workload"], expected_workload)
            self.assertEqual(command["cycle_upper_bound"], 100000)
            self.assertEqual(set(command["identity"]), set(artifact.IDENTITY_FIELDS))
            record = records[index]
            self.assertEqual(
                command["identity"],
                {
                    "kernel_id": record[0] & 0xFFFFFFFF,
                    "command_flags": record[0] >> 32,
                    "context_id": record[1] & 0xFFFFFFFF,
                    "sequence_id": record[2],
                    "producer_id": record[3],
                    "user_tag": record[4],
                    "covered_node_count": record[5] & 0xFFFFFFFF,
                    "node_hash_lo": record[6],
                    "node_hash_hi": record[7],
                    "local_profile": record[9] & 0xFFFFFFFF,
                },
            )
        self.assertEqual(len(metadata["relocations"]), 12)
        self.assertEqual(
            {row["kind"] for row in metadata["relocations"]},
            {"iova64", "window_base64"},
        )

    def test_compilation_is_deterministic_across_nonsemantic_order(self) -> None:
        reordered = copy.deepcopy(self.graph)
        reordered["buffers"].reverse()
        for command in reordered["commands"]:
            command["relocations"].reverse()
        other = artifact.compile_graph(reordered)
        self.assertEqual(other.command_bin, self.bundle.command_bin)
        self.assertEqual(other.weights_bin, self.bundle.weights_bin)
        self.assertEqual(other.metadata_json, self.bundle.metadata_json)

    def test_noncanonical_metadata_is_rejected(self) -> None:
        with error_code(self, "METADATA_CANONICAL"):
            artifact.load_bundle(
                self.bundle.command_bin,
                self.bundle.weights_bin,
                self.bundle.metadata_json + b"\n",
            )

    def test_metadata_artifact_hash_mismatch_is_rejected(self) -> None:
        metadata = json.loads(self.bundle.metadata_json)
        metadata["artifacts"]["command.bin"]["sha256"] = "0" * 64
        with error_code(self, "ARTIFACT_HASH"):
            artifact.load_bundle(
                self.bundle.command_bin,
                self.bundle.weights_bin,
                resign_metadata(metadata),
            )

    def test_cross_bundle_weight_image_is_rejected(self) -> None:
        changed = copy.deepcopy(self.graph)
        changed["buffers"][3]["data_hex"] = "ff" + changed["buffers"][3]["data_hex"][2:]
        other = artifact.compile_graph(changed)
        with error_code(self, "ARTIFACT_HASH"):
            artifact.load_bundle(
                self.bundle.command_bin,
                other.weights_bin,
                self.bundle.metadata_json,
            )

    def test_unknown_relocation_buffer_is_rejected(self) -> None:
        metadata = json.loads(self.bundle.metadata_json)
        metadata["relocations"][0]["buffer_id"] = "ghost"
        with error_code(self, "UNKNOWN_BUFFER"):
            artifact.load_bundle(
                self.bundle.command_bin,
                self.bundle.weights_bin,
                resign_metadata(metadata),
            )

    def test_duplicate_patch_of_one_word_is_rejected(self) -> None:
        metadata = json.loads(self.bundle.metadata_json)
        metadata["relocations"].insert(1, copy.deepcopy(metadata["relocations"][0]))
        with error_code(self, "RELOCATION_DUPLICATE"):
            artifact.load_bundle(
                self.bundle.command_bin,
                self.bundle.weights_bin,
                resign_metadata(metadata),
            )

    def test_weight_offsets_are_aligned_and_optional_dedup_is_exact(self) -> None:
        graph = artifact.tiny_two_command_graph()
        weight = copy.deepcopy(graph["buffers"][3])
        weight["id"] = "bias_copy"
        graph["buffers"].append(weight)
        clone_buffer_provenance(graph, "bias", "bias_copy", 1)
        deduplicated = artifact.compile_graph(graph, deduplicate_weights=True)
        plain = artifact.compile_graph(graph, deduplicate_weights=False)
        dedup_metadata = artifact.load_bundle(
            deduplicated.command_bin, deduplicated.weights_bin, deduplicated.metadata_json
        ).metadata
        plain_metadata = artifact.load_bundle(
            plain.command_bin, plain.weights_bin, plain.metadata_json
        ).metadata
        dedup_weights = [row for row in dedup_metadata["buffers"] if row["kind"] == "weight"]
        plain_weights = [row for row in plain_metadata["buffers"] if row["kind"] == "weight"]
        self.assertEqual([row["weights_offset"] for row in dedup_weights], [0, 0])
        self.assertEqual([row["weights_offset"] for row in plain_weights], [0, 64])
        self.assertEqual(len(deduplicated.weights_bin), 64)
        self.assertEqual(len(plain.weights_bin), 128)

    def test_partial_weight_overlap_is_rejected(self) -> None:
        graph = artifact.tiny_two_command_graph()
        graph["buffers"][3] = {
            "id": "weight_a",
            "kind": "weight",
            "alignment": 64,
            "permissions": "r",
            "data_hex": (b"\x00" * 64 + b"\x01" * 64).hex(),
        }
        graph["buffers"].append(
            {
                "id": "weight_b",
                "kind": "weight",
                "alignment": 64,
                "permissions": "r",
                "data_hex": (b"\x01" * 64).hex(),
            }
        )
        rename_buffer_provenance(graph, "bias", "weight_a", 0)
        weight_a_provenance = next(
            binding
            for binding in graph["provenance"]["buffer_bindings"]
            if binding["buffer_id"] == "weight_a"
        )
        weight_a_provenance["storage_size"] = 128
        weight_a_provenance["logical_size"] = 128
        clone_buffer_provenance(graph, "weight_a", "weight_b", 1)
        weight_b_provenance = graph["provenance"]["buffer_bindings"][-1]
        weight_b_provenance["storage_size"] = 64
        weight_b_provenance["logical_size"] = 64
        for relocation in graph["commands"][1]["relocations"]:
            if relocation["buffer_id"] == "bias":
                relocation["buffer_id"] = "weight_a"
        bundle = artifact.compile_graph(graph, deduplicate_weights=False)
        metadata = json.loads(bundle.metadata_json)
        weight_b = next(row for row in metadata["buffers"] if row["id"] == "weight_b")
        weight_b["weights_offset"] = 64
        with error_code(self, "WEIGHT_OVERLAP"):
            artifact.load_bundle(bundle.command_bin, bundle.weights_bin, resign_metadata(metadata))


class GraphV3ContractTest(unittest.TestCase):
    @staticmethod
    def add_unwritten_transient(graph: dict[str, object]) -> None:
        graph["buffers"].append(
            {
                "alignment": 64,
                "id": "unwritten",
                "kind": "transient",
                "permissions": "rw",
                "size": 64,
            }
        )
        for relocation in graph["commands"][1]["relocations"]:
            if relocation["word_index"] in {10, 23}:
                relocation["buffer_id"] = "unwritten"

    def test_graph_and_command_exact_keys_are_required(self) -> None:
        graph = artifact.tiny_two_command_graph()
        graph["legacy"] = False
        with error_code(self, "SCHEMA_KEYS"):
            artifact.compile_graph(graph)

        graph = artifact.tiny_two_command_graph()
        del graph["commands"][0]["owner"]
        with error_code(self, "SCHEMA_KEYS"):
            artifact.compile_graph(graph)

        graph = artifact.tiny_two_command_graph()
        graph["commands"][0]["workload"]["guess"] = 1
        with error_code(self, "SCHEMA_KEYS"):
            artifact.compile_graph(graph)

    def test_graph_v1_and_unknown_owner_are_rejected(self) -> None:
        graph = artifact.tiny_two_command_graph()
        graph["schema"] = "npu-compiler-graph-v1"
        with error_code(self, "GRAPH_VERSION"):
            artifact.compile_graph(graph)

    def test_transient_read_requires_strictly_earlier_write(self) -> None:
        graph = artifact.tiny_two_command_graph()
        self.add_unwritten_transient(graph)
        with error_code(self, "TRANSIENT_READ_BEFORE_WRITE"):
            artifact.compile_graph(graph)

        graph = artifact.tiny_two_command_graph()
        graph["commands"][0]["owner"] = "host_fallback"
        with error_code(self, "COMMAND_OWNER"):
            artifact.compile_graph(graph)

    def test_f32_owner_requires_the_exact_kernel(self) -> None:
        graph = artifact.tiny_two_command_graph()
        graph["commands"][0]["descriptor_words"][0] ^= 1
        with error_code(self, "OWNER_KERNEL"):
            artifact.compile_graph(graph)

    def test_descriptor_wire_reserved_and_validity_bits_are_rejected(self) -> None:
        mutations = (
            (18, 1 << 32, "DESCRIPTOR_RESERVED"),
            (25, 1 << 8, "DESCRIPTOR_RESERVED"),
            (25, 1, "DESCRIPTOR_VALIDITY"),
            (25, 2, "DESCRIPTOR_VALIDITY"),
        )
        for word, xor_mask, expected in mutations:
            with self.subTest(word=word, xor_mask=xor_mask):
                graph = artifact.tiny_two_command_graph()
                graph["commands"][0]["descriptor_words"][word] ^= xor_mask
                with error_code(self, expected):
                    artifact.compile_graph(graph)

    def test_descriptor_wire_permissions_are_rejected(self) -> None:
        graph = artifact.tiny_two_command_graph()
        graph["commands"][0]["descriptor_words"][25] = 0x9B
        with error_code(self, "DESCRIPTOR_PERMISSION"):
            artifact.compile_graph(graph)

    def test_hardware_deadline_is_not_host_cycle_bound(self) -> None:
        graph = artifact.tiny_two_command_graph()
        graph["commands"][0]["descriptor_words"][8] = 9072
        with error_code(self, "DESCRIPTOR_CAPABILITY"):
            artifact.compile_graph(graph)

    def test_cycle_upper_bound_is_positive_u64_and_sum_is_checked(self) -> None:
        for value, expected in ((0, "SCHEMA_RANGE"), (True, "SCHEMA_TYPE"), (-1, "SCHEMA_RANGE")):
            with self.subTest(value=value):
                graph = artifact.tiny_two_command_graph()
                graph["commands"][0]["cycle_upper_bound"] = value
                with error_code(self, expected):
                    artifact.compile_graph(graph)

        graph = artifact.tiny_two_command_graph()
        graph["commands"][0]["cycle_upper_bound"] = artifact.UINT64_MAX
        graph["commands"][1]["cycle_upper_bound"] = 1
        with error_code(self, "CYCLE_UPPER_BOUND_OVERFLOW"):
            artifact.compile_graph(graph)

    def test_workload_relations_are_closed(self) -> None:
        mutations = (
            ("request_groups", 5, "WORKLOAD_LEDGER"),
            ("response_groups", 3, "WORKLOAD_LEDGER"),
            ("read_bytes", 124, "WORKLOAD_LEDGER"),
            ("write_bytes", 60, "WORKLOAD_LEDGER"),
            ("expected_starts", 0, "WORKLOAD_ZERO_START"),
            ("expected_starts", 2, "SCHEMA_RANGE"),
            ("input_words", True, "SCHEMA_TYPE"),
        )
        for field, value, expected in mutations:
            with self.subTest(field=field, value=value):
                graph = artifact.tiny_two_command_graph()
                graph["commands"][0]["workload"][field] = value
                with error_code(self, expected):
                    artifact.compile_graph(graph)

    def test_workload_arithmetic_overflow_and_schema_are_rejected(self) -> None:
        graph = artifact.tiny_two_command_graph()
        workload = graph["commands"][0]["workload"]
        workload["read_groups"] = artifact.UINT64_MAX
        workload["write_groups"] = 1
        workload["request_groups"] = artifact.UINT64_MAX
        workload["response_groups"] = artifact.UINT64_MAX
        with error_code(self, "WORKLOAD_OVERFLOW"):
            artifact.compile_graph(graph)

        graph = artifact.tiny_two_command_graph()
        workload = graph["commands"][0]["workload"]
        workload["input_words"] = artifact.UINT64_MAX
        workload["read_bytes"] = artifact.UINT64_MAX
        with error_code(self, "WORKLOAD_OVERFLOW"):
            artifact.compile_graph(graph)

        graph = artifact.tiny_two_command_graph()
        graph["commands"][0]["workload"]["schema"] = "f32-alu-v0"
        with error_code(self, "WORKLOAD_VERSION"):
            artifact.compile_graph(graph)

    def test_zero_start_zero_ledger_is_valid(self) -> None:
        graph = artifact.tiny_two_command_graph()
        graph["commands"][0]["descriptor_words"][15] = 0
        workload = graph["commands"][0]["workload"]
        for field in artifact.WORKLOAD_FIELDS:
            workload[field] = 0
        refresh_graph_node_descriptor(graph, 0)
        bundle = artifact.compile_graph(graph)
        loaded = artifact.load_bundle(
            bundle.command_bin, bundle.weights_bin, bundle.metadata_json
        )
        self.assertEqual(loaded.metadata["commands"][0]["workload"]["expected_starts"], 0)


class PublicationContractTest(unittest.TestCase):
    @staticmethod
    def split_graph() -> dict[str, object]:
        graph = artifact.tiny_two_command_graph()
        graph["publications"] = [
            {"buffer_id": "output", "source_offset": 0, "target_offset": 0, "bytes": 32},
            {"buffer_id": "output", "source_offset": 32, "target_offset": 32, "bytes": 32},
        ]
        return graph

    def test_sorted_split_full_publication_is_valid(self) -> None:
        bundle = artifact.compile_graph(self.split_graph())
        loaded = artifact.load_bundle(
            bundle.command_bin, bundle.weights_bin, bundle.metadata_json
        )
        self.assertEqual(len(loaded.metadata["publication"]["entries"]), 2)

    def test_output_without_destination_producer_is_rejected(self) -> None:
        graph = artifact.tiny_two_command_graph()
        graph["commands"][1]["relocations"] = [
            relocation
            for relocation in graph["commands"][1]["relocations"]
            if relocation["word_index"] not in {13, 28}
        ]
        with error_code(self, "PUBLICATION_NO_PRODUCER"):
            artifact.compile_graph(graph)

    def test_publication_source_must_be_fully_written(self) -> None:
        graph = artifact.tiny_two_command_graph()
        graph["commands"][1]["descriptor_words"][29] = 32
        with error_code(self, "PUBLICATION_UNWRITTEN_SOURCE"):
            artifact.compile_graph(graph)

    def test_publication_order_is_strict(self) -> None:
        graph = self.split_graph()
        graph["publications"].reverse()
        with error_code(self, "PUBLICATION_ORDER"):
            artifact.compile_graph(graph)

    def test_publication_requires_a_write_only_output(self) -> None:
        graph = artifact.tiny_two_command_graph()
        graph["publications"][0]["buffer_id"] = "input0"
        with error_code(self, "PUBLICATION_BUFFER"):
            artifact.compile_graph(graph)

        graph = artifact.tiny_two_command_graph()
        graph["buffers"][-1]["permissions"] = "rw"
        with error_code(self, "BUFFER_PERMISSION"):
            artifact.compile_graph(graph)

    def test_publication_unknown_buffer_and_range_are_rejected(self) -> None:
        graph = artifact.tiny_two_command_graph()
        graph["publications"][0]["buffer_id"] = "ghost"
        with error_code(self, "PUBLICATION_BUFFER"):
            artifact.compile_graph(graph)

        graph = artifact.tiny_two_command_graph()
        graph["publications"][0]["bytes"] = 65
        with error_code(self, "PUBLICATION_RANGE"):
            artifact.compile_graph(graph)

        graph = artifact.tiny_two_command_graph()
        graph["publications"][0]["source_offset"] = True
        with error_code(self, "SCHEMA_TYPE"):
            artifact.compile_graph(graph)

    def test_publication_gap_overlap_and_missing_output_are_rejected(self) -> None:
        graph = artifact.tiny_two_command_graph()
        graph["publications"] = [
            {"buffer_id": "output", "source_offset": 0, "target_offset": 0, "bytes": 32},
            {"buffer_id": "output", "source_offset": 40, "target_offset": 40, "bytes": 24},
        ]
        with error_code(self, "PUBLICATION_GAP"):
            artifact.compile_graph(graph)

        graph = artifact.tiny_two_command_graph()
        graph["publications"] = [
            {"buffer_id": "output", "source_offset": 0, "target_offset": 0, "bytes": 40},
            {"buffer_id": "output", "source_offset": 32, "target_offset": 32, "bytes": 32},
        ]
        with error_code(self, "PUBLICATION_OVERLAP"):
            artifact.compile_graph(graph)

        graph = artifact.tiny_two_command_graph()
        graph["publications"] = []
        with error_code(self, "PUBLICATION_COVERAGE"):
            artifact.compile_graph(graph)

        graph = artifact.tiny_two_command_graph()
        graph["buffers"].append(
            {"id": "zout", "kind": "output", "size": 64, "alignment": 64, "permissions": "w"}
        )
        with error_code(self, "PUBLICATION_COVERAGE"):
            artifact.compile_graph(graph)

    def test_source_and_target_are_independently_exact_cover(self) -> None:
        for second_source, second_target in ((16, 32), (32, 16)):
            with self.subTest(source=second_source, target=second_target):
                graph = artifact.tiny_two_command_graph()
                graph["publications"] = [
                    {
                        "buffer_id": "output",
                        "source_offset": 0,
                        "target_offset": 0,
                        "bytes": 32,
                    },
                    {
                        "buffer_id": "output",
                        "source_offset": second_source,
                        "target_offset": second_target,
                        "bytes": 32,
                    },
                ]
                with error_code(self, "PUBLICATION_OVERLAP"):
                    artifact.compile_graph(graph)


class MetadataV3ContractTest(unittest.TestCase):
    def setUp(self) -> None:
        self.bundle = artifact.compile_graph(artifact.tiny_two_command_graph())

    def test_load_rejects_descriptor_wire_reserved_bits(self) -> None:
        records = [list(record) for record in artifact.unpack_command_file(self.bundle.command_bin)]
        records[0][18] |= 1 << 32
        command_bin = artifact.pack_command_file(records)
        metadata = json.loads(self.bundle.metadata_json)
        metadata["commands"][0]["descriptor_sha256"] = hashlib.sha256(
            artifact.COMMAND_RECORD.pack(*records[0])
        ).hexdigest()
        refresh_metadata_node_descriptor(
            metadata, 0, metadata["commands"][0]["descriptor_sha256"]
        )
        metadata["artifacts"]["command.bin"] = {
            "bytes": len(command_bin),
            "sha256": hashlib.sha256(command_bin).hexdigest(),
        }
        with error_code(self, "DESCRIPTOR_RESERVED"):
            artifact.load_bundle(command_bin, self.bundle.weights_bin, resign_metadata(metadata))

    def test_load_rejects_output_without_destination_producer(self) -> None:
        metadata = json.loads(self.bundle.metadata_json)
        metadata["relocations"] = [
            relocation
            for relocation in metadata["relocations"]
            if relocation["word_index"] not in {13, 28}
        ]
        with error_code(self, "PUBLICATION_NO_PRODUCER"):
            artifact.load_bundle(
                self.bundle.command_bin, self.bundle.weights_bin, resign_metadata(metadata)
            )

    def test_load_rejects_publication_beyond_destination_windows(self) -> None:
        records = [list(record) for record in artifact.unpack_command_file(self.bundle.command_bin)]
        records[1][29] = 32
        command_bin = artifact.pack_command_file(records)
        metadata = json.loads(self.bundle.metadata_json)
        for index, record in enumerate(records):
            metadata["commands"][index]["descriptor_sha256"] = hashlib.sha256(
                artifact.COMMAND_RECORD.pack(*record)
            ).hexdigest()
            refresh_metadata_node_descriptor(
                metadata, index, metadata["commands"][index]["descriptor_sha256"]
            )
        metadata["artifacts"]["command.bin"] = {
            "bytes": len(command_bin),
            "sha256": hashlib.sha256(command_bin).hexdigest(),
        }
        with error_code(self, "PUBLICATION_UNWRITTEN_SOURCE"):
            artifact.load_bundle(command_bin, self.bundle.weights_bin, resign_metadata(metadata))

    def test_load_rejects_resigned_unwritten_transient_read(self) -> None:
        metadata = json.loads(self.bundle.metadata_json)
        metadata["buffers"].append(
            {
                "alignment": 64,
                "id": "unwritten",
                "kind": "transient",
                "permissions": "rw",
                "size": 64,
            }
        )
        metadata["buffers"].sort(key=lambda buffer: buffer["id"])
        clone_buffer_provenance(metadata, "intermediate", "unwritten", 2)
        metadata["provenance"]["buffer_bindings"].sort(
            key=lambda binding: binding["buffer_id"]
        )
        for relocation in metadata["relocations"]:
            if relocation["command_index"] == 1 and relocation["word_index"] in {10, 23}:
                relocation["buffer_id"] = "unwritten"
        with error_code(self, "TRANSIENT_READ_BEFORE_WRITE"):
            artifact.load_bundle(
                self.bundle.command_bin, self.bundle.weights_bin, resign_metadata(metadata)
            )

    def load_mutation(self, metadata: dict[str, object]) -> None:
        artifact.load_bundle(
            self.bundle.command_bin,
            self.bundle.weights_bin,
            resign_metadata(metadata),
        )

    def test_metadata_v1_and_abi_1_0_are_rejected(self) -> None:
        metadata = json.loads(self.bundle.metadata_json)
        metadata["schema"] = "npu-artifact-bundle-v1"
        with error_code(self, "METADATA_VERSION"):
            self.load_mutation(metadata)

        metadata = json.loads(self.bundle.metadata_json)
        metadata["abi"]["minor"] = 0
        with error_code(self, "METADATA_ABI"):
            self.load_mutation(metadata)

    def test_service_abi_and_publication_mode_are_exact(self) -> None:
        metadata = json.loads(self.bundle.metadata_json)
        metadata["runtime"]["service_abi"]["minor"] = 0
        with error_code(self, "SERVICE_ABI"):
            self.load_mutation(metadata)

        metadata = json.loads(self.bundle.metadata_json)
        metadata["publication"]["mode"] = "per_command"
        with error_code(self, "PUBLICATION_MODE"):
            self.load_mutation(metadata)

    def test_metadata_identity_must_be_derived_from_descriptor(self) -> None:
        for field in artifact.IDENTITY_FIELDS:
            with self.subTest(field=field):
                metadata = json.loads(self.bundle.metadata_json)
                metadata["commands"][0]["identity"][field] ^= 1
                expected = "OWNER_KERNEL" if field == "kernel_id" else "COMMAND_IDENTITY"
                with error_code(self, expected):
                    self.load_mutation(metadata)

    def test_metadata_identity_workload_and_publication_have_exact_keys(self) -> None:
        mutations = (
            (lambda value: value["commands"][0]["identity"].update({"vector_flags": 0})),
            (lambda value: value["commands"][0]["workload"].update({"estimated": 1})),
            (lambda value: value["publication"]["entries"][0].update({"destination": "host"})),
            (lambda value: value["runtime"]["service_abi"].update({"patch": 0})),
        )
        for mutate in mutations:
            with self.subTest(mutate=mutate):
                metadata = json.loads(self.bundle.metadata_json)
                mutate(metadata)
                with error_code(self, "SCHEMA_KEYS"):
                    self.load_mutation(metadata)

    def test_metadata_uints_are_not_booleans(self) -> None:
        mutations = (
            (lambda value: value["commands"][0]["identity"].update({"producer_id": True})),
            (lambda value: value["commands"][0]["workload"].update({"input_words": True})),
            (lambda value: value["commands"][0].update({"cycle_upper_bound": True})),
            (lambda value: value["publication"]["entries"][0].update({"bytes": True})),
            (lambda value: value["runtime"]["service_abi"].update({"minor": True})),
        )
        for mutate in mutations:
            with self.subTest(mutate=mutate):
                metadata = json.loads(self.bundle.metadata_json)
                mutate(metadata)
                with error_code(self, "SCHEMA_TYPE"):
                    self.load_mutation(metadata)

    def test_metadata_workload_and_cycle_invariants_are_rechecked(self) -> None:
        metadata = json.loads(self.bundle.metadata_json)
        metadata["commands"][0]["workload"]["response_groups"] = 3
        with error_code(self, "WORKLOAD_LEDGER"):
            self.load_mutation(metadata)

        metadata = json.loads(self.bundle.metadata_json)
        metadata["commands"][0]["cycle_upper_bound"] = artifact.UINT64_MAX
        metadata["commands"][1]["cycle_upper_bound"] = 1
        with error_code(self, "CYCLE_UPPER_BOUND_OVERFLOW"):
            self.load_mutation(metadata)

    def test_metadata_publication_coverage_is_rechecked(self) -> None:
        metadata = json.loads(self.bundle.metadata_json)
        metadata["publication"]["entries"][0]["bytes"] = 63
        with error_code(self, "PUBLICATION_COVERAGE"):
            self.load_mutation(metadata)


class ProvenanceV3ContractTest(unittest.TestCase):
    def setUp(self) -> None:
        self.graph = artifact.tiny_two_command_graph()
        self.bundle = artifact.compile_graph(self.graph)

    def load_mutation(self, metadata: dict[str, object]) -> None:
        artifact.load_bundle(
            self.bundle.command_bin,
            self.bundle.weights_bin,
            resign_metadata(metadata),
        )

    def test_synthetic_fixture_has_canonical_exact_cover(self) -> None:
        loaded = artifact.load_bundle(
            self.bundle.command_bin,
            self.bundle.weights_bin,
            self.bundle.metadata_json,
        )
        provenance = loaded.metadata["provenance"]
        self.assertEqual(provenance["source"]["schema"], "synthetic-graph-manifest-v1")
        self.assertEqual(provenance["source"]["profile"], "synthetic:p00-dense-add")
        self.assertIsNone(provenance["source"]["source_commit"])
        self.assertEqual(
            [binding["artifact_node_id"] for binding in provenance["node_bindings"]],
            [node_id for command in loaded.metadata["commands"] for node_id in command["node_ids"]],
        )
        self.assertEqual(
            [binding["buffer_id"] for binding in provenance["buffer_bindings"]],
            [buffer["id"] for buffer in loaded.metadata["buffers"]],
        )
        self.assertTrue(
            all(
                binding["alias_offset"] == 0
                and binding["logical_size"] == binding["storage_size"]
                for binding in provenance["buffer_bindings"]
            )
        )

    def test_normalized_storage_root_view_is_one_artifact_buffer(self) -> None:
        graph = copy.deepcopy(self.graph)
        input0 = next(buffer for buffer in graph["buffers"] if buffer["id"] == "input0")
        input0["size"] = 128
        binding = next(
            row
            for row in graph["provenance"]["buffer_bindings"]
            if row["buffer_id"] == "input0"
        )
        binding["canonical_id"] = "synthetic:tiny/tensor/input0-view"
        binding["tensor_descriptor_sha256"] = hashlib.sha256(b"logical input0 view").hexdigest()
        binding["storage_tensor_descriptor_sha256"] = hashlib.sha256(
            b"input0 storage root"
        ).hexdigest()
        binding["alias_offset"] = 64
        binding["logical_size"] = 64
        binding["storage_size"] = 128
        for relocation in graph["commands"][0]["relocations"]:
            if relocation["word_index"] in {10, 23}:
                relocation["addend"] = 64
        graph["commands"][0]["descriptor_words"][10] = 64
        graph["commands"][0]["descriptor_words"][23] = 64
        refresh_graph_node_descriptor(graph, 0)
        bundle = artifact.compile_graph(graph)
        loaded = artifact.load_bundle(
            bundle.command_bin, bundle.weights_bin, bundle.metadata_json
        )
        bindings = [
            row
            for row in loaded.metadata["provenance"]["buffer_bindings"]
            if row["buffer_id"] == "input0"
        ]
        self.assertEqual(len(bindings), 1)
        self.assertEqual(
            (bindings[0]["alias_offset"], bindings[0]["logical_size"], bindings[0]["storage_size"]),
            (64, 64, 128),
        )

    def test_real_style_hash_id_and_source_schedule_are_preserved(self) -> None:
        graph = copy.deepcopy(self.graph)
        first = graph["provenance"]["node_bindings"][0]
        second = graph["provenance"]["node_bindings"][1]
        first["canonical_id"] = "1e3d" + "a" * 60
        first["source_schedule_position"] = 15
        second["source_schedule_position"] = 16
        first["source_descriptor_sha256"] = "b044" + "c" * 60
        bundle = artifact.compile_graph(graph)
        loaded = artifact.load_bundle(
            bundle.command_bin, bundle.weights_bin, bundle.metadata_json
        )
        loaded_first = loaded.metadata["provenance"]["node_bindings"][0]
        self.assertEqual(loaded_first["canonical_id"], "1e3d" + "a" * 60)
        self.assertEqual(loaded_first["artifact_schedule_position"], 0)
        self.assertEqual(loaded_first["source_schedule_position"], 15)
        self.assertEqual(loaded_first["source_descriptor_sha256"], "b044" + "c" * 60)
        self.assertNotEqual(
            loaded_first["source_descriptor_sha256"],
            loaded_first["command_descriptor_sha256"],
        )

    def test_compile_rejects_node_coverage_uniqueness_and_descriptor_lies(self) -> None:
        mutations = (
            (lambda value: value["provenance"]["node_bindings"].pop(), "PROVENANCE_NODE_COVERAGE"),
            (
                lambda value: value["provenance"]["node_bindings"][1].update(
                    {"canonical_id": value["provenance"]["node_bindings"][0]["canonical_id"]}
                ),
                "PROVENANCE_NODE_DUPLICATE",
            ),
            (
                lambda value: value["provenance"]["node_bindings"][0].update(
                    {"command_descriptor_sha256": "0" * 64}
                ),
                "PROVENANCE_NODE_DESCRIPTOR",
            ),
            (
                lambda value: value["provenance"]["node_bindings"][0].update(
                    {"artifact_schedule_position": 1}
                ),
                "PROVENANCE_NODE_DUPLICATE",
            ),
        )
        for mutate, expected in mutations:
            with self.subTest(expected=expected):
                graph = copy.deepcopy(self.graph)
                mutate(graph)
                with error_code(self, expected):
                    artifact.compile_graph(graph)

    def test_compile_rejects_buffer_coverage_identity_and_checked_range(self) -> None:
        mutations = (
            (lambda value: value["provenance"]["buffer_bindings"].pop(), "PROVENANCE_BUFFER_COVERAGE"),
            (
                lambda value: value["provenance"]["buffer_bindings"][1].update(
                    {"canonical_id": value["provenance"]["buffer_bindings"][0]["canonical_id"]}
                ),
                "PROVENANCE_BUFFER_DUPLICATE",
            ),
            (
                lambda value: value["provenance"]["buffer_bindings"][0].update(
                    {"alias_offset": artifact.UINT64_MAX}
                ),
                "PROVENANCE_BUFFER_RANGE",
            ),
            (
                lambda value: value["provenance"]["buffer_bindings"][0].update(
                    {"storage_size": 65}
                ),
                "PROVENANCE_BUFFER_RANGE",
            ),
        )
        for mutate, expected in mutations:
            with self.subTest(expected=expected):
                graph = copy.deepcopy(self.graph)
                mutate(graph)
                with error_code(self, expected):
                    artifact.compile_graph(graph)

    def test_source_and_identifier_formats_are_strict(self) -> None:
        mutations = (
            (
                lambda value: value["provenance"]["source"].update(
                    {"schema": "QwenManifestV1"}
                ),
                "PROVENANCE_FORMAT",
            ),
            (
                lambda value: value["provenance"]["source"].update(
                    {"source_commit": "A" * 40}
                ),
                "PROVENANCE_FORMAT",
            ),
            (
                lambda value: value["provenance"]["node_bindings"][0].update(
                    {"canonical_id": "Qwen Node 0"}
                ),
                "PROVENANCE_FORMAT",
            ),
            (
                lambda value: value["provenance"]["source"].update(
                    {"raw_sha256": "A" * 64}
                ),
                "SCHEMA_HASH",
            ),
        )
        for mutate, expected in mutations:
            with self.subTest(expected=expected):
                graph = copy.deepcopy(self.graph)
                mutate(graph)
                with error_code(self, expected):
                    artifact.compile_graph(graph)

    def test_resigned_metadata_still_rechecks_provenance_semantics(self) -> None:
        mutations = (
            (
                lambda value: value["provenance"]["node_bindings"].pop(),
                "PROVENANCE_NODE_COVERAGE",
            ),
            (
                lambda value: value["provenance"]["node_bindings"][0].update(
                    {"command_descriptor_sha256": "0" * 64}
                ),
                "PROVENANCE_NODE_DESCRIPTOR",
            ),
            (
                lambda value: value["provenance"]["buffer_bindings"][0].update(
                    {"logical_size": 65}
                ),
                "PROVENANCE_BUFFER_RANGE",
            ),
            (
                lambda value: value["provenance"]["buffer_bindings"].reverse(),
                "PROVENANCE_BUFFER_ORDER",
            ),
            (
                lambda value: value["provenance"]["source"].update(
                    {"graph_scope": "Synthetic Scope"}
                ),
                "PROVENANCE_FORMAT",
            ),
        )
        for mutate, expected in mutations:
            with self.subTest(expected=expected):
                metadata = json.loads(self.bundle.metadata_json)
                mutate(metadata)
                with error_code(self, expected):
                    self.load_mutation(metadata)

    def test_v2_graph_and_metadata_are_rejected(self) -> None:
        graph = copy.deepcopy(self.graph)
        graph["schema"] = "npu-compiler-graph-v2"
        with error_code(self, "GRAPH_VERSION"):
            artifact.compile_graph(graph)

        metadata = json.loads(self.bundle.metadata_json)
        metadata["schema"] = "npu-artifact-bundle-v2"
        with error_code(self, "METADATA_VERSION"):
            self.load_mutation(metadata)


class RelocationTest(unittest.TestCase):
    def setUp(self) -> None:
        bundle = artifact.compile_graph(artifact.tiny_two_command_graph())
        self.loaded = artifact.load_bundle(bundle.command_bin, bundle.weights_bin, bundle.metadata_json)
        self.bases = {
            "input0": 0x1000,
            "input1": 0x2000,
            "intermediate": 0x3000,
            "output": 0x4000,
        }

    def test_iova_and_window_base_relocations_are_applied(self) -> None:
        runtime_image = self.loaded.relocate(self.bases, weights_base=0x5000)
        records = artifact.unpack_command_file(runtime_image)
        self.assertEqual(
            [records[0][word] for word in (10, 11, 13, 23, 26, 28)],
            [0x1000, 0x2000, 0x3000, 0x1000, 0x2000, 0x3000],
        )
        self.assertEqual(
            [records[1][word] for word in (10, 11, 13, 23, 26, 28)],
            [0x3000, 0x5000, 0x4000, 0x3000, 0x5000, 0x4000],
        )
        self.assertNotEqual(runtime_image, self.loaded.command_bin)

    def test_relocation_u64_overflow_is_rejected(self) -> None:
        bases = dict(self.bases)
        bases["input0"] = artifact.UINT64_MAX - 63
        with error_code(self, "RELOC_OVERFLOW"):
            self.loaded.relocate(bases, weights_base=0x5000)

    def test_unknown_runtime_buffer_is_rejected(self) -> None:
        bases = dict(self.bases)
        bases["ghost"] = 0x6000
        with error_code(self, "UNKNOWN_BUFFER"):
            self.loaded.relocate(bases, weights_base=0x5000)

    def test_missing_runtime_buffer_is_rejected(self) -> None:
        bases = dict(self.bases)
        del bases["input1"]
        with error_code(self, "MISSING_BUFFER_BASE"):
            self.loaded.relocate(bases, weights_base=0x5000)

    def test_runtime_buffer_overlap_is_rejected(self) -> None:
        bases = dict(self.bases)
        bases["input1"] = bases["input0"]
        with error_code(self, "BUFFER_OVERLAP"):
            self.loaded.relocate(bases, weights_base=0x5000)

    def test_compile_rejects_addend_outside_buffer(self) -> None:
        graph = artifact.tiny_two_command_graph()
        graph["commands"][0]["relocations"][0]["addend"] = 64
        with error_code(self, "RELOCATION_RANGE"):
            artifact.compile_graph(graph)

    def test_compile_rejects_unpaired_window_and_scratch_iova(self) -> None:
        graph = artifact.tiny_two_command_graph()
        graph["commands"][0]["relocations"] = [
            row for row in graph["commands"][0]["relocations"] if row["word_index"] != 23
        ]
        with error_code(self, "RELOCATION_PAIR_MISSING"):
            artifact.compile_graph(graph)

        graph = artifact.tiny_two_command_graph()
        graph["commands"][0]["descriptor_words"][14] = 64
        with error_code(self, "SCRATCH_UNSUPPORTED"):
            artifact.compile_graph(graph)

    def test_src2_must_alias_a_declared_window(self) -> None:
        graph = artifact.tiny_two_command_graph()
        graph["commands"][0]["relocations"].append(
            {"word_index": 12, "kind": "iova64", "buffer_id": "bias", "addend": 0}
        )
        with error_code(self, "SRC2_NOT_WINDOW_ALIAS"):
            artifact.compile_graph(graph)

        graph = artifact.tiny_two_command_graph()
        graph["buffers"][0]["size"] = 128
        graph["commands"][0]["relocations"].append(
            {"word_index": 12, "kind": "iova64", "buffer_id": "input0", "addend": 64}
        )
        with error_code(self, "SRC2_NOT_WINDOW_ALIAS"):
            artifact.compile_graph(graph)


class CliFixtureTest(unittest.TestCase):
    def test_checked_in_fixture_matches_generator_and_cli_compiles_it(self) -> None:
        fixture_path = PROJECT_ROOT / "compiler" / "fixtures" / "tiny_two_command_graph.json"
        self.assertEqual(json.loads(fixture_path.read_bytes()), artifact.tiny_two_command_graph())
        with tempfile.TemporaryDirectory() as temporary:
            temporary_path = pathlib.Path(temporary)
            emitted = temporary_path / "emitted.json"
            emit = subprocess.run(
                [
                    sys.executable,
                    "-m",
                    "compiler.npu_compile",
                    "--emit-tiny-graph",
                    str(emitted),
                ],
                cwd=PROJECT_ROOT,
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(emit.returncode, 0, emit.stderr)
            self.assertEqual(json.loads(emitted.read_bytes()), artifact.tiny_two_command_graph())
            output = temporary_path / "bundle"
            compile_result = subprocess.run(
                [
                    sys.executable,
                    "-m",
                    "compiler.npu_compile",
                    str(fixture_path),
                    "-o",
                    str(output),
                ],
                cwd=PROJECT_ROOT,
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(compile_result.returncode, 0, compile_result.stderr)
            loaded = artifact.load_bundle(
                (output / "command.bin").read_bytes(),
                (output / "weights.bin").read_bytes(),
                (output / "metadata.json").read_bytes(),
            )
            self.assertEqual(len(loaded.records), 2)


if __name__ == "__main__":
    unittest.main()
