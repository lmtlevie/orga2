extern malloc
extern free
extern fprintf

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
	;prologo
	push rbp
	mov rbp,rsp
	
	;asumo string igual tamanio
	.cycle:
		mov al,[rdi]
		mov bl,[rsi]
		
		add rdi,1
		add rsi,1

		cmp al,bl
		je .cycle
		
		jg .mayor

		jl .menor

		mov rax,0

		jmp .end
	
	.mayor:
		mov rax,1
		jmp .end
	.menor:
		mov rax,-1
		jmp .end

	.end:
		pop rbp	

		ret

; char* strClone(char* a)
strClone:
	ret

; void strDelete(char* a)
strDelete:
	; Esto no funciona porque copia el puntero al string
	; pero no el string en sí mismo
	mov rax, rdi
	ret

; void strPrint(char* a, FILE* pFile)
strPrint:
	ret

; uint32_t strLen(char* a)
strLen:
	ret


