#ifndef KLIB_MACROS_H__
#define KLIB_MACROS_H__

//把地址或者数值a向上对齐到sz的整数倍，常用于页对齐、栈对齐、缓冲区对齐
#define ROUNDUP(a, sz)      ((((uintptr_t)a) + (sz) - 1) & ~((sz) - 1))
//把a向下对齐到sz的整数倍，常用于处理整数和指针
#define ROUNDDOWN(a, sz)    ((((uintptr_t)a)) & ~((sz) - 1))
//求静态数组元素个数，例a[10]，LENGTH(a)就是10，只能用于真正的数组，不能用于指针
#define LENGTH(arr)         (sizeof(arr) / sizeof((arr)[0]))
//构造一个Area结构体，表示左闭右开的区间[st,ed)，例子，用于构造heap区间
#define RANGE(st, ed)       (Area) { .start = (void *)(st), .end = (void *)(ed) }
//判断指针ptr是否落在area这个区间，左闭右开区间判断，用于在区间拼接的时候边界更加自然，不会重复包含终点
#define IN_RANGE(ptr, area) ((area).start <= (ptr) && (ptr) < (area).end)

//把参数直接转换成字符串字面量
#define STRINGIFY(s)        #s
//两层封装，用于转字符串，先展开宏，再转字符串
#define TOSTRING(s)         STRINGIFY(s)
//拼接用,CONCAT(foo,1) 变成 foo1
#define _CONCAT(x, y)       x ## y
#define CONCAT(x, y)        _CONCAT(x, y)

//贴近AM实际使用
//把一个字符串逐字符输出
//从字符串首地址开始，遇到非0字符就开始调用putch输出，遇到'\0'结束
#define putstr(s) \
  ({ for (const char *p = s; *p; p++) putch(*p); })

//读取一个AM设备寄存器
#define io_read(reg) \
  ({ reg##_T __io_param; \
    ioe_read(reg, &__io_param); \
    __io_param; })

//写一个AM设备寄存器
#define io_write(reg, ...) \
  ({ reg##_T __io_param = (reg##_T) { __VA_ARGS__ }; \
    ioe_write(reg, &__io_param); })

//编译器断言
#define static_assert(const_cond) \
  static char CONCAT(_static_assert_, __LINE__) [(const_cond) ? 1 : -1] __attribute__((unused))

//打印错误
#define panic_on(cond, s) \
  ({ if (cond) { \
      putstr("AM Panic: "); putstr(s); \
      putstr(" @ " __FILE__ ":" TOSTRING(__LINE__) "  \n"); \
      halt(1); \
    } })

#define panic(s) panic_on(1, s)

#endif
