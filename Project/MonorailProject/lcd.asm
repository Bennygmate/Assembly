
; LCD Functions
initialise_LCD: 		; used to initialise LCD and related variables
	do_lcd_command LCD_FUNC_SET 
	rcall sleep_5ms
	do_lcd_command LCD_FUNC_SET
	rcall sleep_1ms
	do_lcd_command LCD_FUNC_SET
	do_lcd_command LCD_FUNC_SET
	do_lcd_command LCD_DISP_OFF
	do_lcd_command LCD_DISP_CLR
	do_lcd_command LCD_ENTR_SET
	do_lcd_command LCD_DISP_ON
	ret

; OUTPUT FOR SYSTEM CONFIGURATION
lcd_output_one: ; "Type the max num(new line)of stations: "
	do_lcd_data 'T'
	do_lcd_data 'y'
	do_lcd_data 'p'
	do_lcd_data 'e' ;4
	do_lcd_data ' '
	do_lcd_data 't'
	do_lcd_data 'h'
	do_lcd_data 'e' ;4
	do_lcd_data ' '
	do_lcd_data 'm'
	do_lcd_data 'a'
	do_lcd_data 'x' ;4
	do_lcd_data ' '
	do_lcd_data 'n'
	do_lcd_data 'u'
	do_lcd_data 'm'; 16
	do_lcd_command LCD_SEC_LINE
	do_lcd_data 'o'
	do_lcd_data 'f'
	do_lcd_data ' '
	do_lcd_data 's'
	do_lcd_data 't'
	do_lcd_data 'a'
	do_lcd_data 't'
	do_lcd_data 'i'
	do_lcd_data 'o'
	do_lcd_data 'n'
	do_lcd_data 's'
	do_lcd_data ':'
	do_lcd_data ' '
	ret

lcd_output_two: ; "Name of station (newline)"
	do_lcd_data 'N'
	do_lcd_data 'a'
	do_lcd_data 'm'
	do_lcd_data 'e' ;4
	do_lcd_data ' '
	do_lcd_data 'o'
	do_lcd_data 'f'
	do_lcd_data ' ' ;4
	do_lcd_data 's'
	do_lcd_data 't'
	do_lcd_data 'a'
	do_lcd_data 't'
	do_lcd_data 'i'
	do_lcd_data 'o'
	do_lcd_data 'n'
	do_lcd_data ' ' ;
	do_lcd_command LCD_SEC_LINE
	ret

lcd_output_three: ; "Time from statio(new line)n is "
	do_lcd_data 'T'
	do_lcd_data 'i'
	do_lcd_data 'm'
	do_lcd_data 'e' ;4
	do_lcd_data ' '
	do_lcd_data 'f'
	do_lcd_data 'r'
	do_lcd_data 'o' ;4
	do_lcd_data 'm' 
	do_lcd_data ' '
	do_lcd_data 's'
	do_lcd_data 't' ;4
	do_lcd_data 'a'
	do_lcd_data 't'
	do_lcd_data 'i'
	do_lcd_data 'o' ;16	
	do_lcd_command LCD_SEC_LINE
	do_lcd_data 'n'
	do_lcd_data ' '
	ret

lcd_output_four: ; "Stop time at any(newline)station is: "
	do_lcd_data 'S'
	do_lcd_data 't'
	do_lcd_data 'o'
	do_lcd_data 'p' ;4
	do_lcd_data ' '
	do_lcd_data 't'
	do_lcd_data 'i'
	do_lcd_data 'm' ;4
	do_lcd_data 'e' 
	do_lcd_data ' '
	do_lcd_data 'a'
	do_lcd_data 't' ;4
	do_lcd_data ' '
	do_lcd_data 'a'
	do_lcd_data 'n'
	do_lcd_data 'y' ;16	
	do_lcd_command LCD_SEC_LINE
	do_lcd_data 's'
	do_lcd_data 't'
	do_lcd_data 'a'
	do_lcd_data 't' ;4
	do_lcd_data 'i'
	do_lcd_data 'o'
	do_lcd_data 'n' 
	do_lcd_data ' ' ;4
	do_lcd_data 'i'
	do_lcd_data 's'   	
	do_lcd_data ':'
	do_lcd_data ' ' ;4
	ret	

print_numstation:
	push temp
	do_lcd_command LCD_DISP_CLR
	do_lcd_data 'N'
	do_lcd_data 'u'
	do_lcd_data 'm'
	do_lcd_data 'b'
	do_lcd_data 'e'
	do_lcd_data 'r' 
	do_lcd_data ' '
	do_lcd_data 'o'
	do_lcd_data 'f'
	do_lcd_command LCD_SEC_LINE
	do_lcd_data 's'
	do_lcd_data 't' 
	do_lcd_data 'a'
	do_lcd_data 't' 
	do_lcd_data 'i'
	do_lcd_data 'o'
	do_lcd_data 'n'
	do_lcd_data ' ' ;8
	do_lcd_data 'i'
	do_lcd_data 's'   
	do_lcd_data ':'
	do_lcd_data ' ' ;12
	lds temp, num_stations
	cpi temp, 10
	breq print_numstation_10
	subi temp, -48
	do_lcd_data_reg temp
print_numstation_done:
	rcall sleep_5000ms
	do_lcd_command LCD_DISP_CLR
	pop temp
	ret
print_numstation_10:
	do_lcd_data '1'
	do_lcd_data '0'
	jmp print_numstation_done
	

print_incorrect_input:
	do_lcd_command LCD_DISP_CLR
	do_lcd_data 'I'
	do_lcd_data 'N'
	do_lcd_data 'C'
	do_lcd_data 'O'
	do_lcd_data 'R'
	do_lcd_data 'R' 
	do_lcd_data 'R'
	do_lcd_data 'E'
	do_lcd_data 'C'
	do_lcd_data 'T'
	do_lcd_command LCD_SEC_LINE
	do_lcd_data 'I'
	do_lcd_data 'N'
	do_lcd_data 'P'
	do_lcd_data 'U'
	do_lcd_data 'T'
	ret

print_finish:
	do_lcd_command LCD_DISP_CLR
	do_lcd_data 'C'
	do_lcd_data 'O'
	do_lcd_data 'N'
	do_lcd_data 'F' ;4
	do_lcd_data 'I'
	do_lcd_data 'G' 
	do_lcd_data 'U'
	do_lcd_data 'R' ;4
	do_lcd_data 'A'
	do_lcd_data 'T'
	do_lcd_data 'I'
	do_lcd_data 'O' ;4
	do_lcd_data 'N'
	do_lcd_data ' '
	do_lcd_data 'I'
	do_lcd_data 'S' ;4
	do_lcd_command LCD_SEC_LINE
	do_lcd_data 'C'
	do_lcd_data 'O'
	do_lcd_data 'M'
	do_lcd_data 'P' ;4
	do_lcd_data 'L'
	do_lcd_data 'E'
	do_lcd_data 'T'
	do_lcd_data 'E' ;4
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data 'A'
	do_lcd_data 'I' ;4
	do_lcd_data 'T'
	do_lcd_data '.'
	do_lcd_data '.'
	do_lcd_data '.' ;4
	rcall sleep_5000ms
	rcall sleep_5000ms
	do_lcd_command LCD_DISP_CLR	
	ret

print_namestation: ; TEMP2 has to be the station number printed
	do_lcd_command LCD_DISP_CLR
	do_lcd_data 'N'
	do_lcd_data 'a'
	do_lcd_data 'm'
	do_lcd_data 'e' ;4
	do_lcd_data ' '
	do_lcd_data 'o'
	do_lcd_data 'f'
	do_lcd_data ' ' ;8
	do_lcd_data 's'
	do_lcd_data 't'
	do_lcd_data 'a'
	do_lcd_data 't' ;12
	do_lcd_data 'i'
	do_lcd_data 'o'
	do_lcd_data 'n' ;15
	do_lcd_command LCD_SEC_LINE
	subi temp2, -49
	do_lcd_data_reg temp2
	subi temp2, 49
	do_lcd_data ' '
	do_lcd_data 'i'
	do_lcd_data 's' ;4
	do_lcd_data ':'
	do_lcd_data ' '
	ret

print_station: ;temp2 holds stationnumber-1
	push outp
	push temp1
	push temp3

	mov temp3, temp2
	ldi temp1, 10
	mul temp3, temp1
	mov YL, r0
	clr YH
	ldi temp1, low(station_names)
	add YL, temp1
	ldi temp1, high(station_names)
	adc YH, temp1

	ldi temp1, 0
print_station_loop:
	cpi temp1, 10
	breq print_station_done
	ld outp, Y+
	do_lcd_data_reg outp
	inc temp1
	jmp print_station_loop

print_station_done:
	rcall sleep_5000ms
	do_lcd_command LCD_DISP_CLR

	pop temp3
	pop temp1
	pop outp
	ret

emulator_LCD_display:
	push temp
	do_lcd_command LCD_DISP_CLR
	; NEXT STATION NAME
	rcall write_nextstation
	; MEASURED RPS
	ldi temp, 139
	do_lcd_command_reg temp
	rcall write_rps
	; TARGET RPS
	ldi temp, 142
	do_lcd_command_reg temp
	rcall write_targetrps
	; TOURIST COUNT
	do_lcd_command LCD_SEC_LINE
	rcall write_tourist_count
	; TOURIST ON
	ldi temp, 173
	do_lcd_command_reg temp
	do_lcd_data 'O'
	do_lcd_data 'N'
	rcall write_tourist_on
	; TOURIST OFF
	ldi temp, 177
	do_lcd_command_reg temp
	do_lcd_data 'O'
	do_lcd_data 'F'
	do_lcd_data 'F'
	rcall write_tourist_off
	; Seconds passed
	ldi temp, 182
	do_lcd_command_reg temp
	rcall write_seconds
	; MOVE OR STOP
	ldi temp, 183
	do_lcd_command_reg temp
	rcall write_move_stop
	pop temp
	ret

write_move_stop:
	push temp
	lds temp, monorail_stop_move
	cpi temp, 1
	breq write_move
	cpi temp, 2
	breq write_between
	; else stop
	do_lcd_data 'S'
	jmp write_move_epilogue
write_move:
	do_lcd_data 'M'
	jmp write_move_epilogue
write_between:
	do_lcd_data 'B'
write_move_epilogue:
	pop temp
	ret

write_seconds:
	push temp
	lds temp, seconds_passed
	rcall write_two_digit
	pop temp
	ret

write_nextstation:
	push temp2
	lds temp2, next_station
	;dec temp2
	rcall print_station_help
	pop temp2

write_tourist_count:
	push temp
	lds temp, tourist_count ; TEMP holds RPS
	rcall write_two_digit
	pop temp
	ret	

write_tourist_on:
	push temp
	lds temp, tourist_on ; TEMP holds RPS
	rcall write_two_digit
	pop temp
	ret	
write_tourist_off:
	push temp
	lds temp, tourist_off ; TEMP holds RPS
	rcall write_two_digit
	pop temp
	ret	
write_rps: ;2 DIGITS
	push temp
	lds temp, currRPS ; TEMP holds RPS
	rcall write_two_digit
	pop temp
	ret

write_targetrps: ;2 DIGITS
	push temp
	lds temp, targetRPS ; TEMP holds RPS
	rcall write_two_digit
	pop temp
	ret

write_two_digit:
	push temp
	push temp1
	 ; TEMP holds 2 digit
	clr temp1 ; temp1 holds division for 10
tens:
	cpi temp, 10
	brsh find10s
	rjmp finish_write
find10s:
	subi temp, 10
	inc temp1
	cpi temp, 10
	brsh find10s ; Still divide by 10 reloop
	subi temp1, -48
	do_lcd_data_reg temp1
finish_write:
	subi temp, -48
	do_lcd_data_reg temp
	pop temp1
	pop temp
	ret	
; Note: From example LCD

; LCD Instructions
.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4
; LCD Commands
lcd_command:
	out PORTF, r16
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	ret
lcd_data:
	out PORTF, r16
	lcd_set LCD_RS
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	lcd_clr LCD_RS
	ret
lcd_wait:
	push r16
	clr r16
	out DDRF, r16
	out PORTF, r16
	lcd_set LCD_RW
lcd_wait_loop:
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	in r16, PINF
	lcd_clr LCD_E
	sbrc r16, 7
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser r16
	out DDRF, r16
	pop r16
	ret