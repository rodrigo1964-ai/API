/* ================================================================
 * json_output.h - API del generador de salida JSON estructurada
 * Proyecto: GNUBison - Bridge GeCode Validator
 * ================================================================
 *
 * PROPÓSITO:
 *   Define la API para serializar resultados de evaluación a formato JSON
 *   estructurado. Complementa el modo debug (salida texto) con formato
 *   machine-readable para integración con herramientas externas.
 *
 * ESTRUCTURA DE SALIDA:
 *   {
 *     "archivo_entrada": "ejemplo.json",
 *     "precision": 2,
 *     "factor": 100,
 *     "variables": [ {nombre, tipo, dominio, valor}, ... ],
 *     "expresiones": [ {expresion, resultado}, ... ],
 *     "resumen": {total_variables, total_expresiones, errores, valido}
 *   }
 *
 * USO TÍPICO:
 *   // Después de evaluar todas las expresiones
 *   generar_salida_json("entrada.json", "salida.json");
 *
 *   // O imprimir a stdout
 *   generar_salida_json("entrada.json", NULL);
 *
 * GESTIÓN DE RESULTADOS:
 *   El array global resultados_expresiones[] acumula pares (expresion, resultado)
 *   durante el procesamiento. generar_salida_json() los serializa a JSON.
 *
 * ================================================================ */

#ifndef JSON_OUTPUT_H
#define JSON_OUTPUT_H

#include "bridge_types.h"
#include "expr_eval.h"

/* ================================================================
 * ResultadoExpr - Par (expresión, resultado) para salida JSON
 * ================================================================
 *
 * Almacena la expresión original (string) y su resultado evaluado.
 * Se llena durante parse_json_file() y se serializa en generar_salida_json().
 */
typedef struct {
    char *expresion_str;       /* Expresión original (ej: "x + y * 2") */
    ResultadoEval *resultado;  /* Resultado de evaluar_expresion() */
} ResultadoExpr;

/* ================================================================
 * VARIABLES GLOBALES
 * ================================================================ */

/* Array de resultados acumulados durante procesamiento */
extern ResultadoExpr resultados_expresiones[MAX_EXPRS];

/* Cantidad de resultados en el array */
extern int n_resultados;

/* ================================================================
 * API PRINCIPAL
 * ================================================================ */

/* generar_salida_json: Serializa resultados a formato JSON
 *
 * Parámetros:
 *   - archivo_entrada: Path del archivo de entrada (se incluye en JSON)
 *   - archivo_salida: Path donde guardar JSON (NULL = stdout)
 *
 * Salida:
 *   - Si archivo_salida != NULL: escribe JSON formateado al archivo
 *   - Si archivo_salida == NULL: imprime JSON a stdout
 *
 * Formato:
 *   - JSON pretty-printed (indentado) usando cJSON_Print()
 *   - Valores numéricos desescalados (div por factor_global)
 *   - Arrays de incertidumbre serializados como arrays JSON
 *   - Valor único como escalar (no array de 1 elemento)
 *
 * Depende de:
 *   - Variables globales: vars[], n_vars, precision_decimales, factor_global
 *   - resultados_expresiones[], n_resultados
 */
void generar_salida_json(const char *archivo_entrada, const char *archivo_salida);

#endif /* JSON_OUTPUT_H */
