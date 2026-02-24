# Documentación Bridge GeCode

Esta carpeta contiene la documentación completa del proyecto en formato Markdown y PDF.

## 📚 Documentos Disponibles

### Formato Markdown (`.md`)

- **01_introduccion.md** - Introducción, arquitectura y compilación
- **02_ejemplos_pipeline.md** - Ejemplos completos del pipeline JSON→JSON

### Formato PDF (`.pdf`)

Los PDFs se generan automáticamente desde los archivos Markdown.

##  Generar PDFs

### Requisitos

Instalar `pandoc` y LaTeX:

```bash
# Ubuntu/Debian
sudo apt install pandoc texlive-latex-base texlive-fonts-recommended texlive-latex-extra

# Fedora/RHEL
sudo dnf install pandoc texlive-scheme-basic

# macOS (Homebrew)
brew install pandoc
brew install --cask basictex
```

### Generar Todos los PDFs

Desde el directorio raíz del proyecto:

```bash
./generar_pdfs.sh
```

Esto generará:

- `docs/pdf/01_introduccion.pdf`
- `docs/pdf/02_ejemplos_pipeline.pdf`
- `docs/pdf/Bridge_GeCode_Manual_Completo.pdf` (combinado)

### Generar PDF Individual

```bash
# Solo introducción
pandoc docs/01_introduccion.md -o introduccion.pdf --pdf-engine=pdflatex --toc

# Solo ejemplos
pandoc docs/02_ejemplos_pipeline.md -o ejemplos.pdf --pdf-engine=pdflatex --toc
```

## 📖 Contenido de los Documentos

### 01. Introducción
- ¿Qué es Bridge GeCode?
- Características principales
- Tipos de datos y operadores
- Arquitectura del sistema
- Compilación e instalación

### 02. Ejemplos de Pipeline
- **Ejemplo 1**: Expresión aritmética simple
- **Ejemplo 2**: Incertidumbre con múltiples valores
- **Ejemplo 3**: Sistema de control con sensores
- **Ejemplo 4**: Constraint Satisfaction Problem (CSP)
- Análisis detallado de resultados
- Casos de uso

##  Estructura de Cada Ejemplo

Cada ejemplo incluye:

1. **Caso de uso** - Descripción del problema
2. **JSON de entrada** - Especificación completa
3. **Comando** - Cómo ejecutar
4. **JSON de salida** - Resultado del pipeline
5. **Análisis** - Explicación detallada de los resultados

## 📁 Estructura del Directorio

```
docs/
├── README.md                        # Este archivo
├── 01_introduccion.md               # Documento 1
├── 02_ejemplos_pipeline.md          # Documento 2
└── pdf/                             # PDFs generados
    ├── 01_introduccion.pdf
    ├── 02_ejemplos_pipeline.pdf
    └── Bridge_GeCode_Manual_Completo.pdf
```

## 🚀 Uso Rápido

```bash
# Generar todos los PDFs
./generar_pdfs.sh

# Ver PDFs generados
ls -lh docs/pdf/

# Abrir PDF (Linux)
xdg-open docs/pdf/Bridge_GeCode_Manual_Completo.pdf

# Abrir PDF (macOS)
open docs/pdf/Bridge_GeCode_Manual_Completo.pdf
```

## 📝 Actualizar Documentación

1. Editar archivos `.md` en `docs/`
2. Ejecutar `./generar_pdfs.sh`
3. Los PDFs se actualizan automáticamente

## 🎨 Personalización de PDFs

Para modificar el estilo de los PDFs, editar las opciones en `generar_pdfs.sh`:

- `--toc-depth`: Profundidad del índice
- `-V papersize`: Tamaño de página (letter, a4)
- `-V fontsize`: Tamaño de fuente (10pt, 11pt, 12pt)
- `-V geometry:margin`: Márgenes

## 📧 Soporte

Para más información sobre el proyecto, consultar el `README.md` principal en el directorio raíz.
