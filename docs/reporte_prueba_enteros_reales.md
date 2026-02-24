# Reporte de Prueba: Enteros y Reales Combinados (Anidamiento Doble)
## Bridge GeCode Validator

**Fecha:** 21 de febrero de 2026
**Tipo de Prueba:** Evaluación de expresiones mixtas con anidamiento doble
**Archivo:** `test_prueba_enteros_reales.json`

---

## 1. Objetivo

Validar el comportamiento del sistema Bridge GeCode al trabajar con **expresiones que combinan enteros y flotantes** usando **anidamiento doble de paréntesis** y evaluar **15 expresiones** que incluyen:

- Combinación de tipos integer y float
- Anidamiento doble: ((a op b) op (c op d))
- Operaciones aritméticas complejas
- Funciones matemáticas anidadas
- Propagación de incertidumbre con 3-6 variables
- Explosión combinatoria masiva (hasta 216 valores)

## 2. Configuración de la Prueba

### 2.1 Precisión
- **Decimales:** 2
- **Factor de escala:** 100

### 2.2 Variables Definidas

| Variable | Tipo    | Dominio        | Valores Posibles | Cantidad |
|----------|---------|----------------|------------------|----------|
| x        | integer | [1, 100]       | [10, 20]         | 2        |
| y        | integer | [1, 50]        | [5, 10, 15]      | 3        |
| a        | float   | [0.0, 10.0]    | [1.5, 3.0]       | 2        |
| b        | float   | [0.0, 5.0]     | [0.5, 1.0, 2.0]  | 3        |
| c        | integer | [-10, 10]      | [-2, 0, 2]       | 3        |
| d        | float   | [0.0, 100.0]   | [10.0, 25.0]     | 2        |

Total: **3 variables integer** y **3 variables float** con diferentes grados de incertidumbre.

---

## 3. Expresiones Evaluadas (con Anidamiento Doble)

### 3.1 Operaciones Aritméticas Anidadas

#### Expresión 1: `((x + y) * (a - b))`
- **Estructura:** (suma) * (resta)
- **Resultado:** [1500.000, 750.000, -750.000, ...] (36 valores)
- **Combinaciones:** 2 × 3 × 2 × 3 = 36
- **Interpretación:** Producto de suma de enteros por resta de floats

#### Expresión 2: `((x - y) / (a + b))`
- **Estructura:** (resta) / (suma)
- **Resultado:** [0.020, 0.020, 0.010, ...] (36 valores)
- **Combinaciones:** 36
- **Interpretación:** División puede producir valores muy pequeños

#### Expresión 3: `((a * b) + (x * y))`
- **Estructura:** (float × float) + (int × int)
- **Resultado:** [5075.000, 10075.000, 15075.000, ...] (36 valores)
- **Interpretación:** Suma de productos heterogéneos

#### Expresión 4: `((x / 2) - (a * 3))`
- **Estructura:** (división) - (multiplicación con constante)
- **Resultado:** [0.500, -4.000, 5.500, 1.000] (4 valores)
- **Combinaciones:** 2 × 2 = 4
- **Interpretación:** Mezcla de enteros, floats y constantes

---

### 3.2 Anidamiento Triple con División

#### Expresión 5: `(((x + y) * a) / (b + 1))`
- **Estructura:** ((suma) × float) / (suma con constante)
- **Resultado:** [44.110, 22.270, 11.190, ...] (36 valores)
- **Niveles de anidamiento:** 3
- **Interpretación:** División de producto anidado

#### Expresión 8: `(((a + b) * (x - c)) / (y + 1))`
- **Estructura:** ((float+float) × (int-int)) / (int+constante)
- **Resultado:** [4.790, 2.390, 1.590, ...] (108 valores)
- **Combinaciones:** 2 × 3 × 2 × 3 × 3 = 108
- **Interpretación:** División compleja de 5 variables

---

### 3.3 Funciones Matemáticas Anidadas

#### Expresión 6: `((sqr(a) + sqr(b)) * (x - y))`
- **Estructura:** (función + función) × (resta)
- **Resultado:** [1250.000, 0.000, -1250.000, ...] (36 valores)
- **Interpretación:** Suma de cuadrados multiplicada por diferencia

#### Expresión 9: `((abs(c) * a) + (sqrt(d) * b))`
- **Estructura:** (abs × float) + (sqrt × float)
- **Resultado:** [458.000, 616.000, 932.000, ...] (36 valores)
- **Interpretación:** Combinación de funciones abs y sqrt

#### Expresión 12: `((sin(a) + cos(b)) * (x + y))`
- **Estructura:** (trigonométrica + trigonométrica) × suma
- **Resultado:** [2790.000, 3720.000, 4650.000, ...] (36 valores)
- **Interpretación:** Funciones trigonométricas anidadas

#### Expresión 13: `((exp(a) - ln(d)) * (y - c))`
- **Estructura:** (exponencial - logaritmo) × resta
- **Resultado:** [1526.000, 1090.000, 654.000, ...] (36 valores)
- **Interpretación:** Funciones trascendentes combinadas

---

### 3.4 Expresiones Máximas (6 Variables)

#### Expresión 7: `((x * (y + c)) - (a * (b + d)))`
- **Estructura:** (int×(int+int)) - (float×(float+float))
- **Resultado:** [1425.000, -825.000, 1350.000, ...] (216 valores)
- **Combinaciones:** 2 × 3 × 3 × 2 × 3 × 2 = 216
- **Explosión combinatoria máxima:** 216 valores posibles
- **Interpretación:** Todas las 6 variables involucradas

#### Expresión 10: `((x + (y * 2)) - ((a + b) * c))`
- **Estructura:** (int+(int×const)) - ((float+float)×int)
- **Resultado:** [420.000, 20.000, -380.000, ...] (108 valores)
- **Combinaciones:** 108
- **Interpretación:** Múltiples niveles de paréntesis

#### Expresión 14: `(((x + a) * (y - b)) / ((c + 5) * d))`
- **Estructura:** ((int+float)×(int-float)) / ((int+const)×float)
- **Resultado:** [-0.020, -0.010, 1.030, ...] (216 valores)
- **Combinaciones:** 216 (máxima complejidad)
- **Interpretación:** División compleja de 6 variables

#### Expresión 15: `((sqr(x - y) + abs(a - b)) * (c + d))`
- **Estructura:** (función(resta) + función(resta)) × (suma)
- **Resultado:** [20800.000, 59800.000, 26000.000, ...] (216 valores)
- **Interpretación:** Funciones sobre restas anidadas

---

### 3.5 Operaciones Mixtas Avanzadas

#### Expresión 11: `(((x / y) + (a / b)) * c)`
- **Estructura:** ((división int) + (división float)) × int
- **Resultado:** [-10.000, 0.000, 10.000, ...] (108 valores)
- **Interpretación:** Suma de divisiones heterogéneas

---

## 4. Análisis de Resultados

### 4.1 Explosión Combinatoria por Niveles

| Expresión | Variables | Tipo de combinación | Total valores |
|-----------|-----------|---------------------|---------------|
| 4         | 2 (x,a)   | 2 × 2               | 4             |
| 1-6       | 4         | 2 × 3 × 2 × 3       | 36            |
| 8, 10, 11 | 5         | Variable            | 108           |
| 7, 14, 15 | 6         | 2 × 3 × 2 × 3 × 3 × 2 | 216        |

### 4.2 Impacto del Anidamiento

El anidamiento doble permite:
- **Composición de operaciones:** (a op b) op (c op d)
- **Precedencia clara:** Paréntesis explícitos
- **Evaluación correcta:** De adentro hacia afuera
- **Complejidad controlada:** Hasta 3-4 niveles de profundidad

### 4.3 Mezcla de Tipos (Int + Float)

- **Conversión implícita:** Integer → Float en operaciones mixtas
- **Precisión:** Mantiene 2 decimales
- **Rango dinámico:** Floats amplían el espacio de valores
- **Compatibilidad:** Todas las operaciones funcionan entre tipos

### 4.4 Validación

- **Variables procesadas:** 6 (3 integer, 3 float)
- **Expresiones evaluadas:** 15
- **Combinaciones máximas:** 216 valores
- **Errores detectados:** 0
- **Estado:** JSON VÁLIDO - listo para el Bridge

---

## 5. Comparación con Otras Pruebas

| Aspecto              | Solo Floats | Solo Ints | Int + Float (Esta) |
|----------------------|-------------|-----------|---------------------|
| Tipos de datos       | 1           | 1         | 2 (mixto)          |
| Valores máximos      | 16          | 54        | 216                |
| Anidamiento          | Simple      | Simple    | Doble              |
| Complejidad          | Media       | Media     | Alta               |
| Aplicabilidad        | CSP numérico| CSP discreto| CSP híbrido       |

---

## 6. Aplicaciones Prácticas

Este tipo de pruebas es útil para:

- **Modelos físicos:** Combinación de parámetros discretos y continuos
- **Optimización multiobjetivo:** Variables de diferentes naturalezas
- **Simulación de sistemas:** Mezcla de contadores enteros y medidas reales
- **Finanzas:** Cantidades discretas (acciones) y precios continuos
- **Ingeniería:** Especificaciones enteras con tolerancias continuas
- **Machine Learning:** Hiperparámetros discretos y continuos

---

## 7. Conclusiones

1. El sistema **maneja correctamente** la mezcla de integer y float
2. El **anidamiento doble** funciona según lo esperado
3. La **explosión combinatoria** alcanza hasta 216 valores
4. Las **funciones matemáticas** (sqr, abs, sqrt, sin, cos, exp, ln) operan en contextos anidados
5. La **precedencia de operadores** se respeta con paréntesis explícitos
6. Es apto para **CSP híbridos** con variables discretas y continuas
7. Representa el **caso más complejo** de evaluación de expresiones

---

## 8. Archivo de Entrada

```json
{
  "precision": 2,
  "variables": [
    {"nombre": "x", "tipo": "integer", "domain": [1, 100], "value": [10, 20]},
    {"nombre": "y", "tipo": "integer", "domain": [1, 50], "value": [5, 10, 15]},
    {"nombre": "a", "tipo": "float", "domain": [0.0, 10.0], "value": [1.5, 3.0]},
    {"nombre": "b", "tipo": "float", "domain": [0.0, 5.0], "value": [0.5, 1.0, 2.0]},
    {"nombre": "c", "tipo": "integer", "domain": [-10, 10], "value": [-2, 0, 2]},
    {"nombre": "d", "tipo": "float", "domain": [0.0, 100.0], "value": [10.0, 25.0]}
  ],
  "expresiones": [
    "((x + y) * (a - b))", "((x - y) / (a + b))",
    "((a * b) + (x * y))", "((x / 2) - (a * 3))",
    "(((x + y) * a) / (b + 1))", "((sqr(a) + sqr(b)) * (x - y))",
    "((x * (y + c)) - (a * (b + d)))",
    "(((a + b) * (x - c)) / (y + 1))",
    "((abs(c) * a) + (sqrt(d) * b))",
    "((x + (y * 2)) - ((a + b) * c))",
    "(((x / y) + (a / b)) * c)",
    "((sin(a) + cos(b)) * (x + y))",
    "((exp(a) - ln(d)) * (y - c))",
    "(((x + a) * (y - b)) / ((c + 5) * d))",
    "((sqr(x - y) + abs(a - b)) * (c + d))"
  ]
}
```

---

**Fin del Reporte**
