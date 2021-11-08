	; COM1 IRQ4 stub

int0c:
	push ax
	push dx
	mov dx, 0x3F8
	in al, dx
	mov al, 0x20
	out 0x20, al
	pop dx
	pop ax
	iret
