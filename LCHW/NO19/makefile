CC=gcc
CFLAGS=-Wall -g

SRCS = ex19.c object.c
OBJS = ex19.o object.o
TARGET = ex19

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS)

ex19.o: ex19.c ex19.h object.h
	$(CC) $(CFLAGS) -c ex19.c

object.o: object.c object.h
	$(CC) $(CFLAGS) -c object.c

test: all
	@bash run_tests.sh

clean:
	rm -f $(TARGET) *.o test_output_*.txt

.PHONY: all test clean