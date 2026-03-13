/** Warning: This code is fresh and potentially isn't correct yet */

#include<stdio.h>
#include<stdlib.h>
#include<stdarg.h>
#include"dbg.h"

#define MAX_DATA 100

int read_string(char **out_string, int max_buffer)
{
    if (max_buffer <= 0)
    {
        *out_string = NULL;
        return -1;
    }
    
    *out_string = malloc((size_t)max_buffer + 1);
    check_mem(*out_string);

    int c = 0;
    int i = 0;

    while ((c = fgetc(stdin)) != EOF && c != '\n')
    {
        if (i < max_buffer)
        {
            (*out_string)[i++] = (char)c;
        } else {
            while ((c = fgetc(stdin)) != EOF && c != '\n') { }
            break;
        }
        
    }
    
    (*out_string)[i] = '\0';
    
    check(!(i == 0 && c == EOF), "Input error,");

    return 0;

error:
    if (*out_string)
    {
        free(*out_string);
        *out_string = NULL;
    }
    return -1;
}

int read_int(int *out_int)
{
    char *input = NULL;
    int rc = read_string(&input, MAX_DATA);
    check(rc == 0, "Failed to read number.");
    
    *out_int = atoi(input);
    return 0;

error:
    if(input) free(input);
    return -1;
}

int read_scan(const char *fmt, ...)
{
    int i = 0;
    int rc = 0;
    int *out_int = NULL;
    char *out_char = NULL;
    char **out_string = NULL;
    int max_buffer = 0;

    va_list argp;
    va_start(argp, fmt);

    for ( i = 0; fmt[i] != '\0'; i++)
    {
        if (fmt[i] == '%')
        {
            i++;
            switch (fmt[i])
            {
            case '\0':
                sentinel("Invalid format, you ended with %%");
                break;

            case 'd':
                out_int = va_arg(argp, int *);
                rc = read_int(out_int);
                check(rc == 0, "Failed to read int.");
                break;

            case 'c':
                out_char = va_arg(argp, char *);
                *out_char = fgetc(stdin);
                break;
            
            case 's':
                max_buffer = va_arg(argp, int);
                out_string = va_arg(argp, char **);
                rc = read_string(out_string, max_buffer);
                check(rc == 0, "Failed to read string.");
                break;
            
            default:
                sentinel("Invalid format.");
            }
        } else {
            fgetc(stdin);
        }
        
        check(!feof(stdin) && !ferror(stdin), "Input error.");
    }
    
    va_end(argp);
    return 0;

error:
    va_end(argp);
    return -1;
}

int my_printf(const char *fmt, ...)
{
    int rc;
    va_list ap;
    va_start(ap, fmt);
    rc = vprintf(fmt, ap);
    va_end(ap);
    return rc;
}

int main(int argc, char *argv[])
{
    char *first_name = NULL;
    char initial = ' ';
    char *last_name = NULL;
    int age = 0;

    my_printf("What's your first name? ");
    int rc = read_scan("%s", MAX_DATA, &first_name);
    check(rc == 0, "Failed first name.");

    my_printf("What's your initial? ");
    rc = read_scan("%c\n", &initial);
    check(rc == 0, "Failed initial.");

    my_printf("What's your last name? ");
    rc = read_scan("%s", MAX_DATA, &last_name);
    check(rc == 0, "Failed last name. ");

    my_printf("How old are you? ");
    rc = read_scan("%d", &age);

    my_printf("---- RESULTS ----\n");
    my_printf("First Name: %s\n", first_name);
    my_printf("Initial: '%c'\n", initial);
    my_printf("Last Name: %s\n", last_name);
    my_printf("Age: %d\n", age);

    free(first_name);
    free(last_name);
    return 0;
error:
    return -1;
}