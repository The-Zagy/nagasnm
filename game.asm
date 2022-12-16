STACK SEGMENT PARA STACK
	DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'
	
	WINDOW_WIDTH DW 0140h                 	;the width of the window (320 pixels)
	WINDOW_HEIGHT DW 00C8h                	;the height of the window (200 pixels)
	
	; general variables to DRAW PROC
    POS_X DW ?				 			    ;Position on the x-axis
	POS_Y DW ?							    ;Position on the y-axis
	DRAW_WIDTH DW ?
    DRAW_HEIGHT DW ?
    COLOR DB ?   

	CAR_POS_X DW ?				 			;Position of the player's car on the x-axis
	CAR_POS_Y DW ?							;Position of the player's car on the y-axis
	PLAYER_CAR_WIDTH DW 010h
	PLAYER_CAR_HEIGHT DW 020h
	PLAYER_CAR_VELOCITY DW 08H
	GRASS_BLOCK_WIDTH DW 0030h
	GRASS_BLOCK_HEIGHT DW 00C8h
	STONE_SIZE DW 0004h
    STONE_1_X DW 0040h
    STONE_1_Y DW 0007h
    STONE_2_X DW 0100h
    STONE_2_Y DW 0007h
    STONE_3_X DW 0090h
    STONE_3_Y DW 0007h
    STONE_1_VELOCITY DW 0004h
    STONE_2_VELOCITY DW 0006h
    STONE_3_VELOCITY DW 0003h
	   

	TIME_AUX DB 0                        	;variable used when checking if the time has changed
	SCORE DB '0','$'                  	     	;(current Score)
	TEXT_GAME_OVER_TITLE DB 'GAME OVER','$' ;text with the game over menu title
	TEXT_GAME_OVER_PLAY_AGAIN DB 'Press R to play again','$' ;text with the game over play again message
	TEXT_SCORE DB 'SCORE','$' ;text with the game over menu title
	POINTS DB 03h
	GAME_ACTIVE DB 01h                     ;is the game active? (1 -> Yes, 0 -> No (game over))	
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
		
		
		;draw stones
        MOV COLOR, 0Fh
        CALL STONES
		
        CALL DRAW_CAR


		;------------------------------
		; Main game loop start
		GAME_LOOP:

			CMP GAME_ACTIVE,00h
			JE SHOW_GAME_OVER

			;get current system time  [CH = hour, CL = minute, DH = seconds, DL = 1/100 sec]
			MOV AH,2Ch	
			INT 21h
			CMP DL, TIME_AUX				
			JE GAME_LOOP	

			MOV TIME_AUX, DL ;update time
            MOV COLOR, 00h
			
            CALL STONES
			CALL RAND_STONES
			CALL DRAW_UI
            CALL MOVE_CAR
			CALL COLLION_STONES
			;CALL UPDATE_SCORE
			JMP GAME_LOOP
			SHOW_GAME_OVER:
				CALL DRAW_GAME_OVER_MENU
				CALL SET_SCREEN
				CALL DRAW_GRASS_BLOCKS
				CALL DRAW_CAR
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
	
    DRAW PROC NEAR
        MOV CX, POS_X       ;set the x-axis of the drawing cursor the x-axis position
        MOV DX, POS_Y       ;set the y-axis of the drawing cursor the y-axis position
        REPEAT:
			MOV AH, 0Ch 					;Set the config to write graphics pixel
			MOV AL, COLOR 					;Choose the color
			MOV BH, 00h 					;Page number (0) we'll never exceed this number anyways but it has to be set
			INT 10h                         ;Interupt video mode and execute 
            INC CX
            MOV AX, CX
            SUB AX, POS_X
            CMP AX, DRAW_WIDTH
            JNG REPEAT
            MOV CX, POS_X
            INC DX
            MOV AX, DX
            SUB AX, POS_Y
            CMP AX, DRAW_HEIGHT
			
            JNG REPEAT
        RET
    DRAW ENDP

	DRAW_CAR PROC NEAR
 		; draw player's car
        MOV CAR_POS_X, 90h
        MOV CAR_POS_Y, 98h
        MOV COLOR, 04h
        MOV AX, PLAYER_CAR_WIDTH
        MOV DRAW_WIDTH, AX
        MOV AX, PLAYER_CAR_HEIGHT
        MOV DRAW_HEIGHT, AX
        MOV AX, CAR_POS_X
		MOV POS_X, AX
        MOV AX, CAR_POS_Y
		MOV POS_Y, AX
		CALL DRAW
	RET
	DRAW_CAR ENDP

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

	DRAW_UI PROC NEAR
		MOV AH,02h                       ;set cursor position
		MOV BH,00h                       ;set page number
		MOV DH,001h                       ;set row 
		MOV DL,019h						 ;set column
		MOV BL,00h
		MOV AL, 04h 
		INT 10h							 
		MOV AH,09h                       ;WRITE STRING TO STANDARD OUTPUT
		LEA DX,TEXT_SCORE    ;give DX a pointer to the string TEXT_PLAYER_POINTS
		INT 21h 
		MOV AX,15
		CALL PRINT_NUMBER
		RET
	DRAW_UI ENDP

	

	; function to remove player car by replacing it with black
	RESET_PLAYER_CAR PROC NEAR
		MOV COLOR, 00H ; set color to black then draw player car
		MOV AX, PLAYER_CAR_WIDTH
        MOV DRAW_WIDTH, AX
        MOV AX, PLAYER_CAR_HEIGHT
        MOV DRAW_HEIGHT, AX
        MOV AX, CAR_POS_X
		MOV POS_X, AX
        MOV AX, CAR_POS_Y
		MOV POS_Y, AX
        CALL DRAW

		RET
	RESET_PLAYER_CAR ENDP

	; function will be used to move the car position in the x-axis
	MOVE_CAR PROC NEAR
		; INT 16H  is used to acess keyboard bios services [AH = 01 to get keyboard status RETURN => ZF=0 if key pressed, AL=ASCII char]
		; check if any key is pressed if no exit 
		MOV AH, 01
		INT 16H ; EXecute to chechk if key was pressed
		JNZ CHECK_KEY ; jump if zero flag is not set(0)
		RET ; if no key pressed return
		
		; check which key [AL will contain ascii char]
		CHECK_KEY:
			MOV AH, 00h
			INT 16H
			; if it was 'a' or 'A' move car left WITHOUT GETTING OUT OF THE ROOD
			CMP AL, 100 ; cmp with 'd' ascii
			JE MOVE_RIGHT
			CMP AL, 97  ; cmp with 'a' ascii
			JE MOVE_LEFT
			; if reached this line means not a correct keystrock so only leave the function
			RET

		MOVE_RIGHT:

			CALL RESET_PLAYER_CAR ; remove old car from old pos
			MOV AX, PLAYER_CAR_VELOCITY
			ADD CAR_POS_X, AX
			; don't break the grass
			MOV BX, WINDOW_WIDTH
			SUB BX, GRASS_BLOCK_WIDTH
			SUB BX, PLAYER_CAR_WIDTH
			CMP CAR_POS_X, BX
			JGE CORRECT_RIGHT_POS


			MOV COLOR, 04H ; set color to red
			MOV AX, PLAYER_CAR_WIDTH
            MOV DRAW_WIDTH, AX
            MOV AX, PLAYER_CAR_HEIGHT
            MOV DRAW_HEIGHT, AX
            MOV AX, CAR_POS_X
		    MOV POS_X, AX
            MOV AX, CAR_POS_Y
		    MOV POS_Y, AX
            CALL DRAW

			RET

		MOVE_LEFT:
			CALL RESET_PLAYER_CAR ; remove old car from old pos
			MOV AX, PLAYER_CAR_VELOCITY
			SUB CAR_POS_X, AX

			; DON'T BREAK grass
			MOV BX, GRASS_BLOCK_WIDTH
			ADD BX, PLAYER_CAR_WIDTH
			CMP CAR_POS_X, BX
			JLE CORRECT_LEFT_POS

			MOV COLOR, 04H ; set color to red
			MOV AX, PLAYER_CAR_WIDTH
            MOV DRAW_WIDTH, AX
            MOV AX, PLAYER_CAR_HEIGHT
            MOV DRAW_HEIGHT, AX
            MOV AX, CAR_POS_X
		    MOV POS_X, AX
            MOV AX, CAR_POS_Y
		    MOV POS_Y, AX
            CALL DRAW

			RET
	
		CORRECT_RIGHT_POS:
			; at this point pos_x was inc by volcity so need to dec it to be just before the grass blk
			MOV AX, PLAYER_CAR_VELOCITY
			SUB CAR_POS_X, AX
			MOV COLOR, 04H ; set color to red
			MOV AX, PLAYER_CAR_WIDTH
            MOV DRAW_WIDTH, AX
            MOV AX, PLAYER_CAR_HEIGHT
            MOV DRAW_HEIGHT, AX
            MOV AX, CAR_POS_X
		    MOV POS_X, AX
            MOV AX, CAR_POS_Y
		    MOV POS_Y, AX
            CALL DRAW
			RET
	
		CORRECT_LEFT_POS:
			MOV AX, PLAYER_CAR_VELOCITY
			ADD CAR_POS_X, AX
			MOV COLOR, 04H ; set color to red
			MOV AX, PLAYER_CAR_WIDTH
            MOV DRAW_WIDTH, AX
            MOV AX, PLAYER_CAR_HEIGHT
            MOV DRAW_HEIGHT, AX
            MOV AX, CAR_POS_X
		    MOV POS_X, AX
            MOV AX, CAR_POS_Y
		    MOV POS_Y, AX
            CALL DRAW
            RET

    MOVE_CAR ENDP
	
	RAND_STONES PROC NEAR
        MOV COLOR, 0Fh
        MOV AX, STONE_SIZE
        MOV DRAW_WIDTH, AX
        MOV DRAW_HEIGHT, AX

        MOV AX, STONE_1_VELOCITY
        ADD STONE_1_Y, AX		;increasing stones velocity
        MOV AX, STONE_1_Y
        CMP AX, WINDOW_HEIGHT 	; check if stone reached end of screen
        JGE RESET_Y				; call reset stone position to top
        MOV POS_Y, AX
        MOV AX, STONE_1_X
        MOV POS_X, AX
        CALL DRAW
        
        MOV AX, STONE_2_VELOCITY
        ADD STONE_2_Y, AX
        MOV AX, STONE_2_Y
        CMP AX, WINDOW_HEIGHT
        JGE RESET_Y_2
        MOV POS_Y, AX
        MOV AX, STONE_2_X
        MOV POS_X, AX
        CALL DRAW
        
        MOV AX, STONE_3_X
        MOV POS_X, AX
        MOV AX, STONE_3_VELOCITY
        ADD STONE_3_Y, AX
        MOV AX, STONE_3_Y
        CMP AX, WINDOW_HEIGHT
        JGE RESET_Y_3
        MOV POS_Y, AX
        CALL DRAW
		
         
		
        RET

        RESET_Y: 
            MOV STONE_1_Y, 0007h
            MOV AX, STONE_1_Y
            MOV POS_Y, AX

            MOV AX, STONE_1_VELOCITY
            ADD STONE_1_X, AX
            MOV AX, WINDOW_WIDTH
            SUB AX, GRASS_BLOCK_WIDTH
            CMP STONE_1_X, AX
            JGE RESET_X
            MOV AX, STONE_1_X
            MOV POS_X, AX
            CALL DRAW
            RET
        
        RESET_X:
            MOV STONE_1_X, 0040h
            MOV AX, STONE_1_X
            MOV POS_X, AX
            CALL DRAW  
            RET 
        

        RESET_Y_2: 
            MOV STONE_2_Y, 0007h
            MOV AX, STONE_2_Y
            MOV POS_Y, AX

            MOV AX, STONE_2_VELOCITY
            SUB STONE_2_X, AX
            MOV AX, GRASS_BLOCK_WIDTH
            ADD AX, 5
            CMP STONE_2_X, AX
            JLE RESET_X_2
            MOV AX, STONE_2_X
            MOV POS_X, AX
            CALL DRAW
            RET
        
        RESET_X_2:
            MOV STONE_2_X, 0100h
            MOV AX, STONE_2_X
            MOV POS_X, AX
            CALL DRAW  
            RET   

        RESET_Y_3: 
            MOV STONE_3_Y, 0007h
            MOV AX, STONE_3_Y
            MOV POS_Y, AX
            CALL DRAW
            RET
        
    RAND_STONES ENDP
	
	STONES PROC NEAR
        MOV AX, STONE_SIZE
        MOV DRAW_WIDTH, AX
        MOV DRAW_HEIGHT, AX

        MOV AX, STONE_1_X
        MOV POS_X, AX
        MOV AX, STONE_1_Y
        MOV POS_Y, AX
        CALL DRAW   

        MOV AX, STONE_2_X
        MOV POS_X, AX
        MOV AX, STONE_2_Y
        MOV POS_Y, AX
        CALL DRAW    
        
		MOV AX, STONE_3_X
        MOV POS_X, AX
        MOV AX, STONE_3_Y
        MOV POS_Y, AX
        CALL DRAW    
      
		RET
    STONES ENDP

	COLLION_STONES PROC NEAR
		;check if stones is colliding with the car
		;maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny1 && miny1 < maxy2
		;STONE_1_X + STONE_SIZE > CAR_POS_X && STONE_1_X < CAR_POS_X + PLAYER_CAR_WIDTH 
		;&& STONE_1_Y + STONE_SIZE > CAR_POS_Y && STONE_1_Y < CAR_POS_Y +  PLAYER_CAR_HEIGHT
		
		MOV AX,STONE_1_X
		ADD AX,STONE_SIZE
		CMP AX,CAR_POS_X
		JNG CHECK_COLLISION_WITH_STONE_2 	;if there's no collision check for stone 2

		MOV AX,CAR_POS_X
		ADD AX,PLAYER_CAR_WIDTH
		CMP STONE_1_X,AX
		JNL  CHECK_COLLISION_WITH_STONE_2 	;if there's no collision check for stone 2

		MOV AX,STONE_1_Y
		ADD AX,STONE_SIZE
		CMP AX,CAR_POS_Y
		JNG CHECK_COLLISION_WITH_STONE_2 	;if there's no collision check for stone 2

		MOV AX,CAR_POS_Y
		;ADD AX,PLAYER_CAR_HEIGHT
		CMP AX,STONE_1_Y
		JNL CHECK_COLLISION_WITH_STONE_2 	;if there's no collision check for stone 2
		
		;if it reaches this point stone 1 is colliding with the car
		;CALL RESET_STONE_POSITION
		;CALL UPDATE_SCORE
		CALL GAME_OVER
		RET
		
		CHECK_COLLISION_WITH_STONE_2:
		MOV AX,STONE_2_X
		ADD AX,STONE_SIZE
		CMP AX,CAR_POS_X
		JNG CHECK_COLLISION_WITH_STONE_3 	;if there's no collision check for stone 3

		MOV AX,CAR_POS_X
		ADD AX,PLAYER_CAR_WIDTH
		CMP STONE_2_X,AX
		JNL  CHECK_COLLISION_WITH_STONE_3 	;if there's no collision check for stone 3

		MOV AX,STONE_2_Y
		ADD AX,STONE_SIZE
		CMP AX,CAR_POS_Y
		JNG CHECK_COLLISION_WITH_STONE_3 	;if there's no collision check for stone 3

		MOV AX,CAR_POS_Y
		;ADD AX,PLAYER_CAR_HEIGHT
		CMP AX,STONE_2_Y
		JNL CHECK_COLLISION_WITH_STONE_3 	;if there's no collision check for stone 3
		
		;if it reaches this point stone 2 is colliding with the car
		; CALL RESET_STONE_POSITION
		; CALL UPDATE_SCORE 
		CALL GAME_OVER
		
		RET
		CHECK_COLLISION_WITH_STONE_3:
		
		MOV AX,STONE_3_X
		ADD AX,STONE_SIZE
		CMP AX,CAR_POS_X
		JNG EXIT_COLLISION 	;if there's no collision Exit

		MOV AX,CAR_POS_X
		ADD AX,PLAYER_CAR_WIDTH
		CMP STONE_3_X,AX
		JNL  EXIT_COLLISION 	;if there's no collision Exit

		MOV AX,STONE_3_Y
		ADD AX,STONE_SIZE
		CMP AX,CAR_POS_Y
		JNG EXIT_COLLISION 	;if there's no collision Exit

		MOV AX,CAR_POS_Y
		;ADD AX,PLAYER_CAR_HEIGHT
		CMP AX,STONE_3_Y
		JNL EXIT_COLLISION 	;if there's no collision Exit
		
		;if it reaches this point stone 3 is colliding with the car
		;INC POINTS
		; CALL RESET_STONE_POSITION
		; CALL UPDATE_SCORE 
		CALL GAME_OVER
		
		RET
		EXIT_COLLISION:
		;CALL UPDATE_SCORE
		RET

	RET
	COLLION_STONES ENDP

	GAME_OVER PROC NEAR
	
	MOV GAME_ACTIVE,00h
	RET
	GAME_OVER ENDP

RESET_STONE_POSITION PROC NEAR        ;restart ball position to the original position
		
		MOV STONE_1_Y, 0007h
		MOV AX, STONE_1_Y
        MOV POS_Y, AX
		CALL DRAW
		MOV STONE_2_Y, 0007h
		MOV AX, STONE_2_Y
        MOV POS_Y, AX
		CALL DRAW
		MOV STONE_3_Y, 0007h
		MOV AX, STONE_3_Y
        MOV POS_Y, AX
		CALL DRAW
		RET
	RESET_STONE_POSITION ENDP

	UPDATE_SCORE PROC NEAR
		
		XOR AX,AX
		INC POINTS
		MOV AL,POINTS ;given, for example that P1 -> 2 points => AL,2
		
		;now, before printing to the screen, we need to convert the decimal value to the ascii code character 
		;we can do this by adding 30h (number to ASCII)
		;and by subtracting 30h (ASCII to number)
		ADD AL,03h  
		MOV [SCORE],AL		;AL,'2'
		
		
		RET
	UPDATE_SCORE ENDP


	DRAW_GAME_OVER_MENU PROC NEAR        ;draw the game over menu
		
		CALL SET_SCREEN                ;clear the screen before displaying the menu

;       Shows the menu title
		MOV AH,02h                       ;set cursor position
		MOV BH,00h                       ;set page number
		MOV DH,04h                       ;set row 
		MOV DL,04h						 ;set column
		INT 10h							 
		
		MOV AH,09h                       ;WRITE STRING TO STANDARD OUTPUT
		LEA DX,TEXT_GAME_OVER_TITLE      ;give DX a pointer 
		INT 21h  

				
;       Shows the play again message
		MOV AH,02h                       ;set cursor position
		MOV BH,00h                       ;set page number
		MOV DH,08h                       ;set row 
		MOV DL,04h						 ;set column
		INT 10h							 

		MOV AH,09h                       ;WRITE STRING TO STANDARD OUTPUT
		LEA DX,TEXT_GAME_OVER_PLAY_AGAIN      ;give DX a pointer 
		INT 21h                          ;print the string
		
				
;       Waits for a key press
		MOV AH,00h
		INT 16h

;       If the key is either 'R' or 'r', restart the game		
		CMP AL,'R'
		JE RESTART_GAME
		CMP AL,'r'
		JE RESTART_GAME
;       If the key is either 'E' or 'e', exit to main menu
		; CMP AL,'E'
		; JE EXIT_TO_MAIN_MENU
		; CMP AL,'e'
		; JE EXIT_TO_MAIN_MENU
		 RET
		
		RESTART_GAME:
		CALL RESET_STONE_POSITION
			MOV GAME_ACTIVE,01h
			RET
		
		; EXIT_TO_MAIN_MENU:
		; 	MOV GAME_ACTIVE,00h
		; 	MOV CURRENT_SCENE,00h
		; 	RET

		RET
		DRAW_GAME_OVER_MENU ENDP


	CONCLUDE_EXIT_GAME PROC NEAR     ;goes back to the text mode

		MOV AH,00h                   ;set the configuration to video mode
		MOV AL,02h                   ;choose the video mode
		INT 10h    		     		 ;execute the configuration 
		MOV AH,4Ch                   ;terminate program
		INT 21h

	CONCLUDE_EXIT_GAME ENDP
	PRINT_NUMBER PROC NEAR
	;takes ax the number
	mov BX, 10
    MOV CX, 0
	CONSTRUCT_STRING:
    	MOV DX, 0
    	DIV BX                          ;divide by ten
    	; now ax <-- ax/10
    	;     dx <-- ax % 10
    	; print dx
    	; this is one digit, which we have to convert to ASCII
    	; the print routine uses dx and ax, so let's push ax
    	; onto the stack. we clear dx at the beginning of the
    	; loop anyway, so we don't care if we much around with it
    	PUSH AX
    	ADD DL, '0'                     ;convert dl to ascii
    	POP AX                          ;restore ax
    	PUSH DX                         ;digits are in reversed order, must use stack
    	INC CX                          ;remember how many digits we pushed to stack
    	CMP AX, 0                       ;if ax is zero, we can quit
	JNZ CONSTRUCT_STRING

		MOV AH,02h                       ;set cursor position
		MOV BH,00h                       ;set page number
		MOV DH,001h                      ;set row 
		MOV DL,01Fh						 ;set column
		INT 10h
		MOV AH,2                       ;WRITE STRING TO STANDARD OUTPUT	
	PRINT_STRING:
    	POP DX                          ;restore digits from last to first
    	INT 21h                         ;calls DOS Services
    	LOOP PRINT_STRING
    RET
PRINT_NUMBER endp
CODE ENDS
END