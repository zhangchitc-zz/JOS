
#include <inc/stdio.h>
#include <inc/assert.h>
#include <inc/stdlib.h>

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


void 
test_stdlib ()
{
    // islower
    assert (islower ('a'));
    assert (islower ('z'));
    assert (!islower ('A'));
    assert (!islower ('9'));

    // isupper
    assert (isupper ('A'));
    assert (isupper ('Z'));
    assert (!isupper ('a'));
    assert (!isupper ('6'));

    // isalpha
    assert (isalpha ('a'));
    assert (isalpha ('z'));
    assert (isalpha ('A'));
    assert (isalpha ('Z'));
    assert (!isalpha ('9'));
    assert (!isalpha ('0'));




    cprintf ("Hooray! Passed all test cases for stdlib!!\n");


}
