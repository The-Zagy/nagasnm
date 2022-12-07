STACK SEGMENT PARA STACK
	DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'
	
	WINDOW_WIDTH DW 280h                 	;the width of the window (320 pixels)
	WINDOW_HEIGHT DW 1E0h                	;the height of the window (200 pixels)
	PLAYER_POS_X DW 12Bh				 	;Position of the player's car on the x-axis
	PLAYER_POS_Y DW 1A0h					;Position of the player's car on the y-axis
	GRASS_BLOCK_WIDTH DW 0A0h
	GRASS_BLOCK_HEIGHT DW 1E0h
	PLAYER_CAR_WIDTH DW 020h
	PLAYER_CAR_HEIGHT DW 030h
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
		;set video mode
		MOV AH,00h ;set the configuration to video mode
		MOV AL,12h ;choose the video mode
		INT 10h    ;execute the configuration 
		
		MOV AH,0Bh ;set the configuration
		MOV BH,00h ;to the background color
		MOV BL,00h ;choose black as background color
		INT 10h    ;execute the configuration
		
		;------------------------------
		;Main game loop start
		CALL DRAW_PLAYER_CAR
		CALL DRAW_GRASS_BLOCKS
		;------------------------------			
		RET	
	MAIN ENDP
	
	
	CLEAR_SCREEN PROC NEAR               ;clear the screen by restarting the video mode
	
			MOV AH,00h                   ;set the configuration to video mode
			MOV AL,13h                   ;choose the video mode
			INT 10h    					 ;execute the configuration 
		
			MOV AH,0Bh 					 ;set the configuration
			MOV BH,00h 					 ;to the background color
			MOV BL,00h 					 ;choose black as background color
			INT 10h    					 ;execute the configuration
			
			RET
			
	CLEAR_SCREEN ENDP
	DRAW_PLAYER_CAR PROC NEAR
		MOV CX, PLAYER_POS_X 			;set the x-axis of the drawing cursor the x-axis position of the car
		MOV DX, PLAYER_POS_Y			;set the y-axis of the drawing cursor the y-axis position of the car
		DRAW_ROW:
			MOV AH, 0Ch 					;Set the config to video mode
			MOV AL, 04h 					;Choose the color (white)
			MOV BH, 00h 					;Page number (0) we'll never exceed this number anyways but it has to be set
			INT 10h                         ;Interupt video mode and execute the
			INC CX
			MOV AX, CX
			SUB AX, PLAYER_POS_X
			CMP AX, PLAYER_CAR_WIDTH
			JNG DRAW_ROW                     ; JUMP IF PLAYER_CAR_WIDTH > AX (current length of the row) meaning row hasn't finished yet\
			MOV CX, PLAYER_POS_X             ; Re-intialize x-axis 
			INC DX                           ; Up by on in the y-axis
			MOV AX, DX
			SUB AX, PLAYER_POS_Y
			CMP AX, PLAYER_CAR_HEIGHT
			JNG DRAW_ROW
		RET
	DRAW_GRASS_BLOCKS PROC NEAR
		MOV CX, 0h			;set the x-axis of the drawing cursor the x-axis position of the car
		MOV DX, 0h			;set the y-axis of the drawing cursor the y-axis position of the car
		MOV AH, 0Ch 					;Set the config to video mode
		MOV AL, 0Ah 					;Choose the color (green)
		MOV BH, 00h 					;Page number (0) we'll never exceed this number anyways but it has to be set
		DRAW_ROW_GRASS_ONE:
			INT 10h                         ;Interupt video mode and execute the
			INC CX
			CMP CX, GRASS_BLOCK_WIDTH
			JNG DRAW_ROW_GRASS_ONE                     ; JUMP IF PLAYER_CAR_WIDTH > AX (current length of the row) meaning row hasn't finished yet\
			MOV CX, 0             ; Re-intialize x-axis 
			INC DX                           ; Up by on in the y-axis
			CMP DX, GRASS_BLOCK_HEIGHT
			JNG DRAW_ROW_GRASS_ONE
		MOV DX, 0h			;set the y-axis of the drawing cursor the y-axis position of the car
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
	CONCLUDE_EXIT_GAME PROC NEAR         ;goes back to the text mode
		
		MOV AH,00h                   ;set the configuration to video mode
		MOV AL,02h                   ;choose the video mode
		INT 10h    		     ;execute the configuration 
		MOV AH,4Ch                   ;terminate program
		INT 21h

	CONCLUDE_EXIT_GAME ENDP

CODE ENDS
END