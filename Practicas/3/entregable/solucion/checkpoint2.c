#include "checkpoints.h"

uint32_t sumar_c(uint32_t a,uint32_t b){
	return a + b; 
}
uint32_t restar_c(uint32_t a,uint32_t b){
	return a - b; 
}

/* Pueden programar alguna rutina auxiliar del checkpoint 2 acá */
uint32_t operacion(uint32_t a,uint32_t b, uint32_t c,uint32_t d){
	uint32_t uno = restar_c(a,b);
	uint32_t dos = restar_c(c,d);
	return sumar_c(uno, dos);
}