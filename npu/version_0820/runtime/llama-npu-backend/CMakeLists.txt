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
find_program(NPU_RISCV64_GCC_EXECUTABLE
    NAMES riscv64-linux-gnu-gcc REQUIRED)
find_program(NPU_RISCV64_OBJCOPY_EXECUTABLE
    NAMES riscv64-linux-gnu-objcopy REQUIRED)
find_program(NPU_RISCV64_OBJDUMP_EXECUTABLE
    NAMES riscv64-linux-gnu-objdump REQUIRED)
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

# Fixed RV64 service firmware.  The build output is an ELF for auditing, a
# flat image for the SystemTop CPU aperture, and a deterministic C++ header for
# the Host Runtime.  Firmware consumes only relocated 30-word records from the
# NC mailbox; it never parses command.bin's file header.
set(NPU_RV64_FIRMWARE_DIR "${NPU_PROJECT_ROOT}/firmware")
set(NPU_RV64_FIRMWARE_BUILD_DIR
    "${CMAKE_CURRENT_BINARY_DIR}/rv64-service-firmware")
set(NPU_RV64_FIRMWARE_ELF
    "${NPU_RV64_FIRMWARE_BUILD_DIR}/npu-service-firmware.elf")
set(NPU_RV64_FIRMWARE_BIN
    "${NPU_RV64_FIRMWARE_BUILD_DIR}/npu-service-firmware.bin")
set(NPU_RV64_FIRMWARE_MAP
    "${NPU_RV64_FIRMWARE_BUILD_DIR}/npu-service-firmware.map")
set(NPU_RV64_FIRMWARE_HEADER
    "${NPU_RV64_FIRMWARE_BUILD_DIR}/npu-rv64-service-firmware-image.h")

add_custom_command(
    OUTPUT
        "${NPU_RV64_FIRMWARE_ELF}"
        "${NPU_RV64_FIRMWARE_BIN}"
        "${NPU_RV64_FIRMWARE_HEADER}"
    BYPRODUCTS "${NPU_RV64_FIRMWARE_MAP}"
    COMMAND "${CMAKE_COMMAND}" -E make_directory
            "${NPU_RV64_FIRMWARE_BUILD_DIR}"
    COMMAND "${NPU_RISCV64_GCC_EXECUTABLE}"
            -march=rv64im_zicsr
            -mabi=lp64
            -mcmodel=medany
            -nostdlib
            -nostartfiles
            -nodefaultlibs
            -ffreestanding
            -static
            -Wl,--build-id=none
            -Wl,--no-relax
            -Wl,--gc-sections
            "-Wl,-T,${NPU_RV64_FIRMWARE_DIR}/npu_service.ld"
            "-Wl,-Map,${NPU_RV64_FIRMWARE_MAP}"
            "-I${NPU_RV64_FIRMWARE_DIR}"
            -x assembler-with-cpp
            "${NPU_RV64_FIRMWARE_DIR}/npu_service.S"
            -o "${NPU_RV64_FIRMWARE_ELF}"
    COMMAND "${NPU_RISCV64_OBJCOPY_EXECUTABLE}"
            -O binary
            "${NPU_RV64_FIRMWARE_ELF}"
            "${NPU_RV64_FIRMWARE_BIN}"
    COMMAND "${Python3_EXECUTABLE}"
            "${NPU_RV64_FIRMWARE_DIR}/bin_to_cpp_header.py"
            --input "${NPU_RV64_FIRMWARE_BIN}"
            --output "${NPU_RV64_FIRMWARE_HEADER}"
            --load-address 0x80000000
            --entry-address 0x80000000
            --mailbox-address 0xa0000000
            --command-address 0xa0000100
            --completion-address 0xa0100000
    DEPENDS
        "${NPU_RV64_FIRMWARE_DIR}/npu_service.S"
        "${NPU_RV64_FIRMWARE_DIR}/npu_service.ld"
        "${NPU_RV64_FIRMWARE_DIR}/npu_service_mailbox_abi.h"
        "${NPU_RV64_FIRMWARE_DIR}/bin_to_cpp_header.py"
    COMMENT "Building fixed RV64 NPU service firmware"
    VERBATIM
)
add_custom_target(npu-rv64-service-firmware
    DEPENDS
        "${NPU_RV64_FIRMWARE_ELF}"
        "${NPU_RV64_FIRMWARE_BIN}"
        "${NPU_RV64_FIRMWARE_HEADER}"
)
set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_CLEAN_FILES
    "${NPU_RV64_FIRMWARE_BUILD_DIR}")

# Consumers can link this interface target to get the generated image header
# and the mailbox ABI include path without depending on source-tree binaries.
add_library(npu-rv64-service-firmware-image INTERFACE)
add_dependencies(npu-rv64-service-firmware-image
    npu-rv64-service-firmware)
target_include_directories(npu-rv64-service-firmware-image INTERFACE
    "${NPU_RV64_FIRMWARE_BUILD_DIR}"
    "${NPU_RV64_FIRMWARE_DIR}"
)

add_executable(npu-rv64-service-firmware-image-test EXCLUDE_FROM_ALL
    "${NPU_RV64_FIRMWARE_DIR}/test-firmware-image.cpp"
    "${NPU_RV64_FIRMWARE_HEADER}"
)
add_dependencies(npu-rv64-service-firmware-image-test
    npu-rv64-service-firmware)
target_compile_features(npu-rv64-service-firmware-image-test
    PRIVATE cxx_std_17)
target_compile_options(npu-rv64-service-firmware-image-test PRIVATE
    -Wall -Wextra -Wpedantic)
target_link_libraries(npu-rv64-service-firmware-image-test PRIVATE
    npu-rv64-service-firmware-image)

add_custom_target(test-npu-rv64-service-firmware
    COMMAND "${NPU_RISCV64_OBJDUMP_EXECUTABLE}"
            -f "${NPU_RV64_FIRMWARE_ELF}"
    COMMAND $<TARGET_FILE:npu-rv64-service-firmware-image-test>
    DEPENDS npu-rv64-service-firmware-image-test
    COMMENT "Checking RV64 firmware entry and Tensor instruction layout"
    VERBATIM
)

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

add_executable(test-npu-fault-recovery EXCLUDE_FROM_ALL
    "${NPU_PROJECT_ROOT}/tests/npu_fault_recovery_tb.cpp"
    "${VERILATOR_ROOT}/include/verilated.cpp"
    "${VERILATOR_ROOT}/include/verilated_threads.cpp"
)
add_dependencies(test-npu-fault-recovery npu-verilated-model)
target_compile_features(test-npu-fault-recovery PRIVATE cxx_std_17)
target_compile_options(test-npu-fault-recovery PRIVATE
    -O3 -DNDEBUG -Wall -Wextra -Wpedantic)
target_include_directories(test-npu-fault-recovery SYSTEM PRIVATE
    "${NPU_VERILATED_MDIR}"
    "${VERILATOR_ROOT}/include"
    "${VERILATOR_ROOT}/include/vltstd"
)
target_link_libraries(test-npu-fault-recovery PRIVATE
    Threads::Threads
    "${NPU_VERILATED_ARCHIVE}"
)

add_custom_target(check-npu-fault-recovery
    COMMAND $<TARGET_FILE:test-npu-fault-recovery>
    DEPENDS test-npu-fault-recovery
    COMMENT "Checking recoverable and fatal NPU error lifecycles"
    VERBATIM
)

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
# Use the CPU's native catalog; no historical Ooo CPU enters this model.
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
    "${NPU_NPC_RTL_ROOT}/filelist.mk" "${NPU_NPC_RTL_ROOT}/chengyue64/filelist.mk")
execute_process(
    COMMAND "${NPU_MAKE_EXECUTABLE}" -s -C "${NPU_WORKBENCH_ROOT}/npc/rv64" print-synth-rtl
    OUTPUT_VARIABLE NPU_NATIVE_SOURCE_TEXT OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY)
string(REGEX REPLACE "[ \t\r\n]+" ";" NPU_NPC_RTL_SOURCES "${NPU_NATIVE_SOURCE_TEXT}")
list(APPEND NPU_NPC_RTL_SOURCES
    "${NPU_NPC_RTL_ROOT}/sim/AxiDpiSlave.sv"
    "${NPU_NPC_RTL_ROOT}/sim/R64NpuCpuSim.sv")
file(GLOB NPU_SYSTEM_INCLUDE_DEPENDENCIES CONFIGURE_DEPENDS
    "${NPU_NPC_RTL_ROOT}/chengyue64/backend/*.vh"
    "${NPU_NPC_RTL_ROOT}/chengyue64/platform/*.vh")
list(APPEND NPU_SYSTEM_INCLUDE_DEPENDENCIES
    "${NPU_NPC_RTL_ROOT}/include/define.v"
    "${NPU_PROJECT_ROOT}/rtl/tensor_npu_defs.vh")
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
    "${NPU_PROJECT_ROOT}/rtl/TensorNpuServiceDma.v"
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
            --cc -O3 --assert -DR64_ASSERT --no-trace
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
            "-I${NPU_NPC_RTL_ROOT}/chengyue64/backend"
            "-I${NPU_NPC_RTL_ROOT}/chengyue64/platform"
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
    COMMENT "Generating native R64 CPU + Tensor NPU model with assertions"
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

add_library(npu-command-abi STATIC
    npu-command-abi.cpp
)
target_compile_features(npu-command-abi PUBLIC cxx_std_17)
target_compile_options(npu-command-abi PRIVATE
    -Wall -Wextra -Wpedantic)
target_include_directories(npu-command-abi PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}"
)
set_target_properties(npu-command-abi PROPERTIES
    POSITION_INDEPENDENT_CODE ON
)

add_library(npu-compiled-runtime STATIC
    npu-compiled-bundle.cpp
)
target_compile_features(npu-compiled-runtime PUBLIC cxx_std_17)
target_compile_options(npu-compiled-runtime PRIVATE
    -O3 -Wall -Wextra -Wpedantic)
target_include_directories(npu-compiled-runtime PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}"
)
target_include_directories(npu-compiled-runtime SYSTEM PRIVATE
    "${LLAMA_SOURCE_DIR}/vendor"
)
target_link_libraries(npu-compiled-runtime PUBLIC
    npu-command-abi
)
set_target_properties(npu-compiled-runtime PROPERTIES
    POSITION_INDEPENDENT_CODE ON
)

# Persistent fixed-firmware execution service.  The process-global Verilator
# DPI callbacks live in this library, so consumers must not link it together
# with npu-verilator-runner (the legacy per-transaction harness owns the same
# callback symbols).  A session constructs and resets one production
# SystemTop once, then accepts strictly monotonic mailbox generations.
add_library(npu-system-session STATIC
    npu-system-session.cpp
    "${VERILATOR_ROOT}/include/verilated.cpp"
    "${VERILATOR_ROOT}/include/verilated_dpi.cpp"
    "${VERILATOR_ROOT}/include/verilated_threads.cpp"
)
add_dependencies(npu-system-session
    npu-system-verilated-model
    npu-rv64-service-firmware
)
target_compile_features(npu-system-session PUBLIC cxx_std_17)
target_compile_options(npu-system-session PRIVATE
    -O3 -DNDEBUG -Wall -Wextra -Wpedantic)
target_include_directories(npu-system-session PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}"
)
target_include_directories(npu-system-session SYSTEM PRIVATE
    "${NPU_SYSTEM_VERILATED_MDIR}"
    "${VERILATOR_ROOT}/include"
    "${VERILATOR_ROOT}/include/vltstd"
)
target_link_libraries(npu-system-session
    PUBLIC
        npu-compiled-runtime
        npu-rv64-service-firmware-image
    PRIVATE
        Threads::Threads
        "${NPU_SYSTEM_VERILATED_ARCHIVE}"
        m
        "${CMAKE_DL_LIBS}"
)
set_target_properties(npu-system-session PROPERTIES
    POSITION_INDEPENDENT_CODE ON
)

# Atomic compiled-artifact execution boundary used by production backends.
# It owns one persistent SystemTop session, constructs a private IOVA arena,
# and exposes external outputs only after every command has completed.
add_library(npu-host-runtime STATIC
    npu-host-runtime.cpp
)
target_compile_features(npu-host-runtime PUBLIC cxx_std_17)
target_compile_options(npu-host-runtime PRIVATE
    -O3 -DNDEBUG -Wall -Wextra -Wpedantic)
target_include_directories(npu-host-runtime PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}"
)
target_link_libraries(npu-host-runtime PUBLIC
    npu-compiled-runtime
    npu-system-session
)
set_target_properties(npu-host-runtime PROPERTIES
    POSITION_INDEPENDENT_CODE ON
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
    npu-command-abi
    Threads::Threads
    "${NPU_SYSTEM_VERILATED_ARCHIVE}"
    m
    "${CMAKE_DL_LIBS}"
)
set_target_properties(npu-verilator-runner PROPERTIES
    POSITION_INDEPENDENT_CODE ON
)

# Model-independent conformance suite for the one 30-word wire ABI shared by
# the compiler, Host Runtime, fixed firmware, and the legacy exact runner.
add_executable(test-npu-command-abi EXCLUDE_FROM_ALL
    test-command-abi.cpp
)
target_compile_features(test-npu-command-abi PRIVATE cxx_std_17)
target_compile_options(test-npu-command-abi PRIVATE
    -Wall -Wextra -Wpedantic)
target_link_libraries(test-npu-command-abi PRIVATE
    npu-command-abi
)

add_custom_target(check-npu-command-abi
    COMMAND $<TARGET_FILE:test-npu-command-abi>
    DEPENDS test-npu-command-abi
    COMMENT "Checking NPU command wire ABI and fail-closed relocation"
    VERBATIM
)

add_executable(test-npu-compiled-bundle EXCLUDE_FROM_ALL
    test-compiled-bundle.cpp
)
target_compile_features(test-npu-compiled-bundle PRIVATE cxx_std_17)
target_compile_options(test-npu-compiled-bundle PRIVATE
    -Wall -Wextra -Wpedantic)
target_link_libraries(test-npu-compiled-bundle PRIVATE
    npu-compiled-runtime
)

set(NPU_TINY_BUNDLE_DIR
    "${CMAKE_CURRENT_BINARY_DIR}/npu-tiny-compiled-bundle")
set(NPU_TINY_BUNDLE_COMMAND "${NPU_TINY_BUNDLE_DIR}/command.bin")
set(NPU_TINY_BUNDLE_WEIGHTS "${NPU_TINY_BUNDLE_DIR}/weights.bin")
set(NPU_TINY_BUNDLE_METADATA "${NPU_TINY_BUNDLE_DIR}/metadata.json")
add_custom_command(
    OUTPUT
        "${NPU_TINY_BUNDLE_COMMAND}"
        "${NPU_TINY_BUNDLE_WEIGHTS}"
        "${NPU_TINY_BUNDLE_METADATA}"
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${NPU_TINY_BUNDLE_DIR}"
    COMMAND "${CMAKE_COMMAND}" -E env
            PYTHONDONTWRITEBYTECODE=1
            "PYTHONPATH=${NPU_PROJECT_ROOT}"
            "${Python3_EXECUTABLE}" -m compiler.npu_compile
            "${NPU_PROJECT_ROOT}/compiler/fixtures/tiny_two_command_graph.json"
            --output-dir "${NPU_TINY_BUNDLE_DIR}"
    DEPENDS
        "${NPU_PROJECT_ROOT}/compiler/npu_artifact.py"
        "${NPU_PROJECT_ROOT}/compiler/npu_compile.py"
        "${NPU_PROJECT_ROOT}/compiler/fixtures/tiny_two_command_graph.json"
    WORKING_DIRECTORY "${NPU_PROJECT_ROOT}"
    COMMENT "Compiling deterministic two-command NPU test bundle"
    VERBATIM
)
add_custom_target(npu-tiny-compiled-bundle
    DEPENDS
        "${NPU_TINY_BUNDLE_COMMAND}"
        "${NPU_TINY_BUNDLE_WEIGHTS}"
        "${NPU_TINY_BUNDLE_METADATA}"
)

add_custom_target(check-npu-compiler-python
    COMMAND "${CMAKE_COMMAND}" -E env
            PYTHONDONTWRITEBYTECODE=1
            "PYTHONPATH=${NPU_PROJECT_ROOT}"
            "${Python3_EXECUTABLE}"
            "${NPU_PROJECT_ROOT}/tests/test_npu_compiler_artifacts.py"
    COMMAND "${CMAKE_COMMAND}" -E env
            PYTHONDONTWRITEBYTECODE=1
            "PYTHONPATH=${NPU_PROJECT_ROOT}"
            "${Python3_EXECUTABLE}"
            "${NPU_PROJECT_ROOT}/tests/test_qwen_graph_ir.py"
    COMMAND "${CMAKE_COMMAND}" -E env
            PYTHONDONTWRITEBYTECODE=1
            "PYTHONPATH=${NPU_PROJECT_ROOT}"
            "${Python3_EXECUTABLE}"
            "${NPU_PROJECT_ROOT}/tests/test_qwen_weights.py"
    COMMAND "${CMAKE_COMMAND}" -E env
            PYTHONDONTWRITEBYTECODE=1
            "PYTHONPATH=${NPU_PROJECT_ROOT}"
            "${Python3_EXECUTABLE}"
            "${NPU_PROJECT_ROOT}/tests/test_qwen_p00_lowering.py"
    COMMAND "${CMAKE_COMMAND}" -E env
            PYTHONDONTWRITEBYTECODE=1
            "PYTHONPATH=${NPU_PROJECT_ROOT}"
            "${Python3_EXECUTABLE}"
            "${NPU_PROJECT_ROOT}/tests/test_qwen_p00_codegen.py"
    DEPENDS
        "${NPU_PROJECT_ROOT}/compiler/npu_artifact.py"
        "${NPU_PROJECT_ROOT}/compiler/npu_compile.py"
        "${NPU_PROJECT_ROOT}/compiler/qwen_graph_ir.py"
        "${NPU_PROJECT_ROOT}/compiler/npu_ids.py"
        "${NPU_PROJECT_ROOT}/compiler/qwen_p00_codegen.py"
        "${NPU_PROJECT_ROOT}/compiler/qwen_p00_lowering.py"
        "${NPU_PROJECT_ROOT}/compiler/qwen_weights.py"
        "${NPU_PROJECT_ROOT}/tests/test_npu_compiler_artifacts.py"
        "${NPU_PROJECT_ROOT}/tests/test_qwen_graph_ir.py"
        "${NPU_PROJECT_ROOT}/tests/test_qwen_weights.py"
        "${NPU_PROJECT_ROOT}/tests/test_qwen_p00_lowering.py"
        "${NPU_PROJECT_ROOT}/tests/test_qwen_p00_codegen.py"
    WORKING_DIRECTORY "${NPU_PROJECT_ROOT}"
    COMMENT "Running NPU compiler artifact, GraphIR, GGUF weight, and exact P00 tests"
    VERBATIM
)

add_custom_target(check-npu-compiled-bundle
    COMMAND $<TARGET_FILE:test-npu-compiled-bundle>
            "${NPU_TINY_BUNDLE_DIR}"
    DEPENDS
        test-npu-compiled-bundle
        npu-tiny-compiled-bundle
    COMMENT "Checking compiled NPU bundle loading and relocation"
    VERBATIM
)

# Executor-injected behavioral test of provenance revalidation, private arena
# construction, automatic generations, exact compiler-owned contracts, and
# bundle-atomic output publication.  A trusted fake executor exercises failure
# after private output writes without booting SystemTop.
add_executable(test-npu-host-runtime EXCLUDE_FROM_ALL
    test-npu-host-runtime.cpp
)
add_dependencies(test-npu-host-runtime
    npu-tiny-compiled-bundle
)
target_compile_features(test-npu-host-runtime PRIVATE cxx_std_17)
target_compile_options(test-npu-host-runtime PRIVATE
    -O3 -DNDEBUG -Wall -Wextra -Wpedantic)
target_link_libraries(test-npu-host-runtime PRIVATE
    npu-host-runtime
)

add_custom_target(check-npu-host-runtime
    COMMAND $<TARGET_FILE:test-npu-host-runtime>
            "${NPU_TINY_BUNDLE_DIR}"
    DEPENDS test-npu-host-runtime
    COMMENT "Checking compiled-artifact Host Runtime atomicity"
    VERBATIM
)

# Production-path proof: the public Host Runtime API owns and reuses one real
# SystemTop/fixed-firmware session across two compiled-bundle generations.
# This target must not link the legacy per-transaction DPI runner.
add_executable(test-npu-host-runtime-system EXCLUDE_FROM_ALL
    test-npu-host-runtime-system.cpp
)
add_dependencies(test-npu-host-runtime-system
    npu-tiny-compiled-bundle
)
target_compile_features(test-npu-host-runtime-system PRIVATE cxx_std_17)
target_compile_options(test-npu-host-runtime-system PRIVATE
    -O3 -DNDEBUG -Wall -Wextra -Wpedantic)
target_link_libraries(test-npu-host-runtime-system PRIVATE
    npu-host-runtime
)

add_custom_target(check-npu-host-runtime-system
    COMMAND $<TARGET_FILE:test-npu-host-runtime-system>
            "${NPU_TINY_BUNDLE_DIR}"
    DEPENDS test-npu-host-runtime-system
    COMMENT "Running production Host Runtime persistent-SystemTop proof"
    VERBATIM
)

# End-to-end architecture proof: Python compiler artifact -> strict C++ Host
# Runtime relocation -> NC mailbox -> one fixed RV64 firmware instance ->
# production SystemTop/NPU F32 portal.  The reusable session owns its DPI
# callbacks, so this executable intentionally does not link npu-verilator-runner.
add_executable(test-npu-compiled-bundle-system EXCLUDE_FROM_ALL
    test-compiled-bundle-system.cpp
)
add_dependencies(test-npu-compiled-bundle-system
    npu-tiny-compiled-bundle
)
target_compile_features(test-npu-compiled-bundle-system PRIVATE cxx_std_17)
target_compile_options(test-npu-compiled-bundle-system PRIVATE
    -O3 -DNDEBUG -Wall -Wextra -Wpedantic)
target_link_libraries(test-npu-compiled-bundle-system PRIVATE
    npu-system-session
)

add_custom_target(check-npu-compiled-bundle-system
    COMMAND $<TARGET_FILE:test-npu-compiled-bundle-system>
            "${NPU_TINY_BUNDLE_DIR}"
    DEPENDS test-npu-compiled-bundle-system
    COMMENT "Running fixed-firmware compiled-bundle SystemTop proof"
    VERBATIM
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

# Compiled-artifact production backend.  Keep this DSO separate from the
# legacy profile-driven ggml-npu module: npu-host-runtime owns the persistent
# fixed-firmware SystemTop DPI callbacks, while npu-verilator-runner owns the
# incompatible per-transaction callbacks used by the legacy path.
add_library(ggml-npu-compiled MODULE
    ggml-npu-compiled.cpp
    npu-ggml-manifest.cpp
)
target_compile_features(ggml-npu-compiled PRIVATE cxx_std_17)
target_compile_definitions(ggml-npu-compiled PRIVATE
    GGML_BACKEND_DL
    GGML_BACKEND_BUILD
    GGML_BACKEND_SHARED
    GGML_SHARED
)
target_compile_options(ggml-npu-compiled PRIVATE
    -Wall -Wextra -Wpedantic)
target_include_directories(ggml-npu-compiled PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${LLAMA_SOURCE_DIR}/ggml/include"
    "${LLAMA_SOURCE_DIR}/ggml/src"
)
target_include_directories(ggml-npu-compiled SYSTEM PRIVATE "${LLAMA_SOURCE_DIR}/vendor")
target_link_libraries(ggml-npu-compiled PRIVATE
    ggml-base-pinned
    npu-host-runtime
)
set_target_properties(ggml-npu-compiled PROPERTIES
    OUTPUT_NAME "ggml-npu-compiled"
    BUILD_RPATH "${LLAMA_BUILD_BIN}"
)

# Load the compiled backend as a real GGML plugin so the test executable has
# no link-time access to backend/runtime implementation symbols.  The test
# drives the public plan API against the deterministic compiler-owned bundle.
add_executable(test-npu-compiled-backend EXCLUDE_FROM_ALL
    test-compiled-backend.cpp
)
add_dependencies(test-npu-compiled-backend
    ggml-npu-compiled
    npu-tiny-compiled-bundle
)
target_compile_features(test-npu-compiled-backend PRIVATE cxx_std_17)
target_compile_options(test-npu-compiled-backend PRIVATE
    -Wall -Wextra -Wpedantic)
target_include_directories(test-npu-compiled-backend PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${LLAMA_SOURCE_DIR}/ggml/include"
)
target_link_libraries(test-npu-compiled-backend PRIVATE
    ggml-pinned
    ggml-base-pinned
)
set_target_properties(test-npu-compiled-backend PROPERTIES
    BUILD_RPATH "${LLAMA_BUILD_BIN}"
)

add_custom_target(check-npu-compiled-backend
    COMMAND $<TARGET_FILE:test-npu-compiled-backend>
            $<TARGET_FILE:ggml-npu-compiled>
            "${NPU_TINY_BUNDLE_DIR}"
            "${LLAMA_BUILD_BIN}"
    DEPENDS
        test-npu-compiled-backend
        ggml-npu-compiled
        npu-tiny-compiled-bundle
    COMMENT "Checking compiled-artifact GGML backend integration"
    VERBATIM
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

# Exact canonical slice integration is explicit because it needs the original
# source manifest and GGUF. The default synthetic test remains model-independent.
set(NPU_COMPILED_CANONICAL_MANIFEST "" CACHE FILEPATH "Exact compiler source manifest")
set(NPU_COMPILED_CANONICAL_MODEL "" CACHE FILEPATH "GGUF used by the canonical compiler")
set(NPU_COMPILED_CANONICAL_NODE
    "1e3dac5ab4a21eb84d4d473de864ce2aa3129e1d4f248ee44d766549a51e6f3f"
    CACHE STRING "Canonical P00 slice to qualify")
set(NPU_CANONICAL_BUNDLE_DIR "${CMAKE_CURRENT_BINARY_DIR}/npu-canonical-bundle")
add_executable(test-npu-compiled-canonical EXCLUDE_FROM_ALL test-compiled-canonical.cpp)
target_compile_features(test-npu-compiled-canonical PRIVATE cxx_std_17)
target_compile_options(test-npu-compiled-canonical PRIVATE -Wall -Wextra -Wpedantic -ffp-contract=off)
target_include_directories(test-npu-compiled-canonical SYSTEM PRIVATE "${LLAMA_SOURCE_DIR}/vendor")
target_link_libraries(test-npu-compiled-canonical PRIVATE ggml-pinned ggml-base-pinned)
add_dependencies(test-npu-compiled-canonical ggml-npu-compiled)
set_target_properties(test-npu-compiled-canonical PROPERTIES BUILD_RPATH "${LLAMA_BUILD_BIN}")
add_custom_target(check-npu-compiled-canonical
    COMMAND "${CMAKE_COMMAND}" -E env PYTHONDONTWRITEBYTECODE=1
        "PYTHONPATH=${NPU_PROJECT_ROOT}" "${Python3_EXECUTABLE}" -m compiler.npu_compile
        --qwen-manifest "${NPU_COMPILED_CANONICAL_MANIFEST}"
        --canonical-node "${NPU_COMPILED_CANONICAL_NODE}"
        --model "${NPU_COMPILED_CANONICAL_MODEL}" --output-dir "${NPU_CANONICAL_BUNDLE_DIR}"
    COMMAND $<TARGET_FILE:test-npu-compiled-canonical> $<TARGET_FILE:ggml-npu-compiled>
        "${NPU_CANONICAL_BUNDLE_DIR}" "${NPU_COMPILED_CANONICAL_MANIFEST}"
    WORKING_DIRECTORY "${NPU_PROJECT_ROOT}"
    DEPENDS test-npu-compiled-canonical
    COMMENT "Checking exact-manifest compiled subgraph on persistent RV64 firmware"
    VERBATIM)

# Full-model quasi-offline compiler frontend; no legacy execution harness is linked.
add_library(ggml-npu-model MODULE
    ggml-npu-model.cpp
    npu-model-artifact.cpp
    "${NPU_PROJECT_ROOT}/compiler/npu-model-exact-profiles.cpp"
    "${NPU_PROJECT_ROOT}/compiler/npu-model-f32-profiles.cpp"
    "${NPU_PROJECT_ROOT}/compiler/npu-model-q8-profiles.cpp"
    "${NPU_PROJECT_ROOT}/compiler/npu-model-q8-gemv-profiles.cpp"
    "${NPU_PROJECT_ROOT}/compiler/npu-model-f32-mover-profiles.cpp"
    "${NPU_F32_ALU_GENERATED_HEADER}"
    "${NPU_Q8_GEMV_GENERATED_HEADER}"
    "${NPU_F32_MOVER_GENERATED_HEADER}"
    "${NPU_REMAINING_GENERATED_HEADER}"
    "${NPU_SAMPLER_ARGMAX_GENERATED_HEADER}")
add_dependencies(ggml-npu-model npu-f32-alu-generated npu-q8-gemv-generated
    npu-f32-mover-generated npu-remaining-generated npu-sampler-argmax-generated)
target_compile_features(ggml-npu-model PRIVATE cxx_std_17)
target_compile_definitions(ggml-npu-model PRIVATE GGML_BACKEND_DL GGML_BACKEND_BUILD GGML_BACKEND_SHARED GGML_SHARED)
target_compile_options(ggml-npu-model PRIVATE -O3 -Wall -Wextra -Wpedantic)
target_include_directories(ggml-npu-model PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}"
    "${NPU_Q8_GEMV_GENERATED_DIR}" "${LLAMA_SOURCE_DIR}/ggml/include" "${LLAMA_SOURCE_DIR}/ggml/src")
target_include_directories(ggml-npu-model SYSTEM PRIVATE "${LLAMA_SOURCE_DIR}/vendor")
target_link_libraries(ggml-npu-model PRIVATE ggml-base-pinned npu-system-session)
set_target_properties(ggml-npu-model PROPERTIES OUTPUT_NAME "ggml-npu-model" BUILD_RPATH "${LLAMA_BUILD_BIN}")

# The firmware's raw-copy engine: alignment, held requests, delayed responses,
# exact byte publication, overlap rejection, and read/write fault propagation.
find_program(NPU_IVERILOG_EXECUTABLE iverilog)
find_program(NPU_VVP_EXECUTABLE vvp)
if(NPU_IVERILOG_EXECUTABLE AND NPU_VVP_EXECUTABLE)
    add_custom_target(check-npu-service-dma
        COMMAND "${NPU_IVERILOG_EXECUTABLE}" -g2012 -s tb_service_dma
                -o "${CMAKE_CURRENT_BINARY_DIR}/test-service-dma.vvp"
                "${NPU_PROJECT_ROOT}/rtl/TensorNpuServiceDma.v"
                "${NPU_PROJECT_ROOT}/tests/tb_service_dma.sv"
        COMMAND "${NPU_VVP_EXECUTABLE}" "${CMAKE_CURRENT_BINARY_DIR}/test-service-dma.vvp"
        DEPENDS "${NPU_PROJECT_ROOT}/rtl/TensorNpuServiceDma.v"
                "${NPU_PROJECT_ROOT}/tests/tb_service_dma.sv"
        COMMENT "Checking the fixed firmware raw DMA transport"
        VERBATIM)
endif()

add_executable(test-npu-model-artifact EXCLUDE_FROM_ALL
    test-npu-model-artifact.cpp npu-model-artifact.cpp)
target_compile_features(test-npu-model-artifact PRIVATE cxx_std_17)
target_compile_options(test-npu-model-artifact PRIVATE -O3 -Wall -Wextra -Wpedantic)
target_include_directories(test-npu-model-artifact SYSTEM PRIVATE "${LLAMA_SOURCE_DIR}/vendor")
target_link_libraries(test-npu-model-artifact PRIVATE npu-system-session)
add_custom_target(check-npu-model-artifact
    COMMAND $<TARGET_FILE:test-npu-model-artifact> "${CMAKE_CURRENT_BINARY_DIR}"
    DEPENDS test-npu-model-artifact
    COMMENT "Checking model artifact integrity, DMA dependencies, atomic publication and precise recovery"
    VERBATIM)

# Optional focused check of the full model compiler's final command. This is
# component evidence only; the real token runner still requires both full graphs.
add_executable(test-npu-model-argmax EXCLUDE_FROM_ALL
    test-npu-model-argmax.cpp npu-model-artifact.cpp)
target_compile_features(test-npu-model-argmax PRIVATE cxx_std_17)
target_compile_options(test-npu-model-argmax PRIVATE -O3 -Wall -Wextra -Wpedantic)
target_include_directories(test-npu-model-argmax SYSTEM PRIVATE "${LLAMA_SOURCE_DIR}/vendor")
target_link_libraries(test-npu-model-argmax PRIVATE npu-system-session)
