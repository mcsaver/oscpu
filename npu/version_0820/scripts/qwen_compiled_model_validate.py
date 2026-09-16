#!/usr/bin/env python3
"""Validate actual compiled Qwen generation; prefix execution is never success."""
import argparse
import hashlib
import json
import pathlib
import re
import struct


def require(condition, message):
    if not condition:
        raise ValueError(message)


def file_hash(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def validate(root, oracle_path):
    oracle = json.loads(oracle_path.read_text())
    turn = oracle["turns"][0]
    identity = json.loads((root / "model-identity.json").read_text())
    require(identity["model_sha256"] == oracle["model_sha256"] and identity["model_bytes"] > 0,
            "executed model identity does not match the frozen oracle")
    prompt = [int(x) for x in (root / "prompt.ids").read_text().split()]
    tokens = [int(x) for x in (root / "generated.ids").read_text().split()]
    require(prompt == turn["prompt_token_ids"], f"prompt token mismatch: {prompt}")
    require(tokens == turn["generated_token_ids"][:2], f"generated token mismatch: {tokens}")
    log = (root / "run.log").read_text()
    require("[NPU-STRICT][READY] backend=NPU candidates=1 audit_abi=v2" in log,
            "strict real backend admission missing")
    for failure in ("[NPU-COMPILED-MODEL][FAIL]", "[NPU-STRICT][FAIL]",
                    "[NPU-SERVICE][FAIL]", "[NPU-STRICT-ADMISSION-ONLY][PASS]"):
        require(failure not in log, f"invalid run marker: {failure}")
    passes = re.findall(r"^\[NPU-COMPILED-MODEL\]\[PASS\] (.+)$", log, re.M)
    strict = re.findall(r"^\[NPU-STRICT\]\[PASS\] (.+)$", log, re.M)
    require(len(passes) == 2 and len(strict) == 2, "need two complete real dispatches")
    numeric = lambda line: {key: int(value) for key, value in re.findall(r"(\w+)=(\d+)", line)}
    artifacts = []
    for generation in (1, 2):
        fields = numeric(passes[generation - 1])
        require(fields.get("generation") == generation and fields.get("completed") == 1080,
                f"generation {generation} completion mismatch")
        require(all(fields.get(k) == 1 for k in ("constructors", "resets", "boots")),
                "SystemTop or firmware was restarted")
        require(fields.get("cpu_tensor_fallbacks") == 0 and fields.get("cycles", 0) > 0,
                "missing no-fallback execution evidence")
        audit = numeric(strict[generation - 1])
        require(audit.get("dispatch") == generation, "strict dispatch sequence mismatch")
        for key in ("required_seen", "assigned", "required_enqueued", "required_completed",
                    "executed", "commands_accepted", "completion_success"):
            require(audit.get(key) == 1080, f"strict {key} does not close")
        for key in ("completion_failure", "coverage_missing", "coverage_duplicate",
                    "coverage_hash_mismatch", "completion_identity_mismatch", "unsupported",
                    "rtl_failures", "gmem_errors", "timeout_errors", "cpu_fallback_attempts",
                    "host_tensor_arithmetic"):
            require(audit.get(key) == 0, f"strict {key} is nonzero or missing")
        directory = root / "artifacts" / f"dispatch-{generation}"
        metadata = json.loads((directory / "metadata.json").read_text())
        require(metadata["schema"] == "npu-compiled-model-v1", "wrong artifact schema")
        commands = metadata["commands"]
        require(len(commands) == 1080, "artifact command coverage mismatch")
        require(len({c["canonical_id"] for c in commands}) == 1080, "duplicate canonical node")
        require(file_hash(directory / "command.bin") == metadata["command_sha256"],
                "command.bin changed after compilation")
        require(file_hash(directory / "weights.bin") == metadata["weights_sha256"],
                "weights.bin changed after compilation")
        image = (directory / "command.bin").read_bytes()
        magic, major, minor, header, stride, count, flags, payload = struct.unpack_from("<8s4HIIQ", image)
        require((magic, major, minor, header, stride, count, flags, payload) ==
                (b"NPUCMD\0\0", 1, 1, 64, 240, 1080, 0, 1080 * 240), "command header mismatch")
        require(len(image) == 64 + payload and hashlib.sha256(image[64:]).digest() == image[32:64],
                "command payload integrity mismatch")
        for relocation in metadata["relocations"]:
            word = 64 + relocation["command"] * 240 + relocation["word"] * 8
            require(image[word:word + 8] == bytes(8), "artifact contains a resolved host address")
        expected = [(str(i), str(c["graph_index"])) for i, c in enumerate(commands)]
        for event in ("LAUNCH", "TERMINAL"):
            seen = re.findall(rf"^\[NPU-SERVICE\]\[{event}\] generation={generation} command=(\d+) graph_index=(\d+) ",
                              log, re.M)
            require(seen == expected, f"generation {generation}: {event} is not exact once and ordered")
        artifacts.append({
            "generation": generation, "commands": len(commands), "cycles": fields["cycles"],
            "metadata_sha256": file_hash(directory / "metadata.json"),
            "command_sha256": metadata["command_sha256"], "weights_sha256": metadata["weights_sha256"],
            "copy_records": len(metadata["copies"]), "publication_records": len(metadata["publications"]),
        })
    return {"schema": "qwen-compiled-model-result-v1", "pass": True,
            "prompt_token_ids": prompt, "generated_token_ids": tokens,
            "model_sha256": oracle["model_sha256"], "llama_commit": oracle["llama_commit"],
            "constructors": 1, "resets": 1, "boots": 1, "cpu_tensor_fallbacks": 0,
            "dispatches": artifacts}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run_root", type=pathlib.Path)
    parser.add_argument("--oracle", type=pathlib.Path, default=pathlib.Path(__file__).resolve().parents[1] /
                        "tests/vectors/qwen35_08b_q8_0/strict-smoke-oracle.json")
    args = parser.parse_args()
    try:
        result = validate(args.run_root, args.oracle)
    except (ValueError, KeyError, OSError, TypeError, struct.error) as error:
        parser.exit(1, f"[QWEN-COMPILED-MODEL][FAIL] {error}\n")
    (args.run_root / "result.json").write_text(json.dumps(result, indent=2) + "\n")
    print("[QWEN-COMPILED-MODEL][PASS] actual tokens", result["generated_token_ids"],
          "compiled dispatches=2 commands=2160 persistent boots=1 CPU tensor fallback=0")


if __name__ == "__main__":
    main()
