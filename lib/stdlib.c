
#include <inc/stdio.h>


int 
islower (int c)
{
    return 'a' <= c && c <= 'z';
}



int
isupper (int c)
{
    return 'A' <= c && c <= 'Z';
}



int
isalpha (int c)
{
    return isupper (c) || islower (c);
}



int
isspace (int c)
{
    return c == ' ' 
        || c == '\t'
        || c == '\n'
        || c == '\v'
        || c == '\f'
        || c == '\r'; 
}



int
isdigit (int c)
{
    return '0' <= c && c <= '9';
}



int
isxdigit (int c)
{
    return isdigit (c) || ('A' <= toupper (c) && toupper (c) <= 'F');
}



int
isalnum (int c)
{
    return isdigit (c) || isalpha (c);
}


int 
toupper (int c)
{
    return islower (c) ? c - 'a' + 'A' : c;
}



int 
tolower (int c)
{
    return isupper (c) ? c - 'A' + 'a' : c;
}


// Parses the C string str interpreting its content 
// as an integral number of the specified base, 
// which is returned as a long int value.
//
//
// The function first discards as many whitespace characters as necessary 
// until the first non-whitespace character is found. 
// Then, starting from this character, takes as many characters as possible 
// that are valid following a syntax that depends on the base parameter, 
// and interprets them as a numerical value. 
// Finally, a pointer to the first character following the integer representation in str 
// is stored in the object pointed by endptr.
//
//
// If the value of base is zero, the syntax expected is similar to that of integer constants, 
// which is formed by a succession of:
//      *   An optional plus or minus sign
//      *   An optional prefix indicating octal or hexadecimal base ("0" or "0x" respectively)
//      *   A sequence of decimal digits (if no base prefix was specified) 
//          or either octal or hexadecimal digits if a specific prefix is present
//
//
// If the base value is between 2 and 36, the format expected for the integral number 
// is a succession of the valid digits and/or letters needed to represent integers of the specified radix 
// (starting from '0' and up to 'z'/'Z' for radix 36). 
// The sequence may optionally be preceded by a plus or minus sign and, 
// if base is 16, an optional "0x" or "0X" prefix.
//
// If the first sequence of non-whitespace characters in str is not a valid integral number 
// as defined above, or if no such sequence exists because either str is empty
// or it contains only whitespace characters, no conversion is performed.

unsigned int
strtol (const char *str, char **endptr, int base)
{
       
}
