# Ejemplos del Pipeline Bridge GeCode

Esta carpeta contiene 41 ejemplos completos del pipeline JSON → JSON.

## Ejemplos 1-20: Operaciones Básicas
Ejemplos fundamentales de aritmética, lógica, comparaciones e incertidumbre.

## Ejemplos 21-41: Operaciones de Conjuntos
Ejemplos avanzados que demuestran UNION, INTERSECT, DIFFERENCE, SUBSET, CARDINALITY e IN.

## Estructura

Cada ejemplo tiene dos archivos:
- `entrada_N.json` - Especificación del problema
- `salida_N.json` - Resultados evaluados

## Uso

```bash
./bridge ejemplos/entrada_N.json ejemplos/salida_N.json
```

## Catálogo de Ejemplos

### Ejemplo 1: Operaciones Aritméticas Básicas
**entrada_1.json** - Suma, resta y multiplicación de enteros
```bash
./bridge ejemplos/entrada_1.json ejemplos/salida_1.json
```
Resultado: a=5, b=3 → a+b=8, a-b=2, a*b=15

### Ejemplo 2: Operaciones con Punto Flotante
**entrada_2.json** - Aritmética decimal de precisión
```bash
./bridge ejemplos/entrada_2.json ejemplos/salida_2.json
```
Resultado: x=12.75, y=8.25 → x+y=21.00, x*y=105.19

### Ejemplo 3: Lógica Booleana
**entrada_3.json** - AND, OR, NOT
```bash
./bridge ejemplos/entrada_3.json ejemplos/salida_3.json
```
Resultado: activo=true, bloqueado=false → AND=false, OR=true, NOT=false

### Ejemplo 4: Comparaciones
**entrada_4.json** - Operadores relacionales
```bash
./bridge ejemplos/entrada_4.json ejemplos/salida_4.json
```
Resultado: temperatura=22.5 vs umbral=20.0 → >, >=, <=

### Ejemplo 5: Incertidumbre Simple
**entrada_5.json** - Variable con múltiples valores
```bash
./bridge ejemplos/entrada_5.json ejemplos/salida_5.json
```
Resultado: x=[2,5,8] → x*2=[4,10,16]

### Ejemplo 6: Incertidumbre Combinada
**entrada_6.json** - Producto cartesiano de dos variables
```bash
./bridge ejemplos/entrada_6.json ejemplos/salida_6.json
```
Resultado: a=[1,2,3], b=[4,5] → a+b=[5,6,7,6,7,8]

### Ejemplo 7: Función Valor Absoluto
**entrada_7.json** - abs() con número negativo
```bash
./bridge ejemplos/entrada_7.json ejemplos/salida_7.json
```
Resultado: x=-5 → abs(x)=5

### Ejemplo 8: Área de Círculo
**entrada_8.json** - Cálculo geométrico
```bash
./bridge ejemplos/entrada_8.json ejemplos/salida_8.json
```
Resultado: radio=5.0 → área=25.00

### Ejemplo 9: Implicación Lógica
**entrada_9.json** - Operador IMPLICA
```bash
./bridge ejemplos/entrada_9.json ejemplos/salida_9.json
```
Resultado: p=true, q=false → p IMPLICA q = false

### Ejemplo 10: Expresiones Complejas
**entrada_10.json** - Precedencia de operadores
```bash
./bridge ejemplos/entrada_10.json ejemplos/salida_10.json
```
Resultado: Evalúa (x+y)*z, x+(y*z), x*y+z

### Ejemplo 11: Raíz Cuadrada
**entrada_11.json** - Función sqrt()
```bash
./bridge ejemplos/entrada_11.json ejemplos/salida_11.json
```
Resultado: sqrt(16) = 4

### Ejemplo 12: Variable No Asignada
**entrada_12.json** - Valor null
```bash
./bridge ejemplos/entrada_12.json ejemplos/salida_12.json
```
Resultado: edad=25 → edad>=18 = true

### Ejemplo 13: Comparaciones Múltiples
**entrada_13.json** - <, >, = con incertidumbre
```bash
./bridge ejemplos/entrada_13.json ejemplos/salida_13.json
```
Resultado: x=[3,7] vs y=5 → múltiples resultados

### Ejemplo 14: Tabla de Verdad Completa
**entrada_14.json** - Todas las combinaciones booleanas
```bash
./bridge ejemplos/entrada_14.json ejemplos/salida_14.json
```
Resultado: a=[T,F], b=[T,F] → 4 combinaciones

### Ejemplo 15: Área de Triángulo
**entrada_15.json** - Fórmula geométrica
```bash
./bridge ejemplos/entrada_15.json ejemplos/salida_15.json
```
Resultado: (base * altura) / 2 = 27.5

### Ejemplo 16: Distancia Absoluta
**entrada_16.json** - abs() simétrico
```bash
./bridge ejemplos/entrada_16.json ejemplos/salida_16.json
```
Resultado: |x-y| = |y-x| = 5

### Ejemplo 17: Promedio
**entrada_17.json** - Media aritmética
```bash
./bridge ejemplos/entrada_17.json ejemplos/salida_17.json
```
Resultado: (5+10+15)/3 = 10

### Ejemplo 18: Condiciones Múltiples
**entrada_18.json** - AND con dos condiciones
```bash
./bridge ejemplos/entrada_18.json ejemplos/salida_18.json
```
Resultado: cond1 AND cond2 = true

### Ejemplo 19: Cálculo con Incertidumbre
**entrada_19.json** - Precio con múltiples valores
```bash
./bridge ejemplos/entrada_19.json ejemplos/salida_19.json
```
Resultado: precio=[100,200,300] - descuento=20

### Ejemplo 20: Expresiones Anidadas
**entrada_20.json** - Paréntesis y precedencia
```bash
./bridge ejemplos/entrada_20.json ejemplos/salida_20.json
```
Resultado: Diferentes agrupaciones de operadores

### Ejemplo 21: Operaciones de Conjuntos - CARDINALITY
**entrada_21.json** - Contar elementos de conjuntos
```bash
./bridge ejemplos/entrada_21.json ejemplos/salida_21.json
```
Resultado: Cardinalidad de variables set y sets literales

### Ejemplo 22-41: Casos de Uso Avanzados
Ejemplos que demuestran:
- Control de acceso y permisos (25, 31)
- Gestión de proyectos y equipos (22, 34, 37, 39)
- Redes y protocolos (24, 28)
- Inventarios y productos (29)
- Recursos humanos (23, 30, 38)
- IoT y sensores (32)
- Software y módulos (33, 39)
- Logística y regiones (35, 31)
- Finanzas y pagos (36)
- Estados y workflows (40)
- Hardware y componentes (41)

## Ejecutar Todos los Ejemplos

```bash
# Regenerar todas las salidas (ejemplos 1-41)
for i in {1..41}; do
  ./bridge ejemplos/entrada_$i.json ejemplos/salida_$i.json
done
```

## Ver Resultados

```bash
# Ver salida de un ejemplo específico
cat ejemplos/salida_1.json

# Ver entrada y salida lado a lado
cat ejemplos/entrada_1.json
cat ejemplos/salida_1.json
```

## Características Demostradas

### Operaciones Básicas (Ejemplos 1-20)
- Aritmética: suma, resta, multiplicación, división
- Comparaciones: <, >, <=, >=, =, <>
- Lógica: AND, OR, NOT, IMPLICA
- Funciones: abs(), sqrt(), sqr(), sin(), cos(), ln(), exp()
- Incertidumbre: múltiples valores posibles
- Producto cartesiano: combinaciones de valores

### Operaciones de Conjuntos (Ejemplos 21-41)
- **IN**: Pertenencia a conjunto
- **UNION**: Unión de conjuntos
- **INTERSECT**: Intersección
- **DIFFERENCE**: Diferencia
- **SUBSET**: Verificación de subconjunto
- **CARDINALITY**: Conteo de elementos
- **Sintaxis sin comillas**: `{a,b,c}` en expresiones

### Características Generales
- Precisión decimal: 0, 1, 2 decimales
- Tipos: integer, float, logic, set
- Expresiones anidadas y complejas
- Combinación de operadores aritméticos, lógicos y de conjuntos
