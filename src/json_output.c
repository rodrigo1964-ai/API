#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "cJSON.h"
#include "json_output.h"
#include "bridge_types.h"

ResultadoExpr resultados_expresiones[MAX_EXPRS];
int n_resultados = 0;

void generar_salida_json(const char *archivo_entrada, const char *archivo_salida) {
    cJSON *root = cJSON_CreateObject();

    /* Metadata */
    cJSON_AddStringToObject(root, "archivo_entrada", archivo_entrada);
    cJSON_AddNumberToObject(root, "precision", precision_decimales);
    cJSON_AddNumberToObject(root, "factor", factor_global);

    /* Variables */
    cJSON *vars_array = cJSON_CreateArray();
    for (int i = 0; i < n_vars; i++) {
        cJSON *var_obj = cJSON_CreateObject();
        VarReg *v = &vars[i];

        cJSON_AddStringToObject(var_obj, "nombre", v->nombre);
        cJSON_AddStringToObject(var_obj, "tipo", tipo_str[v->tipo]);

        /* Dominio */
        cJSON *domain = NULL;
        if (v->tipo == T_SET && v->dom_n_miembros > 0) {
            domain = cJSON_CreateArray();
            for (int j = 0; j < v->dom_n_miembros; j++) {
                cJSON_AddItemToArray(domain, cJSON_CreateString(v->dom_set_miembros[j]));
            }
        } else if (v->tipo == T_LOGIC) {
            domain = cJSON_CreateArray();
            cJSON_AddItemToArray(domain, cJSON_CreateBool(1));
            cJSON_AddItemToArray(domain, cJSON_CreateBool(0));
        } else {
            domain = cJSON_CreateArray();
            cJSON_AddItemToArray(domain, cJSON_CreateNumber((double)v->dom_min / factor_global));
            cJSON_AddItemToArray(domain, cJSON_CreateNumber((double)v->dom_max / factor_global));
        }
        cJSON_AddItemToObject(var_obj, "dominio", domain);

        /* Valor */
        cJSON *value = NULL;
        if (v->tiene_value == 0) {
            value = cJSON_CreateNull();
        } else if (v->tiene_value == 1) {
            if (v->tipo == T_LOGIC) {
                value = cJSON_CreateBool(v->val_escalar);
            } else if (v->tipo == T_SET) {
                value = cJSON_CreateString(set_tabla[v->val_escalar]);
            } else {
                value = cJSON_CreateNumber((double)v->val_escalar / factor_global);
            }
        } else {
            value = cJSON_CreateArray();
            if (v->tipo == T_SET && v->val_set_miembros) {
                for (int j = 0; j < v->val_n; j++) {
                    cJSON_AddItemToArray(value, cJSON_CreateString(v->val_set_miembros[j]));
                }
            } else if (v->val_vals) {
                for (int j = 0; j < v->val_n; j++) {
                    if (v->tipo == T_LOGIC) {
                        cJSON_AddItemToArray(value, cJSON_CreateBool(v->val_vals[j]));
                    } else {
                        cJSON_AddItemToArray(value, cJSON_CreateNumber((double)v->val_vals[j] / factor_global));
                    }
                }
            }
        }
        cJSON_AddItemToObject(var_obj, "valor", value);

        cJSON_AddItemToArray(vars_array, var_obj);
    }
    cJSON_AddItemToObject(root, "variables", vars_array);

    /* Expresiones y Resultados */
    cJSON *exprs_array = cJSON_CreateArray();
    for (int i = 0; i < n_resultados; i++) {
        cJSON *expr_obj = cJSON_CreateObject();

        cJSON_AddStringToObject(expr_obj, "expresion", resultados_expresiones[i].expresion_str);

        /* Resultado */
        ResultadoEval *res = resultados_expresiones[i].resultado;
        cJSON *resultado = NULL;

        if (res && res->es_set) {
            /* Resultado de tipo conjunto */
            resultado = cJSON_CreateArray();
            for (int j = 0; j < res->n_set_elementos; j++) {
                cJSON_AddItemToArray(resultado, cJSON_CreateString(res->set_elementos[j]));
            }
        } else if (res && res->n_valores > 0) {
            if (res->n_valores == 1) {
                /* Valor único */
                if (res->es_bool) {
                    resultado = cJSON_CreateBool(res->valores[0]);
                } else {
                    resultado = cJSON_CreateNumber((double)res->valores[0] / factor_global);
                }
            } else {
                /* Múltiples valores */
                resultado = cJSON_CreateArray();
                for (int j = 0; j < res->n_valores; j++) {
                    if (res->es_bool) {
                        cJSON_AddItemToArray(resultado, cJSON_CreateBool(res->valores[j]));
                    } else {
                        cJSON_AddItemToArray(resultado, cJSON_CreateNumber((double)res->valores[j] / factor_global));
                    }
                }
            }
        } else {
            resultado = cJSON_CreateNull();
        }

        cJSON_AddItemToObject(expr_obj, "resultado", resultado);
        cJSON_AddItemToArray(exprs_array, expr_obj);
    }
    cJSON_AddItemToObject(root, "expresiones", exprs_array);

    /* Resumen */
    cJSON *resumen_obj = cJSON_CreateObject();
    cJSON_AddNumberToObject(resumen_obj, "total_variables", n_vars);
    cJSON_AddNumberToObject(resumen_obj, "total_expresiones", n_expresiones);
    cJSON_AddNumberToObject(resumen_obj, "errores", n_errores);
    cJSON_AddBoolToObject(resumen_obj, "valido", n_errores == 0);
    cJSON_AddItemToObject(root, "resumen", resumen_obj);

    /* Imprimir o guardar JSON */
    char *json_string = cJSON_Print(root);

    if (archivo_salida) {
        /* Guardar en archivo */
        FILE *fp = fopen(archivo_salida, "w");
        if (fp) {
            fprintf(fp, "%s\n", json_string);
            fclose(fp);
            printf("Resultados guardados en: %s\n", archivo_salida);
        } else {
            fprintf(stderr, "Error: no se puede escribir en '%s'\n", archivo_salida);
        }
    } else {
        /* Imprimir a stdout */
        printf("%s\n", json_string);
    }

    cJSON_free(json_string);
    cJSON_Delete(root);
}
