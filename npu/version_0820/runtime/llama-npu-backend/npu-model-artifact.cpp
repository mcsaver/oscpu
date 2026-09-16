#include "npu-model-artifact.h"
#include "npu_service_mailbox_abi.h"
#include <algorithm>
#include <cstring>
#include <fstream>
#include <set>
#include <stdexcept>
#include <limits>

std::string npu_model_hash(const void * bytes, std::size_t size) {
    const auto digest = npu_compiled_sha256(bytes, size);
    static const char hex[] = "0123456789abcdef";
    std::string result;
    for (auto b : digest) { result += hex[b >> 4]; result += hex[b & 15]; }
    return result;
}
static void put(std::vector<std::uint8_t> & out, std::size_t off, std::uint64_t v, std::size_t n) {
    for (std::size_t i = 0; i < n; ++i) out.at(off + i) = v >> (8 * i);
}
std::vector<std::uint8_t> npu_model_command_image(const std::vector<npu_command_abi_words> & words) {
    std::vector<std::uint8_t> image(64 + words.size() * 240, 0);
    const std::uint8_t magic[] = {'N','P','U','C','M','D',0,0};
    std::copy_n(magic, 8, image.begin());
    put(image, 8, 1, 2); put(image, 10, 1, 2);
    put(image, 12, 64, 2); put(image, 14, 240, 2);
    put(image, 16, words.size(), 4); put(image, 24, words.size() * 240, 8);
    for (std::size_t c = 0; c < words.size(); ++c)
        for (std::size_t w = 0; w < 30; ++w) put(image, 64 + c * 240 + w * 8, words[c][w], 8);
    auto hash = npu_compiled_sha256(image.data() + 64, image.size() - 64);
    std::copy(hash.begin(), hash.end(), image.begin() + 32);
    return image;
}
static std::vector<std::uint8_t> read_file(const std::string & path, std::size_t limit) {
    std::ifstream file(path, std::ios::binary | std::ios::ate);
    if (!file) throw std::runtime_error("cannot open " + path);
    const auto size = file.tellg();
    if (size < 0 || static_cast<std::uint64_t>(size) > limit) throw std::runtime_error("invalid size " + path);
    std::vector<std::uint8_t> bytes(static_cast<std::size_t>(size));
    file.seekg(0);
    if (!bytes.empty() && !file.read(reinterpret_cast<char *>(bytes.data()), bytes.size()))
        throw std::runtime_error("short read " + path);
    return bytes;
}
static bool range(std::uint64_t off, std::uint64_t n, std::uint64_t bytes) {
    return off <= bytes && n <= bytes - off;
}
bool npu_model_execute(const std::string & dir, const std::string & expected,
    const std::vector<npu_model_binding> & bindings, npu_system_session & session,
    std::uint64_t generation, npu_system_dispatch_result * result, std::string * error) {
    try {
        auto raw = read_file(dir + "/metadata.json", 32U << 20);
        if (npu_model_hash(raw.data(), raw.size()) != expected) throw std::runtime_error("metadata identity mismatch");
        auto json = npu_model_json::parse(raw);
        auto meta = json.get<npu_model_metadata>();
        if (meta.schema != "npu-compiled-model-v1" || meta.commands.empty() ||
            meta.commands.size() > NPU_SERVICE_MAX_COMMANDS) throw std::runtime_error("schema/count mismatch");
        auto command = read_file(dir + "/command.bin", 2U << 20);
        auto weights = read_file(dir + "/weights.bin", 2ULL << 30);
        if (npu_model_hash(command.data(), command.size()) != meta.command_sha256 ||
            npu_model_hash(weights.data(), weights.size()) != meta.weights_sha256)
            throw std::runtime_error("command/weights integrity mismatch");
        if (command.size() != NPU_COMPILED_COMMAND_HEADER_BYTES +
                meta.commands.size() * NPU_SERVICE_COMMAND_STRIDE)
            throw std::runtime_error("command file/metadata cardinality mismatch");
        std::vector<npu_command_abi_words> words(meta.commands.size());
        for (std::size_t i = 0; i < words.size(); ++i)
            if (!npu_compiled_bundle_decode_record(command, i, &words[i]))
                throw std::runtime_error("invalid command file record " + std::to_string(i));
        std::vector<std::vector<std::uint8_t>> arena(meta.buffers.size());
        npu_system_submission submission = {};
        submission.generation = generation;
        submission.max_cycles = 20000;
        submission.copies.resize(words.size());
        std::set<std::string> ids, nodes;
        for (std::size_t i = 0; i < meta.buffers.size(); ++i) {
            const auto & b = meta.buffers[i];
            if (!b.bytes || b.bytes > (2ULL << 30) || !b.base ||
                !ids.insert(b.id).second || b.permissions < 1 || b.permissions > 3)
                throw std::runtime_error("invalid buffer capability " + b.id);
            arena[i].resize(b.bytes, 0);
            if (b.kind == "weight") {
                if (b.permissions != 1 || !range(b.weight_offset, b.bytes, weights.size()))
                    throw std::runtime_error("weight range/permission mismatch " + b.id);
                std::copy_n(weights.data() + b.weight_offset, b.bytes, arena[i].data());
            } else if (b.kind == "binding") {
                if (b.binding < 0 || static_cast<std::size_t>(b.binding) >= bindings.size())
                    throw std::runtime_error("missing host binding " + b.id);
                const auto & host = bindings[b.binding];
                if (!host.input || host.bytes > b.bytes) throw std::runtime_error("host binding extent mismatch " + b.id);
                std::copy_n(host.input, host.bytes, arena[i].data());
            } else if (b.kind != "scratch") throw std::runtime_error("unknown buffer kind");
            submission.buffers.push_back({b.id, b.base, b.permissions, &arena[i]});
        }
        // Release the on-disk weight image before advancing the RTL.
        weights.clear(); weights.shrink_to_fit();
        std::set<std::pair<std::uint32_t, std::uint32_t>> relocated;
        for (const auto & r : meta.relocations) {
            if (r.command >= words.size() || r.buffer >= meta.buffers.size() ||
                !(r.word == 10 || r.word == 11 || r.word == 12 || r.word == 13 ||
                  r.word == 23 || r.word == 26 || r.word == 28) ||
                !relocated.insert({r.command,r.word}).second || words[r.command][r.word] != 0)
                throw std::runtime_error("invalid/duplicate relocation");
            const auto & b = meta.buffers[r.buffer];
            if (r.addend > b.bytes || b.base > UINT64_MAX - r.addend)
                throw std::runtime_error("relocation overflow");
            words[r.command][r.word] = b.base + r.addend;
        }
        for (std::size_t i = 0; i < words.size(); ++i) {
            const auto & c = meta.commands[i];
            npu_command_abi_diagnostic diagnostic = {};
            if (c.canonical_id.size() != 64 || !nodes.insert(c.canonical_id).second ||
                !c.max_cycles || submission.max_cycles > UINT64_MAX - c.max_cycles ||
                !npu_command_abi_validate_words(&words[i], &diagnostic))
                throw std::runtime_error("invalid identity/budget/relocated command " + std::to_string(i) + " " + c.name + " abi=" + npu_command_abi_error_string(diagnostic.error) + " word=" + std::to_string(diagnostic.word_index));
            submission.max_cycles += c.max_cycles;
            submission.commands.push_back(c.contract);
        }
        std::set<std::pair<std::uint32_t, std::uint32_t>> copies;
        for (const auto & c : meta.copies) {
            if (c.command >= words.size() || c.phase > 1 || c.src_buffer >= arena.size() ||
                c.dst_buffer >= arena.size() || !c.bytes ||
                !copies.insert({c.command,c.phase}).second ||
                !range(c.src_offset,c.bytes,arena[c.src_buffer].size()) ||
                !range(c.dst_offset,c.bytes,arena[c.dst_buffer].size()))
                throw std::runtime_error("copy relocation range mismatch");
            const npu_system_raw_copy copy = {meta.buffers[c.src_buffer].base + c.src_offset,
                meta.buffers[c.dst_buffer].base + c.dst_offset, c.bytes};
            (c.phase ? submission.copies[c.command].after : submission.copies[c.command].before) = copy;
            if (c.bytes > (UINT64_MAX - submission.max_cycles) / 64)
                throw std::runtime_error("copy budget overflow");
            submission.max_cycles += c.bytes * 64;
        }
        for (const auto & p : meta.publications) {
            if (p.buffer >= arena.size() || p.binding >= bindings.size() ||
                !bindings[p.binding].output ||
                !range(p.offset,p.bytes,arena[p.buffer].size()) ||
                !range(p.offset,p.bytes,bindings[p.binding].bytes))
                throw std::runtime_error("publication escaped host binding");
        }
        command = npu_model_command_image(words);
        submission.relocated_command_image = &command;
        if (!session.dispatch(submission, result)) {
            std::string detail = session.failure();
            std::size_t i = result && result->delta.launch_accepts ? result->delta.launch_accepts - 1 : 0;
            const auto bracket = detail.find("command[");
            if (bracket != std::string::npos) { try { i = std::stoull(detail.substr(bracket + 8)); } catch (...) {} }
            if (i < meta.commands.size()) detail += " graph_index=" + std::to_string(meta.commands[i].graph_index) +
                " node=" + meta.commands[i].name + " canonical_id=" + meta.commands[i].canonical_id;
            throw std::runtime_error(detail);
        }
        for (const auto & p : meta.publications)
            std::memcpy(bindings[p.binding].output + p.offset, arena[p.buffer].data() + p.offset, p.bytes);
        return true;
    } catch (const std::exception & e) { if (error) *error = e.what(); return false; }
}
