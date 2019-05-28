initialise_buttons:
	push temp1 ; Prolouge 

	clr temp1
	sts button_flag, temp1 ; Clear debounce flag

	lds temp1, EICRA
	ori temp1, (2 << ISC00)		; set INT0 to trigger on falling edges
	ori temp1, (2 << ISC10) 	; set INT1 to trigger on falling edges
	sts EICRA, temp1

	in temp1, EIMSK
	ori temp1, (1 << INT0) 		; enable INT0
	ori temp1, (1 << INT1) 		; enable INT1
	out EIMSK, temp1

	; button flag timer settings
	clr temp1 				; normal mode
	sts TCCR1A, temp1
	ldi temp1, (1 << CS12)	; set prescaler to 256
	sts TCCR1B, temp1

	pop temp1 ; Epilouge
	ret

increase_tourist_off:
	push temp ; prolouge
	push temp1
	lds temp, tourist_count
	lds temp1, tourist_off
	cp temp, temp1 ; IF THEY ARE THE SAME CANT INCREASE ANYMORE
	breq increase_tourist_off_epilogue 
	inc temp1 ; OTHERWISE INCREASE AND STORE
	sts tourist_off, temp1
increase_tourist_off_epilogue:
	pop temp1
	pop temp
	ret
