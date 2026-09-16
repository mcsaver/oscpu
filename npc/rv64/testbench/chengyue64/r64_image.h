#pragma once
#include <cstdint>
#include <cstring>
#include <elf.h>
#include <fstream>
#include <iterator>
#include <stdexcept>
#include <string>
#include <vector>

// A boot ELF uses physical PT_LOAD addresses; additional images are raw bytes
// at explicit physical addresses. Bounds are checked without overflowing sums.
class R64Images {
  std::vector<uint8_t>& ram_;
  uint64_t base_;
  struct Span { uint64_t begin,end; };
  std::vector<Span> spans_;
  static void require(bool ok,const char* message) {
    if(!ok)throw std::runtime_error(message);
  }
  static std::vector<uint8_t> read(const std::string& path) {
    std::ifstream in(path,std::ios::binary);
    require(bool(in),"cannot open image");
    std::vector<uint8_t> bytes((std::istreambuf_iterator<char>(in)),{});
    require(!in.bad(),"image read failed");
    require(!bytes.empty(),"empty image");
    return bytes;
  }
  void place(uint64_t address,uint64_t memsz,const uint8_t* data,uint64_t filesz) {
    require(filesz<=memsz,"ELF file size exceeds memory size");
    require(address>=base_&&memsz<=ram_.size()&&address-base_<=ram_.size()-memsz,
            "image segment outside guest memory");
    if(!memsz)return;
    for(const auto& span:spans_)
      require(address+memsz<=span.begin||address>=span.end,"guest images overlap");
    spans_.push_back({address,address+memsz});
    std::memset(ram_.data()+address-base_,0,memsz);
    if(filesz)std::memcpy(ram_.data()+address-base_,data,filesz);
  }
public:
  R64Images(std::vector<uint8_t>& ram,uint64_t base):ram_(ram),base_(base){}
  void raw(const std::string& path,uint64_t address) {
    auto data=read(path);
    place(address,data.size(),data.data(),data.size());
  }
  void boot(const std::string& path) {
    auto data=read(path);
    if(data.size()<SELFMAG||std::memcmp(data.data(),ELFMAG,SELFMAG)) {
      place(base_,data.size(),data.data(),data.size());return;
    }
    require(data.size()>=sizeof(Elf64_Ehdr),"ELF header truncated");
    Elf64_Ehdr eh;std::memcpy(&eh,data.data(),sizeof eh);
    require(eh.e_ident[EI_CLASS]==ELFCLASS64&&eh.e_ident[EI_DATA]==ELFDATA2LSB&&
            eh.e_ident[EI_VERSION]==EV_CURRENT&&eh.e_version==EV_CURRENT&&
            eh.e_machine==EM_RISCV&&eh.e_type==ET_EXEC,"not a little-endian RV64 executable ELF");
    require(eh.e_entry==base_,"ELF entry differs from the hardware reset PC");
    require(eh.e_phentsize==sizeof(Elf64_Phdr)&&eh.e_phoff<=data.size()&&
            uint64_t(eh.e_phnum)<=(data.size()-eh.e_phoff)/sizeof(Elf64_Phdr),
            "ELF program headers invalid or truncated");
    bool loaded=false,entry=false;
    for(unsigned i=0;i<eh.e_phnum;i++) {
      Elf64_Phdr ph;std::memcpy(&ph,data.data()+eh.e_phoff+i*sizeof ph,sizeof ph);
      if(ph.p_type!=PT_LOAD)continue;
      require(ph.p_offset<=data.size()&&ph.p_filesz<=data.size()-ph.p_offset,
              "ELF segment truncated");
      require(ph.p_filesz<=ph.p_memsz,"ELF file size exceeds memory size");
      uint64_t prefix=0;
      if(ph.p_paddr<base_) {
        // GNU ld -Ttext=0x80000000 includes a preceding read-only ELF-header
        // page in the text PT_LOAD. It is file metadata, not mapped guest RAM.
        // Only omit that precise header/zero-padding form; never clip code,
        // mutable data, allocated sections, or an arbitrary out-of-range span.
        prefix=base_-ph.p_paddr;
        require(ph.p_offset==0&&ph.p_vaddr==ph.p_paddr&&!(ph.p_flags&PF_W)&&
                ph.p_align>=sizeof eh&&ph.p_align<=65536&&
                !(ph.p_align&(ph.p_align-1))&&prefix==ph.p_align&&
                !(ph.p_paddr&(ph.p_align-1))&&prefix<=ph.p_filesz&&
                eh.e_ehsize==sizeof eh&&eh.e_phoff>=sizeof eh&&
                eh.e_phoff<=prefix&&
                uint64_t(eh.e_phnum)<=(prefix-eh.e_phoff)/sizeof(Elf64_Phdr),
                "ELF prefix below RAM is not an aligned header page");
        const uint64_t phend=eh.e_phoff+uint64_t(eh.e_phnum)*sizeof(Elf64_Phdr);
        for(uint64_t j=sizeof eh;j<prefix;j++)
          if(j<eh.e_phoff||j>=phend)
            require(data[j]==0,"ELF data below guest memory");
        if(eh.e_shnum) {
          require(eh.e_shentsize==sizeof(Elf64_Shdr)&&eh.e_shoff<=data.size()&&
                  uint64_t(eh.e_shnum)<=(data.size()-eh.e_shoff)/sizeof(Elf64_Shdr),
                  "ELF section headers invalid or truncated");
          for(unsigned j=0;j<eh.e_shnum;j++) {
            Elf64_Shdr sh;std::memcpy(&sh,data.data()+eh.e_shoff+j*sizeof sh,sizeof sh);
            if(!(sh.sh_flags&SHF_ALLOC)||!sh.sh_size)continue;
            bool overlaps=sh.sh_addr<base_&&
              (sh.sh_addr>=ph.p_paddr||sh.sh_size>ph.p_paddr-sh.sh_addr);
            require(!overlaps,"ELF allocated section below guest memory");
          }
        }
      }
      place(ph.p_paddr+prefix,ph.p_memsz-prefix,
            data.data()+ph.p_offset+prefix,ph.p_filesz-prefix);loaded=true;
      if((ph.p_flags&PF_X)&&ph.p_paddr<=base_&&ph.p_memsz>base_-ph.p_paddr)entry=true;
    }
    require(loaded&&entry,"ELF reset entry is not in an executable loaded segment");
  }
};
