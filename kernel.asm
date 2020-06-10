org 0x8000      ;Set assembler location counter
bits 16

; Modo grafico
call initGraphics


;loop principal
gameLoop:
    call resetBuffer        ;resetea la pantalla llamada desde buffer.asm	
	
	mov di, player
    call drawEntity
	
	mov di, falcon
	call drawEntity
	
	call drawMap
	
	mov dx, [shooting]
	sub dx, 1
	jnz .passBala
		mov di, bullet
		call drawEntity
	
	.passBala:
	mov di, enemy1
	mov ax, [di+12]		; seleccionamos el contador de activar de enemy
	cmp ax, 0			; Cada 20 llamadas de gameloop se mueve el enemigo
		jz .passEnemy
	call drawEntity

	.passEnemy:

	mov dx, [shooting]
	sub dx, 1
	jnz .noMoveBala
		call moveBala
	.noMoveBala:
	
	call moveEnemy
	
	mov dx, [bad_bullet_active]
	cmp dx, 0
		je	.notEnemyBullet
	mov di, badBullet
	call drawEntity
	.notEnemyBullet:


	call copyBufferOver ;draw frame to screen
	call gameControls ;handle control logic
	
	jmp gameLoop

GameOver:
jmp $

moveEnemyBala:
	pusha
	mov di, word [badBullet]
	mov cx, word [di+2] ;set cx to bullet x
	mov dx, word [di+4] ;set dx to bullet z
	mov bx, word [di+8]	;direction of movement
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
		call checkForHit
		mov word [di+2] ,cx  ;update x pos
		mov word [di+4] ,dx  ;update y pos
		ret

	.destroy:
		mov word [di+10] ,30  ;update y pos
		ret


;
moveEnemy:
	pusha
	mov di, enemy1		; Seleccionamos al enemigo, meter un loop para varios
	mov ax, [di+8]		; seleccionamos el contador de activar de enemy
	cmp ax, 15			; Cada 20 llamadas de gameloop se mueve el enemigo
		je .active
	inc word [di+8]
	popa
	ret
	
	
	.active:
		mov cx, word[di+2] ;set cx to enemy x
		mov dx, word[di+4] ;set dx to enemy z
		
		mov ax, word[di+14] 
		cmp ax, 0
			je .fire
		dec word [di+14]
	.move:
		mov bx, word [di+10]	;direction of movement
		cmp bx, 0 				; choque cuadros derecha
			jne .d1
			mov bp, enemyImg_right
			cmp cx,76
				jge .turnUp
			inc cx
			call collissionsMapa
			cmp ax, 0
				jz .turnUp
			jg .back
		.d1:; choque cuadros izquierda
			cmp bx, 2 ;try to move x-1 if 'a' is pressed and set animation accordingly, test other cases otherwise
			mov bp, enemyImg_left
			jne .d2
			cmp cx,0
				jnge .turnDown
			dec cx
			call collissionsMapa
			cmp ax, 0
				jz .turnDown
			jg .back
		.d2:; choque cuadros arriba
			cmp bx, 1 ;try to move z-1 if 'w' is pressed and set animation accordingly, test other cases otherwise
			jne .d3
			mov bp, enemyImg_front
			cmp dx,3
				jnge .turnLeft
			inc dx
			call collissionsMapa
			cmp ax, 0
				jz .turnLeft
			jg .back
		.d3: ;choque cuadros de abajo
			cmp dx,40
				jge .turnRight
			dec dx
			mov bp, enemyImg_back
			call collissionsMapa
			cmp ax, 0
				jz .turnRight
			jg .back
			;ret
		;
		.checkForEnemy:
			mov bx, word [player] ;ax = entity x
			mov ax, word [player_PosX] ;ax = entity x
			sub ax, 6           ;subtract 5 because of hitbox
			cmp ax, cx ; (entityX-8 <= playerX)
				jg .update
				
			mov ax, word [player_PosX] ;ax = entity x
			add ax, 6           ;add 8 because of hitbox
			cmp ax, cx ; (entityX+8 > playerX)
				jle .update

			mov ax, word [player_PosZ] ;ax = entity z
			sub ax, 6          ;subtract 10 because of hitbox
			cmp ax, dx ; (entityZ-10 <= playerZ)
				jg .update
				
			mov ax, word [player_PosZ] ;ax = entity z
			add ax, 6           ;subtract 9 because of hitbox
			cmp ax, dx ; (entityZ+9 > playerZ)
				jle .update
			mov cx, [di+2]         ;set new x pos to current x pos => no movement
			mov dx, [di+4]
			.update:
			ret
		;
					
		.back:
			call .checkForEnemy
			mov word [di]   ,bp  ;update the animation in use
			mov word [di+2] ,cx  ;update x pos
			mov word [di+4] ,dx  ;update y pos
			mov word [di+8] ,0  ;update active count to 0
			popa                 ;reload old register state
			ret 

		.turnRight:
			mov word [di+10], 0  ;update y pos
			jmp .move
		.turnLeft:
			mov word [di+10], 2
			jmp .move
		.turnUp:
			mov word [di+10], 1
			jmp .move
		.turnDown:
			mov word [di+10], 3
			jmp .move
		
		;

	;
	.fire:
		mov si, badBullet
		mov ax, [si+10]
		; cmp ax,1
			; je .passTrigger		
		mov word[di+14], 50
		mov word[si+10], 1
		mov word[si+2], cx
		mov word[si+4], dx
		
		.passTrigger:
		jmp .move
		
		
;
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
		;mov di, word [bullet]
		call checkForHit
		mov word [bullet_PosX] ,cx  ;update x pos
		mov word [bullet_PosZ] ,dx  ;update y pos
		ret

	.destroy:
		mov word [shooting] ,0  ;update y pos
		ret



;
moveEnemyBullet:
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
		;mov di, word [bullet]
		call checkForHit
		mov word [bullet_PosX] ,cx  ;update x pos
		mov word [bullet_PosZ] ,dx  ;update y pos
		ret

	.destroy:
		mov word [shooting] ,0  ;update y pos
		ret

;
checkForHit:
	pusha
	mov si, targetBullet-2   ;set si to entityArray (-2 because we increment at the start of the loop)
	.whileLoop:
	add si, 2           ;set si to the next entry in the entityArray
	mov bx, word [si]   ;read entityArray entry
	test bx, bx         ;if entry is zero => end of array
	jz .whileEscape
	
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
	;CAMBIAR
	mov cx, [bullet+2]         ;set new x pos to current x pos => no movement
	mov dx, [bullet+4]         ;set new z pos to current z pos => no movement
	mov word[shooting], 0
	mov word[bx+12], 0
	
	.whileEscape:
	pop si					;NO ESTOY SEGURO QUE SEA ADECUADO
	; inc word [si+6]  ;update animation if moving
	; mov word [di]   ,bp  ;update the animation in use
	mov word [bullet+2] ,cx  ;update x pos
	mov word [bullet+4] ,dx  ;update y pos
	popa                 ;reload old register state
	ret

;
checkForStrike:
	pusha
	mov si, targetBadBullet-2   ;set si to entityArray (-2 because we increment at the start of the loop)
	.whileLoop:
	add si, 2           ;set si to the next entry in the entityArray
	mov bx, word [si]   ;read entityArray entry
	test bx, bx         ;if entry is zero => end of array
	jz .whileEscape
	
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
	;CAMBIAR
	call GameOver
	
	.whileEscape:
	pop si					;NO ESTOY SEGURO QUE SEA ADECUADO
	; inc word [si+6]  ;update animation if moving
	; mov word [di]   ,bp  ;update the animation in use
	mov word [bullet+2] ,cx  ;update x pos
	mov word [bullet+4] ,dx  ;update y pos
	popa                 ;reload old register state
	ret
;
drawMap:
	mov di, map2
	mov cx, [di+2]
	mov si, word [di]   ;get animation
	mov si, word [si+4] ;get first frame of animation
	; mov di, [di+4]
	.drawing:
	cmp cx, 0
		jne .drawbrick
	ret
	.drawbrick:
		mov ax, word[di+4]
		mov bx, word[di+6] ;get entity y
		push di
		mov di, map2
		call drawImage
		pop di
		add di, 4
		dec cx
		jmp .drawing
	


;
drawEntity:
	mov si, word [di]   ;get animation
	mov si, word [si+4] ;get first frame of animation
	mov ax, word [di+2] ;get entity x
	mov bx, word [di+4] ;get entity y
	call drawImage      ;draw image to buffer
	ret
	
;
collissionsMapa:
	mov si, map2
    ;CX tiene posición X
    ;DX tiene posición Z
    mov bx, [si+2]
    inc bx 
    .comparar:
	dec bx
	cmp bx, 0
	jne .compararBrick
	ret
	
    .compararBrick:
		add si, 4
        mov ax, [si] ;obtener la pos x del cubo del mapa
        sub ax, 4           ;subtract 3 because of hitbox
        cmp ax, cx ; comparar l popaas dos posiciones
        mov ax, 1
		jg .comparar
    
        mov ax, word [si] ;axsalirbtract 9 because of hitbox
		add ax, 3           ;subtract 3 because of hitbox
        cmp ax, cx ; (entityZ+9 > playerZ)
        mov ax, 1
		jle .comparar

		mov ax, word [si+2] ;obtener la pos x del cubo del mapa
        sub ax, 4           ;subtract 3 because of hitbox
        cmp ax, dx ; comparar l popaas dos posiciones
        mov ax, 1
		jg .comparar
    
        mov ax, word [si+2] ;axsalirbtract 9 because of hitbox
		add ax, 3           ;subtract 3 because of hitbox
        cmp ax, dx ; (entityZ+9 > playerZ)
        mov ax, 1
		jle .comparar
		mov cx, word[di+2]
		mov dx, word[di+4]
		mov	ax, 0
        ret

;
checkForCollision:
	push si 				;save si for lateR NO ESTOY SEGURO DE QUE ESTE BIEN
	mov si, choquesPlayer-2   ;set si to entityArray (-2 because we increment at the start of the loop)
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
	call collissionsMapa;
	pop si					;NO ESTOY SEGURO QUE SEA ADECUADO
	inc word [si+6]  ;update animation if moving
	mov word [di]   ,bp  ;update the animation in use
	mov word [di+2] ,cx  ;update x pos
	mov word [di+4] ,dx  ;update y pos
	ret



;
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
			pusha
			call checkForCollision ;check if player would collide on new position, if not change position to new position
			popa
			ret

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

;entityArray:
choquesPlayer:
			dw enemy1
			dw falcon
			dw 0
choquesEnemy:
			;dw map			No se si va a pasar
			dw player
			dw 0

targetBadBullet:
			;dw map			No se si va a pasar
			dw player
			dw falcon
			dw 0

targetBullet:
			;dw map			No se si va a pasar
			dw enemy1
			dw 0


;
enemy1:
	enemy_Anim dw enemyImg_front          	;0 puntero a animacion
	enemy_PosX dw 0x35                      ;2 pos X
	enemy_PosZ dw 0x10                      ;4 pos Z
	enemy_AnimC dw 0                       	;6 animation counter
	enemy_act	dw 0						;8 activation counter
	enemy_dir	dw 0						;10 direction counter
	enemy_life dw 1							;12
	enemy_bullet_count dw 50				;14
	enemy_bullet dw badBullet				;16
;
badBullet:
	bad_bullet_Anim dw bulletImg            ;0 puntero a la animacion
	bad_bullet_PosX dw 0x35                    ;2 brick pos x
	bad_bullet_PosZ dw 0x10                    ;4 brick pos z
	bad_bullet_AnimC dw 0                   ;6 counter animacion
	bad_bullet_dir dw 0						;8
	bad_bullet_active dw 0					;10




player:
	player_Anim dw playerImg_front          ;puntero a animacion
	player_PosX dw 30                        ;pos X
	player_PosZ dw 30                        ;pos Z
	
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
	box_PosX2 dw 0x0+15                    ;brick pos x
	box_PosZ2 dw 0x0+15                    ;brick pos z
	box_AnimC2 dw 0                      ;counter animacion

falcon:
	falcon_Anim2 dw falconImg                  ;puntero a la animacion
	falcon_PosX2 dw 0                    ;brick pos x
	falcon_PosZ2 dw 19                    ;brick pos z
	falcon_AnimC2 dw 0

;IMAGENES

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

	falconImg:
		dw 1            ;time per frames
		dw 1            ;time of animation
		dw falconImg_0     ;frames
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

	boxImg_0          incbin "img/bloque.bin"

	bulletImg_0			incbin "img/bullet.bin"

	falconImg_0		incbin "img/falcon.bin"

map:
	map_Anim dw boxImg                  ;puntero a la animacion
	cant_bricks dw 51
	dw 0			; X
	dw 4			; Y
    ;	dw 0			; Visible Flag
	;1
	dw 0
	dw 9
	;2
	dw 0
	dw 14
	;3
	dw 0
	dw 19
	;4
	dw 5
	dw 19
	;5
	dw 5
	dw 24
	;6
	dw 5
	dw 29
	;7
	dw 0
	dw 29
	;8
	dw 0
	dw 34
	;9
	dw 0
	dw 39
	;10
	dw 0
	dw 44
	;11

	dw 0
	dw 49
	;12

	; #### Y ####   (12)
	dw 5
	dw 45
	;1
	dw 10
	dw 45
	;2
	dw 15
	dw 45
	;3
	dw 20
	dw 45
	;4
	dw 25
	dw 45
	;5
	dw 30
	dw 45
	;6
	dw 35
	dw 45
	;7
	dw 40
	dw 45
	;8
	dw 45
	dw 45
	;9
	dw 50
	dw 45
	;10
	dw 55
	dw 45
	;11
	dw 60
	dw 45
	;12
	dw 65
	dw 45
	;13
	dw 70
	dw 45
	;14

	dw 75
	dw 45
	;15

map3:
	map3_Anim dw boxImg                  ;puntero a la animacion
	cant3_bricks dw 50

	dw 24
	dw 27
	;1
	dw 21
	dw 27
	;2
	dw 18
	dw 27
	;3
	dw 15
	dw 27
	;4
	dw 12
	dw 27
	;5
	dw 9
	dw 27
	;6
	dw 6
	dw 27
	;7
	dw 6
	dw 30
	;8
	dw 6
	dw 33
	;9
	dw 6
	dw 36
	;10
	dw 6
	dw 39
	;11
	dw 6
	dw 42
	;12
	dw 6
	dw 45
	;13
	dw 6
	dw 48
	; Lado 1

	dw 138
	dw 45
	;14
	dw 135
	dw 45
	;15
	dw 132
	dw 45
	;16
	dw 129
	dw 45
	;17
	dw 126
	dw 45
	;18
	dw 123
	dw 45
	;19
	dw 120
	dw 45
	;20
	dw 120
	dw 42
	;21
	dw 120
	dw 39
	;22
	dw 120
	dw 36
	;23
	dw 120
	dw 33
	;24

	;Lado 2
	dw 120
	dw 18
	;25
	dw 120
	dw 15
	;26
	dw 120
	dw 12
	;27
	dw 120
	dw 9
	;28
	dw 120
	dw 6
	;27
	dw 120
	dw 3
	;28
	dw 117
	dw 3
	;29
	dw 114
	dw 3
	;30
	dw 111
	dw 3
	;31
	dw 108
	dw 3
	;32
	dw 105
	dw 3
	;33
	dw 102
	dw 3
	;34
	dw 99
	dw 3
	;35
	dw 96
	dw 3	
	;36
	; Lado 3

	dw 156
	dw 3
	;37
	dw 156
	dw 6
	;38
	dw 156
	dw 9
	;39
	dw 156
	dw 12
	;40
	dw 156
	dw 15
	;41
	dw 156
	dw 18
	;42
	dw 156
	dw 21
	;43
	dw 153
	dw 21
	;44
	dw 150
	dw 21
	;45
	dw 147
	dw 21
	;46
	dw 144
	dw 21
	;47
	dw 141
	dw 21
	;48
	dw 139
	dw 21
	;49
	dw 136
	dw 21
	;50
	;Lado derecho arriba
map2: 
    map_Anim2 dw boxImg                  ;puntero a la animacion
	cant_bricks2 dw 107
	;0 pared lateral izquierda
		dw 10
		dw 30
		;1
		dw 0
		dw 6
		;2
		dw 0
		dw 9
		;3
		dw 0
		dw 12
		;4
		dw 0
		dw 15
		;5
		dw 3
		dw 15
		;6
		dw 6
		dw 15
		;7
		dw 9
		dw 15
		;8
		dw 12
		dw 15
		;9
		dw 12
		dw 18
		;10
		dw 12
		dw 21
		;11
		dw 12
		dw 24
		;12
		dw 9
		dw 24
		;13
		dw 6
		dw 24
		;14
		dw 3
		dw 24
		;15
		dw 0
		dw 24
		;16
		dw 0
		dw 27
		;17
		dw 0
		dw 30
		;18
		dw 0
		dw 33
		;19
		dw 0
		dw 36
		;20
		dw 0
		dw 39
		;21
		dw 0
		dw 42
		;22
		dw 0
		dw 45
		;23
		dw 0
		dw 48 
	;24 pared lateral inferior
		dw 3
		dw 48
		;25
		dw 6
		dw 48
		;26
		dw 9
		dw 48
		;27
		dw 12
		dw 48
		;28
		dw 15
		dw 48
		;29
		dw 18
		dw 48
		;30
		dw 21
		dw 48
		;31
		dw 21
		dw 45
		;32
		dw 21
		dw 42
		;33
		dw 21
		dw 39
		;34
		dw 21
		dw 36
		;35
		dw 24
		dw 48
		;36
		dw 27
		dw 48
		;37
		dw 30
		dw 48
		;38
		dw 33
		dw 48
		;39   
		dw 36
		dw 48
		;40
		dw 39
		dw 48
		;41
		dw 42
		dw 48
		;42
		dw 45
		dw 48
		;43
		dw 48
		dw 48
		;44
		dw 51
		dw 48
		;45
		dw 51
		dw 45
		;46
		dw 51
		dw 42
		;47
		dw 51
		dw 39
		;48
		dw 51
		dw 36
		;49
		dw 51
		dw 33
		;50
		dw 54
		dw 48
		;51
		dw 57
		dw 48
		;52 
		dw 60
		dw 48
		;53
		dw 63
		dw 48
		;54
		dw 66
		dw 48
		;55
		dw 69
		dw 48
		;56
		dw 72
		dw 48
		;57
		dw 75
		dw 48
	;58 oared lateral derecha
		dw 75
		dw 45
		;59
		dw 75
		dw 42
		;60
		dw 75
		dw 39
		;61
		dw 75
		dw 36
		;62
		dw 75
		dw 33
		;63
		dw 75
		dw 30
		;64
		dw 75
		dw 27
		;65
		dw 75
		dw 24
		;66
		dw 75
		dw 21
		;67
		dw 75
		dw 18
		;68
		dw 75
		dw 15
		;69
		dw 75
		dw 12
		;70
		dw 75
		dw 9
		;71
		dw 75
		dw 6
		;72
		dw 75
		dw 3
		;73
		dw 72
		dw 24
		;74
		dw 69
		dw 24
		;75
		dw 66
		dw 24
		;76
		dw 63
		dw 24
		;77
		dw 60
		dw 24
	;78 Pared Lateral superior
        dw 72
		dw 3
		;79
		dw 69
		dw 3
		;80
		dw 66
		dw 3
		;81
		dw 63
		dw 3
		;82
		dw 60
		dw 3
		;83
		dw 57
		dw 3
		;84
		dw 54
		dw 3
		;85
		dw 51
		dw 3
		;86
		dw 48
		dw 3
		;87
		dw 45
		dw 3
		;88
		dw 42
		dw 3
		;89
		dw 39
		dw 3
		;90
		dw 36
		dw 3
		;91
		dw 33
		dw 3
		;92
		dw 30
		dw 3
		;93
		dw 27
		dw 3
		;94
		dw 24
		dw 3
		;95
		dw 21
		dw 3
		;96
		dw 18
		dw 3
		;97
		dw 15
		dw 3
		;98
		dw 12
		dw 3
		;99
		dw 9
		dw 3
		;100
		dw 6
		dw 3
		;101
		dw 3
		dw 3	
		;102
;Diferentes? 
			dw 40
			dw 40
		;103
			dw 55
			dw 40
		;104
			dw 36
			dw 12
		;105
			dw 36
			dw 15
		;106
			dw 0
			dw 0
%assign usedMemory ($-$$)
%assign usableMemory (512*16)
%warning [usedMemory/usableMemory] Bytes used
times (512*16)-($-$$) db 0