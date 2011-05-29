#include "ns.h"
#include <inc/lib.h>

extern union Nsipc nsipcbuf;

envid_t shunting_input_id;

void
input(envid_t ns_envid)
{
	binaryname = "ns_input";

	// LAB 6: Your code here:
	// 	- read a packet from the device driver
	//	- send it to the network server
	// Hint: When you IPC a page to the network server, it will be
	// reading from it for a while, so don't immediately receive
	// another packet in to the same physical page.

    char buf[1518];
    int len;

    shunting_input_id = env->env_id;

    while (1) {
        int pgent = vpt[ VPN (&nsipcbuf) ];
        #define PTE_COW 0x800
        //cprintf (" before =input [%08x]=: nsipcbuf %08x pgent %08x COW %x 3bit %d\n", env->env_id, &nsipcbuf, pgent, pgent & PTE_COW, pgent & 7);

        //while ((nsipcbuf.pkt.jp_len = sys_net_try_recv (nsipcbuf.pkt.jp_data)) < 0);

        pgent = vpt[ VPN (&nsipcbuf) ];
        //cprintf (" after =input=: nsipcbuf pgent %08x COW %x 3bit %d\n", pgent, pgent & PTE_COW, pgent & 7);

        
        while ((len = sys_net_try_recv (buf)) < 0);

        nsipcbuf.pkt.jp_len = len;
        memmove ((void*) nsipcbuf.pkt.jp_data, (void *) buf, len);
        

        ipc_send(ns_envid, NSREQ_INPUT, &nsipcbuf, PTE_U|PTE_W|PTE_P);     

        sys_yield ();
 sys_yield ();
 sys_yield ();
    }
}
