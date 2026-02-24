#ifndef EXPR_EVAL_H
#define EXPR_EVAL_H

#include "bridge_types.h"

/* Resultado de evaluación */
typedef struct {
    int *valores;      /* Array de valores posibles (números/booleanos) */
    int n_valores;     /* Cantidad de valores */
    int es_bool;       /* 1 si es resultado booleano */
    char **set_elementos; /* Array de elementos del conjunto */
    int n_set_elementos;  /* Cantidad de elementos en el conjunto */
    int es_set;        /* 1 si es un conjunto */
} ResultadoEval;

/* Evalúa una expresión y retorna todos los valores posibles */
ResultadoEval* evaluar_expresion(Nodo *expr);

/* Libera memoria del resultado */
void liberar_resultado(ResultadoEval *res);

/* Imprime el resultado de forma legible */
void imprimir_resultado(ResultadoEval *res);

#endif
