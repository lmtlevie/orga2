section .rodata
sharpen: dd -1.0, -1.0, -1.0, -1.0, 9.0, -1.0, -1.0, -1.0, -1.0
solo_alpha: db 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255

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

	; cargada de registros iniciales
	xor r13, r13 ; r13 = 0, guardamos en r13 el desplazamiento en src
	mov r14, r9 ; r14 = 0, guardamos en r14 los valores de los pixeles en cada ciclo
	mov r15, rcx ; r15 = height, guardamos en r15 la altura de la imagen como contador
	movdqu xmm10, [solo_alpha]

	xor rcx, rcx
	mov rcx, r9
    dec rcx
	sub rcx, 8 ; rcx = src_row_size - 8 pixels de borde

    .primeraFila:
        movups [rsi], xmm10
        add r13, 16
        add rsi, 16                ; 4(px) * 4(bytes cada px)
        cmp r13, r8
        jne .primeraFila
    ;Todos negros en la primera fila

	.filtro:
	cmp r15, 0 
	je .fin

	pxor xmm6, xmm6 ; pixel 1
	pxor xmm7, xmm7 ; pixel 2
	pxor xmm8, xmm8 ; pixel 3
	pxor xmm9, xmm9 ; pixel 4
	xor r9, r9 ; r9 = ii

	.loopfilaSharpen:
	cmp r9, 3 ; Si ii = 3 paso a siguiente pixel

	je .finSharpen
	xor r10, r10 ; r10 = jj

	.loopColSharpen:
	mov r11, 12
	imul r11, r9 ; r11 = 12*ii
	movdqu xmm1, [sharpen + r11 + r10*4] ; xmm1 = [a, b, c, d]
	shufps xmm1, xmm1, 0x00 ; xmm1 = [a, a, a, a]

	;calculo en r11 el offset
	mov r11, r8 ; r11 = row_size  
	imul r11, r9 ;  r11 = row_size * ii

	mov r12, r10 ; r12 = jj
	imul r12, 4 ; r12 = jj * 4 (4 bytes por pixel)

	add r11, r12 ; r11 = row_size * ii + jj * 4

	movdqu xmm0, [rdi + r11] ; Cargo 2 pixeles

	;Extender los pixeles a double word
	pmovzxbd xmm2, xmm0 
	psrldq xmm0, 4 
	pmovzxbd xmm3, xmm0 
	cvtdq2ps xmm2, xmm2 
	cvtdq2ps xmm3, xmm3 

    ; Hago la multiplicacion por el valor [ii][jj] de la matriz sharpen

	mulps xmm2, xmm1
	mulps xmm3, xmm1
	; Hago la suma saturada

	addps xmm6, xmm2
	addps xmm7, xmm3

	inc r10
	cmp r10, 3
	jne .loopColSharpen
	inc r9
	jmp .loopfilaSharpen

	.finSharpen:
	cvtps2dq xmm6, xmm6 ; float a int
	cvtps2dq xmm7, xmm7

	; empaquetado
	packssdw xmm6, xmm7
	por xmm6, xmm10 ; alpha en 255

	movdqu [rsi + 4], xmm6 ; guardo resultado en dst[i+1][j+1]

	add rdi, 8 ; avanzamos 4 pixel de lectura en src
	add rsi, 8; avanzamos 4 pixel de escritura en dst
	add r13, 8; sumamos 4 pixel al desplazamiento total en src

	cmp r13, rcx 
	jl .filtro

	.sigLinea:
	xor r13, r13 ; reiniciamos el desplazamiento en src
	
	dec r15	
	jmp .filtro
	
	.fin:
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
	ret