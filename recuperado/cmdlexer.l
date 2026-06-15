/*
 * cmdlexer.l
 * Analizador léxico para lenguaje de comandos de bots
 * Genera tokens para el parser Bison
 */

%{
#include "cmdparser.tab.h"
#include <string.h>
#include <stdlib.h>
%}

%option noyywrap nounput noinput

%%

    /* Comandos principales */
"ALLOW"       { return TOKEN_ALLOW; }
"DENY"        { return TOKEN_DENY; }
"START"       { return TOKEN_START; }
"STOP"        { return TOKEN_STOP; }
"STATUS"      { return TOKEN_STATUS; }
"RESTART"     { return TOKEN_RESTART; }
"LOG"         { return TOKEN_LOG; }

    /* Modificadores */
"ON"          { return TOKEN_ON; }
"PORT"        { return TOKEN_PORT; }
"FORCE"       { return TOKEN_FORCE; }
"IF"          { return TOKEN_IF; }
"DOWN"        { return TOKEN_DOWN; }
"LEVEL"       { return TOKEN_LEVEL; }
"ALL"         { return TOKEN_ALL; }

    /* Numeros */
[0-9]+        { yylval.num = atoi(yytext); return TOKEN_NUMBER; }

    /* Identificadores (nombres de servicio) */
[a-zA-Z_][a-zA-Z0-9_]*  {
                strncpy(yylval.name, yytext, 63);
                yylval.name[63] = '\0';
                return TOKEN_ID;
              }

    /* Fin de linea = fin de comando */
\n            { return TOKEN_NEWLINE; }

    /* Ignorar espacios y tabs */
[ \t]         ;

    /* Cualquier otro caracter: error */
.             { return TOKEN_UNKNOWN; }

%%
