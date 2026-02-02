CC=gcc
CFLAGS=-Wall -g 

SRCS = ex22_main.c ex22.c
OBJS = ex22_main.o ex22.o
TARGET = ex22_main

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS)

ex22_main.o: ex22_main.c ex22.h dbg.h
	$(CC) $(CFLAGS) -c ex22_main.c

ex22.o: ex22.c dbg.h ex22.h
	$(CC) $(CFLAGS) -c ex22.c

clean:
	rm -f $(TARGET) *.o

.PHONY: all clean
