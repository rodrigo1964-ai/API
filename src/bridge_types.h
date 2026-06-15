/* ================================================================
 * bridge_types.h - Tipos y estructuras compartidas del proyecto
 * Proyecto: GNUBison - Bridge GeCode Validator
 * ================================================================
 *
 * PROPÓSITO:
 *   Definiciones centralizadas de tipos, estructuras de datos y constantes
 *   globales para todo el proyecto. Header compartido por parser Bison,
 *   lexer Flex, evaluador, y módulos JSON.
 *
 * COMPONENTES PRINCIPALES:
 *
 * 1. PRECISION Y ESCALADO:
 *    - precision_decimales: Número de decimales para floats (ej: 2)
 *    - factor_global: Factor de escala (10^precision, ej: 100)
 *    - Todos los floats se almacenan como int * factor_global
 *
 * 2. TIPOS DE VARIABLES (TipoVar):
 *    - T_INTEGER: Enteros (dom_min..dom_max)
 *    - T_FLOAT: Flotantes escalados (dom_min..dom_max en int)
 *    - T_LOGIC: Booleanos (dominio implícito {0,1})
 *    - T_SET: Conjuntos (dominio = lista de strings)
 *
 * 3. NODOS AST (TipoNodo):
 *    - Literales: NODO_ENTERO, NODO_BOOL, NODO_SET_LIT
 *    - Operadores aritméticos: SUMA, RESTA, MULT, DIV
 *    - Operadores comparación: EQ, NEQ, LT, GT, LEQ, GEQ
 *    - Operadores lógicos: AND, OR, NOT, IMPLICA
 *    - Funciones estándar: ABS, SQRT, SQR, SIN, COS, LN, EXP
 *    - Operadores de conjuntos: UNION, INTERSECT, DIFFERENCE, SUBSET,
 *      CARDINALITY, IN
 *
 * 4. ESTRUCTURAS:
 *    - Nodo: AST de expresiones (árbol binario + casos especiales)
 *    - VarReg: Registro de variable (nombre, tipo, dominio, valor)
 *    - FuncReg: Registro de función (nombre, parámetros, salida)
 *
 * 5. TABLAS GLOBALES:
 *    - vars[MAX_VARS]: Variables declaradas (256 max)
 *    - funcs[MAX_FUNCS]: Funciones definidas (64 max)
 *    - set_tabla[MAX_SET_ENTRIES]: Interning de strings de conjuntos (512 max)
 *
 * DECISIONES DE DISEÑO:
 *   - Arrays estáticos: Evita malloc/free en hot path (límites conocidos)
 *   - Interning de sets: set_tabla[] mapea strings → índices para comparación
 *     rápida (reg_set() retorna índice, comparación por ==)
 *   - Incertidumbre en VarReg:
 *       tiene_value=0 → sin valor (usar dominio completo)
 *       tiene_value=1 → valor fijo (val_escalar)
 *       tiene_value=2 → múltiples valores (val_vals[], val_n)
 *   - AST heterogéneo: struct Nodo tiene campos para todos los casos (izq/der
 *     para binarios, args[] para funciones, set_elementos[] para literales de
 *     conjuntos). Trade-off: memoria vs simplicidad.
 *
 * LÍMITES:
 *   MAX_VARS = 256        // Variables por archivo
 *   MAX_FUNCS = 64        // Funciones definidas
 *   MAX_SET_ENTRIES = 512 // Strings de conjuntos únicos
 *   MAX_LIST = 64         // Elementos en listas temporales
 *   MAX_EXPRS = 256       // Expresiones por archivo
 *
 * REFERENCIAS:
 *   - bridge_gecode.y: Implementa variables globales (vars[], funcs[], etc.)
 *   - expr_eval.c: Consume Nodo (evaluar_expresion)
 *   - json_reader.c: Construye VarReg desde JSON
 *
 * ================================================================ */

#ifndef BRIDGE_TYPES_H
#define BRIDGE_TYPES_H

/* ---- Precision global ---- */
extern int precision_decimales;
extern int factor_global;

/* ---- Tipos de variable ---- */
typedef enum { T_INTEGER, T_FLOAT, T_LOGIC, T_SET } TipoVar;
extern const char *tipo_str[];

/* ---- Tipos de nodo AST ---- */
typedef enum {
    NODO_IDENT, NODO_ENTERO, NODO_BOOL, NODO_SET_LIT,
    NODO_SUMA, NODO_RESTA, NODO_MULT, NODO_DIV,
    NODO_EQ, NODO_NEQ, NODO_LT, NODO_GT, NODO_LEQ, NODO_GEQ,
    NODO_AND, NODO_OR, NODO_NOT, NODO_IMPLICA,
    NODO_ABS, NODO_SQRT, NODO_SQR, NODO_SIN, NODO_COS, NODO_LN, NODO_EXP,
    NODO_FUNC_CALL, NODO_IN,
    NODO_UNION, NODO_INTERSECT, NODO_DIFFERENCE, NODO_SUBSET, NODO_CARDINALITY
} TipoNodo;

extern const char *nodo_str[];

/* Forward declaration */
typedef struct Nodo Nodo;

/* ---- Nodo del AST ---- */
struct Nodo {
    TipoNodo tipo;
    char    *nombre;
    int      valor_entero;
    int      valor_bool;
    struct Nodo *izq, *der;
    struct Nodo **args;
    int      n_args;
    char   **set_elementos;  /* Para NODO_SET_LIT: lista de strings sin comillas */
    int      set_n_elementos;
};

/* ---- Registro de variable ---- */
typedef struct {
    char   *nombre;
    TipoVar tipo;
    int     dom_min, dom_max;
    char  **dom_set_miembros;
    int     dom_n_miembros;
    char   *dom_set_nombre;
    int     tiene_value;     /* 0=nil, 1=escalar, 2=incertidumbre */
    int     val_escalar;
    int    *val_vals;
    char  **val_set_miembros;
    int     val_n;
} VarReg;

/* ---- Registro de funcion ---- */
typedef struct {
    char  *nombre;
    char **entradas;
    int    n_entradas;
    int    tiene_salida;
    char  *salida;
} FuncReg;

/* ---- Tablas globales ---- */
#define MAX_VARS 256
#define MAX_FUNCS 64
#define MAX_SET_ENTRIES 512
#define MAX_LIST 64
#define MAX_EXPRS 256

extern VarReg  vars[MAX_VARS];
extern int     n_vars;
extern FuncReg funcs[MAX_FUNCS];
extern int     n_funcs;
extern char   *set_tabla[MAX_SET_ENTRIES];
extern int     n_set_entries;
extern int     n_expresiones;
extern int     n_errores;

/* Expresiones parseadas como strings para JSON */
extern char *expresiones_str[MAX_EXPRS];

/* Modo de salida JSON */
extern int json_output_mode;
extern char *archivo_salida_json;

/* ---- Funciones utilidad ---- */
int buscar_var(const char *s);
int reg_set(const char *s);
void resumen(void);

/* ---- Funciones AST ---- */
struct Nodo* nodo_ident(const char *s);
struct Nodo* nodo_entero(int v);
struct Nodo* nodo_bool(int v);
struct Nodo* nodo_unario(TipoNodo t, struct Nodo *h);
struct Nodo* nodo_binario(TipoNodo t, struct Nodo *i, struct Nodo *d);
struct Nodo* nodo_func_std(TipoNodo t, struct Nodo *a);
struct Nodo* nodo_func_call(const char *s, struct Nodo **a, int n);
void imprimir_ast(struct Nodo *n, int nivel);
void liberar_ast(struct Nodo *n);
void validar_expr(struct Nodo *n);

#endif
