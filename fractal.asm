	org	#6000
;**********************************
; Tabulate fixpoint squares with
; accuracy up to 2^-8
; Formats of 16 bit data:
; operand-index: 0000XXX.X XXXXXXX0
; table result:  0XXXXXX.X XXXXXXX0
;**********************************

;**********************************
tbl	equ	#c000
;**********************************

init:
	di

	xor	a
	
	ld	hl,tbl+2
	exx
	ld	bc,tbl
	ld	d,a
	ld	e,a
	ld	h,a
	ld	l,a
i2:
	exx
	dec	hl
	ld	(hl),a
	exx
	ex	af,af'
	ld	a,h
	and	#FE
	ld	(bc),a
	inc	bc
	exx
	dec	hl
	ld	(hl),a
	exx
	ex	af,af'
	ld	(bc),a
	inc	bc

	inc	de
	inc	de
	add	hl,de
	adc	a,0
	inc	de
	inc	de
	
;	bit	5,d
;	jr	z,i2
	jp	p,i2 ; while A:HL is positive


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
tab_bc	macro
	add	hl, bc	;11
	ld	c, (hl)	; 7
	inc	hl	; 6
	ld	b, (hl) ; 7
	endm		; = 21 t
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

	end	init
