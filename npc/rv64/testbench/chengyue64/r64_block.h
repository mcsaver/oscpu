#pragma once
#include <dlfcn.h>
#include <link.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/fs.h>
#include <sys/stat.h>
#include <unistd.h>
#include <cerrno>
#include <cstdio>
#include <cstring>
#include <stdexcept>
#include <string>

// The caller supplies a writable run image. Snapshot it before either device
// opens it, so the oracle cannot see DUT writes through a shared host file.
class R64BlockImages {
 std::string reference_path;
public:
 explicit R64BlockImages(const std::string& source) {
  if(source.empty())return;
  int in=open(source.c_str(),O_RDONLY);
  if(in<0)throw std::runtime_error("cannot open block image: "+source);
  struct stat st{};
  if(fstat(in,&st)||!S_ISREG(st.st_mode)||st.st_size<=0||st.st_size%512){
   close(in);throw std::runtime_error("block image must be a nonempty sector-aligned regular file");
  }
  char name[]="/tmp/r64-reference-block-XXXXXX";
  int out=mkstemp(name);
  if(out<0){close(in);throw std::runtime_error("cannot create reference block snapshot");}
  reference_path=name;
  bool ok=true;
  if(ioctl(out,FICLONE,in)<0){
   char data[65536];ssize_t n;
   while((n=read(in,data,sizeof data))>0){
    ssize_t done=0;
    while(done<n){ssize_t w=write(out,data+done,n-done);if(w<=0){ok=false;break;}done+=w;}
    if(!ok)break;
   }
   if(n<0)ok=false;
  }
  close(in);if(close(out))ok=false;
  if(!ok){unlink(reference_path.c_str());reference_path.clear();throw std::runtime_error("cannot snapshot reference disk");}
 }
 ~R64BlockImages(){if(!reference_path.empty())unlink(reference_path.c_str());}
 R64BlockImages(const R64BlockImages&)=delete;
 const char* reference()const{return reference_path.empty()?nullptr:reference_path.c_str();}
};

// Reuse the workspace's virtio transport/block model as a software peripheral.
// It has a separate ELF namespace, registers and disk from the ISA oracle.
// Only accepted AXI MMIO requests call it; this instance never executes a CPU
// instruction or supplies expected architectural state to the comparator.
class R64BlockDevice {
 void* dependency=nullptr;void* handle=nullptr;
 bool (*mmio)(uint32_t,int,uint64_t*,bool)=nullptr;
 bool (*irq_level)()=nullptr;
 template<class T> T symbol(const char* name){
  void* p=dlsym(handle,name);
  if(!p)throw std::runtime_error(std::string("block model lacks ")+name);
  return reinterpret_cast<T>(p);
 }
public:
 R64BlockDevice(const char* library,const char* disk,
     bool (*dma)(uint32_t,void*,uint32_t,bool)){
  dependency=dlmopen(LM_ID_NEWLM,"libreadline.so.8",RTLD_NOW|RTLD_LOCAL);
  if(!dependency)throw std::runtime_error(dlerror());
  Lmid_t ns;
  if(dlinfo(dependency,RTLD_DI_LMID,&ns))throw std::runtime_error(dlerror());
  handle=dlmopen(ns,library,RTLD_NOW|RTLD_LOCAL);
  if(!handle)throw std::runtime_error(dlerror());
  symbol<void(*)(bool(*)(uint32_t,void*,uint32_t,bool))>("difftest_set_device_dma")(dma);
  symbol<void(*)()>("difftest_init_devices")();
  symbol<void(*)(const char*)>("difftest_init_block")(disk);
  mmio=symbol<decltype(mmio)>("difftest_device_mmio");
  irq_level=symbol<decltype(irq_level)>("difftest_block_irq");
 }
 ~R64BlockDevice(){if(handle)dlclose(handle);if(dependency)dlclose(dependency);}
 R64BlockDevice(const R64BlockDevice&)=delete;
 bool access(uint64_t address,unsigned size,uint64_t& value,bool write){
  return address>=0x10001000&&address<0x10002000&&size<=3&&
         mmio(uint32_t(address),1<<size,&value,write);
 }
 bool irq()const{return irq_level();}
};
