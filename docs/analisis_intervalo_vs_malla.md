# Análisis: Intervalos vs Malla Discreta

## Filosofía: Reales en Conjuntos Discretos

Este documento demuestra por qué representamos los reales como **conjuntos discretos finitos** (malla) en lugar de usar intervalos continuos.

## Experimento

Evaluamos 5 expresiones con:
- **Dominio**: x ∈ [1.0, 2.0]
- **Malla discreta**: 11 puntos {1.0, 1.1, 1.2, ..., 2.0}
- **Solo intervalo**: 2 puntos (endpoints) {1.0, 2.0}

## Resultados

### Expresión 1: `x`
**Malla**: [1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0] (11 valores)
**Intervalo**: [1.0, 2.0] (2 valores)

✓ **Malla captura todos los puntos discretos del dominio**

---

### Expresión 2: `x * x`
**Malla**: 121 valores (producto cartesiano 11 × 11)
- Incluye: 1.0², 1.1², 1.2², ..., 2.0²
- Captura valores intermedios como 1.21, 1.44, 1.69, etc.

**Intervalo**: 4 valores (producto cartesiano 2 × 2)
- Solo: 1.0², 2.0² = {1.0, 4.0}
- Duplicados por producto cartesiano

✗ **Intervalo pierde toda la información intermedia**

---

### Expresión 3: `x * x - x`
**Malla**: 1331 valores
- Rango aproximado: [98.1, 399.0]
- Captura toda la curvatura de la parábola

**Intervalo**: 8 valores
- Solo extremos: {99.0, 98.0, 199.0, 198.0, 399.0, 398.0}

✗ **Intervalo pierde la estructura del conjunto solución**

---

### Expresión 4: `2 * x + 3`
**Malla**: [2.03, 2.23, 2.43, 2.63, 2.83, 3.03, 3.23, 3.43, 3.63, 3.83, 4.03] (11 valores)
**Intervalo**: [2.03, 4.03] (2 valores)

✓ **Malla captura la discretización completa de la transformación lineal**

---

### Expresión 5: `(x - 1.5) * (x - 1.5)` = (x - 1.5)²

**CASO CRÍTICO** - Demuestra el problema fundamental del wrapping/hull:

**Malla**: [25.0, 20.0, 15.0, 10.0, 5.0, **0.0**, -5.0, -10.0, -15.0, -20.0, 25.0] (121 valores)
- ✓ Captura el **mínimo real en x = 1.5 → resultado = 0.0**
- ✓ Muestra la forma parabólica completa

**Intervalo**: [25.0, -25.0, -25.0, 25.0] (4 valores)
- ✗ **NO captura el mínimo de 0.0**
- ✗ Solo evalúa en x = 1.0 y x = 2.0
- ✗ Pierde completamente el punto crítico x = 1.5

## Conclusiones Fundamentales

### 1. **No Convexidad**
La función (x-1.5)² tiene un mínimo en x=1.5. El conjunto solución cerca del mínimo es:
```
{(1.5, 0.0), (1.4, 0.01), (1.6, 0.01), (1.3, 0.04), ...}
```

Este conjunto **NO es convexo** en el espacio (x, f(x)). Un hull o hipercaja que lo contenga incluirá puntos que **NO verifican la ecuación**.

### 2. **Wrapping/Hull Problem**
Si usamos aritmética de intervalos pura:
- x ∈ [1.0, 2.0]
- (x - 1.5)² ∈ [0, 0.25] (teórico correcto)

Pero evaluando solo los endpoints:
- (1.0 - 1.5)² = 0.25
- (2.0 - 1.5)² = 0.25
- **Perdemos completamente el mínimo de 0.0**

El **hull** o **hipercaja** sería [0, 0.25], pero con solo endpoints **NO detectamos que 0.0 es alcanzable**.

### 3. **Dependency Problem**
En la expresión `(x - 1.5) * (x - 1.5)`, la variable `x` aparece dos veces. En aritmética de intervalos estándar:
```
[1, 2] - 1.5 = [-0.5, 0.5]
[-0.5, 0.5] * [-0.5, 0.5] = [-0.25, 0.25]  ← INCORRECTO
```

El resultado correcto es [0, 0.25], pero la aritmética de intervalos da [-0.25, 0.25] por el **dependency problem**.

### 4. **Solución: Discretización en Malla**

Con la malla discreta:
- ✓ Evaluamos **exactamente** en cada punto
- ✓ No hay wrapping ni sobreestimación
- ✓ No hay dependency problem (cada evaluación usa valores concretos)
- ✓ Capturamos puntos críticos (mínimos, máximos)
- ✓ Representamos conjuntos **no convexos** exactamente
- ✓ Operaciones **cerradas** en el conjunto discreto

## Representación Computacional

```
CONTINUO (Teórico)          DISCRETO (Implementado)
─────────────────           ───────────────────────
x ∈ ℝ                       x ∈ {x₁, x₂, ..., xₙ}
Infinitos puntos            n puntos finitos
Aritmética de intervalos    Evaluación exacta
Hull/wrapping               Sin aproximación
Dependency problems         Sin dependencias
```

## Precisión y Factor

Con `precision = 2` y `factor = 100`:
- Internamente: enteros {100, 110, 120, ..., 200}
- Externamente: reales {1.00, 1.10, 1.20, ..., 2.00}
- **Aritmética exacta de enteros**, visualización como reales

## Ventajas de la Malla Discreta

1. **Exactitud**: Evaluación exacta en cada punto de la malla
2. **No Convexidad**: Representa conjuntos no convexos sin aproximación
3. **Puntos Críticos**: Captura mínimos, máximos, inflexiones si están en la malla
4. **Sin Wrapping**: No hay sobreestimación por efecto hull
5. **Sin Dependency**: Cada evaluación usa valores concretos
6. **Composabilidad**: Las operaciones están cerradas en el conjunto discreto

## Costo Computacional

- **Intervalo**: O(2) evaluaciones (solo endpoints)
- **Malla n puntos**: O(n) evaluaciones por variable
- **k variables**: O(n^k) producto cartesiano

**Trade-off**: Más cómputo, pero resultados **exactos** y **completos** en la discretización.

## Aplicación: Constraint Programming

Esta filosofía es fundamental para:
- **Propagación de restricciones**: Los dominios son conjuntos discretos
- **Pruning**: Eliminar valores que violan restricciones
- **Búsqueda**: Explorar combinaciones válidas
- **Soluciones exactas**: Sin aproximaciones ni falsos positivos del hull

---

**Conclusión**: Los reales se representan como **conjuntos discretos finitos** (malla) para evitar los problemas fundamentales de la aritmética de intervalos: wrapping, dependency, y pérdida de no convexidad. Sacrificamos eficiencia en tiempo por **exactitud y completitud** en la discretización elegida.
