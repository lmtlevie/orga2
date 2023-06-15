; ** por compatibilidad se omiten tildes **
; ==============================================================================
; TALLER System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
; ==============================================================================

%include "print.mac"
global start


; COMPLETAR - Agreguen declaraciones extern según vayan necesitando
extern A20_enable
extern GDT_DESC
extern screen_draw_layout
extern idt_init
extern IDT_DESC
extern pic_reset
extern pic_enable
extern mmu_init_kernel_dir

; COMPLETAR - Definan correctamente estas constantes cuando las necesiten
%define CS_RING_0_SEL 0x08  
%define DS_RING_0_SEL 0x18   


BITS 16
;; Saltear seccion de datos
jmp start

;;
;; Seccion de datos.
;; -------------------------------------------------------------------------- ;;
start_rm_msg db     'Iniciando kernel en Modo Real'
start_rm_len equ    $ - start_rm_msg

start_pm_msg db     'Iniciando kernel en Modo Protegido'
start_pm_len equ    $ - start_pm_msg

task_msg db     'Task ok'
task_len equ    $ - task_msg


;;
;; Seccion de código.
;; -------------------------------------------------------------------------- ;;

;; Punto de entrada del kernel.
BITS 16
start:
    ; COMPLETAR - Deshabilitar interrupciones
    cli

    ; Cambiar modo de video a 80 X 50
    mov ax, 0003h
    int 10h ; set mode 03h
    xor bx, bx
    mov ax, 1112h
    int 10h ; load 8x8 font

    ; COMPLETAR - Imprimir mensaje de bienvenida - MODO REAL
    ; (revisar las funciones definidas en print.mac y los mensajes se encuentran en la
    ; sección de datos)
    print_text_rm start_rm_msg, start_rm_len, 0x01, 0x00, 0x00

    ; COMPLETAR - Habilitar A20
    ; (revisar las funciones definidas en a20.asm)
    call A20_check
    call A20_enable
    call A20_check

    ; COMPLETAR - Cargar la GDT
    LGDT [GDT_DESC]

    ; COMPLETAR - Setear el bit PE del registro CR0
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; COMPLETAR - Saltar a modo protegido (far jump)
    ; (recuerden que un far jmp se especifica como jmp CS_selector:address)
    ; Pueden usar la constante CS_RING_0_SEL definida en este archivo
    JMP CS_RING_0_SEL:modo_protegido

BITS 32
modo_protegido:
    ; COMPLETAR - A partir de aca, todo el codigo se va a ejectutar en modo protegido
    ; Establecer selectores de segmentos DS, ES, GS, FS y SS en el segmento de datos de nivel 0
    ; Pueden usar la constante DS_RING_0_SEL definida en este archivo
    MOV ax, DS_RING_0_SEL
    MOV ds, ax
    MOV es, ax
    MOV gs, ax
    MOV fs, ax
    MOV ss, ax

    ; COMPLETAR - Establecer el tope y la base de la pila
    MOV esp, 0x25000
    MOV ebp, 0x25000

    ; COMPLETAR - Imprimir mensaje de bienvenida - MODO PROTEGIDO
    print_text_pm start_pm_msg, start_pm_len, 0x0004, 0x0000, 0x0000

    ; COMPLETAR - Inicializar pantalla
    call screen_draw_layout

    ; Inicializar IDT y load de IDT
    call idt_init
    LIDT [IDT_DESC]

    ; Inicializacion de PICs
    call pic_reset
    call pic_enable

    ; Activo paginacion
    call mmu_init_kernel_dir ; al terminar se carga en eax la direccion del directorio de paginas
    tlbflush

    mov cr3, eax

    mov eax, cr0
    or eax, 0x80000001
    mov cr0, eax

    ; habilitacion de interrupciones
    sti

    ; call de interrupciones
    int 88
    int 98

    mov ebx, cr3
    push 0x18000
    call mmu_init_task_dir
    mov cr3, eax
    print_text_pm task_msg, task_len, 0x0004, 0x0000, 0x0000
    mov cr3, ebx

    extern mmu_init_task_dir
    extern mmu_init_kernel_dir

   
    ; Ciclar infinitamente 
    mov eax, 0xFFFF
    mov ebx, 0xFFFF
    mov ecx, 0xFFFF
    mov edx, 0xFFFF
    jmp $

;; -------------------------------------------------------------------------- ;;

%include "a20.asm"
