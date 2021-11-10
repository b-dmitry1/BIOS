	; Partial implementation of PC/AT int 15h
	; Designed for use with FPGA / emulator and
	; Intel 386EX / Texas Instruments 486 / Cyrix 486 CPUs

%include "drivers\a20.asm"

int15:
	cmp ah, 0x24
	je int15_a20
	cmp ah, 0x88
	je int15_memsize
	cmp ah, 0xC0
	je int15_getconfig
	cmp ax, 0xE801
	je int15_memsize2
	cmp ah, 0x8A
	je int15_memsize3

	mov ah, 0x86
	jmp iret_carry_on

int15_a20:
	cmp al, 0
	je int15_a20_disable
	cmp al, 1
	je int15_a20_enable
	cmp al, 2
	je int15_a20_get
	cmp al, 3
	je int15_a20_get_support
	mov ah, 0x86
	stc
	jmp iret_carry

int15_a20_disable:
	push ax
	call a20_disable
	pop ax

	xor ah, ah
	clc
	jmp iret_carry

int15_a20_enable:
	push ax
	call a20_enable
	pop ax

	xor ah, ah
	clc
	jmp iret_carry

int15_a20_get:
	call a20_get

	xor ah, ah
	clc
	jmp iret_carry

int15_a20_get_support:
	xor ah, ah
%if ((CPU == CPU_CX486) || (CPU == CPU_TI486))
	; No switch via port 0x92 support
	mov bx, 0
%else
	; Can use port 0x92
	mov bx, 0x02
%endif
	clc
	jmp iret_carry

int15_memsize:
	mov ax, EXT_RAM_SIZE
	clc
	jmp iret_carry

int15_memsize2:
	mov ax, EXT_RAM_SIZE
	mov cx, ax
	xor bx, bx
	mov dx, bx
	clc
	jmp iret_carry

int15_memsize3:
	mov ax, EXT_RAM_SIZE
	xor dx, dx
	clc
	jmp iret_carry

int15_getconfig:
	mov bx, 0xF000
	mov es, bx
	mov bx, int15_system_config
	mov ah, 0
	clc
	jmp iret_carry
	

int15_system_config:
	dw 8		; Size
	db 0xFC		; Computer type (PC)
	db 0x00		; Model
	db 0x01		; BIOS revision
	db 0xE0		; Feature information
	db 0x02		; Feature 2, we could use Micro Channel Implemented bit
			; to make himem.sys think we are PS/2
	db 0
	db 0
	db 0

