#pragma once
#include "trace.hpp"
namespace r64model {
inline int64_t sext(uint64_t x,unsigned bits){return int64_t(x<<(64-bits))>>(64-bits);}
inline uint32_t enc_i(int imm,int rs,int fn,int rd,int op=0x13){
 return ((uint32_t(imm)&4095)<<20)|(rs<<15)|(fn<<12)|(rd<<7)|op;
}
inline uint32_t enc_r(int f7,int rs2,int rs1,int f3,int rd,int op=0x33){
 return (f7<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|op;
}
inline uint32_t enc_s(int imm,int rs2,int rs1,int f3,int op=0x23){
 return ((uint32_t(imm)&0xfe0)<<20)|(rs2<<20)|(rs1<<15)|(f3<<12)|((imm&31)<<7)|op;
}
inline uint32_t enc_b(int imm,int rs2,int rs1,int f3){
 uint32_t v=imm;return ((v>>12&1)<<31)|((v>>5&63)<<25)|(rs2<<20)|(rs1<<15)|
 (f3<<12)|((v>>1&15)<<8)|((v>>11&1)<<7)|0x63;
}
inline uint32_t enc_j(int imm,int rd){
 uint32_t v=imm;return ((v>>20&1)<<31)|((v>>1&1023)<<21)|((v>>11&1)<<20)|(v&0xff000)|(rd<<7)|0x6f;
}
inline uint32_t expand(uint32_t x){
 if((x&3)==3)return x;
 int q=x&3,f=x>>13&7,rd=x>>7&31,r2=x>>2&31,rp=8+(x>>7&7),sp=8+(x>>2&7);
 int imm=sext(((x>>12&1)<<5)|(x>>2&31),6);
 if(q==0){
  if(f==0){int v=((x>>7&15)<<6)|((x>>11&3)<<4)|((x>>5&1)<<3)|((x>>6&1)<<2);
   require(v!=0,"illegal C.ADDI4SPN");return enc_i(v,2,0,sp);}
  if(f==1||f==2||f==3||f==5||f==6||f==7){
   bool wide=(f&3)!=2;int v=((x>>10&7)<<3)|(wide?((x>>5&3)<<6):((x>>6&1)<<2)|((x>>5&1)<<6));
   if(f<4)return enc_i(v,rp,wide?3:2,sp,f==1?7:3);
   return enc_s(v,sp,rp,wide?3:2,f==5?0x27:0x23);
  }
 }else if(q==1){
  if(f==0)return enc_i(imm,rd,0,rd);
  if(f==1){require(rd!=0,"illegal C.ADDIW");return enc_i(imm,rd,0,rd,0x1b);}
  if(f==2)return enc_i(imm,0,0,rd);
  if(f==3){
   if(rd==2){int v=((x>>12&1)<<9)|((x>>6&1)<<4)|((x>>5&1)<<6)|((x>>3&3)<<7)|((x>>2&1)<<5);
    require(v!=0,"illegal C.ADDI16SP");return enc_i(sext(v,10),2,0,2);}
   require(rd!=0&&imm!=0,"illegal C.LUI");return (uint32_t(imm)<<12)|(rd<<7)|0x37;
  }
  if(f==4){
   int mode=x>>10&3;
   if(mode<2)return enc_i((mode?0x400:0)+(imm&63),rp,5,rp);
   if(mode==2)return enc_i(imm,rp,7,rp);
   int fn=x>>5&3;
   if(x>>12&1){require(fn<2,"reserved compressed ALU");return enc_r(fn?0:32,sp,rp,0,rp,0x3b);}
   int f3[]={0,4,6,7};return enc_r(fn==0?32:0,sp,rp,f3[fn],rp);
  }
  if(f==5){
   int v=((x>>12&1)<<11)|((x>>11&1)<<4)|((x>>9&3)<<8)|((x>>8&1)<<10)|
    ((x>>7&1)<<6)|((x>>6&1)<<7)|((x>>3&7)<<1)|((x>>2&1)<<5);
   return enc_j(sext(v,12),0);
  }
  if(f==6||f==7){
   int v=((x>>12&1)<<8)|((x>>10&3)<<3)|((x>>5&3)<<6)|((x>>3&3)<<1)|((x>>2&1)<<5);
   return enc_b(sext(v,9),0,rp,f==7?1:0);
  }
 }else if(q==2){
  if(f==0)return enc_i(imm&63,rd,1,rd);
  if(f==1||f==2||f==3){
   bool wide=f!=2;require(rd!=0||f==1,"illegal stack load");
   int v=((x>>12&1)<<5)|(wide?((x>>5&3)<<3)|((x>>2&7)<<6):((x>>4&7)<<2)|((x>>2&3)<<6));
   return enc_i(v,2,wide?3:2,rd,f==1?7:3);
  }
  if(f==4){
   if(!(x>>12&1))return r2?enc_r(0,r2,0,0,rd):enc_i(0,rd,0,0,0x67);
   if(!rd&&!r2)return 0x00100073;
   return r2?enc_r(0,r2,rd,0,rd):enc_i(0,rd,0,1,0x67);
  }
  if(f==5||f==6||f==7){
   bool wide=f!=6;int v=wide?((x>>10&7)<<3)|((x>>7&7)<<6):((x>>9&15)<<2)|((x>>7&3)<<6);
   return enc_s(v,r2,2,wide?3:2,f==5?0x27:0x23);
  }
 }
 throw std::runtime_error("unsupported/reserved compressed instruction");
}
enum Kind{ALU,BRANCH,MUL,DIV,CLMUL,LOAD,STORE,FP,SERIAL,KIND_COUNT};
inline const char* name(Kind k){static const char* n[]={"alu","branch","mul","div","clmul","load","store","fp","serial"};return n[k];}
struct Decoded{
 Kind kind=ALU;std::array<int,3> src{{-1,-1,-1}};int dst=-1,base=0,rs1=0,rs2=0,rd=0;
 unsigned bytes=0,length=4,f3=0;uint32_t canonical=0;int64_t offset=0,target_offset=0;
 bool conditional=false,indirect=false,call=false,ret=false,word=false,div_unsigned=false;
 bool fp_long=false,fp_fma=false,timing_csr=false;
};
inline Decoded decode(uint32_t raw){
 Decoded d;d.length=(raw&3)==3?4:2;uint32_t x=expand(raw);d.canonical=x;
 unsigned op=x&127,rd=x>>7&31,f=x>>12&7,r1=x>>15&31,r2=x>>20&31,f7=x>>25;
 d.rd=rd;d.rs1=r1;d.rs2=r2;d.f3=f;
 auto src=[&](int slot,int r,bool fp=false){d.src[slot]=fp?32+r:(r?r:-1);};
 auto dst=[&](bool fp=false){d.dst=fp?32+rd:(rd?int(rd):-1);};
 switch(op){
 case 0x37:case 0x17:dst();break;
 case 0x13:case 0x1b:src(0,r1);dst();break;
 case 0x33:case 0x3b:
  src(0,r1);src(1,r2);dst();d.word=op==0x3b;
  if(f7==1){d.kind=f<4?MUL:DIV;d.div_unsigned=f&1;}
  else if(f7==5&&f>=1&&f<=3)d.kind=CLMUL;
  break;
 case 0x63:
  d.kind=BRANCH;d.conditional=true;src(0,r1);src(1,r2);
  d.target_offset=sext(((x>>31)<<12)|((x>>7&1)<<11)|((x>>25&63)<<5)|((x>>8&15)<<1),13);break;
 case 0x6f:
  d.kind=BRANCH;dst();d.call=rd==1||rd==5;
  d.target_offset=sext(((x>>31)<<20)|(x&0xff000)|((x>>20&1)<<11)|((x>>21&1023)<<1),21);break;
 case 0x67:
  require(f==0,"invalid JALR");d.kind=BRANCH;d.indirect=true;src(0,r1);dst();d.offset=sext(x>>20,12);
  d.call=rd==1||rd==5;d.ret=(r1==1||r1==5)&&r1!=rd;break;
 case 3:case 7:
  require(op==7?(f==2||f==3):f<=6,"unsupported load");
  d.kind=LOAD;src(0,r1);dst(op==7);d.base=r1;d.offset=sext(x>>20,12);d.bytes=1u<<(f&3);break;
 case 0x23:case 0x27:
  require(op==0x27?(f==2||f==3):f<4,"unsupported store");
  d.kind=STORE;src(0,r1);src(1,r2,op==0x27);d.base=r1;
  d.offset=sext(((x>>25)<<5)|(x>>7&31),12);d.bytes=1u<<f;break;
 case 0x43:case 0x47:case 0x4b:case 0x4f:
  d.kind=FP;d.fp_fma=true;src(0,r1,true);src(1,r2,true);src(2,x>>27,true);dst(true);break;
 case 0x53:{
  d.kind=FP;unsigned family=f7&~1u;d.fp_long=family==0x0c||family==0x2c;
  bool intsrc=family==0x68||family==0x78,intdst=family==0x50||family==0x60||family==0x70;
  src(0,r1,!intsrc);dst(!intdst);
  if(family==0||family==4||family==8||family==12||family==16||family==20||family==80)src(1,r2,true);
  break;}
 case 0x0f:d.kind=SERIAL;break;
 case 0x73:{
  require(f!=0,"system trap/return/WFI unsupported in bare-mode timing model");
  d.kind=SERIAL;if(!(f&4))src(0,r1);dst();unsigned csr=x>>20;
  require(csr!=0x180,"SATP access requires an MMU model");
  d.timing_csr=csr==0xc00||csr==0xc01||csr==0xc02||csr==0xb00||csr==0xb02;break;}
 default:throw std::runtime_error("unsupported opcode (atomics/vector/custom/privileged not modeled)");
 }
 return d;
}
inline unsigned divide_cycles(const Decoded& d,uint64_t a,uint64_t b){
 if(d.word){a=d.div_unsigned?uint32_t(a):uint64_t(int64_t(int32_t(a)));b=d.div_unsigned?uint32_t(b):uint64_t(int64_t(int32_t(b)));}
 uint64_t min=d.word?uint64_t(int64_t(INT32_MIN)):(1ull<<63);
 if(b==0||(!d.div_unsigned&&a==min&&b==UINT64_MAX))return 1;
 if(!d.div_unsigned){if(int64_t(a)<0)a=0-a;if(int64_t(b)<0)b=0-b;}
 if(a<b)return 6;
 unsigned diff=unsigned(__builtin_clzll(b)-__builtin_clzll(a));return 8+2*(diff/2+1);
}
}
