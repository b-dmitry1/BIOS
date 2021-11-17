
%include "data\video_init.asm"

; TODO: Add Bochs's specific values to replace their own VGA BIOS

; write_regs
; Writes default values to a graphic registers
; In:
;   DX = index register port
;   CS:SI = table address
;   CX = number of bytes
;   AL = start reg
write_regs:
	mov ah, [cs:si]
	out dx, ax
	inc al
	add si, VIDEO_TABLE_COLS
	loop write_regs
	ret

; calc_video_table_column
; Calculates the column number of init tables
; In:
;   AL = video mode
; Out:
;   BX = table column
calc_video_table_column:
	xor bh, bh
	mov bl, al
	cmp al, 6
	jle calc_video_table_column_done
	mov bl, 7
	cmp al, 0x0D
	je calc_video_table_column_done
	inc bl
	cmp al, 0x0E
	je calc_video_table_column_done
	inc bl
	cmp al, 0x10
	je calc_video_table_column_done
	inc bl
	cmp al, 0x12
	je calc_video_table_column_done
	inc bl	

calc_video_table_column_done:
	ret

; write_regs
; Writes default values from mode tables
; In:
;   BX = init table column
init_vga_regs:
	; Misc output
	mov dx, 0x3c2
	mov al, 0x63
	out dx, al

	; Sequence controller
	mov si, bx
	add si, seq_table
	mov dx, 0x3c4
	mov cx, 5
	xor al, al
	call write_regs

	; CRT registers
	mov si, bx
	add si, crt_table
	mov dx, 0x3d4
	mov cx, 25
	xor al, al
	call write_regs
	
	; Graphic controller
	mov si, bx
	add si, gc_table
	mov dx, 0x3ce
	mov cx, 9
	xor al, al
	call write_regs

	; Attribute controller	
	; Switch port 0x3C0 to address mode
	mov dx, 0x3DA
	in al, dx

	mov si, bx
	add si, ac_table
	mov cx, 21
	mov dx, 0x3c0
	xor al, al
init_vga_regs_ac:
	; Index
	out dx, al
	mov ah, [cs:si]
	add si, VIDEO_TABLE_COLS
	xchg al, ah
	; Value
	out dx, al
	xchg al, ah
	inc al
	loop init_vga_regs_ac

	; Enable video, 80x25
	mov dx, 0x3d8
	mov al, 9
	out dx, al
	
	; CGA palette
	mov dx, 0x3d9
	mov al, 7
	out dx, al

	; Switch port 0x3C0 to address mode
	mov dx, 0x3DA
	in al, dx

	; Lock 16-color palette
	mov dx, 0x3c0
	mov al, 0x20
	out dx, al

	; Enable blink, video, hi-res
	mov dx, 0x3b8
	mov al, 0x29
	out dx, al

	ret

colors:
	db 0, 0, 0
	db 0, 0, 32
	db 0, 32, 0
	db 0, 48, 32
	db 32, 0, 0
	db 32, 0, 32
	db 32, 32, 0
	db 48, 48, 48
	db 32, 32, 32
	db 0, 0, 63
	db 0, 63, 0
	db 0, 63, 63
	db 63, 0, 0
	db 63, 0, 63
	db 63, 63, 0
	db 63, 63, 63

set_video_mode:
	push ax
	push bx
	push cx
	push dx

	mov [video_mode], al

	test al, 0x80
	jnz set_video_mode_done_clear_fb

	; Clear framebuffer
	mov ax, 0xA000
	mov es, ax
	xor di, di
	mov cx, 32768
	xor ax, ax
	rep stosw
	mov ax, 0xB000
	mov es, ax
	xor di, di
	mov cx, 32768
	mov ax, 0x720
	cmp byte [video_mode], 3
	jle fill_7
	xor ax, ax
fill_7:	
	rep stosw

	mov al, [video_mode]
set_video_mode_done_clear_fb:
	and al, 0x7F

	; FPGA or emulator video mode register
	out PORT_VMODE, al

	call calc_video_table_column

	; Configure graphics controller
	call init_vga_regs

	; Write default BIOS values
	mov byte [video_attr], 7
	mov [video_page], byte 0
	mov [cursor_pos], word 0
	mov [cursor_pos + 2], word 0
	mov [cursor_pos + 4], word 0
	mov [cursor_pos + 6], word 0
	mov [cursor_pos + 8], word 0
	mov [cursor_pos + 10], word 0
	mov [cursor_pos + 12], word 0
	mov [cursor_pos + 14], word 0
	mov [cursor_lines], byte 6
	mov [cursor_lines + 1], byte 7
	mov [video_rows], byte 24
	mov [video_regen_size], word 0x4000

	; Get Chars per line
	mov si, bx
	add si, video_cols
	mov al, [cs:si]
	xor ah, ah
	mov [chars_per_line], ax

	; Set default palette
	mov dx, 0x3c6
	mov al, 0xFF
	out dx, al
	mov dx, 0x3c8
	xor al, al
	out dx, al
	inc dx
	mov cx, 48
	mov si, colors
defaultpalette:
	mov al, [cs:si]
	inc si
	out dx, al
	loop defaultpalette

	pop dx
	pop cx
	pop bx
	pop ax	

	jmp int10_done
