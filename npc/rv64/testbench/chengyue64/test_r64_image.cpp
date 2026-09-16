#include "r64_image.h"
#include <array>
#include <filesystem>
#include <functional>
#include <iostream>
static void check(bool ok){if(!ok)throw std::runtime_error("image-loader test failed");}
static void reject(const std::function<void()>& f){
 bool caught=false;try{f();}catch(const std::runtime_error&){caught=true;}check(caught);
}
int main(int argc,char**argv){
 check(argc==2);
 const auto dir=std::filesystem::path(argv[1]);std::filesystem::create_directories(dir);
 auto save=[&](const char* name,const std::vector<uint8_t>& data){
  auto path=dir/name;std::ofstream out(path,std::ios::binary);out.write(reinterpret_cast<const char*>(data.data()),data.size());check(bool(out));return path.string();
 };
 constexpr uint64_t base=0x80000000;
 const auto raw=save("raw.bin",{0x88,0x77,0x66,0x55});
 std::vector<uint8_t> ram(4096,0xa5);R64Images images(ram,base);
 images.boot(raw);images.raw(raw,base+1024);
 check(ram[0]==0x88&&ram[1027]==0x55&&ram[1028]==0xa5);
 reject([&]{images.raw(raw,base+2);}); // Overlay would destroy boot bytes.
 reject([&]{images.raw(raw,UINT64_MAX-1);});
 reject([&]{images.raw(raw,base+4094);});
 reject([&]{images.raw(raw,base-1);});
 std::vector<uint8_t> elf(256,0);
 Elf64_Ehdr eh{};std::memcpy(eh.e_ident,ELFMAG,SELFMAG);
 eh.e_ident[EI_CLASS]=ELFCLASS64;eh.e_ident[EI_DATA]=ELFDATA2LSB;
 eh.e_ident[EI_VERSION]=EV_CURRENT;eh.e_version=EV_CURRENT;
 eh.e_machine=EM_RISCV;eh.e_type=ET_EXEC;eh.e_entry=base;
 eh.e_phoff=sizeof eh;eh.e_phnum=1;eh.e_phentsize=sizeof(Elf64_Phdr);
 Elf64_Phdr ph{};ph.p_type=PT_LOAD;ph.p_flags=PF_R|PF_X;ph.p_paddr=base;
 ph.p_offset=200;ph.p_filesz=4;ph.p_memsz=16;
 auto save_elf=[&](){
  std::memcpy(elf.data(),&eh,sizeof eh);std::memcpy(elf.data()+sizeof eh,&ph,sizeof ph);
  elf[200]=0x13;elf[201]=0x05;elf[202]=0;elf[203]=0;
  return save("boot.elf",elf);
 };
 {
  R64Images valid(ram,base);valid.boot(save_elf());
  check(ram[0]==0x13&&ram[1]==5&&ram[4]==0&&ram[15]==0&&ram[16]==0xa5);
 }
 auto bad=[&](){R64Images invalid(ram,base);invalid.boot(save_elf());};
 ph.p_memsz=3;reject(bad);ph.p_memsz=16;
 ph.p_offset=UINT64_MAX-1;reject(bad);ph.p_offset=200;
 eh.e_phoff=UINT64_MAX;reject(bad);eh.e_phoff=sizeof eh;
 eh.e_ident[EI_DATA]=ELFDATA2MSB;reject(bad);eh.e_ident[EI_DATA]=ELFDATA2LSB;
 eh.e_entry=base+4;reject(bad);eh.e_entry=base;
 ph.p_flags=PF_R;reject(bad);
 // Match real GNU ld executables whose PT_LOAD includes the ELF-header page.
 eh.e_ehsize=sizeof eh;
 ph.p_flags=PF_R|PF_X;ph.p_vaddr=ph.p_paddr=base-4096;
 ph.p_offset=0;ph.p_align=4096;ph.p_filesz=4100;ph.p_memsz=4112;
 elf.assign(4100,0);elf[4096]=0x13;elf[4097]=0x05;
 auto prefix_elf=[&](){
  std::memcpy(elf.data(),&eh,sizeof eh);std::memcpy(elf.data()+sizeof eh,&ph,sizeof ph);
  return save("header-prefix.elf",elf);
 };
 {R64Images valid(ram,base);valid.boot(prefix_elf());check(ram[0]==0x13&&ram[1]==5&&ram[4]==0&&ram[15]==0);}
 auto bad_prefix=[&](){R64Images invalid(ram,base);invalid.boot(prefix_elf());};
 elf[512]=0x42;reject(bad_prefix);elf[512]=0;
 ph.p_flags|=PF_W;reject(bad_prefix);ph.p_flags&=~PF_W;
 ph.p_memsz=4099;reject(bad_prefix);ph.p_memsz=4112;
 ph.p_paddr-=4096;reject(bad_prefix);ph.p_paddr+=4096;
 // Zero-filled allocated data below RAM must not be mistaken for file padding.
 eh.e_shoff=4104;eh.e_shentsize=sizeof(Elf64_Shdr);eh.e_shnum=1;
 elf.resize(eh.e_shoff+sizeof(Elf64_Shdr));
 Elf64_Shdr sh{};sh.sh_type=SHT_NOBITS;sh.sh_flags=SHF_ALLOC;sh.sh_addr=base-8;sh.sh_size=8;
 std::memcpy(elf.data()+eh.e_shoff,&sh,sizeof sh);reject(bad_prefix);
 std::cout<<"[PASS] r64_image: raw, ELF/BSS, GNU header prefix, overlays, bounds, overflow and invalid headers\n";
}
