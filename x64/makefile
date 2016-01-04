CC=gcc
CFLAGS=-Wall -Wextra

ASM=nasm
AFLAGS=-f elf64

all: resize perftest

main.o: ../common/main.c
	$(CC) $(CFLAGS) -c ../common/main.c
perftest.o: ../common/perftest.c
	$(CC) $(CFLAGS) -c ../common/perftest.c
scale_image.o: scale_image.nasm
	$(ASM) $(AFLAGS) scale_image.nasm
resize: main.o scale_image.o
	$(CC) $(CFLAGS) main.o scale_image.o -lSDL2 -o resize
perftest: perftest.o scale_image.o
	$(CC) $(CFLAGS) perftest.o scale_image.o -o perftest
clean: 
	rm -f *.o
	rm -f resize
	rm -f perftest
