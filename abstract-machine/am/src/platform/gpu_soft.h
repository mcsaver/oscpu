#ifndef __AM_PLATFORM_GPU_SOFT_H__
#define __AM_PLATFORM_GPU_SOFT_H__

#include <am.h>
#include <klib-macros.h>
#include <stdint.h>

#define AM_GPU_SOFT_VMEM_SIZE (512 << 10)

typedef struct {
  uint32_t width;
  uint32_t height;
} am_gpu_surface_t;

static uint8_t am_gpu_vmem[AM_GPU_SOFT_VMEM_SIZE];
static uint8_t am_gpu_scratch[AM_GPU_SOFT_VMEM_SIZE];
static uint8_t *am_gpu_scratch_head = am_gpu_scratch;

static inline bool am_gpu_present(uint32_t width, uint32_t height) {
  return width > 0 && height > 0;
}

static inline void *am_gpu_to_host(gpuptr_t ptr) {
  if (ptr == AM_GPU_NULL) {
    return NULL;
  }

  panic_on(ptr >= AM_GPU_SOFT_VMEM_SIZE, "gpu pointer out of range");
  return am_gpu_vmem + ptr;
}

static inline void am_gpu_reset_scratch(void) {
  am_gpu_scratch_head = am_gpu_scratch;
}

static inline void *am_gpu_alloc_scratch(uint32_t size) {
  panic_on(size > AM_GPU_SOFT_VMEM_SIZE, "gpu scratch request too large");

  uint8_t *ret = am_gpu_scratch_head;
  am_gpu_scratch_head += size;
  panic_on(am_gpu_scratch_head > am_gpu_scratch + sizeof(am_gpu_scratch), "gpu scratch overflow");

  for (uint32_t i = 0; i < size; i++) {
    ret[i] = 0;
  }
  return ret;
}

static inline void am_gpu_memcpy_to_vmem(AM_GPU_MEMCPY_T *params) {
  panic_on(params->size < 0, "gpu memcpy size is negative");
  if (params->size == 0) {
    return;
  }

  panic_on(params->src == NULL, "gpu memcpy src is NULL");

  uint32_t size = (uint32_t)params->size;
  panic_on(params->dest > AM_GPU_SOFT_VMEM_SIZE || size > AM_GPU_SOFT_VMEM_SIZE - params->dest,
      "gpu memcpy out of range");

  uint8_t *src = (uint8_t *)params->src;
  uint8_t *dst = (uint8_t *)am_gpu_to_host(params->dest);
  for (uint32_t i = 0; i < size; i++) {
    dst[i] = src[i];
  }
}

static void am_gpu_render_node(struct gpu_canvas *cv, const am_gpu_surface_t *parent, uint32_t *target) {
  panic_on(cv == NULL, "gpu render root is NULL");

  uint32_t *local_pixels = NULL;
  uint32_t local_w = 0;
  uint32_t local_h = 0;

  switch (cv->type) {
    case AM_GPU_TEXTURE:
      local_w = cv->texture.w;
      local_h = cv->texture.h;
      panic_on(local_w == 0 || local_h == 0, "gpu texture size is zero");
      local_pixels = (uint32_t *)am_gpu_to_host(cv->texture.pixels);
      panic_on(local_pixels == NULL, "gpu texture pixels is NULL");
      break;

    case AM_GPU_SUBTREE: {
      local_w = cv->w;
      local_h = cv->h;
      panic_on(local_w == 0 || local_h == 0, "gpu subtree size is zero");
      local_pixels = (uint32_t *)am_gpu_alloc_scratch(local_w * local_h * sizeof(uint32_t));

      am_gpu_surface_t child_surface = {
        .width = local_w,
        .height = local_h,
      };

      for (struct gpu_canvas *child = (struct gpu_canvas *)am_gpu_to_host(cv->child);
           child != NULL;
           child = (struct gpu_canvas *)am_gpu_to_host(child->sibling)) {
        am_gpu_render_node(child, &child_surface, local_pixels);
      }
      break;
    }

    default:
      panic("invalid gpu node type");
  }

  if (cv->w1 == 0 || cv->h1 == 0) {
    return;
  }

  for (uint32_t j = 0; j < cv->h1; j++) {
    for (uint32_t i = 0; i < cv->w1; i++) {
      uint32_t dst_x = cv->x1 + i;
      uint32_t dst_y = cv->y1 + j;
      if (dst_x < parent->width && dst_y < parent->height) {
        uint32_t src_x = i * local_w / cv->w1;
        uint32_t src_y = j * local_h / cv->h1;
        target[parent->width * dst_y + dst_x] = local_pixels[local_w * src_y + src_x];
      }
    }
  }
}

static inline void am_gpu_render_to_fb(gpuptr_t root, uint32_t width, uint32_t height, uint32_t *fb) {
  if (!am_gpu_present(width, height) || root == AM_GPU_NULL || fb == NULL) {
    return;
  }

  am_gpu_reset_scratch();
  am_gpu_surface_t display = {
    .width = width,
    .height = height,
  };
  am_gpu_render_node((struct gpu_canvas *)am_gpu_to_host(root), &display, fb);
}

#endif