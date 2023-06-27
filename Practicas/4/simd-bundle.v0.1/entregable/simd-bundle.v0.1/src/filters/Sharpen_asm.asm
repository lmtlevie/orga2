global Sharpen_asm
mascaraNueve: times 8 dw 9  ; [9, 9, 9, 9, 9, 9, 9, 9]
mascaraBlackDeDosPixeles: times 2 db 0, 0, 0, 0xff

Sharpen_asm:
	push rbp
    mov rbp, rsp
    push r10
    push r11
    push r12
    push r13
    push r14 ;aca me voy a guardar el pixel que esta arriba a la izquierda
    push r15  
    
        
    xor r11, r11 ; r11 = nro de pixeles modificados de una fila. Va a ser mÃºltiplo de 2 X
    xor r13, r13 ; r13 = nro de filas modificadas                                       Y



    mov r12, rdx
    imul r12, 4
    mov r9, r8  ;
	sub r8, r12 ;src_row_padding

    
    .ciclo:
        cmp r13, 0
        je .primeraFila
        
        mov r10, r13
        inc r10
        cmp r10, rcx
        je .ultimaFila


        xor r10, r10 ;ii
        xor r15, r15 ;jj
        
        pxor xmm0, xmm0

        ;cmp r11, 10
        ;je .fin

        jmp .aplicarFiltro


    .primeraFila:
        cmp r11, rdx
        jne .noTerminaPrimeraFila

        add r13, 1      ;paso a la siguiente fila
        xor r11, r11    ;seteo el r11 en 0
        add rdi, r8     ;salto con padding a la siguiente fila
        add rsi, r8

        jmp .ciclo


        .noTerminaPrimeraFila:
        mov r15, [mascaraBlackDeDosPixeles] ;puedo usar el r15 porque no me afecta lo de despues
        mov [rsi], r15 

        add r11, 2
        add rsi, 8
        add rdi, 8

        jmp .primeraFila

    .ultimaFila:
        cmp r11, rdx
        je .fin

        mov r15, [mascaraBlackDeDosPixeles] ;puedo usar el r15 porque no me afecta lo de despues
        mov [rsi], r15

        add r11, 2
        add rsi, 8
        add rdi, 8
        

        jmp .ultimaFila


    .aplicarFiltro:
        ;primero necesito el valor desde donde voy a empezar el filtro (ii=0 jj=0)
        mov r14, rdi
        sub r14, r9
        sub r14, 4     ; r14 = pixel de arriba a la izquierda

        cmp r11, 0 ;veo si es el primer pixel. Si es el primero le aplico negro al primero y pixel al ultimo
        jne .noEsPrimerPixel

        push r10
        mov r10, [mascaraBlackDeDosPixeles]
        mov [rsi], r10
        pop r10
        add r14, 4
        add rdi, 4
        add rsi, 4
        pxor xmm0, xmm0
        jmp .sharpenPrimerPixel
        

        ;jmp .desdeAca

        .noEsPrimerPixel:

        
        add r11, 2
        cmp r11, rdx ;si es el ultimo menos 2 le aplico filtro al primer pixel y negro al ultimo
        jne .noEsUltimoPixel

        sub r11, 2
        push r12
        mov r12, [mascaraBlackDeDosPixeles]
        mov [rsi], r12
        pop r12
        sub r14, 4
        sub rdi, 4
        sub rsi, 4
        jmp .sharpenUltimoPixel

        jmp .desdeAca


        .noEsUltimoPixel:
        sub r11, 2
        jmp .sharpen

    
    .sharpen:
        cmp r10, 3

        je .siguientePixeles
        
        push rsi
        mov rax, r14    ;rax = [r14]
        mov rsi, r10    
        imul rsi, r9    
        add rax, rsi    ;rax = [r14 + (r10*padding)]

        mov rsi, r15
        imul rsi, 4
        add rax, rsi    ;rax = [r14 + (r10*padding) + r15*4]

        pop rsi

        pmovzxbw xmm1, [rax]
        ;jmp .siguientePixeles

        cmp r10, 1
        jne .noMul9
        cmp r15, 1
        jne .noMul9

        PMULLW xmm1, [mascaraNueve]
        PADDW xmm0, xmm1
        jmp .f

        .noMul9:
        PSUBW xmm0, xmm1

        .f:


        inc r15
        cmp r15, 3

        jne .jjNoEsIguslA2

        inc r10
        xor r15, r15
        jmp .sharpen

        .jjNoEsIguslA2:
        jmp .sharpen

    .sharpenPrimerPixel:
        cmp r10, 3

        jne .seguir1
        
        PACKUSWB xmm0, xmm0 ;packed con saturacion, en la primera mitad me deja el resultado
        
        mov r10, 255
        pinsrb xmm0, r10d, 3
        pinsrb xmm0, r10d, 7

        movq [rsi], xmm0
        sub r14, 4
        sub rdi, 4
        sub rsi, 4
        jmp .desdeAca
        

        .seguir1:
        
        push rsi
        mov rax, r14    ;rax = [r14]
        mov rsi, r10    
        imul rsi, r9    
        add rax, rsi    ;rax = [r14 + (r10*padding)]

        mov rsi, r15
        imul rsi, 4
        add rax, rsi    ;rax = [r14 + (r10*padding) + r15*4]

        pop rsi

        pmovzxbw xmm1, [rax]

        cmp r10, 1
        jne .noMul9_1
        cmp r15, 1
        jne .noMul9_1

        PMULLW xmm1, [mascaraNueve]
        PADDW xmm0, xmm1
        jmp .f2

        .noMul9_1:
        PSUBW xmm0, xmm1

        .f2:


        inc r15
        cmp r15, 3

        jne .jjNoEsIguslA2_2

        inc r10
        xor r15, r15
        jmp .sharpenPrimerPixel

        .jjNoEsIguslA2_2:
        jmp .sharpenPrimerPixel

    .sharpenUltimoPixel:
        cmp r10, 3

        jne .seguir2
        
        PACKUSWB xmm0, xmm0 ;packed con saturacion, en la primera mitad me deja el resultado
        
        mov r10, 255
        pinsrb xmm0, r10d, 3
        pinsrb xmm0, r10d, 7

        movq [rsi], xmm0
        add r14, 4
        add rdi, 4
        add rsi, 4
        jmp .desdeAca
        

        .seguir2:
        
        push rsi
        mov rax, r14    ;rax = [r14]
        mov rsi, r10    
        imul rsi, r9    
        add rax, rsi    ;rax = [r14 + (r10*padding)]

        mov rsi, r15
        imul rsi, 4
        add rax, rsi    ;rax = [r14 + (r10*padding) + r15*4]

        pop rsi

        pmovzxbw xmm1, [rax]

        cmp r10, 1
        jne .noMul9_2
        cmp r15, 1
        jne .noMul9_2

        PMULLW xmm1, [mascaraNueve]
        PADDW xmm0, xmm1
        jmp .f3

        .noMul9_2:
        PSUBW xmm0, xmm1

        .f3:


        inc r15
        cmp r15, 3

        jne .jjNoEsIguslA2_3

        inc r10
        xor r15, r15
        jmp .sharpenUltimoPixel

        .jjNoEsIguslA2_3:
        jmp .sharpenUltimoPixel


    .siguientePixeles:
        PACKUSWB xmm0, xmm0 ;packed con saturacion, en la primera mitad me deja el resultado
        
        mov r10, 255
        pinsrb xmm0, r10d, 3
        pinsrb xmm0, r10d, 7

        movq [rsi], xmm0  
        

        .desdeAca:
        add r11, 2 ;le sumo los 2 pixeles que recorri
        add rdi, 8 ;se agregan 8 bytes
        add rsi, 8

        cmp r11, rdx
        jne .noTerminoLaFila

        add r13, 1
        xor r11, r11
        add rdi, r8
        add rsi, r8


        .noTerminoLaFila:
        jmp .ciclo


.fin:
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop rbp
    ret