#!/bin/bash
# Script para generar PDFs de la documentación

echo "================================================="
echo "  Generando PDFs - Bridge GeCode Documentation"
echo "================================================="
echo ""

# Crear directorio de salida
mkdir -p docs/pdf

# Verificar que pandoc está instalado
if ! command -v pandoc &> /dev/null; then
    echo "ERROR: pandoc no está instalado"
    echo ""
    echo "Instalar con:"
    echo "  Ubuntu/Debian: sudo apt install pandoc texlive-latex-base texlive-fonts-recommended texlive-latex-extra"
    echo ""
    exit 1
fi

echo "pandoc encontrado: $(pandoc --version | head -1)"
echo ""

# Generar PDF 1: Introducción
echo "Generando: 01_introduccion.pdf..."
pandoc docs/01_introduccion.md \
    -o docs/pdf/01_introduccion.pdf \
    --pdf-engine=pdflatex \
    -V papersize=letter \
    --toc \
    --toc-depth=2 \
    2>/dev/null

if [ -f docs/pdf/01_introduccion.pdf ]; then
    echo "   OK: docs/pdf/01_introduccion.pdf"
else
    echo "   ERROR generando 01_introduccion.pdf"
fi

# Generar PDF 2: Ejemplos Pipeline
echo "Generando: 02_ejemplos_pipeline.pdf..."
pandoc docs/02_ejemplos_pipeline.md \
    -o docs/pdf/02_ejemplos_pipeline.pdf \
    --pdf-engine=pdflatex \
    -V papersize=letter \
    --toc \
    --toc-depth=2 \
    2>/dev/null

if [ -f docs/pdf/02_ejemplos_pipeline.pdf ]; then
    echo "   OK: docs/pdf/02_ejemplos_pipeline.pdf"
else
    echo "   ERROR generando 02_ejemplos_pipeline.pdf"
fi

# Generar PDF 3: Operaciones de Conjuntos
echo "Generando: 03_operaciones_conjuntos.pdf..."
pandoc docs/03_operaciones_conjuntos.md \
    -o docs/pdf/03_operaciones_conjuntos.pdf \
    --pdf-engine=pdflatex \
    -V papersize=letter \
    --toc \
    --toc-depth=2 \
    2>/dev/null

if [ -f docs/pdf/03_operaciones_conjuntos.pdf ]; then
    echo "   OK: docs/pdf/03_operaciones_conjuntos.pdf"
else
    echo "   ERROR generando 03_operaciones_conjuntos.pdf"
fi

# Generar PDF combinado
echo "Generando: Bridge_GeCode_Manual_Completo.pdf..."
pandoc docs/01_introduccion.md docs/02_ejemplos_pipeline.md docs/03_operaciones_conjuntos.md \
    -o docs/pdf/Bridge_GeCode_Manual_Completo.pdf \
    --pdf-engine=pdflatex \
    -V papersize=letter \
    --toc \
    --toc-depth=2 \
    --metadata title="Bridge GeCode - Manual Completo" \
    2>/dev/null

if [ -f docs/pdf/Bridge_GeCode_Manual_Completo.pdf ]; then
    echo "   OK: docs/pdf/Bridge_GeCode_Manual_Completo.pdf"
else
    echo "   ERROR generando manual completo"
fi

echo ""
echo "================================================="
echo "  Resumen"
echo "================================================="
echo ""

if [ -d docs/pdf ] && [ -n "$(ls -A docs/pdf/*.pdf 2>/dev/null)" ]; then
    ls -lh docs/pdf/*.pdf
    echo ""
    echo "PDFs generados exitosamente en: docs/pdf/"
else
    echo "No se generaron PDFs"
fi

echo ""
echo "================================================="
echo "Proceso completado"
echo "================================================="
