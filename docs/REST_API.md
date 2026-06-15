# GNUBison REST API - Especificación para LLM

> Referencia de integración HTTP para el validador/evaluador de expresiones CSP con propagación de incertidumbre

## Descripción

GNUBison expone un endpoint REST que acepta especificaciones de variables con dominios y expresiones CSP, las evalúa con propagación de incertidumbre, y retorna los resultados en JSON estructurado.

**Base URL:** `https://api-ru24.onrender.com`  
**Repositorio hub:** `rodrigo1964-ai/API` (GitHub)  
**Motor subyacente:** bridge_gecode (Bison + Flex + evaluador C)

---

## Endpoints

### `POST /api/bison` — Evaluación de expresiones

Parsea variables con dominios, construye AST de expresiones, evalúa con propagación de incertidumbre y retorna todos los valores posibles.

**Headers:**
```
Content-Type: application/json
```

**Body (Input):**
```typescript
{
  precision: number;           // Decimales significativos (escala floats a enteros)
  variables: Variable[];       // Tabla de variables con dominios y valores
  expresiones: string[];       // Expresiones CSP a evaluar
}

interface Variable {
  nombre: string;              // Identificador de la variable
  tipo: "integer"              // Entero
       | "float"               // Real (escalado por factor = 10^precision)
       | "logic"               // Booleano (true/false o 1/0)
       | "set";                // Conjunto de strings
  domain: [number, number]     // [min, max] para integer/float
        | string[];            // Elementos válidos para set
  value: number                // Valor escalar (certeza)
       | boolean               // Valor lógico
       | string                // Elemento de set
       | number[]              // Valores con incertidumbre (integer/float)
       | string[];             // Valores con incertidumbre (set/logic)
}
```

**Body (Output) — caso determinístico:**
```typescript
{
  success: true;
  results: {
    expresiones: Array<{
      expresion: string;       // Expresión evaluada
      resultado: number        // Resultado único (sin incertidumbre)
               | boolean
               | string;
    }>;
    precision: number;         // Precisión usada
    factor: number;            // 10^precision (escala aplicada a floats)
    variables: Array<{
      nombre: string;
      tipo: string;
      valor: number | boolean | string;
      dominio: [number, number] | string[];
    }>;
    resumen: {
      total_expresiones: number;
      total_variables: number;
      errores: number;
      valido: boolean;
    };
  };
}
```

**Body (Output) — con incertidumbre:**

Cuando alguna variable tiene `value` como array, el campo `resultado` se reemplaza por `resultados` (producto cartesiano de todos los valores posibles):

```typescript
{
  success: true;
  results: {
    expresiones: Array<{
      expresion: string;
      resultados: Array<number | boolean | string>;  // Todos los valores posibles
    }>;
    // ... resto igual
  };
}
```

**Body (Output) — error:**
```typescript
{
  success: false;
  error: string;               // Descripción del error de parsing o evaluación
}
```

---

### `GET /health` — Health check

Verifica disponibilidad del servicio.

**Respuesta exitosa:**
```json
{"status": "ok"}
```

---

## Tipos de variables

| `tipo`      | `domain`             | `value`                          | Descripción                        |
|-------------|----------------------|----------------------------------|------------------------------------|
| `"integer"` | `[min, max]`         | `number` o `number[]`            | Entero con dominio acotado         |
| `"float"`   | `[min, max]`         | `number` o `number[]`            | Real escalado a entero             |
| `"logic"`   | —                    | `boolean` o `boolean[]`/`0\|1`   | Booleano para restricciones lógicas|
| `"set"`     | `string[]`           | `string` o `string[]`            | Conjunto con interning de strings  |

---

## Notas de diseño

### Precisión y escala float → entero

`precision` controla cuántos decimales se preservan. El motor multiplica todos los valores float por `factor = 10^precision` y opera con enteros para evitar errores de redondeo en aritmética de punto flotante.

```
precision = 2, factor = 100
3.14  → 314  (almacenado como entero)
2.50  → 250
314 + 250 = 564  →  5.64  (al serializar: /factor)
```

El campo `factor` aparece en la respuesta para que el cliente pueda interpretar resultados escalados si es necesario.

### Incertidumbre y producto cartesiano

Cuando una variable tiene `value` como array, representa múltiples estados posibles simultáneos (incertidumbre, no iteración). El evaluador calcula el producto cartesiano de los operandos en cada operación binaria:

```
x = [1, 2],  y = [3, 4]
x + y  →  [1+3, 1+4, 2+3, 2+4]  =  [4, 5, 5, 6]
```

El resultado es `"resultados": [4, 5, 5, 6]` (con duplicados, preservando multiplicidad).

Útil para explorar el espacio de soluciones de un CSP sin backtracking explícito.

### Expresiones soportadas

Los operadores disponibles en las strings de `expresiones`:

| Categoría     | Operadores / Funciones                            |
|---------------|---------------------------------------------------|
| Aritmética    | `+`, `-`, `*`, `/`, `%`, `^`                     |
| Comparación   | `==`, `!=`, `<`, `<=`, `>`, `>=`                 |
| Lógica        | `AND`, `OR`, `NOT`, `XOR`, `IMPLIES`             |
| Conjuntos     | `UNION`, `INTERSECT`, `DIFFERENCE`, `SUBSET`, `IN`, `CARDINALITY` |
| Agregación    | `sum()`, `avg()`, `min()`, `max()`, `median()`, `variance()`, `stdev()`, `count()`, `all()`, `any()` |

---

## Ejemplos completos

### Ejemplo 1: Aritmética básica (determinístico)

```json
POST /api/bison
{
  "precision": 1,
  "variables": [
    {"nombre": "x", "tipo": "integer", "domain": [1, 100], "value": 10},
    {"nombre": "y", "tipo": "integer", "domain": [1, 100], "value": 5}
  ],
  "expresiones": ["x + y", "x * y"]
}
```

```json
{
  "success": true,
  "results": {
    "expresiones": [
      {"expresion": "x + y", "resultado": 15},
      {"expresion": "x * y", "resultado": 500}
    ],
    "precision": 1,
    "factor": 10,
    "variables": [
      {"nombre": "x", "tipo": "integer", "valor": 10, "dominio": [1, 100]},
      {"nombre": "y", "tipo": "integer", "valor": 5,  "dominio": [1, 100]}
    ],
    "resumen": {
      "total_expresiones": 2,
      "total_variables": 2,
      "errores": 0,
      "valido": true
    }
  }
}
```

### Ejemplo 2: Incertidumbre (múltiples valores)

```json
POST /api/bison
{
  "precision": 0,
  "variables": [
    {"nombre": "carga", "tipo": "integer", "domain": [0, 100], "value": [10, 20, 30]},
    {"nombre": "limite", "tipo": "integer", "domain": [0, 100], "value": 25}
  ],
  "expresiones": ["carga + limite", "carga <= limite"]
}
```

```json
{
  "success": true,
  "results": {
    "expresiones": [
      {"expresion": "carga + limite", "resultados": [35, 45, 55]},
      {"expresion": "carga <= limite", "resultados": [true, true, false]}
    ],
    "precision": 0,
    "factor": 1,
    "variables": [
      {"nombre": "carga",  "tipo": "integer", "valor": [10, 20, 30], "dominio": [0, 100]},
      {"nombre": "limite", "tipo": "integer", "valor": 25,           "dominio": [0, 100]}
    ],
    "resumen": {
      "total_expresiones": 2,
      "total_variables": 2,
      "errores": 0,
      "valido": true
    }
  }
}
```

### Ejemplo 3: Operaciones de conjuntos

```json
POST /api/bison
{
  "precision": 0,
  "variables": [
    {"nombre": "permisos_usuario", "tipo": "set", "domain": ["read","write","exec","admin"], "value": ["read","write"]},
    {"nombre": "permisos_requeridos", "tipo": "set", "domain": ["read","write","exec","admin"], "value": ["read","exec"]}
  ],
  "expresiones": [
    "permisos_usuario UNION permisos_requeridos",
    "permisos_usuario INTERSECT permisos_requeridos",
    "CARDINALITY(permisos_usuario)"
  ]
}
```

```json
{
  "success": true,
  "results": {
    "expresiones": [
      {"expresion": "permisos_usuario UNION permisos_requeridos",     "resultado": ["read","write","exec"]},
      {"expresion": "permisos_usuario INTERSECT permisos_requeridos", "resultado": ["read"]},
      {"expresion": "CARDINALITY(permisos_usuario)",                  "resultado": 2}
    ],
    "precision": 0,
    "factor": 1,
    "variables": [
      {"nombre": "permisos_usuario",    "tipo": "set", "valor": ["read","write"],        "dominio": ["read","write","exec","admin"]},
      {"nombre": "permisos_requeridos", "tipo": "set", "valor": ["read","exec"],         "dominio": ["read","write","exec","admin"]}
    ],
    "resumen": {
      "total_expresiones": 3,
      "total_variables": 2,
      "errores": 0,
      "valido": true
    }
  }
}
```

---

## Flujo de uso típico para LLM

### Caso 1: Validar restricción CSP

```
Usuario: "Verifica si x=15 satisface x > 10 AND x < 20"

LLM:
1. POST /api/bison con x=15, expresion="x > 10 AND x < 20"
2. Recibe: {"resultado": true}
3. Responde: "Sí, x=15 satisface la restricción"
```

### Caso 2: Explorar espacio de soluciones

```
Usuario: "¿Qué valores de y=[1,2,3] hacen que x+y > 5 con x=3?"

LLM:
1. POST /api/bison con x=3, y=[1,2,3], expresion="x + y > 5"
2. Recibe: {"resultados": [false, false, true]}
3. Correlaciona: y=3 satisface, y=1 y y=2 no
4. Responde: "Solo y=3 satisface x+y > 5 con x=3"
```

### Caso 3: Análisis de conjuntos con control de acceso

```
Usuario: "¿Tiene el usuario acceso? Tiene [read,write], necesita [read,exec]"

LLM:
1. POST /api/bison con variables de tipo set
2. Expresion: "permisos_usuario INTERSECT permisos_requeridos == permisos_requeridos"
3. Recibe: {"resultado": false}
4. Responde: "No tiene acceso completo: le falta 'exec'"
```

---

**Versión:** 1.0  
**Fecha:** 2026-06-15  
**Deploy:** https://api-ru24.onrender.com  
**Propósito:** Documentación REST para integración LLM con GNUBison
