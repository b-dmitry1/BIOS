putch_calc_offset:
	push ax
	mov al, [cursor_pos + 1]
	mov ah, [chars_per_line]
	mul ah
	mov dl, [cursor_pos]
	xor dh, dh
	add ax, dx
	shl ax, 1
	mov di, ax
	pop ax
	ret

putch:
	cmp byte [video_mode], 3
	jg putch_graphic

	push ax
	push bx
	push cx
	push dx
	push di

	call putch_calc_offset

	mov ah, [chars_per_line]
putch_loop:
	cmp cx, 0
	je putch_done
	mov [es:di], al
	add di, 2
	dec cx
	jmp putch_loop
putch_done:

	pop di
	pop dx
	pop cx
	pop bx
	pop ax

	jmp int10_done

putch_graphic:
	; This require too much space so not implemented
	jmp int10_done

putcha:
	cmp byte [video_mode], 3
	jg putcha_graphic

	mov [video_attr], bl

	push ax
	push bx
	push cx
	push dx
	push di

	call putch_calc_offset

	mov ah, bl
	mov bl, [chars_per_line]
putcha_loop:
	cmp cx, 0
	je putcha_done
	mov [es:di], ax
	add di, 2
	dec cx
	jmp putcha_loop
putcha_done:

	pop di
	pop dx
	pop cx
	pop bx
	pop ax

	jmp int10_done

putcha_graphic:
	jmp int10_done

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putch_tty:
	; Send char to debug port too
	out DEBUG_UART, al

	cmp byte [video_mode], 3
	jg putch_tty_graphic

	cmp al, 13
	je cr
	cmp al, 10
	je lf
	cmp al, 8
	je backspace

	push ax
	push dx
	push di

	push ax
	mov al, [cursor_pos + 1]
	mov ah, [chars_per_line]
	mul ah
	mov dl, [cursor_pos]
	xor dh, dh
	add ax, dx
	shl ax, 1
	mov di, ax
	pop ax
	mov [es:di], al

	pop di
	pop dx
	pop ax

	inc byte [cursor_pos]
	push ax
	mov ah, [chars_per_line]
	cmp byte [cursor_pos], ah
	pop ax
	jl int10_done
	mov byte [cursor_pos], 0
	jmp lf

putch_tty_graphic:
	jmp int10_done

cr:
	mov byte [cursor_pos], 0
	jmp int10_done

lf:
	inc byte [cursor_pos + 1]
	cmp byte [cursor_pos + 1], 25
	jge int10_need_scroll
	jmp int10_done
int10_need_scroll:
	mov byte [cursor_pos + 1], 24
scroll_up:
	push ax
	push cx
	push di
	push si
	push ds
	push es
	mov ax, 0xB800
	mov ds, ax
	mov es, ax
	mov si, 160
	mov di, 0
	mov cx, 2000 - 80
	cld
	rep movsw
	mov ax, 0x700
	mov cx, 80
	rep stosw
	pop es
	pop ds
	pop si
	pop di
	pop cx
	pop ax
	jmp int10_done

backspace:
	mov al, byte [cursor_pos]
	cmp al, 0
	je int10_done

	dec byte [cursor_pos]

	push ax
	push dx
	push di

	mov al, [cursor_pos + 1]
	mov ah, [chars_per_line]
	mul ah
	mov dl, [cursor_pos]
	xor dh, dh
	add ax, dx
	shl ax, 1
	mov di, ax
	mov al, ' '
	; Should we?
	; mov [es:di], al
	pop di
	pop dx
	pop ax
	
	jmp int10_done

; int10_scroll_up
; In:
;   CH, CL = line, column of top-left corner
;   DH, DL = line, column of bottom-right corner
;   AL = number of lines or 0 if need to clear
;   BH = empty lines attributes
int10_scroll_up:
	push ax
	push cx
	push di
	push si
	push ds

	mov di, 0xB800
	mov ds, di

	cmp cl, dl
	jle int10_scroll_up_cl_ok
	xchg cl, dl
int10_scroll_up_cl_ok:

	cmp ch, dh
	jle int10_scroll_up_ch_ok
	xchg ch, dh
int10_scroll_up_ch_ok:

	cmp al, 0
	jz int10_scroll_up_fill
int10_scroll_up_not_zero:
	push cx
int10_scroll_up_scroll:
	cmp ch, dh
	jge int10_copystr_up_done_copy
	call int10_copystr_up
	inc ch
	jmp int10_scroll_up_scroll
int10_copystr_up_done_copy:
	call int10_fillstr
	pop cx
	dec al
	or al, al
	jnz int10_scroll_up_not_zero

int10_scroll_up_done:
	pop ds
	pop si
	pop di
	pop cx
	pop ax
	jmp int10_done

int10_scroll_up_fill:
	call int10_fillstr
	inc ch
	cmp ch, dh
	jle int10_scroll_up_fill

	jmp int10_scroll_up_done

; int10_scroll_down
; In:
;   CH, CL = line, column of top-left corner
;   DH, DL = line, column of bottom-right corner
;   AL = number of lines or 0 if need to clear
;   BH = empty lines attributes
int10_scroll_down:
	push ax
	push cx
	push di
	push si
	push ds

	mov di, 0xB800
	mov ds, di

	cmp cl, dl
	jle int10_scroll_down_cl_ok
	xchg cl, dl
int10_scroll_down_cl_ok:

	cmp ch, dh
	jle int10_scroll_down_ch_ok
	xchg ch, dh
int10_scroll_down_ch_ok:

	cmp al, 0
	jz int10_scroll_down_fill
int10_scroll_down_not_zero:
	push cx
int10_scroll_down_scroll:
	cmp dh, ch
	jle int10_copystr_down_done_copy
	call int10_copystr_down
	dec dh
	jmp int10_scroll_down_scroll
int10_copystr_down_done_copy:
	call int10_fillstr
	pop cx
	dec al
	or al, al
	jnz int10_scroll_down_not_zero

int10_scroll_down_done:
	pop ds
	pop si
	pop di
	pop cx
	pop ax
	jmp int10_done

int10_scroll_down_fill:
	call int10_fillstr
	inc ch
	cmp ch, dh
	jle int10_scroll_down_fill

	jmp int10_scroll_down_done

int10_copystr_up:
	push ax
	push cx
	mov al, 80
	mul ch
	xor ch, ch
	add ax, cx
	shl ax, 1
	mov di, ax
	mov si, ax
	add si, 160
	pop cx
	push cx
	cld
int10_copystr_up1:
	movsw
	inc cl
	cmp cl, dl
	jle int10_copystr_up1
	pop cx
	pop ax
	ret

int10_copystr_down:
	push ax
	push cx
	mov al, 80
	mul dh
	xor ch, ch
	add ax, cx
	shl ax, 1
	mov di, ax
	mov si, ax
	sub si, 160
	pop cx
	push cx
	cld
int10_copystr_down1:
	movsw
	inc cl
	cmp cl, dl
	jle int10_copystr_down1
	pop cx
	pop ax
	ret

int10_fillstr:
	push ax
	push cx
	mov al, 80
	mul ch
	xor ch, ch
	add ax, cx
	shl ax, 1
	mov di, ax
	pop cx
	push cx
	cld
	mov ah, bh
	xor al, al
int10_fillstr1:
	stosw
	inc cl
	cmp cl, dl
	jle int10_fillstr1
	pop cx
	pop ax
	ret
