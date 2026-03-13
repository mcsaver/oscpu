#include<stdio.h>

int main(int argc, char *argv[])
{
    char Letter_reg;
    if (argc != 2)
    {
        printf("ERROR: You need one argument.\n");
        // this is how you abort a program
        return 1;
    }
    
    for (int i = 0; argv[1][i] != '\0'; i++)
    {
        char letter = argv[1][i];// you must assign it this way; otherwise letter will always refer to the first character
        if (letter < 'a')
        {
            Letter_reg = letter + 32;
        }
        else    Letter_reg = letter;

        if (Letter_reg == 'a') {
            printf("%d: 'a'\n", i);
        } else if (Letter_reg == 'e') {
            printf("%d: 'e'\n", i);
        } else if (Letter_reg == 'i') {
            printf("%d: 'i'\n", i);
        } else if (Letter_reg == 'o') {
            printf("%d: 'o'\n", i);
        } else if (Letter_reg == 'u') {
            printf("%d: 'u'\n", i);
        } else if (Letter_reg == 'y') {
            if (i > 2) {
                // it's only sometimes Y
                printf("%d: 'y'\n", i);
            }
        } else {
            printf("%d: %c is not a vowel\n", i, Letter_reg);
        }
    }
    
}