/* ================================================================
 * aggregate_functions.c - Funciones de agregación estadística
 * Proyecto: GNUBison - Bridge GeCode Validator
 * ================================================================
 *
 * PROPÓSITO:
 *   Biblioteca de funciones agregadas para procesar resultados de evaluación
 *   con incertidumbre. Soporta operaciones numéricas (sum, avg, min, max,
 *   median, variance, stdev), lógicas (all, any, none) y de conjuntos (count).
 *
 * ARQUITECTURA:
 *   Tres familias de funciones:
 *   1. Agregación numérica: arrays de double (valores con precisión)
 *   2. Agregación entera: arrays de int (optimizada para enteros)
 *   3. Agregación lógica/conjuntos: arrays de int/char*
 *
 * DECISIONES DE DISEÑO:
 *   - Versiones separadas int/double: Evita conversión implícita y mejora
 *     rendimiento para el caso común (enteros con factor_global).
 *   - MEDIAN modifica el array: Requiere ordenamiento in-place (qsort).
 *     Documentar que no es const.
 *   - Null-safe: Todas las funciones verifican array==NULL antes de procesar.
 *   - Retorno 0.0 en caso de error: Simplifica manejo en evaluador.
 *
 * USO TÍPICO:
 *   // Evaluar expresión con incertidumbre
 *   ResultadoEval *res = evaluar_expresion(ast);  // res->n_valores > 1
 *
 *   // Calcular estadísticas sobre resultados
 *   double promedio = aggregate_avg_int(res->valores, res->n_valores);
 *   double desv_std = aggregate_stdev_int(res->valores, res->n_valores);
 *
 * EXTENSIÓN FUTURA:
 *   - Funciones agregadas para sets: UNION_ALL, INTERSECT_ALL
 *   - Percentiles: p50, p90, p95
 *   - Moda (valor más frecuente)
 *
 * REFERENCIAS:
 *   - aggregate_functions.h: Declaraciones y documentación de API
 *   - expr_eval.c: Consumidor principal (evaluar resultados con incertidumbre)
 *
 * ================================================================ */

#include "aggregate_functions.h"
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <float.h>

/* ============================================
 * FUNCIONES AGREGADAS NUMÉRICAS
 * ============================================ */

/* SUM: Suma de elementos */
double aggregate_sum(const double *array, size_t length) {
    if (!array || length == 0) return 0.0;

    double sum = 0.0;
    for (size_t i = 0; i < length; i++) {
        sum += array[i];
    }
    return sum;
}

/* AVG: Promedio */
double aggregate_avg(const double *array, size_t length) {
    if (!array || length == 0) return 0.0;

    return aggregate_sum(array, length) / (double)length;
}

/* MIN: Mínimo */
double aggregate_min(const double *array, size_t length) {
    if (!array || length == 0) return 0.0;

    double min_val = array[0];
    for (size_t i = 1; i < length; i++) {
        if (array[i] < min_val) {
            min_val = array[i];
        }
    }
    return min_val;
}

/* MAX: Máximo */
double aggregate_max(const double *array, size_t length) {
    if (!array || length == 0) return 0.0;

    double max_val = array[0];
    for (size_t i = 1; i < length; i++) {
        if (array[i] > max_val) {
            max_val = array[i];
        }
    }
    return max_val;
}

/* PRODUCT: Producto */
double aggregate_product(const double *array, size_t length) {
    if (!array || length == 0) return 0.0;

    double product = 1.0;
    for (size_t i = 0; i < length; i++) {
        product *= array[i];
    }
    return product;
}

/* Función auxiliar para qsort */
int compare_doubles(const void *a, const void *b) {
    double diff = (*(double*)a - *(double*)b);
    return (diff > 0) - (diff < 0);
}

/* MEDIAN: Mediana (modifica el array) */
double aggregate_median(double *array, size_t length) {
    if (!array || length == 0) return 0.0;

    /* Ordenar el array */
    qsort(array, length, sizeof(double), compare_doubles);

    /* Calcular mediana */
    if (length % 2 == 0) {
        /* Par: promedio de los dos centrales */
        size_t mid = length / 2;
        return (array[mid - 1] + array[mid]) / 2.0;
    } else {
        /* Impar: elemento central */
        return array[length / 2];
    }
}

/* VARIANCE: Varianza poblacional */
double aggregate_variance(const double *array, size_t length) {
    if (!array || length == 0) return 0.0;

    double mean = aggregate_avg(array, length);
    double sum_sq_diff = 0.0;

    for (size_t i = 0; i < length; i++) {
        double diff = array[i] - mean;
        sum_sq_diff += diff * diff;
    }

    return sum_sq_diff / (double)length;
}

/* STDEV: Desviación estándar poblacional */
double aggregate_stdev(const double *array, size_t length) {
    return sqrt(aggregate_variance(array, length));
}

/* ============================================
 * FUNCIONES AGREGADAS PARA CONJUNTOS
 * ============================================ */

/* COUNT: Cuenta elementos únicos */
size_t aggregate_count(const char **set, size_t length) {
    if (!set) return 0;

    /* Por ahora simplemente retorna la longitud
     * En una implementación completa, verificaría unicidad */
    size_t count = 0;
    for (size_t i = 0; i < length; i++) {
        if (set[i] != NULL) {
            count++;
        }
    }
    return count;
}

/* COUNT_IF: Cuenta elementos no-nulos */
size_t aggregate_count_if(const char **set, size_t length) {
    return aggregate_count(set, length);
}

/* ============================================
 * FUNCIONES AGREGADAS LÓGICAS
 * ============================================ */

/* ALL: Todos verdaderos */
int aggregate_all(const int *array, size_t length) {
    if (!array || length == 0) return 0;

    for (size_t i = 0; i < length; i++) {
        if (!array[i]) {
            return 0; /* Encontró un false */
        }
    }
    return 1; /* Todos son true */
}

/* ANY: Alguno verdadero */
int aggregate_any(const int *array, size_t length) {
    if (!array || length == 0) return 0;

    for (size_t i = 0; i < length; i++) {
        if (array[i]) {
            return 1; /* Encontró un true */
        }
    }
    return 0; /* Ninguno es true */
}

/* NONE: Ninguno verdadero */
int aggregate_none(const int *array, size_t length) {
    return !aggregate_any(array, length);
}

/* ============================================
 * FUNCIONES AGREGADAS ENTERAS
 * ============================================ */

/* Versiones enteras de las funciones numéricas */

int aggregate_sum_int(const int *array, size_t length) {
    if (!array || length == 0) return 0;

    int sum = 0;
    for (size_t i = 0; i < length; i++) {
        sum += array[i];
    }
    return sum;
}

int aggregate_min_int(const int *array, size_t length) {
    if (!array || length == 0) return 0;

    int min_val = array[0];
    for (size_t i = 1; i < length; i++) {
        if (array[i] < min_val) {
            min_val = array[i];
        }
    }
    return min_val;
}

int aggregate_max_int(const int *array, size_t length) {
    if (!array || length == 0) return 0;

    int max_val = array[0];
    for (size_t i = 1; i < length; i++) {
        if (array[i] > max_val) {
            max_val = array[i];
        }
    }
    return max_val;
}

double aggregate_avg_int(const int *array, size_t length) {
    if (!array || length == 0) return 0.0;

    return (double)aggregate_sum_int(array, length) / (double)length;
}
