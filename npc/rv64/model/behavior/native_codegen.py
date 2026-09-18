"""Lower pure behavior expressions directly to native uint32 SSA.

Wide integers are tuples of native words at compile time, not HLSL structs
passed through a function for every AST operation. Structs only remain at the
small leaf/output ABI shared with the existing family and trace generators.
"""
from simd_codegen import SimdEmitter

class NativeEmitter(SimdEmitter):
    def dag(self,e,lines,cache,bindings=None):
        def show(v):return f"0x{v&0xffffffff:x}u" if isinstance(v,int) else v
        def emit(kind,*args):
            if all(isinstance(x,int) for x in args):
                a=args[0];b=args[1] if len(args)>1 else 0
                values={"&":lambda:a&b,"|":lambda:a|b,"^":lambda:a^b,"~":lambda:~a,
                    "+":lambda:a+b,"-":lambda:a-b,"<<":lambda:a<<(b&31),">>":lambda:a>>(b&31),
                    "==":lambda:int(a==b),"<":lambda:int(a<b),"!=":lambda:int(a!=b)}
                if kind in values:return values[kind]()&0xffffffff
            if kind in ("&","|","^","+","-","<<",">>"):
                if kind=="&":
                    if 0 in args:return 0
                    if args[1]==0xffffffff:return args[0]
                    if args[0]==0xffffffff:return args[1]
                if kind in ("|","^","+") and args[0]==0:return args[1]
                if kind in ("|","^","+","-","<<",">>") and args[1]==0:return args[0]
                if kind in ("<<",">>") and args[0]==0:return 0
            key=("native",kind,args)
            if key not in cache:
                value=f"~{show(args[0])}" if kind=="~" else f"({show(args[0])}{kind}{show(args[1])})"
                if kind in ("==","<","!="):value="uint("+value+")"
                name="native_"+str(len(cache));lines.append(f"uint {name}={value};");cache[key]=name
            return cache[key]
        def select(c,a,b):
            if c==0:return b
            if c==1:return a
            if a==b:return a
            key=("native_select",c,a,b)
            if key not in cache:
                name="native_"+str(len(cache))
                lines.append(f"uint {name}=({show(c)}!=0u)?{show(a)}:{show(b)};")
                cache[key]=name
            return cache[key]
        def reduce_or(xs):
            result=0
            for x in xs:result=emit("|",result,x)
            return result
        def truth(xs):return emit("!=",reduce_or(xs),0)
        def padded(xs,n):return tuple(xs[:n])+(0,)*max(0,n-len(xs))
        def shifted(values,index,count,left=False):
            # The low index word addresses native words; nonzero high words
            # denote an out-of-range shift and produce zero.
            low=index[0];valid=emit("==",reduce_or(index[1:]),0)
            if isinstance(low,int):
                whole,bits=divmod(low,32);out=[]
                for j in range(count):
                    k=j-whole if left else j+whole
                    lo=values[k] if 0<=k<len(values) else 0
                    other=k-1 if left else k+1
                    hi=values[other] if bits and 0<=other<len(values) else 0
                    value=emit("|",emit("<<" if left else ">>",lo,bits),
                               emit(">>" if left else "<<",hi,32-bits)) if bits else lo
                    out.append(select(valid,value,0))
                return tuple(out)
            whole=emit(">>",low,5);bits=emit("&",low,31)
            inverse=emit("&",emit("-",32,bits),31);extra=emit("!=",bits,0)
            out=[]
            for j in range(count):
                lo=hi=0
                for q,value in enumerate(values):
                    base=emit("+",whole,q) if left else emit("+",whole,j)
                    want0=emit("==",base,j if left else q)
                    want1=emit("==",emit("+",base,1),j if left else q)
                    lo=emit("|",lo,select(want0,value,0));hi=emit("|",hi,select(want1,value,0))
                value=emit("|",emit("<<" if left else ">>",lo,bits),
                           select(extra,emit(">>" if left else "<<",hi,inverse),0))
                out.append(select(valid,value,0))
            return tuple(out)
        def visit(x):
            n=(x.width+31)//32
            if x.op in ("ref","const","word_ref"):
                text=next(bindings) if bindings is not None else self.expr(x)
                key=("native_leaf",x.width,text)
                if key not in cache:
                    constant=next((value for (value,width),name in self.constants.items()
                                   if width==x.width and text==name+"()"),None)
                    if constant is not None:result=tuple((constant>>(32*j))&0xffffffff for j in range(n))
                    else:
                        name="native_leaf_"+str(len(cache));lines.append(f"B{x.width} {name}={text};")
                        result=tuple(name+f".w[{j}]" for j in range(n))
                    cache[key]=result
                return cache[key]
            a=[visit(child) for child in x.args]
            if x.op=="edge":
                result=(f"uint(edge=={x.value}u)",)
            elif x.op=="resize":result=padded(a[0],n)
            elif x.op in ("word","extract","shr"):
                result=shifted(a[0],a[1],n)
            elif x.op=="shl":result=shifted(a[0],a[1],n,left=True)
            elif x.op=="onehot_word":
                index,part=a
                condition=emit("&",emit("==",reduce_or(index[1:]),0),emit("==",emit(">>",index[0],5),part[0]))
                result=(select(condition,emit("<<",1,emit("&",index[0],31)),0),)
            elif x.op in ("and","or","xor"):
                symbol={"and":"&","or":"|","xor":"^"}[x.op]
                result=tuple(emit(symbol,u,v) for u,v in zip(padded(a[0],n),padded(a[1],n)))
            elif x.op=="inv":result=tuple(emit("~",v) for v in padded(a[0],n))
            elif x.op=="mux":result=tuple(select(a[0][0],u,v) for u,v in zip(padded(a[1],n),padded(a[2],n)))
            elif x.op=="bool":result=(truth(a[0]),)
            elif x.op in ("eq","lt"):
                equal=1;less=0
                size=max(len(a[0]),len(a[1]))
                for u,v in reversed(list(zip(padded(a[0],size),padded(a[1],size)))):
                    less=emit("|",less,emit("&",equal,emit("<",u,v)))
                    equal=emit("&",equal,emit("==",u,v))
                result=(equal if x.op=="eq" else less,)
            elif x.op in ("add","sub"):
                out=[];carry=0
                for u,v in zip(padded(a[0],n),padded(a[1],n)):
                    if x.op=="add":
                        intermediate=emit("+",u,v);total=emit("+",intermediate,carry)
                        carry=emit("|",emit("<",intermediate,u),emit("<",total,intermediate))
                    else:
                        intermediate=emit("-",u,v);total=emit("-",intermediate,carry)
                        carry=emit("|",emit("<",u,v),emit("<",intermediate,carry))
                    out.append(total)
                result=tuple(out)
            else:raise ValueError("native behavior operation is unsupported: "+x.op)
            result=padded(result,n)
            if x.width%32:result=result[:-1]+(emit("&",result[-1],(1<<(x.width%32))-1),)
            return result
        words=visit(e)
        key=("native_wrapped",e.width,words)
        if key not in cache:
            name="native_value_"+str(len(cache));self.typ(e.width)
            lines.append(f"B{e.width} {name};")
            lines += [f"{name}.w[{j}]={show(value)};" for j,value in enumerate(words)]
            cache[key]=name
        return cache[key]
