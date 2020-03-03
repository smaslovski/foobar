	org	25000
;**********************************
; Tabulate fixpoint squares with
; accuracy up to 2^-8
; Formats of 16 bit data:
; operand-index: 0000XXX.X XXXXXXX0
; table result:  0XXXXXX.X XXXXXXX0
;**********************************
init:
	di
	ld	ix, tbl
	ld	iy, tbl
	ld	hl, 0		; operand-index in HL
	ld	de, 0		; last square in DE
	xor	a		;   with extra bits in A
i1:
	ld	b, e
	res	0, b		; make it even
	ld	(ix+0), b
	ld	(ix+1), d
	ld	(iy+0), b
	ld	(iy+1), d

	inc	hl
	push	hl
	add	hl, hl		; HL = 2*x + 2^-8
	add	a, l		; 24 bit accumulator in DE:A
	ld	l, h
	ld	h, 0
	adc	hl, de		; get next square as
	ex	de, hl		; DE:A = x^2 + 2^-7*x + 2^-16 = (x + 2^-8)^2

	dec	ix
	dec	ix
	inc	iy
	inc	iy
	pop	hl
	inc	hl
	bit	4, h		; test for x >= 8.0
	jr	z, i1
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
tab_hl	macro
	ld	l, (hl)	; 7
	inc	h	; 6
	ld	h, (hl) ; 7
	endm		; = 20 t
;**********************************
tab_de	macro
	add	hl, de
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	endm
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
	ld	de, dx
	add	ix, de		; update a
	ld	(x), ix		; x = a
	ld	(y), iy		; y = b

	ld	b, niter	; max iteration number
loop:
	exx

y	equ	$+1		; imm16 as y variable
	ld	bc, 0
	ld	hl, tbl
	tab_bc			; BC = y^2

x	equ	$+1		; imm16 as x variable
	ld	de, 0
	ld	hl, tbl
	tab_de			; DE = x^2

	ex	de, hl
	add	hl, bc		; HL = x^2+y^2

	ld	a, max2
	cp	h		; H > max2 ?
	jr	c, ovfl

	push	hl

	sbc	hl, bc		; here CF is not set
	sbc	hl, bc		; HL = x^2-y^2

	pop	bc		; BC = x^2+y^2

	push	hl

	ld	hl, (x)
	ld	de, (y)
	add	hl, de
	ld	de, tbl
	tab_de			; DE = (x+y)^2

	and	a		; clear CF
	ex	de, hl
	sbc	hl, bc
	st_iy	d, e		; b
	add	hl, de		; HL = 2*x*y+b
	ld	(y), hl

	pop	hl

	st_ix	d, e		; a
	add	hl, de		; HL = x^2-y^2+a
	ld	(x), hl

	exx

	djnz	loop		; to next iteration
	jr	norm
ovfl:
	exx
norm:
	rr	b
	rl	c		; update bitmask
	jr	nc, newpx	; to newpixel

	ld	(hl), c		; write to upper half-screen

	push	hl
	ld	a, l
	xor	0e0h
	ld	l, a
	ld	a, 97h
	sub	h
	ld	h, a
	ld	(hl), c		; write to lower half-screen
	ld	de, 489fh	; check for end condition
	sbc	hl, de
	pop	hl
	jp	z, mndbrt	; restart

	inc	l
	ld	a, 1fh
	and	l
	jr	nz, newbt

	ld	ix, x0		; a = x0
	ld	de, dy
	add	iy, de		; update b

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
	ret
;**********************************
tbl	equ	$0e000h
;**********************************
	end	init
