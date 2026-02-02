#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "/home/lyg/PA/ysyx-workbench/am-kernels/tests/am-tests/include/amtest.h"
#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#define NREG 16
#define NMEM 16u * 1024u *1024u//rom容量16m
#define DMEM 16u * 1024u *1024u//ram容量16m

enum {
  $0 = 0, ra, sp, gp, tp, t0, t1, t2,
  s0, s1, a0, a1, a2, a3, a4, a5,
  a6, a7, s2, s3, s4, s5, s6, s7,
  s8, s9, s10, s11, t3, t4, t5, t6
};

//所有字段顺序从低到高排列，小端序
typedef union {
  struct { uint32_t opcode : 7, rd : 5, funct3 : 3, rs1 : 5, rs2 : 5, funct7 : 7; } rtype;
  struct { uint32_t opcode : 7, rd : 5, funct3 : 3, rs1 : 5, imm : 12; } itype;
  struct { uint32_t opcode : 7, imm0 : 5, funct3 : 3, rs1 : 5, rs2 : 5, imm1 : 7; } stype;
  struct { uint32_t opcode : 7, rd : 5, imm : 20; } utype;
  uint32_t inst;
} inst_t;

#define DECODE_R(inst) uint32_t rs1 = (inst).rtype.rs1, rs2 = (inst).rtype.rs2, rd =(inst).rtype.rd \
                                , funct3 = (inst).rtype.funct3, funct7 = (inst).rtype.funct7
#define DECODE_I(inst) uint32_t rs1 = (inst).itype.rs1, funct3 = (inst).itype.funct3 \
                                , rd = (inst).itype.rd; \
                       int32_t  imm = ((int32_t)((inst).itype.imm << 20) >> 20)
//进行符号拓展的时候，要先左移再右移动，否则回出现高位全1或者高位全是0导致表达错误
#define DECODE_S(inst) uint32_t rs2 = (inst).stype.rs2, rs1 = (inst).stype.rs1, funct3 = (inst).stype.funct3; \
                       int32_t imm = ((int32_t)(((inst).stype.imm1 << 5) | (inst).stype.imm0) << 20) >> 20
#define DECODE_U(inst) int32_t imm = (inst).utype.imm, rd = (inst).utype.rd

uint32_t pc = 0;       // PC
uint32_t n_pc = 0;     //next pc
uint32_t R[NREG] = {}; // 寄存器

uint32_t M[NMEM] = {
    // --- 主程序初始化 (Main Init) ---
    // 0x00: lui t0, 1         -> t0 = 0x1000 (设置数据段基地址，避开指令区)
    0x000012b7,
    // 0x04: sw zero, 0(t0)    -> MEM[0x1000] = 0 (初始化 sum = 0)
    0x0002a023,
    // 0x08: addi a1, zero, 1  -> a1 = 1 (初始化 i = 1)
    0x00100593,
    // 0x0C: sw a1, 4(t0)      -> MEM[0x1004] = 1 (保存 i)
    0x00b2a223,
    // 0x10: addi t1, zero, 76 -> t1 = 0x4C (加载子过程“add_step”的入口地址)
    0x04c00313,

    // --- 展开调用 10 次 (Call Subroutine 10 times) ---
    // 通过 jalr ra, t1, 0 跳转到子过程，ra 保存返回地址
    // 每次调用对应 i=1, i=2, ..., i=10
    0x000300e7, // 1:  jalr ra, t1, 0
    0x000300e7, // 2:  jalr ra, t1, 0
    0x000300e7, // 3:  jalr ra, t1, 0
    0x000300e7, // 4:  jalr ra, t1, 0
    0x000300e7, // 5:  jalr ra, t1, 0
    0x000300e7, // 6:  jalr ra, t1, 0
    0x000300e7, // 7:  jalr ra, t1, 0
    0x000300e7, // 8:  jalr ra, t1, 0
    0x000300e7, // 9:  jalr ra, t1, 0
    0x000300e7, // 10: jalr ra, t1, 0

    // --- 结果搬运与结束 (Finalize) ---
    // 0x3C: lw a0, 0(t0)      -> a0 = MEM[0x1000] (读取最终 sum)
    0x0002a503,
    // 0x40: sw a0, 0(zero)    -> MEM[0] = a0 (将结果写回MEM[0]，供 main 打印)
    0x00a02023,
    // 0x44: ebreak            -> 停机 (0x00100073 或 0x00100073)
    // 注意：你的代码匹配的是 0x73 结尾即可，此处用标准 RISC-V ebreak
    0x00100073,

    // --- 子过程：add_step (Function: Sum += i; i++) ---
    // 地址: 0x48 (由前面的指令数决定: 18条 * 4 = 72 = 0x48)
    // 实际上我们在 0x48 处放一个 nop (addi x0,x0,0) 对齐，子过程从 0x4C 开始
    0x00000013, // 0x48: nop (padding)

    // 0x4C: 子过程入口 (Entry)
    // 1. 从内存加载 sum 和 i
    0x0002a503, // lw a0, 0(t0)    -> a0 = sum
    0x0042a583, // lw a1, 4(t0)    -> a1 = i

    // 2. 执行加法
    0x00b50533, // add a0, a0, a1  -> sum = sum + i

    // 3. sum 写回内存 (sw 测试)
    0x00a2a023, // sw a0, 0(t0)    -> MEM[0x1000] = sum

    // 4. i 自增
    0x00158593, // addi a1, a1, 1  -> i++

    // 5. i 写回内存 (混合 sb/lbu 测试)
    // 我们先把 i 的低 8 位存进去，再读出来，验证字节操作
    0x00b28223, // sb a1, 4(t0)    -> MEM[0x1004] (byte) = i
    0x0042c583, // lbu a1, 4(t0)   -> a1 = MEM[0x1004] (unsigned byte)
    
    // 注意：由于 sum 是 32 位的，i 虽然只用了 lbu 读取低 8 位，
    // 但在 10 以内 i 的高位本身就是 0，所以逻辑是成立的。

    // 6. 返回 (Return)
    0x00008067, // jalr zero, ra, 0 -> PC = ra
};
uint32_t MEM[DMEM] = {};//ram
static int vga_en = 0;
static int hat_static = 0; // 结束标志

#define MEM_32_r(addr) (MEM[(addr) >> 2])//32位全读取
//(uint8_t *)&MEM[(addr) >> 2]：把这个地址强制转换成uint8_t*，现在它可以像字节数组一样访问
//在C语言中，指针加加下标，（如p[n]的本质是从指针p开始，跳过n个元素进行取值
//对于uint8_t *p，p[n]就是从地址p开始，向后偏移n字节后的那个字节的值
#define MEM_byte_r(addr) ( ((uint8_t *)&MEM[(addr) >> 2])[(addr) & 0x3] )
#define MEM_32_w(addr, data) (MEM[(addr) >> 2] = data)
#define MEM_byte_w(addr, data) (((uint8_t *)&MEM[(addr) >> 2])[(addr) & 0x3] = data)


// 执行一条指令
void exec_once() {

  vga_en = 0;
  inst_t this;
  this.inst = M[pc >> 2]; // 取指
  //inst_t是一个union, 它有三种解释方式：rtype、mtype、inst
  //上句把内存中的一个字节赋给inst后，由于union的所用成员公用一块内存
  //赋值给inst后，rtype和mtype也能“看到”这8位数据，只是解释方式不同
  switch (this.rtype.opcode) {
  //  操作码译码       操作数译码           执行

    case 0b0110011: { DECODE_R(this); (void)funct3; (void)funct7; R[rd] = R[rs1] + R[rs2]; n_pc = pc + 4; break;}//add
    //补码表示法下，有符号与无符号加减法二进制位结果是一样的
    case 0b0010011: { DECODE_I(this); (void)funct3; R[rd] = R[rs1] + imm; n_pc = pc + 4; break;}//addi
    case 0b0110111: { DECODE_U(this); R[rd] = imm << 12; n_pc = pc + 4; break;}//lui
    case 0b0000011: {//load
        DECODE_I(this);
        (void)funct3;
        switch (funct3)
        {
          case 0b010 : {//lw
            uint32_t addr = R[rs1] + imm;
            if ((addr >> 2) < DMEM) {
              R[rd] = MEM_32_r(addr);
            } else {
              R[rd] = 0; // MMIO or out of bound read returns 0
            }
            n_pc = pc + 4;
            break;
          }//lw
          case 0b100 : {//lbu
            uint32_t addr = R[rs1] + imm;
            if ((addr >> 2) < DMEM) {
              R[rd] = MEM_byte_r(addr);
            } else {
              R[rd] = 0;
            }
            n_pc = pc + 4;
            break;
          }//lbu
        }
        break;
      }
    case 0b0100011: {
        DECODE_S(this);
        switch (funct3)
        {
          case 0b010 : {//sw
            uint32_t addr = R[rs1] + imm;
            if (addr >= 0x20000000 && addr < 0x20040000) {
              uint8_t x = (addr >> 2) & 0xFF;   // 取9:2，共8位
              uint8_t y = (addr >> 10) & 0xFF;  // 取17:10，共8位
              uint32_t vga_data = R[rs2];
              io_write(AM_GPU_FBDRAW, x, y, &vga_data, 1, 1, true);
            } else {
              // 只有在内存范围内才写 MEM，防止越界
              if ((addr >> 2) < DMEM) {
                MEM_32_w(addr, R[rs2]);
              }
            }
            n_pc = pc + 4;
            break;
          }
        case 0b000 : {//sb
          uint32_t addr = R[rs1] + imm;
          if ((addr >> 2) < DMEM) {
            MEM_byte_w(addr, (uint8_t)(R[rs2]));
          }
          n_pc = pc + 4;
          break;
          }//sb
        }
        break;
      }
    case 0b1100111: {
      DECODE_I(this); (void)funct3; uint32_t ret_addr = pc + 4; n_pc = (R[rs1] + imm) & -1; R[rd] = ret_addr; break;
    }//{DECODE_I(this); (void)funct3; R[rd] = pc + 4; n_pc = (R[rs1] + imm) & ~1; break;}//jalr
    case 0b1010101: {hat_static = 1; break;}
    case 0b1110011: { /* ebreak/ECALL */
      printf("ebreak encountered, hat_static.\n");
      hat_static = 1;
      break;
}
    default:
      printf("Invalid instruction with inst = %08x, halting...\n", this.inst);
      hat_static = 1;
      break;
  }

  R[0] = 0;//强制重置R[0]
  pc = n_pc; // 更新PC
}

//寄存器打印
void print_regs() {
  for (int i = 0; i < NREG; i++)
  {
    printf("R[%2d] = 0x%08x\n", i, R[i]);
  }
}

int main() {
  //ioe_init();
  //IOE;
  //printf("argc = %d\n", argc);

    //int pc_repeat_reg = 0;
    //const int pc_repeat_max = 5000;
    char *path = getenv("mainargs");//argv[1];
    printf("Path is :%s\n", path);
    int test_bin = 0;
    if(strcmp(path, "hex/sum.bin") == 0) test_bin = 1;
    if(strcmp(path, "hex/mem.bin") == 0) test_bin = 2;
    if(strcmp(path, "hex/vga.bin") == 0) test_bin = 3;
    FILE *fp = fopen(path, "rb");
    printf("打开文件: %s\n", path);
    if (fp == NULL) {printf("fp打开失败\n"); return 1;}

    if (fseek(fp, 0, SEEK_END) != 0) {printf("fseek 失败\n"); fclose(fp); return 1;}
    long sz = ftell(fp);//获取字节数
    if (sz < 0) printf("ftell 失败\n");
    if (fseek(fp, 0, SEEK_SET) != 0) {printf("fseek 失败\n"); fclose(fp); return 1;}
    if (sz % 4 != 0) printf("二进制大小必须是4的倍数(字节)\n");

    printf("文件大小: %ld 字节\n", sz);
    int ret = fread(M, sz, 1, fp);
    memcpy(MEM, M, sz);
    if (ret == 0) {printf("fread错误\n"); fclose(fp); return 1;}

    fclose(fp);
  //}
  printf("开始执行指令\n");
  while (1) {
    exec_once();
    if (test_bin == 1 && pc == 0x00000228)//sum的halt函数退出
    {
      if (R[tp] == 0x224)
      {
        hat_static = 1;
        printf("HIT GOOD TRAP(sum)\n");
        break;
      }
      else {printf("HIT BAD TRAP\n"); break;}
    }
    if (test_bin == 2 && pc == 0x00001220)//mem的halt函数退出
    {
      if (R[tp] == 0x1218)
      {
        hat_static = 1;
        printf("HIT GOOD TRAP(mem)\n");
        break;
      }
      else {printf("HIT BAD TRAP\n"); break;}
    }
    if (test_bin == 3 && pc == 0x00000dac)//vga的halt函数退出
    {
      if (R[tp] == 0xda4)
      {
        hat_static = 1;
        printf("HIT GOOD TRAP(vga)\n");
        break;
      }
      else {printf("HIT BAD TRAP\n"); break;}
    }
    if (hat_static) break;
    AM_INPUT_KEYBRD_T kbd; 
    ioe_read(AM_INPUT_KEYBRD, &kbd);
    if (kbd.keycode == AM_KEY_ESCAPE) {
      return 0 ;
      }

  }

  print_regs();
  if (path == NULL) {
  printf("default test Result :%08x\n", MEM[0]);
}
  return 0;
}

