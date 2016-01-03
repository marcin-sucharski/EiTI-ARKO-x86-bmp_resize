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
;	width (4 bytes unsigned integer)
;	height (4 bytes unsigned integer)
; }
;
global scale_image
scale_image:
	; prolog
	push	rbp
	push	rbx
	push	r12
	push	r13
	push	r14
	push	r15
	mov	rbp,	rsp
	; set sse state
	sub	rsp,	4
	stmxcsr	[rsp]				; store mxcsr register
	mov	eax,	[rsp]
	or	rax,	1110000001000000b		; set round to zero, FZ, DAZ
	sub	rsp,	4
	mov	[rsp],	eax
	ldmxcsr	[rsp]				; load mxcsr register
	add	rsp,	4
	; load arguments to registers
	mov	r8d,	[rdi+8]			; source image width
	mov	r9d,	[rdi+12]			; source image height
	mov	r10d,	[rsi+8]			; destination image width
	mov	r11d,	[rsi+12]			; destination image height
	mov	rdi,	[rdi]			; source pointer in rdi
	mov	rsi,	[rsi]			; dest pointer in rdi
	xchg	rdi,	rsi			; rsi - source image data; rdi - dest image data
	; prepare arguments for sse constants
	shl	r8,	32			; r8 == [src_w 0]
	shl	r10,	32			; r10 == [dst_w 0]
	mov	r12,	r8			; r12 == [src_w 0]
	mov	r13,	r10			; r13 == [dst_w 0]
	or	r12,	r9			; r12 == [src_w src_h]
	or	r13,	r11			; r13 == [dst_w dst_h]
	shr	r8,	32			; r8 == [0 src_w]
	shr	r10,	32			; r10 == [0 dst_w]
	; prepare sse constants
	movaps	xmm1,	[one_vec]			; xmm1 == [1 1 1 1] float32
	movq	xmm6,	r12			; xmm6 == [0 0 src_w src_h] int32
	pshufd	xmm0,	xmm6,	11011101b		; xmm0 == [0 src_w 0 src_w] int32
	movq	xmm5,	r13			; xmm5 == [0 0 dst_w dst_h] int32
	pshufd	xmm6,	xmm6,	01000100b		; xmm6 == [src_w src_h src_w src_h] int32
	pshufd	xmm5,	xmm5,	01000100b		; xmm5 == [dst_w dst_h dst_w dst_h] int32
	cvtdq2ps	xmm6,	xmm6			; xmm6 == [src_w src_h src_w src_h] float32
	subps	xmm6,	xmm1			; xmm6 == [src_w-1 src_h-1 src_w-1 src_h-1] flaot32
	cvtdq2ps	xmm5,	xmm5			; xmm5 == [dst_w dst_h dst_w dst_h] float32
	subps	xmm5,	xmm1			; xmm5 == [dst_w-1 dst_h-1 dst_w-1 dst_h-1] float32
	divps	xmm6,	xmm5			; xmm5 == [dw/sw dh/sh dw/sw dh/sh] float32a
	movaps	xmm5,	xmm6
	movaps	xmm6,	xmm0			; xmm6 == [0 src_w 0 src_w] int32
	; init y_loop
	lea	rcx,	[r11-1]			; counter for y, upper 32 bits are zero
.y_loop:
	; init x_loop
	lea	rbx,	[r10-1]			; counter for x, upper 32 bits are zero
align 16
.x_loop:
	; load constant
	movaps	xmm7,	[half_vec]			; load half_vec into xmm7
	; calculate offset in dest image and prepare coordinates
	shl	rbx,	32			; rbx == [x 0]
	mov	rax,	rcx			; rax == [0 y]
	mov	rdx,	rcx			; rdx == y
	imul	rdx,	r10			; rdx == dst_w*y
	or	rax,	rbx			; rax == [x y]
	shr	rbx,	32			; rbx == [0 x]
	add	rdx,	rbx			; rdx == dst_w*y + x
	; calculate offsets
	movq	xmm0,	rax			; xmm0 == [0 0 x y] int32
	pshufd	xmm0,	xmm0,	01000100b		; xmm0 == [x y x y] int32
	cvtdq2ps	xmm0,	xmm0			; xmm0 == [x y x y] float32
	mulps	xmm0,	xmm5			; xmm0 == [x2 y2 x y] float32
	addps	xmm0,	xmm7			; xmm0 == [x2+0.5 y2+0.5 x y] float32
	cvtps2dq	xmm1,	xmm0			; xmm1 == [x2 y2 x1 y1] int32
	cvtdq2ps	xmm2,	xmm1			; xmm2 == [x2 y2 x1 y1] float32
	movdqa	xmm3,	xmm1			; xmm3 == [x2 y2 x1 y1] int32
	pmuludq	xmm1,	xmm6			; xmm1 == [0 y2*sw 0 y1*sw] int32
	pshufd	xmm3,	xmm3,	01110111b		; xmm3 == [x1 x2 x1 x2] int32
	pshufd	xmm1,	xmm1,	10100000b		; xmm1 == [y2*sw y2*sw y1*sw y1*sw] int32
	paddd	xmm3,	xmm1			; xmm3 == [off_12 off_22 off_11 off_21] int32
	; calculate coefficents #1
	pshufd	xmm1,	xmm2,	00001111b		; xmm1 == [y1 y1 x2 x2] float32
	pshufd	xmm4,	xmm0,	01010101b		; xmm4 == [x x x x] float32
	unpcklps	xmm1,	xmm0			; xmm1 == [x x2 y x2] float32
	unpcklps	xmm4,	xmm2			; xmm4 == [x1 x y1 x] float32
	; prepare to load colors
	movq	r12,	xmm3			; r12 == [off_11 off_21]
	mov	r13d,	r12d			; r13 == [0 off_21]
	shr	r12,	32			; r12 == [0 off_11]
	prefetcht0	[rsi+r12*4]
	psrldq	xmm3,	8			; xmm3 == [0 0 off_12 off_22] int32
	; calculate coefficents #1
	pshufd	xmm4,	xmm4,	11100111b		; xmm4 == [x1 x y1 x1] float32
	subps	xmm1,	xmm4			; xmm1 == [x-x1 x2-x y-y1 x2-x1] float32
	; prepare to load colors
	movq	r14,	xmm3			; r14 == [off_12 off_22]
	; calculate coefficents #1
	pshufd	xmm3,	xmm1,	10111011b		; xmm3 == [x2-x x-x1 x2-x x-x1] float32
	pshufd	xmm1,	xmm1,	00000000b		; xmm1 == [x2-x1 x2-x1 x2-x1 x2-x1] float32
	rcpps	xmm1,	xmm1			; xmm1 = 1/xmm1
	; prepare to load colors
	mov	r15d,	r14d			; r15 == [0 off_22]
	shr	r14,	32			; r14 == [0 off_12]
	; calculate coefficents #1
	mulps	xmm3,	xmm1			; xmm3 == [coef11 coef21 coef12 coef22] float32
	; load colors and check for infinity
	mov	r12d,	[rsi+r12*4]			; r12 == [0 Q_11]
	mov	r14d,	[rsi+r14*4]			; r14 == [0 Q_12]
	mov	r13d,	[rsi+r13*4]			; r13 == [0 Q_21]
	mov	r15d,	[rsi+r15*4]			; r15 == [0 Q_22]
	; calculate coefficents #2
	pshufd	xmm1,	xmm2,	00000010b		; xmm1 == [y1 y1 y1 y2] float32
	unpcklps	xmm1,	xmm0			; xmm1 == [x y1 y y2] float32
	pshufd	xmm4,	xmm1,	11000001b		; xmm4 == [x y2 y2 y] float32
	pshufd	xmm1,	xmm1,	11011010b		; xmm1 == [x y y1 y1] float32
	subps	xmm4,	xmm1			; xmm4 == [0 y2-y y2-y1 y-y1] float32
	pshufd	xmm1,	xmm4,	01010101b		; xmm1 == [y2-y1 y2-y1 y2-y1 y2-y1] float32
	rcpps	xmm1,	xmm1			; xmm1 == 1/xmm1
	pshufd	xmm4,	xmm4,	11111000b		; xmm4 == [0 0 y2-y y-y1] float32
	mulps	xmm4,	xmm1			; xmm4 == [0 0 coeffr1 coeffr2] float32
	; load colors into sse
	pxor	xmm0,	xmm0			; xmm0 == 0
	movq	xmm1,	r12			; xmm1 == [0 0 0 RGBA] uint8
	punpcklbw	xmm1,	xmm0			; xmm1 == [0 RG 0 BA] uint16
	punpcklwd	xmm1,	xmm0			; xmm1 == [R G B A] uint32
	cvtdq2ps	xmm1,	xmm1			; xmm1 == [R G B A] float32, Q_11
	movq	xmm2,	r13			; xmm2 == [0 0 0 RGBA] uint8
	punpcklbw	xmm2,	xmm0			; xmm2 == [0 RG 0 BA] uint16
	punpcklwd	xmm2,	xmm0			; xmm2 == [R G B A] uint32
	cvtdq2ps	xmm2,	xmm2			; xmm2 == [R G B A] float32, Q_21
	movq	xmm7,	r14			; xmm7 == [0 0 0 RGBA] uint8
	punpcklbw	xmm7,	xmm0			; xmm7 == [0 RG 0 BA] uint16
	punpcklwd	xmm7,	xmm0			; xmm7 == [R G B A] uint32
	cvtdq2ps	xmm7,	xmm7			; xmm7 == [R G B A] float32, Q_12
	movq	xmm8,	r15			; xmm8 == [0 0 0 RGBA] uint8
	punpcklbw	xmm8,	xmm0			; xmm8 == [0 RG 0 BA] uint16
	punpcklwd	xmm8,	xmm0			; xmm8 == [R G B A] uint32
	cvtdq2ps	xmm8,	xmm8			; xmm8 == [R G B A] float32, Q_22
	; calculate new color
	pshufd	xmm0,	xmm3,	11111111b		; xmm0 == [coeff_11 coeff_11 coef_11 coef_11] float32
	mulps	xmm1,	xmm0			; xmm1 == Q_11 * coeff_11 float32
	pshufd	xmm0,	xmm3,	10101010b		; xmm0 == [coeff_21 coeff_21 coeff_21 coeff_21] float32
	mulps	xmm2,	xmm0			; xmm2 == Q_21 * coeff_21 float32
	pshufd	xmm0,	xmm3,	01010101b		; xmm0 == [coeff_12 coeff_12 coeff_12 coeff_12] float32
	mulps	xmm7,	xmm0			; xmm7 == Q_12 * coeff_12 float32
	pshufd	xmm0,	xmm3,	00000000b		; xmm0 == [coeff_22 coeff_22 coeff_22 coeff_22] float32
	mulps	xmm8,	xmm0			; xmm8 == Q_22 * coeff_22 float32
	addps	xmm1,	xmm2			; xmm1 == Q_11 * coeff_11 + Q_21 * coeff_21 float32
	addps	xmm7,	xmm8			; xmm7 == Q_12 * coeff_12 + Q_22 * coeff_22 float32
	pshufd	xmm0,	xmm4,	01010101b		; xmm0 == [coeffr_1 coeffr_1 coeffr_1 coeffr_1] float32
	mulps	xmm1,	xmm0			; xmm1 == R_1 float32
	pshufd	xmm0,	xmm4,	00000000b		; xmm0 == [coeffr_2 ceffr_2 coeffr_2 coeffr_2] float32
	mulps	xmm7,	xmm0			; xmm7 == R_2 float32
	addps	xmm1,	xmm7			; xmm1 == result color float32
	; save color
	pxor	xmm0,	xmm0			; xmm0 == 0
	cvtps2dq	xmm1,	xmm1			; xmm1 == result color int32
	packssdw	xmm1,	xmm0			; xmm1 == result color int16
	packuswb	xmm1,	xmm0			; xmm1 == result color int8
	movq	rax,	xmm1			; rax == [0 RGBA]
	mov	[rdi+rdx*4],	eax
	; end of x_loop
	sub	rbx,	1			; subtract inner loop index
	jns	.x_loop				; check inner loop condition
	; end of y_loop
	sub	rcx,	1			; subtract outer loop index
	jns	.y_loop				; check outer loop condition
	; restore old sse flag
	ldmxcsr	[rsp]
	add	rsp,	4
	; epilog
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	rbx
	pop	rbp
	xor	rax,	rax
	rep ret

section .data
align 16
	half_vec:	dd	0, 0, 1.0, 1.0
	one_vec:	dd	1.0, 1.0, 1.0, 1.0
