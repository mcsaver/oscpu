#!/usr/bin/env python3
"""Directed build-free tests for Qwen F32 ALU source/evidence identity."""

from __future__ import annotations

import hashlib
import json
import os
import pathlib
import tempfile
import unittest
from collections.abc import Sequence
from typing import Any


DEFAULT_REPO_ROOT = pathlib.Path(__file__).resolve().parents[3]
REPO_ROOT = pathlib.Path(os.environ.get("QWEN_F32_ALU_REPO_ROOT", DEFAULT_REPO_ROOT))
NPU_ROOT = REPO_ROOT / "npu/version_0820"
SCRIPTS_ROOT = NPU_ROOT / "scripts"
if str(SCRIPTS_ROOT) not in os.sys.path:
    os.sys.path.insert(0, str(SCRIPTS_ROOT))

import qwen_f32_alu_build_identity as identity  # noqa: E402


class CppLexicalStructureTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.cpp = NPU_ROOT / "runtime/llama-npu-backend/npu-verilator-runner.cpp"
        cls.source_bytes = identity.read_bytes_stable(cls.cpp)

    def test_production_definition_and_exact_constructor(self) -> None:
        observed = identity.audit_f32_constructor_bytes(self.source_bytes)
        self.assertEqual(
            observed["cpp_sha256"],
            "b5581ad476afa265d351906c95e072fc6c9d0957114b29b170e03687473a348e",
        )
        self.assertEqual(observed["definition_count"], 1)
        self.assertTrue(observed["definition_body_balanced"])
        self.assertEqual(
            observed["definition_extractor"],
            "cpp-phase2-phase3-full-function-template-v2",
        )
        self.assertEqual(observed["call_count"], 1)
        self.assertEqual(tuple(observed["arguments"]), identity.EXPECTED_F32_CONSTRUCTOR_ARGS)
        self.assertEqual(observed["argument_tail"], ["nullptr", "0", "result"])
        self.assertTrue(observed["frozen_complete_file_sha256_verified"])
        self.assertEqual(
            observed["function_template_sha256"],
            observed["expected_function_template_sha256"],
        )
        self.assertGreater(observed["function_template_token_count"], 100)
        self.assertEqual(observed["class_definition_count"], 1)
        self.assertGreater(observed["class_definition_token_count"], 100)
        self.assertTrue(observed["class_identity_bound_to_frozen_cpp_sha256"])
        self.assertTrue(observed["translation_phase2_before_phase3"])
        self.assertTrue(observed["original_offset_mapping_retained"])

    def test_all_lexical_and_structural_decoys_rejected(self) -> None:
        result = identity.f32_constructor_mutation_self_test(self.source_bytes)
        expected = {
            "ordinary_string_decoy",
            "raw_string_decoy",
            "escaped_literal_decoy",
            "character_preprocessor_decoy",
            "macro_decoy",
            "if0_fake_definition_call",
            "comment_prefixed_if0",
            "renamed_real_with_string_decoy",
            "declaration_without_definition",
            "missing_definition",
            "duplicate_definition",
            "unbalanced_body",
            "duplicate_real_call",
            "old_ten_argument_form",
            "missing_result",
            "physical_line_comment_splice",
            "if_false_dead_flow",
            "uncalled_lambda",
            "local_using_decoy",
            "local_typedef_decoy",
            "local_type_rebind",
            "argument_rebind",
            "declaration_decoy",
            "overload_decoy",
            "function_pointer_decoy",
            "unknown_preprocessor_condition",
        }
        self.assertEqual(set(result["harmful_mutations_rejected"]), expected)
        self.assertTrue(all(result["harmful_mutations_rejected"].values()))
        self.assertTrue(result["successor_rename_accepted"])
        self.assertTrue(result["successor_template_observation_unchanged"])
        self.assertTrue(result["successor_hash_check_intentionally_disabled"])
        self.assertEqual(
            result["classifiers"]["comment_prefixed_if0"], "complete-file-sha256"
        )
        self.assertEqual(
            result["classifiers"]["unknown_preprocessor_condition"],
            "preprocessor-fail-closed",
        )

    def test_wide_utf_raw_character_and_if0_text_is_masked_positionally(self) -> None:
        decoy = r'''
const char * a = "bool npu_verilator_execute_f32_alu() { f32_alu_harness harness(); }";
const char * b = u8R"tag(bool npu_verilator_execute_f32_alu() {
f32_alu_harness harness(); })tag";
wchar_t c = L'{';
#if 0
bool npu_verilator_execute_f32_alu() { f32_alu_harness harness(profile); }
#endif
'''
        masked = identity.mask_cpp_noncode(decoy)
        self.assertEqual(len(masked), len(decoy))
        self.assertEqual(masked.count("\n"), decoy.count("\n"))
        self.assertNotIn("npu_verilator_execute_f32_alu", masked)
        self.assertNotIn("f32_alu_harness", masked)

    def test_phase2_splice_precedes_comment_and_comment_prefix_precedes_directive(self) -> None:
        decoy = (
            "// physical comment continues "
            + chr(92)
            + "\n"
            + "bool npu_verilator_execute_f32_alu() { f32_alu_harness harness(); }\n"
            + "/**/ #if 0\n"
            + "bool npu_verilator_execute_f32_alu() { f32_alu_harness harness(); }\n"
            + "#endif\n"
            + "int live_token = 1;\n"
        )
        view = identity._cpp_phase2_source_view(decoy)
        self.assertEqual(len(view["splices"]), 1)
        self.assertEqual(len(view["logical"]), len(view["original_offsets"]))
        masked = identity.mask_cpp_noncode(decoy)
        self.assertEqual(len(masked), len(decoy))
        self.assertNotIn("npu_verilator_execute_f32_alu", masked)
        self.assertNotIn("f32_alu_harness", masked)
        self.assertIn("live_token", masked)

    def test_unknown_or_malformed_preprocessor_condition_fails_closed(self) -> None:
        for text in (
            "#if UNKNOWN\nint value;\n#endif\n",
            "#ifdef UNKNOWN\nint value;\n#endif\n",
            "#else\nint value;\n",
            "#if 0\nint value;\n",
        ):
            with self.subTest(text=text), self.assertRaises(identity.IdentityError):
                identity.mask_cpp_noncode(text)


class CMakeMembershipTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.cmake = NPU_ROOT / "runtime/llama-npu-backend/CMakeLists.txt"
        cls.source_bytes = identity.read_bytes_stable(cls.cmake)
        cls.source_text = cls.source_bytes.decode("utf-8")
        cls.set_start = cls.source_text.index("set(NPU_RTL_SOURCES")
        cls.set_end = cls.source_text.index("\n)\n", cls.set_start) + 3
        cls.set_block = cls.source_text[cls.set_start : cls.set_end]
        cls.custom_start = cls.source_text.index("add_custom_command(")
        cls.custom_end = cls.source_text.index("\n)\n", cls.custom_start) + 3
        cls.custom_block = cls.source_text[cls.custom_start : cls.custom_end]

    def assert_rejected(self, text: str, marker: str) -> None:
        with self.assertRaisesRegex(identity.IdentityError, marker):
            identity.parse_cmake_sources_bytes(text.encode("utf-8"))

    def source_line(self, relative: str) -> str:
        line = f'    "${{NPU_PROJECT_ROOT}}/{relative}"\n'
        self.assertEqual(self.source_text.count(line), 1, relative)
        return line

    def test_exact_unconditional_top_level_membership_and_current_bytes(self) -> None:
        parsed = identity.parse_cmake_sources_bytes(self.source_bytes)
        self.assertEqual(parsed, identity.EXPECTED_RTL_SOURCES)
        payload = identity.build_cmake_identity(REPO_ROOT, self.cmake)
        self.assertEqual(payload["source_count"], 21)
        self.assertTrue(payload["exact_order"])
        self.assertEqual(
            [item["path"] for item in payload["ordered_sources"]],
            list(identity.EXPECTED_RTL_SOURCES),
        )
        consumer = payload["consumer_binding"]
        self.assertEqual(consumer["all_expansion_count"], 2)
        self.assertEqual(consumer["verilator_command_expansion_count"], 1)
        self.assertEqual(consumer["depends_expansion_count"], 1)
        self.assertTrue(consumer["unconditional_top_level_set"])
        self.assertTrue(consumer["unconditional_top_level_custom_command"])
        self.assertTrue(consumer["bare_unquoted_exact_consumers"])
        self.assertTrue(consumer["producer_template_exact"])
        self.assertTrue(consumer["canonical_token_spellings"])
        self.assertTrue(consumer["downstream_target_template_exact"])
        self.assertEqual(consumer["competing_producer_count"], 0)
        self.assertTrue(consumer["active_structure_allowlist"])
        self.assertEqual(
            consumer["restricted_parser"], "cmake-frozen-producer-grammar-v2"
        )
        self.assertTrue(payload["frozen_complete_file_sha256_verified"])
        self.assertEqual(payload["frozen_cmake_template"], "PASS")
        self.assertEqual(payload["actual_configured_argv"], "GAP")
        self.assertEqual(payload["compile_membership_status"], "GAP")

    def test_inactive_and_uncalled_scope_sets_rejected(self) -> None:
        wrappers = {
            "if_false": ("if(FALSE)\n", "endif()\n"),
            "function": ("function(fake_sources)\n", "endfunction()\n"),
            "macro": ("macro(fake_sources)\n", "endmacro()\n"),
        }
        for name, (opening, closing) in wrappers.items():
            with self.subTest(name=name):
                mutant = (
                    self.source_text[: self.set_start]
                    + opening
                    + self.set_block
                    + closing
                    + self.source_text[self.set_end :]
                )
                self.assert_rejected(
                    mutant, "unconditional top-level set|pre-producer control"
                )

    def test_quoted_bracket_and_comment_command_decoys_rejected(self) -> None:
        renamed = self.source_text.replace(
            "set(NPU_RTL_SOURCES", "set(NPU_RTL_SOURCEZ", 1
        )
        decoys = {
            "quoted": 'message("set(NPU_RTL_SOURCES fake)")\n',
            "bracket": "message([[set(NPU_RTL_SOURCES fake)]])\n",
            "comment": "# set(NPU_RTL_SOURCES fake)\n",
        }
        for name, decoy in decoys.items():
            with self.subTest(name=name):
                self.assert_rejected(renamed + decoy, "top-level set|mutation/alias")

    def test_include_override_list_append_remove_and_duplicate_set_rejected(self) -> None:
        mutants = {
            "include_override": self.source_text + "\ninclude(fake-override.cmake)\n",
            "unset": self.source_text + "\nunset(NPU_RTL_SOURCES)\n",
            "list_append": self.source_text + "\nlist(APPEND NPU_RTL_SOURCES fake.v)\n",
            "list_remove": self.source_text + "\nlist(REMOVE_ITEM NPU_RTL_SOURCES fake.v)\n",
            "duplicate_set": self.source_text + "\n" + self.set_block,
            "alias": self.source_text + "\nset(NPU_RTL_ALIAS NPU_RTL_SOURCES)\n",
        }
        for name, mutant in mutants.items():
            with self.subTest(name=name):
                self.assert_rejected(mutant, "include/override|mutation/alias|top-level set")

    def test_missing_or_relocated_consumers_rejected(self) -> None:
        command_line = "            ${NPU_RTL_SOURCES}\n"
        depends_line = "    DEPENDS ${NPU_RTL_SOURCES}\n"
        self.assertEqual(self.source_text.count(command_line), 1)
        self.assertEqual(self.source_text.count(depends_line), 1)
        mutants = {
            "missing_command": self.source_text.replace(command_line, "", 1),
            "missing_depends": self.source_text.replace(depends_line, "    DEPENDS\n", 1),
            "different_command": self.source_text.replace(command_line, "", 1)
            + "\nadd_custom_command(OUTPUT fake COMMAND ${NPU_RTL_SOURCES})\n",
            "different_scope": (
                self.source_text[: self.custom_start]
                + "if(TRUE)\n"
                + self.custom_block
                + "endif()\n"
                + self.source_text[self.custom_end :]
            ),
        }
        for name, mutant in mutants.items():
            with self.subTest(name=name):
                self.assert_rejected(mutant, "consumer|producer")

    def test_frozen_producer_template_and_restricted_grammar_mutations_rejected(self) -> None:
        command_line = "            ${NPU_RTL_SOURCES}\n"
        self.assertEqual(self.source_text.count(command_line), 1)
        producer_insert = self.custom_start
        mutants = {
            "generator_expression": self.source_text.replace(
                command_line,
                '            "$<$<BOOL:0>:${NPU_RTL_SOURCES}>"\n',
                1,
            ),
            "top_level_return": (
                self.source_text[:producer_insert]
                + "return()\n"
                + self.source_text[producer_insert:]
            ),
            "indirect_variable": (
                self.source_text[:producer_insert]
                + "set(v NPU_RTL_SOURCE)\nstring(APPEND v S)\nunset(${v})\n"
                + self.source_text[producer_insert:]
            ),
            "dynamic_eval": (
                self.source_text[:producer_insert]
                + 'cmake_language(EVAL CODE "unset(NPU_RTL_SOURCES)")\n'
                + self.source_text[producer_insert:]
            ),
            "dynamic_call": (
                self.source_text[:producer_insert]
                + "cmake_language(CALL set NPU_RTL_SOURCES fake)\n"
                + self.source_text[producer_insert:]
            ),
            "variable_watch": (
                self.source_text[:producer_insert]
                + "variable_watch(NPU_RTL_SOURCES)\n"
                + self.source_text[producer_insert:]
            ),
            "parent_scope_mutation": (
                self.source_text[:producer_insert]
                + "set(NPU_RTL_SOURCES ${NPU_RTL_SOURCES} PARENT_SCOPE)\n"
                + self.source_text[producer_insert:]
            ),
            "cache_mutation": (
                self.source_text[:producer_insert]
                + "set(NPU_RTL_SOURCES fake CACHE STRING fake)\n"
                + self.source_text[producer_insert:]
            ),
            "command_shadowing": (
                self.source_text[:producer_insert]
                + "function(add_custom_command)\nendfunction()\n"
                + self.source_text[producer_insert:]
            ),
            "quoted_consumer": self.source_text.replace(
                command_line, '            "${NPU_RTL_SOURCES}"\n', 1
            ),
            "option_drift": self.source_text.replace("--no-trace", "--trace", 1),
            "escaped_producer_variable": self.source_text.replace(
                'OUTPUT "${NPU_VERILATED_ARCHIVE}"',
                'OUTPUT "' + chr(92) + '${NPU_VERILATED_ARCHIVE}"',
                1,
            ),
            "competing_output": self.source_text
            + '\nadd_custom_command(OUTPUT "${NPU_VERILATED_ARCHIVE}" COMMAND fake)\n',
        }
        markers = {
            "generator_expression": "generator expression",
            "top_level_return": "return rejected",
            "indirect_variable": "control/mutation|indirect",
            "dynamic_eval": "dynamic EVAL/CALL",
            "dynamic_call": "dynamic EVAL/CALL",
            "variable_watch": "variable_watch",
            "parent_scope_mutation": "top-level set|producer",
            "cache_mutation": "top-level set|producer",
            "command_shadowing": "control/mutation",
            "quoted_consumer": "producer token template|bare unquoted",
            "option_drift": "producer token template",
            "escaped_producer_variable": "producer token spelling",
            "competing_output": "competing producer",
        }
        for name, mutant in mutants.items():
            with self.subTest(name=name):
                self.assert_rejected(mutant, markers[name])

    def test_exact_downstream_target_and_producer_scope_relocation_rejected(self) -> None:
        target_line = (
            'add_custom_target(npu-verilated-model DEPENDS "${NPU_VERILATED_ARCHIVE}")\n'
        )
        self.assertEqual(self.source_text.count(target_line), 1)
        mutants = {
            "target_dependency_drift": self.source_text.replace(
                target_line,
                'add_custom_target(npu-verilated-model DEPENDS "${NPU_VERILATED_HEADER}")\n',
                1,
            ),
            "target_relocation": self.source_text.replace(
                target_line, "if(TRUE)\n" + target_line + "endif()\n", 1
            ),
            "producer_relocation": (
                self.source_text[: self.custom_start]
                + "block()\n"
                + self.custom_block
                + "endblock()\n"
                + self.source_text[self.custom_end :]
            ),
            "producer_foreach_relocation": (
                self.source_text[: self.custom_start]
                + "foreach(item IN ITEMS one)\n"
                + self.custom_block
                + "endforeach()\n"
                + self.source_text[self.custom_end :]
            ),
            "producer_while_relocation": (
                self.source_text[: self.custom_start]
                + "while(TRUE)\n"
                + self.custom_block
                + "endwhile()\n"
                + self.source_text[self.custom_end :]
            ),
        }
        for name, mutant in mutants.items():
            with self.subTest(name=name):
                self.assert_rejected(mutant, "downstream target|producer|control")

    def test_malformed_block_structure_rejected(self) -> None:
        mutants = {
            "unmatched_endif": self.source_text + "\nendif()\n",
            "unterminated_if": (
                self.source_text[: self.custom_start]
                + "if(TRUE)\n"
                + self.source_text[self.custom_start :]
            ),
        }
        for name, mutant in mutants.items():
            with self.subTest(name=name):
                self.assert_rejected(mutant, "mismatched|unterminated")

    def test_exact_list_mutations_rejected(self) -> None:
        fp32 = self.source_line("rtl/TensorNpuFp32AddMul.v")
        extra_anchor = self.source_line("rtl/tensor_npu_defs.vh")
        duplicate = self.source_line("rtl/TensorNpuCoprocessor.v")
        substitute = self.source_line("third_party/fpu-sp/verilog/src/float/fp_ext.sv")
        category = self.source_line("third_party/fpu-sp/verilog/src/float/fp_wire.sv")
        alias = self.source_line("rtl/TensorNpuF32TensorAlu.v")
        bracket_source = (
            "    [[${NPU_PROJECT_ROOT}/rtl/TensorNpuF32TensorAlu.v]]\n"
        )
        escaped_source = alias.replace('"${', '"' + chr(92) + '${', 1)
        mutants = {
            "missing": self.source_text.replace(fp32, "", 1),
            "extra": self.source_text.replace(
                extra_anchor,
                extra_anchor + '    "${NPU_PROJECT_ROOT}/rtl/UnexpectedExtra.v"\n',
                1,
            ),
            "duplicate": self.source_text.replace(duplicate, duplicate + duplicate, 1),
            "substitution": self.source_text.replace(
                substitute, substitute.replace("fp_ext.sv", "fp_substitute.sv"), 1
            ),
            "category_collision": self.source_text.replace(
                category, '    "${NPU_PROJECT_ROOT}/rtl/CategoryCollision.v"\n', 1
            ),
            "path_alias": self.source_text.replace(alias, alias.replace("/rtl/", "/rtl/./"), 1),
            "bracket_source": self.source_text.replace(alias, bracket_source, 1),
            "escaped_source": self.source_text.replace(alias, escaped_source, 1),
        }
        for name, mutant in mutants.items():
            with self.subTest(name=name):
                self.assert_rejected(
                    mutant,
                    "missing source|extra source|duplicate source|substitution|category collision|"
                    "path alias|quoted literal|token spelling",
                )

    def test_harmless_unrelated_command_edit_preserves_identity(self) -> None:
        mutant = self.source_text.replace(
            "add_executable(test-npu-backend test-backend.cpp)",
            "add_executable(test-npu-backend-renamed test-backend.cpp)",
            1,
        )
        self.assertEqual(
            identity.parse_cmake_sources_bytes(mutant.encode("utf-8")),
            identity.EXPECTED_RTL_SOURCES,
        )


class PublicationClosureTests(unittest.TestCase):
    def test_atomic_fresh_publication_and_no_replace(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            output = root / "identity.json"
            payload = {"schema": "atomic-publication-probe", "value": 1}
            digest = identity.atomic_write_json(output, payload)
            value, observed, data = identity.read_json_same_bytes(output)
            self.assertEqual(value, payload)
            self.assertEqual(observed, digest)
            self.assertEqual(hashlib.sha256(data).hexdigest(), digest)
            with self.assertRaisesRegex(identity.IdentityError, "already exists"):
                identity.atomic_write_json(output, payload)

    def test_manifest_reopens_json_and_nonjson_and_rejects_late_replacement(self) -> None:
        for kind in ("json", "bytes"):
            with self.subTest(kind=kind), tempfile.TemporaryDirectory() as directory:
                root = pathlib.Path(directory)
                path = root / ("artifact.json" if kind == "json" else "artifact.log")
                schema = "late-json-v1" if kind == "json" else None
                if schema:
                    identity.atomic_write_json(path, {"schema": schema, "value": 1})
                else:
                    identity.atomic_write_bytes(path, b"trusted\n")
                record = identity.build_artifact_record(root, path, schema)
                manifest = {path.name: record}
                self.assertTrue(
                    identity.revalidate_bound_artifacts(root, manifest)["all_reopened"]
                )
                replacement = root / "replacement"
                if schema:
                    identity.atomic_write_json(replacement, {"schema": schema, "value": 2})
                else:
                    identity.atomic_write_bytes(replacement, b"substituted\n")
                os.replace(replacement, path)
                with self.assertRaisesRegex(identity.IdentityError, "late artifact replacement"):
                    identity.revalidate_bound_artifacts(root, manifest)

    def test_manifest_rejects_path_alias_and_schema_spoof(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            artifact = root / "artifact.json"
            identity.atomic_write_json(artifact, {"schema": "real-v1"})
            record = identity.build_artifact_record(root, artifact, "real-v1")
            with self.assertRaisesRegex(identity.IdentityError, "non-canonical"):
                identity.revalidate_bound_artifacts(root, {"nested/../artifact.json": record})
            spoof = dict(record)
            spoof["schema"] = "spoof-v1"
            with self.assertRaisesRegex(identity.IdentityError, "schema mismatch"):
                identity.revalidate_bound_artifacts(root, {"artifact.json": spoof})


class StrictDepfileTests(unittest.TestCase):
    @staticmethod
    def dep_escape(path: pathlib.Path | str) -> str:
        return str(path).replace("\\", "\\\\").replace(" ", "\\ ")

    def create_fixture(self, directory: str) -> dict[str, Any]:
        root = pathlib.Path(directory).resolve()
        build = root / "build root"
        build.mkdir()
        target = build / "runner object.o"
        target.write_bytes(b"object\n")
        control = build / "verilated std.sv"
        control.write_bytes(b"control\n")
        tool = build / "verilator compiler"
        tool.write_bytes(b"tool\n")
        tool.chmod(0o755)
        verfiles = build / "VTensorNpuCoprocessor__verFiles.dat"
        design = [NPU_ROOT / relative for relative in identity.EXPECTED_RTL_SOURCES]
        verfile_rows = [f'S 0 0 "{path}"' for path in [*design, control, tool]]
        verfiles.write_text("\n".join(verfile_rows) + "\n", encoding="utf-8")
        depfile = build / "runner dependency.d"
        prerequisites = [*design, control, tool, verfiles]
        escaped = [self.dep_escape(path) for path in prerequisites]
        midpoint = len(escaped) // 2
        depfile.write_text(
            f"{self.dep_escape(target)}: "
            + " ".join(escaped[:midpoint])
            + " \\\n  "
            + " ".join(escaped[midpoint:])
            + "\n",
            encoding="utf-8",
        )
        argv_path = build / "compiler-argv.json"
        categories = {
            "design": sorted(str(path.resolve()) for path in design),
            "transitive": [],
            "control": [str(control)],
            "tool": [str(tool)],
        }
        argv_payload = {
            "schema": identity.SCHEMA_COMPILER_ARGV,
            "build_root": str(build),
            "cwd": str(build),
            "object_targets": [str(target)],
            "verfiles_path": str(verfiles),
            "dependency_files": [str(depfile)],
            "prerequisite_categories": categories,
            "argv": [str(tool), "-MMD", "-MF", str(depfile), "-o", str(target)],
        }
        argv_path.write_bytes(identity.canonical_json_bytes(argv_payload))
        argv_sha = hashlib.sha256(argv_path.read_bytes()).hexdigest()
        return {
            "root": root,
            "build": build,
            "target": target,
            "control": control,
            "tool": tool,
            "verfiles": verfiles,
            "depfile": depfile,
            "argv": argv_path,
            "argv_payload": argv_payload,
            "argv_sha": argv_sha,
            "design": design,
            "prerequisites": prerequisites,
        }

    def audit(self, fixture: dict[str, Any], **overrides: Any) -> dict[str, Any]:
        parameters = {
            "repo_root": REPO_ROOT,
            "cmake_path": NPU_ROOT / "runtime/llama-npu-backend/CMakeLists.txt",
            "verfiles_path": fixture["verfiles"],
            "transitive_sources": (),
            "control_sources": (fixture["control"],),
            "tool_sources": (fixture["tool"],),
            "dependency_files": (fixture["depfile"],),
            "expected_build_root": fixture["build"],
            "object_targets": (fixture["target"],),
            "compiler_argv_path": fixture["argv"],
            "compiler_argv_sha256": fixture["argv_sha"],
            "declared_roots": (NPU_ROOT, fixture["build"]),
        }
        parameters.update(overrides)
        return identity.audit_verfiles(**parameters)

    def rewrite_depfile(
        self,
        fixture: dict[str, Any],
        *,
        targets: Sequence[pathlib.Path] | None = None,
        prerequisites: Sequence[pathlib.Path | str] | None = None,
    ) -> None:
        targets = targets if targets is not None else [fixture["target"]]
        prerequisites = prerequisites if prerequisites is not None else fixture["prerequisites"]
        fixture["depfile"].write_text(
            " ".join(self.dep_escape(path) for path in targets)
            + ": "
            + " ".join(self.dep_escape(path) for path in prerequisites)
            + "\n",
            encoding="utf-8",
        )

    def test_strict_verfiles_depfile_argv_and_provenance_closure(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = self.create_fixture(directory)
            result = self.audit(fixture)
            self.assertEqual(result["raw_s_row_count"], 23)
            self.assertEqual(result["class_counts"]["design"], 21)
            self.assertEqual(result["class_counts"]["control"], 1)
            self.assertEqual(result["class_counts"]["tool"], 1)
            self.assertEqual(result["depfile_target_count"], 1)
            self.assertEqual(result["depfile_prerequisite_count"], 24)
            self.assertTrue(result["depfile_exact_closure"])
            self.assertTrue(result["depfile_provenance_bound"])
            self.assertEqual(result["compile_membership_status"], "PASS")

    def test_depfile_parser_continuation_escaped_space_and_backslash(self) -> None:
        rules = identity.parse_make_depfile_bytes(
            b"obj\\ file.o: src\\ file.cpp dir\\\\name.h \\\n next.h\n"
        )
        self.assertEqual(rules[0]["targets"], ["obj file.o"])
        self.assertEqual(
            rules[0]["prerequisites"], ["src file.cpp", "dir\\name.h", "next.h"]
        )

    def test_malformed_and_arbitrary_depfile_bytes_rejected(self) -> None:
        mutants = {
            "no_colon": b"arbitrary bytes\n",
            "empty_prerequisite": b"runner.o:\n",
            "multiple_colon": b"a: b: c\n",
            "dangling_escape": b"a: b\\",
            "make_variable": b"a: $(FAKE)\n",
        }
        for name, data in mutants.items():
            with self.subTest(name=name), self.assertRaises(identity.IdentityError):
                identity.parse_make_depfile_bytes(data)

    def test_wrong_stale_and_duplicate_targets_rejected(self) -> None:
        for name in ("wrong", "stale", "duplicate"):
            with self.subTest(name=name), tempfile.TemporaryDirectory() as directory:
                fixture = self.create_fixture(directory)
                other = fixture["build"] / "other.o"
                if name != "stale":
                    other.write_bytes(b"other\n")
                targets = [other, other] if name == "duplicate" else [other]
                self.rewrite_depfile(fixture, targets=targets)
                with self.assertRaises(identity.IdentityError):
                    self.audit(fixture)

    def test_stale_build_root_and_wrong_argv_identity_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = self.create_fixture(directory)
            stale = fixture["root"] / "stale-build"
            stale.mkdir()
            with self.assertRaisesRegex(identity.IdentityError, "build root|outside expected"):
                self.audit(fixture, expected_build_root=stale, declared_roots=(NPU_ROOT, stale))
            with self.assertRaisesRegex(identity.IdentityError, "external identity"):
                self.audit(fixture, compiler_argv_sha256="0" * 64)

    def test_missing_extra_duplicate_alias_and_escape_prerequisites_rejected(self) -> None:
        for name in ("missing", "extra", "duplicate", "alias", "escape"):
            with self.subTest(name=name), tempfile.TemporaryDirectory() as directory:
                fixture = self.create_fixture(directory)
                prerequisites: list[pathlib.Path | str] = list(fixture["prerequisites"])
                if name == "missing":
                    prerequisites.pop()
                elif name == "extra":
                    extra = fixture["build"] / "unrelated.h"
                    extra.write_bytes(b"extra\n")
                    prerequisites.append(extra)
                elif name == "duplicate":
                    prerequisites.append(prerequisites[0])
                elif name == "alias":
                    prerequisites[0] = str(
                        fixture["design"][0].parent
                        / ".."
                        / fixture["design"][0].parent.name
                        / fixture["design"][0].name
                    )
                else:
                    outside = fixture["root"] / "outside.h"
                    outside.write_bytes(b"outside\n")
                    prerequisites.append(outside)
                self.rewrite_depfile(fixture, prerequisites=prerequisites)
                with self.assertRaises(identity.IdentityError):
                    self.audit(fixture)

    def test_caller_category_collision_and_unrelated_self_declaration_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = self.create_fixture(directory)
            with self.assertRaisesRegex(identity.IdentityError, "category collision"):
                self.audit(
                    fixture,
                    control_sources=(fixture["control"],),
                    tool_sources=(fixture["control"],),
                )
            unrelated = fixture["build"] / "unrelated-control.sv"
            unrelated.write_bytes(b"unrelated\n")
            with self.assertRaises(identity.IdentityError):
                self.audit(fixture, control_sources=(fixture["control"], unrelated))

    def test_compiler_argv_build_root_target_and_category_mutations_rejected(self) -> None:
        for field in (
            "build_root",
            "object_targets",
            "prerequisite_categories",
            "argv_dependency_file",
        ):
            with self.subTest(field=field), tempfile.TemporaryDirectory() as directory:
                fixture = self.create_fixture(directory)
                payload = json.loads(json.dumps(fixture["argv_payload"]))
                if field == "build_root":
                    payload[field] = str(fixture["root"])
                elif field == "object_targets":
                    payload[field] = []
                elif field == "prerequisite_categories":
                    payload[field]["control"] = []
                else:
                    payload["argv"] = [
                        str(fixture["tool"]), "-o", str(fixture["target"])
                    ]
                fixture["argv"].write_bytes(identity.canonical_json_bytes(payload))
                fixture["argv_sha"] = hashlib.sha256(
                    fixture["argv"].read_bytes()
                ).hexdigest()
                with self.assertRaisesRegex(
                    identity.IdentityError, "provenance|dependency file"
                ):
                    self.audit(fixture)


def main() -> int:
    suite = unittest.defaultTestLoader.loadTestsFromModule(os.sys.modules[__name__])
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if not result.wasSuccessful():
        return 1
    print(
        "[qwen-f32-alu-build-identity-test] PASS exact=21 "
        "cpp-lexical=pass cpp-phase2-phase3=pass cpp-full-template=pass "
        "cmake-structural=pass frozen-cmake-template=pass cmake-mutations=44/44 "
        "depfile-strict=pass "
        "late-revalidation=pass compile-membership=GAP"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
