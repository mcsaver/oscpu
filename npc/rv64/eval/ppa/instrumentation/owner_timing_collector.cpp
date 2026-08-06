#include <array>
#include <cinttypes>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <limits>

namespace owner_timing {

constexpr uint32_t kBridgeCount = 2;
constexpr uint32_t kEncodedStateCount = 16;
constexpr uint32_t kLegalStateCount = 13;
constexpr uint32_t kHistogramBinCount = 9;

enum class OperationClass : uint32_t {
  Load = 0,
  Store = 1,
  Atomic = 2,
  AdUpdate = 3,
  Unknown = 4,
  Count = 5,
};

enum class Stage : uint32_t {
  AdmissionWait = 0,
  Reservation = 1,
  Translation = 2,
  WriteRequest = 3,
  WriteResponse = 4,
  AwWToB = 5,
  SqQuery = 6,
  Count = 7,
};

enum class InvalidReason : uint32_t {
  Configuration = 0,
  IllegalState = 1,
  ActiveKind = 2,
  StationKind = 3,
  RequestKind = 4,
  RequestFireWithoutValid = 5,
  StageAdvanceWithoutStation = 6,
  StationCancelWithoutStation = 7,
  ActiveDropWithoutActive = 8,
  StageIdentityChange = 9,
  AdmissionIdentityChange = 10,
  WriteOccupancy = 11,
  BoundaryOrder = 12,
  Count = 13,
};

constexpr uint32_t kOperationClassCount =
    static_cast<uint32_t>(OperationClass::Count);
constexpr uint32_t kStageCount = static_cast<uint32_t>(Stage::Count);
constexpr uint32_t kInvalidReasonCount =
    static_cast<uint32_t>(InvalidReason::Count);

constexpr const char *kOperationClassNames[kOperationClassCount] = {
    "load", "store", "atomic", "a_d_update", "unknown"};
constexpr const char *kStageNames[kStageCount] = {
    "admission_wait", "reservation", "translation", "write_request",
    "write_response", "aw_w_to_b", "sq_query"};
constexpr const char *kInvalidReasonNames[kInvalidReasonCount] = {
    "configuration",
    "illegal_state",
    "active_kind",
    "station_kind",
    "request_kind",
    "request_fire_without_valid",
    "stage_advance_without_station",
    "station_cancel_without_station",
    "active_drop_without_active",
    "stage_identity_change",
    "admission_identity_change",
    "write_occupancy",
    "boundary_order",
};

struct OwnerIdentity {
  uint32_t kind = 3;
  uint32_t token = 0;
  uint32_t epoch = 0;

  bool operator==(const OwnerIdentity &other) const {
    return kind == other.kind && token == other.token && epoch == other.epoch;
  }
  bool operator!=(const OwnerIdentity &other) const { return !(*this == other); }
};

struct BridgeSample {
  uint32_t state = 0;
  OwnerIdentity active;
  bool station_valid = false;
  OwnerIdentity station;
  bool request_valid = false;
  bool request_fire = false;
  OwnerIdentity request;
  bool aw_complete = false;
  bool w_complete = false;
  bool bvalid = false;
  bool stage_advance = false;
  bool station_cancel = false;
  bool active_drop = false;
  bool response_fire = false;

  bool active_valid() const { return state != 0; }
};

static uint32_t field(uint64_t value, uint32_t low, uint32_t width) {
  return static_cast<uint32_t>((value >> low) & ((UINT64_C(1) << width) - 1));
}

static BridgeSample decode_bridge(uint64_t value) {
  BridgeSample sample;
  sample.state = field(value, 0, 4);
  sample.active.kind = field(value, 4, 2);
  sample.active.token = field(value, 6, 5);
  sample.active.epoch = field(value, 11, 2);
  sample.station_valid = field(value, 13, 1) != 0;
  sample.station.kind = field(value, 14, 2);
  sample.station.token = field(value, 16, 5);
  sample.station.epoch = field(value, 21, 2);
  sample.request_valid = field(value, 23, 1) != 0;
  sample.request_fire = field(value, 24, 1) != 0;
  sample.request.kind = field(value, 25, 2);
  sample.request.token = field(value, 27, 5);
  sample.request.epoch = field(value, 32, 2);
  sample.aw_complete = field(value, 34, 1) != 0;
  sample.w_complete = field(value, 35, 1) != 0;
  sample.bvalid = field(value, 36, 1) != 0;
  sample.stage_advance = field(value, 37, 1) != 0;
  sample.station_cancel = field(value, 38, 1) != 0;
  sample.active_drop = field(value, 39, 1) != 0;
  sample.response_fire = field(value, 40, 1) != 0;
  return sample;
}

static uint32_t duration_bin(uint64_t duration) {
  if (duration == 0) return 0;
  if (duration == 1) return 1;
  if (duration == 2) return 2;
  if (duration <= 4) return 3;
  if (duration <= 8) return 4;
  if (duration <= 16) return 5;
  if (duration <= 32) return 6;
  if (duration <= 64) return 7;
  return 8;
}

static OperationClass operation_class(const OwnerIdentity &owner,
                                      uint32_t state) {
  if (state == 8) return OperationClass::AdUpdate;
  if (owner.kind == 0) return OperationClass::Load;
  if (owner.kind == 1) return OperationClass::Store;
  if (owner.kind == 2) return OperationClass::Atomic;
  return OperationClass::Unknown;
}

static bool translation_state(uint32_t state) {
  return state == 1 || state == 2 || state == 8;
}

static bool write_inflight_state(uint32_t state) {
  return state == 5 || state == 6 || state == 8;
}

struct Aggregate {
  uint64_t eligible_started = 0;
  uint64_t completed = 0;
  uint64_t right_censored = 0;
  uint64_t cancelled = 0;
  uint64_t left_censored = 0;
  uint64_t left_completed = 0;
  uint64_t left_right_censored = 0;
  uint64_t observed_cycles = 0;
  uint64_t completed_cycles = 0;
  uint64_t rob_head_cycles = 0;
  uint64_t peer_overlap_cycles = 0;
  uint64_t bins[kHistogramBinCount] = {};
};

struct Tracker {
  bool active = false;
  bool eligible = false;
  OwnerIdentity owner;
  OperationClass operation = OperationClass::Unknown;
  uint64_t duration = 0;
};

class Collector {
 public:
  void reset() { *this = Collector(); }

  void configure(uint64_t start_pc, uint64_t end_pc) {
    configured_ = true;
    enabled_ = start_pc != end_pc;
    start_pc_ = start_pc;
    end_pc_ = end_pc;
    if (!enabled_) bump_invalid(InvalidReason::Configuration);
  }

  bool configure_from_environment() {
    if (configured_) return enabled_;
    configured_ = true;
    const char *start_text = std::getenv("NPC_REGION_START_PC");
    const char *end_text = std::getenv("NPC_REGION_END_PC");
    if (start_text == nullptr || end_text == nullptr || start_text[0] == '\0' ||
        end_text[0] == '\0') {
      return false;
    }
    char *start_tail = nullptr;
    char *end_tail = nullptr;
    const uint64_t start_pc = std::strtoull(start_text, &start_tail, 0);
    const uint64_t end_pc = std::strtoull(end_text, &end_tail, 0);
    if (start_tail == start_text || *start_tail != '\0' ||
        end_tail == end_text || *end_tail != '\0' || start_pc == end_pc) {
      enabled_ = true;
      bump_invalid(InvalidReason::Configuration);
      return true;
    }
    enabled_ = true;
    start_pc_ = start_pc;
    end_pc_ = end_pc;
    return true;
  }

  void event(bool reset_i, bool commit0_valid, uint64_t commit0_pc,
             bool commit1_valid, uint64_t commit1_pc, bool head0_valid,
             uint32_t head0_token, bool head1_valid, uint32_t head1_token,
             uint64_t bridge0_bits, uint64_t bridge1_bits) {
    if (reset_i) {
      reset();
      return;
    }
    if (!configured_) configure_from_environment();
    if (!enabled_) return;

    const BridgeSample samples[kBridgeCount] = {
        decode_bridge(bridge0_bits), decode_bridge(bridge1_bits)};
    const bool head_valid[2] = {head0_valid, head1_valid};
    const uint32_t head_token[2] = {head0_token & 31u, head1_token & 31u};

    if (start_seen_ && !end_seen_) {
      observe_cycle(samples, head_valid, head_token);
    }
    if (commit0_valid) observe_commit(0, commit0_pc, samples);
    if (commit1_valid) observe_commit(1, commit1_pc, samples);
  }

  bool complete() const {
    return enabled_ && start_seen_ && end_seen_ && roi_cycles_ != 0 &&
           !overflow_ && invalid_events_ == 0 && state_conservation() &&
           interval_conservation();
  }

  uint64_t roi_cycles() const { return roi_cycles_; }
  uint64_t start_hits() const { return start_hits_; }
  uint64_t end_hits() const { return end_hits_; }
  uint64_t invalid_events() const { return invalid_events_; }
  uint64_t invalid_reason(InvalidReason reason) const {
    return invalid_reason_counts_[static_cast<uint32_t>(reason)];
  }
  uint64_t write_occupancy(uint32_t count) const {
    return count < 3 ? write_inflight_occupancy_[count] : 0;
  }
  uint64_t b_terminal(uint32_t bridge, OperationClass operation) const {
    return bridge < kBridgeCount
               ? b_terminal_[bridge][static_cast<uint32_t>(operation)]
               : 0;
  }
  const Aggregate &aggregate(uint32_t bridge, Stage stage,
                             OperationClass operation) const {
    return aggregates_[bridge][static_cast<uint32_t>(stage)]
                      [static_cast<uint32_t>(operation)];
  }

  void report() {
    if (reported_) return;
    reported_ = true;
    if (!enabled_) {
      std::printf(
          "OWNER_TIMING_FINAL schema=npc-rv64-owner-timing-v1"
          " complete=0 available=0 overflow=%u invalid_events=%" PRIu64
          ,
          overflow_ ? 1u : 0u, invalid_events_);
      print_invalid_breakdown();
      std::printf(
          " invalid_conservation=%u"
          " start_seen=0 end_seen=0 start_hits=0 end_hits=0"
          " start_lane=0 end_lane=0 cycles=0 state_conservation=0"
          " interval_conservation=0 candidate_authorized=0"
          " promotion_eligible=0 ppa=UNQUALIFIED\n",
          invalid_reason_conservation() ? 1u : 0u);
      std::fflush(stdout);
      return;
    }
    if (start_seen_ && !intervals_finalized_) finalize_intervals();
    const bool states_ok = state_conservation();
    const bool intervals_ok = interval_conservation();
    std::printf(
        "OWNER_TIMING_FINAL schema=npc-rv64-owner-timing-v1"
        " complete=%u available=%u overflow=%u invalid_events=%" PRIu64
        ,
        complete() ? 1u : 0u, enabled_ ? 1u : 0u, overflow_ ? 1u : 0u,
        invalid_events_);
    print_invalid_breakdown();
    std::printf(
        " invalid_conservation=%u"
        " start_seen=%u end_seen=%u start_hits=%" PRIu64
        " end_hits=%" PRIu64 " start_lane=%u end_lane=%u cycles=%" PRIu64
        " state_conservation=%u interval_conservation=%u"
        " candidate_authorized=0 promotion_eligible=0 ppa=UNQUALIFIED\n",
        invalid_reason_conservation() ? 1u : 0u,
        start_seen_ ? 1u : 0u, end_seen_ ? 1u : 0u, start_hits_, end_hits_,
        start_lane_, end_lane_, roi_cycles_,
        states_ok ? 1u : 0u, intervals_ok ? 1u : 0u);
    std::printf(
        "OWNER_TIMING_OCCUPANCY write_inflight_0=%" PRIu64
        " write_inflight_1=%" PRIu64 " write_inflight_2=%" PRIu64
        " conservation=%u\n",
        write_inflight_occupancy_[0], write_inflight_occupancy_[1],
        write_inflight_occupancy_[2], states_ok ? 1u : 0u);
    for (uint32_t bridge = 0; bridge < kBridgeCount; ++bridge) {
      std::printf("OWNER_TIMING_STATE bridge=%u", bridge);
      for (uint32_t state = 0; state < kEncodedStateCount; ++state) {
        std::printf(" s%u=%" PRIu64, state, state_cycles_[bridge][state]);
      }
      std::printf("\n");
      for (uint32_t operation = 0; operation < kOperationClassCount;
           ++operation) {
        std::printf(
            "OWNER_TIMING_EVENT bridge=%u class=%s request_fire=%" PRIu64
            " b_terminal=%" PRIu64 "\n",
            bridge, kOperationClassNames[operation],
            request_fire_[bridge][operation],
            b_terminal_[bridge][operation]);
      }
      for (uint32_t stage = 0; stage < kStageCount; ++stage) {
        for (uint32_t operation = 0; operation < kOperationClassCount;
             ++operation) {
          const Aggregate &value = aggregates_[bridge][stage][operation];
          std::printf(
              "OWNER_TIMING_STAGE bridge=%u stage=%s class=%s"
              " eligible_started=%" PRIu64 " completed=%" PRIu64
              " right_censored=%" PRIu64 " cancelled=%" PRIu64
              " left_censored=%" PRIu64 " left_completed=%" PRIu64
              " left_right_censored=%" PRIu64
              " observed_cycles=%" PRIu64 " completed_cycles=%" PRIu64
              " rob_head_cycles=%" PRIu64 " peer_overlap_cycles=%" PRIu64
              " bins=%" PRIu64 "/%" PRIu64 "/%" PRIu64 "/%" PRIu64
              "/%" PRIu64 "/%" PRIu64 "/%" PRIu64 "/%" PRIu64
              "/%" PRIu64 "\n",
              bridge, kStageNames[stage], kOperationClassNames[operation],
              value.eligible_started, value.completed, value.right_censored,
              value.cancelled, value.left_censored, value.left_completed,
              value.left_right_censored, value.observed_cycles,
              value.completed_cycles, value.rob_head_cycles,
              value.peer_overlap_cycles, value.bins[0], value.bins[1],
              value.bins[2], value.bins[3], value.bins[4], value.bins[5],
              value.bins[6], value.bins[7], value.bins[8]);
        }
      }
    }
    std::fflush(stdout);
  }

 private:
  using StageAggregates =
      std::array<std::array<Aggregate, kOperationClassCount>, kStageCount>;
  using StageTrackers = std::array<Tracker, kStageCount>;

  void bump(uint64_t &value) {
    if (value == std::numeric_limits<uint64_t>::max()) {
      overflow_ = true;
      return;
    }
    ++value;
  }

  void add(uint64_t &value, uint64_t increment) {
    if (std::numeric_limits<uint64_t>::max() - value < increment) {
      value = std::numeric_limits<uint64_t>::max();
      overflow_ = true;
      return;
    }
    value += increment;
  }

  void bump_invalid(InvalidReason reason) {
    bump(invalid_events_);
    bump(invalid_reason_counts_[static_cast<uint32_t>(reason)]);
  }

  bool invalid_reason_conservation() const {
    unsigned __int128 sum = 0;
    for (uint32_t reason = 0; reason < kInvalidReasonCount; ++reason) {
      sum += invalid_reason_counts_[reason];
    }
    return sum == invalid_events_;
  }

  void print_invalid_breakdown() const {
    for (uint32_t reason = 0; reason < kInvalidReasonCount; ++reason) {
      std::printf(" invalid_%s=%" PRIu64, kInvalidReasonNames[reason],
                  invalid_reason_counts_[reason]);
    }
  }

  Aggregate &aggregate_for(uint32_t bridge, Stage stage,
                           OperationClass operation) {
    return aggregates_[bridge][static_cast<uint32_t>(stage)]
                      [static_cast<uint32_t>(operation)];
  }

  bool owner_is_head(const OwnerIdentity &owner, const bool head_valid[2],
                     const uint32_t head_token[2]) const {
    return (head_valid[0] && owner.token == head_token[0]) ||
           (head_valid[1] && owner.token == head_token[1]);
  }

  bool peer_is_independent(const BridgeSample &sample,
                           const BridgeSample &peer) const {
    return sample.active_valid() && peer.active_valid() &&
           sample.active != peer.active;
  }

  void validate_sample(const BridgeSample &sample) {
    if (sample.state >= kLegalStateCount)
      bump_invalid(InvalidReason::IllegalState);
    if (sample.active_valid() && sample.active.kind == 3)
      bump_invalid(InvalidReason::ActiveKind);
    if (sample.station_valid && sample.station.kind == 3)
      bump_invalid(InvalidReason::StationKind);
    if (sample.request_valid && sample.request.kind == 3)
      bump_invalid(InvalidReason::RequestKind);
    if (sample.request_fire && !sample.request_valid)
      bump_invalid(InvalidReason::RequestFireWithoutValid);
    if (sample.stage_advance && !sample.station_valid)
      bump_invalid(InvalidReason::StageAdvanceWithoutStation);
    if (sample.station_cancel && !sample.station_valid)
      bump_invalid(InvalidReason::StationCancelWithoutStation);
    if (sample.active_drop && !sample.active_valid())
      bump_invalid(InvalidReason::ActiveDropWithoutActive);
  }

  void start_tracker(uint32_t bridge, Stage stage, const OwnerIdentity &owner,
                     OperationClass operation, bool eligible) {
    Tracker &tracker = trackers_[bridge][static_cast<uint32_t>(stage)];
    tracker.active = true;
    tracker.eligible = eligible;
    tracker.owner = owner;
    tracker.operation = operation;
    tracker.duration = 0;
    Aggregate &value = aggregate_for(bridge, stage, operation);
    if (eligible) {
      bump(value.eligible_started);
    } else {
      bump(value.left_censored);
    }
  }

  void add_tracker_cycle(uint32_t bridge, Stage stage, bool at_head,
                         bool peer_overlap) {
    Tracker &tracker = trackers_[bridge][static_cast<uint32_t>(stage)];
    if (!tracker.active) return;
    bump(tracker.duration);
    Aggregate &value = aggregate_for(bridge, stage, tracker.operation);
    bump(value.observed_cycles);
    if (at_head) bump(value.rob_head_cycles);
    if (peer_overlap) bump(value.peer_overlap_cycles);
  }

  void close_tracker(uint32_t bridge, Stage stage, bool cancelled) {
    Tracker &tracker = trackers_[bridge][static_cast<uint32_t>(stage)];
    if (!tracker.active) return;
    Aggregate &value = aggregate_for(bridge, stage, tracker.operation);
    if (tracker.eligible) {
      if (cancelled) {
        bump(value.cancelled);
      } else {
        bump(value.completed);
        add(value.completed_cycles, tracker.duration);
        bump(value.bins[duration_bin(tracker.duration)]);
      }
    } else {
      bump(value.left_completed);
    }
    tracker = Tracker();
  }

  void update_stage(uint32_t bridge, Stage stage, bool active,
                    const OwnerIdentity &owner, OperationClass operation,
                    bool at_head, bool peer_overlap, bool terminal_now,
                    bool cancelled_now = false,
                    bool zero_duration_on_start = false) {
    Tracker &tracker = trackers_[bridge][static_cast<uint32_t>(stage)];
    if (!active) {
      close_tracker(bridge, stage, false);
      return;
    }
    if (tracker.active &&
        (tracker.owner != owner || tracker.operation != operation)) {
      bump_invalid(InvalidReason::StageIdentityChange);
      close_tracker(bridge, stage, false);
    }
    if (!tracker.active) {
      start_tracker(bridge, stage, owner, operation, true);
      if (zero_duration_on_start && terminal_now && !cancelled_now) {
        close_tracker(bridge, stage, false);
        return;
      }
    }
    add_tracker_cycle(bridge, stage, at_head, peer_overlap);
    if (terminal_now || cancelled_now)
      close_tracker(bridge, stage, cancelled_now);
  }

  void prime_stage(uint32_t bridge, Stage stage, bool active,
                   const OwnerIdentity &owner, OperationClass operation) {
    if (!active) return;
    start_tracker(bridge, stage, owner, operation, false);
  }

  void update_admission(uint32_t bridge, const BridgeSample &sample,
                        bool at_head, bool peer_overlap) {
    const Stage stage = Stage::AdmissionWait;
    Tracker &tracker = trackers_[bridge][static_cast<uint32_t>(stage)];
    const OperationClass operation = operation_class(sample.request, 0);
    if (sample.request_fire) {
      if (tracker.active && tracker.owner != sample.request) {
        bump_invalid(InvalidReason::AdmissionIdentityChange);
        close_tracker(bridge, stage, true);
      }
      if (tracker.active) {
        close_tracker(bridge, stage, false);
      } else {
        start_tracker(bridge, stage, sample.request, operation, true);
        close_tracker(bridge, stage, false);
      }
      return;
    }
    if (!sample.request_valid) {
      close_tracker(bridge, stage, true);
      return;
    }
    if (tracker.active && tracker.owner != sample.request) {
      bump_invalid(InvalidReason::AdmissionIdentityChange);
      close_tracker(bridge, stage, true);
    }
    if (!tracker.active) {
      start_tracker(bridge, stage, sample.request, operation, true);
    }
    add_tracker_cycle(bridge, stage, at_head, peer_overlap);
  }

  void prime_boundary(const BridgeSample samples[kBridgeCount]) {
    for (uint32_t bridge = 0; bridge < kBridgeCount; ++bridge) {
      const BridgeSample &sample = samples[bridge];
      if (sample.request_valid && !sample.request_fire) {
        prime_stage(bridge, Stage::AdmissionWait, true, sample.request,
                    operation_class(sample.request, 0));
      }
      prime_stage(bridge, Stage::Reservation, sample.station_valid,
                  sample.station, operation_class(sample.station, 0));
      prime_stage(bridge, Stage::Translation,
                  translation_state(sample.state), sample.active,
                  operation_class(sample.active, sample.state));
      prime_stage(bridge, Stage::WriteRequest, sample.state == 5,
                  sample.active, operation_class(sample.active, sample.state));
      prime_stage(bridge, Stage::WriteResponse, sample.state == 6,
                  sample.active, operation_class(sample.active, sample.state));
      prime_stage(bridge, Stage::AwWToB,
                  sample.state == 6 ||
                      (sample.state == 8 && sample.aw_complete &&
                       sample.w_complete),
                  sample.active, operation_class(sample.active, sample.state));
      prime_stage(bridge, Stage::SqQuery, sample.state == 12, sample.active,
                  operation_class(sample.active, sample.state));
    }
  }

  void observe_bridge(uint32_t bridge, const BridgeSample &sample,
                      const BridgeSample &peer, const bool head_valid[2],
                      const uint32_t head_token[2]) {
    validate_sample(sample);
    const bool active_head = owner_is_head(sample.active, head_valid, head_token);
    const bool station_head =
        owner_is_head(sample.station, head_valid, head_token);
    const bool request_head =
        owner_is_head(sample.request, head_valid, head_token);
    const bool peer_overlap = peer_is_independent(sample, peer);

    if (sample.request_fire) {
      bump(request_fire_[bridge][static_cast<uint32_t>(
          operation_class(sample.request, 0))]);
    }
    if (sample.bvalid && (sample.state == 6 || sample.state == 8)) {
      bump(b_terminal_[bridge][static_cast<uint32_t>(
          operation_class(sample.active, sample.state))]);
    }

    update_admission(bridge, sample, request_head,
                     sample.request_valid && peer.active_valid() &&
                         sample.request != peer.active);
    update_stage(bridge, Stage::Reservation, sample.station_valid,
                 sample.station, operation_class(sample.station, 0),
                 station_head,
                 sample.station_valid && peer.active_valid() &&
                     sample.station != peer.active,
                 sample.stage_advance, sample.station_cancel);
    update_stage(bridge, Stage::Translation,
                 translation_state(sample.state), sample.active,
                 operation_class(sample.active, sample.state), active_head,
                 peer_overlap,
                 sample.response_fire ||
                     (sample.state == 8 && sample.bvalid),
                 sample.active_drop);
    update_stage(bridge, Stage::WriteRequest, sample.state == 5,
                 sample.active, operation_class(sample.active, sample.state),
                 active_head, peer_overlap,
                 sample.response_fire ||
                     (sample.aw_complete && sample.w_complete),
                 sample.active_drop);
    update_stage(bridge, Stage::WriteResponse, sample.state == 6,
                 sample.active, operation_class(sample.active, sample.state),
                 active_head, peer_overlap,
                 sample.response_fire || sample.bvalid, sample.active_drop);
    update_stage(bridge, Stage::AwWToB,
                 sample.state == 6 ||
                     (sample.state == 8 && sample.aw_complete &&
                      sample.w_complete),
                 sample.active, operation_class(sample.active, sample.state),
                 active_head, peer_overlap,
                 sample.response_fire || sample.bvalid, sample.active_drop,
                 sample.state == 8);
    update_stage(bridge, Stage::SqQuery, sample.state == 12, sample.active,
                 operation_class(sample.active, sample.state), active_head,
                 peer_overlap, sample.response_fire, sample.active_drop);
  }

  void observe_cycle(const BridgeSample samples[kBridgeCount],
                     const bool head_valid[2],
                     const uint32_t head_token[2]) {
    bump(roi_cycles_);
    uint32_t write_inflight = 0;
    for (uint32_t bridge = 0; bridge < kBridgeCount; ++bridge) {
      bump(state_cycles_[bridge][samples[bridge].state]);
      if (write_inflight_state(samples[bridge].state)) ++write_inflight;
    }
    if (write_inflight > 2) {
      bump_invalid(InvalidReason::WriteOccupancy);
      write_inflight = 2;
    }
    bump(write_inflight_occupancy_[write_inflight]);
    observe_bridge(0, samples[0], samples[1], head_valid, head_token);
    observe_bridge(1, samples[1], samples[0], head_valid, head_token);
  }

  void observe_commit(uint32_t lane, uint64_t pc,
                      const BridgeSample samples[kBridgeCount]) {
    if (pc == start_pc_) {
      bump(start_hits_);
      if (!start_seen_) {
        if (end_seen_) bump_invalid(InvalidReason::BoundaryOrder);
        start_seen_ = true;
        start_lane_ = lane;
        prime_boundary(samples);
      }
    }
    if (pc == end_pc_) {
      bump(end_hits_);
      if (!start_seen_) {
        bump_invalid(InvalidReason::BoundaryOrder);
      } else if (!end_seen_) {
        end_seen_ = true;
        end_lane_ = lane;
        finalize_intervals();
      }
    }
  }

  void finalize_intervals() {
    if (intervals_finalized_) return;
    intervals_finalized_ = true;
    for (uint32_t bridge = 0; bridge < kBridgeCount; ++bridge) {
      for (uint32_t stage = 0; stage < kStageCount; ++stage) {
        Tracker &tracker = trackers_[bridge][stage];
        if (!tracker.active) continue;
        Aggregate &value = aggregates_[bridge][stage]
                                    [static_cast<uint32_t>(tracker.operation)];
        if (tracker.eligible) {
          bump(value.right_censored);
        } else {
          bump(value.left_right_censored);
        }
        tracker = Tracker();
      }
    }
  }

  bool state_conservation() const {
    if (!start_seen_) return false;
    for (uint32_t bridge = 0; bridge < kBridgeCount; ++bridge) {
      unsigned __int128 sum = 0;
      for (uint32_t state = 0; state < kEncodedStateCount; ++state) {
        sum += state_cycles_[bridge][state];
      }
      if (sum != roi_cycles_) return false;
    }
    unsigned __int128 occupancy = 0;
    for (uint32_t count = 0; count < 3; ++count) {
      occupancy += write_inflight_occupancy_[count];
    }
    return occupancy == roi_cycles_;
  }

  bool interval_conservation() const {
    for (uint32_t bridge = 0; bridge < kBridgeCount; ++bridge) {
      for (uint32_t stage = 0; stage < kStageCount; ++stage) {
        for (uint32_t operation = 0; operation < kOperationClassCount;
             ++operation) {
          const Aggregate &value = aggregates_[bridge][stage][operation];
          const unsigned __int128 eligible_closed =
              static_cast<unsigned __int128>(value.completed) +
              value.right_censored + value.cancelled;
          const unsigned __int128 left_closed =
              static_cast<unsigned __int128>(value.left_completed) +
              value.left_right_censored;
          unsigned __int128 bins = 0;
          for (uint32_t index = 0; index < kHistogramBinCount; ++index) {
            bins += value.bins[index];
          }
          if (eligible_closed != value.eligible_started ||
              left_closed != value.left_censored || bins != value.completed) {
            return false;
          }
        }
      }
    }
    return true;
  }

  bool configured_ = false;
  bool enabled_ = false;
  bool start_seen_ = false;
  bool end_seen_ = false;
  bool intervals_finalized_ = false;
  bool reported_ = false;
  bool overflow_ = false;
  uint64_t start_pc_ = 0;
  uint64_t end_pc_ = 0;
  uint64_t start_hits_ = 0;
  uint64_t end_hits_ = 0;
  uint32_t start_lane_ = 0;
  uint32_t end_lane_ = 0;
  uint64_t roi_cycles_ = 0;
  uint64_t invalid_events_ = 0;
  uint64_t invalid_reason_counts_[kInvalidReasonCount] = {};
  std::array<StageAggregates, kBridgeCount> aggregates_{};
  std::array<StageTrackers, kBridgeCount> trackers_{};
  uint64_t state_cycles_[kBridgeCount][kEncodedStateCount] = {};
  uint64_t write_inflight_occupancy_[3] = {};
  uint64_t request_fire_[kBridgeCount][kOperationClassCount] = {};
  uint64_t b_terminal_[kBridgeCount][kOperationClassCount] = {};
};

}  // namespace owner_timing

#ifndef NPC_OWNER_TIMING_UNIT_TEST
static owner_timing::Collector g_owner_timing_collector;
static bool g_owner_timing_atexit_registered = false;

static void report_owner_timing_at_exit() {
  g_owner_timing_collector.report();
}

extern "C" void npc_ooo_owner_timing_event(
    uint32_t reset, uint32_t commit0_valid, uint64_t commit0_pc,
    uint32_t commit1_valid, uint64_t commit1_pc, uint32_t head0_valid,
    uint32_t head0_token, uint32_t head1_valid, uint32_t head1_token,
    uint64_t bridge0_sample, uint64_t bridge1_sample) {
  if (!g_owner_timing_atexit_registered) {
    std::atexit(report_owner_timing_at_exit);
    g_owner_timing_atexit_registered = true;
  }
  g_owner_timing_collector.event(
      reset != 0, commit0_valid != 0, commit0_pc, commit1_valid != 0,
      commit1_pc, head0_valid != 0, head0_token, head1_valid != 0,
      head1_token, bridge0_sample, bridge1_sample);
}
#else

using owner_timing::Collector;
using owner_timing::InvalidReason;
using owner_timing::OperationClass;
using owner_timing::Stage;

static uint64_t sample(uint32_t state, uint32_t active_kind,
                       uint32_t active_token, uint32_t active_epoch,
                       bool station_valid = false, uint32_t station_kind = 0,
                       uint32_t station_token = 0, uint32_t station_epoch = 0,
                       bool request_valid = false, bool request_fire = false,
                       uint32_t request_kind = 0, uint32_t request_token = 0,
                       uint32_t request_epoch = 0, bool aw_complete = false,
                       bool w_complete = false, bool bvalid = false,
                       bool stage_advance = false,
                       bool station_cancel = false,
                       bool active_drop = false,
                       bool response_fire = false) {
  uint64_t value = 0;
  value |= static_cast<uint64_t>(state & 15u);
  value |= static_cast<uint64_t>(active_kind & 3u) << 4;
  value |= static_cast<uint64_t>(active_token & 31u) << 6;
  value |= static_cast<uint64_t>(active_epoch & 3u) << 11;
  value |= static_cast<uint64_t>(station_valid) << 13;
  value |= static_cast<uint64_t>(station_kind & 3u) << 14;
  value |= static_cast<uint64_t>(station_token & 31u) << 16;
  value |= static_cast<uint64_t>(station_epoch & 3u) << 21;
  value |= static_cast<uint64_t>(request_valid) << 23;
  value |= static_cast<uint64_t>(request_fire) << 24;
  value |= static_cast<uint64_t>(request_kind & 3u) << 25;
  value |= static_cast<uint64_t>(request_token & 31u) << 27;
  value |= static_cast<uint64_t>(request_epoch & 3u) << 32;
  value |= static_cast<uint64_t>(aw_complete) << 34;
  value |= static_cast<uint64_t>(w_complete) << 35;
  value |= static_cast<uint64_t>(bvalid) << 36;
  value |= static_cast<uint64_t>(stage_advance) << 37;
  value |= static_cast<uint64_t>(station_cancel) << 38;
  value |= static_cast<uint64_t>(active_drop) << 39;
  value |= static_cast<uint64_t>(response_fire) << 40;
  return value;
}

static void push(Collector &collector, uint64_t bridge0, uint64_t bridge1,
                 bool commit0 = false, uint64_t pc0 = 0,
                 bool commit1 = false, uint64_t pc1 = 0,
                 bool head0 = false, uint32_t head0_token = 0,
                 bool head1 = false, uint32_t head1_token = 0) {
  collector.event(false, commit0, pc0, commit1, pc1, head0, head0_token,
                  head1, head1_token, bridge0, bridge1);
}

static bool expect(bool condition, const char *message) {
  if (condition) return true;
  std::fprintf(stderr, "[OWNER-TIMING-UNIT][FAIL] %s\n", message);
  return false;
}

static bool test_complete_store_path() {
  Collector collector;
  collector.configure(0x100, 0x200);
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0), true, 0x100);
  push(collector,
       sample(0, 0, 0, 0, false, 0, 0, 0, true, true, 1, 7, 0),
       sample(0, 0, 0, 0));
  push(collector, sample(0, 0, 0, 0, true, 1, 7, 0),
       sample(0, 0, 0, 0));
  push(collector, sample(0, 0, 0, 0, true, 1, 7, 0, false, false,
                         0, 0, 0, false, false, false, true),
       sample(0, 0, 0, 0));
  push(collector, sample(5, 1, 7, 0), sample(0, 0, 0, 0));
  push(collector, sample(5, 1, 7, 0, false, 0, 0, 0, false, false,
                         0, 0, 0, true, true),
       sample(0, 0, 0, 0));
  push(collector, sample(6, 1, 7, 0), sample(0, 0, 0, 0));
  push(collector, sample(6, 1, 7, 0, false, 0, 0, 0, false, false,
                         0, 0, 0, true, true, true),
       sample(0, 0, 0, 0), true, 0x200);
  const auto &admission = collector.aggregate(
      0, Stage::AdmissionWait, OperationClass::Store);
  const auto &reservation = collector.aggregate(
      0, Stage::Reservation, OperationClass::Store);
  const auto &write_request = collector.aggregate(
      0, Stage::WriteRequest, OperationClass::Store);
  const auto &write_response = collector.aggregate(
      0, Stage::WriteResponse, OperationClass::Store);
  const auto &aw_to_b = collector.aggregate(
      0, Stage::AwWToB, OperationClass::Store);
  return expect(collector.complete(), "complete store path must qualify") &&
         expect(collector.roi_cycles() == 7, "ROI must contain S+1..E") &&
         expect(admission.completed == 1 && admission.bins[0] == 1,
                "immediate admission must enter zero-cycle bin") &&
         expect(reservation.completed == 1 && reservation.bins[2] == 1,
                "two-cycle reservation interval missing") &&
         expect(write_request.completed == 1 && write_request.bins[2] == 1,
                "two-cycle write-request interval missing") &&
         expect(write_response.completed == 1 && write_response.bins[2] == 1,
                "two-cycle write-response interval missing") &&
         expect(aw_to_b.completed == 1 && aw_to_b.bins[2] == 1,
                "two-cycle AW/W-to-B interval missing");
}

static bool test_boundary_censoring() {
  Collector left;
  left.configure(0x100, 0x200);
  push(left, sample(5, 1, 3, 0), sample(0, 0, 0, 0), true, 0x100);
  push(left, sample(5, 1, 3, 0), sample(0, 0, 0, 0));
  push(left, sample(5, 1, 3, 0), sample(0, 0, 0, 0), true, 0x200);
  const auto &left_value = left.aggregate(
      0, Stage::WriteRequest, OperationClass::Store);

  Collector right;
  right.configure(0x100, 0x200);
  push(right, sample(0, 0, 0, 0), sample(0, 0, 0, 0), true, 0x100);
  push(right, sample(5, 1, 4, 0), sample(0, 0, 0, 0));
  push(right, sample(5, 1, 4, 0), sample(0, 0, 0, 0), true, 0x200);
  const auto &right_value = right.aggregate(
      0, Stage::WriteRequest, OperationClass::Store);
  return expect(left.complete(), "left-censored region must remain complete") &&
         expect(left_value.left_censored == 1 &&
                    left_value.left_right_censored == 1 &&
                    left_value.completed == 0,
                "left/right double censor was not preserved") &&
         expect(right.complete(), "right-censored region must remain complete") &&
         expect(right_value.eligible_started == 1 &&
                    right_value.right_censored == 1 &&
                    right_value.completed == 0,
                "right censor was not excluded from histogram");
}

static bool test_owner_aba_is_invalid() {
  Collector collector;
  collector.configure(0x100, 0x200);
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0), true, 0x100);
  push(collector, sample(5, 1, 1, 0), sample(0, 0, 0, 0));
  push(collector, sample(5, 1, 2, 0), sample(0, 0, 0, 0), true, 0x200);
  return expect(!collector.complete(), "owner change without boundary must fail") &&
         expect(collector.invalid_events() != 0,
                "owner change must increment invalid_events");
}

static bool test_admission_payload_change_is_invalid() {
  Collector collector;
  collector.configure(0x100, 0x200);
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0), true, 0x100);
  push(collector,
       sample(0, 0, 0, 0, false, 0, 0, 0, true, false, 0, 1, 0),
       sample(0, 0, 0, 0));
  push(collector,
       sample(0, 0, 0, 0, false, 0, 0, 0, true, true, 0, 2, 0),
       sample(0, 0, 0, 0));
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0), true, 0x200);
  const auto &admission = collector.aggregate(
      0, Stage::AdmissionWait, OperationClass::Load);
  return expect(!collector.complete(),
                "admission payload change while waiting must fail") &&
         expect(collector.invalid_events() == 1,
                "admission payload change must be one invalid event") &&
         expect(collector.invalid_reason(
                    InvalidReason::AdmissionIdentityChange) == 1,
                "admission identity reason bucket missing") &&
         expect(admission.cancelled == 1 && admission.completed == 1,
                "old admission must cancel and fired owner must complete");
}

static bool test_station_flush_is_cancelled() {
  Collector collector;
  collector.configure(0x100, 0x200);
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0), true, 0x100);
  push(collector, sample(0, 0, 0, 0, true, 1, 11, 2),
       sample(0, 0, 0, 0));
  push(collector,
       sample(0, 0, 0, 0, true, 1, 11, 2, false, false, 0, 0, 0,
              false, false, false, false, true),
       sample(0, 0, 0, 0));
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0), true, 0x200);
  const auto &reservation = collector.aggregate(
      0, Stage::Reservation, OperationClass::Store);
  return expect(collector.complete(), "station cancellation must conserve") &&
         expect(reservation.eligible_started == 1 &&
                    reservation.cancelled == 1 &&
                    reservation.completed == 0,
                "station flush must not be reported as normal completion");
}

static bool test_active_drop_is_cancelled() {
  Collector collector;
  collector.configure(0x100, 0x200);
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0), true, 0x100);
  push(collector, sample(6, 1, 12, 1), sample(0, 0, 0, 0));
  push(collector,
       sample(6, 1, 12, 1, false, 0, 0, 0, false, false, 0, 0, 0,
              false, false, false, false, false, true),
       sample(0, 0, 0, 0));
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0), true, 0x200);
  const auto &write_response = collector.aggregate(
      0, Stage::WriteResponse, OperationClass::Store);
  return expect(collector.complete(), "active drop must conserve") &&
         expect(write_response.eligible_started == 1 &&
                    write_response.cancelled == 1 &&
                    write_response.completed == 0,
                "active drop must not enter the completion histogram");
}

static bool test_illegal_state_is_rejected() {
  Collector collector;
  collector.configure(0x100, 0x200);
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0), true, 0x100);
  push(collector, sample(13, 0, 3, 0), sample(0, 0, 0, 0));
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0), true, 0x200);
  return expect(!collector.complete(), "encoded S13 must fail qualification") &&
         expect(collector.invalid_events() == 1,
                "encoded S13 must increment invalid_events");
}

static bool test_dual_bridge_overlap() {
  Collector collector;
  collector.configure(0x100, 0x200);
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0), true, 0x100);
  push(collector, sample(6, 1, 5, 0), sample(3, 0, 6, 0));
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0), true, 0x200);
  const auto &value = collector.aggregate(
      0, Stage::WriteResponse, OperationClass::Store);
  return expect(collector.complete(), "dual-bridge overlap region must qualify") &&
         expect(value.peer_overlap_cycles == 1,
                "independent peer overlap cycle missing") &&
         expect(collector.write_occupancy(1) == 1,
                "single write-inflight occupancy missing");
}

static bool test_same_cycle_region_is_unqualified() {
  Collector collector;
  collector.configure(0x100, 0x200);
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0), true, 0x100,
       true, 0x200);
  return expect(!collector.complete(), "zero-cycle lane pair must not qualify") &&
         expect(collector.roi_cycles() == 0,
                "same-cycle lane pair must have zero full-cycle samples");
}

static bool test_ad_update_channel() {
  Collector collector;
  collector.configure(0x100, 0x200);
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0), true, 0x100);
  push(collector, sample(8, 0, 9, 1, false, 0, 0, 0, false, false,
                         0, 0, 0, true, true, true),
       sample(0, 0, 0, 0));
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0), true, 0x200);
  const auto &translation = collector.aggregate(
      0, Stage::Translation, OperationClass::AdUpdate);
  const auto &aw_to_b = collector.aggregate(
      0, Stage::AwWToB, OperationClass::AdUpdate);
  return expect(collector.complete(), "A/D timing region must qualify") &&
         expect(translation.completed == 1 && translation.bins[1] == 1,
                "A/D translation interval missing") &&
         expect(aw_to_b.completed == 1 && aw_to_b.bins[0] == 1 &&
                    aw_to_b.completed_cycles == 0,
                "same-edge A/D AW/W-to-B must enter the zero-cycle bin");
}

static bool test_repeated_boundary_hits_use_first_pair() {
  Collector collector;
  collector.configure(0x100, 0x200);
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0), true, 0x100);
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0));
  // Dhrystone 的循环入口会反复退休同一 start PC；ROI 仍由首次 start/end 界定。
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0), true, 0x100);
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0));
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0), true, 0x200);
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0), true, 0x200);
  return expect(collector.complete(),
                "repeated boundary hits must preserve the first ROI") &&
         expect(collector.roi_cycles() == 4,
                "repeated start must remain an ordinary in-ROI cycle") &&
         expect(collector.start_hits() == 2 && collector.end_hits() == 2,
                "boundary hit counters must retain every observed match") &&
         expect(collector.invalid_events() == 0,
                "legal repeated boundary PCs must not create invalid events");
}

static bool test_distinct_b_terminals_are_not_deduplicated() {
  Collector collector;
  collector.configure(0x100, 0x200);
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0), true, 0x100);
  push(collector, sample(6, 1, 3, 0, false, 0, 0, 0, false, false,
                         0, 0, 0, true, true, true),
       sample(0, 0, 0, 0));
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0));
  push(collector, sample(6, 1, 4, 0, false, 0, 0, 0, false, false,
                         0, 0, 0, true, true, true),
       sample(0, 0, 0, 0));
  push(collector, sample(0, 0, 0, 0), sample(0, 0, 0, 0), true, 0x200);
  const auto &write_response = collector.aggregate(
      0, Stage::WriteResponse, OperationClass::Store);
  return expect(collector.complete(), "two B terminals must conserve") &&
         expect(collector.b_terminal(0, OperationClass::Store) == 2,
                "two distinct B terminals must both remain observable") &&
         expect(write_response.completed == 2,
                "two B terminals must close two response intervals");
}

int main() {
  const bool passed = test_complete_store_path() &&
                      test_boundary_censoring() &&
                      test_owner_aba_is_invalid() &&
                      test_admission_payload_change_is_invalid() &&
                      test_station_flush_is_cancelled() &&
                      test_active_drop_is_cancelled() &&
                      test_illegal_state_is_rejected() &&
                      test_dual_bridge_overlap() &&
                      test_same_cycle_region_is_unqualified() &&
                      test_ad_update_channel() &&
                      test_repeated_boundary_hits_use_first_pair() &&
                      test_distinct_b_terminals_are_not_deduplicated();
  if (!passed) return 1;
  std::printf("[OWNER-TIMING-UNIT][PASS] cases=12\n");
  return 0;
}
#endif
