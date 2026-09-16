// Raw memory transport for compiled multi-owner command streams.
// Included inside npu_system_session::impl. No tensor arithmetic is permitted.
struct memory_response {
    bool occupied = false;
    std::size_t command = kNoCommand;
    std::uint64_t data = 0;
    std::uint16_t mask = 0;
    std::array<std::uint32_t, 34> blocks = {};
    std::array<std::uint32_t, 16> words = {};
};
memory_response gmem_response_ = {}, q8_response_ = {}, mover_response_ = {};
memory_response next_gmem_ = {}, next_q8_ = {}, next_mover_ = {};

bool memory_fail(const std::string & message) {
    return set_fatal(npu_system_session_error::portal_protocol,
                     "command[" + std::to_string(active_command_ < contracts_.size() ? active_command_ :
                         mailbox32(NPU_SERVICE_MB_COMPLETED_OFFSET)) + "] " + message);
}

bool command_range(std::uint64_t address, std::size_t size, bool write) {
    if (active_command_ >= descriptors_.size()) return false;
    const auto & w = descriptors_[active_command_];
    auto contains = [&](std::size_t base_word) {
        return w[base_word + 1] <= SIZE_MAX &&
            range_contains(w[base_word], static_cast<std::size_t>(w[base_word + 1]),
                           address, size);
    };
    if (write) return contains(28);
    if (contains(23) || contains(26)) return true;
    // SET_ROWS is the sole public owner allowed to read its private old dst.
    return contracts_[active_command_].owner == npu_system_command_owner::exact &&
           w[12] != 0 && contains(28);
}

bool memory_read(std::uint64_t address, std::size_t size, std::uint8_t * dst) {
    auto * b = find_buffer(address, size, 1U);
    if (!b || !dst || !command_range(address, size, false))
        return memory_fail("read escaped the active descriptor capability");
    std::copy_n(b->bytes->data() + (address - b->base), size, dst);
    b->activity.read_words += (size + 3) / 4;
    if (b->written) b->activity.reads_after_write += (size + 3) / 4;
    return true;
}

bool memory_write(std::uint64_t address, std::uint8_t value) {
    auto * b = find_buffer(address, 1, 2U);
    if (!b || !command_range(address, 1, true))
        return memory_fail("write escaped the active descriptor capability");
    (*b->bytes)[address - b->base] = value;
    b->written = true;
    return true;
}

bool verify_memory_owner(const command_observed & got,
                         const npu_system_memory_contract & expected) {
    const auto & m = got.mover;
    const auto & e = expected.mover;
    if (got.gmem_reads != expected.gmem_reads ||
        got.gmem_writes != expected.gmem_writes ||
        got.gmem_responses != got.gmem_reads + got.gmem_writes ||
        got.gmem_read_bytes != expected.gmem_reads * 8U ||
        got.gmem_write_bytes != expected.gmem_write_bytes ||
        got.q8_groups != expected.q8_groups || got.q8_responses != got.q8_groups ||
        got.q8_blocks != expected.q8_blocks ||
        m.request_groups != e.request_groups || m.response_groups != e.response_groups ||
        m.read_groups != e.read_groups || m.write_groups != e.write_groups ||
        m.input_words != e.input_words || m.output_words != e.output_words ||
        m.read_bytes != e.read_bytes || m.write_bytes != e.write_bytes) {
        return memory_fail("GMEM/Q8/mover traffic differs from compiler ledger");
    }
    return true;
}

bool tick_memory_before_edge() {
    if (!tick_dma_before_edge()) return false;
    next_gmem_ = gmem_response_;
    next_q8_ = q8_response_;
    next_mover_ = mover_response_;
    if (gmem_response_.occupied && top_->gmem_rsp_ready_o) {
        ++observed_[gmem_response_.command].gmem_responses; next_gmem_ = {};
    }
    if (q8_response_.occupied && top_->q8_portal_rsp_ready_o) {
        ++observed_[q8_response_.command].q8_responses; next_q8_ = {};
    }
    if (mover_response_.occupied && top_->f32_mover_portal_rsp_ready_o) {
        ++observed_[mover_response_.command].mover.response_groups; next_mover_ = {};
    }
    const bool g = top_->gmem_req_valid_o && top_->gmem_req_ready_i;
    const bool q = top_->q8_portal_req_valid_o && top_->q8_portal_req_ready_i;
    const bool m = top_->f32_mover_portal_req_valid_o && top_->f32_mover_portal_req_ready_i;
    if (!(g || q || m)) return true;
    if (active_command_ >= contracts_.size()) return memory_fail("request without owner");
    auto & observed = observed_[active_command_];
    const auto owner = contracts_[active_command_].owner;
    if (g) {
        if (owner == npu_system_command_owner::f32_alu ||
            owner == npu_system_command_owner::f32_mover)
            return memory_fail("owner unexpectedly requested GMEM");
        const auto addr = top_->gmem_req_addr_o;
        if ((addr & 7U) != 0) return memory_fail("unaligned GMEM beat");
        next_gmem_ = {}; next_gmem_.occupied = true; next_gmem_.command = active_command_;
        if (top_->gmem_req_write_o) {
            const unsigned strobe = top_->gmem_req_wstrb_o;
            if (!strobe) return memory_fail("empty GMEM write strobe");
            ++observed.gmem_writes;
            for (unsigned byte = 0; byte < 8; ++byte) if (strobe & (1U << byte)) {
                if (!memory_write(addr + byte, top_->gmem_req_wdata_o >> (8 * byte))) return false;
                ++observed.gmem_write_bytes; ++counters_.gmem_write_bytes;
            }
        } else {
            if (top_->gmem_req_wstrb_o) return memory_fail("read carried write strobe");
            std::array<std::uint8_t, 8> raw = {};
            if (!memory_read(addr, 8, raw.data())) return false;
            next_gmem_.data = load_le64(raw.data());
            ++observed.gmem_reads; observed.gmem_read_bytes += 8;
            counters_.gmem_read_bytes += 8;
        }
    }
    if (q) {
        if (owner != npu_system_command_owner::q8_gemv)
            return memory_fail("owner unexpectedly requested Q8 portal");
        next_q8_ = {}; next_q8_.occupied = true; next_q8_.command = active_command_;
        next_q8_.mask = top_->q8_portal_req_mask_o;
        if (!next_q8_.mask || (next_q8_.mask & ~15U)) return memory_fail("invalid Q8 mask");
        std::array<std::uint8_t, 136> raw = {};
        for (unsigned lane = 0; lane < 4; ++lane) {
            const auto addr = portal_lane_address(top_->q8_portal_req_addr_o, lane);
            if (!(next_q8_.mask & (1U << lane))) {
                if (addr) return memory_fail("inactive Q8 lane carried address");
                continue;
            }
            if (!memory_read(addr, 34, raw.data() + lane * 34)) return false;
            ++observed.q8_blocks; ++counters_.q8_blocks;
        }
        for (unsigned word = 0; word < 34; ++word)
            next_q8_.blocks[word] = load_le32(raw.data() + word * 4);
        ++observed.q8_groups;
    }
    if (m) {
        if (owner != npu_system_command_owner::f32_mover)
            return memory_fail("owner unexpectedly requested mover portal");
        next_mover_ = {}; next_mover_.occupied = true; next_mover_.command = active_command_;
        next_mover_.mask = top_->f32_mover_portal_req_mask_o;
        if (!next_mover_.mask) return memory_fail("empty mover mask");
        const bool write = top_->f32_mover_portal_req_write_o;
        auto & ledger = observed.mover;
        ++ledger.request_groups;
        if (write) ++ledger.write_groups; else ++ledger.read_groups;
        for (unsigned lane = 0; lane < 16; ++lane) {
            const auto addr = portal_lane_address(top_->f32_mover_portal_req_addr_o, lane);
            const auto data = top_->f32_mover_portal_req_wdata_o[lane];
            if (!(next_mover_.mask & (1U << lane))) {
                if (addr || data) return memory_fail("inactive mover lane carried payload");
                continue;
            }
            if (addr & 3U) return memory_fail("unaligned mover word");
            if (write) {
                for (unsigned byte = 0; byte < 4; ++byte)
                    if (!memory_write(addr + byte, data >> (8 * byte))) return false;
                ++ledger.output_words; ledger.write_bytes += 4; counters_.mover_write_bytes += 4;
            } else {
                if (data) return memory_fail("mover read carried write data");
                std::array<std::uint8_t, 4> raw = {};
                if (!memory_read(addr, 4, raw.data())) return false;
                next_mover_.words[lane] = load_le32(raw.data());
                ++ledger.input_words; ledger.read_bytes += 4; counters_.mover_read_bytes += 4;
            }
        }
    }
    return true;
}

void memory_after_edge() {
    dma_after_edge();
    gmem_response_ = next_gmem_; q8_response_ = next_q8_; mover_response_ = next_mover_;
}

void drive_memory_inputs() {
    drive_dma_inputs();
    const bool active = top_->rst == 0 && dispatch_active_;
    top_->gmem_req_ready_i = active && !gmem_response_.occupied;
    top_->gmem_rsp_valid_i = gmem_response_.occupied;
    top_->gmem_rsp_rdata_i = gmem_response_.data;
    top_->gmem_rsp_error_i = 0;
    top_->q8_portal_req_ready_i = active && !q8_response_.occupied;
    top_->q8_portal_rsp_valid_i = q8_response_.occupied;
    top_->q8_portal_rsp_mask_i = q8_response_.mask;
    top_->q8_portal_rsp_error_i = 0;
    for (unsigned i = 0; i < 34; ++i) top_->q8_portal_rsp_blocks_i[i] = q8_response_.blocks[i];
    top_->f32_mover_portal_req_ready_i = active && !mover_response_.occupied;
    top_->f32_mover_portal_rsp_valid_i = mover_response_.occupied;
    top_->f32_mover_portal_rsp_mask_i = mover_response_.mask;
    top_->f32_mover_portal_rsp_error_i = 0;
    for (unsigned i = 0; i < 16; ++i) top_->f32_mover_portal_rsp_rdata_i[i] = mover_response_.words[i];
}

// MMIO registers are a bus bridge, not a copy implementation. The RTL DMA
// alone generates every memory beat after the firmware's committed START.
std::uint64_t dma_src_ = 0, dma_dst_ = 0, dma_bytes_ = 0, dma_written_ = 0;
bool dma_pending_ = false, dma_inflight_ = false;
memory_response dma_response_ = {}, next_dma_response_ = {};
std::vector<std::uint8_t> dma_issued_;

bool dma_mmio_write(std::uint64_t address, std::uint64_t value, std::uint64_t mask) {
    if (mask != 255 || (address & 7) || dma_pending_ || dma_inflight_)
        return memory_fail("invalid or busy DMA MMIO write");
    const auto reg = address - NPU_SERVICE_DMA_MMIO_ADDRESS;
    if (reg == 0) dma_src_ = value;
    else if (reg == 8) dma_dst_ = value;
    else if (reg == 16) dma_bytes_ = value;
    else if (reg == 24) {
        const auto index = mailbox32(NPU_SERVICE_MB_COMPLETED_OFFSET);
        if (value != 1 || !dma_bytes_ || index >= copies_.size() || active_command_ != kNoCommand)
            return memory_fail("DMA START has no firmware copy owner");
        // Phase is owned by the observed command lifecycle, not inferred
        // from address equality (pre/post may legitimately be identical).
        const auto launched = counters_.launch_accepts - generation_launch_base_;
        const auto terminal = counters_.macro_terminals - generation_terminal_base_;
        const auto configs = counters_.config_accepts - generation_config_base_;
        const int phase = launched == index && terminal == index &&
                configs == index * NPU_COMMAND_ABI_WORD_COUNT ? 0 :
            launched == index + 1 && terminal == index + 1 &&
                configs == (index + 1) * NPU_COMMAND_ABI_WORD_COUNT &&
                !fault_terminal_seen_ ? 1 : -1;
        if (phase < 0) return memory_fail("DMA START violates pre/post command order");
        const auto & c = phase ? copies_[index].after : copies_[index].before;
        if (c.src != dma_src_ || c.dst != dma_dst_ || c.bytes != dma_bytes_ ||
                (dma_issued_[index] & (1U << phase)))
            return memory_fail("DMA START differs from or repeats compiler copy");
        dma_issued_[index] |= 1U << phase;
        dma_pending_=true;dma_inflight_=true;dma_written_=0;
        ++counters_.dma_starts;
    } else return memory_fail("unknown DMA MMIO register");
    return true;
}
std::uint64_t dma_status() const {
    if (dma_pending_) return 1;
    return (top_->service_dma_busy_o ? 1U:0U) | (top_->service_dma_done_o ? 2U:0U) |
           (top_->service_dma_error_o ? 4U:0U);
}
bool tick_dma_before_edge() {
    next_dma_response_ = dma_response_;
    if (dma_response_.occupied && top_->service_dma_rsp_ready_o) next_dma_response_={};
    if (!top_->service_dma_req_valid_o || !top_->service_dma_req_ready_i) return true;
    if (!dma_inflight_ || active_command_ != kNoCommand ||
        top_->gmem_req_valid_o || top_->q8_portal_req_valid_o ||
        top_->f32_alu_portal_req_valid_o || top_->f32_mover_portal_req_valid_o)
        return memory_fail("DMA and NPU memory ownership overlapped");
    const auto addr=top_->service_dma_req_addr_o;
    if (addr&7) return memory_fail("DMA published unaligned beat");
    next_dma_response_={};next_dma_response_.occupied=true;
    if(top_->service_dma_req_write_o) {
        const auto mask=top_->service_dma_req_wstrb_o;
        if(!mask) return memory_fail("DMA write has empty strobe");
        for(unsigned b=0;b<8;++b) if(mask&(1U<<b)) {
            auto * buffer=find_buffer(addr+b,1,2);
            if(!buffer || !range_contains(dma_dst_,dma_bytes_,addr+b,1))
                return memory_fail("DMA write escaped compiled destination");
            (*buffer->bytes)[addr+b-buffer->base]=top_->service_dma_req_wdata_o>>(8*b);
            buffer->written=true;++dma_written_;++counters_.dma_write_bytes;
        }
    } else {
        const auto base=dma_src_&~7ULL, end=(dma_src_+dma_bytes_+7)&~7ULL;
        auto * buffer=find_buffer(addr,8,1);
        if(!buffer || !range_contains(base,end-base,addr,8) || top_->service_dma_req_wstrb_o)
            return memory_fail("DMA read escaped compiled source");
        next_dma_response_.data=load_le64(buffer->bytes->data()+addr-buffer->base);
        counters_.dma_read_bytes+=8;
    }
    return true;
}
void dma_after_edge() {
    dma_response_=next_dma_response_;
    if(top_->service_dma_start_i && (top_->service_dma_busy_o || top_->service_dma_done_o))
        dma_pending_=false;
    if(dma_inflight_ && !dma_pending_ && top_->service_dma_done_o) {
        if(top_->service_dma_error_o || dma_written_!=dma_bytes_ || dma_response_.occupied) {
            memory_fail("RTL DMA completion/error/byte ledger mismatch");
        } else ++counters_.dma_completions;
        dma_inflight_=false;
    }
}
void drive_dma_inputs() {
    top_->service_dma_start_i=dma_pending_;
    top_->service_dma_src_i=dma_src_;top_->service_dma_dst_i=dma_dst_;top_->service_dma_bytes_i=dma_bytes_;
    top_->service_dma_req_ready_i=dispatch_active_ && !dma_response_.occupied;
    top_->service_dma_rsp_valid_i=dma_response_.occupied;
    top_->service_dma_rsp_rdata_i=dma_response_.data;top_->service_dma_rsp_error_i=0;
}
