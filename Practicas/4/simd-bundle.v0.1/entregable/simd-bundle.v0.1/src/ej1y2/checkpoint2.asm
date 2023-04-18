
section .text

global checksum_asm

; uint8_t checksum_asm(void* array, uint32_t n)
;1 si (cji = (aji + bji)*8 
checksum_asm:
	push rbp
	mov rbp,rsp
	mov rcx, rsi
	.ciclo:
		movd xmm0, [rdi]	;a
		movd xmm1, [rdi+ 128] ;b
		movd xmm2, [rdi + 256] ;c0 a c3
		movd xmm3, [rdi+ 128*3] ;c4 a c8
		
		; extinedo a 32 bits
		punpckhwd xmm4, xmm0;
		punpcklwd xmm5, xmm0; 
		punpckhwd xmm6, xmm1;
		punpcklwd xmm7, xmm1;
		
		;sumo a + b
		paddd xmm4, xmm6
		paddd xmm5, xmm7
		movdqa xmm6, xmm4
		movdqa xmm8, xmm5
	
		;
		mov ebx ,8
		movd xmm0, ebx
		punpckldq xmm0,xmm0
		pmulhw xmm4, xmm0 ;a0+b0, a1+b1 . *8
		pmullw xmm6, xmm0  ; 
		pmulhw xmm5, xmm0 
		pmullw xmm8, xmm0  

		;Separo los c en 2 y los extiendo a 64 bits
		punpckldq xmm9, xmm2
		punpckhdq xmm10, xmm2
		punpckldq xmm11, xmm3
		punpckhdq xmm12, xmm3

		
		comisd xmm9, xmm4 ;Comparo A1+B1=C, A2+B2)*8=C2
		jnz mal
		comisd xmm10, xmm5 ;Comparo A1+B1=C, A2+B2)*8=C2
		jnz mal
		comisd xmm11, xmm6 ;Comparo A1+B1=C, A2+B2)*8=C2
		jnz mal
		
		comisd xmm12, xmm7 ;Comparo A1+B1=C, A2+B2)*8=C2
		jnz mal
		add rdi, 128*4
		dec rcx
		jnz .ciclo
		

	mov rax,1
	jmp final
	mal:
		mov rax, 0
	
	final:
		mov rsp, rbp
		pop rbp
		ret  

