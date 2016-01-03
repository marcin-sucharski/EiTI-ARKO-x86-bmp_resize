CC=gcc
CFLAGS=-Wall -Wextra

ASM=nasm
AFLAGS=-f elf64

all: resize perftest

main.o: main.c
	$(CC) $(CFLAGS) -c main.c
func.o: func.nasm
	$(ASM) $(AFLAGS) func.nasm
resize: main.o func.o
	$(CC) $(CFLAGS) main.o func.o -lSDL2 -o resize
perftest: perftest.o func.o
	$(CC) $(CFLAGS) perftest.o func.o -o perftest
clean: 
	rm -f *.o
	rm -f resize
	rm -f perftest
