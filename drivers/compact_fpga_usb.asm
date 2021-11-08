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

%define INIT_PACKET_DELAY		5

%include "drivers\usb.asm"

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; USB 1
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
usb1_init:
	; На входе прерывания должны быть запрещены
	; Инициализация USB1:
	;  1. Отправить команду set_address устройству с адресом 0
	;  2. Повторять 200 раз или пока не получим ответ ACK
	;  3. Отправить команду чтения из конечной точки 0 устройству с адресом 0
	;  4. Повторять 200 раз или пока не получим ответ ACK
	;  5. Отправить команду set_configuration устройству с адресом 1
	;  6. Повторять 200 раз или пока не получим ответ ACK
	;  7. Если не получен ответ ACK, то выдать сообщение об ошибке и не продолжать
	;  8. Отправить команду чтения из конечной точки 0 устройству с адресом 1
	;  9. Повторять 200 раз или пока не получим ответ ACK
	; 10. Если не получен ответ ACK, то выдать сообщение об ошибке и не продолжать
	; После этого устройство будет выдавать отчет или NAK, если нет данных
	mov al, 0x40
	out 0xBD, al
	xor al, al
	out 0xBD, al
	mov cx, 65535
	loop $
	mov dx, 20
usb1_set_address_1:
	mov si, usb_setup
	call usb1_send
	mov si, usb_set_address
	call usb1_send
	in ax, USB1
	cmp ax, 0xD280
	je usb1_set_address_1_done
	mov cx, INIT_PACKET_DELAY
	loop $
	sub dx, 1
	jnz usb1_set_address_1
usb1_set_address_1_done:
	mov al, '.'
	call putchv
	mov dx, 20
usb1_set_address_2:
	mov si, usb_read0
	call usb1_send
	in ax, USB1
	push ax
	in ax, USB1
	mov ax, 0xD280
	out USB1, ax
	pop ax
	cmp ax, 0x4B80
	je usb1_set_address_done
	mov cx, INIT_PACKET_DELAY
	loop $
	sub dx, 1
	jnz usb1_set_address_2
usb1_set_address_done:
	mov al, '.'
	call putchv
	mov cx, 65535
	loop $
	mov dx, 20
usb1_set_conf_1:
	mov si, usb_setup1
	call usb1_send
	mov si, usb_set_configuration
	call usb1_send
	in ax, USB1
	cmp ax, 0xD280
	je usb1_set_conf_1_done
	mov cx, INIT_PACKET_DELAY
	loop $
	sub dx, 1
	jnz usb1_set_conf_1
;	mov al, 1
;	ret
usb1_set_conf_1_done:
	mov al, '.'
	call putchv
	mov dx, 50
usb1_set_conf_2:
	mov si, usb_read10
	call usb1_send
	in ax, USB1
	push ax
	in ax, USB1
	mov si, usb_ack
	call usb1_send
	pop ax
	cmp ax, 0x4B80
	je usb1_set_conf_done
	mov cx, INIT_PACKET_DELAY
	loop $
	sub dx, 1
	jnz usb1_set_conf_2
	jmp usb1_init
	mov al, 1
	ret
usb1_set_conf_done:
	mov al, 0
	ret


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; USB 2
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
usb2_init:
	; На входе прерывания должны быть запрещены
	mov al, 0x80
	out 0xBD, al
	mov cx, 65
	loop $
	xor al, al
	out 0xBD, al
	mov cx, 6553
	loop $
	mov dx, 20
usb2_set_address_1:
	mov si, usb_setup
	call usb2_send
	mov si, usb_set_address
	call usb2_send
	in ax, USB2
	cmp ax, 0xD280
	je usb2_set_address_1_done
;	mov al, '.'
;	call putchv
	mov cx, INIT_PACKET_DELAY
	loop $
	sub dx, 1
	jnz usb2_set_address_1
usb2_set_address_1_done:
	mov al, '.'
	call putchv
	mov dx, 20
usb2_set_address_2:
	mov si, usb_read0
	call usb2_send
	in ax, USB2
	push ax
	in ax, USB2
	mov si, usb_ack
	call usb2_send
	pop ax
	cmp ax, 0x4B80
	je usb2_set_address_done
;	mov al, '.'
;	call putchv
	mov cx, INIT_PACKET_DELAY
	loop $
	sub dx, 1
	jnz usb2_set_address_2
usb2_set_address_done:
	mov al, '.'
	call putchv
	mov cx, 6553
	loop $
	mov dx, 20
usb2_set_conf_1:
	mov si, usb_setup1
	call usb2_send
	mov si, usb_set_configuration
	call usb2_send
	in ax, USB2
	cmp ax, 0xD280
	je usb2_set_conf_1_done
;	mov al, '.'
;	call putchv
	mov cx, INIT_PACKET_DELAY
	loop $
	sub dx, 1
	jnz usb2_set_conf_1
;	mov al, 1
;	ret
usb2_set_conf_1_done:
	mov al, '.'
	call putchv
	mov dx, 20
usb2_set_conf_2:
	mov si, usb_read10
	call usb2_send
	in ax, USB2
	push ax
	in ax, USB2
	mov si, usb_ack
	call usb2_send
	pop ax
	cmp ax, 0x4B80
	je usb2_set_conf_done
;	mov al, '.'
;	call putchv
	mov cx, INIT_PACKET_DELAY
	loop $
	sub dx, 1
	jnz usb2_set_conf_2
	jmp usb2_init
	mov al, 1
	ret
usb2_set_conf_done:
	mov al, 0
	ret





; Сообщения USB
usb_setup:
	db 2
	db 0x80, 0x2D, 0x00, 0x10

usb_setup1:
	db 2
	db 0x80, 0x2D, 0x01, 0xE8

usb_set_address:
	db 6
	db 0x80, 0xC3, 0x00, 0x05, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0xEB, 0x25

usb_set_configuration:
	db 6
	db 0x80, 0xC3, 0x00, 0x09, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x27, 0x25

usb_read0:
	db 2
	db 0x80, 0x69, 0x00, 0x10

usb_read01:
	db 2
	db 0x80, 0x69, 0x80, 0xA0

usb_read10:
	db 2
	db 0x80, 0x69, 0x01, 0xE8

usb_read1:
	db 2
	db 0x80, 0x69, 0x81, 0x58

usb_ack:
	db 1
	db 0x80, 0xD2

usb_get_desc:
	db 6
	db 0x80, 0xC3, 0x80, 0x06, 0x00, 0x01, 0x00, 0x00, 0x12, 0x00, 0xE0, 0xF4
