#include <inc/x86.h>
#include <inc/lib.h>

void
umain(void)
{
    sys_net_try_send ("Hello, World", 12);
}

