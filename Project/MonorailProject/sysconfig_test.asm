; This is helper function after system configuration is complete
; To print out # of Station
; STATION
; STATION
; STATION
; STATION
; STATION
; Then
; STATION1 to STATION 2: #second
; ...
; STATIONFINAL to STATION 1
; STOP TIME: # second

demo_test:
	rcall print_stations ; Prints # Stations: (nextline) station 5s station 5s ...
	rcall print_traveltime
	rcall print_stoptime
	rcall pass_demotest
	ret

pass_demotest:
	rcall lcd_pressanykey_placeholder
	rcall keypad_scan
	rcall emulation_countdown
	ret

; FIX PRINT STATION (PASSING temp2 VALUE) 
; If pass 1 PRINT IN LCD timetravel byte 1 (e.g. station 1-2)
; is pass 2 print in LCD timetravel BYTE 2 (e.g. station 2-3)
; ... up to last - station 1
print_traveltime_help: ;temp2 holds stationnumber (e.g. 1 means 1-2)
	push outp
	push temp1
	push temp

	lds temp1, num_stations 
	cp temp2, temp1
	breq print_traveltime_help_last

	ldi yl, low(time_travel)
	ldi yh, high(time_travel)

	ldi temp1, 1
print_traveltime_loop_help:
	ld outp, y+
	cp temp1, temp2
	breq print_traveltime_done_help
	inc temp1
	jmp print_traveltime_loop_help
print_traveltime_help_last:
	ldi yl, low(time_travel) + 9
	ldi yh, high(time_travel) + 9
	ld outp, y
print_traveltime_done_help:	
	;subi outp, -48
	;do_lcd_data_reg outp
	mov temp, outp
	rcall write_two_digit
	pop temp
	pop temp1
	pop outp
	ret

; FUNCTION END HERE

print_traveltime:
	push temp
	push temp1
	push temp2
	clr temp2
loop_traveltime:
	lds temp, num_stations
	cp temp2, temp
	breq finish_traveltime 
	
	; TRAVEL TIME (NEWLINE) STATION #-#+1
	rcall print_traveltime_initialisation

	; Prints Station # to Station #+1
	do_lcd_command LCD_DISP_CLR
	do_lcd_command LCD_HOME_LINE
	rcall print_station_help ; THIS PRINT STATION (TEMP2 STARTS AT 0)
	do_lcd_data ' '
	do_lcd_data 't'
	do_lcd_data 'o'
	do_lcd_data ' '
	do_lcd_command LCD_SEC_LINE
	inc temp2
	rcall print_station_help
	do_lcd_data ':'
	;do_lcd_data ' ' ;12
	; GRAB TIME
	rcall print_traveltime_help
	do_lcd_data 's'
	do_lcd_data 'e'
	do_lcd_data 'c' ;16
	rcall sleep_5000ms
	do_lcd_command LCD_DISP_CLR
	do_lcd_command LCD_HOME_LINE
	jmp loop_traveltime
finish_traveltime:
	pop temp2
	pop temp1
	pop temp
	ret

print_stoptime:
	push temp
	rcall lcd_stoptime_placeholder
	do_lcd_command LCD_SEC_LINE
	lds temp, time_stop
	subi temp, -48
	do_lcd_data_reg temp
	rcall lcd_seconds_placeholder
	rcall sleep_5000ms
	do_lcd_command LCD_DISP_CLR
	pop temp
	ret

print_stations:
	push temp
	push temp1
	push temp2
	clr temp2
loop_num_stations:
	lds temp, num_stations
	cp temp2, temp
	breq finish_print_station ;
	rcall num_station_to_word ; This prints "# STATIONS:" FIRST LINE
	do_lcd_command LCD_SEC_LINE ; NEW LINE
	; Get station number printing in keypad form
	mov temp1, temp2
	inc temp1
	subi temp1, -48
	do_lcd_data_reg temp1
	do_lcd_data ' '
	do_lcd_data '-'
	do_lcd_data ' '
	rcall print_station_help ; THIS PRINT STATION (TEMP2 STARTS AT 0)
	rcall sleep_5000ms
	do_lcd_command LCD_DISP_CLR
	do_lcd_command LCD_HOME_LINE	
	inc temp2
	jmp loop_num_stations
finish_print_station:
	pop temp2
	pop temp1
	pop temp
	ret

print_station_help: ;temp2 holds stationnumber-1
	push outp
	push temp1
	push temp3

	lds temp1, num_stations
	cp temp2, temp1
	breq print_station_help_back_to_first

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
	jmp print_station_loop_help

print_station_help_back_to_first:
	ldi YL,  low(station_names)
	ldi Yh, high(station_names)

	ldi temp1, 0
print_station_loop_help:
	cpi temp1, 10
	breq print_station_done_help
	ld outp, Y+
	do_lcd_data_reg outp
	inc temp1
	jmp print_station_loop_help
print_station_done_help:
	pop temp3
	pop temp1
	pop outp
	ret


emulation_countdown:
	push temp
	push temp1
	do_lcd_command LCD_DISP_CLR
	rcall lcd_startemulation_placeholder
	do_lcd_data '1'
	do_lcd_data '0'
	rcall sleep_1000ms
	do_lcd_command LCD_DISP_CLR
	ldi temp, 9
countdownloop:
	cpi temp, 0
	breq countdown_finish
	rcall lcd_startemulation_placeholder
	mov temp1, temp
	subi temp1, -48
	do_lcd_data_reg temp1
	rcall sleep_1000ms
	do_lcd_command LCD_DISP_CLR
	dec temp
	jmp countdownloop
countdown_finish:
	pop temp1
	pop temp
	ret

print_traveltime_initialisation:
	push temp1
	push temp2
	push temp3
	rcall lcd_traveltime_placeholder ; This prints "Travel time:" FIRST LINE
	do_lcd_command LCD_SEC_LINE ; NEW LINE
	rcall lcd_station_placeholder2
	mov temp1, temp2 ; Get station number printing in keypad form
	inc temp1
	subi temp1, -48
	do_lcd_data_reg temp1
	do_lcd_data ' '
	do_lcd_data 't'
	do_lcd_data 'o'
	do_lcd_data ' '
	mov temp1, temp2 ; Get station number printing in keypad form
	inc temp1
	inc temp1

	lds temp3, num_stations
	inc temp3
	cp temp1, temp3
	brne print_traveltime_initialisation_not_on_last
	ldi temp1, 1 ;loop back from last station to first

print_traveltime_initialisation_not_on_last:
	subi temp1, -48
	do_lcd_data_reg temp1
	rcall sleep_5000ms
	pop temp3
	pop temp2
	pop temp1
	ret

num_station_to_word:
	push temp
	lds temp, num_stations
	cpi temp, 2
	breq two_to_word
	cpi temp, 3
	breq three_to_word
	cpi temp, 4
	breq four_to_word
	cpi temp, 5
	breq five_to_word
	cpi temp, 6
	breq six_to_word
	cpi temp, 7
	breq seven_to_word
	cpi temp, 8
	breq eight_to_word
	cpi temp, 9
	breq nine_to_word
	cpi temp, 10
	breq ten_to_word
two_to_word:
	rcall lcd_two
	jmp num_station_to_word_epilogue
three_to_word:
	rcall lcd_three
	jmp num_station_to_word_epilogue
four_to_word:
	rcall lcd_four
	jmp num_station_to_word_epilogue
five_to_word:
	rcall lcd_five
	jmp num_station_to_word_epilogue
six_to_word:
	rcall lcd_six
	jmp num_station_to_word_epilogue
seven_to_word:
	rcall lcd_seven
	jmp num_station_to_word_epilogue
eight_to_word:
	rcall lcd_eight
	jmp num_station_to_word_epilogue
nine_to_word:
	rcall lcd_nine
	jmp num_station_to_word_epilogue
ten_to_word:
	rcall lcd_ten
	jmp num_station_to_word_epilogue
num_station_to_word_epilogue:
	rcall lcd_station_placeholder
	pop temp
	ret

lcd_two:
	do_lcd_data 'T'
	do_lcd_data 'w'
	do_lcd_data 'o'
	ret
lcd_three:
	do_lcd_data 'T'
	do_lcd_data 'h'
	do_lcd_data 'r'
	do_lcd_data 'e'
	do_lcd_data 'e'
	ret
lcd_four:
	do_lcd_data 'F'
	do_lcd_data 'o'
	do_lcd_data 'u'
	do_lcd_data 'r'
	ret
lcd_five:
	do_lcd_data 'F'
	do_lcd_data 'i'
	do_lcd_data 'v'
	do_lcd_data 'e'
	ret
lcd_six:
	do_lcd_data 'S'
	do_lcd_data 'i'
	do_lcd_data 'x'
	ret
lcd_seven:
	do_lcd_data 'S'
	do_lcd_data 'e'
	do_lcd_data 'v'
	do_lcd_data 'e'
	do_lcd_data 'n'
	ret
lcd_eight:
	do_lcd_data 'E'
	do_lcd_data 'i'
	do_lcd_data 'g'
	do_lcd_data 'h'
	do_lcd_data 't'
	ret
lcd_nine:
	do_lcd_data 'N'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'e'
	ret
lcd_ten:
	do_lcd_data 'T'
	do_lcd_data 'e'
	do_lcd_data 'n'
	ret

lcd_station_placeholder:
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
	ret

lcd_traveltime_placeholder:
	do_lcd_data 'T'
	do_lcd_data 'r'
	do_lcd_data 'a'
	do_lcd_data 'v'
	do_lcd_data 'e'
	do_lcd_data 'l'
	do_lcd_data ' '
	do_lcd_data 't'
	do_lcd_data 'i'
	do_lcd_data 'm'
	do_lcd_data 'e'
	do_lcd_data ':'
	ret


lcd_stoptime_placeholder:
	do_lcd_data 'S'
	do_lcd_data 't'
	do_lcd_data 'o'
	do_lcd_data 'p'
	do_lcd_data ' '
	do_lcd_data 't'
	do_lcd_data 'i'
	do_lcd_data 'm'
	do_lcd_data 'e'
	do_lcd_data ':'
	ret

lcd_station_placeholder2:
	do_lcd_data 's'
	do_lcd_data 't'
	do_lcd_data 'a'
	do_lcd_data 't'
	do_lcd_data 'i'
	do_lcd_data 'o'
	do_lcd_data 'n'
	do_lcd_data ' '
	ret

lcd_seconds_placeholder:
	do_lcd_data ' '
	do_lcd_data 's'
	do_lcd_data 'e'
	do_lcd_data 'c'
	do_lcd_data 'o'
	do_lcd_data 'n'
	do_lcd_data 'd'
	do_lcd_data 's'
	ret	

lcd_pressanykey_placeholder:
	do_lcd_data 'P'
	do_lcd_data 'r'
	do_lcd_data 'e'
	do_lcd_data 's' ;4
	do_lcd_data 's'
	do_lcd_data ' '
	do_lcd_data 'a'
	do_lcd_data 'n' ;4
	do_lcd_data 'y'
	do_lcd_data ' '
	do_lcd_data 'k'
	do_lcd_data 'e' ;4
	do_lcd_data 'y'
	do_lcd_data ' '
	do_lcd_data 't'
	do_lcd_data 'o' ;4
	do_lcd_command LCD_SEC_LINE
	do_lcd_data 'c'
	do_lcd_data 'o'
	do_lcd_data 'n'
	do_lcd_data 'f' ;4
	do_lcd_data 'i'
	do_lcd_data 'r'
	do_lcd_data 'm'
	ret	

lcd_startemulation_placeholder:
	do_lcd_data 'M'
	do_lcd_data 'o'
	do_lcd_data 'n'
	do_lcd_data 'o' ;4
	do_lcd_data 'r'
	do_lcd_data 'a'
	do_lcd_data 'i'
	do_lcd_data 'l' ;4
	do_lcd_data ' '
	do_lcd_data 's'
	do_lcd_data 't'
	do_lcd_data 'a' ;4
	do_lcd_data 'r'
	do_lcd_data 't'
	do_lcd_data 's'
	do_lcd_command LCD_SEC_LINE
	do_lcd_data 'e'
	do_lcd_data 'm'
	do_lcd_data 'u'
	do_lcd_data 'l' ;4
	do_lcd_data 'a'
	do_lcd_data 't'
	do_lcd_data 'i'
	do_lcd_data 'o' ;4
	do_lcd_data 'n'
	do_lcd_data ' '
	do_lcd_data 'i'
	do_lcd_data 'n' ;4
	do_lcd_data ' '
	ret	