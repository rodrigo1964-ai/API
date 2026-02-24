#!/bin/bash
# Script de demostración del pipeline Bridge GeCode

echo "========================================="
echo "   Bridge GeCode - Demo Pipeline"
echo "========================================="
echo ""

echo "1. Expresión simple:"
echo "-----------------"
./bridge ejemplo_simple.json
echo ""

echo "========================================="
echo ""
echo "2. Expresiones con incertidumbre:"
echo "--------------------------------"
./bridge ejemplo_incertidumbre.json
echo ""

echo "========================================="
echo "Pipeline completado exitosamente!"
