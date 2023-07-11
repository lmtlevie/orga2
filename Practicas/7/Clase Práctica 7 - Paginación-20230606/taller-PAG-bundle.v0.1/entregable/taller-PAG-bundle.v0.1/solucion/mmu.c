/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================

  Definicion de funciones del manejador de memoria
*/

#include "mmu.h"
#include "i386.h"

#include "kassert.h"

static pd_entry_t* kpd = (pd_entry_t*)KERNEL_PAGE_DIR;
static pt_entry_t* kpt = (pt_entry_t*)KERNEL_PAGE_TABLE_0;

static const uint32_t identity_mapping_end = 0x003FFFFF;
static const uint32_t user_memory_pool_end = 0x02FFFFFF;

static paddr_t next_free_kernel_page = 0x100000;
static paddr_t next_free_user_page = 0x400000;

/**
 * kmemset asigna el valor c a un rango de memoria interpretado
 * como un rango de bytes de largo n que comienza en s
 * @param s es el puntero al comienzo del rango de memoria
 * @param c es el valor a asignar en cada byte de s[0..n-1]
 * @param n es el tamaño en bytes a asignar
 * @return devuelve el puntero al rango modificado (alias de s)
*/
static inline void* kmemset(void* s, int c, size_t n) {
    uint8_t* dst = (uint8_t*)s;
    for (size_t i = 0; i < n; i++) {
        dst[i] = c;
    }
    return dst;
}
/**
 * zero_page limpia el contenido de una página que comienza en addr
 * @param addr es la dirección del comienzo de la página a limpiar
*/
static inline void zero_page(paddr_t addr) {
    kmemset((void*)addr, 0x00, PAGE_SIZE);
}


void mmu_init(void) {}


/**
 * mmu_next_free_kernel_page devuelve la dirección de la próxima página de kernel disponible
 * @return devuelve la dirección de memoria de comienzo de la próxima página libre de kernel
 */
paddr_t mmu_next_free_kernel_page(void) {
    next_free_kernel_page += PAGE_SIZE; // Carga la proxima pagina libre
    return next_free_kernel_page - PAGE_SIZE; // Devuelve la anterior
}

/**
 * mmu_next_free_user_page devuelve la dirección de la próxima página de usuarix disponible
 * @return devuelve la dirección de memoria de comienzo de la próxima página libre de usuarix
 */
paddr_t mmu_next_free_user_page(void) {
    next_free_user_page += PAGE_SIZE; // Carga la proxima pagina libre
    return next_free_user_page - PAGE_SIZE; // Devuelve la anterior
}

/**
 * mmu_init_kernel_dir inicializa las estructuras de paginación vinculadas al kernel y
 * realiza el identity mapping
 * @return devuelve la dirección de memoria de la página donde se encuentra el directorio
 * de páginas usado por el kernel
 */
paddr_t mmu_init_kernel_dir(void) {
    // Crea una pagina vacia en la direccion del page directory
    zero_page(KERNEL_PAGE_DIR);
    // Crea una pagina vacia en la direccion del page table
    zero_page(KERNEL_PAGE_TABLE_0);

    kpd[0].attrs = 0x3; // Attrs: P=1, R/W=1
    kpd[0].pt = (KERNEL_PAGE_TABLE_0 >> 12); // Los 20 bits de la direccion (address)

    for (int i = 0; i < 1024; i++) {
        kpt[i].attrs = 0x3; // Attrs: P=1, R/W=1
        kpt[i].page = i;
    }

    return KERNEL_PAGE_DIR;
}

/**
 * mmu_map_page agrega las entradas necesarias a las estructuras de paginación de modo de que
 * la dirección virtual virt se traduzca en la dirección física phy con los atributos definidos en attrs
 * @param cr3 el contenido que se ha de cargar en un registro CR3 al realizar la traducción
 * @param virt la dirección virtual que se ha de traducir en phy
 * @param phy la dirección física que debe ser accedida (dirección de destino)
 * @param attrs los atributos a asignar en la entrada de la tabla de páginas
 */
void mmu_map_page(uint32_t cr3, vaddr_t virt, paddr_t phy, uint32_t attrs) {
    // Index del page directory de virt
    uint32_t id_dir = VIRT_PAGE_DIR(virt);

    // Index del page table de virt
    uint32_t id_table = VIRT_PAGE_TABLE(virt);

    // Extract PD address from CR3
    pd_entry_t *pd = (pd_entry_t*)CR3_TO_PAGE_DIR(cr3);

    // Por si no hay una page table en esa direccion
    if ((pd[id_dir].attrs & MMU_P) == 0) {
        paddr_t new_page_table = mmu_next_free_kernel_page();
        zero_page(new_page_table);
        pd[id_dir].pt = (uint32_t)(new_page_table >> 12);
        pd[id_dir].attrs = attrs | MMU_P;
    }

    // Extract PT address from the PD
    pt_entry_t *pt = (pt_entry_t*)MMU_ENTRY_PADDR(pd[id_dir].pt);
    // Coloca los valores correspondientes
    pt[id_table].page = phy >> 12;
    pt[id_table].attrs = attrs | MMU_P;

    // Como se tocaron los valores del PD y PT, limpiamos la TLB
    tlbflush();
}

/**
 * mmu_unmap_page elimina la entrada vinculada a la dirección virt en la tabla de páginas correspondiente
 * @param virt la dirección virtual que se ha de desvincular
 * @return la dirección física de la página desvinculada
 */
paddr_t mmu_unmap_page(uint32_t cr3, vaddr_t virt) {
    // Indices a remover
    uint32_t id_dir = VIRT_PAGE_DIR(virt);
    uint32_t id_table = VIRT_PAGE_TABLE(virt);

    // Invoca la PD y PT
    pd_entry_t* pd = (pd_entry_t*)CR3_TO_PAGE_DIR(cr3);
    pt_entry_t* pt = (pd_entry_t*)((pd[id_dir].pt) & 0xFFFFF000);

    // Gets the physical address
    paddr_t phy = (pt[id_table].page << 12);

    // Removes the page, blanking
    pt[id_table].attrs = 0;
    pt[id_table].page = 0;

    tlbflush();
    return phy;
}

#define DST_VIRT_PAGE 0xA00000
#define SRC_VIRT_PAGE 0xB00000

/**
 * copy_page copia el contenido de la página física localizada en la dirección src_addr a la página física ubicada en dst_addr
 * @param dst_addr la dirección a cuya página queremos copiar el contenido
 * @param src_addr la dirección de la página cuyo contenido queremos copiar
 *
 * Esta función mapea ambas páginas a las direcciones SRC_VIRT_PAGE y DST_VIRT_PAGE, respectivamente, realiza
 * la copia y luego desmapea las páginas. Usar la función rcr3 definida en i386.h para obtener el cr3 actual
 */
void copy_page(paddr_t dst_addr, paddr_t src_addr) {
    mmu_map_page(rcr3(), (vaddr_t)DST_VIRT_PAGE, dst_addr, MMU_W | MMU_P);
    mmu_map_page(rcr3(), (vaddr_t)SRC_VIRT_PAGE, src_addr, MMU_W | MMU_P);

    uint8_t *ptr_dst = (uint8_t*)(DST_VIRT_PAGE);
    uint8_t *ptr_src = (uint8_t*)(SRC_VIRT_PAGE);

    for (size_t i = 0; i < PAGE_SIZE; i++) {
        ptr_dst[i] = ptr_src[i];
    }

    mmu_unmap_page(rcr3(), DST_VIRT_PAGE);
    mmu_unmap_page(rcr3(), SRC_VIRT_PAGE);
}

 /**
 * mmu_init_task_dir inicializa las estructuras de paginación vinculadas a una tarea cuyo código se encuentra en la dirección phy_start
 * @pararm phy_start es la dirección donde comienzan las dos páginas de código de la tarea asociada a esta llamada
 * @return el contenido que se ha de cargar en un registro CR3 para la tarea asociada a esta llamada
 */
paddr_t mmu_init_task_dir(paddr_t phy_start) {
    // Obtiene la nueva pagina libre del kernel y esta sera el nuevo CR3
    paddr_t cr3 = mmu_next_free_kernel_page();
    // Init page (all 0)
    zero_page(cr3);

    /* Identity mapping
     * virt <=> phy
     * R/W=1, P=1
    */
    for (uint32_t i = 0; i < identity_mapping_end; i += PAGE_SIZE) {
        mmu_map_page(cr3, i, i, MMU_W | MMU_P);
    }

    /* Code mapping
     * La rutina debe mapear las paginas de codigo como solo lectura (R/W=0)
     * La rutina la hace el usuario (U/S=1)
    */
    for (int i=0; i < TASK_CODE_PAGES; i++) {
        mmu_map_page(cr3, TASK_CODE_VIRTUAL + i * PAGE_SIZE, phy_start + i * PAGE_SIZE, MMU_U | MMU_P);
    }

    /* Stack mapping
     * SHARED es la direccion fisica de la pagina de memoria compartida
    */
    paddr_t stack = mmu_next_free_user_page();
    mmu_map_page(cr3, TASK_STACK_BASE - PAGE_SIZE, stack, MMU_U | MMU_W | MMU_P);
    mmu_map_page(cr3, TASK_STACK_BASE, SHARED, MMU_U | MMU_P);

    return cr3;
}
