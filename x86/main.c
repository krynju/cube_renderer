#include <stdio.h>

extern int render(char *a);

char output_str[] = "Hello, world";

int main() {
    printf("Hello, World!\n");

    render(output_str);
    printf("%s", output_str);
    return 0;
}