#ifndef CUBE_RENDERER_CUBE_H
#define CUBE_RENDERER_CUBE_H

struct Point {
    float position_vector[3];
};

struct Cube {
    float position_vector[3];
    float rotation_vector[3];
    struct Point vertices[8];
};


#endif //CUBE_RENDERER_CUBE_H
