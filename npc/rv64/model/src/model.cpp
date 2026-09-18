#include "decode.hpp"
#include <algorithm>
#include <chrono>
#include <deque>
#include <iomanip>
#include <iostream>
#include <limits>
#include <map>
#include <sstream>
using namespace r64model;
using Cycle=uint64_t;
constexpr Cycle NEVER=std::numeric_limits<Cycle>::max()/4;
constexpr size_t NONE=std::numeric_limits<size_t>::max();
struct Config {
 unsigned rob=32;
 unsigned iq=16;
 unsigned lsq=20;
 unsigned gpr=64;
 unsigned fpr=64;
 unsigned fetch_width=2;
 unsigned dispatch_width=2;
 unsigned issue_width=2;
 unsigned wb_width=2;
 unsigned commit_width=2;
 unsigned frontend_slots=24;
 unsigned decode_slots=4;
 unsigned frontend_latency=13;
 unsigned iq_init_latency=2;
 unsigned rr_latency=2;
 unsigned rr_slots_per_lane=3;
 unsigned alu_slots=4;
 unsigned mul_slots=8;
 unsigned clmul_slots=8;
 unsigned alu_latency=1;
 unsigned mul_latency=6;
 unsigned clmul_latency=6;
 unsigned early_alu_wake=1;
 unsigned wakeup_latency=1;
 unsigned wb_register_latency=1;
 unsigned wb_request_hints=1;
 unsigned retire_latency=1;
 unsigned icache_sets=64;
 unsigned icache_ways=2;
 unsigned icache_miss=23;
 unsigned dcache_sets=64;
 unsigned dcache_ways=2;
 unsigned translation_latency=5;
 unsigned lsu_query_latency=3;
 unsigned dcache_hit=2;
 unsigned dcache_miss=24;
 unsigned lsu_completion_latency=2;
 unsigned store_response=11;
 unsigned forward_latency=3;
 unsigned branch_recovery=8;
 unsigned predicted_taken_bubble=1;
 unsigned bimodal_entries=256;
 unsigned btb_entries=64;
 unsigned ras_entries=8;
 unsigned serial_latency=4;
 unsigned fp_fast_latency=6;
 unsigned fp_fma_latency=10;
 unsigned fp_long_latency=70;
 unsigned max_cycles=1000000000;
 std::map<std::string,unsigned> v{
 {"rob",32},{"iq",16},{"lsq",20},{"gpr",64},{"fpr",64},
 {"fetch_width",2},{"dispatch_width",2},{"issue_width",2},{"wb_width",2},{"commit_width",2},
 {"frontend_slots",24},{"decode_slots",4},{"frontend_latency",13},{"iq_init_latency",2},
 {"rr_latency",2},{"rr_slots_per_lane",3},{"alu_slots",4},{"mul_slots",8},{"clmul_slots",8},
 {"alu_latency",1},{"mul_latency",6},{"clmul_latency",6},{"early_alu_wake",1},
 {"wakeup_latency",1},{"wb_register_latency",1},{"wb_request_hints",1},{"retire_latency",1},
 {"icache_sets",64},{"icache_ways",2},{"icache_miss",23},{"dcache_sets",64},{"dcache_ways",2},
 {"translation_latency",5},{"lsu_query_latency",3},{"dcache_hit",2},{"dcache_miss",24},
 {"lsu_completion_latency",2},{"store_response",11},{"forward_latency",3},
 {"branch_recovery",8},{"predicted_taken_bubble",1},{"bimodal_entries",256},{"btb_entries",64},{"ras_entries",8},
 {"serial_latency",4},{"fp_fast_latency",6},{"fp_fma_latency",10},{"fp_long_latency",70},
 {"max_cycles",1000000000}
 };
 unsigned operator[](const std::string& k)const{return v.at(k);}
 void set(const std::string& line){
  auto end=line.find('#');auto s=line.substr(0,end);if(s.find_first_not_of(" \t\r\n")==std::string::npos)return;
  auto eq=s.find('=');require(eq!=std::string::npos,"expected key=value: "+s);
  auto trim=[](std::string x){auto a=x.find_first_not_of(" \t\r\n"),b=x.find_last_not_of(" \t\r\n");return a==std::string::npos?std::string():x.substr(a,b-a+1);};
  auto k=trim(s.substr(0,eq)),val=trim(s.substr(eq+1));require(v.count(k),"unknown model parameter: "+k);
  size_t consumed=0;auto value=std::stoull(val,&consumed,0);require(consumed==val.size()&&value<1000000001,"invalid value: "+s);v[k]=value;
 }
 void read(const std::string& path){std::ifstream in(path);require(bool(in),"cannot read config");std::string s;while(std::getline(in,s))set(s);}
 void validate(){
  rob=v.at("rob");
  iq=v.at("iq");
  lsq=v.at("lsq");
  gpr=v.at("gpr");
  fpr=v.at("fpr");
  fetch_width=v.at("fetch_width");
  dispatch_width=v.at("dispatch_width");
  issue_width=v.at("issue_width");
  wb_width=v.at("wb_width");
  commit_width=v.at("commit_width");
  frontend_slots=v.at("frontend_slots");
  decode_slots=v.at("decode_slots");
  frontend_latency=v.at("frontend_latency");
  iq_init_latency=v.at("iq_init_latency");
  rr_latency=v.at("rr_latency");
  rr_slots_per_lane=v.at("rr_slots_per_lane");
  alu_slots=v.at("alu_slots");
  mul_slots=v.at("mul_slots");
  clmul_slots=v.at("clmul_slots");
  alu_latency=v.at("alu_latency");
  mul_latency=v.at("mul_latency");
  clmul_latency=v.at("clmul_latency");
  early_alu_wake=v.at("early_alu_wake");
  wakeup_latency=v.at("wakeup_latency");
  wb_register_latency=v.at("wb_register_latency");
  wb_request_hints=v.at("wb_request_hints");
  retire_latency=v.at("retire_latency");
  icache_sets=v.at("icache_sets");
  icache_ways=v.at("icache_ways");
  icache_miss=v.at("icache_miss");
  dcache_sets=v.at("dcache_sets");
  dcache_ways=v.at("dcache_ways");
  translation_latency=v.at("translation_latency");
  lsu_query_latency=v.at("lsu_query_latency");
  dcache_hit=v.at("dcache_hit");
  dcache_miss=v.at("dcache_miss");
  lsu_completion_latency=v.at("lsu_completion_latency");
  store_response=v.at("store_response");
  forward_latency=v.at("forward_latency");
  branch_recovery=v.at("branch_recovery");
  predicted_taken_bubble=v.at("predicted_taken_bubble");
  bimodal_entries=v.at("bimodal_entries");
  btb_entries=v.at("btb_entries");
  ras_entries=v.at("ras_entries");
  serial_latency=v.at("serial_latency");
  fp_fast_latency=v.at("fp_fast_latency");
  fp_fma_latency=v.at("fp_fma_latency");
  fp_long_latency=v.at("fp_long_latency");
  max_cycles=v.at("max_cycles");
  for(const auto& [k,x]:v)require(x>0||k=="early_alu_wake"||k=="wb_request_hints"||k=="predicted_taken_bubble","zero capacity/latency: "+k);
  for(auto k:{"fetch_width","dispatch_width","issue_width","wb_width","commit_width"})require(v[k]<=2,std::string(k)+" must be 1 or 2 for the two-lane topology");
  require(v["gpr"]>32&&v["fpr"]>32,"PRF needs free physical destinations");
  for(auto k:{"icache_sets","dcache_sets","bimodal_entries","btb_entries"})require((v[k]&(v[k]-1))==0,std::string(k)+" must be a power of two");
  require(v["early_alu_wake"]<=1&&v["wb_request_hints"]<=1,"boolean parameter outside 0/1");
 }
};
struct Cache {
 struct Line{uint64_t tag=NEVER,age=0;Cycle valid_at=NEVER;};
 unsigned sets,ways;uint64_t age=0;std::vector<Line> lines;
 Cache(unsigned s,unsigned w):sets(s),ways(w),lines(s*w){}
 unsigned set(uint64_t a)const{return (a>>6)&(sets-1);}
 bool hit(uint64_t a,Cycle c,bool touch=true){
  for(unsigned w=0;w<ways;w++){auto& l=lines[set(a)*ways+w];if(l.tag==(a>>6)&&l.valid_at<=c){if(touch)l.age=++age;return true;}}return false;
 }
 void install(uint64_t a,Cycle ready){
  auto first=lines.begin()+set(a)*ways;
  auto p=std::min_element(first,first+ways,[](auto&a,auto&b){return a.age<b.age;});
  *p={a>>6,++age,ready};
 }
};
struct Op {
 Decoded d;size_t id;std::array<size_t,3> deps{{NONE,NONE,NONE}};
 Cycle fetch=NEVER,dispatch=NEVER,issue=NEVER,execute=NEVER,result=NEVER,wb=NEVER,retire=NEVER;
 Cycle translated=NEVER,query=NEVER;
 Cycle ready=NEVER,wake=NEVER,done=NEVER,mem_ready=NEVER,mem_end=NEVER,resolve=NEVER;
 int lane=-1,source=-1;bool mispredict=false,trained=false,mem_started=false,lsq_released=false,completed=false;
};
struct Predictor {
 std::vector<int> direction;std::vector<std::pair<uint64_t,uint64_t>> btb;std::vector<uint64_t> ras;unsigned depth;
 Predictor(const Config& p):direction(p.bimodal_entries,-1),btb(p.btb_entries,{NEVER,0}),depth(p.ras_entries){}
 uint64_t predict(const Record&r,const Decoded&d){
  uint64_t pc=r.pc+d.length;
  if(d.conditional){int v=direction[(r.pc>>1)&(direction.size()-1)];bool taken=v<0?d.target_offset<0:v>=2;
   if(taken)pc=r.pc+d.target_offset;
  }else if(d.indirect){
   auto b=btb[(r.pc>>1)&(btb.size()-1)];if(b.first==(r.pc>>7&0xffff))pc=b.second;
   if(d.ret&&!ras.empty()&&d.offset==0)pc=ras.back();
  }else pc=r.pc+d.target_offset;
  if(d.ret&&!ras.empty())ras.pop_back();
  if(d.call){if(ras.size()==depth)ras.erase(ras.begin());ras.push_back(r.pc+d.length);}
  return pc;
 }
 void train(const Record&r,const Decoded&d,bool wrong){
  if(d.conditional){auto&v=direction[(r.pc>>1)&(direction.size()-1)];bool t=r.next!=r.pc+d.length;
   v=v<0?(t?2:1):std::clamp(v+(t?1:-1),0,3);
  }else if(d.indirect)btb[(r.pc>>1)&(btb.size()-1)]={r.pc>>7&0xffff,r.next};
  if(wrong)ras.clear();
 }
};
struct Model {
 Config p;const std::vector<Record>& trace;std::vector<Op> ops;Cache ic,dc;Predictor predictor;
 std::deque<size_t> frontend,decodeq,rob,iq,lsq;std::array<std::deque<size_t>,2> rr;
 std::array<std::deque<size_t>,9> sources;std::array<unsigned,9> reserved{};
 std::array<size_t,64> rename;std::array<int,2> grant{{0,1}};
 std::map<std::string,uint64_t> stats,slots;std::array<uint64_t,KIND_COUNT> mix{};
 unsigned free_g,free_f,rotate=2,load_turn=0;Cycle c=0,fetch_after=0,read_until=0,store_until=0,bus_until=0;
 uint64_t read_address=0,store_address=0;size_t next=0,retired=0,blocked_branch=NONE;
 Cycle roi_first=NEVER,roi_last=0;size_t roi_begin=0,roi_count=0;std::ostream* stages=nullptr;
 Model(Config conf,const std::vector<Record>& t):p(conf),trace(t),ic(p.icache_sets,p.icache_ways),dc(p.dcache_sets,p.dcache_ways),predictor(p),free_g(p.gpr-32),free_f(p.fpr-32){
  rename.fill(NONE);ops.reserve(t.size());
  for(size_t i=0;i<t.size();i++){
   Op o;o.id=i;try{o.d=decode(t[i].raw);}catch(const std::exception&e){throw std::runtime_error("trace instruction "+std::to_string(i)+": "+e.what());}
   if(o.d.kind==LOAD||o.d.kind==STORE)require(t[i].address%o.d.bytes==0,"misaligned memory needs a split-transaction model");
   if(i+1<t.size())require(t[i].next==t[i+1].pc,"discontinuous functional trace");
   ops.push_back(o);
  }
 }
 bool operands(const Op&o)const{for(auto d:o.deps)if(d!=NONE&&ops[d].wake>c)return false;return true;}
 bool old_serial(size_t id)const{for(auto i:rob){if(i>=id)break;if(ops[i].d.kind==SERIAL)return true;}return false;}
 bool memory(Kind k)const{return k==LOAD||k==STORE;}
 int resource(const Decoded&d)const{
  switch(d.kind){case ALU:return 0;case BRANCH:return 1;case MUL:return 2;case DIV:return 3;
  case CLMUL:return 4;case FP:return 5;case LOAD:case STORE:return 6;case SERIAL:return 7;default:return -1;}
 }
 unsigned fp_reads(const Decoded&d)const{unsigned n=0;for(auto x:d.src)n+=x>=32;return n;}
 unsigned source_cap(int s)const{
  if(s<2)return p.alu_slots;
  if(s==2)return p.mul_slots;
  if(s==3)return 1;
  if(s==4)return p.clmul_slots;
  if(s==7)return 2;
  return p.lsq;
 }
 void release_lsq(Op&o){if(memory(o.d.kind)&&!o.lsq_released){o.lsq_released=true;auto it=std::find(lsq.begin(),lsq.end(),o.id);if(it!=lsq.end())lsq.erase(it);}}
 void write_stage(const Op&o){
  if(!stages)return;
  *stages<<o.id<<",0x"<<std::hex<<trace[o.id].pc<<std::dec<<","<<name(o.d.kind)<<","<<o.fetch<<","<<o.dispatch<<","<<o.issue<<","<<o.execute<<","<<o.result<<","<<o.wb<<","<<o.retire<<"\n";
 }
 std::string reason(size_t id)const{
  auto&o=ops[id];if(o.dispatch==NEVER)return "frontend";
  if(o.issue==NEVER)return operands(o)?"issue_resource":"dependency";
  if(o.execute==NEVER)return "register_read";
  if(o.d.kind==SERIAL)return "serial";
  if(memory(o.d.kind)&&o.result>c)return "memory";
  if(o.result>c)return "execution";
  return "completion";
 }
 void retire(){
  unsigned count=0;
  while(count<p.commit_width&&!rob.empty()){
   auto&o=ops[rob.front()];if(o.done>c)break;
   if(count&&o.d.kind==SERIAL)break;
   o.retire=c;mix[o.d.kind]++;write_stage(o);
   if(o.d.dst>=0){if(o.d.dst<32)free_g++;else free_f++;}
   release_lsq(o);rob.pop_front();retired++;count++;
   if(o.id>=roi_begin&&o.id<roi_begin+roi_count){roi_first=std::min(roi_first,c);roi_last=c;}
   if(o.d.kind==SERIAL)break;
  }
  stats["retire_"+std::to_string(count)]++;
  unsigned missing=p.commit_width-count;
  if(missing){auto r=rob.empty()?"rob_empty":reason(rob.front());slots[r]+=missing;}
 }
 void writeback(){
  // R64LsuCompletion rotates on accepted completion events, not instruction
  // IDs. Each fixed output lane owns a front and one skid entry; old skid
  // occupancy determines input credit even when WB also drains this edge.
  std::array<bool,2> credit{{sources[5].size()<2,sources[6].size()<2}};
  unsigned first=credit[load_turn]?load_turn:1-load_turn;
  std::array<size_t,2> pending{{NONE,NONE}};
  // Raw bank0 precedes raw bank1 in the LSU event selector.
  for(auto id:lsq){
   auto&o=ops[id];
   if(o.d.kind!=LOAD||!o.mem_started||o.completed||o.result>c)continue;
   unsigned bank=(trace[id].address>>3)&1;
   if(pending[bank]==NONE||o.mem_end<ops[pending[bank]].mem_end)pending[bank]=id;
  }
  unsigned accepted_loads=0;
  for(auto id:pending)if(id!=NONE){
   unsigned lane=accepted_loads?1-first:first;
   if(!credit[lane])break;
   auto&o=ops[id];o.source=5+lane;o.result=c;accepted_loads++;
  }
  if(accepted_loads)load_turn=1-first;

  // Demand/grant uses edge-old source validity. Each source can supply one owner.
  std::array<int,2> ng=grant;unsigned n=0;bool new_request=false;
  std::array<bool,9> requests{};
  for(unsigned k=0;k<9;k++){
   int s=(rotate+k)%9;bool demand=!sources[s].empty()&&ops[sources[s].front()].result<=c;
   if(p.wb_request_hints&&(s==5||s==6))
    for(auto id:lsq)if(ops[id].d.kind==LOAD&&ops[id].mem_started&&ops[id].source==s&&!ops[id].completed&&ops[id].result==c)demand=true;
   requests[s]=demand;
   if(demand&&s!=grant[0]&&(p.wb_width==1||s!=grant[1]))new_request=true;
  }
  // R64Writeback keeps existing grants until an ungranted source requests.
  // Priority advances by two ports, not by the winning source number.
  if(new_request){
   ng={{-1,-1}};
   for(unsigned k=0;k<9&&n<p.wb_width;k++){int s=(rotate+k)%9;if(requests[s])ng[n++]=s;}
   rotate=(rotate+2)%9;
  }
  unsigned accepted=0;
  for(unsigned lane=0;lane<p.wb_width;lane++){
   int s=grant[lane];if(s<0||sources[s].empty())continue;
   auto&o=ops[sources[s].front()];if(o.result>c)continue;
   sources[s].pop_front();reserved[s]--;o.wb=c;
   if(s<2&&p.early_alu_wake&&!sources[s].empty()){
    auto& head=ops[sources[s].front()];
    if(head.d.kind==ALU)head.wake=std::min(head.wake,std::max(c+1,head.result));
   }
   o.wake=std::min(o.wake,c+p.wb_register_latency+p.wakeup_latency);
   o.done=c+p.wb_register_latency+p.retire_latency;release_lsq(o);accepted++;
  }
  for(auto&q:sources)if(!q.empty()&&ops[q.front()].result<=c)stats["wb_source_wait"]++;
  stats["wb_accepted"]+=accepted;grant=ng;
 }
 void complete(){
  for(auto id:rob){
   auto&o=ops[id];
   if(o.resolve==c&&!o.trained){predictor.train(trace[id],o.d,o.mispredict);o.trained=true;
    if(o.mispredict){blocked_branch=NONE;fetch_after=std::max(fetch_after,c+p.branch_recovery);}}
   if(o.execute==NEVER||o.completed||o.result>c)continue;
   if(o.d.kind==LOAD&&o.source<0)continue;
   o.completed=true;
   if(o.d.kind==LOAD){reserved[o.source]++;release_lsq(o);}
   if(o.d.kind==STORE){o.wb=c;o.done=c+1;o.wake=c+1;}
   else{
    require(o.source>=0,"completion has no source");
    // R64AluLane also publishes at terminal capture when becoming bypass head.
    // This is essential when the early-accept promise was unavailable.
    if(o.d.kind==ALU&&p.early_alu_wake&&sources[o.source].empty())
     o.wake=std::min(o.wake,c);
    sources[o.source].push_back(id);
   }
  }
 }
 void memory_step(){
  unsigned banks=0;
  for(auto id:lsq){
   auto&o=ops[id];if(o.execute==NEVER||o.mem_started||o.translated>c)continue;
   auto&r=trace[id];bool mmio=r.address<0x80000000;
   if((o.d.kind==STORE||mmio)&&(rob.empty()||rob.front()!=id)){stats["memory_head_wait"]++;continue;}
   bool blocked=false,forward=false,ordering=false;
   if(o.d.kind==LOAD){
    for(auto older:lsq){if(older>=id)break;auto&s=ops[older];
     // R64Lsu.barrier_w includes every unbound/untranslated memory owner:
     // even an ordinary load can still resolve as IO until protection returns.
     if(s.translated>c){blocked=true;break;}
     if(trace[older].address<0x80000000&&s.done>c){blocked=true;break;}
     if(s.d.kind!=STORE)continue;
     ordering=true;
     uint64_t a=trace[older].address,b=r.address;
     if(a<b+o.d.bytes&&b<a+s.d.bytes){
      if(a<=b&&a+s.d.bytes>=b+o.d.bytes)forward=true;
      else if(s.done>c){blocked=true;break;}
     }
    }
   }
   if(blocked){stats["memory_order_wait"]++;continue;}
   if(o.mem_ready==NEVER){
    // Protected RAM responses may enter the query queue directly. A missed
    // direct path visits registered selection, descriptor and query capture.
    bool fast=o.d.kind==LOAD&&!mmio&&o.translated==c&&!ordering;
    o.query=c+(fast?0:p.lsu_query_latency);
    o.mem_ready=o.query+1;
    stats[fast?"load_direct_query":"memory_descriptor_query"]++;
   }
   if(o.mem_ready>c)continue;
   unsigned bank=(r.address>>3)&1;
   if(banks>>bank&1){stats["dcache_bank_conflict"]++;continue;}
   bool hit=dc.hit(r.address,c,false);
   if(o.d.kind==STORE){
    if(store_until>c||read_until>c){stats["store_port_wait"]++;continue;}
    o.mem_end=c+p.store_response;store_until=o.mem_end;store_address=r.address;
    stats["stores"]++;
   }else if(forward&&!mmio){
    o.mem_end=c+p.forward_latency;stats["forwarded_loads"]++;
   }else{
    bool overlap_ok=hit&&!mmio;
    if(read_until>c)overlap_ok&=((r.address>>3&1)!=(read_address>>3&1))&&dc.set(r.address)!=dc.set(read_address);
    if(store_until>c)overlap_ok&=((r.address>>3&1)!=(store_address>>3&1))&&dc.set(r.address)!=dc.set(store_address);
    if((read_until>c||store_until>c)&&!overlap_ok){stats["dcache_owner_wait"]++;continue;}
    if(hit&&!mmio){dc.hit(r.address,c);o.mem_end=c+p.dcache_hit+p.lsu_completion_latency;stats["dcache_hits"]++;}
    else{Cycle start=std::max(c,bus_until);
     o.mem_end=start+p.dcache_miss+p.lsu_completion_latency;
     read_until=start+p.dcache_miss;bus_until=read_until;read_address=r.address;
     if(!mmio)dc.install(r.address,read_until);
     stats["dcache_misses"]++;}
    if(mmio)stats["mmio_loads"]++;
   }
   banks|=1u<<bank;o.mem_started=true;o.result=o.mem_end;
   
  }
 }
 void execute(){
  unsigned shared_used=0;
  for(unsigned lane=0;lane<2;lane++){
   if(rr[lane].empty())continue;
   auto&o=ops[rr[lane].front()];if(o.ready>c)continue;
   int s=-1;unsigned latency=0;switch(o.d.kind){
    case ALU:case BRANCH:s=lane;latency=p.alu_latency;break;
    case MUL:s=2;latency=p.mul_latency;break;
    case DIV:s=3;latency=divide_cycles(o.d,trace[o.id].a,trace[o.id].b);break;
    case CLMUL:s=4;latency=p.clmul_latency;break;
    case FP:s=7;latency=o.d.fp_long?p.fp_long_latency:o.d.fp_fma?p.fp_fma_latency:p.fp_fast_latency;break;
    case SERIAL:s=8;latency=p.serial_latency;break;
    case LOAD:case STORE:break;
    default:break;
   }
   if(s>=2&&(shared_used&(1u<<s)))continue;
   if(s>=0&&reserved[s]>=source_cap(s)){stats["fu_credit_wait"]++;continue;}
   if(s>=2)shared_used|=1u<<s;
   o.execute=c;o.source=s;
   if(memory(o.d.kind)){
    o.translated=c+p.translation_latency;
    if(o.d.kind==STORE)o.mem_ready=o.translated+1;
   }
   else{
    if(o.d.kind==ALU&&p.early_alu_wake&&reserved[s]==0)o.wake=c+latency;
    o.result=c+latency;reserved[s]++;
   }
   if(o.d.kind==BRANCH)o.resolve=c+p.alu_latency;
   rr[lane].pop_front();
  }
 }
 void issue(){
  int first_resource=-1;unsigned fp_used=0,issued=0;
  for(unsigned lane=0;lane<2&&issued<p.issue_width;lane++){
   if(rr[lane].size()>=p.rr_slots_per_lane)continue;
   for(auto it=iq.begin();it!=iq.end();++it){
    auto&o=ops[*it];if(o.dispatch+p.iq_init_latency>c||!operands(o)||old_serial(o.id))continue;
    if(o.d.kind==SERIAL&&(rob.empty()||rob.front()!=o.id))continue;
    int res=resource(o.d);
    if(first_resource==res&&res!=0&&res!=6)continue;
    if(fp_used+fp_reads(o.d)>3)continue;
    o.issue=c;o.lane=lane;o.ready=c+p.rr_latency;rr[lane].push_back(o.id);iq.erase(it);
    first_resource=res;fp_used+=fp_reads(o.d);issued++;break;
   }
  }
  stats["issue_"+std::to_string(issued)]++;
 }
 void dispatch(){
  unsigned count=0;
  while(count<p.dispatch_width&&!decodeq.empty()){
   auto&o=ops[decodeq.front()];
   if(o.ready>c)break;
   std::string block;
   if(rob.size()>=p.rob)block="dispatch_rob";
   else if(iq.size()>=p.iq)block="dispatch_iq";
   else if(memory(o.d.kind)&&lsq.size()>=p.lsq)block="dispatch_lsq";
   else if(o.d.dst>=0&&(o.d.dst<32?free_g:free_f)==0)block="dispatch_prf";
   if(!block.empty()){stats[block]++;break;}
   for(unsigned i=0;i<3;i++)if(o.d.src[i]>=0)o.deps[i]=rename[o.d.src[i]];
   if(o.d.dst>=0){rename[o.d.dst]=o.id;if(o.d.dst<32)free_g--;else free_f--;}
   o.dispatch=c;rob.push_back(o.id);iq.push_back(o.id);if(memory(o.d.kind))lsq.push_back(o.id);
   decodeq.pop_front();count++;
  }
 }
 void frontend_step(){
  unsigned count=0;
  while(!frontend.empty()&&ops[frontend.front()].ready<=c&&decodeq.size()<p.decode_slots&&count<p.dispatch_width){
   auto id=frontend.front();frontend.pop_front();decodeq.push_back(id);ops[id].ready=c+1;count++;
  }
  if(blocked_branch!=NONE||c<fetch_after){stats["fetch_blocked"]++;return;}
  for(unsigned n=0;n<p.fetch_width&&next<trace.size()&&frontend.size()<p.frontend_slots;n++){
   auto&r=trace[next];auto&o=ops[next];
   if(!ic.hit(r.pc,c)){
    fetch_after=std::max(c,bus_until)+p.icache_miss;bus_until=fetch_after;ic.install(r.pc,fetch_after);stats["icache_misses"]++;break;
   }
   if((r.pc&63)+o.d.length>64&&!ic.hit(r.pc+o.d.length-1,c)){
    fetch_after=std::max(c,bus_until)+p.icache_miss;bus_until=fetch_after;ic.install(r.pc+o.d.length-1,fetch_after);stats["icache_misses"]++;break;
   }
   o.fetch=c;o.ready=c+p.frontend_latency;frontend.push_back(next);next++;
   if(o.d.kind==BRANCH){
    auto predicted=predictor.predict(r,o.d);stats["branches"]++;
    if(predicted!=r.next){o.mispredict=true;blocked_branch=o.id;stats["branch_mispredicts"]++;break;}
    if(predicted!=r.pc+o.d.length){fetch_after=c+p.predicted_taken_bubble;break;}
   }
  }
 }
 void run(){
  if(stages)*stages<<"id,pc,kind,fetch,dispatch,issue,execute,result,wb,retire\n";
  for(c=0;retired<trace.size()&&c<p.max_cycles;c++){
   retire();writeback();complete();memory_step();execute();issue();dispatch();frontend_step();
   stats["rob_occupancy_sum"]+=rob.size();stats["iq_occupancy_sum"]+=iq.size();stats["lsq_occupancy_sum"]+=lsq.size();
  }
  require(retired==trace.size(),"model cycle limit exceeded");
 }
 void json(std::ostream&out,const TraceHeader&h,double seconds)const{
  out<<"{\n  \"model\": \"chengyue64-cycle-model-v0.1\",\n  \"scope\": \"correct-path bare-mode timing; approximate frontend/LSU/FP; no wrong-path traffic\",\n";
  out<<"  \"instructions\": "<<retired<<",\n  \"cycles\": "<<c<<",\n  \"cpi\": "<<double(c)/retired<<",\n";
  out<<"  \"host_seconds\": "<<seconds<<",\n  \"trace_natural_end\": "<<((h.flags&1)?"true":"false")<<",\n  \"trace_timing_inputs\": "<<((h.flags&2)?"true":"false")<<",\n";
  if(roi_count)out<<"  \"roi\": {\"start_instruction\": "<<roi_begin<<", \"instructions\": "<<roi_count<<", \"inclusive_retirement_span\": "<<roi_last-roi_first+1<<"},\n";
  auto dict=[&](const char*label,const auto&values){
   out<<"  \""<<label<<"\": {";bool first=true;for(const auto&[k,v]:values){out<<(first?"\n":",\n")<<"    \""<<k<<"\": "<<v;first=false;}out<<"\n  }";
  };
  dict("config",p.v);out<<",\n";dict("events",stats);out<<",\n";dict("unused_retire_slots",slots);out<<",\n";
  std::map<std::string,uint64_t> m;for(unsigned i=0;i<KIND_COUNT;i++)m[name(Kind(i))]=mix[i];dict("instruction_mix",m);out<<"\n}\n";
 }
};
int main(int argc,char**argv){try{
 require(argc>=2,"usage: r64-model TRACE [--config FILE] [--set key=value] [--output FILE] [--stages CSV] [--roi START:COUNT]");
 Config p;std::string output,stagefile;size_t begin=0,count=0;
 for(int i=2;i<argc;i++){std::string a=argv[i];require(i+1<argc,"missing option value");std::string value=argv[++i];
  if(a=="--config")p.read(value);else if(a=="--set")p.set(value);else if(a=="--output")output=value;
  else if(a=="--stages")stagefile=value;else if(a=="--roi"){auto k=value.find(':');require(k!=std::string::npos,"ROI must be START:COUNT");begin=std::stoull(value.substr(0,k));count=std::stoull(value.substr(k+1));}
  else throw std::runtime_error("unknown option: "+a);
 }
 p.validate();TraceHeader header;auto trace=read_trace(argv[1],header);Model m(p,trace);
 require(begin<=trace.size()&&count<=trace.size()-begin,"ROI out of trace");m.roi_begin=begin;m.roi_count=count;
 std::ofstream stages;if(!stagefile.empty()){stages.open(stagefile);require(bool(stages),"cannot open stages output");m.stages=&stages;}
 auto start=std::chrono::steady_clock::now();m.run();
 double seconds=std::chrono::duration<double>(std::chrono::steady_clock::now()-start).count();
 if(output.empty())m.json(std::cout,header,seconds);else{std::ofstream out(output);require(bool(out),"cannot open output");m.json(out,header,seconds);require(bool(out),"output write failed");}
 if(stages.is_open()){stages.close();require(bool(stages),"stages write failed");}
 return 0;
 }catch(const std::exception&e){std::cerr<<"model error: "<<e.what()<<"\n";return 1;}}
