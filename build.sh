#!/bin/bash
# Script de build para Render.com

set -e

echo "=== Compilando bridge C ==="
make clean
make

echo "=== Verificando ejecutable ==="
ls -lh bin/bridge
file bin/bridge

echo "=== Compilando servidor Go ==="
go build -o server main.go

echo "=== Build completado ==="
ls -lh server
