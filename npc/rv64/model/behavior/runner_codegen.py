"""Text stimulus driver for generated behaviors; host oracle or explicit CUDA run."""
from cuda_codegen import CudaEmitter

def runner_source(model,header="generated.hpp"):
    emitter=CudaEmitter(model)
    lines=['#include "'+header+'"','#include <iostream>','#include <iomanip>',
           '#include <vector>','#include <stdexcept>','#include <string>',
           'using namespace r64_generated;',
           'template<int W> bool read_value(Bits<W>& v) {',
           '    for(auto& word:v.v) if(!(std::cin>>std::hex>>word))return false;',
           '    auto original=v;trim(v);',
           '    if(!truth(equal(original,v)))throw std::runtime_error("input exceeds width");',
           '    return true;','}',
           'template<int W> void print_value(const Bits<W>& v) {',
           "    for(int i=v.words-1;i>=0;--i)std::cout<<std::hex<<std::setfill('0')<<std::setw(8)<<v.v[i];",
           "    std::cout<<' ';",'}',
           'void print_observation(const Observation& o) {']
    for n in model.outputs:
        lines.append(f'    print_value(o.outputs.{emitter.output_ids[n]});')
    for n in model.states:lines.append(f'    print_value(o.state.{emitter.signals[n]});')
    lines.extend(["    std::cout<<'\\n';","}","#ifdef __CUDACC__",
                  'void checked(cudaError_t result) {',
                  '    if(result!=cudaSuccess)throw std::runtime_error(cudaGetErrorString(result));','}',
                  'template<class T> struct DeviceBuffer {',
                  '    T* p=nullptr;',
                  '    explicit DeviceBuffer(size_t n){checked(cudaMalloc(&p,n*sizeof(T)));}',
                  '    ~DeviceBuffer(){if(p)cudaFree(p);}',
                  '    DeviceBuffer(const DeviceBuffer&)=delete;',
                  '};',
                  'void gpu_run(const std::vector<Stimulus>& input,std::vector<Observation>& output,Failure& failure) {',
                  '    DeviceBuffer<Stimulus> in(input.empty()?1:input.size());',
                  '    DeviceBuffer<Observation> trace(output.empty()?1:output.size());',
                  '    DeviceBuffer<State> state(1);DeviceBuffer<Failure> status(1);',
                  '    if(!input.empty())checked(cudaMemcpy(in.p,input.data(),input.size()*sizeof(Stimulus),cudaMemcpyHostToDevice));',
                  '    resident_kernel<<<1,128>>>(in.p,input.size(),trace.p,state.p,status.p);',
                  '    checked(cudaGetLastError());checked(cudaDeviceSynchronize());',
                  '    checked(cudaMemcpy(&failure,status.p,sizeof(Failure),cudaMemcpyDeviceToHost));',
                  '    if(failure.cycle==~uint64_t(0) && !output.empty())',
                  '        checked(cudaMemcpy(output.data(),trace.p,output.size()*sizeof(Observation),cudaMemcpyDeviceToHost));',
                  '}','#endif',
                  'int main(int argc,char** argv) { try {',
                  '    if(argc!=2 || (std::string(argv[1])!="--host-oracle" && std::string(argv[1])!="--gpu"))',
                  '        throw std::runtime_error("choose --host-oracle or --gpu explicitly");',
                  '    std::vector<Stimulus> input;unsigned edge;',
                  '    while(std::cin>>std::hex>>edge) {',
                  '        if(edge>1)throw std::runtime_error("edge must be 0 or 1");',
                  '        Stimulus i{};i.edge=edge;'])
    for n in model.inputs:
        lines.append(f'        if(!read_value(i.inputs.{emitter.signals[n]}))throw std::runtime_error("truncated input");')
    lines.extend(['        input.push_back(i);','    }',
                  '    if(!std::cin.eof())throw std::runtime_error("invalid input");',
                  '    std::vector<Observation> output(input.size()*2);',
                  '    Failure failure{~uint64_t(0),0,0};',
                  '    if(std::string(argv[1])=="--gpu") {',
                  '#ifdef __CUDACC__','        gpu_run(input,output,failure);',
                  '#else','        throw std::runtime_error("driver was built without CUDA");','#endif',
                  '    } else {',
                  '        Frame f{};f.states[0]=initial_state();',
                  '        for(size_t cycle=0;cycle<input.size();++cycle) {',
                  '            unsigned phase=0;',
                  '            if(!host_edge(f,input[cycle],output[2*cycle],output[2*cycle+1],phase)) {',
                  '                failure=Failure{cycle,first_error(f.errors)-1,phase};break;',
                  '            }',
                  '        }','    }',
                  '    if(failure.cycle!=~uint64_t(0)) {',
                  '        std::cerr<<"behavior check failed: cycle "<<failure.cycle<<" block "<<failure.block<<" phase "<<failure.phase<<"\\n";return 2;',
                  '    }',
                  '    for(const auto& o:output)print_observation(o);return 0;',
                  '    } catch(const std::exception& error) {std::cerr<<error.what()<<"\\n";return 1;}',
                  '}'])
    return "\n".join(lines)+"\n"

def write_driver(model,directory):
    from pathlib import Path
    directory=Path(directory);directory.mkdir(parents=True,exist_ok=True)
    (directory/"generated.hpp").write_text(CudaEmitter(model).emit())
    (directory/"driver.cu").write_text(runner_source(model))
