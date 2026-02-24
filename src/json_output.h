#ifndef JSON_OUTPUT_H
#define JSON_OUTPUT_H

#include "bridge_types.h"
#include "expr_eval.h"

/* Genera salida en formato JSON */
void generar_salida_json(const char *archivo_entrada, const char *archivo_salida);

/* Variables globales para almacenar resultados */
typedef struct {
    char *expresion_str;
    ResultadoEval *resultado;
} ResultadoExpr;

extern ResultadoExpr resultados_expresiones[MAX_EXPRS];
extern int n_resultados;

#endif
