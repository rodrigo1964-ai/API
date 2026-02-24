================================================================================
GNUBison - Bridge GeCode Validator
================================================================================

DESCRIPCIÓN
-----------

Bridge GeCode Validator

Validador y evaluador de expresiones para problemas de Constraint Programming, diseñado como puente entre notación Pascal/JSON y GeCode Space.

Descripción

Este proyecto implementa un pipeline de verificación y evaluación que:

- ✅ Valida la sintaxis de archivos de especificación (Pascal-like y JSON)
- ✅ Construye un AST (Árbol de Sintaxis Abstracta) de las expresiones
- ✅ EVALÚA y CALCULA expresiones con variables
- ✅ Soporta variables de tipo: integer, float, logic, set
- ✅ Maneja expresiones aritméticas, lógicas y relacionales
- ✅ Operaciones de conjuntos: UNION, INTERSECT, DIFFERENCE, SUBSET, CARDINALITY, IN
- ✅ Sintaxis moderna de sets: {a,b,c} sin comillas en expresiones
- ✅ Evalúa funciones estándar (abs, sqrt, sin, cos, etc.)
- ✅ Maneja incertidumbre (múltiples valores posibles)
- ✅ Reporta errores de sintaxis y variables no declaradas
- ✅ Soporta formato Pascal-like Y JSON
- ✅ Incluye 41 ejemplos completos con casos de uso reales

Compilación

```bash
make
```

Para limpiar archivos generados:

```bash
make clean
```

Uso

```bash
./bridge <archivo_entrada>
```

El programa detecta automáticamente el formato (Pascal o JSON).

Ejemplos:

```bash
Formato Pascal-like
./bridge test_bridge.txt

Formato JSON (con evaluación)
./bridge ejemplo.json

Ejemplo simple con una expresión
./bridge ejemplo_simple.json
```

Formatos de Entrada

Formato Pascal-like

El archivo de entrada debe seguir esta estructura:

```pascal
precision: <decimales>;

variables: {
    <nombre> : <tipo> : <dominio> : <valor>;
    ...
}

expresiones: {
    <expresion>;
    ...
}

funciones: {
    <nombre> : [<parametros>] : <salida>;
    ...
}
```

Tipos Soportados

- integer: Números enteros
- float: Números de punto flotante (convertidos a enteros según precisión)
- logic: Booleanos (true/false o 0/1)
- set: Conjuntos de valores string

Operadores

- Aritméticos: +, -, *, /
- Comparación: =, <>, <, >, <=, >=
- Lógicos: AND, OR, NOT, IMPLICA
- Conjuntos:
  - IN - Pertenencia: x IN {a,b,c}
  - UNION - Unión: A UNION B
  - INTERSECT - Intersección: A INTERSECT B
  - DIFFERENCE - Diferencia: A DIFFERENCE B
  - SUBSET - Subconjunto: A SUBSET B
  - CARDINALITY - Tamaño: CARDINALITY(A)

Funciones Estándar

- abs(x) - Valor absoluto
- sqrt(x) - Raíz cuadrada
- sqr(x) - Cuadrado
- sin(x), cos(x) - Funciones trigonométricas
- ln(x) - Logaritmo natural
- exp(x) - Exponencial

Formato JSON

Alternativamente, puedes usar formato JSON:

```json
{
  "precision": 2,
  "variables": [
    {"nombre": "x", "tipo": "integer", "domain": [1, 100], "value": 10},
    {"nombre": "y", "tipo": "float", "domain": [0.0, 50.0], "value": 15.5},
    {"nombre": "activo", "tipo": "logic", "domain": [true, false], "value": true},
    {"nombre": "estado", "tipo": "set",
     "domain": {"nombre": "Estados", "miembros": ["A", "B", "C"]},
     "value": "A"}
  ],
  "expresiones": [
    "x + y * 2",
    "activo AND x > 5"
  ]
}
```

Valores con incertidumbre:
- "value": [10, 20, 30] - Múltiples valores posibles
- "value": null - Sin valor asignado
- El evaluador calcula todos los resultados posibles

Ejemplos Completos

- test_bridge.txt - Formato Pascal con todos los tipos
- test_sets_completo.txt - Demostración completa de operaciones de conjuntos
- ejemplos/ - 41 ejemplos JSON cubriendo:
  - Ejemplos 1-20: Operaciones básicas, aritmética, lógica
  - Ejemplos 21-41: Operaciones de conjuntos avanzadas
  - Casos de uso: control de acceso, proyectos, redes, inventarios, IoT, etc.

Ver ejemplos/README.md para la lista completa.

Salida

El validador imprime:

1. Sección de PRECISION
2. Lista de VARIABLES declaradas con sus tipos, dominios y valores
3. Árbol AST de cada EXPRESIÓN
4. EVALUACIÓN de la expresión con resultado calculado
5. Lista de FUNCIONES definidas
6. RESUMEN final con estadísticas y errores

Evaluación de Expresiones

Cuando se usa formato JSON, el programa evalúa y calcula automáticamente cada expresión:

```
Expr #1: (x + y) * z
  [*]
    [+]
      IDENT(x)
      IDENT(y)
    IDENT(z)
  Evaluando...
  => 4650000 (46500.000)
```

Manejo de incertidumbre:
- Variables con múltiples valores generan múltiples resultados
- Ejemplo: x=[10,20], y=5 → x+y produce [15, 25]
- Útil para análisis de restricciones y CSP

Si no hay errores, indica: >>> JSON VALIDO - listo para el Bridge <<<

Archivos del Proyecto

Core
- bridge_gecode.y - Parser Bison (gramática Pascal-like)
- bridge_gecode.l - Lexer Flex (análisis léxico)
- bridge_types.h - Tipos y estructuras compartidas
- Makefile - Sistema de construcción

Parser y Evaluador JSON
- json_reader.c/h - Parser de archivos JSON
- expr_parser.c - Parser de expresiones desde strings
- expr_eval.c/h - Evaluador de expresiones (cálculo)
- cJSON.c/h - Biblioteca JSON (externa)

Ejemplos
- test_bridge.txt - Formato Pascal completo
- ejemplo.json - Formato JSON completo (hospital)
- ejemplo_simple.json - JSON simple con una expresión

Requisitos

- gcc
- bison (GNU Bison 3.x)
- flex (Flex 2.x)
- make

Autor

Proyecto GNUBison - Bridge GeCode Validator

--------------------------------------------------------------------------------

EJECUTABLES
-----------

Este proyecto contiene 1 ejecutable en el directorio bin/:

  * bridge
    Ejecutable compilado (ELF)
    Descripción: Bridge GeCode Validator - Parser y evaluador de expresiones
    con soporte para incertidumbre, conjuntos y constraints.

CÓMO EJECUTAR
-------------

Desde el directorio raíz del proyecto:

  ./bin/bridge [archivo_entrada.json]

Ejemplos:

  ./bin/bridge ejemplos/entrada_1.json
  ./bin/bridge ejemplos/entrada_10.json > salida.json

Para ejecutar todos los ejemplos:

  ./probar_todos.sh

Para ver la demostración:

  ./demo.sh

--------------------------------------------------------------------------------
ESTRUCTURA DEL PROYECTO
-----------------------

  /bin/         - Ejecutable bridge
  /docs/        - Documentación técnica y reportes
  /ejemplos/    - 41 casos de prueba (entrada_*.json, salida_*.json)
  /obj/         - Archivos objeto de compilación
  /src/         - Código fuente (*.c, *.h, *.y, *.l)
  /tests/       - Tests adicionales y archivos de prueba

COMPILACIÓN
-----------

Requisitos:
  - GNU Bison 3.0+
  - Flex 2.6+
  - GCC con soporte C11
  - Make

Para compilar el proyecto:

  make

Para limpiar archivos generados:

  make clean

Para ejecutar tests:

  make test-all
  # o directamente:
  ./probar_todos.sh

Para generar documentación PDF:

  ./generar_pdfs.sh

ARCHIVOS PRINCIPALES
--------------------

  bridge_gecode.y    - Gramática Bison (parser)
  bridge_gecode.l    - Lexer Flex (tokenizador)
  json_reader.c      - Lector de entrada JSON
  expr_eval.c        - Evaluador de expresiones
  json_output.c      - Generador de salida JSON
  aggregate_functions.c - Funciones agregadas (sum, avg, min, max, etc.)

FORMATO DE ENTRADA
------------------

Los archivos de entrada son JSON con la estructura:

  {
    "variables": [...],
    "constraints": [...],
    "expressions": [...]
  }

Ver ejemplos/ para casos de uso completos.

================================================================================
