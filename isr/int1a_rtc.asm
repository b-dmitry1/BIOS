	; RTC
int1a:
	cmp ah, 0x00
	je int1a_get_ticks
	cmp ah, 0x01
	je int1a_set_ticks

	mov ah, 0x86
	jmp iret_carry_on
	iret

int1a_get_ticks:
	push ds
	mov cx, 0x40
	mov ds, cx
	mov cx, [ticks_high]
	mov dx, [ticks_low]
	mov al, [new_day]
	xor [new_day], al
	pop ds
	iret

int1a_set_ticks:
	push ds
	push cx
	mov cx, 0x40
	mov ds, cx
	pop cx
	mov [ticks_high], cx
	mov [ticks_low], dx
	mov [new_day], byte 0
	pop ds
	iret
