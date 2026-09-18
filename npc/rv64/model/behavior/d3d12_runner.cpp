// Native Linux/WSL Direct3D 12 compute runner. Never launches a Windows executable.
// One dispatch advances the complete supplied edge sequence in device memory.
#include <wsl/winadapter.h>
#include <wsl/wrladapter.h>
#include <directx/d3d12.h>
#include <directx/dxcore.h>
#include <dxguids/dxguids.h>
#include <chrono>
#include <thread>
#include <cstdio>
#include <fstream>
#include <iostream>
#include <vector>
#include <stdexcept>
#include <sstream>
#include <string>
#include <limits>
#include <cstring>
using Microsoft::WRL::ComPtr;
using Clock=std::chrono::steady_clock;
static void checked(HRESULT h,const char* operation) {
    if(FAILED(h)){std::ostringstream s;s<<operation<<" failed HRESULT=0x"<<std::hex<<unsigned(h);throw std::runtime_error(s.str());}
}
static std::vector<char> read_file(const char* path) {
    std::ifstream f(path,std::ios::binary|std::ios::ate);
    if(!f)throw std::runtime_error(std::string("cannot read ")+path);
    auto size=f.tellg();if(size<=0)throw std::runtime_error("empty input file");
    std::vector<char> bytes(size);f.seekg(0);f.read(bytes.data(),size);
    if(!f)throw std::runtime_error("short input read");
    return bytes;
}
static std::string quoted(const std::string& s) {
    std::string r="\"";for(char c:s){if(c=='"' || c=='\\')r+='\\';r+=c;}return r+'"';
}
static ComPtr<ID3D12Resource> buffer(ID3D12Device* d,uint64_t bytes,D3D12_HEAP_TYPE type,
                                    D3D12_RESOURCE_STATES state,bool uav=false) {
    D3D12_HEAP_PROPERTIES heap{};heap.Type=type;heap.CreationNodeMask=1;heap.VisibleNodeMask=1;
    D3D12_RESOURCE_DESC desc{};desc.Dimension=D3D12_RESOURCE_DIMENSION_BUFFER;
    desc.Width=bytes;desc.Height=1;desc.DepthOrArraySize=1;desc.MipLevels=1;
    desc.SampleDesc.Count=1;desc.Layout=D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
    if(uav)desc.Flags=D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;
    ComPtr<ID3D12Resource> r;
    checked(d->CreateCommittedResource(&heap,D3D12_HEAP_FLAG_NONE,&desc,state,nullptr,IID_PPV_ARGS(&r)),"CreateCommittedResource");
    return r;
}
static void transition(ID3D12GraphicsCommandList* list,ID3D12Resource* r,
                       D3D12_RESOURCE_STATES before,D3D12_RESOURCE_STATES after) {
    D3D12_RESOURCE_BARRIER b{};b.Type=D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
    b.Transition.pResource=r;b.Transition.StateBefore=before;b.Transition.StateAfter=after;
    b.Transition.Subresource=D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;list->ResourceBarrier(1,&b);
}
static uint32_t number(const char* text) {
    size_t end;auto n=std::stoull(text,&end);
    if(text[end] || n>std::numeric_limits<uint32_t>::max())throw std::runtime_error("invalid unsigned argument");
    return uint32_t(n);
}
int main(int argc,char** argv) {try {
    auto process_start=Clock::now();
    if(argc!=7)throw std::runtime_error("usage: d3d12-run shader.dxil input.bin output.bin cycles output_words trace(0|1)");
    uint32_t count=number(argv[4]),words=number(argv[5]),trace=number(argv[6]);
    if(count==0 || words<4 || trace>1)throw std::runtime_error("invalid buffer/count/trace arguments");
    auto shader=read_file(argv[1]);auto input=read_file(argv[2]);
    if(input.size()%4)throw std::runtime_error("input must contain uint32 words");
    const uint64_t output_bytes=uint64_t(words)*4;
    ComPtr<IDXCoreAdapterFactory> factory;ComPtr<IDXCoreAdapterList> adapters;
    checked(DXCoreCreateAdapterFactory(factory.GetAddressOf()),"DXCoreCreateAdapterFactory");
    checked(factory->CreateAdapterList(1,&DXCORE_ADAPTER_ATTRIBUTE_D3D12_CORE_COMPUTE,adapters.GetAddressOf()),"CreateAdapterList");
    ComPtr<IDXCoreAdapter> selected;std::string description;DXCoreHardwareID identity{};
    for(unsigned i=0;i<adapters->GetAdapterCount();++i) {
        ComPtr<IDXCoreAdapter> a;checked(adapters->GetAdapter(i,a.GetAddressOf()),"GetAdapter");
        bool hardware=false,integrated=false;DXCoreHardwareID id{};
        if(FAILED(a->GetProperty(DXCoreAdapterProperty::IsHardware,&hardware)) ||
           FAILED(a->GetProperty(DXCoreAdapterProperty::IsIntegrated,&integrated)) ||
           FAILED(a->GetProperty(DXCoreAdapterProperty::HardwareID,&id)))continue;
        if(!hardware || !integrated || id.vendorID!=0x8086)continue;
        size_t size=0;checked(a->GetPropertySize(DXCoreAdapterProperty::DriverDescription,&size),"DescriptionSize");
        std::vector<char> name(size+1,0);
        checked(a->GetProperty(DXCoreAdapterProperty::DriverDescription,size,name.data()),"Description");
        selected=a;description=name.data();identity=id;break;
    }
    if(!selected)throw std::runtime_error("no Intel hardware integrated GPU; software/CPU fallback is disabled");
    ComPtr<ID3D12Device> device;
    checked(D3D12CreateDevice(selected.Get(),D3D_FEATURE_LEVEL_11_0,IID_PPV_ARGS(&device)),"D3D12CreateDevice");
    D3D12_FEATURE_DATA_SHADER_MODEL sm{D3D_SHADER_MODEL_6_0};
    checked(device->CheckFeatureSupport(D3D12_FEATURE_SHADER_MODEL,&sm,sizeof(sm)),"ShaderModel");
    if(sm.HighestShaderModel<D3D_SHADER_MODEL_6_0)throw std::runtime_error("Shader Model 6.0 required");
    D3D12_ROOT_PARAMETER params[3]{};
    params[0].ParameterType=D3D12_ROOT_PARAMETER_TYPE_SRV;params[0].Descriptor.ShaderRegister=0;
    params[1].ParameterType=D3D12_ROOT_PARAMETER_TYPE_UAV;params[1].Descriptor.ShaderRegister=0;
    params[2].ParameterType=D3D12_ROOT_PARAMETER_TYPE_32BIT_CONSTANTS;
    params[2].Constants.ShaderRegister=0;params[2].Constants.Num32BitValues=2;
    D3D12_ROOT_SIGNATURE_DESC root_desc{};root_desc.NumParameters=3;root_desc.pParameters=params;
    ComPtr<ID3DBlob> blob,error;ComPtr<ID3D12RootSignature> root;
    HRESULT hr=D3D12SerializeRootSignature(&root_desc,D3D_ROOT_SIGNATURE_VERSION_1,&blob,&error);
    if(FAILED(hr) && error)std::cerr.write(static_cast<char*>(error->GetBufferPointer()),error->GetBufferSize());
    checked(hr,"SerializeRootSignature");
    checked(device->CreateRootSignature(0,blob->GetBufferPointer(),blob->GetBufferSize(),IID_PPV_ARGS(&root)),"CreateRootSignature");
    D3D12_COMPUTE_PIPELINE_STATE_DESC pipeline_desc{};pipeline_desc.pRootSignature=root.Get();
    pipeline_desc.CS={shader.data(),shader.size()};ComPtr<ID3D12PipelineState> pipeline;
    checked(device->CreateComputePipelineState(&pipeline_desc,IID_PPV_ARGS(&pipeline)),"CreateComputePipelineState");
    auto upload=buffer(device.Get(),input.size(),D3D12_HEAP_TYPE_UPLOAD,D3D12_RESOURCE_STATE_GENERIC_READ);
    auto gpu_input=buffer(device.Get(),input.size(),D3D12_HEAP_TYPE_DEFAULT,D3D12_RESOURCE_STATE_COPY_DEST);
    auto gpu_output=buffer(device.Get(),output_bytes,D3D12_HEAP_TYPE_DEFAULT,D3D12_RESOURCE_STATE_UNORDERED_ACCESS,true);
    auto readback=buffer(device.Get(),output_bytes,D3D12_HEAP_TYPE_READBACK,D3D12_RESOURCE_STATE_COPY_DEST);
    auto timing=buffer(device.Get(),16,D3D12_HEAP_TYPE_READBACK,D3D12_RESOURCE_STATE_COPY_DEST);
    void* mapped=nullptr;D3D12_RANGE none{0,0};
    checked(upload->Map(0,&none,&mapped),"MapUpload");std::memcpy(mapped,input.data(),input.size());upload->Unmap(0,nullptr);
    ComPtr<ID3D12CommandQueue> queue;D3D12_COMMAND_QUEUE_DESC queue_desc{};queue_desc.Type=D3D12_COMMAND_LIST_TYPE_DIRECT;
    checked(device->CreateCommandQueue(&queue_desc,IID_PPV_ARGS(&queue)),"CreateCommandQueue");
    uint64_t frequency=0;checked(queue->GetTimestampFrequency(&frequency),"GetTimestampFrequency");
    ComPtr<ID3D12CommandAllocator> allocator;
    checked(device->CreateCommandAllocator(queue_desc.Type,IID_PPV_ARGS(&allocator)),"CreateCommandAllocator");
    ComPtr<ID3D12GraphicsCommandList> list;
    checked(device->CreateCommandList(0,queue_desc.Type,allocator.Get(),pipeline.Get(),IID_PPV_ARGS(&list)),"CreateCommandList");
    ComPtr<ID3D12QueryHeap> queries;D3D12_QUERY_HEAP_DESC query_desc{};query_desc.Type=D3D12_QUERY_HEAP_TYPE_TIMESTAMP;query_desc.Count=2;
    checked(device->CreateQueryHeap(&query_desc,IID_PPV_ARGS(&queries)),"CreateQueryHeap");
    list->CopyBufferRegion(gpu_input.Get(),0,upload.Get(),0,input.size());
    transition(list.Get(),gpu_input.Get(),D3D12_RESOURCE_STATE_COPY_DEST,D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE);
    list->SetComputeRootSignature(root.Get());list->SetComputeRootShaderResourceView(0,gpu_input->GetGPUVirtualAddress());
    list->SetComputeRootUnorderedAccessView(1,gpu_output->GetGPUVirtualAddress());
    const uint32_t values[2]={count,trace};list->SetComputeRoot32BitConstants(2,2,values,0);
    list->EndQuery(queries.Get(),D3D12_QUERY_TYPE_TIMESTAMP,0);
    list->Dispatch(1,1,1);
    list->EndQuery(queries.Get(),D3D12_QUERY_TYPE_TIMESTAMP,1);
    transition(list.Get(),gpu_output.Get(),D3D12_RESOURCE_STATE_UNORDERED_ACCESS,D3D12_RESOURCE_STATE_COPY_SOURCE);
    list->CopyBufferRegion(readback.Get(),0,gpu_output.Get(),0,output_bytes);
    list->ResolveQueryData(queries.Get(),D3D12_QUERY_TYPE_TIMESTAMP,0,2,timing.Get(),0);
    checked(list->Close(),"CloseCommandList");
    ComPtr<ID3D12Fence> fence;checked(device->CreateFence(0,D3D12_FENCE_FLAG_NONE,IID_PPV_ARGS(&fence)),"CreateFence");
    ID3D12CommandList* lists[]={list.Get()};auto submit=Clock::now();
    queue->ExecuteCommandLists(1,lists);checked(queue->Signal(fence.Get(),1),"Signal");
    while(fence->GetCompletedValue()<1) {
        if(std::chrono::duration<double>(Clock::now()-submit).count()>30)throw std::runtime_error("device completion timeout");
        std::this_thread::sleep_for(std::chrono::microseconds(50));
    }
    checked(device->GetDeviceRemovedReason(),"DeviceRemovedReason");
    auto completed=Clock::now();
    D3D12_RANGE timer_range{0,16};checked(timing->Map(0,&timer_range,&mapped),"MapTiming");
    uint64_t timestamps[2];std::memcpy(timestamps,mapped,16);timing->Unmap(0,&none);
    D3D12_RANGE data_range{0,size_t(output_bytes)};checked(readback->Map(0,&data_range,&mapped),"MapReadback");
    uint32_t status[4];std::memcpy(status,mapped,16);
    std::ofstream out(argv[3],std::ios::binary);out.write(static_cast<char*>(mapped),output_bytes);
    if(!out)throw std::runtime_error("output write failed");
    out.close();readback->Unmap(0,&none);
    double gpu_ms=double(timestamps[1]-timestamps[0])*1000.0/double(frequency);
    double submit_ms=std::chrono::duration<double,std::milli>(completed-submit).count();
    double total_ms=std::chrono::duration<double,std::milli>(Clock::now()-process_start).count();
    std::cout<<"{\"adapter\":"<<quoted(description)<<",\"vendor_id\":"<<identity.vendorID
             <<",\"device_id\":"<<identity.deviceID<<",\"hardware\":true,\"integrated\":true,"
             <<"\"cycles\":"<<count<<",\"trace\":"<<trace<<",\"gpu_ms\":"<<gpu_ms
             <<",\"submit_wait_ms\":"<<submit_ms<<",\"process_ms\":"<<total_ms
             <<",\"status\":"<<status[0]<<",\"failure_cycle\":"<<status[1]<<",\"failure_block\":"<<status[2]
             <<",\"failure_phase\":"<<status[3]<<"}\n";
    return status[0]?2:0;
} catch(const std::exception& e){std::cerr<<e.what()<<"\n";return 1;}}
