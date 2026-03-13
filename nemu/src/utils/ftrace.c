#include <common.h>
#include <elf.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef CONFIG_FTRACE

typedef struct  {
    uint32_t addr;  //函数起始地址
    uint32_t size;  //函数大小
    char name[64];
} FuncSymbol;

static FuncSymbol *func_table = NULL;
static int func_cnt = 0;
static int call_depth = 0; //缩进层级

//根据地址查函数名（命中任意地址区间）
static const char *find_func(uint32_t addr) {
    for (int i = 0; i < func_cnt; i++) {
        if (addr >= func_table[i].addr &&
            addr < func_table[i].addr + func_table[i].size)
            return func_table[i].name;
    }
    return "???";
}

//根据起始地址精确查函数名（用于call目标）
static const char *find_func_by_entry(uint32_t addr) {
    for (int i = 0; i < func_cnt; i++) {
        if (func_table[i].addr == addr)
        return func_table[i].name;
    }
    return "???";
}

void init_ftrace(const char *elf_file) {
    if (elf_file == NULL) {
        Log("ftrace: no ELF file provide, ftrace disabled.");
        return;
    }

    FILE *fp = fopen(elf_file, "rb");
    Assert(fp, "ftrace: cannot open ELF file '%s'", elf_file);

    //读ELF header
    Elf32_Ehdr ehdr;
    Assert(fread(&ehdr, sizeof(ehdr), 1, fp) == 1, "ftrace: read ELF header failed");
    Assert(memcmp(ehdr.e_ident, ELFMAG, SELFMAG) == 0, "ftrace: not a valid ELF file");
    Assert(ehdr.e_ident[EI_CLASS] == ELFCLASS32, "ftrace: only ELF32 supported");

    //读section headers
    //ehdr.e_shoff -> Section Header Table在文件中的偏移
    //ehdr.e_shnum -> Section Header 的数量
    Elf32_Shdr *shdrs = malloc(ehdr.e_shnum * sizeof(Elf32_Shdr));
    Assert(shdrs, "ftrace: malloc shdrs failed");
    fseek(fp, ehdr.e_shoff, SEEK_SET);
    Assert(fread(shdrs, sizeof(Elf32_Shdr), ehdr.e_shnum, fp) == ehdr.e_shnum,
            "ftrace: read section headers failed");

    //找.symtab和.strtab
    //sh_type -> section类型（SHT_SYMTAB = 符号表格）
    //sh_offset -> section数据在文件中的偏移
    //sh_size -> section数据的字节大小
    //sh_link -> 关联的另一个section的索引（符号表用此指向对应字符串表）
    Elf32_Shdr *symtab_shdr = NULL, *strtab_shdr = NULL;
    for (int i = 0; i< ehdr.e_shnum; i++) {
        if (shdrs[i].sh_type == SHT_SYMTAB) {
            symtab_shdr = &shdrs[i];
            //sh_link 指向对应的字符串细节
            strtab_shdr = &shdrs[symtab_shdr->sh_link]; // sh_link 直接指向 .strtab的索引
        }
    }
    Assert(symtab_shdr && strtab_shdr, "ftrace: .symtab/.strtab not found in ELF");

    // 读符号表
    int sym_cnt = symtab_shdr->sh_size / sizeof(Elf32_Sym); // 条目数
    Elf32_Sym *syms = malloc(symtab_shdr->sh_size);
    Assert(syms, "ftrace: malloc syms failed");
    fseek(fp, symtab_shdr->sh_offset, SEEK_SET);
    Assert(fread(syms, symtab_shdr->sh_size, 1, fp) == 1, "ftrace: read symtab failed");

    // 读字符串表
    char *strtab = malloc(strtab_shdr->sh_size);
    Assert(strtab, "ftrace: malloc strtab failed");
    fseek(fp, strtab_shdr->sh_offset, SEEK_SET);
    Assert(fread(strtab, strtab_shdr->sh_size, 1, fp) == 1, "ftrace: read strtab failed");

    //统计函数符号数量，分配表
    int cnt = 0;
    for (int i = 0; i < sym_cnt; i++) {
        if (ELF32_ST_TYPE(syms[i].st_info) == STT_FUNC && syms[i].st_size > 0)
        cnt++;
    }
    func_table = malloc(cnt *sizeof(FuncSymbol));
    Assert(func_table, "ftrace: malloc func_table failed");

    func_cnt = 0;
    for (int i = 0; i < sym_cnt; i++)
    {
        if (ELF32_ST_TYPE(syms[i].st_info) == STT_FUNC && syms[i].st_size > 0)
        {
            func_table[func_cnt].addr = (uint32_t)syms[i].st_value;
            func_table[func_cnt].size = (uint32_t)syms[i].st_size;
            strncpy(func_table[func_cnt].name, strtab + syms[i].st_name, 63);
            func_table[func_cnt].name[63] = '\0';
            func_cnt++;
        }
    }
    
    free(syms);
    free(strtab);
    free(shdrs);
    fclose(fp);

    Log("ftrace: loaded %d function symbols from '%s'", func_cnt, elf_file);

}
//call or ret
//1 = call 进入函数
//-1 = ret 返回
//pc 调用返回发生时的pc(jal/jalr指令地址)
//target跳转目标地址
void ftrace_log(int call_or_ret, uint32_t pc, uint32_t target) {
    if (func_table == NULL) return;

    if (call_or_ret == 1) {
        //call先打印，再加深度
        log_write("[Ftrace]: 0x%08x: \t \t", pc);
        for (int i = 0; i < call_depth; i++) log_write("  \t");
        log_write("call [%s@0x%08x]\n", find_func_by_entry(target), target);
        call_depth++;
    } else {
        //ret:先减深度，再打印
        if (call_depth > 0) call_depth--;
        log_write("[Ftrace]: 0x%08x: \t \t", pc);
        for (int i = 0; i < call_depth; i++) log_write("  \t");
        log_write("ret  [%s]\n", find_func(pc));
    }
}

#endif //CONFIG_FTRACE