#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "bridge_types.h"

/* Tokenizer simple para expresiones */
typedef enum {
    TOK_EOF, TOK_NUM, TOK_IDENT, TOK_TRUE, TOK_FALSE,
    TOK_PLUS, TOK_MINUS, TOK_MULT, TOK_DIV,
    TOK_EQ, TOK_NEQ, TOK_LT, TOK_GT, TOK_LEQ, TOK_GEQ,
    TOK_AND, TOK_OR, TOK_NOT, TOK_IMPLICA, TOK_IN,
    TOK_UNION, TOK_INTERSECT, TOK_DIFFERENCE, TOK_SUBSET, TOK_CARDINALITY,
    TOK_LPAREN, TOK_RPAREN, TOK_LBRACE, TOK_RBRACE, TOK_COMMA,
    TOK_ABS, TOK_SQRT, TOK_SQR, TOK_SIN, TOK_COS, TOK_LN, TOK_EXP
} TokenType;

typedef struct {
    TokenType type;
    int num_val;
    char *str_val;
} Token;

static const char *input;
static int pos;
static Token current_token;

static void skip_spaces() {
    while (input[pos] && isspace(input[pos])) pos++;
}

static Token next_token() {
    Token tok = {TOK_EOF, 0, NULL};
    skip_spaces();

    if (!input[pos]) return tok;

    /* Números */
    if (isdigit(input[pos])) {
        int val = 0;
        int has_dot = 0;
        int decimal_places = 0;
        while (isdigit(input[pos]) || input[pos] == '.') {
            if (input[pos] == '.') {
                has_dot = 1;
                pos++;
                continue;
            }
            val = val * 10 + (input[pos] - '0');
            if (has_dot) decimal_places++;
            pos++;
        }
        if (has_dot) {
            /* Convertir a entero según factor_global */
            for (int i = decimal_places; i < precision_decimales; i++) val *= 10;
            for (int i = precision_decimales; i < decimal_places; i++) val /= 10;
        }
        tok.type = TOK_NUM;
        tok.num_val = val;
        return tok;
    }

    /* Identificadores y palabras clave */
    if (isalpha(input[pos]) || input[pos] == '_') {
        char buf[256];
        int i = 0;
        while ((isalnum(input[pos]) || input[pos] == '_') && i < 255) {
            buf[i++] = input[pos++];
        }
        buf[i] = '\0';

        if (strcmp(buf, "true") == 0) { tok.type = TOK_TRUE; return tok; }
        if (strcmp(buf, "false") == 0) { tok.type = TOK_FALSE; return tok; }
        if (strcmp(buf, "AND") == 0) { tok.type = TOK_AND; return tok; }
        if (strcmp(buf, "OR") == 0) { tok.type = TOK_OR; return tok; }
        if (strcmp(buf, "NOT") == 0) { tok.type = TOK_NOT; return tok; }
        if (strcmp(buf, "IMPLICA") == 0) { tok.type = TOK_IMPLICA; return tok; }
        if (strcmp(buf, "IN") == 0 || strcmp(buf, "in") == 0) { tok.type = TOK_IN; return tok; }
        if (strcmp(buf, "UNION") == 0) { tok.type = TOK_UNION; return tok; }
        if (strcmp(buf, "INTERSECT") == 0) { tok.type = TOK_INTERSECT; return tok; }
        if (strcmp(buf, "DIFFERENCE") == 0) { tok.type = TOK_DIFFERENCE; return tok; }
        if (strcmp(buf, "SUBSET") == 0) { tok.type = TOK_SUBSET; return tok; }
        if (strcmp(buf, "CARDINALITY") == 0) { tok.type = TOK_CARDINALITY; return tok; }
        if (strcmp(buf, "abs") == 0) { tok.type = TOK_ABS; return tok; }
        if (strcmp(buf, "sqrt") == 0) { tok.type = TOK_SQRT; return tok; }
        if (strcmp(buf, "sqr") == 0) { tok.type = TOK_SQR; return tok; }
        if (strcmp(buf, "sin") == 0) { tok.type = TOK_SIN; return tok; }
        if (strcmp(buf, "cos") == 0) { tok.type = TOK_COS; return tok; }
        if (strcmp(buf, "ln") == 0) { tok.type = TOK_LN; return tok; }
        if (strcmp(buf, "exp") == 0) { tok.type = TOK_EXP; return tok; }

        tok.type = TOK_IDENT;
        tok.str_val = strdup(buf);
        return tok;
    }

    /* Operadores */
    if (input[pos] == '<' && input[pos+1] == '>') {
        pos += 2; tok.type = TOK_NEQ; return tok;
    }
    if (input[pos] == '<' && input[pos+1] == '=') {
        pos += 2; tok.type = TOK_LEQ; return tok;
    }
    if (input[pos] == '>' && input[pos+1] == '=') {
        pos += 2; tok.type = TOK_GEQ; return tok;
    }
    if (input[pos] == '=') { pos++; tok.type = TOK_EQ; return tok; }
    if (input[pos] == '<') { pos++; tok.type = TOK_LT; return tok; }
    if (input[pos] == '>') { pos++; tok.type = TOK_GT; return tok; }
    if (input[pos] == '+') { pos++; tok.type = TOK_PLUS; return tok; }
    if (input[pos] == '-') { pos++; tok.type = TOK_MINUS; return tok; }
    if (input[pos] == '*') { pos++; tok.type = TOK_MULT; return tok; }
    if (input[pos] == '/') { pos++; tok.type = TOK_DIV; return tok; }
    if (input[pos] == '(') { pos++; tok.type = TOK_LPAREN; return tok; }
    if (input[pos] == ')') { pos++; tok.type = TOK_RPAREN; return tok; }
    if (input[pos] == '{') { pos++; tok.type = TOK_LBRACE; return tok; }
    if (input[pos] == '}') { pos++; tok.type = TOK_RBRACE; return tok; }
    if (input[pos] == ',') { pos++; tok.type = TOK_COMMA; return tok; }

    pos++; /* Skip unknown character */
    return tok;
}

/* Forward declarations */
static Nodo* parse_expr();
static Nodo* parse_impl();
static Nodo* parse_or();
static Nodo* parse_and();
static Nodo* parse_not();
static Nodo* parse_comp();
static Nodo* parse_add();
static Nodo* parse_mult();
static Nodo* parse_atom();

static Nodo* parse_impl() {
    Nodo *left = parse_or();
    if (current_token.type == TOK_IMPLICA) {
        current_token = next_token();
        Nodo *right = parse_or();
        return nodo_binario(NODO_IMPLICA, left, right);
    }
    return left;
}

static Nodo* parse_or() {
    Nodo *left = parse_and();
    while (current_token.type == TOK_OR) {
        current_token = next_token();
        Nodo *right = parse_and();
        left = nodo_binario(NODO_OR, left, right);
    }
    return left;
}

static Nodo* parse_and() {
    Nodo *left = parse_not();
    while (current_token.type == TOK_AND) {
        current_token = next_token();
        Nodo *right = parse_not();
        left = nodo_binario(NODO_AND, left, right);
    }
    return left;
}

static Nodo* parse_not() {
    if (current_token.type == TOK_NOT) {
        current_token = next_token();
        return nodo_unario(NODO_NOT, parse_not());
    }
    return parse_comp();
}

static Nodo* parse_comp() {
    Nodo *left = parse_add();

    TokenType cmp = current_token.type;
    if (cmp == TOK_EQ || cmp == TOK_NEQ || cmp == TOK_LT ||
        cmp == TOK_GT || cmp == TOK_LEQ || cmp == TOK_GEQ) {
        current_token = next_token();
        Nodo *right = parse_add();
        TipoNodo tipo;
        switch (cmp) {
            case TOK_EQ: tipo = NODO_EQ; break;
            case TOK_NEQ: tipo = NODO_NEQ; break;
            case TOK_LT: tipo = NODO_LT; break;
            case TOK_GT: tipo = NODO_GT; break;
            case TOK_LEQ: tipo = NODO_LEQ; break;
            case TOK_GEQ: tipo = NODO_GEQ; break;
            default: tipo = NODO_EQ;
        }
        return nodo_binario(tipo, left, right);
    }

    return left;
}

static Nodo* parse_add() {
    Nodo *left = parse_mult();
    while (current_token.type == TOK_PLUS || current_token.type == TOK_MINUS) {
        TokenType op = current_token.type;
        current_token = next_token();
        Nodo *right = parse_mult();
        left = nodo_binario(op == TOK_PLUS ? NODO_SUMA : NODO_RESTA, left, right);
    }
    return left;
}

static Nodo* parse_mult() {
    Nodo *left = parse_atom();
    while (current_token.type == TOK_MULT || current_token.type == TOK_DIV) {
        TokenType op = current_token.type;
        current_token = next_token();
        Nodo *right = parse_atom();
        left = nodo_binario(op == TOK_MULT ? NODO_MULT : NODO_DIV, left, right);
    }
    return left;
}

static Nodo* parse_atom() {
    /* Números */
    if (current_token.type == TOK_NUM) {
        int val = current_token.num_val;
        current_token = next_token();
        return nodo_entero(val);
    }

    /* Booleanos */
    if (current_token.type == TOK_TRUE) {
        current_token = next_token();
        return nodo_bool(1);
    }
    if (current_token.type == TOK_FALSE) {
        current_token = next_token();
        return nodo_bool(0);
    }

    /* Funciones estándar */
    if (current_token.type >= TOK_ABS && current_token.type <= TOK_EXP) {
        TipoNodo func_tipo;
        switch (current_token.type) {
            case TOK_ABS: func_tipo = NODO_ABS; break;
            case TOK_SQRT: func_tipo = NODO_SQRT; break;
            case TOK_SQR: func_tipo = NODO_SQR; break;
            case TOK_SIN: func_tipo = NODO_SIN; break;
            case TOK_COS: func_tipo = NODO_COS; break;
            case TOK_LN: func_tipo = NODO_LN; break;
            case TOK_EXP: func_tipo = NODO_EXP; break;
            default: func_tipo = NODO_ABS;
        }
        current_token = next_token();
        if (current_token.type == TOK_LPAREN) {
            current_token = next_token();
            Nodo *arg = parse_expr();
            if (current_token.type == TOK_RPAREN) current_token = next_token();
            return nodo_func_std(func_tipo, arg);
        }
    }

    /* Identificadores */
    if (current_token.type == TOK_IDENT) {
        char *name = current_token.str_val;
        current_token = next_token();
        return nodo_ident(name);
    }

    /* Paréntesis */
    if (current_token.type == TOK_LPAREN) {
        current_token = next_token();
        Nodo *expr = parse_expr();
        if (current_token.type == TOK_RPAREN) current_token = next_token();
        return expr;
    }

    return NULL;
}

static Nodo* parse_expr() {
    return parse_impl();
}

Nodo* parse_expression(const char *expr_str) {
    input = expr_str;
    pos = 0;
    current_token = next_token();
    return parse_expr();
}
