
global Offset_asm


Offset_asm:
    ;rdi => src, rsi => dst, rdx => filas, rcx => cols, r8 => src_row_size
	; prologo
	push rbp
	mov rbp, rsp

    .ciclo:
		movdqa xmm1, [rdi]							; cargo 128 bits, 16bytes, 4pixel
		; cargo los 4pixel rdi+32
		; cargo los 4pixel rdi+r8*8
		; cargo los 4pixel rdi+r8*8+32

		; puedo procesar los 4pixel a la vez
		; uso PSHUFB para para crear dos registros con los bytes alineados
		; uso PADDB para sumar byte a byte


	; epilogo
	pop rsp, rbp
	ret
	


