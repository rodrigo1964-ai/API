/* ================================================================
 * bridge_gecode.y - Parser Bison para formato Pascal-like
 * Proyecto: GNUBison - Bridge GeCode Validator
 * ================================================================
 *
 * PROPÓSITO:
 *   Parser principal del proyecto. Analiza archivos de especificación en
 *   notación Pascal-like (alternativa textual a JSON) con secciones de
 *   precision, variables, expresiones y funciones. Construye AST de
 *   expresiones y valida tipos/dominios.
 *
 * ARQUITECTURA:
 *   Bison parser + Flex lexer → AST + tablas globales
 *
 *   Pipeline:
 *   1. Análisis léxico (bridge_gecode.l): Tokens
 *   2. Análisis sintáctico (este archivo): Reglas gramaticales
 *   3. Acciones semánticas: Registro en vars[], funcs[], construcción AST
 *   4. Validación: validar_expr() verifica variables declaradas
 *   5. Evaluación: Para formato Pascal-like solo imprime AST (no evalúa)
 *
 * FORMATO PASCAL-LIKE:
 *   precision: 2;
 *
 *   variables: {
 *     x : integer : [1..100] : 42;
 *     estado : set : {A, B, C} : A;
 *     activo : logic : {0,1} : true;
 *   }
 *
 *   expresiones: {
 *     x + 10;
 *     estado IN {A, B};
 *   }
 *
 *   funciones: {
 *     distancia : [x, y] : float;
 *   }
 *
 * DECISIONES DE DISEÑO:
 *   - Modo dry-run: Solo valida sintaxis y construye AST, no ejecuta solver.
 *     La evaluación real solo ocurre en modo JSON (json_reader.c).
 *   - Gramática LL(1) compatible: Sin ambigüedades, precedencia declarativa.
 *   - Registro incremental: Cada regla semántica actualiza vars[n_vars++]
 *     directamente (no construcción de árbol intermedio).
 *   - Dominios tipados:
 *       integer/float: [min..max]
 *       logic: {0,1} (implícito)
 *       set: {str1, str2, ...}
 *   - Valores con incertidumbre: [val1, val2, ...] en Pascal-like también
 *     soportado (tiene_value=2).
 *
 * DIFERENCIAS CON JSON:
 *   - JSON: Evaluación completa (json_reader.c → expr_eval.c)
 *   - Pascal-like: Solo validación + AST printing (útil para debug)
 *   - JSON: Formato machine-readable (APIs, pipelines)
 *   - Pascal-like: Formato human-readable (edición manual, ejemplos)
 *
 * INTEGRACIÓN:
 *   - Lexer: bridge_gecode.l define tokens (yylex)
 *   - Main: Detecta formato (JSON vs Pascal) y llama yyparse() o parse_json_file()
 *   - Salida: resumen() imprime estadísticas finales
 *
 * REFERENCIAS:
 *   - GNU Bison 3.x: Parser generator (https://www.gnu.org/software/bison/)
 *   - bridge_gecode.l: Lexer Flex asociado
 *   - bridge_types.h: Definiciones de VarReg, FuncReg, Nodo
 *   - json_reader.c: Parser alternativo para formato JSON
 *
 * RELACIÓN CON GNU BISON UPSTREAM:
 *   Este proyecto usa GNU Bison como herramienta (parser generator), no es
 *   un fork de Bison. El nombre "GNUBison" del directorio es histórico y
 *   refleja el uso de Bison + GeCode para constraint programming.
 *
 * ================================================================ */

%{
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <ctype.h>
#include "bridge_types.h"

/* ---- Implementación de variables globales ---- */
int precision_decimales = 1;
int factor_global = 10;

const char *tipo_str[] = {"integer", "float", "logic", "set"};

const char *nodo_str[] = {
    "IDENT", "ENTERO", "BOOL", "SET_LIT",
    "+", "-", "*", "/",
    "=", "<>", "<", ">", "<=", ">=",
    "AND", "OR", "NOT", "IMPLICA",
    "abs", "sqrt", "sqr", "sin", "cos", "ln", "exp",
    "CALL", "IN",
    "UNION", "INTERSECT", "DIFFERENCE", "SUBSET", "CARDINALITY"
};

VarReg  vars[MAX_VARS];
int     n_vars = 0;
FuncReg funcs[MAX_FUNCS];
int     n_funcs = 0;
char   *set_tabla[MAX_SET_ENTRIES];
int     n_set_entries = 0;
int     n_expresiones = 0;
int     n_errores = 0;
char   *expresiones_str[MAX_EXPRS];
int     json_output_mode = 0;
char   *archivo_salida_json = NULL;

/* Temporales para listas */
int     tmp_int[MAX_LIST], tmp_int_n = 0;
char   *tmp_str[MAX_LIST];
int     tmp_str_n = 0;
char   *tmp_ent[MAX_LIST];
int     tmp_ent_n = 0;

/* ---- Prototipos ---- */
void  yyerror(const char *s);
int   yylex(void);
extern int yylineno;
extern char *yytext;
%}

%code requires {
    #include "bridge_types.h"
}

%union {
    int     entero;
    char   *str;
    Nodo   *nodo;
    struct { Nodo **lista; int n; } arg_lista;
}

%token <entero> NUMERO
%token <str>    IDENTIFICADOR STRING_LIT
%token BOOL_TRUE BOOL_FALSE
%token PRECISION VARIABLES EXPRESIONES FUNCIONES
%token TIPO_INTEGER TIPO_FLOAT TIPO_LOGIC TIPO_SET
%token NIL
%token AND OR NOT IMPLICA
%token EQ NEQ LT GT LEQ GEQ
%token IN UNION INTERSECT DIFFERENCE SUBSET CARDINALITY
%token FN_ABS FN_SQRT FN_SQR FN_SIN FN_COS FN_LN FN_EXP
%token LBRACE RBRACE LBRACKET RBRACKET LPAREN RPAREN
%token COMMA COLON SEMICOLON

%type <nodo> expresion expr_impl expr_or expr_and expr_not
%type <nodo> expr_comp expr_set_op expr_arit expr_term expr_factor expr_atom
%type <nodo> func_std_call set_literal
%type <arg_lista> lista_args lista_set_elementos
%type <entero> tipo

%%

/* ================ NIVEL SUPERIOR ================ */

programa
    : decl_precision sec_vars sec_expr sec_funcs  { resumen(); }
    ;

decl_precision
    : PRECISION COLON NUMERO SEMICOLON
        {
            precision_decimales = $3;
            factor_global = (int)pow(10, $3);
            printf("=== PRECISION: %d decimales (factor=%d) ===\n\n",
                   precision_decimales, factor_global);
        }
    ;

/* ================ SECCION 1: VARIABLES ================ */

sec_vars
    : VARIABLES COLON LBRACE { printf("=== VARIABLES ===\n"); }
      lista_vars RBRACE      { printf("\n"); }
    ;

lista_vars
    : /* vacío */
    | una_var
    | lista_vars una_var
    ;

una_var
    : IDENTIFICADOR COLON tipo COLON dominio COLON valor SEMICOLON
        {
            VarReg *v = &vars[n_vars];
            v->nombre = $1;
            v->tipo = (TipoVar)$3;
            if (v->tipo == T_SET) {
                v->dom_set_miembros = malloc(tmp_str_n * sizeof(char*));
                memcpy(v->dom_set_miembros, tmp_str, tmp_str_n * sizeof(char*));
                v->dom_n_miembros = tmp_str_n;
                for (int i = 0; i < tmp_str_n; i++) reg_set(tmp_str[i]);
            } else if (tmp_int_n == 2 && v->tipo != T_LOGIC) {
                v->dom_min = tmp_int[0];
                v->dom_max = tmp_int[1];
            }
            /* Imprimir */
            printf("  [%d] %s : %s", n_vars, v->nombre, tipo_str[v->tipo]);
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
            n_vars++;
        }
    ;

tipo
    : TIPO_INTEGER { $$ = T_INTEGER; }
    | TIPO_FLOAT   { $$ = T_FLOAT; }
    | TIPO_LOGIC   { $$ = T_LOGIC; }
    | TIPO_SET     { $$ = T_SET; }
    ;

dominio
    : LBRACKET NUMERO COMMA NUMERO RBRACKET
        { tmp_int[0]=$2; tmp_int[1]=$4; tmp_int_n=2; }
    | LBRACKET BOOL_TRUE COMMA BOOL_FALSE RBRACKET
        { tmp_int_n=0; }
    | LBRACE STRING_LIT COLON LBRACKET dom_strs RBRACKET RBRACE
        { vars[n_vars].dom_set_nombre = $2; }
    | NIL
        { tmp_int_n=0; tmp_str_n=0; }
    ;

dom_strs
    : STRING_LIT                   { tmp_str_n=0; tmp_str[tmp_str_n++]=$1; }
    | dom_strs COMMA STRING_LIT   { tmp_str[tmp_str_n++]=$3; }
    ;

valor
    : NUMERO
        { vars[n_vars].tiene_value=1; vars[n_vars].val_escalar=$1; }
    | BOOL_TRUE
        { vars[n_vars].tiene_value=1; vars[n_vars].val_escalar=1; }
    | BOOL_FALSE
        { vars[n_vars].tiene_value=1; vars[n_vars].val_escalar=0; }
    | STRING_LIT
        { vars[n_vars].tiene_value=1; vars[n_vars].val_escalar=reg_set($1); }
    | LBRACKET val_nums RBRACKET
        {
            vars[n_vars].tiene_value=2;
            vars[n_vars].val_vals=malloc(tmp_int_n*sizeof(int));
            memcpy(vars[n_vars].val_vals, tmp_int, tmp_int_n*sizeof(int));
            vars[n_vars].val_n=tmp_int_n;
        }
    | LBRACKET val_strs RBRACKET
        {
            vars[n_vars].tiene_value=2;
            vars[n_vars].val_set_miembros=malloc(tmp_str_n*sizeof(char*));
            memcpy(vars[n_vars].val_set_miembros, tmp_str, tmp_str_n*sizeof(char*));
            vars[n_vars].val_n=tmp_str_n;
        }
    | LBRACKET BOOL_TRUE COMMA BOOL_FALSE RBRACKET
        { vars[n_vars].tiene_value=2; vars[n_vars].val_n=2; }
    | NIL
        { vars[n_vars].tiene_value=0; }
    ;

val_nums
    : NUMERO                     { tmp_int_n=0; tmp_int[tmp_int_n++]=$1; }
    | val_nums COMMA NUMERO      { tmp_int[tmp_int_n++]=$3; }
    ;

val_strs
    : STRING_LIT                 { tmp_str_n=0; tmp_str[tmp_str_n++]=$1; }
    | val_strs COMMA STRING_LIT  { tmp_str[tmp_str_n++]=$3; }
    ;

/* ================ SECCION 2: EXPRESIONES ================ */

sec_expr
    : EXPRESIONES COLON LBRACE { printf("=== EXPRESIONES ===\n"); }
      lista_expr RBRACE        { printf("\n"); }
    ;

lista_expr
    : /* vacío */
    | una_expr
    | lista_expr una_expr
    ;

una_expr
    : expresion SEMICOLON
        {
            n_expresiones++;
            printf("  Expr #%d:\n", n_expresiones);
            imprimir_ast($1, 4);
            validar_expr($1);
            printf("\n");
            liberar_ast($1);
        }
    ;

expresion : expr_impl ;

expr_impl
    : expr_or IMPLICA expr_or  { $$ = nodo_binario(NODO_IMPLICA,$1,$3); }
    | expr_or
    ;

expr_or
    : expr_or OR expr_and      { $$ = nodo_binario(NODO_OR,$1,$3); }
    | expr_and
    ;

expr_and
    : expr_and AND expr_not    { $$ = nodo_binario(NODO_AND,$1,$3); }
    | expr_not
    ;

expr_not
    : NOT expr_not             { $$ = nodo_unario(NODO_NOT,$2); }
    | expr_comp
    ;

expr_comp
    : expr_set_op EQ  expr_set_op { $$ = nodo_binario(NODO_EQ,$1,$3); }
    | expr_set_op NEQ expr_set_op { $$ = nodo_binario(NODO_NEQ,$1,$3); }
    | expr_set_op LT  expr_set_op { $$ = nodo_binario(NODO_LT,$1,$3); }
    | expr_set_op GT  expr_set_op { $$ = nodo_binario(NODO_GT,$1,$3); }
    | expr_set_op LEQ expr_set_op { $$ = nodo_binario(NODO_LEQ,$1,$3); }
    | expr_set_op GEQ expr_set_op { $$ = nodo_binario(NODO_GEQ,$1,$3); }
    | expr_set_op IN set_literal { $$ = nodo_binario(NODO_IN,$1,$3); }
    | expr_set_op IN IDENTIFICADOR { $$ = nodo_binario(NODO_IN,$1,nodo_ident($3)); }
    | expr_set_op SUBSET set_literal { $$ = nodo_binario(NODO_SUBSET,$1,$3); }
    | expr_set_op SUBSET IDENTIFICADOR { $$ = nodo_binario(NODO_SUBSET,$1,nodo_ident($3)); }
    | expr_set_op
    ;

expr_set_op
    : expr_set_op UNION expr_arit { $$ = nodo_binario(NODO_UNION,$1,$3); }
    | expr_set_op INTERSECT expr_arit { $$ = nodo_binario(NODO_INTERSECT,$1,$3); }
    | expr_set_op DIFFERENCE expr_arit { $$ = nodo_binario(NODO_DIFFERENCE,$1,$3); }
    | CARDINALITY LPAREN expr_set_op RPAREN { $$ = nodo_unario(NODO_CARDINALITY,$3); }
    | expr_arit
    ;

expr_arit
    : expr_arit '+' expr_term { $$ = nodo_binario(NODO_SUMA,$1,$3); }
    | expr_arit '-' expr_term { $$ = nodo_binario(NODO_RESTA,$1,$3); }
    | expr_term
    ;

expr_term
    : expr_term '*' expr_factor { $$ = nodo_binario(NODO_MULT,$1,$3); }
    | expr_term '/' expr_factor { $$ = nodo_binario(NODO_DIV,$1,$3); }
    | expr_factor
    ;

expr_factor
    : func_std_call
    | IDENTIFICADOR LPAREN lista_args RPAREN
        { $$ = nodo_func_call($1, $3.lista, $3.n); }
    | expr_atom
    ;

expr_atom
    : NUMERO          { $$ = nodo_entero($1); }
    | BOOL_TRUE       { $$ = nodo_bool(1); }
    | BOOL_FALSE      { $$ = nodo_bool(0); }
    | IDENTIFICADOR   { $$ = nodo_ident($1); }
    | set_literal     { $$ = $1; }
    | LPAREN expresion RPAREN { $$ = $2; }
    ;

set_literal
    : LBRACE lista_set_elementos RBRACE
        {
            Nodo *n = calloc(1, sizeof(Nodo));
            n->tipo = NODO_SET_LIT;
            n->set_n_elementos = $2.n;
            n->set_elementos = malloc($2.n * sizeof(char*));
            for (int i = 0; i < $2.n; i++) {
                /* Convertir nodos a strings */
                if ($2.lista[i]->tipo == NODO_IDENT) {
                    n->set_elementos[i] = strdup($2.lista[i]->nombre);
                } else if ($2.lista[i]->tipo == NODO_ENTERO) {
                    char buf[32];
                    snprintf(buf, sizeof(buf), "%d", $2.lista[i]->valor_entero);
                    n->set_elementos[i] = strdup(buf);
                } else {
                    yyerror("Solo se permiten identificadores y números en sets literales");
                    n->set_elementos[i] = strdup("error");
                }
                liberar_ast($2.lista[i]);
            }
            free($2.lista);
            $$ = n;
        }
    | LBRACE RBRACE  /* Conjunto vacío */
        {
            Nodo *n = calloc(1, sizeof(Nodo));
            n->tipo = NODO_SET_LIT;
            n->set_n_elementos = 0;
            n->set_elementos = NULL;
            $$ = n;
        }
    ;

lista_set_elementos
    : IDENTIFICADOR
        { $$.lista=malloc(sizeof(Nodo*)); $$.lista[0]=nodo_ident($1); $$.n=1; }
    | NUMERO
        { $$.lista=malloc(sizeof(Nodo*)); $$.lista[0]=nodo_entero($1); $$.n=1; }
    | lista_set_elementos COMMA IDENTIFICADOR
        { $$.lista=realloc($1.lista,($1.n+1)*sizeof(Nodo*));
          $$.lista[$1.n]=nodo_ident($3); $$.n=$1.n+1; }
    | lista_set_elementos COMMA NUMERO
        { $$.lista=realloc($1.lista,($1.n+1)*sizeof(Nodo*));
          $$.lista[$1.n]=nodo_entero($3); $$.n=$1.n+1; }
    ;

func_std_call
    : FN_ABS  LPAREN expresion RPAREN { $$ = nodo_func_std(NODO_ABS,$3); }
    | FN_SQRT LPAREN expresion RPAREN { $$ = nodo_func_std(NODO_SQRT,$3); }
    | FN_SQR  LPAREN expresion RPAREN { $$ = nodo_func_std(NODO_SQR,$3); }
    | FN_SIN  LPAREN expresion RPAREN { $$ = nodo_func_std(NODO_SIN,$3); }
    | FN_COS  LPAREN expresion RPAREN { $$ = nodo_func_std(NODO_COS,$3); }
    | FN_LN   LPAREN expresion RPAREN { $$ = nodo_func_std(NODO_LN,$3); }
    | FN_EXP  LPAREN expresion RPAREN { $$ = nodo_func_std(NODO_EXP,$3); }
    ;

lista_args
    : expresion
        { $$.lista=malloc(sizeof(Nodo*)); $$.lista[0]=$1; $$.n=1; }
    | lista_args COMMA expresion
        { $$.lista=realloc($1.lista,($1.n+1)*sizeof(Nodo*));
          $$.lista[$1.n]=$3; $$.n=$1.n+1; }
    ;

/* ================ SECCION 3: FUNCIONES ================ */

sec_funcs
    : FUNCIONES COLON LBRACE { printf("=== FUNCIONES ===\n"); }
      lista_funcs RBRACE     { printf("\n"); }
    ;

lista_funcs
    : /* vacío */
    | una_func
    | lista_funcs una_func
    ;

una_func
    : IDENTIFICADOR COLON LBRACKET func_ents RBRACKET COLON func_sal SEMICOLON
        {
            FuncReg *f = &funcs[n_funcs];
            f->nombre = $1;
            f->entradas = malloc(tmp_ent_n * sizeof(char*));
            memcpy(f->entradas, tmp_ent, tmp_ent_n * sizeof(char*));
            f->n_entradas = tmp_ent_n;
            printf("  [%d] %s(", n_funcs, f->nombre);
            for (int i = 0; i < f->n_entradas; i++)
                printf("%s%s", i?", ":"", f->entradas[i]);
            printf(") -> %s\n", f->tiene_salida ? f->salida : "nil");
            for (int i = 0; i < f->n_entradas; i++)
                if (buscar_var(f->entradas[i]) < 0) {
                    printf("    *** ERROR: '%s' no declarada\n", f->entradas[i]);
                    n_errores++;
                }
            n_funcs++;
        }
    ;

func_ents
    : IDENTIFICADOR                    { tmp_ent_n=0; tmp_ent[tmp_ent_n++]=$1; }
    | func_ents COMMA IDENTIFICADOR    { tmp_ent[tmp_ent_n++]=$3; }
    ;

func_sal
    : IDENTIFICADOR { funcs[n_funcs].tiene_salida=1; funcs[n_funcs].salida=$1; }
    | NIL           { funcs[n_funcs].tiene_salida=0; funcs[n_funcs].salida=NULL; }
    ;

%%

/* ================ FUNCIONES C ================ */

struct Nodo* nodo_ident(const char *s) {
    struct Nodo *n=calloc(1,sizeof(struct Nodo)); n->tipo=NODO_IDENT; n->nombre=strdup(s); return n;
}
struct Nodo* nodo_entero(int v) {
    struct Nodo *n=calloc(1,sizeof(struct Nodo)); n->tipo=NODO_ENTERO; n->valor_entero=v; return n;
}
struct Nodo* nodo_bool(int v) {
    struct Nodo *n=calloc(1,sizeof(struct Nodo)); n->tipo=NODO_BOOL; n->valor_bool=v; return n;
}
struct Nodo* nodo_unario(TipoNodo t, struct Nodo *h) {
    struct Nodo *n=calloc(1,sizeof(struct Nodo)); n->tipo=t; n->izq=h; return n;
}
struct Nodo* nodo_binario(TipoNodo t, struct Nodo *i, struct Nodo *d) {
    struct Nodo *n=calloc(1,sizeof(struct Nodo)); n->tipo=t; n->izq=i; n->der=d; return n;
}
struct Nodo* nodo_func_std(TipoNodo t, struct Nodo *a) {
    struct Nodo *n=calloc(1,sizeof(struct Nodo)); n->tipo=t; n->izq=a; return n;
}
struct Nodo* nodo_func_call(const char *s, struct Nodo **a, int na) {
    struct Nodo *n=calloc(1,sizeof(struct Nodo)); n->tipo=NODO_FUNC_CALL;
    n->nombre=strdup(s); n->args=a; n->n_args=na; return n;
}

void imprimir_ast(struct Nodo *n, int niv) {
    if (!n) return;
    for (int i=0;i<niv;i++) printf(" ");
    switch (n->tipo) {
        case NODO_IDENT:
            printf("IDENT(%s)\n", n->nombre); break;
        case NODO_ENTERO:
            if (factor_global > 1)
                printf("ENTERO(%d = %.3f)\n", n->valor_entero,
                       (double)n->valor_entero/factor_global);
            else
                printf("ENTERO(%d)\n", n->valor_entero);
            break;
        case NODO_BOOL:
            printf("BOOL(%s)\n", n->valor_bool?"true":"false"); break;
        case NODO_SET_LIT:
            printf("SET{");
            for (int i=0;i<n->set_n_elementos;i++)
                printf("%s%s", i?",":"", n->set_elementos[i]);
            printf("}\n");
            break;
        case NODO_FUNC_CALL:
            printf("CALL %s(\n", n->nombre);
            for (int i=0;i<n->n_args;i++) imprimir_ast(n->args[i],niv+2);
            for (int i=0;i<niv;i++) printf(" ");
            printf(")\n"); break;
        case NODO_CARDINALITY:
            printf("[%s]\n", nodo_str[n->tipo]);
            imprimir_ast(n->izq, niv+2);
            break;
        default:
            printf("[%s]\n", nodo_str[n->tipo]);
            imprimir_ast(n->izq, niv+2);
            imprimir_ast(n->der, niv+2);
    }
}

void liberar_ast(struct Nodo *n) {
    if (!n) return;
    free(n->nombre);
    liberar_ast(n->izq); liberar_ast(n->der);
    if (n->args) {
        for (int i=0;i<n->n_args;i++) liberar_ast(n->args[i]);
        free(n->args);
    }
    if (n->tipo == NODO_SET_LIT && n->set_elementos) {
        for (int i=0;i<n->set_n_elementos;i++) free(n->set_elementos[i]);
        free(n->set_elementos);
    }
    free(n);
}

int buscar_var(const char *s) {
    for (int i=0;i<n_vars;i++) if (strcmp(vars[i].nombre,s)==0) return i;
    return -1;
}

int reg_set(const char *s) {
    for (int i=0;i<n_set_entries;i++) if (strcmp(set_tabla[i],s)==0) return i;
    set_tabla[n_set_entries]=strdup(s);
    return n_set_entries++;
}

void validar_expr(struct Nodo *n) {
    if (!n) return;
    if (n->tipo==NODO_IDENT && buscar_var(n->nombre)<0) {
        printf("    *** ERROR: '%s' no declarada\n", n->nombre);
        n_errores++;
    }
    validar_expr(n->izq); validar_expr(n->der);
    if (n->args) for (int i=0;i<n->n_args;i++) validar_expr(n->args[i]);
}

void resumen(void) {
    int ni=0,nf=0,nl=0,ns=0;
    for (int i=0;i<n_vars;i++) switch(vars[i].tipo) {
        case T_INTEGER:ni++;break; case T_FLOAT:nf++;break;
        case T_LOGIC:nl++;break; case T_SET:ns++;break;
    }
    printf("========================================\n");
    printf("RESUMEN\n");
    printf("========================================\n");
    printf("  Variables: %d (int:%d float:%d logic:%d set:%d)\n",
           n_vars,ni,nf,nl,ns);
    printf("  Expresiones: %d\n", n_expresiones);
    printf("  Funciones:   %d\n", n_funcs);
    if (n_set_entries) {
        printf("  TablaGlobal sets:\n");
        for (int i=0;i<n_set_entries;i++) printf("    [%d] %s\n",i,set_tabla[i]);
    }
    printf("  Errores: %d\n", n_errores);
    printf(n_errores==0 ?
        "\n  >>> JSON VALIDO - listo para el Bridge <<<\n" :
        "\n  >>> ERRORES ENCONTRADOS - corregir <<<\n");
}

void yyerror(const char *s) {
    fprintf(stderr, "Error linea %d: %s (cerca de '%s')\n", yylineno, s, yytext);
    n_errores++;
}

int main(int argc, char **argv) {
    char *archivo_entrada = NULL;
    char *archivo_salida = NULL;

    /* Parsear argumentos */
    if (argc >= 2) {
        archivo_entrada = argv[1];
    }
    if (argc >= 3) {
        archivo_salida = argv[2];
        archivo_salida_json = archivo_salida;
        json_output_mode = 1;  /* Activar modo JSON si hay archivo de salida */
    }

    /* Mostrar uso si no hay argumentos */
    if (!archivo_entrada) {
        printf("Uso:\n");
        printf("  %s <entrada.json>              # Validar y evaluar (salida texto)\n", argv[0]);
        printf("  %s <entrada.json> <salida.json> # Validar y evaluar (salida JSON)\n", argv[0]);
        printf("  %s <entrada.txt>               # Validar formato Pascal-like\n", argv[0]);
        return 1;
    }

    /* Detectar si es JSON */
    FILE *f = fopen(archivo_entrada, "r");
    if (!f) {
        fprintf(stderr, "Error: no se puede abrir '%s'\n", archivo_entrada);
        return 1;
    }

    int c;
    while ((c = fgetc(f)) != EOF && isspace(c));
    fclose(f);

    if (c == '{') {
        /* Es JSON */
        extern int parse_json_file(const char *);
        int resultado = parse_json_file(archivo_entrada);

        /* Si hay archivo de salida, redirigir stdout */
        if (archivo_salida && resultado == 0) {
            /* La salida JSON ya se imprimió en stdout, necesitamos capturarla */
            /* Por ahora, indicar que se debe redirigir manualmente */
        }

        return resultado;
    } else {
        /* Es formato Pascal-like */
        if (!json_output_mode) {
            printf("Bridge GeCode - Validador (dry-run)\n");
            printf("====================================\n\n");
        }
        extern FILE *yyin;
        yyin = fopen(archivo_entrada, "r");
        if (!yyin) {
            fprintf(stderr, "Error: no se puede abrir '%s'\n", archivo_entrada);
            return 1;
        }
        return yyparse();
    }
}
