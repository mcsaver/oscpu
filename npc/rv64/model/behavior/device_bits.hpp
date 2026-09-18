// Unsigned behavioral values. Shared by generated CUDA and host semantic checks.
#pragma once
#include <cstdint>
#ifdef __CUDACC__
#define R64_HD __host__ __device__ inline
#else
#define R64_HD inline
#endif
namespace r64_behavior {
template<int W> struct Bits {
    static_assert(W >= 1 && W <= 4096, "unsupported behavior width");
    static constexpr int words = (W+31)/32;
    uint32_t v[words];
};
template<int W> R64_HD void trim(Bits<W>& a) {
    if constexpr (W%32) a.v[a.words-1] &= (uint32_t(1)<<(W%32))-1;
}
template<int W> R64_HD bool truth(const Bits<W>& a) {
    uint32_t r=0; for(int i=0;i<a.words;++i) r|=a.v[i]; return r!=0;
}
R64_HD Bits<1> boolean(bool x) { return Bits<1>{{uint32_t(x)}}; }
template<int W> R64_HD bool get(const Bits<W>& a,unsigned bit) {
    return bit<unsigned(W) && ((a.v[bit/32]>>(bit%32))&1);
}
template<int W> R64_HD void set(Bits<W>& a,unsigned bit,bool value) {
    if(bit>=unsigned(W)) return;
    uint32_t m=uint32_t(1)<<(bit%32);
    a.v[bit/32]=(a.v[bit/32]&~m)|(value?m:0);
}
// Saturation prevents a wide dynamic index from wrapping into a valid small one.
template<int W> R64_HD unsigned index(const Bits<W>& a) {
    for(int i=1;i<a.words;++i) if(a.v[i]) return 0xffffffffu;
    return a.v[0];
}
template<int O,int A> R64_HD Bits<O> resize(const Bits<A>& a) {
    Bits<O> r{}; for(int i=0;i<r.words && i<a.words;++i) r.v[i]=a.v[i];
    trim(r); return r;
}
template<int O,int A> R64_HD Bits<O> slice(const Bits<A>& a,unsigned low) {
    Bits<O> r{};
    if(low>=unsigned(A)) return r;
    unsigned word=low/32,shift=low%32;
    for(int i=0;i<r.words;++i) {
        unsigned j=word+unsigned(i);
        if(j<unsigned(a.words)) r.v[i]=a.v[j]>>shift;
        if(shift && j+1<unsigned(a.words)) r.v[i]|=a.v[j+1]<<(32-shift);
    }
    trim(r); return r;
}
template<int W,int V> R64_HD void put(Bits<W>& target,unsigned low,Bits<V> value) {
    // RHS is a value snapshot even when a blocking write aliases its source.
    if(low>=unsigned(W)) return;
    unsigned end=low+unsigned(V);if(end>unsigned(W))end=W;
    for(unsigned word=low/32;word<target.words && word*32<end;++word) {
        unsigned base=word*32,start=low>base?low:base;
        unsigned stop=end<base+32?end:base+32,span=stop-start;
        uint32_t bits=span==32?0xffffffffu:((uint32_t(1)<<span)-1);
        unsigned offset=start-base;uint32_t write_mask=bits<<offset;
        uint32_t chunk=slice<32>(value,start-low).v[0]<<offset;
        target.v[word]=(target.v[word]&~write_mask)|(chunk&write_mask);
    }
}
template<int A,int B> R64_HD Bits<A+B> cat(const Bits<A>& a,const Bits<B>& b) {
    Bits<A+B> r=resize<A+B>(b); put(r,B,a); return r;
}
template<int W> R64_HD Bits<W> invert(const Bits<W>& a) {
    Bits<W> r{}; for(int i=0;i<r.words;++i) r.v[i]=~a.v[i]; trim(r); return r;
}
template<int W> R64_HD Bits<W> band(const Bits<W>& a,const Bits<W>& b) {
    Bits<W> r{}; for(int i=0;i<r.words;++i) r.v[i]=a.v[i]&b.v[i]; return r;
}
template<int W> R64_HD Bits<W> bor(const Bits<W>& a,const Bits<W>& b) {
    Bits<W> r{}; for(int i=0;i<r.words;++i) r.v[i]=a.v[i]|b.v[i]; return r;
}
template<int W> R64_HD Bits<W> bxor(const Bits<W>& a,const Bits<W>& b) {
    Bits<W> r{}; for(int i=0;i<r.words;++i) r.v[i]=a.v[i]^b.v[i]; return r;
}
template<int W> R64_HD Bits<W> add(const Bits<W>& a,const Bits<W>& b) {
    Bits<W> r{}; uint64_t carry=0;
    for(int i=0;i<r.words;++i) {
        uint64_t x=uint64_t(a.v[i])+b.v[i]+carry; r.v[i]=uint32_t(x);carry=x>>32;
    }
    trim(r); return r;
}
template<int W> R64_HD Bits<W> sub(const Bits<W>& a,const Bits<W>& b) {
    Bits<W> r{}; uint64_t borrow=0;
    for(int i=0;i<r.words;++i) {
        uint64_t rhs=uint64_t(b.v[i])+borrow;
        r.v[i]=uint32_t(uint64_t(a.v[i])-rhs);borrow=uint64_t(a.v[i])<rhs;
    }
    trim(r); return r;
}
template<int W> R64_HD Bits<1> equal(const Bits<W>& a,const Bits<W>& b) {
    for(int i=0;i<a.words;++i) if(a.v[i]!=b.v[i]) return boolean(false);
    return boolean(true);
}
template<int W> R64_HD Bits<1> less(const Bits<W>& a,const Bits<W>& b) {
    for(int i=a.words-1;i>=0;--i) if(a.v[i]!=b.v[i]) return boolean(a.v[i]<b.v[i]);
    return boolean(false);
}
template<int W> R64_HD Bits<W> shift_left(const Bits<W>& a,unsigned shift) {
    Bits<W> r{}; if(shift>=unsigned(W)) return r;
    unsigned word=shift/32,bits=shift%32;
    for(int i=r.words-1;i>=int(word);--i) {
        r.v[i]=a.v[i-word]<<bits;
        if(bits && unsigned(i)>word) r.v[i]|=a.v[i-word-1]>>(32-bits);
    }
    trim(r); return r;
}
} // namespace r64_behavior
