// Quasi-offline GGML subgraph compiler. This translation unit is included by
// the strict frontend so it shares the audited metadata matchers, never the
// legacy execution routines. It emits a complete artifact before any launch.
struct npu_model_compilation {
    std::string directory, metadata_sha256;
    std::vector<npu_model_binding> bindings;
};
static std::uint64_t model_align(std::uint64_t x, std::uint64_t n = 64) {
    if (x > UINT64_MAX - n + 1) throw std::runtime_error("allocation size overflow");
    return (x + n - 1) & ~(n - 1);
}
static ggml_tensor * model_root(ggml_tensor * t) {
    while (t && t->view_src) t = t->view_src;
    return t;
}
static std::string model_hex(const std::array<std::uint8_t,32> & a) {
    static const char h[] = "0123456789abcdef"; std::string s;
    for (auto b : a) { s += h[b >> 4]; s += h[b & 15]; } return s;
}
static void model_write(const std::string & path, const void * data, std::size_t bytes) {
    std::ofstream file(path, std::ios::binary | std::ios::trunc);
    if (!file || (bytes && !file.write(static_cast<const char *>(data), bytes)))
        throw std::runtime_error("artifact write failed: " + path);
}
static npu_model_compilation npu_compile_model_graph(npu_backend_context * context,
        ggml_cgraph * graph, const std::string & directory) {
    struct region { std::uintptr_t lo, hi; bool weight; std::uint32_t buffer; };
    std::vector<region> ranges;
    std::set<ggml_tensor *> roots;
    auto visit = [&](ggml_tensor * t) {
        auto * r = model_root(t);
        if (!r || !roots.insert(r).second) return;
        const auto bytes = ggml_nbytes(r);
        if (!bytes) return;
        if (!r->data) throw std::runtime_error("unallocated tensor " + std::string(r->name));
        const auto lo = reinterpret_cast<std::uintptr_t>(r->data);
        if (lo > UINTPTR_MAX - bytes) throw std::runtime_error("host range overflow");
        const bool weight = r->buffer && ggml_backend_buffer_get_usage(r->buffer) == GGML_BACKEND_BUFFER_USAGE_WEIGHTS;
        ranges.push_back({lo,lo + bytes,weight,0});
    };
    for (int i = 0; i < ggml_graph_n_nodes(graph); ++i) {
        auto * n = ggml_graph_node(graph,i); visit(n);
        for (auto * s : n->src) visit(s);
    }
    std::sort(ranges.begin(),ranges.end(),[](const region & a,const region & b){return a.lo < b.lo;});
    std::vector<region> merged;
    for (const auto & r : ranges) {
        if (!merged.empty() && r.lo < merged.back().hi) {
            if (r.weight != merged.back().weight) throw std::runtime_error("weight/output host alias");
            merged.back().hi = std::max(merged.back().hi,r.hi);
        } else merged.push_back(r);
    }
    npu_model_compilation compiled; compiled.directory = directory;
    npu_model_metadata meta;
    std::vector<std::uint8_t> weights;
    std::uint64_t next_mutable = 0xa0400000ULL, next_weight = 0x100000000ULL;
    for (auto & r : merged) {
        npu_model_buffer b;
        b.id = "buffer-" + std::to_string(meta.buffers.size());
        b.bytes = model_align(r.hi - r.lo,8);
        b.permissions = r.weight ? 1 : 3;
        auto & next = r.weight ? next_weight : next_mutable;
        b.base = next; next += model_align(b.bytes) + 64;
        b.kind = r.weight ? "weight" : "binding";
        if (r.weight) {
            b.weight_offset = weights.size();
            const auto old = weights.size(); weights.resize(old + b.bytes,0);
            std::memcpy(weights.data()+old,reinterpret_cast<const void *>(r.lo),r.hi-r.lo);
        } else {
            b.binding = compiled.bindings.size();
            compiled.bindings.push_back({reinterpret_cast<const std::uint8_t *>(r.lo),
                reinterpret_cast<std::uint8_t *>(r.lo),r.hi-r.lo});
        }
        r.buffer = meta.buffers.size(); meta.buffers.push_back(b);
    }
    // One serialized scratch destination suffices; live intermediate values
    // reside in the private logical arena and are updated by firmware copies.
    const std::uint32_t scratch_id = meta.buffers.size();
    meta.buffers.push_back({"command-destination","scratch",8,0,next_mutable,3,-1});
    const std::uint32_t empty_id = meta.buffers.size();
    meta.buffers.push_back({"empty-capability","scratch",1048576,0,0xbfe00000ULL,3,-1});
    auto locate = [&](ggml_tensor * t) -> std::pair<std::uint32_t,std::uint64_t> {
        if (!t || !ggml_nbytes(model_root(t)) || !t->data) return {empty_id,t ? t->view_offs : 0};
        const auto p = reinterpret_cast<std::uintptr_t>(t->data);
        for (const auto & r : merged)
            if (p >= r.lo && (p < r.hi || (p == r.hi && !ggml_nbytes(t)))) return {r.buffer,p-r.lo};
        throw std::runtime_error("missing storage for " + std::string(t->name));
    };
    std::vector<npu_command_abi_words> commands;
    std::set<std::uint32_t> publish_buffers;
    for (int gi = 0; gi < ggml_graph_n_nodes(graph); ++gi) {
        auto * node = ggml_graph_node(graph,gi);
        if (!(node->flags & GGML_TENSOR_FLAG_COMPUTE) || npu_is_metadata_op(node->op)) continue;
        const auto found = context->canonical_nodes.find(node);
        if (found == context->canonical_nodes.end()) throw std::runtime_error("canonical binding missing: " + std::string(node->name));
        const auto & binding = found->second;
        npu_model_command mc;
        mc.canonical_id = model_hex(binding.canonical_id); mc.graph_index = binding.graph_node_index;
        mc.name=node->name; mc.op=ggml_op_name(node->op);
        auto identity = npu_canonical_wire_identity(binding);
        npu_exact_command_contract c = {};
        c.abi_valid=1;c.windows_generation_valid=1;c.capability_epoch=1;c.node_count=1;c.dtype=1;
        c.command_flags=identity.command_flags;c.context_id=identity.context_id;
        c.sequence_id=identity.sequence_id;c.producer_id=identity.producer_id;c.user_tag=identity.user_tag;
        c.node_hash_lo=identity.node_hash_lo;c.node_hash_hi=identity.node_hash_hi;
        npu_f32_alu_profile f={};npu_q8_get_rows_profile q={};npu_q8_gemv_profile g={};
        npu_f32_mover_profile m={};npu_sampler_argmax_profile a={};npu_exact_profile e={};
        const bool mf=npu_match_f32_alu_profile(node,&f), mq=npu_match_q8_get_rows_profile(node,&q),
            mg=npu_match_q8_gemv_profile(node,&g), mm=npu_match_f32_mover_profile(node,&m),
            ma=npu_match_sampler_argmax_profile(node,&a), me=npu_match_remaining_profile(node,&e);
        if (unsigned(mf)+mq+mg+mm+ma+me != 1) throw std::runtime_error("ambiguous/unsupported owner "+mc.name);
        ggml_tensor * src0=node->src[0], * src1=node->src[1];
        auto * dstroot=model_root(node);
        std::uint64_t dstbytes=ggml_nbytes(dstroot);
        std::uint64_t dstoff=node->view_src ? node->view_offs : 0;
        bool partial = node->view_src || !ggml_is_contiguous(node);
        if (mf) {
            const bool zero=npu_zero_scale_tensor_descriptor(node);
            const auto elements=zero ? 0 : f.total_elements, groups=(elements+7)/8;
            c.kernel_id=0x514e0010;c.vector_op=f.vector_op;c.local_profile=f.profile_id;
            c.element_count=zero?0:f.element_count;c.outer_count=zero?1:f.outer_count;
            c.src0_stride=zero?0:f.src0.nb[1];c.src1_stride=f.src1_present?f.src1.nb[1]:0;
            c.dst_stride=zero?0:f.dst.nb[1];c.scalar0=f.scalar0;
            if (!f.src1_present) src1=nullptr;
            mc.contract.owner=npu_system_command_owner::f32_alu;
            mc.contract.f32_alu={groups*2,groups*2,groups,groups,elements*(f.src1_present?2U:1U),
                elements,elements*(f.src1_present?8U:4U),elements*4,elements,zero?0U:1U};
            mc.max_cycles=f.cycle_upper_bound; dstbytes=zero?0:f.expected_write_bytes;dstoff=0;partial=false;
        } else if (mq) {
            c.kernel_id=0x514e0001;c.element_count=q.embedding_dim;c.outer_count=q.gathered_rows;
            c.src0_stride=q.table_row_stride;c.src1_stride=q.index_stride;c.dst_stride=q.dst_row_stride;c.scalar0=q.vocabulary_rows;
            mc.contract.owner=npu_system_command_owner::q8_get_rows;
            auto & l=mc.contract.memory;
            l.gmem_reads=q.embedding_dim/32*5+1;l.gmem_read_bytes=l.gmem_reads*8;
            l.gmem_writes=q.embedding_dim;l.gmem_write_bytes=q.dst_bytes;l.vector_elements=q.expected_elements;
            mc.max_cycles=q.cycle_upper_bound;
        } else if (mg) {
            std::swap(src0,src1);
            c.kernel_id=0x514e0002;c.element_count=g.k;c.outer_count=g.command_rows;
            c.src1_stride=g.weight_row_stride;c.dst_stride=g.dst_row_stride;
            mc.contract.owner=npu_system_command_owner::q8_gemv;auto & l=mc.contract.memory;
            const auto activation=locate(src0);
            const auto bytes=g.command_rows ? model_align((activation.second&7)+g.activation_bytes,8):0;
            l.gmem_reads=bytes/8;l.gmem_read_bytes=bytes;l.gmem_writes=g.command_rows;
            l.gmem_write_bytes=g.command_rows*4;l.q8_macs=g.expected_q8_macs;l.vector_elements=g.expected_elements;
            l.q8_groups=((g.command_rows+3)/4)*g.block_count;l.q8_blocks=std::uint64_t(g.command_rows)*g.block_count;
            mc.max_cycles=g.cycle_upper_bound;
            if (!g.command_rows) dstbytes=0;
        } else if (mm) {
            const bool get=m.owner==npu_f32_mover_owner::get_rows;
            c.kernel_id=get?0x514e0003:0x514e0004;c.element_count=m.element_count;
            c.outer_count=get?m.index_count:m.outer_count;c.src0_stride=m.src_row_stride;
            c.src1_stride=m.index_stride;c.src2_stride=m.dst_outer_stride;c.dst_stride=m.dst_row_stride;
            c.scalar0=get?m.source_row_count:m.repeat_count;
            if (!get) src1=nullptr;
            mc.contract.owner=npu_system_command_owner::f32_mover;auto & l=mc.contract.memory;
            l.vector_elements=m.expected_elements;
            const auto eg=(m.element_count+15)/16, ig=get?(m.index_count+15)/16:0;
            const std::uint64_t sg=(get?m.index_count:m.outer_count)*std::uint64_t(eg),
                wg=get?sg:std::uint64_t(m.outer_count)*m.repeat_count*eg,
                rw=get?m.index_count+m.expected_elements:m.expected_read_requests;
            l.mover={ig+sg+wg,ig+sg+wg,ig+sg,wg,rw,m.expected_elements,rw*4,m.expected_elements*4,0,0};
            mc.max_cycles=m.cycle_upper_bound;dstbytes=m.dst_bytes;dstoff=0;partial=false;
        } else if (ma) {
            c.kernel_id=0x514e0030;c.element_count=a.element_count;c.outer_count=1;
            c.src0_stride=4;c.dst_stride=4;src1=nullptr;
            mc.contract.owner=npu_system_command_owner::argmax;auto & l=mc.contract.memory;
            auto loc=locate(src0);l.gmem_read_bytes=model_align((loc.second&7)+a.element_count*4,8);
            l.gmem_reads=l.gmem_read_bytes/8;l.gmem_writes=1;l.gmem_write_bytes=4;l.vector_elements=a.element_count;
            mc.max_cycles=1000000+(l.gmem_reads+1)*32;dstbytes=4;dstoff=0;partial=false;
        } else {
            std::array<std::size_t,3> sizes={};
            for (unsigned j=0;j<e.source_count;++j) sizes[j]=ggml_nbytes(model_root(node->src[j]));
            std::uint32_t slot=0;
            if (e.owner==npu_exact_owner::set_rows) {
                if (!node->src[1] || !node->src[1]->data) throw std::runtime_error("SET_ROWS slot binding absent");
                std::uint64_t raw=0;std::memcpy(&raw,node->src[1]->data,8);
                if (raw>=256) throw std::runtime_error("SET_ROWS slot outside compiled KV capacity");
                slot=raw;partial=true;
            }
            identity.profile_id=e.public_local_profile;
            if (!npu_exact_build_command_contract(&e,&identity,slot,&sizes,dstbytes,&c))
                throw std::runtime_error("exact command lowering rejected "+mc.name);
            mc.contract.owner=npu_system_command_owner::exact;auto & l=mc.contract.memory;
            l.gmem_reads=e.expected_read_requests;l.gmem_writes=e.expected_write_requests;
            l.gmem_read_bytes=e.expected_read_bytes;l.gmem_write_bytes=e.expected_write_bytes;
            l.vector_elements=e.expected_elements;l.q8_macs=e.expected_q8_macs;l.state_updates=e.expected_state_updates;
            mc.max_cycles=e.cycle_upper_bound; if(e.source_count<2) src1=nullptr;
            // Exact empty CPY profiles reserve a floor even when GGML reports zero logical bytes.
            dstbytes=std::max(dstbytes,c.dst_window_size);
        }
        const auto ci=static_cast<std::uint32_t>(commands.size());
        // Re-express every window in BufferId + offset form. Address fields in
        // command.bin remain zero until Host Runtime resolves relocations.
        auto src=[&](ggml_tensor * t,bool first) {
            auto loc=locate(t);const auto & b=meta.buffers[loc.first];
            auto * root=model_root(t);auto rootloc=locate(root);
            const auto size=t?ggml_nbytes(root):0;
            const auto logical=t ? loc.second : 0;
            std::uint64_t window=rootloc.second & ~7ULL;
            std::uint64_t span=t ? model_align(rootloc.second-window+size,8):0;
            if (t && !size && me) span=first?c.src0_window_size:c.src1_window_size;
            if (mf && !c.element_count) span=0;
            if (mg && !c.outer_count) span=0;
            if (mm && m.owner==npu_f32_mover_owner::get_rows && !m.index_count) span=0;
            // A zero-cardinality VIEW can point inside a merged allocation
            // even when its own view_offs is zero. The empty capability must
            // identify that address's beat, not the allocation's first beat.
            if (!span) window = logical & ~7ULL;
            if (t) {
                meta.relocations.push_back({ci,first?10U:11U,loc.first,logical});
                meta.relocations.push_back({ci,first?23U:26U,loc.first,window});
            }
            if(first){c.src0_iova=0;c.src0_window_base=0;c.src0_window_size=span;c.src0_window_perm=t?1:0;}
            else {c.src1_iova=0;c.src1_window_base=0;c.src1_window_size=span;c.src1_window_perm=(t || me || mm)?1:0;}
            (void)b;
        };
        src(src0,true);src(src1,false);
        meta.buffers[scratch_id].bytes=std::max(meta.buffers[scratch_id].bytes,model_align(dstbytes,8));
        c.dst_iova=0;c.dst_window_base=0;c.dst_window_size=model_align(dstbytes,8);c.dst_window_perm=2;
        meta.relocations.push_back({ci,13,scratch_id,dstoff});
        meta.relocations.push_back({ci,28,scratch_id,0});
        if(c.src2_iova){c.src2_iova=0;meta.relocations.push_back({ci,12,scratch_id,dstoff});}
        const auto rootloc=locate(dstroot);
        const bool writes = mf ? mc.contract.f32_alu.write_bytes != 0 :
            mm ? mc.contract.memory.mover.write_bytes != 0 :
                 mc.contract.memory.gmem_write_bytes != 0;
        bool direct = writes && ggml_nbytes(dstroot) != 0;
        const auto target = meta.buffers[rootloc.first].base + rootloc.second;
        const auto target_end = target + dstbytes;
        // The entire dispatch arena is private. A disjoint destination is
        // already an isolated NPU destination and needs no shadow publication
        // between commands. Conservatively compare complete source windows.
        for (const auto & r : meta.relocations) if (r.command == ci &&
                (r.word == 23 || r.word == 26)) {
            const auto lo = meta.buffers[r.buffer].base + r.addend;
            const auto size = r.word == 23 ? c.src0_window_size : c.src1_window_size;
            if (size && target < lo + size && lo < target_end) direct = false;
        }
        if (direct) {
            for (auto & r : meta.relocations) if (r.command == ci &&
                    (r.word == 13 || r.word == 28 || r.word == 12)) {
                r.buffer = rootloc.first; r.addend += rootloc.second;
            }
        }
        if (writes && dstbytes && ggml_nbytes(dstroot)) {
            const auto copybytes=std::min<std::uint64_t>(dstbytes,ggml_nbytes(dstroot));
            if (!direct) {
                if(partial) meta.copies.push_back({ci,0,rootloc.first,scratch_id,rootloc.second,0,copybytes});
                meta.copies.push_back({ci,1,scratch_id,rootloc.first,0,rootloc.second,copybytes});
            }
            if (dstroot->op==GGML_OP_NONE || (node->flags&GGML_TENSOR_FLAG_OUTPUT))
                publish_buffers.insert(rootloc.first);
        }
        npu_command_abi_words w={};
        if(!npu_command_abi_pack_words(&c,&w)) throw std::runtime_error("descriptor pack rejected "+mc.name);
        mc.contract.identity={c.kernel_id,c.command_flags,c.context_id,c.sequence_id,c.producer_id,c.user_tag,
            c.node_count,c.node_hash_lo,c.node_hash_hi,c.local_profile};
        mc.contract.max_cycles=mc.max_cycles;
        commands.push_back(w);meta.commands.push_back(mc);
    }
    if(commands.size()!=context->canonical_expected_nodes)
        throw std::runtime_error("compiled subgraph does not cover the entire strict dispatch");
    if(meta.buffers[scratch_id].base+meta.buffers[scratch_id].bytes>=meta.buffers[empty_id].base)
        throw std::runtime_error("mutable arena exceeds firmware transport aperture");
    for(auto id:publish_buffers) {
        const auto & b=meta.buffers[id];
        if(b.binding<0 || b.permissions!=3) throw std::runtime_error("publication targets a weight");
        meta.publications.push_back({id,static_cast<std::uint32_t>(b.binding),0,compiled.bindings[b.binding].bytes});
    }
    const auto image=npu_model_command_image(commands);
    meta.command_sha256=npu_model_hash(image.data(),image.size());
    meta.weights_sha256=npu_model_hash(weights.data(),weights.size());
    const std::string metadata=npu_model_json(meta).dump(2)+"\n";
    std::filesystem::create_directories(directory);
    model_write(directory+"/command.bin",image.data(),image.size());
    model_write(directory+"/weights.bin",weights.data(),weights.size());
    model_write(directory+"/metadata.json",metadata.data(),metadata.size());
    compiled.metadata_sha256=npu_model_hash(metadata.data(),metadata.size());
    std::fprintf(stderr,"[NPU-COMPILER][MODEL] commands=%zu buffers=%zu weights_bytes=%zu copies=%zu artifact=%s\n",
        commands.size(),meta.buffers.size(),weights.size(),meta.copies.size(),directory.c_str());
    return compiled;
}
