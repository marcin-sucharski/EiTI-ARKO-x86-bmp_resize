#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include "scale_image.h"

int main(int argc, char *argv[]) {
	if (argc != 2) {
		fprintf(stderr, "Use: perftest <test_size>\n");
		return 1;
	}

	const int TEST_SIZE_SRC = atoi(argv[1]);
	const int TEST_SIZE_DST = TEST_SIZE_SRC * 2;
	image_data src = {
		.ptr = malloc(TEST_SIZE_SRC * TEST_SIZE_SRC * 4),
		.width = TEST_SIZE_SRC,
		.height = TEST_SIZE_SRC
	};
	image_data dst = {
		.ptr = malloc(TEST_SIZE_DST * TEST_SIZE_DST * 4),
		.width = TEST_SIZE_DST,
		.height = TEST_SIZE_DST
	};

	for (int i = 0; i < TEST_SIZE_SRC * TEST_SIZE_SRC; ++i) {
		((int32_t*)src.ptr)[i] = i;
	}
	for (int i = 0; i < TEST_SIZE_DST * TEST_SIZE_DST; ++i) {
		((int32_t*)dst.ptr)[i] = i;
	}

	const int REPEAT_COUNT = 512;
	for (int i = 0; i < REPEAT_COUNT; ++i) {
		scale_image(&src, &dst);
	}

	free(dst.ptr);
	free(src.ptr);
	return 0;
}
