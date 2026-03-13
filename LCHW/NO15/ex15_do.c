#include<stdio.h>

/* Functions that accept pointers and print the arrays in different styles. */
void print_indexing(char **names, int *ages, int count)
{
    for (int i = 0; i < count; i++) {
        /* use array-style indexing inside the function */
        printf("%s has %d years alive.\n", names[i], ages[i]);
    }
}

void print_pointer_arithmetic(char **names, int *ages, int count)
{
    for (int i = 0; i < count; i++) {
        /* use pointer arithmetic with dereference */
        printf("%s is %d years old.\n", *(names + i), *(ages + i));
    }
}

void print_subscript_with_pointers(char **names, int *ages, int count)
{
    for (int i = 0; i < count; i++) {
        /* even though we received pointers, we can still use [] */
        printf("%s is %d years old again.\n", names[i], ages[i]);
    }
}

void print_with_increment(char **names, int *ages, int count)
{
    char **p_name = names;
    int *p_age = ages;
    for (int i = 0; i < count; i++) {
        printf("%s lived %d years so far.\n", *p_name, *p_age);
        p_name++;
        p_age++;
    }
}

void print_args_pointer_style(int argc, char **argv)
{
    if (argc <= 1) {
        printf("no command-line arguments provided\n");
        return;
    }

    char **p = argv + 1; /* skip program name */
    for (int i = 0; i < argc - 1; i++) {
        printf("arg %d: %s\n", i, *(p + i));
    }
}

int main (int argc, char *argv[])
{
    /* create two arrays we care about */
    int ages[] = {23, 43, 12, 89, 2};
    char *names[] = { "Alan", "Frank", "Mary", "John", "Lisa" };

    /* safely get the size of ages */
    int count = sizeof(ages) / sizeof(int);

    /* call functions that accept pointers and behave like arrays */
    print_indexing(names, ages, count);
    printf("---\n");

    print_pointer_arithmetic(names, ages, count);
    printf("---\n");

    print_subscript_with_pointers(names, ages, count);
    printf("---\n");

    print_with_increment(names, ages, count);
    printf("---\n");

    /* print command-line arguments using pointer-style function */
    print_args_pointer_style(argc, argv);

    return 0;
}