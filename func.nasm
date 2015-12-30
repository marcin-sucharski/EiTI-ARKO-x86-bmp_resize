section	.text

; Resizes bitmap image.
;
; Arguments:
; rdi: pointer to source image struct
; rsi: pointer to dest image struct
;
; Image struct:
; struct {
;	pointer (8 bytes)
;	width (8 bytes unsigned integer)
;	height (8 bytes unsigned integer)
; }
;
global scale_image
scale_image:
	; prolog
	push	rbp
	push	rbx
	push	r12
	push	r13
	mov	rbp,	rsp
	
	mov	r8d,	dword [rdi+8]		; source image width
	mov	r9d,	dword [rdi+12]		; source image height
	mov	r10d,	dword [rsi+8]		; destination image width
	mov	r11d,	dword [rsi+12]		; destination image height
	mov	rdi,	[rdi]			; source pointer in rdi
	mov	rsi,	[rsi]			; dest pointer in rdi
	xchg	rdi,	rsi			; rsi - source image data; rdi - dest image data

	lea	rcx,	[r11-1]			; counter for y
.y_loop:
	lea	rbx,	[r10-1]			; counter for x
.x_loop:
	; TODO: implement
	
	sub	rbx,	1			; subtract inner loop index
	jns	.x_loop				; check inner loop condition
	sub	rcx,	1			; subtract outer loop index
	jns	.y_loop				; check outer loop condition
	
	pop	r13
	pop	r12
	pop	rbx
	pop	rbp
	xor	rax,	rax
	rep ret
