task_dir := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
repo_root := $(abspath $(task_dir)/../../../..)

NAME = ooo-dual-memory-stress
SRCS = $(task_dir)/ooo-dual-memory-stress.c
INC_PATH += $(repo_root)/am-kernels/tests/cpu-tests/include
AM_HOME ?= $(repo_root)/abstract-machine
export AM_HOME

include $(AM_HOME)/Makefile
