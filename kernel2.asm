org 0x8000      ;Set assembler location counter
bits 16

; Modo grafico
call initGraphics
%include "buffer.asm"
;loop principal
gameLoop:
    call resetBuffer        ;resetea la pantalla llamada desde buffer.asm

    ; DRAW A BRICK
    ;mov cx, [player+2]      ;dibuja relativamente x
    ;mov dx, [player+4]      ;
    mov di, map
    call printMap

printMap:
	mov si, word [di]   ;get animation
	mov si, word [si+2] ;get first frame of animation
	;mov ax, word [di+2] ;get entity x
	
    mov ax, word [di+4] ;get entity x1
	mov bx, word [di+6] ;get entity y1
    call drawImage      ;draw image to buffer


    mov ax, word [di+8] ;get entity x1
	mov bx, word [di+10] ;get entity y1
	call drawImage      ;draw image to buffer

	;sub ax, cx          ;subtract the position of the player from the x position
	;add ax, 80/2 - 9/2 - 1  ;relative to screen image drawing code for x position
	;mov bx, word [di+4] ;get entity y
	;sub bx, dx          ;subtract the position of the player from the z position
	;add bx, 50/2 - 12/2 - 1 ;relative to screen image drawing code for z position
	;call drawImage      ;draw image to buffer
	ret


map:
    box_Anim dw boxImg                  ;puntero a la animacion
    box_AnimC dw 0                      ;counter animacion
    dw 0x0                    ;brick pos x
    dw 0x0                    ;brick pos z

    dw 0x0                    ;brick pos x
    dw 0x3                    ;brick pos z

    dw 0x0                    ;brick pos x
    dw 0x6                    ;brick pos z

    dw 0x0                    ;brick pos x
    dw 0x9                    ;brick pos z

    dw 0x0                    ;brick pos x
    dw 0x12                    ;brick pos z

boxImg:
    dw 1            ;time per frames
    dw 1            ;time of animation
    dw boxImg_0     ;frames
    dw 0            ;zero end frame

boxImg_0          incbin "img/brick.bin"
%assign usedMemory ($-$$)
%assign usableMemory (512*16)
%warning [usedMemory/usableMemory] Bytes used
times (512*16)-($-$$) db 0