# ================================================================
# Makefile - Sistema de construcción de GNUBison
# Proyecto: GNUBison - Bridge GeCode Validator
# ================================================================
#
# PROPÓSITO:
#   Sistema de construcción modular para el proyecto. Genera parser/lexer
#   con Bison/Flex, compila módulos C, y enlaza el ejecutable final.
#
# ESTRUCTURA DEL PROYECTO:
#   src/     - Código fuente (.y, .l, .c, .h)
#   obj/     - Archivos objeto (.o) y código generado (.tab.c, lex.yy.c)
#   bin/     - Ejecutable final (bridge)
#   docs/    - Documentación
#   tests/   - Casos de prueba
#
# PIPELINE DE CONSTRUCCIÓN:
#   1. Bison: bridge_gecode.y → bridge_gecode.tab.c + bridge_gecode.tab.h
#   2. Flex: bridge_gecode.l → lex.yy.c (requiere bridge_gecode.tab.h)
#   3. Compilación: Módulos C (.c → .o)
#   4. Enlazado: .o + .tab.c + lex.yy.c → bin/bridge
#
# TARGETS PRINCIPALES:
#   make           - Construye bin/bridge
#   make clean     - Elimina objetos y archivos generados
#   make test      - Ejecuta prueba básica
#   make test-all  - Ejecuta todas las pruebas (via probar_todos.sh)
#   make info      - Muestra estructura del proyecto
#   make install   - Instala a /usr/local/bin/bridge
#
# DECISIONES DE DISEÑO:
#   - Separación de directorios: Evita mezclar fuente/binarios/generados
#   - Dependencias explícitas: Cada .o lista sus .h para rebuild incremental
#   - Bison primero, Flex después: lex.yy.c necesita bridge_gecode.tab.h
#   - CFLAGS con -lm: Enlaza libmath para funciones trigonométricas
#   - CFLAGS con -I$(SRC_DIR): Permite #include "header.h" sin path relativo
#
# DEPENDENCIAS EXTERNAS:
#   - gcc (compilador C)
#   - GNU Bison 3.x (parser generator)
#   - Flex 2.x (lexer generator)
#   - make (GNU Make)
#
# ================================================================

CC = gcc
CFLAGS = -Wall -std=c11 -g -lm -I$(SRC_DIR)

# Directorios
SRC_DIR = src
OBJ_DIR = obj
BIN_DIR = bin
DOCS_DIR = docs
TESTS_DIR = tests

# Archivos fuente
SOURCES = $(SRC_DIR)/bridge_gecode.y $(SRC_DIR)/bridge_gecode.l
C_SOURCES = $(SRC_DIR)/json_reader.c $(SRC_DIR)/expr_parser.c \
            $(SRC_DIR)/expr_eval.c $(SRC_DIR)/json_output.c \
            $(SRC_DIR)/cJSON.c $(SRC_DIR)/aggregate_functions.c

# Archivos objeto
OBJECTS = $(OBJ_DIR)/json_reader.o $(OBJ_DIR)/expr_parser.o \
          $(OBJ_DIR)/expr_eval.o $(OBJ_DIR)/json_output.o \
          $(OBJ_DIR)/cJSON.o $(OBJ_DIR)/aggregate_functions.o

# Archivos generados
GENERATED = $(OBJ_DIR)/bridge_gecode.tab.c $(OBJ_DIR)/bridge_gecode.tab.h \
            $(OBJ_DIR)/lex.yy.c $(OBJ_DIR)/bridge_gecode.output

# Ejecutable
TARGET = $(BIN_DIR)/bridge

# Regla principal
all: $(TARGET)

# Compilar ejecutable
$(TARGET): $(OBJ_DIR)/bridge_gecode.tab.c $(OBJ_DIR)/lex.yy.c $(OBJECTS)
	@echo "Linking executable..."
	$(CC) $(CFLAGS) -o $(TARGET) \
	      $(OBJ_DIR)/bridge_gecode.tab.c $(OBJ_DIR)/lex.yy.c $(OBJECTS) -lm
	@echo "Build complete: $(TARGET)"

# Compilar módulos C
$(OBJ_DIR)/json_reader.o: $(SRC_DIR)/json_reader.c $(SRC_DIR)/json_reader.h \
                           $(SRC_DIR)/bridge_types.h $(SRC_DIR)/cJSON.h \
                           $(SRC_DIR)/expr_eval.h $(SRC_DIR)/json_output.h
	@echo "Compiling json_reader.c..."
	$(CC) $(CFLAGS) -c $(SRC_DIR)/json_reader.c -o $(OBJ_DIR)/json_reader.o

$(OBJ_DIR)/expr_parser.o: $(SRC_DIR)/expr_parser.c $(SRC_DIR)/bridge_types.h
	@echo "Compiling expr_parser.c..."
	$(CC) $(CFLAGS) -c $(SRC_DIR)/expr_parser.c -o $(OBJ_DIR)/expr_parser.o

$(OBJ_DIR)/expr_eval.o: $(SRC_DIR)/expr_eval.c $(SRC_DIR)/expr_eval.h \
                         $(SRC_DIR)/bridge_types.h
	@echo "Compiling expr_eval.c..."
	$(CC) $(CFLAGS) -c $(SRC_DIR)/expr_eval.c -o $(OBJ_DIR)/expr_eval.o

$(OBJ_DIR)/json_output.o: $(SRC_DIR)/json_output.c $(SRC_DIR)/json_output.h \
                           $(SRC_DIR)/bridge_types.h $(SRC_DIR)/cJSON.h
	@echo "Compiling json_output.c..."
	$(CC) $(CFLAGS) -c $(SRC_DIR)/json_output.c -o $(OBJ_DIR)/json_output.o

$(OBJ_DIR)/cJSON.o: $(SRC_DIR)/cJSON.c $(SRC_DIR)/cJSON.h
	@echo "Compiling cJSON.c..."
	$(CC) $(CFLAGS) -c $(SRC_DIR)/cJSON.c -o $(OBJ_DIR)/cJSON.o

$(OBJ_DIR)/aggregate_functions.o: $(SRC_DIR)/aggregate_functions.c \
                                   $(SRC_DIR)/aggregate_functions.h
	@echo "Compiling aggregate_functions.c..."
	$(CC) $(CFLAGS) -c $(SRC_DIR)/aggregate_functions.c -o $(OBJ_DIR)/aggregate_functions.o

# Generar parser con Bison
$(OBJ_DIR)/bridge_gecode.tab.c $(OBJ_DIR)/bridge_gecode.tab.h: $(SRC_DIR)/bridge_gecode.y
	@echo "Generating parser with Bison..."
	bison -d -v $(SRC_DIR)/bridge_gecode.y -o $(OBJ_DIR)/bridge_gecode.tab.c

# Generar lexer con Flex
$(OBJ_DIR)/lex.yy.c: $(SRC_DIR)/bridge_gecode.l $(OBJ_DIR)/bridge_gecode.tab.h
	@echo "Generating lexer with Flex..."
	flex -o $(OBJ_DIR)/lex.yy.c $(SRC_DIR)/bridge_gecode.l

# Limpiar archivos generados
clean:
	@echo "Cleaning build files..."
	rm -f $(TARGET) $(OBJECTS) $(GENERATED)
	@echo "Clean complete."

# Limpiar todo (incluye directorios)
distclean: clean
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*

# Ejecutar prueba básica
test: $(TARGET)
	@echo "Running basic test..."
	$(TARGET) $(TESTS_DIR)/test_bridge.txt

# Ejecutar todas las pruebas
test-all: $(TARGET)
	@echo "Running all tests..."
	./probar_todos.sh

# Mostrar información del proyecto
info:
	@echo "=== Bridge GeCode Validator ==="
	@echo "Structure:"
	@echo "  Source:     $(SRC_DIR)/"
	@echo "  Objects:    $(OBJ_DIR)/"
	@echo "  Binary:     $(BIN_DIR)/"
	@echo "  Docs:       $(DOCS_DIR)/"
	@echo "  Tests:      $(TESTS_DIR)/"
	@echo ""
	@echo "Targets:"
	@echo "  make        - Build project"
	@echo "  make clean  - Remove generated files"
	@echo "  make test   - Run basic test"
	@echo "  make info   - Show this information"

# Instalar (copiar a /usr/local/bin)
install: $(TARGET)
	@echo "Installing to /usr/local/bin..."
	sudo cp $(TARGET) /usr/local/bin/bridge
	@echo "Installation complete."

.PHONY: all clean distclean test test-all info install
