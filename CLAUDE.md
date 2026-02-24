# Proyecto: GNUBison

## Descripción
Bridge GeCode Validator - Sistema de validación y evaluación de expresiones con 
incertidumbre usando GNU Bison y GeCode.

## Historial de Modificaciones

### 2026-02-24 - Estandarización del proyecto
- Estructura de directorios completada según modelo estándar
- Archivos organizados en: bin/, docs/, ejemplos/, obj/, src/, tests/
- Scripts de automatización agregados
- CLAUDE.md y README.txt creados

### Versiones anteriores
- Implementación del parser Bison/Flex
- Integración con GeCode para resolución de constraints
- Sistema de procesamiento de incertidumbre
- 41 casos de prueba validados

---

## Notas Técnicas

### Stack Tecnológico
- GNU Bison (parser generator)
- Flex (lexer generator)
- GeCode (constraint solver)
- C/C++ (implementación)

### Arquitectura
El sistema implementa un pipeline completo:
1. Parsing de expresiones JSON
2. Análisis semántico
3. Evaluación con incertidumbre
4. Generación de salida JSON

### Testing
- 41 casos de prueba en ejemplos/
- Tests de incertidumbre
- Tests de conjuntos
- Tests de ecuaciones
