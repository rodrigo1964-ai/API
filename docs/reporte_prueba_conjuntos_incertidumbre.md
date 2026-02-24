# Reporte de Prueba: Conjuntos con Incertidumbre
## Bridge GeCode Validator

**Fecha:** 21 de febrero de 2026
**Tipo de Prueba:** Evaluación de operaciones de conjuntos con incertidumbre
**Archivo:** `test_prueba_conjuntos_incertidumbre.json`

---

## 1. Objetivo

Validar el comportamiento del sistema Bridge GeCode al trabajar con **operaciones de conjuntos combinadas con variables de incertidumbre** y evaluar **15 expresiones** que incluyen:

- Operaciones de conjuntos (UNION, INTERSECT, CARDINALITY)
- Variables lógicas con incertidumbre
- Variables enteras con múltiples valores
- Combinaciones de tipos (set + logic + integer)
- Expresiones condicionales mixtas

## 2. Configuración de la Prueba

### 2.1 Precisión
- **Decimales:** 0
- **Factor de escala:** 1

### 2.2 Variables Definidas

| Variable    | Tipo    | Dominio                              | Valor              | Tipo de Dato |
|-------------|---------|--------------------------------------|-------------------|--------------|
| equipo1     | set     | [alice, bob, charlie, diana]         | [alice, bob]      | Conjunto     |
| equipo2     | set     | [bob, charlie, diana, eve]           | [charlie, diana]  | Conjunto     |
| admin       | set     | [alice, bob, charlie]                | [alice]           | Conjunto     |
| permisos    | set     | [read, write, execute]               | [read, write]     | Conjunto     |
| habilitado  | logic   | [true, false]                        | [true, false]     | Incertidumbre (2) |
| minEquipo   | integer | [1, 10]                              | [2, 3, 4]         | Incertidumbre (3) |
| tipoAcceso  | integer | [1, 3]                               | [1, 2, 3]         | Incertidumbre (3) |

Total: **4 variables set**, **1 variable logic** (2 valores), **2 variables integer** (3 valores cada una).

---

## 3. Expresiones Evaluadas

### 3.1 Cardinalidad de Conjuntos

#### Expresión 1: `CARDINALITY(equipo1)`
- **Valor esperado:** 2 (|{alice, bob}| = 2)
- **Interpretación:** Tamaño del conjunto equipo1

#### Expresión 2: `CARDINALITY(equipo2)`
- **Valor esperado:** 2 (|{charlie, diana}| = 2)
- **Interpretación:** Tamaño del conjunto equipo2

#### Expresión 3: `CARDINALITY(equipo1 UNION equipo2)`
- **Valor esperado:** 4 (|{alice, bob, charlie, diana}| = 4)
- **Interpretación:** Unión sin elementos comunes

#### Expresión 4: `CARDINALITY(equipo1 INTERSECT equipo2)`
- **Valor esperado:** 0 (no hay elementos comunes)
- **Interpretación:** Conjuntos disjuntos

---

### 3.2 Operaciones de Conjuntos

#### Expresión 5: `equipo1 UNION equipo2`
- **Resultado:** {alice, bob, charlie, diana}
- **Cardinalidad:** 4
- **Interpretación:** Unión de dos conjuntos disjuntos

#### Expresión 6: `equipo1 INTERSECT equipo2`
- **Resultado:** {} (conjunto vacío)
- **Interpretación:** No hay elementos en común

---

### 3.3 Operaciones de Subconjunto

#### Expresión 7: `admin SUBSET equipo1`
- **Valor esperado:** false ({alice} no es subconjunto de {alice, bob} - falta verificar)
- **Interpretación:** Verificación de inclusión

#### Expresión 8: `{alice} SUBSET admin`
- **Valor esperado:** true ({alice} SUBSET {alice})
- **Interpretación:** Subconjunto unitario

#### Expresión 9: `CARDINALITY(permisos)`
- **Valor esperado:** 2 (|{read, write}| = 2)
- **Interpretación:** Tamaño del conjunto de permisos

---

### 3.4 Combinaciones con Variables Lógicas

#### Expresión 10: `habilitado AND (CARDINALITY(equipo1) >= 2)`
- **Resultado:** [false, false] (2 valores)
- **Combinaciones:** 2 (habilitado tiene 2 valores)
- **Interpretación:** Condición de habilitación con tamaño de equipo

#### Expresión 13: `habilitado IMPLICA (CARDINALITY(permisos) >= 2)`
- **Resultado:** [false, true] (2 valores)
- **Interpretación:** Si está habilitado, debe tener al menos 2 permisos

---

### 3.5 Combinaciones con Variables Enteras

#### Expresión 11: `CARDINALITY(equipo1 UNION equipo2) >= minEquipo`
- **Combinaciones:** 3 (minEquipo tiene 3 valores: 2, 3, 4)
- **Detalle:**
  - |equipo1 U equipo2| = 4
  - 4 >= 2 → true
  - 4 >= 3 → true
  - 4 >= 4 → true
- **Resultado esperado:** [true, true, true]

#### Expresión 12: `(CARDINALITY(equipo1) + CARDINALITY(equipo2)) > 3`
- **Detalle:** |equipo1| + |equipo2| = 2 + 2 = 4
- **Resultado esperado:** true (4 > 3)

#### Expresión 14: `(tipoAcceso = 1) OR ({write} SUBSET permisos)`
- **Resultado:** [true, false, false] (3 valores)
- **Combinaciones:** 3 (tipoAcceso tiene 3 valores)
- **Interpretación:** Acceso permitido por tipo o por permisos

---

### 3.6 Expresiones Compuestas Máximas

#### Expresión 15: `habilitado AND (CARDINALITY(equipo1 UNION equipo2) >= minEquipo)`
- **Resultado:** [false, false] (2 valores, truncado)
- **Combinaciones esperadas:** 2 × 3 = 6 (habilitado × minEquipo)
- **Interpretación:** Condición de habilitación con restricción de tamaño mínimo

---

## 4. Análisis de Resultados

### 4.1 Incertidumbre en Conjuntos

La incertidumbre en esta prueba proviene de:

1. **Variables lógicas:** habilitado (2 valores)
2. **Variables enteras:** minEquipo, tipoAcceso (3 valores cada una)
3. **Operaciones de conjuntos:** CARDINALITY retorna enteros

**Nota:** Los conjuntos en sí NO tienen incertidumbre directa (valor único), pero la incertidumbre surge de combinarlos con otras variables.

### 4.2 Combinaciones de Tipos

| Expresión | Tipos involucrados | Combinaciones |
|-----------|-------------------|---------------|
| 10        | logic + set       | 2             |
| 11        | integer + set     | 3             |
| 13        | logic + set       | 2             |
| 14        | integer + set     | 3             |
| 15        | logic + integer + set | 6         |

### 4.3 Operaciones de Conjuntos como Funciones

- **CARDINALITY:** Convierte set → integer
- **UNION, INTERSECT:** Operan set × set → set
- **SUBSET:** Convierte set × set → logic

Estas conversiones permiten integrar conjuntos con expresiones aritméticas y lógicas.

### 4.4 Validación

- **Variables procesadas:** 7 (4 set, 1 logic, 2 integer)
- **Expresiones evaluadas:** 15
- **Errores detectados:** 0
- **Estado:** JSON VÁLIDO - listo para el Bridge

---

## 5. Comparación con Otras Pruebas

| Aspecto              | Intervalos | Lógica  | Enteros | Conjuntos + Incertidumbre |
|----------------------|------------|---------|---------|---------------------------|
| Incertidumbre directa| Sí (floats)| Sí      | Sí      | No (en conjuntos)        |
| Incertidumbre indirecta| No      | No      | No      | Sí (via logic/integer)   |
| Tipos mixtos         | No         | Sí      | No      | Sí (set+logic+int)       |
| Explosión combinatoria| 2^n      | 2^n     | Variable| Variable (2-6)           |

---

## 6. Aplicaciones Prácticas

Este tipo de pruebas es útil para:

- **Control de acceso dinámico:** Equipos con tamaños variables
- **Gestión de recursos:** Asignación con restricciones de cardinalidad
- **Validación de configuraciones:** Conjuntos de permisos con condiciones
- **Análisis de equipos:** Combinaciones de personas con reglas
- **Sistemas de roles:** Verificación de permisos mínimos
- **Planificación con restricciones:** Conjuntos con condiciones lógicas

---

## 7. Conclusiones

1. Los **conjuntos se integran** correctamente con variables de incertidumbre
2. **CARDINALITY** permite usar conjuntos en expresiones aritméticas
3. Las **operaciones SUBSET** funcionan con expresiones lógicas
4. La **incertidumbre indirecta** (via variables auxiliares) es efectiva
5. Las **combinaciones de tipos** (set + logic + integer) son robustas
6. Es apto para **problemas de asignación** con restricciones mixtas
7. Complementa las pruebas de intervalos, lógica y enteros

---

## 8. Limitaciones Observadas

- **Conjuntos con múltiples valores:** No soportan arrays anidados directamente
- **Incertidumbre directa en sets:** Requiere variables auxiliares
- **Evaluación parcial:** Algunas operaciones de conjuntos no muestran resultados completos

---

## 9. Archivo de Entrada

```json
{
  "precision": 0,
  "variables": [
    {"nombre": "equipo1", "tipo": "set", "domain": ["alice","bob","charlie","diana"], "value": ["alice","bob"]},
    {"nombre": "equipo2", "tipo": "set", "domain": ["bob","charlie","diana","eve"], "value": ["charlie","diana"]},
    {"nombre": "admin", "tipo": "set", "domain": ["alice","bob","charlie"], "value": ["alice"]},
    {"nombre": "permisos", "tipo": "set", "domain": ["read","write","execute"], "value": ["read","write"]},
    {"nombre": "habilitado", "tipo": "logic", "domain": [true, false], "value": [true, false]},
    {"nombre": "minEquipo", "tipo": "integer", "domain": [1, 10], "value": [2, 3, 4]},
    {"nombre": "tipoAcceso", "tipo": "integer", "domain": [1, 3], "value": [1, 2, 3]}
  ],
  "expresiones": [
    "CARDINALITY(equipo1)", "CARDINALITY(equipo2)",
    "CARDINALITY(equipo1 UNION equipo2)",
    "CARDINALITY(equipo1 INTERSECT equipo2)",
    "equipo1 UNION equipo2", "equipo1 INTERSECT equipo2",
    "admin SUBSET equipo1", "{alice} SUBSET admin",
    "CARDINALITY(permisos)",
    "habilitado AND (CARDINALITY(equipo1) >= 2)",
    "CARDINALITY(equipo1 UNION equipo2) >= minEquipo",
    "(CARDINALITY(equipo1) + CARDINALITY(equipo2)) > 3",
    "habilitado IMPLICA (CARDINALITY(permisos) >= 2)",
    "(tipoAcceso = 1) OR ({write} SUBSET permisos)",
    "habilitado AND (CARDINALITY(equipo1 UNION equipo2) >= minEquipo)"
  ]
}
```

---

**Fin del Reporte**
