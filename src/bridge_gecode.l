/* ================================================================
 * bridge_gecode.l - Lexer Flex para formato Pascal-like
 * Proyecto: GNUBison - Bridge GeCode Validator
 * ================================================================
 *
 * PROPÓSITO:
 *   Análisis léxico (tokenización) de archivos en formato Pascal-like.
 *   Trabaja en conjunto con bridge_gecode.y (parser Bison) para
 *   implementar el pipeline de parsing completo.
 *
 * ARQUITECTURA:
 *   Entrada (texto) → Flex scanner (este archivo) → Tokens →
 *   Bison parser (bridge_gecode.y) → AST + tablas globales
 *
 * CARACTERÍSTICAS PRINCIPALES:
 *
 * 1. CONVERSIÓN FLOAT → INT:
 *    Los números decimales se multiplican por factor_global y se redondean.
 *    Ejemplo: con precision=2 (factor_global=100):
 *      - Input: "3.14"
 *      - Proceso: atof("3.14") * 100 = 314.0 → round() → 314
 *      - Token: NUMERO con yylval.entero=314
 *
 * 2. LOOKAHEAD PARA FUNCIONES:
 *    Patrón "abs"/[ \t]*"(" distingue función abs() de variable abs.
 *    Sin lookahead, "abs" siempre sería IDENTIFICADOR.
 *
 * 3. PALABRAS CLAVE CASE-SENSITIVE:
 *    AND/OR/NOT en mayúsculas (Pascal-like estricto).
 *    Operadores de conjuntos: UNION, INTERSECT, DIFFERENCE, etc.
 *
 * 4. STRINGS CON COMILLAS:
 *    "estado" → yylval.str = "estado" (sin comillas)
 *    Usado para elementos de conjuntos en formato Pascal.
 *
 * 5. COMENTARIOS:
 *    - Pascal: (* comentario *)
 *    - C++: // comentario
 *
 * TOKENS GENERADOS:
 *   - Estructura: PRECISION, VARIABLES, EXPRESIONES, FUNCIONES
 *   - Tipos: TIPO_INTEGER, TIPO_FLOAT, TIPO_LOGIC, TIPO_SET
 *   - Operadores: +, -, *, /, =, <>, <, >, <=, >=
 *   - Lógicos: AND, OR, NOT, IMPLICA
 *   - Conjuntos: IN, UNION, INTERSECT, DIFFERENCE, SUBSET, CARDINALITY
 *   - Funciones: FN_ABS, FN_SQRT, FN_SQR, FN_SIN, FN_COS, FN_LN, FN_EXP
 *   - Literales: NUMERO, IDENTIFICADOR, STRING_LIT, BOOL_TRUE, BOOL_FALSE
 *   - Delimitadores: {, }, [, ], (, ), ,, :, ;
 *
 * DECISIONES DE DISEÑO:
 *   - Conversión temprana float→int: Evita aritmética flotante en parser.
 *   - Lookahead para funciones: Reduce ambigüedad sin cambiar gramática.
 *   - strdup() para strings: Parser/evaluador asume ownership (debe free()).
 *   - yylineno habilitado: Reporta número de línea en errores.
 *   - noyywrap: No soporta múltiples archivos (un archivo por invocación).
 *
 * INTEGRACIÓN:
 *   - Genera tokens para bridge_gecode.y (parser Bison)
 *   - Usa bridge_gecode.tab.h (definiciones de tokens generadas por Bison)
 *   - Accede a factor_global (definido en bridge_gecode.y)
 *
 * DIFERENCIAS CON expr_parser.c:
 *   - Este lexer: Archivos completos Pascal-like (precision, variables, etc.)
 *   - expr_parser.c: Solo expresiones individuales (para JSON)
 *
 * REFERENCIAS:
 *   - GNU Flex: https://github.com/westes/flex
 *   - bridge_gecode.y: Parser Bison asociado
 *   - bridge_gecode.tab.h: Definiciones de tokens (generado por Bison)
 *
 * ================================================================ */

%{
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "bridge_gecode.tab.h"

extern int factor_global;
extern char *strdup(const char *);
%}

%option yylineno
%option noyywrap

%%

 /* ---- Estructura ---- */
"precision"     { return PRECISION; }
"variables"     { return VARIABLES; }
"expresiones"   { return EXPRESIONES; }
"funciones"     { return FUNCIONES; }
"nil"           { return NIL; }

 /* ---- Tipos ---- */
"integer"       { return TIPO_INTEGER; }
"float"         { return TIPO_FLOAT; }
"logic"         { return TIPO_LOGIC; }
"set"           { return TIPO_SET; }

 /* ---- Booleanos ---- */
"true"          { return BOOL_TRUE; }
"false"         { return BOOL_FALSE; }

 /* ---- Operadores logicos ---- */
"AND"           { return AND; }
"OR"            { return OR; }
"NOT"           { return NOT; }
"IMPLICA"       { return IMPLICA; }

 /* ---- Operadores de conjuntos ---- */
"IN"            { return IN; }
"UNION"         { return UNION; }
"INTERSECT"     { return INTERSECT; }
"DIFFERENCE"    { return DIFFERENCE; }
"SUBSET"        { return SUBSET; }
"CARDINALITY"   { return CARDINALITY; }

 /* ---- Funciones estandar (lookahead para distinguir de ident) ---- */
"abs"/[ \t]*"("   { return FN_ABS; }
"sqrt"/[ \t]*"("  { return FN_SQRT; }
"sqr"/[ \t]*"("   { return FN_SQR; }
"sin"/[ \t]*"("   { return FN_SIN; }
"cos"/[ \t]*"("   { return FN_COS; }
"ln"/[ \t]*"("    { return FN_LN; }
"exp"/[ \t]*"("   { return FN_EXP; }

 /* ---- Comparacion ---- */
"<>"            { return NEQ; }
"<="            { return LEQ; }
">="            { return GEQ; }
"="             { return EQ; }
"<"             { return LT; }
">"             { return GT; }

 /* ---- Float: redondear y convertir a entero ---- */
[0-9]+\.[0-9]+  {
    double val = atof(yytext);
    yylval.entero = (int)round(val * factor_global);
    return NUMERO;
}

 /* ---- Entero puro ---- */
[0-9]+  {
    yylval.entero = atoi(yytext);
    return NUMERO;
}

 /* ---- Identificador ---- */
[a-zA-Z_][a-zA-Z0-9_]*  {
    yylval.str = strdup(yytext);
    return IDENTIFICADOR;
}

 /* ---- String entre comillas ---- */
\"[^\"]*\"  {
    yytext[yyleng-1] = '\0';
    yylval.str = strdup(yytext + 1);
    return STRING_LIT;
}

 /* ---- Delimitadores ---- */
"{"     { return LBRACE; }
"}"     { return RBRACE; }
"["     { return LBRACKET; }
"]"     { return RBRACKET; }
"("     { return LPAREN; }
")"     { return RPAREN; }
","     { return COMMA; }
":"     { return COLON; }
";"     { return SEMICOLON; }

 /* ---- Aritmetica ---- */
[+\-*/] { return yytext[0]; }

 /* ---- Ignorar ---- */
[ \t\r\n]+  { /* skip */ }

 /* ---- Comentarios Pascal ---- */
"(*"([^*]|\*+[^*)])*"*)"  { /* skip */ }
"//"[^\n]*                  { /* skip */ }

 /* ---- Error ---- */
.   { fprintf(stderr, "Linea %d: caracter inesperado '%s'\n", yylineno, yytext); }

%%
