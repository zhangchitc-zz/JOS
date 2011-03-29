// Simple command-line kernel monitor useful for
// controlling the kernel and exploring the system interactively.

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/mmu.h>
#include <inc/assert.h>
#include <inc/x86.h>

#include <kern/pmap.h>
#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>

#define CMDBUF_SIZE	80	// enough for one VGA text line


struct Command {
	const char *name;
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};

static struct Command commands[] = {
	{ "help", "Display this list of commands", mon_help },
	{ "kerninfo", "Display information about the kernel", mon_kerninfo },
    { "backtrace", "Display information about the stack", mon_backtrace },
    { "showmappings", "Display a easy-to-read format of physical page mapping", mon_showmappings },
    { "setmappings", "Modify virtual address to physical address mapping", mon_setmappings },
    { "dumpmem", "Dump the contents of a range of memory", mon_dumpmem },
    { "alloc_page", "Allocate a physical page", mon_alloc_page },
    { "page_status", "Check physical page status", mon_page_status },
    { "free_page", "Free a physical page", mon_free_page }
};
#define NCOMMANDS (sizeof(commands)/sizeof(commands[0]))

unsigned read_eip();

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
	extern char _start[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
	cprintf("  _start %08x (virt)  %08x (phys)\n", _start, _start - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-_start+1023)/1024);
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{

    uint32_t *ebp, *eip;
    uint32_t arg0, arg1, arg2, arg3, arg4;
    struct Eipdebuginfo debuginfo;
    struct Eipdebuginfo *eipinfo = &debuginfo;

    ebp = (uint32_t*) read_ebp ();

    cprintf ("Stack backtrace:\n");
    while (ebp != 0) {

        eip = (uint32_t*) ebp[1];
        arg0 = ebp[2];
        arg1 = ebp[3];
        arg2 = ebp[4];
        arg3 = ebp[5];
        arg4 = ebp[6];
        
        debuginfo_eip ((uintptr_t) eip, eipinfo);

        cprintf ("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, eip, arg0, arg1, arg2, arg3, arg4);
        cprintf ("         %s:%d: %.*s+%d\n", 
            eipinfo->eip_file, 
            eipinfo->eip_line, 
            eipinfo->eip_fn_namelen, eipinfo->eip_fn_name,
            (uint32_t) eip - eipinfo->eip_fn_addr);


        ebp = (uint32_t*) ebp[0];
    }
	
    return 0;
}

int 
showmappings (uint32_t lva, uint32_t uva)
{    
    pte_t *pte;
    
    while (lva < uva) {
        pte = pgdir_walk (boot_pgdir, (void*) lva, 0);

        cprintf ("0x%x - 0x%x     ", lva, lva + PGSIZE);

        if (pte == NULL || !(*pte & PTE_P)) {
            cprintf ("not mapped\n");
        } else {
            cprintf ("0x%x   ", PTE_ADDR (*pte));

            if (*pte & PTE_U) 
                cprintf ("user: ");
            else
                cprintf ("kernel: ");
            
            if (*pte & PTE_W) 
                cprintf ("read/write");
            else
                cprintf ("read only");

            cprintf ("\n");
        }

        lva += PGSIZE;
    }
 
    return 0;
}

int
mon_showmappings (int argc, char **argv, struct Trapframe *tf)
{
    if (argc != 3) {
        cprintf ("Usage: showmappings [LOWER_ADDR] [UPPER_ADDR]\n");
        cprintf ("Both address must be aligned in 4KB\n");
        return 0;
    }

    uint32_t lva = strtol (argv[1], 0, 0);
    uint32_t uva = strtol (argv[2], 0, 0);

    if (lva != ROUNDUP (lva, PGSIZE) ||
        uva != ROUNDUP (uva, PGSIZE) ||
        lva > uva) {
        cprintf ("showmappings: Invalid address\n");
        return 0;
    }

    showmappings (lva, uva);

    return 0;
}



int
setmappings (uint32_t va, uint32_t memsize, uint32_t pa, int perm)
{
    uint32_t offset;

    for (offset = 0; offset < memsize; offset += PGSIZE) {
       page_insert (boot_pgdir, pa2page (pa + offset), (void *)va + offset, perm); 
    }

    return 0;
}

int
mon_setmappings (int argc, char **argv, struct Trapframe *tf)
{
    if (argc != 5) {
        cprintf ("Usage: setmappings [VIRTUAL_ADDR] [PAGE_NUM] [PHYSICAL_ADDR] [PERMISSION]\n");
        cprintf ("    Both virtual address and physical address must be aligned in 4KB\n");
        cprintf ("    Permission is one of 4 options ('ur', 'uw', 'kr', 'kw')\n");
        cprintf ("           u stands for user mode, k for kernel mode\n");

        cprintf ("\n     Make sure that the physical memory space has already been mounted before\n");
        return 0;
    }


    //
    // Added by Chi Zhang (zhangchitc@gmail.com)
    // Just for test use!!
    // In the beginning, there is no physical page mounted
    // (The KERNBASE above space is static mapping which did't affect the pp_ref
    // so we need manually insert a page
    // here I select the second physical page
    // 
    // page_insert (boot_pgdir, pages + 1, 0, 0);

    uint32_t va = strtol (argv[1], 0, 0);
    uint32_t pa = strtol (argv[3], 0, 0);
    uint32_t perm = 0;
    uint32_t memsize = strtol (argv[2], 0, 0) * PGSIZE;

    if (va != ROUNDUP (va, PGSIZE) ||
        pa != ROUNDUP (pa, PGSIZE) ||
        va > ~0 - memsize) {
        cprintf ("setmappings: Invalid address\n");
        return 0;
    }

    uint32_t offset;
    struct Page *pp;

    for (offset = 0; offset < memsize; offset += PGSIZE) {
        pp = pa2page (pa + offset);
        if (pp -> pp_ref == 0) {
            cprintf ("setmappings: Unmounted physical page: %x - %x\n", 
                pa + offset, pa + offset + PGSIZE);
            return 0;
        }
    }

    if (argv[4][0] == 'u') {
        perm |= PTE_U;
    }
    if (argv[4][1] == 'w') {
        perm |= PTE_W;
    }

    setmappings (va, memsize, pa, perm);

    cprintf ("Set memory mapping successfully!  The new mapping is:\n");
    showmappings (va, va + memsize);


    return 0;
}




int
dumpmem (uint32_t lva, uint32_t uva)
{
    while (lva < uva) {
        cprintf ("0x%x:  ", lva);
        int i;
        for (i = 0; i < 4 && lva < uva; i++, lva += 4) {
            cprintf ("0x%x  ", *((uint32_t*) lva));
        }
        cprintf ("\n");
    }

    return 0;
}


int
mon_dumpmem (int argc, char **argv, struct Trapframe *tf)
{
    if (argc != 4) {
        cprintf ("Usage: dumpmem [ADDR_TYPE] [LOWER_ADDR] [PRINT_DWORD]\n");
        cprintf ("       Address must be aligned in 4B\n");
        cprintf ("       Address type can only be 'v' or 'p'\n");
        return 0;
    }

    uint32_t lva = strtol (argv[2], 0, 0);
    uint32_t uva = strtol (argv[3], 0, 0) * 4 + lva;

    if (lva != ROUNDUP (lva, 4) ||
        uva != ROUNDUP (uva, 4) ||
        lva > uva) {
        cprintf ("dumpmem: Invalid address\n");
        return 0;
    }

    if (argv[1][0] != 'v' && argv[1][0] != 'p') {
        cprintf ("dumpmem: Invalid address type\n");
        return 0;
    }

    if (argv[1][0] == 'p') {
        lva += KERNBASE;
        uva += KERNBASE;
    }

    dumpmem (lva, uva); 

    return 0;
}




int 
mon_alloc_page (int argc, char **argv, struct Trapframe *tf)
{
    struct Page *pp;

    if (page_alloc (&pp) == 0) {
        cprintf ("    0x%x\n", page2pa (pp));
        pp -> pp_ref ++;
    } else {
        cprintf ("    Page allocation failed!\n");
    }

    return 0;
}



int 
mon_page_status (int argc, char **argv, struct Trapframe *tf)
{
    if (argc != 2) {
        cprintf ("Usage: page_status [ADDR]\n");
        cprintf ("    Address must be aligned in 4KB\n");
        return 0;
    }

    uint32_t pa = strtol (argv[1], 0, 0);
    struct Page *pp = pa2page (pa);

    if (pp -> pp_ref > 0) {
        cprintf ("    allocated\n");
    } else {
        cprintf ("    free\n");
    }

    return 0;
}

int mon_free_page (int argc, char **argv, struct Trapframe *tf)
{
    if (argc != 2) {
        cprintf ("Usage: free_page [ADDR]\n");
        cprintf ("    Address must be aligned in 4KB\n");
        cprintf ("    Please make sure that the page is currently mounted only 1 time\n");
        return 0;
    }

    uint32_t pa = strtol (argv[1], 0, 0);
    struct Page *pp = pa2page (pa);

    if (pp -> pp_ref == 1) {
        page_decref (pp);
        cprintf ("    Page freed successfully!\n");
    } else {
        cprintf ("    Failed!\n");
    }

   
    return 0;
}

/***** Kernel monitor command interpreter *****/

#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void
monitor(struct Trapframe *tf)
{
	char *buf;

	cprintf("%CredWelcome %Cwhtto %Cgrnthe %CorgJOS %Cgrykernel %Cpurmonitor!\n");
	cprintf("%CcynType %Cylw'help' %C142for a %C201list %C088of %Cwhtcommands.\n");

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}

// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
	return callerpc;
}
