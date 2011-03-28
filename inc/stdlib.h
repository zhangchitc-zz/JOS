#ifndef JOS_INC_STDLIB_H
#define JOS_INC_STDLIB_H

#include <inc/assert.h>
// lib/stdlib.c

int islower (int c);
int isupper (int c);
int isalpha (int c);
int isdigit (int c);
int isxdigit (int c);
int tolower (int c);
int toupper (int c);

int isspace (int c);
int isalnum (int c);

void test_stdlib ();
#endif
