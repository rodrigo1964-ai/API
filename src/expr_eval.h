/* ================================================================
 * expr_eval.h - API del motor de evaluación de expresiones
 * Proyecto: GNUBison - Bridge GeCode Validator
 * ================================================================
 *
 * PROPÓSITO:
 *   Define la estructura ResultadoEval y las funciones principales del
 *   evaluador de expresiones con soporte de incertidumbre.
 *
 * ESTRUCTURA ResultadoEval:
 *   Representa el resultado de evaluar una expresión. Puede ser:
 *   - Valor único numérico: n_valores=1, es_bool=0
 *   - Valor único booleano: n_valores=1, es_bool=1
 *   - Múltiples valores (incertidumbre): n_valores>1
 *   - Conjunto: es_set=1, set_elementos[] contiene strings
 *
 * GESTIÓN DE MEMORIA:
 *   ResultadoEval aloca sus propios arrays (valores[], set_elementos[]).
 *   IMPORTANTE: Llamar liberar_resultado() después de usar para evitar leaks.
 *
 * EJEMPLO DE USO:
 *   Nodo *ast = parse_expression("x + y * 2");
 *   ResultadoEval *res = evaluar_expresion(ast);
 *
 *   if (res->n_valores == 1) {
 *       printf("Resultado: %d\n", res->valores[0]);
 *   } else {
 *       printf("Incertidumbre: %d valores posibles\n", res->n_valores);
 *   }
 *
 *   liberar_resultado(res);
 *   liberar_ast(ast);
 *
 * ================================================================ */

#ifndef EXPR_EVAL_H
#define EXPR_EVAL_H

#include "bridge_types.h"

/* ================================================================
 * ResultadoEval - Resultado de evaluación con incertidumbre
 * ================================================================
 *
 * Campos:
 *   - valores[]: Array de valores numéricos/booleanos posibles
 *   - n_valores: Cantidad de valores (1=determinista, >1=incertidumbre)
 *   - es_bool: 1 si es resultado booleano (imprime true/false)
 *   - set_elementos[]: Array de strings para resultados de tipo conjunto
 *   - n_set_elementos: Cantidad de elementos en el conjunto
 *   - es_set: 1 si es un conjunto (valores[] no aplica)
 *
 * Invariantes:
 *   - Si es_set==1: solo set_elementos[] es válido
 *   - Si es_set==0: solo valores[] es válido
 *   - n_valores > 0 (o n_set_elementos > 0 para sets)
 */
typedef struct {
    int *valores;         /* Array de valores posibles (escalados por factor_global) */
    int n_valores;        /* Cantidad de valores en el array */
    int es_bool;          /* 1 si resultado booleano (0/1 → false/true) */
    char **set_elementos; /* Array de elementos del conjunto (strings) */
    int n_set_elementos;  /* Cantidad de elementos en el conjunto */
    int es_set;           /* 1 si es un conjunto, 0 si numérico/booleano */
} ResultadoEval;

/* ================================================================
 * API PRINCIPAL
 * ================================================================ */

/* evaluar_expresion: Evalúa un AST y retorna todos los valores posibles
 *
 * Parámetros:
 *   - expr: Nodo raíz del AST (construido por parse_expression o Bison)
 *
 * Retorna:
 *   - ResultadoEval* alocado dinámicamente
 *   - NULL en caso de error grave (raro, usualmente retorna resultado válido)
 *
 * Propagación de incertidumbre:
 *   Si las variables tienen múltiples valores posibles, calcula el producto
 *   cartesiano de operandos. Ejemplo:
 *     x=[10,20], y=5 → evaluar_expresion("x+y") → {valores=[15,25], n=2}
 *
 * Gestión de memoria:
 *   - Aloca valores[] o set_elementos[] internamente
 *   - Llamar liberar_resultado() después de usar
 */
ResultadoEval* evaluar_expresion(Nodo *expr);

/* liberar_resultado: Libera memoria de un ResultadoEval
 *
 * Parámetros:
 *   - res: Resultado a liberar (puede ser NULL, función es null-safe)
 *
 * Libera:
 *   - res->valores (si no es NULL)
 *   - res->set_elementos[] y cada string interno (si es_set==1)
 *   - struct ResultadoEval
 */
void liberar_resultado(ResultadoEval *res);

/* imprimir_resultado: Imprime el resultado en formato legible
 *
 * Parámetros:
 *   - res: Resultado a imprimir
 *
 * Formato de salida:
 *   - Valor único numérico: "=> 42 (0.42)" (si factor_global > 1)
 *   - Valor booleano: "=> true" o "=> false"
 *   - Incertidumbre: "=> [15, 25, 35] (3 valores)"
 *   - Conjunto: "=> {A, B, C}"
 *
 * Salida: stdout
 */
void imprimir_resultado(ResultadoEval *res);

#endif /* EXPR_EVAL_H */
