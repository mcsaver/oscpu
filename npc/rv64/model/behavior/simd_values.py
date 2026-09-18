"""Canonical word representations for SIMD behavior families, with exact RTL masks."""
from functools import lru_cache
from always_ir import Expr,const,mask

def width(w):return 1 if w==1 else max(64,((w+31)//32)*32)

def raw(kind,w,*args,value=None):
    if kind=="resize" and args[0].width==w:return args[0]
    if kind=="and":
        if args[1].op=="const" and args[1].value==mask(w):return args[0]
        if args[0].op=="const" and args[0].value==mask(w):return args[1]
        if any(a.op=="const" and a.value==0 for a in args):return const(0,w)
    if kind=="or":
        if args[0].op=="const" and args[0].value==0:return args[1]
        if args[1].op=="const" and args[1].value==0:return args[0]
    if kind=="mux" and args[1]==args[2]:return args[1]
    return Expr(kind,w,tuple(args),value)

def fit(e,w):return raw("resize",w,e)
def clipped(e,bits):return raw("and",e.width,e,const(mask(bits),e.width)) if bits<e.width else e

@lru_cache(maxsize=None)
def canonical(e):
    # Flatten static subfields before lowering: reading a bit from a lane must
    # not first construct and shift that lane's entire packed payload.
    if e.op=="slice" and e.args[0].op=="slice":
        inner=e.args[0]
        return canonical(Expr("slice",e.width,inner.args,e.value+inner.value))
    w=width(e.width)
    if e.op=="const":return const(e.value,w)
    if e.op=="ref":return fit(e,w)
    if e.op=="edge":return e
    a=[canonical(x) for x in e.args]
    if e.op=="insert":
        old,value,index=a
        write_mask=raw("shl",w,const(mask(e.args[1].width),w),index)
        shifted=raw("shl",w,fit(value,w),index)
        return clipped(raw("or",w,raw("and",w,old,raw("inv",w,write_mask)),
                           raw("and",w,shifted,write_mask)),e.width)
    if e.op in ("slice","indexed"):
        index=const(e.value,64) if e.op=="slice" else a[1]
        return clipped(Expr("extract",w,(a[0],index)),e.width)
    if e.op=="concat":
        out=const(0,w);offset=0
        for original,value in reversed(list(zip(e.args,a))):
            out=raw("or",w,out,raw("shl",w,fit(value,w),const(offset,64)));offset+=original.width
        return clipped(out,e.width)
    if e.op=="resize":return clipped(fit(a[0],w),e.width)
    if e.op=="mux":return raw("mux",w,a[0],a[1],a[2])
    if e.op in ("eq","lt"):return raw(e.op,1,*a)
    if e.op=="bool":return raw("bool",1,*a)
    return clipped(raw(e.op,w,*a),e.width)
