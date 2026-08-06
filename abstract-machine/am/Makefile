ifeq ($(AM_LIBRARY_RECURSIVE),1)
override NAME := am
override SRCS = $(addprefix src/, $(AM_SRCS))
else
NAME     := am
SRCS      = $(addprefix src/, $(AM_SRCS))
endif
INC_PATH += $(AM_HOME)/am/src

include $(AM_HOME)/Makefile
