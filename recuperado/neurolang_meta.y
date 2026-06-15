/*=============================================================================
 * NeuroLang Meta — GNU Bison Grammar v2.0
 * 
 * Metalenguaje para definición de arquitecturas neuronales arbitrarias.
 *
 * EXTENSIONES SOBRE v1.0:
 *   - Archetypes: plantillas parametrizables de arquitecturas
 *   - Capas con base matemática arbitraria: Fourier, polinomial, wavelet,
 *     RBF, lineal, custom
 *   - Pesos de entrenamiento por zona (train_weight)
 *   - Redes de espacio (space_net) à la Lopes MFF
 *   - Comités / Ensembles con estrategias de fusión
 *   - Búsqueda de arquitectura (NAS)
 *   - Definición de funciones de activación y base custom
 *   - Reglas de comportamiento (behavior blocks)
 *
 * Requiere GNU Bison >= 3.8 y GNU Flex >= 2.6
 *===========================================================================*/

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex(void);
extern int line_num;
extern FILE *yyin;

void yyerror(const char *s);

/* ═══════════════════════════════════════════════════════════════════════
 * AST Node Types — Extended for Meta
 * ═════════════════════════════════════════════════════════════════════*/

typedef enum {
    /* v1.0 nodes */
    NODE_NETWORK, NODE_LAYER, NODE_CONNECTION, NODE_TRAIN,
    NODE_EVALUATE, NODE_PREDICT, NODE_PIPELINE, NODE_STAGE,
    NODE_IF, NODE_REPEAT, NODE_ASSIGN, NODE_EXPR,
    NODE_PRINT, NODE_SAVE, NODE_LOAD, NODE_SUMMARY,
    NODE_CONV2D, NODE_MAXPOOL, NODE_FLATTEN, NODE_DROPOUT,
    NODE_BATCHNORM,

    /* v2.0 Meta nodes */
    NODE_ARCHETYPE,         /* plantilla de arquitectura */
    NODE_PARAMS,            /* lista de parámetros formales */
    NODE_PARAM,             /* un parámetro individual */
    NODE_BEHAVIOR,          /* bloque de comportamiento */
    NODE_RULE,              /* regla dentro de behavior */
    NODE_SPACE_NET,         /* red de espacio (MFF) */
    NODE_TRAIN_WEIGHT,      /* peso de entrenamiento por zona */
    NODE_INSTANTIATE,       /* instanciación de archetype */
    NODE_COMMITTEE,         /* comité / ensemble */
    NODE_MEMBER_LIST,       /* lista de miembros del comité */
    NODE_SEARCH,            /* búsqueda de arquitectura (NAS) */
    NODE_SEARCH_SPACE,      /* espacio de búsqueda */
    NODE_SEARCH_RANGE,      /* rango de un parámetro */
    NODE_CONSTRAINT,        /* restricción de búsqueda */

    /* Capas con base matemática */
    NODE_LINEAR_LAYER,      /* capa lineal pura (sin activación) */
    NODE_FOURIER_LAYER,     /* capa con serie de Fourier */
    NODE_POLYNOMIAL_LAYER,  /* capa con base polinomial */
    NODE_WAVELET_LAYER,     /* capa con base wavelet */
    NODE_RBF_LAYER,         /* capa con funciones de base radial */
    NODE_CUSTOM_LAYER,      /* capa definida por el usuario */

    /* Definiciones de funciones custom */
    NODE_DEFINE_ACTIVATION, /* definir función de activación */
    NODE_DEFINE_BASIS,      /* definir función de base */
    NODE_MATH_EXPR,         /* expresión matemática (sin, cos, exp, etc.) */

    /* Operaciones de composición */
    NODE_CONCAT,            /* concatenación de salidas */
    NODE_WEIGHTED_AVG,      /* promedio ponderado */
    NODE_GATE_MUL,          /* multiplicación por compuerta */
    NODE_RESIDUAL,          /* conexión residual (skip) */
    NODE_ATTENTION,         /* mecanismo de atención */

    NODE_PROGRAM            /* nodo raíz */
} NodeType;

typedef struct ASTNode {
    NodeType type;
    char *name;
    char *str_val;
    double num_val;
    int int_val;
    struct ASTNode *left;
    struct ASTNode *right;
    struct ASTNode *children;
    struct ASTNode *next;
    struct ASTNode *params;  /* para archetypes e instanciaciones */
} ASTNode;

ASTNode *make_node(NodeType type, const char *name) {
    ASTNode *n = (ASTNode *)calloc(1, sizeof(ASTNode));
    n->type = type;
    if (name) n->name = strdup(name);
    return n;
}

void append_sibling(ASTNode *list, ASTNode *node) {
    ASTNode *n = list;
    while (n->next) n = n->next;
    n->next = node;
}

/* Nombres de los tipos para debug */
const char *node_type_name(NodeType t) {
    static const char *names[] = {
        "NETWORK","LAYER","CONNECTION","TRAIN","EVALUATE","PREDICT",
        "PIPELINE","STAGE","IF","REPEAT","ASSIGN","EXPR","PRINT",
        "SAVE","LOAD","SUMMARY","CONV2D","MAXPOOL","FLATTEN",
        "DROPOUT","BATCHNORM",
        "ARCHETYPE","PARAMS","PARAM","BEHAVIOR","RULE","SPACE_NET",
        "TRAIN_WEIGHT","INSTANTIATE","COMMITTEE","MEMBER_LIST",
        "SEARCH","SEARCH_SPACE","SEARCH_RANGE","CONSTRAINT",
        "LINEAR_LAYER","FOURIER_LAYER","POLYNOMIAL_LAYER",
        "WAVELET_LAYER","RBF_LAYER","CUSTOM_LAYER",
        "DEFINE_ACTIVATION","DEFINE_BASIS","MATH_EXPR",
        "CONCAT","WEIGHTED_AVG","GATE_MUL","RESIDUAL","ATTENTION",
        "PROGRAM"
    };
    return names[t];
}

void print_ast(ASTNode *node, int depth) {
    if (!node) return;
    for (int i = 0; i < depth; i++) printf("  ");
    printf("[%s] %s", node_type_name(node->type), node->name ? node->name : "");
    if (node->str_val) printf(" str='%s'", node->str_val);
    if (node->num_val != 0.0) printf(" num=%.4f", node->num_val);
    if (node->int_val != 0) printf(" int=%d", node->int_val);
    printf("\n");
    print_ast(node->params, depth + 1);
    print_ast(node->children, depth + 1);
    print_ast(node->left, depth + 1);
    print_ast(node->right, depth + 1);
    print_ast(node->next, depth);
}

ASTNode *ast_root = NULL;

%}

/* ═══════════════════════════════════════════════════════════════════════
 * Unión de tipos semánticos
 * ═════════════════════════════════════════════════════════════════════*/
%union {
    int    ival;
    double fval;
    char  *sval;
    struct ASTNode *node;
}

/* ═══════════════════════════════════════════════════════════════════════
 * Tokens — v1.0 heredados
 * ═════════════════════════════════════════════════════════════════════*/
%token KW_NETWORK KW_LAYER KW_INPUT KW_OUTPUT KW_HIDDEN
%token KW_NEURONS KW_CONNECT KW_TO KW_WITH
%token KW_ACTIVATION
%token KW_TRAIN KW_EPOCHS KW_BATCH_SIZE KW_LEARNING_RATE
%token KW_OPTIMIZER KW_LOSS KW_DATASET KW_FROM
%token KW_VALIDATE KW_SPLIT
%token KW_EVALUATE KW_PREDICT KW_USING
%token KW_SAVE KW_LOAD KW_PRINT KW_SUMMARY
%token KW_DROPOUT KW_BATCHNORM
%token KW_CONV2D KW_MAXPOOL KW_FLATTEN
%token KW_KERNEL KW_STRIDE KW_PADDING KW_FILTERS
%token KW_IF KW_ELSE KW_REPEAT KW_TIMES
%token KW_PIPELINE KW_STAGE
%token KW_NORMALIZE KW_AUGMENT KW_SHUFFLE

/* ═══════════════════════════════════════════════════════════════════════
 * Tokens — v2.0 Meta
 * ═════════════════════════════════════════════════════════════════════*/
/* Archetypes y composición */
%token KW_ARCHETYPE KW_PARAMS KW_BEHAVIOR KW_RULE
%token KW_SPACE_NET KW_TRAIN_WEIGHT
%token KW_COMMITTEE KW_MEMBERS KW_STRATEGY
%token KW_INSTANTIATE KW_AS

/* Capas con base matemática */
%token KW_LINEAR KW_FOURIER KW_POLYNOMIAL KW_WAVELET KW_RBF KW_CUSTOM
%token KW_ORDER KW_HARMONICS KW_SIGMA KW_CENTERS KW_BASIS
%token KW_SERIES KW_DEGREE KW_TERMS

/* Funciones matemáticas para definiciones custom */
%token KW_DEFINE KW_FUNCTION
%token KW_SIN KW_COS KW_EXP KW_LOG KW_TANH_F KW_SQRT KW_ABS KW_POW
%token KW_SUM KW_PRODUCT KW_PI KW_E_CONST
%token KW_N_VAR KW_K_VAR KW_X_VAR  /* variables de iteración/entrada */

/* Composición avanzada */
%token KW_CONCAT KW_WEIGHTED_AVG KW_GATE KW_RESIDUAL KW_ATTENTION
%token KW_GRADIENT_SCALE KW_FREEZE KW_UNFREEZE

/* Búsqueda de arquitectura */
%token KW_SEARCH KW_SPACE KW_OBJECTIVE KW_MAXIMIZE KW_MINIMIZE
%token KW_CONSTRAINT KW_METHOD KW_BUDGET KW_TRIALS
%token KW_IN KW_RANGE KW_TOTAL_PARAMS KW_AUTO

/* Operadores y símbolos (heredados) */
%token ARROW FAT_ARROW
%token EQ NEQ GEQ LEQ GT LT
%token ASSIGN PLUS MINUS STAR SLASH
%token LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET
%token COMMA COLON SEMICOLON PIPE AT DOT
%token DOTDOT  /* .. para rangos */

/* Literales */
%token <ival> INT_LIT
%token <fval> FLOAT_LIT
%token <sval> STRING_LIT IDENTIFIER
%token <sval> ACTIVATION_FUNC OPTIMIZER_NAME LOSS_FUNC

/* ═══════════════════════════════════════════════════════════════════════
 * Tipos de no-terminales
 * ═════════════════════════════════════════════════════════════════════*/
%type <node> program top_level_list top_level_stmt
%type <node> network_def layer_list layer_def layer_body
%type <node> connection_def connection_chain
%type <node> train_def train_body train_props train_prop
%type <node> evaluate_stmt predict_stmt
%type <node> pipeline_def stage_list stage_def stage_body stage_ops stage_op
%type <node> if_stmt repeat_stmt
%type <node> assign_stmt print_stmt save_stmt load_stmt summary_stmt
%type <node> special_layer_list special_layer
%type <node> dim_list dim_list_inner

/* Meta types */
%type <node> archetype_def archetype_body archetype_member_list archetype_member
%type <node> formal_params formal_param_list formal_param
%type <node> behavior_block behavior_stmts behavior_stmt
%type <node> space_net_def train_weight_def
%type <node> instantiation_stmt actual_params actual_param_list
%type <node> committee_def committee_body committee_members
%type <node> search_def search_body search_stmts search_stmt search_range_list

/* Mathematical layer types */
%type <node> linear_layer fourier_layer polynomial_layer wavelet_layer rbf_layer custom_basis_layer
%type <node> math_layer_body

/* Custom function definitions */
%type <node> define_activation_stmt define_basis_stmt
%type <node> math_expr math_term math_factor math_atom
%type <node> math_func_call sum_expr

/* Composition */
%type <node> composition_expr

/* Expressions (extended) */
%type <node> expr comparison_expr additive_expr multiplicative_expr unary_expr primary_expr
%type <node> member_access

/* Precedencia */
%left PLUS MINUS
%left STAR SLASH
%right UMINUS
%left DOT

%start program

%%

/*══════════════════════════════════════════════════════════════════════
 * PROGRAMA PRINCIPAL
 *════════════════════════════════════════════════════════════════════*/

program
    : top_level_list    { ast_root = $1; }
    ;

top_level_list
    : top_level_stmt                        { $$ = $1; }
    | top_level_list top_level_stmt         {
        append_sibling($1, $2);
        $$ = $1;
    }
    ;

top_level_stmt
    : network_def           { $$ = $1; }
    | archetype_def         { $$ = $1; }
    | instantiation_stmt    { $$ = $1; }
    | committee_def         { $$ = $1; }
    | search_def            { $$ = $1; }
    | define_activation_stmt { $$ = $1; }
    | define_basis_stmt     { $$ = $1; }
    | train_def             { $$ = $1; }
    | evaluate_stmt         { $$ = $1; }
    | predict_stmt          { $$ = $1; }
    | pipeline_def          { $$ = $1; }
    | if_stmt               { $$ = $1; }
    | repeat_stmt           { $$ = $1; }
    | assign_stmt           { $$ = $1; }
    | print_stmt            { $$ = $1; }
    | save_stmt             { $$ = $1; }
    | load_stmt             { $$ = $1; }
    | summary_stmt          { $$ = $1; }
    | connection_def        { $$ = $1; }
    ;

/*══════════════════════════════════════════════════════════════════════
 * DEFINICIÓN DE FUNCIONES CUSTOM
 *
 * Ejemplo:
 *   define activation gaussian(x) = exp(-(x * x) / 2.0);
 *
 *   define basis fourier_term(x, k) = sin(2 * PI * k * x) + cos(2 * PI * k * x);
 *
 *   define activation mexican_hat(x) = (1 - x*x) * exp(-(x*x) / 2.0);
 *════════════════════════════════════════════════════════════════════*/

define_activation_stmt
    : KW_DEFINE KW_ACTIVATION IDENTIFIER LPAREN IDENTIFIER RPAREN ASSIGN math_expr SEMICOLON {
        ASTNode *n = make_node(NODE_DEFINE_ACTIVATION, $3);
        n->str_val = $5;   /* nombre del parámetro (x) */
        n->left = $8;      /* expresión matemática */
        $$ = n;
        free($3); free($5);
    }
    ;

define_basis_stmt
    : KW_DEFINE KW_BASIS IDENTIFIER LPAREN IDENTIFIER COMMA IDENTIFIER RPAREN ASSIGN math_expr SEMICOLON {
        ASTNode *n = make_node(NODE_DEFINE_BASIS, $3);
        n->str_val = $5;   /* primer parámetro (x) */
        ASTNode *p2 = make_node(NODE_PARAM, $7);
        n->params = p2;    /* segundo parámetro (k, n, etc.) */
        n->left = $10;     /* expresión */
        $$ = n;
        free($3); free($5); free($7);
    }
    ;

/* ── Expresiones matemáticas para definiciones ── */

math_expr
    : math_expr PLUS math_term {
        ASTNode *n = make_node(NODE_MATH_EXPR, "+");
        n->left = $1; n->right = $3;
        $$ = n;
    }
    | math_expr MINUS math_term {
        ASTNode *n = make_node(NODE_MATH_EXPR, "-");
        n->left = $1; n->right = $3;
        $$ = n;
    }
    | math_term { $$ = $1; }
    ;

math_term
    : math_term STAR math_factor {
        ASTNode *n = make_node(NODE_MATH_EXPR, "*");
        n->left = $1; n->right = $3;
        $$ = n;
    }
    | math_term SLASH math_factor {
        ASTNode *n = make_node(NODE_MATH_EXPR, "/");
        n->left = $1; n->right = $3;
        $$ = n;
    }
    | math_factor { $$ = $1; }
    ;

math_factor
    : MINUS math_factor %prec UMINUS {
        ASTNode *n = make_node(NODE_MATH_EXPR, "neg");
        n->left = $2;
        $$ = n;
    }
    | math_atom     { $$ = $1; }
    | math_func_call { $$ = $1; }
    | sum_expr      { $$ = $1; }
    ;

math_atom
    : INT_LIT {
        ASTNode *n = make_node(NODE_MATH_EXPR, "int");
        n->int_val = $1;
        $$ = n;
    }
    | FLOAT_LIT {
        ASTNode *n = make_node(NODE_MATH_EXPR, "float");
        n->num_val = $1;
        $$ = n;
    }
    | IDENTIFIER {
        ASTNode *n = make_node(NODE_MATH_EXPR, $1);
        $$ = n;
        free($1);
    }
    | KW_PI {
        $$ = make_node(NODE_MATH_EXPR, "PI");
    }
    | KW_E_CONST {
        $$ = make_node(NODE_MATH_EXPR, "E");
    }
    | KW_X_VAR {
        $$ = make_node(NODE_MATH_EXPR, "x");
    }
    | KW_K_VAR {
        $$ = make_node(NODE_MATH_EXPR, "k");
    }
    | KW_N_VAR {
        $$ = make_node(NODE_MATH_EXPR, "n");
    }
    | LPAREN math_expr RPAREN {
        $$ = $2;
    }
    ;

math_func_call
    : KW_SIN LPAREN math_expr RPAREN {
        ASTNode *n = make_node(NODE_MATH_EXPR, "sin");
        n->left = $3;
        $$ = n;
    }
    | KW_COS LPAREN math_expr RPAREN {
        ASTNode *n = make_node(NODE_MATH_EXPR, "cos");
        n->left = $3;
        $$ = n;
    }
    | KW_EXP LPAREN math_expr RPAREN {
        ASTNode *n = make_node(NODE_MATH_EXPR, "exp");
        n->left = $3;
        $$ = n;
    }
    | KW_LOG LPAREN math_expr RPAREN {
        ASTNode *n = make_node(NODE_MATH_EXPR, "log");
        n->left = $3;
        $$ = n;
    }
    | KW_TANH_F LPAREN math_expr RPAREN {
        ASTNode *n = make_node(NODE_MATH_EXPR, "tanh");
        n->left = $3;
        $$ = n;
    }
    | KW_SQRT LPAREN math_expr RPAREN {
        ASTNode *n = make_node(NODE_MATH_EXPR, "sqrt");
        n->left = $3;
        $$ = n;
    }
    | KW_ABS LPAREN math_expr RPAREN {
        ASTNode *n = make_node(NODE_MATH_EXPR, "abs");
        n->left = $3;
        $$ = n;
    }
    | KW_POW LPAREN math_expr COMMA math_expr RPAREN {
        ASTNode *n = make_node(NODE_MATH_EXPR, "pow");
        n->left = $3;
        n->right = $5;
        $$ = n;
    }
    ;

/* Sumatorias: sum(k, 1, N, expr) */
sum_expr
    : KW_SUM LPAREN IDENTIFIER COMMA math_expr COMMA math_expr COMMA math_expr RPAREN {
        ASTNode *n = make_node(NODE_MATH_EXPR, "sum");
        n->str_val = $3;   /* variable de iteración */
        n->left = $5;      /* inicio */
        n->right = $7;     /* fin */
        n->children = $9;  /* cuerpo */
        $$ = n;
        free($3);
    }
    ;

/*══════════════════════════════════════════════════════════════════════
 * CAPAS CON BASE MATEMÁTICA
 *
 * Ejemplo:
 *   layer transformada : fourier neurons 128 harmonics 32;
 *   layer aprox       : polynomial neurons 64 degree 5;
 *   layer local       : rbf neurons 100 centers 50 sigma 0.5;
 *   layer ondita      : wavelet neurons 64 basis "morlet" order 4;
 *   layer pura        : linear neurons 256;
 *   layer especial    : custom neurons 128 basis mi_base_custom terms 10;
 *════════════════════════════════════════════════════════════════════*/

linear_layer
    : KW_LINEAR KW_NEURONS INT_LIT {
        ASTNode *n = make_node(NODE_LINEAR_LAYER, NULL);
        n->int_val = $3;
        $$ = n;
    }
    ;

fourier_layer
    : KW_FOURIER KW_NEURONS INT_LIT KW_HARMONICS INT_LIT {
        ASTNode *n = make_node(NODE_FOURIER_LAYER, NULL);
        n->int_val = $3;
        ASTNode *h = make_node(NODE_EXPR, "harmonics");
        h->int_val = $5;
        n->children = h;
        $$ = n;
    }
    | KW_FOURIER KW_NEURONS INT_LIT KW_HARMONICS INT_LIT KW_SERIES IDENTIFIER {
        /* Serie de Fourier con tipo específico (sin, cos, full) */
        ASTNode *n = make_node(NODE_FOURIER_LAYER, NULL);
        n->int_val = $3;
        n->str_val = $7;  /* tipo de serie */
        ASTNode *h = make_node(NODE_EXPR, "harmonics");
        h->int_val = $5;
        n->children = h;
        $$ = n;
        free($7);
    }
    ;

polynomial_layer
    : KW_POLYNOMIAL KW_NEURONS INT_LIT KW_DEGREE INT_LIT {
        ASTNode *n = make_node(NODE_POLYNOMIAL_LAYER, NULL);
        n->int_val = $3;
        ASTNode *d = make_node(NODE_EXPR, "degree");
        d->int_val = $5;
        n->children = d;
        $$ = n;
    }
    ;

wavelet_layer
    : KW_WAVELET KW_NEURONS INT_LIT KW_BASIS STRING_LIT KW_ORDER INT_LIT {
        ASTNode *n = make_node(NODE_WAVELET_LAYER, NULL);
        n->int_val = $3;
        n->str_val = $5;  /* tipo: "morlet", "haar", "daubechies", etc. */
        ASTNode *o = make_node(NODE_EXPR, "order");
        o->int_val = $7;
        n->children = o;
        $$ = n;
    }
    | KW_WAVELET KW_NEURONS INT_LIT KW_BASIS IDENTIFIER KW_ORDER INT_LIT {
        ASTNode *n = make_node(NODE_WAVELET_LAYER, NULL);
        n->int_val = $3;
        n->str_val = $5;
        ASTNode *o = make_node(NODE_EXPR, "order");
        o->int_val = $7;
        n->children = o;
        $$ = n;
        free($5);
    }
    ;

rbf_layer
    : KW_RBF KW_NEURONS INT_LIT KW_CENTERS INT_LIT KW_SIGMA expr {
        ASTNode *n = make_node(NODE_RBF_LAYER, NULL);
        n->int_val = $3;
        ASTNode *c = make_node(NODE_EXPR, "centers");
        c->int_val = $5;
        n->children = c;
        n->left = $7;  /* sigma como expresión */
        $$ = n;
    }
    ;

custom_basis_layer
    : KW_CUSTOM KW_NEURONS INT_LIT KW_BASIS IDENTIFIER KW_TERMS INT_LIT {
        ASTNode *n = make_node(NODE_CUSTOM_LAYER, NULL);
        n->int_val = $3;
        n->str_val = $5;  /* nombre de la basis function definida con 'define basis' */
        ASTNode *t = make_node(NODE_EXPR, "terms");
        t->int_val = $7;
        n->children = t;
        $$ = n;
        free($5);
    }
    ;

/* Agrupación de todas las capas matemáticas */
math_layer_body
    : linear_layer      { $$ = $1; }
    | fourier_layer     { $$ = $1; }
    | polynomial_layer  { $$ = $1; }
    | wavelet_layer     { $$ = $1; }
    | rbf_layer         { $$ = $1; }
    | custom_basis_layer { $$ = $1; }
    ;

/*══════════════════════════════════════════════════════════════════════
 * DEFINICIÓN DE RED — EXTENDIDA
 *
 * Ahora soporta capas matemáticas, space_net y train_weight
 *════════════════════════════════════════════════════════════════════*/

network_def
    : KW_NETWORK IDENTIFIER LBRACE layer_list RBRACE {
        ASTNode *n = make_node(NODE_NETWORK, $2);
        n->children = $4;
        $$ = n;
        free($2);
    }
    ;

layer_list
    : layer_def                     { $$ = $1; }
    | layer_list layer_def          { append_sibling($1, $2); $$ = $1; }
    | layer_list connection_def     { append_sibling($1, $2); $$ = $1; }
    | layer_list space_net_def      { append_sibling($1, $2); $$ = $1; }
    | layer_list train_weight_def   { append_sibling($1, $2); $$ = $1; }
    ;

layer_def
    : KW_LAYER IDENTIFIER COLON layer_body SEMICOLON {
        $4->name = strdup($2);
        $$ = $4;
        free($2);
    }
    | KW_LAYER IDENTIFIER COLON layer_body LBRACE special_layer_list RBRACE {
        $4->name = strdup($2);
        if ($4->children) {
            ASTNode *c = $4->children;
            while (c->next) c = c->next;
            c->next = $6;
        } else {
            $4->children = $6;
        }
        $$ = $4;
        free($2);
    }
    ;

layer_body
    /* Capas estándar v1.0 */
    : KW_INPUT KW_NEURONS INT_LIT {
        ASTNode *n = make_node(NODE_LAYER, NULL);
        n->str_val = strdup("input");
        n->int_val = $3;
        $$ = n;
    }
    | KW_INPUT KW_NEURONS INT_LIT dim_list {
        ASTNode *n = make_node(NODE_LAYER, NULL);
        n->str_val = strdup("input");
        n->int_val = $3;
        n->children = $4;
        $$ = n;
    }
    | KW_HIDDEN KW_NEURONS INT_LIT KW_ACTIVATION ACTIVATION_FUNC {
        ASTNode *n = make_node(NODE_LAYER, NULL);
        n->str_val = strdup("hidden");
        n->int_val = $3;
        n->left = make_node(NODE_EXPR, $5);
        $$ = n;
        free($5);
    }
    | KW_HIDDEN KW_NEURONS INT_LIT KW_ACTIVATION IDENTIFIER {
        /* Permite activaciones custom definidas con 'define activation' */
        ASTNode *n = make_node(NODE_LAYER, NULL);
        n->str_val = strdup("hidden");
        n->int_val = $3;
        n->left = make_node(NODE_EXPR, $5);
        $$ = n;
        free($5);
    }
    | KW_OUTPUT KW_NEURONS INT_LIT KW_ACTIVATION ACTIVATION_FUNC {
        ASTNode *n = make_node(NODE_LAYER, NULL);
        n->str_val = strdup("output");
        n->int_val = $3;
        n->left = make_node(NODE_EXPR, $5);
        $$ = n;
        free($5);
    }
    | KW_OUTPUT KW_NEURONS INT_LIT KW_ACTIVATION IDENTIFIER {
        ASTNode *n = make_node(NODE_LAYER, NULL);
        n->str_val = strdup("output");
        n->int_val = $3;
        n->left = make_node(NODE_EXPR, $5);
        $$ = n;
        free($5);
    }
    /* Capas convolucionales heredadas */
    | KW_CONV2D KW_FILTERS INT_LIT KW_KERNEL dim_list KW_ACTIVATION ACTIVATION_FUNC {
        ASTNode *n = make_node(NODE_CONV2D, NULL);
        n->int_val = $3;
        n->children = $5;
        n->left = make_node(NODE_EXPR, $7);
        $$ = n;
        free($7);
    }
    | KW_MAXPOOL KW_KERNEL dim_list {
        ASTNode *n = make_node(NODE_MAXPOOL, NULL);
        n->children = $3;
        $$ = n;
    }
    | KW_FLATTEN {
        $$ = make_node(NODE_FLATTEN, NULL);
    }
    /* ── NUEVAS: capas matemáticas ── */
    | math_layer_body { $$ = $1; }
    ;

/* Capas especiales dentro de { } */
special_layer_list
    : special_layer                         { $$ = $1; }
    | special_layer_list special_layer      { append_sibling($1, $2); $$ = $1; }
    ;

special_layer
    : KW_DROPOUT FLOAT_LIT SEMICOLON {
        ASTNode *n = make_node(NODE_DROPOUT, NULL);
        n->num_val = $2;
        $$ = n;
    }
    | KW_DROPOUT expr SEMICOLON {
        ASTNode *n = make_node(NODE_DROPOUT, NULL);
        n->left = $2;
        $$ = n;
    }
    | KW_BATCHNORM SEMICOLON {
        $$ = make_node(NODE_BATCHNORM, NULL);
    }
    ;

/*══════════════════════════════════════════════════════════════════════
 * RED DE ESPACIO (MFF à la Lopes) Y PESOS DE ENTRENAMIENTO
 *
 * Ejemplo:
 *   space_net gate_h1 for oculta1 : hidden neurons 128 activation sigmoid;
 *   train_weight oculta1 = 0.5;
 *   freeze oculta2;
 *════════════════════════════════════════════════════════════════════*/

space_net_def
    : KW_SPACE_NET IDENTIFIER KW_TO IDENTIFIER COLON layer_body SEMICOLON {
        ASTNode *n = make_node(NODE_SPACE_NET, $2);
        n->str_val = strdup($4);  /* capa destino */
        n->children = $6;         /* definición de la red de espacio */
        $$ = n;
        free($2); free($4);
    }
    ;

train_weight_def
    : KW_TRAIN_WEIGHT IDENTIFIER ASSIGN expr SEMICOLON {
        ASTNode *n = make_node(NODE_TRAIN_WEIGHT, $2);
        n->left = $4;
        $$ = n;
        free($2);
    }
    | KW_FREEZE IDENTIFIER SEMICOLON {
        ASTNode *n = make_node(NODE_TRAIN_WEIGHT, $2);
        n->num_val = 0.0;
        $$ = n;
        free($2);
    }
    | KW_UNFREEZE IDENTIFIER SEMICOLON {
        ASTNode *n = make_node(NODE_TRAIN_WEIGHT, $2);
        n->num_val = 1.0;
        $$ = n;
        free($2);
    }
    ;

/*══════════════════════════════════════════════════════════════════════
 * ARCHETYPES — Meta-definición de arquitecturas
 *
 * Ejemplo:
 *   archetype FourierZone(n_neurons, n_harmonics, tw) {
 *       layer core : fourier neurons n_neurons harmonics n_harmonics;
 *       space_net gate to core : hidden neurons n_neurons activation sigmoid;
 *       train_weight core = tw;
 *
 *       behavior {
 *           output = core.output * gate.output;
 *           gradient_scale = tw * gate.output;
 *       }
 *   }
 *════════════════════════════════════════════════════════════════════*/

archetype_def
    : KW_ARCHETYPE IDENTIFIER formal_params LBRACE archetype_body RBRACE {
        ASTNode *n = make_node(NODE_ARCHETYPE, $2);
        n->params = $3;
        n->children = $5;
        $$ = n;
        free($2);
    }
    ;

formal_params
    : LPAREN formal_param_list RPAREN   { $$ = $2; }
    ;

formal_param_list
    : formal_param                              { $$ = $1; }
    | formal_param_list COMMA formal_param      { append_sibling($1, $3); $$ = $1; }
    ;

formal_param
    : IDENTIFIER {
        $$ = make_node(NODE_PARAM, $1);
        free($1);
    }
    | IDENTIFIER LBRACKET RBRACKET {
        /* Parámetro tipo lista: members[] */
        ASTNode *n = make_node(NODE_PARAM, $1);
        n->str_val = strdup("list");
        $$ = n;
        free($1);
    }
    ;

archetype_body
    : archetype_member_list     { $$ = $1; }
    ;

archetype_member_list
    : archetype_member                              { $$ = $1; }
    | archetype_member_list archetype_member         { append_sibling($1, $2); $$ = $1; }
    ;

archetype_member
    : layer_def             { $$ = $1; }
    | connection_def        { $$ = $1; }
    | space_net_def         { $$ = $1; }
    | train_weight_def      { $$ = $1; }
    | behavior_block        { $$ = $1; }
    | assign_stmt           { $$ = $1; }
    ;

/* ── Bloque de comportamiento ── */
behavior_block
    : KW_BEHAVIOR LBRACE behavior_stmts RBRACE {
        ASTNode *n = make_node(NODE_BEHAVIOR, NULL);
        n->children = $3;
        $$ = n;
    }
    ;

behavior_stmts
    : behavior_stmt                         { $$ = $1; }
    | behavior_stmts behavior_stmt          { append_sibling($1, $2); $$ = $1; }
    ;

behavior_stmt
    : IDENTIFIER ASSIGN composition_expr SEMICOLON {
        ASTNode *n = make_node(NODE_RULE, $1);
        n->left = $3;
        $$ = n;
        free($1);
    }
    | KW_GRADIENT_SCALE ASSIGN composition_expr SEMICOLON {
        ASTNode *n = make_node(NODE_RULE, "gradient_scale");
        n->left = $3;
        $$ = n;
    }
    ;

/* ── Expresiones de composición ── */
composition_expr
    : composition_expr STAR composition_expr {
        ASTNode *n = make_node(NODE_GATE_MUL, "*");
        n->left = $1; n->right = $3;
        $$ = n;
    }
    | composition_expr PLUS composition_expr {
        ASTNode *n = make_node(NODE_RESIDUAL, "+");
        n->left = $1; n->right = $3;
        $$ = n;
    }
    | KW_CONCAT LPAREN actual_param_list RPAREN {
        ASTNode *n = make_node(NODE_CONCAT, NULL);
        n->children = $3;
        $$ = n;
    }
    | KW_WEIGHTED_AVG LPAREN actual_param_list RPAREN {
        ASTNode *n = make_node(NODE_WEIGHTED_AVG, NULL);
        n->children = $3;
        $$ = n;
    }
    | KW_ATTENTION LPAREN actual_param_list RPAREN {
        ASTNode *n = make_node(NODE_ATTENTION, NULL);
        n->children = $3;
        $$ = n;
    }
    | member_access { $$ = $1; }
    | primary_expr { $$ = $1; }
    ;

member_access
    : IDENTIFIER DOT IDENTIFIER {
        ASTNode *n = make_node(NODE_EXPR, "member_access");
        n->str_val = strdup($1);
        n->left = make_node(NODE_EXPR, $3);
        $$ = n;
        free($1); free($3);
    }
    ;

/*══════════════════════════════════════════════════════════════════════
 * INSTANCIACIÓN DE ARCHETYPES
 *
 * Ejemplo:
 *   zona_espectral = FourierZone(128, 32, 1.0);
 *   zona_frozen    = FourierZone(64, 16, 0.0);
 *   load zona_frozen from "pretrained.bin";
 *════════════════════════════════════════════════════════════════════*/

instantiation_stmt
    : IDENTIFIER ASSIGN IDENTIFIER LPAREN actual_param_list RPAREN SEMICOLON {
        ASTNode *n = make_node(NODE_INSTANTIATE, $1);
        n->str_val = strdup($3);  /* nombre del archetype */
        n->children = $5;         /* parámetros actuales */
        $$ = n;
        free($1); free($3);
    }
    ;

actual_params
    : LPAREN actual_param_list RPAREN   { $$ = $2; }
    ;

actual_param_list
    : expr                              { $$ = $1; }
    | actual_param_list COMMA expr      { append_sibling($1, $3); $$ = $1; }
    ;

/*══════════════════════════════════════════════════════════════════════
 * COMITÉ / ENSEMBLE
 *
 * Ejemplo:
 *   committee Diagnostico {
 *       members zona_espectral, zona_polinomial, zona_rbf, red_clinica;
 *       strategy concatenate;
 *       
 *       layer arbiter : hidden neurons 128 activation relu;
 *       layer salida  : output neurons 5 activation softmax;
 *       arbiter -> salida;
 *   }
 *════════════════════════════════════════════════════════════════════*/

committee_def
    : KW_COMMITTEE IDENTIFIER LBRACE committee_body RBRACE {
        ASTNode *n = make_node(NODE_COMMITTEE, $2);
        n->children = $4;
        $$ = n;
        free($2);
    }
    ;

committee_body
    : committee_members                     { $$ = $1; }
    | committee_body layer_def              { append_sibling($1, $2); $$ = $1; }
    | committee_body connection_def         { append_sibling($1, $2); $$ = $1; }
    | committee_body train_weight_def       { append_sibling($1, $2); $$ = $1; }
    ;

committee_members
    : KW_MEMBERS actual_param_list SEMICOLON KW_STRATEGY IDENTIFIER SEMICOLON {
        ASTNode *n = make_node(NODE_MEMBER_LIST, $5);
        n->children = $2;
        $$ = n;
        free($5);
    }
    ;

/*══════════════════════════════════════════════════════════════════════
 * BÚSQUEDA DE ARQUITECTURA (NAS)
 *
 * Ejemplo:
 *   search BuscarMejor {
 *       space {
 *           n_harmonics in [8, 16, 32, 64];
 *           degree in range(2, 10);
 *           sigma in [0.1, 0.5, 1.0, 2.0];
 *       }
 *       objective maximize accuracy;
 *       constraint total_params < 1000000;
 *       method bayesian_optimization;
 *       budget 200 trials;
 *   }
 *════════════════════════════════════════════════════════════════════*/

search_def
    : KW_SEARCH IDENTIFIER LBRACE search_body RBRACE {
        ASTNode *n = make_node(NODE_SEARCH, $2);
        n->children = $4;
        $$ = n;
        free($2);
    }
    ;

search_body
    : search_stmts  { $$ = $1; }
    ;

search_stmts
    : search_stmt                   { $$ = $1; }
    | search_stmts search_stmt     { append_sibling($1, $2); $$ = $1; }
    ;

search_stmt
    : KW_SPACE LBRACE search_range_list RBRACE {
        ASTNode *n = make_node(NODE_SEARCH_SPACE, NULL);
        n->children = $3;
        $$ = n;
    }
    | KW_OBJECTIVE KW_MAXIMIZE IDENTIFIER SEMICOLON {
        ASTNode *n = make_node(NODE_EXPR, "objective");
        n->str_val = strdup("maximize");
        n->left = make_node(NODE_EXPR, $3);
        $$ = n;
        free($3);
    }
    | KW_OBJECTIVE KW_MINIMIZE IDENTIFIER SEMICOLON {
        ASTNode *n = make_node(NODE_EXPR, "objective");
        n->str_val = strdup("minimize");
        n->left = make_node(NODE_EXPR, $3);
        $$ = n;
        free($3);
    }
    | KW_CONSTRAINT expr LT expr SEMICOLON {
        ASTNode *n = make_node(NODE_CONSTRAINT, "<");
        n->left = $2; n->right = $4;
        $$ = n;
    }
    | KW_CONSTRAINT expr GT expr SEMICOLON {
        ASTNode *n = make_node(NODE_CONSTRAINT, ">");
        n->left = $2; n->right = $4;
        $$ = n;
    }
    | KW_METHOD IDENTIFIER SEMICOLON {
        ASTNode *n = make_node(NODE_EXPR, "method");
        n->str_val = strdup($2);
        $$ = n;
        free($2);
    }
    | KW_BUDGET INT_LIT KW_TRIALS SEMICOLON {
        ASTNode *n = make_node(NODE_EXPR, "budget");
        n->int_val = $2;
        $$ = n;
    }
    ;

search_range_list
    : IDENTIFIER KW_IN dim_list SEMICOLON {
        ASTNode *n = make_node(NODE_SEARCH_RANGE, $1);
        n->children = $3;
        $$ = n;
        free($1);
    }
    | IDENTIFIER KW_IN KW_RANGE LPAREN expr COMMA expr RPAREN SEMICOLON {
        ASTNode *n = make_node(NODE_SEARCH_RANGE, $1);
        n->left = $5;
        n->right = $7;
        $$ = n;
        free($1);
    }
    | search_range_list IDENTIFIER KW_IN dim_list SEMICOLON {
        ASTNode *n = make_node(NODE_SEARCH_RANGE, $2);
        n->children = $4;
        append_sibling($1, n);
        $$ = $1;
        free($2);
    }
    | search_range_list IDENTIFIER KW_IN KW_RANGE LPAREN expr COMMA expr RPAREN SEMICOLON {
        ASTNode *n = make_node(NODE_SEARCH_RANGE, $2);
        n->left = $6;
        n->right = $8;
        append_sibling($1, n);
        $$ = $1;
        free($2);
    }
    ;

/*══════════════════════════════════════════════════════════════════════
 * CONEXIONES — Extendidas con cadenas más largas
 *════════════════════════════════════════════════════════════════════*/

connection_def
    : connection_chain SEMICOLON    { $$ = $1; }
    | KW_CONNECT IDENTIFIER KW_TO IDENTIFIER SEMICOLON {
        ASTNode *n = make_node(NODE_CONNECTION, NULL);
        n->left = make_node(NODE_EXPR, $2);
        n->right = make_node(NODE_EXPR, $4);
        $$ = n;
        free($2); free($4);
    }
    ;

connection_chain
    : IDENTIFIER ARROW IDENTIFIER {
        ASTNode *n = make_node(NODE_CONNECTION, NULL);
        n->left = make_node(NODE_EXPR, $1);
        n->right = make_node(NODE_EXPR, $3);
        $$ = n;
        free($1); free($3);
    }
    | connection_chain ARROW IDENTIFIER {
        /* Encadenar: la última conexión se extiende */
        ASTNode *last = $1;
        while (last->next) last = last->next;
        ASTNode *n = make_node(NODE_CONNECTION, NULL);
        n->left = make_node(NODE_EXPR, last->right->name);
        n->right = make_node(NODE_EXPR, $3);
        append_sibling($1, n);
        $$ = $1;
        free($3);
    }
    ;

/*══════════════════════════════════════════════════════════════════════
 * ENTRENAMIENTO — Extendido con train_weight y freeze
 *════════════════════════════════════════════════════════════════════*/

train_def
    : KW_TRAIN IDENTIFIER LBRACE train_body RBRACE {
        ASTNode *n = make_node(NODE_TRAIN, $2);
        n->children = $4;
        $$ = n;
        free($2);
    }
    ;

train_body
    : train_props   { $$ = $1; }
    ;

train_props
    : train_prop                    { $$ = $1; }
    | train_props train_prop        { append_sibling($1, $2); $$ = $1; }
    ;

train_prop
    : KW_DATASET KW_FROM STRING_LIT SEMICOLON {
        ASTNode *n = make_node(NODE_EXPR, "dataset");
        n->str_val = $3;
        $$ = n;
    }
    | KW_EPOCHS expr SEMICOLON {
        ASTNode *n = make_node(NODE_EXPR, "epochs");
        n->left = $2;
        $$ = n;
    }
    | KW_BATCH_SIZE expr SEMICOLON {
        ASTNode *n = make_node(NODE_EXPR, "batch_size");
        n->left = $2;
        $$ = n;
    }
    | KW_LEARNING_RATE expr SEMICOLON {
        ASTNode *n = make_node(NODE_EXPR, "learning_rate");
        n->left = $2;
        $$ = n;
    }
    | KW_OPTIMIZER OPTIMIZER_NAME SEMICOLON {
        ASTNode *n = make_node(NODE_EXPR, "optimizer");
        n->str_val = $2;
        $$ = n;
    }
    | KW_LOSS LOSS_FUNC SEMICOLON {
        ASTNode *n = make_node(NODE_EXPR, "loss");
        n->str_val = $2;
        $$ = n;
    }
    | KW_VALIDATE KW_SPLIT expr SEMICOLON {
        ASTNode *n = make_node(NODE_EXPR, "validate_split");
        n->left = $3;
        $$ = n;
    }
    | KW_TRAIN_WEIGHT IDENTIFIER ASSIGN expr SEMICOLON {
        ASTNode *n = make_node(NODE_TRAIN_WEIGHT, $2);
        n->left = $4;
        $$ = n;
        free($2);
    }
    | KW_FREEZE IDENTIFIER SEMICOLON {
        ASTNode *n = make_node(NODE_TRAIN_WEIGHT, $2);
        n->num_val = 0.0;
        $$ = n;
        free($2);
    }
    ;

/*══════════════════════════════════════════════════════════════════════
 * SENTENCIAS HEREDADAS (evaluate, predict, pipeline, if, etc.)
 *════════════════════════════════════════════════════════════════════*/

evaluate_stmt
    : KW_EVALUATE IDENTIFIER KW_USING STRING_LIT SEMICOLON {
        ASTNode *n = make_node(NODE_EVALUATE, $2);
        n->str_val = $4;
        $$ = n;
        free($2);
    }
    ;

predict_stmt
    : KW_PREDICT IDENTIFIER KW_USING dim_list SEMICOLON {
        ASTNode *n = make_node(NODE_PREDICT, $2);
        n->children = $4;
        $$ = n;
        free($2);
    }
    | KW_PREDICT IDENTIFIER KW_USING STRING_LIT SEMICOLON {
        ASTNode *n = make_node(NODE_PREDICT, $2);
        n->str_val = $4;
        $$ = n;
        free($2);
    }
    ;

pipeline_def
    : KW_PIPELINE IDENTIFIER LBRACE stage_list RBRACE {
        ASTNode *n = make_node(NODE_PIPELINE, $2);
        n->children = $4;
        $$ = n;
        free($2);
    }
    ;

stage_list
    : stage_def                 { $$ = $1; }
    | stage_list stage_def      { append_sibling($1, $2); $$ = $1; }
    ;

stage_def
    : KW_STAGE IDENTIFIER LBRACE stage_body RBRACE {
        ASTNode *n = make_node(NODE_STAGE, $2);
        n->children = $4;
        $$ = n;
        free($2);
    }
    ;

stage_body : stage_ops { $$ = $1; } ;

stage_ops
    : stage_op                  { $$ = $1; }
    | stage_ops stage_op        { append_sibling($1, $2); $$ = $1; }
    ;

stage_op
    : KW_NORMALIZE SEMICOLON    { $$ = make_node(NODE_EXPR, "normalize"); }
    | KW_AUGMENT SEMICOLON      { $$ = make_node(NODE_EXPR, "augment"); }
    | KW_SHUFFLE SEMICOLON      { $$ = make_node(NODE_EXPR, "shuffle"); }
    | KW_DATASET KW_FROM STRING_LIT SEMICOLON {
        ASTNode *n = make_node(NODE_EXPR, "dataset");
        n->str_val = $3;
        $$ = n;
    }
    ;

if_stmt
    : KW_IF comparison_expr LBRACE top_level_list RBRACE {
        ASTNode *n = make_node(NODE_IF, NULL);
        n->left = $2; n->children = $4;
        $$ = n;
    }
    | KW_IF comparison_expr LBRACE top_level_list RBRACE KW_ELSE LBRACE top_level_list RBRACE {
        ASTNode *n = make_node(NODE_IF, NULL);
        n->left = $2; n->children = $4; n->right = $8;
        $$ = n;
    }
    ;

repeat_stmt
    : KW_REPEAT INT_LIT KW_TIMES LBRACE top_level_list RBRACE {
        ASTNode *n = make_node(NODE_REPEAT, NULL);
        n->int_val = $2; n->children = $5;
        $$ = n;
    }
    ;

assign_stmt
    : IDENTIFIER ASSIGN expr SEMICOLON {
        ASTNode *n = make_node(NODE_ASSIGN, $1);
        n->left = $3;
        $$ = n;
        free($1);
    }
    ;

print_stmt
    : KW_PRINT STRING_LIT SEMICOLON {
        ASTNode *n = make_node(NODE_PRINT, NULL);
        n->str_val = $2;
        $$ = n;
    }
    | KW_PRINT expr SEMICOLON {
        ASTNode *n = make_node(NODE_PRINT, NULL);
        n->left = $2;
        $$ = n;
    }
    ;

save_stmt
    : KW_SAVE IDENTIFIER KW_TO STRING_LIT SEMICOLON {
        ASTNode *n = make_node(NODE_SAVE, $2);
        n->str_val = $4;
        $$ = n;
        free($2);
    }
    ;

load_stmt
    : KW_LOAD IDENTIFIER KW_FROM STRING_LIT SEMICOLON {
        ASTNode *n = make_node(NODE_LOAD, $2);
        n->str_val = $4;
        $$ = n;
        free($2);
    }
    ;

summary_stmt
    : KW_SUMMARY IDENTIFIER SEMICOLON {
        $$ = make_node(NODE_SUMMARY, $2);
        free($2);
    }
    ;

/*══════════════════════════════════════════════════════════════════════
 * EXPRESIONES
 *════════════════════════════════════════════════════════════════════*/

expr : additive_expr { $$ = $1; } ;

comparison_expr
    : expr EQ expr  { ASTNode *n = make_node(NODE_EXPR, "=="); n->left=$1; n->right=$3; $$=n; }
    | expr NEQ expr { ASTNode *n = make_node(NODE_EXPR, "!="); n->left=$1; n->right=$3; $$=n; }
    | expr GEQ expr { ASTNode *n = make_node(NODE_EXPR, ">="); n->left=$1; n->right=$3; $$=n; }
    | expr LEQ expr { ASTNode *n = make_node(NODE_EXPR, "<="); n->left=$1; n->right=$3; $$=n; }
    | expr GT expr  { ASTNode *n = make_node(NODE_EXPR, ">");  n->left=$1; n->right=$3; $$=n; }
    | expr LT expr  { ASTNode *n = make_node(NODE_EXPR, "<");  n->left=$1; n->right=$3; $$=n; }
    ;

additive_expr
    : multiplicative_expr                               { $$ = $1; }
    | additive_expr PLUS multiplicative_expr            { ASTNode *n=make_node(NODE_EXPR,"+"); n->left=$1; n->right=$3; $$=n; }
    | additive_expr MINUS multiplicative_expr           { ASTNode *n=make_node(NODE_EXPR,"-"); n->left=$1; n->right=$3; $$=n; }
    ;

multiplicative_expr
    : unary_expr                                        { $$ = $1; }
    | multiplicative_expr STAR unary_expr               { ASTNode *n=make_node(NODE_EXPR,"*"); n->left=$1; n->right=$3; $$=n; }
    | multiplicative_expr SLASH unary_expr              { ASTNode *n=make_node(NODE_EXPR,"/"); n->left=$1; n->right=$3; $$=n; }
    ;

unary_expr
    : primary_expr                      { $$ = $1; }
    | MINUS unary_expr %prec UMINUS     { ASTNode *n=make_node(NODE_EXPR,"neg"); n->left=$2; $$=n; }
    ;

primary_expr
    : INT_LIT       { ASTNode *n=make_node(NODE_EXPR,"int"); n->int_val=$1; $$=n; }
    | FLOAT_LIT     { ASTNode *n=make_node(NODE_EXPR,"float"); n->num_val=$1; $$=n; }
    | IDENTIFIER    { $$=make_node(NODE_EXPR,$1); free($1); }
    | IDENTIFIER DOT IDENTIFIER {
        ASTNode *n=make_node(NODE_EXPR,"member_access");
        n->str_val=strdup($1); n->left=make_node(NODE_EXPR,$3);
        $$=n; free($1); free($3);
    }
    | LPAREN expr RPAREN    { $$=$2; }
    ;

dim_list
    : LBRACKET dim_list_inner RBRACKET  { $$ = $2; }
    ;

dim_list_inner
    : expr {
        ASTNode *n = make_node(NODE_EXPR, "dim");
        n->left = $1;
        $$ = n;
    }
    | dim_list_inner COMMA expr {
        ASTNode *n = make_node(NODE_EXPR, "dim");
        n->left = $3;
        append_sibling($1, n);
        $$ = $1;
    }
    ;

%%

/*══════════════════════════════════════════════════════════════════════
 * MAIN
 *════════════════════════════════════════════════════════════════════*/

void yyerror(const char *s) {
    fprintf(stderr, "Error de parseo en línea %d: %s\n", line_num, s);
}

int main(int argc, char **argv) {
    printf("╔══════════════════════════════════════════════╗\n");
    printf("║     NeuroLang Meta Parser v2.0               ║\n");
    printf("║  Meta-lenguaje para Arquitecturas Neuronales  ║\n");
    printf("╚══════════════════════════════════════════════╝\n\n");

    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            fprintf(stderr, "Error: no se puede abrir '%s'\n", argv[1]);
            return 1;
        }
    }

    if (yyparse() == 0) {
        printf("✓ Parseo exitoso.\n\n");
        printf("── Árbol Sintáctico Abstracto (AST) ──\n\n");
        print_ast(ast_root, 0);
    } else {
        printf("✗ Parseo fallido.\n");
    }

    if (yyin && yyin != stdin) fclose(yyin);
    return 0;
}
