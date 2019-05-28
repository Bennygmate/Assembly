; Note: This code was provided in the labs.
; Delay Constants
.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4 	; 4 cycles per iteration - setup/call-return overhead

; Delay commands
sleep_1ms:
	push r24
	push r25
	ldi r25, high(DELAY_1MS)
	ldi r24, low(DELAY_1MS)
delayloop_1ms:
	sbiw r25:r24, 1
	brne delayloop_1ms
	pop r25
	pop r24
	ret
sleep_5ms:
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	ret
sleep_20ms:
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	ret
sleep_1000ms:
	push temp
	clr temp
	loop_50:
		cpi temp, 50
		breq finish
		rcall sleep_20ms
		inc temp
		jmp loop_50
sleep_5000ms:
	push temp
	clr temp
	loop_250:
		cpi temp, 250	;reduced to 50 for testing
		breq finish
		rcall sleep_20ms
		inc temp
		jmp loop_250
finish:
	pop temp
	ret