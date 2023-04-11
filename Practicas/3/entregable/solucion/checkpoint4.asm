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
		
		inc rdi
		inc rsi
		
		cmp al,0
		je .equal_a

		cmp bl,0
		je .equal_b

		cmp al,bl
		je .cycle
		
		jg .mayor

		jl .menor

			
	.mayor:
		mov rax,-1
		jmp .end
	.menor:
		mov rax,1
		jmp .end
	.equal_a:
		cmp bl,0
		je .equal
		jmp .menor
	.equal_b:
		cmp al,0
		je .equal
		jmp .mayor
	.equal:
		mov rax,0
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
	;en rdi esta el puntero a primer string
	; si aumento 1 byte paso al siguiente
	; si es 0 se termina
	mov rsi, 0
	.cycle
		mov al, [rdi]
		cmp al, 0
		je .end
		add rsi,1
		add rdi,1
		jmp .cycle
		
	.end
		mov rax, rsi
		ret




