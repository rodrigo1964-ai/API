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
