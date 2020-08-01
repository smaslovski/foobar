	org	#c000
;**********************************
; Tabulate fixpoint squares with
; accuracy up to 2^-8
; Formats of 16 bit data (S=sign):
; operand-index: 1SSSXXX.X XXXXXXX0
; table result:  0XXXXXX.X XXXXXXX0
;**********************************
init:
	di
	xor	a		; 24 bit accumulator in A:DE
	ld	d, a
	ld	e, a
	ld	l, a
	ld	h, a
	ld	sp, hl
	ld	h, 80h
	pop	bc		; increment SP by 2
i1:
	ld	b, a
	ld	c, d
	res	0, c		; make it even
	push	bc		; store BC to high tbl
	ld	(hl), c		; and to
	inc	hl		;  low
	ld	(hl), b		;   tbl
	push	hl		; always below the data, can use
	add	hl, hl		; HL = 2*x + 2^-8, bit15 = 0
	add	hl, de
	ex	de, hl
	adc	a, 0		; A:DE = x^2 + 2^-7*x + 2^-16 = (x + 2^-8)^2
	pop	hl		; restore HL and SP
	inc	hl
	jp	p, i1		; A is negative if overflow

;**********************************
; Draw fractal
;**********************************
niter	equ	32
max2	equ	7
dx	equ	6
dy	equ	dx
x0	equ	-170*dx
y0	equ	-96*dx
;**********************************

mndbrt:
	ld	hl, 4000h	; screen start addr
newln:
	ld	d,h
	ld	e,l
newbt:
	ld	(hl), 1		; initial bit mask
newpx:
	ld	b, niter	; max iteration number

	exx			; moved here, can be useful

	ld	de, dx
	ld	hl, (za)
	add	hl, de		; update a
	set	7, h		; fix MSB, because sign can change
	ld	(za), hl
	ld	(x), hl		; x = a
	ld	hl, (zb)
	ld	(y), hl		; y = b
	jr	entry

loop:
	exx

	ld	d, h
	ld	e, l		; DE = x^2+y^2

	sbc	hl, bc		; here CF is not set
	sbc	hl, bc		; HL = x^2-y^2
za	equ	$+1
	ld	bc, x0		; a
	add	hl, bc		; HL = x^2-y^2+a
	set	7, h		; fix MSB
	ld	(x), hl		; new x

y	equ	$+1		; imm16 as y variable
	ld	hl, 2121h
	dec	sp
	dec	sp		; old x
	add	hl, sp		; HL = x+y
	set	7, h		; fix MSB
	ld	sp, hl
	pop	hl		; HL = (x+y)^2

	and	a		; clear CF
	sbc	hl, de		; HL = 2*x*y
zb	equ	$+1
	ld	de, y0		; b
	add	hl, de		; HL = 2*x*y+b
	set	7, h
	ld	(y), hl		; new y
entry:
	ld	sp, hl
	pop	bc		; BC = y^2

x	equ	$+1		; imm16 as x variable
	ld	sp, 3131h
	pop	hl		; HL = x^2
	add	hl, bc		; HL = x^2+y^2

	ld	a, max2
	cp	h		; H > max2 ?

	exx

	jr	c, ovfl
	djnz	loop		; to next iteration
ovfl:
	rr	b
	rl	(hl)		; update bitmask in place
	jr	nc, newpx	; to new pixel

	ld	a, l
	xor	0e0h
	ld	c, a
	ld	a, 97h
	sub	h
	ld	b, a
	ld	a, (hl)
	ld	(bc), a		; write to lower half-screen

	inc	l
	ld	a,l
	and	31
	jr	nz, newbt

	exx
	ld	hl, x0
	ld	(za), hl	; set a = x0
	ld	de, dy
	ld	hl, (zb)
	add	hl, de		; update b, no need to fix MSB
	ld	(zb), hl
	exx
trap:
	jr	c, trap		; loop when iy >= 0

	
	ex	de,hl

	inc	h
	ld	a,h
	and	7
	jr	nz,newln2
	ld	a,l
	add	a,32
	ld	l,a
	jr	c,newln2
	ld	a,h
	sub	8
	ld	h,a
newln2
	jp	newln


	end	init





