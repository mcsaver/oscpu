#!/usr/bin/env python3
"""Require a real Intel integrated GPU and compare device behavior with original RTL."""
import argparse,json,random,statistics,struct,subprocess,sys,tempfile,time
from pathlib import Path
sys.dont_write_bytecode=True
from always_ir import mask
from counter import counter
from lsu_queue import request_queue
from hlsl_codegen import HlslEmitter
from d3d12_backend import BUILD,HERE,build_runner,compile_model,execute,command,pack_inputs
from test_codegen import semantics_model,expected_trace
from test_queue import sequence,rtl_run
from test_always import ROOT
from cuda_codegen import CudaEmitter
from gpu_edge_cases import check_phases

def counter_cases():
    cases=[dict(rst_i=1,enable_i=1,increment_i=3,write_i=1,write_value_i=mask(64))]
    for bank in range(1,9):
        for distance in range(1,5):
            for step in range(4):
                value=((1<<(bank*8))-distance)&mask(64)
                cases += [
                    dict(rst_i=0,enable_i=1,increment_i=3,write_i=1,write_value_i=value),
                    dict(rst_i=0,enable_i=1,increment_i=step,write_i=0,write_value_i=0),
                    dict(rst_i=0,enable_i=0,increment_i=3,write_i=0,write_value_i=0)]
    rng=random.Random(2049)
    while len(cases)<2000:
        cases.append(dict(rst_i=int(rng.randrange(37)==0),enable_i=rng.randrange(2),
                          increment_i=rng.randrange(4),write_i=int(rng.randrange(7)==0),write_value_i=rng.getrandbits(64)))
    return [("posedge",x) for x in cases]

def counter_rtl(cases,directory):
    m=counter();directory=Path(directory)
    data=directory/"counter.txt"
    data.write_text("\n".join(" ".join(f"{r[n]:x}" for n in m.inputs) for _,r in cases)+"\n")
    near="{"+",".join(f"d.g_bank[{b}].near_wrap_q" for b in reversed(range(1,8)))+"}"
    code=f"""module tb;
reg clk_i=0,rst_i,enable_i,write_i;reg [1:0] increment_i;reg [63:0] write_value_i;
wire [63:0] value_o;wire [20:0] near_debug={near};R64Counter d(.*);
integer f,r,cycle;
initial begin cycle=0;f=$fopen("{data}","r");
while(!$feof(f))begin
r=$fscanf(f,"%h %h %h %h %h",rst_i,enable_i,increment_i,write_i,write_value_i);
if(r==5)begin clk_i=0;#1;if(cycle>0)$display("%h %h",value_o,near_debug);
clk_i=1;#1;$display("%h %h",value_o,near_debug);cycle=cycle+1;end end
$finish;end endmodule
"""
    tb=directory/"counter.sv";tb.write_text(code);sim=directory/"counter.vvp"
    command(["iverilog","-g2012","-s","tb","-o",sim,tb,
             ROOT/"npc/rv64/vsrc/control/R64Counter.v",
             ROOT/"npc/rv64/vsrc/control/R64CounterNear.v"])
    return [tuple(int(x,16) for x in line.split()) for line in command(["vvp",sim]).splitlines() if "$finish" not in line]

def host_benchmark(model,cases,directory):
    """Same generated behavior, trace disabled, report inner loop and process separately."""
    directory=Path(directory);emitter=CudaEmitter(model)
    (directory/"generated.hpp").write_text(emitter.emit())
    source=['#include "generated.hpp"','#include <chrono>','#include <fstream>','#include <iostream>',
            '#include <vector>','using namespace r64_generated;',
            'int main(int argc,char** argv){if(argc!=3)return 1;std::ifstream input(argv[1],std::ios::binary);',
            'std::vector<Stimulus> cases;unsigned count=std::stoul(argv[2]);',
            'for(unsigned c=0;c<count;++c){Stimulus i{};input.read(reinterpret_cast<char*>(&i.edge),4);']
    for n,w in model.inputs.items():source.append(f'input.read(reinterpret_cast<char*>(i.inputs.{emitter.signals[n]}.v),{((w+31)//32)*4});')
    source += ['if(!input)return 1;cases.push_back(i);}',
               'Frame f{};f.states[0]=initial_state();unsigned phase;Observation before,after;',
               'auto start=std::chrono::steady_clock::now();',
               'for(const auto& i:cases)if(!host_edge(f,i,before,after,phase))return 2;',
               'double us=std::chrono::duration<double,std::micro>(std::chrono::steady_clock::now()-start).count();',
               'std::cout<<us;']
    for n in model.states:source.append(f'for(auto word:f.states[0].{emitter.signals[n]}.v)std::cout<<" "<<word;')
    source+=['std::cout<<"\\n";return 0;}']
    cpp=directory/"bench.cpp";exe=directory/"bench";data=directory/"bench-input.bin"
    cpp.write_text("\n".join(source));data.write_bytes(pack_inputs(model,cases))
    command(["g++","-std=c++17","-O3","-I",HERE,cpp,"-o",exe])
    samples=[];wall=[];state=None
    for _ in range(5):
        start=time.perf_counter();text=command([exe,data,len(cases)]);wall.append((time.perf_counter()-start)*1000)
        values=text.split();samples.append(float(values[0])/1000);state=tuple(map(int,values[1:]))
    expected=tuple((model.state[n]>>(32*j))&0xffffffff for n,w in model.states.items() for j in range((w+31)//32))
    if state!=expected:raise AssertionError("host benchmark final state differs")
    return {"samples":5,"inner_ms":samples,"median_inner_ms":statistics.median(samples),
            "invocation_ms":wall,"median_invocation_ms":statistics.median(wall)}

def exact(rows,expected):
    if len(rows)!=len(expected):raise AssertionError(("length",len(rows),len(expected)))
    for i,(got,want) in enumerate(zip(rows,expected)):
        if got!=want:raise AssertionError({"observation":i,"got":got,"expected":want})

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--out",type=Path,default=HERE/"IGPU_OPTIMIZATION.json")
    p.add_argument("--build",type=Path,default=BUILD)
    p.add_argument("--skip-benchmark",action="store_true")
    p.add_argument("--backend",choices=("auto","baseline","simd","wave"),default="auto")
    p.add_argument("--compare-baseline",action="store_true")
    a=p.parse_args();a.build=a.build.resolve();build_runner(a.build)
    report={"status":"running","backend":"native WSL Direct3D12 HLSL","gpu_executed":True,
            "whole_cpu_executed":False,"tests":[],"benchmarks":[]}
    with tempfile.TemporaryDirectory(prefix="r64-igpu-validation-") as temp:
        root=Path(temp)
        models=[("counter",counter(),counter_cases())]
        for index,cfg in enumerate(({},{"prepared_cancel":True,"data_w":193,"age_w":32,"rob_w":6,"tag_w":12})):
            m=request_queue(**cfg);cases,_,coverage=sequence(m,cycles=1500,seed=1001+index)
            models.append(("queue"+str(index),m,[("posedge",r) for r in cases]))
        m=semantics_model();rng=random.Random(3209);cases=[]
        indexes=[0,1,31,32,63,64,125,129,130,1<<32,1<<64]
        for cycle in range(400):
            row=dict(a=rng.getrandbits(130),b=rng.getrandbits(130),index=indexes[cycle%len(indexes)])
            if cycle<8:row.update(a=mask(130) if cycle%2 else 0,b=1)
            if cycle%13==0:row["b"]=row["a"]
            cases.append(("negedge" if cycle%3==2 else "posedge",row))
        models.append(("semantics",m,cases))
        for name,m,cases in models:
            directory=root/name;directory.mkdir()
            expected=expected_trace(m,cases)
            emitter,binary,compile_s=compile_model(m,directory,a.build,backend=a.backend)
            rows,state,device=execute(m,cases,emitter,binary,directory,build=a.build)
            exact(rows,expected)
            if state!=tuple(m.state.values()):raise AssertionError("final state differs")
            rtl_count=0
            if name=="counter":
                # First pre-reset observation contains RTL X values and is excluded.
                positions={n:len(m.outputs)+i for i,n in enumerate(m.states)}
                combined=[(r[positions["value_o"]],sum(r[positions[f"near_q{j+1}"]]<<(3*j) for j in range(7))) for r in rows[1:]]
                exact(combined,counter_rtl(cases,directory));rtl_count=len(combined)
            elif name.startswith("queue"):
                exact(rows,rtl_run(m,[r for _,r in cases],directory));rtl_count=len(rows)
                if name=="queue1":
                    row={n:0 for n in m.inputs};row["rst_i"]=1;bad=[("posedge",dict(row))]
                    row.update(rst_i=0,in_fire_i=3)
                    bad += [("posedge",dict(row)) for _ in range(3)]
                    pre_failure=expected_trace(m,bad[:-1]);hold=tuple(m.state.values())
                    _,bad_state,negative=execute(m,bad,emitter,binary,directory,build=a.build,expect_failure=True)
                    if negative["failure_cycle"]!=3 or negative["failure_phase"]!=1 or bad_state!=hold:raise AssertionError("invalid edge committed")
                    row.update(in_fire_i=0,kill_mask_i=1)
                    _,_,cancel=execute(m,[bad[0],("posedge",dict(row))],emitter,binary,directory,build=a.build,expect_failure=True)
                    if cancel["failure_cycle"]!=1 or cancel["failure_phase"]!=1:raise AssertionError(cancel)
                    report["negative_checks"]={"credit":negative,"prepared_cancel":cancel}
                    expected_trace(m,cases) # restore benchmark final-state expectation
            item={"name":name,"parameters":getattr(m,"parameters",{}),"edges":len(cases),
                  "observations":len(rows),"rtl_observations":rtl_count,"differences":0,
                  "compile_seconds":compile_s,"shared_bytes":emitter.metadata()["shared_bytes"],"execution":emitter.metadata(),"device":device}
            report["tests"].append(item)
            print("IGPU_PASS "+json.dumps({k:v for k,v in item.items() if k!="execution"}),flush=True)
            if not a.skip_benchmark and name in ("counter","queue1"):
                fast_dir=directory/"fast";fast_dir.mkdir()
                fast_emitter,fast_binary,fast_compile_s=compile_model(m,fast_dir,a.build,backend=a.backend,trace_mode=False)
                samples=[]
                for _ in range(5):
                    _,last,result=execute(m,cases,fast_emitter,fast_binary,fast_dir,trace=False,build=a.build)
                    if last!=tuple(m.state.values()):raise AssertionError("trace-free device result differs")
                    samples.append(result)
                host=host_benchmark(m,cases,directory)
                bench={"name":name,"edges":len(cases),"trace":False,"samples":5,"gpu_samples":samples,"host":host,
                       "median_gpu_ms":statistics.median(x["gpu_ms"] for x in samples),
                       "median_gpu_invocation_ms":statistics.median(x["invocation_ms"] for x in samples),
                       "execution":fast_emitter.metadata(),"trace_specialized":True,"compile_seconds":fast_compile_s}
                if a.compare_baseline:
                    baseline_dir=directory/"baseline";baseline_dir.mkdir()
                    be,bb,bt=compile_model(m,baseline_dir,a.build,backend="baseline",trace_mode=False)
                    baseline=[]
                    for _ in range(5):
                        _,last,result=execute(m,cases,be,bb,baseline_dir,trace=False,build=a.build)
                        if last!=tuple(m.state.values()):raise AssertionError("baseline result differs")
                        baseline.append(result)
                    bench["baseline_samples"]=baseline
                    bench["baseline_median_gpu_ms"]=statistics.median(x["gpu_ms"] for x in baseline)
                    bench["baseline_median_invocation_ms"]=statistics.median(x["invocation_ms"] for x in baseline)
                    bench["kernel_speedup_vs_baseline"]=bench["baseline_median_gpu_ms"]/bench["median_gpu_ms"]
                    bench["process_speedup_vs_baseline"]=bench["baseline_median_invocation_ms"]/bench["median_gpu_invocation_ms"]
                bench["gpu_inner_over_host_inner"]=bench["median_gpu_ms"]/host["median_inner_ms"]
                report["benchmarks"].append(bench)
                print("IGPU_BENCH "+json.dumps({k:v for k,v in bench.items() if k not in ("gpu_samples","baseline_samples","host","execution")}),flush=True)
        report["additional_gpu_check_phases"]=check_phases(root/"check-phases",a.build)
    report["status"]="pass";report["temporary_compilation_files_removed"]=True
    report["speed_scope"]="single module, one instance; GPU timestamp vs generated C++ semantic loop; not whole CPU or Verilator"
    a.out.parent.mkdir(parents=True,exist_ok=True);a.out.write_text(json.dumps(report,indent=2)+"\n")
    print("IGPU_VALIDATION_PASS "+str(a.out),flush=True)
if __name__=="__main__":main()
