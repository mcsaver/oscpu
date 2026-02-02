CC=gcc
CFLAGS=-Wall -g -DNDEBUG

SRCS = ex20.c
OBJS = ex20.o
TARGET = ex20

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS)

ex20.o: ex20.c dbg.h
	$(CC) $(CFLAGS) -c ex20.c

clean:
	rm -f $(TARGET) *.o

.PHONY: all clean
