#include "ns.h"

extern union Nsipc nsipcbuf;

void
output(envid_t ns_envid)
{
    binaryname = "ns_output";

    // LAB 6: Your code here:
    // 	- read a packet from the network server
    //	- send the packet to the device driver

	uint32_t req, whom;
	int perm, r;

    while (1) {
        perm = 0;
        req = ipc_recv((int32_t *) &whom, &nsipcbuf, &perm);
    
        // All requests must contain an argument page
        if (!(perm & PTE_P))
            panic ("output: Invalid request from %08x: no argument page\n", whom);

        if (req != NSREQ_OUTPUT)
            panic ("output: Invalid IPC Request type: %d\n", req);

        while ((r = sys_net_try_send (nsipcbuf.pkt.jp_data, nsipcbuf.pkt.jp_len)) != 0);

        //sys_page_unmap(0, &nsipcbuf);
    }
}
