---
title: "Bridge GeCode - Validador y Evaluador de Expresiones"
subtitle: "Pipeline de Verificación para Constraint Programming"
author: "Proyecto GNUBison"
date: "2026"
geometry: margin=2.5cm
fontsize: 11pt
colorlinks: true
---

\newpage

# Introducción

## ¿Qué es Bridge GeCode?

**Bridge GeCode** es un compilador y evaluador de expresiones diseñado para problemas de **Constraint Programming (CSP)**. Funciona como un pipeline que:

1. **Recibe** especificaciones en formato JSON o Pascal-like
2. **Valida** la sintaxis y semántica
3. **Evalúa** expresiones con variables
4. **Retorna** resultados en formato JSON

## Características Principales

-  **Validación de Sintaxis**: Parser robusto con Flex/Bison
-  **Evaluación de Expresiones**: Calcula resultados automáticamente
-  **Soporte Dual**: Acepta formato JSON y Pascal-like
-  **Manejo de Incertidumbre**: Variables con múltiples valores posibles
-  **Operaciones de Conjuntos**: UNION, INTERSECT, DIFFERENCE, SUBSET, CARDINALITY, IN
-  **Sintaxis Moderna de Sets**: `{a,b,c}` sin comillas en expresiones
-  **Salida Estructurada**: JSON con resultados detallados
-  **Funciones Matemáticas**: abs, sqrt, sin, cos, ln, exp, etc.

## Tipos de Datos Soportados

| Tipo     | Descripción                        | Ejemplo                    |
|----------|------------------------------------|-----------------------------|
| integer  | Números enteros                    | `[1, 100]`                 |
| float    | Números decimales                  | `[0.0, 50.0]`              |
| logic    | Booleanos                          | `[true, false]`            |
| set      | Conjuntos de strings               | `["A", "B", "C"]`          |

## Operadores

### Aritméticos
`+`, `-`, `*`, `/`

### Lógicos
`AND`, `OR`, `NOT`, `IMPLICA`

### Relacionales
`=`, `<>`, `<`, `>`, `<=`, `>=`

### Operadores de Conjuntos
- **IN**: Verificar pertenencia → `x IN {a,b,c}`
- **UNION**: Unión de conjuntos → `A UNION B`
- **INTERSECT**: Intersección → `A INTERSECT B`
- **DIFFERENCE**: Diferencia → `A DIFFERENCE B`
- **SUBSET**: Verificar subconjunto → `A SUBSET B`
- **CARDINALITY**: Contar elementos → `CARDINALITY(A)`

### Funciones Estándar
`abs(x)`, `sqrt(x)`, `sqr(x)`, `sin(x)`, `cos(x)`, `ln(x)`, `exp(x)`

\newpage

# Arquitectura del Sistema

## Componentes Principales

```
                      ↓
                      ↓
                      ↓
                      ↓
                      ↓
```

## Archivos del Proyecto

- **cJSON.c**: Biblioteca JSON (MIT License)

\newpage

# Compilación e Instalación

## Requisitos

- **gcc** (compilador C)
- **bison** >= 3.0
- **flex** >= 2.6
- **make**

## Instalación de Dependencias

```bash
# Ubuntu/Debian
sudo apt install gcc bison flex make

# Fedora/RHEL
sudo dnf install gcc bison flex make
```

## Compilación

```bash
# Clonar o descargar el proyecto
cd GNUBison

# Compilar
make

# Limpiar archivos generados
make clean
```

## Verificación

```bash
# Ejecutar ejemplo simple

# Debe mostrar JSON con resultados
```

## Estructura de Directorios

```
GNUBison/
```
