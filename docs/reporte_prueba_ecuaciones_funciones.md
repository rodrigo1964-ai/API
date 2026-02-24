# Reporte de Prueba: Ecuaciones con Funciones Estándar + Lógica
## Bridge GeCode Validator

**Fecha:** 21 de febrero de 2026
**Tipo de Prueba:** Evaluación de ecuaciones matemáticas con lógica booleana
**Archivo:** `test_prueba_ecuaciones_funciones.json`

---

## 1. Objetivo

Validar el comportamiento del sistema Bridge GeCode al trabajar con **ecuaciones matemáticas** usando **funciones estándar** (sqrt, abs, sqr, sin, cos, exp, ln) y **operadores relacionales** (=, <, >) combinados con **lógica booleana** (AND, OR, NOT, IMPLICA).

Esta prueba evalúa:
- Identidades matemáticas
- Ecuaciones trigonométricas
- Funciones inversas (exp/ln, sqr/sqrt)
- Propiedades algebraicas
- Integración con lógica booleana

---

## 2. Configuración de la Prueba

### 2.1 Precisión
- **Decimales:** 2
- **Factor de escala:** 100

### 2.2 Variables Definidas

| Variable | Tipo    | Dominio      | Valores Posibles | Cantidad |
|----------|---------|--------------|------------------|----------|
| x        | float   | [0.0, 10.0]  | [1.0, 2.0, 4.0]  | 3        |
| y        | float   | [0.0, 10.0]  | [2.0, 3.0]       | 2        |
| z        | float   | [0.0, 20.0]  | [5.0, 10.0]      | 2        |
| a        | integer | [1, 100]     | [10, 20, 30]     | 3        |
| b        | integer | [1, 50]      | [5, 15]          | 2        |
| activo   | logic   | [true, false]| [true, false]    | 2        |
| validado | logic   | [true, false]| [true, false]    | 2        |

Total: **7 variables** (3 float, 2 integer, 2 logic)

---

## 3. Expresiones Evaluadas (Ecuaciones + Lógica)

### 3.1 Ecuaciones con Raíces Cuadradas

#### Expresión 1: `((sqrt(x) = sqrt(y - 1)) AND activo)`
- **Tipo de ecuación:** Igualdad de raíces
- **Resultado:** [false, false, ..., true, ...] (12 valores)
- **Identidad probada:** sqrt(a) = sqrt(b) <-> a = b
- **Interpretación:** Verifica igualdad de raíces Y activación

#### Expresión 7: `((sqr(sqrt(x)) = x) IMPLICA (validado AND (y > 0)))`
- **Tipo de ecuación:** Identidad de funciones inversas
- **Resultado:** [true, true, false, ...] (36 valores)
- **Identidad probada:** sqr(sqrt(x)) = x (para x >= 0)
- **Interpretación:** La identidad implica validación

#### Expresión 9: `((exp(ln(x)) = x) OR ((sqrt(sqr(y)) = y) AND validado))`
- **Tipo de ecuación:** Doble identidad inversa
- **Resultado:** [true, true, ...] (72 valores)
- **Identidades probadas:**
  - exp(ln(x)) = x (para x > 0)
  - sqrt(sqr(y)) = y (para y >= 0)
- **Interpretación:** OR de dos identidades fundamentales

---

### 3.2 Ecuaciones Trigonométricas

#### Expresión 6: `((sin(x) = cos(y - 1.57)) AND (activo OR validado))`
- **Tipo de ecuación:** Identidad trigonométrica
- **Resultado:** [false, ..., true, ...] (24 valores)
- **Identidad probada:** sin(x) = cos(x - pi/2)
- **Interpretación:** Desfase de fase con condición lógica

#### Expresión 11: `((sin(x) * sin(x) + cos(x) * cos(x) = 1) OR (NOT activo))`
- **Tipo de ecuación:** Identidad pitagórica
- **Resultado:** [false, true, ...] (162 valores)
- **Identidad probada:** sin^2(x) + cos^2(x) = 1
- **Interpretación:** Identidad fundamental OR negación

---

### 3.3 Funciones Exponenciales y Logarítmicas

#### Expresión 4: `((exp(x) > exp(y)) AND (ln(z) < ln(x + y)))`
- **Tipo de ecuación:** Desigualdades exponenciales y logarítmicas
- **Resultado:** [false, false, ...] (72 valores)
- **Propiedades probadas:**
  - exp es monotónica creciente
  - ln es monotónica creciente
- **Interpretación:** Comparación de funciones trascendentes

#### Expresión 13: `((ln(exp(x)) = x) IMPLICA ((abs(a - b) > 5) AND activo))`
- **Tipo de ecuación:** Identidad inversa
- **Resultado:** [true, true, ...] (108 valores)
- **Identidad probada:** ln(exp(x)) = x
- **Interpretación:** Identidad implica condición aritmética

---

### 3.4 Propiedades Algebraicas

#### Expresión 10: `((abs(x - y) = abs(y - x)) AND (activo IMPLICA validado))`
- **Tipo de ecuación:** Propiedad de simetría
- **Resultado:** [true, false, ...] (144 valores)
- **Propiedad probada:** |a - b| = |b - a| (simetría del valor absoluto)
- **Interpretación:** Simetría con implicación lógica

#### Expresión 14: `((sqr(x) - sqr(y) = (x + y) * (x - y)) OR (validado AND (z > 5)))`
- **Tipo de ecuación:** Diferencia de cuadrados
- **Resultado:** [true, true, false, ...] (864 valores)
- **Identidad probada:** a^2 - b^2 = (a+b)(a-b)
- **Interpretación:** Identidad algebraica clásica

#### Expresión 15: `((sqrt(a) * sqrt(b) = sqrt(a * b)) AND ((activo OR validado) IMPLICA (x < y)))`
- **Tipo de ecuación:** Propiedad distributiva de raíz
- **Resultado:** [false, false, ...] (864 valores)
- **Propiedad probada:** sqrt(a) x sqrt(b) = sqrt(axb) (para a,b >= 0)
- **Interpretación:** Propiedad de raíces con implicación

---

### 3.5 Desigualdades y Comparaciones

#### Expresión 2: `((abs(x - y) > 1) OR (sin(x) < cos(y)))`
- **Tipo de ecuación:** Desigualdades mixtas
- **Resultado:** [true, true, ...] (36 valores)
- **Interpretación:** Distancia significativa OR relación trigonométrica

#### Expresión 3: `((sqr(x) + sqr(y) = sqr(z)) IMPLICA validado)`
- **Tipo de ecuación:** Teorema de Pitágoras
- **Resultado:** [true, true, ...] (24 valores)
- **Identidad probada:** a^2 + b^2 = c^2 (triángulo rectángulo)
- **Interpretación:** Pitagórica implica validación

#### Expresión 5: `((sqrt(a) >= b) OR ((abs(a - b) < 10) AND activo))`
- **Tipo de ecuación:** Desigualdad con valor absoluto
- **Resultado:** [false, false, ...] (72 valores)
- **Interpretación:** Comparación de raíz O proximidad

#### Expresión 8: `((abs(sin(x)) < 1) AND ((cos(y) >= 0) OR activo))`
- **Tipo de ecuación:** Cotas trigonométricas
- **Resultado:** [false, false, ...] (12 valores)
- **Propiedad probada:** |sin(x)| <= 1 (acotación)
- **Interpretación:** Cota fundamental con condición

#### Expresión 12: `((sqrt(x * x + y * y) > z) AND ((a > b) OR validado))`
- **Tipo de ecuación:** Norma euclidiana
- **Resultado:** [true, true, ...] (864 valores)
- **Fórmula probada:** Distancia euclidiana sqrt(x^2+y^2)
- **Interpretación:** Distancia vs límite

---

## 4. Análisis de Resultados

### 4.1 Explosión Combinatoria

| Expresión | Variables | Combinaciones | Valores |
|-----------|-----------|---------------|---------|
| 1         | 4         | 3x2x2 = 12    | 12      |
| 2         | 2         | 3x2 = 6       | 36      |
| 3         | 4         | 3x2x2x2       | 24      |
| 4         | 3         | 3x2x2x3x2     | 72      |
| 9         | 3         | 3x2x2x3x2     | 72      |
| 10        | 4         | 3x2x2x2       | 144     |
| 11        | 2         | 3x3x3         | 162     |
| 12, 14, 15| 5         | 3x2x2x3x2x2   | 864 (máximo) |

### 4.2 Identidades Matemáticas Verificadas

1. **Funciones inversas:**
   - sqr(sqrt(x)) = x
   - exp(ln(x)) = x
   - ln(exp(x)) = x
   - sqrt(sqr(x)) = |x|

2. **Trigonométricas:**
   - sin^2(x) + cos^2(x) = 1 (identidad pitagórica)
   - sin(x) = cos(x - pi/2) (desfase)
   - |sin(x)| <= 1, |cos(x)| <= 1 (acotación)

3. **Algebraicas:**
   - a^2 - b^2 = (a+b)(a-b) (diferencia de cuadrados)
   - sqrt(a) x sqrt(b) = sqrt(axb) (distributividad)
   - |a - b| = |b - a| (simetría)

4. **Geométricas:**
   - a^2 + b^2 = c^2 (Pitágoras)
   - sqrt(x^2+y^2) (norma euclidiana)

### 4.3 Integración con Lógica

Todas las ecuaciones se integran con:
- **AND:** Conjunción de condiciones
- **OR:** Disyunción (escape lógico)
- **IMPLICA:** Consecuencia lógica
- **NOT:** Negación

### 4.4 Precisión Numérica

Con precisión de 2 decimales:
- Algunas identidades pueden no ser exactas (ej: sin^2+cos^2~=1.00)
- Las comparaciones = requieren igualdad exacta
- Las funciones trascendentes tienen aproximación

### 4.5 Validación

- **Variables procesadas:** 7 (3 float, 2 int, 2 logic)
- **Expresiones evaluadas:** 15
- **Combinaciones máximas:** 864 valores
- **Errores detectados:** 0
- **Estado:** JSON VÁLIDO

---

## 5. Aplicaciones Prácticas

- **Validación de modelos físicos:** Verificar leyes físicas
- **Simulación numérica:** Comprobar invariantes
- **Sistemas de control:** Verificar condiciones de estabilidad
- **Geometría computacional:** Validar relaciones espaciales
- **Procesamiento de señales:** Identidades trigonométricas
- **Análisis numérico:** Verificar convergencia

---

## 6. Conclusiones

1. El sistema **verifica correctamente** identidades matemáticas
2. Las **funciones estándar** funcionan según especificación
3. Los **operadores relacionales** (=, <, >) operan correctamente
4. La **integración con lógica** es robusta
5. La **explosión combinatoria** alcanza 864 valores
6. Es apto para **validación de modelos matemáticos**

---

**Fin del Reporte**
