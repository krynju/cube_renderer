#ifndef CUBE_RENDERER_CUBE_H
#define CUBE_RENDERER_CUBE_H

struct Point {
    float position_vector[4];
};

struct Cube {
    struct Point vertices[8];
    float position_vector[3];
    float rotation_vector[3];
}__attribute__ ((aligned (16)));


#endif //CUBE_RENDERER_CUBE_H
