# Reporte de Prueba: Enteros con Incertidumbre
## Bridge GeCode Validator

**Fecha:** 21 de febrero de 2026
**Tipo de Prueba:** Evaluación de expresiones enteras con incertidumbre
**Archivo:** `test_prueba_enteros_incertidumbre.json`

---

## 1. Objetivo

Validar el comportamiento del sistema Bridge GeCode al trabajar con **variables enteras con múltiples valores posibles** y evaluar **15 expresiones** que incluyen:

- Operaciones aritméticas (+, -, *, /)
- Funciones matemáticas (abs, sqr)
- Operadores relacionales (>, <, >=, <=)
- Propagación de incertidumbre con 3, 4 y más valores
- Expresiones compuestas y anidadas

## 2. Configuración de la Prueba

### 2.1 Precisión
- **Decimales:** 0 (enteros puros)
- **Factor de escala:** 1

### 2.2 Variables Definidas

| Variable | Tipo    | Dominio    | Valores Posibles    | Cantidad |
|----------|---------|------------|---------------------|----------|
| x        | integer | [1, 100]   | [10, 20, 30]        | 3        |
| y        | integer | [1, 50]    | [5, 15]             | 2        |
| z        | integer | [0, 200]   | [25, 50, 75, 100]   | 4        |
| a        | integer | [-10, 10]  | [-5, 0, 5]          | 3        |
| b        | integer | [1, 20]    | [2, 4, 8]           | 3        |

Total: **5 variables enteras** con diferentes grados de incertidumbre (2, 3 y 4 valores).

---

## 3. Expresiones Evaluadas y Resultados

### 3.1 Operaciones Básicas

#### Expresión 1: `x`
- **Resultado:** [10, 20, 30] (3 valores)
- **Interpretación:** Variable con 3 estados posibles

#### Expresión 2: `x + y`
- **Resultado:** [15, 25, 25, 35, 35, 45] (6 valores)
- **Combinaciones:** 3 × 2 = 6
- **Rango:** [15, 45]
- **Interpretación:** Suma con duplicados (25 y 35 aparecen 2 veces)

#### Expresión 3: `x - y`
- **Resultado:** [5, -5, 15, 5, 25, 15] (6 valores)
- **Combinaciones:** 3 × 2 = 6
- **Rango:** [-5, 25]
- **Interpretación:** Resta puede producir negativos

#### Expresión 4: `x * y`
- **Resultado:** [50, 150, 100, 300, 150, 450] (6 valores)
- **Combinaciones:** 3 × 2 = 6
- **Rango:** [50, 450]
- **Interpretación:** Multiplicación amplifica rango

---

### 3.2 Expresiones con 3 Variables

#### Expresión 5: `x + y + z`
- **Resultado:** [40, 65, 90, 115, ...] (24 valores, truncado)
- **Combinaciones:** 3 × 2 × 4 = 24
- **Rango esperado:** [10+5+25, 30+15+100] = [40, 145]
- **Interpretación:** Explosión combinatoria con 3 variables

#### Expresión 6: `x * y + z`
- **Resultado:** [75, 100, 125, 150, ...] (24 valores, truncado)
- **Combinaciones:** 3 × 2 × 4 = 24
- **Rango esperado:** [50+25, 450+100] = [75, 550]
- **Interpretación:** Multiplicación + suma

---

### 3.3 Expresiones con Constantes

#### Expresión 7: `x - y * 2`
- **Resultado:** [0, -20, 10, -10, 20, 0] (6 valores)
- **Combinaciones:** 3 × 2 = 6
- **Detalle:**
  - x=10, y=5: 10 - 10 = 0
  - x=10, y=15: 10 - 30 = -20
  - x=20, y=5: 20 - 10 = 10
  - x=20, y=15: 20 - 30 = -10
  - x=30, y=5: 30 - 10 = 20
  - x=30, y=15: 30 - 30 = 0
- **Interpretación:** Precedencia de operadores

---

### 3.4 Expresiones con Variables Negativas

#### Expresión 8: `(x + y) * a`
- **Resultado:** [-75, 0, 75, -125, 0, 125, ...] (18 valores, truncado)
- **Combinaciones:** 3 × 2 × 3 = 18
- **Rango:** [-(30+15)×5, (30+15)×5] = [-225, 225]
- **Interpretación:** Variable negativa (a) produce 3 rangos:
  - a = -5: valores negativos
  - a = 0: todos cero
  - a = 5: valores positivos

#### Expresión 9: `x / 5 + y`
- **Resultado:** [7, 17, 9, 19, 11, 21] (6 valores)
- **Combinaciones:** 3 × 2 = 6
- **Detalle:**
  - x=10, y=5: 2 + 5 = 7
  - x=10, y=15: 2 + 15 = 17
  - x=20, y=5: 4 + 5 = 9
  - x=20, y=15: 4 + 15 = 19
  - x=30, y=5: 6 + 5 = 11
  - x=30, y=15: 6 + 15 = 21
- **Interpretación:** División entera + suma

---

### 3.5 Funciones Matemáticas

#### Expresión 10: `abs(a)`
- **Resultado:** [5, 0, 5] (3 valores)
- **Interpretación:** abs(-5)=5, abs(0)=0, abs(5)=5

#### Expresión 11: `sqr(y)`
- **Resultado:** [25, 225] (2 valores)
- **Interpretación:** sqr(5)=25, sqr(15)=225

---

### 3.6 Operadores Relacionales

#### Expresión 12: `x > y`
- **Resultado:** [true, false, true, true, true, true] (6 valores booleanos)
- **Distribución:** 5 true, 1 false
- **Interpretación:** Solo x=10, y=15 produce false

#### Expresión 13: `z >= 50`
- **Resultado:** [false, true, true, true] (4 valores)
- **Distribución:** 1 false, 3 true
- **Interpretación:** Solo z=25 produce false

#### Expresión 14: `(x + y) <= z`
- **Resultado:** [true, true, true, ...] (24 valores, truncado)
- **Combinaciones:** 3 × 2 × 4 = 24
- **Interpretación:** Comparación compleja con 3 variables

---

### 3.7 Expresión Máxima (5 Variables)

#### Expresión 15: `x * b - y * a`
- **Resultado:** [45, 20, -5, 95, 20, -55, ...] (54 valores, truncado)
- **Combinaciones:** 3 × 3 × 2 × 3 = 54
- **Explosión combinatoria máxima:** 54 combinaciones
- **Interpretación:** Combinación de 5 variables genera máxima incertidumbre

---

## 4. Análisis de Resultados

### 4.1 Explosión Combinatoria

| Expresión | Variables | Valores por variable | Total combinaciones |
|-----------|-----------|----------------------|---------------------|
| 1         | 1 (x)     | 3                    | 3                   |
| 2         | 2 (x,y)   | 3, 2                 | 6                   |
| 5         | 3 (x,y,z) | 3, 2, 4              | 24                  |
| 8         | 3 (x,y,a) | 3, 2, 3              | 18                  |
| 15        | 5 (x,b,y,a) | 3, 3, 2, 3 (indirecto) | 54    |

### 4.2 Propagación de Valores

- **Suma:** Tiende a concentrar valores en el centro
- **Resta:** Puede producir negativos inesperados
- **Multiplicación:** Amplifica rangos dramáticamente
- **División entera:** Reduce rangos (truncamiento)

### 4.3 Funciones Matemáticas

- **abs:** Reduce incertidumbre (valores negativos → positivos)
- **sqr:** Amplifica rangos (cuadrático)

### 4.4 Valores Duplicados

Muchas expresiones producen valores duplicados:
- `x + y`: [15, **25**, **25**, **35**, **35**, 45]
- `x - y`: [**5**, -5, 15, **5**, 25, 15]

Esto refleja que diferentes combinaciones de variables pueden producir el mismo resultado.

### 4.5 Validación

- **Variables procesadas:** 5 (todas enteras)
- **Expresiones evaluadas:** 15
- **Errores detectados:** 0
- **Estado:** JSON VÁLIDO - listo para el Bridge

---

## 5. Comparación de Complejidad

| Tipo de dato | Valores típicos | Complejidad combinatoria | Observaciones |
|--------------|-----------------|--------------------------|---------------|
| Logic        | 2 (true/false)  | 2^n                      | Binario puro  |
| Integer      | 2-4 valores     | Variable (6-54)          | Más flexible  |
| Float        | 2 valores       | 2^n                      | Similar a logic |

---

## 6. Aplicaciones Prácticas

Este tipo de pruebas es útil para:

- **Análisis de sensibilidad:** Evaluar cómo varían resultados ante diferentes entradas
- **Planificación de recursos:** Escenarios con cantidades variables
- **Optimización discreta:** Probar combinaciones de valores enteros
- **Scheduling:** Asignación de tareas con duraciones inciertas
- **Inventario:** Niveles de stock con demanda variable
- **Presupuesto:** Análisis de costos con múltiples escenarios

---

## 7. Conclusiones

1. El sistema **maneja correctamente** enteros con incertidumbre
2. La **explosión combinatoria** puede llegar hasta 54 valores (5 variables)
3. Las **operaciones aritméticas** propagan incertidumbre correctamente
4. Los **valores duplicados** son normales y esperados
5. Las **variables negativas** amplían el espacio de soluciones
6. Los **operadores relacionales** generan resultados booleanos con incertidumbre
7. Es apto para **CSP discretos** y **análisis de escenarios**

---

## 8. Archivo de Entrada

```json
{
  "precision": 0,
  "variables": [
    {"nombre": "x", "tipo": "integer", "domain": [1, 100], "value": [10, 20, 30]},
    {"nombre": "y", "tipo": "integer", "domain": [1, 50], "value": [5, 15]},
    {"nombre": "z", "tipo": "integer", "domain": [0, 200], "value": [25, 50, 75, 100]},
    {"nombre": "a", "tipo": "integer", "domain": [-10, 10], "value": [-5, 0, 5]},
    {"nombre": "b", "tipo": "integer", "domain": [1, 20], "value": [2, 4, 8]}
  ],
  "expresiones": [
    "x", "x + y", "x - y", "x * y",
    "x + y + z", "x * y + z", "x - y * 2",
    "(x + y) * a", "x / 5 + y",
    "abs(a)", "sqr(y)",
    "x > y", "z >= 50", "(x + y) <= z",
    "x * b - y * a"
  ]
}
```

---

**Fin del Reporte**
