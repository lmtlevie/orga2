#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>

#include "checkpoints.h"

int main (void){
	/* Acá pueden realizar sus propias pruebas */
	assert(alternate_sum_4(8,2,5,1) == 10);	
	complex_item arr[] = {{1, 2, 3, 4}, {5, 6, 7, 8}, {9, 10, 11, 12}};
	assert(complex_sum_z(arr, 3) == 24);
	return 0;    
}


