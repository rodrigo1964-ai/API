/* ================================================================
 * aggregate_functions.h - API de funciones de agregación estadística
 * Proyecto: GNUBison - Bridge GeCode Validator
 * ================================================================
 *
 * PROPÓSITO:
 *   Funciones estadísticas para procesar resultados de evaluación con
 *   incertidumbre. Cuando una expresión produce múltiples valores posibles
 *   (ej: x=[10,20], y=5 → x+y=[15,25]), estas funciones calculan
 *   estadísticas agregadas.
 *
 * USO TÍPICO:
 *   ResultadoEval *res = evaluar_expresion(ast);
 *   if (res->n_valores > 1) {
 *       double promedio = aggregate_avg_int(res->valores, res->n_valores);
 *       double desviacion = aggregate_stdev_int(res->valores, res->n_valores);
 *   }
 *
 * FAMILIAS DE FUNCIONES:
 *   1. Numéricas (double): sum, avg, min, max, product, median, variance, stdev
 *   2. Enteras (int): sum_int, avg_int, min_int, max_int
 *   3. Lógicas (int): all, any, none
 *   4. Conjuntos (char**): count, count_if
 *
 * NOTA IMPORTANTE - MEDIAN:
 *   aggregate_median() modifica el array (lo ordena con qsort). Si necesitas
 *   preservar el orden original, copia el array antes de llamar.
 *
 * ================================================================ */

#ifndef AGGREGATE_FUNCTIONS_H
#define AGGREGATE_FUNCTIONS_H

#include <stddef.h>

/* ============================================
 * FUNCIONES AGREGADAS NUMÉRICAS (double)
 * ============================================ */

/* SUM: Suma de elementos
 * Retorna: suma total | 0.0 si array==NULL o length==0 */
double aggregate_sum(const double *array, size_t length);

/* AVG: Promedio aritmético
 * Retorna: media | 0.0 si array==NULL o length==0 */
double aggregate_avg(const double *array, size_t length);

/* MIN: Valor mínimo
 * Retorna: min | 0.0 si array==NULL o length==0 */
double aggregate_min(const double *array, size_t length);

/* MAX: Valor máximo
 * Retorna: max | 0.0 si array==NULL o length==0 */
double aggregate_max(const double *array, size_t length);

/* PRODUCT: Producto de elementos
 * Retorna: producto | 0.0 si array==NULL o length==0 */
double aggregate_product(const double *array, size_t length);

/* MEDIAN: Mediana (percentil 50)
 * ATENCION: Modifica el array (lo ordena con qsort)
 * Retorna: mediana | 0.0 si array==NULL o length==0 */
double aggregate_median(double *array, size_t length);

/* VARIANCE: Varianza poblacional
 * Formula: Σ(x - μ)² / N
 * Retorna: varianza | 0.0 si array==NULL o length==0 */
double aggregate_variance(const double *array, size_t length);

/* STDEV: Desviación estándar poblacional
 * Formula: sqrt(variance)
 * Retorna: desviación estándar | 0.0 si array==NULL o length==0 */
double aggregate_stdev(const double *array, size_t length);

/* ============================================
 * FUNCIONES AGREGADAS ENTERAS (int)
 * Optimizadas para valores escalados por factor_global
 * ============================================ */

/* SUM_INT: Suma de enteros
 * Retorna: suma | 0 si array==NULL o length==0 */
int aggregate_sum_int(const int *array, size_t length);

/* AVG_INT: Promedio de enteros (retorna double)
 * Retorna: media | 0.0 si array==NULL o length==0 */
double aggregate_avg_int(const int *array, size_t length);

/* MIN_INT: Mínimo de enteros
 * Retorna: min | 0 si array==NULL o length==0 */
int aggregate_min_int(const int *array, size_t length);

/* MAX_INT: Máximo de enteros
 * Retorna: max | 0 si array==NULL o length==0 */
int aggregate_max_int(const int *array, size_t length);

/* ============================================
 * FUNCIONES AGREGADAS LÓGICAS (int booleano)
 * ============================================ */

/* ALL: Verifica si todos los elementos son verdaderos
 * Retorna: 1 si todos !=0, 0 en caso contrario */
int aggregate_all(const int *array, size_t length);

/* ANY: Verifica si algún elemento es verdadero
 * Retorna: 1 si al menos uno !=0, 0 en caso contrario */
int aggregate_any(const int *array, size_t length);

/* NONE: Verifica si ningún elemento es verdadero
 * Retorna: 1 si todos ==0, 0 en caso contrario */
int aggregate_none(const int *array, size_t length);

/* ============================================
 * FUNCIONES AGREGADAS PARA CONJUNTOS
 * ============================================ */

/* COUNT: Cuenta elementos no-nulos en un conjunto
 * Retorna: cantidad de elementos | 0 si set==NULL */
size_t aggregate_count(const char **set, size_t length);

/* COUNT_IF: Cuenta elementos que cumplen condición
 * (Por ahora equivalente a COUNT - cuenta no-nulos)
 * Retorna: cantidad | 0 si set==NULL */
size_t aggregate_count_if(const char **set, size_t length);

/* ============================================
 * FUNCIONES AUXILIARES
 * ============================================ */

/* compare_doubles: Comparador para qsort (usado por aggregate_median)
 * Retorna: -1 si a<b, 0 si a==b, 1 si a>b */
int compare_doubles(const void *a, const void *b);

#endif /* AGGREGATE_FUNCTIONS_H */
