/* ================================================================
 * json_reader.h - API del parser de archivos JSON
 * Proyecto: GNUBison - Bridge GeCode Validator
 * ================================================================
 *
 * PROPÓSITO:
 *   Define la función principal de parsing de archivos JSON con
 *   especificaciones de constraint programming. Alternativa al parser
 *   Bison/Flex para formato Pascal-like.
 *
 * FORMATO JSON ESPERADO:
 *   {
 *     "precision": 2,
 *     "variables": [
 *       {
 *         "nombre": "x",
 *         "tipo": "integer|float|logic|set",
 *         "domain": [min, max] | {miembros: ["A", "B"]},
 *         "value": valor | [v1, v2, ...] | null
 *       }
 *     ],
 *     "expresiones": ["x + y", "estado IN {A,B}"]
 *   }
 *
 * USO TÍPICO:
 *   if (parse_json_file("ejemplo.json") == 0) {
 *       // Éxito: vars[], expresiones_str[] están pobladas
 *       // Resultados en resultados_expresiones[]
 *   }
 *
 * EFECTOS SECUNDARIOS:
 *   parse_json_file() modifica variables globales:
 *   - precision_decimales, factor_global
 *   - vars[], n_vars
 *   - expresiones_str[], n_expresiones
 *   - resultados_expresiones[], n_resultados
 *   - set_tabla[], n_set_entries
 *
 * PIPELINE INTERNO:
 *   JSON → cJSON_Parse() → Extracción de variables/dominios →
 *   parse_expression() (para cada expresión) → evaluar_expresion() →
 *   Resultados en resultados_expresiones[] → Salida (texto o JSON)
 *
 * ================================================================ */

#ifndef JSON_READER_H
#define JSON_READER_H

/* parse_json_file: Parsea un archivo JSON y ejecuta el pipeline completo
 *
 * Parámetros:
 *   - filename: Path del archivo JSON a procesar
 *
 * Retorna:
 *   - 0 si OK (JSON válido, parsing exitoso)
 *   - -1 si error (archivo no existe, JSON malformado, demasiadas variables)
 *
 * Proceso:
 *   1. Lee archivo completo a memoria
 *   2. Parsea JSON con cJSON_Parse()
 *   3. Extrae precision → precision_decimales, factor_global
 *   4. Extrae variables → vars[], n_vars
 *   5. Procesa expresiones:
 *      - parse_expression(expr_str) → AST
 *      - validar_expr(ast) → verifica variables declaradas
 *      - evaluar_expresion(ast) → ResultadoEval
 *      - Almacena en resultados_expresiones[]
 *   6. Genera salida:
 *      - Si json_output_mode==1: generar_salida_json()
 *      - Si json_output_mode==0: resumen() (texto)
 *
 * Errores reportados:
 *   - Archivo no existe → stderr + return -1
 *   - JSON malformado → stderr con cJSON_GetErrorPtr() + return -1
 *   - Demasiadas variables (> MAX_VARS) → stderr + return -1
 *
 * Depende de:
 *   - cJSON: Parsing de JSON
 *   - expr_parser.c: parse_expression()
 *   - expr_eval.c: evaluar_expresion()
 *   - json_output.c: generar_salida_json()
 *   - bridge_types.h: Estructuras globales
 */
int parse_json_file(const char *filename);

#endif /* JSON_READER_H */
