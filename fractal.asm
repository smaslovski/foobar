	org	#6000
;**********************************
; Tabulate fixpoint squares with
; accuracy up to 2^-8
; Formats of 16 bit data:
; operand-index: 0000XXX.X XXXXXXX0
; table result:  0XXXXXX.X XXXXXXX0
;**********************************
tbl	equ	#8000
;**********************************
init:
	di
	ld	hl, tbl
	ld	sp, hl
	pop	de		; increment SP by 2
	xor	a		; 24 bit accumulator in A:DE
	ld	d, a
	ld	e, a
i1:
	ld	b, a
	ld	c, d
	res	0, c		; make it even
	push	bc		; store BC to bottom half
	ld	(hl), c		; and next to
	inc	hl		;  upper
	ld	(hl), b		;   half
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
tab_bc	macro
	add	hl, bc	;11
	ld	c, (hl)	; 7
	inc	l	; 4  ;low byte is always at even address
	ld	b, (hl) ; 7
	endm		; = 29 t
;**********************************
tab_de	macro
	add	hl, de
	ld	e, (hl)
	inc	l
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
	
	;;;ld	bc, 0
	;;;ld	hl, tbl
	;;;tab_bc			; BC = y^2

	ld	hl,#2121  ;profit if we would pack the executable
	ld	a,#80     ;this inversion could be incorporated in the table and coordinates?
		          ;it does not affect subtraction nor addition
	xor	h
	ld	h,a       ;same bytes, but 25 tc instead of 31 tc
	ld	c,(hl)
	inc	l
	ld	b,(hl)


x	equ	$+1		; imm16 as x variable

	;;;ld	de, 0
	;;;ld	hl, tbl
	;;;tab_de			; DE = x^2
	ld	hl,#2121
	ld	a,#80
	xor	h
	ld	h,a
	ld	e,(hl)
	inc	l
	ld	d,(hl)

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

	;;;ld	de, tbl
	;;;tab_de			; DE = (x+y)^2
	ld	a,#80
	xor	h
	ld	h,a
	ld	e,(hl)
	inc	l
	ld	d,(hl)

	and	a		; clear CF
	ex	de, hl
	sbc	hl, bc

	;;;st_iy	d, e		; b
	push	iy
	pop	de	;1 byte smaller

	add	hl, de		; HL = 2*x*y+b
	ld	(y), hl

	pop	hl

	;;;st_ix	d, e		; a
	push	ix
	pop	de	;1 byte smaller

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

;;;	ld	de,489fh	; check for end condition
;;;	sbc	hl, de
	pop	hl

;;;	jr	z, mndbrt	; restart

	inc	l
	ld	a, 1fh
	and	l
newbt3:	jr	nz,newbt

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
;newbt2:	jr	newbt2
	jr	newbt2
n1:
	ld	a, 0e0h
	and	l
	jr	z,newbt2

	ld	a, h
	sub	08h
	ld	h, a

	xor	l
newbt2:	cp	#c8 ;here only when H=40 and L=00,20,40,60,80,A0,C0,E0
		    ; or H=48 and L=00,20,40,60,80. 4880 is exit condition
	jr	nz,newbt3
	halt	;stops the cpu because of previous DI

	;;;jp	newbt
	;;;ret
	end	init

