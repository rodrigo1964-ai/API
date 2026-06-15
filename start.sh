#!/bin/bash
# Script para iniciar servidor local

set -e

echo "=== GNUBison API Server - Inicio local ==="

# Compilar bridge si no existe
if [ ! -f "bin/bridge" ]; then
    echo "📦 Compilando bridge..."
    make
fi

# Compilar servidor Go si no existe
if [ ! -f "server" ]; then
    echo "🔨 Compilando servidor Go..."
    go build -o server main.go
fi

echo ""
echo "✅ Todo listo!"
echo ""
echo "🌐 Abriendo servidor en http://localhost:8080"
echo "   - Página web: http://localhost:8080/"
echo "   - Health:     http://localhost:8080/health"
echo "   - API:        http://localhost:8080/api/bison"
echo ""
echo "📝 Presiona Ctrl+C para detener"
echo ""

# Ejecutar servidor
PORT=8080 ./server
