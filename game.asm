STACK SEGMENT PARA STACK
	DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'
	
	WINDOW_WIDTH DW 0140h                 	;the width of the window (320 pixels)
	WINDOW_HEIGHT DW 00C8h                	;the height of the window (200 pixels)
	CAR_POS_X DW ?				 			;Position of the player's car on the x-axis
	CAR_POS_Y DW ?							;Position of the player's car on the y-axis
	CAR_DX DW ?
	CAR_DY DW ?
	FLIP DB 0
	COLOR DB ?
	GRASS_BLOCK_WIDTH DW 0030h
	GRASS_BLOCK_HEIGHT DW 00C8h
	PLAYER_CAR_WIDTH DW 020h
	PLAYER_CAR_HEIGHT DW 030h
	DELAY_TIME DW 2710h
	TIME_AUX DB 0                        	;variable used when checking if the time has changed
	SCORE DB 0                    	     	;(current Score)
	CURRENT_SCENE DB 0                   	;the index of the current scene (0, main menu) (1,currently playing) (2,gameover)

DATA ENDS

CODE SEGMENT PARA 'CODE'

	MAIN PROC FAR
		;------------------------------
		ASSUME CS:CODE,DS:DATA,SS:STACK      ;assume as code,data and stack segments the respective registers
		PUSH DS                              ;push to the stack the DS segment
		SUB AX,AX                            ;clean the AX register
		PUSH AX                              ;push AX to the stack
		MOV AX,DATA                          ;save on the AX register the contents of the DATA segment
		MOV DS,AX                            ;save on the DS segment the contents of AX
		POP AX                               ;release the top item from the stack to the AX register
		POP AX                               ;release the top item from the stack to the AX register
		;------------------------------

		CALL SET_SCREEN
		CALL DRAW_GRASS_BLOCKS
		CALL FRAME_1

		;------------------------------
		;Main game loop start
		GAME_LOOP:
			;get current system time  [CH = hour, CL = minute, DH = seconds, DL = 1/100 sec]
			MOV AH,2Ch	
			INT 21h
			CMP DL, TIME_AUX				
			JNE EXE
			JE GAME_LOOP	

			EXE:
				MOV TIME_AUX, DL
				CALL DRAW_CARS
				JMP GAME_LOOP
		;-----------------------------			
		
		RET	
	MAIN ENDP
	
	SET_SCREEN PROC NEAR         
		MOV AH,00h 						 ;set the configuration to video mode
		MOV AL,13h 						 ;choose the video mode
		INT 10h    						 ;execute the configuration 
								
		MOV AH,0Bh 						 ;set the configuration
		MOV BH,00h 						 ;to the background color
		MOV BL,00h 						 ;choose black as background color
		INT 10h    						 ;execute the configuration

		RET
	SET_SCREEN ENDP
	
	DRAW_PLAYER_CAR PROC NEAR
		MOV CX, CAR_POS_X 			;set the x-axis of the drawing cursor the x-axis position of the car
		MOV DX, CAR_POS_Y			;set the y-axis of the drawing cursor the y-axis position of the car
		DRAW_ROW:
			MOV AH, 0Ch 					;Set the config to write graphics pixel
			MOV AL, COLOR 					;Choose the color (red)
			MOV BH, 00h 					;Page number (0) we'll never exceed this number anyways but it has to be set
			INT 10h                         ;Interupt video mode and execute 
			INC CX
			MOV AX, CX
			SUB AX, CAR_POS_X
			CMP AX, PLAYER_CAR_WIDTH
			JNG DRAW_ROW                     ; JUMP IF PLAYER_CAR_WIDTH > AX (current length of the row) meaning row hasn't finished yet\			
			MOV CX, CAR_POS_X             ; Re-intialize x-axis 
			INC DX                           ; Up by on in the y-axis
			MOV AX, DX
			SUB AX, CAR_POS_Y
			CMP AX, PLAYER_CAR_HEIGHT
			JNG DRAW_ROW
		RET
	DRAW_PLAYER_CAR ENDP

	DRAW_CARS PROC NEAR
		CMP FLIP, 00h
		JE f1
		JNE f2
		f1:
			MOV COLOR, 00h 						;set color to black
			CALL FRAME_2
			CALL DELAY
			MOV COLOR, 04h						;set color to red
			CALL FRAME_1
			XOR FLIP, 1
		f2:
			MOV COLOR, 00h
			CALL FRAME_1
			CALL DELAY
			MOV COLOR, 04h 
			CALL FRAME_2
			XOR FLIP, 1
		RET
	DRAW_CARS ENDP

	FRAME_1 PROC NEAR
		MOV CAR_POS_X, 90h
		MOV CAR_POS_Y, 98h
		CALL DRAW_PLAYER_CAR

		MOV CAR_DX, 0FFBAh
		MOV CAR_DY, 60h
		CALL SET_CAR_POS
		CALL DRAW_PLAYER_CAR
		CALL RESET_CAR_POS

		MOV CAR_DX, 40h
		MOV CAR_DY, 80h
		CALL SET_CAR_POS
		CALL DRAW_PLAYER_CAR
		CALL RESET_CAR_POS
		RET
	FRAME_1 ENDP

	FRAME_2 PROC NEAR
		MOV CAR_POS_X, 90h
		MOV CAR_POS_Y, 0Eh
		CALL DRAW_PLAYER_CAR

		MOV CAR_DX, 0FFBAh
		MOV CAR_DY, 0FF81h
		CALL SET_CAR_POS
		CALL DRAW_PLAYER_CAR
		CALL RESET_CAR_POS

		MOV CAR_DX, 40h
		MOV CAR_DY, 0FFA1h
		CALL SET_CAR_POS
		CALL DRAW_PLAYER_CAR
		CALL RESET_CAR_POS
		RET
	FRAME_2 ENDP

	DELAY PROC NEAR
		MOV AX, DELAY_TIME
		RP:
			DEC AX
			CMP AX,0
			JNE RP
		RET
	DELAY ENDP

	SET_CAR_POS PROC NEAR
		MOV AX, CAR_DX
		ADD CAR_POS_X, AX

		MOV AX, CAR_DY
		SUB CAR_POS_Y, AX

		RET
	SET_CAR_POS ENDP

	RESET_CAR_POS PROC NEAR
		MOV AX, CAR_DX
		SUB CAR_POS_X, AX

		MOV AX, CAR_DY
		ADD CAR_POS_Y, AX

		RET
	RESET_CAR_POS ENDP
	
	DRAW_GRASS_BLOCKS PROC NEAR
		MOV CX, 0						;set the x-axis of the drawing cursor the x-axis position of the car
		MOV DX, 0						;set the y-axis of the drawing cursor the y-axis position of the car
		MOV AH, 0Ch 					;Set the config to video mode
		MOV AL, 0Ah 					;Choose the color (green)
		MOV BH, 00h 					;Page number (0) we'll never exceed this number anyways but it has to be set
		DRAW_ROW_GRASS_ONE:
			INT 10h                     ;Interupt video mode and execute
			INC CX
			CMP CX, GRASS_BLOCK_WIDTH
			JNG DRAW_ROW_GRASS_ONE                      ; JUMP IF GRASS_BLOCK_WIDTH > CX (current length of the row) meaning row hasn't finished yet\
			MOV CX, 0             						; Re-intialize x-axis 
			INC DX                           			; Up by on in the y-axis
			CMP DX, GRASS_BLOCK_HEIGHT
			JNG DRAW_ROW_GRASS_ONE
		MOV DX, 0						;set the y-axis of the drawing cursor the y-axis position of the car
		MOV CX, WINDOW_WIDTH
		SUB CX, GRASS_BLOCK_WIDTH
		DRAW_ROW_GRASS_TWO:
			INT 10h                       
			INC CX
			CMP CX, WINDOW_WIDTH
			JNG DRAW_ROW_GRASS_TWO                
			MOV CX, WINDOW_WIDTH
			SUB CX, GRASS_BLOCK_WIDTH    
			INC DX                           
			CMP DX, GRASS_BLOCK_HEIGHT
			JNG DRAW_ROW_GRASS_TWO
		RET
	DRAW_GRASS_BLOCKS ENDP

	CONCLUDE_EXIT_GAME PROC NEAR     ;goes back to the text mode

		MOV AH,00h                   ;set the configuration to video mode
		MOV AL,02h                   ;choose the video mode
		INT 10h    		     		 ;execute the configuration 
		MOV AH,4Ch                   ;terminate program
		INT 21h

	CONCLUDE_EXIT_GAME ENDP

CODE ENDS
END