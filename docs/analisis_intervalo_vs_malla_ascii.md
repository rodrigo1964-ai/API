# Analisis: Intervalos vs Malla Discreta

## Filosofia: Reales en Conjuntos Discretos

Este documento demuestra por que representamos los reales como **conjuntos discretos finitos** (malla) en lugar de usar intervalos continuos.

## Experimento

Evaluamos 5 expresiones con:
- **Dominio**: x pertenece a [1.0, 2.0]
- **Malla discreta**: 11 puntos {1.0, 1.1, 1.2, ..., 2.0}
- **Solo intervalo**: 2 puntos (endpoints) {1.0, 2.0}

## Resultados

### Expresion 1: `x`
**Malla**: [1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0] (11 valores)

**Intervalo**: [1.0, 2.0] (2 valores)

**Conclusion**: Malla captura todos los puntos discretos del dominio

---

### Expresion 2: `x * x`
**Malla**: 121 valores (producto cartesiano 11 x 11)
- Incluye: 1.0^2, 1.1^2, 1.2^2, ..., 2.0^2
- Captura valores intermedios como 1.21, 1.44, 1.69, etc.

**Intervalo**: 4 valores (producto cartesiano 2 x 2)
- Solo: 1.0^2, 2.0^2 = {1.0, 4.0}
- Duplicados por producto cartesiano

**Conclusion**: Intervalo pierde toda la informacion intermedia

---

### Expresion 3: `x * x - x`
**Malla**: 1331 valores
- Rango aproximado: [98.1, 399.0]
- Captura toda la curvatura de la parabola

**Intervalo**: 8 valores
- Solo extremos: {99.0, 98.0, 199.0, 198.0, 399.0, 398.0}

**Conclusion**: Intervalo pierde la estructura del conjunto solucion

---

### Expresion 4: `2 * x + 3`
**Malla**: [2.03, 2.23, 2.43, 2.63, 2.83, 3.03, 3.23, 3.43, 3.63, 3.83, 4.03] (11 valores)

**Intervalo**: [2.03, 4.03] (2 valores)

**Conclusion**: Malla captura la discretizacion completa de la transformacion lineal

---

### Expresion 5: `(x - 1.5) * (x - 1.5)` = (x - 1.5)^2

**CASO CRITICO** - Demuestra el problema fundamental del wrapping/hull:

**Malla**: [25.0, 20.0, 15.0, 10.0, 5.0, **0.0**, -5.0, -10.0, -15.0, -20.0, 25.0] (121 valores)
- Captura el **minimo real en x = 1.5 -> resultado = 0.0**
- Muestra la forma parabolica completa

**Intervalo**: [25.0, -25.0, -25.0, 25.0] (4 valores)
- **NO captura el minimo de 0.0**
- Solo evalua en x = 1.0 y x = 2.0
- Pierde completamente el punto critico x = 1.5

## Conclusiones Fundamentales

### 1. No Convexidad
La funcion (x-1.5)^2 tiene un minimo en x=1.5. El conjunto solucion cerca del minimo es:
```
{(1.5, 0.0), (1.4, 0.01), (1.6, 0.01), (1.3, 0.04), ...}
```

Este conjunto **NO es convexo** en el espacio (x, f(x)). Un hull o hipercaja que lo contenga incluira puntos que **NO verifican la ecuacion**.

### 2. Wrapping/Hull Problem
Si usamos aritmetica de intervalos pura:
- x pertenece a [1.0, 2.0]
- (x - 1.5)^2 pertenece a [0, 0.25] (teorico correcto)

Pero evaluando solo los endpoints:
- (1.0 - 1.5)^2 = 0.25
- (2.0 - 1.5)^2 = 0.25
- **Perdemos completamente el minimo de 0.0**

El **hull** o **hipercaja** seria [0, 0.25], pero con solo endpoints **NO detectamos que 0.0 es alcanzable**.

### 3. Dependency Problem
En la expresion `(x - 1.5) * (x - 1.5)`, la variable `x` aparece dos veces. En aritmetica de intervalos estandar:
```
[1, 2] - 1.5 = [-0.5, 0.5]
[-0.5, 0.5] * [-0.5, 0.5] = [-0.25, 0.25]  <- INCORRECTO
```

El resultado correcto es [0, 0.25], pero la aritmetica de intervalos da [-0.25, 0.25] por el **dependency problem**.

### 4. Solucion: Discretizacion en Malla

Con la malla discreta:
- Evaluamos **exactamente** en cada punto
- No hay wrapping ni sobreestimacion
- No hay dependency problem (cada evaluacion usa valores concretos)
- Capturamos puntos criticos (minimos, maximos)
- Representamos conjuntos **no convexos** exactamente
- Operaciones **cerradas** en el conjunto discreto

## Representacion Computacional

```
CONTINUO (Teorico)          DISCRETO (Implementado)
-------------------         -----------------------
x pertenece a R             x pertenece a {x1, x2, ..., xn}
Infinitos puntos            n puntos finitos
Aritmetica de intervalos    Evaluacion exacta
Hull/wrapping               Sin aproximacion
Dependency problems         Sin dependencias
```

## Precision y Factor

Con `precision = 2` y `factor = 100`:
- Internamente: enteros {100, 110, 120, ..., 200}
- Externamente: reales {1.00, 1.10, 1.20, ..., 2.00}
- **Aritmetica exacta de enteros**, visualizacion como reales

## Ventajas de la Malla Discreta

1. **Exactitud**: Evaluacion exacta en cada punto de la malla
2. **No Convexidad**: Representa conjuntos no convexos sin aproximacion
3. **Puntos Criticos**: Captura minimos, maximos, inflexiones si estan en la malla
4. **Sin Wrapping**: No hay sobreestimacion por efecto hull
5. **Sin Dependency**: Cada evaluacion usa valores concretos
6. **Composabilidad**: Las operaciones estan cerradas en el conjunto discreto

## Costo Computacional

- **Intervalo**: O(2) evaluaciones (solo endpoints)
- **Malla n puntos**: O(n) evaluaciones por variable
- **k variables**: O(n^k) producto cartesiano

**Trade-off**: Mas computo, pero resultados **exactos** y **completos** en la discretizacion.

## Aplicacion: Constraint Programming

Esta filosofia es fundamental para:
- **Propagacion de restricciones**: Los dominios son conjuntos discretos
- **Pruning**: Eliminar valores que violan restricciones
- **Busqueda**: Explorar combinaciones validas
- **Soluciones exactas**: Sin aproximaciones ni falsos positivos del hull

---

**Conclusion**: Los reales se representan como **conjuntos discretos finitos** (malla) para evitar los problemas fundamentales de la aritmetica de intervalos: wrapping, dependency, y perdida de no convexidad. Sacrificamos eficiencia en tiempo por **exactitud y completitud** en la discretizacion elegida.
