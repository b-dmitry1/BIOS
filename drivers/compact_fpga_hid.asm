%define KEY_FIRST_REPEAT		9
%define KEY_NEXT_REPEAT			2

%define HID_CTRL			1
%define HID_SHIFT			2
%define HID_ALT				4
%define HID_WIN				8
%define HID_RCTRL			16
%define HID_RSHIFT			32
%define HID_RALT			64

%define ENABLE_WHEEL_SCROLL

	; USB HID 20 ms timer
intUSB:
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push bp
	push ds

	mov ax, 0x40
	mov ds, ax

	cli
	mov ax, 0x6980
	out USB1, ax
	mov ax, 0x5881
	out USB1, ax

	in ax, USB1
	and ax, 0xFFF8
	cmp ax, 0xB500
	jne hid_keyb_1
	mov ax, 0x5A80
hid_keyb_1:
	cmp ax, 0xC380
	je hid_keyb_got
	cmp ax, 0x4B80
	je hid_keyb_got
	cmp ax, 0xF080
	je hid_keyb_fail
	cmp ax, 0x5A80
	jne hid_keyb_stall
	mov byte [hid_keyb_errors], 0
	jmp intUSB_done_1
hid_keyb_stall:
	inc byte [hid_keyb_errors]
	cmp byte [hid_keyb_errors], 255
	je hid_keyb_real_stall
	jmp intUSB_done_1
hid_keyb_real_stall:
	mov byte [hid_keyb_errors], 0
;	call usb1_init
	jmp intUSB_done_1
hid_keyb_fail:
	jmp intUSB_done_1
hid_keyb_got:
	in ax, USB1
	mov [hid_report], ax
	in ax, USB1
	mov [hid_report + 2], ax
	in ax, USB1
	mov [hid_report + 4], ax

	mov ax, 0xD280
	out USB1, ax

	; Report received:
	; shift, 0, key 1, key 2, key 3

	; Make the same codes for left/right Ctrl, Alt, Shift
	mov al, [hid_report]
	test al, HID_RCTRL
	jz no_rctrl
	or al, HID_CTRL
no_rctrl:
	test al, HID_RALT
	jz no_ralt
	or al, HID_ALT
no_ralt:
	test al, HID_RSHIFT
	jz no_rshift
	or al, HID_SHIFT
no_rshift:
	mov [hid_report], al

	; Check if Shift state changed
	xor al, [hid_keys]
	test al, HID_SHIFT
	jz no_shift
	; Pressed or released Shift
	mov al, [hid_report]
	test al, HID_SHIFT
	jz shift_released
	; Pressed Shift
	or byte [hid_keys], HID_SHIFT
	mov al, 0x2A
	out KEYB_FIFO, al
	jmp intUSB_done_1
shift_released:
	; Released Shift
	and byte [hid_keys], ~HID_SHIFT
	mov al, 0xAA
	out KEYB_FIFO, al
	jmp intUSB_done_1
no_shift:

	mov al, [hid_report]
	; Check if Ctrl state changed
	xor al, [hid_keys]
	test al, HID_CTRL
	jz no_ctrl
	; Pressed or released Ctrl
	mov al, [hid_report]
	test al, HID_CTRL
	jz ctrl_released
	; Pressed Ctrl
	or byte [hid_keys], HID_CTRL
	mov al, 0x1D
	out KEYB_FIFO, al
	jmp intUSB_done_1
ctrl_released:
	; Released Ctrl
	and byte [hid_keys], ~HID_CTRL
	mov al, 0x9D
	out KEYB_FIFO, al
	jmp intUSB_done_1
no_ctrl:

	; Convert key codes
	mov al, [hid_report + 2]
	xor ah, ah
	mov si, ax
	add si, hid_keyb_table
	mov al, [cs:si]
	mov [hid_report + 2], al

	mov al, [hid_report + 3]
	xor ah, ah
	mov si, ax
	add si, hid_keyb_table
	mov al, [cs:si]
	mov [hid_report + 3], al

	mov al, [hid_report + 4]
	xor ah, ah
	mov si, ax
	add si, hid_keyb_table
	mov al, [cs:si]
	mov [hid_report + 4], al

	
	; Check if key released
	; We need to find all the codes in a special table
	; If the code is not found then key released
	mov dx, 3
	mov si, hid_keys + 1
check_released_1:
	; Do not check released keys
	mov al, [si]
	or al, al
	jz check_released_found
	mov cx, 3
	mov di, hid_report + 2
check_released_2:
	cmp al, [di]
	je check_released_found
	inc di
	loop check_released_2
	; Not found in report
	mov al, [si]
	; Send the "released" code
	or al, 0x80
	out KEYB_FIFO, al
	; And remember that a key is not pressed
	mov al, [si]
	mov byte [si], 0
	cmp al, [hid_lastkey]
	jne intUSB_done_1
	mov byte [hid_lastkey], 0
	jmp intUSB_done_1
check_released_found:
	inc si
	sub dx, 1
	jnz check_released_1
check_released_done:

	; Check if keys pressed
	mov dx, 3
	mov si, hid_report + 2
check_pressed_1:
	; Check until first 0
	mov al, [si]
	or al, al
	jz check_pressed_done
	mov cx, 3
	mov di, hid_keys + 1
check_pressed_2:
	cmp al, [di]
	je check_pressed_found
	inc di
	loop check_pressed_2
	; Not found in report
	mov al, [si]
	; Send "pressed" code
	out KEYB_FIFO, al

	; Save "pressed" state
	mov cx, 3
	mov di, hid_keys + 1
check_pressed_save:
	cmp byte [di], 0
	jz check_pressed_save_1
	inc di
	loop check_pressed_save
	; No room in the buffer - something goes wrong
	jmp intUSB_done_1
check_pressed_save_1:
	mov [di], al
	mov [hid_lastkey], al
	mov byte [hid_repeat], KEY_FIRST_REPEAT
	jmp intUSB_done_1
check_pressed_found:
	inc si
	sub dx, 1
	jnz check_pressed_1
check_pressed_done:
	
intUSB_done_1:
	; Check if we need auto-repeat
	mov al, [hid_lastkey]
	or al, al
	jz intUSB_done_1_1

	dec byte [hid_repeat]
	cmp byte [hid_repeat], 0
	jnz intUSB_done_1_1
	mov byte [hid_repeat], KEY_NEXT_REPEAT
	mov al, [hid_lastkey]
	out KEYB_FIFO, al

intUSB_done_1_1:
%if FPGA_USB_NO_MOUSE == 1
	jmp intUSB_done_2
%else

	; Get mouse report
	mov ax, 0x6980
	out USB2, ax
	mov ax, 0x5881
	out USB2, ax

	in ax, USB2
	cmp ax, 0xC380
	je hid_mouse_got
	cmp ax, 0x4B80
	je hid_mouse_got
;	cmp ax, 0x1E80
;	je hid_mouse_stall
	jmp intUSB_done_2
hid_mouse_stall:
;	call usb2_init
	jmp intUSB_done_2
hid_mouse_got:
	in ax, USB2
	mov bx, ax
	in ax, USB2
	mov cx, ax
	in ax, USB2
	mov dx, ax

	mov ax, 0xD280
	out USB2, ax


	; TODO: Should analyse device descriptors to decode report instead of use hard-coded value places

	; BL - buttons
	; BH - X
	; CL - Y
	; DH - wheel

	xchg ch, cl

%ifdef ENABLE_WHEEL_SCROLL
	or dh, dh
	jz wheel_done
	test dh, 0x80
	jnz wheel_neg
	mov al, 0x48
	out KEYB_FIFO, al
	mov al, 0xC8
	out KEYB_FIFO, al
	jmp wheel_done
wheel_neg:
	mov al, 0x50
	out KEYB_FIFO, al
	mov al, 0xD0
	out KEYB_FIFO, al
wheel_done:
%endif

	mov al, 0x40
	test bl, 1
	jz mouse_not_button_1
	or al, 0x20
mouse_not_button_1:
	test bl, 2
	jz mouse_not_button_2
	or al, 0x10
mouse_not_button_2:

	test bh, 0x80
	jz mouse_x_sign_done
	or al, 0x03
mouse_x_sign_done:
	test cl, 0x80
	jz mouse_y_sign_done
	or al, 0x0C
mouse_y_sign_done:
	mov bl, al

	mov dx, 0x3F8

	mov al, cl
	;shr al, 1
	shr al, 1
	and al, 0x3F
	out dx, al

	mov al, bh
	;shr al, 1
	shr al, 1
	and al, 0x3F
	out dx, al

	mov al, bl
	out dx, al

%endif

intUSB_done_2:

	pop ds
	pop bp
	pop di
	pop si
	pop dx
	pop cx
	pop bx

	mov al, 0x20
	out 0x20, al

	pop ax

	iret

hid_keyb_table:
	db 0, 0, 0, 0, 0x1E, 0x30, 0x2E, 0x20, 0x12, 0x21, 0x22, 0x23, 0x17, 0x24, 0x25, 0x26
	db 0x32, 0x31, 0x18, 0x19, 0x10, 0x13, 0x1F, 0x14, 0x16, 0x2F, 0x11, 0x2D, 0x15, 0x2C, 0x02, 0x03
	db 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x1C, 0x01, 0x0E, 0x0F, 0x39, 0x0C, 0x0D, 0x1A
	db 0x1B, 0x2B, 0, 0x27, 0x28, 0x29, 0x33, 0x34, 0x35, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F, 0x40
	db 0x41, 0x42, 0x43, 0x44, 0x57, 0x58, 0, 0x46, 0, 0x52, 0x47, 0x49, 0x53, 0x4F, 0x51, 0x4D
	db 0x4B, 0x50, 0x48, 0x45, 0x35, 0x37, 0x4A, 0x4E, 0x1C, 0x4F, 0x50, 0x51, 0x4B, 0x4C, 0x4D, 0x47
	db 0x48, 0x49, 0x52, 0x53, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

