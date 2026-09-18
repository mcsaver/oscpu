#pragma once
#include <atomic>
#include <condition_variable>
#include <cstdlib>
#include <cstdint>
#include <mutex>
#include <stdexcept>
#include <thread>
#include <vector>

// Workers sleep between jobs. All lanes must reach every barrier inside a job.
// No RTL state is committed until run() has joined every participating lane.
class StagePool {
 public:
  using Job = void (*)(void*, unsigned, unsigned, StagePool&);
  static unsigned configured_threads() {
    const char* value=std::getenv("R64_MODEL_THREADS");
    if(!value)return 1;
    char* end=nullptr;unsigned long n=std::strtoul(value,&end,10);
    if(!*value || *end || n<1 || n>256)throw std::runtime_error("R64_MODEL_THREADS must be 1..256");
    return unsigned(n);
  }
  explicit StagePool(unsigned count=configured_threads()):count_(count) {
    if(!count_)throw std::invalid_argument("zero workers");
    try {
      for(unsigned i=1;i<count_;++i)workers_.emplace_back([this,i]{worker(i);});
    } catch(...) {
      {std::lock_guard<std::mutex> lock(mutex_);stop_=true;}
      wake_.notify_all();
      for(auto& t:workers_)t.join();
      throw;
    }
  }
  ~StagePool() {
    {std::lock_guard<std::mutex> lock(mutex_);stop_=true;}
    wake_.notify_all();
    for(auto& t:workers_)t.join();
  }
  StagePool(const StagePool&)=delete;
  StagePool& operator=(const StagePool&)=delete;
  unsigned size()const{return count_;}
  // Callbacks are nonthrowing generated arithmetic. Assertions run on the
  // owner thread outside these jobs; throwing through a barrier is invalid.
  void run(Job job,void* context) {
    if(count_==1){job(context,0,1,*this);return;}
    {
      std::lock_guard<std::mutex> lock(mutex_);
      job_=job;context_=context;completed_=0;++generation_;
    }
    wake_.notify_all();
    job(context,0,count_,*this);
    std::unique_lock<std::mutex> lock(mutex_);
    finished_.wait(lock,[this]{return completed_==count_-1;});
  }
  void barrier() {
    if(count_==1)return;
    const unsigned phase=barrier_generation_.load(std::memory_order_acquire);
    if(arrived_.fetch_add(1,std::memory_order_acq_rel)==count_-1) {
      arrived_.store(0,std::memory_order_relaxed);
      barrier_generation_.fetch_add(1,std::memory_order_release);
    } else {
      unsigned spins=0;
      while(barrier_generation_.load(std::memory_order_acquire)==phase) {
#if defined(__i386__) || defined(__x86_64__)
        __builtin_ia32_pause();
#endif
        if(++spins==2048){std::this_thread::yield();spins=0;}
      }
    }
  }
 private:
  void worker(unsigned lane) {
    uint64_t observed=0;
    for(;;) {
      Job job;void* context;
      {
        std::unique_lock<std::mutex> lock(mutex_);
        wake_.wait(lock,[&]{return stop_ || generation_!=observed;});
        if(stop_)return;
        observed=generation_;job=job_;context=context_;
      }
      job(context,lane,count_,*this);
      {
        std::lock_guard<std::mutex> lock(mutex_);++completed_;
      }
      finished_.notify_one();
    }
  }
  const unsigned count_;
  std::vector<std::thread> workers_;
  std::mutex mutex_;
  std::condition_variable wake_,finished_;
  Job job_=nullptr;void* context_=nullptr;
  uint64_t generation_=0;
  unsigned completed_=0;bool stop_=false;
  alignas(64) std::atomic<unsigned> arrived_{0};
  alignas(64) std::atomic<unsigned> barrier_generation_{0};
};
