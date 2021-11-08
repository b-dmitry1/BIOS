; Shift / special key status codes
%define KEYB_FLAGS_INS_DN	0x8000
%define KEYB_FLAGS_CAPS_DN	0x4000
%define KEYB_FLAGS_NUM_DN	0x2000
%define KEYB_FLAGS_SCRL_DN	0x1000
%define KEYB_FLAGS_PAUSE_DN	0x0800
%define KEYB_FLAGS_SYSRQ_DN	0x0400
%define KEYB_FLAGS_LEFT_ALT_DN	0x0200
%define KEYB_FLAGS_RIGHT_ALT_DN	0x0100
%define KEYB_FLAGS_INS		0x0080
%define KEYB_FLAGS_CAPS		0x0040
%define KEYB_FLAGS_NUM		0x0020
%define KEYB_FLAGS_SCRL		0x0010
%define KEYB_FLAGS_ALT		0x0008
%define KEYB_FLAGS_CTRL		0x0004
%define KEYB_FLAGS_LEFT_SHIFT	0x0002
%define KEYB_FLAGS_RIGHT_SHIFT	0x0001

	; Keyboard

int09:
	push ax
	push si
	push ds

	mov ax, 0x40
	mov ds, ax

	; Get XT char code
	; FPGA keyboard controller must convert PS/2 or USB code to XT code
	in al, 0x60
	mov ah, al

	; Tell keyboard controller that we are ready for the next one
	in al, 0x61
	or al, 0x80
	out 0x61, al
	and al, 0x7F
	out 0x61, al

	mov al, ah

	; Extanded code
	cmp ah, 0xE0
	je int09_done

	; Test for shift keys
	cmp ah, 0x2A
	je int09_lshift
	cmp ah, 0x36
	je int09_rshift
	cmp ah, 0x1D
	je int09_ctrl
	cmp ah, 0x38
	je int09_alt
	cmp ah, 0xAA
	je int09_lshift_up
	cmp ah, 0xB6
	je int09_rshift_up
	cmp ah, 0x9D
	je int09_ctrl_up
	cmp ah, 0xB8
	je int09_alt_up

	; Test for release
	test al, 0x80
	jnz int09_done

	mov si, ax
	and si, 0x7F

	; Convert to ASCII
	mov al, [keyboard_flags]
	test al, 0x03
	jnz int09_use_shift

	; TODO: add tables for CTRL and ALT
	
	add si, ascii_normal
do_xlat:
	mov al, [cs:si]

	jmp int09_ok

int09_use_shift:
	add si, ascii_shift
	jmp do_xlat

ascii_normal:
	db 0, 27, "1234567890-=", 8, 9
	db "qwertyuiop[]", 13, 0, "as"
	db "dfghjkl;'~", 0, "\zxcv"
	db "bnm,./", 0, "*", 0, " ", 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

ascii_shift:
	db 0, 27, "!@#$%^&*()_+", 8, 9
	db "QWERTYUIOP{}", 13, 0, "AS"
	db "DFGHJKL:", 34, "`", 0, "|ZXCV"
	db "BNM<>?", 0, "*", 0, " ", 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	
int09_ok:
	; Write char to keyboard buffer
	mov si, [keybuf_tail]
	mov [si + 0x1E], ax
	inc si
	inc si
	and si, 0x1E
	mov [keybuf_tail], si

	cmp [keybuf_head], si
	jne int09_done

	; Buffer overflow -> remove 1 char
	mov si, [keybuf_head]
	inc si
	inc si
	and si, 0x1E
	mov [keybuf_head], si

	; TODO: add beep here

int09_done:
	; Update keyboard flags
	mov al, [keyboard_flags]
	and al, 0x0F
	xor ah, ah
	mov [keyboard_flags], ax

	; End of interrupt
	mov al, 0x20
	out 0x20, al

	pop ds
	pop si
	pop ax
	iret

	; Shift keys pressed / released
int09_lshift:
	mov si, [keyboard_flags]
	or si, 0x0001
	mov [keyboard_flags], si
	jmp int09_done
int09_rshift:
	mov si, [keyboard_flags]
	or si, 0x0002
	mov [keyboard_flags], si
	jmp int09_done
int09_ctrl:
	mov si, [keyboard_flags]
	or si, 0x0004
	mov [keyboard_flags], si
	jmp int09_done
int09_alt:
	mov si, [keyboard_flags]
	or si, 0x0008
	mov [keyboard_flags], si
	jmp int09_done
int09_lshift_up:
	mov si, [keyboard_flags]
	and si, 0xFFFE
	mov [keyboard_flags], si
	jmp int09_done
int09_rshift_up:
	mov si, [keyboard_flags]
	and si, 0xFFFD
	mov [keyboard_flags], si
	jmp int09_done
int09_ctrl_up:
	mov si, [keyboard_flags]
	and si, 0xFFFB
	mov [keyboard_flags], si
	jmp int09_done
int09_alt_up:
	mov si, [keyboard_flags]
	and si, 0xFFF7
	mov [keyboard_flags], si
	jmp int09_done
