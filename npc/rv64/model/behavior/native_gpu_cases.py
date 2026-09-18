"""Device regressions for native uint32 behavior lowering.

Includes the load sign-extension failure found while connecting the LSU.
The load oracle is ordinary Python integer semantics, independent of the IR
expression construction. Wide integer cases compare with the ordered model.
"""
from pathlib import Path
import random
from always_ir import Model,Block,nba,ref,mask
from lsu_terminal import load_value
from test_codegen import semantics_model,expected_trace
from d3d12_backend import compile_model,execute

def load_reference(data,fn,amo,offset):
    shifted=data>>(offset*8)
    if fn&16 and amo==3:return data
    if fn&8 and not fn&16:
        return (0xffffffff00000000|(shifted&0xffffffff)) if fn&3==2 else shifted
    code=fn&7
    widths={0:8,1:16,2:32,4:8,5:16,6:32}
    if code not in widths:return shifted
    width=widths[code];value=shifted&mask(width)
    if code<3 and value&(1<<(width-1)):value-=1<<width
    return value&mask(64)

def check_native(directory,build):
    root=Path(directory);root.mkdir(parents=True,exist_ok=True);results=[]
    inputs={"data":64,"fn":5,"amo":5,"off":3}
    load=Model("native_load",inputs,{"q":64},{},
        [Block("load","posedge",(nba("q",load_value(*(ref(n,w) for n,w in inputs.items()))),))],
        outputs={"q":ref("q",64)})
    cases=[("posedge",dict(data=0xd58f,fn=fn,amo=0,off=0)) for fn in range(8)]
    for data in (0x8080808080808080,0x7f7f7f7f7f7f7f7f):
        for fn in range(32):
            for amo in (0,3,7):
                for off in range(8):cases.append(("posedge",dict(data=data,fn=fn,amo=amo,off=off)))
    rng=random.Random(917)
    cases.extend(("posedge",{n:rng.getrandbits(w) for n,w in inputs.items()}) for _ in range(256))
    expected=[];previous=0
    for _,row in cases:
        expected.append((previous,previous))
        previous=load_reference(row["data"],row["fn"],row["amo"],row["off"])
        expected.append((previous,previous))
    if expected_trace(load,cases)!=expected:raise AssertionError("load IR disagrees with integer reference")
    models=[("load_sign_extension",load,cases,expected)]
    model=semantics_model();cases=[]
    indexes=[0,1,31,32,63,64,125,129,130,1<<32,1<<64]
    rng=random.Random(3209)
    for cycle in range(400):
        row=dict(a=rng.getrandbits(130),b=rng.getrandbits(130),index=indexes[cycle%len(indexes)])
        if cycle<8:row.update(a=mask(130) if cycle%2 else 0,b=1)
        if cycle%13==0:row["b"]=row["a"]
        cases.append(("negedge" if cycle%3==2 else "posedge",row))
    models.append(("wide_integer_mixed_edges",model,cases,expected_trace(model,cases)))
    for name,model,cases,expected in models:
        work=root/name;work.mkdir()
        emitter,binary,seconds=compile_model(model,work,build,backend="dataflow",trace_mode=True)
        rows,state,device=execute(model,cases,emitter,binary,work,build=build)
        if rows!=expected:
            for index,(got,want) in enumerate(zip(rows,expected)):
                if got!=want:raise AssertionError((name,index,got,want))
            raise AssertionError((name,"trace length",len(rows),len(expected)))
        if state!=tuple(model.state.values()):raise AssertionError((name,"final state"))
        results.append({"name":name,"edges":len(cases),"observations":len(rows),"differences":0,
                        "compile_seconds":seconds,"device":device})
    return results
