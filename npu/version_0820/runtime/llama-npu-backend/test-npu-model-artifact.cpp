#include "npu-model-artifact.h"
#include "npu-verilator-runner.h"
#include <array>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <stdexcept>

namespace {
void require(bool value, const std::string & message) {
    if (!value) throw std::runtime_error(message);
}
void write(const std::string & path, const void * data, std::size_t bytes) {
    std::ofstream stream(path, std::ios::binary | std::ios::trunc);
    require(bool(stream) && bool(stream.write(static_cast<const char *>(data), bytes)), "write " + path);
}
void fill(std::array<std::uint8_t,64> & bytes, std::uint32_t value) {
    for (unsigned i=0;i<16;++i) for(unsigned j=0;j<4;++j) bytes[i*4+j]=value>>(j*8);
}
bool all_words(const std::array<std::uint8_t,64> & bytes,std::uint32_t value) {
    std::array<std::uint8_t,64> expected;fill(expected,value);return bytes==expected;
}
struct fixture {
    npu_model_metadata meta;
    std::vector<npu_command_abi_words> commands;
    std::array<std::uint8_t,64> weights;
    fixture() {
        meta.buffers = {
            {"input","binding",64,0,0xa0400000,1,0},
            {"weight","weight",64,0,0x100000000,1,-1},
            {"logical-output","binding",64,0,0xa0401000,3,1},
            {"command-destination","scratch",64,0,0xa0402000,3,-1}};
        meta.publications={{2,1,0,64}};
        fill(weights,0x40000000U); // raw F32 2.0
        for(unsigned i=0;i<2;++i) {
            npu_exact_command_contract c={};
            c.abi_valid=1;c.windows_generation_valid=1;c.kernel_id=0x514e0010;
            c.command_flags=0x11;c.context_id=7;c.capability_epoch=1;c.node_count=1;
            c.sequence_id=i+1;c.producer_id=0x2001+i;c.user_tag=0x3001+i;
            c.node_hash_lo=i+1;c.node_hash_hi=0x1234;c.vector_op=1;c.dtype=1;
            c.element_count=16;c.outer_count=1;c.src0_stride=64;c.src1_stride=64;c.dst_stride=64;
            c.src0_window_size=64;c.src1_window_size=64;c.dst_window_size=64;
            c.src0_window_perm=1;c.src1_window_perm=1;c.dst_window_perm=2;
            npu_command_abi_words words={};
            require(npu_command_abi_pack_words(&c,&words),"pack fixture");
            commands.push_back(words);
            npu_model_command command;
            command.canonical_id=std::string(63,'0')+char('1'+i);
            command.name="test-add-"+std::to_string(i);command.op="ADD";
            command.graph_index=i;command.max_cycles=100000;
            command.contract.identity={c.kernel_id,c.command_flags,c.context_id,c.sequence_id,
                c.producer_id,c.user_tag,c.node_count,c.node_hash_lo,c.node_hash_hi,c.local_profile};
            command.contract.f32_alu={4,4,2,2,32,16,128,64,16,1};
            command.contract.max_cycles=100000;
            meta.commands.push_back(command);
            for(auto word:{10U,23U}) meta.relocations.push_back({i,word,i?2U:0U,0});
            for(auto word:{11U,26U}) meta.relocations.push_back({i,word,1,0});
            for(auto word:{13U,28U}) meta.relocations.push_back({i,word,3,0});
            if(i)meta.copies.push_back({i,0,2,3,0,0,64});
            meta.copies.push_back({i,1,3,2,0,0,64});
        }
    }
    std::string save(const std::string & dir) {
        auto image=npu_model_command_image(commands);
        meta.command_sha256=npu_model_hash(image.data(),image.size());
        meta.weights_sha256=npu_model_hash(weights.data(),weights.size());
        auto metadata=npu_model_json(meta).dump(2)+"\n";
        write(dir+"/command.bin",image.data(),image.size());
        write(dir+"/weights.bin",weights.data(),weights.size());
        write(dir+"/metadata.json",metadata.data(),metadata.size());
        return npu_model_hash(metadata.data(),metadata.size());
    }
};
}
int main(int argc,char ** argv) {
    try {
        require(argc==2,"usage: test-npu-model-artifact TEMP_PARENT");
        std::string pattern=std::string(argv[1])+"/npu-model-test-XXXXXX";
        require(mkdtemp(pattern.data())!=nullptr,"create isolated artifact directory");
        fixture original;
        std::array<std::uint8_t,64> input,output;
        fill(input,0x3f800000U);output.fill(0xa5);
        std::vector<npu_model_binding> bindings={
            {input.data(),nullptr,64},{output.data(),output.data(),64}};
        npu_system_session session;
        require(session.ready(),"boot fixed firmware: "+session.failure());
        npu_system_dispatch_result result={};
        std::string error;
        auto hash=original.save(pattern);
        require(npu_model_execute(pattern,hash,bindings,session,1,&result,&error),error);
        require(all_words(output,0x40a00000U),"DMA dependency failed: expected raw F32 5.0");
        require(result.completed==2 && result.delta.dma_starts==3 &&
                result.delta.dma_completions==3 && result.delta.dma_write_bytes==192,
                "firmware pre/post DMA completion ledger");
        fill(input,0);output.fill(0xa5);
        require(npu_model_execute(pattern,hash,bindings,session,2,&result,&error),error);
        require(all_words(output,0x40800000U),"generation 2 expected raw F32 4.0");
        require(session.status().constructor_count==1 && session.status().reset_release_count==1 &&
                session.status().boot_count==1,"session restarted");
        output.fill(0xa5);
        const auto sentinel=output;
        auto reject=[&](fixture & changed,const char * detail) {
            const auto changed_hash=changed.save(pattern);result={};error.clear();
            require(!npu_model_execute(pattern,changed_hash,bindings,session,3,&result,&error),detail);
            require(output==sentinel && session.status().last_generation==2,
                    std::string("preflight published or consumed generation: ")+detail);
        };
        fixture changed=original;
        changed.meta.commands.resize(1);
        changed.meta.relocations.erase(changed.meta.relocations.begin()+6,changed.meta.relocations.end());
        changed.meta.copies.resize(1);
        reject(changed,"extra command records were silently ignored");
        changed=original;
        changed.meta.relocations[0].word=9;reject(changed,"illegal relocation accepted");
        changed=original;changed.meta.buffers[3].base=changed.meta.buffers[2].base;
        reject(changed,"overlapping capabilities accepted");
        changed=original;changed.meta.copies[0].dst_buffer=1;
        reject(changed,"DMA wrote immutable weight");
        changed=original;changed.meta.publications[0].bytes=65;
        reject(changed,"publication escaped caller");
        hash=original.save(pattern);
        require(!npu_model_execute(pattern,std::string(64,'f'),bindings,session,3,&result,&error),
                "wrong metadata identity accepted");
        const std::uint8_t corrupt=0xff;
        write(pattern+"/weights.bin",&corrupt,1);
        require(!npu_model_execute(pattern,hash,bindings,session,3,&result,&error),"corrupt weights accepted");
        hash=original.save(pattern);write(pattern+"/command.bin",&corrupt,1);
        require(!npu_model_execute(pattern,hash,bindings,session,3,&result,&error),"corrupt command accepted");
        require(output==sentinel && session.status().last_generation==2,"integrity failure published");

        // The first command and its post-DMA complete; command 2 then traps.
        // Even that successfully copied private prefix must remain unpublished.
        changed=original;
        changed.commands[1][0]=(changed.commands[1][0]&0xffffffff00000000ULL)|0xdeadbeefU;
        changed.meta.commands[1].contract.identity.kernel_id=0xdeadbeefU;
        changed.meta.commands[1].contract.expected_outcome=npu_system_expected_outcome::recoverable_npu_fault;
        changed.meta.commands[1].contract.expected_npu_error_code=14;
        changed.meta.commands[1].contract.f32_alu={};
        hash=changed.save(pattern);result={};error.clear();
        require(!npu_model_execute(pattern,hash,bindings,session,3,&result,&error),"fault returned success");
        require(output==sentinel && !session.fatal() && result.completed==2 &&
                result.fault_cause==24 && result.fault_pc!=0 &&
                result.delta.dma_completions==2 && result.delta.launch_accepts==2,
                "precise fault or atomic publication lost: "+error);
        hash=original.save(pattern);result={};error.clear();
        require(npu_model_execute(pattern,hash,bindings,session,4,&result,&error),error);
        require(all_words(output,0x40800000U) && result.boot_count==1,"recovery restarted or wrong result");
        // Identical pre/post triples are distinct transfers owned by the
        // command phase. Address matching must not confuse their identities.
        changed=original;
        changed.meta.buffers.push_back({"dma-sink","scratch",64,0,0xa0403000,3,-1});
        changed.meta.copies[0]={0,1,0,4,0,0,64};
        changed.meta.copies.push_back({0,0,0,4,0,0,64});
        for(auto & r:changed.meta.relocations)
            if(r.command==1 && (r.word==10 || r.word==23))r.buffer=0;
        hash=changed.save(pattern);result={};error.clear();
        require(npu_model_execute(pattern,hash,bindings,session,5,&result,&error),error);
        require(all_words(output,0x40000000U) && result.delta.dma_completions==4 &&
                result.delta.dma_write_bytes==256 && result.boot_count==1,
                "identical pre/post DMA phase ownership");
        // A steady graph's empty SCALE source lies inside a merged state
        // allocation. A zero span still carries an exact address capability.
        changed=original;
        npu_exact_command_contract empty={};
        require(npu_command_abi_unpack_words(&changed.commands[0],&empty),"unpack empty SCALE");
        empty.local_profile=18;empty.vector_op=4;empty.element_count=0;empty.outer_count=1;
        empty.src0_stride=0;empty.src1_stride=0;empty.dst_stride=0;
        empty.src0_window_size=0;empty.src1_window_size=0;empty.dst_window_size=0;
        empty.src1_window_perm=0;
        changed.commands.resize(1);
        require(npu_command_abi_pack_words(&empty,&changed.commands[0]),"pack empty SCALE");
        changed.meta.commands.resize(1);
        changed.meta.commands[0].contract.identity.local_profile=18;
        changed.meta.commands[0].contract.f32_alu={};
        changed.meta.copies.clear();changed.meta.publications.clear();
        changed.meta.relocations={{0,10,0,32},{0,23,0,0},{0,13,3,0},{0,28,3,0}};
        output.fill(0xa5);
        hash=changed.save(pattern);result={};error.clear();
        require(!npu_model_execute(pattern,hash,bindings,session,6,&result,&error) &&
                error.find("address is outside its declared window")!=std::string::npos &&
                session.status().last_generation==5 && output==sentinel,
                "empty SCALE accepted an unrelated root capability");
        changed.meta.relocations[1].addend=32;
        hash=changed.save(pattern);result={};error.clear();
        require(npu_model_execute(pattern,hash,bindings,session,6,&result,&error),error);
        require(result.completed==1 && result.delta.launch_accepts==1 &&
                result.delta.macro_terminals==1 && result.delta.dma_starts==0 &&
                result.delta.portal_read_bytes==0 && result.delta.portal_write_bytes==0 &&
                result.boot_count==1 && output==sentinel,
                "empty interior SCALE touched tensor bytes or restarted");
        std::cout<<"[NPU-MODEL-ARTIFACT][PASS] generations=6 boots=1 dma_dependency=1 empty_view=1 "
            <<"tamper_reject=1 prefix_atomic=1 precise_fault=1 recover_without_reset=1 artifacts="<<pattern<<"\n";
        return 0;
    } catch(const std::exception & e) {
        std::cerr<<"[NPU-MODEL-ARTIFACT][FAIL] "<<e.what()<<"\n";return 1;
    }
}
