#include <stdio.h>
#include <string.h>

#define NAME_SIZE 64

/* A Person that stores the name inside the struct (no heap allocation for the
 * name). This lets us create Person instances on the stack and safely pass
 * them by value to functions. */
struct Person {
    char name[NAME_SIZE];
    int age;
    int height;
    int weight;
};

/* Create a Person and return it by value (no malloc). */
struct Person Person_create_value(const char *name, int age, int height, int weight)
{
    struct Person p;
    snprintf(p.name, sizeof p.name, "%s", name);
    p.age = age;
    p.height = height;
    p.weight = weight;
    return p;
}

/* Print a Person passed by value (function receives a copy). */
void Person_print_by_value(struct Person p)
{
    printf("Name: %s\n", p.name);
    printf("\tAge: %d\n", p.age);
    printf("\tHeight: %d\n", p.height);
    printf("\tWeight: %d\n", p.weight);
}

/* Demonstrate modifying a copy (does not change the original). */
struct Person Person_with_added_years(struct Person p, int years)
{
    p.age += years;
    return p;
}

int main(void)
{
    /* 1) Create on the stack using a factory that returns by value */
    struct Person joe = Person_create_value("Joe Alex", 32, 64, 140);

    /* 2) Create on the stack using aggregate initialization and dot operator */
    struct Person frank = { "Frank Blank", 20, 72, 180 };

    /* Print addresses (stack addresses) and values using dot operator and
     * pass-by-value print function. */
    printf("Joe is at %p\n", (void *)&joe);
    Person_print_by_value(joe);

    printf("Frank is at %p\n", (void *)&frank);
    Person_print_by_value(frank);

    /* Modify a copy: original joe remains unchanged */
    struct Person older_joe = Person_with_added_years(joe, 20);
    printf("--- older_joe (copy) ---\n");
    Person_print_by_value(older_joe);

    printf("--- original joe still ---\n");
    Person_print_by_value(joe);

    /* Modify the original directly using dot operator (no pointer needed) */
    joe.age += 20;
    joe.height -= 2;
    joe.weight += 40;
    printf("--- modified original joe ---\n");
    Person_print_by_value(joe);

    return 0;
}