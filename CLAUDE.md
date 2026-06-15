# Proyecto: GNUBison - Bridge GeCode Validator

## Propósito del Proyecto

**GNUBison** es un validador y evaluador de expresiones para problemas de Constraint Programming, diseñado como puente entre notaciones declarativas (Pascal-like y JSON) y motores de resolución como GeCode Space.

El proyecto implementa un **pipeline completo de validación y evaluación**:
- Parsea especificaciones de variables con dominios (integer, float, logic, set)
- Construye AST de expresiones con operadores aritméticos, lógicos, relacionales y de conjuntos
- Evalúa expresiones con propagación de incertidumbre (múltiples valores posibles por variable)
- Genera salida JSON estructurada para integración con solvers

**Casos de uso**: Verificación de restricciones, análisis de CSP con incertidumbre, validación de expresiones antes de enviar a solver, debugging de problemas de optimización.

---

## Arquitectura

### Pipeline Principal

```
Entrada (JSON o Pascal-like)
    ↓
Parser (json_reader.c o bridge_gecode.y)
    ↓
Tablas globales (vars[], set_tabla[])
    ↓
Parser de expresiones (expr_parser.c)
    ↓
AST (Nodo)
    ↓
Evaluador con incertidumbre (expr_eval.c)
    ↓
Resultados (ResultadoEval)
    ↓
Salida (texto o JSON via json_output.c)
```

### Componentes Clave

1. **Parsers duales**:
   - `bridge_gecode.y` + `bridge_gecode.l`: Formato Pascal-like (Bison + Flex)
   - `json_reader.c`: Formato JSON (usando cJSON)

2. **Evaluador con incertidumbre** (`expr_eval.c`):
   - Propaga múltiples valores: si `x=[10,20]` y `y=5`, entonces `x+y=[15,25]`
   - Calcula producto cartesiano de operandos en operadores binarios
   - Soporta aritmética, lógica, comparación y operaciones de conjuntos

3. **Sistema de precisión**:
   - `precision_decimales`: Número de decimales (ej: 2)
   - `factor_global = 10^precision`: Escala floats a enteros (ej: 3.14 → 314)
   - Evita aritmética flotante en evaluador (cálculos exactos con int)

4. **Operaciones de conjuntos**:
   - UNION, INTERSECT, DIFFERENCE, SUBSET, IN, CARDINALITY
   - Sets representados como arrays de strings (char*[])
   - Interning en `set_tabla[]` para comparación eficiente

---

## Decisiones de Diseño

### 1. Dual Format Support (JSON + Pascal-like)
- **JSON**: Machine-readable, ideal para pipelines automatizados y APIs
- **Pascal-like**: Human-readable, ideal para edición manual y ejemplos didácticos
- Ambos formatos comparten el mismo backend (AST, evaluador)

### 2. Escalado Float → Int
- Problema: Aritmética flotante introduce errores de redondeo
- Solución: Multiplicar por `factor_global` y operar con enteros
- Ejemplo: `precision=2`, `3.14 → 314`, `2.5 → 250`, `314 + 250 = 564 → 5.64`

### 3. Incertidumbre como Array de Valores
- Variable con incertidumbre: `tiene_value=2`, `val_vals=[10,20,30]`
- El evaluador calcula todas las combinaciones posibles
- Útil para CSP: explorar espacio de soluciones sin backtracking explícito

### 4. Interning de Strings de Conjuntos
- `reg_set(str)` → índice en `set_tabla[]`
- Comparación de sets por índice (O(1)) en vez de strcmp (O(n))
- Reduce fragmentación de memoria

### 5. AST Heterogéneo (struct Nodo)
- Un solo tipo de nodo con campos para todos los casos (binario, unario, literal, set)
- Trade-off: Memoria desperdiciada por nodos vs simplicidad de código
- Alternativa descartada: Herencia con void* (requiere casts, menos type-safe)

---

## Archivos Principales

### Core del Parser
- **`src/bridge_gecode.y`**: Parser Bison para formato Pascal-like. Define gramática, precedencia de operadores, acciones semánticas (registro de variables/funciones).
- **`src/bridge_gecode.l`**: Lexer Flex. Tokenización de palabras clave, identificadores, operadores.
- **`src/bridge_types.h`**: Tipos compartidos (Nodo, VarReg, FuncReg, TipoVar, TipoNodo). Header central incluido por todos los módulos.

### Procesamiento JSON
- **`src/json_reader.c`**: Parser de archivos JSON. Lee precision, variables, expresiones. Delega parsing de expresiones a `expr_parser.c` y evaluación a `expr_eval.c`.
- **`src/json_output.c`**: Generador de salida JSON estructurada. Serializa resultados de evaluación para consumo externo.
- **`src/cJSON.c/h`**: Biblioteca JSON externa (MIT license, single-file).

### Motor de Evaluación
- **`src/expr_eval.c`**: Evaluador recursivo de AST con propagación de incertidumbre. Implementa operadores aritméticos, lógicos, de comparación y de conjuntos. Retorna `ResultadoEval` con array de valores posibles.
- **`src/expr_parser.c`**: Parser recursivo descendente de expresiones. Tokeniza y parsea strings de expresiones en JSON (alternativa ligera a Bison para expresiones individuales).

### Funciones Auxiliares
- **`src/aggregate_functions.c/h`**: Funciones estadísticas (sum, avg, min, max, median, variance, stdev, all, any, count) para procesar resultados con incertidumbre.

---

## Relación con GNU Bison y GeCode

### GNU Bison (Parser Generator)
- **Uso**: Herramienta de construcción, no código base modificado
- **Propósito**: Genera `bridge_gecode.tab.c` a partir de `bridge_gecode.y`
- **Versión**: Bison 3.x (estándar GNU)
- **Relación**: Este proyecto **no es un fork de Bison**, usa Bison como dependencia

### GeCode (Constraint Solver)
- **Diseño**: Este validador es el "bridge" para preparar expresiones para GeCode
- **Pipeline previsto**: JSON → Validación → GeCode Space → Solución
- **Estado actual**: El validador está completo (parsing + evaluación), integración con GeCode solver pendiente (modo dry-run)

### Nombre del Proyecto
- "GNUBison" es nombre histórico del directorio
- Refleja stack: GNU Bison (parser) + GeCode (solver previsto)
- **No implica** modificación del código de GNU Bison upstream

---

## Testing y Ejemplos

### Casos de Prueba
- **41 ejemplos JSON** en `ejemplos/`:
  - Ejemplos 1-20: Operaciones básicas (aritmética, lógica, comparación)
  - Ejemplos 21-41: Operaciones avanzadas de conjuntos
  - Casos de uso: control de acceso, proyectos, redes, inventarios, IoT

### Tests de Incertidumbre
- Variables con múltiples valores: `"value": [10, 20, 30]`
- Propagación en operadores: `x=[1,2], y=[3,4]` → `x+y=[4,5,5,6]`
- Documentados en `docs/reporte_prueba_*_incertidumbre.md`

### Tests de Conjuntos
- Operaciones: UNION, INTERSECT, DIFFERENCE, SUBSET, IN, CARDINALITY
- Ejemplo: `{A,B} UNION {B,C} = {A,B,C}`
- Archivo: `test_sets_completo.txt` (formato Pascal-like)

---

## Compilación y Uso

### Requisitos
- gcc (compilador C)
- GNU Bison 3.x (parser generator)
- Flex 2.x (lexer generator)
- make

### Compilar
```bash
make              # Compila bridge (ejecutable principal)
make clean        # Limpia objetos generados
```

### Ejecutar
```bash
# Formato JSON (con evaluación)
./bridge ejemplo.json

# Formato Pascal-like (solo validación + AST)
./bridge test_bridge.txt

# Modo JSON output (machine-readable)
./bridge --json ejemplo.json -o resultados.json
```

---

## Historial de Modificaciones

### 2026-06-14 - Documentación paradigma MotorGoARP
- Headers uniformados en archivos principales: json_reader.c, json_output.c, expr_eval.c, expr_parser.c, aggregate_functions.c, bridge_types.h, bridge_gecode.y
- CLAUDE.md expandido con arquitectura, decisiones de diseño, relación con GNU Bison/GeCode
- Documentación de pipeline completo y propagación de incertidumbre

### 2026-02-24 - Estandarización del proyecto
- Estructura de directorios completada según modelo estándar
- Archivos organizados en: bin/, docs/, ejemplos/, obj/, src/, tests/
- Scripts de automatización agregados (demo.sh, probar_todos.sh, generar_pdfs.sh)
- CLAUDE.md y README.txt creados

### Versiones anteriores
- Implementación del parser Bison/Flex
- Sistema de evaluación con incertidumbre
- Soporte de operaciones de conjuntos
- 41 casos de prueba validados

---

## Referencias Externas

- **GNU Bison**: https://www.gnu.org/software/bison/
- **Flex**: https://github.com/westes/flex
- **GeCode**: https://www.gecode.org/
- **cJSON**: https://github.com/DaveGamble/cJSON
- **Constraint Programming**: Rossi, van Beek, Walsh (2006) - Handbook of Constraint Programming
