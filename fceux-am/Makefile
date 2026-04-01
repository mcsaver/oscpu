NAME = fceux

ROM_PATH  = ./nes
ROM_GEN_HDR = $(ROM_PATH)/gen/roms.h
ROMS      = $(wildcard $(ROM_PATH)/rom/*.nes)
ROM_SRC   = $(patsubst $(ROM_PATH)/rom/%.nes,$(ROM_PATH)/gen/%.c,$(ROMS))
FCEUX_SRC = $(shell find -L src/ -name "*.c" -o -name "*.cpp")

INC_PATH  = $(ROM_PATH)/gen/
SRCS      = $(FCEUX_SRC) $(ROM_SRC)
CFLAGS    = -DPSS_STYLE=1 -DFRAMESKIP -D__NO_FILE_SYSTEM__

include $(AM_HOME)/Makefile

$(FCEUX_SRC): rom $(ROM_SRC)
$(ROM_SRC): rom
.PHONY: rom
rom:
	@-cd $(ROM_PATH) && python3 build-roms.py

clean: myclean

myclean:
	-rm -rf ./nes/gen
