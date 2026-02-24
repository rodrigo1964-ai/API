---
title: "Ejemplos de Pipeline - Bridge GeCode"
subtitle: "JSON Entrada → Validación → Evaluación → JSON Salida"
author: "Proyecto GNUBison"
date: "2026"
geometry: margin=2.5cm
fontsize: 11pt
colorlinks: true
---

\newpage

# Ejemplo 1: Expresión Aritmética Simple

## Caso de Uso
Evaluar una expresión aritmética básica: `(x + y) * z`

## JSON de Entrada

```json
{
  "precision": 2,
  "variables": [
    {"nombre": "x", "tipo": "integer", "domain": [1, 100], "value": 10},
    {"nombre": "y", "tipo": "integer", "domain": [1, 100], "value": 20},
    {"nombre": "z", "tipo": "float", "domain": [0.0, 50.0], "value": 15.5}
  ],
  "expresiones": [
    "(x + y) * z"
  ]
}
```

## Comando

```bash
./bridge ejemplo_simple.json --json-output
```

## JSON de Salida

```json
{
  "archivo_entrada": "ejemplo_simple.json",
  "precision": 2,
  "factor": 100,
  "variables": [
    {
      "nombre": "x",
      "tipo": "integer",
      "dominio": [1, 100],
      "valor": 10
    },
    {
      "nombre": "y",
      "tipo": "integer",
      "dominio": [1, 100],
      "valor": 20
    },
    {
      "nombre": "z",
      "tipo": "float",
      "dominio": [0, 50],
      "valor": 15.5
    }
  ],
  "expresiones": [
    {
      "expresion": "(x + y) * z",
      "resultado": 46500
    }
  ],
  "resumen": {
    "total_variables": 3,
    "total_expresiones": 1,
    "errores": 0,
    "valido": true
  }
}
```

## Análisis del Resultado

**Cálculo Manual:**
- x = 10
- y = 20
- z = 15.5
- (x + y) * z = (10 + 20) * 15.5 = 30 * 15.5 = **465**

**Resultado del Sistema:**
- Valor retornado: `46500`
- Precisión: 2 decimales (factor = 100)
- Conversión: 46500 / 100 = **465.00** 

\newpage

# Ejemplo 2: Incertidumbre con Múltiples Valores

## Caso de Uso
Evaluar expresiones cuando las variables tienen **múltiples valores posibles** (incertidumbre).

## JSON de Entrada

```json
{
  "precision": 1,
  "variables": [
    {"nombre": "a", "tipo": "integer", "domain": [1, 10], "value": [2, 5, 8]},
    {"nombre": "b", "tipo": "integer", "domain": [1, 10], "value": 3},
    {"nombre": "valido", "tipo": "logic", "domain": [true, false],
     "value": [true, false]}
  ],
  "expresiones": [
    "a + b",
    "a > b",
    "valido AND a > 3"
  ]
}
```

## Comando

```bash
./bridge ejemplo_incertidumbre.json --json-output
```

## JSON de Salida

```json
{
  "archivo_entrada": "ejemplo_incertidumbre.json",
  "precision": 1,
  "factor": 10,
  "variables": [
    {
      "nombre": "a",
      "tipo": "integer",
      "dominio": [1, 10],
      "valor": [2, 5, 8]
    },
    {
      "nombre": "b",
      "tipo": "integer",
      "dominio": [1, 10],
      "valor": 3
    },
    {
      "nombre": "valido",
      "tipo": "logic",
      "dominio": [true, false],
      "valor": [true, false]
    }
  ],
  "expresiones": [
    {
      "expresion": "a + b",
      "resultado": [5, 8, 11]
    },
    {
      "expresion": "a > b",
      "resultado": [false, true, true]
    },
    {
      "expresion": "valido AND a > 3",
      "resultado": [true, true, true, false, false, false]
    }
  ],
  "resumen": {
    "total_variables": 3,
    "total_expresiones": 3,
    "errores": 0,
    "valido": true
  }
}
```

## Análisis Detallado

### Expresión 1: `a + b`

| a | b | Resultado |
|---|---|-----------|
| 2 | 3 | **5**     |
| 5 | 3 | **8**     |
| 8 | 3 | **11**    |

**Salida:** `[5, 8, 11]` 

### Expresión 2: `a > b`

| a | b | a > b     |
|---|---|-----------|
| 2 | 3 | **false** |
| 5 | 3 | **true**  |
| 8 | 3 | **true**  |

**Salida:** `[false, true, true]` 

### Expresión 3: `valido AND a > 3`

Producto cartesiano de todas las combinaciones:

| valido | a | a > 3 | valido AND (a>3) |
|--------|---|-------|------------------|
| true   | 2 | false | **false → true** |
| true   | 5 | true  | **true**         |
| true   | 8 | true  | **true**         |
| false  | 2 | false | **false**        |
| false  | 5 | true  | **false**        |
| false  | 8 | true  | **false**        |

**Salida:** `[true, true, true, false, false, false]` 

\newpage

# Ejemplo 3: Sistema de Control con Sensores

## Caso de Uso
Sistema de monitoreo con temperatura, presión y estado activo.

## JSON de Entrada

```json
{
  "precision": 1,
  "variables": [
    {"nombre": "temperatura", "tipo": "float",
     "domain": [0.0, 100.0], "value": 25.5},
    {"nombre": "presion", "tipo": "integer",
     "domain": [1, 10], "value": [3, 5, 7]},
    {"nombre": "activo", "tipo": "logic",
     "domain": [true, false], "value": true}
  ],
  "expresiones": [
    "temperatura > 20.0",
    "presion * 2",
    "activo AND temperatura > 15.0"
  ]
}
```

## Comando

```bash
./bridge pipeline_demo.json --json-output
```

## JSON de Salida

```json
{
  "archivo_entrada": "pipeline_demo.json",
  "precision": 1,
  "factor": 10,
  "variables": [
    {
      "nombre": "temperatura",
      "tipo": "float",
      "dominio": [0, 100],
      "valor": 25.5
    },
    {
      "nombre": "presion",
      "tipo": "integer",
      "dominio": [1, 10],
      "valor": [3, 5, 7]
    },
    {
      "nombre": "activo",
      "tipo": "logic",
      "dominio": [true, false],
      "valor": true
    }
  ],
  "expresiones": [
    {
      "expresion": "temperatura > 20.0",
      "resultado": true
    },
    {
      "expresion": "presion * 2",
      "resultado": [6, 10, 14]
    },
    {
      "expresion": "activo AND temperatura > 15.0",
      "resultado": true
    }
  ],
  "resumen": {
    "total_variables": 3,
    "total_expresiones": 3,
    "errores": 0,
    "valido": true
  }
}
```

## Interpretación de Resultados

###  Temperatura dentro de rango
- Expresión: `temperatura > 20.0`
- Valor: 25.5 °C
- **Resultado: true** → Sistema operando correctamente

###  Presión con incertidumbre
- Expresión: `presion * 2`
- Valores posibles: [3, 5, 7]
- **Resultados: [6, 10, 14]** → Múltiples escenarios

###  Sistema activo y temperatura adecuada
- Expresión: `activo AND temperatura > 15.0`
- **Resultado: true** → Condiciones óptimas

\newpage

# Ejemplo 4: Constraint Satisfaction Problem (CSP)

## Caso de Uso
Asignación de recursos con restricciones.

## JSON de Entrada

```json
{
  "precision": 1,
  "variables": [
    {"nombre": "enfermeros", "tipo": "integer",
     "domain": [2, 15], "value": null},
    {"nombre": "medicos", "tipo": "integer",
     "domain": [1, 8], "value": [3, 4, 5]},
    {"nombre": "urgente", "tipo": "logic",
     "domain": [true, false], "value": true}
  ],
  "expresiones": [
    "enfermeros + medicos <= 20",
    "enfermeros >= medicos * 2",
    "urgente = 1 IMPLICA medicos >= 3"
  ]
}
```

## Análisis de Restricciones

### Restricción 1: Total de personal limitado
```
enfermeros + medicos <= 20
```

### Restricción 2: Proporción enfermeros/médicos
```
enfermeros >= medicos * 2
```
*Al menos 2 enfermeros por cada médico*

### Restricción 3: Mínimo de médicos en emergencias
```
urgente = 1 IMPLICA medicos >= 3
```
*Si es urgente, mínimo 3 médicos*

## Validación del Sistema

El evaluador calcula **todas las combinaciones posibles** y verifica qué asignaciones satisfacen las restricciones.

**Ventajas:**
-  Verifica consistencia de restricciones
-  Identifica valores que satisfacen todas las condiciones
-  Detecta contradicciones automáticamente

\newpage

# Resumen de Capacidades

## Tipos de Evaluación

| Característica | Soportado | Ejemplo |
|----------------|-----------|---------|
| Valores fijos |  | `"value": 10` |
| Incertidumbre |  | `"value": [10, 20, 30]` |
| Sin asignación |  | `"value": null` |
| Expresiones anidadas |  | `(a + b) * (c - d)` |
| Funciones matemáticas |  | `abs(x - y)` |
| Lógica booleana |  | `A AND (B OR C)` |

## Precisión Numérica

El sistema maneja precisión decimal configurable:

- **precision: 0** → Factor = 1 (enteros)
- **precision: 1** → Factor = 10 (1 decimal)
- **precision: 2** → Factor = 100 (2 decimales)
- **precision: 3** → Factor = 1000 (3 decimales)

Los valores se almacenan como enteros multiplicados por el factor.

**Ejemplo:**
- Entrada: 15.5 con precision=1
- Almacenamiento: 155 (factor=10)
- Salida: 15.5

## Manejo de Incertidumbre

Cuando hay variables con múltiples valores, el sistema:

1. Calcula el **producto cartesiano** de todas las combinaciones
2. Evalúa la expresión para **cada combinación**
3. Retorna **array con todos los resultados**

**Complejidad:**
- n variables con m valores cada una
- Total combinaciones: m^n
- Todas las combinaciones se evalúan

## Casos de Uso

-  **Validación de restricciones** en CSP
-  **Análisis de sensibilidad** con incertidumbre
-  **Verificación formal** de condiciones lógicas
-  **Cálculo simbólico** con evaluación numérica
-  **Pruebas automatizadas** de expresiones
-  **Sistemas expertos** con reglas lógicas
