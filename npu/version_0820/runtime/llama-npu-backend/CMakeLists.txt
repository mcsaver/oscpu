cmake_minimum_required(VERSION 3.20)
project(ggml_npu_backend LANGUAGES CXX)

include(ProcessorCount)
find_package(Threads REQUIRED)
find_package(Python3 COMPONENTS Interpreter REQUIRED)

get_filename_component(NPU_PROJECT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)
get_filename_component(NPU_WORKBENCH_ROOT "${NPU_PROJECT_ROOT}/../.." ABSOLUTE)
set(NPU_NPC_RTL_ROOT "${NPU_WORKBENCH_ROOT}/npc/rv64/vsrc")
set(LLAMA_SOURCE_DIR "${NPU_PROJECT_ROOT}/third_party/llama.cpp" CACHE PATH "Pinned llama.cpp source")
set(LLAMA_BUILD_BIN "${NPU_PROJECT_ROOT}/tmp/build/llama.cpp/bin" CACHE PATH "Pinned llama.cpp libraries")
set(NPU_VERILATED_MDIR "${NPU_PROJECT_ROOT}/tmp/build/npu-backend-verilated"
    CACHE PATH "Verilator generated model directory")
set(NPU_SYSTEM_VERILATED_MDIR
    "${NPU_PROJECT_ROOT}/tmp/build/npu-backend-system-verilated"
    CACHE PATH "Verilator generated RV64 SystemTop model directory")

if(NOT EXISTS "${LLAMA_SOURCE_DIR}/ggml/src/ggml-backend-impl.h")
    message(FATAL_ERROR "Pinned ggml internal headers are missing: ${LLAMA_SOURCE_DIR}")
endif()
if(NOT EXISTS "${LLAMA_BUILD_BIN}/libggml-base.so")
    message(FATAL_ERROR "Build llama.cpp first; libggml-base.so is missing")
endif()

find_program(VERILATOR_EXECUTABLE NAMES verilator REQUIRED)
find_program(NPU_MAKE_EXECUTABLE NAMES gmake make REQUIRED)
execute_process(
    COMMAND "${VERILATOR_EXECUTABLE}" --getenv VERILATOR_ROOT
    OUTPUT_VARIABLE VERILATOR_ROOT
    OUTPUT_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE VERILATOR_ROOT_STATUS
)
if(NOT VERILATOR_ROOT_STATUS EQUAL 0 OR
   NOT EXISTS "${VERILATOR_ROOT}/include/verilated.cpp")
    message(FATAL_ERROR "Unable to locate the Verilator runtime")
endif()

ProcessorCount(NPU_HOST_PROCESSORS)
if(NOT NPU_HOST_PROCESSORS OR NPU_HOST_PROCESSORS EQUAL 0)
    set(NPU_HOST_PROCESSORS 1)
endif()
set(NPU_VERILATOR_JOBS "${NPU_HOST_PROCESSORS}" CACHE STRING
    "Parallel jobs used to build the Verilated model")

set(NPU_RTL_SOURCES
    # Frozen fpu-sp production subset and complete lzc_4 -> lzc_128 chain.
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/float/fp_wire.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_4.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_8.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_16.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_32.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_64.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_128.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/float/fp_ext.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/float/fp_fma.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/float/fp_fdiv.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/float/fp_rnd.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/float/fp_cvt.sv"
    # Ordered HardFloat closure used by the exact unary/norm/batch2 owners.
    "${NPU_PROJECT_ROOT}/third_party/hardfloat/source/RISCV/HardFloat_specialize.v"
    "${NPU_PROJECT_ROOT}/third_party/hardfloat/source/HardFloat_primitives.v"
    "${NPU_PROJECT_ROOT}/third_party/hardfloat/source/HardFloat_rawFN.v"
    "${NPU_PROJECT_ROOT}/third_party/hardfloat/source/isSigNaNRecFN.v"
    "${NPU_PROJECT_ROOT}/third_party/hardfloat/source/fNToRecFN.v"
    "${NPU_PROJECT_ROOT}/third_party/hardfloat/source/recFNToFN.v"
    "${NPU_PROJECT_ROOT}/third_party/hardfloat/source/recFNToRecFN.v"
    "${NPU_PROJECT_ROOT}/third_party/hardfloat/source/recFNToIN.v"
    "${NPU_PROJECT_ROOT}/third_party/hardfloat/source/iNToRecFN.v"
    "${NPU_PROJECT_ROOT}/third_party/hardfloat/source/mulAddRecFN.v"
    "${NPU_PROJECT_ROOT}/third_party/hardfloat/source/addRecFN.v"
    # Keep every public production kernel dependency before the Coprocessor.
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuFp16ToFp32.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuInt32ToFp32.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuFp32AddMul.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuFp32Div.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuFp32ToFp16.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuFp32ToInt32Rmm.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuQ8DequantBlock.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuQ8GetRowsEngine.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuQ8GetRowsWritebackAdapter.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuQ8DotEngine.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuQ8ScaleAccumulator.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuQ8ReferenceQuantizer.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuQ8StreamGemv.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuQ8GemvWritebackAdapter.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuF32GatherRepeatAdapter.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuF32TensorAlu.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuVectorF32Adapter.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuF32AluSimdCore.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuF32AluPortalAdapter.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuF32GatherRepeatPortalAdapter.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuFp32ToFp64.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuFp64Fma.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuFp64ToInt32Rmm.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuInt32ToFp64.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuFp64ToFp32Finite.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuAorExp32.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuAorLog32.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuUnaryGluElement.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuUnaryGluWritebackAdapter.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuFp32Sqrt.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuFp64Add.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuFp64ToFp32.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuFp32SquareSum64.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuFp64Pow2Scale.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuNormEngine.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuNormWritebackAdapter.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuFp32ToFp64Ieee.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuFp64AddIeee.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuFp64ToFp32Ieee.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuOrderedSumRows.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuSumRowsWritebackAdapter.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuSsmConvWritebackAdapter.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuTensorMover.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuSetRowsEngine.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuMoverSetRowsWritebackAdapter.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuFp32Fma.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuF16AttentionMatmulWritebackAdapter.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuSoftmaxWritebackAdapter.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuFp32SincosCordic.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuRopeWritebackAdapter.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuF32ArgmaxWritebackAdapter.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuCoprocessor.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuCommandDecoder.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuRegisterFile.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuMm2Engine.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuDmaEngine.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuLocalMemory.v"
    "${NPU_PROJECT_ROOT}/rtl/tensor_npu_defs.vh"
)
set(NPU_VERILATED_ARCHIVE
    "${NPU_VERILATED_MDIR}/VTensorNpuCoprocessor__ALL.a")
set(NPU_VERILATED_HEADER
    "${NPU_VERILATED_MDIR}/VTensorNpuCoprocessor.h")

add_custom_command(
    OUTPUT "${NPU_VERILATED_ARCHIVE}"
    BYPRODUCTS "${NPU_VERILATED_HEADER}"
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${NPU_VERILATED_MDIR}"
    COMMAND "${VERILATOR_EXECUTABLE}"
            --cc -O3 -Wall -Wno-fatal
            -Wno-UNOPTFLAT -Wno-IMPORTSTAR -Wno-UNUSEDPARAM
            -Wno-UNUSEDSIGNAL -Wno-GENUNNAMED -Wno-DECLFILENAME
            -Wno-TIMESCALEMOD -Wno-VARHIDDEN
            --no-assert --no-trace
            "-I${NPU_PROJECT_ROOT}/rtl"
            "-I${NPU_PROJECT_ROOT}/third_party/hardfloat/source/RISCV"
            "-I${NPU_PROJECT_ROOT}/third_party/hardfloat/source"
            --Mdir "${NPU_VERILATED_MDIR}"
            --top-module TensorNpuCoprocessor
            -CFLAGS "-O3 -DNDEBUG -march=native -fPIC"
            ${NPU_RTL_SOURCES}
    # CMake's generated make recipe does not preserve the parent jobserver
    # descriptors for this nested Verilator make.  Drop the stale jobserver
    # environment and use the explicitly bounded parallelism instead.
    COMMAND "${CMAKE_COMMAND}" -E env
            --unset=MAKEFLAGS
            --unset=MFLAGS
            "${NPU_MAKE_EXECUTABLE}"
            -C "${NPU_VERILATED_MDIR}"
            -f VTensorNpuCoprocessor.mk
            -j${NPU_VERILATOR_JOBS}
            VTensorNpuCoprocessor__ALL.a
    DEPENDS ${NPU_RTL_SOURCES}
    WORKING_DIRECTORY "${NPU_PROJECT_ROOT}"
    COMMENT "Generating O3/no-assert/no-trace TensorNpuCoprocessor model"
    VERBATIM
)
add_custom_target(npu-verilated-model DEPENDS "${NPU_VERILATED_ARCHIVE}")
set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_CLEAN_FILES
    "${NPU_VERILATED_MDIR}")

# Frozen production CPU closure from the final NpcTensorNpuSystemTop build.
# Keep this explicit: recursive globs also pull in alternate tops and checker
# variants which are not part of the verified RV64 transport configuration.
set(NPU_SYSTEM_FPU_RTL_SOURCES
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/float/fp_wire.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_32.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_128.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_64.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_4.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_16.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_8.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/float/fp_fma.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/float/fp_max.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/float/fp_exe.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/float/fp_rnd.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/float/fp_sgnj.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/float/fp_unit.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/float/fp_mac.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/float/fp_fdiv.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/float/fp_cmp.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/float/fp_cvt.sv"
    "${NPU_PROJECT_ROOT}/third_party/fpu-sp/verilog/src/float/fp_ext.sv"
)
set(NPU_NPC_RTL_SOURCES
    "${NPU_NPC_RTL_ROOT}/pipeline/PipeStageReg.v"
    "${NPU_NPC_RTL_ROOT}/writeback/OooWriteback.v"
    "${NPU_NPC_RTL_ROOT}/writeback/OooArchRegFile.v"
    "${NPU_NPC_RTL_ROOT}/writeback/OooRob.v"
    "${NPU_NPC_RTL_ROOT}/writeback/OooCommitOutputMux.v"
    "${NPU_NPC_RTL_ROOT}/writeback/WBU.v"
    "${NPU_NPC_RTL_ROOT}/writeback/OooControlCommitSequencer.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooBackendDrainTracker.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooBranchLocalPht.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooDirectBranchResolveGate.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooDirectControlFlowGate.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooFrontendActionGate.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooRasUpdateGate.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooDirectRasCandidateGate.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooFetchHeadClassifyGate.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooFrontendRunGate.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooFrontendUopSafety.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooBranchAppendDispatchGate.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooFetchAxiBridge.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooFetchBranchTarget.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooFetchPacketHeadMux.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooDirectBranchWaitBuffer.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooFetchHeadPairGate.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooBranchSpecTracker.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooFetchPacketDecode.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooFetchPcOutstandingSequencer.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooFetchStaticClassify.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooFetchFlowControl.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooFrontend.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooFrontendDispatchGate.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooFetchRequestMux.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooBranchBpuUpdateGate.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooFetchPacketSeedMux.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooRasStack.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooFrontendBackendDispatchMux.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooFetchPacketFifo.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooBranchResolveRecoveryGate.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooTensorPairOwner.v"
    "${NPU_NPC_RTL_ROOT}/frontend/OooBranchDirectionPredictor.v"
    "${NPU_NPC_RTL_ROOT}/memory/OooDualMemBridgeWrapper.v"
    "${NPU_NPC_RTL_ROOT}/memory/OooPmaChecker.v"
    "${NPU_NPC_RTL_ROOT}/memory/OooMemOwnerTerminalCollector.v"
    "${NPU_NPC_RTL_ROOT}/memory/OooMemAxiBridge.v"
    "${NPU_NPC_RTL_ROOT}/memory/OooPostTranslateMemoryClass.v"
    "${NPU_NPC_RTL_ROOT}/memory/OooDualMemAxiArbiter.v"
    "${NPU_NPC_RTL_ROOT}/memory/LSUDataPath.v"
    "${NPU_NPC_RTL_ROOT}/memory/OooTypedPmaChecker.v"
    "${NPU_NPC_RTL_ROOT}/memory/LSU.v"
    "${NPU_NPC_RTL_ROOT}/memory/OooStoreQueue.v"
    "${NPU_NPC_RTL_ROOT}/memory/OooTypedMemoryClassifier.v"
    "${NPU_NPC_RTL_ROOT}/memory/LSUControl.v"
    "${NPU_NPC_RTL_ROOT}/memory/OooMemInflightQueue.v"
    "${NPU_NPC_RTL_ROOT}/memory/OooMmuEpochOwner.v"
    "${NPU_NPC_RTL_ROOT}/memory/OooLoadQueue.v"
    "${NPU_NPC_RTL_ROOT}/memory/OooMemoryRequestGate.v"
    "${NPU_NPC_RTL_ROOT}/memory/OooMemoryAccess.v"
    "${NPU_NPC_RTL_ROOT}/memory/OooLsuAxiLaneAdapter.v"
    "${NPU_NPC_RTL_ROOT}/memory/OooMemOwnerTracker.v"
    "${NPU_NPC_RTL_ROOT}/memory/PmpChecker.v"
    "${NPU_NPC_RTL_ROOT}/memory/OooSv39Tlb.v"
    "${NPU_NPC_RTL_ROOT}/core/OooCoreTopGlue.v"
    "${NPU_NPC_RTL_ROOT}/core/NpcCoreTop.v"
    "${NPU_NPC_RTL_ROOT}/core/CsrFile.v"
    "${NPU_NPC_RTL_ROOT}/core/NpcTop.v"
    "${NPU_NPC_RTL_ROOT}/common/OooSlotFacts.v"
    "${NPU_NPC_RTL_ROOT}/scheduling/OooIntIssueSelect8.v"
    "${NPU_NPC_RTL_ROOT}/scheduling/OooIntIssueQueue.v"
    "${NPU_NPC_RTL_ROOT}/scheduling/OooFpIssueQueue.v"
    "${NPU_NPC_RTL_ROOT}/sim/NpcSimTop.sv"
    "${NPU_NPC_RTL_ROOT}/sim/AxiVirtioBlk.sv"
    "${NPU_NPC_RTL_ROOT}/sim/AxiDpiSlave.sv"
    "${NPU_NPC_RTL_ROOT}/debug/OooFetchPacketCacheChecker.sv"
    "${NPU_NPC_RTL_ROOT}/debug/OooDataWordCacheChecker.sv"
    "${NPU_NPC_RTL_ROOT}/debug/OooRedirectMuxChecker.sv"
    "${NPU_NPC_RTL_ROOT}/debug/OooRedirectSeqChecker.sv"
    "${NPU_NPC_RTL_ROOT}/debug/OooAdUpdateChecker.sv"
    "${NPU_NPC_RTL_ROOT}/debug/OooBranchDirectionPredictorChecker.sv"
    "${NPU_NPC_RTL_ROOT}/decode/OooFpDecode.v"
    "${NPU_NPC_RTL_ROOT}/decode/DecodeStage.v"
    "${NPU_NPC_RTL_ROOT}/decode/OooAluDecodeBackend.v"
    "${NPU_NPC_RTL_ROOT}/decode/DecodeUnit.v"
    "${NPU_NPC_RTL_ROOT}/decode/ImmGen.v"
    "${NPU_NPC_RTL_ROOT}/decode/OooRvcDecompressor.v"
    "${NPU_NPC_RTL_ROOT}/include/define.v"
    "${NPU_NPC_RTL_ROOT}/cache/OooDataWordCache.v"
    "${NPU_NPC_RTL_ROOT}/cache/OooFetchPacketCache.v"
    "${NPU_NPC_RTL_ROOT}/rename_allocate/OooFreeList.v"
    "${NPU_NPC_RTL_ROOT}/rename_allocate/OooRenameMap.v"
    "${NPU_NPC_RTL_ROOT}/rename_allocate/OooDispatchBackend.v"
    "${NPU_NPC_RTL_ROOT}/rename_allocate/OooTensorRobSidecar.v"
    "${NPU_NPC_RTL_ROOT}/rename_allocate/OooBusyTable.v"
    "${NPU_NPC_RTL_ROOT}/bus/NpcAxiBus.v"
    "${NPU_NPC_RTL_ROOT}/bus/AxiToUart.v"
    "${NPU_NPC_RTL_ROOT}/bus/Uart.v"
    "${NPU_NPC_RTL_ROOT}/bus/AxiClint.v"
    "${NPU_NPC_RTL_ROOT}/bus/AxiResetSyscon.v"
    "${NPU_NPC_RTL_ROOT}/bus/AxiDefaultSlave.v"
    "${NPU_NPC_RTL_ROOT}/bus/AxiPlic.v"
    "${NPU_NPC_RTL_ROOT}/bus/AxiCrossbar.v"
    "${NPU_NPC_RTL_ROOT}/regread_bypass/OooFpPhysRegFile.v"
    "${NPU_NPC_RTL_ROOT}/regread_bypass/OooPendingOperandReadGate.v"
    "${NPU_NPC_RTL_ROOT}/regread_bypass/OooFpRegFile.v"
    "${NPU_NPC_RTL_ROOT}/regread_bypass/OooPhysRegFile.v"
    "${NPU_NPC_RTL_ROOT}/execute/OooClmulUnit.v"
    "${NPU_NPC_RTL_ROOT}/execute/OooFpLongOpGate.v"
    "${NPU_NPC_RTL_ROOT}/execute/OooFpSgnjGate.v"
    "${NPU_NPC_RTL_ROOT}/execute/OooFpFmaNormRoundPipe.v"
    "${NPU_NPC_RTL_ROOT}/execute/OooFpDivIter.v"
    "${NPU_NPC_RTL_ROOT}/execute/OooAluCoreSlice.v"
    "${NPU_NPC_RTL_ROOT}/execute/ALU.v"
    "${NPU_NPC_RTL_ROOT}/execute/OooAmoGate.v"
    "${NPU_NPC_RTL_ROOT}/execute/OooMulDivUnit.v"
    "${NPU_NPC_RTL_ROOT}/execute/OooFpPredicates.v"
    "${NPU_NPC_RTL_ROOT}/execute/OooFpMulProductPipe.v"
    "${NPU_NPC_RTL_ROOT}/execute/OooFpFmaAlignAddPipe.v"
    "${NPU_NPC_RTL_ROOT}/execute/OooFpAddSubPipe.v"
    "${NPU_NPC_RTL_ROOT}/execute/OooFpSqrtIter.v"
    "${NPU_NPC_RTL_ROOT}/execute/OooFpConvertGate.v"
    "${NPU_NPC_RTL_ROOT}/execute/OooBitmanipGate.v"
    "${NPU_NPC_RTL_ROOT}/execute/OooIntBackend.v"
    "${NPU_NPC_RTL_ROOT}/control/OooTrapExitOutputSequencer.v"
    "${NPU_NPC_RTL_ROOT}/execute/OooFpBackend.v"
    "${NPU_NPC_RTL_ROOT}/execute/OooFpRound.v"
    "${NPU_NPC_RTL_ROOT}/control/OooSerializedMemTerminalPermit.v"
    "${NPU_NPC_RTL_ROOT}/control/OooPendingSystemSequencer.v"
    "${NPU_NPC_RTL_ROOT}/control/OooPendingSystemAdmissionCancelGate.v"
    "${NPU_NPC_RTL_ROOT}/control/OooCoreSliceControlGate.v"
    "${NPU_NPC_RTL_ROOT}/control/OooCoreObservableOutputGate.v"
    "${NPU_NPC_RTL_ROOT}/control/OooControlEventApplySequencer.v"
    "${NPU_NPC_RTL_ROOT}/control/OooCsrAccessRequestMux.v"
    "${NPU_NPC_RTL_ROOT}/control/OooRedirectArbiter.v"
    "${NPU_NPC_RTL_ROOT}/control/OooPendingLane1CaptureGate.v"
    "${NPU_NPC_RTL_ROOT}/control/OooPendingDispatchArbiter.v"
    "${NPU_NPC_RTL_ROOT}/control/OooControlFlushSequencer.v"
    "${NPU_NPC_RTL_ROOT}/control/OooStopPendingSequencer.v"
    "${NPU_NPC_RTL_ROOT}/control/OooPendingTrapExitSequencer.v"
    "${NPU_NPC_RTL_ROOT}/control/OooControlPlane.v"
    "${NPU_NPC_RTL_ROOT}/control/OooTrapExitEventMux.v"
    "${NPU_NPC_RTL_ROOT}/control/OooCsrIllegalProbeGate.v"
    "${NPU_NPC_RTL_ROOT}/control/OooPendingDrainResolveGate.v"
    "${NPU_NPC_RTL_ROOT}/control/OooCsrTrapRequestMux.v"
    "${NPU_NPC_RTL_ROOT}/execute/OooFpMulNormRoundPipe.v"
    "${NPU_NPC_RTL_ROOT}/execute/OooFpClassifyGate.v"
    "${NPU_NPC_RTL_ROOT}/execute/OooFpCompareGate.v"
    "${NPU_NPC_RTL_ROOT}/execute/OooExecuteBackend.v"
    "${NPU_NPC_RTL_ROOT}/execute/CompareUnit.v"
    "${NPU_NPC_RTL_ROOT}/execute/OooFpArithGate.v"
    "${NPU_NPC_RTL_ROOT}/sram/Sram4096x199.v"
    "${NPU_NPC_RTL_ROOT}/sram/Sram4096x113.v"
)
set(NPU_SYSTEM_INCLUDE_DEPENDENCIES
    "${NPU_NPC_RTL_ROOT}/common/OooBranchDirectionPredictorFacts.vh"
    "${NPU_NPC_RTL_ROOT}/common/OooDataWordCacheFacts.vh"
    "${NPU_NPC_RTL_ROOT}/common/OooFetchPacketCacheFacts.vh"
    "${NPU_NPC_RTL_ROOT}/common/OooRedirectMuxFacts.vh"
    "${NPU_NPC_RTL_ROOT}/common/OooRedirectSeqFacts.vh"
    "${NPU_PROJECT_ROOT}/rtl/tensor_npu_defs.vh"
)
set(NPU_SYSTEM_RTL_SOURCES
    ${NPU_SYSTEM_FPU_RTL_SOURCES}
    ${NPU_NPC_RTL_SOURCES}
    # Production-only raw Q8 portal closure.  The public/direct Coprocessor
    # archive intentionally keeps its default portal parameter disabled.
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuQ8RowSimdCore.v"
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuQ8GemvPortalAdapter.v"
)
foreach(NPU_DIRECT_SOURCE IN LISTS NPU_RTL_SOURCES)
    if(NOT NPU_DIRECT_SOURCE MATCHES "/third_party/fpu-sp/" AND
       NOT NPU_DIRECT_SOURCE MATCHES "/tensor_npu_defs[.]vh$")
        list(APPEND NPU_SYSTEM_RTL_SOURCES "${NPU_DIRECT_SOURCE}")
    endif()
endforeach()
list(APPEND NPU_SYSTEM_RTL_SOURCES
    "${NPU_PROJECT_ROOT}/sim/NpcTensorNpuSystemTop.sv")

set(NPU_SYSTEM_VERILATED_ARCHIVE
    "${NPU_SYSTEM_VERILATED_MDIR}/VNpcTensorNpuSystemTop__ALL.a")
set(NPU_SYSTEM_VERILATED_HEADER
    "${NPU_SYSTEM_VERILATED_MDIR}/VNpcTensorNpuSystemTop.h")
set(NPU_SYSTEM_VERILATED_DPI_HEADER
    "${NPU_SYSTEM_VERILATED_MDIR}/VNpcTensorNpuSystemTop__Dpi.h")

add_custom_command(
    OUTPUT "${NPU_SYSTEM_VERILATED_ARCHIVE}"
    BYPRODUCTS
        "${NPU_SYSTEM_VERILATED_HEADER}"
        "${NPU_SYSTEM_VERILATED_DPI_HEADER}"
    COMMAND "${CMAKE_COMMAND}" -E make_directory
            "${NPU_SYSTEM_VERILATED_MDIR}"
    COMMAND "${VERILATOR_EXECUTABLE}"
            --cc -O3 --no-assert --no-trace
            --top-module NpcTensorNpuSystemTop
            -GCOMMAND_FUNCTIONAL_ENABLE=0
            -GQ8_GEMV_PORTAL_ENABLE=1
            -GQ8_GEMV_ROW_LANES=4
            -GQ8_GEMV_MAC_LANES=32
            -GQ8_GEMV_TILE_FUNCTIONAL_ENABLE=0
            -GF32_ALU_PORTAL_ENABLE=1
            -GF32_ALU_PORTAL_LANES=8
            -GF32_MOVER_PORTAL_ENABLE=1
            -GF32_MOVER_PORTAL_LANES=16
            -Wno-fatal -Wno-DECLFILENAME -Wno-WIDTHEXPAND
            -Wno-WIDTHTRUNC -Wno-WIDTHCONCAT -Wno-UNUSEDSIGNAL
            -Wno-TIMESCALEMOD
            -Wno-PINMISSING -Wno-UNOPTFLAT
            "-I${NPU_NPC_RTL_ROOT}"
            "-I${NPU_NPC_RTL_ROOT}/include"
            "-I${NPU_PROJECT_ROOT}/rtl"
            "-I${NPU_PROJECT_ROOT}/third_party/hardfloat/source/RISCV"
            "-I${NPU_PROJECT_ROOT}/third_party/hardfloat/source"
            --Mdir "${NPU_SYSTEM_VERILATED_MDIR}"
            -CFLAGS "-O3 -DNDEBUG -march=native -fPIC"
            ${NPU_SYSTEM_RTL_SOURCES}
    COMMAND "${CMAKE_COMMAND}" -E env
            --unset=MAKEFLAGS
            --unset=MFLAGS
            "${NPU_MAKE_EXECUTABLE}"
            -C "${NPU_SYSTEM_VERILATED_MDIR}"
            -f VNpcTensorNpuSystemTop.mk
            -j${NPU_VERILATOR_JOBS}
            OPT_FAST=-O3 OPT_SLOW=-O3 OPT_GLOBAL=-O3
            VNpcTensorNpuSystemTop__ALL.a
    DEPENDS
        ${NPU_SYSTEM_RTL_SOURCES}
        ${NPU_SYSTEM_INCLUDE_DEPENDENCIES}
    WORKING_DIRECTORY "${NPU_PROJECT_ROOT}"
    COMMENT "Generating O3/no-assert/no-trace RV64 NpcTensorNpuSystemTop model"
    VERBATIM
)
add_custom_target(npu-system-verilated-model
    DEPENDS "${NPU_SYSTEM_VERILATED_ARCHIVE}")
set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_CLEAN_FILES
    "${NPU_SYSTEM_VERILATED_MDIR}")

set(NPU_Q8_GEMV_MANIFEST
    "${NPU_PROJECT_ROOT}/tmp/logs/qwen-graph-manifest-v5/dispatch.manifest.json"
    CACHE FILEPATH "Canonical Qwen dispatch manifest used for NPU profile generation")
set(NPU_QWEN_STEADY_MANIFEST
    "${NPU_PROJECT_ROOT}/tmp/logs/qwen-graph-manifest-v5/steady.manifest.json"
    CACHE FILEPATH "Canonical Qwen steady-state dispatch manifest used for NPU profile generation")
set(NPU_Q8_GEMV_GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")
set(NPU_F32_ALU_GENERATED_HEADER
    "${NPU_Q8_GEMV_GENERATED_DIR}/qwen-f32-alu-manifest.generated.h")
add_custom_command(
    OUTPUT "${NPU_F32_ALU_GENERATED_HEADER}"
    COMMAND "${CMAKE_COMMAND}" -E make_directory
            "${NPU_Q8_GEMV_GENERATED_DIR}"
    COMMAND "${CMAKE_COMMAND}" -E env PYTHONDONTWRITEBYTECODE=1
            "${Python3_EXECUTABLE}"
            "${NPU_PROJECT_ROOT}/scripts/qwen_f32_alu_profiles.py"
            emit-header
            --bootstrap-manifest "${NPU_Q8_GEMV_MANIFEST}"
            --steady-manifest "${NPU_QWEN_STEADY_MANIFEST}"
            --output "${NPU_F32_ALU_GENERATED_HEADER}"
    DEPENDS
        "${NPU_Q8_GEMV_MANIFEST}"
        "${NPU_QWEN_STEADY_MANIFEST}"
        "${NPU_PROJECT_ROOT}/scripts/qwen_f32_alu_profiles.py"
        "${NPU_PROJECT_ROOT}/scripts/qwen_graph_manifest.py"
    COMMENT "Auditing bootstrap/steady F32 ALU nodes and generating the exact canonical allowlist"
    VERBATIM
)
add_custom_target(npu-f32-alu-generated
    DEPENDS "${NPU_F32_ALU_GENERATED_HEADER}")
set(NPU_Q8_GEMV_GENERATED_HEADER
    "${NPU_Q8_GEMV_GENERATED_DIR}/qwen-q8-gemv-manifest.generated.h")
add_custom_command(
    OUTPUT "${NPU_Q8_GEMV_GENERATED_HEADER}"
    COMMAND "${CMAKE_COMMAND}" -E make_directory
            "${NPU_Q8_GEMV_GENERATED_DIR}"
    COMMAND "${CMAKE_COMMAND}" -E env PYTHONDONTWRITEBYTECODE=1
            "${Python3_EXECUTABLE}"
            "${NPU_PROJECT_ROOT}/scripts/qwen_q8_gemv_profiles.py"
            emit-header
            --manifest "${NPU_Q8_GEMV_MANIFEST}"
            --output "${NPU_Q8_GEMV_GENERATED_HEADER}"
    DEPENDS
        "${NPU_Q8_GEMV_MANIFEST}"
        "${NPU_PROJECT_ROOT}/scripts/qwen_q8_gemv_profiles.py"
        "${NPU_PROJECT_ROOT}/scripts/qwen_f32_alu_profiles.py"
        "${NPU_PROJECT_ROOT}/scripts/qwen_graph_manifest.py"
    COMMENT "Auditing canonical-v5 Q8 GEMV nodes and generating exact tables"
    VERBATIM
)
add_custom_target(npu-q8-gemv-generated
    DEPENDS "${NPU_Q8_GEMV_GENERATED_HEADER}")

set(NPU_F32_MOVER_GENERATED_HEADER
    "${NPU_Q8_GEMV_GENERATED_DIR}/qwen-f32-gather-repeat-manifest.generated.h")
add_custom_command(
    OUTPUT "${NPU_F32_MOVER_GENERATED_HEADER}"
    COMMAND "${CMAKE_COMMAND}" -E make_directory
            "${NPU_Q8_GEMV_GENERATED_DIR}"
    COMMAND "${CMAKE_COMMAND}" -E env PYTHONDONTWRITEBYTECODE=1
            "${Python3_EXECUTABLE}"
            "${NPU_PROJECT_ROOT}/scripts/qwen_f32_gather_repeat_profiles.py"
            emit-header
            --manifest "${NPU_Q8_GEMV_MANIFEST}"
            --output "${NPU_F32_MOVER_GENERATED_HEADER}"
    DEPENDS
        "${NPU_Q8_GEMV_MANIFEST}"
        "${NPU_PROJECT_ROOT}/scripts/qwen_f32_gather_repeat_profiles.py"
        "${NPU_PROJECT_ROOT}/scripts/qwen_f32_alu_profiles.py"
        "${NPU_PROJECT_ROOT}/scripts/qwen_graph_manifest.py"
    COMMENT "Auditing canonical-v5 F32 GET_ROWS/REPEAT and generating exact tables"
    VERBATIM
)
add_custom_target(npu-f32-mover-generated
    DEPENDS "${NPU_F32_MOVER_GENERATED_HEADER}")

set(NPU_REMAINING_GENERATED_HEADER
    "${NPU_Q8_GEMV_GENERATED_DIR}/qwen-remaining-manifest.generated.h")
add_custom_command(
    OUTPUT "${NPU_REMAINING_GENERATED_HEADER}"
    COMMAND "${CMAKE_COMMAND}" -E make_directory
            "${NPU_Q8_GEMV_GENERATED_DIR}"
    COMMAND "${CMAKE_COMMAND}" -E env PYTHONDONTWRITEBYTECODE=1
            "${Python3_EXECUTABLE}"
            "${NPU_PROJECT_ROOT}/scripts/qwen_remaining_profiles.py"
            emit-header
            --manifest "${NPU_Q8_GEMV_MANIFEST}"
            --output "${NPU_REMAINING_GENERATED_HEADER}"
    DEPENDS
        "${NPU_Q8_GEMV_MANIFEST}"
        "${NPU_PROJECT_ROOT}/scripts/qwen_remaining_profiles.py"
        "${NPU_PROJECT_ROOT}/scripts/qwen_f32_gather_repeat_profiles.py"
        "${NPU_PROJECT_ROOT}/scripts/qwen_q8_gemv_profiles.py"
        "${NPU_PROJECT_ROOT}/scripts/qwen_f32_alu_profiles.py"
        "${NPU_PROJECT_ROOT}/scripts/qwen_graph_manifest.py"
    COMMENT "Auditing final 433 canonical-v5 nodes and generating 30 exact profiles"
    VERBATIM
)
add_custom_target(npu-remaining-generated
    DEPENDS "${NPU_REMAINING_GENERATED_HEADER}")

set(NPU_SAMPLER_ARGMAX_GENERATED_HEADER
    "${NPU_Q8_GEMV_GENERATED_DIR}/qwen-sampler-argmax-profile.generated.h")
add_custom_command(
    OUTPUT "${NPU_SAMPLER_ARGMAX_GENERATED_HEADER}"
    COMMAND "${CMAKE_COMMAND}" -E make_directory
            "${NPU_Q8_GEMV_GENERATED_DIR}"
    COMMAND "${CMAKE_COMMAND}" -E env PYTHONDONTWRITEBYTECODE=1
            "${Python3_EXECUTABLE}"
            "${NPU_PROJECT_ROOT}/scripts/qwen_sampler_argmax_profile.py"
            emit-header
            --manifest "${NPU_Q8_GEMV_MANIFEST}"
            --output "${NPU_SAMPLER_ARGMAX_GENERATED_HEADER}"
    DEPENDS
        "${NPU_Q8_GEMV_MANIFEST}"
        "${NPU_PROJECT_ROOT}/scripts/qwen_sampler_argmax_profile.py"
        "${NPU_PROJECT_ROOT}/scripts/qwen_f32_alu_profiles.py"
        "${NPU_PROJECT_ROOT}/scripts/qwen_graph_manifest.py"
    COMMENT "Auditing the canonical strict-greedy ARGMAX sampler owner"
    VERBATIM
)
add_custom_target(npu-sampler-argmax-generated
    DEPENDS "${NPU_SAMPLER_ARGMAX_GENERATED_HEADER}")

add_library(ggml-base-pinned SHARED IMPORTED GLOBAL)
set_target_properties(ggml-base-pinned PROPERTIES
    IMPORTED_LOCATION "${LLAMA_BUILD_BIN}/libggml-base.so"
    INTERFACE_INCLUDE_DIRECTORIES "${LLAMA_SOURCE_DIR}/ggml/include"
)

add_library(ggml-pinned SHARED IMPORTED GLOBAL)
set_target_properties(ggml-pinned PROPERTIES
    IMPORTED_LOCATION "${LLAMA_BUILD_BIN}/libggml.so"
    INTERFACE_INCLUDE_DIRECTORIES "${LLAMA_SOURCE_DIR}/ggml/include"
)

add_library(npu-verilator-runner STATIC
    npu-verilator-runner.cpp
    npu-verilator-q8-runner.cpp
    npu-verilator-q8-gemv-runner.cpp
    npu-verilator-f32-mover-runner.cpp
    npu-verilator-argmax-runner.cpp
    npu-verilator-exact-runner.cpp
    "${VERILATOR_ROOT}/include/verilated.cpp"
    "${VERILATOR_ROOT}/include/verilated_dpi.cpp"
    "${VERILATOR_ROOT}/include/verilated_threads.cpp"
)
add_dependencies(npu-verilator-runner
    npu-system-verilated-model)
target_compile_features(npu-verilator-runner PRIVATE cxx_std_17)
target_compile_definitions(npu-verilator-runner PRIVATE
    NPU_PRODUCTION_SYSTEM_RUNNER=1
    NPU_SYSTEM_Q8_PORTAL=1
    NPU_SYSTEM_F32_ALU_PORTAL=1
    NPU_SYSTEM_F32_MOVER_PORTAL=1)
target_compile_options(npu-verilator-runner PRIVATE
    -O3 -DNDEBUG -march=native -Wall -Wextra -Wpedantic)
target_include_directories(npu-verilator-runner SYSTEM PRIVATE
    "${NPU_SYSTEM_VERILATED_MDIR}"
    "${VERILATOR_ROOT}/include"
    "${VERILATOR_ROOT}/include/vltstd"
)
set_source_files_properties(
    "${VERILATOR_ROOT}/include/verilated.cpp"
    "${VERILATOR_ROOT}/include/verilated_dpi.cpp"
    "${VERILATOR_ROOT}/include/verilated_threads.cpp"
    PROPERTIES COMPILE_OPTIONS -w
)
set_source_files_properties(
    npu-q8-row-tile-dpi.cpp
    npu-functional-command-dpi.cpp
    PROPERTIES COMPILE_OPTIONS
        "-fno-fast-math;-ffp-contract=off;-frounding-math"
)
target_link_libraries(npu-verilator-runner PUBLIC
    Threads::Threads
    "${NPU_SYSTEM_VERILATED_ARCHIVE}"
    m
    "${CMAKE_DL_LIBS}"
)
set_target_properties(npu-verilator-runner PROPERTIES
    POSITION_INDEPENDENT_CODE ON
)

# Fast, model-independent qualification of the command-DPI numerical and
# checked-capability boundary.  It deliberately does not link a Verilated top;
# production SystemTop coverage is exercised by the existing backend tests.
add_executable(test-npu-functional-command EXCLUDE_FROM_ALL
    test-functional-command.cpp
    npu-functional-command-dpi.cpp
)
target_compile_features(test-npu-functional-command PRIVATE cxx_std_17)
target_compile_options(test-npu-functional-command PRIVATE
    -O3 -DNDEBUG -Wall -Wextra -Wpedantic
    -fno-fast-math -ffp-contract=off -frounding-math)
target_include_directories(test-npu-functional-command SYSTEM PRIVATE
    "${VERILATOR_ROOT}/include"
    "${VERILATOR_ROOT}/include/vltstd"
)
target_link_libraries(test-npu-functional-command PRIVATE m)

# Legacy port-level qualification is intentionally outside the production
# dependency closure.  This optional DSO is built only when an explicit
# self-test target is requested; ggml-npu neither links it nor the direct
# VTensorNpuCoprocessor archive.
add_library(npu-direct-selftests MODULE EXCLUDE_FROM_ALL
    npu-verilator-runner.cpp
    npu-verilator-direct-selftest-export.cpp
    "${VERILATOR_ROOT}/include/verilated.cpp"
    "${VERILATOR_ROOT}/include/verilated_threads.cpp"
)
add_dependencies(npu-direct-selftests npu-verilated-model)
target_compile_features(npu-direct-selftests PRIVATE cxx_std_17)
target_compile_options(npu-direct-selftests PRIVATE
    -O3 -DNDEBUG -march=native -Wall -Wextra -Wpedantic)
target_include_directories(npu-direct-selftests SYSTEM PRIVATE
    "${NPU_VERILATED_MDIR}"
    "${VERILATOR_ROOT}/include"
    "${VERILATOR_ROOT}/include/vltstd"
)
target_link_libraries(npu-direct-selftests PRIVATE
    Threads::Threads
    "${NPU_VERILATED_ARCHIVE}"
)
set_target_properties(npu-direct-selftests PROPERTIES
    OUTPUT_NAME "npu-direct-selftests"
)

add_library(ggml-npu MODULE
    ggml-npu.cpp
    "${NPU_F32_ALU_GENERATED_HEADER}"
    "${NPU_Q8_GEMV_GENERATED_HEADER}"
    "${NPU_F32_MOVER_GENERATED_HEADER}"
    "${NPU_REMAINING_GENERATED_HEADER}"
    "${NPU_SAMPLER_ARGMAX_GENERATED_HEADER}"
)
add_dependencies(ggml-npu
    npu-f32-alu-generated
    npu-q8-gemv-generated
    npu-f32-mover-generated
    npu-remaining-generated
    npu-sampler-argmax-generated)
target_compile_features(ggml-npu PRIVATE cxx_std_17)
target_compile_definitions(ggml-npu PRIVATE
    GGML_BACKEND_DL
    GGML_BACKEND_BUILD
    GGML_BACKEND_SHARED
    GGML_SHARED
)
target_compile_options(ggml-npu PRIVATE -Wall -Wextra -Wpedantic)
target_include_directories(ggml-npu PRIVATE
    "${NPU_Q8_GEMV_GENERATED_DIR}"
    "${LLAMA_SOURCE_DIR}/ggml/include"
    "${LLAMA_SOURCE_DIR}/ggml/src"
)
target_link_libraries(ggml-npu PRIVATE ggml-base-pinned npu-verilator-runner)
set_target_properties(ggml-npu PROPERTIES
    OUTPUT_NAME "ggml-npu"
    BUILD_RPATH "${LLAMA_BUILD_BIN}"
)

add_executable(test-npu-backend
    test-backend.cpp
    "${NPU_F32_ALU_GENERATED_HEADER}"
    "${NPU_Q8_GEMV_GENERATED_HEADER}"
    "${NPU_F32_MOVER_GENERATED_HEADER}"
    "${NPU_SAMPLER_ARGMAX_GENERATED_HEADER}"
)
add_dependencies(test-npu-backend
    npu-f32-alu-generated
    npu-q8-gemv-generated
    npu-f32-mover-generated
    npu-sampler-argmax-generated)
target_compile_features(test-npu-backend PRIVATE cxx_std_17)
target_compile_options(test-npu-backend PRIVATE -Wall -Wextra -Wpedantic)
target_include_directories(test-npu-backend PRIVATE
    "${NPU_Q8_GEMV_GENERATED_DIR}"
    "${LLAMA_SOURCE_DIR}/ggml/include"
)
target_link_libraries(test-npu-backend PRIVATE ggml-pinned ggml-base-pinned)
set_target_properties(test-npu-backend PROPERTIES
    BUILD_RPATH "${LLAMA_BUILD_BIN}"
)

# Direct SystemTop qualification for the canonical P17/P18 zero-cardinality
# SCALE variant.  This remains a default build target so a fresh production
# build cannot silently omit the zero-work command/completion proof.
add_executable(test-npu-f32-zero
    test-f32-zero.cpp
)
add_dependencies(test-npu-f32-zero npu-system-verilated-model)
target_compile_features(test-npu-f32-zero PRIVATE cxx_std_17)
target_compile_options(test-npu-f32-zero PRIVATE
    -O3 -DNDEBUG -Wall -Wextra -Wpedantic)
target_link_libraries(test-npu-f32-zero PRIVATE npu-verilator-runner)

add_executable(test-npu-f32-mover
    test-f32-mover.cpp
    "${NPU_F32_MOVER_GENERATED_HEADER}"
)
add_dependencies(test-npu-f32-mover npu-f32-mover-generated)
target_compile_features(test-npu-f32-mover PRIVATE cxx_std_17)
target_compile_options(test-npu-f32-mover PRIVATE
    -O3 -DNDEBUG -Wall -Wextra -Wpedantic)
target_include_directories(test-npu-f32-mover PRIVATE
    "${NPU_Q8_GEMV_GENERATED_DIR}"
    "${LLAMA_SOURCE_DIR}/ggml/include"
)
target_link_libraries(test-npu-f32-mover PRIVATE
    ggml-pinned
    ggml-base-pinned)
set_target_properties(test-npu-f32-mover PROPERTIES
    BUILD_RPATH "${LLAMA_BUILD_BIN}"
)

add_executable(test-npu-remaining
    test-remaining.cpp
    "${NPU_Q8_GEMV_GENERATED_HEADER}"
    "${NPU_REMAINING_GENERATED_HEADER}"
)
add_dependencies(test-npu-remaining
    npu-q8-gemv-generated
    npu-remaining-generated
    npu-system-verilated-model)
target_compile_features(test-npu-remaining PRIVATE cxx_std_17)
target_compile_options(test-npu-remaining PRIVATE
    -O3 -DNDEBUG -Wall -Wextra -Wpedantic)
target_include_directories(test-npu-remaining PRIVATE
    "${NPU_Q8_GEMV_GENERATED_DIR}"
    "${LLAMA_SOURCE_DIR}/ggml/include"
)
target_link_libraries(test-npu-remaining PRIVATE
    ggml-pinned
    ggml-base-pinned
    npu-verilator-runner)
set_target_properties(test-npu-remaining PROPERTIES
    BUILD_RPATH "${LLAMA_BUILD_BIN}"
)

add_executable(test-npu-argmax
    test-argmax.cpp
)
add_dependencies(test-npu-argmax npu-system-verilated-model)
target_compile_features(test-npu-argmax PRIVATE cxx_std_17)
target_compile_options(test-npu-argmax PRIVATE
    -O3 -DNDEBUG -Wall -Wextra -Wpedantic
    -fno-fast-math -ffp-contract=off)
target_link_libraries(test-npu-argmax PRIVATE npu-verilator-runner)
