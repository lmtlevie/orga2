; ** por compatibilidad se omiten tildes **
; ==============================================================================
; TALLER System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
; ==============================================================================

%include "print.mac"

global start


; COMPLETAR - Agreguen declaraciones extern según vayan necesitando
extern GDT_DESC
extern A20_enable
extern screen_draw_layout
extern idt_init
extern IDT_DESC
extern pic_reset
extern pic_enable
extern mmu_init
extern mmu_init_kernel_dir
extern mmu_init_task_dir
extern mmu_map_page
extern mmu_unmap_page
extern copy_page

; COMPLETAR - Definan correctamente estas constantes cuando las necesiten
%define CS_RING_0_SEL  0x08
%define DS_RING_0_SEL  0x18


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

start_cr3_msg db    'Cambio el CR3'
start_cr3_len equ   $ - start_cr3_msg

;;
;; Seccion de código.
;; -------------------------------------------------------------------------- ;;

;; Punto de entrada del kernel.
BITS 16
start:
    ; Deshabilita interrupciones
    cli

    ; Cambia modo de video a 80 X 50
    mov ax, 0003h
    int 10h ; set mode 03h
    xor bx, bx
    mov ax, 1112h
    int 10h ; load 8x8 font

    ; Imprime mensaje de bienvenida - MODO REAL - (print.mac func)
    print_text_rm start_rm_msg, start_rm_len, 1, 0, 0

    ; Habilita A20 (a20.asm)
    call A20_enable

    ; Carga la GDT
    lgdt [GDT_DESC]

    ; Setea el bit PE del registro CR0
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; COMPLETAR - Saltar a modo protegido (far jump)
    ; (recuerden que un far jmp se especifica como jmp CS_selector:address)
    ; Pueden usar la constante CS_RING_0_SEL definida en este archivo
    jmp CS_RING_0_SEL:modo_protegido

BITS 32
modo_protegido:
    ; A partir de aca, todo el codigo se va a ejectutar en modo protegido
    ; Establecer selectores de segmentos DS, ES, GS, FS y SS en el segmento de datos de nivel 0
    ; Pueden usar la constante DS_RING_0_SEL definida en este archivo
    mov ax, DS_RING_0_SEL
    mov ds, ax
    mov es, ax
    mov gs, ax
    mov fs, ax
    mov ss, ax

    ; Establecer el tope y la base de la pila
    mov esp, 0x25000
    mov ebp, esp

    ; Imprime mensaje de bienvenida - MODO PROTEGIDO
    print_text_pm start_pm_msg, start_pm_len, 1, 0, 0

    ; Paginacion
    ; Init MMU
    call mmu_init

    ; Init Page Directory
    call mmu_init_kernel_dir

    ; Cargamos el Page Directory, eax tiene el address del Page Diretory
    mov cr3, eax

    ; Habilitamos paginacion
    mov eax, cr0
    or eax, 0x80000000 ; 0x80000000 es 1 con 30 ceros
    mov cr0, eax

    ; Mapping test
    push 2 ; attrs: R/W=1
    push 0x00400000 ; phy
    push 0x0050E000 ; virt
    mov eax, cr3
    push eax ; cr3
    call mmu_map_page ; mapping func
    ; alinear stack
    ; cantidad de parametros por tamaño de parametro
    add esp, 4*4
    mov byte [0x0050E000], 54

    ; Unmap test
    mov eax, cr3
    push eax
    push 0x0050E000 ; virt
    call mmu_unmap_page
    add esp, 2*4

    ; Copy page test
    push 0x00400000 ; src_addr <- 54
    push 0x00402000 ; dst_addr <- 0
    call copy_page
    add esp, 2*4

    ; Fake task test
    mov ebx, cr3 ; store current CR3
    push 0x18000
    call mmu_init_task_dir
    add esp, 4

    mov cr3, eax ; eax <- new CR3
    print_text_pm start_cr3_msg, start_cr3_len, 1, 0, 0
    mov cr3, ebx ; return the previous CR3

    ; PRIMERO SE INICIALIZA PAGINACION Y DESPUES LO OTRO (IDT, INTS)

    ; Inicializar pantalla
    call screen_draw_layout

    ; Cargar IDT
    call idt_init
    lidt [IDT_DESC]

    ; Inicializacion del PIC
    call pic_reset
    call pic_enable
    sti

    int 98

    ; Ciclar infinitamente
    mov eax, 0xFFFF
    mov ebx, 0xFFFF
    mov ecx, 0xFFFF
    mov edx, 0xFFFF
    jmp $

;; -------------------------------------------------------------------------- ;;

%include "a20.asm"
