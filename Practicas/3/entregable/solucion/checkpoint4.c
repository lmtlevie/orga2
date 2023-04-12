#include "checkpoints.h"

/* Pueden programar alguna rutina auxiliar del checkpoint 4 acá */

void freeC(char* a){
    free(a);
}
bool esMenorChar(char a, char b){
    return a < b;
}

bool esMayorChar(char a, char b){
    return a > b;
}

void fprintfC(char* a, FILE* pFile){
    fprintf(a, pFile);
}