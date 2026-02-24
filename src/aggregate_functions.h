#ifndef AGGREGATE_FUNCTIONS_H
#define AGGREGATE_FUNCTIONS_H

#include <stddef.h>

/* ============================================
 * FUNCIONES AGREGADAS NUMÉRICAS
 * ============================================ */

/* SUM: Suma de elementos en un array
 * Retorna la suma de todos los elementos */
double aggregate_sum(const double *array, size_t length);

/* AVG: Promedio de elementos en un array
 * Retorna el promedio aritmético */
double aggregate_avg(const double *array, size_t length);

/* MIN: Mínimo de elementos en un array
 * Retorna el valor mínimo */
double aggregate_min(const double *array, size_t length);

/* MAX: Máximo de elementos en un array
 * Retorna el valor máximo */
double aggregate_max(const double *array, size_t length);

/* PRODUCT: Producto de elementos en un array
 * Retorna el producto de todos los elementos */
double aggregate_product(const double *array, size_t length);

/* MEDIAN: Mediana de elementos en un array
 * Retorna el valor de la mediana (modifica el array) */
double aggregate_median(double *array, size_t length);

/* VARIANCE: Varianza de elementos en un array
 * Retorna la varianza poblacional */
double aggregate_variance(const double *array, size_t length);

/* STDEV: Desviación estándar de elementos en un array
 * Retorna la desviación estándar poblacional */
double aggregate_stdev(const double *array, size_t length);

/* ============================================
 * FUNCIONES AGREGADAS PARA CONJUNTOS
 * ============================================ */

/* COUNT: Cuenta elementos únicos en un conjunto
 * Retorna la cantidad de elementos */
size_t aggregate_count(const char **set, size_t length);

/* COUNT_IF: Cuenta elementos que cumplen condición
 * (por ahora cuenta no-nulos) */
size_t aggregate_count_if(const char **set, size_t length);

/* ============================================
 * FUNCIONES AGREGADAS LÓGICAS
 * ============================================ */

/* ALL: Verifica si todos los elementos son verdaderos
 * Retorna 1 si todos son true (!=0), 0 en caso contrario */
int aggregate_all(const int *array, size_t length);

/* ANY: Verifica si algún elemento es verdadero
 * Retorna 1 si al menos uno es true (!=0), 0 en caso contrario */
int aggregate_any(const int *array, size_t length);

/* NONE: Verifica si ningún elemento es verdadero
 * Retorna 1 si todos son false (==0), 0 en caso contrario */
int aggregate_none(const int *array, size_t length);

/* ============================================
 * FUNCIONES AUXILIARES
 * ============================================ */

/* Función auxiliar para ordenar (usado por MEDIAN) */
int compare_doubles(const void *a, const void *b);

#endif /* AGGREGATE_FUNCTIONS_H */
