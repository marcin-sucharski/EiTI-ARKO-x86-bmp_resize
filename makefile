CC=gcc
CFLAGS=-O2 -Wall -Wextra

ASM=nasm
AFLAGS=-f elf64

all:resize

main.o: main.c
	$(CC) $(CFLAGS) -c main.c
func.o: func.nasm
	$(ASM) $(AFLAGS) func.nasm
resize: main.o func.o
	$(CC) $(CFLAGS) main.o func.o -lSDL2 -o resize
clean: 
	rm -f *.o
	rm -f resize
