CC=gcc
CFLAGS=-Wall -g 

SRCS = ex25.c
OBJS = ex25.o
TARGET = ex25

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS)

ex25.o: ex25.c dbg.h 
	$(CC) $(CFLAGS) -c ex25.c

clean:
	rm -f $(TARGET) *.o

.PHONY: all clean
