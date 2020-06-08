org 0x8000      ;Set assembler location counter
bits 16

; Modo grafico
call initGraphics


;loop principal
gameLoop:
    call resetBuffer        ;resetea la pantalla llamada desde buffer.asm
	

    ; DRAW A BRICK
    ;mov cx, [player+2]      ;dibuja relativamente x
    ;mov dx, [player+4]      ;
    ;mov di, box
    ;call drawEntity

	;mov cx, [player+2]      ;dibuja relativamente x
    ;mov dx, [player+4]      ;
    ;mov di, box2
    ;call drawEntity
	call drawMap

	mov di, player
    call drawEntity
		
	mov dx, [shooting]
	sub dx, 1
	jnz .noBala
		;mov di, enemy
		;call drawEntity
		mov di, bullet
		call drawEntity
		
	.noBala:
	
	mov di, enemy
	call drawEntity

	call moveEnemy

	mov dx, [shooting]
	sub dx, 1
	jnz .noMoveBala
		call moveBala
	.noMoveBala:
	call copyBufferOver ;draw frame to screen
	call gameControls ;handle control logic
	
jmp gameLoop

jmp $

moveEnemy:
	pusha
	mov di, enemy		; Seleccionamos al enemigo, meter un loop para varios
	mov ax, [di+8]		; seleccionamos el contador de activar de enemy
	sub ax, 5			; Cada 20 llamadas de gameloop se mueve el enemigo
		jz .active
	inc word [di+8]
	popa
	ret

	.active:
		mov cx, word [di+2] ;set cx to enemy x
		mov dx, word [di+4] ;set dx to enemy z
	.move:
		mov bx, word [di+10]	;direction of movement
		cmp bx, 0 					;0 -> derecha
			jne .d1
			cmp cx,0x0+75
				jge .turnUp
			inc cx
			mov bp, enemyImg_right
			jg .back
		.d1:
			cmp bx, 1 ;try to move x-1 if 'a' is pressed and set animation accordingly, test other cases otherwise
			jne .d2
			cmp cx,0x3
				jnge .turnDown
			dec cx
			mov bp, enemyImg_left
			jg .back
		.d2:
			cmp bx, 2 ;try to move z-1 if 'w' is pressed and set animation accordingly, test other cases otherwise
			jne .d3
			cmp dx,0x2
				jnge .turnLeft
			dec dx
			mov bp, enemyImg_back
			jg .back
		.d3:
			cmp dx,0x0+45
				jge .turnRight
			inc dx
			mov bp, enemyImg_front
			jg .back
			
		.back:
			mov word [di]   ,bp  ;update the animation in use
			mov word [di+2] ,cx  ;update x pos
			mov word [di+4] ,dx  ;update y pos
			mov word [di+8] ,0  ;update active count to 0
			;call checkForCollision
			popa                 ;reload old register state
			ret
		
		.turnRight:
			mov word [di+10], 0  ;update y pos
			jmp .move
		.turnLeft:
			inc word [di+10]
			jmp .move
		.turnUp:
			inc word [di+10]
			jmp .move
		.turnDown:
			inc word [di+10]
			jmp .move
		
		
		

moveBala:

	mov cx, word [bullet_PosX] ;set cx to bullet x
	mov dx, word [bullet_PosZ] ;set dx to bullet z
	mov bx, word [bullet_dir]	;direction of movement
	cmp bx, 0 					;0 -> derecha
		jne .d1
		cmp cx,0x0+75
			jge .destroy
		inc cx
		jg .back
	.d1:
		cmp bx, 1 ;try to move x-1 if 'a' is pressed and set animation accordingly, test other cases otherwise
		jne .d2
		cmp cx,0x3
			jnge .destroy
		dec cx
		jg .back
	.d2:
		cmp bx, 2 ;try to move z-1 if 'w' is pressed and set animation accordingly, test other cases otherwise
		jne .d3
		cmp dx,0x2
			jnge .destroy
		dec dx
		jg .back
	.d3:
		cmp dx,0x0+45
			jge .destroy
		inc dx
		jg .back
		
	.back:
		mov word [bullet_PosX] ,cx  ;update x pos
		mov word [bullet_PosZ] ,dx  ;update y pos
		ret
	.destroy:
		mov word [shooting] ,0  ;update y pos
		ret
	



drawMap:
	mov di, box
	mov si, word [di]   ;get animation
	mov si, word [si+4] ;get first frame of animation
	
	mov ax, word [map] ;get entity x
	mov bx, word [map+2] ;get entity y
	call drawImage      ;draw image to buffer
	
	mov ax, word [map+4] ;get entity x
	mov bx, word [map+6] ;get entity y
	call drawImage      ;draw image to buffer

	mov ax, word [map+8] ;get entity x
	mov bx, word [map+10] ;get entity y
	call drawImage      ;draw image to buffer

	mov ax, word [map+12] ;get entity x
	mov bx, word [map+14] ;get entity y
	call drawImage      ;draw image to buffer
	
	mov ax, word [map+16] ;get entity x
	mov bx, word [map+18] ;get entity y
	call drawImage      ;draw image to buffer
	ret


drawEntity:
	mov si, word [di]   ;get animation
	mov si, word [si+4] ;get first frame of animation
	mov ax, word [di+2] ;get entity x
	mov bx, word [di+4] ;get entity y
	call drawImage      ;draw image to buffer
	ret

;di = entity, cx = new_xpos, dx = new_zpos, bp = new animation
checkForCollision:
	pusha                   ;save current state
	push si 				;save si for lateR NO ESTOY SEGURO DE QUE ESTE BIEN
	mov si, entityArray-2   ;set si to entityArray (-2 because we increment at the start of the loop)

	.whileLoop:
	add si, 2           ;set si to the next entry in the entityArray
	mov bx, word [si]   ;read entityArray entry
	test bx, bx         ;if entry is zero => end of array
	jz .whileEscape
	cmp bx, di          ;if entity is equal to di => next entity to not collide with it self
	jz .whileLoop
	
	mov ax, word [bx+2] ;ax = entity x
	sub ax, 5           ;subtract 8 because of hitbox
	cmp ax, cx ; (entityX-8 <= playerX)
		jg .whileLoop
		
	mov ax, word [bx+2] ;ax = entity x
	add ax, 5           ;add 8 because of hitbox
	cmp ax, cx ; (entityX+8 > playerX)
		jle .whileLoop

	mov ax, word [bx+4] ;ax = entity z
	sub ax, 5          ;subtract 10 because of hitbox
	cmp ax, dx ; (entityZ-10 <= playerZ)
		jg .whileLoop
		
	mov ax, word [bx+4] ;ax = entity z
	add ax, 5           ;subtract 9 because of hitbox
	cmp ax, dx ; (entityZ+9 > playerZ)
		jle .whileLoop
		
	;if we reach this point => actual collision
	mov cx, [di+2]         ;set new x pos to current x pos => no movement
	mov dx, [di+4]         ;set new z pos to current z pos => no movement
	;mov word [player+6], 0 ;reset animation counter
	
	jmp .whileLoop         ;repeat for all entities in array
	.whileEscape:
	pop si					;NO ESTOY SEGURO QUE SEA ADECUADO
	inc word [si+6]  ;update animation if moving
	mov word [di]   ,bp  ;update the animation in use
	mov word [di+2] ,cx  ;update x pos
	mov word [di+4] ,dx  ;update y pos
	popa                 ;reload old register state
	ret

gameControls:
	mov di, player ;select the player as the main entity for "checkForCollision"
	call checkKey  ;check if a key is pressed
	jz .nokey
		mov cx, word [player_PosX] ;set cx to player x
		mov dx, word [player_PosZ] ;set dx to player z
		mov bp, [player]           ;set bp to current animation
		; p 0x19
		; cmp
		; .fire
		cmp ah, 0x39
		jne .movDr
		mov word[shooting], 1
		mov word[bullet_PosX], cx
		mov word[bullet_PosZ], dx

		; DERECHA (D)
		.movDr:
			cmp ah, 0x20 ;try to move x+1 if 'd' is pressed and set animation accordingly, test other cases otherwise
			jne .movIz
			inc cx
			mov bp, playerImg_right
			mov word[bullet_dir], 0
		; IZQUIERDA (A)
		.movIz:
			cmp ah, 0x1e ;try to move x-1 if 'a' is pressed and set animation accordingly, test other cases otherwise
			jne .movAr
			dec cx
			mov bp, playerImg_left
			mov word[bullet_dir], 1
		; ARRIBA (W)
		.movAr:
			cmp ah, 0x11 ;try to move z-1 if 'w' is pressed and set animation accordingly, test other cases otherwise
			jne .movAb
			dec dx
			mov bp, playerImg_back
			mov word[bullet_dir], 2
		; ABAJO (S)
		.movAb:
			cmp ah, 0x1F ;try to move z+1 if 's' is pressed and set animation accordingly, test other cases otherwise
			jne .end
			inc dx
			mov bp, playerImg_front
			mov word[bullet_dir], 3
		.end:
			call checkForCollision ;check if player would collide on new position, if not change position to new position
		
	.nokey:
	ret


checkKey:
	mov ah, 1
	int 0x16   ;int 0x16 ah=1 => read key status, zeroflag if no key pressed
	jz .end
	mov ax, 1  ;int 0x16 ah=0 => read key
	int 0x16
	ret
	.end:
	mov ax, 0  ;return 0 if no key is pressed
	ret
	
%include "buffer.asm"

;entity array
entityArray:
			dw player
			dw box
			dw box2
			dw enemy
			dw 0
map:; Bloque 0
	dw 0
	dw 3
	; Bloque 1
	dw 0
	dw 8
	; Bloque 2
	dw 0
	dw 13
	; Bloque 3
	dw 0
	dw 18
	; Bloque 4
	dw 0
	dw 23
	
enemy:
	enemy_Anim dw enemyImg_front          	;puntero a animacion
	enemy_PosX dw 0x15                      ;pos X
	enemy_PosZ dw 0x15                      ;pos Z
	enemy_AnimC dw 0                       	;animation counter
	enemy_act	dw 0						;activation counter
	enemy_dir	dw 0						;direction counter



player:
	player_Anim dw playerImg_front          ;puntero a animacion
	player_PosX dw 0x35                        ;pos X
	player_PosZ dw 0x25                        ;pos Z
	player_AnimC dw 0                       ;animation counter
	shooting dw 0

bullet:
	bullet_Anim dw bulletImg                  ;puntero a la animacion
	bullet_PosX dw 0                   ;brick pos x
	bullet_PosZ dw 0                    ;brick pos z
	bullet_AnimC dw 0                     ;counter animacion
	bullet_dir dw 0


;brick estructura
box:
	box_Anim dw boxImg                  ;puntero a la animacion
	box_PosX dw 0x0                    ;brick pos x
	box_PosZ dw 0x3                    ;brick pos z
	box_AnimC dw 0                      ;counter animacion


box2:
	box_Anim2 dw boxImg                  ;puntero a la animacion
	box_PosX2 dw 0x0+75                    ;brick pos x
	box_PosZ2 dw 0x0+45                    ;brick pos z
	box_AnimC2 dw 0                      ;counter animacion



enemyImg_front:
	dw 1
	dw 1
	dw enemyImg_front_0
	dw 0

enemyImg_back:
	dw 1
	dw 1
	dw enemyImg_back_0
	dw 0

enemyImg_left:
	dw 1
	dw 1
	dw enemyImg_left_0
	dw 0

enemyImg_right:
	dw 1
	dw 1
	dw enemyImg_right_0
	dw 0



;animation structure
playerImg_front:
	dw 1
	dw 1
	dw playerImg_front_0
	dw 0
	
playerImg_back:
    dw 1
	dw 1
	dw playerImg_back_0
	dw 0
	
playerImg_right:
    dw 1
	dw 1
	dw playerImg_right_0
	dw 0
	
	
playerImg_left:
	dw 1
	dw 1
	dw playerImg_left_0
	dw 0

boxImg:
	dw 1            ;time per frames
	dw 1            ;time of animation
	dw boxImg_0     ;frames
	dw 0            ;zero end frame


bulletImg:
	dw 1            ;time per frames
	dw 1            ;time of animation
	dw bulletImg_0     ;frames
	dw 0            ;zero end frame



playerImg_front_0 incbin "img/IzV.bin"
playerImg_back_0  incbin "img/DeV.bin"
playerImg_right_0 incbin "img/ArV.bin"
playerImg_left_0  incbin "img/AbV.bin"

enemyImg_front_0 incbin "img/IzD.bin"
enemyImg_back_0  incbin "img/DeD.bin"
enemyImg_right_0 incbin "img/ArD.bin"
enemyImg_left_0  incbin "img/AbD.bin"

boxImg_0          incbin "img/brick.bin"

bulletImg_0			incbin "img/bullet.bin"

%assign usedMemory ($-$$)
%assign usableMemory (512*16)
%warning [usedMemory/usableMemory] Bytes used
times (512*16)-($-$$) db 0