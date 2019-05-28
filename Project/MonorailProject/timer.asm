initialise_timer:
	push temp1

	; initialise variables
	clr temp1
	sts TempCounter, temp1 			; initialise temporary counter to 0
	sts TempCounter + 1, temp1
	sts SecondCounter, temp1 		; initialise second counter to 0
	sts SecondCounter + 1, temp1
	ldi temp1, 1 << TOIE0 	; enable timer
	sts TIMSK0, temp1
	
	clr r24
	clr r25

	pop temp1
	ret

increment_secondpassed:
	push temp
	push temp1
	lds temp, monorail_stop_move
	cpi temp, 2 ; 2 MEANS STOPPED BETWEEN SO DONT ADD
	breq secondpassed_epilogue
	lds temp, thirdofsecond_passed
	inc temp
	sts thirdofsecond_passed, temp
secondpassed_epilogue:
	rcall convert_to_seconds
	pop temp1
	pop temp
	ret

check_order_stop:
	push temp
	push temp1
	lds temp, order_to_stop
	cpi temp, 2 ; 2 MEANS MOVE ORDER
	breq order_start_moving_again
	cpi temp, 1 ; ORDERED TO STOP
	breq order_stop_initiate
	; NO ORDER OTHERWISE 0 
	jmp check_order_stop_epilogue
order_start_moving_again:
	rcall start_moving_again_variable
	jmp check_order_stop_epilogue
order_stop_initiate:
	rcall check_order_stop_initiate
check_order_stop_epilogue:
	pop temp1
	pop temp
	ret	
	
check_order_stop_initiate: ; ORDERED TO STOP 
	push temp
	push temp1
	push temp2
	clr temp1
	lds temp, thirdofsecond_passed
loop_full_second: ; CHECK SECONDS
	cpi temp, 3
	brlo check_second_finish ; SECOND INTERVAL
	subi temp, 3
	inc temp1 ; THIS WILL HAVE SECOND
	jmp loop_full_second
check_second_finish:
	cpi temp, 0 ; TEMP HOLDS REMAINER
	breq check_next_sec_station ; IF SECOND IT CAN STOP if not arrive at next station
	jmp check_order_stop_initiate_epilogue ; MEANS NOT SECOND INTERVAL CHECK LATER
check_next_sec_station:
	; CHECK IF NEXT SECOND IS NEXT STATION
	lds temp2, currtime_to_nextstation
	cp temp1, temp2 ;SECONDS PASSED VS CURR TIME TO NEXT
	brlo order_monorail_to_stop ; IF LOWER CAN STOP
	jmp next_sec_station_reset	
order_monorail_to_stop:
	rcall stop_between_variable
	jmp check_order_stop_initiate_epilogue
next_sec_station_reset:
	clr temp
	sts order_to_stop, temp ; THE ORDER IS VOID BECAUSE NEXT STATION ALREADY REACHED
check_order_stop_initiate_epilogue:
	pop temp2
	pop temp1
	pop temp
	ret

stop_between_variable:
	push temp
	push temp1
	clr temp
	sts targetRPS, temp ; TRPS 0
	sts order_to_stop, temp ; NO ORDER ANYMORE
	ldi temp, 2
	sts monorail_stop_move, temp ; 2 MEANS STOPPED BETWEEN
	; UPDATE CURRTIME_TO_NEXT_STATION
	; CURRTIME = CURRTIME - SECOND_PASSED
	;lds temp, currtime_to_nextstation
	;lds temp1, seconds_passed
	;sub temp, temp1
	;sts currtime_to_nextstation, temp
	pop temp1
	pop temp
	ret

start_moving_again_variable:
	push temp
	ldi temp, 60
	sts targetRPS, temp
	ldi temp, 1
	sts monorail_stop_move, temp ; 1 MEANS MOVING AGAIN
	clr temp
	sts order_to_stop, temp ; NO ORDER ANYMORE
	pop temp
	ret

stop_station: ; CHECK IF STOPPED AT STATION
	push temp
	lds temp, monorail_stop_move
	cpi temp, 1 ; 1 MEANS MOVING
	breq stop_station_epilogue
	cpi temp, 2 ; 2 MEANS BETWEEN STATIONS
	breq stop_station_epilogue
	lds temp, time_stop ; ELSE IT IS 0 and STOPPED
	lds temp1, seconds_passed
	cp temp, temp1
	breq stop_ended
	jmp stop_station_epilogue
stop_ended:
	ldi temp, 60
	sts targetRPS, temp
	ldi temp, 1
	sts monorail_stop_move, temp ; MOVING
	clr temp
	sts thirdofsecond_passed, temp
	sts seconds_passed, temp
stop_station_epilogue:
	pop temp
	ret

update_station:
	push temp
	push temp1
	lds temp, monorail_stop_move ; IF STOPPED IGNORE
	cpi temp, 0
	breq update_station_epilogue
	cpi temp, 2 ; IF STOPPED BETWEEN STATIONS IGNORE
	breq update_station_epilogue
check_reach_station:
	lds temp, currtime_to_nextstation
	lds temp1, seconds_passed
	cp temp1, temp
	breq station_reached
	jmp update_station_epilogue
station_reached:
	; UPDATE NEXT STATION
	rcall update_next_station
	clr temp
	sts monorail_stop_move, temp ; MONORAIL STOP
	sts thirdofsecond_passed, temp
	sts seconds_passed, temp
	rcall update_station_time ; will update curr time to next station later
	; UPDATE TOURIST
	lds temp, tourist_on
	lds temp1, tourist_count
	add temp1, temp
	lds temp, tourist_off
	sub temp1, temp
	sts tourist_count, temp1
	clr temp
	sts tourist_on, temp
	sts tourist_off, temp
	; MAKE MOTOR STOP
	sts targetRPS, temp
update_station_epilogue:
	pop temp1
	pop temp
	ret

update_next_station:
	push temp
	push temp1
	lds temp, next_station
	lds temp1, num_stations
	cp temp, temp1 ; IF NEXT_STATION IS ALREADY LAST MAKE FIRST
	breq next_is_first
	inc temp
	jmp update_next_station_epilogue
next_is_first:
	ldi temp, 1
update_next_station_epilogue:
	sts next_station, temp
	pop temp1
	pop temp
	ret

convert_to_seconds:
	push temp
	push temp1
	clr temp1
	lds temp, thirdofsecond_passed
	cpi temp, 3
	brlo seconds_epilogue
find_seconds:
	subi temp, 3
	inc temp1 ; temp1 holds seconds
	cpi temp, 3
	brlo seconds_epilogue
	jmp find_seconds	
seconds_epilogue:
	sts seconds_passed, temp1
	pop temp1
	pop temp
	ret


update_station_time:
	push temp
	push temp1
	lds temp, next_station ; This is real number e.g. initially it will be 1

	lds temp1, num_stations 
	cp temp, temp1
	breq update_station_time_last

	ldi yl, low(time_travel)
	ldi yh, high(time_travel)
	
	ldi temp1, 1
update_station_time_loop:
	ld outp, y+
	cp temp1, temp
	breq update_station_time_done
	inc temp1
	jmp update_station_time_loop

update_station_time_last:
	ldi yl, low(time_travel) + 9
	ldi yh, high(time_travel) + 9
	ld outp, y
update_station_time_done:
	sts	currtime_to_nextstation, outp; INSERT THE VALUE FOUND

	pop temp1
	pop temp
	ret