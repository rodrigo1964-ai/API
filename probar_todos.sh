#!/bin/bash
# Script para ejecutar todos los ejemplos y tests de GNUBison

echo "═══════════════════════════════════════════════════════════"
echo "  PROBANDO TODOS LOS EJEMPLOS DE GNUBison"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Verificar que el ejecutable exista
if [ ! -f "./bridge" ]; then
    echo "ERROR: ./bridge no existe. Ejecutá 'make' primero."
    exit 1
fi

# Contadores
total=0
exitosos=0
fallidos=0

echo "--- EJEMPLOS DEL DIRECTORIO ejemplos/ ---"
echo ""

# Procesar ejemplos numerados
for i in {1..41}; do
    archivo="ejemplos/entrada_${i}.json"
    if [ -f "$archivo" ]; then
        total=$((total + 1))
        printf "[%2d/41] Procesando %s ... " "$i" "$archivo"

        # Ejecutar y capturar código de salida
        if ./bridge "$archivo" > "ejemplos/salida_${i}.json" 2>&1; then
            exitosos=$((exitosos + 1))
            echo "✓ OK"
        else
            fallidos=$((fallidos + 1))
            echo "✗ FALLO"
        fi
    fi
done

echo ""
echo "--- TESTS DEL DIRECTORIO RAÍZ ---"
echo ""

# Procesar tests adicionales
for archivo in test_*.json; do
    if [ -f "$archivo" ]; then
        total=$((total + 1))
        nombre_base=$(basename "$archivo" .json)
        salida="salida_${nombre_base#test_}.json"

        printf "Procesando %s ... " "$archivo"

        if ./bridge "$archivo" > "$salida" 2>&1; then
            exitosos=$((exitosos + 1))
            echo "✓ OK"
        else
            fallidos=$((fallidos + 1))
            echo "✗ FALLO"
        fi
    fi
done

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  RESUMEN"
echo "═══════════════════════════════════════════════════════════"
echo "Total procesados: $total"
echo "Exitosos:         $exitosos"
echo "Fallidos:         $fallidos"

if [ $fallidos -eq 0 ]; then
    echo ""
    echo "✓ ¡TODOS LOS TESTS PASARON!"
    exit 0
else
    echo ""
    echo "✗ Algunos tests fallaron. Revisá los archivos de salida."
    exit 1
fi
