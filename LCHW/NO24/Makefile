CC=gcc
CFLAGS=-Wall -g 

SRCS = ex24.c
OBJS = ex24.o
TARGET = ex24

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS)

ex24.o: ex24.c dbg.h 
	$(CC) $(CFLAGS) -c ex24.c

clean:
	rm -f $(TARGET) *.o

.PHONY: all clean
