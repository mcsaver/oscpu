#include"ex22.h"
#include"dbg.h"

const char * MY_NAME = "Zed A. Shaw";

void scope_demo(int count)
{
    log_info("count is: %d", count);

    if (count > 10)
    {
        int count = 100; //BAD! BUGS!

        log_info("count in thisscope is %d", count);
    }
    
    log_info("count is at exit : %d", count);

    count = 3000;

    log_info("count after assign: %d", count);
}

int main(int argc, char *argv[])
{
    //test out THE_AGE accessors
    log_info("My name: %s, age: %d", MY_NAME, get_age());
    
    set_age(100);

    log_info("My age is now: %d", get_age());

    // test out THE_SIZE extern
    log_info("THE_SIZE is: %d", THE_SIZE);
    print_size();

    THE_SIZE = 9;

    log_info("The SIZE is nowL %d", THE_SIZE);
    print_size();

    // test the ratio function static
    log_info("Ratio at first: %f", update_ratio(2.0));
    log_info("Ratio again: %f", update_ratio(10.0));
    log_info("Ratio once more: %f", update_ratio(300.0));

    /* Demonstrate pointer access to the internal ratio variable via accessor */
    double *rptr = get_ratio_ptr();
    log_info("ratio via pointer before: %f", *rptr);
    *rptr = 0.25; /* modify the internal ratio directly */
    log_info("ratio via pointer after modification: %f", *rptr);
    log_info("Ratio returned by update_ratio after direct modification: %f", update_ratio(1.5));

    // test the scope demo
    int count = 4;
    scope_demo(count);
    scope_demo(count * 20);

    log_info("count after calling scope_demo: %d", count);

    return 0;
}