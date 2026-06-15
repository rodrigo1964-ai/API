/*
 * cmdparser.y
 * Parser de comandos para orquestador de bots
 * Genera libcmdparser.so para ser consumido desde FreePascal
 */

%{
#include <stdio.h>
#include <string.h>

/* Prototipos */
int yylex(void);
void yyerror(const char *s);

/*
 * CALLBACKS HACIA PASCAL
 * Estas funciones son punteros que Pascal setea al iniciar.
 * Cuando Bison reconoce un comando, llama al callback correspondiente.
 * Pascal recibe la notificación y ejecuta la lógica de negocio.
 */

/* Callback: comando simple (ALLOW Bot1, DENY Bot1, STATUS Bot1) */
typedef void (*cmd_simple_cb)(int cmd, const char* service_name);
static cmd_simple_cb on_simple_command = NULL;

/* Callback: comando con puerto (START Bot1 ON PORT 8080) */
typedef void (*cmd_port_cb)(int cmd, const char* service_name, int port);
static cmd_port_cb on_port_command = NULL;

/* Callback: comando con condición (RESTART Bot1 IF DOWN) */
typedef void (*cmd_condition_cb)(int cmd, const char* service_name, int condition);
static cmd_condition_cb on_condition_command = NULL;

/* Callback: comando con nivel (LOG Bot1 LEVEL debug) */
typedef void (*cmd_level_cb)(int cmd, const char* service_name, const char* level);
static cmd_level_cb on_level_command = NULL;

/* Callback: error de parseo */
typedef void (*cmd_error_cb)(const char* message);
static cmd_error_cb on_parse_error = NULL;

/*
 * Funciones exportadas para que Pascal registre los callbacks
 */
void register_simple_cb(cmd_simple_cb cb)    { on_simple_command = cb; }
void register_port_cb(cmd_port_cb cb)        { on_port_command = cb; }
void register_condition_cb(cmd_condition_cb cb) { on_condition_command = cb; }
void register_level_cb(cmd_level_cb cb)      { on_level_command = cb; }
void register_error_cb(cmd_error_cb cb)      { on_parse_error = cb; }

/* Códigos de comando */
#define CMD_ALLOW    1
#define CMD_DENY     2
#define CMD_START    3
#define CMD_STOP     4
#define CMD_STATUS   5
#define CMD_RESTART  6
#define CMD_LOG      7

/* Códigos de condición */
#define COND_DOWN    1

%}

/* Tipos de valores semánticos */
%union {
    int    num;
    char   name[64];
}

/* Tokens sin valor */
%token TOKEN_ALLOW TOKEN_DENY TOKEN_START TOKEN_STOP
%token TOKEN_STATUS TOKEN_RESTART TOKEN_LOG
%token TOKEN_ON TOKEN_PORT TOKEN_FORCE TOKEN_IF TOKEN_DOWN
%token TOKEN_LEVEL TOKEN_ALL
%token TOKEN_NEWLINE TOKEN_UNKNOWN

/* Tokens con valor */
%token <num>  TOKEN_NUMBER
%token <name> TOKEN_ID

%%

/*
 * GRAMATICA
 * Define la estructura válida de los comandos
 */

input:
        /* vacío */
      | input line
      ;

line:
        command TOKEN_NEWLINE
      | TOKEN_NEWLINE              /* línea vacía, ignorar */
      ;

command:
        simple_command
      | port_command
      | condition_command
      | level_command
      | force_command
      ;

/* ALLOW Bot1 / DENY Bot1 / STATUS Bot1 / STOP Bot1 */
simple_command:
        TOKEN_ALLOW TOKEN_ID
        { if(on_simple_command) on_simple_command(CMD_ALLOW, $2); }
      | TOKEN_DENY TOKEN_ID
        { if(on_simple_command) on_simple_command(CMD_DENY, $2); }
      | TOKEN_STATUS TOKEN_ID
        { if(on_simple_command) on_simple_command(CMD_STATUS, $2); }
      | TOKEN_STOP TOKEN_ID
        { if(on_simple_command) on_simple_command(CMD_STOP, $2); }
      | TOKEN_STATUS TOKEN_ALL
        { if(on_simple_command) on_simple_command(CMD_STATUS, "ALL"); }
      | TOKEN_STOP TOKEN_ALL
        { if(on_simple_command) on_simple_command(CMD_STOP, "ALL"); }
      ;

/* START Bot1 ON PORT 8080 */
port_command:
        TOKEN_START TOKEN_ID TOKEN_ON TOKEN_PORT TOKEN_NUMBER
        { if(on_port_command) on_port_command(CMD_START, $2, $5); }
      | TOKEN_START TOKEN_ID
        { if(on_port_command) on_port_command(CMD_START, $2, 0); }
      ;

/* RESTART Bot1 IF DOWN */
condition_command:
        TOKEN_RESTART TOKEN_ID TOKEN_IF TOKEN_DOWN
        { if(on_condition_command) on_condition_command(CMD_RESTART, $2, COND_DOWN); }
      | TOKEN_RESTART TOKEN_ID
        { if(on_simple_command) on_simple_command(CMD_RESTART, $2); }
      | TOKEN_RESTART TOKEN_ALL TOKEN_IF TOKEN_DOWN
        { if(on_condition_command) on_condition_command(CMD_RESTART, "ALL", COND_DOWN); }
      ;

/* LOG Bot1 LEVEL debug */
level_command:
        TOKEN_LOG TOKEN_ID TOKEN_LEVEL TOKEN_ID
        { if(on_level_command) on_level_command(CMD_LOG, $2, $4); }
      ;

/* STOP Bot1 FORCE */
force_command:
        TOKEN_STOP TOKEN_ID TOKEN_FORCE
        { if(on_simple_command) on_simple_command(CMD_STOP, $2); }
      ;

%%

/*
 * Manejo de errores: notifica a Pascal
 */
void yyerror(const char *s) {
    if(on_parse_error)
        on_parse_error(s);
    else
        fprintf(stderr, "Parse error: %s\n", s);
}

/*
 * Función para parsear un string directamente (sin stdin)
 * Pascal llama a esta función pasando el texto a parsear
 */
typedef struct yy_buffer_state *YY_BUFFER_STATE;
extern YY_BUFFER_STATE yy_scan_string(const char *str);
extern void yy_delete_buffer(YY_BUFFER_STATE buffer);

int parse_command(const char* cmd) {
    /* Agregar newline si no tiene */
    char buffer[256];
    snprintf(buffer, sizeof(buffer), "%s\n", cmd);

    YY_BUFFER_STATE bs = yy_scan_string(buffer);
    int result = yyparse();
    yy_delete_buffer(bs);
    return result;
}
