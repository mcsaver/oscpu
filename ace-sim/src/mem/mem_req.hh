// ace-sim: 内存请求 packet + 端口接口(不变量 #6)。
// CPU 只通过 MemPort::send() 与内存交互,不深入内部。
#pragma once
#include <cstdint>
#include "sim/cycle.hh"

namespace ace {

struct MemReq {
  uint64_t dyn_id   = 0;             // 发起该 load 的 dyn-inst id(用于响应回填)
  uint64_t addr     = 0;
  CompId   requester = kInvalidComp; // 响应事件投递目标
  Epoch    epoch    = 0;
  uint32_t tag      = 0;             // 请求方私有标签(如 ROB idx),原样回显到响应 payload2
  uint32_t extra_latency = 0;        // 额外延迟(如 TLB miss 页表 walk,④),内存加到响应时刻
};

// 内存端口。
//  - load:检查 can_send() 后 send() 一个读请求,响应由事件异步返回;backpressure 由 can_send() 表达。
//  - store drain:write() 同步落存(store buffer 排空,V3;写延迟/带宽建模留后续)。
class MemPort {
 public:
  virtual ~MemPort() = default;
  virtual bool can_send() const = 0;
  virtual void send(const MemReq& req) = 0;               // 读请求;调用前必须 can_send()
  virtual void write(uint64_t addr, uint64_t data) = 0;   // 已提交 store 落存
};

}  // namespace ace
