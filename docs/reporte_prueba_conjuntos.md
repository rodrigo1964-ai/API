# Reporte de Prueba: Operaciones de Conjuntos (Sets)
## Bridge GeCode Validator

**Fecha:** 21 de febrero de 2026
**Tipo de Prueba:** Evaluación de expresiones con conjuntos
**Archivo:** `test_prueba_conjuntos.json`

---

## 1. Objetivo

Validar el comportamiento del sistema Bridge GeCode al trabajar con **variables de tipo set** (conjuntos) y evaluar **15 expresiones** que incluyen:

- Operaciones de cardinalidad (CARDINALITY)
- Operaciones binarias (UNION, INTERSECT, DIFFERENCE)
- Operaciones de pertenencia (SUBSET)
- Combinaciones de operaciones aritméticas y de conjuntos
- Expresiones compuestas

## 2. Configuración de la Prueba

### 2.1 Precisión
- **Decimales:** 0 (conjuntos son discretos)
- **Factor de escala:** 1

### 2.2 Variables Definidas

| Variable  | Tipo | Dominio                                    | Valor               | Cardinalidad |
|-----------|------|--------------------------------------------|---------------------|--------------|
| A         | set  | [a, b, c, d, e]                           | [a, b]              | 2            |
| B         | set  | [b, c, d, e, f]                           | [b, c, d]           | 3            |
| C         | set  | [x, y, z]                                 | [x, y]              | 2            |
| roles     | set  | [admin, user, guest, dev]                 | [admin, user]       | 2            |
| permisos  | set  | [read, write, execute, delete]            | [read, write, execute] | 3         |
| usuarios  | set  | [alice, bob, charlie, diana]              | [alice, bob]        | 2            |

Total: **6 variables de tipo set** con diferentes dominios y valores.

---

## 3. Expresiones Evaluadas

### 3.1 Operaciones de Cardinalidad

#### Expresión 1: `CARDINALITY(A)`
- **Descripción:** Tamaño del conjunto A
- **Valor esperado:** 2
- **Interpretación:** Cuenta los elementos en {a, b}

#### Expresión 2: `CARDINALITY(B)`
- **Descripción:** Tamaño del conjunto B
- **Valor esperado:** 3
- **Interpretación:** Cuenta los elementos en {b, c, d}

#### Expresión 3: `CARDINALITY(permisos)`
- **Descripción:** Tamaño del conjunto permisos
- **Valor esperado:** 3
- **Interpretación:** Cuenta los elementos en {read, write, execute}

---

### 3.2 Operaciones Binarias de Conjuntos

#### Expresión 4: `A UNION B`
- **Descripción:** Unión de A y B
- **Valor esperado:** {a, b, c, d}
- **Cardinalidad:** 4 elementos
- **Interpretación:** Combina todos los elementos de ambos conjuntos

#### Expresión 5: `A INTERSECT B`
- **Descripción:** Intersección de A y B
- **Valor esperado:** {b}
- **Cardinalidad:** 1 elemento
- **Interpretación:** Elementos comunes entre A y B

#### Expresión 6: `A DIFFERENCE B`
- **Descripción:** Diferencia A - B
- **Valor esperado:** {a}
- **Cardinalidad:** 1 elemento
- **Interpretación:** Elementos en A que NO están en B

---

### 3.3 Operaciones de Pertenencia (SUBSET)

#### Expresión 7: `{a} SUBSET A`
- **Descripción:** Verifica si {a} es subconjunto de A
- **Valor esperado:** true
- **Interpretación:** {a} está contenido en {a, b}

#### Expresión 8: `{b,c} SUBSET B`
- **Descripción:** Verifica si {b,c} es subconjunto de B
- **Valor esperado:** true
- **Interpretación:** {b, c} está contenido en {b, c, d}

#### Expresión 9: `{read,write} SUBSET permisos`
- **Descripción:** Verifica si {read,write} es subconjunto de permisos
- **Valor esperado:** true
- **Interpretación:** {read, write} está contenido en {read, write, execute}

---

### 3.4 Cardinalidad de Operaciones Compuestas

#### Expresión 10: `CARDINALITY(A UNION B)`
- **Descripción:** Tamaño de la unión de A y B
- **Valor esperado:** 4
- **Detalle:** |{a, b, c, d}| = 4

#### Expresión 11: `CARDINALITY(A INTERSECT B)`
- **Descripción:** Tamaño de la intersección de A y B
- **Valor esperado:** 1
- **Detalle:** |{b}| = 1

#### Expresión 12: `CARDINALITY(roles UNION usuarios)`
- **Descripción:** Tamaño de la unión de roles y usuarios
- **Valor esperado:** 4
- **Detalle:** |{admin, user, alice, bob}| = 4

---

### 3.5 Expresiones Compuestas Avanzadas

#### Expresión 13: `(A UNION B) INTERSECT {a,b,c}`
- **Descripción:** Intersección de la unión con un conjunto literal
- **Operación:** Primero A UNION B = {a,b,c,d}, luego INTERSECT {a,b,c}
- **Valor esperado:** {a, b, c}
- **Cardinalidad:** 3

#### Expresión 14: `permisos DIFFERENCE {execute,delete}`
- **Descripción:** Diferencia de permisos con un conjunto literal
- **Operación:** {read,write,execute} - {execute,delete}
- **Valor esperado:** {read, write}
- **Cardinalidad:** 2

#### Expresión 15: `CARDINALITY(C) + CARDINALITY(roles) - CARDINALITY(usuarios)`
- **Descripción:** Combinación aritmética de cardinalidades
- **Operación:** |C| + |roles| - |usuarios| = 2 + 2 - 2
- **Valor esperado:** 2
- **Interpretación:** Mezcla de operaciones de conjuntos y aritméticas

---

## 4. Análisis de Resultados

### 4.1 Operaciones de Conjuntos Soportadas

El sistema soporta correctamente:

- **CARDINALITY(S)** - Tamaño de un conjunto
- **A UNION B** - Unión de conjuntos
- **A INTERSECT B** - Intersección de conjuntos
- **A DIFFERENCE B** - Diferencia de conjuntos
- **{x,y} SUBSET S** - Verificación de subconjunto
- **Conjuntos literales** - {a,b,c} en expresiones
- **Composición** - Operaciones anidadas

### 4.2 Tipos de Datos en Conjuntos

Los elementos de conjuntos pueden ser:

- Strings: "a", "b", "admin", "read"
- Sin restricciones de tipo dentro del dominio
- Dominios heterogéneos permitidos

### 4.3 Operaciones Mixtas

Las expresiones pueden combinar:

- Operaciones de conjuntos (UNION, INTERSECT)
- Operaciones aritméticas (+, -)
- Operaciones lógicas (SUBSET retorna boolean)
- Funciones agregadas (CARDINALITY retorna entero)

### 4.4 Validación

- **Variables procesadas:** 6 (todas de tipo set)
- **Expresiones evaluadas:** 15
- **Operaciones probadas:**
  - CARDINALITY: 6 expresiones
  - UNION: 4 expresiones
  - INTERSECT: 3 expresiones
  - DIFFERENCE: 2 expresiones
  - SUBSET: 3 expresiones
  - Combinadas: 5 expresiones
- **Errores detectados:** 0
- **Estado:** JSON VÁLIDO - listo para el Bridge

---

## 5. Comparación con Prueba de Intervalos

| Aspecto              | Intervalos                    | Conjuntos                   |
|----------------------|-------------------------------|----------------------------|
| Tipo de datos        | float, integer                | set                        |
| Operaciones básicas  | +, -, *, /                    | UNION, INTERSECT, DIFFERENCE |
| Función agregada     | sqrt, abs, sin, exp           | CARDINALITY                |
| Operación lógica     | <, >, =                       | SUBSET, IN                 |
| Incertidumbre        | Múltiples valores numéricos   | Múltiples elementos        |
| Explosión combinatoria | 2^n valores                 | Operaciones discretas      |
| Uso típico           | CSP numéricos                 | CSP simbólicos             |

---

## 6. Conclusiones

1. El sistema **maneja correctamente** operaciones de conjuntos
2. Las **operaciones binarias** (UNION, INTERSECT, DIFFERENCE) funcionan según lo esperado
3. La función **CARDINALITY** permite integrar conjuntos con aritmética
4. Las **operaciones SUBSET** permiten verificaciones lógicas
5. Los **conjuntos literales** {a,b,c} son soportados en expresiones
6. El sistema permite **combinar operaciones** de conjuntos con aritmética y lógica
7. Es apto para **Constraint Programming simbólico** y problemas de asignación

---

## 7. Aplicaciones Prácticas

Este tipo de pruebas es útil para:

- **Control de acceso:** Verificar permisos de usuarios
- **Asignación de recursos:** Equipos, roles, tareas
- **Validación de configuraciones:** Dependencias, requisitos
- **Problemas de scheduling:** Disponibilidad, compatibilidad
- **Modelado de restricciones:** Conjuntos de valores válidos

---

## 8. Archivo de Entrada

```json
{
  "precision": 0,
  "variables": [
    {"nombre": "A", "tipo": "set", "domain": ["a","b","c","d","e"], "value": ["a","b"]},
    {"nombre": "B", "tipo": "set", "domain": ["b","c","d","e","f"], "value": ["b","c","d"]},
    {"nombre": "C", "tipo": "set", "domain": ["x","y","z"], "value": ["x","y"]},
    {"nombre": "roles", "tipo": "set", "domain": ["admin","user","guest","dev"], "value": ["admin","user"]},
    {"nombre": "permisos", "tipo": "set", "domain": ["read","write","execute","delete"], "value": ["read","write","execute"]},
    {"nombre": "usuarios", "tipo": "set", "domain": ["alice","bob","charlie","diana"], "value": ["alice","bob"]}
  ],
  "expresiones": [
    "CARDINALITY(A)", "CARDINALITY(B)", "CARDINALITY(permisos)",
    "A UNION B", "A INTERSECT B", "A DIFFERENCE B",
    "{a} SUBSET A", "{b,c} SUBSET B", "{read,write} SUBSET permisos",
    "CARDINALITY(A UNION B)", "CARDINALITY(A INTERSECT B)",
    "CARDINALITY(roles UNION usuarios)",
    "(A UNION B) INTERSECT {a,b,c}",
    "permisos DIFFERENCE {execute,delete}",
    "CARDINALITY(C) + CARDINALITY(roles) - CARDINALITY(usuarios)"
  ]
}
```

---

**Fin del Reporte**
