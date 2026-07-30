# Verilated -*- Makefile -*-
# DESCRIPTION: Verilator output: Makefile for building Verilated archive or executable
#
# Execute this makefile from the object directory:
#    make -f VNpcSimTop.mk

default: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure/product-default-a3-toolchain-build/NpcSimTop

### Constants...
# Perl executable (from $PERL)
PERL = perl
# Path to Verilator kit (from $VERILATOR_ROOT)
VERILATOR_ROOT = /usr/share/verilator
# SystemC include directory with systemc.h (from $SYSTEMC_INCLUDE)
SYSTEMC_INCLUDE ?= 
# SystemC library directory with libsystemc.a (from $SYSTEMC_LIBDIR)
SYSTEMC_LIBDIR ?= 

### Switches...
# C++ code coverage  0/1 (from --prof-c)
VM_PROFC = 0
# SystemC output mode?  0/1 (from --sc)
VM_SC = 0
# Legacy or SystemC output mode?  0/1 (from --sc)
VM_SP_OR_SC = $(VM_SC)
# Deprecated
VM_PCLI = 1
# Deprecated: SystemC architecture to find link library path (from $SYSTEMC_ARCH)
VM_SC_TARGET_ARCH = linux

### Vars...
# Design prefix (from --prefix)
VM_PREFIX = VNpcSimTop
# Module prefix (from --prefix)
VM_MODPREFIX = VNpcSimTop
# User CFLAGS (from -CFLAGS on Verilator command line)
VM_USER_CFLAGS = \
	-DNPC_DEFAULT_DIFF_SO=\"/home/lyg/PA/ysyx-workbench/nemu/build/riscv64-nemu-interpreter-so\" \
	-DNPC_HAS_SDL=1 \
	-I/usr/include/SDL2 \
	-D_REENTRANT \
	-O3 \
	-DNPC_XLEN=64 \
	-DNPC_GUEST_ISA_RV64=1 \
	-I/home/lyg/PA/ysyx-workbench/npc/rv64/csrc/include \
	-I/home/lyg/PA/ysyx-workbench/nemu/tools/capstone/repo/include \
	-include \
	/home/lyg/PA/ysyx-workbench/npc/rv64/include/generated/autoconf.h \

# User LDLIBS (from -LDFLAGS on Verilator command line)
VM_USER_LDLIBS = \
	-ldl \
	-lSDL2 \

# User .cpp files (from .cpp's on Verilator command line)
VM_USER_CLASSES = \
	cpu-exec \
	difftest \
	device \
	keyboard \
	map \
	timer \
	vga \
	virtio_blk \
	dpi \
	main \
	paddr \
	disasm \
	expr \
	log \
	monitor \
	sdb \
	trace \
	watchpoint \
	utils \

# User .cpp directories (from .cpp's on Verilator command line)
VM_USER_DIR = \
	/home/lyg/PA/ysyx-workbench/npc/rv64/csrc \
	/home/lyg/PA/ysyx-workbench/npc/rv64/csrc/cpu \
	/home/lyg/PA/ysyx-workbench/npc/rv64/csrc/device \
	/home/lyg/PA/ysyx-workbench/npc/rv64/csrc/memory \
	/home/lyg/PA/ysyx-workbench/npc/rv64/csrc/monitor \


### Default rules...
# Include list of all generated classes
include VNpcSimTop_classes.mk
# Include global rules
include $(VERILATOR_ROOT)/include/verilated.mk

### Executable rules... (from --exe)
VPATH += $(VM_USER_DIR)

cpu-exec.o: /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/cpu/cpu-exec.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
difftest.o: /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/cpu/difftest.cpp
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
device.o: /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/device/device.c
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
keyboard.o: /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/device/keyboard.c
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
map.o: /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/device/map.c
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
timer.o: /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/device/timer.c
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
vga.o: /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/device/vga.c
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
virtio_blk.o: /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/device/virtio_blk.c
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
dpi.o: /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/dpi.c
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
main.o: /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/main.c
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
paddr.o: /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/memory/paddr.c
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
disasm.o: /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/monitor/disasm.c
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
expr.o: /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/monitor/expr.c
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
log.o: /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/monitor/log.c
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
monitor.o: /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/monitor/monitor.c
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
sdb.o: /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/monitor/sdb.c
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
trace.o: /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/monitor/trace.c
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
watchpoint.o: /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/monitor/watchpoint.c
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<
utils.o: /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/utils.c
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST) -c -o $@ $<

### Link rules... (from --exe)
/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure/product-default-a3-toolchain-build/NpcSimTop: $(VK_USER_OBJS) $(VK_GLOBAL_OBJS) $(VM_PREFIX)__ALL.a $(VM_HIER_LIBS)
	$(LINK) $(LDFLAGS) $^ $(LOADLIBES) $(LDLIBS) $(LIBS) $(SC_LIBS) -o $@


# Verilated -*- Makefile -*-
