"""Connected response/fault/forward -> cyclic event selection -> completion slice.

This is the production LSU terminal feedback network, not the entire LSU.
Inputs stop at the three existing ingress queue boundaries. All queue credit,
event arbitration, completion credit and round-robin feedback are internal.
"""
from always_ir import *
from compose import Network
from lsu_queue import request_queue
from lsu_completion import completion,all_of,any_of,RESULT_W
SOURCE="npc/rv64/vsrc/chengyue64/lsu/R64Lsu.v"

def reduce_or(xs,width):
    value=const(0,width)
    for x in xs:value=bor(value,x)
    return value

def order_select(n=6,slot_w=3):
    r=lambda s,w:ref(s,w);valid=r("valid_i",n);older=r("older_i",n*n)
    first=[];second=[]
    for i in range(n):
        preceding=band(valid,bit_slice(older,i*n,n));any_pre=nonzero(preceding)
        two=nonzero(band(preceding,sub(preceding,const(1,n))))
        first.append(all_of(bit_slice(valid,i),inv(any_pre)))
        second.append(all_of(bit_slice(valid,i),any_pre,inv(two)))
    fm=concat(*reversed(first));sm=concat(*reversed(second))
    values={"first_mask_o":fm,"second_mask_o":sm,"first_valid_o":nonzero(fm),"second_valid_o":nonzero(sm),
            "first_slot_o":reduce_or((mux(first[i],const(i,slot_w),const(0,slot_w)) for i in range(n)),slot_w),
            "second_slot_o":reduce_or((mux(second[i],const(i,slot_w),const(0,slot_w)) for i in range(n)),slot_w)}
    m=Model("R64LsuOrderSelect",{"valid_i":n,"older_i":n*n},{},{k:e.width for k,e in values.items()},
        [Block("select","comb",tuple(blocking(k,e) for k,e in values.items()),source="npc/rv64/vsrc/chengyue64/lsu/R64LsuOrderSelect.v:12")],
        outputs={k:ref(k,e.width) for k,e in values.items()})
    m.parameters={"N":n,"SLOT_W":slot_w};return m

def controller(tag_w):
    R=RESULT_W
    inputs={"rst_i":1,"valid_i":6,"first_i":6,"second_i":6,"credit_i":2,"tags_i":6*tag_w,"results_i":6*R}
    states={"event_before_q":6}
    wires={"order_o":36,"grant_o":6,"fire_o":2,"tags_o":2*tag_w,"results_o":2*R,"before_next":6}
    r=lambda n:ref(n,{**inputs,**states,**wires}[n]);b=lambda n,i:bit_slice(r(n),i)
    order=concat(*(any_of(all_of(b("event_before_q",e),inv(b("event_before_q",z))),
        all_of(eq(b("event_before_q",e),b("event_before_q",z)),const(int(z<e))))
        for e in reversed(range(6)) for z in reversed(range(6))))
    grant=bor(mux(b("credit_i",0),r("first_i"),const(0,6)),mux(b("credit_i",1),r("second_i"),const(0,6)))
    last=mux(all_of(b("credit_i",1),nonzero(r("second_i"))),r("second_i"),
             mux(b("credit_i",0),r("first_i"),const(0,6)))
    nxt=reduce_or((mux(bit_slice(last,i),const((1<<(i+1))-1,6),const(0,6)) for i in range(5)),6)
    two=nonzero(band(r("valid_i"),sub(r("valid_i"),const(1,6))))
    fire=band(concat(two,nonzero(r("valid_i"))),r("credit_i"))
    values={}
    for out,src,width in (("tags_o","tags_i",tag_w),("results_o","results_i",R)):
        picked=[]
        for select in ("first_i","second_i"):
            picked.append(reduce_or((mux(b(select,e),bit_slice(r(src),e*width,width),const(0,width)) for e in range(6)),width))
        values[out]=concat(*reversed(picked))
    blocks=[Block("order","comb",(blocking("order_o",order),),source=SOURCE+":1095"),
        Block("arbitrate","comb",(blocking("grant_o",grant),blocking("fire_o",fire),blocking("before_next",nxt)),source=SOURCE+":1082"),
        Block("payload","comb",tuple(blocking(k,e) for k,e in values.items()),source=SOURCE+":1117"),
        Block("priority","posedge",(If(r("rst_i"),(nba("event_before_q",const(0,6)),),
            (If(nonzero(r("grant_o")),(nba("event_before_q",r("before_next")),)),)),),source=SOURCE+":1092"),
        Block("count_check","posedge",(If(inv(r("rst_i")),(Check(eq(fire,band(concat(nonzero(r("second_i")),nonzero(r("first_i"))),r("credit_i"))),
            "event count changed completion acceptance"),)),),source=SOURCE+":1461")]
    m=Model("R64LsuEventController",inputs,states,wires,blocks,outputs={n:r(n) for n in wires if n!="before_next"})
    m.rtl_state_paths={"event_before_q":"event_before_q"};return m

def load_value(data,fn,amo,offset):
    shifted=indexed(data,concat(offset,const(0,3)),64)
    def signext(width):
        low=bit_slice(shifted,0,width)
        return concat(mux(bit_slice(low,width-1),const(mask(64-width),64-width),const(0,64-width)),low)
    normal=shifted
    for code,width in ((6,32),(5,16),(4,8),(2,32),(1,16),(0,8)):
        value=resize(bit_slice(shifted,0,width),64) if code>=4 else signext(width)
        normal=mux(eq(bit_slice(fn,0,3),const(code,3)),value,normal)
    fp=mux(eq(bit_slice(fn,0,2),const(2,2)),concat(const(mask(32),32),bit_slice(shifted,0,32)),shifted)
    return mux(all_of(bit_slice(fn,4),eq(amo,const(3,5))),data,
               mux(all_of(bit_slice(fn,3),inv(bit_slice(fn,4))),fp,normal))

def terminal(tag_w=9,rob_w=5,prepared_cancel=False):
    R=RESULT_W;slots=1<<rob_w
    inputs={"rst_i":1,"flush_i":1,"kill_mask_i":slots,"cancel_candidates_i":slots,"cancel_active_i":1,"out_ready_i":2}
    queue_specs=(("raw",152),("fault",70),("forward",77))
    for name,width in queue_specs:
        inputs.update({name+"_fire_i":2,name+"_tag_i":2*tag_w,name+"_data_i":2*width})
    network=Network("R64LsuTerminal",inputs)
    for name,width in queue_specs:network.add(name,request_queue(data_w=width,tag_w=tag_w,rob_w=rob_w,prepared_cancel=prepared_cancel))
    network.add("select",order_select());network.add("events",controller(tag_w));network.add("completion",completion(tag_w,rob_w))
    p=network.port;r=lambda n:ref(n,inputs[n])
    for index,(name,width) in enumerate(queue_specs):
        for port in ("rst_i","flush_i","kill_mask_i","cancel_candidates_i","cancel_active_i"):network.connect(name,port,r(port))
        for port,suffix in (("in_fire_i","fire_i"),("in_tag_i","tag_i"),("in_data_i","data_i")):network.connect(name,port,r(name+"_"+suffix))
        network.connect(name,"in_age_i",const(0,2));network.connect(name,"age_clear_i",const(0))
        network.connect(name,"out_ready_i",bit_slice(p("events","grant_o"),index*2,2))
    valid=concat(p("forward","out_valid_o"),p("fault","out_valid_o"),p("raw","out_valid_o"))
    tags=concat(*(p(n,"out_tag_o") for n,_ in reversed(queue_specs)))
    # Keep event payloads as separate aligned values on the GPU. Packing six
    # unrelated formats into an 840-bit intermediate mixes their word rules.
    format_inputs={};format_values={};format_bindings={}
    for source_index,(name,width) in enumerate(queue_specs):
        for lane in range(2):
            port=f"{name}{lane}_i";out=f"result{source_index*2+lane}_o"
            format_inputs[port]=width;format_bindings[port]=bit_slice(p(name,"out_data_o"),lane*width,width)
            v=ref(port,width);s=lambda low,w=1:bit_slice(v,low,w)
            if name=="raw":
                result=concat(const(0,5),add(s(78,64),resize(mux(s(148),s(149,3),const(0,3)),64)),
                    s(142,6),s(148),mux(s(64),const(0,64),load_value(s(0,64),s(73,5),s(68,5),s(65,3))))
            elif name=="fault":result=concat(const(0,5),s(6,64),s(0,6),const(1),const(0,64))
            else:result=concat(const(0,76),load_value(s(0,64),s(64,5),s(69,5),s(74,3)))
            format_values[out]=result
    formatter=Model("R64LsuResultFormat",format_inputs,{},dict.fromkeys(format_values,R),
        [Block(n,"comb",(blocking(n,v),),source=SOURCE+":1056") for n,v in format_values.items()],
        outputs={n:ref(n,R) for n in format_values})
    network.add("format",formatter)
    for port,value in format_bindings.items():network.connect("format",port,value)
    results=[p("format",n) for n in format_values]
    for port,value in {"rst_i":r("rst_i"),"valid_i":valid,"first_i":p("select","first_mask_o"),
        "second_i":p("select","second_mask_o"),"credit_i":p("completion","in_ready_o"),"tags_i":tags,
        "results_i":concat(*reversed(results))}.items():network.connect("events",port,value)
    network.connect("select","valid_i",valid);network.connect("select","older_i",p("events","order_o"))
    for port in ("rst_i","flush_i","kill_mask_i","out_ready_i"):network.connect("completion",port,r(port))
    for port,out in (("in_fire_i","fire_o"),("in_tag_i","tags_o"),("in_result_i","results_o")):
        network.connect("completion",port,p("events",out))
    outputs={n:p("completion",n) for n in ("out_valid_o","out_request_o","out_tag_o","out_result_o")}
    outputs.update({name+"_ready_o":p(name,"in_ready_o") for name,_ in queue_specs})
    outputs.update(event_grant_o=p("events","grant_o"),event_valid_o=valid,completion_fire_o=p("events","fire_o"),
                   completion_credit_o=p("completion","in_ready_o"))
    outputs["reuse_block_o"]=reduce_or((p(n,"reuse_block_o") for n in ("raw","fault","forward","completion")),slots)
    outputs["idle_o"]=all_of(*(p(n,"idle_o") for n in ("raw","fault","forward","completion")))
    m=network.build(outputs);m.parameters={"TAG_W":tag_w,"ROB_W":rob_w,"PREPARED_CANCEL":int(prepared_cancel)}
    m.rtl_state_paths["events__event_before_q"]="event_before_q"
    m.materialize={f"{name}__{port}" for name in ("raw","fault","forward")
                   for port in ("out_valid_o","out_tag_o")}
    m.materialize.update({"completion__in_ready_o","events__order_o","select__first_mask_o",
                          "select__second_mask_o","events__grant_o","events__fire_o","events__tags_o","events__results_o"})
    m.materialize.update("format__"+n for n in (*format_inputs,*format_values))
    return m
