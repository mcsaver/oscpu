#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

//计算字符串长度
size_t strlen(const char *s) {
  //panic("Not implemented");
  const char *p = s;
  while (*p) ++p;
  return (size_t)(p - s);
}

//把src字符复制到dst(含\0)
char *strcpy(char *dst, const char *src) {
  //panic("Not implemented");
  char *ret = dst;
  while((*dst++ = *src++) != '\0') {
    //循环体必须保留，不然只能执行一次
  }
  return ret;
}

//最多复制n个字符到dst(不足时补\0，超出不一定写\0)
//const约束的是你不能改src指向的字符内容，并不代表你不能改src这个变量本身
char *strncpy(char *dst, const char *src, size_t n) {
  //panic("Not implemented");
  char *ret = dst;
  //复制src，最多n个字节，遇到'\0'就停止复制内容
  while (n && *src) 
  {
    *dst++ = *src++;
    --n;
  }
  //如果src提前结束，用'\0'填充到n个字节
  while (n)
  {
    *dst++ = '\0';
    --n;
  }
  return ret;
}

//把src追加到dst末尾(含\0)
char *strcat(char *dst, const char *src) {
  //panic("Not implemented");
  char *ret = dst;
  //先找到dst的'\0'
  while (*dst)
  {
    ++dst;
  }
  //把src复制到dst末尾(包含'\0')
  while((*dst++ = *src++) != '\0') {
    //同strcpy
  }
  return ret;
}

//按字典序比较两个字符串(返回<0 / 0 / >0)
int strcmp(const char *s1, const char *s2) {
  //panic("Not implemented");
  const unsigned char *p1 = (const unsigned char *)s1;
  const unsigned char *p2 = (const unsigned char *)s2;

  //跳过两个字符串开头连续相同的部分
  while (*p1 && (*p1 == *p2))
  {
    ++p1;
    ++p2;
  }
  return (int)(*p1) - (int)(*p2);
}

//比较前n个字符
int strncmp(const char *s1, const char *s2, size_t n) {
  //panic("Not implemented");
  const unsigned char *p1 = (const unsigned char *)s1;
  const unsigned char *p2 = (const unsigned char *)s2;

  while (n && *p1 && (*p1 == *p2))
  {
    ++p1;
    ++p2;
    --n;
  }
  if (n == 0) return 0;
  return (int)(*p1) - (int)(*p2);
}

//把一段内存设置为同一字节值
void *memset(void *s, int c, size_t n) {
  //panic("Not implemented");
  unsigned char *p = (unsigned char *)s;
  unsigned char v = (unsigned char)c;

  while (n--)
  {
    *p++ = v;
  }
  return s;
}

//内存拷贝，支持重叠区域
void *memmove(void *dst, const void *src, size_t n) {
  //panic("Not implemented");
  unsigned char *d = (unsigned char *)dst;
  const unsigned char *s = (const unsigned char *)src;

  if (d == s || n == 0)
  {
    return dst;
  }
  
  //如果dst在src之后发生重叠，必须从后往前拷贝
  if (d > s && d < s + n)
  {
    d += n;
    s += n;
    while (n--)
    {
      *--d = *--s;
    }
    
  } else {
    //否则从前往后拷贝
    while (n--)
    {
      *d++ = *s++;
    }
    
  }
  return dst;

}

//内存拷贝，不保证重叠安全
void *memcpy(void *out, const void *in, size_t n) {
 // panic("Not implemented");
 unsigned char *d = (unsigned char *)out;
 const unsigned char *s = (unsigned char *)in;

 while (n--)
 {
  *d++ = *s++;
 }
 return out;
}

//逐字节比较内存(返回<0/0/>0)
int memcmp(const void *s1, const void *s2, size_t n) {
  //panic("Not implemented");
  const unsigned char *p1 = (const unsigned char *)s1;
  const unsigned char *p2 = (const unsigned char *)s2;

  while (n--)
  {
    unsigned char a = *p1++;
    unsigned char b = *p2++;
    if (a != b)
    {
      return (int)a - (int)b;
    }
    
  }
  return 0;
}

#endif
