#include<stdio.h>
#include<assert.h>
#include<stdlib.h>
#include<string.h>

struct Person
{
    char name[64];
    int age;
    int height;
    int weight;
};

struct Person Person_create(const char *name, int age, int height, int weight)
{
    struct Person p;
    assert(name != NULL);

    int n = snprintf(p.name, sizeof p.name, "%s", name);
    if (n < 0) { /* error */ }
    if (n >= (int)sizeof p.name) {
        /* 截断，视需要处理 */
    }
    p.age = age;
    p.height = height;
    p.weight = weight;
    return p;
};

void Person_printf(struct Person p)
{
    printf("Name: %s\n", p.name);
    printf("\tAge: %d\n", p.age);
    printf("\tHeight: %d\n", p.height);
    printf("\tWeight: %d\n", p.weight);
}

int main(int argc, char *argv[])
{
    struct Person joe = Person_create("Joe Alex", 32, 64, 140);
    struct Person frank = Person_create("Frank Blank", 20, 72, 180);

    printf("Joe is at memory location %p:\n", (void*)&joe);
    Person_printf(joe);
    printf("Frank is at memory location %p:\n", (void*)&frank);
    Person_printf(frank);

    joe.age += 20;
    joe.height -= 2;
    joe.weight += 40;
    Person_printf(joe);

    frank.age += 20;
    frank.weight += 20;
    Person_printf(frank);

    return 0;
}