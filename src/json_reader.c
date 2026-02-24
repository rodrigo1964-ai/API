#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "cJSON.h"
#include "bridge_types.h"
#include "json_reader.h"
#include "expr_eval.h"
#include "json_output.h"

/* Parser simple de expresiones JSON */
extern Nodo* parse_expression(const char *expr_str);

/* Modo de salida */
extern int json_output_mode;

static int parse_json_variables(cJSON *vars_array) {
    int count = 0;
    cJSON *var_item = NULL;

    cJSON_ArrayForEach(var_item, vars_array) {
        if (count >= MAX_VARS) {
            fprintf(stderr, "Error: demasiadas variables (max %d)\n", MAX_VARS);
            return -1;
        }

        VarReg *v = &vars[count];

        /* Nombre */
        cJSON *nombre = cJSON_GetObjectItem(var_item, "nombre");
        if (!nombre || !cJSON_IsString(nombre)) continue;
        v->nombre = strdup(nombre->valuestring);

        /* Tipo */
        cJSON *tipo = cJSON_GetObjectItem(var_item, "tipo");
        if (!tipo || !cJSON_IsString(tipo)) continue;

        if (strcmp(tipo->valuestring, "integer") == 0) v->tipo = T_INTEGER;
        else if (strcmp(tipo->valuestring, "float") == 0) v->tipo = T_FLOAT;
        else if (strcmp(tipo->valuestring, "logic") == 0) v->tipo = T_LOGIC;
        else if (strcmp(tipo->valuestring, "set") == 0) v->tipo = T_SET;

        /* Domain */
        cJSON *domain = cJSON_GetObjectItem(var_item, "domain");
        if (domain) {
            if (cJSON_IsArray(domain) && cJSON_GetArraySize(domain) == 2) {
                /* Dominio numérico [min, max] */
                v->dom_min = (int)(cJSON_GetArrayItem(domain, 0)->valuedouble * factor_global);
                v->dom_max = (int)(cJSON_GetArrayItem(domain, 1)->valuedouble * factor_global);
            } else if (cJSON_IsObject(domain)) {
                /* Dominio de set */
                cJSON *miembros = cJSON_GetObjectItem(domain, "miembros");
                if (miembros && cJSON_IsArray(miembros)) {
                    int n = cJSON_GetArraySize(miembros);
                    v->dom_set_miembros = malloc(n * sizeof(char*));
                    v->dom_n_miembros = n;
                    for (int i = 0; i < n; i++) {
                        cJSON *m = cJSON_GetArrayItem(miembros, i);
                        v->dom_set_miembros[i] = strdup(m->valuestring);
                        reg_set(m->valuestring);
                    }
                }
            }
        }

        /* Value */
        cJSON *value = cJSON_GetObjectItem(var_item, "value");
        if (!value || cJSON_IsNull(value)) {
            v->tiene_value = 0;
        } else if (cJSON_IsNumber(value)) {
            v->tiene_value = 1;
            v->val_escalar = (int)(value->valuedouble * factor_global);
        } else if (cJSON_IsBool(value)) {
            v->tiene_value = 1;
            v->val_escalar = cJSON_IsTrue(value) ? 1 : 0;
        } else if (cJSON_IsString(value)) {
            v->tiene_value = 1;
            v->val_escalar = reg_set(value->valuestring);
        } else if (cJSON_IsArray(value)) {
            int n = cJSON_GetArraySize(value);
            v->tiene_value = 2;
            v->val_n = n;

            cJSON *first = cJSON_GetArrayItem(value, 0);
            if (cJSON_IsNumber(first)) {
                v->val_vals = malloc(n * sizeof(int));
                for (int i = 0; i < n; i++) {
                    cJSON *item = cJSON_GetArrayItem(value, i);
                    v->val_vals[i] = (int)(item->valuedouble * factor_global);
                }
            } else if (cJSON_IsBool(first)) {
                /* Array de booleanos */
                v->val_vals = malloc(n * sizeof(int));
                for (int i = 0; i < n; i++) {
                    cJSON *item = cJSON_GetArrayItem(value, i);
                    v->val_vals[i] = cJSON_IsTrue(item) ? 1 : 0;
                }
            } else if (cJSON_IsString(first)) {
                v->val_set_miembros = malloc(n * sizeof(char*));
                for (int i = 0; i < n; i++) {
                    cJSON *item = cJSON_GetArrayItem(value, i);
                    v->val_set_miembros[i] = strdup(item->valuestring);
                }
            }
        }

        /* Imprimir solo si no es modo JSON output */
        if (!json_output_mode) {
            printf("  [%d] %s : %s", count, v->nombre, tipo_str[v->tipo]);
            if (v->tipo == T_SET) {
                printf(" dom={");
                for (int i = 0; i < v->dom_n_miembros; i++)
                    printf("%s%s", i?",":"", v->dom_set_miembros[i]);
                printf("}");
            } else if (v->tipo == T_LOGIC)
                printf(" dom={0,1}");
            else
                printf(" dom=[%d..%d]", v->dom_min, v->dom_max);

            switch (v->tiene_value) {
                case 0: printf(" val=nil"); break;
                case 1: printf(" val=%d (fijo)", v->val_escalar); break;
                case 2: printf(" val=[incert. %d vals]", v->val_n); break;
            }
            printf("\n");
        }

        count++;
    }

    return count;
}

int parse_json_file(const char *filename) {
    FILE *fp = fopen(filename, "r");
    if (!fp) {
        fprintf(stderr, "Error: no se puede abrir %s\n", filename);
        return -1;
    }

    /* Leer archivo completo */
    fseek(fp, 0, SEEK_END);
    long size = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    char *content = malloc(size + 1);
    fread(content, 1, size, fp);
    content[size] = '\0';
    fclose(fp);

    /* Parsear JSON */
    cJSON *root = cJSON_Parse(content);
    free(content);

    if (!root) {
        const char *error_ptr = cJSON_GetErrorPtr();
        if (error_ptr) {
            fprintf(stderr, "Error JSON: %s\n", error_ptr);
        }
        return -1;
    }

    if (!json_output_mode) {
        printf("Bridge GeCode - Validador JSON\n");
        printf("====================================\n\n");
    }

    /* Precision */
    cJSON *precision = cJSON_GetObjectItem(root, "precision");
    if (precision && cJSON_IsNumber(precision)) {
        precision_decimales = precision->valueint;
        factor_global = (int)pow(10, precision_decimales);
        if (!json_output_mode) {
            printf("=== PRECISION: %d decimales (factor=%d) ===\n\n",
                   precision_decimales, factor_global);
        }
    }

    /* Variables */
    cJSON *variables = cJSON_GetObjectItem(root, "variables");
    if (variables && cJSON_IsArray(variables)) {
        if (!json_output_mode) {
            printf("=== VARIABLES ===\n");
        }
        n_vars = parse_json_variables(variables);
        if (!json_output_mode) {
            printf("\n");
        }
    }

    /* Expresiones */
    cJSON *expresiones = cJSON_GetObjectItem(root, "expresiones");
    if (expresiones && cJSON_IsArray(expresiones)) {
        if (!json_output_mode) {
            printf("=== EXPRESIONES ===\n");
        }
        int count = 0;
        cJSON *expr_item = NULL;

        cJSON_ArrayForEach(expr_item, expresiones) {
            if (cJSON_IsString(expr_item)) {
                expresiones_str[count] = strdup(expr_item->valuestring);

                if (!json_output_mode) {
                    printf("  Expr #%d: %s\n", count + 1, expr_item->valuestring);
                }

                /* Parsear y validar expresión */
                Nodo *ast = parse_expression(expr_item->valuestring);
                if (ast) {
                    if (!json_output_mode) {
                        imprimir_ast(ast, 4);
                    }
                    validar_expr(ast);

                    /* Evaluar expresión */
                    if (!json_output_mode) {
                        printf("  Evaluando...\n");
                    }
                    ResultadoEval *resultado = evaluar_expresion(ast);

                    /* Guardar resultado */
                    resultados_expresiones[n_resultados].expresion_str = strdup(expr_item->valuestring);
                    resultados_expresiones[n_resultados].resultado = resultado;
                    n_resultados++;

                    if (!json_output_mode) {
                        imprimir_resultado(resultado);
                    }

                    liberar_ast(ast);
                }
                if (!json_output_mode) {
                    printf("\n");
                }
                count++;
            }
        }
        n_expresiones = count;
    }

    cJSON_Delete(root);

    if (json_output_mode) {
        extern char *archivo_salida_json;
        generar_salida_json(filename, archivo_salida_json);
    } else {
        resumen();
    }

    return 0;
}
