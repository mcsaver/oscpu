"""Independent deque/list specification. Does not import or evaluate the IR."""
from collections import Counter, deque
import random


class Reference:
    def __init__(self, layout):
        self.l = layout
        self.q = [deque() for _ in range(layout["n"])]
        self.held = [None for _ in range(layout["m"])]
        self.pointer = 0

    def resident(self):
        return [item for q in self.q for item in q] + [x for x in self.held if x is not None]

    def step(self, signals):
        l = self.l
        n, m = l["n"], l["m"]
        reset = bool(signals["reset"])
        kills = {signals[f"cancel{i}_owner"] for i in range(l["cancel_ports"])
                 if signals[f"cancel{i}_valid"]}
        old = self.resident()
        chosen = {}
        eligible = []
        for a in [(self.pointer+j) % n for j in range(n)]:
            i = l["input_for_arb"][a]
            if not reset and self.q[i] and self.q[i][0][0] not in kills:
                eligible.append((a, i))
        next_pointer = self.pointer
        for lane in range(m):
            if not reset and self.held[lane] is None and eligible:
                a, src = eligible.pop(0)
                chosen[lane] = src
                next_pointer = (a+1) % n
        selected = set(chosen.values())
        result = {}
        for i in range(n):
            valid = bool(signals[f"src{i}_offer"]) and signals[f"src{i}_owner"] not in kills and not reset
            ready = len(self.q[i]) < l["depths"][i] and not reset
            head = self.q[i][0] if self.q[i] else None
            qvalid = head is not None and head[0] not in kills and not reset
            result.update({
                f"in{i}_valid":int(valid), f"in{i}_ready":int(ready), f"in{i}_fire":int(valid and ready),
                f"in{i}_owner":signals[f"src{i}_owner"] if valid else 0,
                f"in{i}_data":signals[f"src{i}_data"] if valid else 0,
                f"q{i}_valid":int(qvalid), f"q{i}_ready":int(i in selected),
                f"q{i}_fire":int(i in selected), f"q{i}_owner":head[0] if qvalid else 0,
                f"q{i}_data":head[1] if qvalid else 0, f"q{i}_count":len(self.q[i]),
            })
        for lane in range(m):
            sink = l["sink_for_lane"][lane]
            item = self.held[lane]
            valid = item is not None and item[0] not in kills and not reset
            ready = bool(signals[f"sink{sink}_ready"]) and not reset
            result.update({
                f"out{sink}_valid":int(valid), f"out{sink}_ready":int(ready),
                f"out{sink}_fire":int(valid and ready),
                f"out{sink}_owner":item[0] if valid else 0, f"out{sink}_data":item[1] if valid else 0,
                f"out{sink}_occupied":int(item is not None),
            })
        result["inflight"] = len(old)
        result["cancelled"] = sum(t in kills for t, _ in old) if not reset else 0
        result["arbiter_pointer"] = self.pointer
        if reset:
            self.q = [deque() for _ in range(n)]
            self.held = [None for _ in range(m)]
            self.pointer = 0
            return result
        new_held = list(self.held)
        for lane, item in enumerate(self.held):
            sink = l["sink_for_lane"][lane]
            if item is not None and (item[0] in kills or signals[f"sink{sink}_ready"]):
                new_held[lane] = None
            if lane in chosen:
                new_held[lane] = self.q[chosen[lane]][0]
        for i in range(n):
            self.q[i] = deque(item for j, item in enumerate(self.q[i])
                              if item[0] not in kills and not (j == 0 and i in selected))
            if result[f"in{i}_fire"]:
                self.q[i].append((signals[f"src{i}_owner"], signals[f"src{i}_data"]))
        self.held = new_held
        self.pointer = next_pointer
        return result


class Suite:
    def __init__(self, manifest):
        self.manifest = manifest
        self.l = manifest["layout"]
        self.ref = Reference(self.l)
        self.pending = [None]*self.l["n"]
        self.serial = 0x100
        self.rng = random.Random(0x647)
        self.rows, self.expected, self.phases = [], [], []
        self.phase = "idle"

    def offer(self, index, owner=None):
        if self.pending[index] is not None:
            return
        mask = (1 << self.l["owner_bits"])-1
        if owner is None:
            used = {t for t,_ in self.ref.resident()} | {x[0] for x in self.pending if x}
            for _ in range(mask+1):
                self.serial = (self.serial+1)&mask
                if self.serial not in used:
                    owner = self.serial
                    break
            else:
                raise ValueError("owner namespace exhausted")
        payload = self.rng.getrandbits(self.l["payload_bits"])
        self.pending[index] = (owner & mask, payload)

    def tick(self, ready=None, kills=(), reset=False):
        ready = [1]*self.l["m"] if ready is None else ready
        row = {name:0 for name in self.manifest["inputs"]}
        row["reset"] = int(reset)
        for i,item in enumerate(self.pending):
            if item is not None:
                row[f"src{i}_offer"], row[f"src{i}_owner"], row[f"src{i}_data"] = 1,*item
        for i,value in enumerate(ready):
            row[f"sink{i}_ready"] = int(value)
        for i,owner in enumerate(list(dict.fromkeys(kills))[:self.l["cancel_ports"]]):
            row[f"cancel{i}_valid"],row[f"cancel{i}_owner"] = 1,owner
        expected = self.ref.step(row)
        for i,item in enumerate(self.pending):
            if reset or expected[f"in{i}_fire"] or (item and item[0] in kills):
                self.pending[i] = None
        self.rows.append(row)
        self.expected.append(expected)
        self.phases.append(self.phase)

    def drain(self):
        for _ in range(256):
            if not self.ref.resident() and not any(self.pending):
                self.tick()
                return
            self.tick()
        raise AssertionError("reference failed to drain")

    def generate(self, random_cycles=4000):
        n, m = self.l["n"],self.l["m"]
        for _ in range(5): self.tick()
        self.phase = "single_source"
        self.offer(0); self.drain()
        self.phase = "fill_and_backpressure"
        for _ in range(25):
            for i in range(n): self.offer(i)
            self.tick(ready=[0]*m)
        self.phase = "cancel_interior_and_output"
        targets = []
        if len(self.ref.q[0])>1: targets.append(self.ref.q[0][-1][0])
        targets += [x[0] for x in self.ref.held if x is not None]
        for t in targets: self.tick(ready=[0]*m,kills=[t])
        self.phase = "cancel_head_and_offer"
        if self.ref.q[-1]: self.tick(ready=[1]*m,kills=[self.ref.q[-1][0][0]])
        self.offer(0)
        if self.pending[0]: self.tick(kills=[self.pending[0][0]])
        self.drain()
        self.phase = "asymmetric_outputs"
        for cycle in range(100):
            for i in range(n): self.offer(i)
            self.tick(ready=[int(i==cycle//25 % m) for i in range(m)])
        self.drain()
        self.phase = "continuous_contention"
        for _ in range(180):
            for i in range(n): self.offer(i)
            self.tick()
        self.drain()
        self.phase = "generation_and_safe_reuse"
        self.offer(0,0x11); self.drain()
        self.offer(0,0x21); self.tick(kills=[0x11]); self.drain()
        self.offer(0,0x31); self.tick(ready=[0]*m); self.tick(ready=[0]*m,kills=[0x31]); self.drain()
        self.offer(0,0x31); self.drain()
        self.phase = "reset_with_inflight"
        for _ in range(12):
            for i in range(n): self.offer(i)
            self.tick(ready=[0]*m)
        self.tick(reset=True)
        self.tick()
        self.phase = "random_seed_1607"
        for cycle in range(random_cycles):
            for i in range(n):
                if self.rng.randrange(4): self.offer(i)
            ready = [self.rng.randrange(5)>0 for _ in range(m)]
            if cycle%127<30: ready=[0]*m
            kills=[]
            if self.rng.randrange(7)==0:
                candidates=self.ref.resident()+[x for x in self.pending if x is not None]
                if candidates:
                    kills=[self.rng.choice(candidates)[0] for _ in range(self.l["cancel_ports"])]
            self.tick(ready=ready,kills=kills)
        self.phase="final_drain"
        self.drain()
        return self


def audit(suite, actual):
    """Protocol scoreboard using observed boundary events, not internal IR state."""
    l=suite.l
    live={}
    stats=Counter()
    waits=Counter()
    phases=Counter()
    occupancy=Counter()
    source_stall=[0]*l["n"]
    output_stall=[0]*l["m"]
    head_wait={}
    max_head_wait=0
    previous={}
    for cycle,(row,out) in enumerate(zip(suite.rows,actual)):
        reset=bool(row["reset"])
        kills={row[f"cancel{i}_owner"] for i in range(l["cancel_ports"]) if row[f"cancel{i}_valid"]}
        phases[suite.phases[cycle]]+=1
        assert len(live)==out["inflight"], ("inflight conservation",cycle,len(live),out["inflight"])
        occupancy[out["inflight"]]+=1
        stats["max_inflight"]=max(stats["max_inflight"],out["inflight"])
        if reset:
            stats["reset_discarded"]+=len(live)
            stats["reset_with_inflight"]+=bool(live)
            live.clear()
        else:
            killed=set(live)&kills
            assert out["cancelled"]==len(killed), ("cancel accounting",cycle)
            stats["cancelled"]+=len(killed)
            for t in killed: del live[t]
        # Cancellation is allowed to withdraw a stalled message. Otherwise
        # every held interface must keep exactly the same owner and payload.
        for prefix,(owner,data) in previous.items():
            if not reset and owner not in kills:
                assert out[prefix+"_valid"] and (out[prefix+"_owner"],out[prefix+"_data"])==(owner,data), ("hold",cycle,prefix)
                stats["hold_checks"]+=1
        previous={}
        for prefix in ([f"in{i}" for i in range(l["n"])]+[f"q{i}" for i in range(l["n"])]+[f"out{i}" for i in range(l["m"])]):
            assert out[prefix+"_fire"]==out[prefix+"_valid"]*out[prefix+"_ready"], ("fire",cycle,prefix)
            if out[prefix+"_valid"] and not out[prefix+"_ready"]:
                previous[prefix]=(out[prefix+"_owner"],out[prefix+"_data"])
        for i in range(l["m"]):
            if out[f"out{i}_fire"]:
                tag,data=out[f"out{i}_owner"],out[f"out{i}_data"]
                assert tag in live and live[tag][0]==data, ("unowned/duplicate/torn delivery",cycle,tag)
                waits[cycle-live[tag][1]]+=1
                del live[tag]
                stats["delivered"]+=1
            stalled=out[f"out{i}_valid"] and not out[f"out{i}_ready"]
            output_stall[i]=output_stall[i]+1 if stalled else 0
            stats[f"output{i}_backpressure_cycles"]+=int(stalled)
            stats[f"output{i}_max_backpressure_run"]=max(stats[f"output{i}_max_backpressure_run"],output_stall[i])
        stats["dual_output_cycles"]+=sum(out[f"out{i}_fire"] for i in range(l["m"]))>=2
        if suite.phases[cycle]!="continuous_contention":
            head_wait.clear()
        for i in range(l["n"]):
            count=out[f"q{i}_count"]
            assert 0<=count<=l["depths"][i], ("capacity",cycle,i)
            assert out[f"in{i}_ready"]==int(not reset and count<l["depths"][i]), ("old-Q credit",cycle,i)
            if count==l["depths"][i] and out[f"q{i}_fire"]:
                stats["full_queue_pop_without_credit"]+=1
            if out[f"in{i}_fire"] and out[f"q{i}_fire"]:
                stats["simultaneous_push_pop"]+=1
            if out[f"in{i}_fire"]:
                t,d=out[f"in{i}_owner"],out[f"in{i}_data"]
                assert t not in live, ("owner reused while live",cycle,t)
                live[t]=(d,cycle)
                stats["accepted"]+=1
                stats[f"source{i}_accepted"]+=1
            if row[f"src{i}_offer"] and row[f"src{i}_owner"] in kills:
                assert not out[f"in{i}_fire"]
                stats["cancelled_offer"]+=1
            stalled=out[f"in{i}_valid"] and not out[f"in{i}_ready"]
            source_stall[i]=source_stall[i]+1 if stalled else 0
            stats[f"source{i}_backpressure_cycles"]+=int(stalled)
            stats[f"source{i}_max_backpressure_run"]=max(stats[f"source{i}_max_backpressure_run"],source_stall[i])
            stats[f"queue{i}_occupancy_sum"]+=count
            stats[f"queue{i}_arbitration_wait_cycles"]+=out[f"q{i}_valid"] and not out[f"q{i}_ready"]
            if suite.phases[cycle]=="continuous_contention" and out[f"q{i}_valid"]:
                t=out[f"q{i}_owner"]
                head_wait.setdefault(t,cycle)
                if out[f"q{i}_fire"]:
                    wait=cycle-head_wait.pop(t)
                    max_head_wait=max(max_head_wait,wait)
                    assert wait<=2*l["n"]+2, ("fairness under available sinks",cycle,wait)
        assert stats["accepted"]==stats["delivered"]+stats["cancelled"]+stats["reset_discarded"]+len(live)
    assert not live, "final network has live transactions"
    required=["full_queue_pop_without_credit","hold_checks","cancelled","cancelled_offer","reset_with_inflight","delivered"]
    if max(l["depths"])>1: required.append("simultaneous_push_pop")
    if l["m"]>1: required.append("dual_output_cycles")
    for name in required: assert stats[name]>0, ("uncovered acceptance",name)
    return {"cycles":len(actual),"stats":dict(stats),"phases":dict(phases),
            "latency_histogram":dict(sorted(waits.items())),"occupancy_histogram":dict(sorted(occupancy.items())),
            "maximum_head_wait_continuous_contention":max_head_wait,"final_inflight":0}
