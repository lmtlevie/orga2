extern sumar_c
extern restar_c
extern operacion
;########### SECCION DE DATOS
section .data

;########### SECCION DE TEXTO (PROGRAMA)
section .text

;########### LISTA DE FUNCIONES EXPORTADAS

global alternate_sum_4
global alternate_sum_4_simplified
global alternate_sum_8
global product_2_f
global alternate_sum_4_using_c

;########### DEFINICION DE FUNCIONES
; uint32_t alternate_sum_4(uint32_t x1, uint32_t x2, uint32_t x3, uint32_t x4);
; registros: x1[edi], x2[esi], x3[edx], x4[ecx]
alternate_sum_4:
	;prologo
	push rbp 
	mov rbp,rsp
	sub rsp, 8

	sub rdi, rsi
	add rdi, rdx
	sub rdi, rcx

	mov rax, rdi

	;recordar que si la pila estaba alineada a 16 al hacer la llamada
	;con el push de RIP como efecto del CALL queda alineada a 8

	;epilogo
	mov rsp, rbp
	pop rbp
	ret

; uint32_t alternate_sum_4_using_c(uint32_t x1, uint32_t x2, uint32_t x3, uint32_t x4);
; registros: x1[rdi], x2[rsi], x3[rdx], x4[rcx]
alternate_sum_4_using_c:
	;prologo
	push rbp 
	mov rbp,rsp
	sub rsp, 8


	; COMPLETAR
	call operacion

	;epilogo
	mov rsp, rbp
	pop rbp
	ret



; uint32_t alternate_sum_4_simplified(uint32_t x1, uint32_t x2, uint32_t x3, uint32_t x4);
; registros: x1[?], x2[?], x3[?], x4[?]
alternate_sum_4_simplified:
	call operacion
	ret


; uint32_t alternate_sum_8(uint32_t x1, uint32_t x2, uint32_t x3, uint32_t x4, uint32_t x5, uint32_t x6, uint32_t x7, uint32_t x8);
; registros y pila: x1[rdi], x2[rsi], x3[rdx], x4[rcx], x5[r8], x6[r9], x7[rbp+0x10], x8[rbp+ 0x18]
alternate_sum_8:
	;prologo
	push rbp ; alineado a 16
	mov rbp,rsp
	sub rsp, 8

	; x1 - x2 + x3 - x4 , misma idea que alternate sum
	mov rax, rdi
	sub rax, rsi
	add rax, rdx
	sub rax, rcx

	;// devuelve el resultado de la operación x1 - x2 + x3 - x4 + x5 - x6 + x7 - x8
	add rax, r8
	sub rax, r9
	add rax, [rbp+0x10]
	sub rax, [rbp+0x18]
	;--------

	;epilogo
	mov rsp, rbp
	pop rbp	
	ret


; SUGERENCIA: investigar uso de instrucciones para convertir enteros a floats y viceversa
;void product_2_f(uint32_t * destination, uint32_t x1, float f1);
;registros: destination[rdi], x1[rsi], f1[XMM0]

product_2_f:
	; El x1 esta en rsi y el f1 en XMM0
	; El resultado se almacena en XMM1
	; El resultado se almacena en rax
	push rbp
	mov rbp, rsp
	sub rsp, 4

	cvtsi2ss   xmm1, rsi
	;cvtss2sd xmm0, xmm0
	mulss xmm1, xmm0
	;la direccion del resultado se almacena en rdi, el resultado debe ser truncado
	cvttss2si eax, xmm1
	mov [rdi], eax

	;epilogo
	mov rsp, rbp
	pop rbp
	ret
