#include <stdio.h>
#include <SDL2/SDL.h>

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

const int SCREEN_WIDTH = 640;
const int SCREEN_HEIGHT = 480;

int main(int argc, char** argv) {
	SDL_Window *window = NULL;
	SDL_Surface *image = NULL;
	SDL_Event event;
	int isRunning = 1;

	if (argc != 2) {
		fprintf(stderr, "Usage: resize \"path/to/image\"");
		goto cleanup;
	}

	if (SDL_Init(SDL_INIT_VIDEO) < 0) {
		fprintf(stderr, "Failed to initialize SDL; Error: %s\n", SDL_GetError());
		goto cleanup;
	}

	window = SDL_CreateWindow(
		"Resize image",
		SDL_WINDOWPOS_UNDEFINED,
		SDL_WINDOWPOS_UNDEFINED,
		SCREEN_WIDTH,
		SCREEN_HEIGHT,
		SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE);

	if (!window) {
		fprintf(stderr, "Failed to create window; Error: %s\n", SDL_GetError());
		goto cleanup;
	}

	image = SDL_LoadBMP(argv[1]);
	if (!image) {
		fprintf(stderr, "Failed to load image; Error: %s\n", SDL_GetError());
		goto cleanup;
	}


	SDL_PixelFormat fmt = { 0 };
	fmt.format = SDL_PIXELFORMAT_RGBA8888;
	fmt.BitsPerPixel = 32;
	fmt.BytesPerPixel = 4;
	SDL_Surface *temp = SDL_ConvertSurface(image, &fmt, 0);
	SDL_FreeSurface(image);
	image = temp;

	SDL_SetWindowSize(window, SCREEN_WIDTH, SCREEN_HEIGHT);
	while (isRunning) {
		while (SDL_PollEvent(&event)) {
			switch (event.type) {
			case SDL_QUIT:
				isRunning = 0;
				break;

			case SDL_WINDOWEVENT:
				if (event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED) {
					SDL_Surface *surface = SDL_GetWindowSurface(window);
					image_data src = {image->pixels, image->w, image->h};
					image_data dst = {surface->pixels, surface->w, surface->h};
					scale_image(&src, &dst);
					SDL_UpdateWindowSurface(window);
				}
				break;
			}
		}
		SDL_Delay(1);
	}

cleanup:
	if (image) {
		SDL_FreeSurface(image);
	}
	if (window) {
		SDL_DestroyWindow(window);
	}
	SDL_Quit();
	return 0;
}
