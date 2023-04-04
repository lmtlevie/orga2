#ifndef STACK_H
#define STACK_H

#include <stddef.h>
#include <stdint.h>

typedef struct stack stack_t;

struct stack
{
    uint64_t *ebp;  // Base del stack: dirección de memoria numericamente más grande
    uint64_t *esp;  /* Tope del stack: dirección con el último dato apilado
                       (crece hacia direcciones numericamente más chicas) */
                       
    uint64_t *_stackMem;  // Área de memoria a reservar para el stack

    uint64_t (*pop)(stack_t*);
    uint64_t (*top)(stack_t*);
    void (*push)(stack_t*, uint64_t);
};

stack_t * createStack(size_t);
void deleteStack(stack_t *);

#endif
