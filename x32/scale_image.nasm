section	.text

; Resizes bitmap image.
;
; Arguments:
; [ebp+16]: pointer to source image struct
; [ebp+20]: pointer to dest image struct
;
; Image struct:
; struct {
;	pointer (4 bytes)
;	width (4 bytes unsigned integer)
;	height (4 bytes unsigned integer)
; }
;
global scale_image
scale_image:
	; prolog
	push	ebp
	push	ebx
	sub	esp,	4			; place for mxcsr register
	mov	ebp,	esp
	sub	esp,	64
	; set sse state
	stmxcsr	[ebp]				; store mxcsr register
	mov	eax,	[ebp]
	or	eax,	1110000001000000b		; set round to zero, FZ, DAZ
	mov	[esp],	eax
	ldmxcsr	[esp]				; load mxcsr register
	; load arguments to variables
	mov	eax,	[ebp+16]			; pointer to source struct
	mov	edx,	[eax+4]
	mov	[ebp-4],	edx			; source image width
	mov	ecx,	[eax+8]
	mov	[ebp-8],	ecx			; source image height
	mov	ebx,	[eax]
	mov	[ebp-12],	ebx			; source image pointer
	mov	eax,	[ebp+20]			; pointer to dest struct
	mov	edx,	[eax+4]
	mov	[ebp-16],	ecx			; dest image width
	mov	ebx,	[eax+8]
	mov	[ebp-20],	ebx			; dest image height
	mov	ecx,	[eax]
	mov	[ebp-24],	ecx			; dest image pointer
	xor	eax,	eax
	xor	edx,	edx
	xor	ebx,	ebx
	xor	ecx,	ecx
	; prepare sse constants
	movaps	xmm1,	[one_vec]			; xmm1 == [1 1 1 1] float32
	movq	xmm6,	[ebp-8]			; xmm6 == [0 0 src_w src_h] int32
	pshufd	xmm0,	xmm6,	11011101b		; xmm0 == [0 src_w 0 src_w] int32
	movq	xmm5,	[ebp-20]			; xmm5 == [0 0 dst_w dst_h] int32
	pshufd	xmm6,	xmm6,	01000100b		; xmm6 == [src_w src_h src_w src_h] int32
	pshufd	xmm5,	xmm5,	01000100b		; xmm5 == [dst_w dst_h dst_w dst_h] int32
	cvtdq2ps	xmm6,	xmm6			; xmm6 == [src_w src_h src_w src_h] float32
	subps	xmm6,	xmm1			; xmm6 == [src_w-1 src_h-1 src_w-1 src_h-1] flaot32
	cvtdq2ps	xmm5,	xmm5			; xmm5 == [dst_w dst_h dst_w dst_h] float32
	subps	xmm5,	xmm1			; xmm5 == [dst_w-1 dst_h-1 dst_w-1 dst_h-1] float32
	divps	xmm6,	xmm5			; xmm5 == [dw/sw dh/sh dw/sw dh/sh] float32a
	movaps	xmm5,	xmm6
	movaps	[ebp-64],	xmm5
	movaps	xmm6,	xmm0			; xmm6 == [0 src_w 0 src_w] int32
	; init y_loop
	mov	eax,	[ebp-20]
	sub	eax,	1
	mov	[ebp-32],	eax			; counter for y
.y_loop:
	; init x_loop
	mov	eax,	[ebp-16]
	sub	eax,	1
	mov	[ebp-28],	eax			; counter for x
	xor	eax,	eax
align 16
.x_loop:
	mov	esi,	[ebp-12]			; source image pointer
	; load constants
	movaps	xmm7,	[half_vec]			; load half_vec into xmm7
	movaps	xmm5,	[ebp-64]
	; calculate offsets
	movq	xmm0,	[ebp-32]			; xmm0 == [0 0 x y] int32
	pshufd	xmm0,	xmm0,	01000100b		; xmm0 == [x y x y] int32
	cvtdq2ps	xmm0,	xmm0			; xmm0 == [x y x y] float32
	mulps	xmm0,	xmm5			; xmm0 == [x2 y2 x y] float32
	addps	xmm0,	xmm7			; xmm0 == [x2+0.5 y2+0.5 x y] float32
	pxor	xmm7,	xmm7
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
	movaps	[ebp-48],	xmm3
	mov	eax,	[ebp-48]			; eax == off_21
	mov	ebx,	[ebp-44]			; ebx == off_11
	mov	ecx,	[ebp-40]			; ecx == off_22
	mov	edx,	[ebp-36]			; edx == off_12
	prefetcht0	[esi+eax*4]
	prefetcht0	[esi+ebx*4]
	prefetcht0	[esi+ecx*4]
	prefetcht0	[esi+edx*4]
	; calculate coefficents #1
	pshufd	xmm4,	xmm4,	11100111b		; xmm4 == [x1 x y1 x1] float32
	subps	xmm1,	xmm4			; xmm1 == [x-x1 x2-x y-y1 x2-x1] float32
	pshufd	xmm3,	xmm1,	10111011b		; xmm3 == [x2-x x-x1 x2-x x-x1] float32
	pshufd	xmm1,	xmm1,	00000000b		; xmm1 == [x2-x1 x2-x1 x2-x1 x2-x1] float32
	rcpps	xmm1,	xmm1			; xmm1 = 1/xmm1
	; calculate coefficents #1
	mulps	xmm3,	xmm1			; xmm3 == [coef11 coef21 coef12 coef22] float32
	; load colors and check for infinity
	mov	edi,	[esi+ebx*4]
	mov	ebx,	edi			; ebx == Q_11
	mov	edi,	[esi+edx*4]
	mov	edx,	edi			; edx == Q_12
	mov	edi,	[esi+eax*4]
	mov	eax,	edi			; eax == Q_21
	mov	edi,	[esi+ecx*4]
	mov	ecx,	edi			; ecx == Q_22
	xor	edi,	edi
	; calculate coefficents #2
	pshufd	xmm1,	xmm2,	00000010b		; xmm1 == [y1 y1 y1 y2] float32
	pxor	xmm2,	xmm2
	unpcklps	xmm1,	xmm0			; xmm1 == [x y1 y y2] float32
	pxor	xmm0,	xmm0
	pshufd	xmm4,	xmm1,	11000001b		; xmm4 == [x y2 y2 y] float32
	pshufd	xmm1,	xmm1,	11011010b		; xmm1 == [x y y1 y1] float32
	subps	xmm4,	xmm1			; xmm4 == [0 y2-y y2-y1 y-y1] float32
	pshufd	xmm1,	xmm4,	01010101b		; xmm1 == [y2-y1 y2-y1 y2-y1 y2-y1] float32
	rcpps	xmm1,	xmm1			; xmm1 == 1/xmm1
	pshufd	xmm4,	xmm4,	11111000b		; xmm4 == [0 0 y2-y y-y1] float32
	mulps	xmm4,	xmm1			; xmm4 == [0 0 coeffr1 coeffr2] float32
	; load colors into sse
	movd	xmm1,	ebx			; xmm1 == [0 0 0 RGBA] uint8
	xor	ebx,	ebx
	punpcklbw	xmm1,	xmm0			; xmm1 == [0 RG 0 BA] uint16
	punpcklwd	xmm1,	xmm0			; xmm1 == [R G B A] uint32
	cvtdq2ps	xmm1,	xmm1			; xmm1 == [R G B A] float32, Q_11
	movd	xmm2,	eax			; xmm2 == [0 0 0 RGBA] uint8
	xor	eax,	eax
	punpcklbw	xmm2,	xmm0			; xmm2 == [0 RG 0 BA] uint16
	punpcklwd	xmm2,	xmm0			; xmm2 == [R G B A] uint32
	cvtdq2ps	xmm2,	xmm2			; xmm2 == [R G B A] float32, Q_21
	movd	xmm7,	edx			; xmm7 == [0 0 0 RGBA] uint8
	xor	edx,	edx
	punpcklbw	xmm7,	xmm0			; xmm7 == [0 RG 0 BA] uint16
	punpcklwd	xmm7,	xmm0			; xmm7 == [R G B A] uint32
	cvtdq2ps	xmm7,	xmm7			; xmm7 == [R G B A] float32, Q_12
	movd	xmm5,	ecx			; xmm8 == [0 0 0 RGBA] uint8
	xor	ecx,	ecx
	punpcklbw	xmm5,	xmm0			; xmm8 == [0 RG 0 BA] uint16
	punpcklwd	xmm5,	xmm0			; xmm8 == [R G B A] uint32
	cvtdq2ps	xmm5,	xmm5			; xmm8 == [R G B A] float32, Q_22
	; calculate new color
	pshufd	xmm0,	xmm3,	11111111b		; xmm0 == [coeff_11 coeff_11 coef_11 coef_11] float32
	mulps	xmm1,	xmm0			; xmm1 == Q_11 * coeff_11 float32
	pshufd	xmm0,	xmm3,	10101010b		; xmm0 == [coeff_21 coeff_21 coeff_21 coeff_21] float32
	mulps	xmm2,	xmm0			; xmm2 == Q_21 * coeff_21 float32
	pshufd	xmm0,	xmm3,	01010101b		; xmm0 == [coeff_12 coeff_12 coeff_12 coeff_12] float32
	mulps	xmm7,	xmm0			; xmm7 == Q_12 * coeff_12 float32
	pshufd	xmm0,	xmm3,	00000000b		; xmm0 == [coeff_22 coeff_22 coeff_22 coeff_22] float32
	pxor	xmm3,	xmm3
	mulps	xmm5,	xmm0			; xmm8 == Q_22 * coeff_22 float32
	addps	xmm1,	xmm2			; xmm1 == Q_11 * coeff_11 + Q_21 * coeff_21 float32
	pxor	xmm2,	xmm2
	addps	xmm7,	xmm5			; xmm7 == Q_12 * coeff_12 + Q_22 * coeff_22 float32
	pxor	xmm5,	xmm5
	pshufd	xmm0,	xmm4,	01010101b		; xmm0 == [coeffr_1 coeffr_1 coeffr_1 coeffr_1] float32
	mulps	xmm1,	xmm0			; xmm1 == R_1 float32
	pshufd	xmm0,	xmm4,	00000000b		; xmm0 == [coeffr_2 ceffr_2 coeffr_2 coeffr_2] float32
	pxor	xmm4,	xmm4
	mulps	xmm7,	xmm0			; xmm7 == R_2 float32
	addps	xmm1,	xmm7			; xmm1 == result color float32
	pxor	xmm7,	xmm7
	; calc offset
	mov	edi,	[ebp-24]			; destimage pointer
	mov	ecx,	[ebp-32]			; ecx == y
	mov	ebx,	[ebp-28]			; ebx == x
	mov	edx,	ecx			; edx == y
	imul	ecx,	[ebp-16]			; ecx == y*dst_w
	add	ecx,	ebx			; ecx == y*dst_w + x
	; save color
	cvtps2dq	xmm1,	xmm1			; xmm1 == result color int32
	packssdw	xmm1,	xmm3			; xmm1 == result color int16
	packuswb	xmm1,	xmm3			; xmm1 == result color int8
	movd	eax,	xmm1			; eax == RGBA
	mov	[edi+ecx*4],	eax
	xor	eax,	eax
	; end of x_loop
	sub	ebx,	1			; subtract inner loop index
	mov	[ebp-28],	ebx
	jns	.x_loop				; check inner loop condition
	; end of y_loop
	sub	edx,	1			; subtract outer loop index
	mov	[ebp-32],	edx
	jns	.y_loop				; check outer loop condition
	; restore old sse flag
	ldmxcsr	[ebp]
	; epilog
	mov	esp,	ebp
	add	esp,	4			; mxcsr register
	pop	ebx
	pop	ebp
	xor	eax,	eax
	rep ret

section .data
align 16
	half_vec:	dd	0, 0, 1.0, 1.0
	one_vec:	dd	1.0, 1.0, 1.0, 1.0
