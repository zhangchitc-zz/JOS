#ifndef JOS_KERN_E100_H
#define JOS_KERN_E100_H

#include <inc/x86.h>

#include <kern/pci.h>

#define E100_VENDOR		0x8086
#define E100_DEVICE		0x1209


// CSR Address Registers
#define E100_MEMORY     0
#define E100_IO         1
#define E100_FLASH      2


// SCB component offset in CSR
#define CSR_SCB         0x0
#define CSR_STATUS      0x0
#define CSR_US          0x0
#define CSR_STATACK     0x1
#define CSR_COMMAND     0x2
#define CSR_UC          0x2
#define CSR_INT         0x3
#define CSR_GP          0x4
#define CSR_PORT        0x8


// PORT Interface
#define PORT_SW_RESET   0x0
#define PORT_SELF_TEST  0x1
#define PORT_SEL_RESET  0x2


// CU Status Word
#define CUS_MASK        0xc0
#define CUS_IDLE        0x0
#define CUS_SUSPENDED   0x1
#define CUS_LPQ_ACTIVE  0x2
#define CUS_HQP_ACTIVE  0x3


// CU Command Word
#define CUC_SHIFT       0
#define CUC_NOP         0x0
#define CUC_START       0x10
#define CUC_RESUME      0x20
#define CUC_LOAD_BASE   0x60



// Control Block Command

#define CBF_EL          0x8000
#define CBF_S           0x4000
#define CBF_I           0x2000

#define CBC_NOP         0x0
#define CBC_IAS         0x1
#define CBC_CONFIG      0x2
#define CBC_MAS         0x3
#define CBC_TRANSMIT    0x4


// Control Block Status
#define CBS_F           0x0800
#define CBS_OK          0x2000
#define CBS_C           0x8000


// Error CODE
#define E_CBL_FULL    0
#define E_CBL_EMPTY   1
#define E_RFA_FULL    2
#define E_RFA_EMPTY   3


#define TCB_MAXSIZE     1518
#define CB_MAX_NUM      10

// Transmit Command Blocks
struct tcb {
    uint32_t tcb_tbd_array_addr;
    uint16_t tcb_byte_count;
    uint8_t tcb_thrs;
    uint8_t tcb_tbd_count;
    char tcb_data[TCB_MAXSIZE];
};


// Control Blocks
struct cb {
    volatile uint16_t cb_status;
    uint16_t cb_control;
    uint32_t cb_link;

    union cb_cmd_spec_data {
        struct tcb tcb;
    } cb_cmd_spec;


    struct cb *prev, *next;
    physaddr_t phy_addr;   
};




struct cbl {
    int cb_avail;
    int cb_wait;

    struct cb *start;
    struct cb *front, *rear;
};




// Network Interface Card
struct nic {
    uint32_t io_base;
    uint32_t io_size;

    struct cbl cbl;
};

int e100_attach(struct pci_func *pcif);

#endif	// JOS_KERN_E100_H
