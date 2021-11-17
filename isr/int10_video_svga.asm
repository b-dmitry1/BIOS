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
