#!/bin/bash
# Script para probar la API localmente

API_URL="http://localhost:8080"

echo "=== Probando API GNUBison ==="
echo ""

# Test 1: Health check
echo "1️⃣  Health Check:"
curl -s $API_URL/health | jq .
echo ""

# Test 2: Evaluación básica
echo "2️⃣  Evaluación básica:"
curl -s -X POST $API_URL/api/bison \
  -H "Content-Type: application/json" \
  -d '{
    "precision": 2,
    "variables": [
      {"name": "x", "type": "integer", "value": 10},
      {"name": "y", "type": "float", "value": 3.14}
    ],
    "expressions": [
      {"name": "suma", "formula": "x + y"}
    ]
  }' | jq .
echo ""

# Test 3: Con incertidumbre
echo "3️⃣  Con incertidumbre:"
curl -s -X POST $API_URL/api/bison \
  -H "Content-Type: application/json" \
  -d '{
    "precision": 0,
    "variables": [
      {"name": "x", "type": "integer", "value": [1, 2, 3]},
      {"name": "y", "type": "integer", "value": [10, 20]}
    ],
    "expressions": [
      {"name": "suma", "formula": "x + y"}
    ]
  }' | jq .
echo ""

echo "✅ Tests completados"
