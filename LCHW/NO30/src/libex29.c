#include<stdio.h>
#include<ctype.h>
#include<string.h>
#include<stdlib.h>
#include"dbg.h"

int print_a_message(const char *msg)
{
    printf("A STRING: %s\n", msg);

    return 0;
}

int uppercase(const char *msg)
{
    if(!msg) return -1;

    const unsigned char *p = (const unsigned char *)msg;
    while (*p)
    {
        int c = toupper((int)*p);
        putchar(c);
        p++;
    }
    putchar('\n');
    return 0;
    
}

int lowercase(const char *msg)
{
    if (!msg) return -1;

    size_t len = strlen(msg);
    char *buf = malloc(len + 1);
    if (!buf) return -1;

    for (size_t i = 0; i < len; ++i)
    {
        buf[i] = (char) tolower((unsigned char) msg[i]);
    }
    buf[len] = '\0';

    fwrite(buf, 1, len, stdout);
    fputc('\n', stdout);
    free(buf);
    return 0;

}

int fail_on_purpose(const char *msg)
{
    return 1;
}