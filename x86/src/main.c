#include <stdio.h>
#include <SDL2/SDL.h>
#include "../include/Cube.h"

#define BMP_SIZE 786486
#define SCREEN_WIDTH 512
#define SCREEN_HEIGHT 512
#define CUBE_SIDE 100.0
#define CUBE_HALF_SIDE (CUBE_SIDE/2)


extern int render(void *adr, unsigned char *output);

unsigned char output[BMP_SIZE] = {0x42, 0x4d, 0x36, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x36, 0x00, 0x00, 0x00,
                                  0x28, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x01, 0x00,
                                  0x18, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00,
                                  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

struct Cube cube = {
        .vertices={
                [0]={CUBE_HALF_SIDE, CUBE_HALF_SIDE, CUBE_HALF_SIDE, 1},
                [1]={CUBE_HALF_SIDE, CUBE_HALF_SIDE, -CUBE_HALF_SIDE, 1},
                [2]={CUBE_HALF_SIDE, -CUBE_HALF_SIDE, CUBE_HALF_SIDE, 1},
                [3]={CUBE_HALF_SIDE, -CUBE_HALF_SIDE, -CUBE_HALF_SIDE, 1},
                [4]={-CUBE_HALF_SIDE, CUBE_HALF_SIDE, CUBE_HALF_SIDE, 1},
                [5]={-CUBE_HALF_SIDE, CUBE_HALF_SIDE, -CUBE_HALF_SIDE, 1},
                [6]={-CUBE_HALF_SIDE, -CUBE_HALF_SIDE, CUBE_HALF_SIDE, 1},
                [7]={-CUBE_HALF_SIDE, -CUBE_HALF_SIDE, -CUBE_HALF_SIDE, 1},
        },
        .position_vector={0.0, 0.0, -100},
        .rotation_vector={0.0, 0.0, 0.0}
};


int main(int argc, char *argv[]) {
    render(&cube, output);


    SDL_Window *window = NULL;
    SDL_Surface *screenSurface = NULL;

    SDL_Surface *gBMP = SDL_LoadBMP_RW(SDL_RWFromConstMem(output, BMP_SIZE), 1);

    SDL_Init(SDL_INIT_VIDEO);

    window = SDL_CreateWindow("SDL window", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
                              SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);

    screenSurface = SDL_GetWindowSurface(window);

    //loop start
    for (int i = 0; i < 100; i++) {
        render(&cube, output);
        gBMP = SDL_LoadBMP_RW(SDL_RWFromConstMem(output, BMP_SIZE), 1);
        SDL_BlitSurface(gBMP, NULL, screenSurface, NULL);
        SDL_UpdateWindowSurface(window);
        SDL_Delay(1000);
    }
    //loop end

    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}