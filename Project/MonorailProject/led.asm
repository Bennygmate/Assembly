initialise_LED:
	push temp1
	clr temp1
	out PORTC, temp1
	pop temp1
	ret

on_LED:
	push temp1
	ser temp1
	out PORTC, temp1
	clr temp1
	sts OCR3AH, temp
	sts OCR3AL, temp
	pop temp1
	ret
