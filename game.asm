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
    ;set stones' initial position
	STONE_1_X DW 0040h
    STONE_1_Y DW 0007h
    STONE_2_X DW 0100h
    STONE_2_Y DW 0007h
    STONE_3_X DW 0090h
    STONE_3_Y DW 0007h
	;to change the stones' position for the movement illusion
    STONE_1_VELOCITY DW 0004h
    STONE_2_VELOCITY DW 0006h
    STONE_3_VELOCITY DW 0003h

	CURRENT_SCENE DB 0                   						;the index of the current scene (0, main menu) (1,currently playing) (2,gameover)
	TIME_AUX DB 0                        						;variable used when checking if the time has changed
	SCORE DW 0			               	     					;(current Score)
	UPDATE_SCORE_TIME_1 DW 0									;variable used when checking if the time has changed
	UPDATE_SCORE_TIME_2 DW 0									;variable used when checking if the time has changed
	TEXT_SCORE DB 'SCORE','$' 									
	
	;----------------------------TEXT IN GAME OVER-----------------------------
	TEXT_GAME_OVER_TITLE DB 'GAME OVER','$' 					;text with the game over menu title
	TEXT_GAME_OVER_PLAY_AGAIN DB 'PLAY AGAIN - PRESS R','$' 	;text with the game over play again message
	TEXT_BACK_TO_MENU DB 'BACK TO MAIN MENU - PRESS B', '$'	
	;---------------------------------------------------------------------------

	;----------------------------TEXT IN MAIN MENU-----------------------------
	TEXT_MAIN_MENU_TITLE DB 'NAGSM - STREET FIGHTER', '$'
	TEXT_MAIN_MENU_NORMAL DB 'START GAME IN NORMAL MODE - PRESS 1', '$'
	TEXT_MAIN_MENU_HARD DB 'START GAME IN HARD MODE - PRESS 2', '$'
	TEXT_MAIN_MENU_QUIT DB 'QUIT THE GAME - PRESS Q', '$'
	;---------------------------------------------------------------------------
	
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

		CALL SET_SCREEN						 ;set video mode and black background 
		
		CALL DRAW_GRASS_BLOCKS				 ;draw the left and the right grass blocks
		
		;draw stones
        MOV COLOR, 0Fh						 ;set color to white
        CALL STONES							 ;set the variables to DRAW the stones
 
		CALL DRAW_CAR						;draw player's car
       
		;------------------------------
		; Main game loop start
		GAME_LOOP:
			; check current scene to decide what to show
			CMP CURRENT_SCENE, 00H 			;00H decided to be main menu scene
			JE SHOW_MAIN_MENU
			
			; check game state to decide is the game over or not
			CMP CURRENT_SCENE, 02h
			JE SHOW_GAME_OVER

			;get current system time  [CH = hour, CL = minute, DH = seconds, DL = 1/100 sec]
			MOV AH,2Ch	
			INT 21h
			CMP DL, TIME_AUX				
			JE GAME_LOOP	

			MOV TIME_AUX, DL 		;update time
            
			MOV COLOR, 00h			;set stones' color to black 
            CALL STONES				;draw black stones to be as if they were erased 
			
			CALL RAND_STONES		;draw the stones in new positions to pretend they are moving
			
			CALL DRAW_SCORE			;draw player's current score
            INC UPDATE_SCORE_TIME_2
			CALL UPDATE_SCORE

			CALL MOVE_CAR
			CALL COLLION_STONES
			
			JMP GAME_LOOP
			
			SHOW_GAME_OVER:
				CALL DRAW_GAME_OVER_MENU
				CALL SET_SCREEN
				CALL DRAW_GRASS_BLOCKS
				CALL DRAW_CAR
				JMP GAME_LOOP
			
			SHOW_MAIN_MENU:
				CALL DRAW_GAME_MAIN_MENU
				; after return from the menu draw required for playing scene
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

	DRAW_SCORE PROC NEAR
		MOV AH,02h                       ;set cursor position
		MOV BH,00h                       ;set page number
		MOV DH,001h                      ;set row 
		MOV DL,019h						 ;set column
		MOV BL,00h
		MOV AL, 04h 
		INT 10h							 
		MOV AH,09h                       ;WRITE STRING TO STANDARD OUTPUT
		LEA DX,TEXT_SCORE    			 ;give DX a pointer to the string TEXT_SCORE
		INT 21h 
		MOV AX, SCORE
		CALL PRINT_NUMBER
		RET
	DRAW_SCORE ENDP

	;function to remove player car by replacing it with black
	RESET_PLAYER_CAR PROC NEAR
		MOV COLOR, 00H 					; set color to black then draw player car
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

	;function will be used to move the car position in the x-axis
	MOVE_CAR PROC NEAR
		;INT 16H  is used to acess keyboard bios services [AH = 01 to get keyboard status RETURN => ZF=0 if key pressed, AL=ASCII char]
		;check if any key is pressed if no exit 
		MOV AH, 01
		INT 16H 					;EXecute to chechk if key was pressed
		JNZ CHECK_KEY 				;jump if zero flag is not set(0)
		RET 						;if no key pressed return
		
		;check which key [AL will contain ascii char]
		CHECK_KEY:
			MOV AH, 00h
			INT 16H
			;if it was 'a' or 'A' move car left WITHOUT GETTING OUT OF THE ROOD
			CMP AL, 100 			;cmp with 'd' ascii
			JE MOVE_RIGHT
			CMP AL, 97  			;cmp with 'a' ascii
			JE MOVE_LEFT
			;if reached this line means not a correct keystrock so only leave the function
			RET

		MOVE_RIGHT:
			CALL RESET_PLAYER_CAR		;remove old car from old pos
			MOV AX, PLAYER_CAR_VELOCITY
			ADD CAR_POS_X, AX
			; don't break the grass
			MOV BX, WINDOW_WIDTH
			SUB BX, GRASS_BLOCK_WIDTH
			SUB BX, PLAYER_CAR_WIDTH
			CMP CAR_POS_X, BX
			JGE CORRECT_RIGHT_POS

			MOV COLOR, 04H 				;set color to red
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
			CALL RESET_PLAYER_CAR 		;remove old car from old pos
			MOV AX, PLAYER_CAR_VELOCITY
			SUB CAR_POS_X, AX

			; DON'T BREAK grass
			MOV BX, GRASS_BLOCK_WIDTH
			ADD BX, 5
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
		;set variables to be used in DRAW PROC
        MOV COLOR, 0Fh
        MOV AX, STONE_SIZE
        MOV DRAW_WIDTH, AX
        MOV DRAW_HEIGHT, AX

		;the left stone
        MOV AX, STONE_1_VELOCITY
        ADD STONE_1_Y, AX			;change the stone's position
        MOV AX, STONE_1_Y
        ;check if the stone reached the end of screen
		CMP AX, WINDOW_HEIGHT 		
        JGE RESET_Y					;if stone's y-position >= window's height => reset the stone to the top
        ;if less => set variables to DRAW the stone in the new position
		MOV POS_Y, AX	
        MOV AX, STONE_1_X
        MOV POS_X, AX
        CALL DRAW
        
		;the right stone
        MOV AX, STONE_2_VELOCITY
        ADD STONE_2_Y, AX			;change the stone's position
        MOV AX, STONE_2_Y
        ;check if the stone reached the end of screen
		CMP AX, WINDOW_HEIGHT
        JGE RESET_Y_2				;if stone's y-position >= window's height => reset the stone to the top
        ;if less => set variables to DRAW the stone in the new position
		MOV POS_Y, AX
        MOV AX, STONE_2_X
        MOV POS_X, AX
        CALL DRAW
        
		;the middle stone
        MOV AX, STONE_3_X
        MOV POS_X, AX				;set the x-axis position
        MOV AX, STONE_3_VELOCITY
        ADD STONE_3_Y, AX			;change the stone's position
        MOV AX, STONE_3_Y
		;check if the stone reached the end of screen
        CMP AX, WINDOW_HEIGHT
        JGE RESET_Y_3				;if stone's y-position >= window's height => reset the stone to the top
		MOV POS_Y, AX				;if less => set the y-axis position and DRAW the stone
        CALL DRAW
		
        RET

		;if the left stone reached the end of screen
        RESET_Y: 
            MOV STONE_1_Y, 0007h		;move the stone to its initial y-position
            MOV AX, STONE_1_Y		
            MOV POS_Y, AX				;set the y-axis position to DRAW
			;every time the stone is moved to the top, its x-position is increased
            MOV AX, STONE_1_VELOCITY
            ADD STONE_1_X, AX			
            ;check if the stone is overlapped with the right grass block
			MOV AX, WINDOW_WIDTH	
            SUB AX, GRASS_BLOCK_WIDTH	
            CMP STONE_1_X, AX
            JGE RESET_X					;if the stone reached the grass block => reset it to the left
            MOV AX, STONE_1_X
            MOV POS_X, AX				;if not => set the x-position to DRAW and return
            CALL DRAW
            RET
        
		;reset the left stone to the its initial x-axis position
        RESET_X:
            MOV STONE_1_X, 0040h		;move the stone to its initial x-position (left)
            MOV AX, STONE_1_X
            MOV POS_X, AX				;set the x-axis position to DRAW
            CALL DRAW  
            RET 
        
		;if the right stone reached the end of screen
        RESET_Y_2: 
            MOV STONE_2_Y, 0007h		;move the stone to its initial y-position
            MOV AX, STONE_2_Y
            MOV POS_Y, AX				;set the y-axis position to DRAW
			;every time the stone is moved to the top, its x-position is decreased
            MOV AX, STONE_2_VELOCITY
            SUB STONE_2_X, AX
			;check if the stone reached the left grass block
            MOV AX, GRASS_BLOCK_WIDTH
            ADD AX, 5
            CMP STONE_2_X, AX
            JLE RESET_X_2				;if the stone overlap the grass block => reset it to the right
            MOV AX, STONE_2_X			
            MOV POS_X, AX				;if not => set the x-position to DRAW and return
            CALL DRAW
            RET
        
		;reset the right stone to the its initial x-axis position
        RESET_X_2:
            MOV STONE_2_X, 0100h		;move the stone to its initial x-position (right)
            MOV AX, STONE_2_X
            MOV POS_X, AX				;set the x-axis position to DRAW
            CALL DRAW  
            RET   

		;if the middle stone reached the end of screen
        RESET_Y_3: 
            MOV STONE_3_Y, 0007h		;move the stone to its initial y-position
            MOV AX, STONE_3_Y
            MOV POS_Y, AX				;set the y-axis position to DRAW
            CALL DRAW
            RET
        
    RAND_STONES ENDP
	
	STONES PROC NEAR
		;set variables to be used in DRAW PROC
        MOV AX, STONE_SIZE
        MOV DRAW_WIDTH, AX
        MOV DRAW_HEIGHT, AX

		;the left stone
        MOV AX, STONE_1_X
        MOV POS_X, AX
        MOV AX, STONE_1_Y
        MOV POS_Y, AX
        CALL DRAW   
		;the right stone
        MOV AX, STONE_2_X
        MOV POS_X, AX
        MOV AX, STONE_2_Y
        MOV POS_Y, AX
        CALL DRAW    
        ;the middle stone
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
		JNL CHECK_COLLISION_WITH_STONE_2 	;if there's no collision check for stone 2

		MOV AX,STONE_1_Y
		ADD AX,STONE_SIZE
		CMP AX,CAR_POS_Y
		JNG CHECK_COLLISION_WITH_STONE_2 	;if there's no collision check for stone 2

		MOV AX,CAR_POS_Y
		CMP AX,STONE_1_Y
		JNL CHECK_COLLISION_WITH_STONE_2 	;if there's no collision check for stone 2
		
		;if it reaches this point stone 1 is colliding with the car
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
			JNL CHECK_COLLISION_WITH_STONE_3 	;if there's no collision check for stone 3

			MOV AX,STONE_2_Y
			ADD AX,STONE_SIZE
			CMP AX,CAR_POS_Y
			JNG CHECK_COLLISION_WITH_STONE_3 	;if there's no collision check for stone 3

			MOV AX,CAR_POS_Y
			;ADD AX,PLAYER_CAR_HEIGHT
			CMP AX,STONE_2_Y
			JNL CHECK_COLLISION_WITH_STONE_3 	;if there's no collision check for stone 3

			;if it reaches this point stone 2 is colliding with the car
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
			JNL EXIT_COLLISION 	;if there's no collision Exit

			MOV AX,STONE_3_Y
			ADD AX,STONE_SIZE
			CMP AX,CAR_POS_Y
			JNG EXIT_COLLISION 	;if there's no collision Exit

			MOV AX,CAR_POS_Y
			;ADD AX,PLAYER_CAR_HEIGHT
			CMP AX,STONE_3_Y
			JNL EXIT_COLLISION 	;if there's no collision Exit

			;if it reaches this point stone 3 is colliding with the car
			CALL GAME_OVER
			RET

		EXIT_COLLISION:
			RET

		RET
	COLLION_STONES ENDP

	GAME_OVER PROC NEAR
		MOV CURRENT_SCENE,02h
		RET
	GAME_OVER ENDP

	;reset stone position to the original position
	RESET_STONE_POSITION PROC NEAR        
		MOV STONE_1_Y, 0007h
		MOV AX, STONE_1_Y
        MOV POS_Y, AX
		MOV STONE_1_X, 0040h
		MOV AX, STONE_1_X
        MOV POS_X, AX
		CALL DRAW

		MOV STONE_2_Y, 0007h
		MOV AX, STONE_2_Y
        MOV POS_Y, AX
		MOV STONE_2_X, 0100h
		MOV AX, STONE_2_X
        MOV POS_X, AX
		CALL DRAW

		MOV STONE_3_Y, 0007h
		MOV AX, STONE_3_Y
        MOV POS_Y, AX
		MOV STONE_3_X, 0090h
		MOV AX, STONE_3_X
        MOV POS_X, AX
		CALL DRAW
		RET
	RESET_STONE_POSITION ENDP

	UPDATE_SCORE PROC NEAR
		MOV AX, UPDATE_SCORE_TIME_2
		MOV BX, UPDATE_SCORE_TIME_1
		SUB AX, BX
		CMP AX, 14h
		JE UPDATE
		RET

		UPDATE:
			MOV AX, UPDATE_SCORE_TIME_2
			MOV UPDATE_SCORE_TIME_1, AX
			INC SCORE
			CALL DRAW_SCORE
			RET

	UPDATE_SCORE ENDP

	DRAW_GAME_OVER_MENU PROC NEAR        ;draw the game over menu
		CALL SET_SCREEN                	 ;clear the screen before displaying the menu
		CALL DRAW_SCORE

		;Shows the menu title
		MOV AH,02h                       ;set cursor position
		MOV BH,00h                       ;set page number
		MOV DH,04h                       ;set row 
		MOV DL,04h						 ;set column
		INT 10h							 

		MOV AH,09h                       ;WRITE STRING TO STANDARD OUTPUT
		LEA DX,TEXT_GAME_OVER_TITLE      ;give DX a pointer 
		INT 21h  
 
		;Shows the play again message
		MOV AH,02h                       ;set cursor position
		MOV BH,00h                       ;set page number
		MOV DH,08h                       ;set row 
		MOV DL,04h						 ;set column
		INT 10h							 

		MOV AH,09h                       		;WRITE STRING TO STANDARD OUTPUT
		LEA DX,TEXT_GAME_OVER_PLAY_AGAIN     	;give DX a pointer 
		INT 21h                          		;print the string
				
		;Shows the back to main menu message
		MOV AH,02h                       ;set cursor position
		MOV BH,00h                       ;set page number
		MOV DH,0Ah                       ;set row 
		MOV DL,04h						 ;set column
		INT 10h							 

		MOV AH,09h                       		;WRITE STRING TO STANDARD OUTPUT
		LEA DX,TEXT_BACK_TO_MENU     			;give DX a pointer 
		INT 21h                          		;print the string
				
		;Shows quit the game message
		MOV AH,02h                       ;set cursor position
		MOV BH,00h                       ;set page number
		MOV DH,0Ch                       ;set row 
		MOV DL,04h						 ;set column
		INT 10h							 

		MOV AH,09h                       		;WRITE STRING TO STANDARD OUTPUT
		LEA DX,TEXT_MAIN_MENU_QUIT     			;give DX a pointer 
		INT 21h                          		;print the string
				
		;Waits for a key press
		READ_INPUT:
			MOV AH,00h
			INT 16h

			;If the key is either 'R' or 'r', restart the game		
			CMP AL,'R'
			JE RESTART_GAME
			CMP AL,'r'
			JE RESTART_GAME
			;If the key is either 'B' or 'b', back to main menu
			CMP AL,'B'
			JE BACK_TO_MENU
			CMP AL,'b'
			JE BACK_TO_MENU
			;If the key is either 'Q' or 'q', exit the game 
			CMP AL,'Q'
			JE QUIT_THE_GAME
			CMP AL,'q'
			JE QUIT_THE_GAME
			
			JMP READ_INPUT
		
		RESTART_GAME:
			CALL RESET_STONE_POSITION
			MOV CURRENT_SCENE, 01h
			MOV SCORE, 0
			MOV UPDATE_SCORE_TIME_1, 0
			MOV UPDATE_SCORE_TIME_2, 0
			RET

		BACK_TO_MENU:
			CALL RESET_STONE_POSITION
			MOV CURRENT_SCENE, 00h
			MOV SCORE, 0
			MOV UPDATE_SCORE_TIME_1, 0
			MOV UPDATE_SCORE_TIME_2, 0
			RET

		QUIT_THE_GAME:
			CALL CONCLUDE_EXIT_GAME
			RET

	DRAW_GAME_OVER_MENU ENDP
	
	;function to draw main menu 
	DRAW_GAME_MAIN_MENU PROC NEAR
		CALL SET_SCREEN                  ;clear the screen before displaying the menu

		;Shows the menu title
		MOV AH,02h                       ;set cursor position
		MOV BH,00h                       ;set page number
		MOV DH,04h                       ;set row 
		MOV DL,04h						 ;set column
		INT 10h							 
		
		MOV AH,09h                       ;WRITE STRING TO STANDARD OUTPUT
		LEA DX,TEXT_MAIN_MENU_TITLE      ;give DX a pointer 
		INT 21h  
		;Shows normal mode option
		MOV AH,02h                       ;set cursor position
		MOV BH,00h                       ;set page number
		MOV DH,07h                       ;set row 
		MOV DL,04h						 ;set column
		INT 10h							 
		
		MOV AH,09h                       ;WRITE STRING TO STANDARD OUTPUT
		LEA DX,TEXT_MAIN_MENU_NORMAL     ;give DX a pointer 
		INT 21h  
		;Shows hard mode option
		MOV AH,02h                       ;set cursor position
		MOV BH,00h                       ;set page number
		MOV DH,09h                       ;set row 
		MOV DL,04h						 ;set column
		INT 10h							 
		
		MOV AH,09h                       ;WRITE STRING TO STANDARD OUTPUT
		LEA DX,TEXT_MAIN_MENU_HARD      ;give DX a pointer 
		INT 21h  
		;Shows quit option
		MOV AH,02h                       ;set cursor position
		MOV BH,00h                       ;set page number
		MOV DH,0Bh                       ;set row 
		MOV DL,04h						 ;set column
		INT 10h							 
		
		MOV AH,09h                       ;WRITE STRING TO STANDARD OUTPUT
		LEA DX,TEXT_MAIN_MENU_QUIT      ;give DX a pointer 
		INT 21h  
		
		;Waits for a key press
		READ_USER_INPUT:
			MOV AH,00h
			INT 16h

			CMP AL, '1'
			JE CHANGE_TO_GAME_SCENE_NORMAL
			CMP AL, '2'
			JE CHANGE_TO_GAME_SCENE_HARD
			CMP AL, 'Q'
			JE EXIT_GAME
			CMP AL, 'q'
			JE EXIT_GAME
			
			JMP READ_USER_INPUT ; unconditional jump to not accept any wrong input	

		;choose hard will perform both code for hard and normal, if normal only execute code for normal and keep speed at the normal[default]
		CHANGE_TO_GAME_SCENE_HARD:
			MOV CURRENT_SCENE, 01H ; scene 1 means playing the game
			; the idea of hard here increase how fast the stones moves
			MOV STONE_1_VELOCITY, 06H 
			MOV STONE_2_VELOCITY, 08H 
			MOV STONE_3_VELOCITY, 05H 
			RET

		CHANGE_TO_GAME_SCENE_NORMAL:
			MOV CURRENT_SCENE, 01H ; scene 1 means playing the game
			; reset velocity
			MOV STONE_1_VELOCITY, 04H 
			MOV STONE_2_VELOCITY, 06H 
			MOV STONE_3_VELOCITY, 03H 
			RET

		EXIT_GAME: 
			CALL CONCLUDE_EXIT_GAME
			RET
		
	DRAW_GAME_MAIN_MENU ENDP
	
	CONCLUDE_EXIT_GAME PROC NEAR     ;goes back to the text mode
		MOV AH,00h                   ;set the configuration to video mode
		MOV AL,02h                   ;choose the video mode
		INT 10h    		     		 ;execute the configuration 
		MOV AH,4Ch                   ;terminate program
		INT 21h
		RET
	CONCLUDE_EXIT_GAME ENDP
	
	PRINT_NUMBER PROC NEAR
		;takes ax the number
		MOV BX, 10
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
	PRINT_NUMBER ENDP

CODE ENDS
END