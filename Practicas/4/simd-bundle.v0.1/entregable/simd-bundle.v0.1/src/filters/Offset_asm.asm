
global Offset_asm


Offset_asm:
    ;rdi => src, rsi => dst, rdx => filas, rcx => cols, r8 => src_row_size
	push rbp
	mov rsp,rbp
    push rbx
    push rbp

	mov rbx,0;fila
    mov rbp,4; pixeles que recorri en la fila
   
    .ciclo:
	   
	   ;Agarro los pixeles que necesito
	   movq xmm1,[rdi]
       ;ultima fila
	   cmp rbx,rdx
	   jz .todos_negros
	   movq xmm2,[rdi+32] 
       movq xmm3,[rdi+r8*8]
	   movq xmm4,[rdi+r8*8+32]


       ;opero
       mov xmm0,0b10001000100010001000
	   pblendvb xmm1,xmm2
       mov xmm0,0b01000100010001000100
	   pblendvb xmm1,xmm3
       mov xmm0,0b00100010001000100010
	   pblendvb xmm1,xmm4
       ;setear todas las transparencias en 255


	   ; Borde negro
	   cmp rbx,0
	   jz .todos_negros
	   cmp rbp,4
	   jz .primer_negro
	   cmo rbp,8
	   jz .segundo_negro
	   cmp rbp,rcx-4
	   jz .anteultimo_negro
       cmp rbp,rcx
       jz .ultimo_negro

       ; Necesito saber en que fila y columna estoy por el borde
       
       cmp rbp,rcx
	   jnz .sigo_fila
	   add rbx,1
       
	   .sigo_fila
	   ; aumento el contador de pixeles
	   add rbp,4
	   
	   ; acumulo la solucion
	   ; no me acuerdo como era, seria pushear el xmm1 en la dest y aumentar en 4 bytes el puntero


	   ; miro si recorri todas las filas
	   cmp rbx,rdx
	   jz .fin
	   jmp .ciclo

	.fin:
	   pop rbx
	   pop rbp
	   ret
	


