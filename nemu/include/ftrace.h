#ifndef __FTRACE_H__
#define __FTRACE_H__

#ifdef CONFIG_FTRACE
void init_ftrace(const char *elf_file);
void ftrace_log(int call_or_ret, uint32_t pc, uint32_t target);
#else
#define init_ftrace(f) ((void)0)
#define ftrace_log(t, pc, dst) ((void)0)
#endif

#endif // __FTRACE_H__