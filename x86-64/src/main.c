#include <stdio.h>
#include <SDL2/SDL.h>
#include <stdlib.h>
#include "Cube.h"

#define SCREEN_WIDTH 512
#define SCREEN_HEIGHT 512
#define BMP_SIZE SCREEN_WIDTH*SCREEN_HEIGHT
#define CUBE_SIDE 100.0
#define CUBE_HALF_SIDE (CUBE_SIDE/2.0)

#define FRAME_TIME 10


extern int render(void *adr, unsigned int *output);

void handle_keys_down(SDL_Event event);

void handle_keys_up(SDL_Event event);

void calculate_new_frame();

volatile unsigned short int key_table[12] = {0};

unsigned int output[BMP_SIZE];

struct Cube cube = {
        .vertices={
                [0]={-CUBE_HALF_SIDE, CUBE_HALF_SIDE, CUBE_HALF_SIDE, 1},
                [1]={-CUBE_HALF_SIDE, -CUBE_HALF_SIDE, -CUBE_HALF_SIDE, 1},
                [2]={CUBE_HALF_SIDE, -CUBE_HALF_SIDE, CUBE_HALF_SIDE, 1},
                [3]={-CUBE_HALF_SIDE, -CUBE_HALF_SIDE, CUBE_HALF_SIDE, 1},
                [4]={CUBE_HALF_SIDE, -CUBE_HALF_SIDE, -CUBE_HALF_SIDE, 1},
                [5]={CUBE_HALF_SIDE, CUBE_HALF_SIDE, CUBE_HALF_SIDE, 1},
                [6]={-CUBE_HALF_SIDE, CUBE_HALF_SIDE, -CUBE_HALF_SIDE, 1},
                [7]={CUBE_HALF_SIDE, CUBE_HALF_SIDE, -CUBE_HALF_SIDE, 1},
        },
        .position_vector={0.0, 0.0, -200},
        .rotation_vector={0.0, 0.0, 0.0},
        .connections={
                [0]={0, 3}, [1]={0, 5}, [2]={0, 6}, [3]={1, 3}, [4]={1, 4}, [5]={1, 6},
                [6]={2, 3}, [7]={2, 4}, [8]={2, 5}, [9]={4, 7}, [10]={5, 7}, [11]={6, 7}
        },
        .walls={
                [0]={2,4,7,5},
                [1]={4,1,6,7},
                [2]={1,3,0,6},
                [3]={3,2,5,0},
                [4]={7,6,0,5},
                [5]={1,4,2,3}
        }
};

int main(int argc, char *argv[]) {
    render(&cube, output); // debug - useless here

    SDL_Event event;
    SDL_Window *window = NULL;
    SDL_Surface *screenSurface = NULL;
    SDL_Surface *gBMP;

    SDL_Init(SDL_INIT_VIDEO);

    window = SDL_CreateWindow("SDL window", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
                              SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);

    screenSurface = SDL_GetWindowSurface(window);

    unsigned int quit = 0;
    unsigned int last_frame = 0;

    while (!quit) {
        render(&cube, output);

        gBMP = SDL_CreateRGBSurfaceFrom((void*)output, 512, 512, 32, 4 * 512,0, 0, 0, 0);

        SDL_BlitSurface(gBMP, NULL, screenSurface, NULL);
        SDL_UpdateWindowSurface(window);
        last_frame = SDL_GetTicks();

        while (SDL_PollEvent(&event)) {
            switch (event.type) {
                case SDL_KEYDOWN:
                    if (event.key.keysym.scancode == SDL_SCANCODE_Q)
                        quit = 1;
                    else
                        handle_keys_down(event);
                    break;
                case SDL_KEYUP:
                    handle_keys_up(event);
                    break;
                default:
                    break;
            }
        }

        calculate_new_frame();
        SDL_FreeSurface(gBMP);
        memset(output, 0, BMP_SIZE * 4);
        if (SDL_GetTicks() - last_frame < FRAME_TIME)
            SDL_Delay(last_frame + FRAME_TIME - SDL_GetTicks());
    }

    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}

void calculate_new_frame() {
    const float pos_speed = 2;
    const float rot_speed = 0.025;
    cube.position_vector[0] = cube.position_vector[0] + pos_speed * (key_table[3] - key_table[1]);
    cube.position_vector[1] = cube.position_vector[1] + pos_speed * (key_table[0] - key_table[2]);
    cube.position_vector[2] = cube.position_vector[2] + pos_speed * (key_table[10] - key_table[8]);
    cube.rotation_vector[0] = cube.rotation_vector[0] + rot_speed * (key_table[4] - key_table[6]);
    cube.rotation_vector[1] = cube.rotation_vector[1] + rot_speed * (key_table[5] - key_table[7]);
    cube.rotation_vector[2] = cube.rotation_vector[2] + rot_speed * (key_table[11] - key_table[9]);
}


void handle_keys_up(SDL_Event event) {
    switch (event.key.keysym.scancode) {
        case SDL_SCANCODE_W:
            key_table[0] = 0;
            break;
        case SDL_SCANCODE_A:
            key_table[1] = 0;
            break;
        case SDL_SCANCODE_S:
            key_table[2] = 0;
            break;
        case SDL_SCANCODE_D:
            key_table[3] = 0;
            break;
        case SDL_SCANCODE_I:
            key_table[4] = 0;
            break;
        case SDL_SCANCODE_J:
            key_table[5] = 0;
            break;
        case SDL_SCANCODE_K:
            key_table[6] = 0;
            break;
        case SDL_SCANCODE_L:
            key_table[7] = 0;
            break;
        case SDL_SCANCODE_T:
            key_table[8] = 0;
            break;
        case SDL_SCANCODE_F:
            key_table[9] = 0;
            break;
        case SDL_SCANCODE_G:
            key_table[10] = 0;
            break;
        case SDL_SCANCODE_H:
            key_table[11] = 0;
            break;
        default:
            break;
    }
}

void handle_keys_down(SDL_Event event) {
    switch (event.key.keysym.scancode) {
        case SDL_SCANCODE_W:
            key_table[0] = 1;
            break;
        case SDL_SCANCODE_A:
            key_table[1] = 1;
            break;
        case SDL_SCANCODE_S:
            key_table[2] = 1;
            break;
        case SDL_SCANCODE_D:
            key_table[3] = 1;
            break;
        case SDL_SCANCODE_I:
            key_table[4] = 1;
            break;
        case SDL_SCANCODE_J:
            key_table[5] = 1;
            break;
        case SDL_SCANCODE_K:
            key_table[6] = 1;
            break;
        case SDL_SCANCODE_L:
            key_table[7] = 1;
            break;
        case SDL_SCANCODE_T:
            key_table[8] = 1;
            break;
        case SDL_SCANCODE_F:
            key_table[9] = 1;
            break;
        case SDL_SCANCODE_G:
            key_table[10] = 1;
            break;
        case SDL_SCANCODE_H:
            key_table[11] = 1;
            break;
        default:
            break;
    }
}