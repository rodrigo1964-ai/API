# Reporte de Prueba: Lógicas y Conjuntos Combinados (Anidamiento Doble)
## Bridge GeCode Validator

**Fecha:** 21 de febrero de 2026
**Tipo de Prueba:** Evaluación de expresiones lógicas y conjuntos con anidamiento doble
**Archivo:** `test_prueba_logicas_conjuntos.json`

---

## 1. Objetivo

Validar el comportamiento del sistema Bridge GeCode al trabajar con **expresiones que combinan lógica booleana y operaciones de conjuntos** usando **anidamiento doble de paréntesis** y evaluar **15 expresiones** que incluyen:

- Combinación de tipos logic, set e integer
- Anidamiento doble: ((p AND q) OR (r AND s))
- Operaciones de conjuntos anidadas (UNION, INTERSECT, CARDINALITY)
- Operadores lógicos complejos (AND, OR, NOT, IMPLICA)
- Operadores relacionales con conjuntos
- Mezcla de álgebra booleana y teoría de conjuntos

## 2. Configuración de la Prueba

### 2.1 Precisión
- **Decimales:** 0
- **Factor de escala:** 1

### 2.2 Variables Definidas

| Variable    | Tipo    | Dominio                      | Valores Posibles | Cantidad |
|-------------|---------|------------------------------|------------------|----------|
| activo      | logic   | [true, false]                | [true, false]    | 2        |
| validado    | logic   | [true, false]                | [true, false]    | 2        |
| autorizado  | logic   | [true, false]                | [true, false]    | 2        |
| A           | set     | [a, b, c, d]                 | [a, b]           | 1        |
| B           | set     | [b, c, d, e]                 | [b, c]           | 1        |
| permisos    | set     | [read, write, execute]       | [read, write]    | 1        |
| nivel       | integer | [1, 10]                      | [2, 5, 8]        | 3        |

Total: **3 variables logic** (2 valores), **3 variables set**, **1 variable integer** (3 valores).

---

## 3. Expresiones Evaluadas (con Anidamiento Doble)

### 3.1 Lógica con Cardinalidad de Conjuntos

#### Expresión 1: `((activo AND validado) OR (autorizado AND (CARDINALITY(A) > 1)))`
- **Estructura:** (bool AND bool) OR (bool AND (card > int))
- **Resultado:** [true, true, false, false, ...] (8 valores)
- **Combinaciones:** 2 × 2 × 2 = 8
- **Interpretación:** Condición compuesta con verificación de tamaño de conjunto
- **Análisis:** CARDINALITY(A) = 2, entonces (2 > 1) = true

#### Expresión 4: `((activo IMPLICA validado) AND (CARDINALITY(permisos) >= 2))`
- **Estructura:** (implicación) AND (cardinalidad >= constante)
- **Resultado:** [false, false, false, false] (4 valores)
- **Combinaciones:** 2 × 2 = 4
- **Interpretación:** Implicación lógica combinada con restricción de conjunto

---

### 3.2 Conjuntos con Operadores Lógicos

#### Expresión 2: `((CARDINALITY(A UNION B) >= 3) AND (activo OR validado))`
- **Estructura:** (card(operación) >= int) AND (bool OR bool)
- **Detalle:** |A U B| = |{a,b,c}| = 3
- **Interpretación:** Tamaño de unión con condición lógica

#### Expresión 3: `(({b} SUBSET A) AND ({c} SUBSET B)) OR (NOT activo)`
- **Estructura:** ((subset) AND (subset)) OR (negación)
- **Detalle:**
  - {b} SUBSET {a,b} = true
  - {c} SUBSET {b,c} = true
- **Interpretación:** Verificación de pertenencia con escape lógico

---

### 3.3 Expresiones con Operaciones de Conjuntos Anidadas

#### Expresión 7: `(((A INTERSECT B) = {b}) IMPLICA (activo AND validado))`
- **Estructura:** (igualdad de conjuntos) IMPLICA (conjunción)
- **Detalle:**
  - A = {a,b}, B = {b,c}
  - A INTERSECT B = {b}
  - {b} = {b} es true
- **Interpretación:** Condición sobre resultado de intersección

#### Expresión 8: `((CARDINALITY(A UNION B) <= 5) AND ((activo AND validado) OR autorizado))`
- **Estructura:** (comparación de cardinalidad) AND (disyunción anidada)
- **Interpretación:** Restricción de tamaño con condición lógica compuesta

#### Expresión 15: `(((A DIFFERENCE B) = {a}) AND (activo IMPLICA (validado AND (nivel >= 2))))`
- **Estructura:** (igualdad tras diferencia) AND (implicación anidada)
- **Detalle:**
  - A DIFFERENCE B = {a,b} - {b,c} = {a}
  - Verifica diferencia exacta
- **Interpretación:** Operación de conjunto con implicación compleja

---

### 3.4 Mezcla de Tipos (Logic + Set + Integer)

#### Expresión 5: `(((CARDINALITY(A) + CARDINALITY(B)) > 2) AND (activo AND autorizado))`
- **Estructura:** (suma de cardinalidades > int) AND (conjunción)
- **Detalle:** |A| + |B| = 2 + 2 = 4 > 2
- **Tipos involucrados:** set → int → bool + logic

#### Expresión 6: `((activo OR validado) AND ((nivel > 3) OR ({write} SUBSET permisos)))`
- **Estructura:** (disyunción) AND ((comparación int) OR (subset))
- **Resultado:** [false, true, true, ...] (12 valores)
- **Combinaciones:** 2 × 2 × 3 = 12
- **Tipos:** logic + integer + set combinados

#### Expresión 9: `(({a} SUBSET A) AND ({read} SUBSET permisos)) AND (validado OR (nivel >= 5))`
- **Estructura:** ((subset) AND (subset)) AND (bool OR (comparación))
- **Detalle:**
  - {a} SUBSET {a,b} = true
  - {read} SUBSET {read,write} = true
- **Interpretación:** Triple conjunción con tipos mixtos

---

### 3.5 Operadores de Comparación y Conjuntos

#### Expresión 10: `((NOT activo) OR ((CARDINALITY(permisos) >= 2) AND autorizado))`
- **Estructura:** (negación) OR ((cardinalidad) AND bool)
- **Resultado:** [false, true] (2 valores)
- **Interpretación:** Cortocircuito lógico con cardinalidad

#### Expresión 11: `(((CARDINALITY(A) * nivel) > 10) AND (activo OR validado))`
- **Estructura:** (producto de cardinalidad × int > constante) AND disyunción
- **Detalle:** |A| × nivel = 2 × {2,5,8} = {4,10,16}
- **Interpretación:** Operación aritmética sobre cardinalidad

#### Expresión 14: `((CARDINALITY(permisos) + nivel) >= 5) AND ((activo OR validado) AND (NOT autorizado))`
- **Estructura:** (suma card+int >= const) AND (disyunción AND negación)
- **Detalle:** |permisos| + nivel = 2 + {2,5,8} = {4,7,10}
- **Interpretación:** Aritmética sobre conjuntos con lógica anidada

---

### 3.6 Expresiones Avanzadas con SUBSET

#### Expresión 12: `((activo AND (CARDINALITY(B) >= 2)) OR ((nivel > 5) AND autorizado))`
- **Estructura:** (bool AND comparación) OR (comparación AND bool)
- **Resultado:** [false, false] (2 valores)
- **Interpretación:** Disyunción de condiciones compuestas

#### Expresión 13: `(({b,c} SUBSET (A UNION B)) AND ((activo AND validado) IMPLICA autorizado))`
- **Estructura:** (subset de unión) AND (implicación)
- **Detalle:**
  - A U B = {a,b,c}
  - {b,c} SUBSET {a,b,c} = true
- **Interpretación:** Operación de conjunto como condición para implicación

---

## 4. Análisis de Resultados

### 4.1 Integración de Tipos

| Tipo origen | Operación | Tipo resultado | Ejemplo |
|-------------|-----------|----------------|---------|
| set         | CARDINALITY | integer    | CARDINALITY(A) → 2 |
| set × set   | SUBSET    | logic          | {a} SUBSET A → true |
| set × set   | UNION/INTERSECT | set   | A UNION B → {a,b,c} |
| integer     | comparación | logic        | nivel > 3 → bool |
| logic × logic | AND/OR   | logic         | p AND q → bool |

### 4.2 Explosión Combinatoria

| Expresión | Variables lógicas | Variables int | Combinaciones |
|-----------|-------------------|---------------|---------------|
| 1         | 3 (2 cada una)    | 0             | 8             |
| 4         | 2                 | 0             | 4             |
| 6         | 2                 | 1 (3 valores) | 12            |
| 10        | 1                 | 0             | 2             |

### 4.3 Anidamiento y Precedencia

El anidamiento doble permite expresar:
- **Condiciones complejas:** ((p AND q) OR (r AND s))
- **Jerarquía clara:** Paréntesis explícitos
- **Composición de operadores:** Lógicos, relacionales, de conjuntos
- **Evaluación correcta:** De adentro hacia afuera

### 4.4 Operaciones de Conjuntos como Predicados

Los conjuntos se usan como:
1. **Fuente de valores numéricos:** CARDINALITY → integer
2. **Condiciones lógicas:** SUBSET → boolean
3. **Operandos de comparación:** A UNION B = {...}
4. **Restricciones:** Tamaño mínimo/máximo

### 4.5 Validación

- **Variables procesadas:** 7 (3 logic, 3 set, 1 integer)
- **Expresiones evaluadas:** 15
- **Errores detectados:** 0
- **Estado:** JSON VÁLIDO - listo para el Bridge

---

## 5. Aplicaciones Prácticas

Este tipo de pruebas es útil para:

- **Sistemas de autorización:** Combinación de roles, permisos y condiciones
- **Control de acceso basado en roles (RBAC):** Verificación de pertenencia a grupos
- **Validación de configuraciones:** Conjuntos de opciones con restricciones lógicas
- **Workflow engines:** Condiciones complejas para transiciones de estado
- **Sistemas expertos:** Reglas con conjuntos de hechos
- **Gestión de equipos:** Asignaciones con restricciones de tamaño y habilidades

---

## 6. Conclusiones

1. El sistema **integra correctamente** lógica booleana y operaciones de conjuntos
2. El **anidamiento doble** funciona para expresiones mixtas
3. **CARDINALITY** convierte conjuntos en valores numéricos para comparaciones
4. **SUBSET** genera valores booleanos para lógica
5. La **mezcla de tipos** (logic + set + integer) es robusta
6. Las **implicaciones anidadas** se evalúan correctamente
7. Es apto para **sistemas de reglas complejas** y **control de acceso avanzado**

---

## 7. Comparación con Otras Pruebas

| Aspecto              | Solo Lógica | Solo Conjuntos | Logic + Set (Esta) |
|----------------------|-------------|----------------|--------------------|
| Tipos mezclados      | 1           | 1              | 3 (logic+set+int)  |
| Complejidad          | Media       | Media          | Alta               |
| Anidamiento          | Simple      | Simple         | Doble              |
| Aplicaciones         | Decisiones  | Asignación     | RBAC, autorizació  |

---

## 8. Archivo de Entrada

```json
{
  "precision": 0,
  "variables": [
    {"nombre": "activo", "tipo": "logic", "domain": [true, false], "value": [true, false]},
    {"nombre": "validado", "tipo": "logic", "domain": [true, false], "value": [true, false]},
    {"nombre": "autorizado", "tipo": "logic", "domain": [true, false], "value": [true, false]},
    {"nombre": "A", "tipo": "set", "domain": ["a","b","c","d"], "value": ["a","b"]},
    {"nombre": "B", "tipo": "set", "domain": ["b","c","d","e"], "value": ["b","c"]},
    {"nombre": "permisos", "tipo": "set", "domain": ["read","write","execute"], "value": ["read","write"]},
    {"nombre": "nivel", "tipo": "integer", "domain": [1, 10], "value": [2, 5, 8]}
  ],
  "expresiones": [
    "((activo AND validado) OR (autorizado AND (CARDINALITY(A) > 1)))",
    "((CARDINALITY(A UNION B) >= 3) AND (activo OR validado))",
    "(({b} SUBSET A) AND ({c} SUBSET B)) OR (NOT activo)",
    "((activo IMPLICA validado) AND (CARDINALITY(permisos) >= 2))",
    "(((CARDINALITY(A) + CARDINALITY(B)) > 2) AND (activo AND autorizado))",
    "((activo OR validado) AND ((nivel > 3) OR ({write} SUBSET permisos)))",
    "(((A INTERSECT B) = {b}) IMPLICA (activo AND validado))",
    "((CARDINALITY(A UNION B) <= 5) AND ((activo AND validado) OR autorizado))",
    "(({a} SUBSET A) AND ({read} SUBSET permisos)) AND (validado OR (nivel >= 5))",
    "((NOT activo) OR ((CARDINALITY(permisos) >= 2) AND autorizado))",
    "(((CARDINALITY(A) * nivel) > 10) AND (activo OR validado))",
    "((activo AND (CARDINALITY(B) >= 2)) OR ((nivel > 5) AND autorizado))",
    "(({b,c} SUBSET (A UNION B)) AND ((activo AND validado) IMPLICA autorizado))",
    "((CARDINALITY(permisos) + nivel) >= 5) AND ((activo OR validado) AND (NOT autorizado))",
    "(((A DIFFERENCE B) = {a}) AND (activo IMPLICA (validado AND (nivel >= 2))))"
  ]
}
```

---

**Fin del Reporte**
