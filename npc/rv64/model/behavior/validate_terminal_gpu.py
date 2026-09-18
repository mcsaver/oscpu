#!/usr/bin/env python3
"""Execute the connected LSU terminal behavior on the actual Intel integrated GPU."""
import argparse,json,statistics,sys,tempfile,time
from pathlib import Path
sys.dont_write_bytecode=True
from lsu_terminal import terminal
from test_terminal import sequence,rtl_run
from d3d12_backend import HERE,BUILD,compile_model,execute
from validate_igpu import exact,host_benchmark
from gpu_edge_cases import check_phases
from native_gpu_cases import check_native

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--out",type=Path,default=HERE/"TERMINAL_GPU_VALIDATION.json")
    p.add_argument("--build",type=Path,default=BUILD)
    p.add_argument("--cycles",type=int,default=1200)
    p.add_argument("--skip-benchmark",action="store_true")
    a=p.parse_args()
    if a.cycles<100:p.error("at least 100 cycles are required for directed coverage and drain")
    report={"status":"running","scope":"connected production LSU terminal slice; one instance, one dispatch per run",
            "whole_cpu_executed":False,"stimulus":"external ingress queue inputs only; credit, grants, completion and priority feedback stay on GPU",
            "tests":[],"benchmarks":[]}
    with tempfile.TemporaryDirectory(prefix="r64-terminal-validation-") as directory:
        root=Path(directory)
        for index,cfg in enumerate(({},{"tag_w":12,"rob_w":6,"prepared_cancel":True})):
            name="terminal"+str(index);work=root/name;work.mkdir()
            m=terminal(**cfg);cases,expected,coverage=sequence(m,cycles=a.cycles,seed=916)
            exact(rtl_run(m,cases,work),expected)
            print("TERMINAL_RTL_PASS",name,len(cases),flush=True)
            started=time.perf_counter()
            emitter,binary,compile_s=compile_model(m,work,a.build,backend="dataflow",trace_mode=True)
            generate_and_compile_s=time.perf_counter()-started
            rows,state,device=execute(m,cases,emitter,binary,work,build=a.build)
            exact(rows,expected)
            if state!=tuple(m.state.values()):raise AssertionError("terminal final state mismatch")
            item={"name":name,"parameters":m.parameters,"instances":m.instances,"state_fields":len(m.states),
                  "edges":len(cases),"rtl_observations":len(rows),"differences":0,"coverage":coverage,
                  "compile_seconds":compile_s,"generation_and_compile_seconds":generate_and_compile_s,
                  "execution":emitter.metadata(),"device":device}
            report["tests"].append(item)
            print("TERMINAL_GPU_PASS",name,device["gpu_ms"],flush=True)
            # A bad external ingress fire must trip the original queue check and
            # preserve the entire network state, not just the queue's state.
            badrow={n:0 for n in m.inputs};badrow["rst_i"]=1
            bad=[("posedge",dict(badrow))]
            badrow.update(rst_i=0,raw_fire_i=3,fault_fire_i=3,forward_fire_i=3)
            m.state=dict(m.initial);m.step(bad[0][1])
            for cycle in range(24):
                hold=tuple(m.state.values());bad.append(("posedge",dict(badrow)))
                try:m.step(badrow)
                except AssertionError:
                    failure_cycle=len(bad)-1;break
            else:raise AssertionError("invalid ingress did not fill")
            rtl_failure=rtl_run(m,bad,work/"negative",expect_failure=True)
            _,final,failure=execute(m,bad,emitter,binary,work,build=a.build,expect_failure=True)
            if final!=hold or failure["failure_cycle"]!=failure_cycle or failure["failure_phase"]!=1:
                raise AssertionError(("partial network commit on failure",failure))
            item["negative_credit"]={"failure_cycle":failure_cycle,"gpu":failure,
                                      "whole_network_state_held":True,"rtl_rejected":"credit violation" in rtl_failure}
            # Restore the successful reference state for final-state benchmark checks.
            m.state=dict(m.initial)
            for edge,row in cases:m.step(row,edge)
            if not a.skip_benchmark and index==0:
                fast=work/"fast";fast.mkdir()
                e,b,fast_compile_s=compile_model(m,fast,a.build,backend="dataflow",trace_mode=False)
                samples=[]
                for _ in range(5):
                    _,last,result=execute(m,cases,e,b,fast,trace=False,build=a.build)
                    if last!=tuple(m.state.values()):raise AssertionError("trace-free terminal mismatch")
                    samples.append(result)
                host=host_benchmark(m,cases,work)
                bench={"name":name,"edges":len(cases),"samples":5,"trace":False,"gpu_samples":samples,"host":host,
                       "median_gpu_ms":statistics.median(x["gpu_ms"] for x in samples),
                       "median_gpu_invocation_ms":statistics.median(x["invocation_ms"] for x in samples),
                       "execution":e.metadata(),"fast_compile_seconds":fast_compile_s}
                bench["gpu_inner_over_host_inner"]=bench["median_gpu_ms"]/host["median_inner_ms"]
                report["benchmarks"].append(bench)
                print("TERMINAL_BENCH",name,bench["median_gpu_ms"],host["median_inner_ms"],flush=True)
        report["additional_gpu_check_phases"]=check_phases(root/"check-phases",a.build)
        report["native_uint32_regressions"]=check_native(root/"native-integers",a.build)
    report["status"]="pass";report["temporary_compilation_files_removed"]=True
    a.out.parent.mkdir(parents=True,exist_ok=True);a.out.write_text(json.dumps(report,indent=2)+"\n")
    print("TERMINAL_VALIDATION_PASS",a.out,flush=True)
if __name__=="__main__":main()
