#include <stdio.h>
#include <SDL2/SDL.h>
#include "../include/Cube.h"

#define BMP_SIZE 786486
#define SCREEN_WIDTH 512
#define SCREEN_HEIGHT 512
#define CUBE_SIDE 100.0
#define CUBE_HALF_SIDE (CUBE_SIDE/2)


extern int render(unsigned char *input, unsigned char *output);

unsigned char input[BMP_SIZE];
unsigned char output[BMP_SIZE];

struct Cube cube = {
        .position_vector={0.0, 0.0, 0.0},
        .rotation_vector={0.0, 0.0, 0.0},
        .vertices={
                [0]={CUBE_HALF_SIDE, CUBE_HALF_SIDE, CUBE_HALF_SIDE},
                [1]={CUBE_HALF_SIDE, CUBE_HALF_SIDE, -CUBE_HALF_SIDE},
                [2]={CUBE_HALF_SIDE, -CUBE_HALF_SIDE, CUBE_HALF_SIDE},
                [3]={CUBE_HALF_SIDE, -CUBE_HALF_SIDE, -CUBE_HALF_SIDE},
                [4]={-CUBE_HALF_SIDE, CUBE_HALF_SIDE, CUBE_HALF_SIDE},
                [5]={-CUBE_HALF_SIDE, CUBE_HALF_SIDE, -CUBE_HALF_SIDE},
                [6]={-CUBE_HALF_SIDE, -CUBE_HALF_SIDE, CUBE_HALF_SIDE},
                [7]={-CUBE_HALF_SIDE, -CUBE_HALF_SIDE, -CUBE_HALF_SIDE},
        }
};


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