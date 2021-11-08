	; Traps / faults
	; If your system working properly this will never be executed
	; Otherwise you will see red error code in the top left corner of the screen
	; and in the debug console. This may indicate RAM controller or CPU error

trap:
	mov dx, 0xB800
	mov ds, dx

	mov ah, 12
	mov di, 150
	cld
	
	mov al, 'T'
	out DEBUG_UART, al
	stosw
	mov al, 'r'
	out DEBUG_UART, al
	stosw
	mov al, 'a'
	out DEBUG_UART, al
	stosw
	mov al, 'p'
	out DEBUG_UART, al
	stosw
	mov al, bl
	out DEBUG_UART, al
	stosw

	mov al, 3
	out PORT_VMODE, al

	jmp $

int00:
	mov bl, 'Z'
	jmp trap

int01:
	iret
	mov bl, 'D'
	jmp trap

int02:
	mov bl, 'N'
	jmp trap

int03:
	mov bl, '3'
	jmp trap

int04:
	mov bl, 'O'
	jmp trap

int05:
	mov bl, 'B'
	jmp trap

int06:
	mov bl, 'I'
	jmp trap

int07:
	mov bl, 'E'
	jmp trap
