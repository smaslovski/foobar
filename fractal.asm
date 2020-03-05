	org	6000h
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
st_ix   macro   hi, lo
        ld      hi, ixh
        ld      lo, ixl
        endm
;**********************************
st_iy   macro   hi, lo
        ld      hi, iyh
        ld      lo, iyl
        endm
;**********************************

mndbrt:
	ld	hl, 4000h	; screen start addr
	ld	ix, x0		; a = x0
	ld	iy, y0		; b = y0
newbt:
	ld	c, 1		; initial bit mask
newpx:
	ld	b, niter	; max iteration number

	exx			; moved here, can be useful

	ld	de, dx
	add	ix, de		; update a
	ld	a, ixh
	or	#80		; fix MSB, because sign can change
	ld	ixh, a
	ld	(x), ix		; x = a
	ld	(y), iy		; y = b
	ld	sp, iy
	jr	entry

loop:
	exx

	ld	d, h
	ld	e, l		; DE = x^2+y^2

	sbc	hl, bc		; here CF is not set
	sbc	hl, bc		; HL = x^2-y^2
	st_ix	b, c		; a
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
	st_iy	d, e		; b
	add	hl, de		; HL = 2*x*y+b
	set	7, h
	ld	(y), hl		; new y
	ld	sp, hl
entry:
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
	rl	c		; update bitmask
	jr	nc, newpx	; to newpixel

	ld	(hl), c		; write to upper half-screen
	ld	a, l
	xor	0e0h
	ld	e, a
	ld	a, 97h
	sub	h
	ld	d, a
	ld	a, c
	ld	(de), a		; write to lower half-screen

	inc	l
	ld	a, 1fh
	and	l
	jr	nz, newbt

	ld	ix, x0		; a = x0
	ld	de, dy
	add	iy, de		; update b, no need to fix MSB
	jr	c, mndbrt	; restart when iy >= 0

	inc	h
	ld	a, 07h
	and	h
	jr	z, n1

	ld	a, l
	sub	20h
	ld	l, a
	jp	newbt
n1:
	ld	a, 0e0h
	and	l
	jp	z, newbt

	ld	a, h
	sub	08h
	ld	h, a
	jp	newbt

	end	init
