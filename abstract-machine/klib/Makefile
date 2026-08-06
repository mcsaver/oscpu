ifeq ($(AM_LIBRARY_RECURSIVE),1)
override NAME := klib
override SRCS = $(shell find src/ -name "*.c")
else
NAME = klib
SRCS = $(shell find src/ -name "*.c")
endif
include $(AM_HOME)/Makefile
