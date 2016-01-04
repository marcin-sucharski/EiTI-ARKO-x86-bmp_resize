CC=gcc
CFLAGS=-Wall -Wextra -m32

ASM=nasm
AFLAGS=-f elf32

all: resize perftest

main.o: ../common/main.c
	$(CC) $(CFLAGS) -c ../common/main.c
perftest.o: ../common/perftest.c
	$(CC) $(CFLAGS) -c ../common/perftest.c
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
