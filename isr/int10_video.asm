	; Compact video BIOS for FPGA / emulator use only
	; It WILL NOT initialize graphics controller properly
	; and some functions are not implemented to fit in 8K ROM
	;
	; If you want to use it with real hardware you should
	; use OEM bios instead

int10:
	push ds
	push es
	push si
	push di

	cld

	push dx
	mov dx, 0x40
	mov ds, dx
	pop dx

	; SVGA functions
	cmp ah, 0x4F
	je int10_svga

	; Graphics / video functions
	cmp ah, 0x1B
	je int10_get_state_info
	cmp ah, 0xFF
	je int10_test_output


	cmp ax, 0x1000
	je int10_ega_set_palette
	cmp ax, 0x1002
	je int10_ega_set_all_palette
	cmp ax, 0x1012
	je int10_vga_set_all_palette

	push dx
	mov dx, 0xB800
	mov es, dx
	pop dx

	cmp ah, 0
	je set_video_mode
	cmp ah, 0x0B
	je cga_palette
	cmp ah, 0x0F
	je get_video_mode
	cmp ah, 0x12
	je int10_ega_12
	cmp ah, 0x1A
	je int10_video_combination

	cmp ah, 1
	je set_cursor_type
	cmp ah, 2
	je set_cursor_pos
	cmp ah, 3
	je get_cursor_pos
	cmp ah, 5
	je set_video_page

	cmp ah, 0x0E
	je putch_tty

	cmp byte [video_mode], 3
	jg int10_done_no_update

	; Text mode only functions
	cmp ah, 6
	je int10_scroll_up
	cmp ah, 7
	je int10_scroll_down
	cmp ah, 8
	je readch
	cmp ah, 9
	je putcha
	cmp ah, 0x0A
	je putch

	jmp int10_done_no_update

int10_ega_12:
	cmp bl, 0x10
	je int10_ega_12_getinfo

	jmp int10_done_no_update

int10_ega_12_getinfo:
	mov bx, 3
	mov cx, 0
	jmp int10_done_no_update

int10_ega_set_palette:
	push ax
	push dx
	mov dx, 0x3DA
	in al, dx
	xor ax, ax
	mov dx, 0x3C0
	mov al, bl
	out dx, al
	mov al, bh
	out dx, al
int10_ega_set_palette_done:
	pop dx
	pop ax
	jmp int10_done_no_update

; ES:DX = palette + border color
int10_ega_set_all_palette:
	push ax
	push cx
	push dx
	push si
	mov si, dx
	mov dx, 0x3DA
	in al, dx
	xor al, al
	mov dx, 0x3C0
	xor ax, ax
	mov cx, 17
int10_ega_set_all_palette_1:
	mov al, ah
	out dx, al
	inc ah
	mov al, [es:si]
	out dx, al
	inc si
	loop int10_ega_set_all_palette_1
	pop si
	pop dx
	pop cx
	pop ax
	jmp int10_done_no_update

; bx = first reg
; cx = num regs
; es:dx = table address
int10_vga_set_all_palette:
	push bx
	push cx
	push dx
	push si
	mov si, dx
	xor ch, ch
	mov dx, 0x3C8
	mov al, bl
	out dx, al
	inc dx
int10_vga_set_all_palette_loop:
	mov al, [es:si]
	out dx, al
	inc si
	mov al, [es:si]
	out dx, al
	inc si
	mov al, [es:si]
	out dx, al
	inc si
	loop int10_vga_set_all_palette_loop
	pop si
	pop dx
	pop cx
	pop ax
	jmp int10_done_no_update

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

; int 0x10 function 0xFF
; Debug port output
int10_test_output:
	out DEBUG_UART, al
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

int10_done:
	push ax
	push bx
	push dx
	mov dx, 0x40
	mov ds, dx

	mov al, [cursor_pos + 1]
	mov ah, [chars_per_line]
	mul ah
	mov dl, [cursor_pos]
	xor dh, dh
	add ax, dx
	mov bx, ax

	mov dx, 0x3D4
	mov al, 0x0E
	out dx, al
	inc dx
	mov al, bh
	out dx, al
	dec dx
	mov al, 0x0F
	out dx, al
	inc dx
	mov al, bl
	out dx, al
	pop dx
	pop bx
	pop ax

int10_done_no_update:
	pop di
	pop si
	pop es
	pop ds
	iret

readch:
	cmp byte [video_mode], 3
	jg readch_graphic
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
	mov ax, [es:di]
	pop di
	pop dx
	mov bh, [video_page]
	jmp int10_done_no_update

readch_graphic:
	jmp int10_done_no_update

	; Video mode init tables
	; Some values may be incorrect for a real graphics controller
	; but ok for games and MS Windows in FPGA / emulator
def_crt:
	db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	db 0x00, 0x00, 0x06, 0x07, 0x00, 0x00, 0x00, 0x00
def_ac:
	db 0x00, 0x02, 0x08, 0x0A, 0x20, 0x22, 0x28, 0x2A
	db 0x00, 0x03, 0x0C, 0x0F, 0x30, 0x33, 0x3C, 0x3F
	db 0x0c, 0x00, 0x0f, 0x08, 0x00
def_sq:
	db 0x00
	db 0x01
	db 0x0f ; plane mask
	db 0x00
	db 0x0A ; linear mode by default
def_gc:
	db 0x0F ; fill color
	db 0x00 ; fill mask
	db 0x00 ; color compare
	db 0x00 ; rotate(2:0), logic op(4:3)
	db 0x00 ; read map
	db 0x10 ; writemode(1:0), readmode(3)
	db 0x0e ;
	db 0x00 ; color don't care
	db 0xff ; write mask

; write_regs
; Writes default values to a graphic registers
; In:
;   DX = index register port
;   CS:SI = table address
;   CX = number of bytes
write_regs:
	mov al, 0
write_regs_loop:
	out dx, al
	inc dx
	mov ah, al
	mov al, [cs:si]
	out dx, al
	mov al, ah
	inc al
	dec dx
	inc si
	loop write_regs_loop
	ret

; write_regs_ac
; Writes default values to an attribute control graphic registers
; In:
;   DX = port
;   CS:SI = table address
;   CX = number of bytes
write_regs_ac:
	mov al, 0
write_regs_ac_loop:
	out dx, al
	mov ah, al
	mov al, [cs:si]
	out dx, al
	mov al, ah
	inc al
	inc si
	loop write_regs_ac_loop
	ret

set_video_mode:
	and al, 0x7F

	mov byte [video_attr], 7

	; Write default values
	push ax
	mov dx, 0x3DA
	in al, dx	; Switch port 0x3C0 to address mode
	xor al, al
	mov dx, 0x3c0
	mov si, def_ac
	mov cx, 21
	;call write_regs_ac
	mov dx, 0x3d4
	mov si, abRegsGfx
	mov cx, 16
	call write_regs
	mov dx, 0x3c4
	mov si, def_sq
	mov cx, 5
	call write_regs
	mov dx, 0x3ce
	mov si, def_gc
	mov cx, 9
	call write_regs
	pop ax

	mov [chars_per_line], word 40
	mov [video_rows], byte 24
	mov [video_regen_size], word 0x4000

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


	cmp al, 0
	je set_video_mode_0_1
	cmp al, 1
	je set_video_mode_0_1
	cmp al, 2
	je set_video_mode_2_3
	cmp al, 3
	je set_video_mode_2_3
	cmp al, 4
	je set_video_mode_4_5_6
	cmp al, 5
	je set_video_mode_4_5_6
	cmp al, 6
	je set_video_mode_4_5_6
	cmp al, 7
	je set_video_mode_ok
	cmp al, 0x09
	je set_video_mode_ok_A000
	cmp al, 0x0D
	je set_video_mode_planar_A000
	cmp al, 0x10
	je set_video_mode_planar_A000
	cmp al, 0x11
	je set_video_mode_planar_A000
	cmp al, 0x12
	je set_video_mode_planar_A000
	cmp al, 0x13
	je set_video_mode_ok_A000

	jmp int10_done_no_update

set_video_mode_0_1:
	mov [video_regen_size], word 0x800
	jmp set_video_mode_ok

set_video_mode_2_3:
	mov [chars_per_line], word 80
	mov [video_regen_size], word 0x1000
	jmp set_video_mode_ok

set_video_mode_4_5_6:
	jmp set_video_mode_ok_cga



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

set_video_mode_planar_A000:
	push ax
	push dx
	mov al, 4
	mov dx, 0x3c4
	out dx, al
	inc dx
	mov al, 2
	out dx, al
	pop dx
	pop ax
set_video_mode_ok_A000:
	push ax
	push cx
	push di

	mov [video_mode], al
	out PORT_VMODE, al

	push dx
	mov dx, 0x3c6
	mov al, 0xFF
	out dx, al
	mov dx, 0x3c8
	xor al, al
	out dx, al
	inc dx
	mov cx, 16
defaultpalette1:
	push cx
	mov cx, 48
	mov di, colors
defaultpalette:
	mov al, [cs:di]
	inc di
	out dx, al
	loop defaultpalette
	pop cx
	loop defaultpalette1
	pop dx

	mov ax, 0xA000
	mov es, ax
	xor di, di
	mov cx, 32768
	xor ax, ax
	rep stosw

	pop di
	pop cx
	pop ax

	jmp int10_done

set_video_mode_ok:
	push ax
	push cx
	push di

	mov [video_mode], al
	out PORT_VMODE, al

	xor di, di
	mov cx, 16384
	mov ax, 0x700
	rep stosw

	pop di
	pop cx
	pop ax

	jmp int10_done

set_video_mode_ok_cga:
	push ax
	push cx
	push di

	mov [video_mode], al
	out PORT_VMODE, al

	xor di, di
	mov cx, 16384
	mov ax, 0x00
	rep stosw

	pop di
	pop cx
	pop ax

	jmp int10_done
	                                                           	
get_video_mode:
	mov ah, [chars_per_line]
	mov al, [video_mode]
	and al, 0x7F
	mov bh, [video_page]
	jmp int10_done

set_cursor_type:
	mov [cursor_lines], cx
	jmp int10_done_no_update

set_cursor_pos:
	mov [video_page], bh		; Page
	mov [cursor_pos], dl		; Cursor pos
	mov [cursor_pos + 1], dh
	jmp int10_done

get_cursor_pos:
	mov bh, [video_page]
	mov cl, [cursor_lines]
	mov ch, [cursor_lines + 1]
	mov dl, [cursor_pos]
	mov dh, [cursor_pos + 1]
	jmp int10_done_no_update

set_video_page:
	mov [video_page], al
	jmp int10_done

cga_palette:
	push ax
	push bx
	push dx
	cmp bh, 1
	jne cga_palette_done

	and bl, 0x01
	shl bl, 1
	shl bl, 1
	shl bl, 1
	shl bl, 1
	shl bl, 1
	mov al, bl
	mov dx, 0x3D9
	out dx, al

cga_palette_done:
	pop dx
	pop bx
	pop ax
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

int10_video_combination:
	cmp al, 0
	jne int10_video_combination_done
	
	; AL = 0: Get Video Combination	
	mov bl, 0x08	; VGA analog color display
	mov bh, 0	; No inactive display
	mov al, 0x1a	; Status "OK"
	
int10_video_combination_done:
	jmp int10_done_no_update


; int10_get_state_info
; In:
;   ES, DI = address of buffer for VGADynamicState
;   BX = 0
; Out:
;   AL = 0x1B
int10_get_state_info:
	push ax
	push cx
	push di
	push si
	push ds

	mov ax, 0x40
	mov ds, ax

	; Clear 64 bytes of data
	push di
	mov cx, 32
	xor ax, ax
	rep stosw
	pop di

	; 0 - address 
	mov word [es:di], video_static_table
	mov word [es:di + 2], 0xf000

	; Copy 30 bytes from bios data area
	push di
	add di, 4
	mov si, video_mode
	mov cx, 30
	rep movsb
	pop di

	mov al, [video_rows]
	mov byte [es:di + 34], al
	mov word [es:di + 35], 8	; Font 8 dots
	mov byte [es:di + 37], 0x08	; Display combination code (VGA analog color)
	;mov byte [es:di + 38], 0x00	; Display combination code inactive display code
	mov word [es:di + 39], 256	; Number of colors in active video mode

	mov byte [es:di + 41], 8	; Number of pages in active video mode

	mov byte [es:di + 42], 0	; Number of scan lines: 0 = 200, 1 = 350, 2 = 400, 3 = 480
	mov byte [es:di + 45], 0x01	; Bit 0 - all modes on all active displays active, 1 - grayscale, 2 - mono,
					; 3 - no default palette, 4 - cursor emulation enabled,
					; 5 - cursor blinking
	;mov byte [es:di + 46], 0x00	; Reserved
	;mov byte [es:di + 47], 0x00	; Reserved
	;mov byte [es:di + 48], 0x00	; Reserved
	mov byte [es:di + 49], 0x03	; Video RAM: 3 - 256KB
	mov byte [es:di + 50], 0x1C	; Text font override, graphic font override, palette override
	
	pop ds
	pop si
	pop di
	pop cx
	pop ax
	mov al, 0x1b
	jmp int10_done_no_update

svga_modes:
	dw 0x101, 0xFFFF

svga_oem_str:
	db "svga?", 0

svga_info:
	db "VESA"
	; Version
	dw 1
	; OEM string
	dw svga_oem_str
	dw 0xF000
	; Capabilities: 6 bit DAC (0), VGA (1)
	dd 0
	; Video modes list
	dw svga_modes
	dw 0xF000
	; Number of 64KB blocks
	dw 8
	; VBE2 revision
	dw 0
	; Manufacturer name
	dw svga_oem_str
	dw 0xF000
	; Device name
	dw svga_oem_str
	dw 0xF000
	; Version name
	dw svga_oem_str
	dw 0xF000
svga_info_end:

; ES:DI = buffer
int10_svga_query_support:
	push cx
	push di
	xor ax, ax
	mov cx, 128
	rep stosw
	pop di
	push di
	push si
	mov si, svga_info
	mov cx, svga_info_end - svga_info + 1
int10_svga_query_support_copy:
	mov al, [cs:si]
	mov [es:di], al
	inc si
	inc di
	loop int10_svga_query_support_copy
	pop si
	pop di
	pop cx

	mov ax, 0x004F
	jmp int10_done_no_update

int10_svga:
	cmp ax, 0x4F05
	je int10_svga_select_window
	cmp ax, 0x4F00
	je int10_svga_query_support
	cmp ax, 0x4F01
	je int10_svga_get_mode_info
	cmp ax, 0x4F02
	je int10_svga_set_mode

	jmp int10_done_no_update

int10_svga_get_mode_info:
	push di
	push cx
	xor ax, ax
	mov cx, 128
	rep stosw
	pop cx
	pop di

	mov al, 'i'
	out DEBUG_UART, al

	; Set 640x480x256 video mode here because some games
	; for some reason don't use 0x4F02 function
	;mov al, 0x14
	;out PORT_VMODE, al

	; Mode supported (0), TTY not supported (2), color (3)
	; Graphic (4), VGA-compatible (5), windowed mode only (6-7)
	mov [es:di + 0x00], word 0x1b
	; Window A movable, read allowed, write allowed
	mov [es:di + 0x02], byte 0x1
	; Window B movable, read allowed, write allowed
	mov [es:di + 0x02], byte 0x1
	; Window move size in KB
	mov [es:di + 0x04], word 64
	; Window size in KB
	mov [es:di + 0x06], word 64
	; Segment A
	mov [es:di + 0x08], word 0xA000
	; Segment B
	mov [es:di + 0x08], word 0xA000
	; Select window function pointer
	mov [es:di + 0x0C], word int10_svga_select_window_func
	mov [es:di + 0x0E], word 0xF000
	; Bytes per line
	mov [es:di + 0x10], word 640
	; Resolution
	mov [es:di + 0x12], word 640
	mov [es:di + 0x14], word 480
	; Char size
	mov [es:di + 0x16], byte 8
	mov [es:di + 0x17], byte 16
	; Number of bit planes
	mov [es:di + 0x18], byte 1
	; BPP
	mov [es:di + 0x19], byte 8
	; Memory banks
	mov [es:di + 0x1A], byte 8
	; Memory model: packed pixels
	mov [es:di + 0x1B], byte 4
	; KB in memory bank
	mov [es:di + 0x1C], byte 64
	; Number of pages minus 1
	mov [es:di + 0x1D], byte 4
	; Reserved
	mov [es:di + 0x1D], byte 1

	push dx
	mov dx, 0x3D4
	mov al, 0x6A
	out dx, al
	inc dx
	xor al, al
	out dx, al
	pop dx

	mov ax, 0x4F

	jmp int10_done_no_update

int10_svga_set_mode:
	mov al, 0x14
	out PORT_VMODE, al
	mov ax, 0x4F
	jmp int10_done_no_update

int10_svga_select_window_func:
	push dx
	push ax
	mov al, dl
	mov dx, 0x3DC
	out dx, al
	pop ax
	pop dx
	retf

int10_svga_select_window:
	; SVGA games will use this function frequently
	; to select 64K video RAM window on 0xA0000
	mov al, dl
	mov dx, 0x3DC
	out dx, al
	mov ax, 0x4F
	mov dx, 0
	jmp int10_done_no_update
