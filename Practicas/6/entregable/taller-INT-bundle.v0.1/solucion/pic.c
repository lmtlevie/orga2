/* ** por compatibilidad se omiten tildes **
================================================================================
 TALLER System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================

  Rutinas del controlador de interrupciones.
*/
#include "pic.h"

#define PIC1_PORT 0x20
#define PIC2_PORT 0xA0

static __inline __attribute__((always_inline)) void outb(uint32_t port,
                                                         uint8_t data) {
  __asm __volatile("outb %0,%w1" : : "a"(data), "d"(port));
}
void pic_finish1(void) { outb(PIC1_PORT, 0x20); }
void pic_finish2(void) {
  outb(PIC1_PORT, 0x20);
  outb(PIC2_PORT, 0x20);
}

// COMPLETAR: implementar pic_reset()
void pic_reset() {
  outb(PIC1_PORT, 0x11);
  outb(PIC1_PORT + 1, 0x20); // ICW2: IRQ0 mapeado a INT 32
  outb(PIC1_PORT + 1, 0x04); // ICW3: PIC1 Master, tiene un Slave conectado a IRQ2
  outb(PIC1_PORT + 1, 0x01); // ICW4: Modo No Buffered, Fin de Interrupcion Normal
  outb(PIC1_PORT + 1, 0xFF); // OCW1: Set o Clearel IMR
  // Inicialización del PIC2
  outb(PIC2_PORT, 0x11); // ICW1: IRQs activas por flanco, Modo cascada, ICW4 Si.
  outb(PIC2_PORT + 1, 0x28); // ICW2: IRQ8 mapeado a INT 40
  outb(PIC2_PORT + 1, 0x02); // ICW3: PIC2 Slave, conectado a IRQ2 del Master
  outb(PIC2_PORT + 1, 0x01); // ICW4: Modo No Buffered, Fin de Interrupcion Normal


}

void pic_enable() {
  outb(PIC1_PORT + 1, 0x00);
  outb(PIC2_PORT + 1, 0x00);
}

void pic_disable() {
  outb(PIC1_PORT + 1, 0xFF);
  outb(PIC2_PORT + 1, 0xFF);
}
