; Keypad
.def outp =r16
.def row =r17
.def col =r18
.def mask =r19
.def temp2 =r20
; General
.def temp=r21
.def temp1 = r22
.def temp3 = r23
.def numberL=r24
.def numberH = r25
; Keypad Variables
.equ PORTLDIR = 0xF0
.equ INITCOLMASK = 0xEF
.equ INITROWMASK = 0x01
.equ ROWMASK = 0x0F
; LCD Settings
.set LCD_DISP_ON = 0b00001110
.set LCD_DISP_OFF = 0b00001000
.set LCD_DISP_CLR = 0b00000001
.set LCD_FUNC_SET = 0b00111000 		; 2 lines, 5 by 7 characters
.set LCD_ENTR_SET = 0b00000110 		; increment, no display shift
.set LCD_HOME_LINE = 0b10000000 	; goes to 1st line (address 0)
.set LCD_SEC_LINE = 0b10101000 		; goes to 2nd line (address 40)
; LCD Macros
.macro do_lcd_command
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro
.macro do_lcd_command_reg
	mov r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro
.macro do_lcd_data
	ldi r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro
.macro do_lcd_data_reg
	mov r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro
.macro lcd_set
	sbi PORTA, @0
.endmacro
.macro lcd_clr
	cbi PORTA, @0
.endmacro
.macro clearTempCounter ; The macro clears a word (2 bytes) in the data memory The parameter @0 is the memory address for that word
	ldi YL, low(@0) ; load the memory address to Y pointer
	ldi YH, high(@0)
	clr temp ; set temp to 0
	st Y+, temp ; clear the two bytes at @0 in SRAM
	st Y, temp
.endmacro

.dseg
.org 0x200
	;Designate space for variables and data
	SecondCounter: .byte 2
	TempCounter: .byte 2
	button_flag: .byte 1
	num_stations: .byte 1
	station_names: .byte 100
	time_travel: .byte 10
	time_stop: .byte 1
	tourist_on: .byte 1
	tourist_off: .byte 1
	tourist_count: .byte 1
	currRPS: .byte 1
	holes: .byte 1
	targetRPS: .byte 1
	next_station: .byte 1
	monorail_stop_move: .byte 1
	thirdofsecond_passed: .byte 1
	seconds_passed: .byte 1
	currtime_to_nextstation: .byte 1
	order_to_stop: .byte 1


