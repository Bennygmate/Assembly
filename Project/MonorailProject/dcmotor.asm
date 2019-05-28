initialise_motor:
	push temp1

	; Output things and OVERRIDE NORMAL PORT FUNCTIONALITY
	ser temp1
	out DDRE, temp1
	clr temp1	; connected to PE5
	sts OCR3AH, temp1
	clr temp1
	sts OCR3AL, temp1
	ldi temp1, (1 << CS30) 	; set the Timer3 to Phase Correct PWM mode. 
	sts TCCR3B, temp1 ; WGM31=1  phase correct PWN, 8 bits
	ldi temp1, (1 << WGM31)|(1<< WGM30)|(1<<COM3B1)|(1<<COM3A1) ; COM3B1=1 make OC3B override the normal port functionality of the I/0 pin PL2
	sts TCCR3A, temp1

	ldi temp1, 0b00000010
	out TCCR0B, temp1 ; set prescaler to 8 = 278 microseconds

	pop temp1
	ret

; Mulitply number by 3 to give RPS, divide by 4 to account for 4 holes = /2
measure_RPS:
	push temp1
	lds temp1, holes
	asr temp1 ; TEMP1 is RPS
	sts currRPS, temp1
	pop temp1
	ret