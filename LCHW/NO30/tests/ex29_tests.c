#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>

typedef int (*lib_function)(const char *data);

static void fail_msg(const char *msg, void *lib) {
    if (lib) dlclose(lib);
    fprintf(stderr, "%s\n", msg);
    exit(1);
}

int main(void)
{
    const char *lib_path = "build/libex29.so";
    void *lib = dlopen(lib_path, RTLD_NOW);
    if (!lib) {
        fprintf(stderr, "dlopen(%s) error: %s\n", lib_path, dlerror());
        return 1;
    }

    dlerror(); /* clear */

    lib_function print_a_message = (lib_function)dlsym(lib, "print_a_message");
    if (!print_a_message) fail_msg("dlsym print_a_message failed", lib);

    lib_function uppercase = (lib_function)dlsym(lib, "uppercase");
    if (!uppercase) fail_msg("dlsym uppercase failed", lib);

    lib_function lowercase = (lib_function)dlsym(lib, "lowercase");
    if (!lowercase) fail_msg("dlsym lowercase failed", lib);

    lib_function fail_on_purpose = (lib_function)dlsym(lib, "fail_on_purpose");
    if (!fail_on_purpose) fail_msg("dlsym fail_on_purpose failed", lib);

    /* run tests similar to examples */
    if (print_a_message("hello there") != 0) fail_msg("print_a_message returned non-zero", lib);
    if (uppercase("hello there") != 0) fail_msg("uppercase returned non-zero", lib);
    if (lowercase("HELLO THERE") != 0) fail_msg("lowercase returned non-zero", lib);

    /* expected to fail */
    if (fail_on_purpose("i fail") == 0) fail_msg("fail_on_purpose returned 0 but expected non-zero", lib);

    if (dlclose(lib) != 0) {
        fprintf(stderr, "dlclose failed\n");
        return 1;
    }

    printf("ex29_tests: ALL PASSED\n");
    return 0;
}