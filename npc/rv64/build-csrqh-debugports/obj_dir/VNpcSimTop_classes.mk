# Verilated -*- Makefile -*-
# DESCRIPTION: Verilator output: Make include file with class lists
#
# This file lists generated Verilated files, for including in higher level makefiles.
# See VNpcSimTop.mk for the caller.

### Switches...
# C11 constructs required?  0/1 (always on now)
VM_C11 = 1
# Timing enabled?  0/1
VM_TIMING = 0
# Coverage output mode?  0/1 (from --coverage)
VM_COVERAGE = 0
# Parallel builds?  0/1 (from --output-split)
VM_PARALLEL_BUILDS = 1
# Tracing output mode?  0/1 (from --trace/--trace-fst)
VM_TRACE = 0
# Tracing output mode in VCD format?  0/1 (from --trace)
VM_TRACE_VCD = 0
# Tracing output mode in FST format?  0/1 (from --trace-fst)
VM_TRACE_FST = 0

### Object file lists...
# Generated module classes, fast-path, compile with highest optimization
VM_CLASSES_FAST += \
	VNpcSimTop \
	VNpcSimTop___024root__DepSet_h00145668__0 \
	VNpcSimTop___024root__DepSet_h00145668__1 \
	VNpcSimTop___024root__DepSet_h00145668__2 \
	VNpcSimTop___024root__DepSet_h00145668__3 \
	VNpcSimTop___024root__DepSet_h00145668__4 \
	VNpcSimTop___024root__DepSet_h00145668__5 \
	VNpcSimTop___024root__DepSet_h00145668__6 \
	VNpcSimTop___024root__DepSet_h00145668__7 \
	VNpcSimTop___024root__DepSet_hcadfbd6d__0 \
	VNpcSimTop___024root__DepSet_hcadfbd6d__1 \
	VNpcSimTop___024root__DepSet_hcadfbd6d__2 \
	VNpcSimTop___024root__DepSet_hcadfbd6d__3 \
	VNpcSimTop___024root__DepSet_hcadfbd6d__4 \
	VNpcSimTop___024root__DepSet_hcadfbd6d__5 \
	VNpcSimTop___024root__DepSet_hcadfbd6d__6 \
	VNpcSimTop___024root__DepSet_hcadfbd6d__7 \
	VNpcSimTop___024root__DepSet_hcadfbd6d__8 \
	VNpcSimTop___024root__DepSet_hcadfbd6d__9 \
	VNpcSimTop___024root__DepSet_hcadfbd6d__10 \
	VNpcSimTop___024root__DepSet_hcadfbd6d__11 \
	VNpcSimTop___024root__DepSet_hcadfbd6d__12 \
	VNpcSimTop___024root__DepSet_hcadfbd6d__13 \
	VNpcSimTop___024root__DepSet_hcadfbd6d__14 \
	VNpcSimTop___024root__DepSet_hcadfbd6d__15 \
	VNpcSimTop___024unit__DepSet_h4c0d1c9b__0 \

# Generated module classes, non-fast-path, compile with low/medium optimization
VM_CLASSES_SLOW += \
	VNpcSimTop__ConstPool_0 \
	VNpcSimTop___024root__Slow \
	VNpcSimTop___024root__DepSet_h00145668__0__Slow \
	VNpcSimTop___024root__DepSet_hcadfbd6d__0__Slow \
	VNpcSimTop___024root__DepSet_hcadfbd6d__1__Slow \
	VNpcSimTop___024root__DepSet_hcadfbd6d__2__Slow \
	VNpcSimTop___024root__DepSet_hcadfbd6d__3__Slow \
	VNpcSimTop___024root__DepSet_hcadfbd6d__4__Slow \
	VNpcSimTop___024root__DepSet_hcadfbd6d__5__Slow \
	VNpcSimTop___024root__DepSet_hcadfbd6d__6__Slow \
	VNpcSimTop___024root__DepSet_hcadfbd6d__7__Slow \
	VNpcSimTop___024root__DepSet_hcadfbd6d__8__Slow \
	VNpcSimTop___024root__DepSet_hcadfbd6d__9__Slow \
	VNpcSimTop___024root__DepSet_hcadfbd6d__10__Slow \
	VNpcSimTop___024root__DepSet_hcadfbd6d__11__Slow \
	VNpcSimTop___024unit__Slow \
	VNpcSimTop___024unit__DepSet_h96e6737a__0__Slow \

# Generated support classes, fast-path, compile with highest optimization
VM_SUPPORT_FAST += \
	VNpcSimTop__Dpi \

# Generated support classes, non-fast-path, compile with low/medium optimization
VM_SUPPORT_SLOW += \
	VNpcSimTop__Syms \

# Global classes, need linked once per executable, fast-path, compile with highest optimization
VM_GLOBAL_FAST += \
	verilated \
	verilated_dpi \
	verilated_threads \

# Global classes, need linked once per executable, non-fast-path, compile with low/medium optimization
VM_GLOBAL_SLOW += \


# Verilated -*- Makefile -*-
