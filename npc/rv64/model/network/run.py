#!/usr/bin/env python3
"""Build, verify and measure both generated engines; discard temporary builds."""
import argparse
import copy
import csv
import json
import os
from pathlib import Path
import statistics
import signal
import subprocess
import sys
import tempfile
import time

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(HERE/"tests"))
from emit import emit
from reference import Suite, audit


def command(args, log, timeout=120):
    start=time.perf_counter()
    process=subprocess.Popen([str(x) for x in args], stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        text=True, start_new_session=True, env=dict(os.environ,PYTHONDONTWRITEBYTECODE="1"))
    try:
        stdout,stderr=process.communicate(timeout=timeout)
    except BaseException:
        # Compilers spawn make/cc1plus children. Stop the entire owned group
        # before TemporaryDirectory cleans the build, including interruption.
        try: os.killpg(process.pid,signal.SIGTERM)
        except ProcessLookupError: pass
        try:
            stdout,stderr=process.communicate(timeout=5)
        except subprocess.TimeoutExpired:
            try: os.killpg(process.pid,signal.SIGKILL)
            except ProcessLookupError: pass
            stdout,stderr=process.communicate()
        with log.open("a") as f:
            f.write("$ "+" ".join(str(x) for x in args)+"\n"+stdout+stderr+"\nINTERRUPTED OR TIMEOUT\n")
        raise
    elapsed=time.perf_counter()-start
    with log.open("a") as f:
        f.write("$ "+" ".join(str(x) for x in args)+"\n"+stdout+stderr+"\n")
    if process.returncode:
        raise RuntimeError(f"command failed ({process.returncode}); see {log}\n{(stdout+stderr)[-2500:]}")
    return stdout,elapsed


def icarus_tb(manifest):
    ins, outs = manifest["inputs"],manifest["outputs"]
    lines=["module tb;", "reg clk=0;"]
    for name,w in zip(ins,manifest["input_widths"]):
        lines.append(f"reg [{w-1}:0] {name}=0;")
    for name,w in zip(outs,manifest["output_widths"]):
        lines.append(f"wire [{w-1}:0] o_{name};")
    lines+=["Network dut(.clk(clk),"+",".join(f".{x}({x})" for x in ins)+","+
            ",".join(f".o_{x}(o_{x})" for x in outs)+");",
            "integer fi,fo,rc; reg [4095:0] ip,op;",
            "initial begin",
            'if (!$value$plusargs("input=%s",ip) || !$value$plusargs("output=%s",op)) $fatal(1,"paths");',
            'fi=$fopen(ip,"r");fo=$fopen(op,"w");if (!fi || !fo) $fatal(1,"open");',
            "reset=1; #1; clk=1; #1; clk=0; reset=0;",
            "while (!$feof(fi)) begin",
            'rc=$fscanf(fi,"'+" ".join("%h" for _ in ins)+'",'+",".join(ins)+");",
            "if (rc>0) begin",f'if (rc!={len(ins)}) $fatal(1,"bad input row");',
            "#1;",
            '$fwrite(fo,"'+" ".join("%h" for _ in outs)+r'\n",'+",".join("o_"+x for x in outs)+");",
            "#1;clk=1;#1;clk=0;", 'end else if (!$feof(fi)) $fatal(1,"invalid input"); end',
            "$fclose(fi);$fclose(fo);$finish;", "end", "endmodule", ""]
    return "\n".join(lines)


def parse_and_compare(path, suite, manifest, label, report_dir):
    lines=path.read_text().splitlines()
    if len(lines)!=len(suite.rows):
        raise AssertionError(f"{label}: expected {len(suite.rows)} cycles, got {len(lines)}")
    actual=[]
    for cycle,line in enumerate(lines):
        fields=line.split()
        if len(fields)!=len(manifest["outputs"]):
            raise AssertionError(f"{label}: wrong output column count at {cycle}")
        values=[int(x,16) for x in fields]
        row=dict(zip(manifest["outputs"],values))
        differences={key:{"expected":value,"actual":row[key]} for key,value in suite.expected[cycle].items()
                     if row[key]!=value}
        if differences:
            failure={"engine":label,"cycle":cycle,"phase":suite.phases[cycle],
                     "inputs":suite.rows[cycle],"differences":differences,
                     "previous_inputs":suite.rows[max(0,cycle-2):cycle]}
            (report_dir/"first_mismatch.json").write_text(json.dumps(failure,indent=2)+"\n")
            raise AssertionError(f"{label}: cycle {cycle} mismatch: {differences}")
        actual.append(row)
    return audit(suite,actual)


def one(name,cfg,args,out):
    dest=out/name
    dest.mkdir(parents=True,exist_ok=True)
    log=dest/"commands.log"
    log.write_text("")
    (dest/"config.json").write_text(json.dumps(cfg,indent=2)+"\n")
    manifest=emit(cfg,dest/"generated")
    suite=Suite(manifest).generate(args.random_cycles)
    print(f"{name}: generated {manifest['registers']} registers, {manifest['combinational_nodes']} expressions; {len(suite.rows)} test cycles",flush=True)
    result={"status":"running","scope":"protocol-network prototype; not production CPU",
            "config":cfg,"manifest":manifest,"build_seconds":{},"validation":{},"benchmarks":{}}
    receipt=dest/"report.json"
    try:
        # Only files owned by this run are inside TemporaryDirectory. Both success
        # and failure close subprocesses before deleting their compilation files.
        with tempfile.TemporaryDirectory(prefix="build-",dir=dest) as tmp_name:
            tmp=Path(tmp_name)
            gen=dest/"generated"
            stimuli=tmp/"input.hex"
            stimuli.write_text("".join(" ".join(f"{row[k]:x}" for k in manifest["inputs"])+"\n"
                                      for row in suite.rows))
            model=tmp/"model"
            _,result["build_seconds"]["cpp"]=command(
                ["g++","-O3","-std=c++17","-Wall","-Wextra","-Werror","-I",gen,"-I",HERE,
                 HERE/"driver.cpp","-o",model],log)
            _,result["build_seconds"]["verilator"]=command(
                ["verilator","--cc","--exe","--build","-j","2","--assert","-DR64_ASSERT","-Wall",
                 "--top-module","Network","--Mdir",tmp/"obj","-o","rtl",
                 "-CFLAGS",f"-O3 -std=c++17 -DNETWORK_RTL -I{gen} -I{HERE}",
                 "-MAKEFLAGS","OPT_FAST=-O3 OPT_SLOW=-O3",gen/"Network.v",HERE/"driver.cpp"],log)
            rtl=tmp/"obj/rtl"
            for label,exe in (("cpp",model),("verilator",rtl)):
                trace=tmp/(label+".hex")
                command([exe,"--trace",stimuli,trace],log)
                result["validation"][label]=parse_and_compare(trace,suite,manifest,label,dest)
            (tmp/"tb.sv").write_text(icarus_tb(manifest))
            _,result["build_seconds"]["icarus"]=command(
                ["iverilog","-g2012","-DR64_ASSERT","-s","tb","-o",tmp/"tb.vvp",gen/"Network.v",tmp/"tb.sv"],log)
            command(["vvp",tmp/"tb.vvp",f"+input={stimuli}",f"+output={tmp/'icarus.hex'}"],log)
            result["validation"]["icarus"]=parse_and_compare(tmp/"icarus.hex",suite,manifest,"icarus",dest)
            print(f"{name}: C++ / Verilator / Icarus match independent specification on every channel",flush=True)
            if not args.skip_bench:
                for repeat in range(args.bench_repeats):
                    # Alternate order to reduce systematic thermal/order bias.
                    engines=[("cpp",model),("verilator",rtl)]
                    if repeat%2: engines.reverse()
                    for label,exe in engines:
                        stdout,wall=command([exe,"--bench",str(args.bench_cycles)],log)
                        sample=json.loads(stdout)
                        sample["process_seconds"]=wall
                        result["benchmarks"].setdefault(label,[]).append(sample)
                signatures={(s["cycles"],s["accepted"],s["checksum"])
                            for samples in result["benchmarks"].values() for s in samples}
                if len(signatures)!=1: raise AssertionError("independent feedback benchmark diverged")
                c=statistics.median(s["execution_seconds"] for s in result["benchmarks"]["cpp"])
                r=statistics.median(s["execution_seconds"] for s in result["benchmarks"]["verilator"])
                result["benchmark_summary"]={"cpp_median_seconds":c,"verilator_median_seconds":r,
                    "verilator_over_cpp":r/c,
                    "scope":"same generated network and feedback driver; initialization excluded; assertions and output checksum enabled; no detailed logging"}
                print(f"{name}: C++ {c:.6f}s, Verilator {r:.6f}s, ratio {r/c:.3f}x",flush=True)
            summary=result["validation"]["cpp"]
            with (dest/"statistics.csv").open("w",newline="") as f:
                writer=csv.writer(f);writer.writerow(["metric","value"])
                writer.writerows(summary["stats"].items())
                writer.writerow(["cycles",summary["cycles"]])
            result["status"]="pass"
        result["temporary_build_cleaned"]=not any(dest.glob("build-*"))
    except BaseException as exc:
        result["status"]="fail"
        result["error"]=str(exc)
        result["temporary_build_cleaned"]=not any(dest.glob("build-*"))
        raise
    finally:
        receipt.write_text(json.dumps(result,indent=2)+"\n")
    return result


def variants(cfg):
    yield "default",cfg
    second=copy.deepcopy(cfg)
    qs=[x for x in second["nodes"] if x["kind"]=="queue"]
    for i,q in enumerate(qs): q["depth"]=[3,1,4][i%3]
    arb=next(x for x in second["nodes"] if x["kind"]=="rr_hold")
    incoming=[x for x in second["links"] if x[1].startswith(arb["id"]+".in")]
    destinations=[x[1] for x in incoming][::-1]
    for edge,target in zip(incoming,destinations): edge[1]=target
    outgoing=[x for x in second["links"] if x[0].startswith(arb["id"]+".out")]
    destinations=[x[1] for x in outgoing][::-1]
    for edge,target in zip(outgoing,destinations): edge[1]=target
    second["payload_bits"]=17
    yield "permuted_depths",second
    yield "single_lane",{
        "protocol":"r64net-v0","owner_bits":8,"payload_bits":1,"cancel_ports":1,
        "inputs":["source"],"outputs":["sink"],
        "nodes":[{"id":"queue","kind":"queue","depth":1},{"id":"arb","kind":"rr_hold","inputs":1,"outputs":1}],
        "links":[["source","queue.in"],["queue.out","arb.in0"],["arb.out0","sink"]]}


def main():
    p=argparse.ArgumentParser()
    p.add_argument("--config",type=Path,default=HERE/"completion.json")
    p.add_argument("--out",type=Path,default=ROOT/"tmp/rv64-protocol-network")
    p.add_argument("--random-cycles",type=int,default=4000)
    p.add_argument("--bench-cycles",type=int,default=1000000)
    p.add_argument("--bench-repeats",type=int,default=3)
    p.add_argument("--skip-bench",action="store_true")
    p.add_argument("--single-config",action="store_true")
    args=p.parse_args()
    if args.random_cycles<1 or args.bench_cycles<1 or args.bench_repeats<1:
        p.error("cycle/repeat counts must be positive")
    out=args.out.resolve();out.mkdir(parents=True,exist_ok=True)
    (out/"summary.json").write_text(json.dumps({"status":"running","scope":"protocol-network prototype only"})+"\n")
    (out/"unit-tests.log").write_text("")
    results=[]
    try:
        cfg=json.loads(args.config.read_text())
        if cfg.get("owner_bits",0)<8:
            raise ValueError("built-in test/benchmark traffic requires at least 8 owner bits")
        command([sys.executable,"-m","unittest","discover","-s",HERE/"tests","-p","test_ir.py"],out/"unit-tests.log")
        cases=[("default",cfg)] if args.single_config else list(variants(cfg))
        for name,config in cases:
            results.append(one(name,config,args,out))
    except BaseException as exc:
        (out/"summary.json").write_text(json.dumps({"status":"fail","error":str(exc)},indent=2)+"\n")
        print(str(exc),file=sys.stderr)
        return 130 if isinstance(exc,KeyboardInterrupt) else 2
    summary={"status":"pass","scope":"protocol-network prototype only",
             "configurations":{name:{"cycles":r["validation"]["cpp"]["cycles"],
                  "signals_per_cycle":len(r["manifest"]["outputs"]),
                  "temporary_build_cleaned":r["temporary_build_cleaned"],
                  "benchmark":r.get("benchmark_summary")} for (name,_),r in zip(cases,results)}}
    (out/"summary.json").write_text(json.dumps(summary,indent=2)+"\n")
    print(json.dumps(summary,indent=2))
    return 0


if __name__=="__main__":
    raise SystemExit(main())
