
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start-0xc>:
.long MULTIBOOT_HEADER_FLAGS
.long CHECKSUM

.globl		_start
_start:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 03 00    	add    0x31bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fb                   	sti    
f0100009:	4f                   	dec    %edi
f010000a:	52                   	push   %edx
f010000b:	e4 66                	in     $0x66,%al

f010000c <_start>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 

	# Establish our own GDT in place of the boot loader's temporary GDT.
	lgdt	RELOC(mygdtdesc)		# load descriptor table
f0100015:	0f 01 15 18 00 11 00 	lgdtl  0x110018

	# Immediately reload all segment registers (including CS!)
	# with segment selectors from the new GDT.
	movl	$DATA_SEL, %eax			# Data segment selector
f010001c:	b8 10 00 00 00       	mov    $0x10,%eax
	movw	%ax,%ds				# -> DS: Data Segment
f0100021:	8e d8                	mov    %eax,%ds
	movw	%ax,%es				# -> ES: Extra Segment
f0100023:	8e c0                	mov    %eax,%es
	movw	%ax,%ss				# -> SS: Stack Segment
f0100025:	8e d0                	mov    %eax,%ss
	ljmp	$CODE_SEL,$relocated		# reload CS by jumping
f0100027:	ea 2e 00 10 f0 08 00 	ljmp   $0x8,$0xf010002e

f010002e <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002e:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100033:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100038:	e8 fd 00 00 00       	call   f010013a <i386_init>

f010003d <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003d:	eb fe                	jmp    f010003d <spin>
	...

f0100040 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
	cprintf("kernel warning at %s:%d: ", file, line);
f0100046:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100049:	89 44 24 08          	mov    %eax,0x8(%esp)
f010004d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100050:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100054:	c7 04 24 c0 1c 10 f0 	movl   $0xf0101cc0,(%esp)
f010005b:	e8 93 09 00 00       	call   f01009f3 <cprintf>
	vcprintf(fmt, ap);
f0100060:	8d 45 14             	lea    0x14(%ebp),%eax
f0100063:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100067:	8b 45 10             	mov    0x10(%ebp),%eax
f010006a:	89 04 24             	mov    %eax,(%esp)
f010006d:	e8 4e 09 00 00       	call   f01009c0 <vcprintf>
	cprintf("\n");
f0100072:	c7 04 24 6b 1d 10 f0 	movl   $0xf0101d6b,(%esp)
f0100079:	e8 75 09 00 00       	call   f01009f3 <cprintf>
	va_end(ap);
}
f010007e:	c9                   	leave  
f010007f:	c3                   	ret    

f0100080 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100080:	55                   	push   %ebp
f0100081:	89 e5                	mov    %esp,%ebp
f0100083:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	if (panicstr)
f0100086:	83 3d 40 03 11 f0 00 	cmpl   $0x0,0xf0110340
f010008d:	75 40                	jne    f01000cf <_panic+0x4f>
		goto dead;
	panicstr = fmt;
f010008f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100092:	a3 40 03 11 f0       	mov    %eax,0xf0110340

	va_start(ap, fmt);
	cprintf("kernel panic at %s:%d: ", file, line);
f0100097:	8b 45 0c             	mov    0xc(%ebp),%eax
f010009a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010009e:	8b 45 08             	mov    0x8(%ebp),%eax
f01000a1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000a5:	c7 04 24 da 1c 10 f0 	movl   $0xf0101cda,(%esp)
f01000ac:	e8 42 09 00 00       	call   f01009f3 <cprintf>
	vcprintf(fmt, ap);
f01000b1:	8d 45 14             	lea    0x14(%ebp),%eax
f01000b4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000b8:	8b 45 10             	mov    0x10(%ebp),%eax
f01000bb:	89 04 24             	mov    %eax,(%esp)
f01000be:	e8 fd 08 00 00       	call   f01009c0 <vcprintf>
	cprintf("\n");
f01000c3:	c7 04 24 6b 1d 10 f0 	movl   $0xf0101d6b,(%esp)
f01000ca:	e8 24 09 00 00       	call   f01009f3 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000cf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000d6:	e8 e5 06 00 00       	call   f01007c0 <monitor>
f01000db:	eb f2                	jmp    f01000cf <_panic+0x4f>

f01000dd <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f01000dd:	55                   	push   %ebp
f01000de:	89 e5                	mov    %esp,%ebp
f01000e0:	53                   	push   %ebx
f01000e1:	83 ec 14             	sub    $0x14,%esp
f01000e4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f01000e7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000eb:	c7 04 24 f2 1c 10 f0 	movl   $0xf0101cf2,(%esp)
f01000f2:	e8 fc 08 00 00       	call   f01009f3 <cprintf>
	if (x > 0)
f01000f7:	85 db                	test   %ebx,%ebx
f01000f9:	7e 0d                	jle    f0100108 <test_backtrace+0x2b>
		test_backtrace(x-1);
f01000fb:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01000fe:	89 04 24             	mov    %eax,(%esp)
f0100101:	e8 d7 ff ff ff       	call   f01000dd <test_backtrace>
f0100106:	eb 1c                	jmp    f0100124 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f0100108:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010010f:	00 
f0100110:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100117:	00 
f0100118:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010011f:	e8 d4 07 00 00       	call   f01008f8 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100124:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100128:	c7 04 24 0e 1d 10 f0 	movl   $0xf0101d0e,(%esp)
f010012f:	e8 bf 08 00 00       	call   f01009f3 <cprintf>
}
f0100134:	83 c4 14             	add    $0x14,%esp
f0100137:	5b                   	pop    %ebx
f0100138:	5d                   	pop    %ebp
f0100139:	c3                   	ret    

f010013a <i386_init>:

void
i386_init(void)
{
f010013a:	55                   	push   %ebp
f010013b:	89 e5                	mov    %esp,%ebp
f010013d:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100140:	b8 a0 09 11 f0       	mov    $0xf01109a0,%eax
f0100145:	2d 24 03 11 f0       	sub    $0xf0110324,%eax
f010014a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010014e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100155:	00 
f0100156:	c7 04 24 24 03 11 f0 	movl   $0xf0110324,(%esp)
f010015d:	e8 74 16 00 00       	call   f01017d6 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100162:	e8 42 03 00 00       	call   f01004a9 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100167:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f010016e:	00 
f010016f:	c7 04 24 29 1d 10 f0 	movl   $0xf0101d29,(%esp)
f0100176:	e8 78 08 00 00       	call   f01009f3 <cprintf>




	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f010017b:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f0100182:	e8 56 ff ff ff       	call   f01000dd <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100187:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010018e:	e8 2d 06 00 00       	call   f01007c0 <monitor>
f0100193:	eb f2                	jmp    f0100187 <i386_init+0x4d>
	...

f01001a0 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba 84 00 00 00       	mov    $0x84,%edx
f01001a8:	ec                   	in     (%dx),%al
f01001a9:	ec                   	in     (%dx),%al
f01001aa:	ec                   	in     (%dx),%al
f01001ab:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001ac:	5d                   	pop    %ebp
f01001ad:	c3                   	ret    

f01001ae <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001ae:	55                   	push   %ebp
f01001af:	89 e5                	mov    %esp,%ebp
f01001b1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b6:	ec                   	in     (%dx),%al
f01001b7:	89 c2                	mov    %eax,%edx
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01001be:	f6 c2 01             	test   $0x1,%dl
f01001c1:	74 09                	je     f01001cc <serial_proc_data+0x1e>
f01001c3:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001c8:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001c9:	0f b6 c0             	movzbl %al,%eax
}
f01001cc:	5d                   	pop    %ebp
f01001cd:	c3                   	ret    

f01001ce <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ce:	55                   	push   %ebp
f01001cf:	89 e5                	mov    %esp,%ebp
f01001d1:	57                   	push   %edi
f01001d2:	56                   	push   %esi
f01001d3:	53                   	push   %ebx
f01001d4:	83 ec 0c             	sub    $0xc,%esp
f01001d7:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
		cons.buf[cons.wpos++] = c;
f01001d9:	bb 84 05 11 f0       	mov    $0xf0110584,%ebx
f01001de:	bf 80 03 11 f0       	mov    $0xf0110380,%edi
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001e3:	eb 1e                	jmp    f0100203 <cons_intr+0x35>
		if (c == 0)
f01001e5:	85 c0                	test   %eax,%eax
f01001e7:	74 1a                	je     f0100203 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001e9:	8b 13                	mov    (%ebx),%edx
f01001eb:	88 04 17             	mov    %al,(%edi,%edx,1)
f01001ee:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01001f1:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01001f6:	0f 94 c2             	sete   %dl
f01001f9:	0f b6 d2             	movzbl %dl,%edx
f01001fc:	83 ea 01             	sub    $0x1,%edx
f01001ff:	21 d0                	and    %edx,%eax
f0100201:	89 03                	mov    %eax,(%ebx)
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100203:	ff d6                	call   *%esi
f0100205:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100208:	75 db                	jne    f01001e5 <cons_intr+0x17>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010020a:	83 c4 0c             	add    $0xc,%esp
f010020d:	5b                   	pop    %ebx
f010020e:	5e                   	pop    %esi
f010020f:	5f                   	pop    %edi
f0100210:	5d                   	pop    %ebp
f0100211:	c3                   	ret    

f0100212 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100212:	55                   	push   %ebp
f0100213:	89 e5                	mov    %esp,%ebp
f0100215:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100218:	b8 99 05 10 f0       	mov    $0xf0100599,%eax
f010021d:	e8 ac ff ff ff       	call   f01001ce <cons_intr>
}
f0100222:	c9                   	leave  
f0100223:	c3                   	ret    

f0100224 <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100224:	55                   	push   %ebp
f0100225:	89 e5                	mov    %esp,%ebp
f0100227:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f010022a:	83 3d 64 03 11 f0 00 	cmpl   $0x0,0xf0110364
f0100231:	74 0a                	je     f010023d <serial_intr+0x19>
		cons_intr(serial_proc_data);
f0100233:	b8 ae 01 10 f0       	mov    $0xf01001ae,%eax
f0100238:	e8 91 ff ff ff       	call   f01001ce <cons_intr>
}
f010023d:	c9                   	leave  
f010023e:	c3                   	ret    

f010023f <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f010023f:	55                   	push   %ebp
f0100240:	89 e5                	mov    %esp,%ebp
f0100242:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100245:	e8 da ff ff ff       	call   f0100224 <serial_intr>
	kbd_intr();
f010024a:	e8 c3 ff ff ff       	call   f0100212 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010024f:	8b 15 80 05 11 f0    	mov    0xf0110580,%edx
f0100255:	b8 00 00 00 00       	mov    $0x0,%eax
f010025a:	3b 15 84 05 11 f0    	cmp    0xf0110584,%edx
f0100260:	74 21                	je     f0100283 <cons_getc+0x44>
		c = cons.buf[cons.rpos++];
f0100262:	0f b6 82 80 03 11 f0 	movzbl -0xfeefc80(%edx),%eax
f0100269:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
f010026c:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.rpos = 0;
f0100272:	0f 94 c1             	sete   %cl
f0100275:	0f b6 c9             	movzbl %cl,%ecx
f0100278:	83 e9 01             	sub    $0x1,%ecx
f010027b:	21 ca                	and    %ecx,%edx
f010027d:	89 15 80 05 11 f0    	mov    %edx,0xf0110580
		return c;
	}
	return 0;
}
f0100283:	c9                   	leave  
f0100284:	c3                   	ret    

f0100285 <getchar>:
	cons_putc(c);
}

int
getchar(void)
{
f0100285:	55                   	push   %ebp
f0100286:	89 e5                	mov    %esp,%ebp
f0100288:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010028b:	e8 af ff ff ff       	call   f010023f <cons_getc>
f0100290:	85 c0                	test   %eax,%eax
f0100292:	74 f7                	je     f010028b <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100294:	c9                   	leave  
f0100295:	c3                   	ret    

f0100296 <iscons>:

int
iscons(int fdnum)
{
f0100296:	55                   	push   %ebp
f0100297:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100299:	b8 01 00 00 00       	mov    $0x1,%eax
f010029e:	5d                   	pop    %ebp
f010029f:	c3                   	ret    

f01002a0 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002a0:	55                   	push   %ebp
f01002a1:	89 e5                	mov    %esp,%ebp
f01002a3:	57                   	push   %edi
f01002a4:	56                   	push   %esi
f01002a5:	53                   	push   %ebx
f01002a6:	83 ec 2c             	sub    $0x2c,%esp
f01002a9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01002ac:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01002b1:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01002b2:	a8 20                	test   $0x20,%al
f01002b4:	75 21                	jne    f01002d7 <cons_putc+0x37>
f01002b6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01002bb:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01002c0:	e8 db fe ff ff       	call   f01001a0 <delay>
f01002c5:	89 f2                	mov    %esi,%edx
f01002c7:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01002c8:	a8 20                	test   $0x20,%al
f01002ca:	75 0b                	jne    f01002d7 <cons_putc+0x37>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002cc:	83 c3 01             	add    $0x1,%ebx
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01002cf:	81 fb 00 32 00 00    	cmp    $0x3200,%ebx
f01002d5:	75 e9                	jne    f01002c0 <cons_putc+0x20>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f01002d7:	0f b6 7d e4          	movzbl -0x1c(%ebp),%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002db:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002e0:	89 f8                	mov    %edi,%eax
f01002e2:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002e3:	b2 79                	mov    $0x79,%dl
f01002e5:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002e6:	84 c0                	test   %al,%al
f01002e8:	78 21                	js     f010030b <cons_putc+0x6b>
f01002ea:	bb 00 00 00 00       	mov    $0x0,%ebx
f01002ef:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f01002f4:	e8 a7 fe ff ff       	call   f01001a0 <delay>
f01002f9:	89 f2                	mov    %esi,%edx
f01002fb:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002fc:	84 c0                	test   %al,%al
f01002fe:	78 0b                	js     f010030b <cons_putc+0x6b>
f0100300:	83 c3 01             	add    $0x1,%ebx
f0100303:	81 fb 00 32 00 00    	cmp    $0x3200,%ebx
f0100309:	75 e9                	jne    f01002f4 <cons_putc+0x54>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010030b:	ba 78 03 00 00       	mov    $0x378,%edx
f0100310:	89 f8                	mov    %edi,%eax
f0100312:	ee                   	out    %al,(%dx)
f0100313:	b2 7a                	mov    $0x7a,%dl
f0100315:	b8 0d 00 00 00       	mov    $0xd,%eax
f010031a:	ee                   	out    %al,(%dx)
f010031b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100320:	ee                   	out    %al,(%dx)
extern int ch_color;

static void
cga_putc(int c)
{
    c = c + (ch_color << 8);
f0100321:	a1 20 03 11 f0       	mov    0xf0110320,%eax
f0100326:	c1 e0 08             	shl    $0x8,%eax
f0100329:	03 45 e4             	add    -0x1c(%ebp),%eax

	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010032c:	a9 00 ff ff ff       	test   $0xffffff00,%eax
f0100331:	75 03                	jne    f0100336 <cons_putc+0x96>
		c |= 0x0700;
f0100333:	80 cc 07             	or     $0x7,%ah

	switch (c & 0xff) {
f0100336:	0f b6 d0             	movzbl %al,%edx
f0100339:	83 fa 09             	cmp    $0x9,%edx
f010033c:	0f 84 80 00 00 00    	je     f01003c2 <cons_putc+0x122>
f0100342:	83 fa 09             	cmp    $0x9,%edx
f0100345:	7f 0b                	jg     f0100352 <cons_putc+0xb2>
f0100347:	83 fa 08             	cmp    $0x8,%edx
f010034a:	0f 85 a6 00 00 00    	jne    f01003f6 <cons_putc+0x156>
f0100350:	eb 18                	jmp    f010036a <cons_putc+0xca>
f0100352:	83 fa 0a             	cmp    $0xa,%edx
f0100355:	8d 76 00             	lea    0x0(%esi),%esi
f0100358:	74 3e                	je     f0100398 <cons_putc+0xf8>
f010035a:	83 fa 0d             	cmp    $0xd,%edx
f010035d:	8d 76 00             	lea    0x0(%esi),%esi
f0100360:	0f 85 90 00 00 00    	jne    f01003f6 <cons_putc+0x156>
f0100366:	66 90                	xchg   %ax,%ax
f0100368:	eb 36                	jmp    f01003a0 <cons_putc+0x100>
	case '\b':
		if (crt_pos > 0) {
f010036a:	0f b7 15 70 03 11 f0 	movzwl 0xf0110370,%edx
f0100371:	66 85 d2             	test   %dx,%dx
f0100374:	0f 84 e7 00 00 00    	je     f0100461 <cons_putc+0x1c1>
			crt_pos--;
f010037a:	83 ea 01             	sub    $0x1,%edx
f010037d:	66 89 15 70 03 11 f0 	mov    %dx,0xf0110370
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100384:	0f b7 d2             	movzwl %dx,%edx
f0100387:	b0 00                	mov    $0x0,%al
f0100389:	83 c8 20             	or     $0x20,%eax
f010038c:	8b 0d 6c 03 11 f0    	mov    0xf011036c,%ecx
f0100392:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f0100396:	eb 7c                	jmp    f0100414 <cons_putc+0x174>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100398:	66 83 05 70 03 11 f0 	addw   $0x50,0xf0110370
f010039f:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003a0:	0f b7 05 70 03 11 f0 	movzwl 0xf0110370,%eax
f01003a7:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003ad:	c1 e8 10             	shr    $0x10,%eax
f01003b0:	66 c1 e8 06          	shr    $0x6,%ax
f01003b4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b7:	c1 e0 04             	shl    $0x4,%eax
f01003ba:	66 a3 70 03 11 f0    	mov    %ax,0xf0110370
f01003c0:	eb 52                	jmp    f0100414 <cons_putc+0x174>
		break;
	case '\t':
		cons_putc(' ');
f01003c2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c7:	e8 d4 fe ff ff       	call   f01002a0 <cons_putc>
		cons_putc(' ');
f01003cc:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d1:	e8 ca fe ff ff       	call   f01002a0 <cons_putc>
		cons_putc(' ');
f01003d6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003db:	e8 c0 fe ff ff       	call   f01002a0 <cons_putc>
		cons_putc(' ');
f01003e0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e5:	e8 b6 fe ff ff       	call   f01002a0 <cons_putc>
		cons_putc(' ');
f01003ea:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ef:	e8 ac fe ff ff       	call   f01002a0 <cons_putc>
f01003f4:	eb 1e                	jmp    f0100414 <cons_putc+0x174>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003f6:	0f b7 15 70 03 11 f0 	movzwl 0xf0110370,%edx
f01003fd:	0f b7 da             	movzwl %dx,%ebx
f0100400:	8b 0d 6c 03 11 f0    	mov    0xf011036c,%ecx
f0100406:	66 89 04 59          	mov    %ax,(%ecx,%ebx,2)
f010040a:	83 c2 01             	add    $0x1,%edx
f010040d:	66 89 15 70 03 11 f0 	mov    %dx,0xf0110370
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100414:	66 81 3d 70 03 11 f0 	cmpw   $0x7cf,0xf0110370
f010041b:	cf 07 
f010041d:	76 42                	jbe    f0100461 <cons_putc+0x1c1>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010041f:	a1 6c 03 11 f0       	mov    0xf011036c,%eax
f0100424:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010042b:	00 
f010042c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100432:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100436:	89 04 24             	mov    %eax,(%esp)
f0100439:	e8 f7 13 00 00       	call   f0101835 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010043e:	8b 15 6c 03 11 f0    	mov    0xf011036c,%edx
f0100444:	b8 80 07 00 00       	mov    $0x780,%eax
f0100449:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010044f:	83 c0 01             	add    $0x1,%eax
f0100452:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100457:	75 f0                	jne    f0100449 <cons_putc+0x1a9>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100459:	66 83 2d 70 03 11 f0 	subw   $0x50,0xf0110370
f0100460:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100461:	8b 0d 68 03 11 f0    	mov    0xf0110368,%ecx
f0100467:	89 cb                	mov    %ecx,%ebx
f0100469:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046e:	89 ca                	mov    %ecx,%edx
f0100470:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100471:	0f b7 35 70 03 11 f0 	movzwl 0xf0110370,%esi
f0100478:	83 c1 01             	add    $0x1,%ecx
f010047b:	89 f0                	mov    %esi,%eax
f010047d:	66 c1 e8 08          	shr    $0x8,%ax
f0100481:	89 ca                	mov    %ecx,%edx
f0100483:	ee                   	out    %al,(%dx)
f0100484:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100489:	89 da                	mov    %ebx,%edx
f010048b:	ee                   	out    %al,(%dx)
f010048c:	89 f0                	mov    %esi,%eax
f010048e:	89 ca                	mov    %ecx,%edx
f0100490:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100491:	83 c4 2c             	add    $0x2c,%esp
f0100494:	5b                   	pop    %ebx
f0100495:	5e                   	pop    %esi
f0100496:	5f                   	pop    %edi
f0100497:	5d                   	pop    %ebp
f0100498:	c3                   	ret    

f0100499 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100499:	55                   	push   %ebp
f010049a:	89 e5                	mov    %esp,%ebp
f010049c:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010049f:	8b 45 08             	mov    0x8(%ebp),%eax
f01004a2:	e8 f9 fd ff ff       	call   f01002a0 <cons_putc>
}
f01004a7:	c9                   	leave  
f01004a8:	c3                   	ret    

f01004a9 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004a9:	55                   	push   %ebp
f01004aa:	89 e5                	mov    %esp,%ebp
f01004ac:	57                   	push   %edi
f01004ad:	56                   	push   %esi
f01004ae:	53                   	push   %ebx
f01004af:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01004b2:	b8 00 80 0b f0       	mov    $0xf00b8000,%eax
f01004b7:	0f b7 10             	movzwl (%eax),%edx
	*cp = (uint16_t) 0xA55A;
f01004ba:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
f01004bf:	0f b7 00             	movzwl (%eax),%eax
f01004c2:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01004c6:	74 11                	je     f01004d9 <cons_init+0x30>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01004c8:	c7 05 68 03 11 f0 b4 	movl   $0x3b4,0xf0110368
f01004cf:	03 00 00 
f01004d2:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f01004d7:	eb 16                	jmp    f01004ef <cons_init+0x46>
	} else {
		*cp = was;
f01004d9:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01004e0:	c7 05 68 03 11 f0 d4 	movl   $0x3d4,0xf0110368
f01004e7:	03 00 00 
f01004ea:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f01004ef:	8b 0d 68 03 11 f0    	mov    0xf0110368,%ecx
f01004f5:	89 cb                	mov    %ecx,%ebx
f01004f7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004fc:	89 ca                	mov    %ecx,%edx
f01004fe:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01004ff:	83 c1 01             	add    $0x1,%ecx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100502:	89 ca                	mov    %ecx,%edx
f0100504:	ec                   	in     (%dx),%al
f0100505:	0f b6 f8             	movzbl %al,%edi
f0100508:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010050b:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100510:	89 da                	mov    %ebx,%edx
f0100512:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100513:	89 ca                	mov    %ecx,%edx
f0100515:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100516:	89 35 6c 03 11 f0    	mov    %esi,0xf011036c
	crt_pos = pos;
f010051c:	0f b6 c8             	movzbl %al,%ecx
f010051f:	09 cf                	or     %ecx,%edi
f0100521:	66 89 3d 70 03 11 f0 	mov    %di,0xf0110370
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100528:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f010052d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100532:	89 da                	mov    %ebx,%edx
f0100534:	ee                   	out    %al,(%dx)
f0100535:	b2 fb                	mov    $0xfb,%dl
f0100537:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010053c:	ee                   	out    %al,(%dx)
f010053d:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f0100542:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100547:	89 ca                	mov    %ecx,%edx
f0100549:	ee                   	out    %al,(%dx)
f010054a:	b2 f9                	mov    $0xf9,%dl
f010054c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100551:	ee                   	out    %al,(%dx)
f0100552:	b2 fb                	mov    $0xfb,%dl
f0100554:	b8 03 00 00 00       	mov    $0x3,%eax
f0100559:	ee                   	out    %al,(%dx)
f010055a:	b2 fc                	mov    $0xfc,%dl
f010055c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100561:	ee                   	out    %al,(%dx)
f0100562:	b2 f9                	mov    $0xf9,%dl
f0100564:	b8 01 00 00 00       	mov    $0x1,%eax
f0100569:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056a:	b2 fd                	mov    $0xfd,%dl
f010056c:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010056d:	3c ff                	cmp    $0xff,%al
f010056f:	0f 95 c0             	setne  %al
f0100572:	0f b6 f0             	movzbl %al,%esi
f0100575:	89 35 64 03 11 f0    	mov    %esi,0xf0110364
f010057b:	89 da                	mov    %ebx,%edx
f010057d:	ec                   	in     (%dx),%al
f010057e:	89 ca                	mov    %ecx,%edx
f0100580:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100581:	85 f6                	test   %esi,%esi
f0100583:	75 0c                	jne    f0100591 <cons_init+0xe8>
		cprintf("Serial port does not exist!\n");
f0100585:	c7 04 24 44 1d 10 f0 	movl   $0xf0101d44,(%esp)
f010058c:	e8 62 04 00 00       	call   f01009f3 <cprintf>
}
f0100591:	83 c4 1c             	add    $0x1c,%esp
f0100594:	5b                   	pop    %ebx
f0100595:	5e                   	pop    %esi
f0100596:	5f                   	pop    %edi
f0100597:	5d                   	pop    %ebp
f0100598:	c3                   	ret    

f0100599 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100599:	55                   	push   %ebp
f010059a:	89 e5                	mov    %esp,%ebp
f010059c:	53                   	push   %ebx
f010059d:	83 ec 14             	sub    $0x14,%esp
f01005a0:	ba 64 00 00 00       	mov    $0x64,%edx
f01005a5:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01005a6:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01005ab:	a8 01                	test   $0x1,%al
f01005ad:	0f 84 d9 00 00 00    	je     f010068c <kbd_proc_data+0xf3>
f01005b3:	b2 60                	mov    $0x60,%dl
f01005b5:	ec                   	in     (%dx),%al
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01005b6:	3c e0                	cmp    $0xe0,%al
f01005b8:	75 11                	jne    f01005cb <kbd_proc_data+0x32>
		// E0 escape character
		shift |= E0ESC;
f01005ba:	83 0d 60 03 11 f0 40 	orl    $0x40,0xf0110360
f01005c1:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
f01005c6:	e9 c1 00 00 00       	jmp    f010068c <kbd_proc_data+0xf3>
	} else if (data & 0x80) {
f01005cb:	84 c0                	test   %al,%al
f01005cd:	79 32                	jns    f0100601 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01005cf:	8b 15 60 03 11 f0    	mov    0xf0110360,%edx
f01005d5:	f6 c2 40             	test   $0x40,%dl
f01005d8:	75 03                	jne    f01005dd <kbd_proc_data+0x44>
f01005da:	83 e0 7f             	and    $0x7f,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f01005dd:	0f b6 c0             	movzbl %al,%eax
f01005e0:	0f b6 80 80 1d 10 f0 	movzbl -0xfefe280(%eax),%eax
f01005e7:	83 c8 40             	or     $0x40,%eax
f01005ea:	0f b6 c0             	movzbl %al,%eax
f01005ed:	f7 d0                	not    %eax
f01005ef:	21 c2                	and    %eax,%edx
f01005f1:	89 15 60 03 11 f0    	mov    %edx,0xf0110360
f01005f7:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
f01005fc:	e9 8b 00 00 00       	jmp    f010068c <kbd_proc_data+0xf3>
	} else if (shift & E0ESC) {
f0100601:	8b 15 60 03 11 f0    	mov    0xf0110360,%edx
f0100607:	f6 c2 40             	test   $0x40,%dl
f010060a:	74 0c                	je     f0100618 <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010060c:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f010060f:	83 e2 bf             	and    $0xffffffbf,%edx
f0100612:	89 15 60 03 11 f0    	mov    %edx,0xf0110360
	}

	shift |= shiftcode[data];
f0100618:	0f b6 c0             	movzbl %al,%eax
	shift ^= togglecode[data];
f010061b:	0f b6 90 80 1d 10 f0 	movzbl -0xfefe280(%eax),%edx
f0100622:	0b 15 60 03 11 f0    	or     0xf0110360,%edx
f0100628:	0f b6 88 80 1e 10 f0 	movzbl -0xfefe180(%eax),%ecx
f010062f:	31 ca                	xor    %ecx,%edx
f0100631:	89 15 60 03 11 f0    	mov    %edx,0xf0110360

	c = charcode[shift & (CTL | SHIFT)][data];
f0100637:	89 d1                	mov    %edx,%ecx
f0100639:	83 e1 03             	and    $0x3,%ecx
f010063c:	8b 0c 8d 80 1f 10 f0 	mov    -0xfefe080(,%ecx,4),%ecx
f0100643:	0f b6 1c 01          	movzbl (%ecx,%eax,1),%ebx
	if (shift & CAPSLOCK) {
f0100647:	f6 c2 08             	test   $0x8,%dl
f010064a:	74 1a                	je     f0100666 <kbd_proc_data+0xcd>
		if ('a' <= c && c <= 'z')
f010064c:	89 d9                	mov    %ebx,%ecx
f010064e:	8d 43 9f             	lea    -0x61(%ebx),%eax
f0100651:	83 f8 19             	cmp    $0x19,%eax
f0100654:	77 05                	ja     f010065b <kbd_proc_data+0xc2>
			c += 'A' - 'a';
f0100656:	83 eb 20             	sub    $0x20,%ebx
f0100659:	eb 0b                	jmp    f0100666 <kbd_proc_data+0xcd>
		else if ('A' <= c && c <= 'Z')
f010065b:	83 e9 41             	sub    $0x41,%ecx
f010065e:	83 f9 19             	cmp    $0x19,%ecx
f0100661:	77 03                	ja     f0100666 <kbd_proc_data+0xcd>
			c += 'a' - 'A';
f0100663:	83 c3 20             	add    $0x20,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100666:	f7 d2                	not    %edx
f0100668:	f6 c2 06             	test   $0x6,%dl
f010066b:	75 1f                	jne    f010068c <kbd_proc_data+0xf3>
f010066d:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100673:	75 17                	jne    f010068c <kbd_proc_data+0xf3>
		cprintf("Rebooting!\n");
f0100675:	c7 04 24 61 1d 10 f0 	movl   $0xf0101d61,(%esp)
f010067c:	e8 72 03 00 00       	call   f01009f3 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100681:	ba 92 00 00 00       	mov    $0x92,%edx
f0100686:	b8 03 00 00 00       	mov    $0x3,%eax
f010068b:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010068c:	89 d8                	mov    %ebx,%eax
f010068e:	83 c4 14             	add    $0x14,%esp
f0100691:	5b                   	pop    %ebx
f0100692:	5d                   	pop    %ebp
f0100693:	c3                   	ret    
	...

f01006a0 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f01006a0:	55                   	push   %ebp
f01006a1:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f01006a3:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f01006a6:	5d                   	pop    %ebp
f01006a7:	c3                   	ret    

f01006a8 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006a8:	55                   	push   %ebp
f01006a9:	89 e5                	mov    %esp,%ebp
f01006ab:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006ae:	c7 04 24 90 1f 10 f0 	movl   $0xf0101f90,(%esp)
f01006b5:	e8 39 03 00 00       	call   f01009f3 <cprintf>
	cprintf("  _start %08x (virt)  %08x (phys)\n", _start, _start - KERNBASE);
f01006ba:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006c1:	00 
f01006c2:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006c9:	f0 
f01006ca:	c7 04 24 50 20 10 f0 	movl   $0xf0102050,(%esp)
f01006d1:	e8 1d 03 00 00       	call   f01009f3 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d6:	c7 44 24 08 a5 1c 10 	movl   $0x101ca5,0x8(%esp)
f01006dd:	00 
f01006de:	c7 44 24 04 a5 1c 10 	movl   $0xf0101ca5,0x4(%esp)
f01006e5:	f0 
f01006e6:	c7 04 24 74 20 10 f0 	movl   $0xf0102074,(%esp)
f01006ed:	e8 01 03 00 00       	call   f01009f3 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006f2:	c7 44 24 08 24 03 11 	movl   $0x110324,0x8(%esp)
f01006f9:	00 
f01006fa:	c7 44 24 04 24 03 11 	movl   $0xf0110324,0x4(%esp)
f0100701:	f0 
f0100702:	c7 04 24 98 20 10 f0 	movl   $0xf0102098,(%esp)
f0100709:	e8 e5 02 00 00       	call   f01009f3 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010070e:	c7 44 24 08 a0 09 11 	movl   $0x1109a0,0x8(%esp)
f0100715:	00 
f0100716:	c7 44 24 04 a0 09 11 	movl   $0xf01109a0,0x4(%esp)
f010071d:	f0 
f010071e:	c7 04 24 bc 20 10 f0 	movl   $0xf01020bc,(%esp)
f0100725:	e8 c9 02 00 00       	call   f01009f3 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010072a:	b8 9f 0d 11 f0       	mov    $0xf0110d9f,%eax
f010072f:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100734:	89 c2                	mov    %eax,%edx
f0100736:	c1 fa 1f             	sar    $0x1f,%edx
f0100739:	c1 ea 16             	shr    $0x16,%edx
f010073c:	8d 04 02             	lea    (%edx,%eax,1),%eax
f010073f:	c1 f8 0a             	sar    $0xa,%eax
f0100742:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100746:	c7 04 24 e0 20 10 f0 	movl   $0xf01020e0,(%esp)
f010074d:	e8 a1 02 00 00       	call   f01009f3 <cprintf>
		(end-_start+1023)/1024);
	return 0;
}
f0100752:	b8 00 00 00 00       	mov    $0x0,%eax
f0100757:	c9                   	leave  
f0100758:	c3                   	ret    

f0100759 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100759:	55                   	push   %ebp
f010075a:	89 e5                	mov    %esp,%ebp
f010075c:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010075f:	a1 24 22 10 f0       	mov    0xf0102224,%eax
f0100764:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100768:	a1 20 22 10 f0       	mov    0xf0102220,%eax
f010076d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100771:	c7 04 24 a9 1f 10 f0 	movl   $0xf0101fa9,(%esp)
f0100778:	e8 76 02 00 00       	call   f01009f3 <cprintf>
f010077d:	a1 30 22 10 f0       	mov    0xf0102230,%eax
f0100782:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100786:	a1 2c 22 10 f0       	mov    0xf010222c,%eax
f010078b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010078f:	c7 04 24 a9 1f 10 f0 	movl   $0xf0101fa9,(%esp)
f0100796:	e8 58 02 00 00       	call   f01009f3 <cprintf>
f010079b:	a1 3c 22 10 f0       	mov    0xf010223c,%eax
f01007a0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007a4:	a1 38 22 10 f0       	mov    0xf0102238,%eax
f01007a9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007ad:	c7 04 24 a9 1f 10 f0 	movl   $0xf0101fa9,(%esp)
f01007b4:	e8 3a 02 00 00       	call   f01009f3 <cprintf>
	return 0;
}
f01007b9:	b8 00 00 00 00       	mov    $0x0,%eax
f01007be:	c9                   	leave  
f01007bf:	c3                   	ret    

f01007c0 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007c0:	55                   	push   %ebp
f01007c1:	89 e5                	mov    %esp,%ebp
f01007c3:	57                   	push   %edi
f01007c4:	56                   	push   %esi
f01007c5:	53                   	push   %ebx
f01007c6:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("%CredWelcome %Cwhtto %Cgrnthe %CorgJOS %Cgrykernel %Cpurmonitor!\n");
f01007c9:	c7 04 24 0c 21 10 f0 	movl   $0xf010210c,(%esp)
f01007d0:	e8 1e 02 00 00       	call   f01009f3 <cprintf>
	cprintf("%CcynType %Cylw'help' %C142for a %C201list %C088of %Cwhtcommands.\n");
f01007d5:	c7 04 24 50 21 10 f0 	movl   $0xf0102150,(%esp)
f01007dc:	e8 12 02 00 00       	call   f01009f3 <cprintf>

	while (1) {
		buf = readline("K> ");
f01007e1:	c7 04 24 b2 1f 10 f0 	movl   $0xf0101fb2,(%esp)
f01007e8:	e8 63 0d 00 00       	call   f0101550 <readline>
f01007ed:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007ef:	85 c0                	test   %eax,%eax
f01007f1:	74 ee                	je     f01007e1 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007f3:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
f01007fa:	be 00 00 00 00       	mov    $0x0,%esi
f01007ff:	eb 06                	jmp    f0100807 <monitor+0x47>
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100801:	c6 03 00             	movb   $0x0,(%ebx)
f0100804:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100807:	0f b6 03             	movzbl (%ebx),%eax
f010080a:	84 c0                	test   %al,%al
f010080c:	74 6d                	je     f010087b <monitor+0xbb>
f010080e:	0f be c0             	movsbl %al,%eax
f0100811:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100815:	c7 04 24 b6 1f 10 f0 	movl   $0xf0101fb6,(%esp)
f010081c:	e8 5d 0f 00 00       	call   f010177e <strchr>
f0100821:	85 c0                	test   %eax,%eax
f0100823:	75 dc                	jne    f0100801 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100825:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100828:	74 51                	je     f010087b <monitor+0xbb>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010082a:	83 fe 0f             	cmp    $0xf,%esi
f010082d:	8d 76 00             	lea    0x0(%esi),%esi
f0100830:	75 16                	jne    f0100848 <monitor+0x88>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100832:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100839:	00 
f010083a:	c7 04 24 bb 1f 10 f0 	movl   $0xf0101fbb,(%esp)
f0100841:	e8 ad 01 00 00       	call   f01009f3 <cprintf>
f0100846:	eb 99                	jmp    f01007e1 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100848:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010084c:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f010084f:	0f b6 03             	movzbl (%ebx),%eax
f0100852:	84 c0                	test   %al,%al
f0100854:	75 0c                	jne    f0100862 <monitor+0xa2>
f0100856:	eb af                	jmp    f0100807 <monitor+0x47>
			buf++;
f0100858:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010085b:	0f b6 03             	movzbl (%ebx),%eax
f010085e:	84 c0                	test   %al,%al
f0100860:	74 a5                	je     f0100807 <monitor+0x47>
f0100862:	0f be c0             	movsbl %al,%eax
f0100865:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100869:	c7 04 24 b6 1f 10 f0 	movl   $0xf0101fb6,(%esp)
f0100870:	e8 09 0f 00 00       	call   f010177e <strchr>
f0100875:	85 c0                	test   %eax,%eax
f0100877:	74 df                	je     f0100858 <monitor+0x98>
f0100879:	eb 8c                	jmp    f0100807 <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f010087b:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100882:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100883:	85 f6                	test   %esi,%esi
f0100885:	0f 84 56 ff ff ff    	je     f01007e1 <monitor+0x21>
f010088b:	bb 20 22 10 f0       	mov    $0xf0102220,%ebx
f0100890:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100895:	8b 03                	mov    (%ebx),%eax
f0100897:	89 44 24 04          	mov    %eax,0x4(%esp)
f010089b:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010089e:	89 04 24             	mov    %eax,(%esp)
f01008a1:	e8 63 0e 00 00       	call   f0101709 <strcmp>
f01008a6:	85 c0                	test   %eax,%eax
f01008a8:	75 23                	jne    f01008cd <monitor+0x10d>
			return commands[i].func(argc, argv, tf);
f01008aa:	6b ff 0c             	imul   $0xc,%edi,%edi
f01008ad:	8b 45 08             	mov    0x8(%ebp),%eax
f01008b0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008b4:	8d 45 a8             	lea    -0x58(%ebp),%eax
f01008b7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008bb:	89 34 24             	mov    %esi,(%esp)
f01008be:	ff 97 28 22 10 f0    	call   *-0xfefddd8(%edi)
	cprintf("%CcynType %Cylw'help' %C142for a %C201list %C088of %Cwhtcommands.\n");

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008c4:	85 c0                	test   %eax,%eax
f01008c6:	78 28                	js     f01008f0 <monitor+0x130>
f01008c8:	e9 14 ff ff ff       	jmp    f01007e1 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008cd:	83 c7 01             	add    $0x1,%edi
f01008d0:	83 c3 0c             	add    $0xc,%ebx
f01008d3:	83 ff 03             	cmp    $0x3,%edi
f01008d6:	75 bd                	jne    f0100895 <monitor+0xd5>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008d8:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008db:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008df:	c7 04 24 d8 1f 10 f0 	movl   $0xf0101fd8,(%esp)
f01008e6:	e8 08 01 00 00       	call   f01009f3 <cprintf>
f01008eb:	e9 f1 fe ff ff       	jmp    f01007e1 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008f0:	83 c4 5c             	add    $0x5c,%esp
f01008f3:	5b                   	pop    %ebx
f01008f4:	5e                   	pop    %esi
f01008f5:	5f                   	pop    %edi
f01008f6:	5d                   	pop    %ebp
f01008f7:	c3                   	ret    

f01008f8 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008f8:	55                   	push   %ebp
f01008f9:	89 e5                	mov    %esp,%ebp
f01008fb:	57                   	push   %edi
f01008fc:	56                   	push   %esi
f01008fd:	53                   	push   %ebx
f01008fe:	83 ec 5c             	sub    $0x5c,%esp
    uint32_t *ebp, *eip;
    uint32_t arg0, arg1, arg2, arg3, arg4;
    struct Eipdebuginfo debuginfo;
    struct Eipdebuginfo *eipinfo = &debuginfo;

    ebp = (uint32_t*) read_ebp ();
f0100901:	89 eb                	mov    %ebp,%ebx

    cprintf ("Stack backtrace:\n");
f0100903:	c7 04 24 ee 1f 10 f0 	movl   $0xf0101fee,(%esp)
f010090a:	e8 e4 00 00 00       	call   f01009f3 <cprintf>
    while (ebp != 0) {
f010090f:	85 db                	test   %ebx,%ebx
f0100911:	0f 84 9a 00 00 00    	je     f01009b1 <mon_backtrace+0xb9>

        eip = (uint32_t*) ebp[1];
f0100917:	8b 73 04             	mov    0x4(%ebx),%esi
        arg0 = ebp[2];
f010091a:	8b 43 08             	mov    0x8(%ebx),%eax
f010091d:	89 45 b8             	mov    %eax,-0x48(%ebp)
        arg1 = ebp[3];
f0100920:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100923:	89 45 bc             	mov    %eax,-0x44(%ebp)
        arg2 = ebp[4];
f0100926:	8b 43 10             	mov    0x10(%ebx),%eax
f0100929:	89 45 c0             	mov    %eax,-0x40(%ebp)
        arg3 = ebp[5];
f010092c:	8b 43 14             	mov    0x14(%ebx),%eax
f010092f:	89 45 c4             	mov    %eax,-0x3c(%ebp)
        arg4 = ebp[6];
f0100932:	8b 7b 18             	mov    0x18(%ebx),%edi
        
        debuginfo_eip ((uintptr_t) eip, eipinfo);
f0100935:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100938:	89 44 24 04          	mov    %eax,0x4(%esp)
f010093c:	89 34 24             	mov    %esi,(%esp)
f010093f:	e8 0a 02 00 00       	call   f0100b4e <debuginfo_eip>

        cprintf ("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, eip, arg0, arg1, arg2, arg3, arg4);
f0100944:	89 7c 24 1c          	mov    %edi,0x1c(%esp)
f0100948:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010094b:	89 44 24 18          	mov    %eax,0x18(%esp)
f010094f:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0100952:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100956:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0100959:	89 44 24 10          	mov    %eax,0x10(%esp)
f010095d:	8b 45 b8             	mov    -0x48(%ebp),%eax
f0100960:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100964:	89 74 24 08          	mov    %esi,0x8(%esp)
f0100968:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010096c:	c7 04 24 94 21 10 f0 	movl   $0xf0102194,(%esp)
f0100973:	e8 7b 00 00 00       	call   f01009f3 <cprintf>
        cprintf ("         %s:%d: %.*s+%d\n", 
f0100978:	2b 75 e0             	sub    -0x20(%ebp),%esi
f010097b:	89 74 24 14          	mov    %esi,0x14(%esp)
f010097f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100982:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100986:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100989:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010098d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100990:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100994:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100997:	89 44 24 04          	mov    %eax,0x4(%esp)
f010099b:	c7 04 24 00 20 10 f0 	movl   $0xf0102000,(%esp)
f01009a2:	e8 4c 00 00 00       	call   f01009f3 <cprintf>
            eipinfo->eip_line, 
            eipinfo->eip_fn_namelen, eipinfo->eip_fn_name,
            (uint32_t) eip - eipinfo->eip_fn_addr);


        ebp = (uint32_t*) ebp[0];
f01009a7:	8b 1b                	mov    (%ebx),%ebx
    struct Eipdebuginfo *eipinfo = &debuginfo;

    ebp = (uint32_t*) read_ebp ();

    cprintf ("Stack backtrace:\n");
    while (ebp != 0) {
f01009a9:	85 db                	test   %ebx,%ebx
f01009ab:	0f 85 66 ff ff ff    	jne    f0100917 <mon_backtrace+0x1f>

        ebp = (uint32_t*) ebp[0];
    }
	
    return 0;
}
f01009b1:	b8 00 00 00 00       	mov    $0x0,%eax
f01009b6:	83 c4 5c             	add    $0x5c,%esp
f01009b9:	5b                   	pop    %ebx
f01009ba:	5e                   	pop    %esi
f01009bb:	5f                   	pop    %edi
f01009bc:	5d                   	pop    %ebp
f01009bd:	c3                   	ret    
	...

f01009c0 <vcprintf>:
	*cnt++;
}

int
vcprintf(const char *fmt, va_list ap)
{
f01009c0:	55                   	push   %ebp
f01009c1:	89 e5                	mov    %esp,%ebp
f01009c3:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01009c6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009cd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009d0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009d4:	8b 45 08             	mov    0x8(%ebp),%eax
f01009d7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009db:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009de:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009e2:	c7 04 24 0d 0a 10 f0 	movl   $0xf0100a0d,(%esp)
f01009e9:	e8 e2 04 00 00       	call   f0100ed0 <vprintfmt>
	return cnt;
}
f01009ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009f1:	c9                   	leave  
f01009f2:	c3                   	ret    

f01009f3 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009f3:	55                   	push   %ebp
f01009f4:	89 e5                	mov    %esp,%ebp
f01009f6:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
	cnt = vcprintf(fmt, ap);
f01009f9:	8d 45 0c             	lea    0xc(%ebp),%eax
f01009fc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a00:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a03:	89 04 24             	mov    %eax,(%esp)
f0100a06:	e8 b5 ff ff ff       	call   f01009c0 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a0b:	c9                   	leave  
f0100a0c:	c3                   	ret    

f0100a0d <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100a0d:	55                   	push   %ebp
f0100a0e:	89 e5                	mov    %esp,%ebp
f0100a10:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100a13:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a16:	89 04 24             	mov    %eax,(%esp)
f0100a19:	e8 7b fa ff ff       	call   f0100499 <cputchar>
	*cnt++;
}
f0100a1e:	c9                   	leave  
f0100a1f:	c3                   	ret    

f0100a20 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a20:	55                   	push   %ebp
f0100a21:	89 e5                	mov    %esp,%ebp
f0100a23:	57                   	push   %edi
f0100a24:	56                   	push   %esi
f0100a25:	53                   	push   %ebx
f0100a26:	83 ec 14             	sub    $0x14,%esp
f0100a29:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a2c:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a2f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100a32:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a35:	8b 1a                	mov    (%edx),%ebx
f0100a37:	8b 01                	mov    (%ecx),%eax
f0100a39:	89 45 ec             	mov    %eax,-0x14(%ebp)
	
	while (l <= r) {
f0100a3c:	39 c3                	cmp    %eax,%ebx
f0100a3e:	0f 8f 9c 00 00 00    	jg     f0100ae0 <stab_binsearch+0xc0>
f0100a44:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		int true_m = (l + r) / 2, m = true_m;
f0100a4b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a4e:	01 d8                	add    %ebx,%eax
f0100a50:	89 c7                	mov    %eax,%edi
f0100a52:	c1 ef 1f             	shr    $0x1f,%edi
f0100a55:	01 c7                	add    %eax,%edi
f0100a57:	d1 ff                	sar    %edi
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a59:	39 df                	cmp    %ebx,%edi
f0100a5b:	7c 33                	jl     f0100a90 <stab_binsearch+0x70>
f0100a5d:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100a60:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100a63:	0f b6 44 82 04       	movzbl 0x4(%edx,%eax,4),%eax
f0100a68:	39 f0                	cmp    %esi,%eax
f0100a6a:	0f 84 bc 00 00 00    	je     f0100b2c <stab_binsearch+0x10c>
f0100a70:	8d 44 7f fd          	lea    -0x3(%edi,%edi,2),%eax
f0100a74:	8d 54 82 04          	lea    0x4(%edx,%eax,4),%edx
f0100a78:	89 f8                	mov    %edi,%eax
			m--;
f0100a7a:	83 e8 01             	sub    $0x1,%eax
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a7d:	39 d8                	cmp    %ebx,%eax
f0100a7f:	7c 0f                	jl     f0100a90 <stab_binsearch+0x70>
f0100a81:	0f b6 0a             	movzbl (%edx),%ecx
f0100a84:	83 ea 0c             	sub    $0xc,%edx
f0100a87:	39 f1                	cmp    %esi,%ecx
f0100a89:	75 ef                	jne    f0100a7a <stab_binsearch+0x5a>
f0100a8b:	e9 9e 00 00 00       	jmp    f0100b2e <stab_binsearch+0x10e>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a90:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0100a93:	eb 3c                	jmp    f0100ad1 <stab_binsearch+0xb1>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a95:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100a98:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
f0100a9a:	8d 5f 01             	lea    0x1(%edi),%ebx
f0100a9d:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0100aa4:	eb 2b                	jmp    f0100ad1 <stab_binsearch+0xb1>
		} else if (stabs[m].n_value > addr) {
f0100aa6:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100aa9:	76 14                	jbe    f0100abf <stab_binsearch+0x9f>
			*region_right = m - 1;
f0100aab:	83 e8 01             	sub    $0x1,%eax
f0100aae:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100ab1:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100ab4:	89 02                	mov    %eax,(%edx)
f0100ab6:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0100abd:	eb 12                	jmp    f0100ad1 <stab_binsearch+0xb1>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100abf:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100ac2:	89 01                	mov    %eax,(%ecx)
			l = m;
			addr++;
f0100ac4:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100ac8:	89 c3                	mov    %eax,%ebx
f0100aca:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100ad1:	39 5d ec             	cmp    %ebx,-0x14(%ebp)
f0100ad4:	0f 8d 71 ff ff ff    	jge    f0100a4b <stab_binsearch+0x2b>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100ada:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100ade:	75 0f                	jne    f0100aef <stab_binsearch+0xcf>
		*region_right = *region_left - 1;
f0100ae0:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100ae3:	8b 03                	mov    (%ebx),%eax
f0100ae5:	83 e8 01             	sub    $0x1,%eax
f0100ae8:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100aeb:	89 02                	mov    %eax,(%edx)
f0100aed:	eb 57                	jmp    f0100b46 <stab_binsearch+0x126>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100aef:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100af2:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100af4:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100af7:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100af9:	39 c1                	cmp    %eax,%ecx
f0100afb:	7d 28                	jge    f0100b25 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0100afd:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b00:	8b 5d f0             	mov    -0x10(%ebp),%ebx
f0100b03:	0f b6 54 93 04       	movzbl 0x4(%ebx,%edx,4),%edx
f0100b08:	39 f2                	cmp    %esi,%edx
f0100b0a:	74 19                	je     f0100b25 <stab_binsearch+0x105>
f0100b0c:	8d 54 40 fd          	lea    -0x3(%eax,%eax,2),%edx
f0100b10:	8d 54 93 04          	lea    0x4(%ebx,%edx,4),%edx
		     l--)
f0100b14:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b17:	39 c1                	cmp    %eax,%ecx
f0100b19:	7d 0a                	jge    f0100b25 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0100b1b:	0f b6 1a             	movzbl (%edx),%ebx
f0100b1e:	83 ea 0c             	sub    $0xc,%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b21:	39 f3                	cmp    %esi,%ebx
f0100b23:	75 ef                	jne    f0100b14 <stab_binsearch+0xf4>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
f0100b25:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100b28:	89 02                	mov    %eax,(%edx)
f0100b2a:	eb 1a                	jmp    f0100b46 <stab_binsearch+0x126>
	}
}
f0100b2c:	89 f8                	mov    %edi,%eax
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100b2e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b31:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0100b34:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100b38:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100b3b:	0f 82 54 ff ff ff    	jb     f0100a95 <stab_binsearch+0x75>
f0100b41:	e9 60 ff ff ff       	jmp    f0100aa6 <stab_binsearch+0x86>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0100b46:	83 c4 14             	add    $0x14,%esp
f0100b49:	5b                   	pop    %ebx
f0100b4a:	5e                   	pop    %esi
f0100b4b:	5f                   	pop    %edi
f0100b4c:	5d                   	pop    %ebp
f0100b4d:	c3                   	ret    

f0100b4e <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b4e:	55                   	push   %ebp
f0100b4f:	89 e5                	mov    %esp,%ebp
f0100b51:	83 ec 48             	sub    $0x48,%esp
f0100b54:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100b57:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100b5a:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100b5d:	8b 75 08             	mov    0x8(%ebp),%esi
f0100b60:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b63:	c7 03 44 22 10 f0    	movl   $0xf0102244,(%ebx)
	info->eip_line = 0;
f0100b69:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100b70:	c7 43 08 44 22 10 f0 	movl   $0xf0102244,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b77:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b7e:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b81:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b88:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b8e:	76 12                	jbe    f0100ba2 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b90:	b8 3b 79 10 f0       	mov    $0xf010793b,%eax
f0100b95:	3d 8d 5f 10 f0       	cmp    $0xf0105f8d,%eax
f0100b9a:	0f 86 a2 01 00 00    	jbe    f0100d42 <debuginfo_eip+0x1f4>
f0100ba0:	eb 1c                	jmp    f0100bbe <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100ba2:	c7 44 24 08 4e 22 10 	movl   $0xf010224e,0x8(%esp)
f0100ba9:	f0 
f0100baa:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100bb1:	00 
f0100bb2:	c7 04 24 5b 22 10 f0 	movl   $0xf010225b,(%esp)
f0100bb9:	e8 c2 f4 ff ff       	call   f0100080 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100bbe:	80 3d 3a 79 10 f0 00 	cmpb   $0x0,0xf010793a
f0100bc5:	0f 85 77 01 00 00    	jne    f0100d42 <debuginfo_eip+0x1f4>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100bcb:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100bd2:	b8 8c 5f 10 f0       	mov    $0xf0105f8c,%eax
f0100bd7:	2d a0 24 10 f0       	sub    $0xf01024a0,%eax
f0100bdc:	c1 f8 02             	sar    $0x2,%eax
f0100bdf:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100be5:	83 e8 01             	sub    $0x1,%eax
f0100be8:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100beb:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100bee:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100bf1:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bf5:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100bfc:	b8 a0 24 10 f0       	mov    $0xf01024a0,%eax
f0100c01:	e8 1a fe ff ff       	call   f0100a20 <stab_binsearch>
	if (lfile == 0)
f0100c06:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c09:	85 c0                	test   %eax,%eax
f0100c0b:	0f 84 31 01 00 00    	je     f0100d42 <debuginfo_eip+0x1f4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c11:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100c14:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c17:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c1a:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c1d:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c20:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c24:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100c2b:	b8 a0 24 10 f0       	mov    $0xf01024a0,%eax
f0100c30:	e8 eb fd ff ff       	call   f0100a20 <stab_binsearch>

	if (lfun <= rfun) {
f0100c35:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100c38:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100c3b:	7f 3c                	jg     f0100c79 <debuginfo_eip+0x12b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100c3d:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100c40:	8b 80 a0 24 10 f0    	mov    -0xfefdb60(%eax),%eax
f0100c46:	ba 3b 79 10 f0       	mov    $0xf010793b,%edx
f0100c4b:	81 ea 8d 5f 10 f0    	sub    $0xf0105f8d,%edx
f0100c51:	39 d0                	cmp    %edx,%eax
f0100c53:	73 08                	jae    f0100c5d <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c55:	05 8d 5f 10 f0       	add    $0xf0105f8d,%eax
f0100c5a:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c5d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100c60:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100c63:	8b 92 a8 24 10 f0    	mov    -0xfefdb58(%edx),%edx
f0100c69:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100c6c:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100c6e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100c71:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100c74:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100c77:	eb 0f                	jmp    f0100c88 <debuginfo_eip+0x13a>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c79:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c7c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c7f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100c82:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c85:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c88:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c8f:	00 
f0100c90:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c93:	89 04 24             	mov    %eax,(%esp)
f0100c96:	e8 10 0b 00 00       	call   f01017ab <strfind>
f0100c9b:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c9e:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
    
    stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100ca1:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100ca4:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100ca7:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100cab:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100cb2:	b8 a0 24 10 f0       	mov    $0xf01024a0,%eax
f0100cb7:	e8 64 fd ff ff       	call   f0100a20 <stab_binsearch>

    if (lline <= rline) {
f0100cbc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100cbf:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100cc2:	0f 8f 7a 00 00 00    	jg     f0100d42 <debuginfo_eip+0x1f4>
        info->eip_line = stabs[lline].n_desc;
f0100cc8:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100ccb:	0f b7 80 a6 24 10 f0 	movzwl -0xfefdb5a(%eax),%eax
f0100cd2:	89 43 04             	mov    %eax,0x4(%ebx)
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
f0100cd5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100cd8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100cdb:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100cde:	81 c2 a8 24 10 f0    	add    $0xf01024a8,%edx
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100ce4:	eb 06                	jmp    f0100cec <debuginfo_eip+0x19e>
f0100ce6:	83 e8 01             	sub    $0x1,%eax
f0100ce9:	83 ea 0c             	sub    $0xc,%edx
f0100cec:	89 c6                	mov    %eax,%esi
f0100cee:	39 f8                	cmp    %edi,%eax
f0100cf0:	7c 1f                	jl     f0100d11 <debuginfo_eip+0x1c3>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100cf2:	0f b6 4a fc          	movzbl -0x4(%edx),%ecx
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100cf6:	80 f9 84             	cmp    $0x84,%cl
f0100cf9:	74 60                	je     f0100d5b <debuginfo_eip+0x20d>
f0100cfb:	80 f9 64             	cmp    $0x64,%cl
f0100cfe:	75 e6                	jne    f0100ce6 <debuginfo_eip+0x198>
f0100d00:	83 3a 00             	cmpl   $0x0,(%edx)
f0100d03:	74 e1                	je     f0100ce6 <debuginfo_eip+0x198>
f0100d05:	8d 76 00             	lea    0x0(%esi),%esi
f0100d08:	eb 51                	jmp    f0100d5b <debuginfo_eip+0x20d>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100d0a:	05 8d 5f 10 f0       	add    $0xf0105f8d,%eax
f0100d0f:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d11:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d14:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100d17:	7d 30                	jge    f0100d49 <debuginfo_eip+0x1fb>
		for (lline = lfun + 1;
f0100d19:	83 c0 01             	add    $0x1,%eax
f0100d1c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d1f:	ba a0 24 10 f0       	mov    $0xf01024a0,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100d24:	eb 08                	jmp    f0100d2e <debuginfo_eip+0x1e0>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100d26:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100d2a:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)

	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d2e:	8b 45 d4             	mov    -0x2c(%ebp),%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100d31:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100d34:	7d 13                	jge    f0100d49 <debuginfo_eip+0x1fb>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d36:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100d39:	80 7c 10 04 a0       	cmpb   $0xa0,0x4(%eax,%edx,1)
f0100d3e:	74 e6                	je     f0100d26 <debuginfo_eip+0x1d8>
f0100d40:	eb 07                	jmp    f0100d49 <debuginfo_eip+0x1fb>
f0100d42:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d47:	eb 05                	jmp    f0100d4e <debuginfo_eip+0x200>
f0100d49:	b8 00 00 00 00       	mov    $0x0,%eax
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
}
f0100d4e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100d51:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100d54:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100d57:	89 ec                	mov    %ebp,%esp
f0100d59:	5d                   	pop    %ebp
f0100d5a:	c3                   	ret    
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100d5b:	6b c6 0c             	imul   $0xc,%esi,%eax
f0100d5e:	8b 80 a0 24 10 f0    	mov    -0xfefdb60(%eax),%eax
f0100d64:	ba 3b 79 10 f0       	mov    $0xf010793b,%edx
f0100d69:	81 ea 8d 5f 10 f0    	sub    $0xf0105f8d,%edx
f0100d6f:	39 d0                	cmp    %edx,%eax
f0100d71:	72 97                	jb     f0100d0a <debuginfo_eip+0x1bc>
f0100d73:	eb 9c                	jmp    f0100d11 <debuginfo_eip+0x1c3>
	...

f0100d80 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d80:	55                   	push   %ebp
f0100d81:	89 e5                	mov    %esp,%ebp
f0100d83:	57                   	push   %edi
f0100d84:	56                   	push   %esi
f0100d85:	53                   	push   %ebx
f0100d86:	83 ec 4c             	sub    $0x4c,%esp
f0100d89:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d8c:	89 d6                	mov    %edx,%esi
f0100d8e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d91:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d94:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100d97:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100d9a:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d9d:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100da0:	8b 7d 18             	mov    0x18(%ebp),%edi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100da3:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100da6:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100dab:	39 d1                	cmp    %edx,%ecx
f0100dad:	72 15                	jb     f0100dc4 <printnum+0x44>
f0100daf:	77 07                	ja     f0100db8 <printnum+0x38>
f0100db1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100db4:	39 d0                	cmp    %edx,%eax
f0100db6:	76 0c                	jbe    f0100dc4 <printnum+0x44>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100db8:	83 eb 01             	sub    $0x1,%ebx
f0100dbb:	85 db                	test   %ebx,%ebx
f0100dbd:	8d 76 00             	lea    0x0(%esi),%esi
f0100dc0:	7f 61                	jg     f0100e23 <printnum+0xa3>
f0100dc2:	eb 70                	jmp    f0100e34 <printnum+0xb4>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100dc4:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0100dc8:	83 eb 01             	sub    $0x1,%ebx
f0100dcb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100dcf:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100dd3:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0100dd7:	8b 5c 24 0c          	mov    0xc(%esp),%ebx
f0100ddb:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0100dde:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0100de1:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100de4:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100de8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100def:	00 
f0100df0:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100df3:	89 04 24             	mov    %eax,(%esp)
f0100df6:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100df9:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100dfd:	e8 3e 0c 00 00       	call   f0101a40 <__udivdi3>
f0100e02:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100e05:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100e08:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100e0c:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100e10:	89 04 24             	mov    %eax,(%esp)
f0100e13:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100e17:	89 f2                	mov    %esi,%edx
f0100e19:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e1c:	e8 5f ff ff ff       	call   f0100d80 <printnum>
f0100e21:	eb 11                	jmp    f0100e34 <printnum+0xb4>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100e23:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100e27:	89 3c 24             	mov    %edi,(%esp)
f0100e2a:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e2d:	83 eb 01             	sub    $0x1,%ebx
f0100e30:	85 db                	test   %ebx,%ebx
f0100e32:	7f ef                	jg     f0100e23 <printnum+0xa3>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100e34:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100e38:	8b 74 24 04          	mov    0x4(%esp),%esi
f0100e3c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100e3f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e43:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100e4a:	00 
f0100e4b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100e4e:	89 14 24             	mov    %edx,(%esp)
f0100e51:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100e54:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100e58:	e8 13 0d 00 00       	call   f0101b70 <__umoddi3>
f0100e5d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100e61:	0f be 80 69 22 10 f0 	movsbl -0xfefdd97(%eax),%eax
f0100e68:	89 04 24             	mov    %eax,(%esp)
f0100e6b:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100e6e:	83 c4 4c             	add    $0x4c,%esp
f0100e71:	5b                   	pop    %ebx
f0100e72:	5e                   	pop    %esi
f0100e73:	5f                   	pop    %edi
f0100e74:	5d                   	pop    %ebp
f0100e75:	c3                   	ret    

f0100e76 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100e76:	55                   	push   %ebp
f0100e77:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e79:	83 fa 01             	cmp    $0x1,%edx
f0100e7c:	7e 0f                	jle    f0100e8d <getuint+0x17>
		return va_arg(*ap, unsigned long long);
f0100e7e:	8b 10                	mov    (%eax),%edx
f0100e80:	83 c2 08             	add    $0x8,%edx
f0100e83:	89 10                	mov    %edx,(%eax)
f0100e85:	8b 42 f8             	mov    -0x8(%edx),%eax
f0100e88:	8b 52 fc             	mov    -0x4(%edx),%edx
f0100e8b:	eb 24                	jmp    f0100eb1 <getuint+0x3b>
	else if (lflag)
f0100e8d:	85 d2                	test   %edx,%edx
f0100e8f:	74 11                	je     f0100ea2 <getuint+0x2c>
		return va_arg(*ap, unsigned long);
f0100e91:	8b 10                	mov    (%eax),%edx
f0100e93:	83 c2 04             	add    $0x4,%edx
f0100e96:	89 10                	mov    %edx,(%eax)
f0100e98:	8b 42 fc             	mov    -0x4(%edx),%eax
f0100e9b:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ea0:	eb 0f                	jmp    f0100eb1 <getuint+0x3b>
	else
		return va_arg(*ap, unsigned int);
f0100ea2:	8b 10                	mov    (%eax),%edx
f0100ea4:	83 c2 04             	add    $0x4,%edx
f0100ea7:	89 10                	mov    %edx,(%eax)
f0100ea9:	8b 42 fc             	mov    -0x4(%edx),%eax
f0100eac:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100eb1:	5d                   	pop    %ebp
f0100eb2:	c3                   	ret    

f0100eb3 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100eb3:	55                   	push   %ebp
f0100eb4:	89 e5                	mov    %esp,%ebp
f0100eb6:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100eb9:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100ebd:	8b 10                	mov    (%eax),%edx
f0100ebf:	3b 50 04             	cmp    0x4(%eax),%edx
f0100ec2:	73 0a                	jae    f0100ece <sprintputch+0x1b>
		*b->buf++ = ch;
f0100ec4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100ec7:	88 0a                	mov    %cl,(%edx)
f0100ec9:	83 c2 01             	add    $0x1,%edx
f0100ecc:	89 10                	mov    %edx,(%eax)
}
f0100ece:	5d                   	pop    %ebp
f0100ecf:	c3                   	ret    

f0100ed0 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100ed0:	55                   	push   %ebp
f0100ed1:	89 e5                	mov    %esp,%ebp
f0100ed3:	57                   	push   %edi
f0100ed4:	56                   	push   %esi
f0100ed5:	53                   	push   %ebx
f0100ed6:	83 ec 5c             	sub    $0x5c,%esp
f0100ed9:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100edc:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100edf:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100ee2:	eb 11                	jmp    f0100ef5 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc, sel_c[4];

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100ee4:	85 c0                	test   %eax,%eax
f0100ee6:	0f 84 a8 05 00 00    	je     f0101494 <vprintfmt+0x5c4>
				return;
			putch(ch, putdat);
f0100eec:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ef0:	89 04 24             	mov    %eax,(%esp)
f0100ef3:	ff d7                	call   *%edi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc, sel_c[4];

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ef5:	0f b6 03             	movzbl (%ebx),%eax
f0100ef8:	83 c3 01             	add    $0x1,%ebx
f0100efb:	83 f8 25             	cmp    $0x25,%eax
f0100efe:	75 e4                	jne    f0100ee4 <vprintfmt+0x14>
f0100f00:	c6 45 d0 20          	movb   $0x20,-0x30(%ebp)
f0100f04:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
f0100f0b:	c7 45 bc ff ff ff ff 	movl   $0xffffffff,-0x44(%ebp)
f0100f12:	c7 45 c4 ff ff ff ff 	movl   $0xffffffff,-0x3c(%ebp)
f0100f19:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100f1e:	eb 06                	jmp    f0100f26 <vprintfmt+0x56>
f0100f20:	c6 45 d0 2d          	movb   $0x2d,-0x30(%ebp)
f0100f24:	89 c3                	mov    %eax,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f26:	0f b6 13             	movzbl (%ebx),%edx
f0100f29:	0f b6 c2             	movzbl %dl,%eax
f0100f2c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100f2f:	8d 43 01             	lea    0x1(%ebx),%eax
f0100f32:	83 ea 23             	sub    $0x23,%edx
f0100f35:	80 fa 55             	cmp    $0x55,%dl
f0100f38:	0f 87 39 05 00 00    	ja     f0101477 <vprintfmt+0x5a7>
f0100f3e:	0f b6 d2             	movzbl %dl,%edx
f0100f41:	ff 24 95 1c 23 10 f0 	jmp    *-0xfefdce4(,%edx,4)
f0100f48:	c6 45 d0 30          	movb   $0x30,-0x30(%ebp)
f0100f4c:	eb d6                	jmp    f0100f24 <vprintfmt+0x54>
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f4e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100f51:	83 ea 30             	sub    $0x30,%edx
f0100f54:	89 55 bc             	mov    %edx,-0x44(%ebp)
				ch = *fmt;
f0100f57:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0100f5a:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0100f5d:	83 fb 09             	cmp    $0x9,%ebx
f0100f60:	77 4d                	ja     f0100faf <vprintfmt+0xdf>
f0100f62:	89 4d c0             	mov    %ecx,-0x40(%ebp)
f0100f65:	8b 4d bc             	mov    -0x44(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f68:	83 c0 01             	add    $0x1,%eax
				precision = precision * 10 + ch - '0';
f0100f6b:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100f6e:	8d 4c 4a d0          	lea    -0x30(%edx,%ecx,2),%ecx
				ch = *fmt;
f0100f72:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0100f75:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0100f78:	83 fb 09             	cmp    $0x9,%ebx
f0100f7b:	76 eb                	jbe    f0100f68 <vprintfmt+0x98>
f0100f7d:	89 4d bc             	mov    %ecx,-0x44(%ebp)
f0100f80:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f0100f83:	eb 2a                	jmp    f0100faf <vprintfmt+0xdf>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f85:	8b 55 14             	mov    0x14(%ebp),%edx
f0100f88:	83 c2 04             	add    $0x4,%edx
f0100f8b:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f8e:	8b 52 fc             	mov    -0x4(%edx),%edx
f0100f91:	89 55 bc             	mov    %edx,-0x44(%ebp)
			goto process_precision;
f0100f94:	eb 19                	jmp    f0100faf <vprintfmt+0xdf>

		case '.':
			if (width < 0)
f0100f96:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0100f99:	c1 fa 1f             	sar    $0x1f,%edx
f0100f9c:	f7 d2                	not    %edx
f0100f9e:	21 55 c4             	and    %edx,-0x3c(%ebp)
f0100fa1:	eb 81                	jmp    f0100f24 <vprintfmt+0x54>
f0100fa3:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
			goto reswitch;
f0100faa:	e9 75 ff ff ff       	jmp    f0100f24 <vprintfmt+0x54>

		process_precision:
			if (width < 0)
f0100faf:	83 7d c4 00          	cmpl   $0x0,-0x3c(%ebp)
f0100fb3:	0f 89 6b ff ff ff    	jns    f0100f24 <vprintfmt+0x54>
f0100fb9:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0100fbc:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f0100fbf:	c7 45 bc ff ff ff ff 	movl   $0xffffffff,-0x44(%ebp)
f0100fc6:	e9 59 ff ff ff       	jmp    f0100f24 <vprintfmt+0x54>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100fcb:	83 c1 01             	add    $0x1,%ecx
			goto reswitch;
f0100fce:	e9 51 ff ff ff       	jmp    f0100f24 <vprintfmt+0x54>
f0100fd3:	89 45 c0             	mov    %eax,-0x40(%ebp)

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100fd6:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fd9:	83 c0 04             	add    $0x4,%eax
f0100fdc:	89 45 14             	mov    %eax,0x14(%ebp)
f0100fdf:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100fe3:	8b 40 fc             	mov    -0x4(%eax),%eax
f0100fe6:	89 04 24             	mov    %eax,(%esp)
f0100fe9:	ff d7                	call   *%edi
f0100feb:	8b 5d c0             	mov    -0x40(%ebp),%ebx
			break;
f0100fee:	e9 02 ff ff ff       	jmp    f0100ef5 <vprintfmt+0x25>
f0100ff3:	89 45 c0             	mov    %eax,-0x40(%ebp)
        // color control
        case 'C':
            // void* memmove (void *dst, const void *src, size_t len) is declared in inc/string.h
            // it could be used to replace memcpy ()

            memmove (sel_c, fmt, sizeof(unsigned char) * 3);
f0100ff6:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
f0100ffd:	00 
f0100ffe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101002:	8d 4d e4             	lea    -0x1c(%ebp),%ecx
f0101005:	89 0c 24             	mov    %ecx,(%esp)
f0101008:	e8 28 08 00 00       	call   f0101835 <memmove>
            sel_c[3] = '\0';
f010100d:	c6 45 e7 00          	movb   $0x0,-0x19(%ebp)
            fmt += 3;
f0101011:	8b 5d c0             	mov    -0x40(%ebp),%ebx
f0101014:	83 c3 03             	add    $0x3,%ebx

            if (sel_c[0] >= '0' && sel_c[0] <= '9') {
f0101017:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010101b:	8d 50 d0             	lea    -0x30(%eax),%edx
f010101e:	80 fa 09             	cmp    $0x9,%dl
f0101021:	77 29                	ja     f010104c <vprintfmt+0x17c>
                // it is a color specifier
                // JOS provide no atoi (), so we can only convert char* to int all by ourselves
           
                ch_color = ((sel_c[0] - '0') * 10 + sel_c[1] - '0') * 10 + sel_c[2] - '0';
f0101023:	0f be 55 e6          	movsbl -0x1a(%ebp),%edx
f0101027:	0f be 4d e5          	movsbl -0x1b(%ebp),%ecx
f010102b:	0f be c0             	movsbl %al,%eax
f010102e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0101031:	8d 84 41 20 fe ff ff 	lea    -0x1e0(%ecx,%eax,2),%eax
f0101038:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010103b:	8d 84 42 f0 fd ff ff 	lea    -0x210(%edx,%eax,2),%eax
f0101042:	a3 20 03 11 f0       	mov    %eax,0xf0110320
f0101047:	e9 a9 fe ff ff       	jmp    f0100ef5 <vprintfmt+0x25>

            } else {
                // it is a explicit color selector
                
                // strcmp (const char *s1, const char *s2) is declared in inc/string.h
                if (strcmp (sel_c, "wht") == 0) ch_color = COLOR_WHT else
f010104c:	c7 44 24 04 7a 22 10 	movl   $0xf010227a,0x4(%esp)
f0101053:	f0 
f0101054:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101057:	89 04 24             	mov    %eax,(%esp)
f010105a:	e8 aa 06 00 00       	call   f0101709 <strcmp>
f010105f:	85 c0                	test   %eax,%eax
f0101061:	75 0f                	jne    f0101072 <vprintfmt+0x1a2>
f0101063:	c7 05 20 03 11 f0 07 	movl   $0x7,0xf0110320
f010106a:	00 00 00 
f010106d:	e9 83 fe ff ff       	jmp    f0100ef5 <vprintfmt+0x25>
                if (strcmp (sel_c, "blk") == 0) ch_color = COLOR_BLK else
f0101072:	c7 44 24 04 7e 22 10 	movl   $0xf010227e,0x4(%esp)
f0101079:	f0 
f010107a:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010107d:	89 14 24             	mov    %edx,(%esp)
f0101080:	e8 84 06 00 00       	call   f0101709 <strcmp>
f0101085:	85 c0                	test   %eax,%eax
f0101087:	75 0f                	jne    f0101098 <vprintfmt+0x1c8>
f0101089:	c7 05 20 03 11 f0 01 	movl   $0x1,0xf0110320
f0101090:	00 00 00 
f0101093:	e9 5d fe ff ff       	jmp    f0100ef5 <vprintfmt+0x25>
                if (strcmp (sel_c, "grn") == 0) ch_color = COLOR_GRN else
f0101098:	c7 44 24 04 82 22 10 	movl   $0xf0102282,0x4(%esp)
f010109f:	f0 
f01010a0:	8d 4d e4             	lea    -0x1c(%ebp),%ecx
f01010a3:	89 0c 24             	mov    %ecx,(%esp)
f01010a6:	e8 5e 06 00 00       	call   f0101709 <strcmp>
f01010ab:	85 c0                	test   %eax,%eax
f01010ad:	75 0f                	jne    f01010be <vprintfmt+0x1ee>
f01010af:	c7 05 20 03 11 f0 02 	movl   $0x2,0xf0110320
f01010b6:	00 00 00 
f01010b9:	e9 37 fe ff ff       	jmp    f0100ef5 <vprintfmt+0x25>
                if (strcmp (sel_c, "red") == 0) ch_color = COLOR_RED else
f01010be:	c7 44 24 04 86 22 10 	movl   $0xf0102286,0x4(%esp)
f01010c5:	f0 
f01010c6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01010c9:	89 04 24             	mov    %eax,(%esp)
f01010cc:	e8 38 06 00 00       	call   f0101709 <strcmp>
f01010d1:	85 c0                	test   %eax,%eax
f01010d3:	75 0f                	jne    f01010e4 <vprintfmt+0x214>
f01010d5:	c7 05 20 03 11 f0 04 	movl   $0x4,0xf0110320
f01010dc:	00 00 00 
f01010df:	e9 11 fe ff ff       	jmp    f0100ef5 <vprintfmt+0x25>
                if (strcmp (sel_c, "gry") == 0) ch_color = COLOR_GRY else
f01010e4:	c7 44 24 04 8a 22 10 	movl   $0xf010228a,0x4(%esp)
f01010eb:	f0 
f01010ec:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01010ef:	89 14 24             	mov    %edx,(%esp)
f01010f2:	e8 12 06 00 00       	call   f0101709 <strcmp>
f01010f7:	85 c0                	test   %eax,%eax
f01010f9:	75 0f                	jne    f010110a <vprintfmt+0x23a>
f01010fb:	c7 05 20 03 11 f0 08 	movl   $0x8,0xf0110320
f0101102:	00 00 00 
f0101105:	e9 eb fd ff ff       	jmp    f0100ef5 <vprintfmt+0x25>
                if (strcmp (sel_c, "ylw") == 0) ch_color = COLOR_YLW else
f010110a:	c7 44 24 04 8e 22 10 	movl   $0xf010228e,0x4(%esp)
f0101111:	f0 
f0101112:	8d 4d e4             	lea    -0x1c(%ebp),%ecx
f0101115:	89 0c 24             	mov    %ecx,(%esp)
f0101118:	e8 ec 05 00 00       	call   f0101709 <strcmp>
f010111d:	85 c0                	test   %eax,%eax
f010111f:	75 0f                	jne    f0101130 <vprintfmt+0x260>
f0101121:	c7 05 20 03 11 f0 0f 	movl   $0xf,0xf0110320
f0101128:	00 00 00 
f010112b:	e9 c5 fd ff ff       	jmp    f0100ef5 <vprintfmt+0x25>
                if (strcmp (sel_c, "org") == 0) ch_color = COLOR_ORG else
f0101130:	c7 44 24 04 92 22 10 	movl   $0xf0102292,0x4(%esp)
f0101137:	f0 
f0101138:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010113b:	89 04 24             	mov    %eax,(%esp)
f010113e:	e8 c6 05 00 00       	call   f0101709 <strcmp>
f0101143:	85 c0                	test   %eax,%eax
f0101145:	75 0f                	jne    f0101156 <vprintfmt+0x286>
f0101147:	c7 05 20 03 11 f0 0c 	movl   $0xc,0xf0110320
f010114e:	00 00 00 
f0101151:	e9 9f fd ff ff       	jmp    f0100ef5 <vprintfmt+0x25>
                if (strcmp (sel_c, "pur") == 0) ch_color = COLOR_PUR else
f0101156:	c7 44 24 04 96 22 10 	movl   $0xf0102296,0x4(%esp)
f010115d:	f0 
f010115e:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0101161:	89 14 24             	mov    %edx,(%esp)
f0101164:	e8 a0 05 00 00       	call   f0101709 <strcmp>
f0101169:	85 c0                	test   %eax,%eax
f010116b:	75 0f                	jne    f010117c <vprintfmt+0x2ac>
f010116d:	c7 05 20 03 11 f0 06 	movl   $0x6,0xf0110320
f0101174:	00 00 00 
f0101177:	e9 79 fd ff ff       	jmp    f0100ef5 <vprintfmt+0x25>
                if (strcmp (sel_c, "cyn") == 0) ch_color = COLOR_CYN else
f010117c:	c7 44 24 04 9a 22 10 	movl   $0xf010229a,0x4(%esp)
f0101183:	f0 
f0101184:	8d 4d e4             	lea    -0x1c(%ebp),%ecx
f0101187:	89 0c 24             	mov    %ecx,(%esp)
f010118a:	e8 7a 05 00 00       	call   f0101709 <strcmp>
f010118f:	83 f8 01             	cmp    $0x1,%eax
f0101192:	19 c0                	sbb    %eax,%eax
f0101194:	83 e0 04             	and    $0x4,%eax
f0101197:	83 c0 07             	add    $0x7,%eax
f010119a:	a3 20 03 11 f0       	mov    %eax,0xf0110320
f010119f:	e9 51 fd ff ff       	jmp    f0100ef5 <vprintfmt+0x25>
f01011a4:	89 45 c0             	mov    %eax,-0x40(%ebp)
            }
            break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f01011a7:	8b 45 14             	mov    0x14(%ebp),%eax
f01011aa:	83 c0 04             	add    $0x4,%eax
f01011ad:	89 45 14             	mov    %eax,0x14(%ebp)
f01011b0:	8b 40 fc             	mov    -0x4(%eax),%eax
f01011b3:	89 c2                	mov    %eax,%edx
f01011b5:	c1 fa 1f             	sar    $0x1f,%edx
f01011b8:	31 d0                	xor    %edx,%eax
f01011ba:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
f01011bc:	83 f8 06             	cmp    $0x6,%eax
f01011bf:	7f 0b                	jg     f01011cc <vprintfmt+0x2fc>
f01011c1:	8b 14 85 74 24 10 f0 	mov    -0xfefdb8c(,%eax,4),%edx
f01011c8:	85 d2                	test   %edx,%edx
f01011ca:	75 20                	jne    f01011ec <vprintfmt+0x31c>
				printfmt(putch, putdat, "error %d", err);
f01011cc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011d0:	c7 44 24 08 9e 22 10 	movl   $0xf010229e,0x8(%esp)
f01011d7:	f0 
f01011d8:	89 74 24 04          	mov    %esi,0x4(%esp)
f01011dc:	89 3c 24             	mov    %edi,(%esp)
f01011df:	e8 38 03 00 00       	call   f010151c <printfmt>
f01011e4:	8b 5d c0             	mov    -0x40(%ebp),%ebx
		// error message
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
f01011e7:	e9 09 fd ff ff       	jmp    f0100ef5 <vprintfmt+0x25>
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
f01011ec:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01011f0:	c7 44 24 08 a7 22 10 	movl   $0xf01022a7,0x8(%esp)
f01011f7:	f0 
f01011f8:	89 74 24 04          	mov    %esi,0x4(%esp)
f01011fc:	89 3c 24             	mov    %edi,(%esp)
f01011ff:	e8 18 03 00 00       	call   f010151c <printfmt>
f0101204:	8b 5d c0             	mov    -0x40(%ebp),%ebx
f0101207:	e9 e9 fc ff ff       	jmp    f0100ef5 <vprintfmt+0x25>
f010120c:	89 45 c0             	mov    %eax,-0x40(%ebp)
f010120f:	89 c3                	mov    %eax,%ebx
f0101211:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0101214:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0101217:	89 45 b8             	mov    %eax,-0x48(%ebp)
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010121a:	8b 45 14             	mov    0x14(%ebp),%eax
f010121d:	83 c0 04             	add    $0x4,%eax
f0101220:	89 45 14             	mov    %eax,0x14(%ebp)
f0101223:	8b 40 fc             	mov    -0x4(%eax),%eax
f0101226:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101229:	85 c0                	test   %eax,%eax
f010122b:	75 07                	jne    f0101234 <vprintfmt+0x364>
f010122d:	c7 45 d4 aa 22 10 f0 	movl   $0xf01022aa,-0x2c(%ebp)
				p = "(null)";
			if (width > 0 && padc != '-')
f0101234:	83 7d b8 00          	cmpl   $0x0,-0x48(%ebp)
f0101238:	7e 06                	jle    f0101240 <vprintfmt+0x370>
f010123a:	80 7d d0 2d          	cmpb   $0x2d,-0x30(%ebp)
f010123e:	75 15                	jne    f0101255 <vprintfmt+0x385>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101240:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101243:	0f be 02             	movsbl (%edx),%eax
f0101246:	85 c0                	test   %eax,%eax
f0101248:	0f 85 a4 00 00 00    	jne    f01012f2 <vprintfmt+0x422>
f010124e:	66 90                	xchg   %ax,%ax
f0101250:	e9 8f 00 00 00       	jmp    f01012e4 <vprintfmt+0x414>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101255:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101259:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010125c:	89 0c 24             	mov    %ecx,(%esp)
f010125f:	e8 e7 03 00 00       	call   f010164b <strnlen>
f0101264:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0101267:	29 c2                	sub    %eax,%edx
f0101269:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f010126c:	85 d2                	test   %edx,%edx
f010126e:	7e d0                	jle    f0101240 <vprintfmt+0x370>
					putch(padc, putdat);
f0101270:	0f be 4d d0          	movsbl -0x30(%ebp),%ecx
f0101274:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0101277:	89 5d b8             	mov    %ebx,-0x48(%ebp)
f010127a:	89 d3                	mov    %edx,%ebx
f010127c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101280:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101283:	89 04 24             	mov    %eax,(%esp)
f0101286:	ff d7                	call   *%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101288:	83 eb 01             	sub    $0x1,%ebx
f010128b:	85 db                	test   %ebx,%ebx
f010128d:	7f ed                	jg     f010127c <vprintfmt+0x3ac>
f010128f:	8b 5d b8             	mov    -0x48(%ebp),%ebx
f0101292:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%ebp)
f0101299:	eb a5                	jmp    f0101240 <vprintfmt+0x370>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010129b:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
f010129f:	74 1b                	je     f01012bc <vprintfmt+0x3ec>
f01012a1:	8d 50 e0             	lea    -0x20(%eax),%edx
f01012a4:	83 fa 5e             	cmp    $0x5e,%edx
f01012a7:	76 13                	jbe    f01012bc <vprintfmt+0x3ec>
					putch('?', putdat);
f01012a9:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01012ac:	89 54 24 04          	mov    %edx,0x4(%esp)
f01012b0:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01012b7:	ff 55 d4             	call   *-0x2c(%ebp)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01012ba:	eb 0d                	jmp    f01012c9 <vprintfmt+0x3f9>
					putch('?', putdat);
				else
					putch(ch, putdat);
f01012bc:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01012bf:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01012c3:	89 04 24             	mov    %eax,(%esp)
f01012c6:	ff 55 d4             	call   *-0x2c(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01012c9:	83 ef 01             	sub    $0x1,%edi
f01012cc:	0f be 03             	movsbl (%ebx),%eax
f01012cf:	85 c0                	test   %eax,%eax
f01012d1:	74 05                	je     f01012d8 <vprintfmt+0x408>
f01012d3:	83 c3 01             	add    $0x1,%ebx
f01012d6:	eb 31                	jmp    f0101309 <vprintfmt+0x439>
f01012d8:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f01012db:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01012de:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01012e1:	8b 5d bc             	mov    -0x44(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01012e4:	83 7d c4 00          	cmpl   $0x0,-0x3c(%ebp)
f01012e8:	7f 36                	jg     f0101320 <vprintfmt+0x450>
f01012ea:	8b 5d c0             	mov    -0x40(%ebp),%ebx
f01012ed:	e9 03 fc ff ff       	jmp    f0100ef5 <vprintfmt+0x25>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01012f2:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01012f5:	83 c2 01             	add    $0x1,%edx
f01012f8:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01012fb:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01012fe:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0101301:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0101304:	89 5d bc             	mov    %ebx,-0x44(%ebp)
f0101307:	89 d3                	mov    %edx,%ebx
f0101309:	85 f6                	test   %esi,%esi
f010130b:	78 8e                	js     f010129b <vprintfmt+0x3cb>
f010130d:	83 ee 01             	sub    $0x1,%esi
f0101310:	79 89                	jns    f010129b <vprintfmt+0x3cb>
f0101312:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0101315:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101318:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010131b:	8b 5d bc             	mov    -0x44(%ebp),%ebx
f010131e:	eb c4                	jmp    f01012e4 <vprintfmt+0x414>
f0101320:	89 5d c8             	mov    %ebx,-0x38(%ebp)
f0101323:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101326:	89 74 24 04          	mov    %esi,0x4(%esp)
f010132a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101331:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101333:	83 eb 01             	sub    $0x1,%ebx
f0101336:	85 db                	test   %ebx,%ebx
f0101338:	7f ec                	jg     f0101326 <vprintfmt+0x456>
f010133a:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f010133d:	e9 b3 fb ff ff       	jmp    f0100ef5 <vprintfmt+0x25>
f0101342:	89 45 c0             	mov    %eax,-0x40(%ebp)
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101345:	83 f9 01             	cmp    $0x1,%ecx
f0101348:	7e 17                	jle    f0101361 <vprintfmt+0x491>
		return va_arg(*ap, long long);
f010134a:	8b 45 14             	mov    0x14(%ebp),%eax
f010134d:	83 c0 08             	add    $0x8,%eax
f0101350:	89 45 14             	mov    %eax,0x14(%ebp)
f0101353:	8b 50 f8             	mov    -0x8(%eax),%edx
f0101356:	8b 48 fc             	mov    -0x4(%eax),%ecx
f0101359:	89 55 c8             	mov    %edx,-0x38(%ebp)
f010135c:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f010135f:	eb 34                	jmp    f0101395 <vprintfmt+0x4c5>
	else if (lflag)
f0101361:	85 c9                	test   %ecx,%ecx
f0101363:	74 19                	je     f010137e <vprintfmt+0x4ae>
		return va_arg(*ap, long);
f0101365:	8b 45 14             	mov    0x14(%ebp),%eax
f0101368:	83 c0 04             	add    $0x4,%eax
f010136b:	89 45 14             	mov    %eax,0x14(%ebp)
f010136e:	8b 40 fc             	mov    -0x4(%eax),%eax
f0101371:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0101374:	89 c1                	mov    %eax,%ecx
f0101376:	c1 f9 1f             	sar    $0x1f,%ecx
f0101379:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f010137c:	eb 17                	jmp    f0101395 <vprintfmt+0x4c5>
	else
		return va_arg(*ap, int);
f010137e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101381:	83 c0 04             	add    $0x4,%eax
f0101384:	89 45 14             	mov    %eax,0x14(%ebp)
f0101387:	8b 40 fc             	mov    -0x4(%eax),%eax
f010138a:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010138d:	89 c2                	mov    %eax,%edx
f010138f:	c1 fa 1f             	sar    $0x1f,%edx
f0101392:	89 55 cc             	mov    %edx,-0x34(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101395:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0101398:	8b 55 cc             	mov    -0x34(%ebp),%edx
f010139b:	bb 0a 00 00 00       	mov    $0xa,%ebx
			if ((long long) num < 0) {
f01013a0:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f01013a4:	0f 89 8b 00 00 00    	jns    f0101435 <vprintfmt+0x565>
				putch('-', putdat);
f01013aa:	89 74 24 04          	mov    %esi,0x4(%esp)
f01013ae:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01013b5:	ff d7                	call   *%edi
				num = -(long long) num;
f01013b7:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01013ba:	8b 55 cc             	mov    -0x34(%ebp),%edx
f01013bd:	f7 d8                	neg    %eax
f01013bf:	83 d2 00             	adc    $0x0,%edx
f01013c2:	f7 da                	neg    %edx
f01013c4:	eb 6f                	jmp    f0101435 <vprintfmt+0x565>
f01013c6:	89 45 c0             	mov    %eax,-0x40(%ebp)
			base = 10;
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01013c9:	89 ca                	mov    %ecx,%edx
f01013cb:	8d 45 14             	lea    0x14(%ebp),%eax
f01013ce:	e8 a3 fa ff ff       	call   f0100e76 <getuint>
f01013d3:	bb 0a 00 00 00       	mov    $0xa,%ebx
			base = 10;
			goto number;
f01013d8:	eb 5b                	jmp    f0101435 <vprintfmt+0x565>
f01013da:	89 45 c0             	mov    %eax,-0x40(%ebp)

		// (unsigned) octal
		case 'o':
            num = getuint(&ap, lflag);
f01013dd:	89 ca                	mov    %ecx,%edx
f01013df:	8d 45 14             	lea    0x14(%ebp),%eax
f01013e2:	e8 8f fa ff ff       	call   f0100e76 <getuint>
f01013e7:	bb 08 00 00 00       	mov    $0x8,%ebx
            base = 8;

            goto number;
f01013ec:	eb 47                	jmp    f0101435 <vprintfmt+0x565>
f01013ee:	89 45 c0             	mov    %eax,-0x40(%ebp)
		// pointer
		case 'p':
			putch('0', putdat);
f01013f1:	89 74 24 04          	mov    %esi,0x4(%esp)
f01013f5:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01013fc:	ff d7                	call   *%edi
			putch('x', putdat);
f01013fe:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101402:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0101409:	ff d7                	call   *%edi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010140b:	8b 45 14             	mov    0x14(%ebp),%eax
f010140e:	83 c0 04             	add    $0x4,%eax
f0101411:	89 45 14             	mov    %eax,0x14(%ebp)
            goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101414:	8b 40 fc             	mov    -0x4(%eax),%eax
f0101417:	ba 00 00 00 00       	mov    $0x0,%edx
f010141c:	bb 10 00 00 00       	mov    $0x10,%ebx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101421:	eb 12                	jmp    f0101435 <vprintfmt+0x565>
f0101423:	89 45 c0             	mov    %eax,-0x40(%ebp)

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101426:	89 ca                	mov    %ecx,%edx
f0101428:	8d 45 14             	lea    0x14(%ebp),%eax
f010142b:	e8 46 fa ff ff       	call   f0100e76 <getuint>
f0101430:	bb 10 00 00 00       	mov    $0x10,%ebx
			base = 16;
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101435:	0f be 4d d0          	movsbl -0x30(%ebp),%ecx
f0101439:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010143d:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0101440:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0101444:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101448:	89 04 24             	mov    %eax,(%esp)
f010144b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010144f:	89 f2                	mov    %esi,%edx
f0101451:	89 f8                	mov    %edi,%eax
f0101453:	e8 28 f9 ff ff       	call   f0100d80 <printnum>
f0101458:	8b 5d c0             	mov    -0x40(%ebp),%ebx
			break;
f010145b:	e9 95 fa ff ff       	jmp    f0100ef5 <vprintfmt+0x25>
f0101460:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0101463:	8b 55 d4             	mov    -0x2c(%ebp),%edx

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101466:	89 74 24 04          	mov    %esi,0x4(%esp)
f010146a:	89 14 24             	mov    %edx,(%esp)
f010146d:	ff d7                	call   *%edi
f010146f:	8b 5d c0             	mov    -0x40(%ebp),%ebx
			break;
f0101472:	e9 7e fa ff ff       	jmp    f0100ef5 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101477:	89 74 24 04          	mov    %esi,0x4(%esp)
f010147b:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101482:	ff d7                	call   *%edi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101484:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0101487:	80 38 25             	cmpb   $0x25,(%eax)
f010148a:	0f 84 65 fa ff ff    	je     f0100ef5 <vprintfmt+0x25>
f0101490:	89 c3                	mov    %eax,%ebx
f0101492:	eb f0                	jmp    f0101484 <vprintfmt+0x5b4>
				/* do nothing */;
			break;
		}
	}
}
f0101494:	83 c4 5c             	add    $0x5c,%esp
f0101497:	5b                   	pop    %ebx
f0101498:	5e                   	pop    %esi
f0101499:	5f                   	pop    %edi
f010149a:	5d                   	pop    %ebp
f010149b:	c3                   	ret    

f010149c <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010149c:	55                   	push   %ebp
f010149d:	89 e5                	mov    %esp,%ebp
f010149f:	83 ec 28             	sub    $0x28,%esp
f01014a2:	8b 45 08             	mov    0x8(%ebp),%eax
f01014a5:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
f01014a8:	85 c0                	test   %eax,%eax
f01014aa:	74 04                	je     f01014b0 <vsnprintf+0x14>
f01014ac:	85 d2                	test   %edx,%edx
f01014ae:	7f 07                	jg     f01014b7 <vsnprintf+0x1b>
f01014b0:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01014b5:	eb 3b                	jmp    f01014f2 <vsnprintf+0x56>
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};
f01014b7:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01014ba:	8d 44 10 ff          	lea    -0x1(%eax,%edx,1),%eax
f01014be:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01014c1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01014c8:	8b 45 14             	mov    0x14(%ebp),%eax
f01014cb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01014cf:	8b 45 10             	mov    0x10(%ebp),%eax
f01014d2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01014d6:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01014d9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01014dd:	c7 04 24 b3 0e 10 f0 	movl   $0xf0100eb3,(%esp)
f01014e4:	e8 e7 f9 ff ff       	call   f0100ed0 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01014e9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01014ec:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01014ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f01014f2:	c9                   	leave  
f01014f3:	c3                   	ret    

f01014f4 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01014f4:	55                   	push   %ebp
f01014f5:	89 e5                	mov    %esp,%ebp
f01014f7:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
	rc = vsnprintf(buf, n, fmt, ap);
f01014fa:	8d 45 14             	lea    0x14(%ebp),%eax
f01014fd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101501:	8b 45 10             	mov    0x10(%ebp),%eax
f0101504:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101508:	8b 45 0c             	mov    0xc(%ebp),%eax
f010150b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010150f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101512:	89 04 24             	mov    %eax,(%esp)
f0101515:	e8 82 ff ff ff       	call   f010149c <vsnprintf>
	va_end(ap);

	return rc;
}
f010151a:	c9                   	leave  
f010151b:	c3                   	ret    

f010151c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010151c:	55                   	push   %ebp
f010151d:	89 e5                	mov    %esp,%ebp
f010151f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
	vprintfmt(putch, putdat, fmt, ap);
f0101522:	8d 45 14             	lea    0x14(%ebp),%eax
f0101525:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101529:	8b 45 10             	mov    0x10(%ebp),%eax
f010152c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101530:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101533:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101537:	8b 45 08             	mov    0x8(%ebp),%eax
f010153a:	89 04 24             	mov    %eax,(%esp)
f010153d:	e8 8e f9 ff ff       	call   f0100ed0 <vprintfmt>
	va_end(ap);
}
f0101542:	c9                   	leave  
f0101543:	c3                   	ret    
	...

f0101550 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101550:	55                   	push   %ebp
f0101551:	89 e5                	mov    %esp,%ebp
f0101553:	57                   	push   %edi
f0101554:	56                   	push   %esi
f0101555:	53                   	push   %ebx
f0101556:	83 ec 1c             	sub    $0x1c,%esp
f0101559:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010155c:	85 c0                	test   %eax,%eax
f010155e:	74 10                	je     f0101570 <readline+0x20>
		cprintf("%s", prompt);
f0101560:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101564:	c7 04 24 a7 22 10 f0 	movl   $0xf01022a7,(%esp)
f010156b:	e8 83 f4 ff ff       	call   f01009f3 <cprintf>

	i = 0;
	echoing = iscons(0);
f0101570:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101577:	e8 1a ed ff ff       	call   f0100296 <iscons>
f010157c:	89 c7                	mov    %eax,%edi
f010157e:	be 00 00 00 00       	mov    $0x0,%esi
	while (1) {
		c = getchar();
f0101583:	e8 fd ec ff ff       	call   f0100285 <getchar>
f0101588:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010158a:	85 c0                	test   %eax,%eax
f010158c:	79 17                	jns    f01015a5 <readline+0x55>
			cprintf("read error: %e\n", c);
f010158e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101592:	c7 04 24 90 24 10 f0 	movl   $0xf0102490,(%esp)
f0101599:	e8 55 f4 ff ff       	call   f01009f3 <cprintf>
f010159e:	b8 00 00 00 00       	mov    $0x0,%eax
			return NULL;
f01015a3:	eb 76                	jmp    f010161b <readline+0xcb>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01015a5:	83 f8 08             	cmp    $0x8,%eax
f01015a8:	74 08                	je     f01015b2 <readline+0x62>
f01015aa:	83 f8 7f             	cmp    $0x7f,%eax
f01015ad:	8d 76 00             	lea    0x0(%esi),%esi
f01015b0:	75 19                	jne    f01015cb <readline+0x7b>
f01015b2:	85 f6                	test   %esi,%esi
f01015b4:	7e 15                	jle    f01015cb <readline+0x7b>
			if (echoing)
f01015b6:	85 ff                	test   %edi,%edi
f01015b8:	74 0c                	je     f01015c6 <readline+0x76>
				cputchar('\b');
f01015ba:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01015c1:	e8 d3 ee ff ff       	call   f0100499 <cputchar>
			i--;
f01015c6:	83 ee 01             	sub    $0x1,%esi
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01015c9:	eb b8                	jmp    f0101583 <readline+0x33>
			if (echoing)
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
f01015cb:	83 fb 1f             	cmp    $0x1f,%ebx
f01015ce:	66 90                	xchg   %ax,%ax
f01015d0:	7e 23                	jle    f01015f5 <readline+0xa5>
f01015d2:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01015d8:	7f 1b                	jg     f01015f5 <readline+0xa5>
			if (echoing)
f01015da:	85 ff                	test   %edi,%edi
f01015dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01015e0:	74 08                	je     f01015ea <readline+0x9a>
				cputchar(c);
f01015e2:	89 1c 24             	mov    %ebx,(%esp)
f01015e5:	e8 af ee ff ff       	call   f0100499 <cputchar>
			buf[i++] = c;
f01015ea:	88 9e a0 05 11 f0    	mov    %bl,-0xfeefa60(%esi)
f01015f0:	83 c6 01             	add    $0x1,%esi
f01015f3:	eb 8e                	jmp    f0101583 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01015f5:	83 fb 0a             	cmp    $0xa,%ebx
f01015f8:	74 05                	je     f01015ff <readline+0xaf>
f01015fa:	83 fb 0d             	cmp    $0xd,%ebx
f01015fd:	75 84                	jne    f0101583 <readline+0x33>
			if (echoing)
f01015ff:	85 ff                	test   %edi,%edi
f0101601:	74 0c                	je     f010160f <readline+0xbf>
				cputchar('\n');
f0101603:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f010160a:	e8 8a ee ff ff       	call   f0100499 <cputchar>
			buf[i] = 0;
f010160f:	c6 86 a0 05 11 f0 00 	movb   $0x0,-0xfeefa60(%esi)
f0101616:	b8 a0 05 11 f0       	mov    $0xf01105a0,%eax
			return buf;
		}
	}
}
f010161b:	83 c4 1c             	add    $0x1c,%esp
f010161e:	5b                   	pop    %ebx
f010161f:	5e                   	pop    %esi
f0101620:	5f                   	pop    %edi
f0101621:	5d                   	pop    %ebp
f0101622:	c3                   	ret    
	...

f0101630 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101630:	55                   	push   %ebp
f0101631:	89 e5                	mov    %esp,%ebp
f0101633:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101636:	b8 00 00 00 00       	mov    $0x0,%eax
f010163b:	80 3a 00             	cmpb   $0x0,(%edx)
f010163e:	74 09                	je     f0101649 <strlen+0x19>
		n++;
f0101640:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101643:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101647:	75 f7                	jne    f0101640 <strlen+0x10>
		n++;
	return n;
}
f0101649:	5d                   	pop    %ebp
f010164a:	c3                   	ret    

f010164b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010164b:	55                   	push   %ebp
f010164c:	89 e5                	mov    %esp,%ebp
f010164e:	53                   	push   %ebx
f010164f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101652:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101655:	85 c9                	test   %ecx,%ecx
f0101657:	74 19                	je     f0101672 <strnlen+0x27>
f0101659:	80 3b 00             	cmpb   $0x0,(%ebx)
f010165c:	74 14                	je     f0101672 <strnlen+0x27>
f010165e:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0101663:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101666:	39 c8                	cmp    %ecx,%eax
f0101668:	74 0d                	je     f0101677 <strnlen+0x2c>
f010166a:	80 3c 03 00          	cmpb   $0x0,(%ebx,%eax,1)
f010166e:	75 f3                	jne    f0101663 <strnlen+0x18>
f0101670:	eb 05                	jmp    f0101677 <strnlen+0x2c>
f0101672:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101677:	5b                   	pop    %ebx
f0101678:	5d                   	pop    %ebp
f0101679:	c3                   	ret    

f010167a <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010167a:	55                   	push   %ebp
f010167b:	89 e5                	mov    %esp,%ebp
f010167d:	53                   	push   %ebx
f010167e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101681:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101684:	ba 00 00 00 00       	mov    $0x0,%edx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101689:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010168d:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0101690:	83 c2 01             	add    $0x1,%edx
f0101693:	84 c9                	test   %cl,%cl
f0101695:	75 f2                	jne    f0101689 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0101697:	5b                   	pop    %ebx
f0101698:	5d                   	pop    %ebp
f0101699:	c3                   	ret    

f010169a <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010169a:	55                   	push   %ebp
f010169b:	89 e5                	mov    %esp,%ebp
f010169d:	56                   	push   %esi
f010169e:	53                   	push   %ebx
f010169f:	8b 45 08             	mov    0x8(%ebp),%eax
f01016a2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01016a5:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01016a8:	85 f6                	test   %esi,%esi
f01016aa:	74 18                	je     f01016c4 <strncpy+0x2a>
f01016ac:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f01016b1:	0f b6 1a             	movzbl (%edx),%ebx
f01016b4:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01016b7:	80 3a 01             	cmpb   $0x1,(%edx)
f01016ba:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01016bd:	83 c1 01             	add    $0x1,%ecx
f01016c0:	39 ce                	cmp    %ecx,%esi
f01016c2:	77 ed                	ja     f01016b1 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01016c4:	5b                   	pop    %ebx
f01016c5:	5e                   	pop    %esi
f01016c6:	5d                   	pop    %ebp
f01016c7:	c3                   	ret    

f01016c8 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01016c8:	55                   	push   %ebp
f01016c9:	89 e5                	mov    %esp,%ebp
f01016cb:	56                   	push   %esi
f01016cc:	53                   	push   %ebx
f01016cd:	8b 75 08             	mov    0x8(%ebp),%esi
f01016d0:	8b 55 0c             	mov    0xc(%ebp),%edx
f01016d3:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01016d6:	89 f0                	mov    %esi,%eax
f01016d8:	85 c9                	test   %ecx,%ecx
f01016da:	74 27                	je     f0101703 <strlcpy+0x3b>
		while (--size > 0 && *src != '\0')
f01016dc:	83 e9 01             	sub    $0x1,%ecx
f01016df:	74 1d                	je     f01016fe <strlcpy+0x36>
f01016e1:	0f b6 1a             	movzbl (%edx),%ebx
f01016e4:	84 db                	test   %bl,%bl
f01016e6:	74 16                	je     f01016fe <strlcpy+0x36>
			*dst++ = *src++;
f01016e8:	88 18                	mov    %bl,(%eax)
f01016ea:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01016ed:	83 e9 01             	sub    $0x1,%ecx
f01016f0:	74 0e                	je     f0101700 <strlcpy+0x38>
			*dst++ = *src++;
f01016f2:	83 c2 01             	add    $0x1,%edx
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01016f5:	0f b6 1a             	movzbl (%edx),%ebx
f01016f8:	84 db                	test   %bl,%bl
f01016fa:	75 ec                	jne    f01016e8 <strlcpy+0x20>
f01016fc:	eb 02                	jmp    f0101700 <strlcpy+0x38>
f01016fe:	89 f0                	mov    %esi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101700:	c6 00 00             	movb   $0x0,(%eax)
f0101703:	29 f0                	sub    %esi,%eax
	}
	return dst - dst_in;
}
f0101705:	5b                   	pop    %ebx
f0101706:	5e                   	pop    %esi
f0101707:	5d                   	pop    %ebp
f0101708:	c3                   	ret    

f0101709 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101709:	55                   	push   %ebp
f010170a:	89 e5                	mov    %esp,%ebp
f010170c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010170f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101712:	0f b6 01             	movzbl (%ecx),%eax
f0101715:	84 c0                	test   %al,%al
f0101717:	74 15                	je     f010172e <strcmp+0x25>
f0101719:	3a 02                	cmp    (%edx),%al
f010171b:	75 11                	jne    f010172e <strcmp+0x25>
		p++, q++;
f010171d:	83 c1 01             	add    $0x1,%ecx
f0101720:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101723:	0f b6 01             	movzbl (%ecx),%eax
f0101726:	84 c0                	test   %al,%al
f0101728:	74 04                	je     f010172e <strcmp+0x25>
f010172a:	3a 02                	cmp    (%edx),%al
f010172c:	74 ef                	je     f010171d <strcmp+0x14>
f010172e:	0f b6 c0             	movzbl %al,%eax
f0101731:	0f b6 12             	movzbl (%edx),%edx
f0101734:	29 d0                	sub    %edx,%eax
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101736:	5d                   	pop    %ebp
f0101737:	c3                   	ret    

f0101738 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101738:	55                   	push   %ebp
f0101739:	89 e5                	mov    %esp,%ebp
f010173b:	53                   	push   %ebx
f010173c:	8b 55 08             	mov    0x8(%ebp),%edx
f010173f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101742:	8b 45 10             	mov    0x10(%ebp),%eax
	while (n > 0 && *p && *p == *q)
f0101745:	85 c0                	test   %eax,%eax
f0101747:	74 23                	je     f010176c <strncmp+0x34>
f0101749:	0f b6 1a             	movzbl (%edx),%ebx
f010174c:	84 db                	test   %bl,%bl
f010174e:	74 24                	je     f0101774 <strncmp+0x3c>
f0101750:	3a 19                	cmp    (%ecx),%bl
f0101752:	75 20                	jne    f0101774 <strncmp+0x3c>
f0101754:	83 e8 01             	sub    $0x1,%eax
f0101757:	74 13                	je     f010176c <strncmp+0x34>
		n--, p++, q++;
f0101759:	83 c2 01             	add    $0x1,%edx
f010175c:	83 c1 01             	add    $0x1,%ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010175f:	0f b6 1a             	movzbl (%edx),%ebx
f0101762:	84 db                	test   %bl,%bl
f0101764:	74 0e                	je     f0101774 <strncmp+0x3c>
f0101766:	3a 19                	cmp    (%ecx),%bl
f0101768:	74 ea                	je     f0101754 <strncmp+0x1c>
f010176a:	eb 08                	jmp    f0101774 <strncmp+0x3c>
f010176c:	b8 00 00 00 00       	mov    $0x0,%eax
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101771:	5b                   	pop    %ebx
f0101772:	5d                   	pop    %ebp
f0101773:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101774:	0f b6 02             	movzbl (%edx),%eax
f0101777:	0f b6 11             	movzbl (%ecx),%edx
f010177a:	29 d0                	sub    %edx,%eax
f010177c:	eb f3                	jmp    f0101771 <strncmp+0x39>

f010177e <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010177e:	55                   	push   %ebp
f010177f:	89 e5                	mov    %esp,%ebp
f0101781:	8b 45 08             	mov    0x8(%ebp),%eax
f0101784:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101788:	0f b6 10             	movzbl (%eax),%edx
f010178b:	84 d2                	test   %dl,%dl
f010178d:	74 15                	je     f01017a4 <strchr+0x26>
		if (*s == c)
f010178f:	38 ca                	cmp    %cl,%dl
f0101791:	75 07                	jne    f010179a <strchr+0x1c>
f0101793:	eb 14                	jmp    f01017a9 <strchr+0x2b>
f0101795:	38 ca                	cmp    %cl,%dl
f0101797:	90                   	nop
f0101798:	74 0f                	je     f01017a9 <strchr+0x2b>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010179a:	83 c0 01             	add    $0x1,%eax
f010179d:	0f b6 10             	movzbl (%eax),%edx
f01017a0:	84 d2                	test   %dl,%dl
f01017a2:	75 f1                	jne    f0101795 <strchr+0x17>
f01017a4:	b8 00 00 00 00       	mov    $0x0,%eax
		if (*s == c)
			return (char *) s;
	return 0;
}
f01017a9:	5d                   	pop    %ebp
f01017aa:	c3                   	ret    

f01017ab <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01017ab:	55                   	push   %ebp
f01017ac:	89 e5                	mov    %esp,%ebp
f01017ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01017b1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01017b5:	0f b6 10             	movzbl (%eax),%edx
f01017b8:	84 d2                	test   %dl,%dl
f01017ba:	74 18                	je     f01017d4 <strfind+0x29>
		if (*s == c)
f01017bc:	38 ca                	cmp    %cl,%dl
f01017be:	75 0a                	jne    f01017ca <strfind+0x1f>
f01017c0:	eb 12                	jmp    f01017d4 <strfind+0x29>
f01017c2:	38 ca                	cmp    %cl,%dl
f01017c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017c8:	74 0a                	je     f01017d4 <strfind+0x29>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01017ca:	83 c0 01             	add    $0x1,%eax
f01017cd:	0f b6 10             	movzbl (%eax),%edx
f01017d0:	84 d2                	test   %dl,%dl
f01017d2:	75 ee                	jne    f01017c2 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f01017d4:	5d                   	pop    %ebp
f01017d5:	c3                   	ret    

f01017d6 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01017d6:	55                   	push   %ebp
f01017d7:	89 e5                	mov    %esp,%ebp
f01017d9:	83 ec 0c             	sub    $0xc,%esp
f01017dc:	89 1c 24             	mov    %ebx,(%esp)
f01017df:	89 74 24 04          	mov    %esi,0x4(%esp)
f01017e3:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01017e7:	8b 7d 08             	mov    0x8(%ebp),%edi
f01017ea:	8b 45 0c             	mov    0xc(%ebp),%eax
f01017ed:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01017f0:	85 c9                	test   %ecx,%ecx
f01017f2:	74 30                	je     f0101824 <memset+0x4e>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01017f4:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01017fa:	75 25                	jne    f0101821 <memset+0x4b>
f01017fc:	f6 c1 03             	test   $0x3,%cl
f01017ff:	75 20                	jne    f0101821 <memset+0x4b>
		c &= 0xFF;
f0101801:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101804:	89 d3                	mov    %edx,%ebx
f0101806:	c1 e3 08             	shl    $0x8,%ebx
f0101809:	89 d6                	mov    %edx,%esi
f010180b:	c1 e6 18             	shl    $0x18,%esi
f010180e:	89 d0                	mov    %edx,%eax
f0101810:	c1 e0 10             	shl    $0x10,%eax
f0101813:	09 f0                	or     %esi,%eax
f0101815:	09 d0                	or     %edx,%eax
		asm volatile("cld; rep stosl\n"
f0101817:	09 d8                	or     %ebx,%eax
f0101819:	c1 e9 02             	shr    $0x2,%ecx
f010181c:	fc                   	cld    
f010181d:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010181f:	eb 03                	jmp    f0101824 <memset+0x4e>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101821:	fc                   	cld    
f0101822:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101824:	89 f8                	mov    %edi,%eax
f0101826:	8b 1c 24             	mov    (%esp),%ebx
f0101829:	8b 74 24 04          	mov    0x4(%esp),%esi
f010182d:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101831:	89 ec                	mov    %ebp,%esp
f0101833:	5d                   	pop    %ebp
f0101834:	c3                   	ret    

f0101835 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101835:	55                   	push   %ebp
f0101836:	89 e5                	mov    %esp,%ebp
f0101838:	83 ec 08             	sub    $0x8,%esp
f010183b:	89 34 24             	mov    %esi,(%esp)
f010183e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101842:	8b 45 08             	mov    0x8(%ebp),%eax
f0101845:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
f0101848:	8b 75 0c             	mov    0xc(%ebp),%esi
	d = dst;
f010184b:	89 c7                	mov    %eax,%edi
	if (s < d && s + n > d) {
f010184d:	39 c6                	cmp    %eax,%esi
f010184f:	73 35                	jae    f0101886 <memmove+0x51>
f0101851:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101854:	39 d0                	cmp    %edx,%eax
f0101856:	73 2e                	jae    f0101886 <memmove+0x51>
		s += n;
		d += n;
f0101858:	01 cf                	add    %ecx,%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010185a:	f6 c2 03             	test   $0x3,%dl
f010185d:	75 1b                	jne    f010187a <memmove+0x45>
f010185f:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101865:	75 13                	jne    f010187a <memmove+0x45>
f0101867:	f6 c1 03             	test   $0x3,%cl
f010186a:	75 0e                	jne    f010187a <memmove+0x45>
			asm volatile("std; rep movsl\n"
f010186c:	83 ef 04             	sub    $0x4,%edi
f010186f:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101872:	c1 e9 02             	shr    $0x2,%ecx
f0101875:	fd                   	std    
f0101876:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101878:	eb 09                	jmp    f0101883 <memmove+0x4e>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010187a:	83 ef 01             	sub    $0x1,%edi
f010187d:	8d 72 ff             	lea    -0x1(%edx),%esi
f0101880:	fd                   	std    
f0101881:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101883:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101884:	eb 20                	jmp    f01018a6 <memmove+0x71>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101886:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010188c:	75 15                	jne    f01018a3 <memmove+0x6e>
f010188e:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101894:	75 0d                	jne    f01018a3 <memmove+0x6e>
f0101896:	f6 c1 03             	test   $0x3,%cl
f0101899:	75 08                	jne    f01018a3 <memmove+0x6e>
			asm volatile("cld; rep movsl\n"
f010189b:	c1 e9 02             	shr    $0x2,%ecx
f010189e:	fc                   	cld    
f010189f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01018a1:	eb 03                	jmp    f01018a6 <memmove+0x71>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01018a3:	fc                   	cld    
f01018a4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01018a6:	8b 34 24             	mov    (%esp),%esi
f01018a9:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01018ad:	89 ec                	mov    %ebp,%esp
f01018af:	5d                   	pop    %ebp
f01018b0:	c3                   	ret    

f01018b1 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f01018b1:	55                   	push   %ebp
f01018b2:	89 e5                	mov    %esp,%ebp
f01018b4:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01018b7:	8b 45 10             	mov    0x10(%ebp),%eax
f01018ba:	89 44 24 08          	mov    %eax,0x8(%esp)
f01018be:	8b 45 0c             	mov    0xc(%ebp),%eax
f01018c1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018c5:	8b 45 08             	mov    0x8(%ebp),%eax
f01018c8:	89 04 24             	mov    %eax,(%esp)
f01018cb:	e8 65 ff ff ff       	call   f0101835 <memmove>
}
f01018d0:	c9                   	leave  
f01018d1:	c3                   	ret    

f01018d2 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01018d2:	55                   	push   %ebp
f01018d3:	89 e5                	mov    %esp,%ebp
f01018d5:	57                   	push   %edi
f01018d6:	56                   	push   %esi
f01018d7:	53                   	push   %ebx
f01018d8:	8b 75 08             	mov    0x8(%ebp),%esi
f01018db:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01018de:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01018e1:	85 c9                	test   %ecx,%ecx
f01018e3:	74 36                	je     f010191b <memcmp+0x49>
		if (*s1 != *s2)
f01018e5:	0f b6 06             	movzbl (%esi),%eax
f01018e8:	0f b6 1f             	movzbl (%edi),%ebx
f01018eb:	38 d8                	cmp    %bl,%al
f01018ed:	74 20                	je     f010190f <memcmp+0x3d>
f01018ef:	eb 14                	jmp    f0101905 <memcmp+0x33>
f01018f1:	0f b6 44 16 01       	movzbl 0x1(%esi,%edx,1),%eax
f01018f6:	0f b6 5c 17 01       	movzbl 0x1(%edi,%edx,1),%ebx
f01018fb:	83 c2 01             	add    $0x1,%edx
f01018fe:	83 e9 01             	sub    $0x1,%ecx
f0101901:	38 d8                	cmp    %bl,%al
f0101903:	74 12                	je     f0101917 <memcmp+0x45>
			return (int) *s1 - (int) *s2;
f0101905:	0f b6 c0             	movzbl %al,%eax
f0101908:	0f b6 db             	movzbl %bl,%ebx
f010190b:	29 d8                	sub    %ebx,%eax
f010190d:	eb 11                	jmp    f0101920 <memcmp+0x4e>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010190f:	83 e9 01             	sub    $0x1,%ecx
f0101912:	ba 00 00 00 00       	mov    $0x0,%edx
f0101917:	85 c9                	test   %ecx,%ecx
f0101919:	75 d6                	jne    f01018f1 <memcmp+0x1f>
f010191b:	b8 00 00 00 00       	mov    $0x0,%eax
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
}
f0101920:	5b                   	pop    %ebx
f0101921:	5e                   	pop    %esi
f0101922:	5f                   	pop    %edi
f0101923:	5d                   	pop    %ebp
f0101924:	c3                   	ret    

f0101925 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101925:	55                   	push   %ebp
f0101926:	89 e5                	mov    %esp,%ebp
f0101928:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010192b:	89 c2                	mov    %eax,%edx
f010192d:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101930:	39 d0                	cmp    %edx,%eax
f0101932:	73 15                	jae    f0101949 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101934:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0101938:	38 08                	cmp    %cl,(%eax)
f010193a:	75 06                	jne    f0101942 <memfind+0x1d>
f010193c:	eb 0b                	jmp    f0101949 <memfind+0x24>
f010193e:	38 08                	cmp    %cl,(%eax)
f0101940:	74 07                	je     f0101949 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101942:	83 c0 01             	add    $0x1,%eax
f0101945:	39 c2                	cmp    %eax,%edx
f0101947:	77 f5                	ja     f010193e <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101949:	5d                   	pop    %ebp
f010194a:	c3                   	ret    

f010194b <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010194b:	55                   	push   %ebp
f010194c:	89 e5                	mov    %esp,%ebp
f010194e:	57                   	push   %edi
f010194f:	56                   	push   %esi
f0101950:	53                   	push   %ebx
f0101951:	83 ec 04             	sub    $0x4,%esp
f0101954:	8b 55 08             	mov    0x8(%ebp),%edx
f0101957:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010195a:	0f b6 02             	movzbl (%edx),%eax
f010195d:	3c 20                	cmp    $0x20,%al
f010195f:	74 04                	je     f0101965 <strtol+0x1a>
f0101961:	3c 09                	cmp    $0x9,%al
f0101963:	75 0e                	jne    f0101973 <strtol+0x28>
		s++;
f0101965:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101968:	0f b6 02             	movzbl (%edx),%eax
f010196b:	3c 20                	cmp    $0x20,%al
f010196d:	74 f6                	je     f0101965 <strtol+0x1a>
f010196f:	3c 09                	cmp    $0x9,%al
f0101971:	74 f2                	je     f0101965 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101973:	3c 2b                	cmp    $0x2b,%al
f0101975:	75 0c                	jne    f0101983 <strtol+0x38>
		s++;
f0101977:	83 c2 01             	add    $0x1,%edx
f010197a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f0101981:	eb 15                	jmp    f0101998 <strtol+0x4d>
	else if (*s == '-')
f0101983:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f010198a:	3c 2d                	cmp    $0x2d,%al
f010198c:	75 0a                	jne    f0101998 <strtol+0x4d>
		s++, neg = 1;
f010198e:	83 c2 01             	add    $0x1,%edx
f0101991:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101998:	85 db                	test   %ebx,%ebx
f010199a:	0f 94 c0             	sete   %al
f010199d:	74 05                	je     f01019a4 <strtol+0x59>
f010199f:	83 fb 10             	cmp    $0x10,%ebx
f01019a2:	75 18                	jne    f01019bc <strtol+0x71>
f01019a4:	80 3a 30             	cmpb   $0x30,(%edx)
f01019a7:	75 13                	jne    f01019bc <strtol+0x71>
f01019a9:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01019ad:	8d 76 00             	lea    0x0(%esi),%esi
f01019b0:	75 0a                	jne    f01019bc <strtol+0x71>
		s += 2, base = 16;
f01019b2:	83 c2 02             	add    $0x2,%edx
f01019b5:	bb 10 00 00 00       	mov    $0x10,%ebx
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01019ba:	eb 15                	jmp    f01019d1 <strtol+0x86>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01019bc:	84 c0                	test   %al,%al
f01019be:	66 90                	xchg   %ax,%ax
f01019c0:	74 0f                	je     f01019d1 <strtol+0x86>
f01019c2:	bb 0a 00 00 00       	mov    $0xa,%ebx
f01019c7:	80 3a 30             	cmpb   $0x30,(%edx)
f01019ca:	75 05                	jne    f01019d1 <strtol+0x86>
		s++, base = 8;
f01019cc:	83 c2 01             	add    $0x1,%edx
f01019cf:	b3 08                	mov    $0x8,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01019d1:	b8 00 00 00 00       	mov    $0x0,%eax
f01019d6:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01019d8:	0f b6 0a             	movzbl (%edx),%ecx
f01019db:	89 cf                	mov    %ecx,%edi
f01019dd:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f01019e0:	80 fb 09             	cmp    $0x9,%bl
f01019e3:	77 08                	ja     f01019ed <strtol+0xa2>
			dig = *s - '0';
f01019e5:	0f be c9             	movsbl %cl,%ecx
f01019e8:	83 e9 30             	sub    $0x30,%ecx
f01019eb:	eb 1e                	jmp    f0101a0b <strtol+0xc0>
		else if (*s >= 'a' && *s <= 'z')
f01019ed:	8d 5f 9f             	lea    -0x61(%edi),%ebx
f01019f0:	80 fb 19             	cmp    $0x19,%bl
f01019f3:	77 08                	ja     f01019fd <strtol+0xb2>
			dig = *s - 'a' + 10;
f01019f5:	0f be c9             	movsbl %cl,%ecx
f01019f8:	83 e9 57             	sub    $0x57,%ecx
f01019fb:	eb 0e                	jmp    f0101a0b <strtol+0xc0>
		else if (*s >= 'A' && *s <= 'Z')
f01019fd:	8d 5f bf             	lea    -0x41(%edi),%ebx
f0101a00:	80 fb 19             	cmp    $0x19,%bl
f0101a03:	77 15                	ja     f0101a1a <strtol+0xcf>
			dig = *s - 'A' + 10;
f0101a05:	0f be c9             	movsbl %cl,%ecx
f0101a08:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101a0b:	39 f1                	cmp    %esi,%ecx
f0101a0d:	7d 0b                	jge    f0101a1a <strtol+0xcf>
			break;
		s++, val = (val * base) + dig;
f0101a0f:	83 c2 01             	add    $0x1,%edx
f0101a12:	0f af c6             	imul   %esi,%eax
f0101a15:	8d 04 01             	lea    (%ecx,%eax,1),%eax
		// we don't properly detect overflow!
	}
f0101a18:	eb be                	jmp    f01019d8 <strtol+0x8d>
f0101a1a:	89 c1                	mov    %eax,%ecx

	if (endptr)
f0101a1c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101a20:	74 05                	je     f0101a27 <strtol+0xdc>
		*endptr = (char *) s;
f0101a22:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101a25:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101a27:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0101a2b:	74 04                	je     f0101a31 <strtol+0xe6>
f0101a2d:	89 c8                	mov    %ecx,%eax
f0101a2f:	f7 d8                	neg    %eax
}
f0101a31:	83 c4 04             	add    $0x4,%esp
f0101a34:	5b                   	pop    %ebx
f0101a35:	5e                   	pop    %esi
f0101a36:	5f                   	pop    %edi
f0101a37:	5d                   	pop    %ebp
f0101a38:	c3                   	ret    
f0101a39:	00 00                	add    %al,(%eax)
f0101a3b:	00 00                	add    %al,(%eax)
f0101a3d:	00 00                	add    %al,(%eax)
	...

f0101a40 <__udivdi3>:
f0101a40:	55                   	push   %ebp
f0101a41:	89 e5                	mov    %esp,%ebp
f0101a43:	57                   	push   %edi
f0101a44:	56                   	push   %esi
f0101a45:	83 ec 10             	sub    $0x10,%esp
f0101a48:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a4b:	8b 55 08             	mov    0x8(%ebp),%edx
f0101a4e:	8b 75 10             	mov    0x10(%ebp),%esi
f0101a51:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101a54:	85 c0                	test   %eax,%eax
f0101a56:	89 55 f0             	mov    %edx,-0x10(%ebp)
f0101a59:	75 35                	jne    f0101a90 <__udivdi3+0x50>
f0101a5b:	39 fe                	cmp    %edi,%esi
f0101a5d:	77 61                	ja     f0101ac0 <__udivdi3+0x80>
f0101a5f:	85 f6                	test   %esi,%esi
f0101a61:	75 0b                	jne    f0101a6e <__udivdi3+0x2e>
f0101a63:	b8 01 00 00 00       	mov    $0x1,%eax
f0101a68:	31 d2                	xor    %edx,%edx
f0101a6a:	f7 f6                	div    %esi
f0101a6c:	89 c6                	mov    %eax,%esi
f0101a6e:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0101a71:	31 d2                	xor    %edx,%edx
f0101a73:	89 f8                	mov    %edi,%eax
f0101a75:	f7 f6                	div    %esi
f0101a77:	89 c7                	mov    %eax,%edi
f0101a79:	89 c8                	mov    %ecx,%eax
f0101a7b:	f7 f6                	div    %esi
f0101a7d:	89 c1                	mov    %eax,%ecx
f0101a7f:	89 fa                	mov    %edi,%edx
f0101a81:	89 c8                	mov    %ecx,%eax
f0101a83:	83 c4 10             	add    $0x10,%esp
f0101a86:	5e                   	pop    %esi
f0101a87:	5f                   	pop    %edi
f0101a88:	5d                   	pop    %ebp
f0101a89:	c3                   	ret    
f0101a8a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101a90:	39 f8                	cmp    %edi,%eax
f0101a92:	77 1c                	ja     f0101ab0 <__udivdi3+0x70>
f0101a94:	0f bd d0             	bsr    %eax,%edx
f0101a97:	83 f2 1f             	xor    $0x1f,%edx
f0101a9a:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0101a9d:	75 39                	jne    f0101ad8 <__udivdi3+0x98>
f0101a9f:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0101aa2:	0f 86 a0 00 00 00    	jbe    f0101b48 <__udivdi3+0x108>
f0101aa8:	39 f8                	cmp    %edi,%eax
f0101aaa:	0f 82 98 00 00 00    	jb     f0101b48 <__udivdi3+0x108>
f0101ab0:	31 ff                	xor    %edi,%edi
f0101ab2:	31 c9                	xor    %ecx,%ecx
f0101ab4:	89 c8                	mov    %ecx,%eax
f0101ab6:	89 fa                	mov    %edi,%edx
f0101ab8:	83 c4 10             	add    $0x10,%esp
f0101abb:	5e                   	pop    %esi
f0101abc:	5f                   	pop    %edi
f0101abd:	5d                   	pop    %ebp
f0101abe:	c3                   	ret    
f0101abf:	90                   	nop
f0101ac0:	89 d1                	mov    %edx,%ecx
f0101ac2:	89 fa                	mov    %edi,%edx
f0101ac4:	89 c8                	mov    %ecx,%eax
f0101ac6:	31 ff                	xor    %edi,%edi
f0101ac8:	f7 f6                	div    %esi
f0101aca:	89 c1                	mov    %eax,%ecx
f0101acc:	89 fa                	mov    %edi,%edx
f0101ace:	89 c8                	mov    %ecx,%eax
f0101ad0:	83 c4 10             	add    $0x10,%esp
f0101ad3:	5e                   	pop    %esi
f0101ad4:	5f                   	pop    %edi
f0101ad5:	5d                   	pop    %ebp
f0101ad6:	c3                   	ret    
f0101ad7:	90                   	nop
f0101ad8:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f0101adc:	89 f2                	mov    %esi,%edx
f0101ade:	d3 e0                	shl    %cl,%eax
f0101ae0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101ae3:	b8 20 00 00 00       	mov    $0x20,%eax
f0101ae8:	2b 45 f4             	sub    -0xc(%ebp),%eax
f0101aeb:	89 c1                	mov    %eax,%ecx
f0101aed:	d3 ea                	shr    %cl,%edx
f0101aef:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f0101af3:	0b 55 ec             	or     -0x14(%ebp),%edx
f0101af6:	d3 e6                	shl    %cl,%esi
f0101af8:	89 c1                	mov    %eax,%ecx
f0101afa:	89 75 e8             	mov    %esi,-0x18(%ebp)
f0101afd:	89 fe                	mov    %edi,%esi
f0101aff:	d3 ee                	shr    %cl,%esi
f0101b01:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f0101b05:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0101b08:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101b0b:	d3 e7                	shl    %cl,%edi
f0101b0d:	89 c1                	mov    %eax,%ecx
f0101b0f:	d3 ea                	shr    %cl,%edx
f0101b11:	09 d7                	or     %edx,%edi
f0101b13:	89 f2                	mov    %esi,%edx
f0101b15:	89 f8                	mov    %edi,%eax
f0101b17:	f7 75 ec             	divl   -0x14(%ebp)
f0101b1a:	89 d6                	mov    %edx,%esi
f0101b1c:	89 c7                	mov    %eax,%edi
f0101b1e:	f7 65 e8             	mull   -0x18(%ebp)
f0101b21:	39 d6                	cmp    %edx,%esi
f0101b23:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0101b26:	72 30                	jb     f0101b58 <__udivdi3+0x118>
f0101b28:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101b2b:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f0101b2f:	d3 e2                	shl    %cl,%edx
f0101b31:	39 c2                	cmp    %eax,%edx
f0101b33:	73 05                	jae    f0101b3a <__udivdi3+0xfa>
f0101b35:	3b 75 ec             	cmp    -0x14(%ebp),%esi
f0101b38:	74 1e                	je     f0101b58 <__udivdi3+0x118>
f0101b3a:	89 f9                	mov    %edi,%ecx
f0101b3c:	31 ff                	xor    %edi,%edi
f0101b3e:	e9 71 ff ff ff       	jmp    f0101ab4 <__udivdi3+0x74>
f0101b43:	90                   	nop
f0101b44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101b48:	31 ff                	xor    %edi,%edi
f0101b4a:	b9 01 00 00 00       	mov    $0x1,%ecx
f0101b4f:	e9 60 ff ff ff       	jmp    f0101ab4 <__udivdi3+0x74>
f0101b54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101b58:	8d 4f ff             	lea    -0x1(%edi),%ecx
f0101b5b:	31 ff                	xor    %edi,%edi
f0101b5d:	89 c8                	mov    %ecx,%eax
f0101b5f:	89 fa                	mov    %edi,%edx
f0101b61:	83 c4 10             	add    $0x10,%esp
f0101b64:	5e                   	pop    %esi
f0101b65:	5f                   	pop    %edi
f0101b66:	5d                   	pop    %ebp
f0101b67:	c3                   	ret    
	...

f0101b70 <__umoddi3>:
f0101b70:	55                   	push   %ebp
f0101b71:	89 e5                	mov    %esp,%ebp
f0101b73:	57                   	push   %edi
f0101b74:	56                   	push   %esi
f0101b75:	83 ec 20             	sub    $0x20,%esp
f0101b78:	8b 55 14             	mov    0x14(%ebp),%edx
f0101b7b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101b7e:	8b 7d 10             	mov    0x10(%ebp),%edi
f0101b81:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101b84:	85 d2                	test   %edx,%edx
f0101b86:	89 c8                	mov    %ecx,%eax
f0101b88:	89 4d f4             	mov    %ecx,-0xc(%ebp)
f0101b8b:	75 13                	jne    f0101ba0 <__umoddi3+0x30>
f0101b8d:	39 f7                	cmp    %esi,%edi
f0101b8f:	76 3f                	jbe    f0101bd0 <__umoddi3+0x60>
f0101b91:	89 f2                	mov    %esi,%edx
f0101b93:	f7 f7                	div    %edi
f0101b95:	89 d0                	mov    %edx,%eax
f0101b97:	31 d2                	xor    %edx,%edx
f0101b99:	83 c4 20             	add    $0x20,%esp
f0101b9c:	5e                   	pop    %esi
f0101b9d:	5f                   	pop    %edi
f0101b9e:	5d                   	pop    %ebp
f0101b9f:	c3                   	ret    
f0101ba0:	39 f2                	cmp    %esi,%edx
f0101ba2:	77 4c                	ja     f0101bf0 <__umoddi3+0x80>
f0101ba4:	0f bd ca             	bsr    %edx,%ecx
f0101ba7:	83 f1 1f             	xor    $0x1f,%ecx
f0101baa:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101bad:	75 51                	jne    f0101c00 <__umoddi3+0x90>
f0101baf:	3b 7d f4             	cmp    -0xc(%ebp),%edi
f0101bb2:	0f 87 e0 00 00 00    	ja     f0101c98 <__umoddi3+0x128>
f0101bb8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101bbb:	29 f8                	sub    %edi,%eax
f0101bbd:	19 d6                	sbb    %edx,%esi
f0101bbf:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101bc2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101bc5:	89 f2                	mov    %esi,%edx
f0101bc7:	83 c4 20             	add    $0x20,%esp
f0101bca:	5e                   	pop    %esi
f0101bcb:	5f                   	pop    %edi
f0101bcc:	5d                   	pop    %ebp
f0101bcd:	c3                   	ret    
f0101bce:	66 90                	xchg   %ax,%ax
f0101bd0:	85 ff                	test   %edi,%edi
f0101bd2:	75 0b                	jne    f0101bdf <__umoddi3+0x6f>
f0101bd4:	b8 01 00 00 00       	mov    $0x1,%eax
f0101bd9:	31 d2                	xor    %edx,%edx
f0101bdb:	f7 f7                	div    %edi
f0101bdd:	89 c7                	mov    %eax,%edi
f0101bdf:	89 f0                	mov    %esi,%eax
f0101be1:	31 d2                	xor    %edx,%edx
f0101be3:	f7 f7                	div    %edi
f0101be5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101be8:	f7 f7                	div    %edi
f0101bea:	eb a9                	jmp    f0101b95 <__umoddi3+0x25>
f0101bec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101bf0:	89 c8                	mov    %ecx,%eax
f0101bf2:	89 f2                	mov    %esi,%edx
f0101bf4:	83 c4 20             	add    $0x20,%esp
f0101bf7:	5e                   	pop    %esi
f0101bf8:	5f                   	pop    %edi
f0101bf9:	5d                   	pop    %ebp
f0101bfa:	c3                   	ret    
f0101bfb:	90                   	nop
f0101bfc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101c00:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101c04:	d3 e2                	shl    %cl,%edx
f0101c06:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0101c09:	ba 20 00 00 00       	mov    $0x20,%edx
f0101c0e:	2b 55 f0             	sub    -0x10(%ebp),%edx
f0101c11:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0101c14:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101c18:	89 fa                	mov    %edi,%edx
f0101c1a:	d3 ea                	shr    %cl,%edx
f0101c1c:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101c20:	0b 55 f4             	or     -0xc(%ebp),%edx
f0101c23:	d3 e7                	shl    %cl,%edi
f0101c25:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101c29:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0101c2c:	89 f2                	mov    %esi,%edx
f0101c2e:	89 7d e8             	mov    %edi,-0x18(%ebp)
f0101c31:	89 c7                	mov    %eax,%edi
f0101c33:	d3 ea                	shr    %cl,%edx
f0101c35:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101c39:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101c3c:	89 c2                	mov    %eax,%edx
f0101c3e:	d3 e6                	shl    %cl,%esi
f0101c40:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101c44:	d3 ea                	shr    %cl,%edx
f0101c46:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101c4a:	09 d6                	or     %edx,%esi
f0101c4c:	89 f0                	mov    %esi,%eax
f0101c4e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101c51:	d3 e7                	shl    %cl,%edi
f0101c53:	89 f2                	mov    %esi,%edx
f0101c55:	f7 75 f4             	divl   -0xc(%ebp)
f0101c58:	89 d6                	mov    %edx,%esi
f0101c5a:	f7 65 e8             	mull   -0x18(%ebp)
f0101c5d:	39 d6                	cmp    %edx,%esi
f0101c5f:	72 2b                	jb     f0101c8c <__umoddi3+0x11c>
f0101c61:	39 c7                	cmp    %eax,%edi
f0101c63:	72 23                	jb     f0101c88 <__umoddi3+0x118>
f0101c65:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101c69:	29 c7                	sub    %eax,%edi
f0101c6b:	19 d6                	sbb    %edx,%esi
f0101c6d:	89 f0                	mov    %esi,%eax
f0101c6f:	89 f2                	mov    %esi,%edx
f0101c71:	d3 ef                	shr    %cl,%edi
f0101c73:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101c77:	d3 e0                	shl    %cl,%eax
f0101c79:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101c7d:	09 f8                	or     %edi,%eax
f0101c7f:	d3 ea                	shr    %cl,%edx
f0101c81:	83 c4 20             	add    $0x20,%esp
f0101c84:	5e                   	pop    %esi
f0101c85:	5f                   	pop    %edi
f0101c86:	5d                   	pop    %ebp
f0101c87:	c3                   	ret    
f0101c88:	39 d6                	cmp    %edx,%esi
f0101c8a:	75 d9                	jne    f0101c65 <__umoddi3+0xf5>
f0101c8c:	2b 45 e8             	sub    -0x18(%ebp),%eax
f0101c8f:	1b 55 f4             	sbb    -0xc(%ebp),%edx
f0101c92:	eb d1                	jmp    f0101c65 <__umoddi3+0xf5>
f0101c94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101c98:	39 f2                	cmp    %esi,%edx
f0101c9a:	0f 82 18 ff ff ff    	jb     f0101bb8 <__umoddi3+0x48>
f0101ca0:	e9 1d ff ff ff       	jmp    f0101bc2 <__umoddi3+0x52>
