
section .rodata
sharper: dd	-1.0, -1.0, -1.0,1.0, -1.0, 9.0, -1.0,1.0, -1.0, -1.0, -1.0,1.0 ;Agrego los 1 asi cuando multiplico por transperencia no afecta nada
todo_negro: db 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255

section .text
	%define offset_pixels 4
	%define float_size 4
	%define pixel_size 4
	

global Sharpen_asm


; *src uint_8[rdi], *dst uint_8[rsi], width uint_32[rdx], height uint_32[rcx],
; src_row_size uint_32[r8], dst_row_size uint_32[r9]
Sharpen_asm:
	push rbp
	mov rbp, rsp
	push rbx
	push r12
	push r13
	push r14
	push r15

	; cargada de registros iniciales
	lea rbx, [rdi] ; rbx = src
	lea r12, [rsi] ; r12 = dst
	xor r13, r13 ; r13 = 0, guardamos en r13 el desplazamiento en src
	xor r14, r14 ; r14 = 0, guardamos en r14 los valores de los pixeles en cada ciclo
	mov r15, rcx ; r15 = height, guardamos en r15 la altura de la imagen como contador
	;dec r15, 4

	.filtro:
	cmp r15, 0
	je .fin

	xor r9, r9 ; r9 = ii
	.loopfilaSharpen:
	cmp r15, 0
	je .fin
	xor r10, r10 ; r10 = jj
	pxor xmm7, xmm7
	pxor xmm6, xmm6
	mov r9, r8
	.loopcolumnaSharpen:

		movdqu xmm1, [sharper + r10*4 + 4 ]

		;shufps xmm1, xmm1, 0x00 ; xmm1 = [a, a, a, a] ;Levanto 4 valores de la matriz sharper
		;Tengo que cargar dos pixeles de src, cada color de uno lo extiendo a 32  bits y lo guardo en un xmm distitno

		;Necesito el pixel [i +ii][j+jj] y [i +ii + 1][j+jj + 1]
		;En la primer vuelta en rbx tengo el pixel i. Tengo que obtener el pixel + jj , y el que esta  

		PMOVZXBD xmm4, [rdi  + r9] ; xmm4 = [b, g, r, a] ;Pixel i + ii
		PMOVZXBD xmm5, [rdi  + r9 + 4] ; xmm5 = [b, g, r, a] ;Pixel i + ii + 1
		CVTDQ2PS xmm4, xmm4
		CVTDQ2PS xmm5 , xmm5
		;Ahora tengo que multiplicar cada color de cada pixel por el valor de la matriz sharper
		MULPS xmm4, xmm1 ; xmm2 = [b, g, r, a] ;Pixel i
		MULPS xmm5, xmm1 ; xmm3 = [b, g, r, a] ;Pixel i + 1
		;Ahora tengo que sumar los valores de cada color de cada pixel
		paddd xmm6, xmm4 ; xmm6 = [b, g, r, a]* sharpen ;Pixel i. Lo uso de acumulador
		paddd xmm7, xmm5 ; xmm7 = [b, g, r, a] ;Pixel i + 1. Lo uso de acumulador
		;Tengo que chequear si j = 3
		inc r10
		cmp r10, 3
		jne .loopcolumnaSharpen
		add r9, r8
		jmp .finColSharpen

	.finColSharpen:
		;Tengo que  pasar los valores de xmm6 de floats a int y despues a 8 bits
		;Tengo que  pasar los valores de xmm7 de floats a int y despues a 8 bits
		cvtps2dq xmm6, xmm6 ; xmm6 = [b, g, r, a] ;Pixel i
		packssdw xmm6, xmm6 ; xmm6 = [b, g, r, a] ;Pixel i
		cvtps2dq xmm7, xmm7 ; xmm7 = [b, g, r, a] ;Pixel i + 1
		packssdw xmm7, xmm7 ; xmm7 = [b, g, r, a] ;Pixel i + 1
		;Ahora tengo que guardar los valores de xmm6 y xmm7 en dst
		;Estan en 16 bits
		packsswb xmm6, xmm6 ; pasamos a 8 bits
		pextrd r14d, xmm6, 0 ; guardamos en r14d el valor de la parte baja de xmm0
		mov r14b, BYTE [rbx+3] ; guardamos el valor de alpha en r14b
		mov DWORD [r12  + 4], r14d ; guardo resultado en dst[i+1][j+1]
		packsswb xmm7, xmm7 ; pasamos a 8 bits
		pextrd r14d, xmm7, 0 ; guardamos en r14d el valor de la parte baja de xmm0

		mov r14b, BYTE [rbx+3] ; guardamos el valor de alpha en r14b
		mov DWORD [r12  + 8], r14d ; guardo resultado en dst[i+2][j+2]
	
	;Hice un ciclo de un pixel, ahora tengo que avanzar 4 bytes en src y dst porque son  2 pixeles por iteracion
	dec r9
	add r13, 4
	add rbx, 4
	add r12, 4
	cmp r13, rdx
	jne .mismaFila
	add rbx, 8 ; Avance 2 pixeles
	add r12, 8
	mov r13, 4 ; Estoy en el pixel de la columna 4 ahora
	dec r15
	.mismaFila:
	jmp .loopfilaSharpen

	.fin:
		pop r15
		pop r14
		pop r13
		pop r12
		pop rbx
		mov rsp, rbp
		pop rbp
	ret
