#include<stdio.h>
#include"ex22.h"
#include"dbg.h"

int THE_SIZE = 1000;

/* We keep a file-scope pointer that will be set to point at the function-local
 * static `ratio` inside update_ratio on first call. This lets external code
 * obtain the address via get_ratio_ptr() after update_ratio has run at least
 * once. */
static double *ratio_addr = NULL;

static int THE_AGE = 37;

int get_age()
{
    return THE_AGE;
}

void set_age(int age)
{
    THE_AGE = age;
}

double update_ratio(double new_ratio)
{
    static double ratio = 1.0;

    if (ratio_addr == NULL) {
        /* capture address of the function-local static on first invocation */
        ratio_addr = &ratio;
    }

    double old_ratio = ratio;
    ratio = new_ratio;
    return old_ratio;
}

/* Return pointer to the file-scope static ratio. Safe: ratio has static storage
 * duration so the pointer remains valid for the program lifetime. */
double *get_ratio_ptr(void)
{
    return ratio_addr;
}

void print_size()
{
    log_info("I think size is: %d", THE_SIZE);
}