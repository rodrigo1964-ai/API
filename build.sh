#!/bin/bash
set -e

echo "=== Compilando servidor Go ==="
go build -tags netgo -ldflags '-s -w' -o app main.go

echo "=== Verificando binarios ==="
ls -lh app bin/bridge
echo "=== Build completado ==="
