"""Device-only edge cases for fused commit and check phases."""
from pathlib import Path
from always_ir import Model,Block,blocking,nba,Check,ref,const,eq,inv,add,op
from d3d12_backend import compile_model,execute

def check_phases(directory,build):
    root=Path(directory);root.mkdir(parents=True,exist_ok=True);results=[]
    for backend in ("simd","wave","dataflow"):
        model=Model("comb_checks",{"bad":1},{"q":8},{"view":8},[
            Block("comb","comb",(blocking("view",ref("q",8)),
                Check(inv(ref("bad")),"bad input"),
                Check(op("lt",1,ref("q",8),const(7,8)),"q bound"))),
            Block("edge","posedge",(nba("q",add(ref("q",8),const(1,8))),))
        ],initial={"q":5},outputs={"view":ref("view",8)})
        if backend=="dataflow":model.materialize={"view"}
        work=root/backend;work.mkdir()
        emitter,binary,_=compile_model(model,work,build,backend=backend)
        cases=[("pre",[("posedge",{"bad":1})],0,0,(5,)),
               ("post",[("posedge",{"bad":0}),("posedge",{"bad":0})],1,2,(7,))]
        for name,rows,cycle,phase,expected_state in cases:
            _,state,report=execute(model,rows,emitter,binary,work,build=build,expect_failure=True)
            if (report["failure_cycle"],report["failure_phase"],state)!=(cycle,phase,expected_state):
                raise AssertionError((backend,name,report,state))
            results.append({"backend":backend,"case":name,"phase":phase,"cycle":cycle,"final_state":state})
    return results
