section .data	

section .text

global invertirBytes_asm

; RDI = puntero a numero , SI = n , DX  = m
invertirBytes_asm:
    push rbp
    mov rbp, rsp


    mov r9d, 15
    mov ecx, edx
    pxor xmm0, xmm0
    ; Cargo 15 hasta m en xmm0
    ciclo:
        cmp r9d, esi
        je move_n
        cmp r9d, edx
        je move_m
        mov eax, r9d      ; move the lower 32 bits of r9 to eax
        movd xmm1, eax    ; move the contents of eax to xmm1
        pslldq xmm0, 1    ; shift xmm0 left by 1 byte
        por xmm0, xmm1
        jmp continuar
    
    move_m:
        movzx eax, si
        movd xmm1, eax
        pslldq xmm0, 1
        por xmm0, xmm1
        jmp continuar
    move_n:
        movzx eax, dx
        movd xmm1, eax
        pslldq xmm0, 1
        por xmm0, xmm1
        jmp continuar
    continuar:
        dec r9d
        jnz ciclo
        jmp ultimo
    ;Falta mover el ultimo byte
    move_m_ult:
        movzx eax, si
        movd xmm1, eax
        pslldq xmm0, 1
        por xmm0, xmm1
        jmp mascara
    move_n_ult:
        movzx eax, dx
        movd xmm1, eax
        pslldq xmm0, 1
        por xmm0, xmm1
        jmp mascara

    ultimo:
        cmp r9d, esi
        je move_n_ult
        cmp r9d, edx
        je move_m_ult
        mov eax, r9d      ; move the lower 32 bits of r9 to eax
        movd xmm1, eax    ; move the contents of eax to xmm1
        pslldq xmm0, 1    ; shift xmm0 left by 1 byte
        por xmm0, xmm1
        jmp mascara
    mascara:
    ; Ahora tengo la mascara creada en xmm0
        movdqa xmm1, [rdi]     
        pshufb xmm1, xmm0    
        movdqa [rdi], xmm1

        mov rsp, rbp
        pop rbp
        ret    
