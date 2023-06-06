section .rodata
	sharpen: dd -1.0, -1.0, -1.0, -1.0, 9.0, -1.0, -1.0, -1.0, -1.0
	solo_alpha: db 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255
	pixel_negro : db 0,0,0,255
	cut: db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
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
	push rsi
	xor r10, r10

	movdqu xmm10, [solo_alpha]

	movdqu xmm13, [cut]
    psrldq xmm13, 4
    por xmm13, xmm10

	xor r10, r10
	top_black:
		movups [rsi + r10], xmm10
		add r10, 4*4                ; 4(px) * 4(bytes cada px)
		cmp r10, r
		jne top_black


	sub rdx, 2 ; 3 porque termina en ancho -3 y 1 porque no me importa el primero
	sub rcx, 1	; sub rcx, 2  -> con esto no pierde memoria y deja la linea blanca abajo
	sub r9, 2
	xor r10, r10

	ciclo:
		;Si no estoy en caso r10 = altura
		xor r11, r11 ; r11 = ii
		pxor xmm6, xmm6 ; pixel 1
		pxor xmm7, xmm7 ; pixel 2
		pxor xmm8, xmm8 ; pixel 3
		pxor xmm9, xmm9 ; pixel 4

		.cicloSharpenII:
			cmp r11, 3
			je finSharpen
			xor r12, r12 ; R12 = JJ
	
			.cicloSharpenJJ:
				;Tengo que cargar la mascara del sharpen , los valores [i + ii][j + jj]
				mov r13, 12
				imul r13, r11
				movdqu xmm1, [sharpen + r13 + r12*4]
				shufps xmm1, xmm1, 0x00 ; xmm1 = [a, a, a, a]
				;Cargo sharpen [ii][jj]

				;Calcular desplazamiento para i + ii
				mov r13, r8
				imul r13, r11
				;Calcular desplazamiento para j + jj
				mov r14, r12
				imul r14, 4

				add r13, r14

				movq xmm0, [rdi + r13] ;|PIXEL1|PIXEL2|PIXEL3|PIXEL4|

				pmovzxbd xmm2, xmm0 ; extiendo el primer pixel de byte a double word (empaquetados)
				psrldq xmm0, 4 ; shift xmm0 4 bytes a la derecha
				pmovzxbd xmm3, xmm0 ; extiendo el segundo pixel de byte a double word (empaquetados)
				psrldq xmm0, 4 ; shift xmm0 4 bytes a la derecha
								
				cvtdq2ps xmm2, xmm2 ; convierto el primer pixel de int a float
				cvtdq2ps xmm3, xmm3 ; convierto el segundo pixel de int a float
				
				mulps xmm2, xmm1
				mulps xmm3, xmm1
			
		 		addps xmm6, xmm2
				addps xmm7, xmm3
				;; AUMENTAR JJ EN 1 Y CHEQUEAR SI ES IGUAL A 3

				inc r12
				cmp r12, 3
				jne .cicloSharpenJJ
				inc r11
				jmp .cicloSharpenII
			
			finSharpen:
				;Tengo que convertir los valores a int y pasarlos a 8 bits de manera saturada
				cvtps2dq xmm6, xmm6
				cvtps2dq xmm7, xmm7
		
				packssdw xmm6, xmm7
				packuswb xmm6, xmm6
			
			    por xmm6, xmm10 ; alpha en 255
				;por xmm6, xmm10 ; alpha en 255

				movq [rsi + r8 + 4], xmm6

				add rsi, 8 ;2 PIXELES
				add rdi, 8 ;2 PIXELes

				add r15, 8;2 PIXELES

				cmp r15, r9
				jl  ciclo

				;Si cambie de fila
				inc r10
				sub rsi, 16
				movdqu xmm0, [rsi + r8+ 4]
				pand xmm0, xmm13
				movups [rsi + r8+ 4], xmm0
				add rsi, 16 ;2 PIXELES
				sub rsi, 20
				movdqu xmm0, [rsi + r8+ 4]
				pand xmm0, xmm13
				movups [rsi + r8+ 4], xmm0
				add rsi, 20 ;2 PIXELES
				xor r15, r15
				cmp r10, rcx	
				jne ciclo


			fin:
				sub rsi, 8
				add rsi, r8
				xor r10, r10
				btm_black:
					movups [rsi + r10], xmm10

					add r10, 4*4                ; 4(px) * 4(bytes cada px)
					cmp r10, r8
					jne btm_black
				pop rsi
				pop r15
				pop r14
				pop r13
				pop r12
				pop rbx
				pop rbp				
				ret

