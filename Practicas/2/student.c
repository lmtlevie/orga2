#include "student.h"
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>

void printStudent(student_t *stud)
{
   /* Imprime por consola una estructura de tipo student_t
   */
   printf("Name: %s\n", stud->name);
   printf("DNI: %d\n", stud->dni);
   printf("Califications: ");
   for (int i = 0; i < NUM_CALIFICATIONS; i++) {
       printf("%d ", stud->califications[i]);
   }
   printf("\n");
   printf("Concept: %d\n", stud->concept);
}

void printStudentp(studentp_t *stud)
{
   /* Imprime por consola una estructura de tipo studentp_t
   */
   printf("Name: %s\n", stud->name);
   printf("DNI: %d\n", stud->dni);
   printf("Califications: ");
   for (int i = 0; i < NUM_CALIFICATIONS; i++) {
       printf("%d ", stud->califications[i]);
   }
   printf("\n");
   printf("Concept: %d\n", stud->concept);
}
