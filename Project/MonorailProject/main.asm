; MonorailProject.asm
; Author : Benjamin Cheung (z3460693) and Christopher Crowe (z)
.include "m2560def.inc"
.include "init.asm" ; def, equ, LCD setting, macro and data segment 

.cseg
.org 0x0000
	jmp RESET
	jmp RIGHT_BUTTON		; IRQ0 Handler PB0 RDX4
	jmp LEFT_BUTTON			; IRQ1 Handler PB1 RDX3
	jmp INTERRUPT2 			; IRQ2 Handler
	jmp DEFAULT 			; IRQ3 Handler
	jmp DEFAULT 			; IRQ4 Handler
	jmp DEFAULT 			; IRQ5 Handler
	jmp DEFAULT 			; IRQ6 Handler
	jmp DEFAULT 			; IRQ7 Handler
	jmp DEFAULT 			; Pin Change Interrupt Request 0
	jmp DEFAULT 			; Pin Change Interrupt Request 1
	jmp DEFAULT 			; Pin Change Interrupt Request 2
	jmp DEFAULT 			; Watchdog Time-out Interrupt
	jmp DEFAULT 			; Timer/Counter2 Compare Match A
	jmp DEFAULT 			; Timer/Counter2 Compare Match B
	jmp DEFAULT 			; Timer/Counter2 Overflow
	jmp DEFAULT 			; Timer/Counter1 Capture Event
	jmp DEFAULT 			; Timer/Counter1 Compare Match A
	jmp DEFAULT 			; Timer/Counter1 Compare Match B
	jmp DEFAULT 			; Timer/Counter1 Compare Match C
	jmp BUTTON_CLR 			; Timer/Counter1 Overflow
	jmp DEFAULT 			; Timer/Counter0 Compare Match A
	jmp DEFAULT 			; Timer/Counter0 Compare Match B
	jmp Timer0OVF 			; Timer/Counter0 Overflow
	jmp DEFAULT 			; SPI Serial Transfer Complete
	jmp DEFAULT 			; USART0, Rx Complete
	jmp DEFAULT 			; USART0 Data register Empty
	jmp DEFAULT 			; USART0, Tx Complete
	jmp DEFAULT 			; Analog Comparator
	jmp DEFAULT 			; ADC Conversion Complete
	jmp DEFAULT 			; EEPROM Ready
	jmp DEFAULT 			; Timer/Counter3 Capture Event
	jmp DEFAULT 			; Timer/Counter3 Compare Match A
	jmp DEFAULT 			; Timer/Counter3 Compare Match B
	jmp DEFAULT 			; Timer/Counter3 Compare Match C
	jmp DEFAULT 			; Timer/Counter3 Overflow
.org 0x0072
DEFAULT: ; used for interrupts that are not handled
	reti 

RESET:
	ldi r16, low(RAMEND) ; Initialise SP
	out SPL, r16
	ldi r16, high(RAMEND)
	out SPH, r16
	
	ser temp1 ; set PORTC (LEDs) to output
	out DDRC, temp1
	
	ser r16 ; LCD SETUP										
	out DDRF, r16
	out DDRA, r16
	clr r16	; clear PORTF and PORTA registers
	out PORTF, r16
	out PORTA, r16
	
	; Hole count porting
	clr r16 ; set PORTD (INT2/TDX2) to input - Timer0
	out DDRD, r16 		
	
	ldi temp1, (2 << ISC20) 	; set INT2 to trigger on falling edges
	sts EICRA, temp1
	ldi temp1, (1 << INT2) 		; enable INT2 to count holes
	out EIMSK, temp1

	; Initialisation
	rcall initialise_LCD
	rcall initialise_LED
	rcall initialise_buttons
	rcall initialise_keypad
	
	sei ; Enable global interrupts

	; Initialise VAR
	ldi temp, 60
	sts targetRPS, temp
	ldi temp, 1
	sts monorail_stop_move, temp ; Initially moving
	ldi temp, 1
	sts next_station, temp ; Initially going towards station 2
	clr temp
	sts tourist_on, temp
	sts tourist_off, temp
	sts tourist_count, temp
	sts thirdofsecond_passed, temp
	sts seconds_passed, temp
	sts order_to_stop, temp ; INTIALLY NO ORDERS

system_configurations: ; CALLS FUNCTIONS FOR SYSTEM CONFIG
	rcall read_station_number
	sts num_stations, outp 
	rcall print_numstation
	rcall read_station_names
	rcall read_travel_times
	rcall read_stop_time
	rcall print_finish
	rcall demo_test

monorail_emulation:	
	ldi yl, low(time_travel)
	ldi yh, high(time_travel)
	ld temp, y
	sts currtime_to_nextstation, temp

	rcall initialise_timer
	rcall initialise_motor
halt: 
	rcall keypad_scan
	cpi outp, '#'
	breq check_moving
	rjmp halt
check_moving:
	lds temp, monorail_stop_move
	cpi temp, 1 ; 1 MEANS MOVING SO CAN ORDER TO STOP
	breq monorail_immediate_stop
	cpi temp, 2 ; 2 MEANS STOPPED BETWEEN
	breq monorail_immediate_stop_restart
	jmp halt
monorail_immediate_stop: ; STOPPING BETWEEN
	ldi temp, 1
	sts order_to_stop, temp ; 1 MEANS STOP ORDER
	rjmp halt
monorail_immediate_stop_restart:
	ldi temp, 2
	sts order_to_stop, temp ; 2 MEANS NO STOP ORDER ANYMORE - MOVE ORDER
	rjmp halt

; Timer + Motor stuff
Timer0OVF: ; interrupt subroutine to Timer0
	in temp, SREG
	push temp ; prologue starts
	push temp1
	push YH ; save all conflicting registers in the prologue
	push YL
	push r25
	push r24 ; prologue ends
	rcall initialise_LED
	lds r24, TempCounter ; Load the value of the temporary counter
	lds r25, TempCounter+1
	adiw r25:r24, 1 ; increase the temporary counter
	; 1 Second = 7812 = 10^6/128 - 2604 every 1/3 seconds
	cpi r24, low(2604) 
	ldi temp, high(2604)
	cpc r25, temp
	brne NotSecond
	clearTempCounter TempCounter ; one second has passed, thus reset the temporary counter
	lds r24, SecondCounter ; Load the value of the second counter
	inc r24 ; increase the second counter by one

	; DO STUFF 1/3 SECOND HAS PASSED - UPDATE STATIONS
	rcall increment_secondpassed
	rcall check_order_stop
	rcall stop_station
	rcall update_station
	
	; LED BLINK IF STOP
	lds temp3, targetRPS ; TEMP3 = TARGET
	cpi temp3, 0
	breq LED_BLINK

	; MEASURE RPS FOR MOTOR
	rcall measure_RPS	

	; CHANGE SPEED FOR MOTOR
	lds temp1, currRPS ; RPS < Target
	mov temp, temp3 
	sub temp, temp1 ; TEMP = TARGET - RPS (DIFFERENCE)
	cp temp1, temp3 ; RPS VS TARGET
	brlo increase_voltage
	;  RPS >= TARGET
	sub temp1, temp3 ; TEMP1 = RPS - TARGET (DIFFERENCE)
	cpi temp1, 0
	breq print_target ; PRINT TARGET IF NO DIFFERENCE
	jmp decrease_voltage ; otherwise decrease voltage
increase_voltage: ; RPS < TARGET_RPS SO INCREASE OCR3A by RPS_UPDATE
	lds temp1, OCR3AL
	lds temp2, OCR3AH
	add temp1, temp
	clr temp3
	adc temp2, temp3
	sts OCR3AH, temp2
	sts OCR3AL, temp1
	jmp print_target
decrease_voltage: ; RPS > TARGET RPS SO DECREASE OCR3A BY UPDATE
	lds temp, OCR3AL
	sub temp, temp1
	lds temp2, OCR3AH
	sbci temp2, 0
	sts OCR3AH, temp2
	sts OCR3AL, temp
LED_BLINK: ; TARGET RPS 0
	rcall on_LED
print_target: ; CALL LCD FUNCTION TO PRINT DISPLAY
	rcall emulator_LCD_display
	clr temp
	sts currRPS, temp ; CLEAR CURR RPS
	sts holes, temp
	sts SecondCounter, r24 ;store the second counter in the data memory
	rjmp EndIF			
NotSecond: ; store the new value of the temporary counter
	sts TempCounter, r24
	sts TempCounter+1, r25
EndIF: ; epilogue 
	pop r24 
	pop r25 ; restore all conflicting registers from the stack
	pop YL
	pop YH
	pop temp1
	pop temp
	out SREG, temp
	reti ; return from the interrupt

; FOR PB0/PB1
RIGHT_BUTTON: ;PB0
	push temp1 ; Prologue
	lds temp1, button_flag ; Debounce
	cpi temp1, 1 ; If button flag, 1 already pressed
	breq RIGHT_BUTTON_EPILOGUE 
	; Do STUFF - Increase tourist off
	rcall increase_tourist_off
	jmp RIGHT_BUTTON_Flag
RIGHT_BUTTON_Flag:
	ldi temp1, 1
	sts button_flag, temp1 ; Set button_flag as 1 (pressed)
	ldi temp1, 1 << TOIE1 	; enable timer interrupt again
	sts TIMSK1, temp1
RIGHT_BUTTON_EPILOGUE:
	rcall sleep_20ms
	pop temp1
	reti
LEFT_BUTTON: ;PB1
	push temp1 ; Prologue
	lds temp1, button_flag ; Debounce
	cpi temp1, 1 ; If button flag, 1 already pressed
	breq LEFT_BUTTON_EPILOGUE
	; DO STUFF - Increase tourist on
	lds temp1, tourist_on
	inc temp1
	sts tourist_on, temp1
	jmp LEFT_BUTTON_FLAG
LEFT_BUTTON_Flag:
	ldi temp1, 1
	sts button_flag, temp1
	ldi temp1, 1 << TOIE1 	; enable timer interrupt again
	sts TIMSK1, temp1
LEFT_BUTTON_EPILOGUE:
	rcall sleep_20ms
	pop temp1
	reti
BUTTON_CLR:
	push temp1 ; Prologue
	sei ; Enable global interrupt
	rcall sleep_1ms
	cli ; Global interrupt disable
	clr temp1 ; set button flag to 0		
	sts button_flag, temp1 
	ldi temp1, 0 << TOIE1 	; disable timer
	sts TIMSK1, temp1
BUTTON_CLR_EPILOGUE:
	pop temp1
	reti

INTERRUPT2: ; COUNT HOLE, interrupt is trigged
	push temp1 ; Prologue
	; DO STUFF
	lds temp1, holes
	inc temp1
	sts holes, temp1
INTERRUPT2_EPILOGUE:
	pop temp1
	reti

; These files contain helper functions as well as some definitions
.include "led.asm"
.include "buttons.asm"
.include "lcd.asm"
.include "delay.asm"
.include "dcmotor.asm"
.include "keypad.asm"
.include "timer.asm"
.include "sysconfig_test.asm"
