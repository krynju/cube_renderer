cmake_minimum_required(VERSION 3.10.2)
project(cube_renderer C)

set(CMAKE_C_STANDARD 11)

set(CMAKE_C_FLAGS "-march=native")

set(CAN_USE_ASSEMBLER TRUE)
set(CMAKE_ASM_NASM_OBJECT_FORMAT win64)
set(CMAKE_ASM_NASM_FLAGS_DEBUG "-g")
enable_language(ASM_NASM)

find_package(SDL2 REQUIRED)
include_directories(${SDL2_INCLUDE_DIR} include)
add_executable(cube_renderer src/main.c src/render.asm include/Cube.h)
target_link_libraries(cube_renderer ${SDL2_LIBRARIES})
