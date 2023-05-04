global checksum_asm

section .rodata
	_8: times 8 dw 8


section .text

; uint8_t checksum_asm(void* array = rdi, uint32_t n = rsi)

checksum_asm:
	push rbp
	mov rbp,rsp

	mov rcx, rsi
	pxor xmm3, xmm3
	movdqu xmm3, [_8]

	.ciclo:
		movdqa xmm0, [rdi] 		; | a1 | a2 | a3 | a4 | | a5 | a6 | |a7| |a8| = 128 bits
		movdqa xmm1, [rdi+16] 	; | b1 | b2 | b3 | b4 | | b5 | b6 | |b7| |b8| = 128 bits
		movdqa xmm2, [rdi+32] 	; | c1 | c2 | c3 | c4 | = 128 bits
		movdqa xmm6, [rdi+48]   ; | c5 | c6 | c7 | c8 | = 128 bits
		paddw xmm0, xmm1        ; | a1+b1 | a2+b2 | a3+b3 | a4+b4 | | a5+b5 | a6+b6 | |a7+b7| |a8+b8| = 128 bits

		movdqu xmm4, xmm0 		;xmm4 = xmm0
		pmullw xmm0, xmm3		;xmm0 = |lw((a1+b1)*8)|..............|lw((a8+b8)*8)|
		pmulhw xmm4, xmm3		;xmm4 = |hi((a1+b1)*8)|..............|hi((a8+b8)*8)|

		movdqa xmm5, xmm0		;xmm5 = xmm0
		punpcklwd xmm0, xmm4	;xmm0 = | hi:low(a3*b3) ... hi:low(0a*b0) |
		punpckhwd xmm5, xmm4	;xmm5 = | hi:low(a7*b7) ... hi:low(a4*b4) |

		pcmpeqd xmm0, xmm2
		ptest xmm0, xmm0
		jz .notEqual
		pcmpeqd xmm5, xmm6
		ptest xmm5, xmm5
		jz .notEqual

		add rdi, 64
	loop .ciclo

	mov rax, 1
	pop rbp
	ret

	.notEqual:
		mov rax, 0
		pop rbp
		ret