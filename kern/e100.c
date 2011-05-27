// LAB 6: Your driver code here

#include <inc/x86.h>
#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/mmu.h>

#include <kern/pmap.h>
#include <kern/e100.h>


#define CBLBASE     (KERNBASE + PGSIZE)


struct pci_func e100;
struct nic nic;

static void e100_sw_reset(struct pci_func e100);
static void e100_exec_cmd(int csr_comp, uint8_t cmd);

static void e100_init();
static void cbl_init();
static void cbl_alloc();


int
e100_attach(struct pci_func *pcif) 
{
    pci_func_enable(pcif);
    e100.bus = pcif->bus;
    e100.dev_id = pcif->dev_id;
    e100.dev_class = pcif->dev_class;
    int i;
    for (i = 0; i < 6; i++) {
    	e100.reg_base[i] = pcif->reg_base[i];
        e100.reg_size[i] = pcif->reg_size[i];
    }
    e100.irq_line = pcif->irq_line;

    // Initialize NIC
    nic.io_base = pcif->reg_base[E100_IO];
    nic.io_size = pcif->reg_size[E100_IO];


    e100_init ();

    return 0;
}

static void
e100_sw_reset(struct pci_func e100) {
	outl(e100.reg_base[E100_IO] + CSR_PORT, PORT_SW_RESET);

    // delay about 10us
    int i = 0;
    for (i = 0; i < 8; i++) {
        inb (0x84);
    }
}

/**
 * Instruct E100 to execute a cmd
 * Might be clear the interrupt, load base for CU and RU or ...
 */
static void
e100_exec_cmd (int csr_comp, uint8_t cmd)
{
    int scb_command;

    outb(nic.io_base + csr_comp, cmd);
    do {
        scb_command = inb(nic.io_base + CSR_COMMAND);
    } while (scb_command != 0);
}


/**
 * Allocate CB_MAX_NUM pages starting from CBLBASE, 
 * each page for a control block
 */
static void
cbl_alloc () {
    int i, r;
    void *va;
    struct Page *p;
    struct cb *prevcb = NULL;
    struct cb *currcb = NULL;

    // Allocate physical page for Control block
    for (i = 0; i < CB_MAX_NUM; i++) {

        va = (void *)CBLBASE + i * PGSIZE;

        if ((r = page_alloc (&p)) != 0)
            panic ("cbl_init: run out of physical memory! %e\n", r);

        pte_t *pte = pgdir_walk (boot_pgdir, va, 1);

        *pte = page2pa (p)|PTE_W|PTE_P;
        p -> pp_ref ++;

        memset (va, 0, PGSIZE);

        currcb = (struct cb *)va;
        currcb->phy_addr = page2pa (p);


        if (i == 0)
            nic.cbl.start = currcb;
        else {
            prevcb->cb_link = currcb->phy_addr;
            prevcb->next = currcb;
            currcb->prev = prevcb;
        }

        prevcb = currcb;
    }

    prevcb->cb_link = nic.cbl.start->phy_addr;
    nic.cbl.start->prev = prevcb;
    prevcb->next = nic.cbl.start;

    nic.cbl.cb_avail = CB_MAX_NUM;
    nic.cbl.cb_wait = 0;

    nic.cbl.front = nic.cbl.start;
    nic.cbl.rear = nic.cbl.start->prev;
}


static int
cbl_append_nop (uint16_t flag)
{
    if (nic.cbl.cb_avail == 0)
        return -E_CBL_FULL;

    nic.cbl.rear = nic.cbl.rear->next;
    nic.cbl.rear->cb_control = CBC_NOP | flag;

    return 0;
}


static int
cbl_append_data (char *data, uint16_t l)
{
    if (nic.cbl.cb_avail == 0)
        return -E_CBL_FULL;

    nic.cbl.rear = nic.cbl.rear->next;
    nic.cbl.rear->cb_control                            = CBC_TRANSMIT;
    nic.cbl.rear->cb_cmd_spec.tcb.tcb_tbd_array_addr    = 0xFFFFFFFF;
    nic.cbl.rear->cb_cmd_spec.tcb.tcb_byte_count        = l;
    nic.cbl.rear->cb_cmd_spec.tcb.tcb_thrs              = 0xE0;
    nic.cbl.rear->cb_cmd_spec.tcb.tcb_tbd_count         = 0;

    memmove (nic.cbl.rear->cb_cmd_spec.tcb.tcb_data, (void *)data, l);

    return 0;
}

static void
cbl_init () 
{
    cbl_alloc ();

    return;

    // Clear General Pointer
    //outl(nic.io_base + CSR_GP, 0);
    //e100_exec_cmd (CSR_COMMAND, CUC_LOAD_BASE); 

    cbl_append_nop (0);

    cbl_append_nop (0);
    cbl_append_nop (0);
    cbl_append_nop (CBF_S);
    cbl_append_nop (0);
    cbl_append_nop (0);
    cbl_append_nop (0);
    cbl_append_nop (0);
    cbl_append_nop (0);
    cbl_append_nop (0);
    //cbl_append_nop (0);

    cbl_append_data ("aaaa", 5);
    

    outl(nic.io_base + CSR_GP, nic.cbl.front->phy_addr);
    e100_exec_cmd (CSR_COMMAND, CUC_START); 


    e100_exec_cmd (CSR_COMMAND, CUC_RESUME); 
}

static void
e100_init ()
{
    // Software Reset E100
    e100_sw_reset(e100);

    // disable all interrupts
    e100_exec_cmd (CSR_INT, 1);

    cbl_init ();
}


