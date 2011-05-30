// LAB 6: Your driver code here

#include <inc/x86.h>
#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/mmu.h>

#include <kern/pmap.h>
#include <kern/e100.h>



struct pci_func e100;
struct nic nic;

static void e100_sw_reset(struct pci_func e100);
static void e100_exec_cmd(int csr_comp, uint8_t cmd);

static void e100_init();

static void cbl_init();
static void cbl_alloc();
static void cbl_validate ();
static int cbl_append_nop (uint16_t flag);
static int cbl_append_transmit (const char *data, uint16_t l, uint16_t flag);

static void rfa_init();
static void rfa_alloc();
static void rfa_validate ();
static int rfa_retrieve_data (char *data);

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
 * Allocate CB_MAX_NUM pages, each page for a control block
 */
static void
cbl_alloc () {
    int i, r;
    struct Page *p;
    struct cb *prevcb = NULL;
    struct cb *currcb = NULL;

    // Allocate physical page for Control block
    for (i = 0; i < CB_MAX_NUM; i++) {

        if ((r = page_alloc (&p)) != 0)
            panic ("cbl_init: run out of physical memory! %e\n", r);

        p -> pp_ref ++;
        memset (page2kva (p), 0, PGSIZE);

        currcb = (struct cb *)page2kva (p);
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

    nic.cbl.cb_avail --;
    nic.cbl.cb_wait ++;

    nic.cbl.rear = nic.cbl.rear->next;

    nic.cbl.rear->cb_status = 0;
    nic.cbl.rear->cb_control = CBC_NOP | flag;

    return 0;
}


static int
cbl_append_transmit (const char *data, uint16_t l, uint16_t flag)
{
    if (nic.cbl.cb_avail == 0)
        return -E_CBL_FULL;

    nic.cbl.cb_avail --;
    nic.cbl.cb_wait ++;

    nic.cbl.rear = nic.cbl.rear->next;

    nic.cbl.rear->cb_status = 0;
    nic.cbl.rear->cb_control = CBC_TRANSMIT | flag;

    nic.cbl.rear->cb_cmd_spec.tcb.tcb_tbd_array_addr    = 0xFFFFFFFF;
    nic.cbl.rear->cb_cmd_spec.tcb.tcb_byte_count        = l;
    nic.cbl.rear->cb_cmd_spec.tcb.tcb_thrs              = 0xE0;
    nic.cbl.rear->cb_cmd_spec.tcb.tcb_tbd_count         = 0;

    memmove (nic.cbl.rear->cb_cmd_spec.tcb.tcb_data, (void *)data, l);

    return 0;
}

int 
e100_transmit (const char *data, uint16_t len)
{
    cbl_validate ();

    if (nic.cbl.cb_avail == 0)
        return -E_CBL_FULL;
    
    nic.cbl.rear->cb_control &= ~CBF_S;
    cbl_append_transmit (data, len, CBF_S);

    int scb_status = inb(nic.io_base + CSR_STATUS);
    if ((scb_status & CUS_MASK) == CUS_SUSPENDED)
        e100_exec_cmd (CSR_COMMAND, CUC_RESUME); 

    return 0;
}

static void
cbl_validate () 
{
    while (nic.cbl.cb_wait > 0 && (nic.cbl.front->cb_status & CBS_C) != 0) {
        nic.cbl.front = nic.cbl.front->next;
        nic.cbl.cb_avail ++;
        nic.cbl.cb_wait --;
    }
}


static void
cbl_init () 
{
    cbl_alloc ();

    cbl_append_nop (CBF_S);

    outl(nic.io_base + CSR_GP, nic.cbl.front->phy_addr);
    e100_exec_cmd (CSR_COMMAND, CUC_START); 
}



/**
 * Allocate RFD_MAX_NUM pages each page for a Recieve Frame Descriptor
 */
static void
rfa_alloc () {
    int i, r;
    struct Page *p;
    struct rfd *prevrfd = NULL;
    struct rfd *currrfd = NULL;

    // Allocate physical page for Control block
    for (i = 0; i < RFD_MAX_NUM; i++) {
        if ((r = page_alloc (&p)) != 0)
            panic ("rfa_init: run out of physical memory! %e\n", r);

        p -> pp_ref ++;
        memset (page2kva (p), 0, PGSIZE);

        currrfd = (struct rfd *)page2kva (p);
        currrfd->phy_addr = page2pa (p);
        currrfd->rfd_control = 0;
        currrfd->rfd_status = 0;
        currrfd->rfd_size = RFD_MAXSIZE;

        if (i == 0)
            nic.rfa.start = currrfd;
        else {
            prevrfd->rfd_link = currrfd->phy_addr;
            prevrfd->next = currrfd;
            currrfd->prev = prevrfd;
        }

        prevrfd = currrfd;
    }

    prevrfd->rfd_link = nic.rfa.start->phy_addr;
    nic.rfa.start->prev = prevrfd;
    prevrfd->next = nic.rfa.start;

    nic.rfa.rfd_avail = RFD_MAX_NUM;
    nic.rfa.rfd_wait = 0;

    nic.rfa.front = nic.rfa.start;
    nic.rfa.rear = nic.rfa.start->prev;
    nic.rfa.rear->rfd_control |= RFDF_S;
}


static void
rfa_init () 
{
    //cprintf ("\n\nRFA Initialization started! \n");

    rfa_alloc ();

    outl(nic.io_base + CSR_GP, nic.rfa.front->phy_addr);
    e100_exec_cmd (CSR_COMMAND, RUC_START); 


/**
 * This section is for test when we finished rfa_alloc ()  
 *
    while (nic.rfa.rfd_avail > 0)
        rfa_validate ();

    int scb_status = inb(nic.io_base + CSR_STATUS);

    cprintf ("zhangchi: rfd slot is full, current RU state = %02x\n", scb_status & RUS_MASK);

    char s[1518];
    while (rfa_retrieve_data (s) >= 0);


    e100_exec_cmd (CSR_COMMAND, RUC_RESUME);

    while (nic.rfa.rfd_avail > 0)
        rfa_validate ();
*/
}


static void
rfa_validate () 
{
    while (nic.rfa.rfd_avail > 0 && (nic.rfa.rear->next->rfd_status & RFDS_C) != 0) {
        nic.rfa.rear = nic.rfa.rear->next;

        nic.rfa.rfd_avail --;
        nic.rfa.rfd_wait ++;
        //cprintf ("zhangchi: validate, avail = %d, wait = %d,   slot = %x\n", 
        //    nic.rfa.rfd_avail, nic.rfa.rfd_wait, nic.rfa.rear);
    }
}

static int
rfa_retrieve_data (char* data)
{
    if (nic.rfa.rfd_wait == 0)
        return -E_RFA_EMPTY;

    nic.rfa.rfd_avail ++;
    nic.rfa.rfd_wait --;
    //cprintf ("zhangchi: retrieve, avail = %d, wait = %d,   slot = %x\n", 
        //nic.rfa.rfd_avail, nic.rfa.rfd_wait, nic.rfa.front);

    nic.rfa.front->prev->rfd_control &= ~RFDF_S;
    nic.rfa.front->rfd_control = RFDF_S;
    nic.rfa.front->rfd_status = 0;

    int r = nic.rfa.front->rfd_actual_count & RFD_AC_MASK;
    memmove (data, nic.rfa.front->rfd_data, r);

    nic.rfa.front = nic.rfa.front->next;

    return r;
}

int 
e100_receive (char *data)
{
    rfa_validate ();

    if (nic.rfa.rfd_wait == 0)
        return -E_RFA_EMPTY;

    int r = rfa_retrieve_data (data);
    
    int scb_status = inb(nic.io_base + CSR_STATUS);
    if ((scb_status & RUS_MASK) == RUS_SUSPEND)
        e100_exec_cmd (CSR_COMMAND, RUC_RESUME); 

    return r;
}

static void
e100_init ()
{
    // Software Reset E100rfd_data
    e100_sw_reset(e100);

    // disable all interrupts
    e100_exec_cmd (CSR_INT, 1);

    cbl_init ();
    rfa_init ();
}


