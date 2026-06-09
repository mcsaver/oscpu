/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#ifndef __DEVICE_MAP_H__
#define __DEVICE_MAP_H__

//把“设备地址映射”抽象成一套同意接口，让NEMU用同一套逻辑处理PIO和MMIO
//CPU访问设备的时候，本质上是在访问某个“地址区间”对应的设备寄存器或者缓冲区，而不是普通内存
//不同设备有不同的地址范围，但访问流程很相，先判断地址命中了哪个设备，再把访存请求转成设备内部偏移，最后读写一块宿主机内存，并在必要时触发设备回调
//这个头文件就是把这套共性提出来，形成IOMap、map_read、map_write这些通用部件

//完整调用链：
//设备初始化阶段：
//1.设备调用new_space申请一块后端空间。
//2.然后调用add_pio_map或add_mmio_map，把地址范围和这块空间绑定
//CPU执行设备访问时：
//1.如果是PIO，就走port-io.c里面的pio_read或pio_write
//2.如果是MMIO，就走mmio.c里面mmio_read或mmio_write
//接着：
//1.先通过find_mapid_by_addr找到命中的IOMap
//2.再调用map_read或map_write
//在map_read或map_write：
//1.先做越界检查check_bound，见map.c
//2.然后把CPU给出的绝对地址换算成设备内部offset
//3.再通过host_read或host_write操作宿主机内存
//4.最后配合callback完成设备语义


#include <cpu/difftest.h>

#ifndef CONFIG_TARGET_AM
#include <stdio.h>
#endif

//第一个参数是设备内部偏移offset
//第二个参数是访问长度len
//第三个参数是是否写操作is_write
typedef void(*io_callback_t)(uint32_t, int, bool);

//从一大片统一的io_space里切一段空间给某个设备用
//切出来的大小会按页对齐
//这块空间通常就是设备寄存器或设备缓冲区的后端存储
uint8_t* new_space(int size);

//描述一个设备映射区间
//name：设备名字，只用于日志和报错
//low和high：这个设备映射的地址范围，注意是闭区间
//space：映射到宿主机中的一段内存，设备寄存器值或显存内容通常就放在这里
//callback：访问这个设备时的钩子函数
typedef struct {
  const char *name;
  // we treat ioaddr_t as paddr_t here
  //PIO地址本来是ioaddr_t
  //MMIO地址本来是paddr_t
  //但是为了复用同一个IOMap结构，这里同一按paddr_t存
  paddr_t low;
  paddr_t high;
  void *space;
  io_callback_t callback;
} IOMap;

//判断某个地址是否落在某个IOMap的low到high范围内
//这是最基础的“地址命中判断”
static inline bool map_inside(IOMap *map, paddr_t addr) {
  return (addr >= map->low && addr <= map->high);
}

//在线性数组里顺序扫描，找到命中的映射项
//找到后会立刻调用difftest_skip_ref
//找不到就返回-1
static inline int find_mapid_by_addr(IOMap *maps, int size, paddr_t addr) {
  int i;
  for (i = 0; i < size; i ++) {
    if (map_inside(maps + i, addr)) {
      //为什么命中映射要调用difftest_skip_ref
      //设备访问同擦汗给你带外部副作用，比如读时钟、读键盘、写串口、刷显存
      //这些行为再DUT和REF之间很难做到逐条完全一致
      //所以一旦发现本条访问命中了设备映射，就告诉difftest：这一步不要拿参考模型硬比
      difftest_skip_ref();
      return i;
    }
  }
  return -1;
}

//只是声明
//负责“注册设备”
//PIO板块实现见port-io.c
//MMIO板块实现见mmio.c
void add_pio_map(const char *name, ioaddr_t addr,
        void *space, uint32_t len, io_callback_t callback);
void add_mmio_map(const char *name, paddr_t addr,
        void *space, uint32_t len, io_callback_t callback);

#ifndef CONFIG_TARGET_AM
// 机器清单只读导出当前已注册的设备区间，给 e2e/monitor 契约使用。
void dump_pio_maps(FILE *out);
void dump_mmio_maps(FILE *out);
#endif

//在map.h中声明，在map.c中实现
//他们是真正通用的读写入口
//PIO和MMIO最后都会走到这里
word_t map_read(paddr_t addr, int len, IOMap *map);
void map_write(paddr_t addr, int len, word_t data, IOMap *map);

#endif
