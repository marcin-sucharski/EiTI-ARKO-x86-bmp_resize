#ifndef SCALE_IMAGE_H
#define SCALE_IMAGE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif
	typedef struct image_data_t {
		void *ptr;
		int32_t width;
		int32_t height;
	} image_data;

	void scale_image(
		const image_data *src,
		image_data *dst);
#ifdef __cplusplus
}
#endif

#endif // SCALE_IMAGE_H
