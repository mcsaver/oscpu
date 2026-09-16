// Deterministic native-FP oracle vectors. Link against Berkeley SoftFloat
// compiled with SPECIALIZE_TYPE=RISCV and tininess-after-rounding.
#include <stdint.h>
#include <stdio.h>
#include "softfloat.h"
static uint64_t random_state=UINT64_C(0x8b734cf53b17a729);
static uint64_t random64(void){
  uint64_t x=random_state;x^=x<<13;x^=x>>7;x^=x<<17;return random_state=x;
}
static const uint64_t corners[]={
  0,UINT64_C(0x8000000000000000),1,UINT64_C(0x000fffffffffffff),
  UINT64_C(0x0010000000000000),UINT64_C(0x7fefffffffffffff),
  UINT64_C(0x7ff0000000000000),UINT64_C(0xfff0000000000000),
  UINT64_C(0x7ff0000000000001),UINT64_C(0x7ff8000000000001),
  UINT64_C(0x3ff0000000000000),UINT64_C(0x3ff0000010000000),
  UINT64_C(0x36a0000000000000),UINT64_C(0x380fffffe0000000),
  UINT64_C(0x47efffffe0000000),UINT64_C(0x47effffff0000000)};
static const uint32_t scorners[]={
  0,0x80000000,1,0x007fffff,0x00800000,0x7f7fffff,0x7f800000,0xff800000,
  0x7f800001,0x7fc00001,0x3f800000,0x3f000000,0x80000001,0xbf800000,0xffffffff,0x00000002};
static void generate_fma(void){
  for(unsigned n=0;n<30000;n++){
    unsigned op=n%7,df=(n/7)%2,rm=(n/14)%5;
    uint64_t a=random64(),b=random64(),c=random64();
    if(df){
      if(n%4==0){a=corners[(n/4)%16];b=corners[(n/64)%16];c=corners[(n/1024)%16];}
    }else{
      a|=UINT64_C(0xffffffff00000000);b|=UINT64_C(0xffffffff00000000);c|=UINT64_C(0xffffffff00000000);
      if(n%4==0){a=UINT64_C(0xffffffff00000000)|scorners[(n/4)%16];
        b=UINT64_C(0xffffffff00000000)|scorners[(n/64)%16];c=UINT64_C(0xffffffff00000000)|scorners[(n/1024)%16];}
    }
    if(n%97==0){df=1;op=3;a=UINT64_C(0x3ff0000000000001);b=UINT64_C(0x3fefffffffffffff);c=UINT64_C(0xbff0000000000000);}
    if(n%223==0&&!df)a&=UINT64_C(0x00000000ffffffff);
    float64_t da={a},db={b},dc={c},dr;
    float32_t sa={(uint32_t)a},sb={(uint32_t)b},sc={(uint32_t)c},sr;
    if(!df&&(a>>32)!=UINT32_MAX)sa.v=0x7fc00000;
    softfloat_roundingMode=rm;softfloat_exceptionFlags=0;
    uint64_t result;
    if(df){
      if(op==0)dr=f64_add(da,db);else if(op==1)dr=f64_sub(da,db);else if(op==2)dr=f64_mul(da,db);
      else{if(op>=5)da.v^=UINT64_C(0x8000000000000000);if(op==4||op==6)dc.v^=UINT64_C(0x8000000000000000);dr=f64_mulAdd(da,db,dc);}
      result=dr.v;
    }else{
      if(op==0)sr=f32_add(sa,sb);else if(op==1)sr=f32_sub(sa,sb);else if(op==2)sr=f32_mul(sa,sb);
      else{if(op>=5)sa.v^=0x80000000;if(op==4||op==6)sc.v^=0x80000000;sr=f32_mulAdd(sa,sb,sc);}
      result=UINT64_C(0xffffffff00000000)|sr.v;
    }
    printf("%u %u %u %016llx %016llx %016llx %016llx %02x\n",op,df,rm,
      (unsigned long long)a,(unsigned long long)b,(unsigned long long)c,(unsigned long long)result,
      (unsigned)softfloat_exceptionFlags);
  }
}

static void generate_long(void){
 for(unsigned n=0;n<12000;n++){
   unsigned op=n%2,df=(n/2)%2,rm=(n/4)%5;
   uint64_t a=random64(),b=random64(),result;
   if(n%3==0){a=df?corners[(n/3)%16]:scorners[(n/3)%16];b=df?corners[(n/48)%16]:scorners[(n/48)%16];}
   if(!df){a|=UINT64_C(0xffffffff00000000);b|=UINT64_C(0xffffffff00000000);}
   if(n%71==0&&!df)a&=UINT64_C(0xffffffff);
   float64_t da={a},db={b};float32_t sa={(uint32_t)a},sb={(uint32_t)b};
   if(!df&&(a>>32)!=UINT32_MAX)sa.v=0x7fc00000;
   softfloat_roundingMode=rm;softfloat_exceptionFlags=0;
   if(df)result=op?f64_sqrt(da).v:f64_div(da,db).v;
   else result=UINT64_C(0xffffffff00000000)|(op?f32_sqrt(sa).v:f32_div(sa,sb).v);
   printf("%u %u %u %016llx %016llx %016llx %02x\n",op,df,rm,(unsigned long long)a,
     (unsigned long long)b,(unsigned long long)result,(unsigned)softfloat_exceptionFlags);
 }
}

static void generate_fast(void){
 for(unsigned n=0;n<80000;n++){
  unsigned op=n%20,df=(n/20)%2,rm=(n/40)%5,srcdf=op==11?!df:df;
  uint64_t a=random64(),b=random64(),result=0;uint32_t inst=0x53,f7=0,f3=0,rs2=0;
  if(n%3==0){a=srcdf?corners[(n/3)%16]:scorners[(n/3)%16];b=df?corners[(n/48)%16]:scorners[(n/48)%16];}
  if(!srcdf&&op<16)a|=UINT64_C(0xffffffff00000000);
  if(!df)b|=UINT64_C(0xffffffff00000000);
  if(n%71==0&&!srcdf)a&=UINT64_C(0xffffffff);
  uint64_t aa=a,bb=b;
  if(!srcdf&&(aa>>32)!=UINT32_MAX)aa=UINT64_C(0xffffffff7fc00000);
  if(!df&&(bb>>32)!=UINT32_MAX)bb=UINT64_C(0xffffffff7fc00000);
  uint64_t mask=srcdf?UINT64_C(0x7fffffffffffffff):UINT64_C(0x7fffffff);
  uint64_t am=aa&mask,bm=bb&mask;
  uint64_t inf=srcdf?UINT64_C(0x7ff0000000000000):UINT64_C(0x7f800000);
  uint64_t quiet=srcdf?UINT64_C(0x8000000000000):UINT64_C(0x400000);
  unsigned sa=(aa>>(srcdf?63:31))&1,sb=(bb>>(df?63:31))&1;
  int anan=am>inf,bnan=bm>inf,asn=anan&&!(am&quiet),bsn=bnan&&!(bm&quiet);
  float64_t da={aa},db={bb};float32_t fa={(uint32_t)aa},fb={(uint32_t)bb};
  softfloat_roundingMode=rm;softfloat_exceptionFlags=0;
  if(op<=2){
   f7=0x10+df;f3=op;unsigned sign=op==0?sb:op==1?!sb:sa^sb;
   result=(aa&mask)|((uint64_t)sign<<(df?63:31));if(!df)result|=UINT64_C(0xffffffff00000000);
  }else if(op<=4){
   f7=0x14+df;f3=op-3;
   if(anan&&bnan)result=df?UINT64_C(0x7ff8000000000000):UINT64_C(0xffffffff7fc00000);
   else if(anan)result=bb;else if(bnan)result=aa;
   else if(am==0&&bm==0){unsigned sign=op==3?(sa|sb):(sa&sb);result=(uint64_t)sign<<(df?63:31);if(!df)result|=UINT64_C(0xffffffff00000000);}
   else {int less=df?f64_lt_quiet(da,db):f32_lt_quiet(fa,fb);result=(less^(op==4))?aa:bb;}
   softfloat_exceptionFlags=(asn||bsn)?16:0;
  }else if(op<=7){
   f7=0x50+df;f3=op-5;
   if(df)result=op==5?f64_le(da,db):op==6?f64_lt(da,db):f64_eq(da,db);
   else result=op==5?f32_le(fa,fb):op==6?f32_lt(fa,fb):f32_eq(fa,fb);
  }else if(op==8){
   f7=0x70+df;f3=1;unsigned bit;
   uint64_t emin=df?UINT64_C(0x0010000000000000):UINT64_C(0x00800000);
   bit=anan?(asn?8:9):am==inf?(sa?0:7):am==0?(sa?3:4):am<emin?(sa?2:5):(sa?1:6);
   result=UINT64_C(1)<<bit;
  }else if(op==9){f7=0x70+df;result=df?a:(uint64_t)(int64_t)(int32_t)a;}
  else if(op==10){f7=0x78+df;result=df?a:UINT64_C(0xffffffff00000000)|(uint32_t)a;}
  else if(op==11){f7=0x20+df;rs2=!df;f3=rm;result=df?f32_to_f64(fa).v:UINT64_C(0xffffffff00000000)|f64_to_f32(da).v;}
  else if(op<=15){
   f7=0x60+df;rs2=op-12;f3=rm;
   if(df){switch(rs2){case 0:result=(int64_t)(int32_t)f64_to_i32(da,rm,1);break;case 1:result=(int64_t)(int32_t)f64_to_ui32(da,rm,1);break;case 2:result=f64_to_i64(da,rm,1);break;default:result=f64_to_ui64(da,rm,1);}}
   else {switch(rs2){case 0:result=(int64_t)(int32_t)f32_to_i32(fa,rm,1);break;case 1:result=(int64_t)(int32_t)f32_to_ui32(fa,rm,1);break;case 2:result=f32_to_i64(fa,rm,1);break;default:result=f32_to_ui64(fa,rm,1);}}
  }else{
   f7=0x68+df;rs2=op-16;f3=rm;
   if(df){switch(rs2){case 0:result=i32_to_f64((int32_t)a).v;break;case 1:result=ui32_to_f64((uint32_t)a).v;break;case 2:result=i64_to_f64((int64_t)a).v;break;default:result=ui64_to_f64(a).v;}}
   else {uint32_t v;switch(rs2){case 0:v=i32_to_f32((int32_t)a).v;break;case 1:v=ui32_to_f32((uint32_t)a).v;break;case 2:v=i64_to_f32((int64_t)a).v;break;default:v=ui64_to_f32(a).v;}result=UINT64_C(0xffffffff00000000)|v;}
  }
  inst|=(f7<<25)|(rs2<<20)|(f3<<12);
  printf("%08x %u %016llx %016llx %016llx %02x\n",inst,rm,(unsigned long long)a,(unsigned long long)b,(unsigned long long)result,(unsigned)softfloat_exceptionFlags);
 }
}

int main(int argc,char **argv){
  softfloat_detectTininess=softfloat_tininess_afterRounding;
  if(argc>1&&argv[1][0]=='c'){generate_fast();return 0;}
  if(argc>1&&argv[1][0]=='l'){generate_long();return 0;}
  if(argc>1&&argv[1][0]=='f'){generate_fma();return 0;}
  for(unsigned n=0;n<40000;n++){
    unsigned op=n%4,rm=(n/4)%5,src_double=(op==0||op==2),dst_double=(op==1||op==2);
    uint64_t a=random64();
    if(n%3==0)a=src_double?corners[(n/3)%16]:UINT64_C(0xffffffff00000000)|scorners[(n/3)%16];
    else if(!src_double)a|=UINT64_C(0xffffffff00000000);
    if(n%71==0&&!src_double)a&=UINT64_C(0x00000000ffffffff);
    float64_t da={a};float32_t sa={(uint32_t)a};
    if(!src_double&&(a>>32)!=UINT32_MAX)sa.v=0x7fc00000;
    uint64_t result;
    softfloat_roundingMode=rm;softfloat_exceptionFlags=0;
    if(op==0){float32_t r=f64_to_f32(da);result=UINT64_C(0xffffffff00000000)|r.v;}
    else if(op==1){result=f32_to_f64(sa).v;}
    else if(op==2){float64_t one={UINT64_C(0x3ff0000000000000)};result=f64_mul(da,one).v;}
    else{float32_t one={0x3f800000};result=UINT64_C(0xffffffff00000000)|f32_mul(sa,one).v;}
    printf("%u %u %u %016llx %016llx %02x\n",src_double,dst_double,rm,
      (unsigned long long)a,(unsigned long long)result,(unsigned)softfloat_exceptionFlags);
  }
  return 0;
}
