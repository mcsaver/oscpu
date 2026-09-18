"""Push an observed 32-bit word through pure behavioral expressions.

Wide payload copies and bitwise/mux operations become one-word lane work instead
of recomputing an entire packed value in every lane. Arithmetic carries and fully
dynamic wide shifts keep their exact generic implementation when necessary.
"""
from functools import lru_cache
from always_ir import Expr,const,mask
from simd_values import raw

def binary(op,a,b):return raw(op,32,a,b)
def shift(op,a,n):
    if n==0:return a
    return raw(op,32,a,const(n,32))

@lru_cache(maxsize=None)
def word(e,j):
    if j*32>=e.width:return const(0,32)
    if e.width==1:return raw("resize",32,e)
    if e.op=="const":return const((e.value>>(32*j))&0xffffffff,32)
    if e.op=="ref":return Expr("word_ref",32,value=(e.value,j,e.width))
    if e.op=="resize":
        out=word(e.args[0],j)
        return binary("and",out,const(mask(e.width%32),32)) if e.width%32 and j==e.width//32 else out
    if e.op=="mux":return raw("mux",32,e.args[0],word(e.args[1],j),word(e.args[2],j))
    if e.op in ("and","or","xor"):return binary(e.op,word(e.args[0],j),word(e.args[1],j))
    if e.op=="inv":return raw("inv",32,word(e.args[0],j))
    if e.op in ("add","sub") and j==0:return binary(e.op,word(e.args[0],0),word(e.args[1],0))
    if e.op in ("shl","shr","extract") and e.args[1].op=="const":
        count=e.args[1].value
        if count>=e.args[0].width:return const(0,32)
        whole,bits=divmod(count,32)
        if e.op=="shl":
            if j<whole:return const(0,32)
            a=shift("shl",word(e.args[0],j-whole),bits)
            b=shift("shr",word(e.args[0],j-whole-1),32-bits) if bits and j>whole else const(0,32)
        else:
            a=shift("shr",word(e.args[0],j+whole),bits)
            b=shift("shl",word(e.args[0],j+whole+1),32-bits) if bits else const(0,32)
        return binary("or",a,b)
    if e.op=="shl" and e.args[0].op=="const" and e.args[0].value==1:
        return Expr("onehot_word",32,(e.args[1],const(j,32)))
    return Expr("word",32,(e,const(j*32,32)))
