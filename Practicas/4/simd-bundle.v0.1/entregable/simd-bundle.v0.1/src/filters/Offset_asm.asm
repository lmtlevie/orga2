section .rodata

MASK_TRASP: db 0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1
MASK_RED:	db 0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0

MASK_GREEN:	db 0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0
MASK_BLUE:	db 1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0
TODOS_NEGROS:  db 0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255

section .data
	%define offset_pixels 16
	mask: times 4 db 0xFF


section .text
global Offset_asm
Offset_asm: 
    push rbp
    mov rsp, rbp
    push rbx
    push r12
    push r13
    push r14
    push r15
    ;PREPARO PARA PONER TODOS EN NEGRO
        lea rbx, [rdi]
        lea r12, [rsi]
        xor r13, r13 ;desplazamiento del src
        xor r14, r14 ;desplazamiento del dst
        mov r15, rcx ; Altura de la imagen
        push rcx

        xor rcx, rcx
        mov rcx, r8
        movdqu xmm15, [TODOS_NEGROS] 

        .cicloNegro:
            cmp r15, 0
            je .filtro

            movdqu [r12], xmm15 ;Directamente cargo el color negro en el resultado
            add rbx, offset_pixels ; avanzamos 4 pixeles de lectura en src
            add r12, offset_pixels ; avanzamos 4 pixeles de escritura en dst

            add r13, offset_pixels ; sumamos 4 pixeles al desplazamiento total en src
            add r14, offset_pixels ; sumamos 4 pixeles al desplazamiento total en dst

            cmp r13, rcx ; si nos desplazamos el ancho de la imagen hacemos .sigFila sino seguimos con .ciclo
            jl .cicloNegro

            .sigFilaNegro:
                xor r13, r13 ; reiniciamos el desplazamiento en src
                xor r14, r14 ; reiniciamos el desplazamiento en dst
                dec r15	
                jmp .cicloNegro
    ;LO que hace es poner todo en negro al principio en dst y despues aplico el filtro, se puede mejorar
	
    .filtro:
        imul r9, 8 ; r9 = dst_row_size * 8

        lea rbx, [rdi] ; rbx = src
        lea r12, [rsi] ; r12 = dst
        xor r13, r13 ; r13 = 0, guardamos en r13 el desplazamiento en src
        xor r14, r14 ; r14 = 0, guardamos en r14 el desplazamiento en dst
        pop rcx
        mov r15, rcx ; r15 = height, guardamos en r15 la altura de la imagen

        xor rcx, rcx
        mov rcx, r8 ; rcx = src_row_size
        sub rcx, offset_pixels*4 ; rcx = src_row_size - 16 pixels de borde

        add r12, r9 ; r12 = dst + dst_row_size * 8
        add rbx, r9 ; rbx = src + dst_row_size * 8
        add r12, offset_pixels*2 ; avanzo 8 pixeles de inicializacion
        add rbx, offset_pixels*2
        sub r15, 16 ; r15 = height - 16 pixeles, 8 arriba, 8 abajo

		PMOVZXBD xmm15, [mask] ;xmm15 = alpha mask
		pslld xmm15, 24
		PMOVZXBD xmm14, [mask] ;xmm14 = red mask
		pslld xmm14, 16
		PMOVZXBD xmm13, [mask] ;xmm13 = green mask
		pslld xmm13, 8
		PMOVZXBD xmm12, [mask] ;xmm12 = blue mask sin shift ya que lo necesitamos en 0x000000FF
		;Me creo las mascaras

    .cicloGrande:
        cmp r15, 0 ;Si llegue a la maxima fila termino
        je .fin

		movdqu xmm1,[rbx] ; Primeros 4 pixeles
		movdqu xmm2,[rbx+32] ; Los otros 4 pixeles que estan 8 a la derecha del primero
		movdqu xmm3,[rbx+r8*8] ;Primeros 4 pixeles 4 filas por abajo
		movdqu xmm4,[rbx+r8*8+32] ; 8 filas por abajo y 8 columnas a la derecha
		
		;
        movdqa xmm11, xmm12
        pand xmm11, xmm3 ;xmm11 ahora tiene solo el dato azul del pixel en i+8


        movdqa xmm10, xmm13
        pand xmm10, xmm2 ;xmm10 ahora tiene solo el dato verde del pixel en j+8

		movdqa xmm9, xmm14
        pand xmm9, xmm4 ;xmm9 ahora tiene solo el dato rojo del pixel en (i+8)(j+8)

        por xmm11, xmm10
        por xmm11, xmm9
        paddd xmm11, xmm15

        movdqu [r12], xmm11

        add rbx, offset_pixels ; avanzamos 4 pixeles de lectura en src
        add r12, offset_pixels ; avanzamos 4 pixeles de escritura en dst
        
        add r13,offset_pixels
        add r14, offset_pixels

        cmp r13, rcx; si llegamos al fin de la fila hacemos el cambio
        jl .cicloGrande

        xor r13,r13
        xor r14,r14

        dec r15
        add rbx, offset_pixels*4 ;Nos movemos 16 pixeles
        add r12, offset_pixels*4
        jmp .cicloGrande 

    .fin:
        pop r15
        pop r14
        pop r13
        pop r12
        pop rbx
        pop rbp
        ret