#ifndef CUBE_RENDERER_CUBE_H
#define CUBE_RENDERER_CUBE_H

struct Point {
    float position_vector[4];
};

struct Connection {
    unsigned int from;
    unsigned int to;
};


struct Cube {
    struct Point vertices[8];
    float position_vector[3];
    float rotation_vector[3];
    struct Connection connections[12];
}__attribute__ ((aligned (16)));


#endif //CUBE_RENDERER_CUBE_H
