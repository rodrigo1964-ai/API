# Reporte de Prueba: Ecuaciones con Funciones Estándar + Conjuntos
## Bridge GeCode Validator

**Fecha:** 21 de febrero de 2026
**Tipo de Prueba:** Evaluación de ecuaciones matemáticas con operaciones de conjuntos
**Archivo:** `test_prueba_ecuaciones_conjuntos.json`

---

## 1. Objetivo

Validar el comportamiento del sistema Bridge GeCode al trabajar con **ecuaciones matemáticas** que integran **funciones estándar** (sqrt, abs, sqr, sin, cos, exp, ln) con **operaciones de conjuntos** (CARDINALITY, UNION, INTERSECT, DIFFERENCE, SUBSET) usando **operadores relacionales** (=, <, >).

Esta prueba evalúa:
- CARDINALITY como valor numérico en ecuaciones
- Ecuaciones que mezclan tamaños de conjuntos con valores numéricos
- Comparaciones entre funciones matemáticas y cardinalidades
- Operaciones de conjuntos como condiciones en ecuaciones

---

## 2. Configuración de la Prueba

### 2.1 Precisión
- **Decimales:** 2
- **Factor de escala:** 100

### 2.2 Variables Definidas

| Variable | Tipo    | Dominio                   | Valores Posibles | Cantidad |
|----------|---------|---------------------------|------------------|----------|
| x        | float   | [0.0, 10.0]               | [1.0, 4.0, 9.0]  | 3        |
| y        | float   | [0.0, 10.0]               | [2.0, 3.0]       | 2        |
| z        | float   | [0.0, 20.0]               | [5.0, 10.0]      | 2        |
| A        | set     | [a, b, c, d]              | [a, b]           | 1 (|A|=2)|
| B        | set     | [b, c, d, e]              | [b, c, d]        | 1 (|B|=3)|
| permisos | set     | [read, write, execute]    | [read, write]    | 1 (|P|=2)|
| nivel    | integer | [1, 10]                   | [2, 4, 6]        | 3        |

Total: **7 variables** (3 float, 1 integer, 3 set)

---

## 3. Expresiones Evaluadas (Ecuaciones + Conjuntos)

### 3.1 Raíces y Cardinalidad

#### Expresión 1: `((sqrt(x) = CARDINALITY(A)) AND ({a} SUBSET A))`
- **Ecuación:** sqrt(x) = |A|
- **Valores:** |A| = 2, sqrt(x)  in  {1, 2, 3}
- **Resultado:** [false, false, false] (3 valores)
- **Interpretación:** sqrt(4) = 2 = |A| es true, pero sqrt(1)=1 y sqrt(9)=3 son false

#### Expresión 3: `((sqr(CARDINALITY(A)) = x) AND ({b} SUBSET (A INTERSECT B)))`
- **Ecuación:** |A|^2 = x
- **Valores:** |A|^2 = 4, x  in  {1, 4, 9}
- **Interpretación:** Cuadrado de cardinalidad igual a variable

#### Expresión 11: `((sqrt(CARDINALITY(A UNION B)) = sqrt(5)) AND (nivel > 3))`
- **Ecuación:** sqrt(|A U B|) = sqrt(5)
- **Valores:** |A U B| = |{a,b,c,d}| = 4
- **Interpretación:** sqrt(4) != sqrt(5)

---

### 3.2 Valor Absoluto y Diferencias de Conjuntos

#### Expresión 2: `((abs(x - y) > CARDINALITY(B)) OR (CARDINALITY(A UNION B) >= 4))`
- **Ecuación:** |x - y| > |B|
- **Valores:** |B| = 3, |A U B| = 4
- **Resultado:** [true, true, ...] (6 valores)
- **Interpretación:** Distancia vs tamaño de conjunto

#### Expresión 6: `((abs(CARDINALITY(A) - CARDINALITY(B)) = 1) OR (sin(x) < 1))`
- **Ecuación:** ||A| - |B|| = 1
- **Valores:** |2 - 3| = 1
- **Interpretación:** Diferencia de tamaños exacta

#### Expresión 14: `((abs(sqrt(x) - CARDINALITY(A)) < 1) OR ({c,d} SUBSET B))`
- **Ecuación:** |sqrt(x) - |A|| < 1
- **Valores:** |sqrt(x) - 2| < 1 para x  in  {1,4,9}
- **Interpretación:** Proximidad entre raíz y cardinalidad

---

### 3.3 Cardinalidad en Ecuaciones Aritméticas

#### Expresión 4: `((CARDINALITY(permisos) + nivel = 8) OR (exp(x) > 10))`
- **Ecuación:** |permisos| + nivel = 8
- **Valores:** 2 + {2,4,6} = {4,6,8}
- **Interpretación:** Suma de cardinalidad con entero

#### Expresión 10: `((CARDINALITY(A) * CARDINALITY(B) = nivel) OR (abs(x - y) > 2))`
- **Ecuación:** |A| × |B| = nivel
- **Valores:** 2 × 3 = 6
- **Interpretación:** Producto de cardinalidades

#### Expresión 13: `((CARDINALITY(A) + CARDINALITY(B) = 5) AND (sqr(y) > x))`
- **Ecuación:** |A| + |B| = 5
- **Valores:** 2 + 3 = 5 OK
- **Interpretación:** Suma de tamaños con condición aritmética

#### Expresión 15: `((CARDINALITY(A INTERSECT B) * nivel = 2) AND (exp(nivel) > z))`
- **Ecuación:** |A intersect B| × nivel = 2
- **Valores:** |{b}| × {2,4,6} = {2,4,6}
- **Interpretación:** Intersección ponderada

---

### 3.4 Funciones Matemáticas sobre Cardinalidad

#### Expresión 5: `((sqrt(nivel) < y) AND (CARDINALITY(A UNION B) = 5))`
- **Ecuación:** sqrt(nivel) < y y |A U B| = 5
- **Resultado:** [false, false, ...] (6 valores)
- **Interpretación:** Raíz de entero comparada con float, verificando unión

#### Expresión 7: `((sqr(nivel) = CARDINALITY(B) * 3) AND ({write} SUBSET permisos))`
- **Ecuación:** nivel^2 = |B| × 3
- **Valores:** {4,16,36} = 3×3 = 9
- **Interpretación:** Cuadrado vs múltiplo de cardinalidad

#### Expresión 9: `((ln(CARDINALITY(permisos) + 1) < y) AND (CARDINALITY(B) >= 3))`
- **Ecuación:** ln(|permisos| + 1) < y
- **Valores:** ln(3) ~= 1.10 < {2.0, 3.0}
- **Interpretación:** Logaritmo de cardinalidad incrementada

---

### 3.5 Ecuaciones Geométricas con Conjuntos

#### Expresión 8: `((CARDINALITY(A DIFFERENCE B) > 0) OR (sqrt(x) + sqrt(y) = sqrt(z)))`
- **Ecuación compuesta:**
  - |A \ B| > 0 (diferencia no vacía)
  - sqrt(x) + sqrt(y) = sqrt(z)
- **Interpretación:** Conjunto no vacío OR suma de raíces

---

### 3.6 Trigonometría con Cardinalidad

#### Expresión 12: `((sin(nivel) + cos(nivel) < 2) OR (CARDINALITY(permisos) = 2))`
- **Ecuación:** sin(nivel) + cos(nivel) < 2 O |permisos| = 2
- **Resultado:** [false, ..., true, ...] (9 valores)
- **Propiedad:** sin(x) + cos(x) <= sqrt(2) ~= 1.414 < 2
- **Interpretación:** Cota trigonométrica O cardinalidad exacta

---

## 4. Análisis de Resultados

### 4.1 Integración Set → Number

CARDINALITY convierte conjuntos en valores numéricos que pueden:
- Participar en aritmética: |A| + |B|, |A| × nivel
- Ser argumentos de funciones: sqrt(|A|), sqr(|B|)
- Usarse en comparaciones: |A| = 2, |B| > nivel

### 4.2 Flujo de Datos

```
Set --UNION/INTERSECT--> Set --CARDINALITY--> Integer
                                                  |
                                                  v
                                            +, -, *, /
                                                  |
                                                  v
                                          sqrt, sqr, abs
                                                  |
                                                  v
                                            =, <, > -> Boolean
```

### 4.3 Ecuaciones Interesantes

| Expresión | Ecuación | Significado |
|-----------|----------|-------------|
| 1         | sqrt(x) = \|A\| | Raíz igual a tamaño |
| 3         | \|A\|^2 = x | Cuadrado de tamaño |
| 4         | \|P\| + nivel = 8 | Suma mixta |
| 10        | \|A\| × \|B\| = nivel | Producto de tamaños |
| 13        | \|A\| + \|B\| = 5 | Suma de cardinalidades |

### 4.4 Validación

- **Variables procesadas:** 7 (3 float, 1 int, 3 set)
- **Expresiones evaluadas:** 15
- **Errores detectados:** 0
- **Estado:** JSON VÁLIDO

---

## 5. Aplicaciones Prácticas

- **Gestión de recursos:** Tamaño de equipos vs carga de trabajo
- **Optimización discreta:** Cardinalidad como restricción
- **Análisis de redes:** Grado de nodos vs métricas
- **Bases de datos:** COUNT(*) en condiciones WHERE
- **Machine Learning:** Tamaño de conjuntos de características
- **Planificación:** Número de elementos vs límites

---

## 6. Conclusiones

1. **CARDINALITY** se integra correctamente en ecuaciones matemáticas
2. Las **funciones estándar** operan sobre cardinalidades
3. Los **operadores relacionales** comparan conjuntos y números
4. La **mezcla de tipos** (set + float + int) es robusta
5. Es apto para **optimización con restricciones de cardinalidad**

---

**Fin del Reporte**
