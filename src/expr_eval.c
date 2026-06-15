/* ================================================================
 * expr_eval.c - Motor de evaluación de expresiones con incertidumbre
 * Proyecto: GNUBison - Bridge GeCode Validator
 * ================================================================
 *
 * PROPÓSITO:
 *   Evaluador de expresiones que calcula resultados exactos para constraint
 *   programming. Soporta propagación de incertidumbre: si una variable tiene
 *   múltiples valores posibles, calcula todas las combinaciones resultantes.
 *
 * ARQUITECTURA:
 *   Evaluación recursiva de AST con propagación de conjuntos de valores:
 *
 *   evaluar_expresion(AST) → ResultadoEval {valores[], n_valores, es_bool}
 *
 *   - Nodos hoja: Variables (valor fijo o array de incertidumbre), literales
 *   - Nodos internos: Operadores (arit, comp, logic, sets) aplican función
 *     sobre producto cartesiano de operandos
 *
 * PROPAGACIÓN DE INCERTIDUMBRE:
 *   Ejemplo: x=[10,20], y=5
 *   Evaluar "x + y":
 *     - obtener_valor_variable("x") → {valores=[10,20], n=2}
 *     - obtener_valor_variable("y") → {valores=[5], n=1}
 *     - eval_op_arit(SUMA) → {valores=[15,25], n=2}
 *
 *   Complejidad: O(n_izq * n_der) por operador binario
 *
 * TIPOS DE RESULTADOS:
 *   - Escalares: n_valores=1, es_bool=0 → entero único
 *   - Booleanos: n_valores=1, es_bool=1 → true/false
 *   - Incertidumbre: n_valores>1 → múltiples valores posibles
 *   - Conjuntos: es_set=1, set_elementos[] → array de strings
 *
 * DECISIONES DE DISEÑO:
 *   - Aritmetica entera: Todos los cálculos en int (factor_global escala floats)
 *   - División por cero: Retorna 0 (sin exception)
 *   - Funciones estándar: Convierte a double, aplica math.h, re-escala a int
 *   - Sets como arrays de strings: Permite operaciones UNION, INTERSECT sin
 *     conversión a enteros (vs tabla de símbolos)
 *   - Memoria: Cada ResultadoEval aloca sus propios arrays (liberar con
 *     liberar_resultado())
 *
 * OPERADORES SOPORTADOS:
 *   Aritmética: +, -, *, /
 *   Comparación: =, <>, <, >, <=, >=
 *   Lógica: AND, OR, NOT, IMPLICA
 *   Conjuntos: UNION, INTERSECT, DIFFERENCE, SUBSET, IN, CARDINALITY
 *   Funciones: abs, sqrt, sqr, sin, cos, ln, exp
 *
 * REFERENCIAS:
 *   - bridge_types.h: Definición de Nodo (AST), VarReg, ResultadoEval
 *   - expr_parser.c: Genera el AST que este módulo evalúa
 *   - json_reader.c: Llama evaluar_expresion() en el pipeline
 *
 * ================================================================ */

#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "expr_eval.h"
#include "bridge_types.h"

/* Crea un resultado con un solo valor */
static ResultadoEval* resultado_simple(int val, int es_bool) {
    ResultadoEval *res = malloc(sizeof(ResultadoEval));
    res->valores = malloc(sizeof(int));
    res->valores[0] = val;
    res->n_valores = 1;
    res->es_bool = es_bool;
    res->set_elementos = NULL;
    res->n_set_elementos = 0;
    res->es_set = 0;
    return res;
}

/* Crea un resultado con múltiples valores */
static ResultadoEval* resultado_multiple(int *vals, int n, int es_bool) {
    ResultadoEval *res = malloc(sizeof(ResultadoEval));
    res->valores = malloc(n * sizeof(int));
    memcpy(res->valores, vals, n * sizeof(int));
    res->n_valores = n;
    res->es_bool = es_bool;
    res->set_elementos = NULL;
    res->n_set_elementos = 0;
    res->es_set = 0;
    return res;
}

/* Crea un resultado de conjunto */
static ResultadoEval* resultado_set(char **elementos, int n) {
    ResultadoEval *res = malloc(sizeof(ResultadoEval));
    res->valores = NULL;
    res->n_valores = 0;
    res->es_bool = 0;
    res->set_elementos = malloc(n * sizeof(char*));
    for (int i = 0; i < n; i++) {
        res->set_elementos[i] = strdup(elementos[i]);
    }
    res->n_set_elementos = n;
    res->es_set = 1;
    return res;
}

void liberar_resultado(ResultadoEval *res) {
    if (res) {
        free(res->valores);
        if (res->set_elementos) {
            for (int i = 0; i < res->n_set_elementos; i++) {
                free(res->set_elementos[i]);
            }
            free(res->set_elementos);
        }
        free(res);
    }
}

/* Obtiene los valores posibles de una variable */
static ResultadoEval* obtener_valor_variable(const char *nombre) {
    int idx = buscar_var(nombre);
    if (idx < 0) {
        fprintf(stderr, "Error: variable '%s' no encontrada\n", nombre);
        return resultado_simple(0, 0);
    }

    VarReg *v = &vars[idx];

    if (v->tiene_value == 0) {
        /* Sin valor asignado - usar dominio completo */
        if (v->tipo == T_LOGIC) {
            int vals[2] = {0, 1};
            return resultado_multiple(vals, 2, 1);
        } else if (v->tipo == T_INTEGER || v->tipo == T_FLOAT) {
            /* Para simplificar, retornamos el valor medio del dominio */
            int val = (v->dom_min + v->dom_max) / 2;
            return resultado_simple(val, 0);
        } else {
            return resultado_simple(0, 0);
        }
    } else if (v->tiene_value == 1) {
        /* Valor fijo */
        return resultado_simple(v->val_escalar, v->tipo == T_LOGIC);
    } else {
        /* Incertidumbre - múltiples valores */
        return resultado_multiple(v->val_vals, v->val_n, v->tipo == T_LOGIC);
    }
}

/* Evalúa operador binario aritmético */
static ResultadoEval* eval_op_arit(ResultadoEval *izq, ResultadoEval *der, TipoNodo op) {
    int *resultados = malloc(izq->n_valores * der->n_valores * sizeof(int));
    int count = 0;

    for (int i = 0; i < izq->n_valores; i++) {
        for (int j = 0; j < der->n_valores; j++) {
            int val;
            switch (op) {
                case NODO_SUMA: val = izq->valores[i] + der->valores[j]; break;
                case NODO_RESTA: val = izq->valores[i] - der->valores[j]; break;
                case NODO_MULT: val = izq->valores[i] * der->valores[j]; break;
                case NODO_DIV:
                    if (der->valores[j] != 0)
                        val = izq->valores[i] / der->valores[j];
                    else
                        val = 0;
                    break;
                default: val = 0;
            }
            resultados[count++] = val;
        }
    }

    ResultadoEval *res = resultado_multiple(resultados, count, 0);
    free(resultados);
    return res;
}

/* Evalúa operador de comparación */
static ResultadoEval* eval_op_comp(ResultadoEval *izq, ResultadoEval *der, TipoNodo op) {
    int *resultados = malloc(izq->n_valores * der->n_valores * sizeof(int));
    int count = 0;

    for (int i = 0; i < izq->n_valores; i++) {
        for (int j = 0; j < der->n_valores; j++) {
            int val;
            switch (op) {
                case NODO_EQ: val = (izq->valores[i] == der->valores[j]) ? 1 : 0; break;
                case NODO_NEQ: val = (izq->valores[i] != der->valores[j]) ? 1 : 0; break;
                case NODO_LT: val = (izq->valores[i] < der->valores[j]) ? 1 : 0; break;
                case NODO_GT: val = (izq->valores[i] > der->valores[j]) ? 1 : 0; break;
                case NODO_LEQ: val = (izq->valores[i] <= der->valores[j]) ? 1 : 0; break;
                case NODO_GEQ: val = (izq->valores[i] >= der->valores[j]) ? 1 : 0; break;
                default: val = 0;
            }
            resultados[count++] = val;
        }
    }

    ResultadoEval *res = resultado_multiple(resultados, count, 1);
    free(resultados);
    return res;
}

/* Evalúa operador lógico */
static ResultadoEval* eval_op_logic(ResultadoEval *izq, ResultadoEval *der, TipoNodo op) {
    int *resultados = malloc(izq->n_valores * der->n_valores * sizeof(int));
    int count = 0;

    for (int i = 0; i < izq->n_valores; i++) {
        for (int j = 0; j < der->n_valores; j++) {
            int val;
            switch (op) {
                case NODO_AND: val = (izq->valores[i] && der->valores[j]) ? 1 : 0; break;
                case NODO_OR: val = (izq->valores[i] || der->valores[j]) ? 1 : 0; break;
                case NODO_IMPLICA: val = (!izq->valores[i] || der->valores[j]) ? 1 : 0; break;
                default: val = 0;
            }
            resultados[count++] = val;
        }
    }

    ResultadoEval *res = resultado_multiple(resultados, count, 1);
    free(resultados);
    return res;
}

/* Evalúa función estándar */
static ResultadoEval* eval_func_std(ResultadoEval *arg, TipoNodo func) {
    int *resultados = malloc(arg->n_valores * sizeof(int));

    for (int i = 0; i < arg->n_valores; i++) {
        double val_real = (double)arg->valores[i] / factor_global;
        double resultado_real;

        switch (func) {
            case NODO_ABS: resultado_real = fabs(val_real); break;
            case NODO_SQRT: resultado_real = sqrt(fabs(val_real)); break;
            case NODO_SQR: resultado_real = val_real * val_real; break;
            case NODO_SIN: resultado_real = sin(val_real); break;
            case NODO_COS: resultado_real = cos(val_real); break;
            case NODO_LN: resultado_real = log(fabs(val_real)); break;
            case NODO_EXP: resultado_real = exp(val_real); break;
            default: resultado_real = val_real;
        }

        resultados[i] = (int)(resultado_real * factor_global);
    }

    ResultadoEval *res = resultado_multiple(resultados, arg->n_valores, 0);
    free(resultados);
    return res;
}

/* Función principal de evaluación recursiva */
/* Verifica si un elemento está en un conjunto */
static int set_contiene(char **elementos, int n, const char *elemento) {
    for (int i = 0; i < n; i++) {
        if (strcmp(elementos[i], elemento) == 0) return 1;
    }
    return 0;
}

/* UNION de dos conjuntos */
static ResultadoEval* eval_set_union(ResultadoEval *a, ResultadoEval *b) {
    int max_size = a->n_set_elementos + b->n_set_elementos;
    char **temp = malloc(max_size * sizeof(char*));
    int count = 0;

    /* Agregar todos de A */
    for (int i = 0; i < a->n_set_elementos; i++) {
        temp[count++] = a->set_elementos[i];
    }

    /* Agregar de B si no están en A */
    for (int i = 0; i < b->n_set_elementos; i++) {
        if (!set_contiene(a->set_elementos, a->n_set_elementos, b->set_elementos[i])) {
            temp[count++] = b->set_elementos[i];
        }
    }

    ResultadoEval *res = resultado_set(temp, count);
    free(temp);
    return res;
}

/* INTERSECT de dos conjuntos */
static ResultadoEval* eval_set_intersect(ResultadoEval *a, ResultadoEval *b) {
    char **temp = malloc(a->n_set_elementos * sizeof(char*));
    int count = 0;

    /* Agregar elementos de A que están en B */
    for (int i = 0; i < a->n_set_elementos; i++) {
        if (set_contiene(b->set_elementos, b->n_set_elementos, a->set_elementos[i])) {
            temp[count++] = a->set_elementos[i];
        }
    }

    ResultadoEval *res = resultado_set(temp, count);
    free(temp);
    return res;
}

/* DIFFERENCE A - B */
static ResultadoEval* eval_set_difference(ResultadoEval *a, ResultadoEval *b) {
    char **temp = malloc(a->n_set_elementos * sizeof(char*));
    int count = 0;

    /* Agregar elementos de A que NO están en B */
    for (int i = 0; i < a->n_set_elementos; i++) {
        if (!set_contiene(b->set_elementos, b->n_set_elementos, a->set_elementos[i])) {
            temp[count++] = a->set_elementos[i];
        }
    }

    ResultadoEval *res = resultado_set(temp, count);
    free(temp);
    return res;
}

/* Verifica si A es SUBSET de B */
static ResultadoEval* eval_set_subset(ResultadoEval *a, ResultadoEval *b) {
    for (int i = 0; i < a->n_set_elementos; i++) {
        if (!set_contiene(b->set_elementos, b->n_set_elementos, a->set_elementos[i])) {
            return resultado_simple(0, 1); /* false */
        }
    }
    return resultado_simple(1, 1); /* true */
}

/* Convierte variable de tipo SET a ResultadoEval */
static ResultadoEval* obtener_valor_set_variable(VarReg *v) {
    if (v->tiene_value == 1 || v->tiene_value == 2) {
        /* Usar valores asignados */
        return resultado_set(v->val_set_miembros, v->val_n);
    } else {
        /* Usar dominio completo */
        return resultado_set(v->dom_set_miembros, v->dom_n_miembros);
    }
}

ResultadoEval* evaluar_expresion(Nodo *expr) {
    if (!expr) return resultado_simple(0, 0);

    switch (expr->tipo) {
        case NODO_ENTERO:
            return resultado_simple(expr->valor_entero, 0);

        case NODO_BOOL:
            return resultado_simple(expr->valor_bool, 1);

        case NODO_IDENT: {
            int idx = buscar_var(expr->nombre);
            if (idx >= 0 && vars[idx].tipo == T_SET) {
                return obtener_valor_set_variable(&vars[idx]);
            }
            return obtener_valor_variable(expr->nombre);
        }

        case NODO_SET_LIT:
            return resultado_set(expr->set_elementos, expr->set_n_elementos);

        case NODO_NOT: {
            ResultadoEval *arg = evaluar_expresion(expr->izq);
            int *resultados = malloc(arg->n_valores * sizeof(int));
            for (int i = 0; i < arg->n_valores; i++) {
                resultados[i] = !arg->valores[i];
            }
            ResultadoEval *res = resultado_multiple(resultados, arg->n_valores, 1);
            free(resultados);
            liberar_resultado(arg);
            return res;
        }

        case NODO_SUMA:
        case NODO_RESTA:
        case NODO_MULT:
        case NODO_DIV: {
            ResultadoEval *izq = evaluar_expresion(expr->izq);
            ResultadoEval *der = evaluar_expresion(expr->der);
            ResultadoEval *res = eval_op_arit(izq, der, expr->tipo);
            liberar_resultado(izq);
            liberar_resultado(der);
            return res;
        }

        case NODO_EQ:
        case NODO_NEQ:
        case NODO_LT:
        case NODO_GT:
        case NODO_LEQ:
        case NODO_GEQ: {
            ResultadoEval *izq = evaluar_expresion(expr->izq);
            ResultadoEval *der = evaluar_expresion(expr->der);
            ResultadoEval *res = eval_op_comp(izq, der, expr->tipo);
            liberar_resultado(izq);
            liberar_resultado(der);
            return res;
        }

        case NODO_AND:
        case NODO_OR:
        case NODO_IMPLICA: {
            ResultadoEval *izq = evaluar_expresion(expr->izq);
            ResultadoEval *der = evaluar_expresion(expr->der);
            ResultadoEval *res = eval_op_logic(izq, der, expr->tipo);
            liberar_resultado(izq);
            liberar_resultado(der);
            return res;
        }

        case NODO_ABS:
        case NODO_SQRT:
        case NODO_SQR:
        case NODO_SIN:
        case NODO_COS:
        case NODO_LN:
        case NODO_EXP: {
            ResultadoEval *arg = evaluar_expresion(expr->izq);
            ResultadoEval *res = eval_func_std(arg, expr->tipo);
            liberar_resultado(arg);
            return res;
        }

        case NODO_IN: {
            ResultadoEval *izq = evaluar_expresion(expr->izq);
            ResultadoEval *der = evaluar_expresion(expr->der);

            /* Si izq es un número y der es un set */
            if (!izq->es_set && der->es_set) {
                /* Convertir el número a string para comparar */
                char num_str[32];
                snprintf(num_str, sizeof(num_str), "%d", izq->valores[0]);
                int resultado = set_contiene(der->set_elementos, der->n_set_elementos, num_str);
                liberar_resultado(izq);
                liberar_resultado(der);
                return resultado_simple(resultado, 1);
            }

            liberar_resultado(izq);
            liberar_resultado(der);
            return resultado_simple(0, 1);
        }

        case NODO_UNION: {
            ResultadoEval *izq = evaluar_expresion(expr->izq);
            ResultadoEval *der = evaluar_expresion(expr->der);
            ResultadoEval *res = eval_set_union(izq, der);
            liberar_resultado(izq);
            liberar_resultado(der);
            return res;
        }

        case NODO_INTERSECT: {
            ResultadoEval *izq = evaluar_expresion(expr->izq);
            ResultadoEval *der = evaluar_expresion(expr->der);
            ResultadoEval *res = eval_set_intersect(izq, der);
            liberar_resultado(izq);
            liberar_resultado(der);
            return res;
        }

        case NODO_DIFFERENCE: {
            ResultadoEval *izq = evaluar_expresion(expr->izq);
            ResultadoEval *der = evaluar_expresion(expr->der);
            ResultadoEval *res = eval_set_difference(izq, der);
            liberar_resultado(izq);
            liberar_resultado(der);
            return res;
        }

        case NODO_SUBSET: {
            ResultadoEval *izq = evaluar_expresion(expr->izq);
            ResultadoEval *der = evaluar_expresion(expr->der);
            ResultadoEval *res = eval_set_subset(izq, der);
            liberar_resultado(izq);
            liberar_resultado(der);
            return res;
        }

        case NODO_CARDINALITY: {
            ResultadoEval *arg = evaluar_expresion(expr->izq);
            int card = arg->es_set ? arg->n_set_elementos : 0;
            liberar_resultado(arg);
            return resultado_simple(card, 0);
        }

        default:
            return resultado_simple(0, 0);
    }
}

void imprimir_resultado(ResultadoEval *res) {
    if (!res) {
        printf("  => [sin resultado]\n");
        return;
    }

    printf("  => ");

    /* Manejar sets */
    if (res->es_set) {
        printf("{");
        for (int i = 0; i < res->n_set_elementos; i++) {
            if (i > 0) printf(", ");
            printf("%s", res->set_elementos[i]);
        }
        printf("}\n");
        return;
    }

    /* Manejar valores numéricos/booleanos */
    if (res->n_valores == 0) {
        printf("[sin resultado]\n");
        return;
    }

    if (res->n_valores == 1) {
        if (res->es_bool) {
            printf("%s\n", res->valores[0] ? "true" : "false");
        } else {
            if (factor_global > 1) {
                printf("%d (%.3f)\n", res->valores[0],
                       (double)res->valores[0] / factor_global);
            } else {
                printf("%d\n", res->valores[0]);
            }
        }
    } else {
        printf("[");
        for (int i = 0; i < res->n_valores && i < 10; i++) {
            if (i > 0) printf(", ");
            if (res->es_bool) {
                printf("%s", res->valores[i] ? "true" : "false");
            } else {
                if (factor_global > 1) {
                    printf("%.3f", (double)res->valores[i] / factor_global);
                } else {
                    printf("%d", res->valores[i]);
                }
            }
        }
        if (res->n_valores > 10) printf(", ...");
        printf("] (%d valores)\n", res->n_valores);
    }
}
