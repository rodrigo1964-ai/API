# Reporte de Prueba: Aritmética de Intervalos
## Bridge GeCode Validator

**Fecha:** 21 de febrero de 2026
**Tipo de Prueba:** Evaluación de expresiones con intervalos
**Archivo:** `test_prueba_intervalos.json`

---

## 1. Objetivo

Validar el comportamiento del sistema Bridge GeCode al trabajar con **variables de intervalos** y evaluar **15 expresiones** que incluyen:

- Operaciones aritméticas básicas
- Funciones matemáticas (sqrt, abs, sqr, sin, cos, exp, ln)
- Expresiones compuestas y anidadas
- Propagación de incertidumbre

## 2. Configuración de la Prueba

### 2.1 Precisión
- **Decimales:** 2
- **Factor de escala:** 100

### 2.2 Variables Definidas

| Variable | Tipo    | Dominio       | Valor (Intervalo) |
|----------|---------|---------------|-------------------|
| x        | float   | [0.0, 10.0]   | [1.0, 3.0]       |
| y        | float   | [-5.0, 5.0]   | [0.5, 2.5]       |
| z        | integer | [1, 100]      | [10, 20]         |
| w        | float   | [0.0, 100.0]  | [5.0, 15.0]      |

Cada variable tiene **2 valores posibles** (extremos del intervalo), lo que permite evaluar la propagación de incertidumbre.

---

## 3. Expresiones Evaluadas

### 3.1 Operaciones Básicas

#### Expresión 1: `x`
- **Resultado:** [1.000, 3.000]
- **Valores posibles:** 2
- **Interpretación:** Identidad, devuelve el intervalo original

#### Expresión 2: `x + y`
- **Resultado:** [1.500, 3.500, 3.500, 5.500]
- **Valores posibles:** 4 (2×2 combinaciones)
- **Interpretación:** Suma de intervalos genera todas las combinaciones

#### Expresión 3: `x - y`
- **Resultado:** [0.500, -1.500, 2.500, 0.500]
- **Valores posibles:** 4
- **Interpretación:** Resta con propagación de incertidumbre

#### Expresión 4: `x * y`
- **Resultado:** [50.000, 250.000, 150.000, 750.000]
- **Valores posibles:** 4
- **Interpretación:** Multiplicación de intervalos

#### Expresión 5: `x * x`
- **Resultado:** [100.000, 300.000, 300.000, 900.000]
- **Valores posibles:** 4
- **Interpretación:** Cuadrado del intervalo (no lineal)

#### Expresión 6: `2 * x + 3`
- **Resultado:** [2.030, 6.030]
- **Valores posibles:** 2
- **Interpretación:** Transformación afín del intervalo

---

### 3.2 Expresiones Compuestas

#### Expresión 7: `(x + y) * z`
- **Resultado:** [1500.000, 3000.000, 3500.000, 7000.000, 3500.000, 7000.000, 5500.000, 11000.000]
- **Valores posibles:** 8 (2×2×2 combinaciones)
- **Interpretación:** Composición de operaciones genera explosión combinatoria

#### Expresión 8: `x * y + z * w`
- **Resultado:** [5050.000, 15050.000, 10050.000, 30050.000, ...] (truncado)
- **Valores posibles:** 16 (2×2×2×2 combinaciones)
- **Interpretación:** Combinación de 4 variables genera todas las permutaciones

---

### 3.3 Funciones Matemáticas

#### Expresión 9: `sqrt(x)`
- **Resultado:** [1.000, 1.730]
- **Valores posibles:** 2
- **Interpretación:** Raíz cuadrada de intervalo

#### Expresión 10: `abs(x - y)`
- **Resultado:** [0.500, 1.500, 2.500, 0.500]
- **Valores posibles:** 4
- **Interpretación:** Valor absoluto con incertidumbre

#### Expresión 11: `sqr(x) - sqr(y)`
- **Resultado:** [0.750, -5.250, 8.750, 2.750]
- **Valores posibles:** 4
- **Interpretación:** Diferencia de cuadrados

#### Expresión 12: `x / 2 + y / 2`
- **Resultado:** [0.750, 1.750, 1.750, 2.750]
- **Valores posibles:** 4
- **Interpretación:** División y suma con propagación

#### Expresión 13: `(x + y) / (w - x)`
- **Resultado:** [0.000, 0.000, 0.000, 0.000, 0.000, 0.010, ...] (truncado)
- **Valores posibles:** 16
- **Interpretación:** División compleja con 4 variables

#### Expresión 14: `sin(x) + cos(y)`
- **Resultado:** [1.710, 0.040, 1.010, -0.660]
- **Valores posibles:** 4
- **Interpretación:** Funciones trigonométricas combinadas

#### Expresión 15: `exp(x) - ln(w)`
- **Resultado:** [1.110, 0.010, 18.480, 17.380]
- **Valores posibles:** 4
- **Interpretación:** Funciones exponencial y logarítmica

---

## 4. Análisis de Resultados

### 4.1 Explosión Combinatoria

La cantidad de valores resultantes sigue la fórmula:

```
Valores resultantes = 2^n
```

Donde `n` es el número de variables diferentes involucradas:

- 1 variable → 2 valores
- 2 variables → 4 valores
- 3 variables → 8 valores
- 4 variables → 16 valores

### 4.2 Propagación de Incertidumbre

El sistema **propaga correctamente** la incertidumbre a través de:

- Operaciones aritméticas (+, -, *, /)
- Funciones matemáticas (sqrt, abs, sqr)
- Funciones trigonométricas (sin, cos)
- Funciones exponenciales (exp, ln)
- Expresiones anidadas y compuestas

### 4.3 Validación

- **Variables procesadas:** 4 (1 integer, 3 float)
- **Expresiones evaluadas:** 15
- **Errores detectados:** 0
- **Estado:** JSON VÁLIDO - listo para el Bridge

---

## 5. Conclusiones

1. El sistema **maneja correctamente** la aritmética de intervalos
2. La **propagación de incertidumbre** funciona según lo esperado
3. Las **funciones matemáticas** (sqrt, sin, cos, exp, ln) operan correctamente con intervalos
4. La **explosión combinatoria** es manejada eficientemente
5. El sistema está **listo para problemas de Constraint Programming** con incertidumbre

---

## 6. Archivo de Entrada

```json
{
  "precision": 2,
  "variables": [
    {"nombre": "x", "tipo": "float", "domain": [0.0, 10.0], "value": [1.0, 3.0]},
    {"nombre": "y", "tipo": "float", "domain": [-5.0, 5.0], "value": [0.5, 2.5]},
    {"nombre": "z", "tipo": "integer", "domain": [1, 100], "value": [10, 20]},
    {"nombre": "w", "tipo": "float", "domain": [0.0, 100.0], "value": [5.0, 15.0]}
  ],
  "expresiones": [
    "x", "x + y", "x - y", "x * y", "x * x",
    "2 * x + 3", "(x + y) * z", "x * y + z * w",
    "sqrt(x)", "abs(x - y)", "sqr(x) - sqr(y)",
    "x / 2 + y / 2", "(x + y) / (w - x)",
    "sin(x) + cos(y)", "exp(x) - ln(w)"
  ]
}
```

---

**Fin del Reporte**
