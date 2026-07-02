i8042_init:
	call i8042_wait
	mov al, 0x60    ; i8042: write next byte to Command Byte
	out 0x64, al
	call i8042_wait
	mov al, 0x41    ; Bit 6: select scancode set 1, bit 0: enable IRQ1
	out 0x60, al
	ret

i8042_wait:
	push cx
	xor cx, cx      ; Set timeout for a buggy hardware
i8042_wait_loop:
	in al, 0x64
	test al, 0x02   ; Bit 1: Input Buffer Full
	jz i8042_wait_done
	loop i8042_wait_loop
i8042_wait_done:
	pop cx
	ret
