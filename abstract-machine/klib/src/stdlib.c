#include <am.h>
#include <klib.h>
#include <klib-macros.h>

#include <limits.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)
static unsigned long int next = 1;

// 统一收口空白、符号、进制前缀和溢出处理，让 atoi/atol/strtol/strtoul 共用一套规则。
static int is_space_char(char ch) {
  return ch == ' ' || ch == '\f' || ch == '\n' || ch == '\r' || ch == '\t' || ch == '\v';
}

static int digit_value(char ch) {
  if (ch >= '0' && ch <= '9') {
    return ch - '0';
  }
  if (ch >= 'a' && ch <= 'z') {
    return ch - 'a' + 10;
  }
  if (ch >= 'A' && ch <= 'Z') {
    return ch - 'A' + 10;
  }
  return -1;
}

static unsigned long parse_unsigned_magnitude(const char *nptr, char **endptr, int base,
                                              unsigned long limit, int *converted,
                                              int *overflowed) {
  const char *s = nptr;
  unsigned long value = 0;
  unsigned long cutoff = 0;
  unsigned long cutlim = 0;
  int any = 0;

  *converted = 0;
  *overflowed = 0;

  if (base != 0 && (base < 2 || base > 36)) {
    if (endptr != NULL) {
      *endptr = (char *)nptr;
    }
    return 0;
  }

  if (base == 0) {
    if (s[0] == '0') {
      if (s[1] == 'x' || s[1] == 'X') {
        int hex_digit = digit_value(s[2]);
        if (hex_digit >= 0 && hex_digit < 16) {
          base = 16;
          s += 2;
        } else {
          base = 8;
        }
      } else {
        base = 8;
      }
    } else {
      base = 10;
    }
  } else if (base == 16) {
    if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) {
      int hex_digit = digit_value(s[2]);
      if (hex_digit >= 0 && hex_digit < 16) {
        s += 2;
      }
    }
  }

  cutoff = limit / (unsigned long)base;
  cutlim = limit % (unsigned long)base;

  while (1) {
    int digit = digit_value(*s);
    if (digit < 0 || digit >= base) {
      break;
    }

    any = 1;
    if (value > cutoff || (value == cutoff && (unsigned long)digit > cutlim)) {
      *overflowed = 1;
      value = limit;
    } else if (!(*overflowed)) {
      value = value * (unsigned long)base + (unsigned long)digit;
    }
    ++s;
  }

  if (!any) {
    if (endptr != NULL) {
      *endptr = (char *)nptr;
    }
    return 0;
  }

  *converted = 1;
  if (endptr != NULL) {
    *endptr = (char *)s;
  }
  return value;
}

int rand(void) {
  next = next * 1103515245 + 12345;
  return (unsigned int)(next / 65536) % (RAND_MAX + 1);
}

void srand(unsigned int seed) {
  next = seed;
}

int abs(int x) {
  return (x < 0 ? -x : x);
}

long labs(long x) {
  return (x < 0 ? -x : x);
}

unsigned long strtoul(const char *nptr, char **endptr, int base) {
  const char *s = nptr;
  unsigned long value = 0;
  int negative = 0;
  int converted = 0;
  int overflowed = 0;

  while (is_space_char(*s)) {
    ++s;
  }

  if (*s == '+' || *s == '-') {
    negative = (*s == '-');
    ++s;
  }

  value = parse_unsigned_magnitude(s, endptr, base, ULONG_MAX, &converted, &overflowed);
  if (!converted) {
    if (endptr != NULL) {
      *endptr = (char *)nptr;
    }
    return 0;
  }

  if (overflowed) {
    return ULONG_MAX;
  }
  return negative ? (0UL - value) : value;
}

long strtol(const char *nptr, char **endptr, int base) {
  const char *s = nptr;
  unsigned long value = 0;
  unsigned long limit = 0;
  int negative = 0;
  int converted = 0;
  int overflowed = 0;

  while (is_space_char(*s)) {
    ++s;
  }

  if (*s == '+' || *s == '-') {
    negative = (*s == '-');
    ++s;
  }

  limit = negative ? ((unsigned long)LONG_MAX + 1UL) : (unsigned long)LONG_MAX;
  value = parse_unsigned_magnitude(s, endptr, base, limit, &converted, &overflowed);
  if (!converted) {
    if (endptr != NULL) {
      *endptr = (char *)nptr;
    }
    return 0;
  }

  if (overflowed) {
    return negative ? LONG_MIN : LONG_MAX;
  }
  if (negative) {
    if (value == ((unsigned long)LONG_MAX + 1UL)) {
      return LONG_MIN;
    }
    return -(long)value;
  }
  return (long)value;
}

int atoi(const char *nptr) {
  return (int)strtol(nptr, NULL, 10);
}

long atol(const char *nptr) {
  return strtol(nptr, NULL, 10);
}

#if !defined(__ISA_NATIVE__)

typedef struct HeapBlock {
  size_t size;
  struct HeapBlock *prev_free;
  struct HeapBlock *next_free;
  int is_free;
} HeapBlock;

typedef struct HeapFooter {
  size_t size;
} HeapFooter;

#define KLIB_ALLOC_ALIGN     8u
#define HEAP_BLOCK_HEAD_SIZE ((size_t)ROUNDUP(sizeof(HeapBlock), KLIB_ALLOC_ALIGN))
#define HEAP_BLOCK_FOOT_SIZE ((size_t)ROUNDUP(sizeof(HeapFooter), KLIB_ALLOC_ALIGN))
#define HEAP_BLOCK_OVERHEAD  (HEAP_BLOCK_HEAD_SIZE + HEAP_BLOCK_FOOT_SIZE)
#define HEAP_MIN_BLOCK_SIZE  (HEAP_BLOCK_OVERHEAD + KLIB_ALLOC_ALIGN)

static char *heap_begin = NULL;
static char *heap_limit = NULL;
static HeapBlock *free_list = NULL;
static int heap_initialized = 0;

static void heap_write_footer(HeapBlock *block) {
  HeapFooter *footer = (HeapFooter *)((char *)block + block->size - HEAP_BLOCK_FOOT_SIZE);
  footer->size = block->size;
}

static size_t heap_payload_size(const HeapBlock *block) {
  return block->size - HEAP_BLOCK_OVERHEAD;
}

static void *heap_payload(HeapBlock *block) {
  return (char *)block + HEAP_BLOCK_HEAD_SIZE;
}

static HeapBlock *heap_from_payload(void *ptr) {
  return (HeapBlock *)((char *)ptr - HEAP_BLOCK_HEAD_SIZE);
}

static HeapBlock *heap_next_block(const HeapBlock *block) {
  char *next = (char *)block + block->size;
  return (next >= heap_limit) ? NULL : (HeapBlock *)next;
}

static HeapBlock *heap_prev_block(const HeapBlock *block) {
  HeapFooter *footer;
  size_t prev_size;

  if ((char *)block <= heap_begin) {
    return NULL;
  }

  footer = (HeapFooter *)((char *)block - HEAP_BLOCK_FOOT_SIZE);
  prev_size = footer->size;
  if (prev_size == 0 || (char *)block - prev_size < heap_begin) {
    return NULL;
  }
  return (HeapBlock *)((char *)block - prev_size);
}

static void heap_remove_free(HeapBlock *block) {
  if (block->prev_free != NULL) {
    block->prev_free->next_free = block->next_free;
  } else if (free_list == block) {
    free_list = block->next_free;
  }

  if (block->next_free != NULL) {
    block->next_free->prev_free = block->prev_free;
  }

  block->prev_free = NULL;
  block->next_free = NULL;
}

static void heap_insert_free(HeapBlock *block) {
  block->is_free = 1;
  block->prev_free = NULL;
  block->next_free = free_list;
  if (free_list != NULL) {
    free_list->prev_free = block;
  }
  free_list = block;
}

static int heap_try_init(void) {
  uintptr_t aligned_start;
  uintptr_t aligned_end;

  if (heap_initialized) {
    return heap_begin != NULL;
  }

  heap_initialized = 1;
  if (heap.start == NULL || heap.end == NULL) {
    return 0;
  }

  aligned_start = ROUNDUP(heap.start, KLIB_ALLOC_ALIGN);
  aligned_end = ROUNDDOWN(heap.end, KLIB_ALLOC_ALIGN);
  if (aligned_start >= aligned_end || aligned_end - aligned_start < HEAP_MIN_BLOCK_SIZE) {
    return 0;
  }

  heap_begin = (char *)aligned_start;
  heap_limit = (char *)aligned_end;
  free_list = (HeapBlock *)heap_begin;
  free_list->size = (size_t)(heap_limit - heap_begin);
  free_list->prev_free = NULL;
  free_list->next_free = NULL;
  free_list->is_free = 1;
  heap_write_footer(free_list);
  return 1;
}

static int heap_compute_block_size(size_t request, size_t *block_size) {
  size_t payload = (request == 0) ? KLIB_ALLOC_ALIGN : request;

  if (payload > SIZE_MAX - (KLIB_ALLOC_ALIGN - 1)) {
    return 0;
  }

  payload = (size_t)ROUNDUP(payload, KLIB_ALLOC_ALIGN);
  if (payload > SIZE_MAX - HEAP_BLOCK_OVERHEAD) {
    return 0;
  }

  *block_size = payload + HEAP_BLOCK_OVERHEAD;
  if (*block_size < HEAP_MIN_BLOCK_SIZE) {
    *block_size = HEAP_MIN_BLOCK_SIZE;
  }
  return 1;
}

static HeapBlock *heap_find_fit(size_t block_size) {
  HeapBlock *block = free_list;
  while (block != NULL) {
    if (block->size >= block_size) {
      return block;
    }
    block = block->next_free;
  }
  return NULL;
}

static void heap_trim_block(HeapBlock *block, size_t block_size) {
  size_t remain_size = block->size - block_size;

  if (remain_size < HEAP_MIN_BLOCK_SIZE) {
    block->is_free = 0;
    heap_write_footer(block);
    return;
  }

  block->size = block_size;
  block->is_free = 0;
  heap_write_footer(block);

  // 分裂出的尾块立即回收到空闲链表，保证 free/realloc 能真正复用碎片。
  HeapBlock *remain = (HeapBlock *)((char *)block + block_size);
  remain->size = remain_size;
  remain->prev_free = NULL;
  remain->next_free = NULL;
  remain->is_free = 1;
  heap_write_footer(remain);
  heap_insert_free(remain);
}

static HeapBlock *heap_coalesce(HeapBlock *block) {
  HeapBlock *next = heap_next_block(block);
  if (next != NULL && next->is_free) {
    heap_remove_free(next);
    block->size += next->size;
    heap_write_footer(block);
  }

  HeapBlock *prev = heap_prev_block(block);
  if (prev != NULL && prev->is_free) {
    heap_remove_free(prev);
    prev->size += block->size;
    heap_write_footer(prev);
    block = prev;
  }
  return block;
}

void *malloc(size_t size) {
  HeapBlock *block;
  size_t block_size = 0;

  if (!heap_compute_block_size(size, &block_size) || !heap_try_init()) {
    return NULL;
  }

  block = heap_find_fit(block_size);
  if (block == NULL) {
    return NULL;
  }

  heap_remove_free(block);
  heap_trim_block(block, block_size);
  return heap_payload(block);
}

void free(void *ptr) {
  HeapBlock *block;

  if (ptr == NULL || !heap_try_init()) {
    return;
  }

  block = heap_from_payload(ptr);
  block->is_free = 1;
  block->prev_free = NULL;
  block->next_free = NULL;
  heap_write_footer(block);
  block = heap_coalesce(block);
  heap_insert_free(block);
}

void *calloc(size_t nmemb, size_t size) {
  size_t total = 0;
  void *ptr = NULL;

  if (nmemb != 0 && size > SIZE_MAX / nmemb) {
    return NULL;
  }

  total = nmemb * size;
  ptr = malloc(total);
  if (ptr != NULL) {
    memset(ptr, 0, total);
  }
  return ptr;
}

void *realloc(void *ptr, size_t size) {
  HeapBlock *block;
  HeapBlock *next;
  size_t block_size = 0;
  size_t copy_size = 0;
  void *new_ptr = NULL;

  if (ptr == NULL) {
    return malloc(size);
  }

  if (size == 0) {
    free(ptr);
    return NULL;
  }

  if (!heap_compute_block_size(size, &block_size) || !heap_try_init()) {
    return NULL;
  }

  block = heap_from_payload(ptr);
  if (block->size >= block_size) {
    heap_trim_block(block, block_size);
    return ptr;
  }

  next = heap_next_block(block);
  if (next != NULL && next->is_free && block->size + next->size >= block_size) {
    heap_remove_free(next);
    block->size += next->size;
    heap_write_footer(block);
    heap_trim_block(block, block_size);
    return ptr;
  }

  new_ptr = malloc(size);
  if (new_ptr == NULL) {
    return NULL;
  }

  copy_size = heap_payload_size(block);
  if (copy_size > size) {
    copy_size = size;
  }
  memcpy(new_ptr, ptr, copy_size);
  free(ptr);
  return new_ptr;
}

#else

// native 目标直接复用宿主 libc 的分配器，避免在 C runtime 初始化阶段拦截宿主启动路径。

#endif

#endif
