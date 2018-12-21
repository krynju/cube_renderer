cmake_minimum_required(VERSION 3.13)
project(cube_renderer C)
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/)

set(CMAKE_C_STANDARD 11)
find_package(SDL2 REQUIRED)
include_directories(${SDL2_INCLUDE_DIR})


enable_language(ASM-NASM)


set(CMAKE_ASM-NASM_FLAGS "-f elf32 -g")
set(CMAKE_C_FLAGS "-m32 -o0 -g")

add_executable(cube_renderer main.c render.asm)
target_link_libraries(cube_renderer ${SDL2_LIBRARY})

