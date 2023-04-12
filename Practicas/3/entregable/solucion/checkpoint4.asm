extern malloc
extern free
extern fprintf
extern esMenorChar
extern esMayorChar
extern freeC
extern fprintfC


section .data

section .text

global strCmp
global strClone
global strDelete
global strPrint
global strLen

; ** String **

; int32_t strCmp(char* a, char* b)


strCmp:
	mov r8, rdi
	mov r9, rsi
	mov r10, 0
	call strLen
	mov rcx, rax
	mov rdi, r9
	call strLen
	mov r11, rax
	;
	jmp max

	loopCmp:
		cmp r10, rcx
		je finCmp
		mov dil, [r8 + r10]
		mov sil, [r9 + r10]
		inc r10
		CMP dil, sil
		;si es menor
		jl aMenor
		;si es mayor
		jg aMayor
		;si son iguales
		jmp loopCmp

	finCmp:
		mov rax, 0
		ret

	aMenor:
		mov rax, 1
		ret
	aMayor:
		mov rax, -1
		ret
	max:
		cmp rcx, r11
		jg loopCmp     ; saltar si a > b
		mov rcx, r11   ; si a < b, mover b a rcx
		jmp loopCmp	

; char* strClone(char* a)
strClone:
	push rbp
	mov rbp, rsp
	push rbx
	sub rsp, 8

	mov rbx, rdi
	;reservo memoria
	call strLen
	mov rdi, rax
	add rdi, 1
	call malloc wrt ..plt

	mov rdi, rbx
	mov r10, 0 ;contador

	loop_clone:
	mov r11b, [rdi + r10]
	cmp r11b, 0
	je fin_clone
	mov [rax + r10], r11b
	inc r10
	jmp loop_clone
	
	fin_clone:
	mov byte [rax + r10], 0
	add rsp, 8
	pop rbx
	pop rbp
	ret

; void strDelete(char* a)
strDelete:
	push rbp
	mov rbp, rsp
	call freeC
	
	pop rbp
	ret

; void strPrint(char* a, FILE* pFile)
strPrint:
	push rbp
	mov rbp, rsp

	mov r9, rdi
	mov rdi, rsi
	mov rsi, r9
	call fprintfC

	pop rbp
	ret

; uint32_t strLen(char* a)
strLen:
	mov rax, 0 ;contador
	loop_len:
	cmp byte [rdi + rax], 0
	je fin_len
	inc rax
	jmp loop_len
	
	fin_len:
	ret



