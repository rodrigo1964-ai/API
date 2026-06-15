#!/bin/bash
# Script de build para Render.com

set -e

echo "=== Instalando dependencias C ==="
apt-get install -y gcc make bison flex 2>/dev/null || true

echo "=== Compilando bridge C ==="
make clean
make

echo "=== Verificando ejecutable ==="
ls -lh bin/bridge
file bin/bridge

echo "=== Compilando servidor Go ==="
go build -tags netgo -ldflags '-s -w' -o app main.go

echo "=== Build completado ==="
ls -lh app
