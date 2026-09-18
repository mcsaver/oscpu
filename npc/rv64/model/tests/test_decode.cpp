#include "../src/decode.hpp"
#include <cassert>
using namespace r64model;
int main(){
 auto mv=decode(0x859a);assert(mv.length==2&&mv.dst==11&&mv.src[1]==6&&mv.src[0]==-1);
 auto add=decode(0x9316);assert(add.dst==6&&add.src[0]==6&&add.src[1]==5);
 auto ld=decode(0x002b283);assert(ld.kind==LOAD&&ld.base==5&&ld.dst==5&&ld.bytes==8);
 auto st=decode(enc_s(-8,6,5,3));assert(st.kind==STORE&&st.offset==-8&&st.src[1]==6&&st.dst==-1);
 auto div=decode(enc_r(1,6,5,4,7));assert(div.kind==DIV);
 assert(divide_cycles(div,1,0)==1);assert(divide_cycles(div,3,5)==6);
 assert(divide_cycles(div,128,1)==16); // 4 radix-4 digits, two phases each + 8
 auto w=decode(enc_r(1,6,5,4,7,0x3b));assert(divide_cycles(w,0x80000000,~0ull)==1);
 auto branch=decode(enc_b(-16,6,5,0));assert(branch.conditional&&branch.target_offset==-16);
 auto fp=decode(enc_r(0x70,0,5,0,6,0x53));assert(fp.src[0]==37&&fp.dst==6);
 bool bad=false;try{decode(0x0000002f);}catch(...){bad=true;}assert(bad);
}
