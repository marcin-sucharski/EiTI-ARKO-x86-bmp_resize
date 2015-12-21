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
	
	; prepare helper xmm2 vector
	mov	eax,	dword [rdi+12]		; rax == [0 src_h]
	sal	rax,	32			; rax == [src_h 0]
	or	eax,	dword [rdi+8]		; rax == [src_h src_w]
	movq	xmm2,	rax			; xmm2 == [0 0 src_h src_w]
	pshufd	xmm2,	xmm2,	11011100b	; xmm2 == [0 src_h 0 src_w]
	psrld	xmm2,	1			; xmm2 == [0 src_h/2 0 src_w/2]

	; prepare helper xmm1 vector
	mov	eax,	dword [rsi+12]		; rax == [0 dest_h]
	sal	rax,	32			; rax == [dest_h 0]
	or	eax,	dword [rsi+8]		; rax == [dest_h dest_w]
	movq	xmm1,	rax			; xmm1 == [0 0 dest_h dest_w]
	pshufd	xmm1,	xmm1,	01010000b	; xmm1 == [dest_h dest_h dest_w dest_w]

	
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
	mov	eax,	ecx			; rax == [0 ecx]
	sal	rax,	32			; rax == [ecx 0]
	or	rax,	rbx			; rax == [ecx ebx]
	movq	xmm0,	rax			; xmm0 == [0 0 ecx ebx]
	pshufd	xmm0,	xmm0,	01010000b	; xmm0 == [ecx ecx ebx ebx]
	paddd	xmm0,	xmm2			; xmm0 == [ecx ecx+1 ebx ebx+1]

	
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
