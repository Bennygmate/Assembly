initialise_keypad:
	push temp1; prolouge

	ldi temp1, PORTLDIR ; columns are outputs, rows are inputs
	STS DDRL, temp1     ; cannot use out
	ser temp1

	pop temp1 ; epilouge
	ret

; Keeps scanning the keypad until any key is pressed and returns the value of that key
keypad_scan: 
	ldi mask, INITCOLMASK ; initial column mask
	clr col ; initial column
colloop:
	STS PORTL, mask ; set column to mask value (sets column 0 off)
	ldi temp, 0xFF ; implement a delay so the hardware can stabilize
delay:
	dec temp
	brne delay
	LDS temp, PINL ; read PORTL. Cannot use in 
	andi temp, ROWMASK ; read only the row bits
	cpi temp, 0xF ; check if any rows are grounded
	breq nextcol ; if not go to the next column
	ldi mask, INITROWMASK ; initialise row check
	clr row ; initial row
rowloop:      
	mov temp2, temp
	and temp2, mask ; check masked bit
	brne skipconv ; if the result is non-zero, we need to look again
	jmp convert ; if bit is clear, convert the bitcode
	jmp keypad_scan ; and start again
skipconv:
	inc row ; else move to the next row
	lsl mask ; shift the mask to the next bit
	jmp rowloop          
nextcol:     
	cpi col, 3 ; check if we're on the last column
	breq keypad_scan ; if so, no buttons were pushed, so start again.
	sec ; else shift the column mask: We must set the carry bit
	rol mask ; and then rotate left by a bit, shifting the carry into
	; bit zero. We need this to make sure all the rows have pull-up resistors
	inc col ; increment column value
	jmp colloop ; and check the next column
; convert function converts the row and column given to a binary number and also outputs the value to PORTC.
; Inputs come from registers row and col and output is in temp.
convert:
	cpi col, 3 ; if column is 3 we have a letter
	breq letters
	cpi row, 3 ; if row is 3 we have a symbol or 0
	breq symbols

number: ; otherwise we have a number (1-9)
	mov outp, row 
	lsl outp ; temp = row * 2
	add outp, row ; temp = row * 3
	add outp, col ; add the column address to get the offset from 1
	inc outp ; add 1. Value of switch is row*3 + col + 1.
	jmp convert_end
letters:
	ldi outp, 0x11 ; 17 (+ 1) (+ 1) -- 48
	add outp, row ; increment from 0xA by the row value
	jmp convert_end
symbols:
	cpi col, 0 ; check if we have a star
	breq star
	cpi col, 1 ; or if we have zero
	breq zero
	ldi outp, 0xF3 ; we'll output 0xF for hash (0XF3 - 243 --48 = 291 (35))
	jmp convert_end
star:
	ldi outp, 0xFA ; we'll output 0xE for star (same process)
	jmp convert_end
zero:
	clr outp ; set to zero
convert_end:
	subi outp, -48 ; '0'
Wait:
	LDS temp2, PINL ; read PORTL. Cannot use in
	andi temp2, ROWMASK ; read only the row bits 
	and temp2, mask ; check masked bit
	breq Wait ; if the result is non-zero,
	ret


;Keeps reading the keypad until either special key D is pressed or an input_error occurs
read_character:
	clr outp ; prolouge
	clr numberL
read_character_loop1:
	rcall keypad_scan
	cpi outp, '*' ; invalid input
	breq input_error
	cpi outp, '#' ; whitespace
	breq read_character_white_space
	cpi outp, 'A' ; invalid input
	breq input_error
	cpi outp, 'B' ; invalid input
	breq input_error
	cpi outp, 'C' ; invalid input
	breq input_error
	cpi outp, 'D' ; character submit
	breq read_character_submit

	;multiply by 10 incase of multiple digits
	ldi temp, 10
	mul numberL, temp
	mov numberL, r0
	add numberL, outp
	subi numberL, 48 ; since keypad_scan returns '1' instead of 1 we need to adjust
	cpi numberL, 27 ; max character is 26 ('Z') if we've exceeded this its an invalid input
	brge input_error 

	jmp read_character_loop1
read_character_white_space:
	ldi outp, ' ' ; return whitespace
	ret
read_character_submit:
	mov outp, numberL
	subi outp, -64	;converts from number to character. 1 -> A etc
	ret



input_error: ; invalid input entered
	rcall print_incorrect_input ;lcd.asm
	rjmp halt


read_station_number: ; gets input for the number of stations
	push temp1
	rcall lcd_output_one ; Output: "Type the max num of stations: "
	clr numberL
read_station_number_loop:
	rcall keypad_scan; waits for keypad input and returns character
	cpi outp, '*' ; invalid input
	breq input_error
	cpi outp, '#' ; invalid input
	breq input_error
	cpi outp, 'A' ; invalid input
	breq input_error
	cpi outp, 'B' ; invalid input
	breq input_error
	cpi outp, 'C' ; invalid input
	breq input_error
	cpi outp, 'D' ; station_number submit
	breq read_station_number_check_limit_high

	do_lcd_data_reg outp ; write current input to lcd

	;multiply by 10 incase of multiple digits
	ldi temp, 10
	mul numberL, temp
	mov numberL, r0
	mov numberH, r1
	mov temp1, outp
	subi temp1, 48
	add numberL, temp1
	clr temp1
	adc numberH, temp1

	;if three digits are entered, invalid input
	cpi numberH, 0
	brne input_error
	cpi numberL, 100
	brge input_error
	
	;if negative number, invalid input (should not be possible)
	cpi numberL, 0
	brlt input_error

	jmp read_station_number_loop ; read next digit

read_station_number_check_limit_high: ; if number of stations is greater than upper limit (10) 
	cpi numberL, 11						
	brlt read_station_number_check_limit_low
	ldi numberL, 10		; set to upper limit (10)
read_station_number_check_limit_low: ; if number of stations is lower than lower limit (2)
	cpi numberL, 2
	brge read_station_number_submit
	ldi numberL, 2		; set to lower limit (2)
read_station_number_submit:
	mov outp, numberL ; return station_number
	pop temp1	;prolouge
	ret


	

read_station_names: ; gets input for the name of a stations
	ldi temp2, 0

read_station_names_loop:
	lds numberL, num_stations ; repeats once for each required station
	cp temp2, numberL
	breq read_stations_names_done ; if we've reached the limit move to the prolouge

	; Find the station name place in the station_names memory block
	mov temp3, temp2
	ldi temp1, 10	
	mul temp3, temp1	;each name is 10 charcters long
	mov temp3, r0
	mov YL, r0
	clr YH
	ldi temp1, low(station_names)
	add YL, temp1
	ldi temp1, high(station_names)
	adc YH, temp1

	; write "Name of station (newline)"
	do_lcd_command LCD_DISP_CLR
	rcall lcd_output_two

	; Write current station number
	subi temp2, -49
	do_lcd_data_reg temp2
	subi temp2, 49
	do_lcd_data ':'
	rcall read_station_name ; reads input and stroes 10 character station name

	; Write "Name of station (i) is: "
	rcall print_namestation
	; Write station name
	rcall print_station

	inc temp2 ; move to next station
	jmp read_station_names_loop

read_stations_names_done: ; epilogue
	ret



read_station_name: ; read charcter inputs and store in the station_names memory block
	push temp1 ; prolouge
	push temp2
	ldi temp1, 0
read_station_name_loop: ; loops through 10 characters
	cpi temp1, 10
	breq read_station_name_done ; Automatically submit when charcter limit is reached
	rcall read_character ; read a single character
	cpi outp, 64 ; Check for name submit
	breq read_station_name_fill_white_space
	do_lcd_data_reg outp ; write inputed character to screen
	st Y+, outp ; store inputed charcter
	inc temp1 ; move to next character
	jmp read_station_name_loop
read_station_name_fill_white_space: ; if inputed name is less than 10 character the rest are filled with whitespace
	cpi temp1, 10
	breq read_station_name_done
	ldi temp2, ' '
	st Y+, temp2
	inc temp1
	jmp read_station_name_fill_white_space

read_station_name_done: ; epilogue
	pop temp2
	pop temp1
	ret





read_travel_times: ; read the time to travel between stations
	push temp1 ; prologue
	ldi temp2, 2

read_travel_times_loop:
	lds numberL, num_stations 
	cp numberL, temp2
	brlt timelast_1 			; Check if upto the last station
	ldi YL,  low(time_travel)	; Setup Y to point to the correct position in the travel_times block
	mov temp1, temp2
	subi temp1, 2
	add YL, temp1
	ldi YH, high(time_travel)
	clr temp1
	adc YH, temp1

	;Write "Time from station (i) to (i+1) is:"
	do_lcd_command LCD_DISP_CLR
	rcall lcd_output_three
	mov temp1, temp2
	subi temp1, -47
	do_lcd_data_reg temp1
	do_lcd_data ' '
	do_lcd_data 't'
	do_lcd_data 'o'
	do_lcd_data ' '
	mov temp1, temp2
	subi temp1, -48
	do_lcd_data_reg temp1
	do_lcd_data ' '
	do_lcd_data 'i'
	do_lcd_data 's'
	do_lcd_data ':'
	rcall read_travel_time ; Read the travel time
	st Y, outp ; write travel_time to memory

	inc temp2 ; move to next station
	jmp read_travel_times_loop

timelast_1: ; Special handling is required for the last station
	ldi YL,  low(time_travel) + 9 ; Always stored in the last byte in the block
	ldi YH, high(time_travel) + 9

	; Write "Time from station (i) to 1 is: "
	do_lcd_command LCD_DISP_CLR
	rcall lcd_output_three
	lds temp1, num_stations
	subi temp1, -48
	do_lcd_data_reg temp1
	do_lcd_data ' '
	do_lcd_data 't'
	do_lcd_data 'o'
	do_lcd_data ' '
	do_lcd_data '1'
	do_lcd_data ' '
	do_lcd_data 'i'
	do_lcd_data 's'
	do_lcd_data ':'
	rcall read_travel_time ; Read travel_time
	st Y, outp ; store travel_time

	pop temp1 ; epilogue
	ret




read_travel_time: ; read singular travel_time
	push temp	;prolouge
	push temp2
	clr numberL
read_travel_time_loop:
	rcall keypad_scan; waits for keypad input and returns character
	cpi outp, '*'	;invalid input
	breq input_error2
	cpi outp, '#'	;invalid input
	breq input_error2
	cpi outp, 'A'	;invalid input
	breq input_error2
	cpi outp, 'B'	;invalid input
	breq input_error2
	cpi outp, 'C'	;invalid input
	breq input_error2
	cpi outp, 'D'	;submit
	breq read_travel_time_check_limit_high

	do_lcd_data_reg outp ; write current input

	; multiply by 10 incase of multiple digits
	ldi temp, 10
	mul numberL, temp
	mov numberL, r0
	mov numberH, r1
	mov temp1, outp
	subi temp1, 48
	add numberL, temp1
	clr temp1
	adc numberH, temp1

	; if number has three digits or is negative -> invalid input
	cpi numberH, 0
	brne input_error2
	cpi numberL, 100
	brge input_error2
	cpi numberL, 0
	brlt input_error2

	jmp read_travel_time_loop

read_travel_time_check_limit_high: ; if travel time is greater than 10 
	cpi numberL, 11
	brlt read_travel_time_check_limit_low
	ldi numberL, 10						; set to 10
read_travel_time_check_limit_low: ; if travel time is less than 1
	cpi numberL, 1
	brge read_travel_time_submit
	ldi numberL, 1						;set to 1
read_travel_time_submit:
	mov outp, numberL ; output read number
	pop temp2	;epilogue
	pop temp
	ret

	
input_error2: ; write "Invalid input"
	rcall print_incorrect_input
	rjmp halt

read_stop_time: ; read the time spent stopped at each station
	ldi YL,  low(time_stop)
	ldi YH, high(time_stop)
	do_lcd_command LCD_DISP_CLR
	rcall lcd_output_four

	clr numberL
read_stop_time_loop:
	rcall keypad_scan; waits for keypad input and returns character
	cpi outp, '*' ; invalid input
	breq input_error2
	cpi outp, '#' ; invalid input
	breq input_error2
	cpi outp, 'A' ; invalid input
	breq input_error2
	cpi outp, 'B' ; invalid input
	breq input_error2
	cpi outp, 'C' ; invalid input
	breq input_error2
	cpi outp, 'D' ; submit input
	breq read_stop_time_check_limit_high

	do_lcd_data_reg outp ; write current input to lcd

	; multiply by 10 incase of multiple digits
	ldi temp, 10
	mul numberL, temp
	mov numberL, r0
	mov numberH, r1
	mov temp1, outp
	subi temp1, 48
	add numberL, temp1
	clr temp1
	adc numberH, temp1

	; if number has three digits or is negative -> invalid input
	cpi numberH, 0
	brne input_error2
	cpi numberL, 100
	brge input_error2
	cpi numberL, 0
	brlt input_error2

	jmp read_stop_time_loop ; read next digit

read_stop_time_check_limit_high: ; if travel time is greater than 5 
	cpi numberL, 6
	brlt read_stop_time_check_limit_low
	ldi numberL, 5					; set to 5
read_stop_time_check_limit_low:	 ; if travel time is less than 2
	cpi numberL, 2
	brge read_stop_time_submit
	ldi numberL, 2					; set to 2
read_stop_time_submit:
	mov outp, numberL

	st Y, outp	; retutn input
	ret