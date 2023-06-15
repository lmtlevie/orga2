/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================

  Definicion de funciones del manejador de memoria
*/

#include "mmu.h"
#include "i386.h"

#include "kassert.h"

static pd_entry_t *kpd = (pd_entry_t *)KERNEL_PAGE_DIR;
static pt_entry_t *kpt = (pt_entry_t *)KERNEL_PAGE_TABLE_0;

static const uint32_t identity_mapping_end = 0x003FFFFF;
static const uint32_t user_memory_pool_end = 0x02FFFFFF;

static paddr_t next_free_kernel_page = 0x100000;
static paddr_t next_free_user_page = 0x400000;

static paddr_t shared_page = NULL;

/**
 * kmemset asigna el valor c a un rango de memoria interpretado
 * como un rango de bytes de largo n que comienza en s
 * @param s es el puntero al comienzo del rango de memoria
 * @param c es el valor a asignar en cada byte de s[0..n-1]
 * @param n es el tamaño en bytes a asignar
 * @return devuelve el puntero al rango modificado (alias de s)
 */
static inline void *kmemset(void *s, int c, size_t n)
{
  uint8_t *dst = (uint8_t *)s;
  for (size_t i = 0; i < n; i++)
  {
    dst[i] = c;
  }
  return dst;
}

/**
 * zero_page limpia el contenido de una página que comienza en addr
 * @param addr es la dirección del comienzo de la página a limpiar
 */
static inline void zero_page(paddr_t addr)
{
  kmemset((void *)addr, 0x00, PAGE_SIZE);
}

void mmu_init(void) {}

/**
 * mmu_next_free_kernel_page devuelve la dirección de la próxima página de kernel disponible
 * @return devuelve la dirección de memoria de comienzo de la próxima página libre de kernel
 */
paddr_t mmu_next_free_kernel_page(void)
{
  return next_free_kernel_page + PAGE_SIZE;
}

/**
 * mmu_next_free_user_page devuelve la dirección de la próxima página de usuarix disponible
 * @return devuelve la dirección de memoria de comienzo de la próxima página libre de usuarix
 */
paddr_t mmu_next_free_user_page(void)
{
  return next_free_user_page + PAGE_SIZE;
}

/**
 * mmu_init_kernel_dir inicializa las estructuras de paginación vinculadas al kernel y
 * realiza el identity mapping
 * @return devuelve la dirección de memoria de la página donde se encuentra el directorio
 * de páginas usado por el kernel
 */
paddr_t mmu_init_kernel_dir(void)
{
  zero_page(KERNEL_PAGE_DIR);
  zero_page(KERNEL_PAGE_TABLE_0);
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
void mmu_map_page(uint32_t cr3, vaddr_t virt, paddr_t phy, uint32_t attrs)
{
  pd_entry_t *directorio = CR3_TO_PAGE_DIR(cr3);
  int pd_index = VIRT_PAGE_DIR(virt);
  if (directorio[pd_index].attrs != MMU_P)
  {
    directorio[pd_index].pt = (mmu_next_free_kernel_page() >> 12);
    zero_page(directorio[pd_index].pt << 12);
    directorio[pd_index].attrs = MMU_P;
  }

  int pdt_index = VIRT_PAGE_TABLE(phy);
  pt_entry_t *tabla = directorio[pdt_index].pt;
  tabla->attrs = attrs;
  tabla->page = phy >> 12;
}

/**
 * mmu_unmap_page elimina la entrada vinculada a la dirección virt en la tabla de páginas correspondiente
 * @param virt la dirección virtual que se ha de desvincular
 * @return la dirección física de la página desvinculada
 */
paddr_t mmu_unmap_page(uint32_t cr3, vaddr_t virt)
{
  pd_entry_t *page_directory = CR3_TO_PAGE_DIR(cr3);
  int pd_index = VIRT_PAGE_DIR(virt);

  pt_entry_t *page_table = MMU_ENTRY_PADDR(page_directory[pd_index].pt);

  int pt_index = VIRT_PAGE_TABLE(virt);
  page_table[pt_index].attrs = 0;
  paddr_t page = MMU_ENTRY_PADDR(page_table[pt_index].page);
  page_table[pt_index].page = 0;

  return (page);
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
void copy_page(paddr_t dst_addr, paddr_t src_addr)
{
  uint32_t cr3 = rcr3();
  mmu_map_page(cr3, SRC_VIRT_PAGE, src_addr, MMU_P | MMU_W);
  mmu_map_page(cr3, DST_VIRT_PAGE, dst_addr, MMU_P | MMU_W);
  pd_entry_t *page_dir = CR3_TO_PAGE_DIR(cr3);
  for (int i = 0; i < PAGE_SIZE; i++)
  {
    ((uint8_t *)DST_VIRT_PAGE)[i] = ((uint8_t *)SRC_VIRT_PAGE)[i];
  }

  mmu_unmap_page(cr3, SRC_VIRT_PAGE);
  mmu_unmap_page(cr3, DST_VIRT_PAGE);
}

/**
 * mmu_init_task_dir inicializa las estructuras de paginación vinculadas a una tarea cuyo código se encuentra en la dirección phy_start
 * @pararm phy_start es la dirección donde comienzan las dos páginas de código de la tarea asociada a esta llamada
 * @return el contenido que se ha de cargar en un registro CR3 para la tarea asociada a esta llamada
 */
paddr_t mmu_init_task_dir(paddr_t phy_start)
{
  pd_entry_t *cr3 = mmu_next_free_kernel_page();
  zero_page(cr3);

  cr3[0].attrs = MMU_P | MMU_U | MMU_W;
  cr3[0].pt = KERNEL_PAGE_TABLE_0 >> 12;

  for (size_t i = 0; i < TASK_CODE_PAGES; i++)
  {
    mmu_map_page(cr3, TASK_CODE_VIRTUAL + i * PAGE_SIZE, phy_start + i * PAGE_SIZE, MMU_P | MMU_U);
  }

  pd_entry_t *stack = mmu_next_free_kernel_page();
  mmu_map_page(cr3, TASK_STACK_BASE, stack - PAGE_SIZE, MMU_U | MMU_W | MMU_P);

  if (shared_page == NULL)
  {
    shared_page = mmu_next_free_kernel_page();
  }
  mmu_map_page(cr3, TASK_SHARED_PAGE, shared_page, MMU_P | MMU_U);
  return (paddr_t)cr3;
}
