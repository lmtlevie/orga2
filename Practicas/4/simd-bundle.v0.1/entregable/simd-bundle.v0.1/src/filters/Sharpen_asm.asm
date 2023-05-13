
extern malloc
extern free

section .rodata
sharpen: dd -1.0, -1.0, -1.0, -1.0, 9.0, -1.0, -1.0, -1.0, -1.0
solo_alpha: db 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255
pixel_negro : db 0,0,0,255
section .text
	%define offset_pixels 16
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

	;Poner primera fila en negro
	movdqu xmm6, [solo_alpha]
	movd xmm10, [pixel_negro]
	
	xor r10, r10

	.filaNegro:
		movdqu [rsi + r10] , xmm6
		add r10, 16
		cmp r10, r8
		jne .filaNegro
	
	push rsi
	push rdi
	sub rcx, 2
	sub rdx, 2
	xor r10, r10
	add rsi, r9
	add rdi, r8 

	ciclo:
		;Poner primer pixel en negro en 0,0,0,255
		movd [rsi], xmm10
		xor r12, r12 ;La columna por la que voy
		xor r13, r13 ;El ii
		cmp r10, rcx ;Si llegue a la ultima fila
		je fin
		;SINO   TENGO QUE SEGUIR CICLANDO
		pxor xmm6, xmm6
		pxor xmm7, xmm7
		;Voy guardando los totalB,G,R
		loopI:
			cmp r13, 3 
			je finSharpen
			xor r14, r14 ; El JJ
			loopJJ:
			;Tengo que calcular que valor de sharpen corresponde
			mov r11, 12
			imul r11, r13
			movdqu xmm1, [sharpen + r11 + r10*4]
			shufps xmm1, xmm1, 0x00 ; xmm1 = [a, a, a, a]

			;Que valor necesito del rdi
			;[i+ii][j+jj	
			mov r15, r8
			imul r15, r13

			mov r11, r14
			imul r11, 4 ;Cada pixel ocupa 4
			add r15, r11
			add r15, r12 ;Por el pixel en el  que iba
			movdqu xmm2, [rdi + r15] ; |PIXEL1|PIXEL2|PIXEL3|PIXEL4|
			;NECESITO PARASARLO A 32 BITS CADA PIXEL Y QUEDARME SOLO CON 1 Y 2
			pmovzxbd xmm3, xmm2 ; extiendo el primer pixel de byte a double word (empaquetados)
			psrldq xmm2, 4
			pmovzxbd xmm4, xmm2 ; extiendo el primer pixel de byte a double word (empaquetados)
			;XMM3 = |0|0|0|PIXEL1|
			;XMM4 = |0|0|0|PIXEL2|

			cvtdq2ps xmm2, xmm2 ; convierto el primer pixel de int a float
			cvtdq2ps xmm3, xmm3 ; convierto el segundo pixel de int a float

			mulps xmm2, xmm1 ;Multiplico por el sharpen
			mulps xmm3, xmm1 ;Multiplico por el sharpen

			addps xmm6, xmm2
			addps xmm7, xmm3

			inc r14
			cmp r14, 3
			jne loopJJ
			inc r13 
			jmp loopI
		finSharpen:
		;Ya tengo los valores de sharpen en xmm6 y xmm7
		;Tengo que juntarlos y guardarlos en dst[i+1][j+1]
		;XMM6 = |B|G|R|A|
		;XMM7 = |B|G|R|A|
		cvtps2dq xmm6, xmm6 ; float a int
		cvtps2dq xmm7, xmm7

		packssdw xmm6, xmm7 ; empaqueto los 4 int en 2 double word
		packssdw xmm6, xmm6 ; Tengo los dos pixeles repetidos en cada mitad
		
		movq [rsi + r15 + 4], xmm6 ; Guardo 2 pixeles

		add r15, 8
		cmp r15, r8
		jne ciclo
		;Si  son iguales es porque estoy en la ultima columna
		add rdi, r8
		add rsi, r8
		xor r15, r15
		inc r10
		jmp ciclo

	;No toco primera fila

	fin:
	
	pop rdi
	pop rsi
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
	ret