
global Offset_asm

ocho:
	db 8

init_reg:
	times 4 db ffh, 00h, 00h, 00h

mb:
	times 4 db 00h, 00h, 00h, 01h

mc:
	times 4 db 00h, 00h, 01h, 00h

md:
	times 4 db 00h, 01h, 00h, 00h

Offset_asm:				; RDI=src, RSI=dst, RDX=filas, RCX=cols, R8=src_row_size
	; prologo
	push rbp
	mov rbp, rsp

	IMUL r8, [ocho]						; r8 = offset 8 filas
	MOV r9, rdi							; r9 = src
	ADD r9, 32							; r9 = src + 8 cols
	ADD r9, r8							; r9 = src + 8 cols + offset 8 filas
	
	.ciclo:
		MOVDQA xmm0, [r9]					; xmm0 = A
		MOVDQA xmm1, [r9 + 32]				; xmm1 = C
		MOVDQA xmm2, [r9 + r8]				; xmm2 = B
		MOVDQA xmm3, [r9 + r8 + 32]			; xmm3 = D
		
		MOVDQA xmm4, [mb]					; xmm4 = mask b
		MOVDQA xmm5, [init_reg]				; xmm5 = hardcoded 255
		PBLENDVB xmm5, xmm2, xmm4

		MOVDQA xmm4, [mc]					; xmm4 = mask c
		PBLENDVB xmm5, xmm1, xmm4

		MOVDQA xmm4, [md]					; xmm4 = mask d
		PBLENDVB xmm5, xmm3, xmm4

		MOVDQA [rsi + 32 + r8], xmm5

	; epilogo
	pop rbp
	mov rsp, rbp
	ret