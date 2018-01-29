#include "stdio.h"
int main (int argc, char** argv, char** env) {
    for (int i = 0; env[i]; i++) {
        printf("env[%d] = >>>%s<<<\n", i, env[i]);
    }
    if (!argc) {
        printf("hello world\n");
        return 0;
    }
    char hello[32];
    snprintf(hello, 32, "hello %s", argv[0]);
    printf("The stack is at [%p]\n", hello);
    //char* memory_start = &argv[0];
    for (int i = 0; i < argc; i++) {
        printf("argv %d = '%s' (%p)\n", i, argv[i], argv[i]);
    }
    sleep(2000);
}
