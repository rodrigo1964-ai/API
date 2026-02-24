/* ================================================================
   bridge_gecode.l
   Lexer Flex - Bridge Pascal/JSON -> GeCode Space
   Convierte floats a enteros via factor_global (redondeo)
   ================================================================ */

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
