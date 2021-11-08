	; Communication / RS232 functions

int14:
	cmp ah, 0
	je int14_init
;	cmp ah, 1
;	je int14_write_char
;	cmp ah, 2
;	je int14_read_char
;	cmp ah, 3
;	je int14_get_status

	iret

int14_init:
	push dx
	mov al, 0x00
	mov dx, 0x3F8
	out dx, al
	mov al, 0x00
	mov dx, 0x3F9
	out dx, al
	mov dx, 0x3FA
	out dx, al
	mov dx, 0x3FE
	out dx, al
	mov dx, 0x3FF
	out dx, al
	mov al, 0xA3
	mov dx, 0x3FB
	out dx, al
	mov al, 0x03
	mov dx, 0x3FC
	out dx, al
	mov al, 0x00
	mov dx, 0x3FD
	out dx, al
	pop dx
	iret

