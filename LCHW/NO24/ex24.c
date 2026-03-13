#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "dbg.h"

#define MAX_DATA 100

typedef enum EyeColor {
    BLUE_EYES, GREEN_EYES, BROWN_EYES,
    BLACK_EYES, OTHER_EYES
} EyeColor;

const char * EYE_COLOR_NAMES[] = {
    "Blue", "Green", "Brown", "Black", "Other"
};

typedef struct Person {
    int age;
    char first_name[MAX_DATA];
    char last_name[MAX_DATA];
    EyeColor eyes;
    float income;
} Person;

/*
 * read_file_to_buffer - read a file one character at a time using fscanf("%c")
 * into the provided buffer `out` of size `out_size`.
 * Guarantees:
 *  - never writes more than out_size bytes to `out`
 *  - always NUL-terminates `out` (even if out_size == 0, nothing is written)
 *  - stops at EOF or when buffer has no room for another character + NUL
 * Returns: number of characters placed into out (not counting terminating NUL)
 *          or a negative error code on failure:
 *            -1 : invalid args (NULL pointers or out_size == 0)
 *            -2 : failed to open file
 */
int read_file_to_buffer(const char *filename, char *out, size_t out_size)
{
    if (!filename || !out || out_size == 0) return -1;

    /* Ensure we have a valid empty string in all cases */
    out[0] = '\0';

    FILE *f = fopen(filename, "r");
    if (!f) return -2;

    size_t i = 0;
    char ch;

    /* Read characters one at a time using fscanf("%c") until buffer full or EOF */
    while (i + 1 < out_size) {
        int r = fscanf(f, "%c", &ch);
        if (r == 1) {
            out[i++] = ch;
        } else {
            /* r == EOF or no more input; stop reading */
            break;
        }
    }

    /* Always NUL-terminate */
    out[i] = '\0';

    fclose(f);
    return (int)i;
}

int main(int argc, char *argv[])
{
    if (argc == 2) {
        /* test mode: read file into buffer and print */
        char filebuf[1024];
        int n = read_file_to_buffer(argv[1], filebuf, sizeof filebuf);
        if (n < 0) {
            fprintf(stderr, "read_file_to_buffer failed: %d\n", n);
            return 1;
        }
        printf("Read %d chars from %s:\n", n, argv[1]);
        fwrite(filebuf, 1, n, stdout);
        printf("\n--- end ---\n");
        return 0;
    }

    Person you = {.age = 0};
    int i = 0;
    char *in = NULL;
    char buf[MAX_DATA];

    printf("What's your First Name? ");
    in = fgets(you.first_name, MAX_DATA-1, stdin);
    check(in != NULL, "Failed to read first name.");

    printf("What's your Last Name? ");
    in = fgets(you.last_name, MAX_DATA-1, stdin);
    check(in != NULL, "Failed to read last name.");

    printf("How old are you? ");
    if (scanf("%d", &you.age) != 1) {
        check(0, "You have to enter a number.");
    }
    /* eat leftover newline */
    int c; while ((c = getchar()) != '\n' && c != EOF) { }

    printf("What color are your eyes:\n");
    for ( i = 0; i < OTHER_EYES; i++)
    {
        printf("%d) %s\n", i+1, EYE_COLOR_NAMES[i]);
    }
    printf("> ");

    int eyes = -1;
    if (scanf("%d", &eyes) != 1) {
        check(0, "You have to enter a number.");
    }
    /* eat leftover newline */
    while ((c = getchar()) != '\n' && c != EOF) { }

    you.eyes = eyes - 1;
    check(you.eyes <= OTHER_EYES && you.eyes >= 0, "Do it right, that's not an option.");
    
    printf("How much do you make an hour? ");
    if (scanf("%f", &you.income) != 1) {
        check(0, "Enter a floating point number.");
    }
    while ((c = getchar()) != '\n' && c != EOF) { }
    printf("\n");
    printf("----- RESULTS -----\n");

    printf("First Name: %s", you.first_name);
    printf("Last Name: %s", you.last_name);
    printf("Age: %d\n", you.age);
    printf("Eyes: %s\n", EYE_COLOR_NAMES[you.eyes]);
    printf("Income: %f\n", you.income);

    return 0;

error:
    return 1;
}
