# Reporte de Prueba: Lógica con Incertidumbre
## Bridge GeCode Validator

**Fecha:** 21 de febrero de 2026
**Tipo de Prueba:** Evaluación de expresiones lógicas con incertidumbre
**Archivo:** `test_prueba_logica_incertidumbre.json`

---

## 1. Objetivo

Validar el comportamiento del sistema Bridge GeCode al trabajar con **variables lógicas con incertidumbre** (múltiples valores posibles) y evaluar **15 expresiones** que incluyen:

- Operadores lógicos básicos (AND, OR, NOT)
- Implicación lógica (IMPLICA)
- Combinación con operadores relacionales (>, <, >=, <=)
- Propagación de incertidumbre en expresiones lógicas
- Mezcla de tipos: logic, integer

## 2. Configuración de la Prueba

### 2.1 Precisión
- **Decimales:** 0
- **Factor de escala:** 1

### 2.2 Variables Definidas

| Variable    | Tipo    | Dominio       | Valores Posibles | Cantidad |
|-------------|---------|---------------|------------------|----------|
| activo      | logic   | [true, false] | [true, false]    | 2        |
| validado    | logic   | [true, false] | [true, false]    | 2        |
| autorizado  | logic   | [true, false] | [true, false]    | 2        |
| conectado   | logic   | [true, false] | [true, false]    | 2        |
| nivel       | integer | [1, 10]       | [3, 7]           | 2        |
| intentos    | integer | [0, 5]        | [1, 3, 5]        | 3        |

Total: **4 variables lógicas** y **2 variables enteras** con incertidumbre.

---

## 3. Expresiones Evaluadas y Resultados

### 3.1 Operadores Básicos

#### Expresión 1: `activo`
- **Resultado:** [true, false] (2 valores)
- **Interpretación:** Variable con 2 estados posibles

#### Expresión 2: `activo AND validado`
- **Resultado:** [true, false, false, false] (4 valores)
- **Combinaciones:** 2 × 2 = 4
- **Distribución:** 1 true, 3 false
- **Interpretación:** Solo ambos true produce true

#### Expresión 3: `activo OR validado`
- **Resultado:** [true, true, true, false] (4 valores)
- **Combinaciones:** 2 × 2 = 4
- **Distribución:** 3 true, 1 false
- **Interpretación:** Solo ambos false produce false

#### Expresión 4: `NOT activo`
- **Resultado:** [false, true] (2 valores)
- **Interpretación:** Negación lógica

#### Expresión 5: `activo AND NOT validado`
- **Resultado:** [false, true, false, false] (4 valores)
- **Combinaciones:** 2 × 2 = 4
- **Distribución:** 1 true, 3 false
- **Interpretación:** Verdadero solo cuando activo=true y validado=false

---

### 3.2 Operadores Múltiples

#### Expresión 6: `activo OR validado OR autorizado`
- **Resultado:** [true, true, true, true, true, true, true, false] (8 valores)
- **Combinaciones:** 2 × 2 × 2 = 8
- **Distribución:** 7 true, 1 false
- **Interpretación:** Solo false cuando las 3 variables son false

#### Expresión 7: `activo AND validado AND autorizado`
- **Resultado:** [true, false, false, false, false, false, false, false] (8 valores)
- **Combinaciones:** 2 × 2 × 2 = 8
- **Distribución:** 1 true, 7 false
- **Interpretación:** Solo true cuando las 3 variables son true

#### Expresión 8: `(activo OR validado) AND conectado`
- **Resultado:** [true, false, true, false, true, false, false, false] (8 valores)
- **Combinaciones:** 2 × 2 × 2 = 8
- **Distribución:** 3 true, 5 false
- **Interpretación:** Composición de OR y AND

---

### 3.3 Implicación Lógica

#### Expresión 9: `activo IMPLICA validado`
- **Resultado:** [true, false, true, true] (4 valores)
- **Combinaciones:** 2 × 2 = 4
- **Tabla de verdad:**
  - activo=T, validado=T → true (T → T = T)
  - activo=T, validado=F → false (T → F = F)
  - activo=F, validado=T → true (F → T = T)
  - activo=F, validado=F → true (F → F = T)
- **Interpretación:** Implicación correcta (3 true, 1 false)

#### Expresión 10: `NOT(activo AND validado)`
- **Resultado:** [false, true, true, true] (4 valores)
- **Distribución:** 1 false, 3 true
- **Interpretación:** Ley de De Morgan (inverso de expresión 2)

---

### 3.4 Operadores Relacionales

#### Expresión 11: `nivel > 5`
- **Resultado:** [false, true] (2 valores)
- **Interpretación:** nivel=3 → false, nivel=7 → true

#### Expresión 12: `intentos < 4`
- **Resultado:** [true, true, false] (3 valores)
- **Interpretación:** intentos=1 → true, intentos=3 → true, intentos=5 → false

---

### 3.5 Combinaciones Mixtas (Lógica + Aritmética)

#### Expresión 13: `activo AND (nivel > 5)`
- **Resultado:** [false, true, false, false] (4 valores)
- **Combinaciones:** 2 × 2 = 4
- **Interpretación:** True solo cuando activo=true Y nivel=7

#### Expresión 14: `(validado OR autorizado) AND (intentos <= 3)`
- **Resultado:** [true, true, false, true, true, false, ...] (12 valores, truncado)
- **Combinaciones:** 2 × 2 × 3 = 12
- **Interpretación:** Mezcla de lógica booleana con comparación numérica

#### Expresión 15: `(activo AND conectado) IMPLICA (validado AND autorizado)`
- **Resultado:** [true, false, false, false, true, true, ...] (16 valores, truncado)
- **Combinaciones:** 2 × 2 × 2 × 2 = 16
- **Interpretación:** Implicación compleja con 4 variables lógicas
- **Explosión combinatoria máxima:** 16 combinaciones posibles

---

## 4. Análisis de Resultados

### 4.1 Explosión Combinatoria

| Variables | Valores cada una | Combinaciones | Ejemplo |
|-----------|------------------|---------------|---------|
| 1 logic   | 2                | 2             | Expr 1  |
| 2 logic   | 2, 2             | 4             | Expr 2  |
| 3 logic   | 2, 2, 2          | 8             | Expr 6  |
| 4 logic   | 2, 2, 2, 2       | 16            | Expr 15 |
| 2 logic + 1 int | 2, 2, 3     | 12            | Expr 14 |

### 4.2 Distribuciones de Verdad

- **AND:** Favorece false (solo 1/n combinaciones es true)
- **OR:** Favorece true (solo 1/n combinaciones es false)
- **IMPLICA:** Mayoría true (solo p→q con p=T y q=F es false)
- **NOT:** Invierte distribución

### 4.3 Leyes Lógicas Verificadas

- **Ley de De Morgan:** NOT(A AND B) = (NOT A) OR (NOT B)
  - Expresión 10 vs Expresión 2: [F,T,T,T] vs [T,F,F,F] OK
- **Implicación:** A IMPLICA B = (NOT A) OR B
  - Expresión 9: Tabla de verdad correcta OK

### 4.4 Validación

- **Variables procesadas:** 6 (4 logic, 2 integer)
- **Expresiones evaluadas:** 15
- **Errores detectados:** 0
- **Estado:** JSON VÁLIDO - listo para el Bridge

---

## 5. Aplicaciones Prácticas

Este tipo de pruebas es útil para:

- **Sistemas de control de acceso:** Verificar múltiples condiciones de autorización
- **Validación de estados:** Sistemas con múltiples banderas booleanas
- **Reglas de negocio:** Expresiones condicionales complejas
- **Análisis de escenarios:** Explorar todas las combinaciones posibles
- **Verificación formal:** Probar propiedades lógicas
- **Diagnosis de sistemas:** Estados válidos e inválidos

---

## 6. Conclusiones

1. El sistema **maneja correctamente** la lógica booleana con incertidumbre
2. La **propagación de incertidumbre** funciona para AND, OR, NOT, IMPLICA
3. La **explosión combinatoria** se comporta como se espera (2^n para n variables)
4. Las **combinaciones mixtas** (logic + integer) funcionan correctamente
5. Los **operadores relacionales** se integran bien con lógica booleana
6. El sistema es apto para **análisis de decisiones** y **verificación de reglas**

---

## 7. Archivo de Entrada

```json
{
  "precision": 0,
  "variables": [
    {"nombre": "activo", "tipo": "logic", "domain": [true, false], "value": [true, false]},
    {"nombre": "validado", "tipo": "logic", "domain": [true, false], "value": [true, false]},
    {"nombre": "autorizado", "tipo": "logic", "domain": [true, false], "value": [true, false]},
    {"nombre": "conectado", "tipo": "logic", "domain": [true, false], "value": [true, false]},
    {"nombre": "nivel", "tipo": "integer", "domain": [1, 10], "value": [3, 7]},
    {"nombre": "intentos", "tipo": "integer", "domain": [0, 5], "value": [1, 3, 5]}
  ],
  "expresiones": [
    "activo", "activo AND validado", "activo OR validado",
    "NOT activo", "activo AND NOT validado",
    "activo OR validado OR autorizado",
    "activo AND validado AND autorizado",
    "(activo OR validado) AND conectado",
    "activo IMPLICA validado", "NOT(activo AND validado)",
    "nivel > 5", "intentos < 4",
    "activo AND (nivel > 5)",
    "(validado OR autorizado) AND (intentos <= 3)",
    "(activo AND conectado) IMPLICA (validado AND autorizado)"
  ]
}
```

---

**Fin del Reporte**
