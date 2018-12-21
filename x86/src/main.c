#include <stdio.h>
#include <SDL2/SDL.h>
#include <SDL2/SDL_vulkan.h>

#define BMP_SIZE 786486
#define SCREEN_WIDTH 512
#define SCREEN_HEIGHT 512

extern int render(unsigned char *input, unsigned char *output);

char output_str[] = "Hello, world";
unsigned char input[BMP_SIZE];
unsigned char output[BMP_SIZE];


int main(int argc, char *argv[]) {
    //<temporary>
    FILE *bmp = fopen("../res/test_bitmap.bmp", "r");
    unsigned int i = 0;
    int c = getc(bmp);
    while (c != EOF) {
        input[i] = (unsigned char) c;
        ++i;
        c = getc(bmp);
    }
    fclose(bmp);
    //</temporary>

    render(input, output);


    SDL_Window *window = NULL;
    SDL_Surface *screenSurface = NULL;

    SDL_Surface *gBMP = SDL_LoadBMP_RW(SDL_RWFromConstMem(output, BMP_SIZE), 1);

    SDL_Init(SDL_INIT_VIDEO);

    window = SDL_CreateWindow("SDL window", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
                              SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);

    screenSurface = SDL_GetWindowSurface(window);

    //loop start
    SDL_BlitSurface(gBMP, NULL, screenSurface, NULL);
    SDL_UpdateWindowSurface(window);
    SDL_Delay(2000);
    //loop end

    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}