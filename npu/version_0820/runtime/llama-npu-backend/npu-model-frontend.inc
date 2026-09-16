static ggml_status npu_model_graph_compute(npu_backend_context * context, ggml_cgraph * graph) {
    context->model_dispatch_passed = false;
    try {
        if (context->active_audit != audit_generation::v2)
            throw std::runtime_error("compiled model requires strict canonical audit v2");
        const char * root = std::getenv("LLAMA_NPU_COMPILED_ARTIFACT_DIR");
        if (!root || !*root) throw std::runtime_error("LLAMA_NPU_COMPILED_ARTIFACT_DIR is required");
        const auto generation = ++context->model_generation;
        const auto compiled = npu_compile_model_graph(context, graph,
            std::string(root) + "/dispatch-" + std::to_string(generation));
        if (!context->model_session) context->model_session = std::make_unique<npu_system_session>();
        if (!context->model_session->ready()) throw std::runtime_error(context->model_session->failure());
        npu_system_dispatch_result result = {};
        std::string error;
        const bool passed = npu_model_execute(compiled.directory, compiled.metadata_sha256,
            compiled.bindings, *context->model_session, generation, &result, &error);
        auto & audit = context->audit_v2;
        audit.required_enqueued += result.delta.launch_accepts;
        audit.commands_accepted += result.delta.launch_accepts;
        audit.commands_terminal_success += passed ? result.completed : 0;
        audit.rtl_cycles += result.delta.cycles;
        audit.gmem_read_bytes += result.delta.gmem_read_bytes;
        audit.gmem_write_bytes += result.delta.gmem_write_bytes;
        audit.vector_elements += result.delta.vector_elements;
        if (!passed) throw std::runtime_error(error +
            " generation=" + std::to_string(generation) +
            " completed=" + std::to_string(result.completed) +
            " mailbox_error=" + std::to_string(result.mailbox_error) +
            " mcause=" + std::to_string(result.fault_cause) +
            " mtval=" + std::to_string(result.fault_tval) +
            " mepc=" + std::to_string(result.fault_pc));
        for (auto & entry : context->canonical_nodes) {
            entry.second.enqueued = true; entry.second.completed = true;
        }
        audit.executed_by_verilator += result.completed;
        audit.required_successfully_covered += result.completed;
        const auto status = context->model_session->status();
        std::fprintf(stderr,"[NPU-COMPILED-MODEL][PASS] generation=%llu completed=%u constructors=%llu resets=%llu boots=%llu cycles=%llu q8_blocks=%llu f32_read_bytes=%llu mover_read_bytes=%llu cpu_tensor_fallbacks=0\n",
            (unsigned long long)generation,result.completed,(unsigned long long)status.constructor_count,
            (unsigned long long)status.reset_release_count,(unsigned long long)status.boot_count,
            (unsigned long long)result.delta.cycles,(unsigned long long)result.delta.q8_blocks,
            (unsigned long long)result.delta.portal_read_bytes,(unsigned long long)result.delta.mover_read_bytes);
        context->model_dispatch_passed = true;
        return GGML_STATUS_SUCCESS;
    } catch (const std::exception & e) {
        ++context->audit_v2.rtl_failures;
        std::fprintf(stderr,"[NPU-COMPILED-MODEL][FAIL] %s; CPU tensor fallback is forbidden\n",e.what());
        return GGML_STATUS_FAILED;
    }
}
