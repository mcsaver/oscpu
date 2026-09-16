#include "npu-model-artifact.h"
#include <array>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <stdexcept>

static void require(bool condition,const std::string & reason) {
    if(!condition)throw std::runtime_error(reason);
}
static std::vector<std::uint8_t> read(const std::string & path) {
    std::ifstream stream(path,std::ios::binary|std::ios::ate);
    require(bool(stream),"open "+path);
    auto bytes=stream.tellg();require(bytes>=0 && bytes<32*1024*1024,"file limit");
    std::vector<std::uint8_t> result(static_cast<std::size_t>(bytes));
    stream.seekg(0);require(bool(stream.read(reinterpret_cast<char *>(result.data()),result.size())),"read "+path);
    return result;
}
static void write(const std::string & path,const void * bytes,std::size_t count) {
    std::ofstream stream(path,std::ios::binary|std::ios::trunc);
    require(bool(stream) && (!count || bool(stream.write(static_cast<const char *>(bytes),count))),"write "+path);
}
static void word(std::vector<std::uint8_t> & bytes,std::size_t index,std::uint32_t raw) {
    for(unsigned j=0;j<4;++j)bytes.at(index*4+j)=raw>>(8*j);
}
int main(int argc,char ** argv) {
    try {
        require(argc==3,"usage: test-npu-model-argmax MODEL_ARTIFACT TEMP_PARENT");
        const auto metadata=read(std::string(argv[1])+"/metadata.json");
        const auto model=npu_model_json::parse(metadata).get<npu_model_metadata>();
        require(model.commands.size()==1080 && model.commands.back().contract.owner==npu_system_command_owner::argmax,
                "expected the real model compiler's final ARGMAX command");
        npu_command_abi_words words={};
        const auto full_image=read(std::string(argv[1])+"/command.bin");
        require(npu_compiled_bundle_decode_record(full_image,1079,&words),"decode original model command");
        require(words[15]==248320 && words[24]==993280 && words[29]==8,"frozen ARGMAX shape changed");
        npu_model_metadata test;
        test.commands={model.commands.back()};
        test.buffers={{"input","binding",993280,0,0xa0400000,1,0},
                      {"output","binding",8,0,0xa0800000,3,1}};
        test.relocations={{0,10,0,0},{0,23,0,0},{0,13,1,0},{0,28,1,0}};
        test.publications={{1,1,0,4}};
        auto image=npu_model_command_image({words});
        test.command_sha256=npu_model_hash(image.data(),image.size());
        test.weights_sha256=npu_model_hash(nullptr,0);
        auto text=npu_model_json(test).dump(2)+"\n";
        std::string directory=std::string(argv[2])+"/model-argmax-test-XXXXXX";
        require(mkdtemp(directory.data())!=nullptr,"isolated test directory");
        write(directory+"/command.bin",image.data(),image.size());
        write(directory+"/weights.bin",nullptr,0);
        write(directory+"/metadata.json",text.data(),text.size());
        std::vector<std::uint8_t> input(993280),output(8,0xa5);
        for(unsigned i=0;i<248320;++i)word(input,i,0x3f800000); // raw F32 1.0
        word(input,100003,0x40000000);word(input,248319,0x40000000); // pinned GGML updates on equality: last index wins
        std::vector<npu_model_binding> bindings={{input.data(),nullptr,input.size()},
                                                 {output.data(),output.data(),output.size()}};
        npu_system_session session;
        require(session.ready(),session.failure());
        npu_system_dispatch_result result={};std::string error;
        require(npu_model_execute(directory,npu_model_hash(text.data(),text.size()),bindings,session,1,&result,&error),error);
        const std::uint32_t selected=output[0]|std::uint32_t(output[1])<<8|std::uint32_t(output[2])<<16|std::uint32_t(output[3])<<24;
        require(selected==248319,"ARGMAX tie-last selected wrong index: "+std::to_string(selected));
        require(output[4]==0xa5 && output[5]==0xa5 && output[6]==0xa5 && output[7]==0xa5,"ARGMAX publication width");
        require(result.completed==1 && result.delta.gmem_read_bytes==993280 &&
                result.delta.gmem_write_bytes==4 && result.delta.vector_elements==248320 &&
                result.delta.launch_accepts==1 && result.delta.macro_terminals==1,
                "ARGMAX actual memory/terminal ledger");
        word(input,248319,0x3f800000); // only the odd-lane middle maximum remains
        result={};error.clear();
        require(npu_model_execute(directory,npu_model_hash(text.data(),text.size()),bindings,session,2,&result,&error),error);
        const std::uint32_t unique=output[0]|std::uint32_t(output[1])<<8|std::uint32_t(output[2])<<16|std::uint32_t(output[3])<<24;
        require(unique==100003 && result.boot_count==1,"ARGMAX unique maximum or persistent boot");
        std::cout<<"[NPU-MODEL-ARGMAX][PASS] compiler_command=1079 elements=248320 tie_last_index=248319 unique_index=100003 boots=1 "
            <<"cpu_tensor_arithmetic=0 cycles="<<result.delta.cycles<<"\n";
        return 0;
    } catch(const std::exception & error) {
        std::cerr<<"[NPU-MODEL-ARGMAX][FAIL] "<<error.what()<<"\n";return 1;
    }
}
